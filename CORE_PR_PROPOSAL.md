# Goose Core: Session Banner Hook Support

## Summary

Allow `SessionStart` hooks to contribute lines to the CLI startup banner.
Today, hook stdout/stderr is captured and discarded (or logged on failure).
This change lets plugins surface context to the user at the moment it's most
useful - session open.

## Motivation

Plugins like session-continuity tools, project-status dashboards, and
reminder systems have information the user needs *before* they type their
first prompt. Currently there's no way to surface this without:

1. The agent making a tool call on first turn (wastes tokens, adds latency)
2. Writing to `/dev/tty` directly (works but is a hack, not portable)
3. Using `tom` to inject into agent context (agent sees it, user doesn't)

## Proposed Change

### Hook Protocol Extension

`SessionStart` hooks can optionally output a JSON object with a `banner` field:

```json
{"banner": "  🌱 spore session: 2026-07-18-a3f2c1\n  🍄 3 active threads"}
```

If stdout is not valid JSON or lacks a `banner` field, behavior is unchanged
(backwards compatible).

### Implementation

**`crates/goose/src/hooks/mod.rs`**

Add a new method alongside `emit` and `emit_blocking`:

```rust
pub async fn emit_with_banner(&self, event: HookEvent, ctx: HookContext) -> Vec<String> {
    // Same as emit(), but collects banner strings from hook stdout
    // Returns Vec of banner lines (empty if no hooks provide banners)
}
```

**`crates/goose-cli/src/session/mod.rs`**

In `interactive()`, capture banner output:

```rust
pub async fn interactive(&mut self, prompt: Option<String>) -> Result<()> {
    let banners = self.agent
        .emit_session_start_with_banner(&self.session_id)
        .await;

    for line in &banners {
        println!("{}", line);
    }

    // Also inject into agent context so it knows what the user saw
    if !banners.is_empty() {
        self.agent.inject_banner_context(banners.join("\n")).await;
    }

    let result = self.run_interactive(prompt).await;
    // ...
}
```

**`crates/goose-cli/src/session/output.rs`**

Move `display_context_usage` to after banner lines, so the layout is:

```
    __( O)>  ● resuming · provider model
   \____)    session_id · /path
     L L     goose is ready
  [banner lines from plugins]
  ━╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌ 5% 45k/1.0M
```

### hooks.json Extension

Optional `provides_banner: true` flag for documentation/tooling:

```json
{
  "hooks": {
    "SessionStart": [
      {
        "provides_banner": true,
        "hooks": [
          { "type": "command", "command": "${PLUGIN_ROOT}/scripts/banner.sh" }
        ]
      }
    ]
  }
}
```

## Backwards Compatibility

- Hooks that don't output JSON: unchanged (stdout discarded as before)
- Hooks that output JSON without `banner`: unchanged
- Only hooks that explicitly output `{"banner":"..."}` contribute to the banner
- Non-zero exit still logged as warning, no banner contribution

## Scope

- ~50 lines of Rust in hooks/mod.rs
- ~15 lines in session/mod.rs
- ~5 lines in output.rs (ordering)
- Tests for banner extraction from hook output

## Alternatives Considered

1. **New hook event (`SessionBanner`)** - more explicit but adds API surface
   for a narrow use case. Rejected: reusing `SessionStart` with an output
   protocol is simpler.

2. **File-based (`~/.goose-banner.txt`)** - works but requires coordination
   between hooks and CLI. The JSON stdout approach keeps it self-contained.

3. **MCP tool approach** - agent calls a tool on first turn. Rejected: adds
   latency, costs tokens, and the user doesn't see it until the agent responds.
