# Staged plan: Tomb of Dice rulebook

Date: 2026-10-11. Status: approved 2026-10-11.
Reads: `ROADMAP.md`, `docs/ARCHITECTURE.md`, `docs/TEAM.md`

## What this covers

Release one of the rulebook site, in the roadmap's order. It adds nothing to the roadmap, and where the two disagree the roadmap wins. It carries no hours, no effort estimates, and no dates for its stages.

## Phases

### Phase 1. Get ready

The site gets a home. A reader notices nothing yet.

| Stage | What | Who | State |
|---|---|---|---|
| P1-S0 | Pick the host for the rulebook site | You | done |
| P1-S1 | The site's home on the host, with the checks running on every change | Alex, Sonnet | done (12) |

Ends when: the empty site opens at its address and a failing check stops a change.

### Phase 2. The rulebook, with its icons

Every entry carries the icon the game uses for it. A reader sees the crown beside Bosses.

| Stage | What | Who | State |
|---|---|---|---|
| P2-S0 | Each entry's icon beside its heading, drawn for you to OK | Kai, Opus | running in its session |
| P2-S1 | The icons beside the headings, built from the drawing | Sasha, Sonnet | not started; follows S0 |
| P2-S2 | A line of words for each icon, for readers who cannot see it | Travolta, Opus | not started; could start now |
| P2-S3 | The page checked against the drawing and the reading rules | Robin, Sonnet | not started; follows S1 and S2 |
| P2-S4 | Someone to own the search box | Open | not started; could start now |

Ends when: you open the rulebook and every entry shows its icon, at phone width too.

### Phase 3. Search

A reader can find an entry by typing part of its name.

| Stage | What | Who | State |
|---|---|---|---|
| P3-S0 | The search screens, in three versions for you to pick | Kai, Opus | not started; follows P2-S3 |
| P3-S1 | Search, built from the version you picked | Sasha, Sonnet | not started; follows S0 |

Ends when: typing "boss" in the search box brings up Bosses.

## Stage by stage

### P1-S0. Pick the host

- Kind: yours
- Does: The author chooses where the site is hosted.
- Files: none
- Reads: `docs/ARCHITECTURE.md`
- Follows: nothing
- Done when: the host is named in `docs/ARCHITECTURE.md`.
- Hands back: nothing

### P1-S1. Set up the site's home

- Kind: build
- Does: Puts the empty site on the host and runs the checks on every change.
- Files: `.github/workflows/`, `hosting/`
- Reads: `docs/ARCHITECTURE.md`
- Follows: S0
- Done when: the site opens at its address and a failing check blocks a change.
- Hands back: a draft pull request

### P2-S0. Draw the rulebook icons

- Kind: drawing
- Does: Draws the Rulebook page with each entry's icon beside its heading.
- Files: `docs/mockups/`
- Reads: `index.html`, `icons/`, `docs/brand-guide.md`
- Follows: nothing
- Done when: the author has said OK to one drawing.
- Hands back: a draft pull request

### P2-S1. Build the rulebook icons

- Kind: build
- Does: Puts each entry's icon beside its heading, as the approved drawing shows.
- Files: `index.html`, `style.css`
- Reads: `docs/mockups/`, `CLAUDE.md`
- Follows: S0
- Done when: `bash tests/check.sh` passes and the page matches the drawing at phone and desktop width.
- Hands back: a draft pull request
- Serves: roadmap step 2

### P2-S2. Words for each icon

- Kind: words
- Does: Writes one short line per icon for readers who cannot see it.
- Files: `docs/icon-words.md`
- Reads: `icons/`, `index.html`
- Follows: nothing
- Done when: every icon in `icons/` has one line of at most eight words.
- Hands back: a draft pull request
- With: Tracy

### P2-S3. Check the rulebook page

- Kind: check
- Does: Checks the built page against the drawing, the words, and the reading rules.
- Files: none
- Reads: `docs/mockups/`, `docs/icon-words.md`, `tests/check.sh`
- Follows: S1 and S2
- Done when: every check is reported as passing or failing, each with its file and line.
- Hands back: a report in the session

### P2-S4. Own the search box

- Kind: build
- Does: Nobody on the team document owns search yet. This row holds its place.
- Files: none
- Reads: `docs/TEAM.md`
- Follows: P1-S1
- Done when: the team document names an owner for search.
- Hands back: nothing

### P3-S0. Draw the search screens

- Kind: design round
- Does: The author types `/ck:design search` and picks one of three versions on its page.
- Files: `docs/design/search/`
- Reads: `docs/PRD.md`
- Follows: P2-S3
- Done when: `docs/design/search/spec.md` exists.
- Hands back: nothing

### P3-S1. Build search

- Kind: build
- Does: Builds the search box and its results from the design spec.
- Files: `index.html`, `style.css`, `search.js`
- Reads: `docs/design/search/spec.md`
- Follows: S0
- Done when: every acceptance check in the design spec passes.
- Hands back: a draft pull request

## Open points

- Nobody owns search yet (P2-S4). Phase 3 cannot start building without an owner.
