---
name: cost
description: What this session has cost so far, in tokens and dollars, by lane (the main session, each persona, Claude Code's own calls) and by kind (input, output, cache write, cache read), priced from Anthropic's pricing page. With "history", one row per merged pull request. Runs only when typed.
disable-model-invocation: true
argument-hint: "[history | <session id>]"
---

Run this exact command from the folder Claude Code was opened in, and nothing else:

```bash
python3 "${CLAUDE_PLUGIN_ROOT}/scripts/cost.py" $ARGUMENTS
```

Show what it printed, exactly as printed, as Markdown, with nothing before or after it. If it printed an error, show that line and stop.
