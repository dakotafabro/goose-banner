# goose-banner

A Goose plugin that lets you customize what prints at session startup.

## The Problem

Goose's startup banner is hardcoded:

```
    __( O)>  ● resuming · databricks goose-claude-4-6-opus
   \____)    20260718_13 · /Users/dakotafabro
     L L     goose is ready
  ━╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌ 5% 45k/1.0M
```

Plugin hooks fire at session start, but their output is piped and swallowed.
There's no way for a plugin to surface information to the user in that startup
moment - the moment when context about active work, reminders, or environment
state is most useful.

## What This Enables

```
    __( O)>  ● resuming · databricks goose-claude-4-6-opus
   \____)    20260718_13 · /Users/dakotafabro
     L L     goose is ready
  🌱 spore session: 2026-07-18-a3f2c1
  🍄 ─────────────────────────────────────────
  🍄  hyphae | 4 thread(s) | work
  🍄  * patent-candidates
  🍄  * tidal-tomorrow
  🍄 ─────────────────────────────────────────
  📋 3 items due today (Linear)
  ━╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌ 5% 45k/1.0M
```

Any plugin can register a banner provider. Users see relevant context the
moment their session opens - no tool calls needed, no waiting for the agent
to "warm up."

## Architecture

Two delivery paths, complementary:

### Path 1: Plugin (works today, no Goose changes)

Uses the `/dev/tty` technique to write directly to the terminal, bypassing
Goose's stdout/stderr pipe capture on hook scripts.

- `SessionStart` hook writes to `/dev/tty` (user sees it)
- Also writes to `~/.goose-session-banner.txt` (agent sees it via `tom`)
- Provides a `banner.d/` directory where other plugins drop scripts
- Scripts are executed in sort order, output collected and printed

### Path 2: Goose Core Enhancement (PR to block/goose)

Adds first-class support for banner providers in the hook system:

- New hook return type: `SessionStart` hooks can return `{"banner": "..."}`
  on stdout, and Goose prints it between "goose is ready" and the context bar
- Respects ANSI colors and emoji
- Multiple plugins can contribute banner lines (concatenated in plugin order)
- Agent also receives the banner content as context (replaces need for `tom`)

## Plugin Structure (Path 1)

```
goose-banner/
  plugin.json
  hooks/
    hooks.json
  scripts/
    session-start.sh    # orchestrator: runs banner.d/* scripts
  banner.d/
    README.md           # explains how to add providers
  examples/
    git-status.sh       # show branch + dirty file count
    linear-today.sh     # show today's assigned tickets
    reminders.sh        # show items from a reminders file
```

## Usage

Install the plugin:

```bash
goose plugin install https://github.com/aaif/goose-banner
```

Drop scripts into `~/.config/goose/banner.d/`:

```bash
# ~/.config/goose/banner.d/01-git.sh
#!/usr/bin/env bash
branch=$(git branch --show-current 2>/dev/null)
[ -n "$branch" ] && printf '  🌿 %s' "$branch"
dirty=$(git status --porcelain 2>/dev/null | wc -l | tr -d ' ')
[ "$dirty" != "0" ] && printf ' (%s dirty)' "$dirty"
[ -n "$branch" ] && printf '\n'
```

Each script's stdout becomes a banner line. Empty output = no line printed.

## Configuration

```yaml
# ~/.config/goose/banner.yaml (optional)
banner:
  max_lines: 10          # cap total banner output
  timeout_ms: 2000       # per-script timeout
  agent_visible: true    # also write to tom message file
  disabled: []           # list of script names to skip
```

## Design Principles

- Zero latency impact on session start (scripts run async, timeout aggressively)
- Fail silent (if /dev/tty unavailable, if scripts error, just skip)
- Composable (multiple plugins can contribute banner lines)
- Both human-visible AND agent-visible (dual channel)
- No Goose core dependency for Path 1 (works with any Goose version that has plugins)

## For Plugin Authors

Want your plugin to show something at session start? Two options:

1. Drop a script in your plugin's `banner.d/` and register it in hooks.json
2. Or: in your `SessionStart` hook, write to `/dev/tty` directly

The goose-banner plugin provides the orchestration layer so multiple providers
play nicely together (ordering, timeouts, max lines).

## Relationship to Goose Core (Path 2)

If the Goose team adopts banner support natively, this plugin becomes a
compatibility shim and eventually unnecessary. The PR proposal:

- `SessionStart` hooks that output `{"banner":"..."}` on stdout get their
  banner content printed by the CLI
- New field in `hooks.json`: `"provides_banner": true` on a SessionStart rule
- CLI collects banner lines from all hooks, prints after "goose is ready"
- Banner content also injected into agent context (replacing tom for this use case)

This is a small, backwards-compatible change to `emit()` in `hooks/mod.rs`
and `display_session_info()` in `session/output.rs`.
