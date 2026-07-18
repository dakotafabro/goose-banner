#!/usr/bin/env bash
reminders_file="${GOOSE_REMINDERS_FILE:-$HOME/.goose-reminders.txt}"
[ -f "$reminders_file" ] || exit 0

count=$(wc -l < "$reminders_file" | tr -d ' ')
[ "$count" = "0" ] && exit 0

printf '  📋 %d reminder(s):\n' "$count"
while IFS= read -r line; do
  [ -n "$line" ] && printf '  📋  * %s\n' "$line"
done < "$reminders_file"
