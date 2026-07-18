# Banner Providers

Drop executable scripts here to customize your Goose session startup banner.

Scripts are executed in sort order (use numeric prefixes: `01-`, `02-`, etc.).
Each script's stdout becomes banner lines printed to your terminal at session start.

## Rules

- Scripts MUST be executable (`chmod +x`)
- Empty stdout = no output (script is silently skipped)
- Scripts timeout after 2 seconds (configurable via `GOOSE_BANNER_TIMEOUT`)
- Total output capped at 15 lines (configurable via `GOOSE_BANNER_MAX_LINES`)
- Errors are swallowed - a broken script never blocks session start
- Scripts receive the SessionStart hook JSON payload on stdin

## Example

```bash
#!/usr/bin/env bash
# 01-hello.sh
printf '  👋 hello from banner\n'
```

## Environment

Scripts inherit the Goose process environment. Useful variables:
- Standard env (HOME, USER, PATH, etc.)
- Stdin: JSON with `event`, `session_id`, `working_dir`

## Tips

- Prefix output lines with `  ` (two spaces) to align with Goose's banner
- Use emoji for visual scanning
- Keep it fast - this runs before you can type
- See `../examples/` for reference implementations
