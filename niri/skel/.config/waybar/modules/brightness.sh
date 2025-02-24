#!/usr/bin/env bash

current_rel() {
    brightnessctl i | grep -Po "(?<=\().*?(?=\%)"
}
max=$(brightnessctl m)
factor=3
brightness_step=$((max * factor / 100 < 1 ? 1 : max * factor / 100))
icon_low="notification-display-brightness-low"
icon_high="notification-display-brightness-full"
current_abs=$(brightnessctl g)

case $1'' in
    '') ;;
    'down')
        # if current value <= 3% and absolute value != 1, set brightness to absolute 1
        if [ "$current_abs" -le "$((factor * max / 100))" ] && [ "$current_abs" -gt 0 ] && [ "$current_abs" -ne 1 ]; then
            brightnessctl s 1
            icon=$icon_low
        else
            brightnessctl s $(("$current_abs" - "$brightness_step"))
            icon=$icon_low
        fi
        ;;
    'up')
        brightnessctl s $(("$current_abs" + "$brightness_step"))
        icon=$icon_high
        ;;
esac

brightness_percentage=$(current_rel)
notify-send -i "$icon" "Brightness Level" "Backlight is at $brightness_percentage%"
