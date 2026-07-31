## Hello

Thank you for trying d77void Openbox edition.

To install use Calamares from the menu.

In case it won't start, open a terminal and type:

```
sudo -E calamares
```

## 1st run:

## d77-welcome

Don't forget to run the d77-welcome script; it will help you in several things; on first run after install I suggest 
the install of d77void repository files and I strongly advise you to remove calamares with the helper on d77-welcome.

## Conky

To tweak conky, edit .conkyrc; 

### Weather

No longer needed to update weather api; I changed the method to receive and parse weather info.

### Wifi

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
sed -i 's|BAT0|BAT1|g' .conkyrc
```

## Keybinds

alt + shift + return -> terminal

alt + b -> swap wallpaper

alt + d -> rofi menu

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
