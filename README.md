# Code Katz "ck" Plugin

### Stop prompting. Start leading. A complete product team, inside Claude.

| | |
|---|---|
| **👑 You are the CEO**<br>Build your vision on Claude in days. You set the direction; your team does the work. | **🧑‍💻 Direct technical team members**<br>A product manager, a marketer, developers, a designer, a tester and a security lead, ready the moment you are. |
| **🔁 Use established product lifecycle workflows**<br>The proven path real product teams follow, from idea to research, requirements, roadmap, design and build. | **🎯 Improve Claude's accuracy, reduce Claude's costs**<br>Specialists who check each other's work, and the right Claude model for every job. |

You have the idea. ck gives you the team to build it. No coding background needed: ck handles how code gets written, tested and shipped, so you can stay focused on what you are building and why.

---

## 👑 You are the CEO

AI can produce work faster than anyone can check it. ck puts you in charge of the pace, so quality keeps up with speed.

- Your team brings you finished work as a private page with one link.
- You comment on it like a shared document and say "done".
- Claude proposes a change for every comment, and you approve the ones you want.
- Nothing joins your product until you say so.

You make the calls. Your team makes it happen.

## 🧑‍💻 Direct technical team members

Every role is written down once, so you never explain the job again. Just hand over the work.

- **River**, product manager: turns your idea into a clear plan: what to build, for whom, and in what order.
- **Toni**, marketing: maps your market and sharpens how your product stands out, with a source behind every claim.
- **Akira**, lead developer: designs how your product will be built.
- **Kai**, designer: draws three versions of every screen so you can pick the best.
- **Robin**, tester: builds a checklist for every journey through your product and proves each one works.
- **Morgan**, security lead: pressure-tests your build plan before it is final.
- **Quinn**, project manager: breaks the build into steps, each with one owner, and keeps them moving.

Need more? Frontend and backend developers, an operations lead, a brand artist and a business advisor are ready to join.

## 🔁 Use established product lifecycle workflows

**Idea → market research → brief → product requirements → roadmap → build plan → design → build.**

The same path successful product teams follow, built in. Every step produces a polished document saved in your project, in the same shape every time. Not sure what is next? Type `/ck:next` and ck tells you.

## 🎯 Improve Claude's accuracy, reduce Claude's costs

**Sharper results.** The one who builds something is the worst person to check it, so ck brings in a fresh pair of eyes: Robin tests and Morgan challenges work they did not write. Every document is checked before you see it, and for the big decisions, three team members on three different Claude models debate it out so you see every angle.

**Smarter spending.** Pay for Claude's most powerful model only where it counts. Big decisions go to the strongest model; everyday building goes to a less expensive one. In a recorded test, a mid-priced Claude model matched the strongest on coding at about a fifth of the cost.

**Leaner by design.** ck's busiest commands were rebuilt to read 60% to 80% fewer words every time they run, so more of your Claude plan goes into building your product.

---

## What you can do today, and what is coming

- **Ready now:** take a product from idea to research, requirements, roadmap, architecture, brand and chosen design; plan and build it in steps; knock out small tasks on a quick path; see exactly what your work costs; file tester reports straight into GitHub.
- **Coming next:** release a new version in one step, and a full code-quality review.
- **On the horizon:** launch and go-to-market, and fixing bugs after launch.

ck is actively developed and ships new versions often. See the [roadmap](ROADMAP.md) for every release.

## How to start

1. Have Claude Code (version 2.1.221 or later) and a paid Claude plan. To comment on your own pages, you need a Max plan. On a Pro plan, turn on dynamic workflows in `/config`.
2. If you once installed the older `claude-team-cli` tool, remove it first.
3. Type these two lines in Claude Code:

```
/plugin marketplace add code-katz/claude-plugins
/plugin install ck@code-katz
```

4. Open your project's folder and type `/ck:next`.

Type each command; don't paste it.

---

## Reference

The rest of this page is the full detail: every command, where each document goes, which Claude model each team member uses, and how to work on ck itself.

### Every command

| Command | What it does | State |
|---|---|---|
| `/ck:next` | Shows the whole pipeline as a table (each step in order, what it does, the document it writes, and where your project stands), then says what to run next in one sentence | Built |
| `/ck:brief <idea>` | Toni runs a short market pass, River writes `docs/brief.md` (from your sentence, or from `docs/opportunity.md`), a checker validates it; you review on a page you can comment on | Built; drilled 2026-10-04 on a real project |
| `/ck:plan [work]` | Quinn lays the work out as a staged plan: phases, then stages, one job and one owner per row, each with its state. With nothing after it, the whole release from the roadmap (`docs/build-plan.md`); with a piece of work after it, that one item (`docs/plan/`). You review it on a page you can comment on | Built |
| `/ck:start [stage]` | Opens the plan's sessions and keeps its board. For a stage it offers a card that starts a session for that one job, named from the row, such as `[R1-P2-S1] [Akira Opus high] Make the creature tables`; with nothing after it, it updates the State column from the sessions and their pull requests and offers every row that could start now. With `fix <stage> <what is wrong>` it offers a card for a session that fixes one fault in a stage that is done, named such as `[R1-P1-S5 fix] [Akira Opus high] Mend the scan's 1`; the stage stays done. The row's job word (design, build, edit, review, write) sets each session's model and effort, from `tiers.conf`, and every new session checks both before it works. You click each card | Built |
| `/ck:do <task>` | The quick path, all in the chat: a plan of a few lines (who does what), you say go, the right personas work in the background on their own tiers, a mockup comes back as a link when you ask for one first, and a build waits on its own branch until you say merge. No documents and no review pages | Built; tried on a real project on 2026-10-27 |
| `/ck:issue <report>` | Files a tester's report (pasted text, an email, a TestFlight line, a screenshot) into this repository's GitHub issue list, under its own form and labels, or as a comment on the issue that already covers it. The draft is shown in the chat first, with no tester's name or email in it, and goes to GitHub only when you say `file` | Built; tried on a real project on 2026-11-14 |
| `/ck:cards [cards \| verify]` | Robin's journey-card loop. With nothing after it, or card numbers such as `01 03`, it offers a card for a Robin session on Sonnet that runs those cards from `docs/journeys/` by the project's own guide; each fault becomes a draft issue through `/ck:issue`'s steps, with its `Test case:` line naming the rows (`09-D4`), and the run's drafts are read on one review page and filed on one `file`. A merged fix labels its bug `to verify`. With `verify` it lists those bugs and offers a card for a session that re-runs exactly their cards, stopping at each card's last named row, and labels each bug `verified` or re-opens it with what Robin saw. Each run ends by rebuilding the project's bug list page from GitHub. You click each card | Being built |
| `/ck:claude-md` | Writes or updates the "How we work" section of this project's `CLAUDE.md` from ck's template (`templates/how-we-work/`), tailored to the project: its lanes, main folder, records and secrets filled in, a rule that does not fit changed or left out. It sorts the project's memory into keep, retire, or move. You review the section on a page you can comment on; it is written on a branch with a draft pull request only when you approve. The rest of `CLAUDE.md` is left as it is, and nothing runs unless you type the command | Built |
| `/ck:cost [history \| <session id>]` | What this session has cost so far: a table with a row per lane (the main session, each persona, Claude Code's own background calls) and a column per kind of token (input, output, cache write, cache read), each cell in tokens and dollars, priced from Anthropic's pricing page and checked against Claude Code's own figure. Once the session has a pull request, a line after each answer shows the cost so far. At merge, the session gets one line with the pull request's cost, and the pull request gets a comment with the table and the numbers as hidden data. A pull request's cost is what the sessions that worked on its branch spent since their previous merge; a session that only merged it is shown apart. `history` lists each pull request's cost | Built; tried on real sessions |
| The memory gate | Not a command: it runs on its own. Before a session saves anything to memory, it shows you the text, whether it belongs in memory or in the project's `CLAUDE.md` and why, and any memory or `CLAUDE.md` line that already says it or says the opposite. You pick save to memory, add to `CLAUDE.md` (written at once on a branch with a draft pull request), or don't save. A hook makes Claude Code ask you before every write to a memory folder, in auto mode too | Built |
| `/ck:panel <question>` | River, Toni, and Kai argue one question on three different models; a memo shows where they disagree | Built |
| `/ck:prd [--panel]` | River drafts `docs/PRD.md` from the brief, a checker validates, River adds a premortem; with `--panel`, three specialists on three models challenge it first and River rewrites; you review on a page you can comment on | Built; drilled 2026-10-05 on a real project |
| `/ck:team [show \| invite <persona> [why] \| drop <persona> [why]]` | This project's team, kept in `.claude/ck-team.conf`: the core (River, Quinn, Akira, Sasha, Kai, Robin, Alex, Morgan) plus whoever is invited; ck suggests and casts only these seats. `show`, `invite`, and `drop` change the file and nothing else. With nothing after it: who is on this product, who owns what, which seat is missing, as `docs/TEAM.md`, reviewed on a page you can comment on; its cast is then invited onto the team | Built; drilled 2026-10-05 on a real project; the team file is new in 0.1.20 |
| `/ck:architecture [--panel]` | Akira recommends an architecture from the PRD and roadmap and adds a premortem; with `--panel`, Morgan, Alex, and Jordan challenge it first on three models; you review on a page you can comment on | Built; drilled 2026-10-05 on a real project |
| `/ck:opportunity <idea>` | River frames the idea, Toni, Akira, and a domain seat write sourced sections, River assembles `docs/opportunity.md`; you review on a page you can comment on | Built; drilled 2026-10-01 |
| `/ck:market-research [focus]` | Toni plans the questions, researchers answer them from the web in parallel, a cross-check marks what is unsourced or contradictory, Toni writes `docs/market-research.md` | Built; drilled 2026-10-01 |
| `/ck:roadmap` | River prioritizes the PRD's requirements into three tiers, Quinn sequences them and writes `ROADMAP.md` in the roadmap skill's format, with a dated revision entry; you review on a page you can comment on | Built; drilled 2026-10-05 on a real project |
| `/ck:brand-guide` | Three rounds: Toni positions, Iris designs four to six brand directions, Kai skins a screen in each, you pick from a gallery; the picks are worked up in full as a second gallery; then the brand direction record, `docs/brand-guide.md`, and the assets under `brand/final/` | Built; drilled 2026-10-01 |
| `/ck:design <feature>` | River pulls the feature from the PRD, Kai draws three labeled variants of its screens with their empty, loading, and error states, you pick one from a gallery, then Kai finishes it at full fidelity with `docs/design/<feature>/spec.md` and Robin adds the acceptance checks | Built; drilled 2026-10-01 |
| `/ck:<persona>` | Switch this session to a persona, for example `/ck:river` | Built, every persona |
| `ck:<persona>` | Delegate one task to a persona on its own model tier, for example the `ck:river` subagent | Built, every persona |

### Removing the old team tool

Remove each of these if present:

```
rm -f ~/.local/bin/claude-team
rm -rf ~/.claude/team
```

Then remove the persona files it installed under `~/.claude/commands/` and `~/.claude/agents/` (one `<persona>.md` per persona: `river.md`, `akira.md`, and so on), the block it wrote between its markers in `~/.claude/CLAUDE.md`, and its `SessionStart` entry in `~/.claude/settings.json`. Start a new session; the warning line is gone when everything is removed.

### How a run works

1. You type a command. If it needs a document you do not have yet, it says which command writes it, and stops.
2. The work runs in the background as a workflow; `/workflows` shows every agent, model, and token count if you want them. The command itself never prints them.
3. The document appears in your repository. Commands with a review step publish it as a page you can comment on, with the steps in the page's banner. Comment on the page without sending comments to Claude (a comment sent to Claude wakes a cloud session that cannot see your files), then say "done" in your Claude Code session; Claude proposes a change for each comment, applies the ones you approve, republishes the same page, and tells you what changed.
4. Each pipeline command closes with the pipeline table: each step in order, what it does, the document it writes, and where your project stands, with the one thing to run next under it. `/ck:next` shows the same table at any time.

Type each command; do not paste it. A pasted command reaches Claude as text, and the skills that own the run record and the review page run only when typed, so the most Claude can do is start the workflow underneath: the document is written, with no run record and no review page. Typing the command afterwards takes the finished document to its review.

Where things go, inside your repository:

| Document | Path |
|---|---|
| Opportunity analysis | `docs/opportunity.md` |
| Market research | `docs/market-research.md` |
| Brief | `docs/brief.md` |
| PRD | `docs/PRD.md` |
| Team | `docs/TEAM.md` |
| Roadmap | `ROADMAP.md` |
| Architecture | `docs/ARCHITECTURE.md` |
| Brand guide and assets | `docs/brand-guide.md`, `brand/` |
| Design gallery and spec | `docs/design/<feature>/` |
| Staged build plan | `docs/build-plan.md` |
| Decision memos | `docs/decisions/` |

A staged plan for one piece of work, written by `/ck:plan <work>`, goes under `docs/plan/`.

`.ck/runs/` is a cache for in-progress runs. Nothing depends on it, and `ck` excludes it from git locally without touching your `.gitignore`.

### Models

Three tiers, set once in `tiers.conf`:

| Tier | Model | Personas |
|---|---|---|
| Judgment | Fable 5.2 | River, Akira, Morgan, Sage, Jordan, Reiner |
| Craft | Opus 5.5 | Toni, Kai, Iris, Quinn, Casey, Cornelius, Ernie, Rez, Tracy, Travolta, Noon |
| Execution | Sonnet 5.5 | Sasha, Alex, Robin, Piper |

Validators run on Haiku 5.5. The panel puts its three lenses on three different models: River on Fable 5.2, Toni on Opus 5.5, Kai moved down to Sonnet 5.5. A switch command (`/ck:river`) runs on your session's model; delegation (`ck:river`) runs on the tier.

### Development

Personas live in `profiles/<name>.md` and `tiers.conf`. Everything else about a persona is generated:

```
bash scripts/generate.sh     # agents/, skills/<persona>/, profiles/ROSTER.md
bash tests/run.sh            # the static checks, and every workflow script run with stub agents
```

Edit the profile, never the generated file; the generator refuses to overwrite uncommitted hand edits to generated files unless you pass `--force`. Every release bumps `version` in `.claude-plugin/plugin.json`, or nobody receives it.

Layout:

```
.claude-plugin/plugin.json   the manifest; name "ck" sets the /ck: prefix
profiles/                    persona source of truth, plus the generated ROSTER.md
tiers.conf                   persona -> model
agents/                      generated subagents, ck:<name>
skills/<persona>/            generated switch commands, /ck:<name>
skills/opportunity, prd, architecture, brand-guide, design, next, review-page, claude-md, memory-gate
skills/*-artifact/           the ten document contracts
templates/how-we-work/       one "How we work" template per release, which /ck:claude-md tailors into a project's CLAUDE.md
workflows/                   panel, brief, draft (PRD and architecture), team, opportunity-draft, market-research, roadmap, brand, design-round
hooks/hooks.json             usage log on SubagentStart; old-tool check and the memory gate's rule on SessionStart; the memory gate on PreToolUse
scripts/                     generate.sh, render-review.py, render-gallery.py, usage-log.sh, check-prereqs.sh, plan.py, claude-md.py, memory-gate.py
tests/                       run.sh, workflows.mjs (the workflow scripts run with stub agents), two fixture projects, the gallery fixtures, and the drill logs
```

## Roadmap at a glance

✅ works today · 🔜 coming next · 🔭 on the horizon

| | What | Team members | Version | Date |
|---|---|---|---|---|
| ✅ | Argue a hard question on three Claude models | River, Toni, Kai | 0.1.0 | 2026-09-09 |
| ✅ | Check whether an idea is worth building, with market research | River, Toni | 0.1.0 | 2026-10-01 |
| ✅ | Set the brand and draw the screens, then pick one | Toni, Iris, Kai | 0.1.0 | 2026-10-01 |
| ✅ | A checklist for every journey through the product | Robin | 0.1.0 | 2026-10-01 |
| ✅ | Write the brief | River, Toni | 0.1.3 | 2026-10-04 |
| ✅ | Write the product requirements and the roadmap | River, Quinn | 0.1.6 | 2026-10-05 |
| ✅ | Plan how the product will be built, with a security challenge on request | Akira, Morgan | 0.1.6 | 2026-10-05 |
| ✅ | Show the whole path and the next step | | 0.1.9 | 2026-10-07 |
| ✅ | Plan the build in steps and run each step with its owner | Quinn | 0.1.10 | 2026-10-12 |
| ✅ | A quick path for small tasks | Any | 0.1.10 | 2026-10-12 |
| ✅ | Read less on the busiest commands | | 0.1.16 to 0.1.21 | 2026-10-27 to 2026-10-30 |
| ✅ | See what a session or a change cost | | 0.1.19 | 2026-10-28 |
| ✅ | The right Claude model and effort for each job | | 0.1.27 | 2026-11-05 |
| ✅ | File a tester's report as a GitHub issue | | 0.1.37 | 2026-11-14 |
| 🔜 | Release a new version in one step | Alex | | |
| 🔜 | Review a project's code quality | | | |
| 🔜 | Read even less on every command | | | |
| 🔜 | Rule changes in ck reach your projects on their own | | | |
| 🔭 | Launch and go to market | Toni | | |
| 🔭 | Fix bugs after launch | | | |

The full plan, with every release, is in the [roadmap](ROADMAP.md).

## License

MIT. See `LICENSE`.
