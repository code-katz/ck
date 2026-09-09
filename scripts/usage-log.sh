#!/usr/bin/env bash
# usage-log.sh: SubagentStart hook. Appends one line per ck persona invocation to
# ${CLAUDE_PLUGIN_DATA}/usage.jsonl so the 90-day persona review has data.
# Never blocks: every path exits 0, and a logging failure must not stop a persona.
input=$(cat 2>/dev/null || true)
dir="${CLAUDE_PLUGIN_DATA:-}"
[ -z "$dir" ] && exit 0
mkdir -p "$dir" 2>/dev/null || exit 0
ts=$(date -u +%Y-%m-%dT%H:%M:%SZ)
if command -v jq >/dev/null 2>&1 && printf '%s' "$input" | jq -e . >/dev/null 2>&1; then
  printf '%s' "$input" | jq -c --arg ts "$ts" '{ts: $ts, agent_type: (.agent_type // ""), agent_id: (.agent_id // ""), session_id: (.session_id // ""), cwd: (.cwd // "")}' >> "$dir/usage.jsonl" 2>/dev/null
else
  # jq is optional in the family: fall back to the raw line, still one record per line.
  printf '{"ts":"%s","raw":%s}\n' "$ts" "$(printf '%s' "$input" | tr -d '\n' | sed 's/^$/""/')" >> "$dir/usage.jsonl" 2>/dev/null
fi
exit 0
