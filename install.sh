#!/usr/bin/env bash
# claude-x installer — ports CLAUDE.md, rules, agents, hooks, settings,
# MCP servers, and plugin marketplaces into ~/.claude on this machine.
#
# Usage:  ./install.sh
# Safe to re-run: existing files are backed up, MCP entries are never overwritten.

set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CLAUDE_DIR="${CLAUDE_DIR:-$HOME/.claude}"
CLAUDE_JSON="$HOME/.claude.json"
STAMP="$(date +%Y%m%d-%H%M%S)"

say()  { printf '\033[1;32m==>\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33m !!\033[0m %s\n' "$*"; }

command -v python3 >/dev/null || { echo "python3 is required"; exit 1; }

mkdir -p "$CLAUDE_DIR"

# ── 1. Backup anything we are about to replace ──────────────────────────────
say "Backing up existing config (suffix .bak-$STAMP)"
for f in settings.json CLAUDE.md keybindings.json; do
  [ -f "$CLAUDE_DIR/$f" ] && cp "$CLAUDE_DIR/$f" "$CLAUDE_DIR/$f.bak-$STAMP"
done

# ── 2. CLAUDE.md + rules + agents + hooks + keybindings + settings ──────────
say "Installing CLAUDE.md, rules/, agents/, hooks/, keybindings.json, settings.json"
cp    "$REPO_DIR/claude/CLAUDE.md"        "$CLAUDE_DIR/CLAUDE.md"
mkdir -p "$CLAUDE_DIR/rules" "$CLAUDE_DIR/agents" "$CLAUDE_DIR/hooks"
cp    "$REPO_DIR/claude/rules/"*.md       "$CLAUDE_DIR/rules/"
cp    "$REPO_DIR/claude/agents/"*.md      "$CLAUDE_DIR/agents/"
cp    "$REPO_DIR/claude/hooks/"*                "$CLAUDE_DIR/hooks/"
cp    "$REPO_DIR/claude/keybindings.json" "$CLAUDE_DIR/keybindings.json"
cp    "$REPO_DIR/claude/settings.json"    "$CLAUDE_DIR/settings.json"

# ── 3. Vendored local MCP server (aseprite-mcp-pro) ─────────────────────────
say "Installing local MCP server: aseprite-mcp-pro"
mkdir -p "$CLAUDE_DIR/mcp-servers"
rm -rf "$CLAUDE_DIR/mcp-servers/aseprite-mcp-pro.new"
cp -R "$REPO_DIR/mcp/servers/aseprite-mcp-pro" "$CLAUDE_DIR/mcp-servers/aseprite-mcp-pro.new"
if [ ! -d "$CLAUDE_DIR/mcp-servers/aseprite-mcp-pro" ]; then
  mv "$CLAUDE_DIR/mcp-servers/aseprite-mcp-pro.new" "$CLAUDE_DIR/mcp-servers/aseprite-mcp-pro"
else
  rm -rf "$CLAUDE_DIR/mcp-servers/aseprite-mcp-pro.new"
  warn "aseprite-mcp-pro already present — left untouched"
fi
if command -v npm >/dev/null && [ ! -d "$CLAUDE_DIR/mcp-servers/aseprite-mcp-pro/node_modules" ]; then
  ( cd "$CLAUDE_DIR/mcp-servers/aseprite-mcp-pro" && (npm ci --silent 2>/dev/null || npm install --silent) ) \
    && say "aseprite-mcp-pro dependencies installed" \
    || warn "npm install failed for aseprite-mcp-pro — run it manually"
fi

# ── 4. Merge MCP servers into ~/.claude.json (never overwrites existing) ────
say "Merging MCP servers into $CLAUDE_JSON"
python3 - "$REPO_DIR/mcp/mcp-servers.json" "$CLAUDE_JSON" <<'PY'
import json, os, sys

src_path, dst_path = sys.argv[1], sys.argv[2]
incoming = json.load(open(src_path))["mcpServers"]

dst = {}
if os.path.exists(dst_path):
    with open(dst_path) as f:
        dst = json.load(f)
existing = dst.setdefault("mcpServers", {})

def expand(o):  # '~' paths -> absolute for this machine
    if isinstance(o, dict):  return {k: expand(v) for k, v in o.items()}
    if isinstance(o, list):  return [expand(x) for x in o]
    if isinstance(o, str) and o.startswith("~/"): return os.path.expanduser(o)
    return o

added, skipped, needs_secret = [], [], []
for name, cfg in incoming.items():
    if name in existing:
        skipped.append(name)
        continue
    cfg = expand(cfg)
    existing[name] = cfg
    added.append(name)
    if "<REPLACE_ME>" in json.dumps(cfg):
        needs_secret.append(name)

with open(dst_path, "w") as f:
    json.dump(dst, f, indent=2)

print(f"  added:   {', '.join(added) or '(none)'}")
print(f"  skipped (already configured): {', '.join(skipped) or '(none)'}")
if needs_secret:
    print(f"  NEEDS SECRETS (<REPLACE_ME> placeholders): {', '.join(needs_secret)}")
PY

# ── 5. Plugin marketplaces + plugins (best effort, needs claude CLI) ────────
if command -v claude >/dev/null; then
  say "Adding plugin marketplaces"
  python3 -c "import json;[print(v) for v in json.load(open('$REPO_DIR/plugins/marketplaces.json')).values()]" |
  while read -r repo; do
    claude plugin marketplace add "$repo" >/dev/null 2>&1 \
      && echo "  + $repo" || echo "  = $repo (already added or unreachable)"
  done

  say "Installing enabled plugins"
  python3 -c "
import json
s = json.load(open('$REPO_DIR/claude/settings.json'))
[print(k) for k, v in s.get('enabledPlugins', {}).items() if v]" |
  while read -r plugin; do
    claude plugin install "$plugin" >/dev/null 2>&1 \
      && echo "  + $plugin" || echo "  = $plugin (already installed or failed — settings.json still enables it)"
  done
else
  warn "claude CLI not found — skipped marketplace/plugin install."
  warn "Install Claude Code first, then re-run ./install.sh"
fi

# ── 5b. Serena: dashboard + GUI log window off ─────────────────────────────
say "Disabling Serena web dashboard / GUI log window"
python3 "$REPO_DIR/lib/serena-ui-off.py"

# ── 6. Shell alias: ccd (zsh + fish, skip if already defined) ───────────────
say "Installing shell alias: ccd -> claude --dangerously-skip-permissions"
ALIAS_LINE='alias ccd="claude --dangerously-skip-permissions"'
if ! grep -qs 'alias ccd=' "$HOME/.zshrc"; then
  printf '\n# ccd - Claude Code with dangerously-skip-permissions\n%s\n' "$ALIAS_LINE" >> "$HOME/.zshrc"
  echo "  + zsh  (~/.zshrc)"
else
  echo "  = zsh  (already defined)"
fi
FISH_CONFIG="$HOME/.config/fish/config.fish"
if command -v fish >/dev/null; then
  if ! grep -qs 'alias ccd' "$FISH_CONFIG"; then
    mkdir -p "$(dirname "$FISH_CONFIG")"
    printf '\n# ccd - Claude Code with dangerously-skip-permissions\n%s\n' "$ALIAS_LINE" >> "$FISH_CONFIG"
    echo "  + fish (~/.config/fish/config.fish)"
  else
    echo "  = fish (already defined)"
  fi
fi

# ── 7. Summary ───────────────────────────────────────────────────────────────
say "Done."
echo
echo "  Installed into: $CLAUDE_DIR"
echo "  Backups:        *.bak-$STAMP (only for files that existed)"
echo
warn "Action required:"
echo "  1. Replace every <REPLACE_ME> in $CLAUDE_JSON with your real API keys/secrets"
echo "     (zai-mcp-server, web-search-prime, web-reader, zread, magic, shopify-*)."
echo "  2. shopify / shopify-smoothe / shopify-dentiste point to ~/code/StandUpCode/shopify-mcp —"
echo "     clone+build that project or remove those entries."
echo "  3. Restart Claude Code so settings, hooks, and MCP servers load."
