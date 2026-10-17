# Proposal: the smallest proof

Date: 2026-10-17. Status: approved 2026-10-17.

## In one sentence

Cut `/ck:proof` down to render, publish, comment, approve, and drop from the release everything that costs you a step or a stage without saving one.

## Decisions for you

None open. All five decided on 2026-10-17, each as recommended.

| # | Decision | Choices | Decided |
|---|---|---|---|
| D1 | The publish guard | Delete the script and its fixtures; the one refusal worth keeping, a pipeline document has its own command, becomes a sentence in the skill (recommended: it is the only refusal that saves a step); keep the script as built | Delete the script; the pipeline-document refusal becomes a sentence in the skill, 2026-10-17 |
| D2 | The key check in the renderer | Keep it as built (recommended: it is merged, runs in Python, and costs no tokens per run); remove it | Keep it as built, 2026-10-17 |
| D3 | A run record for a proof | None: the same session republishes to the same link by file path, and a new session finds the page with the Artifact tool's listing by title (recommended: no `.ck/runs/` folder, no mint step, no resume listing); keep the record for a resume across sessions | None, 2026-10-17 |
| D4 | What is left of the plan | One documentation stage, with the devlog entry folded in, then you use it (recommended: the suite is the check, and your first real use is the drill); keep the security read, the drill, and the drill log | One documentation stage with the devlog entry folded in, then use it, 2026-10-17 |
| D5 | Pull request 36 | Close it unmerged and replace it with the one stage below (recommended: half of what it wrote is cut); merge it, then strip | Close it unmerged and replace it, 2026-10-17 |

## Why

The release grew by habit. The pipeline skills have a run record, a resume listing, a mint step, and a close through `/ck:next`, because a workflow of several agents needs them; `/ck:proof` runs no agent, and carried them anyway. The checks were written before the command, which fixed that shape before anyone asked what size it should be. Two of the ten steps, the guard and the key check, and two of the remaining five stages, the security read and the drill log, are controls against publishing a private file, and you said on 2026-10-17 that ck is a productivity and token optimization tool, not a security one. What is built today works and the suite passes; the cost is the steps and the stages still ahead, and a skill of 1,400 words read on every run.

## What changes

| # | Change | Done when | Where |
|---|---|---|---|
| C1 | The skill shrinks to four steps: take the file or write the document, render, review per the loop, lock at approved | The skill is under 300 words and names the loop and the contract, nothing else | `skills/proof/SKILL.md` |
| C2 | The guard goes, per D1 | No file names `proof-guard.py`; the suite passes | `scripts/proof-guard.py`, `tests/fixtures/guard/`, `tests/checks/P1-S1.sh`, `tests/run.sh` |
| C3 | The proof's checks match the four steps | `tests/checks/P1-S4.sh` reads the skill for the four steps and the plan refusal, and nothing about a run, a guard, or a word count | `tests/checks/P1-S4.sh` |
| C4 | The loop saves the link in the run record only when there is one | `skills/proof-loop/SKILL.md` says what a skill with no record does | `skills/proof-loop/SKILL.md` |
| C5 | The plan is revised: one stage replaces P1-S4, P1-S5 absorbs P2-S4, and P2-S0 to P2-S3 are struck, per D4 | `scripts/plan.py check` passes on it, and `/ck:start` shows one stage that could start now | `docs/plan/2026-10-12-any-document-as-a-proof.md`, `tests/pending/P1-S5.sh` |
| C6 | The document contract loses its word budget rows, and nothing else | The contract has no size column | `skills/doc-artifact/SKILL.md`, `tests/checks/P1-S3.sh` |

## Not doing

- **Not undoing the merged stages that save you steps.** The rename, the renderer's two fixes, the comment steps, and the loop's rules for a comment queued to Claude stay: they are why a proof is cheaper than pasting a comment into the session.
- **Not dropping the contract.** It is one file the skill points at, and a document that opens with the decisions is shorter to read and to review. Only its word budgets go.
- **Not keeping plan-mode plans out.** With no guard there is no location rule: `/ck:proof` with nothing after it renders the plan this session wrote in plan mode, where it is, and publishes it. Nothing is copied.
- **Not reopening the four decisions of 2026-10-11.** Name, folders, what approved does, and how you comment all stand.

## What could go wrong

- **C2.** A path outside the repository or a git-ignored file can be published if you type it. Accepted: you type the path, and the page is private to your account.
- **D3.** A second session on one proof has to find the page by title; two documents with one title give two pages. Limited by the contract's `# <Kind>: <subject>` first line, which is the title.
- **C5.** A plan revision moves done rows; `plan.py` keeps their ids and states, as it did on 2026-10-12.
- **C3.** Tightening-only was the rule for checks; this rewrites one. Accepted: the rule guards a stage against itself, and this is the author changing the plan.

## How we will know it worked

- `/ck:proof <request>` in a test project gives you a page in one turn, with no question asked before the link.
- `/ck:proof` after a plan-mode plan gives you that plan as a page, uncopied.
- `bash tests/run.sh` passes with no check file left under `tests/pending/` after the one stage.
- The skill reads in under a minute.

## Open questions

- Does the Artifact tool's listing find a page by title reliably enough for a second session to republish to it? Assumed meanwhile: yes, as its documentation says; if not, D3 flips to keeping the record.

## What I read

- `docs/proposal/2026-10-11-any-document-as-a-proof.md`, `docs/plan/2026-10-12-any-document-as-a-proof.md`
- `skills/proof/SKILL.md` as written in pull request 36, `skills/proof-loop/SKILL.md`, `skills/doc-artifact/SKILL.md`, `scripts/proof-guard.py`, `tests/checks/P1-S4.sh`, `tests/pending/P1-S5.sh`, `tests/run.sh` (sections 11, 15, 21, 22)
- Will's words in this session, 2026-10-17: ck is a productivity and token optimization tool; too much is being built into it.
- Not checked: the Artifact tool's listing by title across sessions; the exact word count of the skill after C1.
