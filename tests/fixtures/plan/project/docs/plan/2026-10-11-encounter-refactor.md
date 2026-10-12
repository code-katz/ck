# Staged plan: the encounter refactor

Date: 2026-10-11. Status: draft, not approved.
Item: A31
Reads: `docs/ARCHITECTURE.md`, `server/encounters/`

## What this covers

Creatures move out of the encounter code into tables of their own, so a fight can read them. It carries no hours, no effort estimates, and no dates for its stages.

## Phases

### Phase 0. Decide and draw

The rules of the new fight are settled and its screen is drawn. Players notice nothing.

| Stage | What | Who | State |
|---|---|---|---|
| P0-S0 | The new fight's rules, settled in a memo | Reiner, Opus | done (279) |
| P0-S1 | The new fight screen, drawn | Kai, Opus | running in its session |

Ends when: you have ruled on the memo and said OK to the drawing.

### Phase 1. The creatures' new home

Creatures live in their own tables and everything reads them from there. Players still notice nothing.

| Stage | What | Who | State |
|---|---|---|---|
| P1-S0 | Today's roster saved in tests, before anything changes | Akira, Fable | not started; could start now |
| P1-S1 | The creature tables | Akira, Fable | not started; follows S0 |
| P1-S2 | The fight reads the new tables | Akira, Fable | not started; follows S1 and P0-S1 |

Ends when: every test that passed before the refactor passes after it.

## Stage by stage

### P0-S0. Rule the new round

- Kind: words
- Does: Settles the round's open rules in a memo for the author to rule on.
- Files: `docs/reiner-the-new-round.md`
- Reads: `docs/rules/`
- Follows: nothing
- Done when: every open rule has a recommendation and the author has ruled.
- Hands back: a draft pull request

### P0-S1. Draw the new fight

- Kind: drawing
- Does: Draws the new fight screen in five frames.
- Files: `docs/mockups/`
- Reads: `docs/reiner-the-new-round.md`
- Follows: S0
- Done when: the author has said OK to the drawing.
- Hands back: a draft pull request

### P1-S0. Save today's roster

- Kind: tests
- Does: Records what every creature does today as tests, so the refactor can be checked against them.
- Files: `server/tests/`
- Reads: `server/encounters/`
- Follows: nothing
- Done when: the new tests pass on the code as it is today.
- Hands back: a draft pull request

### P1-S1. Make the creature tables

- Kind: build
- Does: Adds the creature tables and fills them from the encounter code.
- Files: `server/db/`, `server/creatures/`
- Reads: `docs/ARCHITECTURE.md`, `server/encounters/`
- Follows: S0
- Done when: the roster tests pass with creatures read from the tables.
- Hands back: a draft pull request

### P1-S2. The fight reads the tables

- Kind: build
- Does: Makes the fight read each creature from its table.
- Files: `server/encounters/`
- Reads: `docs/mockups/`, `server/creatures/`
- Follows: S1 and P0-S1
- Done when: the roster tests and the fight's own tests pass.
- Hands back: a draft pull request

## Open points

None.
