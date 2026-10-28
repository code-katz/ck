# ck: Product Roadmap

> Maintained by [claude-roadmap-skill](https://github.com/code-katz/claude-roadmap-skill). Last updated: 2026-10-27.

---

## Current Roadmap

## Current State Snapshot

**What works well:**
- The product pipeline (opportunity, market research, brief, PRD, team, roadmap, architecture, brand guide, design), drilled on real projects from 2026-10-01 to 2026-10-05.
- `/ck:plan`, `/ck:start` and `/ck:do`, used in d20mob and hireling since 0.1.10.
- `/ck:claude-md` (0.1.12) writes a project's "How we work" from ck's template and sorts its memory.
- The memory gate (0.1.13), asking in the message since 0.1.14: a proposal and an approval before any memory is saved.
- Current models since 0.1.15: Opus 5.5, Sonnet 5.5 and Haiku 5.5; Fable 5.1 for judgment.
- A shorter `/ck:start` (0.1.16, about 1,080 words read per use instead of 2,699), with its chips back (0.1.17, confirmed in hireling).
- Main is at 0.1.17. Each release is a branch from main, a pull request into main, a tag on main, and a GitHub release. The tests run on every pull request.
- Two channels: stable (the `code-katz` marketplace) and ck-next (a local marketplace, used by d20mob, hireling and the ck folder), both on `v0.1.17`. Rollback in a project is two commands.

**What's missing or fragile:**
- The memory gate has not yet been tried in an interactive session.
- Auto mode sometimes refuses to push a tag or create a GitHub release; then you run that step by hand.
- ck2 is abandoned. Anything from it is rebuilt from scratch, if at all.

---

## Releases

| Version | Date | What it added | State |
|---|---|---|---|
| 0.1.1 | 2026-10-03 | The review loop proposes a change before it makes one | From `main` |
| 0.1.2 | 2026-10-03 | A direct `/ck:brief` reads the opportunity and market research | From `main` |
| 0.1.3 | 2026-10-04 | `/ck:brief` owns its run and its review | From `main` |
| 0.1.4 | 2026-10-05 | Length rules first; validators count; the rewrite may not grow | From `main` |
| 0.1.5 | 2026-10-05 | The PRD panel is opt-in (`--panel`) | From `main` |
| 0.1.6 | 2026-10-05 | Team, roadmap and market research become skills | From `main` |
| 0.1.7 | 2026-10-07 | A stopped run restarts at a named stage; workflow tests with stub agents | From `main` |
| 0.1.8 | 2026-10-07 | Fixes to the resume check | From `main` |
| 0.1.9 | 2026-10-07 | `/ck:next` shows the whole pipeline as a table | From `main` |
| 0.1.10 | 2026-10-12 | `/ck:do`, `/ck:plan`, `/ck:start` | Tag `v0.1.10` |
| 0.1.11 | 2026-10-19 | The question rule at session start | Tag `v0.1.11`; reverted in 0.1.12, not coming back |
| 0.1.12 | 2026-10-26 | `/ck:claude-md` | Tag `v0.1.12` |
| 0.1.13 | 2026-10-26 | The memory gate | Tag `v0.1.13` |
| 0.1.14 | 2026-10-26 | Questions in the message, never in the app's box | Tag `v0.1.14` |
| 0.1.15 | 2026-10-26 | Current models: Opus 5.5, Sonnet 5.5, Haiku 5.5 | Tag `v0.1.15` |
| 0.1.16 | 2026-10-27 | A shorter `/ck:start`; a bar in a code span stays in its table cell | Tag `v0.1.16` |
| 0.1.17 | 2026-10-27 | `/ck:start` puts up chips again | Tag `v0.1.17`; stable and ck-next |

---

## ck2 features

Carried forward from the roadmap's revision 3 (2026-10-26). ck2 is abandoned: a feature that returns is rebuilt from scratch, as its own release. Built means it ran in ck2; planned means it was written down and never built. The last column is where each stands in ck now.

| # | Feature | What it does | In ck2 | Where it stands (2026-10-27) |
|---|---|---|---|---|
| 1 | **A team per project** | `.claude/ck-team.conf` invites or drops personas; `/ck:team` shows and changes it; every session is told who is on the team | Built | Not planned |
| 2 | **`/ck:proof`** | Any file, or a document written from a request, becomes a page you comment on until approved; with the proof loop rules and one document contract for a proposal, an analysis, or a note | Built | Removed: 0.1.13 already makes a proof page for any document |
| 3 | **Ask the owner first** | Before a judgment question reaches you, the stage's owning persona answers it on its own model, and the session asks with "<Owner> recommends" | Built | Not planned: a stage session already runs as its owner, on the owner's model |
| 4 | **Lanes for `/ck:do`** | A small task runs in background lanes (builder, checker, reducer, researcher, scout, writer) on its own branch, with a limit on the size of the change | Built | Planned: Tier 1 item 4, for plan stages as well as `/ck:do`, with the model set by the task |
| 5 | **`/ck:start` as a phase coordinator** | One session per phase: a card per ready stage, or auto mode for the whole phase, and a hand-over at the phase's end; `plan.py` prints the board, ready stages, and cards | Built | Partly: 0.1.17 puts up a chip per ready stage; no auto mode or phase hand-over |
| 6 | **`/ck:lean`** | Asks whether a branch's code is as little as it needs to be | Built | Not planned; a one-off lean review was done instead ([ck: is it lean?](https://claude.ai/artifact/PKCgiGsjZroKmLVXXEjuuB)) |
| 7 | **The cost script** | `cost.py` prices a piece of work from session transcripts, by stage, phase, agent, and model | Built | Planned: 0.1.19, `/ck:cost`, rebuilt small |
| 8 | **The cost report** | The cost as a published page with filters, by stage, lane, agent, model, and token type, with the dearest turns | Planned (ck2's only roadmap item) | Not planned: 0.1.19 prints a table |
| 9 | **The outcome loop** | A lean review that runs on its own at each phase's end, and every checker risk put to the stage's owner before the pull request reaches you | Planned (a proposal, two decisions open) | Not planned |
| 10 | **One config file** | `ck.conf` holds every model id and the core team, in place of `tiers.conf` | Built | Not planned: `tiers.conf` stays |
| 11 | **The writing rule at session start** | No em-dashes and plain technical English, in every session's context | Built | Covered: each project's "How we work" carries it (`/ck:claude-md`, 0.1.12) |
| 12 | **The style check** | `style.py` checks a document's headings, em-dashes, and word limits | Built | Not planned |
| 13 | **The instruction-file guard** | A hook refuses a `ck:` agent's edits to ck's own skills and profiles | Built; its Bash reader is in 0.1.13 | Partly: its Bash reader is inside 0.1.13's memory gate hook |
| 14 | **CI and Ruff** | The test suite and the lint check on every pull request, and a Run button when a merge is blocked | Built | Partly: CI on main since 2026-10-26; no Ruff |
| 15 | **Current models** | Opus 5.5 and Sonnet 5.5 for the craft and execution tiers | Built | Done: 0.1.15, with Haiku 5.5 for checkers |
| 16 | **Pipeline commands that stand alone** | Every pipeline command rebuilt on one shared loop (`pipeline.py`), each used on its own, with no required order and no pipeline table | Built | Not planned |
| 17 | **Shorter commands and fewer tests** | About 500 words per command, rare branches in a separate file; tests only for real code | Rules, applied in ck2's rewrite | In progress: 0.1.16 (`/ck:start`), 0.1.18 (`/ck:do`) |

Dropped with ck2: its 0.2.0 release plan, which would have replaced ck in the `code-katz` marketplace.

---

## Opportunities: Prioritized

### Tier 1: Ship Next

| # | Opportunity | Why Now | Success Signal |
|---|---|---|---|
| 1 | **Try the memory gate in d20mob** | It is released and on stable, but not yet tried by hand | A save shows the proposal ending "Reply 1, 2 or 3", then the approval prompt |
| 2 | **0.1.18: `/ck:do`** | It reads 2,737 words every time it is typed; whether to shorten it or remove it is being decided | The decision made, and the release on ck-next |
| 3 | **0.1.19: a small cost script** | Shows what work costs by session, persona and model, so a release's saving can be measured | `/ck:cost` prints d20mob's last 7 days |
| 4 | **Lanes: the model follows the task, not the persona** | A stage runs on its owner's tier, so Akira writes on Fable whether the job is a design call or a small edit, and each d20mob plan row needs a ruling to say otherwise. The V2 proposal (2026-10-13) designed lanes and ck2 built them (ck2 features, row 4); they are rebuilt from scratch | A plan's Who column names no model; in d20mob a stage runs its scout, builder and checker on the models one config file gives each lane, and its author on a model chosen for the job, with no per-row ruling |

### Tier 2: High Value, Plan for Next Sprint

| # | Opportunity | User Need | Assumptions to Validate |
|---|---|---|---|
| 1 | **The lean review's recommendations** ([ck: is it lean?](https://claude.ai/artifact/PKCgiGsjZroKmLVXXEjuuB)) | Fewer tokens per session and per command | Each one is weighed on its own, by tokens saved per week |

### Tier 3: Strategic / Longer Horizon

| # | Opportunity | Strategic Value | Why Not Now |
|---|---|---|---|
| 1 | `/ck:feature`, `/ck:bugfix`, `/ck:gtm` | Build from the definition | `/ck:plan`, `/ck:start` and `/ck:do` cover building now; ongoing work comes first |
| 2 | The 90-day persona prune | A roster sized by evidence | The usage log has not been read yet |

---

## Recommended Sequencing

```
Now:   try the memory gate in d20mob
Next:  0.1.18 (/ck:do) -> 0.1.19 (cost script) -> ck-next -> test -> stable
Then:  lanes -> ck-next -> a d20mob phase -> stable
Later: the lean review's recommendations
```

---

## Open Questions

1. Is the install drill on Clare's machine still wanted?
2. What happens to the ck2 repository: archive it on GitHub, or leave it as it is?
3. Is effort set per lane as well as the model, and where is it set?

---

## OKR

**Objective:** ck serves ongoing work in an active project with fewer steps and fewer tokens.

| Key Result | Target | Current |
|---|---|---|
| Releases tried in d20mob before they go stable | every release | 0.1.12 headless runs only; 0.1.13 and 0.1.14 waiting |
| Releases rolled back after going stable | 0 | 0 |

---

## Revision History

## [2026-10-27] Lanes added to Tier 1

**Change Type:** `add`
**Triggered by:** `planning-session`
**Items Affected:** Tier 1 item 4; ck2 features, row 4; Recommended Sequencing; Open Questions

### What Changed
Lanes are Tier 1 item 4, and row 4 of the ck2 features table moves from not planned to planned. A lane is a kind of task (scout, author, builder, writer, reducer, checker, coordinator) with its model, effort and tools set once in one file; a persona only judges and authors. The plan contract stops naming a model, and the author's model is chosen for the job rather than taken from the persona's tier. Lanes cover plan stages as well as `/ck:do`. The sequencing gains a Then line after 0.1.19, and Open Questions gains question 3.

### Why
You decided that a model should suit the task, not the persona. Released ck still sets it by persona (`skills/plan-artifact/SKILL.md`, the Who rule), which is why each d20mob plan row carries a hand ruling. ck2 built lanes, though its author lane still ran on the persona's tier.

### Open Questions Resolved / Added
- Added: is effort set per lane as well as the model, and where is it set?

---

## [2026-10-27] ck2's features listed, with where each stands

**Change Type:** `add`
**Triggered by:** `stakeholder-feedback`
**Items Affected:** a new section, ck2 features

### What Changed
Revision 3's table of ck2's 17 features is carried forward word for word, with a column for where each stands: done, partly done, planned, not planned, or removed, with the release that carries it.

### Why
You wanted the mapping from ck2 to ck kept in the roadmap, so the reason a ck2 feature is or is not in ck can be found later.

---

## [2026-10-27] The roadmap brought up to date after 0.1.14 to 0.1.17

**Change Type:** `complete`
**Triggered by:** `delivery`
**Items Affected:** Snapshot, Releases, Tier 1, Tier 2, Recommended Sequencing

### What Changed
0.1.15 is added to the Releases table, which had skipped it. Stable is on 0.1.17, not 0.1.12. Tier 1 is now trying the memory gate, 0.1.18 (`/ck:do`) and 0.1.19 (a cost script). The proof page tables shipped in 0.1.16, so Tier 2 now holds the lean review's recommendations.

### Why
Four releases in two days left the snapshot, the table and the tiers behind.

---

## [2026-10-27] 0.1.17: /ck:start puts up chips again

**Change Type:** `add`
**Triggered by:** `user-feedback`
**Items Affected:** Releases

### What Changed
0.1.17 is added to Releases. `/ck:start` opens a stage's session with the desktop app's `start_session` tool, as a chip the author clicks, in place of `spawn_task`, which the app no longer has. A fix to a finished stage gets a chip the same way.

### Why
In hireling on 2026-10-27, `/ck:start` found no `spawn_task` and printed blocks to paste. A coordinator on 2026-10-19 had already used `start_session` on its own; this makes every run do it.

---

## [2026-10-27] 0.1.16: a shorter /ck:start

**Change Type:** `add`
**Triggered by:** `planning-session`
**Items Affected:** Releases

### What Changed
0.1.16 is added to Releases. `/ck:start` reads 1,060 words on every run instead of 2,699: its rare branches (fix cards, the board refresh from sessions, merges, running/done/back/save, and the terminal fallback) move to their own files under `skills/start/`, each read only when its case comes up. The review page keeps a `|` inside a code span, or written as `\|`, in its table cell.

### Why
`/ck:start` is the command Will types most in d20mob, and all of it was read every time. The table fix mends rules such as `^(Write|Edit)$` that broke a table on the proof page.

---

## [2026-10-26] 0.1.15: current models

**Change Type:** `add`
**Triggered by:** `planning-session`
**Items Affected:** Tier 1 item 2; Recommended Sequencing

### What Changed
0.1.15 is added to Tier 1. It moves the craft seats from Opus 5 to Opus 5.5 (`claude-opus-5-5`), the execution seats from Sonnet 5 to Sonnet 5.5 (`claude-sonnet-5-5`), and every checker from Haiku 4.5 to Haiku 5.5 (`claude-haiku-5-5`). The judgment seats stay on Fable 5.1. It follows 0.1.14.

### Why
ck's personas and checkers were a model generation behind. The change is ids in `tiers.conf` and the workflows, and the files generated from them.

---

## [2026-10-26] 0.1.14: questions in the message

**Change Type:** `complete`
**Triggered by:** `delivery`
**Items Affected:** Tier 1; Tier 2 item 1; Releases; Open Questions

### What Changed
0.1.14 is released to ck-next. The memory gate ends its proposal with numbered choices and "Reply 1, 2 or 3", in the message itself, and the "How we work" template (0.1.14) says to ask in the message, never in the app's next-step box or its buttons. Tier 1 is now testing 0.1.14 and promoting it to stable; 0.1.13 goes to stable with it. Tier 2 item 1, the short global CLAUDE.md, is removed: it is done, and `~/.claude/CLAUDE.md` is empty. Its open question goes with it.

### Why
The app collapsed the message that held the box, and you could not see the choices. A question in the message is always on screen.

### Open Questions Resolved / Added
- Resolved: where the short global CLAUDE.md lives → nowhere; the global file is empty.

---

## [2026-10-26] Main is 0.1.13 again; ck2's candidates dropped

**Change Type:** `reframe`
**Triggered by:** `strategy-shift`
**Items Affected:** every section

### What Changed
Main now holds exactly ck 0.1.13, merged from `release/0.1`, plus this roadmap and the CI file. Everything main held from 2026-10-12 to 10-17 that was in no release is gone from its files. The ck2 candidates and the table of main's unreleased commits are dropped. Releases are made from main again, and `release/0.1` is retired. Tier 1 is testing 0.1.13 and building 0.1.14.

### Why
You want to iterate on ck release by release. Any ck2 feature you decide to build starts from scratch, so neither ck2's features nor main's leftovers need keeping. With main equal to the current release, the separate release branch has no reason left.

### Open Questions Resolved / Added
- Resolved: which ck2 candidate is next → none; ck2 features are rebuilt from scratch if wanted.
- Resolved: what to do with main's unreleased commits → their files are gone; they stay only in the history.

---

## [2026-10-26] ck2 candidates reviewed

**Change Type:** `reprioritize`
**Triggered by:** `planning-session`
**Items Affected:** Candidates from ck2; Tier 2; Unreleased commits on main

### What Changed
Each ck2 candidate is kept with a tier, or removed with the files on main that hold it.
- Candidate 1, a team per project: kept, Tier 2. Its proposal stays as the design (row 12); its plan is deleted (row 18).
- Candidate 2, `/ck:proof`: removed, because 0.1.13 already makes a proof page for any document. Both proof proposals are deleted (rows 1, 16); row 20 changed the deleted plan. The proof code on main (rows 4, 7, 8, 15) is decided on its own.
- Main's proof code (rows 4, 7, 8, 15): undone, so main's proof page, renderer and skills match 0.1.10 again; the document contract and the stage checks for these commits are deleted. Row 7's fixes and key check are Tier 2 item 5.

### Why
Tidying the roadmap and main after ck2 was abandoned: what is kept is recorded with its priority, and what is not is deleted.

---

## [2026-10-26] Six of main's unreleased commits removed

**Change Type:** `remove`
**Triggered by:** `planning-session`
**Items Affected:** Unreleased commits on main, rows 1, 5, 9, 11, 14, 17, 19

### What Changed
The six commits that match no ck2 candidate are decided. The five plan status commits (rows 5, 11, 14, 17, 19) are removed by deleting the plan they edited, "Any document as a proof", which also takes the plan from row 1. The publish guard (row 9) is deleted with its check. The table gains a Decided column; the other 13 rows are open.

### Why
The plan stopped on 2026-10-17 and still said a stage was running. The guard was dropped from the rewrite on 2026-10-17 (ck is for productivity, not security), and no command calls it.

### Open Questions Resolved / Added
- Resolved: what to do with the commits that match no ck2 candidate → remove what they changed, keep the history.
- Added: the two check files left under `tests/pending/` (P1-S4, P1-S5) wait for stages of the deleted plan.

---

## [2026-10-26] ck2 abandoned; the releases from 0.1.1 to 0.1.13; ck2's candidates and main's unreleased commits

**Change Type:** `snapshot`
**Triggered by:** `delivery`
**Items Affected:** every tier; new tables for releases, ck2 candidates, and main's unreleased commits

### What Changed
ck2 is abandoned. Its 17 features are listed as candidates for releases on `release/0.1`, and main's 20 unreleased commits are listed with the candidate each overlaps. The roadmap had not changed since 2026-09-09. Every item in the old Tier 1 is done: the drills (2026-10-01 to 2026-10-05), the PRD drill, the remaining contracts and scripts, and the marketplace entry. A Releases table lists 0.1.1 to 0.1.13. The snapshot describes the release scheme and the two channels. The old Tier 2 items (`/ck:feature` and the rest, `/ck:map` and `/ck:report`, routines) move to Tier 3. The new Tier 1 is testing 0.1.13, picking 0.1.14 from the ck2 candidates, and sorting main's unreleased commits.

### Why
You decided on 2026-10-26 to abandon ck2: releases since 0.1.10 grow on `release/0.1`, and ck2's ideas come back only as releases there. Since 2026-10-17 the aim is ongoing work in an active project, so the phase-two pipeline commands wait.

### Open Questions Resolved / Added
- Folded in: the two Clare checks and the manual-mode question now sit under question 3.
- Added: which ck2 candidate is 0.1.14; what happens to the ck2 repository; where the short global CLAUDE.md lives; whether the install drill on Clare's machine is still wanted.

---

## [2026-09-09] First roadmap, from the phase-one PRD

### What Changed
Created with the skeleton commit.

### Why
The PRD's §10 phasing, translated into the roadmap skill's tiers.

### Open Questions Resolved / Added
Added the two Clare checks and the manual-mode consent question.

### Change Types
- [x] New opportunity added

### Triggered By
The `ck` repository's first commit.
