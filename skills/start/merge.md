# Merge a stage's pull request

The author said "merge `<id>`" or "merge `<number>`". With the session tools, list the sessions again first.

With an id, the pull request is that stage's session's. With a number, the stage is the row whose session has that pull request. When it is a fix's session that has it, go on the same way but mark no row: once it is merged, rename that session to `[done] ` and the title it has, and say "`<id>` stays done." When no session has it and its title names no row, say so in one line and merge nothing.

Run `gh pr view <n> --json state,isDraft` and `gh pr checks <n>`. When its state is not OPEN, say so in one line and merge nothing. When a check is failing or still running, say which in one line and ask "Merge anyway?" When it is a draft, run `gh pr ready <n>` first, whatever the project's rules say, and tell the author you did. Then merge it the way the project's own rules say; with no rule, run `gh pr merge <n> --merge`.

When the merge succeeds, run `<plan.py> set "<the plan>" <id> done --pr <n>`, rename the session to `[done] ` and the title it has with `mcp__ccd_session_mgmt__set_session_title`, and say what could start now. When it fails, say why in one line and leave the row as it is. Without `gh`, say so and ask the author to merge it, and then to say `done <id> <n>` only when it is a stage's pull request: a fix's is never marked.
