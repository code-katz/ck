# Proposal: ck V2, lanes under personas

Date: 2026-10-13. Status: approved 2026-10-13.

## In one sentence

ck V2 keeps the personas as the seats that judge and adds lanes as the units that run, so that every agent's model, effort, tools, and exit artifact come from the shape of its task, and only an author's voice comes from a persona.

## Decisions for you

None open.

| # | Decision | Choices | Decided |
|---|---|---|---|
| D1 | Personas or lanes | Both: lanes run the work and a persona rides only the author and lens lanes (recommended: the drills put the cost in persona authors doing passes that need no judgment, and the staged plan already names a model per stage); lanes only, no personas; personas as today | Both, 2026-10-13 |
| D2 | What V2 is | ck 0.2, the same plugin and marketplace entry, built on a V2 branch of this repository kept apart from main until the eval shows before and after, then merged back (recommended: the before is the baseline, and one repository measures both); a second plugin with its own name | ck 0.2 on a V2 branch, merged back once tested, 2026-10-13 |
| D3 | The first measured change | The persona diet and the house-style check in code, measured on `/ck:brief` three runs before and three after (recommended: the cheapest command, and it touches every agent); the scout lane in `/ck:do` first | The diet and the house-style script, on `/ck:brief`, 2026-10-13 |
| D4 | The model word on a stage's card | The most expensive model among the stage's judging personas, with the author's name kept on the card (recommended: the top of the stage's bill is what you need before you click; the coordinator is always Sonnet and tells you nothing); the coordinator's; the author's, as today | The most expensive judging model, 2026-10-13 |

## Why

A ck persona bundles two things: judgment (a voice, a domain, the required behaviors that produce the premortem, the V0, the test matrix) and gear (a model tier fixed to the seat). Because the gear is fixed to the seat, River revises, rewrites, and finalizes on Fable 5.1 as well as drafting on it. The drills show where that goes: three of River's five PRD passes were about length; the finalize cost $2.02 to change one line; one opportunity revision took 51 turns to fix two checklist items because River re-read and re-searched; Fable output was $10.98 of a $14.61 run. Meanwhile ck already runs lane-shaped agents with no persona at all: the Haiku validator, the neutral Sonnet trim, the researchers, the panel's synthesis. And the staged plan names a model per stage, not per seat: P0-S1 of the proof plan ran Robin on Opus, against Robin's Sonnet tier. The playbook's evidence says the same from outside: route for cost, invest in the handoff, verify cheap output; gear at task boundaries; and, in its own words, persona-based gearing has no controlled study behind it. So the answer is neither the pivot nor the status quo. It is to separate the two things a persona bundles.

### Evidence from a staged plan

The first real cost data from a staged plan is the d20mob creature refactor, item A31, priced on 2026-10-13 from each session's transcripts with the drill-log method, at list prices. On a subscription plan these dollars are usage against limits, not a bill.

| Sessions | Count | Total | Mean |
|---|---|---|---|
| A31 stages on Fable 5.1 | 27 | $781 | $29 |
| A31 stages on Opus 5.5 | 9 | $207 | $23 |
| The coordinator session, Opus 5.5 | 1 | $670 | |

The model was not the lever: Fable and Opus stages differ by $6 a session, because both ran at extra-high effort with very large contexts. Every stage opened at about 93,000 tokens before doing anything, then read the 40,505-word plan, the memos, and the code; median context per turn was 250,000 to 720,000 tokens, against the playbook's finding that correctness falls from about 32,000. Stages wrote 3,000 to 5,000 output tokens a turn, mostly reasoning. Four front-end stages and two tests-only stages ran on Fable because the plan assigned the model by phase, not by task. The coordinator ran for five days, 968 turns, with context up to 961,000 tokens. So the levers in this proposal, in order: a scout brief in place of the whole plan (C4), effort set by lane (C1), the subagent diet (C2), and a fresh coordinator per phase rather than one for the whole plan (C10). The cold review on Fable, $80, is the kind of stage the top gear is for.

## What changes

| # | Change | Done when | Where |
|---|---|---|---|
| C1 | A lane is a named unit of execution: model, effort, tools, and exit artifact, set once in a file beside the tier file. Five to start: scout (Haiku, low, read-only, a brief with file and line citations), author (the persona's tier, medium, writes one document), builder (Sonnet, medium, edit and test in a worktree, the minimal-code goal stated up front), reducer (Opus, medium, scoped to one diff or document, a human-set goal), checker (Haiku, low, runs the deterministic checks first and reads only for what they cannot see, never fixes). Workflows name a lane for every neutral agent instead of a model id | No workflow script holds a model id; a test fails one that does; every neutral agent in every script names a lane | `lanes.conf`, `workflows/*.js`, `tests/run.sh` |
| C2 | The subagent form of a persona keeps the role line, the domain, the required behaviors, the handoff brief, and the signature question, and drops Personality, Enterprise and IP, and How You Communicate, which together are 12,189 of the profiles' 31,000 words. The switch command keeps the full profile. The preamble shrinks to what the schema does not already say | The agents folder is under 18,000 words, from 32,774; the brief's checker pass rate and revision count are unchanged across three runs | `scripts/generate.sh`, `agents/`, `tests/run.sh` |
| C3 | The house-style rules move from prompts into one script the checker lane runs first: the roster count, the em-dash, the word count, the section order, the headings verbatim, the `Assumed meanwhile:` lines. The rule leaves every preamble and every checker prompt | The script fails each rule on a fixture that breaks it; no prompt states a rule the script checks; the checker's prompt names the script's output as its first item | `scripts/check-doc.py`, `workflows/*.js`, `scripts/generate.sh`, `tests/fixtures/style/` |
| C4 | A scout lane runs before a build in `/ck:do` and in a stage card: where the task lives, by file and line; the test that covers it; the helper that already exists; what done means. The builder's prompt carries the brief and says not to explore again | A `/ck:do` build on the fixture task carries the brief, and the builder's turn count is lower with it than without over three runs each | `skills/do/SKILL.md`, `scripts/plan.py`, `skills/start/SKILL.md` |
| C5 | A diff budget in `/ck:do`'s plan line, and a reducer lane when the build is over it: the reducer shrinks the diff without changing behaviour, the tests run again, and the report shows lines before and after. A build under budget skips it | A seeded oversize build on the fixture runs the reducer, and the report shows both counts; a build under budget shows one | `skills/do/SKILL.md`, `scripts/diff-budget.sh`, `tests/fixtures/do/` |
| C6 | A hook refuses an Edit or Write from any `ck:` subagent to the instruction files: the profiles, the agents, every skill, the lane and tier files, and the project's `CLAUDE.md`. The session itself may still edit them | A stub subagent's write to a profile is refused and logged; the same write from the session goes through; the suite shows both | `hooks/hooks.json`, `scripts/guard-instructions.sh`, `tests/run.sh` |
| C7 | The drill method becomes code: a cost script that sums usage once per message id at each model's rates, and an eval runner that runs one command on one fixture N times and prints checker pass, revisions, turns, and cost as min, median, and max. Every devlog entry that changes a prompt, a profile, or a lane carries a Measured line from it | `/ck:brief` on the game fixture, three runs, is reported in the repository before and after C2 and C3 | `scripts/cost.py`, `tests/eval/run.sh`, `tests/eval/reports/`, `DEVLOG.md` |
| C8 | The lane and tier files carry a reviewed date, and the roadmap a monthly row to review them, because the model lineup moved five times last quarter | Both files have the line; the roadmap has the row | `lanes.conf`, `tiers.conf`, `ROADMAP.md` |
| C9 | The staged plan names judgment, not lanes. The table stays one row per stage. `Who` lists the personas who judge, each with its model word, and an effort word only when it departs from the lane's default: the first named is the author, who owns the stage and the card; a role word after `as` (lens, co-author, writer) names the others. The neutral lanes, scout, builder, reducer, and checker, come from the lane file and are not shown; a stage that changes one says so in one `Lanes:` line in its entry. A stage is still one card and one session. The card shows the author's name and the most expensive model among the stage's judging personas, so `Sasha, Sonnet; Travolta as writer, Opus` gives `[Sasha Opus]`; the session itself runs on the coordinator's model from the lane file, and `/ck:start` sets it to that. The session runs the lanes in order as background subagents and hands each lane's output to the next. The lanes that ran, with their cost and what the reducer cut, go in the session's report and the eval report, never the plan | `plan.py` reads a `Who` cell with several personas and a role word, and a `Lanes:` entry line; a card's name carries the top judging model and its message the stage's judgment personas and lane changes; `/ck:start` sets a stage session to the coordinator's model; the fixture plans pass `check`; the board is unchanged | `skills/plan-artifact/SKILL.md`, `scripts/plan.py`, `skills/plan/SKILL.md`, `skills/start/SKILL.md`, `tests/fixtures/plan/`, `tests/plan-cases.py` |
| C10 | A coordinator session lasts one phase. It is a lane in the lane file, on Sonnet at low effort, and it reads the plan only through the plan script, never the whole file. When the last stage of its phase is done, `/ck:start` says so in one line and offers a card for the next phase's coordinator, named `[<item>-P<n>] [Coordinator Sonnet] <the phase's title>`, and tells you to archive the one that finished. The plan file is the state, so nothing is carried in the old session's memory. A stage card stays as it is | `plan.py board` names the next phase when one ends; `/ck:start` in a session whose phase is done offers the next coordinator's card and opens no stage card of another phase; a test finds no instruction in the skill to read the plan file whole | `skills/start/SKILL.md`, `scripts/plan.py`, `lanes.conf`, `tests/plan-cases.py`, `tests/run.sh` |

### A phase under C9

One phase from a plan of yours, as the table would read it. Every neutral lane is implied; what you see is where judgment sits and what it runs on.

| Stage | What | Who | State |
|---|---|---|---|
| P3-S2 | Measure | Akira, Opus; Tracy as lens, Opus | not started; needs two rulings from you |
| P3-S3 | Publish | Akira, Opus | not started; follows S2 |
| P3-S4 | The Monster Parties page | Akira, Opus; Sasha as co-author, Sonnet | not started; follows S3 |
| P3-S5 | A creature's own parties of one, two and three | Akira, Opus; Sasha as co-author, Sonnet | not started; follows S4 |
| P3-S6 | The words on the sheets | Akira, Opus; Travolta as writer, Opus; Sasha as lens, Sonnet | not started; follows S5 |

`Akira, Fable, high` would be an author on a stage that deserves long deliberation; `Tracy as lens, Opus` is low effort by default and says nothing. The default sequences: a build stage is scout, author, builder, reducer, checker; a words stage adds the writer before the author; a check stage is scout then checker.

## Not doing

- **Not pruning the roster.** The 90-day prune on the roadmap is the right instrument: by usage, not by taste. The usage log already exists for it.
- **Not pinning Claude Code, and no harness bake-off.** ck is a Claude Code plugin; the README names the version a feature needs. C8 is the ck-sized version of the playbook's monthly gear review.
- **Not dieting the switch commands.** A `/ck:river` session has a person in it, and the personality is for that person.
- **Not replacing the panel with a checker.** It stays, with its question changed to force a stance (the drill note of 2026-10-01 asked for this; the question still invites yes-if). Five runs then decide whether it earns its cost.
- **Not a swarm.** Lanes are stages with file handoffs, as the workflows are today; parallel work stays where it already is: lenses, sections, researchers. The playbook's clearest negative result is parallel workers on a sequential task.
- **Not lanes inside the definition pipeline beyond the author and the checker.** The PRD's inputs are already the brief; a scout before a draft would read what the author must read anyway.

## What could go wrong

- **C2.** The diet drops something an author's output depended on, and the checker cannot see it. Limited by C7's before and after and by your review on the proof; a section is restored one at a time if either drops.
- **C3.** A rule in code knows only the phrasings it was given. Limited by the checker lane still reading for what the script cannot see, as the plan checker does today.
- **C4.** A wrong brief sends the builder the wrong way faster. Limited by the brief citing file and line, which the builder reads, and by the check step comparing the diff with the task, never with the brief.
- **C5.** A reduced diff hides an assumption the tests do not cover. Limited by the check step and the tests running after the reducer; reduction is never the last step.
- **C6.** ck builds itself with ck, so a stage session that edits a profile must not be refused. Limited by the hook matching `ck:` subagents only, never the session.
- **C7.** Three runs give a range, not a confidence interval. Accepted: a range from the cheapest command is what one person can afford to run on every change, and the playbook's own warning is that single runs are noise.
- **C9.** A reader cannot see from the plan which neutral lanes a stage will run, so a surprise lives in the lane file. Limited by the card's message printing the stage's lanes before the session starts, and the report printing what ran.
- **C10.** A new coordinator does not know what the last one learned outside the plan: a ruling said in chat, a stage you asked it to hold. Limited by the coordinator writing every such word into the plan's Open points before its phase ends, which the card for the next one asks it to read.
- **D2.** Main keeps releasing 0.1 while the V2 branch is open, as it did through the proof plan, so the branch drifts. Limited by rebasing the branch on main before every eval run and before the merge, and by running the suite on the merged tree, never only on the branch.

## How we will know it worked

1. The agents folder is under 18,000 words and the brief's checker pass rate is unchanged across three runs before and three after.
2. The lane file and the tier file are the only two places a model id appears, and a test keeps it so.
3. A `/ck:do` report on the fixture shows diff lines before and after the reducer, and a lower builder turn count with the scout brief than without.
4. One eval report for one command is in the repository with min, median, and max cost, before and after the first change.

## Open questions

- Does the diet change a document's quality in your eyes, not only the checker's? Assumed meanwhile: the checker and your review on the proof are the two measures, and a third, a reference document per fixture scored by a neutral checker, waits for the eval runner.
- Does the Agent tool in `/ck:do` take an effort setting, so that a lane's effort holds there as it does in a workflow script? Assumed meanwhile: the workflows set it today, and the skill passes it when the tool takes it.
- Should a lane be able to override a persona's tier when a persona rides it, as the staged plan's Who column already does by hand? Assumed meanwhile: yes, and the model next to the persona in `Who` wins for that persona's lane.
- What is the diff budget for a one-sentence task? Assumed meanwhile: a number is picked, measured, and adjusted; the playbook says no measured optimum exists.
- Where does a stage's lane trace live after the run, so that the eval report can read it? Assumed meanwhile: in the run folder under `.ck/runs/`, as the workflows' files do today, and the report names it.

## What I read

- `/Users/wcurran/Downloads/Project Flynn_ Agentic Coding Playbook.md`, the report, read in full on 2026-10-13. NVIDIA-specific tooling and the 30/60/90 plan were set aside as you asked.
- `README.md`, `ROADMAP.md`, `DEVLOG.md` (the entries from 2026-10-04 to 2026-10-11), `tiers.conf`, `hooks/hooks.json`, `.claude-plugin/plugin.json`
- `profiles/river.md`, `profiles/ROSTER.md`, `agents/river.md`, `scripts/generate.sh`, `scripts/usage-log.sh`, `scripts/render-proof.py` (its header), `scripts/proof-guard.py` (its header)
- `workflows/draft.js`, `workflows/panel.js` (its first eighty lines)
- `skills/do/SKILL.md`, `skills/start/SKILL.md`, `skills/proof-loop/SKILL.md`, `skills/doc-artifact/SKILL.md`
- `docs/proposal/2026-10-11-any-document-as-a-proof.md`, `docs/plan/2026-10-12-any-document-as-a-proof.md`
- `tests/drill/2026-10-01.md` and `tests/drill/2026-10-05.md`, for every cost, turn count, and token figure above
- Commands run on 2026-10-13 in this checkout: word counts of `agents/*.md` and of each profile section; `grep` for `effort:` and for model ids in `workflows/*.js` (no agent runs at max effort; Haiku is named nine times and Sonnet five times as literals)
- The A31 sessions, on 2026-10-13: every d20mob worktree session's transcript under `~/.claude/projects/`, priced once per message id at each model's rates; the session list and two sessions' model and effort read with the app's session tools; `plans/2026-10-10-the-creature-refactor.md` in d20mob, its phase tables and ruling 12.
- Not checked: the playbook's cited sources, which I did not open; the effort of A31 stages other than the engine stage and the coordinator; what fills the 93,000 tokens a stage opens with; whether a cheaper setup would have built the engine round as well; the cost of one `/ck:brief` run, which no drill log I read records; and nothing here was run live, so every Done when is a design, not an observation.
