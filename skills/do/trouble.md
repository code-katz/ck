# /ck:do: when a step goes wrong

- A step comes back with an error, or without what it was asked for: say so in one line and ask "Try again, or stop?"
- The author types stop while a step runs: stop the agent, keep any worktree and branch, name them, and finish.
- The look back says `ready: no`: do not ask the merge question. Say what it printed in one line and ask "Send it back to `<persona>`, or discard?" Sending it back goes per `change.md`.
