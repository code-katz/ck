# ck: Product Roadmap

> Maintained by [claude-roadmap-skill](https://github.com/code-katz/claude-roadmap-skill). Last updated: 2026-10-26.

---

## Current Roadmap

## Current State Snapshot

**What works well:**
- The product pipeline (opportunity, market research, brief, PRD, team, roadmap, architecture, brand guide, design), drilled on real projects from 2026-10-01 to 2026-10-05.
- `/ck:plan`, `/ck:start` and `/ck:do`, used in d20mob and hireling since 0.1.10.
- `/ck:claude-md` (0.1.12) writes a project's "How we work" from ck's template and sorts its memory.
- The memory gate (0.1.13): a proposal and an approval before any memory is saved.
- Main is ck 0.1.13 again (2026-10-26). Each release is a branch from main, a pull request into main, a tag on main, and a GitHub release. The tests run on every pull request.
- Two channels: stable (the `code-katz` marketplace, pinned to `v0.1.12`) and ck-next (a local marketplace, on `v0.1.14`, used by d20mob, hireling and the ck folder). Rollback in a project is two commands.

**What's missing or fragile:**
- 0.1.13 and 0.1.14 have not yet been tried in an interactive session.
- Auto mode refuses to push a tag or create a GitHub release, so you run that step by hand.
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
| 0.1.12 | 2026-10-26 | `/ck:claude-md` | Tag `v0.1.12`; stable |
| 0.1.13 | 2026-10-26 | The memory gate | Tag `v0.1.13` |
| 0.1.14 | 2026-10-26 | Questions in the message, never in the app's box | Tag `v0.1.14`; ck-next, under test |

---

## Opportunities: Prioritized

### Tier 1: Ship Next

| # | Opportunity | Why Now | Success Signal |
|---|---|---|---|
| 1 | **Test 0.1.14 and promote it to stable** | It is released, but not yet tried by hand | In d20mob, a save shows the proposal ending "Reply 1, 2 or 3" and then the approval prompt; the `code-katz` pin moves to `v0.1.14` |
| 2 | **0.1.15: current models** | Craft runs on Opus 5, execution on Sonnet 5 and checkers on Haiku 4.5, a generation behind; Fable 5.1 stays | `tiers.conf` names `claude-opus-5-5` and `claude-sonnet-5-5`, every checker runs on `claude-haiku-5-5`, and a ck persona agent in d20mob reports the new model |

### Tier 2: High Value, Plan for Next Sprint

| # | Opportunity | User Need | Assumptions to Validate |
|---|---|---|---|
| 1 | **Proof page tables** | A `\|` inside code in a table cell breaks the table on a proof page | A small fix to `render-review.py` |

### Tier 3: Strategic / Longer Horizon

| # | Opportunity | Strategic Value | Why Not Now |
|---|---|---|---|
| 1 | `/ck:feature`, `/ck:bugfix`, `/ck:gtm` | Build from the definition | `/ck:plan`, `/ck:start` and `/ck:do` cover building now; ongoing work comes first |
| 2 | The 90-day persona prune | A roster sized by evidence | The usage log has not been read yet |

---

## Recommended Sequencing

```
Now:   test 0.1.14 in d20mob -> promote to stable
Next:  0.1.15 (current models) -> ck-next -> test -> stable
Later: the proof page tables
```

---

## Open Questions

1. Is the install drill on Clare's machine still wanted?
2. What happens to the ck2 repository: archive it on GitHub, or leave it as it is?

---

## OKR

**Objective:** ck serves ongoing work in an active project with fewer steps and fewer tokens.

| Key Result | Target | Current |
|---|---|---|
| Releases tried in d20mob before they go stable | every release | 0.1.12 headless runs only; 0.1.13 and 0.1.14 waiting |
| Releases rolled back after going stable | 0 | 0 |

---

## Revision History

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
