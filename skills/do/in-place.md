# /ck:do: a build in your files

With no git repository, or no `isolation` option on the Agent tool, the build edits the author's files directly. In the plan, the build line is "Sasha builds it in your files directly. There is no branch and no merge step." (with the build's owner in place of Sasha).

Run the build without `isolation`. Its rules: "Read and follow `${CLAUDE_PLUGIN_ROOT}/skills/do/build.md`. in place. Stay inside: `<the task's folders>`." Add "mockup: `<its absolute path>`" when one was OK'd.

When it is back, in a git repository run `git status --porcelain` and report the files it lists; without one, report the files the builder named and say you could not check them. Run the tests as for any build. There is no merge question: go to the finish.
