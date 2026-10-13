---
name: doc-artifact
description: The Code Katz contract for a document /ck:proof writes from a request, which is a proposal, an analysis, or a note. Every kind opens with one sentence and the decisions the reader must make, and ends with the open questions and what was read. It gives each kind's own sections between, how the three kinds differ, and the checklist. Load when writing, revising, or validating a document under docs/proposal/, docs/analysis/, or docs/note/, inside or outside a ck workflow.
user-invocable: false
---

# The document contract (`<project-repo>/docs/<kind>/<date>-<slug>.md`)

One contract for the three kinds of document `/ck:proof` writes from a request: a proposal, an analysis, and a note. Every kind opens with one sentence and then the decisions the reader must make, and ends with the open questions and then what was read. Only the sections between are the kind's own, so a reader who has seen one proof knows where to look in the next. Plain words throughout.

`<kind>` is `proposal`, `analysis`, or `note`. `<date>` is the day the document was first written, as `YYYY-MM-DD`, and a revision keeps the file's name.

## The three kinds

| Kind | What it is for | What the author does with it | Size |
|---|---|---|---|
| Proposal | A change that has not been made | Says yes, no, or what to change | under 2,000 words |
| Analysis | A question, answered from evidence | Decides what to do with the answer | under 2,500 words |
| Note | Something already known or decided, kept so that it is not lost | Checks that it is right | under 800 words |

The kind is the one the author names. When the author names none, take the first that fits, in this order: a request that ends in a change to make is a proposal, even when most of it is findings; one that ends in an answer is an analysis; one that only keeps what is known is a note.

A plan is none of the three. A plan is a staged plan: `/ck:plan` writes it, to the `plan-artifact` contract, and `docs/plan/` is its folder. A document with a contract of its own, a brief or a PRD for example, is written to that contract and never to this one.

## The top of the file

```
# <Kind>: <the subject, in a few words>

Date: <YYYY-MM-DD>. Status: draft, not approved.
```

`<Kind>` is `Proposal`, `Analysis`, or `Note`, as in the path. `Date:` is the date in the file's name. `Status:` is `draft, not approved` until the author approves the document; then it is `approved <YYYY-MM-DD>`, and no decision in it is still open. Nothing else stands above the first heading, so the one sentence stays at the top of the proof.

## What every kind opens and ends with

The same two sections open every document, and the same two end it.

**In one sentence** is exactly one sentence: the whole document, in words the author could say back to someone else. It has no list, no second sentence, and no heading under it.

**Decisions for you** holds the choices only the author can make. Its first line is `Open: D1, D3.`, naming the decisions still open, or `None open.` Once a document has asked for a decision it has this table, and a decided row stays in it:

```
| # | Decision | Choices | Decided |
|---|---|---|---|
| D1 | Where the yearly price is shown | On the plan page (recommended: the question is asked there); in the footer | open |
| D2 | The yearly discount | Two months free (recommended: buyers know the offer); 20 percent | Two months free, 2026-10-12 |
```

Choices puts the recommended one first, marked `recommended:` with its reason in a few words. Decided is `open`, or the choice and its day. The reasoning goes in the sections below, so that a row can be answered at a glance.

**Open questions** holds what nobody knows yet, as a list. Each ends with the assumption the document was written on, after the words `Assumed meanwhile:`. It says `None.` when there are none. A choice the author could make today is a decision, and goes at the top.

**What I read** lists what the document rests on: every file, by path; every page, by address and the day it was read; every command whose output a claim rests on; and anything the writer watched happen or was told, with the day. Its last item begins `Not checked:` and names what the document relies on that the writer did not read, run, or see.

A decision, a change, and a finding carry ids: `D1`, `C2`, `F3`. An id is never reused: what is added takes the next number.

## Proposal (`docs/proposal/<date>-<slug>.md`)

A change that has not been made, put to the author for a yes. It says what will be different and how anyone will know. Who does which part, in what order, and in which session is a staged plan's to say, and `/ck:plan` writes one.

### Section order

Use these headings verbatim, in this order.

1. `## In one sentence`: what would change, and for whom.
2. `## Decisions for you`: the choices that settle whether the change is made, and in what form.
3. `## Why`: what is wrong or missing today, who it costs, and how that is known. One short paragraph.
4. `## What changes`: a table, `| # | Change | Done when | Where |`, one row per change, `C1`, `C2`, and so on. Change is what will be different, in a plain phrase. Done when is something that can be checked. Where is every file the change touches, by path, or the place when it is not a file; the proposal touches nothing else. Where is last, because a path cannot wrap. A row is a change and not a job: it names no owner and no order of work.
5. `## Not doing`: what a reader could expect and will not get, each with the reason. At least one.
6. `## What could go wrong`: a list. Each risk gives the id of the change it comes from, when it comes from one, and what limits it, or says it is accepted.
7. `## How we will know it worked`: at most four results the author can see or run once the change is made. Results, not work done.
8. `## Open questions`: what is still unknown about the change.
9. `## What I read`.

## Analysis (`docs/analysis/<date>-<slug>.md`)

A question, answered from evidence. It asks for no change of its own: what to do about the answer is the author's decision, at the top.

### Section order

Use these headings verbatim, in this order.

1. `## In one sentence`: the answer.
2. `## Decisions for you`: what the answer asks the author to choose. `None open.` when it only informs.
3. `## The question`: what was asked, what was left out of it, and what would count as an answer.
4. `## Findings`: a list. Each finding is its id and one sentence, in bold, and then its evidence: `**F1. <the finding>.** Seen: <the evidence>`. The evidence begins with how the finding is known. `Seen:` the writer ran it or watched it happen. `Read:` a file, a page, or a person says so, and is named. `Inferred:` it follows from other findings or from what the writer already knew, and nobody checked it.
5. `## What it means`: the options the findings leave, what each costs, and the one the writer would take. It cites findings by id and claims nothing that no finding supports.
6. `## Open questions`: what the evidence could not settle.
7. `## What I read`.

## Note (`docs/note/<date>-<slug>.md`)

Something already known or decided, written down so that it is not lost: what happened, what was decided, or how a thing works. It argues for nothing.

### Section order

Use these headings verbatim, in this order.

1. `## In one sentence`: the one thing to remember.
2. `## Decisions for you`: `None open.` in most notes.
3. `## The note`: what a reader who was not there needs, in the order they need it. An event or a decision has its day and who said or decided it.
4. `## Open questions`: what the note leaves unsettled.
5. `## What I read`.

## On the proof

The page is made from the markdown alone.

- The `##` headings are the kind's and no others. Parts of a section go under `###` headings. Both make the page's list of contents, so no two headings are the same, and a `###` heading of 32 characters or fewer keeps to one line of it.
- A file is named by its path, in a code span. A link is for a web address; the page links nothing else.
- A diagram is a `mermaid` fence. The page shows no image and no HTML.

## Checklist

1. The file is at `docs/<kind>/<date>-<slug>.md`, and its top is as this contract writes it, with the same kind and date.
2. Every section of its kind is present, in order, with its heading verbatim, and there is no other `##` heading.
3. Each of the kind's own sections holds what its entry under Section order says.
4. In one sentence holds exactly one sentence.
5. Decisions for you begins with `Open:` and the ids still open, or with `None open.`, and its table agrees. Every row has its choices, the recommended one first. An approved document has none open.
6. Every open question has its `Assumed meanwhile:`, or the section says `None.`
7. What I read names every file by path and every page by address and day, and ends with `Not checked:`.
8. No id is used twice, and no two headings are the same.
9. Files are named in code spans, links hold web addresses, and there is no image and no HTML.
10. No key, token, or password: a setting is named, never its value.
11. No hours and no effort estimates.
12. Before `## What I read`, the document is under its kind's size, unless the author asked for more. Count it with `awk '/^## What I read$/{exit} {print}' "<file>" | wc -w`, never by impression.
13. Proposal: every change has a Done when that can be checked, and no row names an owner or an order of work.
14. Analysis: every finding says how it is known, with `Seen:`, `Read:`, or `Inferred:`.

## Writing

Plain technical English: name the actor, one instruction per sentence, no filler, no loss of precision. The writer is I and the author is you, as two of the headings say. No em-dashes in prose.
