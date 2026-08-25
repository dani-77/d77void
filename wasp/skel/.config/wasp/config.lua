-- wasp — example config, and the default until you copy it:
--   mkdir -p ~/.config/wasp && cp examples/config.lua ~/.config/wasp/config.lua
--
-- Appearance, terminal/menu, keybindings, keyboard, gaps, monitors/output
-- scale, autostart, named scratchpads, window rules, and open/close/move/
-- tag-switch animations are all wired up here -- and your workspaces show
-- up in any ext-workspace-v1-aware bar/shell for free, no config needed
-- for that part.

wasp = {}

wasp.border = {
  width = 5,
  focus = "#7aa2f7",  -- focused window border
  normal = "#414868", -- unfocused window border
  radius = 12,
}
-- Rounded corners' blurrier sibling -- background/wallpaper blur (behind
-- everything) and per-window blur-behind (through a translucent window's
-- own transparency), both via scenefx. enable = false (the default)
-- reproduces today's exact rendering, no blur node ever created.
-- radius/passes/noise/brightness/contrast/saturation are scenefx's own
-- global look parameters (same names as wlr_scene_set_blur_data()'s
-- arguments) -- not per-window, one look for the whole session. Picked
-- up live on hot-reload for any blur node that already exists;
-- enable itself flipping on/off only affects windows mapped *after* the
-- reload (see NOTES.md item 7's own note on this). Global only for now
-- -- no wasp.rules override yet, same "one global on/off" scoping
-- wasp.animations started with too.
wasp.blur = {
  enable = true,
  radius = 5,
  passes = 3,
  noise = 0.02,
  brightness = 0.9,
  contrast = 0.9,
  saturation = 1.1,
}

-- Gaps between/around tiled windows (tile/monocle/dwindle; floating is
-- untouched either way) — pixels. `inner` splits between two adjacent
-- windows, `outer` is the margin against the monitor's usable edges.
-- `smart`, if true, drops the outer gap when there's only one tiled window
-- on screen (same idea as spitfire's -- there it's implicit; here it's
-- opt-in since dwl's classic look has always kept edge gaps at 0).
wasp.gaps = {
  inner = 10,
  outer = 10,
  smart = true,
}

-- MangoWC-style window animations -- open/close/move/tag-switch tweening
-- on top of the wlr_scene graph (see NOTES.md item 3). `enable = false`
-- (the default) reproduces the original instant behavior bit-for-bit --
-- nothing else below matters until it's true. Durations are milliseconds.
-- `type_open`/`type_close`: "fade" (opacity only), "zoom" (shrink/grow
-- around center by `zoom_ratio`, also fades), or "none". `tag_direction`
-- is which monitor edge tag-switches slide to/from (same edge both ways):
-- "left" | "right" | "top" | "bottom". The curve_* fields are CSS
-- cubic-bezier()-style control points {x1, y1, x2, y2} (endpoints pinned
-- at (0,0)/(1,1)) -- see e.g. https://cubic-bezier.com to pick one; all
-- four default to the same gentle ease-out curve. Picked up live on
-- hot-reload (mod+shift+r), same as gaps -- no restart needed.
wasp.animations = {
  enable = true,
  duration_move = 200,
  duration_open = 200,
  duration_close = 150,
  duration_tag = 200,
  type_open = "zoom",
  type_close = "zoom",
  zoom_ratio = 0.8,
  fade_from_opacity = 0.0,
  tag_direction = "right",
  curve_move  = { 0.25, 0.1, 0.25, 1.0 },
  curve_open  = { 0.25, 0.1, 0.25, 1.0 },
  curve_close = { 0.25, 0.1, 0.25, 1.0 },
  curve_tag   = { 0.25, 0.1, 0.25, 1.0 },
}

-- Per-output rules -- mfact/nmaster/layout starting values, output scale,
-- rotation, and layout position. `name` matched as a substring against the
-- output's own name (as in `wlr-randr`/the log at startup); omit it (or
-- use "" / nil) for a fallback rule that matches whatever didn't match an
-- earlier, more specific one -- a monitor uses the *first* rule that
-- matches, not every one that does. `transform` is one of "normal" | "90"
-- | "180" | "270" | "flipped" | "flipped-90" | "flipped-180" |
-- "flipped-270". `x`/`y` are layout position in pixels; -1 lets wlroots
-- auto-place it (the common case, and the default if omitted).
--
-- `scale` here is applied right at startup -- set it to whatever you
-- actually want and wasp starts already scaled, no need to press
-- mod+shift+p every session to get back to where you left off (that's
-- for live adjustment/experimenting, not a substitute for just setting
-- the value you want here). It's also the one field that's live --
-- see the "setscale" action below and the reload note near the bottom
-- of this file for what reload() does and doesn't re-apply here.
wasp.monitors = {
  -- { name = "eDP-1", scale = 1.25 }, -- example: a HiDPI laptop panel
  { mfact = 0.55, nmaster = 1, scale = 1, layout = "tile", x = -1, y = -1 },
}

-- Keyboard layout (xkbcommon RMLVO fields) and repeat speed — same table
-- shape as spitfire.keyboard. Empty/omitted layout/variant/model/
-- options/rules mean "let xkbcommon pick its own default" (in practice
-- "us"). repeat_rate is repeats/second, repeat_delay is ms held before the
-- first repeat -- if typing ever feels like it drops in doubled letters,
-- raise repeat_delay rather than assuming a bug.
wasp.keyboard = {
  layout = "us",
  variant = "",
  model = "",
  options = "", -- e.g. "ctrl:nocaps"
  repeat_rate = 25,
  repeat_delay = 600,
}

wasp.bar = {
  enable = false,
  top = true,
  layout = "tln|s", -- t=tags l=layout-symbol n=window-name s=status, | splits left/right
}

wasp.background = "#11111bff"

-- Agnostic launchers: whatever's actually installed. Any argv works, e.g.
-- {"alacritty", "-e", "tmux"} or {"foot"} if you switch terminals later.
wasp.terminal = { "alacritty" }
wasp.menu = { "wmenu-run" }

-- What "mod" means below. One of "alt" | "ctrl" | "super" | "shift".
-- Alt, not Super -- Super is used bare by the D77 bindings just below, so
-- "mod" needs to be a different key to avoid colliding with those.
wasp.modkey = "alt"

-- Autostart -- one argv array per program, run once (fork+execvp, no
-- shell) right after startup, killed on exit. Uncomment/add whatever you
-- actually want running -- wasp has no opinion on wallpaper/idle/notifier
-- daemons etc., same as upstream dwl.
wasp.autostart = {
{ "awww-daemon" },
{ "/usr/share/quickshell/utumno/wallpaper/./set-wallpaper.sh" },
{ "dunst" },
{ "udiskie", "-a" },
{ "pipewire" },
{ "sh", "-c", "qsd77 run -c utumno" },
{ "/usr/libexec/polkit-mate-authentication-agent-1" },
{ "sh", "-c", "~/./.auto.sh" },
}

-- Named scratchpads -- a hidden, toggleable floating window per slot.
-- Toggling a slot with nothing running yet spawns `cmd`; toggling it again
-- (from anywhere) hides/shows the same window rather than killing and
-- respawning it. `app_id` is what wasp matches the freshly-spawned window
-- against to claim it as this slot's (defaults to `name` -- set it
-- explicitly if `cmd` doesn't already open with a matching --class/
-- --app-id). `w`/`h` are the fraction of the monitor's usable area it's
-- centered and sized to when shown (default 0.6 each). Bound via the
-- "toggle-scratchpad" action below, name = <slot's name>.
--
-- A scratchpad terminal needs its own app_id, distinct from an ordinary
-- one, so wasp can tell them apart -- terminal_with() below builds that
-- on top of wasp.terminal (whatever it's set to above) instead of
-- hardcoding a terminal here too. Assumes a --class-style flag
-- (alacritty/kitty/wezterm); foot uses -a instead -- swap if that's yours.
local function terminal_with(...)
  local argv = {}
  for i, a in ipairs(wasp.terminal) do argv[i] = a end
  for _, a in ipairs({ ... }) do argv[#argv + 1] = a end
  return argv
end

wasp.scratchpad = {
  { name = "term", cmd = terminal_with("--class", "scratch-term"),
    app_id = "scratch-term", w = 0.6, h = 0.6 },
}

-- Window rules -- placement for specific apps, matched by app_id/title
-- (substring match against the client's own, either field omittable).
-- `tags` (1-9) sends it straight to a workspace; `floating` takes it out
-- of the tiling layout; `monitor` (0-based index) forces which output it
-- opens on; `center` re-centers a floating window at its own requested
-- size instead of wherever it happened to want to place itself (dwl, like
-- most dwm-family compositors, otherwise just honors whatever position
-- the app itself asked for -- often the top-left corner, since plenty of
-- apps don't bother asking for anything better). A client matching more
-- than one rule gets every match's `tags` combined, but only the *last*
-- match's `floating`/`monitor`/`center`. Applied once, when a window is
-- created -- editing `wasp.rules` and reloading affects the *next* window
-- that app opens, not ones already on screen.
--
-- A given app's app_id isn't always as fixed as it looks -- some GTK/GLib
-- apps report their prgname most of the time but fall back to their raw
-- (usually reverse-DNS) GApplication id instead if D-Bus single-instance
-- registration fails for that particular run (e.g. no
-- DBUS_SESSION_BUS_ADDRESS). If a rule that used to work suddenly stops
-- matching, that's worth checking (WAYLAND_DEBUG=1 <app> 2>&1 | grep
-- set_app_id) before assuming wasp broke -- and it's fine to list the
-- same app twice, once per app_id it's been seen using, with identical
-- fields.
wasp.rules = {
  -- { app_id = "org.gimp.GIMP", floating = true },
  -- { app_id = "firefox", tags = 9 },
{ app_id = "d77run", floating = true, center = true },
{ app_id = "dev.d77.gmrun-rejuvenated", floating = true, center = true },
{ app_id = "qt-sudo", floating = true, center = true },
}

-- Keybindings ----------------------------------------------------------
-- Each entry: { mods = {...}, key = "<xkb keysym name>", action = "...",
--               <action-specific fields> }
--
-- `key` accepts anything libxkbcommon knows the name of: letters/digits
-- ("j", "1"), symbols ("comma", "exclam"), named keys ("Return", "Tab",
-- "space"), function/media keys ("F1", "XF86AudioRaiseVolume"), arrows
-- ("Left"/"Right"/"Up"/"Down"), and so on.
--
-- Actions and their fields:
--   spawn            cmd = {argv...}       run an arbitrary command
--   spawn-terminal    (none)               run wasp.terminal
--   spawn-menu        (none)               run wasp.menu
--   focusstack        dir = 1 | -1          next/prev window in stack
--   movestack         dir = 1 | -1          swap the focused window's own position with the next/prev one
--   zoom              (none)                swap the focused window into/out of the master area
--   incnmaster        dir = 1 | -1          grow/shrink the master area's window count
--   setmfact          delta = <float>       grow/shrink the master area's size (+/-)
--   view              tag = 1..9 | "all" (omit = toggle back)   switch workspace
--   viewshift         dir = 1 | -1          switch to next/previous workspace (wraps)
--   toggleview        tag = 1..9                                 also show workspace
--   tag               tag = 1..9 | "all" (omit = toggle back)   move focused window to workspace
--   toggletag         tag = 1..9                                 also tag focused window with workspace
--   focusmon          dir = "left" | "right"            focus other monitor
--   tagmon            dir = "left" | "right"            move focused window to other monitor
--   setlayout         layout = "tile"|"floating"|"monocle"|"dwindle" (omit to cycle)
--   setscale          delta = <float>       grow/shrink the focused monitor's output scale (+/-)
--   togglefloating    (none)
--   togglefullscreen  (none)
--   togglebar         (none)
--   killclient        (none)
--   quit              (none)
--   chvt              vt = <number>         switch to a different virtual terminal
--   moveresizekb      dx = dy = dw = dh = <pixels>   nudge/resize the focused floating window
--   reload            (none)                re-read config.lua live -- see the note above wasp.autostart below for what this does/doesn't cover
--   toggle-scratchpad name = "<slot name>"   spawn/show/hide a wasp.scratchpad slot -- see above
wasp.keys = {}
local keys = wasp.keys

local function bind(mods, key, action, fields)
  fields = fields or {}
  fields.mods, fields.key, fields.action = mods, key, action
  keys[#keys + 1] = fields
end

-- Launchers
bind({ "mod", "shift" }, "Return", "spawn-terminal")
bind({ "mod" },          "p",      "spawn-menu")
-- A second launcher, if you use one alongside wasp.menu -- "d77run" here
-- is just what this machine has (see ~/Projectos/d77run); swap the cmd
-- for whatever you actually run. A different modifier than "mod" (here
-- "super", i.e. the Logo/Windows key) so it doesn't compete with any
-- mod+<key> binding you'd rather keep where it already is -- any mod name
-- works standalone like this, not just as part of "mod".

	-- D77 --
bind({ "super" }, "space", "spawn", { cmd = { "sh", "-c", "qsd77 -c utumno launcher" } })
bind({ "super" }, "a", "spawn", { cmd = { "sh", "-c", "qsd77 -c utumno ollama" } })
bind({ "super" }, "t", "spawn", { cmd = { "sh", "-c", "qsd77 -c utumno locker" } })
bind({ "super" }, "x", "spawn", { cmd = { "sh", "-c", "qsd77 -c utumno session" } })
bind({ "super" }, "y", "spawn", { cmd = { "sh", "-c", "qsd77 -c utumno wallpaper" } })

bind({ "super" }, "r", "spawn", { cmd = { "d77run" } })
	-- D77 --

-- Media keys — dedicated hardware keys, so no modifier needed (they can't
-- collide with anything text-related; `mods = {}` means "bare key").
-- Via ALSA (amixer); swap "Master" for whatever `amixer scontrols` lists
-- on your system if it differs, or for
-- "wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%+-/mute-toggle" (PipeWire) /
-- "pactl set-sink-volume/set-sink-mute @DEFAULT_SINK@ ..." (PulseAudio via
-- pactl) if ALSA isn't what your system actually mixes through.
bind({}, "XF86AudioRaiseVolume", "spawn", { cmd = { "amixer", "-q", "set", "Master", "5%+" } })
bind({}, "XF86AudioLowerVolume", "spawn", { cmd = { "amixer", "-q", "set", "Master", "5%-" } })
bind({}, "XF86AudioMute",        "spawn", { cmd = { "amixer", "-q", "set", "Master", "toggle" } })

-- Screenshot (grim, wlr-screencopy-based) -- Print Screen, whole output(s),
-- saved to ~/screenshot-<timestamp>.png. Wrapped in "sh -c" because spawn()
-- execvp()s directly (no shell), so "~" and "$(date ...)" need something to
-- expand them. Region-select instead of full-screen needs `slurp` too (not
-- installed on this machine) -- swap the cmd for:
-- { "sh", "-c", 'grim -g "$(slurp)" ~/screenshot-$(date +%Y%m%d-%H%M%S).png' }
bind({}, "Print", "spawn", { cmd = { "sh", "-c", "grim ~/screenshot-$(date +%Y%m%d-%H%M%S).png" } })

-- Window navigation
bind({ "mod" }, "j",    "focusstack", { dir = 1 })
bind({ "mod" }, "k",    "focusstack", { dir = -1 })
bind({ "mod" }, "Tab",  "view") -- go back to the previously selected tags
bind({ "mod" }, "Return", "zoom")  -- swap focused window into/out of master
-- Swap the focused window's own position in the stack (not just where
-- focus goes, like focusstack above) with the next/previous one.
bind({ "mod", "shift" }, "j", "movestack", { dir = 1 })
bind({ "mod", "shift" }, "k", "movestack", { dir = -1 })

-- Scratchpad -- pairs with the wasp.scratchpad slot above; uncomment both
-- together. Backtick/grave is the common drop-down-terminal convention.
bind({ "mod" }, "comma", "toggle-scratchpad", { name = "term" })

-- Resize
bind({ "mod" }, "i", "incnmaster", { dir = 1 })
bind({ "mod" }, "d", "incnmaster", { dir = -1 })
bind({ "mod" }, "h", "setmfact",   { delta = -0.05 })
bind({ "mod" }, "l", "setmfact",   { delta = 0.05 })
bind({ "mod" },          "Left",  "moveresizekb", { dx = -40 })
bind({ "mod" },          "Right", "moveresizekb", { dx = 40 })
bind({ "mod" },          "Up",    "moveresizekb", { dy = -40 })
bind({ "mod" },          "Down",  "moveresizekb", { dy = 40 })
bind({ "mod", "shift" }, "Left",  "moveresizekb", { dw = -40 })
bind({ "mod", "shift" }, "Right", "moveresizekb", { dw = 40 })
bind({ "mod", "shift" }, "Up",    "moveresizekb", { dh = -40 })
bind({ "mod", "shift" }, "Down",  "moveresizekb", { dh = 40 })

-- Layouts
bind({ "mod" }, "t", "setlayout", { layout = "tile" })
bind({ "mod" }, "f", "setlayout", { layout = "floating" })
bind({ "mod" }, "m", "setlayout", { layout = "monocle" })
bind({ "mod" }, "r", "setlayout", { layout = "dwindle" })
bind({ "mod" }, "space", "setlayout") -- cycle
bind({ "mod", "shift" }, "space", "togglefloating")
bind({ "mod" }, "e", "togglefullscreen")
bind({ "mod" }, "b", "togglebar")

-- Monitor navigation
bind({ "mod" },          "comma",  "focusmon", { dir = "left" })
bind({ "mod" },          "period", "focusmon", { dir = "right" })
bind({ "mod", "shift" }, "less",    "tagmon",   { dir = "left" })
bind({ "mod", "shift" }, "greater", "tagmon",   { dir = "right" })

-- Live output-scale inc/dec on the focused monitor -- same Mod+Shift+P/M
-- as spitfire, so muscle memory carries over between the two. `delta` is
-- relative (added to the current scale, not an absolute value); clamped
-- to a sane 0.25-4.0 range in dwl.c.
bind({ "mod", "shift" }, "p", "setscale", { delta = 0.25 })
bind({ "mod", "shift" }, "m", "setscale", { delta = -0.25 })

-- Workspaces (tags) 1-9: switch/also-show/move-window/also-tag-window
local tagkeys = { "1", "2", "3", "4", "5", "6", "7", "8", "9" }
-- xkb keysym names for Shift+1..9 on *this* layout (wasp.keyboard.layout =
-- "us" above) -- these are per-layout, not universal: change this array
-- to match if you ever change wasp.keyboard.layout -- `xkbcli
-- compile-keymap` or a quick WAYLAND_DEBUG=1 <anything> 2>&1 | grep
-- keysym while pressing Shift+<digit> shows what your layout actually
-- produces.
local tagshiftkeys = { "exclam", "at", "numbersign", "dollar", "percent",
                        "asciicircum", "ampersand", "asterisk", "parenleft" }
for i, key in ipairs(tagkeys) do
  bind({ "mod" },                     key,              "view",       { tag = i })
  bind({ "mod", "ctrl" },             key,              "toggleview", { tag = i })
  bind({ "mod", "shift" },            tagshiftkeys[i],  "tag",        { tag = i })
  bind({ "mod", "ctrl", "shift" },    tagshiftkeys[i],  "toggletag",  { tag = i })
end
bind({ "mod" },          "0",           "view", { tag = "all" })
bind({ "mod", "shift" }, "parenright",  "tag",  { tag = "all" })

-- Window/session control
bind({ "mod", "shift" }, "c", "killclient")
bind({ "mod", "shift" }, "q", "quit")

-- Hot-reload -- re-reads this file and re-applies gaps, wasp.animations
-- (including re-baking the curve_* easing tables), the bar's
-- visibility/position/colors, every window's border color, the
-- background, keyboard layout/repeat speed, wasp.monitors' `scale` (only
-- that one field -- mfact/nmaster/layout/transform/x/y stay startup-time
-- only, same as they always were), and keybindings themselves, all live,
-- no restart. Border *width* on already-open windows and wasp.autostart
-- are the two things that still need a restart to pick up (autostart
-- deliberately only ever runs once, at real startup -- see NOTES.md;
-- otherwise every reload would relaunch everything in it).
bind({ "mod", "shift" }, "r", "reload")

-- VT switching (Ctrl-Alt-Fx) and Ctrl-Alt-Backspace, same as upstream dwl
for vt = 1, 12 do
  bind({ "ctrl", "alt" }, "XF86Switch_VT_" .. vt, "chvt", { vt = vt })
end
bind({ "ctrl", "alt" }, "Terminate_Server", "quit")

-- Touchpad gestures --------------------------------------------------
-- { fingers = <count, omit/0 = any>, direction = "left"|"right"|"up"|"down",
--   action = "...", <action-specific fields> } -- same action table as
-- wasp.keys above (spawn/view/tag/focusmon/... all work here too, with the
-- same fields). `direction` is classified from the swipe's dominant axis
-- once it ends, so a mostly-horizontal swipe always resolves to left/right
-- even if it wasn't perfectly straight. Only swipe gestures exist right now
-- (no pinch/hold) -- see NOTES.md item 8.
wasp.gestures = {
  -- 3-finger left/right cycles focus between windows (same as mod+j/k).
  { fingers = 3, direction = "left",  action = "focusstack", dir = -1 },
  { fingers = 3, direction = "right", action = "focusstack", dir = 1 },
  { fingers = 4, direction = "up",    action = "togglefullscreen" },
  -- 4-finger left/right -- next/previous workspace, wrapping.
  { fingers = 4, direction = "left",  action = "viewshift", dir = -1 },
  { fingers = 4, direction = "right", action = "viewshift", dir = 1 },
}
