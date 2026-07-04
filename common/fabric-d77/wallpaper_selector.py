import os
import subprocess

from fabric.widgets.box import Box
from fabric.widgets.button import Button
from fabric.widgets.image import Image
from fabric.widgets.label import Label
from fabric.widgets.scrolledwindow import ScrolledWindow
from fabric.widgets.wayland import WaylandWindow as Window
from gi.repository import GLib

# Diretório com os wallpapers. Ajusta aqui se quiseres outro caminho.
WALLPAPER_DIR = os.path.expanduser("~/Wallpaper")

# Extensões de imagem aceites
VALID_EXTENSIONS = (".png", ".jpg", ".jpeg", ".webp", ".bmp")

THUMB_SIZE = 160
COLUMNS = 4


class WallpaperSelector(Window):
    """Grid de wallpapers (estilo DankMaterialShell) que aplica via swww ao clicar.

    Janela layer-shell standalone, seguindo o mesmo padrão de SessionMenu:
    overlay centrado, keyboard_mode on-demand, escape para fechar.
    """

    def __init__(self, **kwargs):
        super().__init__(
            layer="overlay",
            anchor="center",
            exclusivity="none",
            keyboard_mode="on-demand",
            visible=False,
            all_visible=False,
            **kwargs,
        )

        self.current_wallpaper: str | None = None

        self.grid_box = Box(
            name="wallpaper-grid",
            orientation="v",
            spacing=8,
        )

        self.scrolled = ScrolledWindow(
            name="wallpaper-scroll",
            child=self.grid_box,
            h_expand=True,
            v_expand=True,
            min_content_width=COLUMNS * (THUMB_SIZE + 16),
            min_content_height=600,
        )

        self.title_label = Label(
            name="wallpaper-title",
            label="Wallpapers",
            h_align="start",
        )

        self.add(
            Box(
                name="wallpaper-selector",
                orientation="v",
                spacing=12,
                children=[
                    self.title_label,
                    self.scrolled,
                ],
            )
        )

        self.add_keybinding("escape", lambda *_: self.set_visible(False))

        print("[wallpaper_selector] __init__: a chamar populate()")
        self.populate()
        print("[wallpaper_selector] __init__: a chamar show_all()")
        self.show_all()
        print("[wallpaper_selector] __init__: concluído")

    # -- listagem / grid -------------------------------------------------

    def list_wallpapers(self) -> list[str]:
        if not os.path.isdir(WALLPAPER_DIR):
            return []
        files = [
            os.path.join(WALLPAPER_DIR, f)
            for f in sorted(os.listdir(WALLPAPER_DIR))
            if f.lower().endswith(VALID_EXTENSIONS)
        ]
        return files

    def populate(self):
        print("[wallpaper_selector] populate() iniciado")
        # limpa o grid atual antes de repopular (permite refresh())
        for child in list(self.grid_box.children):
            self.grid_box.remove(child)

        wallpapers = self.list_wallpapers()
        print(f"[wallpaper_selector] {len(wallpapers)} wallpapers encontrados")

        if not wallpapers:
            self.grid_box.add(
                Label(
                    name="wallpaper-empty",
                    label=f"Nenhuma imagem encontrada em {WALLPAPER_DIR}",
                )
            )
            print("[wallpaper_selector] populate() terminado (sem wallpapers)")
            return

        row = None
        for i, path in enumerate(wallpapers):
            if i % COLUMNS == 0:
                row = Box(orientation="h", spacing=8)
                self.grid_box.add(row)
            try:
                row.add(self.bake_thumbnail(path))
            except Exception as exc:
                print(f"[wallpaper_selector] ERRO ao criar thumbnail para {path}: {exc}")
        print("[wallpaper_selector] populate() terminado com sucesso")

    def bake_thumbnail(self, path: str) -> Button:
        try:
            thumb = Image(
                image_file=path,
                size=THUMB_SIZE,
            )
        except Exception as exc:
            # Ficheiro com extensão de imagem mas formato inválido/sem loader
            # (ex: webp sem gdk-pixbuf-webp instalado, ficheiro corrompido,
            # symlink partido). Não deixamos isto derrubar o selector todo.
            print(f"[wallpaper_selector] falhou a carregar '{path}': {exc}")
            thumb = Label(label="⚠", name="wallpaper-thumb-error")

        is_current = path == self.current_wallpaper

        btn = Button(
            name="wallpaper-thumb-selected" if is_current else "wallpaper-thumb",
            child=Box(
                orientation="v",
                spacing=4,
                children=[
                    thumb,
                    Label(
                        label=os.path.basename(path),
                        name="wallpaper-thumb-label",
                    ),
                ],
            ),
            on_clicked=lambda *_, p=path: self.apply_wallpaper(p),
        )
        return btn

    # -- aplicar wallpaper -------------------------------------------------

    def apply_wallpaper(self, path: str):
        """Aplica o wallpaper via swww de forma assíncrona (não bloqueia a UI)."""
        try:
            subprocess.Popen(
                ["swww", "img", path],
                stdout=subprocess.DEVNULL,
                stderr=subprocess.DEVNULL,
            )
        except FileNotFoundError:
            self.title_label.set_label("Erro: swww não encontrado no PATH")
            return

        self.current_wallpaper = path
        self.title_label.set_label(f"Wallpapers — {os.path.basename(path)}")
        # re-renderiza para destacar a thumbnail selecionada
        GLib.idle_add(self.populate)
        self.set_visible(False)

    def refresh(self):
        """Repopula o grid (chamar ao reabrir, para refletir novos ficheiros)."""
        self.populate()
        self.show_all()

    def toggle(self):
        if self.get_visible():
            self.set_visible(False)
        else:
            self.refresh()
            self.set_visible(True)
