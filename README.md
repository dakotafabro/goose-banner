# goose-banner

Customizable session startup banner for [Goose](https://github.com/block/goose). Drop executable scripts into `banner.d/` to surface context at session open.

## What it looks like

```
  🌱 spore | 120 sessions | 8.3M tokens | 47 retrievals
  🌱 today | 6 sessions | 180k tokens
  🍄 3 thread(s) active | work
  🍄  api-refactor
  🍄    ↳ Migrate v1 endpoints to new response format
  🍄  onboarding-flow
  🍄    ↳ Add email verification step before account creation
  🍄  perf-investigation
  🍄    ↳ Dashboard load time regression after deploy #847

    __( O)>  ● resuming · databricks goose-claude-4-6-opus
   \____)    20260718_15 · /Users/you
     L L     goose is ready
  ━╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌ 5% 45k/1.0M
```

The 🌱 lines come from [spore](https://github.com/dakotafabro/spore) (agent memory and retrieval tracking) and the 🍄 lines come from [hyphae](https://github.com/dakotafabro/hyphae) (session continuity). Both are Goose plugins currently in development, scheduled for public release by end of August 2026. You can write your own banner scripts for any context you want to surface.

## How it works

### Path 1: Shell wrapper (works today)

Wrap the `goose` command in your shell to run banner scripts before Goose launches:

```zsh
# ~/.zshrc
_goose_banner() {
  local banner=""
  for script in ~/.config/goose/banner.d/*.sh(N); do
    [[ -x "$script" ]] && banner+="$("$script" 2>/dev/null)"$'\n'
  done
  [[ -n "$banner" ]] && {
    printf '%s' "$banner" > ~/.goose-session-banner.txt
    printf '\n%s\n' "$banner"
  }
}

goose() {
  [[ "$1" == "session" ]] && _goose_banner
  command goose "$@"
}
```

This intercepts any `goose session` invocation (direct, alias, resume, recipe) and prints the banner first. The banner file is also written so the agent can see it via the `tom` extension.

### Path 2: Native Goose support (proposed)

A [draft PR](https://github.com/block/goose/pull/10562) adds native `SessionBanner` hook support. SessionStart hooks return `{"banner":"..."}` on stdout and the CLI prints it in the banner area. No shell wrapper needed.

## Setup

1. Create the banner directory:
   ```bash
   mkdir -p ~/.config/goose/banner.d
   ```

2. Add the shell wrapper to your `~/.zshrc` (see Path 1 above)

3. Drop executable scripts in `banner.d/` (see Customizing below, or use an example):
   ```bash
   cp examples/01-git-status.sh ~/.config/goose/banner.d/
   chmod +x ~/.config/goose/banner.d/01-git-status.sh
   ```

4. (Optional) Enable agent visibility so the agent also sees your banner:
   ```bash
   echo 'export GOOSE_MOIM_MESSAGE_FILE="$HOME/.goose-session-banner.txt"' >> ~/.zshrc
   ```
   Then enable the `tom` extension in `~/.config/goose/config.yaml`.

## Customizing your banner

The banner is yours to make useful. Write any bash script that prints what you need to see at session start. Here's how:

### Create a script

```bash
#!/usr/bin/env bash
# ~/.config/goose/banner.d/01-my-banner.sh

# Print whatever context helps you orient
printf '  🔥 3 PRs waiting for review\n'
printf '  📅 standup in 45 min\n'
```

Make it executable:
```bash
chmod +x ~/.config/goose/banner.d/01-my-banner.sh
```

That's it. Next time you run `goose session`, those lines appear before the goose art.

### Script rules

- **Executable** - must have `chmod +x`
- **Sort order** - scripts run in filename order (use `01-`, `02-`, `03-` prefixes)
- **Fast** - runs before every session, keep it under 1-2 seconds
- **Stdout only** - print to stdout, stderr is suppressed
- **Silent fail** - if a script produces no output, it's skipped
- **Indent with 2 spaces** - aligns with Goose's own banner formatting

### Ideas for your banner

| What to show | How |
|---|---|
| Git branch + dirty files | `git branch --show-current`, `git status --short \| wc -l` |
| Today's calendar | Query your calendar API or a local cache |
| Open PRs needing review | `gh pr list --search "review-requested:@me"` |
| Reminders / TODOs | Read from a text file (`~/.reminders.txt`) |
| Active Linear tickets | `curl` the Linear API or use a cached export |
| Pomodoro / focus timer | Check a timer state file |
| Weather | `curl wttr.in/?format=3` |
| Disk space warning | `df -h / \| awk 'NR==2{print $5}'` |
| Docker containers running | `docker ps --format '{{.Names}}' \| wc -l` |
| Session stats from a DB | `sqlite3 ~/.local/share/goose/sessions/sessions.db "SELECT ..."` |

### Example: PR review reminder

```bash
#!/usr/bin/env bash
# ~/.config/goose/banner.d/01-prs.sh
count=$(gh pr list --search "review-requested:@me" --json number --jq length 2>/dev/null)
[ "${count:-0}" -gt 0 ] && printf '  👀 %d PR(s) waiting for your review\n' "$count"
```

### Example: simple reminders file

```bash
#!/usr/bin/env bash
# ~/.config/goose/banner.d/02-reminders.sh
file="$HOME/.reminders.txt"
[ -f "$file" ] || exit 0
count=$(wc -l < "$file" | tr -d ' ')
[ "$count" -eq 0 ] && exit 0
printf '  📝 %d reminder(s)\n' "$count"
while IFS= read -r line; do
  printf '  📝   %s\n' "$line"
done < "$file"
```

### Example: current git context

```bash
#!/usr/bin/env bash
# ~/.config/goose/banner.d/03-git.sh
branch=$(git branch --show-current 2>/dev/null) || exit 0
dirty=$(git status --short 2>/dev/null | wc -l | tr -d ' ')
printf '  🌿 %s' "$branch"
[ "$dirty" -gt 0 ] && printf ' (%d uncommitted)' "$dirty"
printf '\n'
```

## Included examples

| Script | What it shows |
|---|---|
| `01-git-status.sh` | Current branch, dirty file count, commits ahead |
| `01-spore.sh` | Session and retrieval stats from spore |
| `02-hyphae.sh` | Active work threads from hyphae |
| `02-reminders.sh` | Lines from a reminders file |
| `03-time-context.sh` | Day of week and time-appropriate greeting |

## Dual-channel architecture

The banner reaches both the user and the agent:

| Channel | Audience | Mechanism |
|---|---|---|
| Terminal (stdout) | User | Shell wrapper prints before Goose launches |
| `~/.goose-session-banner.txt` | Agent | `tom` extension injects into turn context |

This means your banner context is available to the agent on every turn without spending tokens on a tool call.

## Configuration

| Env var | Default | Description |
|---|---|---|
| `GOOSE_MOIM_MESSAGE_FILE` | (unset) | Path to banner file for agent visibility |
| `AGENT_MACHINE` | (from `~/.agent-machine`) | Machine identifier shown in banner |

## License

Apache License 2.0
