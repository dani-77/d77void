Hello
Thank you for trying d77void.

To run the installer just open a terminal and type:

```
sudo d77void-installer
```

Note: 
To maintain the configuration of the live iso, during install, choose local instead of network install.

During install, add your user to the storage group. That way udiskie will automount disks.

# NEWS

Now Calamares installer is available making the install process even simpler.

I would like to thank Calamares team, Kevin Figueroa (Cereus Linux) and johna1 (F-Void Linux) for all the work done and guidance.

I would like to express my gratitude and say a big thank you to Rúben Gomez (Youtube channel Ruben_&_Linux_:~) for all the encouragement.

To install with Calamares:

```
su

calamares
```

# 1st run:

## Conky

To tweak conky, edit .conkyrc; 

To get weather running on it, you will need to register for an API at openweathermap and link it in ~/.config/conky/bunsenweather.sh and change local to be able to have weather running on it with your city instead of mine.

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

# Keybinds

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
