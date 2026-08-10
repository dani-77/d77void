-- spitfire default config — the dwm config.h equivalent, but Lua and
-- reloadable at runtime (spitfire.reload(), or `spitfirectl reload`)
-- instead of a recompile.
--
-- Install at $XDG_CONFIG_HOME/spitfire/config.lua (usually
-- ~/.config/spitfire/config.lua).

-- spitfire.bind(mods, key, fn) takes any modifier per bind, independently —
-- Mod4 (Super/Windows) and Mod1 (Alt) are both first-class; nothing below
-- is fixed, edit any line to move it to whichever modifier (or key) you
-- want, or mix both across different binds. Accepted spellings:
-- Mod4/Super/Logo/Cmd and Mod1/Alt (see spitfire_config::bind::Modifiers::parse)
-- — Shift/Ctrl combine the same way, e.g. "Mod4+Shift".

-- Named scratchpad
spitfire.bind("Mod4", "s", function()
  spitfire.scratchpad.toggle("term", "alacritty --class scratchterm", "scratchterm", 0.5, 0.5) end)

-- Layouts: tile (dwm master-stack), floating, fibonacci (spiral), monocle.
spitfire.bind("Mod4", "t", function() spitfire.layout.set("tile") end)
spitfire.bind("Mod4", "f", function() spitfire.layout.set("fibonacci") end)
spitfire.bind("Mod4", "m", function() spitfire.layout.set("monocle") end)
spitfire.bind("Mod4+Shift", "space", function() spitfire.layout.set("floating") end)
spitfire.bind("Mod4", "space", function() spitfire.layout.cycle() end)

-- Master column size / count — dwm: MODKEY+h/l and MODKEY+i/d.
spitfire.bind("Mod4", "l", function() spitfire.mfact.inc(0.05) end)
spitfire.bind("Mod4", "h", function() spitfire.mfact.inc(-0.05) end)
spitfire.bind("Mod4", "i", function() spitfire.nmaster.inc(1) end)
spitfire.bind("Mod4", "d", function() spitfire.nmaster.inc(-1) end)

-- Workspaces — dynamic, niri-style: asking to focus workspace 5 when only
-- 2 exist just creates 3, 4, and 5. 1-based. Advertised over
-- ext-workspace-v1, so any bar that knows that protocol sees them too —
-- spitfire.bar below shows them directly.
for i = 1, 9 do
  spitfire.bind("Mod4", tostring(i), function() spitfire.workspace.focus(i) end)
  spitfire.bind("Mod1", tostring(i), function() spitfire.workspace.move_window(i) end)
end

-- D77
spitfire.bind("Mod4", "a", function() spitfire.spawn("qsd77 launcher -c utumno") end)
spitfire.bind("Mod4", "r", function() spitfire.spawn("d77run") end)
spitfire.bind("Mod4", "x", function() spitfire.spawn("qsd77 session -c utumno") end)
spitfire.bind("Mod4", "y", function() spitfire.spawn("qsd77 wallpaper -c utumno") end)
spitfire.bind("Mod4", "z", function() spitfire.spawn("qsd77 locker -c utumno") end)

-- Media keys — no modifier, they're dedicated hardware keys. Routed
-- through qsd77's raw IPC passthrough (no dedicated volume subcommand) to
-- utumno's OSD, so raising/lowering/muting shows the on-screen popup —
-- same IPC targets as README.md's niri/Hyprland XF86 examples.
spitfire.bind("", "XF86AudioRaiseVolume", function() spitfire.spawn("qsd77 ipc call osd volumeUp -c utumno") end)
spitfire.bind("", "XF86AudioLowerVolume", function() spitfire.spawn("qsd77 ipc call osd volumeDown -c utumno") end)
spitfire.bind("", "XF86AudioMute", function() spitfire.spawn("qsd77 ipc call osd volumeMuteToggle -c utumno") end)

-- Launching things — this is you configuring which terminal to use,
-- spitfire itself has no built-in/hardcoded default (see spitfire.spawn
-- below); swap "Mod4" for "Mod1" here, or anywhere else, freely.
spitfire.bind("Mod4", "Return", function() spitfire.spawn("alacritty") end)
spitfire.bind("Mod4+Shift", "q", function() spitfire.quit() end)
spitfire.bind("Mod4+Shift", "r", function() spitfire.reload() end)

-- Window management — close the focused window, cycle which one has
-- keyboard focus (dwm-style j/k; wraps around).
spitfire.bind("Mod4", "q", function() spitfire.window.close() end)
spitfire.bind("Mod4", "j", function() spitfire.window.focus_next() end)
spitfire.bind("Mod4", "k", function() spitfire.window.focus_prev() end)
spitfire.bind("Mod4+Shift", "j", function() spitfire.window.swap_next() end)
spitfire.bind("Mod4+Shift", "k", function() spitfire.window.swap_prev() end)

-- Window rules — floating windows are left out of the tiling arrangement
-- entirely (their geometry is never touched).
spitfire.rule({ app_id = "d77-welcome", floating = true, centered = true })
spitfire.rule({ app_id = "qt-sudo", floating = true, centered = true })
spitfire.rule({ app_id = "dev.d77.gmrun-rejuvenated", floating = true, centered = true })

spitfire.border = { width = 4, active = "#7aa2f7", inactive = "#414868", radius = 12 }
spitfire.gaps = { inner = 20, outer = 10 }
spitfire.anim = { enabled = true, duration = 200 }
spitfire.output = { scale = 1.25 }

-- Keyboard layout — empty string means "let xkbcommon pick its own
-- default" (in practice, "us"). Same fields/meaning as setxkbmap's flags
-- of the same names. Applied at startup and again on every
-- spitfire.reload() (no restart needed to try a different layout).
spitfire.keyboard = { layout = "us", variant = "intl", model = "", options = "" }

-- Optional built-in bar — on by default so there's something visibly
-- alive on screen out of the box. Not a client, not a protocol: drawn by
-- spitfire itself (a bitmap font, no TTF), floating with a gap of
-- spitfire.gaps.outer on the top/left/right edges. Workspace list +
-- active layout mode on the left; CPU/RAM/battery/network/clock/date on
-- the right. Coexists fine with a client bar (e.g. Utumno's own) — set
-- `enable = false` if you're using one of those instead.
spitfire.bar = {
  enable = false,
  height = 28,
  bg = "#1e1e2e",
  fg = "#6c7086",
  fg_active = "#cdd6f4",
}

-- Autostart — spitfire has no opinion on which frontend/shell you use.
-- Point this at whatever draws your bar/launcher/wallpaper/lockscreen: a
-- wlr-layer-shell-v1 client is all that's required (waybar, eww, a plain
-- swaybg + swaylock + wlogout combo, a Quickshell-based shell, ...).
spitfire.autostart({
"awww-daemon",
"/usr/share/quickshell/utumno/wallpaper/./set-wallpaper.sh",
"dunst",
"udiskie -a",
"qsd77 run -c utumno",
"pipewire",
"/usr/libexec/polkit-mate-authentication-agent-1",
"~/./.auto.sh",
})
