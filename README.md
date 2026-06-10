# claude-x

Portable snapshot of my Claude Code setup — CLAUDE.md constitution, rules, agents,
hooks, settings, MCP servers, and plugin marketplaces — installable on any machine
with **one command**.

## Install

```bash
git clone <this-repo> claude-x && cd claude-x && ./install.sh
```

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
| `claude/rules/` | `~/.claude/rules/` | mythos-charter, debug-mantra, scrutinize, post-mortem, management-talk |
| `claude/agents/` | `~/.claude/agents/` | 32 local agents (verifier, 1m-*, architects, …) referenced by CLAUDE.md §11.1 |
| `claude/hooks/` | `~/.claude/hooks/` | `claude-island-state.py` (drives all lifecycle hook events) |
| `claude/settings.json` | `~/.claude/settings.json` | env, hooks wiring, enabledPlugins, statusLine, permissions — paths rewritten to `$HOME` |
| `claude/keybindings.json` | `~/.claude/keybindings.json` | Custom keybindings |
| `mcp/mcp-servers.json` | merged into `~/.claude.json` | 20 MCP servers, **secrets scrubbed to `<REPLACE_ME>`** |
| `mcp/servers/aseprite-mcp-pro/` | `~/.claude/mcp-servers/` | Vendored local MCP server (deps installed via `npm ci`) |
| `plugins/marketplaces.json` | via `claude plugin marketplace add` | 14 GitHub marketplaces |

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

- `CLAUDE.md` ends with `@RTK.md` — that file does not exist in the source setup
  either; the include is dangling by origin, kept for fidelity.
- `availableModels` / `env` reference model IDs specific to the source account
  (`claude-fable-5`, `claude-opus-4-8`, and a `claude-hiku-4-6` typo). Adjust to
  what your account can access.
- `permissions.defaultMode` is `bypassPermissions` — review before installing on
  a shared machine.

## Not ported

- `~/.claude/commands/` (SuperClaude + shopify-seo slash commands), skills,
  session data, memory, telemetry, OAuth tokens — intentionally excluded
  (session-local or credential-bearing).
