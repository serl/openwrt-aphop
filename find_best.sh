#!/bin/sh

cd "$(dirname "$0")" || exit
# shellcheck source=config.example
. ./config

if [ $# -gt 0 ]; then
	ESSID="$1"
	ENCRYPTION="$2"
	if [ -z "$ESSID" ] || [ "$ESSID" = "-h" ]; then
		echo "USAGE: $0 [ESSID [ENCRYPTION]]"
		echo
		echo "ENCRYPTION in none, psk2. Defaults to none."
		exit
	fi
fi

BLACKLIST="$(dirname "$0")/blacklist"

if [ "$ENCRYPTION" = "psk2" ]; then
	SCAN_ENCRYPTION="WPA2"
else
	SCAN_ENCRYPTION="none"
fi

wifi_scan_raw="$(mktemp)"
echo "Scanning for $ESSID access points..." >&2
iwinfo "$SCANNING_IFACE" scan | sed -e 's@: @:@g' > "$wifi_scan_raw"  # real scan here, sed will remove the spaces after the :
wifi_scan_results="$(mktemp)"
echo -n > "$wifi_scan_results"

echo -n "Parsing results... " >&2
found_count=0
while IFS='' read -r line; do
	line=$(echo $line)  # remove leading whitespace (as no quotes)
	case "$line" in
		"")
			encryption_without=$(printf '%s' "$encryption" | sed -e "s/$SCAN_ENCRYPTION//g")
			if [ "$essid" = '"'"$ESSID"'"' ] && [ "$encryption" != "$encryption_without" ]  && [ "$quality" -gt "${QUALITY_MIN:-10}" ]; then
				if [ ! -f "$BLACKLIST" ] || ! grep -q "$mac" "$BLACKLIST"; then
					echo "$quality|$mac|$channel" >> "$wifi_scan_results"
					found_count=$((found_count + 1))
				fi
			fi
			;;
		Cell*)
			mac=$(echo "$line" | cut -d':' -f2-) essid='' channel='' quality='' encryption=''
			;;
		ESSID*)
			essid=$(echo "$line" | cut -d':' -f2-)
			;;
		Mode*)
			channel=$(echo "$line" | cut -d':' -f3)
			;;
		Signal*)
			quality=$(echo "$line" | cut -d':' -f3 | cut -d'/' -f1)
			if [ "$quality" -le 9 ]; then
				quality="0$quality"
			fi
			;;
		Encryption*)
			encryption=$(echo "$line" | cut -d':' -f2-)
			;;
	esac
done < "$wifi_scan_raw"

echo "$found_count access points found." >&2
echo "strength|mac|channel" >&2
sort "$wifi_scan_results" >&2

if [ "$found_count" -gt 0 ]; then
	echo "Picking the best one by strenght..." >&2
	sort "$wifi_scan_results" | tail -n 1 | cut -d'|' -f2-  # order by quality, take the best and then remove the quality
fi

rm "$wifi_scan_raw" "$wifi_scan_results"
