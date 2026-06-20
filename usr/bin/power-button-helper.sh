#!/usr/bin/env bash

export DBUS_SESSION_BUS_ADDRESS="unix:path=/run/user/32011/bus"

CACHE_FILE="/home/droidian/.cache/backlight-brightness"
#CACHE_FILE="/tmp/backlight-brightness"
BRIGHTNESS_FILE="/sys/class/backlight/panel0-backlight/brightness"
MIN_BRIGHTNESS=45
DEFAULT_BRIGHTNESS=500

saved_brightness=$DEFAULT_BRIGHTNESS
if [ -f "$CACHE_FILE" ]; then
	val=$(cat "$CACHE_FILE")
	if [[ "$val" =~ ^[0-9]+$ ]] && [ "$val" -ge "$MIN_BRIGHTNESS" ]; then
		saved_brightness=$val
	fi
fi

stdbuf -oL dbus-monitor --session "type='signal',interface='org.gnome.ScreenSaver',member='ActiveChanged'" | while read -r line; do
	if [[ "$line" == *"boolean false"* ]]; then
		echo "$saved_brightness" > "$BRIGHTNESS_FILE" 2>/dev/null
        elif [[ "$line" == *"boolean true"* ]]; then
		if [ -f "$BRIGHTNESS_FILE" ]; then
			val=$(cat "$BRIGHTNESS_FILE")
			if [[ "$val" =~ ^[0-9]+$ ]] && [ "$val" -ge "$MIN_BRIGHTNESS" ]; then
				saved_brightness=$val
				echo "$saved_brightness" > "$CACHE_FILE" 2>/dev/null
			fi
		fi
	fi
done
