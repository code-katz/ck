---
name: next
description: Shows the whole product-definition pipeline as a table (each step in order, what it does, the document it writes, and where this project stands), then says what to run next in one sentence. Use when you do not know where to start, what the steps are, or what comes after the step you just finished.
disable-model-invocation: true
---

Look at the project, show the table, then say exactly one thing under it. Plain words. No token counts, no more than one action.

## 1. Look

Run this in the repository Claude Code was opened in, exactly as written, and trust its output over any other listing:

```bash
ls docs/opportunity.md docs/market-research.md docs/brief.md docs/TEAM.md docs/PRD.md ROADMAP.md docs/ARCHITECTURE.md docs/brand-guide.md 2>/dev/null
find docs/design -maxdepth 2 \( -name gallery.html -o -name spec.md \) 2>/dev/null
grep -rHoE --include=run.json '"(command|status)" *: *"[^"]*"' .ck/runs 2>/dev/null | sort
```

The first line lists the documents that exist. The second lists the designs: a feature folder with `spec.md` is finished, and one with only `gallery.html` is waiting for its review. The third lists every run record, oldest first, so the last record for a command is the one that counts. A folder under `.ck/runs/` with no `run.json` is not a record.

## 2. The table

Print this table with the Status column filled in for this project. Keep the columns, the order of the rows, and the wording of the first four columns.

| # | Step | What it does | Writes | Status |
|---|---|---|---|---|
| 1 | Opportunity: `/ck:opportunity <idea>` | Says what the product is, who it is for, what the market looks like, and whether it is worth doing. | `docs/opportunity.md` | |
| 2 | Market research, optional: `/ck:market-research` | Goes deeper on the market from the web, with a source for every claim. | `docs/market-research.md` | |
| 3 | Brief: `/ck:brief` | Names the problem, the user, the number that should move, and a smaller first version, after a short look at comparable products. | `docs/brief.md` | |
| 4 | Team: `/ck:team` | Decides who is on this product, who owns what, and which seat is missing. | `docs/TEAM.md` | |
| 5 | PRD: `/ck:prd` | Turns the brief into full requirements. | `docs/PRD.md` | |
| 6 | Roadmap: `/ck:roadmap` | Sorts the requirements into three tiers and puts them in the order to build. | `ROADMAP.md` | |
| 7 | Architecture: `/ck:architecture` | Recommends how to build it, with the alternatives it turned down. | `docs/ARCHITECTURE.md` | |
| 8 | Brand guide: `/ck:brand-guide` | Builds the brand identity (mark, colors, type) over two rounds of your picks, and writes the guide and the assets. | `docs/brand-guide.md`, `brand/` | |
| 9 | Design, once per feature: `/ck:design <feature>` | Draws three variants of one feature's screens, then finishes the one you pick with a design spec. | `docs/design/<feature>/` | |
| any | Panel: `/ck:panel <question>` | Three specialists argue one question, and a memo shows where they disagree. | `docs/decisions/` | |

Fill Status with the first of these that applies to the row:

| Status | When |
|---|---|
| `running` | This session launched the step's run and has not yet had its notification. |
| `in review` | The last run record for the step's command has a `status` that starts with `review`. |
| `stopped partway` | The last run record for the step's command has any other `status` except `final`. |
| `done` | The step's document exists. |
| `next` | The sentence in section 3 names the step. |
| `skipped` | The step is 1 or 2, it has no document, and a later step has one. |
| `not started` | Everything else. |

A step's command is the word after `/ck:` in its row; a run record's `command` is the same word. Row 9 is per feature: name each finished feature and each one waiting for review ("done: checkout; in review: onboarding"), and with no design folder use `next` or `not started`. The panel row's status is always `any time`.

Under the table, print this line as it is: "No step writes a go-to-market plan or a marketing brief yet. The marketing thinking is in steps 1, 2, 3, and 8; a go-to-market plan comes in a later release of ck."

## 3. The one thing to say

Then say the first line that applies. "The newest run record" is the last one the third line of the look printed, whatever its command.

| State | Say |
|---|---|
| This session is still waiting on a run it launched | "Your [document] is still being written. I'll tell you when it's ready." |
| The newest run record is `in review` | "Your [document] is waiting for your review. Open the review page or `docs/<file>`, then say done or run `/ck:<command>` again." |
| The newest run record is `stopped partway` | "Your [document] stopped partway. Everything so far is in `docs/<file>`. Run `/ck:<command>` again to continue." |
| No opportunity analysis and no brief | "Start with `/ck:opportunity` and describe your idea in a sentence. It writes `docs/opportunity.md`: what the product is, who it is for, what the market looks like, and whether it is worth doing." |
| Opportunity, no market research, no brief | "Run `/ck:market-research` to go deeper on the market, or `/ck:brief` if the opportunity is enough to start from." |
| Opportunity and market research, no brief | "Run `/ck:brief`. It starts from your opportunity analysis and writes `docs/brief.md`." |
| Brief, no team | "Run `/ck:team`. It decides who is on this product and who owns what, and writes `docs/TEAM.md`." |
| Brief and team, no PRD | "Run `/ck:prd`. It turns the brief into full requirements and takes a few minutes." |
| PRD, no roadmap | "Run `/ck:roadmap`. It orders the work and writes `ROADMAP.md`." |
| Roadmap, no architecture | "Run `/ck:architecture`. It recommends how to build it and writes `docs/ARCHITECTURE.md`." |
| Architecture, no brand guide | "Run `/ck:brand-guide`. It takes two rounds of your review and writes the brand guide and assets." |
| Everything above | "The definition is complete. Run `/ck:design <feature>` for any feature in the PRD, or `/ck:panel <question>` for a decision. Building features is the next release of ck." |

Do not run any agent. Do not explain how the tool works unless asked.

## 4. When another skill closes with this

Every gate-owning skill ends by reading this file. Do sections 1 to 3 the same way, after that skill's own finished sentence: the table, the line under it, then the one thing to say.
