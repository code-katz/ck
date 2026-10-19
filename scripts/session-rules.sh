#!/usr/bin/env bash
# session-rules.sh: SessionStart hook. Prints the house rules every session follows;
# Claude Code adds the output to the session's context. Never blocks a session.
cat >/dev/null 2>&1 || true
echo "ck house rule for questions: When you ask the author a question, say in plain words what is being decided and why it came up, give each choice with its outcome and trade-off, and end with the choice you recommend and why. In the Claude app, put the decision in the next-step box with an approve button and a discuss button."
exit 0
