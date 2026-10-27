# What the author says about a stage

With the session tools, list the sessions again before acting on any of these.

- "running `<id>`": run `<plan.py> set "<the plan>" <id> running`. With the session tools, find that stage's session and check its model as `refresh.md` says.
- "done `<id>`", with or without a pull request number: run `<plan.py> set "<the plan>" <id> done`, with `--pr <n>` when one was given. Say what it printed: the rows that could start now. Open them only when the author says so or types `/ck:start`.
- "back `<id>`", for a session that was abandoned: run `<plan.py> set "<the plan>" <id> not-started`. With the session tools, rename that stage's session to `[dropped] ` and the title it has, so it no longer counts.
- "save": run `git add -- "<the plan>" && git commit -m "plan: <what changed>" -- "<the plan>"`, which commits that one file whatever else is staged. When the project's rules ask for a check before every commit, run it first; when it fails or cannot be run, say so in one line, ask "Commit anyway?", and commit only after "yes". Add to the message only a trailer this session's rules require, and push only when they say so.

A change of State is an edit to the plan file; never commit it but on "save".
