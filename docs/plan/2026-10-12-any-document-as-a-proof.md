# Staged plan: Any document as a proof

Date: 2026-10-17. Status: approved 2026-10-17.
Item: PROOF
Reads: `docs/proposal/2026-10-11-any-document-as-a-proof.md`, `docs/proposal/2026-10-17-the-smallest-proof.md`, `docs/plan/2026-10-12-any-document-as-a-proof.md` (the plan of 2026-10-12), `skills/proof-loop/SKILL.md`, `skills/doc-artifact/SKILL.md`, `skills/plan-artifact/SKILL.md`, `skills/roster/SKILL.md`, `tests/pending/P1-S4.sh`, `tests/pending/P1-S5.sh`, `tests/run.sh`

## What this covers

The `/ck:proof` command, and what every proof gains with it: the new name, two faults mended in the page renderer, a check for keys before a page is made, and the rules for a comment queued for Claude. It was built from the approved proposal of 2026-10-11, and is cut down here by the approved proposal of 2026-10-17, the smallest proof: the command shrinks to four steps, the publish guard goes, a proof keeps no run record, and what was left of the plan becomes one build stage, one documentation stage with the devlog entry folded in, and your first real use. Phase 2 of the plan of 2026-10-12 is struck: the check against the proposal, the security read, the drill, and the drill log do not run; the suite is the check, and your first real use is the drill. Every stage before this revision keeps its id and its state. A stage is done when its checks pass and it has moved its file from `tests/pending/` to `tests/checks/`, where the suite counts them. The highlighting of changes on a revised proof is a separate item and is not in this plan.

## Phases

### Phase 0. Ground

The names and the checks are put in place before anything is built. When it ends, every proof you open says "proof" above its title, and the suite lists the checks that are still waiting for their stage.

| Stage | What | Who | State |
|---|---|---|---|
| P0-S0 | The staged-plan release merged, pull request 25 | You | done (25) |
| P0-S1 | The lint gate, a waiting state for the suite, and the checks for every later stage | Robin, Opus | done (26) |
| P0-S2 | The review page renamed to the proof, everywhere | Sasha, Sonnet | done (27) |
| P0-S3 | A check that runs the suite on every pull request | Alex, Sonnet | done (28) |
| P0-S4 | The tier file and every model id moved to the current models | Alex, Sonnet | done (34) |

Ends when: a proof you open says "proof" above its title, and the suite passes while it lists the checks still waiting.

### Phase 1. Build

The page is made safer, the command is written at its smallest size, and you use it. When it ends, typing `/ck:proof` with a request gives you a proof in one turn, with no question asked before the link.

| Stage | What | Who | State |
|---|---|---|---|
| P1-S0 | The page renderer: two faults mended, a check for keys, the new comment steps on a proof | Sasha, Sonnet | done (30) |
| P1-S1 | The guard that refuses a file a proof must not publish | Akira, Fable | done (32) |
| P1-S2 | The loop's rules, and the new comment steps on a gallery | Akira, Fable | done (35) |
| P1-S3 | The contract every document from the command follows | Kai, Opus | done (31) |
| P1-S4 | The proof command itself, for a new document and for a file that exists | Akira, Fable | running in its session |
| P1-S5 | The command cut to four steps, the guard gone, the loop and the contract trimmed | Akira, Fable | not started; could start now |
| P1-S6 | The documentation, the version, and the release's entry in the development log | Quinn, Sonnet | not started; follows S5 |
| P1-S7 | Your first real proof, and the plan-mode plan as a page | You | not started; follows S6 |

Ends when: in a test project, `/ck:proof` with a request gives you a page in one turn, `/ck:proof` after a plan-mode plan gives you that plan as a page, and the suite passes with no check file left under `tests/pending/`.

## Stage by stage

### P0-S0. Merge the staged-plan release

- Kind: yours
- Does: Says "merge" for pull request 25 in the session that owns it. Every later stage is built on what it adds, and `/ck:start` comes with it.
- Files: none
- Reads: `DEVLOG.md`
- Follows: nothing
- Done when: pull request 25 is merged and the installed plugin is that version.
- Hands back: nothing

### P0-S1. Write the checks first

- Kind: build
- Does: Writes the lint gate as the suite's next section, rewritten from commit `f466efd` on the branch `review-highlights` and not cherry-picked, clears what it finds in the Python on main, and makes the suite run a check file under `tests/pending/` as waiting and one under `tests/checks/` as counted. Writes one check file per later stage, each needing only that stage's work, with the four comment steps' exact text in one fixture, and with every key-shaped file and the guard's repository built at run time, never committed.
- Files: `tests/`, `ruff.toml`, `README.md`, `scripts/render-review.py`, `scripts/plan.py`
- Reads: `docs/proposal/2026-10-11-any-document-as-a-proof.md`, `tests/run.sh`, `tests/workflows.mjs`
- Follows: S0
- Done when: `bash tests/run.sh` passes; a throwaway check shows the waiting state, and a waiting file whose checks all pass fails the suite; every check in a waiting file fails on this tree for the reason its stage will mend; and no check that passes today is in a waiting file, except the two that look for the old comment step, which move to the stages that reverse them.
- Hands back: a draft pull request
- With: Akira

### P0-S2. Rename the page to proof

- Kind: build
- Does: Renames the review page to the proof: the line above the title, the loop skill's folder, the renderer's file name, and every reference to them, the staged-plan and quick-path commands' included. The two checks that forbid the old names forbid the new ones instead, and file names inside a run folder stay, so a run in progress still resumes.
- Files: `skills/`, `scripts/render-review.py`, `scripts/render-proof.py`, `tests/run.sh`, `README.md`, `ROADMAP.md`, `tests/pending/P0-S2.sh`, `tests/checks/P0-S2.sh`
- Reads: `docs/proposal/2026-10-11-any-document-as-a-proof.md`, `tests/pending/P0-S2.sh`, `skills/review-page/SKILL.md`
- Follows: S1
- Done when: its check file passes and is moved to `tests/checks/`, the suite passes, and the old name is left only in the drill logs and old devlog entries.
- Hands back: a draft pull request

### P0-S3. Run the suite on pull requests

- Kind: build
- Does: Adds a check that runs `bash tests/run.sh` on every pull request and on main, so each stage's pull request shows whether the suite passes on the merged tree. The proposal does not have this; the author added it when this plan was reviewed.
- Files: `.github/workflows/`
- Reads: `tests/run.sh`, `README.md`
- Follows: S1
- Done when: a pull request shows the suite's result as a check, and a deliberate failure on a scratch branch turns it red.
- Hands back: a draft pull request

### P0-S4. Move tiers to current models

- Kind: build
- Does: Moves every model id ck sets to the current models: `claude-opus-5` to `claude-opus-5-5`, `claude-sonnet-5` to `claude-sonnet-5-5`, and the validators' `claude-haiku-4-5-20251001` to `claude-haiku-5-5`. Fable stays `claude-fable-5-1`. Edits `tiers.conf` and the ids written into the workflows and skills, regenerates the agents and the roster, and updates the README's Models table and the suite's tier checks to match. The panel keeps three different models. Changes no prompt, no persona's tier, and no stage of this plan.
- Files: `tiers.conf`, `workflows/*.js`, `skills/architecture/SKILL.md`, `skills/start/SKILL.md`, `agents/`, `skills/roster/SKILL.md`, `profiles/ROSTER.md`, `README.md`, `tests/run.sh`, `tests/pending/P0-S4.sh`, `tests/checks/P0-S4.sh`
- Reads: `tests/pending/P0-S4.sh`, `scripts/generate.sh`, `workflows/panel.js`, `workflows/draft.js`
- Follows: nothing
- Done when: its check file passes and is moved to `tests/checks/`, and the suite passes.
- Hands back: a draft pull request

### P1-S0. Mend and guard the renderer

- Kind: build
- Does: Mends two faults in the page renderer: a quote in a link address, and a bar inside a table cell, whether it is written with a backslash or sits in a code span. Makes it refuse a file that holds a known key shape, and writes the four new comment steps on the proof, letter for letter from the fixture.
- Files: `scripts/render-proof.py`, `tests/fixtures/proof/`, `tests/pending/P1-S0.sh`, `tests/checks/P1-S0.sh`
- Reads: `docs/proposal/2026-10-11-any-document-as-a-proof.md`, `tests/pending/P1-S0.sh`, `tests/fixtures/proof/`
- Follows: P0-S2
- Done when: its check file passes and is moved to `tests/checks/`, and the suite passes.
- Hands back: a draft pull request
- With: Morgan

### P1-S1. Build the publish guard

- Kind: build
- Does: Writes the one command that refuses a file a proof must not publish: outside the repository, not markdown, ignored by git, inside the run cache, empty, or owned by a pipeline command, which is every path `/ck:next` lists and the two plan paths. Each refusal is one sentence that names the reason and repeats nothing from inside the file.
- Files: `scripts/proof-guard.py`, `tests/fixtures/guard/`, `tests/pending/P1-S1.sh`, `tests/checks/P1-S1.sh`
- Reads: `docs/proposal/2026-10-11-any-document-as-a-proof.md`, `tests/pending/P1-S1.sh`, `skills/next/SKILL.md`, `skills/plan-artifact/SKILL.md`
- Follows: P0-S2
- Done when: its check file passes and is moved to `tests/checks/`, and the suite passes.
- Hands back: a draft pull request
- With: Morgan

### P1-S2. Write the loop's rules

- Kind: build
- Does: Writes the loop's rules into the loop skill: the six for a queued comment, one published file, the proof's link saved in the run record, a document locked only by "approved" typed in the session, and the Claude Code version a queued comment needs. Writes the four new comment steps for a gallery, letter for letter from the fixture: its renderer's banner, the gallery contract, and the two workflow checks.
- Files: `skills/proof-loop/SKILL.md`, `skills/gallery-artifact/SKILL.md`, `scripts/render-gallery.py`, `workflows/brand.js`, `workflows/design-round.js`, `tests/pending/P1-S2.sh`, `tests/checks/P1-S2.sh`
- Reads: `docs/proposal/2026-10-11-any-document-as-a-proof.md`, `tests/pending/P1-S2.sh`, `tests/fixtures/proof/`, `tests/drill/2026-10-03.md`
- Follows: P0-S2 and P0-S4
- Done when: its check file passes and is moved to `tests/checks/`, and the suite passes.
- Hands back: a draft pull request

### P1-S3. Write the document contract

- Kind: build
- Does: Writes the one contract for a proposal, an analysis, and a note: each opens with one sentence and then the decisions the reader must make, and ends with the open questions and what was read. Says how the three kinds differ.
- Files: `skills/doc-artifact/SKILL.md`, `tests/pending/P1-S3.sh`, `tests/checks/P1-S3.sh`
- Reads: `docs/proposal/2026-10-11-any-document-as-a-proof.md`, `tests/pending/P1-S3.sh`, `skills/brief-artifact/SKILL.md`, `skills/plan-artifact/SKILL.md`
- Follows: P0-S2
- Done when: its check file passes and is moved to `tests/checks/`, and the suite passes.
- Hands back: a draft pull request

### P1-S4. Write the proof command

- Kind: build
- Does: Wrote `/ck:proof` as pull request 36, with a run record, a resume listing, a word count, and the guard, as the proposal of 2026-10-11 asked. Decision D5 of the smallest proof closes that pull request unmerged, and S5 replaces this stage; see Open points for its row.
- Files: `skills/proof/SKILL.md`, `tests/pending/P1-S4.sh`, `tests/checks/P1-S4.sh`
- Reads: `docs/proposal/2026-10-11-any-document-as-a-proof.md`, `tests/pending/P1-S4.sh`, `skills/proof-loop/SKILL.md`, `skills/doc-artifact/SKILL.md`, `skills/brief/SKILL.md`, `scripts/proof-guard.py`
- Follows: S1, S2 and S3
- Done when: pull request 36 is closed unmerged, and nothing from it is on main.
- Hands back: a draft pull request

### P1-S5. Cut the proof to four steps

- Kind: build
- Does: Writes the command in four steps, under 300 words, naming only the loop skill and the document contract: take the file or write the document, render, review per the loop, lock at approved; it refuses only a plan, which it sends to `/ck:plan`, and with nothing after it renders the plan this session wrote in plan mode where it is. Deletes the guard with its fixtures, checks, and suite lines, rewrites the command's checks for the four steps and the plan refusal, says in the loop skill what a skill with no run record does, and drops the size column and its check from the document contract.
- Files: `skills/proof/SKILL.md`, `scripts/proof-guard.py`, `tests/fixtures/guard/`, `tests/checks/P1-S1.sh`, `tests/pending/P1-S4.sh`, `tests/checks/P1-S4.sh`, `skills/proof-loop/SKILL.md`, `skills/doc-artifact/SKILL.md`, `tests/checks/P1-S3.sh`, `tests/run.sh`
- Reads: `docs/proposal/2026-10-17-the-smallest-proof.md`, `tests/pending/P1-S4.sh`, `skills/proof-loop/SKILL.md`, `skills/doc-artifact/SKILL.md`, `skills/brief/SKILL.md`
- Follows: nothing
- Done when: the skill is under 300 words by `wc -w` and names the loop skill and the contract; no file in the repository names `proof-guard.py`; `tests/checks/P1-S4.sh` reads the skill for the four steps and the plan refusal and nothing about a run, a guard, or a word count; the contract has no size column; and the suite passes with `P1-S4.sh` moved to `tests/checks/`.
- Hands back: a draft pull request
- Serves: C1, C2, C3, C4, and C6 of the smallest proof

### P1-S6. Update README and version

- Kind: build
- Does: Adds the command to the README as one row in the command table and one paragraph that says where its document goes, adds the line under the pipeline table, names in the README the same Claude Code version the loop skill names, and sets the plugin's next version with `/ck:proof` in its description. Writes the release's entry in the development log: what shipped, the decisions of both proposals, what was turned down, and what is still open.
- Files: `README.md`, `skills/next/SKILL.md`, `.claude-plugin/plugin.json`, `DEVLOG.md`, `tests/pending/P1-S5.sh`, `tests/checks/P1-S5.sh`
- Reads: `docs/proposal/2026-10-17-the-smallest-proof.md`, `docs/proposal/2026-10-11-any-document-as-a-proof.md`, `tests/pending/P1-S5.sh`, `skills/proof/SKILL.md`, `skills/proof-loop/SKILL.md`, `DEVLOG.md`
- Follows: S5
- Done when: its check file passes and is moved to `tests/checks/`, the suite passes with no check file left under `tests/pending/`, and the devlog entry names the four decisions of 2026-10-11 and the five of 2026-10-17.
- Hands back: a draft pull request

### P1-S7. Use it on one real document

- Kind: yours
- Does: With the plugin installed at the new version, types `/ck:proof` with a real request in a test project and gets a page in one turn, then types `/ck:proof` after a plan-mode plan and gets that plan as a page, uncopied. Queues one comment on the first page and, in a second session, says done and sees whether that session finds the page by its title.
- Files: none
- Reads: `docs/proposal/2026-10-17-the-smallest-proof.md`
- Follows: S6
- Done when: both pages exist, and you can say in a sentence whether the second session republished to the first page's link or opened a new one.
- Hands back: nothing

## Open points

- P1-S4: pull request 36 is closed unmerged, per D5 of the smallest proof. The contract has no state for a stage closed without a merge, so the row keeps `running in its session` until you say how to record it: `done` with no number, or a fifth state in the contract. Holds up nothing; S5 does not wait on it.
- D3 of the smallest proof: whether the Artifact tool's listing finds a page by title reliably enough for a second session to republish to it is assumed yes until P1-S7 shows it. If it does not, D3 flips, and a stage that saves the proof's link in a run record is added after S7. Holds up nothing today.
