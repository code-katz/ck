# Drill 26: the first real `/ck:architecture`, 2026-10-05

Project: Will's `~/development/ck-test` (the ck cost record and report; PRD, roadmap, team document, and opportunity analysis finished). Run by the ck-test session on ck 0.1.6, typed as `/ck:architecture` with nothing after it. The skill minted `.ck/runs/20261005T225616Z-ck-cost-report-architecture/` and launched `ck:draft` with the panel on (the architecture skill has no `--panel` flag): workflow run `wf_b33bab87-6ec`, 14 agents, 32 minutes 27 seconds. Outputs `docs/ARCHITECTURE.md` (2,937 words before the appendices, 5,196 in all) and `docs/decisions/20261005T225616Z-architecture-review.md`. Review page https://claude.ai/artifact/Jqja2nDzzezZKFT36qML8B; Will's review open, owned by the ck-test session.

Verified against the run journal by the shared method.

| Stage | Agent | Model | Output tokens | Cost | Checker's count |
|---|---|---|---|---|---|
| Draft | akira:draft | Fable 5.1 | 16,837 | $2.50 | 4,191 words |
| Validate | validate:1 | Haiku 4.5 | 3,859 | $0.13 | failed on the premortem placeholder, not length |
| Validate | akira:revise:1 | Fable 5.1 | 21,254 | $1.96 | |
| Validate | validate:2 | Haiku 4.5 | 3,803 | $0.08 | 3,113, failed |
| Validate | akira:revise:2 | Fable 5.1 | 6,914 | $1.03 | |
| Validate | validate:3 | Haiku 4.5 | 2,530 | $0.04 | 2,802, passed |
| Panel | security:morgan | Fable 5.1 | 7,533 | $1.76 | |
| Panel | platform:alex | Sonnet 5 | 3,687 | $0.40 | |
| Panel | data:jordan | Opus 5 | 6,484 | $0.93 | |
| Panel | synthesis | Opus 5.5 (session model) | 8,175 | $0.56 | |
| Synthesize | akira:synthesize | Fable 5.1 | 27,488 | $3.44 | |
| Check | check:1 | Haiku 4.5 | 982 | $0.14 | 4,072, failed |
| Check | akira:trim | Fable 5.1 | 53,833 | $4.14 | |
| Check | check:2 | Haiku 4.5 | 1,679 | $0.20 | 2,937, passed |
| | **Total** | | **165k** | **$17.31** | |

Against **$15.87** on the fixture drill (2026-10-01). Akira on Fable 5.1 is $13.07 of it across five passes. Every checker reported an exact count: the 0.1.4 and 0.1.6 counting rules work in this workflow.

## What broke

1. **A false failure on the premortem.** The first validator failed the draft because Appendix B was a placeholder. The premortem is written after the panel by design, so the pre-panel checker should not test that item. That one wrong check cost the first revision ($1.96), which also grew the body from the checker's count of 4,191 (the draft) to 3,113, and so a second revision ($1.03).
2. **Length rules did not hold for Akira.** The draft came in at 4,191 words against "aim for 2,500, never over 3,000" stated first; the rewrite after the panel went from 2,802 to 4,072 against "no longer than the draft it replaces". The prompts from 0.1.4 held for River's PRD run only insofar as they were never re-measured; here they were ignored twice.
3. **The trim is the most expensive agent of the run.** $4.14 and 53,833 output tokens to make one Edit of about 5,000 characters, cutting about 1,100 words. The tokens are reasoning, not edits: the author thought at length on Fable about what to cut. A trim does not need the author or the expensive tier.
4. **No way to skip the panel.** `/ck:prd` got `--panel` in 0.1.5; the architecture skill passes no `panel` argument and the workflow defaults to on.
5. **The Mermaid diagram shows as code on the review page.** `render-review.py` emits a `<pre><code>` block for the `mermaid` fence and the page carries no script to draw it; the contract requires the diagram.

For Will's review, not plugin bugs: the scale line says "six to eight agents per run" while this project's own runs had 3, 4, 11, and 14; and the architecture amends the final PRD's AC2.2 and AC3.1 (skip lines move into the run directory), flagged as its own Open question 8.

## Review, 2026-10-05

Will left no page comments and no premortem answer. Two items raised by the ck-test session and approved by Will: the scale line became "Three to fourteen agents per run, as observed in this project", and Open question 8 (the PRD amendment) stays open in both documents. No finalize agent ran: the 0.1.6 architecture skill still launches one in every case, but the ck-test session applied the PRD skill's 0.1.5 rule by hand (one Edit to the Status line, status final in `run.json`) and saved about $2. The 0.1.5 finalize rule reached the PRD and opportunity skills only; the architecture skill needs it too. Architecture total: $17.31.
