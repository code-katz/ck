# Without the desktop app's session tools

This session cannot see other sessions or put up cards.

- Step 2: say once "I cannot see other sessions here, so tell me when a stage is running or done." Read no `refresh.md`, then go on as step 2's last lines say.
- A card, for a stage or a fix: print the title on a line of its own, then the prompt in one fenced block with its line breaks real. For a stage say "Open a new session in its own worktree of this project, on `<model>`, name it with the line above the block, and paste this as its first message. Then say `running <id>` here." For a fix, end with "`<id>` stays done on the board. When the fix has a pull request, say `merge` and its number here." in place of the words about `running`.
- "merge `<id>`": the pull request is the open one whose title starts with `[<id>]`, which `gh pr list` shows. "merge `<number>`": the stage is the row whose full id fills the first brackets of the pull request's own title, which `gh pr view <n> --json title` shows; when those brackets hold ` fix` after the id, it is a fix's. Then go on as `merge.md` says, renaming nothing.
- "running", "done", "back", and "back fix": do what `state.md` and `fix.md` say, skipping each part that needs the session tools.
