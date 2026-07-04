"""
terminal_launcher.py

Resolve qual terminal usar (TERMINAL env -> xdg-terminal-exec -> fallback list)
e lança comandos de DesktopApp respeitando Terminal=true no .desktop,
em vez de depender do app.launch() padrão do Fabric.
"""

import configparser
import os
import re
import shlex
import shutil
import subprocess

# Diretórios XDG padrão onde os .desktop ficam
XDG_APP_DIRS = [
    os.path.expanduser("~/.local/share/applications"),
    "/usr/local/share/applications",
    "/usr/share/applications",
]

_terminal_flag_cache: dict[str, bool] = {}

FALLBACK_TERMINALS = ["kitty", "foot", "alacritty", "wezterm", "xterm"]

# terminais cuja flag de execução não é "-e"
TERMINAL_EXEC_FLAGS = {
    "gnome-terminal": "--",
    "wezterm": "start",  # wezterm start -- <cmd>
}

_cached_terminal: str | None = None


def resolve_terminal(force_refresh: bool = False) -> str | None:
    """Resolve o terminal a usar, com cache em memória."""
    global _cached_terminal
    if _cached_terminal is not None and not force_refresh:
        return _cached_terminal

    # 1. respeita $TERMINAL se setado e existir no PATH
    env_term = os.environ.get("TERMINAL")
    if env_term and shutil.which(env_term):
        _cached_terminal = env_term
        return _cached_terminal

    # 2. xdg-terminal-exec, se disponível
    if shutil.which("xdg-terminal-exec"):
        _cached_terminal = "xdg-terminal-exec"
        return _cached_terminal

    # 3. cascata de fallback
    for term in FALLBACK_TERMINALS:
        if shutil.which(term):
            _cached_terminal = term
            return _cached_terminal

    _cached_terminal = None
    return None


def build_launch_command(exec_cmd: list[str] | str) -> list[str]:
    """Monta o comando final para rodar exec_cmd dentro do terminal escolhido."""
    if isinstance(exec_cmd, str):
        exec_cmd = shlex.split(exec_cmd)

    terminal = resolve_terminal()
    if terminal is None:
        raise RuntimeError(
            "Nenhum terminal encontrado no sistema (defina $TERMINAL ou instale "
            "xdg-terminal-exec / kitty / foot / alacritty / wezterm / xterm)"
        )

    if terminal == "xdg-terminal-exec":
        return ["xdg-terminal-exec", *exec_cmd]

    if terminal == "wezterm":
        return ["wezterm", "start", "--", *exec_cmd]

    flag = TERMINAL_EXEC_FLAGS.get(terminal, "-e")
    return [terminal, flag, *exec_cmd]


def _find_desktop_file(app_name: str) -> str | None:
    """Procura o .desktop cujo nome do arquivo corresponde ao app, nos diretórios XDG."""
    # tenta o nome direto primeiro (case-insensitive), depois varre tudo
    candidates = [f"{app_name}.desktop", f"{app_name.lower()}.desktop"]
    for directory in XDG_APP_DIRS:
        if not os.path.isdir(directory):
            continue
        for candidate in candidates:
            path = os.path.join(directory, candidate)
            if os.path.isfile(path):
                return path
    # fallback: varre todos os .desktop procurando Name= correspondente
    for directory in XDG_APP_DIRS:
        if not os.path.isdir(directory):
            continue
        for fname in os.listdir(directory):
            if not fname.endswith(".desktop"):
                continue
            path = os.path.join(directory, fname)
            try:
                parser = configparser.ConfigParser(interpolation=None, strict=False)
                parser.read(path, encoding="utf-8")
                entry = parser["Desktop Entry"]
                if entry.get("Name", "").casefold() == app_name.casefold():
                    return path
            except Exception:
                continue
    return None


def app_needs_terminal(app) -> bool:
    """
    Lê Terminal= diretamente do .desktop original, já que
    fabric.utils.DesktopApp não expõe essa informação.
    Resultado é cacheado por nome de app.
    """
    app_name = app.name or app.display_name or ""
    if app_name in _terminal_flag_cache:
        return _terminal_flag_cache[app_name]

    needs_terminal = False
    desktop_path = _find_desktop_file(app_name)
    if desktop_path:
        try:
            parser = configparser.ConfigParser(interpolation=None, strict=False)
            parser.read(desktop_path, encoding="utf-8")
            entry = parser["Desktop Entry"]
            needs_terminal = entry.get("Terminal", "false").strip().lower() == "true"
        except Exception:
            needs_terminal = False

    _terminal_flag_cache[app_name] = needs_terminal
    return needs_terminal



_FIELD_CODE_RE = re.compile(r"%[fFuUdDnNickvmhH]")


def _strip_field_codes(cmd: str) -> str:
    """Remove XDG field codes from an Exec string (no files/URLs to substitute)."""
    cmd = cmd.replace("%%", "\x00")
    cmd = _FIELD_CODE_RE.sub("", cmd)
    return " ".join(cmd.replace("\x00", "%").split())


def launch_app(app) -> None:
    """
    Lança um fabric.utils.DesktopApp respeitando Terminal=true (lido manualmente
    do .desktop original, já que o Fabric não expõe esse atributo), usando o
    terminal resolvido em vez do comportamento default da lib.
    """
    exec_cmd = _strip_field_codes(app.command_line)

    if app_needs_terminal(app):
        cmd = build_launch_command(exec_cmd)
    else:
        cmd = shlex.split(exec_cmd) if isinstance(exec_cmd, str) else exec_cmd

    subprocess.Popen(cmd, start_new_session=True)
