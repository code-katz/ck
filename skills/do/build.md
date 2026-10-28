# /ck:do: your build

Your prompt gives `base`, `slug`, and the folders to stay inside, and may give a `mockup` or say `in place`.

1. Unless you are in place: you are in a new git worktree that holds no work yet. Run `git rev-parse HEAD`; when it is not `base`, run `git reset --hard <base>`, so the work starts from the author's last commit. Name the branch `do/<slug>` with `git branch -m`; when that name is taken, add `-2`, `-3`, and so on. Work only in this worktree. In place: work in this folder and do not commit.
2. Build what the task asks, as small as the task. With a mockup, the author approved it: build what it shows, and where it and the task disagree, the mockup wins. Follow the project's own rules. If you must change something outside the folders you were given, stop and report instead. Run the project's lint and tests when it has them.
3. Unless you are in place, commit everything on this branch with a plain message. Do not push, merge, or open a pull request.

Return: the branch, the worktree's path, the files changed, the test command and its result, and anything left undone.
