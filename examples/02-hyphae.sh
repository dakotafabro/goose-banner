#!/usr/bin/env bash
repo_root="${HYPHAE_REPO_ROOT:-$(git rev-parse --show-toplevel 2>/dev/null || echo "")}"

if [ -z "$repo_root" ] || [ ! -d "$repo_root/.hyphae/active" ]; then
  repo_root="$HOME/the_professional"
fi

hyphae_dir="$repo_root/.hyphae/active"

[ -d "$hyphae_dir" ] || exit 0

thread_files=($(find "$hyphae_dir" -name "*.yaml" -type f 2>/dev/null | sort))
thread_count=${#thread_files[@]}

[ "$thread_count" -eq 0 ] && exit 0

machine="${AGENT_MACHINE:-$(cat ~/.agent-machine 2>/dev/null || hostname)}"

printf '  🍄 %d thread(s) | %s\n' "$thread_count" "$machine"

for thread_file in "${thread_files[@]}"; do
  name=$(grep "^thread_name:" "$thread_file" 2>/dev/null | sed 's/^thread_name: *//' | sed "s/^['\"]//;s/['\"]$//" || echo "?")
  task=$(grep "^task:" "$thread_file" 2>/dev/null | sed 's/^task: *//' | sed "s/^['\"]//;s/['\"]$//" || echo "")
  origin=$(grep "^machine:" "$thread_file" 2>/dev/null | awk '{print $2}' || echo "")

  marker=""
  [ -n "$origin" ] && [ "$origin" != "$machine" ] && marker=" <- ${origin}"

  task_short="${task:0:45}"
  [ ${#task} -gt 45 ] && task_short="${task_short}..."

  printf '  🍄  * %s%s\n' "$name" "$marker"
done
