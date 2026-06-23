#!/usr/bin/env bash

export DBUS_SESSION_BUS_ADDRESS="unix:path=/run/user/32011/bus"

CACHE_FILE="/home/droidian/.cache/backlight-brightness"
#CACHE_FILE="/tmp/backlight-brightness"
BRIGHTNESS_FILE="/sys/class/backlight/panel0-backlight/brightness"
MAX_BRIGHTNESS_FILE="/sys/class/backlight/panel0-backlight/max_brightness"
MIN_BRIGHTNESS=45
DEFAULT_BRIGHTNESS=500

mkdir -p /home/droidian/.cache

saved_brightness=$DEFAULT_BRIGHTNESS
val=$(cat "$CACHE_FILE" 2>/dev/null)
if [[ "$val" -ge "$MIN_BRIGHTNESS" ]] 2>/dev/null; then
	saved_brightness=$val
fi

stdbuf -oL dbus-monitor --session "type='signal',interface='org.gnome.ScreenSaver',member='ActiveChanged'" | while read -r line; do
	if [[ "$line" == *"boolean false"* ]]; then
		echo "$saved_brightness" > "$BRIGHTNESS_FILE"

	elif [[ "$line" == *"boolean true"* ]]; then
		gsd_power_percentage=$(gdbus call --session --dest org.gnome.SettingsDaemon.Power --object-path /org/gnome/SettingsDaemon/Power --method org.freedesktop.DBus.Properties.Get org.gnome.SettingsDaemon.Power.Screen Brightness | awk '{print $NF}' | tr -cd '0-9')
		
		if [[ "$gsd_power_percentage" -gt 0 ]] 2>/dev/null; then
			max_backlight=$(cat "$MAX_BRIGHTNESS_FILE")
			
			saved_brightness=$(( (gsd_power_percentage * max_backlight) / 100 ))
			
			if [[ "$saved_brightness" -ge "$MIN_BRIGHTNESS" ]] 2>/dev/null; then
				echo "$saved_brightness" > "$CACHE_FILE"
			fi
		fi
	fi
done
