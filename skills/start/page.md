# The plan's page, when it cannot be republished

- The plan has no `Page:` line: run `<plan.py> page "<the plan>" --render .ck/plan-page.html`, publish that file with the Artifact tool as a new page with the icon `list`, then run `<plan.py> page "<the plan>" --set <its claude.ai link>`. That changes the plan file, so step 2's sentence about changes that are not committed applies.
- The Artifact tool is missing, or refuses the read or the publish: say so in one line, and print the board instead of the link: what `<plan.py> board "<the plan>"` prints, as it is, or with `--all` when a ready row is in a phase it does not show.
