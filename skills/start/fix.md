# Fix a finished stage

This is for a fault in a stage that is done, when the fix needs a session of its own. The author typed `/ck:start fix <stage> <what is wrong>`, or says "fix `<id>`: `<what is wrong>`" later. A fix changes no State: never run `<plan.py> set` for one, and never ask the author to say `running` for one.

What is wrong is the author's words, as typed. With none, ask "What is wrong with `<id>`?" and stop; the answer is the words. Write the title yourself from those words: a short phrase that starts with a verb and names the fix, such as `Mend the scan's natural 1`, with no `"`, `$`, backtick, or backslash in it.

Run this, with the author's words between the two `CK_FAULT` lines exactly as typed. When a line of the words is exactly `CK_FAULT`, use another word that no line of them equals for both markers:

```bash
<plan.py> card "<the plan>" <id> --fix - --title "<the title>" --plugin-root "${CLAUDE_PLUGIN_ROOT}" <<'CK_FAULT'
<the author's words>
CK_FAULT
```

- It refuses and says why in one line: relay that line. When the line says the name is too long, shorten the title and run it once more. Nothing is opened.
- Otherwise offer the card as step 4 of `SKILL.md` does, its sentence about a plan that is not committed included, with the `title`, `tldr`, and `prompt` exactly as printed. Say "Card up: `<title>`. Click it, start it in its own worktree, and pick `<model>` as its model. `<id>` stays done on the board. When the fix has a pull request, say `merge` and its number here."

## Fix sessions on the board

A session whose `cwd` is the project's folder or inside it (as `refresh.md` finds it), and whose title's first brackets hold a row's full id followed by ` fix`, such as `[A31-P1-S5 fix] [Akira Fable] Mend the scan's natural 1`, is a fix to that stage: it belongs to no row and changes no State. Pass over one whose title starts with `[dropped]` or whose pull request is CLOSED. When its pull request is OPEN, say in one line "A fix for `<id>` is open (`<number>`)." When it is MERGED and its title does not start with `[done]`, rename it with `mcp__ccd_session_mgmt__set_session_title` to `[done] ` and the title it has.

## Back fix

"back fix `<id>`" is a fix that was abandoned. Change no State. With the session tools, list the sessions again and rename that fix's session to `[dropped] ` and the title it has; when two fixes for the stage are open, name both and ask which.
