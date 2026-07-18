#!/usr/bin/env bash
set -euo pipefail

payload="$(cat)"

tty_out="/dev/tty"
[ -w "$tty_out" ] || tty_out="/dev/null"

config_dir="${XDG_CONFIG_HOME:-$HOME/.config}/goose"
banner_dir="$config_dir/banner.d"
banner_file="$HOME/.goose-session-banner.txt"

max_lines="${GOOSE_BANNER_MAX_LINES:-15}"
agent_visible="${GOOSE_BANNER_AGENT_VISIBLE:-true}"

: > "$banner_file"

if [ ! -d "$banner_dir" ]; then
  mkdir -p "$banner_dir"
  exit 0
fi

scripts=($(find "$banner_dir" -type f -perm +111 -not -name "*.md" 2>/dev/null | sort))

if [ ${#scripts[@]} -eq 0 ]; then
  exit 0
fi

collected=""
line_count=0

for script in "${scripts[@]}"; do
  output=$("$script" 2>/dev/null || true)

  [ -z "$output" ] && continue

  while IFS= read -r line; do
    if [ "$line_count" -ge "$max_lines" ]; then
      break 2
    fi
    collected="${collected}${line}
"
    line_count=$((line_count + 1))
  done <<< "$output"
done

if [ -z "$collected" ]; then
  exit 0
fi

printf '%s' "$collected" > "$tty_out"

if [ "$agent_visible" = "true" ]; then
  printf '%s' "$collected" >> "$banner_file"
fi
