# ck — Development Log

A living record of architectural decisions, milestones, key insights, and strategic direction.
Auto-maintained via [claude-devlog-skill](https://github.com/code-katz/claude-devlog-skill). Entries are reverse-chronological.

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
