# Copyright (c) 2010 Aldo Cortesi
# Copyright (c) 2010, 2014 dequis
# Copyright (c) 2012 Randall Ma
# Copyright (c) 2012-2014 Tycho Andersen
# Copyright (c) 2012 Craig Barnes
# Copyright (c) 2013 horsik
# Copyright (c) 2013 Tao Sauvage
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.

from libqtile import bar, layout, qtile, widget, hook
from libqtile.backend.wayland import InputConfig
from libqtile.config import Click, Drag, Group, Key, Match, Screen, Rule
from libqtile.lazy import lazy
from libqtile.utils import guess_terminal
from qtile_extras.widget.decorations import GradientDecoration, BorderDecoration  # type: ignore
from qtile_extras.layout.decorations import RoundedCorners
from qtile_extras.resources import wallpapers
from qtile_extras import widget
import os
import colors
import subprocess
 
mod = "mod4"
terminal = "kitty"

@hook.subscribe.startup_once
def autostart():
    home = os.path.expanduser('~/.config/qtile/autostart.sh')
    subprocess.call(home)

keys = [
    # A list of available commands that can be bound to keys can be found
    # at https://docs.qtile.org/en/latest/manual/config/lazy.html
    # Switch between windows
    Key([mod], "h", lazy.layout.left(), desc="Move focus to left"),
    Key([mod], "l", lazy.layout.right(), desc="Move focus to right"),
    Key([mod], "j", lazy.layout.down(), desc="Move focus down"),
    Key([mod], "k", lazy.layout.up(), desc="Move focus up"),
    Key([mod], "space", lazy.layout.next(), desc="Move window focus to other window"),
    # Move windows between left/right columns or move up/down in current stack.
    # Moving out of range in Columns layout will create new column.
    Key([mod, "shift"], "h", lazy.layout.shuffle_left(), desc="Move window to the left"),
    Key([mod, "shift"], "l", lazy.layout.shuffle_right(), desc="Move window to the right"),
    Key([mod, "shift"], "j", lazy.layout.shuffle_down(), desc="Move window down"),
    Key([mod, "shift"], "k", lazy.layout.shuffle_up(), desc="Move window up"),
    # Grow windows. If current window is on the edge of screen and direction
    # will be to screen edge - window would shrink.
    Key([mod, "control"], "h", lazy.layout.grow_left(), desc="Grow window to the left"),
    Key([mod, "control"], "l", lazy.layout.grow_right(), desc="Grow window to the right"),
    Key([mod, "control"], "j", lazy.layout.grow_down(), desc="Grow window down"),
    Key([mod, "control"], "k", lazy.layout.grow_up(), desc="Grow window up"),
    Key([mod, "shift"], "n", lazy.layout.normalize(), desc="Reset all window sizes"),
    # Toggle between split and unsplit sides of stack.
    # Split = all windows displayed
    # Unsplit = 1 window displayed, like Max layout, but still with
    # multiple stack panes
    Key(
        [mod, "shift"],
        "Return",
        lazy.layout.toggle_split(),
        desc="Toggle between split and unsplit sides of stack",
    ),
    Key([mod], "Return", lazy.spawn(terminal), desc="Launch terminal"),
    # Toggle between different layouts as defined below
    Key([mod], "Tab", lazy.next_layout(), desc="Toggle between layouts"),
    Key([mod], "q", lazy.window.kill(), desc="Kill focused window"),
    Key(
        [mod],
        "f",
        lazy.window.toggle_fullscreen(),
        desc="Toggle fullscreen on the focused window",
    ),
    Key([mod], "t", lazy.window.toggle_floating(), desc="Toggle floating on the focused window"),
    Key([mod, "control"], "r", lazy.reload_config(), desc="Reload the config"),
    Key([mod, "control"], "q", lazy.shutdown(), desc="Shutdown Qtile"),
    Key([mod], "r", lazy.spawncmd(), desc="Spawn a command using a prompt widget"),
    Key([mod], "i", lazy.widget["keyboardlayout"].next_keyboard(), desc="Next keyboard layout."),

    Key([mod], "a", lazy.spawn("rofi -show drun"), desc="Rofi Menu"),
    Key([mod], "b", lazy.spawn("wswap-way"), desc="Swap Wallpaper"),
    Key([mod], "c", lazy.spawn("better-control"), desc="Control Panel"),
    Key([mod], "d", lazy.spawn("pcmanfm"), desc="Filemanager"),
    Key([mod], "m", lazy.spawn("geary"), desc="Web browser"),
    Key([mod], "n", lazy.spawn("nwggrid"), desc="NWG Launcher"),
    Key([mod], "x", lazy.spawn("rofi -show power-menu -modi power-menu:rofi-power-menu"), desc="Rofi PowerMenu"),
    Key([mod], "y", lazy.spawn("slock"), desc="screen locker"),
    Key([mod], "w", lazy.spawn("brave-browser-stable"), desc="Web browser"),
    Key([], "XF86AudioRaiseVolume",lazy.spawn("pactl set-sink-volume @DEFAULT_SINK@ +5%")),
    Key([], "XF86AudioLowerVolume",lazy.spawn("pactl set-sink-volume @DEFAULT_SINK@ -5%")),
    Key([], "XF86AudioMute",lazy.spawn("pactl set-sink-volume @DEFAULT_SINK@ toggle")),
    Key([], "XF86MonBrightnessUp", lazy.spawn("xbacklight -inc 5")),
    Key([], "XF86MonBrightnessDown", lazy.spawn("xbacklight -dec 5")),
]

# Add key bindings to switch VTs in Wayland.
# We can't check qtile.core.name in default config as it is loaded before qtile is started
# We therefore defer the check until the key binding is run by using .when(func=...)
for vt in range(1, 8):
    keys.append(
        Key(
            ["control", "mod1"],
            f"f{vt}",
            lazy.core.change_vt(vt).when(func=lambda: qtile.core.name == "wayland"),
            desc=f"Switch to VT{vt}",
        )
    )
workspaces = [
    {"name": " ", "key": "1", "matches": [Match(wm_class='kitty'), Match(wm_class='mousepad'), Match(wm_class='ranger'), Match(wm_class='geany')], "layout": "monadtall"},
    {"name": " ", "key": "2", "matches": [Match(wm_class='Firefox'), Match(wm_class='brave-browser-stable'), Match(wm_class='org.gnome.Evolution-alarm-notify.desktop'), Match(wm_class='transmission-gtk.desktop'), Match(wm_class='geary')], "layout": "max"},
    {"name": " ", "key": "3", "matches": [Match(wm_class='mpv'), Match(wm_class='deadbeef'),  Match(wm_class='cmus')], "layout": "monadtall"},
    {"name": " ", "key": "4", "matches": [Match(wm_class='abiword'), Match(wm_class='gimp,desktop'), Match(wm_class='Gnumeric')], "layout": "max"},
    {"name": " ", "key": "5", "matches": [Match(wm_class='telegram-desktop'), Match(wm_class='discord')], "layout": "monadtall"},
]


groups = []
for workspace in workspaces:
    matches = workspace["matches"] if "matches" in workspace else None
    layouts = workspace["layout"] if "layout" in workspace else None
    groups.append(Group(workspace["name"], matches=matches, layout=layouts))
    keys.append(Key([mod], workspace["key"], lazy.group[workspace["name"]].toscreen()))
    keys.append(Key([mod, "shift"], workspace["key"], lazy.window.togroup(workspace["name"])))

qtile_colors = colors.d77

layout_theme = {"border_width": 5, "border_focus": qtile_colors[33], "border_normal": qtile_colors[32], "margin": 5}

layouts = [
     #layout.Columns(border_focus_stack=["#4d235c", "#686714"]),
     layout.Bsp(**layout_theme),
     layout.Max(**layout_theme),
     layout.MonadTall(**layout_theme),
     layout.Tile(**layout_theme),
     #layout.Stack(num_stacks=2, **layout_theme), 
     #layout.Matrix(**layout_theme),
     #layout.MonadWide(**layout_theme),
     #layout.RatioTile(**layout_theme),
     #layout.TreeTab(**layout_theme),
     #layout.VerticalTile(**layout_theme),
     #layout.Zoomy(**layout_theme),
]

widget_defaults = dict(
    font="hack",
    fontsize=12,
    padding=3,
)

extension_defaults = widget_defaults.copy()

screens = [
    Screen(
	#wallpaper='~/Wallpaper/qte_triangles_rounded.png',
	wallpaper=wallpapers.WALLPAPER_TRIANGLES_ROUNDED,
    	wallpaper_mode='fill',        
	top=bar.Bar(
            [	
		widget.Image(filename='/usr/share/pixmaps/d77void.png', mouse_callbacks={'Button1': lazy.spawn('rofi -show drun')}),
		widget.CurrentLayoutIcon(scale=0.7),
                widget.CurrentLayout(),
                widget.GroupBox(
		highlight_method='block',
		rounded = True,
		inactive='9d8b8b'),
                widget.Prompt(),
                widget.WindowName(),
                widget.Chord(
                    chords_colors={
                        "launch": ("#ff0000", "#ffffff"),
                    },
                    name_transform=lambda name: name.upper(),
                ),
                # NB Systray is incompatible with Wayland, consider using StatusNotifier instead
		widget.Wttr(location={'Porto': 'Porto'}),
                widget.Clock(format=" %A, %d-%m-%Y %H:%M %p"),
		widget.Spacer(),
		#widget.StatusNotifier(),
		#widget.HDD(),
		widget.CPU(format=" {load_percent}%",
                mouse_callbacks={'Button1': lazy.spawn(terminal + ' --class floating_shell -e htop')}),
		widget.Memory(format="  {MemUsed:.0f}{mm}",interval=1.0,
                mouse_callbacks={'Button1': lazy.spawn(terminal + ' --class floating_shell -e htop')}),
		widget.Net(format='  {down:.0f}{down_suffix} ↓↑ {up:.0f}{up_suffix}',update_interval=1.0,
                mouse_callbacks={'Button1': lazy.spawn(terminal + ' --class floating_shell -e nmtui')}),
		widget.Volume(fmt="  {}",
                mouse_callbacks={'Button3': lazy.spawn('pavucontrol')}),
		widget.Battery(format = '  {percent:2.0%} {hour:d}:{min:02d}'),
		widget.KeyboardLayout(configured_keyboards = ["de deadtilde", "pt", "us"],font = "Hack",fontsize = "12",fmt = '  {}'),
		widget.CheckUpdates(distro = 'Void',no_update_string=' No updates',update_interval=600,
		mouse_callbacks={'Button1': lazy.spawn('qt-sudo xbps-install -Su -y')}),
		widget.TextBox(text=" ", fontsize = 12,
		mouse_callbacks={'Button1': lazy.spawn('rofi -show power-menu -modi power-menu:rofi-power-menu')}),
            ], 
            25,
	    background = "#11111b80",
            border_width=[0, 0, 5, 0],  # Draw top and bottom borders
            border_color=["ff00ff", "000000", "50fa7b", "000000"]  # Borders are magenta
        ),
        # You can uncomment this variable if you see that on X11 floating resize/moving is laggy
        # By default we handle these events delayed to already improve performance, however your system might still be struggling
        # This variable is set to None (no cap) by default, but you can set it to 60 to indicate that you limit it to 60 events per second
        # x11_drag_polling_rate = 60,
    ),
]

# Drag floating layouts.
mouse = [
    Drag([mod], "Button1", lazy.window.set_position_floating(), start=lazy.window.get_position()),
    Drag([mod], "Button3", lazy.window.set_size_floating(), start=lazy.window.get_size()),
    Click([mod], "Button2", lazy.window.bring_to_front()),
]

dgroups_key_binder = None
dgroups_app_rules = []  # type: list
follow_mouse_focus = True
bring_front_click = False
floats_kept_above = True
cursor_warp = False
floating_layout = layout.Floating(
    float_rules=[
        # Run the utility of `xprop` to see the wm class and name of an X client.
        *layout.Floating.default_float_rules,
        Match(wm_class="confirmreset"),  # gitk
        Match(wm_class="makebranch"),  # gitk
        Match(wm_class="maketag"),  # gitk
        Match(wm_class="ssh-askpass"),  # ssh-askpass
        Match(title="branchdialog"),  # gitk
        Match(title="pinentry"),  # GPG key password entry
    ]
)
auto_fullscreen = True
focus_on_window_activation = "smart"
reconfigure_screens = True

# If things like steam games want to auto-minimize themselves when losing
# focus, should we respect this or not?
auto_minimize = True

# When using the Wayland backend, this can be used to configure input devices.

wl_input_rules = {
    "type:touchpad": InputConfig(tap=True),
}

# xcursor theme (string or None) and size (integer) for Wayland backend
wl_xcursor_theme = None
wl_xcursor_size = 24

# XXX: Gasp! We're lying here. In fact, nobody really uses or cares about this
# string besides java UI toolkits; you can see several discussions on the
# mailing lists, GitHub issues, and other WM documentation that suggest setting
# this string if your java app doesn't work correctly. We may as well just lie
# and say that we're a working one by default.
#
# We choose LG3D to maximize irony: it is a 3D non-reparenting WM written in
# java that happens to be on java's whitelist.
wmname = "LG3D"
