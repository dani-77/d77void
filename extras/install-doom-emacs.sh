#!/usr/bin/env bash
# install-doom-emacs.sh — reproducible Doom Emacs bootstrap for dani77's machines.
#
# What this does:
#   1. Installs OS dependencies Doom needs (Void Linux / xbps primary target).
#   2. Clones the Doom Emacs core to ~/.config/emacs (skips if already present).
#   3. Detects whether native-comp (libgccjit) is broken on this machine — a
#      known issue on Void when gcc and libgccjit packages drift out of sync
#      (e.g. gcc 16.1.0 vs libgccjit still on 14.2.1: native compilation aborts
#      with "ld: cannot find crtbeginS.o" / "error invoking gcc driver").
#      If broken, disables native-comp so Emacs falls back to byte-compiled
#      Elisp instead of crashing; if fine, leaves native-comp on for full speed.
#   4. Wires PATH + (if needed) the native-comp workaround into ~/.bashrc,
#      idempotently.
#   5. Runs `doom install`, either bootstrapping a stock config or reusing
#      $DOOMDIR (~/.config/doom) if you've already synced your dotfiles there.
#
# Usage:
#   ./install-doom-emacs.sh
#
# Safe to re-run: every step checks current state before acting.

set -euo pipefail

DOOM_CORE="$HOME/.config/emacs"
DOOM_DIR="${DOOMDIR:-$HOME/.config/doom}"
DOOM_REPO="https://github.com/doomemacs/core"
BASHRC="$HOME/.bashrc"
MARKER="# >>> doom-emacs bootstrap >>>"
MARKER_END="# <<< doom-emacs bootstrap <<<"

log()  { printf '\033[1;34m[doom-install]\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33m[doom-install]\033[0m %s\n' "$*"; }
die()  { printf '\033[1;31m[doom-install]\033[0m %s\n' "$*" >&2; exit 1; }

# ---------------------------------------------------------------------------
# 1. OS dependencies
# ---------------------------------------------------------------------------
install_deps() {
  local deps_void=(git emacs ripgrep fd curl fzf make gcc base-devel)

  if command -v xbps-install >/dev/null 2>&1; then
    log "Void Linux detected (xbps). Installing dependencies..."
    sudo xbps-install -Sy "${deps_void[@]}"
  elif command -v apt-get >/dev/null 2>&1; then
    log "Debian/Ubuntu detected (apt). Installing dependencies..."
    sudo apt-get update
    sudo apt-get install -y git emacs ripgrep fd-find curl fzf build-essential
  elif command -v dnf >/dev/null 2>&1; then
    log "Fedora detected (dnf). Installing dependencies..."
    sudo dnf install -y git emacs ripgrep fd-find curl fzf make gcc
  elif command -v pacman >/dev/null 2>&1; then
    log "Arch detected (pacman). Installing dependencies..."
    sudo pacman -Sy --needed git emacs ripgrep fd curl fzf make gcc base-devel
  else
    warn "No known package manager found. Skipping automatic dependency install."
    warn "Make sure git, emacs (>=29), ripgrep, fd, curl, fzf, make and a C compiler are installed."
  fi
}

# ---------------------------------------------------------------------------
# 2. Clone Doom core
# ---------------------------------------------------------------------------
clone_doom_core() {
  if [ -d "$DOOM_CORE/.git" ]; then
    log "Doom core already present at $DOOM_CORE, skipping clone."
  else
    log "Cloning Doom Emacs core into $DOOM_CORE..."
    git clone --depth 1 "$DOOM_REPO" "$DOOM_CORE"
  fi
}

# ---------------------------------------------------------------------------
# 3. Detect broken native-comp
# ---------------------------------------------------------------------------
native_comp_is_broken() {
  local result
  result=$(timeout 20 emacs -Q --batch --eval "
(if (not (native-comp-available-p))
    (princ \"UNAVAILABLE\")
  (condition-case e
      (progn (native-compile (lambda () 1)) (princ \"OK\"))
    (error (princ \"BROKEN\"))))" 2>/dev/null || echo "BROKEN")
  [ "$result" = "BROKEN" ]
}

# ---------------------------------------------------------------------------
# 4. Wire up ~/.bashrc (PATH + native-comp workaround), idempotently
# ---------------------------------------------------------------------------
setup_bashrc() {
  local need_workaround="$1"

  if grep -qF "$MARKER" "$BASHRC" 2>/dev/null; then
    log "Removing previous doom-emacs bootstrap block from ~/.bashrc to refresh it..."
    sed -i "/^$MARKER\$/,/^$MARKER_END\$/d" "$BASHRC"
  fi

  {
    echo "$MARKER"
    echo 'export PATH="$HOME/.config/emacs/bin:$PATH"'
    if [ "$need_workaround" = "yes" ]; then
      echo "# Native-comp is broken on this machine (gcc/libgccjit version mismatch)."
      echo "# Disabling it avoids Emacs aborting on startup; byte-compiled Elisp still works."
      echo "export EMACS=\"emacs --eval '(setq native-comp-jit-compilation nil native-comp-enable-subr-trampolines nil)'\""
    fi
    echo "$MARKER_END"
  } >> "$BASHRC"

  log "Updated ~/.bashrc (PATH$( [ "$need_workaround" = yes ] && echo ' + native-comp workaround' ))."
}

# ---------------------------------------------------------------------------
# 5. Clear a stale ~/.emacs.d that would shadow ~/.config/emacs
# ---------------------------------------------------------------------------
# Emacs prefers ~/.emacs.d over ~/.config/emacs when both exist. A leftover
# ~/.emacs.d (e.g. eln-cache debris from a prior crashed native-comp attempt)
# can silently make Emacs ignore the real Doom config. Only auto-remove it
# when it's clearly not a real, separate config (no init.el/early-init.el of
# its own) — never touch it if it looks intentional.
clear_stale_emacs_d() {
  local dir="$HOME/.emacs.d"
  if [ ! -d "$dir" ]; then
    return
  fi
  if [ -f "$dir/init.el" ] || [ -f "$dir/early-init.el" ]; then
    warn "$dir has its own init.el/early-init.el — leaving it alone."
    warn "This may shadow Doom (~/.config/emacs); remove or merge it manually if Emacs won't start Doom."
    return
  fi
  log "Removing stale $dir (no config of its own, just cache debris) so it can't shadow Doom's config..."
  rm -rf "$dir"
}

# ---------------------------------------------------------------------------
# 6. Run doom install
# ---------------------------------------------------------------------------
run_doom_install() {
  export PATH="$DOOM_CORE/bin:$PATH"
  if [ "$1" = "yes" ]; then
    export EMACS="emacs --eval '(setq native-comp-jit-compilation nil native-comp-enable-subr-trampolines nil)'"
  fi

  local config_flag="--config"
  if [ -f "$DOOM_DIR/init.el" ]; then
    log "Existing Doom config found at $DOOM_DIR — reusing it (not overwriting)."
    config_flag="--no-config"
  else
    log "No Doom config found at $DOOM_DIR — Doom will generate a starter one."
  fi

  log "Running: doom install $config_flag --force"
  "$DOOM_CORE/bin/doom" install "$config_flag" --force
}

# ---------------------------------------------------------------------------
main() {
  install_deps
  clone_doom_core
  clear_stale_emacs_d

  local broken=no
  if native_comp_is_broken; then
    warn "native-comp looks broken on this machine (gcc/libgccjit mismatch) — disabling it."
    broken=yes
  else
    log "native-comp works fine on this machine — leaving it enabled."
  fi

  setup_bashrc "$broken"
  run_doom_install "$broken"

  log "Running doom doctor for a final health check..."
  "$DOOM_CORE/bin/doom" doctor || true

  log "Done! Open a new terminal (to pick up ~/.bashrc) and run: doom sync"
  log "Then launch Emacs normally — Doom will finish setting itself up."
}

main "$@"
