# goose-banner

Customizable session startup banner for [Goose](https://github.com/block/goose). Drop executable scripts into `banner.d/` to surface context at session open.

## What it looks like

```
  🌱 spore: 2026-07-18-a3f2c1
  🍄 5 thread(s) | work
  🍄  * goose-banner-plugin
  🍄  * hyphae-build
  🍄  * patent-candidates

    __( O)>  ● resuming · databricks goose-claude-4-6-opus
   \____)    20260718_14 · /Users/dakota
     L L     goose is ready
  ━╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌ 5% 45k/1.0M
```

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

2. Drop executable scripts in `banner.d/`:
   ```bash
   cp examples/01-git-status.sh ~/.config/goose/banner.d/
   chmod +x ~/.config/goose/banner.d/01-git-status.sh
   ```

3. Add the shell wrapper to your `~/.zshrc` (see above)

4. (Optional) Enable agent visibility:
   ```bash
   echo 'export GOOSE_MOIM_MESSAGE_FILE="$HOME/.goose-session-banner.txt"' >> ~/.zshrc
   ```
   Then enable the `tom` extension in `~/.config/goose/config.yaml`.

## Writing banner scripts

Scripts are executed in sort order (use numeric prefixes: `01-`, `02-`, etc.). Each script's stdout becomes banner lines.

Rules:
- Must be executable (`chmod +x`)
- Empty stdout = silently skipped
- Keep it fast (runs before every session)
- Prefix lines with `  ` (two spaces) to align with Goose's banner
- Use emoji for visual scanning

```bash
#!/usr/bin/env bash
# 01-hello.sh
printf '  👋 hello from banner\n'
```

## Examples

| Script | What it shows |
|---|---|
| `01-git-status.sh` | Current branch, dirty file count, commits ahead |
| `01-spore.sh` | Spore session ID |
| `02-hyphae.sh` | Active work threads from hyphae |
| `02-reminders.sh` | Lines from a reminders file |
| `03-time-context.sh` | Day of week and time of day |

## Dual-channel architecture

The banner reaches both the user and the agent:

| Channel | Audience | Mechanism |
|---|---|---|
| Terminal (stdout) | User | Shell wrapper prints before Goose launches |
| `~/.goose-session-banner.txt` | Agent | `tom` extension injects into turn context |

## Configuration

| Env var | Default | Description |
|---|---|---|
| `GOOSE_MOIM_MESSAGE_FILE` | (unset) | Path to banner file for agent visibility |
| `AGENT_MACHINE` | (from `~/.agent-machine`) | Machine identifier shown in banner |

## License

MIT
