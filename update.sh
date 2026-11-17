#!/usr/bin/env bash
# claude-x update channel — pull latest repo state and apply ONLY what changed.
# No reinstall: unchanged files are untouched, npm ci runs only if the lockfile
# changed, MCP entries already in ~/.claude.json (your real secrets) are never
# overwritten, plugins are only added — never reinstalled.
#
# Usage:  ./update.sh            # pull + apply deltas
#         ./update.sh --no-pull  # apply deltas from current checkout only

set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CLAUDE_DIR="${CLAUDE_DIR:-$HOME/.claude}"
CLAUDE_JSON="$HOME/.claude.json"
STAMP="$(date +%Y%m%d-%H%M%S)"
CHANGED=0

say()  { printf '\033[1;32m==>\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33m !!\033[0m %s\n' "$*"; }

command -v python3 >/dev/null || { echo "python3 is required"; exit 1; }

# ── 1. Pull latest ───────────────────────────────────────────────────────────
if [ "${1:-}" != "--no-pull" ]; then
  say "Pulling latest claude-x"
  git -C "$REPO_DIR" pull --ff-only || {
    warn "git pull failed (offline or local commits?) — applying current checkout"
  }
fi

# ── 2. Delta sync: copy a file only when content differs ────────────────────
LOCK_BEFORE=""
[ -f "$CLAUDE_DIR/mcp-servers/aseprite-mcp-pro/package-lock.json" ] &&
  LOCK_BEFORE="$(md5 -q "$CLAUDE_DIR/mcp-servers/aseprite-mcp-pro/package-lock.json" 2>/dev/null || md5sum "$CLAUDE_DIR/mcp-servers/aseprite-mcp-pro/package-lock.json" | cut -d' ' -f1)"

sync_file() { # $1=src $2=dst
  if [ ! -f "$2" ] || ! cmp -s "$1" "$2"; then
    [ -f "$2" ] && cp "$2" "$2.bak-$STAMP"
    mkdir -p "$(dirname "$2")"
    cp "$1" "$2"
    echo "  updated: ${2/#$HOME/~}"
    CHANGED=1
  fi
}

say "Syncing changed files into $CLAUDE_DIR"
sync_file "$REPO_DIR/claude/CLAUDE.md"        "$CLAUDE_DIR/CLAUDE.md"
sync_file "$REPO_DIR/claude/settings.json"    "$CLAUDE_DIR/settings.json"
sync_file "$REPO_DIR/claude/keybindings.json" "$CLAUDE_DIR/keybindings.json"
for f in "$REPO_DIR"/claude/rules/*.md;  do sync_file "$f" "$CLAUDE_DIR/rules/$(basename "$f")"; done
for f in "$REPO_DIR"/claude/agents/*.md; do sync_file "$f" "$CLAUDE_DIR/agents/$(basename "$f")"; done
for f in "$REPO_DIR"/claude/hooks/*;     do sync_file "$f" "$CLAUDE_DIR/hooks/$(basename "$f")"; done
for f in "$REPO_DIR"/mcp/servers/aseprite-mcp-pro/*; do
  sync_file "$f" "$CLAUDE_DIR/mcp-servers/aseprite-mcp-pro/$(basename "$f")"
done

# ── 3. npm ci only if the lockfile actually changed ─────────────────────────
LOCK_AFTER=""
[ -f "$CLAUDE_DIR/mcp-servers/aseprite-mcp-pro/package-lock.json" ] &&
  LOCK_AFTER="$(md5 -q "$CLAUDE_DIR/mcp-servers/aseprite-mcp-pro/package-lock.json" 2>/dev/null || md5sum "$CLAUDE_DIR/mcp-servers/aseprite-mcp-pro/package-lock.json" | cut -d' ' -f1)"
if command -v npm >/dev/null; then
  if [ "$LOCK_BEFORE" != "$LOCK_AFTER" ] || [ ! -d "$CLAUDE_DIR/mcp-servers/aseprite-mcp-pro/node_modules" ]; then
    say "aseprite-mcp-pro deps changed — running npm ci"
    ( cd "$CLAUDE_DIR/mcp-servers/aseprite-mcp-pro" && (npm ci --silent 2>/dev/null || npm install --silent) ) \
      || warn "npm install failed — run it manually"
  fi
fi

# ── 3b. Serena UI stays off (idempotent) ────────────────────────────────────
python3 "$REPO_DIR/lib/serena-ui-off.py" >/dev/null

# ── 4. Add-only MCP merge (existing entries / real secrets never touched) ───
say "Merging new MCP servers (add-only)"
python3 - "$REPO_DIR/mcp/mcp-servers.json" "$CLAUDE_JSON" <<'PY'
import json, os, sys
src_path, dst_path = sys.argv[1], sys.argv[2]
incoming = json.load(open(src_path))["mcpServers"]
dst = json.load(open(dst_path)) if os.path.exists(dst_path) else {}
existing = dst.setdefault("mcpServers", {})
def expand(o):
    if isinstance(o, dict):  return {k: expand(v) for k, v in o.items()}
    if isinstance(o, list):  return [expand(x) for x in o]
    if isinstance(o, str) and o.startswith("~/"): return os.path.expanduser(o)
    return o
added, needs = [], []
for name, cfg in incoming.items():
    if name in existing:
        continue
    existing[name] = expand(cfg)
    added.append(name)
    if "<REPLACE_ME>" in json.dumps(existing[name]):
        needs.append(name)
if added:
    with open(dst_path, "w") as f: json.dump(dst, f, indent=2)
print(f"  new servers: {', '.join(added) or '(none)'}")
if needs: print(f"  NEEDS SECRETS: {', '.join(needs)}")
PY

# ── 5. Add-only marketplaces + newly enabled plugins ────────────────────────
if command -v claude >/dev/null; then
  say "Checking for new marketplaces/plugins"
  python3 -c "import json;[print(v) for v in json.load(open('$REPO_DIR/plugins/marketplaces.json')).values()]" |
  while read -r repo; do
    claude plugin marketplace add "$repo" >/dev/null 2>&1 && echo "  + marketplace $repo" || true
  done
  python3 -c "
import json
s = json.load(open('$REPO_DIR/claude/settings.json'))
[print(k) for k, v in s.get('enabledPlugins', {}).items() if v]" |
  while read -r plugin; do
    claude plugin install "$plugin" >/dev/null 2>&1 && echo "  + plugin $plugin" || true
  done
fi

# ── 6. Summary ───────────────────────────────────────────────────────────────
if [ "$CHANGED" -eq 1 ]; then
  say "Update applied. Changed files were backed up as *.bak-$STAMP."
  warn "Restart Claude Code to pick up settings/hook changes."
else
  say "Already up to date — nothing changed."
fi
