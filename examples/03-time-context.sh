#!/usr/bin/env bash
hour=$(date +%H)
day=$(date +%A)

if [ "$hour" -lt 9 ]; then
  greeting="morning"
elif [ "$hour" -lt 12 ]; then
  greeting="late morning"
elif [ "$hour" -lt 17 ]; then
  greeting="afternoon"
else
  greeting="evening"
fi

printf '  🕐 %s, %s\n' "$day" "$greeting"
