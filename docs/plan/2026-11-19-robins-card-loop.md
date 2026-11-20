# Staged plan: Robin's card loop, /ck:cards

Date: 2026-11-19. Status: approved 2026-11-19.
Page: https://claude.ai/artifact/4xGNorDkeajmJopGEYncWi
Item: R46
Reads: `ROADMAP.md`, `CLAUDE.md`, `RELEASING.md`, `/Users/wcurran/Library/Application Support/Claude/side-session-notes/local_80b327c7-4af3-49d4-8646-5ac588ff3e2d/r46-s1-card-loop-proposal.md` (the approved proposal, also at https://claude.ai/artifact/44exM7SXQhukzHi5RKQj9D), `skills/issue/SKILL.md`, `skills/start/merge.md`, `hooks/hooks.json`, `scripts/cost.py`, `scripts/render-review.py`, `tests/run.sh`

## What this covers

A new command, `/ck:cards`, as you approved it on 19 November 2026. A bug that a journey card catches names its rows on one line, d20mob's own `Test case:` line (`Test case: 09-D4`, bold or not). The merge of its fix labels it `to verify`. `/ck:cards verify` re-runs only those cards, stops each card at its last named row, and labels the bug `verified` or re-opens it with what Robin saw. A run's draft issues go on one review page and are filed on one `file`. A bug list page for the project is rebuilt from GitHub at the end of each run. The order of work is the proposal's section 5.

What is in ck today, from a search of the project:

1. No cards command and no `scripts/cards.py`. `skills/issue/SKILL.md` is the one place that files an issue.
2. The step after a merge is one hook in `hooks/hooks.json`. It runs `scripts/cost.py merge` after every `gh pr merge` and already asks GitHub about the merged pull request. The new label step sits beside it.
3. `scripts/render-review.py` builds review pages. The draft issues of a run use it as it is.
4. `tests/run.sh` tests `cost.py` with a stand-in for `gh` and saved files under `tests/fixtures/cost/`. The new script's tests follow that pattern.
5. `README.md` and `.claude-plugin/plugin.json` list the commands, so the new command gets a row and a mention.

Outside this plan, as the proposal says: each project's guide lines (`NN-Xn` and App wrong), known bugs read from GitHub (feature C), and hireling's two labels. Those belong to lanes in d20mob and hireling.

The whole item ships as one release: the stages of Phase 2 open their pull requests against one item branch, `claude/r46-cards`, and P3-S0 takes it to `main` (settled 19 November). No separate check stage is planned: the script's tests and the first real verify run in d20mob show the result.

## Phases

### Phase 1. The choices

The four choices the build waits on are made. There is no drawing: d20mob's triage page of 19 November is the approved design, and its pills are already HTML.

| Stage | What | Who | State |
|---|---|---|---|
| P1-S0 | Four choices the build waits on | You | done |

Ends when: each choice under Open points has your typed answer.

### Phase 2. The loop, built

The command's words, the script behind it, the label step after a merge, the bug list page and the script's tests are built. When this ends you can open d20mob's real bug list as a page the script built, with the new pills on it.

| Stage | What | Who | State |
|---|---|---|---|
| P2-S0 | The words of the new command, and the "Test case" rule for filing | River, write | not started; could start now |
| P2-S1 | The script: the verify list, the labels, the regression match, and the label after a merge | Akira, build | not started; follows S0 |
| P2-S2 | The bug list page, built from GitHub in the style of d20mob's triage page | Akira, build | not started; follows S1 |
| P2-S3 | Tests of the script | Robin, review | not started; follows S1 and S2 |

Ends when: you open the link to d20mob's bug list page, built by the script from GitHub, and the suite passes on the item's pull requests.

### Phase 3. Released and tried in d20mob

ck ships the command, d20mob gets its two labels, and you run the first verify. When this ends a real d20mob bug has been verified or re-opened by Robin without a hand-written brief.

| Stage | What | Who | State |
|---|---|---|---|
| P3-S0 | The release, and d20mob made ready for its first verify | Alex, build | not started; follows P2-S3 |
| P3-S1 | The first verify run in d20mob, started by you | You | not started; follows S0 |

Ends when: a closed d20mob bug carries `verified` and Robin's comment, or is open again with what Robin saw, and the bug list page shows its new pill.

## Stage by stage

### P1-S0. Settle the open points

- Kind: yours
- Does: Answers the four questions under Open points, one at a time.
- Files: none
- Reads: `docs/plan/2026-11-19-robins-card-loop.md`
- Follows: nothing
- Done when: each open point has your typed answer.
- Hands back: nothing

### P2-S0. Write the cards command

- Kind: build
- Does: Writes the new command for `/ck:cards`, `/ck:cards <cards>` and `/ck:cards verify`, by the proposal's sections 3.3 to 3.5, and names each call to `scripts/cards.py` with what it prints, so P2-S1 builds to those words. Adds one rule to the issue command (a report from a card starts with a `Test case:` line naming its rows as `NN-Xn`, as d20mob's bugs do) and the command's row in the README. Makes the item branch `claude/r46-cards` from fresh `origin/main` first.
- Files: `skills/cards/`, `skills/issue/SKILL.md`, `README.md`, `.claude-plugin/plugin.json`
- Reads: the proposal, sections 3 and 4; `skills/issue/SKILL.md`; `skills/start/SKILL.md`; `skills/do/SKILL.md`; `skills/review-page/SKILL.md`
- Follows: P1-S0
- Done when: the command's main file is under 1,000 words, with rare branches in files of their own; it files only through the issue command's steps and copies none of them; it runs only when typed; every call to the script it names is listed once with its arguments and output.
- Hands back: a draft pull request against `claude/r46-cards`
- With: Akira

### P2-S1. Build the cards script

- Kind: build
- Does: Builds `scripts/cards.py` to the calls P2-S0 names: the list of closed bugs with a `Test case:` line and no `verified` label, grouped by card with each card's last named row; the three label changes (to verify, verified with its comment, re-opened with its comment); and the match of a failing row to a `verified` bug that names it. Adds the step after `gh pr merge` that labels each bug the pull request closed and that has a `Test case:` line.
- Files: `scripts/cards.py`, `hooks/hooks.json`, `scripts/cost.py`
- Reads: `skills/cards/SKILL.md`; the proposal, sections 3.1, 3.2 and 3.4; `scripts/cost.py`; `hooks/hooks.json`
- Follows: S0
- Done when: run in a d20mob folder, the list call prints bug, cards and rows without changing GitHub; the script uses the standard library and `gh` only, reads nothing from an issue except its `Test case:` line (bold or not), state and labels, and passes every value to `gh` as an argument; a failed `gh` call after a merge prints one line and leaves the merge and the cost line as they are; a bug never holds both labels after a call.
- Hands back: a draft pull request against `claude/r46-cards`

### P2-S2. Build the bug list page

- Kind: build
- Does: Adds the page call to `scripts/cards.py`: one page for the project, built from GitHub, with the counts across the top, the bugs grouped by epic from their parent issues on GitHub, each epic with its tally and no Coordinator or Waits on lines, and each bug's pills in the style of d20mob's triage page, the four new ones ("test case 09-D4", "to verify", "verified #PR", "re-opened") beside today's. Publishes d20mob's page once, for you to see.
- Files: `scripts/cards.py`, `skills/cards/`
- Reads: d20mob's triage page of 19 November, https://claude.ai/artifact/JgiytFz5qDFa3Ntamur7nA, read with the Artifact tool (the design; copy nothing from it into ck); the proposal, section 4 row E; `scripts/render-review.py`; `scripts/render-gallery.py`
- Follows: S1
- Done when: the page call writes one self-contained file from GitHub alone, every pill on the triage page and the four new ones appear for a bug in that state, the command's words say to republish it to the same link at a run's end, and d20mob's page is published with its link in the session.
- Hands back: a draft pull request against `claude/r46-cards`

### P2-S3. Test the cards script

- Kind: tests
- Does: Adds tests of `scripts/cards.py` to the suite, with a stand-in for `gh` and saved issue lists, as the cost script's tests do. Covers the verify list and its grouping, the last named row, each label change, the regression match, the step after a merge, and the page's pills; no checks of wording.
- Files: `tests/run.sh`, `tests/fixtures/cards/`
- Reads: `scripts/cards.py`; `tests/run.sh`, section 22; `tests/fixtures/cost/`; the proposal, sections 3.1, 3.2 and 3.4
- Follows: S1 and S2
- Done when: `bash tests/run.sh` passes, each case above fails when its part of the script is broken by hand, no test calls GitHub, and the pull request says what the tests add to one run of the suite, in minutes.
- Hands back: a draft pull request against `claude/r46-cards`
- With: Akira

### P3-S0. Release it, set up d20mob

- Kind: build
- Does: Takes `claude/r46-cards` to `main` as one release by `RELEASING.md`, through the release check. In d20mob, on your word in the session, makes the labels `to verify` and `verified`. No issue is rewritten: d20mob's bugs already carry their `Test case:` lines.
- Files: `.claude-plugin/plugin.json`; outside ck: the ck-next marketplace file and the installs, as `RELEASING.md` says; d20mob's labels on GitHub
- Reads: `RELEASING.md`; `scripts/installs.py`; `skills/cards/SKILL.md`; the proposal, section 3.2
- Follows: P2-S3
- Done when: `installs.py verify` passes for the new version; in a d20mob worktree, `/ck:cards verify` prints its list of bugs, cards and rows, and that list is pasted into the pull request; d20mob has both labels; the list includes the 14 bugs closed on 19 November with `Test case:` lines.
- Hands back: a draft pull request
- With: Robin

### P3-S1. Run the first verify

- Kind: yours
- Does: In d20mob, types `/ck:cards verify` and clicks the card it puts up. Robin's session, on Sonnet at medium, runs the named cards and marks each bug.
- Files: none
- Reads: the list `/ck:cards verify` prints
- Follows: S0
- Done when: Robin's closing table gives a verdict for each bug on the list, GitHub shows the label or the re-open with its comment, and the bug list page at its link shows the new pills.
- Hands back: nothing

## Open points

None. Settled by you on 19 November 2026:

1. **One release for the whole item.** The stages of Phase 2 open their pull requests against `claude/r46-cards`, and P3-S0 takes it to `main` as one release.
2. **No drawing.** d20mob's triage page of 19 November (https://claude.ai/artifact/JgiytFz5qDFa3Ntamur7nA) is the design; its pills are HTML. Kai's drawing stage and your OK on it are dropped.
3. **The line keeps d20mob's name, `Test case:`.** ck reads its row names (`NN-Xn`), bold or not, and the issue command writes it on every bug from a card. No issue is rewritten, so the first verify finds the 14 bugs closed on 19 November as they are.
4. **The bug list page shows only what GitHub holds.** Epics from parent issues, each with its tally, every bug's row and its pills; no Coordinator or Waits on lines.
