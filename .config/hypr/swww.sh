#! /bin/bash

currenttime=$(date +%H:%M)
if [[ "$currenttime" > "20:00" ]] || [[ "$currenttime" < "07:00" ]]; then
    swww img ~/.config/hypr/night.gif
else
    swww img ~/.config/hypr/day.gif
fi
