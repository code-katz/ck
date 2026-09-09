# ck

Code Katz personas and workflows for Claude Code. One plugin: the product-definition pipeline from an idea to a designed feature, a three-lens decision panel, and 21 personas as subagents and switch commands on three model tiers.

Every document `ck` writes goes into the repository you opened Claude Code in, under `docs/` (or `ROADMAP.md` and `brand/`), and is committed with your product. Every document has a contract, so it has the same shape every time, on every project.

## Status

Phase one, first release in progress. What runs today:

| Command | What it does | State |
|---|---|---|
| `/ck:next` | Says what to run next, in one sentence | Built |
| `/ck:brief <idea>` | Toni runs a short market pass, River writes `docs/brief.md`, a checker validates it | Built |
| `/ck:panel <question>` | River, Toni, and Kai argue one question on three different models; a memo shows where they disagree | Built |
| `/ck:prd` | River drafts `docs/PRD.md` from the brief, a checker validates, the panel challenges, River rewrites; you review on a page you can comment on | Built |
| `/ck:team` | Who is on this product, who owns what, which seat is missing: `docs/TEAM.md` | Built |
| `/ck:architecture` | Akira recommends an architecture from the PRD and roadmap, challenged by Morgan, Alex, and Jordan | Script built; the gate skill is next |
| `/ck:opportunity`, `/ck:market-research`, `/ck:roadmap`, `/ck:brand-guide`, `/ck:design` | The rest of the pipeline | Specified in the PRD; next on the roadmap |
| `/ck:<persona>` | Switch this session to a persona, for example `/ck:river` | Built, all 21 |
| `ck:<persona>` | Delegate one task to a persona on its own model tier, for example the `ck:river` subagent | Built, all 21 |

The specification is the phase-one PRD in `code-katz/.github`, `plans/2026-09-05-ck-plugin-prd-phase-1.md`.

## Prerequisites

1. **Uninstall the old team tool** (`claude-team-cli`). Its persona commands, subagents, and session hook collide with `ck`'s. Steps are below. `ck` warns at the start of every session while any of it remains.
2. **Claude Code 2.1.221 or later**, signed in with `/login` to a Claude account on a paid plan. Dynamic workflows must be available: on a Pro plan, turn them on in `/config`; an organization can disable them.
3. For review pages with comments: the same version, and a Claude account that can publish artifacts. A page's owner can comment on it on a Max plan; sharing a page with other people needs a Team or Enterprise plan.
4. For development only: Bash 4 or newer, `python3`, and Node 20 or newer, for `scripts/generate.sh` and `tests/run.sh`. The plugin itself needs none of them at run time.

### Uninstalling the old team tool

Remove each of these if present:

```
rm -f ~/.local/bin/claude-team
rm -rf ~/.claude/team
```

Then remove the persona files it installed under `~/.claude/commands/` and `~/.claude/agents/` (one `<persona>.md` per persona: `river.md`, `akira.md`, and so on), the block it wrote between its markers in `~/.claude/CLAUDE.md`, and its `SessionStart` entry in `~/.claude/settings.json`. Start a new session; the warning line is gone when everything is removed.

## Install

From the Code Katz marketplace, once the entry is published:

```
/plugin marketplace add code-katz/claude-plugins
/plugin install ck@code-katz
```

For development, load the checkout directly:

```
claude --plugin-dir /path/to/ck
```

After editing a workflow in a running session, run `/reload-skills`.

## How a run works

1. You type a command. If it needs a document you do not have yet, it says which command writes it, and stops.
2. The work runs in the background as a workflow; `/workflows` shows every agent, model, and token count if you want them. The command itself never prints them.
3. The document appears in your repository. Commands with a review step publish it as a page you can comment on, with the steps in the page's banner. Say "done" in the chat when you have finished; Claude applies every comment, republishes the same page, and resolves each one with a line saying what changed.
4. `/ck:next` tells you what comes next.

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
| Decision memos | `docs/decisions/` |

`.ck/runs/` is a cache for in-progress runs. Nothing depends on it, and `ck` excludes it from git locally without touching your `.gitignore`.

## Models

Three tiers, set once in `tiers.conf`:

| Tier | Model | Personas |
|---|---|---|
| Judgment | Fable 5.1 | River, Akira, Morgan, Sage, Jordan, Reiner |
| Craft | Opus 5 | Toni, Kai, Iris, Quinn, Casey, Cornelius, Ernie, Rez, Tracy, Travolta, Noon |
| Execution | Sonnet 5 | Sasha, Alex, Robin, Piper |

Validators run on Haiku 4.5. The panel puts its three lenses on three different models: River on Fable 5.1, Toni on Opus 5, Kai moved down to Sonnet 5. A switch command (`/ck:river`) runs on your session's model; delegation (`ck:river`) runs on the tier.

## Development

Personas live in `profiles/<name>.md` and `tiers.conf`. Everything else about a persona is generated:

```
bash scripts/generate.sh     # agents/, skills/<persona>/, profiles/ROSTER.md
bash tests/run.sh            # the static checks
```

Edit the profile, never the generated file; the generator refuses to overwrite uncommitted hand edits to generated files unless you pass `--force`. Every release bumps `version` in `.claude-plugin/plugin.json`, or nobody receives it.

Layout:

```
.claude-plugin/plugin.json   the manifest; name "ck" sets the /ck: prefix
profiles/                    persona source of truth, plus the generated ROSTER.md
tiers.conf                   persona -> model
agents/                      generated subagents, ck:<name>
skills/<persona>/            generated switch commands, /ck:<name>
skills/prd, next, review-page
skills/*-artifact/           the document contracts
workflows/                   panel, brief, draft (PRD and architecture), team
hooks/hooks.json             usage log on SubagentStart; old-tool check on SessionStart
scripts/                     generate.sh, usage-log.sh, check-prereqs.sh
tests/                       run.sh and two fixture projects
```

## License

MIT. See `LICENSE`.
