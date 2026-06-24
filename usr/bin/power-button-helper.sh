#!/usr/bin/env bash

export DBUS_SESSION_BUS_ADDRESS="unix:path=/run/user/32011/bus"

BRIGHTNESS_FILE="/sys/class/backlight/panel0-backlight/brightness"

saved_percent=$(gdbus call --session --dest org.gnome.SettingsDaemon.Power --object-path /org/gnome/SettingsDaemon/Power --method org.freedesktop.DBus.Properties.Get org.gnome.SettingsDaemon.Power.Screen Brightness | awk '{print $NF}' | tr -cd '0-9')

stdbuf -oL dbus-monitor --session "type='signal',interface='org.gnome.ScreenSaver',member='ActiveChanged'" | while read -r line; do
	if [[ "$line" == *"boolean false"* ]]; then
		# Wake up
		gdbus call --session --dest org.gnome.SettingsDaemon.Power --object-path /org/gnome/SettingsDaemon/Power --method org.freedesktop.DBus.Properties.Set org.gnome.SettingsDaemon.Power.Screen Brightness "<int32 $saved_percent>" >/dev/null 2>&1

	elif [[ "$line" == *"boolean true"* ]]; then
		# Sleep
		saved_percent=$(gdbus call --session --dest org.gnome.SettingsDaemon.Power --object-path /org/gnome/SettingsDaemon/Power --method org.freedesktop.DBus.Properties.Get org.gnome.SettingsDaemon.Power.Screen Brightness | awk '{print $NF}' | tr -cd '0-9')
	fi
done
