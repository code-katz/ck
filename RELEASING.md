# Releasing ck

Every merge to `main` is a release, `0.1.N`, and merges only on Will's typed "merge N". A release is not done, and no one tells Will it is fixed, until step 7 passes.

## Before the merge

1. Branch from `origin/main`. Rebase on it again right before the pull request, and take the next version after main's: `.claude-plugin/plugin.json`, a DEVLOG entry, and a commit titled `0.1.N: <title>`, all in one commit.
2. `bash tests/run.sh` passes.
3. Open the pull request. Wait for "merge N", fetch, and merge only when the branch sits on main's tip, so the merged tree is the tested one.

## After the merge

4. Tag and release: `git tag -a v0.1.N <merge commit>`, push the tag, `gh release create v0.1.N`.
5. ck-next: in `~/development/ck-next/.claude-plugin/marketplace.json`, set `metadata.version`, the plugin's `ref` (`v0.1.N`), `sha` (the merge commit) and `description`.
6. Installs: `git archive v0.1.N | tar -x -C ~/.claude/plugins/cache/ck-next/ck/0.1.N`, then `python3 scripts/installs.py set 0.1.N --sha <merge commit>`. Never edit `installed_plugins.json` by hand: a session reads the first record of its repository, often an old worktree's, so setting one folder's record leaves sessions on the old ck.
7. The release check, two parts, both pasted into the pull request:
   - `python3 scripts/installs.py verify 0.1.N`: a fresh session in d20mob, hireling and ck each loads `0.1.N`.
   - The fix where Will sees it: in a d20mob worktree, run the command the release changed, on a real plan or file, and paste what it prints. For a chip name, `plan.py card` on a real stage. For a skill's wording, the line a fresh session says.

   If either part fails, the release is not done: say so, and fix it before anything else.
8. Stable (the `code-katz` marketplace) moves only on Will's word.
