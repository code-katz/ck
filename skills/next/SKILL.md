---
name: next
description: Says what to run next, in one sentence, by looking at which documents exist. Use when you do not know where to start or what comes after the step you just finished.
disable-model-invocation: true
---

Look at the project and say exactly one thing. Plain words. No token counts, no more than one action.

Check, in this order, in the repository Claude Code was opened in: the latest `.ck/runs/*/run.json` (its `command` and `status`); then whether each of these exists: `docs/opportunity.md`, `docs/market-research.md`, `docs/brief.md`, `docs/TEAM.md`, `docs/PRD.md`, `ROADMAP.md`, `docs/ARCHITECTURE.md`, `docs/brand-guide.md`.

Then say the first line that applies:

| State | Say |
|---|---|
| `run.json` says `review` | "Your [document] is waiting for your review. Open the review page or `docs/<file>`, then say done or run `/ck:<command>` again." |
| `run.json` names a stopped stage | "Your [document] stopped partway. Everything so far is in `docs/<file>`. Run `/ck:<command>` again to continue." |
| Nothing in `docs/` | "Start with `/ck:opportunity` and describe your idea in a sentence. It writes `docs/opportunity.md`: what the product is, who it is for, what the market looks like, and whether it is worth doing." |
| Opportunity only | "Run `/ck:market-research` to go deeper on the market, or `/ck:brief` if the opportunity is enough to start from." |
| Brief, no team | "Run `/ck:team`. It decides who is on this product and who owns what, and writes `docs/TEAM.md`." |
| Brief and team, no PRD | "Run `/ck:prd`. It turns the brief into full requirements and takes a few minutes." |
| PRD, no roadmap | "Run `/ck:roadmap`. It orders the work and writes `ROADMAP.md`." |
| Roadmap, no architecture | "Run `/ck:architecture`. It recommends how to build it and writes `docs/ARCHITECTURE.md`." |
| Architecture, no brand guide | "Run `/ck:brand-guide`. It takes two rounds of your review and writes the brand guide and assets." |
| Everything above | "The definition is complete. Run `/ck:design <feature>` for any feature in the PRD, or `/ck:panel <question>` for a decision. Building features is the next release of ck." |

Do not run any agent. Do not explain how the tool works unless asked.
