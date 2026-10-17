# Staged plan: Any document as a proof

Date: 2026-10-12. Status: approved 2026-10-12.
Item: PROOF
Reads: `docs/proposal/2026-10-11-any-document-as-a-proof.md`, `skills/review-page/SKILL.md`, `skills/plan-artifact/SKILL.md`, `scripts/render-review.py`, `scripts/render-gallery.py`, `tests/run.sh`

## What this covers

The `/ck:proof` command, and what every proof gains with it: the new name, two faults mended in the page renderer, a check for keys before a page is made, and the rules for a comment queued for Claude. It is built from the approved proposal, `docs/proposal/2026-10-11-any-document-as-a-proof.md`, as changed on 2026-10-12 so that a plan is always a staged plan. The checks are written first. Each later stage's checks are one file of that stage's own under `tests/pending/`: the suite runs it, reports it as waiting, and still passes after every merge. A stage is done when its checks pass and it has moved its file to `tests/checks/`, where the suite counts them. A stage may tighten the checks it was given and never loosen them. The highlighting of changes on a revised proof is a separate item and is not in this plan.

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

The page is made safer and the command is written. When it ends, typing `/ck:proof` with a request gives you a proof, and a file that should not be published is refused.

| Stage | What | Who | State |
|---|---|---|---|
| P1-S0 | The page renderer: two faults mended, a check for keys, the new comment steps on a proof | Sasha, Sonnet | done (30) |
| P1-S1 | The guard that refuses a file a proof must not publish | Akira, Fable | done (32) |
| P1-S2 | The loop's rules, and the new comment steps on a gallery | Akira, Fable | running in its session |
| P1-S3 | The contract every document from the command follows | Kai, Opus | done (31) |
| P1-S4 | The proof command itself, for a new document and for a file that exists | Akira, Fable | not started; follows S2 |
| P1-S5 | The documentation, the line under the pipeline table, and the version | Quinn, Sonnet | not started; follows S4 |

Ends when: in a test project, `/ck:proof` with a request gives you a proof, and pointed at a file that git ignores it refuses.

### Phase 2. Prove

The change is checked by two people who did not build it, and a fault either of them names is mended as a fix to its stage, or accepted under Open points, before the drill. When it ends, you have used `/ck:proof` on a real document and the release has its record.

| Stage | What | Who | State |
|---|---|---|---|
| P2-S0 | The whole change checked against the approved proposal | Robin, Sonnet | not started; follows P1-S5 |
| P2-S1 | A security read of the key check, the guard, and the loop's rules | Morgan, Fable | not started; follows P1-S4 |
| P2-S2 | The drill: one real proof, a review round, and five live checks | You | not started; follows S0 and S1 |
| P2-S3 | The drill's log | Robin, Sonnet | not started; follows S2 |
| P2-S4 | The release's entry in the development log | Quinn, Opus | not started; follows S3 |

Ends when: you have used `/ck:proof` on a real document, and the drill's log shows a result for each of the five live checks.

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
- Does: Writes `/ck:proof`: for a request it reads without changing anything, writes one document to the contract, counts its words, and publishes its proof; for a file that exists, or with nothing after it for the plan this session wrote in plan mode, it runs the guard, asks once, and publishes. Asked for a plan it writes nothing and names `/ck:plan`, and it locks a document only when the author types approved.
- Files: `skills/proof/SKILL.md`, `tests/pending/P1-S4.sh`, `tests/checks/P1-S4.sh`
- Reads: `docs/proposal/2026-10-11-any-document-as-a-proof.md`, `tests/pending/P1-S4.sh`, `skills/proof-loop/SKILL.md`, `skills/doc-artifact/SKILL.md`, `skills/brief/SKILL.md`, `scripts/proof-guard.py`
- Follows: S1, S2 and S3
- Done when: its check file passes and is moved to `tests/checks/`, and the suite passes.
- Hands back: a draft pull request

### P1-S5. Update README and version

- Kind: build
- Does: Adds the command to the documentation, as one row in the command table and one paragraph, and to the line under the pipeline table, and names in the README the same Claude Code version the loop skill names. Sets the plugin's next version and names `/ck:proof` in its description.
- Files: `README.md`, `skills/next/SKILL.md`, `.claude-plugin/plugin.json`, `tests/pending/P1-S5.sh`, `tests/checks/P1-S5.sh`
- Reads: `docs/proposal/2026-10-11-any-document-as-a-proof.md`, `tests/pending/P1-S5.sh`, `skills/proof/SKILL.md`, `skills/proof-loop/SKILL.md`
- Follows: S0, S4 and P0-S4
- Done when: its check file passes and is moved to `tests/checks/`, and the suite passes.
- Hands back: a draft pull request

### P2-S0. Check against the proposal

- Kind: check
- Does: Reads the merged change against the proposal's ten steps and every Done when in this plan, and runs the suite on the merged tree. Changes nothing.
- Files: none
- Reads: `docs/proposal/2026-10-11-any-document-as-a-proof.md`, `docs/plan/2026-10-12-any-document-as-a-proof.md`, `tests/run.sh`
- Follows: P1-S5
- Done when: the report lists each of the ten steps as met or not met with the check that shows it, names any check a stage loosened, and names the stage that owes each file still under `tests/pending/`.
- Hands back: a report in the session

### P2-S1. Read it for security

- Kind: check
- Does: Tries to get a file that should not be published past the guard and the key check, and reads the loop's rules for a comment that could steer the session. Changes nothing.
- Files: none
- Reads: `scripts/proof-guard.py`, `scripts/render-proof.py`, `skills/proof-loop/SKILL.md`, `skills/proof/SKILL.md`
- Follows: P1-S4
- Done when: the report names each attempt and whether it was refused, and names a fix for every hole it found.
- Hands back: a report in the session

### P2-S2. Run the drill

- Kind: yours
- Does: With the plugin installed at the new version, types `/ck:proof` for one real document in a test project, queues comments on its proof, carries the review into a second session, and tries the five live checks the proposal lists. Leaves rough notes of what happened under `tests/drill/`.
- Files: `tests/drill/`
- Reads: `docs/proposal/2026-10-11-any-document-as-a-proof.md`
- Follows: S0 and S1
- Done when: each of the five checks has a result you can say in a sentence, and the notes name the plugin's version.
- Hands back: nothing

### P2-S3. Write the drill log

- Kind: words
- Does: Writes the drill's log from the notes: each of the five checks with its result, what broke, and the cost of the run in dollars.
- Files: `tests/drill/`
- Reads: `tests/drill/`, `docs/proposal/2026-10-11-any-document-as-a-proof.md`
- Follows: S2
- Done when: the log holds a result for each of the five checks, the plugin's version, and the cost.
- Hands back: a draft pull request

### P2-S4. Write the devlog entry

- Kind: words
- Does: Writes the release's entry in the development log: what shipped, the four decisions, what was turned down, and what is still open.
- Files: `DEVLOG.md`
- Reads: `DEVLOG.md`, `docs/proposal/2026-10-11-any-document-as-a-proof.md`, `tests/drill/`
- Follows: S3
- Done when: the entry names the four decisions, the alternatives turned down, and every open point that is left.
- Hands back: a draft pull request

## Open points

None.
