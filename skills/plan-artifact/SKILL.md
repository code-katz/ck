---
name: plan-artifact
description: The ck contract for a staged plan, docs/build-plan.md or under docs/plan/. Load when writing, checking, or reading one.
user-invocable: false
---

# The staged plan

A staged plan lays work out so that each row can be handed to one session. One row is one job for one owner. The table says where every job stands, and the entry under it says enough for a session that knows nothing else to do the job. Plain words throughout.

There are two kinds, with the same shape:

- The release plan, `docs/build-plan.md`: everything the roadmap approved, in the roadmap's order. It adds nothing to the roadmap's scope, and where the two disagree the roadmap wins.
- An item plan, `docs/plan/<date>-<slug>.md`: one piece of work (a feature, a refactor, a fix that needs more than one session).

## The top of the file

```
# Staged plan: <the product, or the item's name>

Date: <YYYY-MM-DD>. Status: draft, not approved.
Item: <ID>
Reads: <the documents it was written from, by path>
```

The `Item:` line is in an item plan only. Its id is one capital letter followed by up to seven capitals or digits, such as `A31`. `Status:` is `draft, not approved` until the author approves the plan in its review; then it is `approved <YYYY-MM-DD>`.

## Section order

1. `## What this covers`
2. `## Phases`
3. `## Stage by stage`
4. `## Open points`

### What this covers

One short paragraph: what is being built and which approved documents it comes from. A plan carries no hours, no effort estimates, and no dates for its stages. Stages are ordered by what each one waits on.

### Phases

One `### Phase <n>. <name>` heading per phase, numbered in order from 0 or from 1. Under each, in this order:

1. One or two plain sentences: what the phase is, and what the author or a user of the product would notice when it ends.
2. The stage table, with exactly these columns:

```
| Stage | What | Who | State |
|---|---|---|---|
| P2-S0 | The accounts screens, drawn in three versions for you to pick | Kai, Opus | not started; could start now |
| P2-S1 | The accounts screens, built from the one you picked | Sasha, Sonnet | not started; follows S0 |
```

3. One line, `Ends when: <something the author can judge for themselves>`.

The columns:

- **Stage** is `P<phase>-S<stage>`. Stages are numbered from 0 within their phase, in order, with no gaps. Once a plan is approved a stage keeps its id: a stage that is added or split off later takes the next free number, at the end of its phase's table, and its Follows says where it sits in the order of work. In an item plan a stage's full id puts the item first, `A31-P2-S0`; the table still shows `P2-S0`.
- **What** is the job in one plain phrase, with no file names.
- **Who** is one owner: `<Persona>, <Model>` with a persona from the roster and one of `Fable`, `Opus`, `Sonnet`, `Haiku`; or `You`, for a job that is the author's own (a decision, a seat to fill, a pick on a page); or `Open`, when nobody on the roster or the team document can own it yet. The model is the persona's own tier unless the author chose another for this job.
- **State** is one of four, in these exact words:
  - `done`, or `done (<pull request number>)`
  - `running in its session`
  - `not started; could start now`
  - `not started; follows S1`, or `follows S1 and S2`, or `follows S1, S2 and S3`. A stage in another phase is written in full, `P1-S3`. The list holds every stage this one follows that is not done yet.

Drawing, building, writing, and checking are separate rows. A row never has two owners. When a second persona should read along, name them in the stage's entry.

### Stage by stage

One entry per row, in the table's order, and no entry without a row:

```
### P2-S1. Build the accounts screens

- Kind: build
- Does: Builds the sign-in, sign-up, and account screens from the chosen design.
- Files: `app/accounts/`, `app/shared/forms/`
- Reads: `docs/design/accounts/spec.md`, `docs/ARCHITECTURE.md`
- Follows: S0
- Done when: every acceptance check in the design spec passes and the project's tests pass.
- Hands back: a draft pull request
```

- The title after the id names the session: `[P2-S1] [Sasha Sonnet] Build the accounts screens`, or `[A31-P2-S1] [...]` in an item plan. That whole name must be 59 characters or fewer, so keep the title short. A fix to a stage that is done runs in a session of its own, named with ` fix` after the stage's id, the stage's owner, and a title for the fix: `[A31-P1-S5 fix] [Akira Fable] Mend the scan's natural 1`. It has no row and changes no State.
- **Kind** is one of: `build` (changes the product and its tests), `drawing` (mockups only, no product code), `words` (one text file, no code), `tests` (tests only, no product code), `check` (changes nothing and reports), `design round` (the author types `/ck:design <feature>`; no session is opened for it), `yours` (a row whose owner is `You`).
- **Does** is two sentences at most.
- **Files** is what the session may change, by folder or file, or `none`.
- **Reads** is what it reads first, by path.
- **Follows** is `nothing` or the stages that must be done first, written as in the State column. A stage follows only stages that come before it.
- **Done when** is something that can be checked.
- **Hands back** is `a draft pull request`, or `a report in the session` for a check, or `nothing` for a row that is the author's.
- Two more lines are optional: `With: <Persona>`, a second persona who reads along, and `Serves: <the requirement or roadmap step>`.

Small rules the script reads by: a bar inside a table cell is written `\|`; a field's value may run on over the next lines, up to a blank line or the next `- ` line; and numbers are written without leading zeros.

### Open points

Seats that are not filled and decisions the plan needs, each with the stage it holds up. "None." when there are none.

## Checklist

1. The four sections are present, in order, with these headings.
2. Every phase has its sentences, a stage table with the four columns, and an `Ends when:` line.
3. Every row has one owner, written as the contract says, and every persona named is on the roster.
4. Stage ids are `P<phase>-S<stage>`, numbered from 0 within each phase with no gaps, and every row has exactly one entry under Stage by stage with the same id.
5. Every entry has Kind, Does, Files, Reads, Follows, Done when, and Hands back, and its Kind is from the list. A `You` row has Kind `yours`, and only a `You` row does.
6. Every Follows names stages that exist and come earlier.
7. Every State is one of the four forms, and a row that is not started names exactly the stages it follows that are not done.
8. Every session name is 59 characters or fewer.
9. No hours, effort estimates, or dates for stages anywhere in the plan.
10. The plan is under 3,500 words.
11. Plain words, no em-dash, and never the total size of the roster.

`scripts/plan.py check <file>` checks items 1 to 8 and 10, and `scripts/plan.py refresh <file>` writes the State of every row that is not started and leaves a correct plan as it is. The check also prints a line that starts `note:` for a row that is done or running while a stage it follows is not; that is the author's call and not a problem.
