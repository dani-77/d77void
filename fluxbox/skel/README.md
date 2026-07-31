## Hello

Thank you for trying d77void Fluxbox edition.

To install use Calamares from the menu.

In case it won't start, open a terminal and type:

```
sudo -E calamares
```

## 1st run:

## Conky

To tweak conky, edit .conkyrc; 

It is no longer needed an weathermap API to retrieve weather info; I changed the method.

Probably you will need to change the wifi card device name to display properly the info.
Check wich device name this way:

```
ip a
```
The one with w??? is the correct name. Change it this way:

```
sed -i 's|wlp21s0|w???|g' .conkyrc
```

In case battery is not working properly, swap BAT0 to BAT1 this way; open a terminal and type:

```
sed -i 's|BAT0|BAT1|' .conkyrc
```

## Fluxbox Variables

To edit and customize your fluxbox variables, like menu, wallpaper and startup applications, go to ~/.fluxbox/ and edit the files in there to fit your needs.

## Keybinds

ctrl + alt + del -> logout

alt + shift + return -> terminal

alt + b -> swap wallpaper

alt + d -> rofi

alt + e -> editor

alt + f -> file manager

alt + j -> menu

alt + l -> lock

alt + m -> mail

alt + p -> print screen

alt + r -> run

alt + w -> web browser

alt + x -> power menu

Have fun!
