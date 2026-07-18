#!/usr/bin/env bash
repo_root="${SPORE_REPO_ROOT:-$(git rev-parse --show-toplevel 2>/dev/null || echo "$HOME/the_professional")}"
[ -d "$repo_root" ] || repo_root="$HOME/the_professional"

db="$HOME/.local/share/goose/sessions/sessions.db"

total_sessions=0
today_sessions=0
today_tokens=0
retrievals=0

if [ -f "$db" ]; then
  read total_sessions total_tokens <<< $(sqlite3 "$db" "SELECT COUNT(*), COALESCE(SUM(total_tokens),0) FROM sessions WHERE session_type='user';" 2>/dev/null | tr '|' ' ')
  read today_sessions today_tokens <<< $(sqlite3 "$db" "SELECT COUNT(*), COALESCE(SUM(total_tokens),0) FROM sessions WHERE session_type='user' AND date(created_at) = date('now');" 2>/dev/null | tr '|' ' ')
fi

retrieval_log="$repo_root/.retrieval-log.csv"
if [ -f "$retrieval_log" ]; then
  retrievals=$(($(wc -l < "$retrieval_log") - 1))
  [ "$retrievals" -lt 0 ] && retrievals=0
fi

total_tokens_k=""
if [ "${total_tokens:-0}" -gt 0 ]; then
  total_tokens_m=$(echo "scale=1; $total_tokens / 1000000" | bc 2>/dev/null || echo "?")
  total_tokens_k="${total_tokens_m}M"
fi

today_tokens_k=""
if [ "${today_tokens:-0}" -gt 0 ]; then
  today_tokens_k=$(echo "scale=0; $today_tokens / 1000" | bc 2>/dev/null || echo "?")
  today_tokens_k="${today_tokens_k}k"
fi

printf '  🌱 spore | %s sessions | %s tokens | %d retrievals\n' "$total_sessions" "$total_tokens_k" "$retrievals"
printf '  🌱 today | %s sessions | %s tokens\n' "$today_sessions" "$today_tokens_k"
