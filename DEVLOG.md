# ck — Development Log

A living record of architectural decisions, milestones, key insights, and strategic direction.
Auto-maintained via [claude-devlog-skill](https://github.com/code-katz/claude-devlog-skill). Entries are reverse-chronological.

---

## [2026-10-06] 0.1.8: a cheap neutral trim, no false premortem failure, --panel for the architecture, Mermaid on review pages, a roadmap cap, the roster rule refined

**Category:** `fix`
**Tags:** `ck`, `draft`, `architecture`, `roadmap`, `review-page`, `cost`, `drill`
**Risk Level:** `low`
**Breaking Change:** `no`

### Summary
Drills 25 (`/ck:roadmap`, $3.73, the first run with nothing fixed by hand) and 26 (`/ck:architecture`, $17.31, Akira on Fable $13.07 across five passes). Seven changes, all approved by Will.

### Detail

- **The trim is a neutral Sonnet editor at low effort**, not the author on Fable. Drill 26's trim cost $4.14 and 53,833 output tokens to make one Edit of about 5,000 characters: reasoning, not editing. A trim only deletes repetition and moves detail, so the author's voice is not at risk.
- **The pre-panel checker skips the premortem item.** Appendix B is written after the panel by design; the first checker of drill 26 failed the draft on its placeholder and cost about $3 in revisions.
- **`/ck:architecture --panel`**, default off, like `/ck:prd` since 0.1.5. The finalize rule from 0.1.5 (no agent when the review changed nothing) now reaches the architecture skill too; the ck-test session had applied it by hand in drill 26.
- **Review pages draw Mermaid diagrams**: a `mermaid` fence becomes a diagram, with the library loaded from cdnjs only on pages that have one. The architecture contract requires a diagram, and drill 26's page showed it as code.
- **The roadmap is capped at 2,500 words** (contract item 8); River and Quinn are told the length first, Open Questions points to the PRD's open questions by number, and the validator counts. Drill 25's roadmap ran to 4,777 words with no rule to count against.
- **The roster rule, refined by Will in the roadmap review**: never state the total size of the roster; a subset count, such as the seats on one tier, is fine. Every agent's preamble says so, and every validator with a checklist carries it as a house-style item.
- **Not fixed, recorded**: the length rules did not hold for Akira in drill 26 (a 4,191-word draft against "aim for 2,500"; the rewrite grew from 2,802 to 4,072). The cheap trim is the backstop.

---

## [2026-10-07] 0.1.7: a note beside a good plan no longer stops the run; a stopped run can start again at research, sections, or synthesize

**Category:** `fix`
**Tags:** `ck`, `market-research`, `roadmap`, `opportunity`, `draft`, `resume`, `tests`
**Risk Level:** `low`
**Breaking Change:** `no`

### Summary
A real `/ck:market-research` on 0.1.6 (2026-10-07) threw away a good six-question plan: the schema required `stopReason`, Toni filled it with a summary of the plan, and the script read any text there as a stop. The documented way to continue, `startAt: "research"`, then threw every time, because the plan is only in memory when the plan stage ran and a script cannot read `plan.json`. Both are fixed, the same two shapes are fixed in the three other scripts that had them, and `tests/run.sh` now runs every workflow script with stub agents.

### Detail

- **The lists decide the stop; `stopReason` only words it.** In `market-research-draft` the run stops when the questions list is empty, and in `roadmap-draft` when all three tiers are empty. `stopReason` is the sentence shown in that case, with a default naming what to run first when it is absent. Text beside a filled list is logged as a note and the run goes on. The field is no longer in `required`, and both prompts say it belongs to the stop case only. `roadmap-draft` had the identical line and would have failed the same way on the first note River left.
- **A run that starts after the first stage reads the saved file back.** `market-research-draft` at `research` and `opportunity-draft` at `sections` each ask one low-effort Haiku agent to return `plan.json` or `frame.json` unchanged against the stage's own schema. A missing file or an empty list stops with the file's path and the stage to start at. The later stages (`crosscheck`, `write`, `validate`; `assemble`, `validate`) never needed the object: their agents read the files themselves.
- **`draft` at `synthesize` no longer throws at the end.** `earlierMemo` was declared inside the panel branch and read in the return statement outside it, so the PRD and architecture resume at `synthesize` did all its work and then failed with "earlierMemo is not defined". The declaration moved up, and a run with the panel off no longer names a memo. Found by the new tests, not by a run.
- **`tests/workflows.mjs`, section 14 of `tests/run.sh`.** Each script is loaded as the runtime loads it and run with stub agents. One check per script starts it at every step its `ORDER` or `ORDERS` lists, with every agent filling every field of its schema with non-empty text: a required string read as a signal, or a step that cannot be started at, fails there. Fourteen named cases cover the two reported bugs and their neighbors. A case's own answer is checked against the script's schema, so a case cannot pass on an answer the runtime would refuse. On 0.1.6 the new section fails 15 of its 23 checks.
- **Skills.** `skills/market-research` and `skills/opportunity` pick `research` or `sections` only when the saved file lists something, so a run cannot be sent back to a step that will refuse it again. `skills/opportunity` said to take the idea from `frame.json`, which does not hold it; it is in `run.json`.

### Rejected
- Passing the plan to the workflow in `args` from the skill. It saves one small agent call, but it only works when the skill is the caller and copies the object faithfully; reading the file inside the script makes `startAt` mean the same thing for every caller, which is what the script's own log line already claimed.
- Fixing the prompt alone ("return an empty string when you planned"), or making the field optional alone. Either leaves the run depending on what a model writes in a free-text field. The list is the evidence; the text is not.

### Open
- A run started after the first step returns null or an empty list for what the skipped stages would have counted (`questions`, `contributors`, the roadmap's `openQuestions`, the brand and design `variants`). No skill reads those today.
- The repository has no linter. An undefined-name rule would have caught `earlierMemo` without a test. The scripts need the same wrapping test 9 gives them for `node --check` before a linter can parse them.

---

## [2026-10-05] 0.1.6: /ck:team, /ck:roadmap, and /ck:market-research become gate-owning skills; every validator counts; nominees read less; the roster is described, not counted

**Category:** `fix`
**Tags:** `ck`, `team`, `roadmap`, `market-research`, `validators`, `cost`, `drill`
**Risk Level:** `low`
**Breaking Change:** `no`

### Summary
The first real `/ck:team` (drill 24, $10.85 against $6.29 on the fixture) passed a 2,685-word document against a 2,500 cap because the validator guessed, left no run record, and spent two thirds of its cost on eight nominees each reading the whole PRD. Three fixes, all approved by Will, and one house-style change: the roster is never counted in the plugin's own text.

### Detail

- **Skills own the run and the review.** `skills/team`, `skills/roadmap`, and `skills/market-research` mint a timestamped run with `run.json`, launch `ck:team-draft`, `ck:roadmap-draft`, or `ck:market-research-draft` with absolute paths, and review on a page, the same shape as `/ck:brief` and `/ck:opportunity`. The workflows are renamed accordingly; typed directly they still run with defaults and no record.
- **Every validator counts.** The team, opportunity, design-spec, and market-research validators run `wc -w` (before `## Sources` where the contract says so) and quote the count; the brief and draft validators already did. A test checks every capped workflow for it.
- **Nominees read less.** In `team-draft`, each nominee reads River's nomination and the brief (or the opportunity analysis), and a PRD requirement only when a responsibility names it. Drill 24's confirmations read 220k to 425k cached tokens each.
- **Gallery banner check fixed.** The brand and design gallery validators still looked for `@claude` in the banner, which the renderer stopped writing in 0.1.1, so every gallery check would have failed and spent its two fix rounds. They now look for the local-review sentence. Found while editing the validators; a test guards it.
- **Roster wording.** The README, `ROADMAP.md`, and the plugin description describe the roster ("the full persona roster, a complete cross-domain team", "every persona") instead of counting it, per Will's rule from the brief review. The PRD in `code-katz/.github` gets the same change in its own commit; drill logs and the correction note about the proposal's count stay as history.

---

## [2026-10-05] 0.1.5: the PRD panel is optional (--panel); finalize runs no agent when the review changed nothing

**Category:** `decision`
**Tags:** `ck`, `prd`, `panel`, `cost`
**Risk Level:** `low`
**Breaking Change:** `no`

### Summary
Two decisions by Will after drill 23. The three-lens panel inside `/ck:prd` has returned "yes, with conditions" on every run and costs about half of each PRD run, so it is now opt-in: `/ck:prd --panel`. Without it the draft is checked, River appends the premortem with a few edits, and the review follows; `/ck:panel` stays as its own command for challenging a finished document. The finalize step of `/ck:prd` and `/ck:opportunity` runs no agent when the review record holds no premortem answer and no answered decision; when it does, the agent edits the passages concerned instead of rewriting the file. Drill 23's finalize cost $2.02 to change one line.

### Detail

- `workflows/draft.js`: `panel: false` skips the panel stage, the rewrite, and the post-rewrite check; a `${author}:premortem` agent appends Appendix A (one line: the panel did not run) and Appendix B with at most four edits. `panel` defaults to true so `/ck:architecture` is unchanged.
- `skills/prd/SKILL.md`: `--panel` flag; `panel` recorded in `run.json` and passed in `args`; the finalize step reads `review.md` first and skips the agent when nothing was answered.
- `skills/opportunity/SKILL.md`: the same finalize rule.
- Expected cost of `/ck:prd` without the panel: about $7; with it, about $12 on the 0.1.4 length rules.

---

## [2026-10-04] 0.1.4: length rules move to the front of the PRD and architecture prompts; every agent carries the roster rule

**Category:** `fix`
**Tags:** `ck`, `draft`, `prd`, `cost`, `drill`
**Risk Level:** `low`
**Breaking Change:** `no`

### Summary
The first real `/ck:prd` (drill 23) cost $13.90 against the $8 accepted, and three of River's five Fable passes were about length: a 3,604-word draft against a 3,000 cap, two revisions, a rewrite that grew to 3,947, and a trim that stopped at 3,406. The `draft` workflow now states the length first and lower, forbids the rewrite from growing, gives the trim the count and a number to cut, and makes every validator count before judging. Every persona agent now carries Will's rule: describe the roster, never count it.

### Detail

- **Length first, and lower.** Each artifact in `workflows/draft.js` has a `targetWords` (2,500) beside its `maxWords` (3,000). The draft prompt opens with it instead of closing with the cap.
- **The rewrite may not grow.** The post-panel rewrite must be no longer than the draft it replaces: for every sentence the panel makes the author add, one comes out. The appendices stay separate and uncounted.
- **The trim gets a number.** The checker's notes (with its count) are passed in; the author cuts at least count minus nine tenths of the cap, and may count once at the end to confirm. Before, it cut blind and stopped 406 words short.
- **Validators always count.** The pre-panel validator runs the same `awk ... | wc -w` as the post-rewrite check; the third round of drill 23 had failed the document on an impression.
- **Roster rule.** One sentence in the generator's shared preamble, regenerated into all persona agents: plain words; describe the roster and the team, never count it.
- **Cost method.** Drill 23 records the shared method both sessions now use: sum usage once per message id (transcripts repeat each assistant message several times), price each message at its own model's rates, cache writes at 1.25 times input for five-minute writes and 2 times for one-hour writes, per-model cache-read rate. Summing every line overstates by about three times.

### Open
- The README, `ROADMAP.md`, the plugin description, and the PRD in `code-katz/.github` still count the roster. Separate cleanup, proposed to Will when between runs.

---

## [2026-10-04] 0.1.3: /ck:brief becomes a gate-owning skill; the brief workflow checks after every revision; review pages render bold around code

**Category:** `fix`
**Tags:** `ck`, `brief`, `review-page`, `drill`
**Risk Level:** `low`
**Breaking Change:** `no`

### Summary
The first real `/ck:brief` run (drill 22, on the ck Workbench project) wrote a good brief and left four things broken around it. All four are fixed here, and the fixes follow the shapes the other commands already use.

### Detail

- **`/ck:brief` is now a skill** (`skills/brief/SKILL.md`), and the workflow is `ck:brief-draft`. The skill mints a timestamped run directory with a `run.json`, launches the workflow with absolute paths, and owns the review page, the same way `/ck:opportunity` does. Typed directly, the old workflow could not mint anything: the run landed in `.ck/runs/brief-latest` with the run id `brief-direct` and a placeholder where the date should be.
- **The checker runs again after each revision** (`validate -> revise -> validate`, at most two revisions, word count first), as in the team and market-research workflows. Before, one check ran before the one revision, so a run that needed a trim always reported `valid: false` on a valid file.
- **River is told the length first**: about 1,000 words, never over the contract's 1,200. The cap stays; the target moved down so a normal draft lands under it instead of 200 words over and paying for a trim (drill 22: 1,403 words, then a $1.14 revision).
- **`render-review.py` lifts code spans out before it applies bold and emphasis.** A bold phrase containing a code span rendered with literal asterisks because the line was split at the code span first. Test added.
- **`tests/run.sh` runs on macOS**: the GNU-only `sed '0,/re/'` form is replaced with `awk`, so the suite runs on the Mac where ck is now developed.

### Rejected
- Raising or dropping the 1,200-word cap. The content fits (1,173 words with eight sections and five sourced comparables); the hard edge was the problem, not the number.

---

## [2026-09-09] Repository created from PRD revision 3: profiles imported, generator, four workflows, six contracts, tests

**Category:** `milestone`
**Tags:** `ck`, `phase-1`, `skeleton`, `generator`, `workflows`
**Risk Level:** `low`
**Breaking Change:** `no`

### Summary
First commit of the `ck` plugin, built from the phase-one PRD (`code-katz/.github`, `plans/2026-09-05-ck-plugin-prd-phase-1.md`, revision 3) after Phase 0 answered seven of eight spikes. The 21 persona profiles are imported once from the old team tool at commit `b4b211fbf4ec6f4d365a550b55e9981610ed7dda` and owned here from now on.

### Detail

- **Source of truth:** `profiles/<name>.md` and `tiers.conf`. `scripts/generate.sh` derives `agents/<name>.md` (subagent form, on its tier), `skills/<name>/SKILL.md` (session switch, verbatim), and `profiles/ROSTER.md`. It refuses to overwrite uncommitted hand edits to generated files.
- **Tiers:** Fable 5.1 for River, Akira, Morgan, Sage, Jordan, Reiner; Opus 5 for the eleven craft seats; Sonnet 5 for the four execution seats.
- **Workflows, taken verbatim from the PRD appendices:** `panel`, `brief`, `draft` (serves the PRD and the architecture document), `team`. Nested workflows are called by name, as Phase 0 showed.
- **Skills:** `prd`, `next`, `review-page` (the one place the gate mechanics live), and the contracts `brief-artifact`, `prd-artifact`, `architecture-artifact`, `team-artifact`, `memo-artifact`.
- **Hooks:** `SubagentStart` on `^ck:` writes the usage log; `SessionStart` warns while the old team tool is installed.
- **Tests:** `tests/run.sh`, static checks 1 to 11 from PRD §9, with two fixture projects.

### Decisions Made
- **Profiles are owned here.** One-time import; no vendoring, no lock, no relationship to the old tool.
- **Generated files are never hand-edited.** The generator refuses to overwrite uncommitted changes to them unless forced.

### Related
- PRD: `code-katz/.github`, `plans/2026-09-05-ck-plugin-prd-phase-1.md`
- Phase 0 record: `code-katz/.github`, `plans/2026-09-09-ck-phase-0-spikes.md`
