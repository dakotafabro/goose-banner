#!/usr/bin/env bash
repo_root="${SPORE_REPO_ROOT:-$(git rev-parse --show-toplevel 2>/dev/null || pwd)}"
session_id="$(date +%Y-%m-%d)-$(openssl rand -hex 3 2>/dev/null || printf '%04x' $$)"

printf '  🌱 spore: %s\n' "$session_id"
