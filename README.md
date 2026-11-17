# claude-x

Portable snapshot of my Claude Code setup — CLAUDE.md constitution, rules, agents,
hooks, settings, MCP servers, and plugin marketplaces — installable on any machine
with **one command**.

## Install

```bash
git clone <this-repo> claude-x && cd claude-x && ./install.sh
```

Windows (PowerShell 5.1+ or pwsh 7 — no python needed for the install itself):

```powershell
git clone <this-repo> claude-x; cd claude-x
powershell -ExecutionPolicy Bypass -File .\install.ps1
```

`install.ps1` mirrors `install.sh`; differences: `npx` MCP entries are rewritten to
`cmd /c npx …` (native Windows can't spawn `npx.cmd` directly), `ccd` becomes a
function in `$PROFILE`, and it warns if `bash` / `python3` (used by hooks) are not on
PATH — Claude Code on Windows runs hooks through Git Bash. Set `$env:CLAUDE_DIR`,
`$env:CLAUDE_JSON`, `$env:SERENA_CONFIG` to install into a scratch location.
There is no `update.ps1` yet — re-run `install.ps1` (it backs up first).

Re-running is safe: existing files are backed up (`*.bak-<timestamp>`) and MCP
server entries already present in `~/.claude.json` are never overwritten.

## Update (no reinstall)

```bash
cd claude-x && ./update.sh
```

Pulls the latest repo state and applies **only the deltas**:

- files are compared byte-for-byte; only changed ones are copied (with a
  timestamped backup of what they replace) — unchanged files are untouched
- `npm ci` for the vendored aseprite server runs only if its lockfile changed
- MCP merge is add-only — entries already in `~/.claude.json` (your real
  secrets) are never overwritten
- marketplaces/plugins are only added, never reinstalled
- prints `Already up to date — nothing changed.` when there is nothing to do

`./update.sh --no-pull` applies the current checkout without fetching (offline,
or when testing local edits before committing).

## What gets installed

| Repo path | Installs to | Contents |
|---|---|---|
| `claude/CLAUDE.md` | `~/.claude/CLAUDE.md` | Strict-mode constitution (global instructions) |
| `claude/rules/` | `~/.claude/rules/` | mythos-charter, debug-mantra, scrutinize, post-mortem, management-talk, comment-discipline, ux-writing |
| `claude/agents/` | `~/.claude/agents/` | 32 local agents (verifier, 1m-*, architects, …) referenced by CLAUDE.md §11.1 |
| `claude/hooks/` | `~/.claude/hooks/` | `claude-island-state.py` (drives all lifecycle hook events) |
| `claude/settings.json` | `~/.claude/settings.json` | env, hooks wiring, enabledPlugins, statusLine, permissions — paths rewritten to `$HOME` |
| `claude/keybindings.json` | `~/.claude/keybindings.json` | Custom keybindings |
| `mcp/mcp-servers.json` | merged into `~/.claude.json` | 20 MCP servers, **secrets scrubbed to `<REPLACE_ME>`** |
| `mcp/servers/aseprite-mcp-pro/` | `~/.claude/mcp-servers/` | Vendored local MCP server (deps installed via `npm ci`) |
| `plugins/marketplaces.json` | via `claude plugin marketplace add` | 14 GitHub marketplaces |
| shell alias `ccd` | appended to `~/.zshrc` + `~/.config/fish/config.fish` | `claude --dangerously-skip-permissions` (skipped if already defined) |
| `lib/serena-ui-off.py` (ps1: inline) | `~/.serena/serena_config.yml` | Forces `web_dashboard`, `web_dashboard_open_on_launch`, `gui_log_window` to `false` (patches in place; creates a 3-key file if absent — Serena fills the rest with defaults). Re-applied by `update.sh` |

## After install (required)

1. **Secrets** — replace every `<REPLACE_ME>` in `~/.claude.json`:
   `zai-mcp-server`, `web-search-prime`, `web-reader`, `zread`, `magic`,
   `shopify`, `shopify-smoothe`, `shopify-dentiste`.
2. **Shopify MCP** — the three `shopify-*` servers run a locally built project at
   `~/code/StandUpCode/shopify-mcp/dist/index.js`. Clone and build it, or delete
   those entries.
3. **Restart Claude Code** so settings, hooks, and MCP servers load.

## Requirements

- `python3` (hard requirement — config merging + hook script)
- `claude` CLI (for marketplace/plugin install; everything else works without it)
- `npm` (for the vendored aseprite server), `jq`, `npx`, `uvx`, `docker` (used by
  individual hooks/servers at runtime — missing ones degrade gracefully)

## Known quirks (ported as-is)

- `CLAUDE.md` ends with `@RTK.md` — `~/.claude/RTK.md` does not exist in the source
  setup either (a copy lives in a separate project); the include is dangling by
  origin, kept for fidelity.
- `availableModels` / `env` reference model IDs specific to the source account
  (`claude-opus-5-5`, `claude-sonnet-5`, …). Adjust to what your account can access.
- The source machine's `autoMode` block (org-specific classifier rules) is not
  shipped — this repo is public. Add your own in `~/.claude/settings.json`.
- The `appshots-local` marketplace + `appshots-reference` plugin from the source
  machine are omitted (local directory path, cannot resolve elsewhere).
- `permissions.defaultMode` is `bypassPermissions` — review before installing on
  a shared machine.

## Not ported

- `~/.claude/commands/` (SuperClaude + shopify-seo slash commands), skills,
  session data, memory, telemetry, OAuth tokens — intentionally excluded
  (session-local or credential-bearing).
