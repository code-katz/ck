# Staged plan: A team per project

Date: 2026-10-16. Status: approved 2026-10-17.
Item: TEAM
Reads: `docs/proposal/2026-10-16-project-teams.md`, `skills/plan-artifact/SKILL.md`, `hooks/hooks.json`, `scripts/check-prereqs.sh`, `scripts/generate.sh`, `scripts/plan.py`, `skills/team/SKILL.md`, `skills/do/SKILL.md`, `skills/start/SKILL.md`, `workflows/team-draft.js`, `workflows/opportunity-draft.js`, `tests/run.sh`

## What this covers

One committed file per project, `.claude/ck-team.conf`, names that project's ck team: a core of eight seats that the plugin owns, plus the members the project invites or drops. One script reads it, every session hears it at start, the workflows that choose a cast choose from it, `/ck:team` gains the short forms that edit it, and a plan row or a switch command outside the team says so. It is built from the approved proposal, `docs/proposal/2026-10-16-project-teams.md`, changes C1 to C7 under decisions D1 to D4, and ships as the release after the proof plan's. The checks are written first, one file per stage, as the proof plan did. Stages are ordered by what each one waits on.

## Phases

### Phase 0. Ground

The proof plan's release is out and the checks for every later stage are waiting in the suite. When it ends, `bash tests/run.sh` passes and lists one waiting check file per build stage of this plan.

| Stage | What | Who | State |
|---|---|---|---|
| P0-S0 | The proof plan's release, shipped and installed | You | not started; could start now |
| P0-S1 | The fixture project and the checks for every later stage | Robin, Sonnet | not started; follows S0 |

Ends when: the installed plugin is the proof plan's release, and the suite passes while it lists this plan's check files as waiting.

### Phase 1. Know the team

The file, its reader, and what a session hears. When it ends, a new session in the fixture project names its team when asked, and typing `/ck:noon` there says that Noon is not on the team.

| Stage | What | Who | State |
|---|---|---|---|
| P1-S0 | The team file, the core, and the one script that reads them | Akira, Fable | not started; follows P0-S1 |
| P1-S1 | The paragraph every session hears at start | Alex, Sonnet | not started; follows S0 |
| P1-S2 | The line a switch command says outside the team | Alex, Sonnet | not started; follows S0 |

Ends when: in the fixture project, a new session asked who is on the team names the core and the invited seats, and `/ck:noon` opens with the line that says Noon is not on the team.

### Phase 2. Cast from the team

Everything that chooses a persona chooses from the team. When it ends, the opportunity workflow in the fixture project casts its domain seat from the team, `/ck:team invite` changes one line of one file, and a plan row naming an outsider gets a warning and no card.

| Stage | What | Who | State |
|---|---|---|---|
| P2-S0 | The four casting workflows read the team, not the roster | Akira, Fable | not started; follows P1-S0 |
| P2-S1 | The gate's question for a nomination outside the team | Akira, Fable | not started; follows S0 |
| P2-S2 | The three short forms of the team command, and the full run from the file | Akira, Fable | not started; follows S0 |
| P2-S3 | The plan check's warning and the card that is not offered | Akira, Fable | not started; follows P1-S0 |
| P2-S4 | The documentation, the next command's line, and the version | Quinn, Opus | not started; follows S0, S1, S2, S3, P1-S1 and P1-S2 |

Ends when: in the fixture project, `/ck:team invite noon` changes one line of `.claude/ck-team.conf` and nothing else, and `plan.py check` on a plan naming an outsider prints one warning line and the suite still passes.

### Phase 3. Prove

The change is checked by two people who did not build it, then tried in d20mob. When it ends, you have used the team in a real project and the release has its record.

| Stage | What | Who | State |
|---|---|---|---|
| P3-S0 | The whole change checked against the approved proposal | Robin, Sonnet | not started; follows P2-S4 |
| P3-S1 | A security read of the hook, the reader, and the team file | Morgan, Fable | not started; follows P1-S1 and P2-S2 |
| P3-S2 | The drill: d20mob's team file, then the four signs the proposal lists | You | not started; follows S0 and S1 |
| P3-S3 | The drill's log | Robin, Sonnet | not started; follows S2 |
| P3-S4 | The release's entry in the development log | Quinn, Opus | not started; follows S3 |

Ends when: a new session in d20mob names twelve seats and not Noon, and the drill's log shows a result for each of the proposal's four signs.

## Stage by stage

### P0-S0. Ship the proof plan's release

- Kind: yours
- Does: Finishes the proof plan, `docs/plan/2026-10-12-any-document-as-a-proof.md`, through its last stage and installs that release of the plugin. Every stage here builds on it: the check files under `tests/pending/`, the proof for the review, and the current model ids.
- Files: none
- Reads: `docs/plan/2026-10-12-any-document-as-a-proof.md`, `DEVLOG.md`
- Follows: nothing
- Done when: the proof plan's board says every stage is done, and `claude plugin list` shows the plugin at that release's version.
- Hands back: nothing

### P0-S1. Write the checks first

- Kind: tests
- Does: Writes the fixture project under `tests/fixtures/team/`, a small repository with a team file that invites two seats and drops one, and one check file per later build stage, each needing only that stage's work. Names each file with the item in front, `tests/pending/TEAM-P1-S0.sh`, so it never collides with the proof plan's files, and makes the suite's section 21 accept that name.
- Files: `tests/pending/`, `tests/fixtures/team/`, `tests/run.sh`
- Reads: `docs/proposal/2026-10-16-project-teams.md`, `tests/run.sh`, `tests/pending/P0-S4.sh`, `tests/checks/P1-S1.sh`
- Follows: S0
- Done when: `bash tests/run.sh` passes and lists every new file as waiting; every check in a waiting file fails on this tree for the reason its stage will mend; and no check that passes today is in a waiting file.
- Hands back: a draft pull request
- With: Akira

### P1-S0. Build the team file and reader

- Kind: build
- Does: Writes `core.conf` in the plugin, the eight core seats, one per line, and `scripts/team.py`, the only code that reads a project's `.claude/ck-team.conf`: `show` prints the team, `roster` prints the roster's rows for the team only, `has <persona>` answers yes or no, and `invite` and `drop` edit the file with a name, a reason, and a `#` comment line. With no file the team is the whole roster; a name not on the roster, a persona both invited and dropped, and a missing file each get one sentence and never a traceback.
- Files: `core.conf`, `scripts/team.py`, `tests/team-cases.py`, `tests/fixtures/team/`, `tests/run.sh`, `tests/pending/TEAM-P1-S0.sh`, `tests/checks/TEAM-P1-S0.sh`
- Reads: `docs/proposal/2026-10-16-project-teams.md`, `tests/pending/TEAM-P1-S0.sh`, `profiles/ROSTER.md`, `tiers.conf`, `scripts/plan.py`, `tests/plan-cases.py`
- Follows: P0-S1
- Done when: its check file passes and is moved to `tests/checks/`, `python3 tests/team-cases.py` passes every case, and the suite passes.
- Hands back: a draft pull request

### P1-S1. Tell every session the team

- Kind: build
- Does: Adds `scripts/team-context.sh` to the SessionStart hook, next to the prerequisite check. It runs `team.py show` for `$CLAUDE_PROJECT_DIR` and prints one short paragraph: the team by name, core and invited, and that anyone else is invited first with `/ck:team invite <persona>`, always far under the 10,000-character cap and silent when the plugin's own repository is the project.
- Files: `hooks/hooks.json`, `scripts/team-context.sh`, `tests/run.sh`, `tests/pending/TEAM-P1-S1.sh`, `tests/checks/TEAM-P1-S1.sh`
- Reads: `docs/proposal/2026-10-16-project-teams.md`, `tests/pending/TEAM-P1-S1.sh`, `hooks/hooks.json`, `scripts/check-prereqs.sh`, `scripts/team.py`
- Follows: S0
- Done when: its check file passes and is moved to `tests/checks/`, the suite passes, and the hook's output for the fixture project and for a project with no file is under 1,000 characters each.
- Hands back: a draft pull request

### P1-S2. Mark a switch outside the team

- Kind: build
- Does: Makes every generated switch skill open by running `team.py has <name>` for the project and, when the answer is no, say first: "<Name> is not on this project's team. Say invite <name> to add them." The switch still works. Regenerates the skills and keeps the drift check passing.
- Files: `scripts/generate.sh`, `skills/*/SKILL.md`, `tests/run.sh`, `tests/pending/TEAM-P1-S2.sh`, `tests/checks/TEAM-P1-S2.sh`
- Reads: `docs/proposal/2026-10-16-project-teams.md`, `tests/pending/TEAM-P1-S2.sh`, `scripts/generate.sh`, `skills/noon/SKILL.md`, `scripts/team.py`
- Follows: S0
- Done when: its check file passes and is moved to `tests/checks/`, the suite passes, and the drift check in section 2 of the suite passes on the regenerated files.
- Hands back: a draft pull request

### P2-S0. Cast workflows from the team

- Kind: build
- Does: Changes the four workflows that read the roster to choose a cast so that they read `team.py roster` for the project instead: opportunity, plan, team, and roadmap. A workflow whose best pick is outside the team names that pick as a nomination in its result, never casts it, and the stub run in `tests/workflows.mjs` shows both paths.
- Files: `workflows/opportunity-draft.js`, `workflows/plan-draft.js`, `workflows/team-draft.js`, `workflows/roadmap-draft.js`, `tests/workflows.mjs`, `tests/pending/TEAM-P2-S0.sh`, `tests/checks/TEAM-P2-S0.sh`
- Reads: `docs/proposal/2026-10-16-project-teams.md`, `tests/pending/TEAM-P2-S0.sh`, `scripts/team.py`, `workflows/opportunity-draft.js`, `tests/workflows.mjs`
- Follows: P1-S0
- Done when: its check file passes and is moved to `tests/checks/`, and the suite passes, including the stub run of each of the four workflows on the fixture project.
- Hands back: a draft pull request

### P2-S1. Ask before casting an outsider

- Kind: build
- Does: Makes the skills that own a gate ask once, at the gate and never mid-workflow, when a workflow returns a nomination outside the team: "<Name> is not on this team. Invite <Name>?" A yes runs `team.py invite` and goes on; a no drops the nomination. Makes `/ck:do` choose its owner from `team.py roster` and `docs/TEAM.md`, with the roster only when the author names someone by name.
- Files: `skills/opportunity/SKILL.md`, `skills/plan/SKILL.md`, `skills/do/SKILL.md`, `skills/roadmap/SKILL.md`, `tests/run.sh`, `tests/pending/TEAM-P2-S1.sh`, `tests/checks/TEAM-P2-S1.sh`
- Reads: `docs/proposal/2026-10-16-project-teams.md`, `tests/pending/TEAM-P2-S1.sh`, `skills/do/SKILL.md`, `skills/opportunity/SKILL.md`, `scripts/team.py`
- Follows: S0
- Done when: its check file passes and is moved to `tests/checks/`, and the suite passes.
- Hands back: a draft pull request

### P2-S2. Add the team short forms

- Kind: build
- Does: Adds `/ck:team show`, `/ck:team invite <persona> [why]`, and `/ck:team drop <persona> [why]` to the team skill: each changes the file only through `team.py`, runs no workflow, and offers to commit the file. Makes the full `/ck:team` start River's cast from the file, turn a nomination outside it into an invitation the author confirms, and makes the team contract's checker fail a Cast that differs from the file.
- Files: `skills/team/SKILL.md`, `workflows/team-draft.js`, `skills/team-artifact/SKILL.md`, `tests/run.sh`, `tests/pending/TEAM-P2-S2.sh`, `tests/checks/TEAM-P2-S2.sh`
- Reads: `docs/proposal/2026-10-16-project-teams.md`, `tests/pending/TEAM-P2-S2.sh`, `skills/team/SKILL.md`, `skills/team-artifact/SKILL.md`, `scripts/team.py`
- Follows: S0
- Done when: its check file passes and is moved to `tests/checks/`, and the suite passes.
- Hands back: a draft pull request
- With: River

### P2-S3. Keep plan rows to the team

- Kind: build
- Does: Makes `plan.py check` print one warning line, and not fail, for a Who cell that names a persona not on the project's team, and makes `plan.py card` refuse such a row in one line that names the invite. Makes `/ck:start` relay that refusal and offer no card until the persona is invited or the row is changed.
- Files: `scripts/plan.py`, `skills/start/SKILL.md`, `tests/plan-cases.py`, `tests/fixtures/plan/`, `tests/pending/TEAM-P2-S3.sh`, `tests/checks/TEAM-P2-S3.sh`
- Reads: `docs/proposal/2026-10-16-project-teams.md`, `tests/pending/TEAM-P2-S3.sh`, `scripts/plan.py`, `tests/plan-cases.py`, `skills/start/SKILL.md`, `scripts/team.py`
- Follows: P1-S0
- Done when: its check file passes and is moved to `tests/checks/`, `python3 tests/plan-cases.py` passes every case, and the suite passes.
- Hands back: a draft pull request

### P2-S4. Update README and version

- Kind: build
- Does: Adds the team file, the core, and the three short forms to the README, as one paragraph and three rows in the command table, and names the team file in the line under the pipeline table in the next command. Sets the plugin's next version and names the team file in its description.
- Files: `README.md`, `skills/next/SKILL.md`, `.claude-plugin/plugin.json`, `tests/pending/TEAM-P2-S4.sh`, `tests/checks/TEAM-P2-S4.sh`
- Reads: `docs/proposal/2026-10-16-project-teams.md`, `tests/pending/TEAM-P2-S4.sh`, `README.md`, `skills/next/SKILL.md`, `skills/team/SKILL.md`
- Follows: S0, S1, S2, S3, P1-S1 and P1-S2
- Done when: its check file passes and is moved to `tests/checks/`, the suite passes, and no file is left under `tests/pending/` with this item's id.
- Hands back: a draft pull request

### P3-S0. Check against the proposal

- Kind: check
- Does: Reads the merged change against the proposal's seven changes, their Done when cells, and every Done when in this plan, and runs the suite on the merged tree. Changes nothing.
- Files: none
- Reads: `docs/proposal/2026-10-16-project-teams.md`, `docs/plan/2026-10-16-team-per-project.md`, `tests/run.sh`
- Follows: P2-S4
- Done when: the report lists each of the seven changes as met or not met with the check that shows it, and names any check a stage loosened.
- Hands back: a report in the session

### P3-S1. Read it for security

- Kind: check
- Does: Reads the hook as a path from a committed project file into every session's context, and tries a team file with a line that carries instructions, a long line, a path, or a name with shell characters, through `team.py` and the hook. Reads `invite` and `drop` for a write outside the file, and the short forms for a commit the author did not approve. Changes nothing.
- Files: none
- Reads: `scripts/team.py`, `scripts/team-context.sh`, `hooks/hooks.json`, `skills/team/SKILL.md`, `core.conf`
- Follows: P1-S1 and P2-S2
- Done when: the report names each attempt and whether it was refused, and names a fix for every hole it found.
- Hands back: a report in the session

### P3-S2. Run the drill in d20mob

- Kind: yours
- Does: With the plugin installed at the new version, writes d20mob's team file by hand from the proposal's example and commits it, then tries the four signs the proposal lists under "How we will know it worked": a new session asked for the team, `/ck:opportunity`'s domain seat, `/ck:team invite noon`, and a plan row naming Noon. Leaves rough notes under `tests/drill/`.
- Files: `tests/drill/`
- Reads: `docs/proposal/2026-10-16-project-teams.md`
- Follows: S0 and S1
- Done when: each of the four signs has a result you can say in a sentence, and the notes name the plugin's version.
- Hands back: nothing

### P3-S3. Write the drill log

- Kind: words
- Does: Writes the drill's log from the notes: each of the four signs with its result, what broke, and the cost of the run in dollars.
- Files: `tests/drill/`
- Reads: `tests/drill/`, `docs/proposal/2026-10-16-project-teams.md`
- Follows: S2
- Done when: the log holds a result for each of the four signs, the plugin's version, and the cost.
- Hands back: a draft pull request

### P3-S4. Write the devlog entry

- Kind: words
- Does: Writes the release's entry in the development log: what shipped, the four decisions, what was turned down, and what is still open, the deny rule test among them.
- Files: `DEVLOG.md`
- Reads: `DEVLOG.md`, `docs/proposal/2026-10-16-project-teams.md`, `tests/drill/`
- Follows: S3
- Done when: the entry names the four decisions, the alternatives turned down, and every open point that is left.
- Hands back: a draft pull request

## Open points

None.
