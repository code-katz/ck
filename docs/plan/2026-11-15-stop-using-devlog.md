# Staged plan: Stop ck using or writing the devlog

Date: 2026-11-15. Status: approved 2026-11-16.
Page: https://claude.ai/artifact/TmSShhZJoL6PfEMVJMAnmN
Item: R1
Reads: `ROADMAP.md`, `CLAUDE.md`, `RELEASING.md`, `skills/`, `templates/how-we-work/`

## What this covers

ck stops writing a devlog entry for each release and stops offering `/devlog` when a command finishes. This plan comes from the author's request and from one search of the whole project for "devlog". `ROADMAP.md` stays the one record, written on "log it".

Every place the search found, with the ones the request did not name marked "new":

1. `RELEASING.md`, step 1: "a DEVLOG entry" in the release commit.
2. `CLAUDE.md`, "Branches and merges": the sentence that a release's `DEVLOG.md` entry goes in its own release commit.
3. `CLAUDE.md`, "Checks that cost": `DEVLOG.md` in the list of files whose change runs no tests.
4. Eight skills that end with "If the devlog skill is installed, add that `/devlog` can record...": architecture, brand-guide, brief, market-research, opportunity, prd, roadmap, team.
5. The claude-md skill: three lines that name `DEVLOG.md` when it fills the template's records and skip-list blanks. The template files themselves hold only the blanks and never name the devlog, so no new template version is needed.
6. New: the next skill, which gives "the `/devlog` note" as an example of a suggestion a lane leaves out.
7. New: the plan skill and the start skill, which each say to send "no linter, devlog, or wrap-up prompt". These lines only silence the separate devlog skill, which the author is removing from the Mac, so they go too.
8. New: `ROADMAP.md`, the "A release in one command" row, which says a script can run the release steps "from the DEVLOG entry".
9. New: `DEVLOG.md` itself, whose heading says it is kept up automatically. It is kept as closed history; only its heading changes, to say it ends at 0.1.43.
10. New, and left alone: four analysis files under `docs/analysis/` mention the devlog as history. They are dated records and are not in git.

Nothing in the scripts, the tests, the hooks, the personas, the workflows, the README, or the hosted check names the devlog.

One stage does all the wording, because every merge to `main` is a release and one release costs less than two. No separate check stage is planned: the stage's own search and the release check in `RELEASING.md` step 7 already show the result, so a check session would save the author nothing.

## Phases

### Phase 1. The devlog leaves ck

ck's rules, release steps and commands stop naming the devlog. When this ends, a release carries no devlog entry and a finished command no longer offers `/devlog`.

| Stage | What | Who | State |
|---|---|---|---|
| P1-S0 | Four choices about what the removal leaves behind | You | done |
| P1-S1 | The devlog taken out of the rules, the release steps and the commands | River, edit | not started; could start now |
| P1-S2 | The roadmap row that cites the devlog entry, reworded | River, edit | not started; follows S1 |

Ends when: you finish a ck command in a fresh session and it says nothing about `/devlog`, and the release that shipped the change has no devlog entry.

## Stage by stage

### P1-S0. Settle what the removal leaves

- Kind: yours
- Does: Answers the four questions under Open points, one at a time.
- Files: none
- Reads: `docs/plan/2026-11-15-stop-using-devlog.md`
- Follows: nothing
- Done when: each of the four open points has the author's typed answer.
- Hands back: nothing

### P1-S1. Take the devlog out of ck

- Kind: build
- Does: Removes places 1 to 7 in the list above and changes the heading of `DEVLOG.md` (place 9) to say it ends at 0.1.43. A release says what changed in its commit title and the pull request's description only; no GitHub release notes, no changelog command, and no "ck keeps no devlog" sentence. The release that ships it writes no devlog entry.
- Files: `RELEASING.md`, `CLAUDE.md`, `DEVLOG.md`, `.claude-plugin/plugin.json`, and `SKILL.md` in `skills/architecture/`, `skills/brand-guide/`, `skills/brief/`, `skills/market-research/`, `skills/opportunity/`, `skills/prd/`, `skills/roadmap/`, `skills/team/`, `skills/claude-md/`, `skills/next/`, `skills/plan/`, `skills/start/`
- Reads: `docs/plan/2026-11-15-stop-using-devlog.md`, `RELEASING.md`, `CLAUDE.md`, `skills/claude-md/SKILL.md`, `scripts/claude-md.py`
- Follows: S0
- Done when: `git grep -i devlog` finds only `DEVLOG.md` and the `ROADMAP.md` row; `python3 scripts/claude-md.py status CLAUDE.md` still says "stamped" and "behind: no"; and `bash tests/run.sh` passes.
- Hands back: a draft pull request
- With: Alex

### P1-S2. Reword the roadmap row

- Kind: words
- Does: Rewords the "A release in one command" row so the script no longer starts from the devlog entry, so it says a release's record is its commit title and the pull request's description. It rides on the "log it" pull request for the release from S1.
- Files: `ROADMAP.md`
- Reads: `ROADMAP.md`, `RELEASING.md`
- Follows: S1
- Done when: `git grep -i devlog -- ROADMAP.md` finds nothing, and the release table shows the release from S1.
- Hands back: a draft pull request

## Open points

None. The four points were answered on the page on 2026-11-16:

1. `DEVLOG.md` is kept as closed history, with its heading changed to say it ends at 0.1.43.
2. A release says what changed in its commit title and the pull request's description only. No changelog command is added; `git log --grep '^0.1.'` lists the titles on demand.
3. The "no linter, devlog, or wrap-up prompt" lines in the plan and start skills are removed, because the author is removing the devlog skill.
4. No "ck keeps no devlog" sentence is added to `CLAUDE.md`, for the same reason.

The devlog skill itself is removed from the Mac outside this plan: the folder at `~/.claude/skills/devlog` goes to the Trash, and the copy in the Claude app's skills settings is switched off by the author.
