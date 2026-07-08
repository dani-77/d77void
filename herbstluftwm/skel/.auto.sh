yad --text-info --filename="$HOME/README.md" --width=0600 --height=450 --title="README.md" --button="Don't show this again:1" --button="close:0"

if [ $? -eq 1 ]; then
	sed -i '/\.auto\.sh/d' "$HOME/.config/herbstluftwm/autostart"
fi
