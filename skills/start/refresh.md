# Bring the board up to date from the sessions

The project's folder is what `dirname "$(git rev-parse --path-format=absolute --git-common-dir 2>/dev/null)"` prints, the main checkout even from a worktree; when it prints `.`, it is the folder Claude Code was opened in. `<plan.py> rows` prints, per row: its full id, its stage as shown, the owner, the model word, the kind, `done`, `running` or `not started`, `yes` when it could start now, and its entry's title.

A session belongs to a row when its `cwd` is the project's folder or inside it and its title, less any `[done] ` in front, starts with `[<the row's full id>] [` and ends with the row's title. A title that only mentions an id, has more after the title, or has more inside the brackets belongs to no row. Pass over a title that starts with `[dropped]`, a session whose pull request is CLOSED, and a title that starts with `[done]` while its row is not done, which is an earlier plan's. When two sessions belong to one row, change nothing for it, name both, and ask which is the stage's.

- Its pull request is MERGED and the row is not done: run `<plan.py> set "<the plan>" <id> done --pr <its number>`, and unless its title starts with `[done]`, rename it with `mcp__ccd_session_mgmt__set_session_title` to `[done] ` and the title it has.
- The row is not started: run `<plan.py> set "<the plan>" <id> running`, then check its model.

To check a session's model, read it with `mcp__ccd_session_mgmt__get_session`. It fits when the model's id holds the row's model word in lower case (`Fable` fits `claude-fable-5-1`). When it does not, set it with `mcp__ccd_session_mgmt__set_session_model` to the id in `${CLAUDE_PLUGIN_ROOT}/tiers.conf` that holds that word, or to the one the app lists for that family when it refuses that id. The app may ask the author first.

Mark a row done only on a merged pull request or the author's word, never on a session's own say-so. Say in one line what you set and renamed, and each model you set, from what to what, adding "Say `go` in that session."
