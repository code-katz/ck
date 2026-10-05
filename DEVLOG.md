# ck — Development Log

A living record of architectural decisions, milestones, key insights, and strategic direction.
Auto-maintained via [claude-devlog-skill](https://github.com/code-katz/claude-devlog-skill). Entries are reverse-chronological.

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
