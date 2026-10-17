# Proposal: A team per project

Date: 2026-10-16. Status: approved 2026-10-16.

## In one sentence

Each project names its ck team in one committed file, a core of seats that is always on plus the members it invites, and every session, workflow, plan, and card reads that file, so d20mob works with Reiner, Tracy, and Travolta and is never offered Noon.

## Decisions for you

None open.

| # | Decision | Choices | Decided |
|---|---|---|---|
| D1 | Where a project's team lives | A small file, `.claude/ck-team.conf`, read by a script (recommended: a hook can read it in milliseconds, it works in a project with no pipeline documents, as d20mob has none, and every worktree sees it once it is committed); the Cast table of `docs/TEAM.md` | The file `.claude/ck-team.conf`, 2026-10-16 |
| D2 | Who the core is | Eight seats: River, Quinn, Akira, Sasha, Kai, Robin, Alex, Morgan (recommended: the seats every build plan has named so far, product through security); the five build seats only, without Kai, Alex, and Morgan; no core, every seat invited | Eight seats: River, Quinn, Akira, Sasha, Kai, Robin, Alex, Morgan, 2026-10-16 |
| D3 | What happens to a persona who is not on the team | Never suggested or cast, and one word away: `/ck:team invite noon` adds them, and a one-off use asks first (recommended: Claude Code cannot hide one skill of a plugin per project, so a soft rule is the one that holds everywhere); also blocked outright with a deny rule in the project's settings, once a test shows the rule matches a plugin's agent | Never suggested or cast, one `invite` away; no deny rule until a test, 2026-10-16 |
| D4 | Whether the pipeline's own seats need the team | No: a command's fixed cast always runs, so `/ck:brief` still uses Toni on a project without Toni, and the team governs only the open choices (recommended: no pipeline command breaks, and a fixed seat is not a choice); yes, a command refuses until its seats are invited | No: a command's fixed cast always runs, 2026-10-16 |

## Why

Every session in every project sees all 21 personas today, and every workflow that chooses a cast reads the whole roster from `profiles/ROSTER.md`. So a card game can be offered a cyberpunk author, the opportunity workflow weighs Cornelius for a fantasy app, and the session greeting lists 21 names where a project uses about ten. `/ck:team` already chooses a cast, but it writes a full document with a responsibilities matrix, needs a brief or an opportunity first, and nothing reads its Cast table when a session starts. The team is chosen once and then forgotten.

## What changes

| # | Change | Done when | Where |
|---|---|---|---|
| C1 | **The team file.** One line per change to the core: `invite <persona> <why>` or `drop <persona> <why>`. Comments start with `#`. The core itself lives in the plugin, so a change to it reaches every project. With no file, the team is the whole roster, as today | A fixture project's file parses to its team; a line naming a persona not on the roster is refused in one sentence | `.claude/ck-team.conf` (in each project), `core.conf`, `tests/fixtures/team/` |
| C2 | **One reader.** `scripts/team.py` is the only code that reads the file: `show` prints the team, `roster` prints the roster's rows for the team only, `has <persona>` answers yes or no, `invite` and `drop` edit the file. It never prints a traceback | Its cases pass, including a missing file, an unknown name, and a persona both invited and dropped | `scripts/team.py`, `tests/team-cases.py` |
| C3 | **Every session knows the team.** ck's SessionStart hook runs `team.py show` and adds one short paragraph to the session: the team by name, core and invited, and that anyone else is invited first. It stays far under Claude Code's 10,000-character cap for a hook | A session in the fixture project names its team when asked, and a session in a project with no file names the whole roster | `hooks/hooks.json`, `scripts/team-context.sh` |
| C4 | **Casting reads the team.** The workflows and skills that read the roster to choose a cast read `team.py roster` instead: opportunity, plan, team, do, and roadmap. A workflow that still wants someone outside the team names them as a nomination, and the skill that owns the gate asks: "Noon is not on this team. Invite Noon?" | The opportunity workflow on the fixture project casts its domain seat from the team; a stubbed nomination from outside it reaches the question | `workflows/opportunity-draft.js`, `workflows/plan-draft.js`, `workflows/team-draft.js`, `workflows/roadmap-draft.js`, `skills/do/SKILL.md`, `skills/opportunity/SKILL.md`, `skills/plan/SKILL.md` |
| C5 | **`/ck:team` gains three short forms.** `/ck:team show`, `/ck:team invite <persona> [why]`, and `/ck:team drop <persona> [why]` change the file only, run no workflow, and offer to commit it. The full `/ck:team` keeps writing `docs/TEAM.md`, starts its cast from the file, and turns River's nominations outside it into invitations you confirm | Each short form changes the fixture's file and nothing else; the full run's Cast equals the file's team plus what you confirmed | `skills/team/SKILL.md`, `workflows/team-draft.js`, `skills/team-artifact/SKILL.md` |
| C6 | **Plans and cards keep to the team.** `plan.py check` warns, and does not fail, when a Who cell names a persona not on the team. `/ck:start` offers no card for such a row until the persona is invited or the row is changed | A fixture plan naming Noon in a d20mob-like project gets one warning line and no card | `scripts/plan.py`, `skills/start/SKILL.md`, `tests/plan-cases.py` |
| C7 | **A switch outside the team says so.** Typing `/ck:noon` in a project without Noon still works, and its first line says "Noon is not on this project's team. Say invite noon to add them." | The generated switch skills carry the line; the suite checks one | `scripts/generate.sh`, `skills/<persona>/` |

For d20mob, the file would read:

```
# ck team for d20mob. The core comes from the plugin; this file adds and removes.
invite reiner    the game's mechanics, the round, balance
invite tracy     D&D canon and the SRD status of a name
invite travolta  the narrator, lore, bestiary and sheet words
invite piper     playtests of a new fight or scenario
```

That gives d20mob twelve seats: the eight core, and Reiner, Tracy, Travolta, and Piper. Noon, Rez, Cornelius, Ernie, Casey, Jordan, Sage, Iris, and Toni are not on it, and each is one `invite` away.

## Not doing

- **Not hiding the switch commands or the subagents per project.** Claude Code documents no way to turn off one skill or one agent of an enabled plugin from a project's settings; `skillOverrides` does not reach plugin skills. C7 is the honest version.
- **Not splitting ck into several plugins.** It is the only documented route to a real per-project subset, but it breaks the one-plugin install and the shared roster for a gain C3 and C4 already give.
- **Not changing a persona's tier per project.** The staged plan's Who column already sets a model per stage. A team file with models in it would be a second place to look.
- **Not touching V2's lanes.** Lanes are neutral and carry no persona, so the team decides only who judges. Under V2, C4 and C6 apply to the judging seats in a Who cell, and the scout, builder, reducer, and checker run as before.
- **Not the 90-day prune.** That prunes the roster for everyone, by usage. This chooses per project, by hand. The usage log can later show which invited seats a project never uses.

## What could go wrong

- **C3.** The paragraph is advice to the model, and a session can still suggest an outsider. Limited by C4 and C6, which hold in code where it matters: who is cast and which cards are offered.
- **C4.** A workflow's best pick is outside the team and the question interrupts a run. Limited by asking once per run, at the gate the skill already owns, never mid-workflow.
- **C1.** The file and `docs/TEAM.md` disagree. Limited by the file being the one source: the full `/ck:team` writes its Cast from the file, and its checker fails a Cast that differs.
- **C5.** An `invite` made in a stage's worktree never reaches main. Limited by the short forms offering to commit, and by the card's model check line saying which team the session read.
- **D2.** The core is too large for a small project, or too small for a big one. Accepted: `drop` handles the first, `invite` the second, and the core is one file to change.

## How we will know it worked

1. A new session in d20mob, asked who is on the team, names twelve seats and not Noon.
2. `/ck:opportunity` in d20mob casts its domain seat from Reiner or Tracy, never from Rez or Cornelius.
3. `/ck:team invite noon` in d20mob changes one line of one file, and the next session names Noon.
4. A plan row with Noon's name in d20mob gets a warning and no card until Noon is invited.

## Open questions

- Does a project deny rule `Agent(ck:noon)` match a plugin's subagent, and does it hide it or only block it? Assumed meanwhile: not used; a test settles it, and D3's second choice waits on that test.
- Should an invitation for one task, a guest, leave no line in the file? Assumed meanwhile: a guest is asked once and leaves nothing; only `invite` changes the file.
- Should the core differ by the kind of project, a game or a data product? Assumed meanwhile: one core, and a kind is a set of invites the full `/ck:team` proposes.
- Where does this ship? Assumed meanwhile: its own staged plan, item TEAM, written with `/ck:plan` once this is approved, released as 0.1.12 after the proof plan's 0.1.11, and carried into the V2 branch when it rebases on main.

## What I read

- `profiles/ROSTER.md`, `tiers.conf`, `hooks/hooks.json`, `scripts/check-prereqs.sh`, `skills/team-artifact/SKILL.md`, `skills/roster/SKILL.md`, `skills/doc-artifact/SKILL.md`, in ck's main checkout on 2026-10-16.
- The lines in `skills/do/SKILL.md`, `workflows/plan-draft.js`, `workflows/opportunity-draft.js`, `workflows/team-draft.js`, and `workflows/roadmap-draft.js` that read the roster or `docs/TEAM.md`, found by search on 2026-10-16.
- `docs/proposal/2026-10-13-ck-v2-lanes-under-personas.md`, for how lanes and the Who column relate.
- The list of files under d20mob's `docs/` on 2026-10-16: no `TEAM.md`, and documents by Akira, Kai, Reiner, River, and Travolta.
- Claude Code's documentation, read on 2026-10-16 by a research agent: code.claude.com/docs/en/sub-agents (the `Agent(name)` deny rule), /permissions, /skills (`Skill(name)` rules, and that `skillOverrides` does not reach plugin skills), /plugins/install (plugins enabled per project, whole plugins only), and /hooks (SessionStart's `additionalContext`, capped at 10,000 characters, and `$CLAUDE_PROJECT_DIR`).
- Not checked: whether `Agent(ck:noon)` matches a plugin's agent; how often each d20mob session named each persona; how many projects besides d20mob use ck today.
