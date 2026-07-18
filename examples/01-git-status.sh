#!/usr/bin/env bash
branch=$(git branch --show-current 2>/dev/null)
[ -z "$branch" ] && exit 0

dirty=$(git status --porcelain 2>/dev/null | wc -l | tr -d ' ')
ahead=$(git rev-list --count @{u}..HEAD 2>/dev/null || echo "0")

line="  🌿 ${branch}"
[ "$dirty" != "0" ] && line="${line} (${dirty} dirty)"
[ "$ahead" != "0" ] && line="${line} ↑${ahead}"

printf '%s\n' "$line"
