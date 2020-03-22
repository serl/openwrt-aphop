#!/bin/sh

cd "$(dirname "$0")" || exit
# shellcheck source=config.example
. ./config

LED_OK_DEV="/sys/class/leds/$LED_OK/brightness"
LED_ERROR_DEV="/sys/class/leds/$LED_ERROR/brightness"

# find out whether we need to find a new hotspot or not.
check="false"
if [ "$1" = "force" ]; then
	check="true"
else
	network_interface_name="$(uci get wireless.@wifi-iface[$WIFI_IFACE_ID].network)"
	network_status_json="$(ubus -S call network.interface.$network_interface_name status)"
	up_substring='"up":true'
	if [ "${network_status_json/$up_substring/}" = "$network_status_json" ]; then
		echo "Not connected to $ESSID at the moment."
		check="true"
	else
		echo "Healty."
	fi
fi

# edit the configuration, if needed, then restart the wifi.
if [ "$check" = "true" ]; then
	bssid_channel=$(./find_best.sh "$ESSID" "$ENCRYPTION")
	if [ -z "$bssid_channel" ]; then
		echo "Unable to find a $ESSID hotspot."
		if [ "$(uci get wireless.@wifi-iface[$WIFI_IFACE_ID].disabled)" = "0" ]; then
			echo "Disabling wireless client."
			uci set "wireless.@wifi-iface[$WIFI_IFACE_ID].disabled=1"
			uci commit wireless  # commit changes
			echo "Restarting wifi."
			wifi reload
			[ -f "$LED_OK_DEV" ] && echo 0 > "$LED_OK_DEV"
			[ -f "$LED_ERROR_DEV" ] && echo 1 > "$LED_ERROR_DEV"
		fi
		exit 1
	fi
	bssid="$(echo "$bssid_channel" | cut -d'|' -f1)"
	channel="$(echo "$bssid_channel" | cut -d'|' -f2)"
	echo "Changing configuration to connect to $ESSID hotspot $bssid at channel $channel."
	radio_name="$(uci get wireless.@wifi-iface[$WIFI_IFACE_ID].device)"
	uci set "wireless.$radio_name.channel=$channel"
	uci set "wireless.@wifi-iface[$WIFI_IFACE_ID].ssid=$ESSID"
	uci set "wireless.@wifi-iface[$WIFI_IFACE_ID].encryption=$ENCRYPTION"
	uci set "wireless.@wifi-iface[$WIFI_IFACE_ID].bssid=$bssid"
	uci set "wireless.@wifi-iface[$WIFI_IFACE_ID].disabled=0"
	uci commit wireless  # commit changes
	echo "Restarting wifi."
	wifi reload  # restart wifi
fi
[ -f "$LED_OK_DEV" ] && echo 1 > "$LED_OK_DEV"
[ -f "$LED_ERROR_DEV" ] && echo 0 > "$LED_ERROR_DEV"
