# ck: Product Roadmap

> Maintained by [claude-roadmap-skill](https://github.com/code-katz/claude-roadmap-skill). Last updated: 2026-10-26.

---

## Current Roadmap

## Current State Snapshot

**What works well:**
- The product pipeline (opportunity, market research, brief, PRD, team, roadmap, architecture, brand guide, design), drilled on real projects from 2026-10-01 to 2026-10-05.
- `/ck:plan`, `/ck:start` and `/ck:do`, used in d20mob and hireling since 0.1.10.
- Releases have a scheme (since 2026-10-19): they grow on `release/0.1`, cut from tag `v0.1.10`. Each release is a tag, a GitHub release, and a version bump. `main` is a record of ideas; nothing ships from it.
- Two channels: stable (the `code-katz` marketplace, pinned to `v0.1.12`) and ck-next (a local marketplace, on `v0.1.13`, used by d20mob, hireling and the ck folder). Rollback in a project is two commands.
- `/ck:claude-md` (0.1.12) writes a project's "How we work" from ck's template and sorts its memory.
- The memory gate (0.1.13): a proposal and an approval before any memory is saved.

**What's missing or fragile:**
- 0.1.13 has not yet been tried in an interactive session.
- `release/0.1` has no CI. Auto mode refuses to push a tag or create a GitHub release, so you run that step by hand.
- ck2 is abandoned (2026-10-26). It was a rewrite in its own repository, frozen on 2026-10-19 and never released. Nothing more is built there. Its features are listed under "Candidates from ck2"; one comes back only as a release of its own, when you pick it. So far only ck2's guard has come back, inside 0.1.13's hook.
- `main` still says 0.1.10, by design: releases are built on `release/0.1`. It also holds 20 commits made from 2026-10-12 to 10-17, before the release scheme, that are in no release. They are listed under "Unreleased commits on main" for you to sort.
- The install drill on a second machine (Clare's) has not been done.

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
| 0.1.10 | 2026-10-12 | `/ck:do`, `/ck:plan`, `/ck:start` | Tag `v0.1.10`, the base of `release/0.1` |
| 0.1.11 | 2026-10-19 | The question rule at session start | Tag `v0.1.11`; reverted on `release/0.1`, not coming back |
| 0.1.12 | 2026-10-26 | `/ck:claude-md` | Tag `v0.1.12`; stable |
| 0.1.13 | 2026-10-26 | The memory gate | Tag `v0.1.13`; ck-next, under test |

---

## Candidates from ck2

ck2 is abandoned. These are its features, as candidates for a release on `release/0.1`. Built means it ran in ck2; planned means it was written down and never built.

| # | Feature | What it does | In ck2 |
|---|---|---|---|
| 1 | **A team per project** | `.claude/ck-team.conf` invites or drops personas; `/ck:team` shows and changes it; every session is told who is on the team | Built |
| 2 | **`/ck:proof`** | Any file, or a document written from a request, becomes a page you comment on until approved; with the proof loop rules and one document contract for a proposal, an analysis, or a note | Built |
| 3 | **Ask the owner first** | Before a judgment question reaches you, the stage's owning persona answers it on its own model, and the session asks with "<Owner> recommends" | Built |
| 4 | **Lanes for `/ck:do`** | A small task runs in background lanes (builder, checker, reducer, researcher, scout, writer) on its own branch, with a limit on the size of the change | Built |
| 5 | **`/ck:start` as a phase coordinator** | One session per phase: a card per ready stage, or auto mode for the whole phase, and a hand-over at the phase's end; `plan.py` prints the board, ready stages, and cards | Built |
| 6 | **`/ck:lean`** | Asks whether a branch's code is as little as it needs to be | Built |
| 7 | **The cost script** | `cost.py` prices a piece of work from session transcripts, by stage, phase, agent, and model | Built |
| 8 | **The cost report** | The cost as a published page with filters, by stage, lane, agent, model, and token type, with the dearest turns | Planned (ck2's only roadmap item) |
| 9 | **The outcome loop** | A lean review that runs on its own at each phase's end, and every checker risk put to the stage's owner before the pull request reaches you | Planned (a proposal, two decisions open) |
| 10 | **One config file** | `ck.conf` holds every model id and the core team, in place of `tiers.conf` | Built |
| 11 | **The writing rule at session start** | No em-dashes and plain technical English, in every session's context | Built |
| 12 | **The style check** | `style.py` checks a document's headings, em-dashes, and word limits | Built |
| 13 | **The instruction-file guard** | A hook refuses a `ck:` agent's edits to ck's own skills and profiles | Built; its Bash reader is in 0.1.13 |
| 14 | **CI and Ruff** | The test suite and the lint check on every pull request, and a Run button when a merge is blocked | Built |
| 15 | **Current models** | Opus 5.5 and Sonnet 5.5 for the craft and execution tiers | Built |
| 16 | **Pipeline commands that stand alone** | Every pipeline command rebuilt on one shared loop (`pipeline.py`), each used on its own, with no required order and no pipeline table | Built |
| 17 | **Shorter commands and fewer tests** | About 500 words per command, rare branches in a separate file; tests only for real code | Rules, applied in ck2's rewrite |

Dropped with ck2: its 0.2.0 release plan, which would have replaced ck in the `code-katz` marketplace.

---

## Unreleased commits on main

Made from 2026-10-12 to 10-17, before the release scheme. None is in a release. Most were rebuilt in ck2, so each overlaps a candidate above.

| # | Commit | Date | What it is | Kind | Same as ck2 candidate | Decided |
|---|---|---|---|---|---|---|
| 1 | `81bfa62` | 10-12 | Plan: any document as a proof, with its proposal | Plan | 2 | Plan removed (2026-10-26); its proposal waits on candidate 2 |
| 2 | `42b821a` | 10-12 | Ruff lint rules, and six findings cleared | Code | 14 | Open |
| 3 | `6d3f523` | 10-12 | The lint gate, and a check file for every later stage | Code | 14 (the per-stage checks were dropped in ck2) | Open |
| 4 | `5901660` | 10-12 | The comment page renamed the proof, with a new renderer, `render-proof.py` | Code | 2 | Open |
| 5 | `603b080` | 10-12 | Plan status: P0-S1 running | Bookkeeping | None | Removed: the proof plan is deleted (2026-10-26) |
| 6 | `60f379b` | 10-12 | CI: run the suite on every pull request and on main | Code | 14 | Open |
| 7 | `4d147f4` | 10-12 | Renderer fixes, a refusal of seven key shapes, the four comment steps | Code | 2 (ck2 kept the key check) | Open |
| 8 | `d719e2d` | 10-12 | The document contract for a proposal, an analysis, and a note | Code | 2 | Open |
| 9 | `0659e5f` | 10-12 | The publish guard | Code | None (dropped in ck2) | Removed: the guard and its check are deleted (2026-10-26) |
| 10 | `3e4b155` | 10-13 | Proposal: ck V2, lanes under personas | Proposal | 4 | Open |
| 11 | `7786c0c` | 10-13 | Plan status: save the proof plan's changes | Bookkeeping | None | Removed: the proof plan is deleted (2026-10-26) |
| 12 | `72608ce` | 10-16 | Plan status, and the proposal for a team per project | Proposal | 1 | Open |
| 13 | `e3141ec` | 10-16 | Move the tiers to current models | Code | 15 | Open |
| 14 | `6e64f85` | 10-17 | Plan status: P0-S4 done | Bookkeeping | None | Removed: the proof plan is deleted (2026-10-26) |
| 15 | `2b5fdbb` | 10-17 | The proof loop's rules, and the comment steps on a gallery | Code | 2 | Open |
| 16 | `8da98bb` | 10-17 | Proposal: the smallest proof | Proposal | 2 | Open |
| 17 | `2d25800` | 10-17 | Plan status: P1-S2 running | Bookkeeping | None | Removed: the proof plan is deleted (2026-10-26) |
| 18 | `6a90361` | 10-17 | Plan: a team per project | Plan | 1 | Open |
| 19 | `a0acd8f` | 10-17 | Plan status: P1-S2 done | Bookkeeping | None | Removed: the proof plan is deleted (2026-10-26) |
| 20 | `9175df4` | 10-17 | Plan: the smallest proof, replanned | Plan | 2 | Open |

In short: 9 code commits, 3 plans, 3 proposals, 5 bookkeeping. The code is all proof, CI, lint, or model work.

A commit on main is never cut out of its history: that would rebuild every later commit and force-push main. Removing a commit here means removing what it changed, in a new commit.

---

## Opportunities: Prioritized

Proposed tiers. Every tier is your call.

### Tier 1: Ship Next

| # | Opportunity | Why Now | Success Signal |
|---|---|---|---|
| 1 | **Test 0.1.13 and promote it to stable** | It is built and released, but not yet tried by hand | In d20mob, a save shows the proposal and then the approval prompt; the `code-katz` pin moves to `v0.1.13` |
| 2 | **Pick 0.1.14 from the ck2 candidates** | ck2 is abandoned, so its features come back only as releases here, one at a time | One candidate chosen, designed on a proof page, and released to ck-next |
| 3 | **Sort main's 20 unreleased commits** | Each overlaps a ck2 candidate or is bookkeeping, so it may be easier to bring a feature in from ck2 than from main | Each row of the table is marked: bring in from main, take the ck2 version instead, or leave as a record |

### Tier 2: High Value, Plan for Next Sprint

| # | Opportunity | User Need | Assumptions to Validate |
|---|---|---|---|
| 1 | **A short global CLAUDE.md** ("How we work with Will", about 400 words, replacing the old team tool's 4,150) | About 5,000 fewer tokens in every session in every project, and no roster greeting or mode menu | The lessons d20mob, ck and hireling each learned can live in one place without losing project facts |
| 2 | **CI on `release/0.1`** (ck2 candidate 14; main commit 6) | Each pull request shows its checks before you say merge | Auto mode still refuses the tag push with CI in place; CI only helps the merge |
| 3 | **The cost report** (ck2 candidates 7 and 8) | See where tokens go, by stage, lane, agent and model | `cost.py` can match lanes to stages reliably |

### Tier 3: Strategic / Longer Horizon

| # | Opportunity | Strategic Value | Why Not Now |
|---|---|---|---|
| 1 | `/ck:feature`, `/ck:bugfix`, `/ck:gtm` | Build from the definition | `/ck:plan`, `/ck:start` and `/ck:do` cover building now; the rewrite aim puts ongoing work first |
| 2 | `/ck:map`, `/ck:report`, and routines for market research | See the catalog and spend; scheduled research | The cost report comes first |
| 3 | The Workbench, a local place to see and edit everything | One place for plans, runs and documents | Too big for one release at a time |
| 4 | The 90-day persona prune | A roster sized by evidence | The usage log has not been read yet |

---

## Recommended Sequencing

```
Now:   test 0.1.13 in d20mob -> promote to stable
Next:  pick 0.1.14 from the ck2 candidates -> design on a proof -> build -> ck-next -> test -> stable
Also:  sort main's 20 commits (a short proof, one row per commit)
Later: global CLAUDE.md, CI on release/0.1, cost report
```

---

## Open Questions

1. Which ck2 candidate is 0.1.14? The table lists 17.
2. Does the short global CLAUDE.md belong in ck (as a template, like "How we work"), or is it a one-off edit of your own file?
3. Is the install drill on Clare's machine still wanted?
4. What happens to the ck2 repository: archive it on GitHub, or leave it as it is? Only the ck2 folder itself still turns on its plugin.

---

## OKR

**Objective:** ck serves ongoing work in an active project with fewer steps and fewer tokens.

| Key Result | Target | Current |
|---|---|---|
| Releases tried in d20mob before they go stable | every release | 0.1.12 headless runs only; 0.1.13 waiting |
| ck2 candidates brought back as releases | one per release | 1 (the guard's Bash reader, in 0.1.13) |
| Releases rolled back after going stable | 0 | 0 |

---

## Revision History

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
