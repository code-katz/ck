# Add a memory to CLAUDE.md

Read only when the User picks "Add to CLAUDE.md". Write it now, on a branch with a draft pull request:

1. Name the branch by the project's rule for branches, with `memory-gate` for any part this session cannot fill; when the name is taken, add `-2`, `-3`.
2. Run `git fetch origin <default branch>`, then `git worktree add -b <branch> "<projectRoot>/.claude/worktrees/<branch>" origin/<default branch>`, and work there. This session's own branch and folder are not touched.
3. Add the line after the closing marker `<!-- /ck:how-we-work -->`, in the memory's own words. With no markers, add it as the last bullet of "## How we work"; with no such heading, under a new "## How we work" at the end of the file.
4. Commit only CLAUDE.md, with the message `CLAUDE.md: <the rule's name>`, push, and open a draft pull request into the default branch with `gh pr create --draft`. Then remove the worktree.
5. Give the pull request's link, then "Say merge <N>." Only on the User's "merge <N>", in a message of its own, merge it by the project's rule for merges. For replace, the old memory then goes to the Trash as the skill's step 4 says.
