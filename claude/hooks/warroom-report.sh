#!/usr/bin/env bash
# warroom-report — Claude Code hook that forwards the hook event JSON (stdin)
# to the warroom agent's POST /events endpoint (JSONL landing zone for the
# usage dashboard). Fail-silent by design: a dead, slow, or unconfigured
# warroom must never break or delay a Claude session.
#
# Config (first match wins):
#   token: $WARROOM_AGENT_TOKEN  ·or·  ~/.config/warroom/token (chmod 600)
#   url:   $WARROOM_URL          ·or·  http://127.0.0.1:8787
set -u

TOKEN="${WARROOM_AGENT_TOKEN:-}"
if [ -z "$TOKEN" ] && [ -f "$HOME/.config/warroom/token" ]; then
  TOKEN="$(head -c 256 "$HOME/.config/warroom/token" | tr -d '[:space:]')"
fi
[ -z "$TOKEN" ] && exit 0   # warroom not configured on this machine — no-op

URL="${WARROOM_URL:-http://127.0.0.1:8787}"
HOST="$(hostname -s 2>/dev/null || echo unknown)"

# Enrich the hook payload with host + source, then ship it. Token goes in the
# query string because that is the agent's auth convention on every route
# (localhost / tunneled only — never a public URL).
jq -c --arg host "$HOST" '. + {host: $host, source: "claude-code-hook"}' 2>/dev/null |
  curl -s -o /dev/null --max-time 2 \
       -H 'Content-Type: application/json' \
       --data-binary @- \
       "$URL/events?token=$TOKEN" || true
exit 0
