#!/usr/bin/env bash
# check-prereqs.sh: SessionStart hook. Warns, in one plain sentence, while the old
# team tool is still installed; its persona commands and subagents collide with ck's.
# Never blocks a session.
cat >/dev/null 2>&1 || true
found=""
[ -d "$HOME/.claude/team" ] && found="yes"
[ -e "$HOME/.local/bin/claude-team" ] && found="yes"
if [ -f "$HOME/.claude/CLAUDE.md" ] && grep -q 'Claude Team CLI' "$HOME/.claude/CLAUDE.md" 2>/dev/null; then found="yes"; fi
if [ -n "$found" ]; then
  echo "The old team tool is still installed and its persona commands will collide with ck's. Remove it with the steps in the ck README (Uninstalling the old team tool)."
fi
exit 0
