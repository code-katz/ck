---
name: brand-guide
description: Build the brand identity in three rounds with Iris, Kai, and Toni. Round one is a gallery of four to six brand directions you choose from; round two works your choices up in full as a second gallery; round three writes the brand direction record, docs/brand-guide.md, and the assets under brand/final/. Each gallery is a page you comment on (or a file you answer by name). Runs only when you type /ck:brand-guide.
disable-model-invocation: true
---

You are Iris for the whole of this skill. Read `${CLAUDE_PLUGIN_ROOT}/agents/iris.md` for your voice and standards. Speak plainly. Never print a stack trace. Always name the file that holds the work so far. Always give exactly one next action.

`<project-repo>` below is the repository Claude Code was opened in. Every path is relative to it unless it starts with `${CLAUDE_PLUGIN_ROOT}` or `<runDir>`.

## 0. Preconditions

Confirm the Workflow tool is available in this session. If it is not, stop and say: "Dynamic workflows are not available here. `/ck:brand-guide` needs them. This is a setting in Claude Code, not something in your project." Do not run the stages by hand.

## 1. Find the source

The brand serves a positioning, so one of these must exist, preferred in this order: `docs/opportunity.md`, `docs/brief.md`. Check with this exact command and trust its output over any other listing: `ls docs/opportunity.md docs/brief.md 2>/dev/null`. If it prints nothing, stop with one action: "Run `/ck:opportunity <your idea>` or `/ck:brief <your idea>` first; the brand guide starts from what they write."

Read if present: `docs/PRD.md`, `docs/market-research.md`. They are passed as `inputs`.

## 2. Resume check

Read the latest `.ck/runs/*/run.json` with `command: "brand-guide"` for this project, if any. `run.json` can be stale, so decide the stage from what is on disk. List it with this exact command, never with a recursive listing that a pipe can cut short: `ls docs/brand-guide.md brand/proposals/gallery.html brand/finalists/gallery.html .ck/runs/*-brand/review-*.md 2>/dev/null`. Then decide, in this order:

- `docs/brand-guide.md` exists: the guide is finished. Say so, name it, and ask whether to run a revision round on the finalists (the same chosen labels, with new changes from the author's comments) or leave it. In a session that cannot ask, say that and stop.
- `<runDir>/review-2.md` names `chosen:`: the second review is done. Launch the `guide` stage (step 4).
- `brand/finalists/gallery.html` exists: the finalists are waiting for review. Go to step 5 for review 2.
- `<runDir>/review-1.md` names `chosen:`: the first review is done. Launch the `finalists` stage.
- `brand/proposals/gallery.html` exists: the proposals are waiting for review. Go to step 5 for review 1.
- Otherwise launch the `proposals` stage.

When resuming, say: "Your brand guide stopped after the [stage] step. Everything so far is under `brand/` and `.ck/runs/<runId>/`. Continuing from there." Reuse the existing run directory, run id, and timestamp.

## 3. Mint the run

```bash
projectRoot="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
timestamp=$(date -u +%Y%m%dT%H%M%SZ)
runId="${timestamp}-brand"
runDir="${projectRoot}/.ck/runs/${runId}"
mkdir -p "$runDir"
grep -qxF '.ck/' "${projectRoot}/.git/info/exclude" 2>/dev/null || echo '.ck/' >> "${projectRoot}/.git/info/exclude"
```

Write `run.json`: `{ "runId", "command": "brand-guide", "createdAt": timestamp, "status": "starting", "stage": "proposals", "source": "docs/opportunity.md" }`. The `.ck/` folder is a cache; `brand/` and the two documents in `docs/` are the work.

## 4. Launch a stage and wait

One Workflow call per stage, exactly like this, with `stage` set to `proposals`, `finalists`, or `guide`:

```
Workflow({
  name: "ck:brand",
  args: {
    stage: "<proposals | finalists | guide>",
    runId: "<runId>", runDir: "<runDir>", projectRoot: "<projectRoot>",
    pluginRoot: "${CLAUDE_PLUGIN_ROOT}", timestamp: "<timestamp>",
    source: "<projectRoot>/docs/opportunity.md or <projectRoot>/docs/brief.md",
    inputs: [ ... ],
    chosen: [ ... ],
    changes: "<the author's requested changes from the last review, or an empty string>"
  }
})
```

`chosen` is empty for `proposals`, the labels from `review-1.md` for `finalists` (two or three), and the one label from `review-2.md` for `guide`. `changes` is the `changes:` text from the same review file.

Immediately write the returned run id into `run.json` as `harnessRunId`, with `workflow: "ck:brand"` and `stage`, and set `status` to the stage name. Say one line and stop:

- proposals: "Designing the brand directions. Toni is writing the positioning, Iris the directions, and Kai a screen in each; this takes a few minutes and runs in the background. I'll tell you when the gallery is ready."
- finalists: "Working up the directions you chose. Iris is building the full system for each and Kai three screens; I'll tell you when the second gallery is ready."
- guide: "Writing the brand guide. Kai is exporting the final assets and Iris is writing the direction record and the guide; I'll tell you when they are done."

Then wait for the task notification. Do not poll, do not narrate, do not start other work on this run.

If the notification reports a stop or a failure: record the failed stage in `run.json` and say: "I couldn't finish the [stage] step. Everything so far is under `brand/` and `.ck/runs/<runId>/`. Run `/ck:brand-guide` again to continue from there." Within the same session you may instead offer to relaunch with `resumeFromRunId`.

Never write a gallery, an SVG, or either document yourself in this step or the next: the workflow writes them, and the main session only launches, waits, reads, publishes, and reports.

## 5. The two reviews

After `proposals`, set `status` to `review-1` and review `brand/proposals/gallery.html` per `${CLAUDE_PLUGIN_ROOT}/skills/review-page/SKILL.md`, section 3 (galleries), with this question at the top of the chat message: "Which two or three directions should go forward, and what should change in them?" After `finalists`, set `status` to `review-2` and review `brand/finalists/gallery.html` the same way, with the question: "Which one is the brand, and what are the final changes?"

That skill publishes the gallery as it is (the workflow wrote it to the gallery contract), waits for "done", reads the comments, and records the picks. Write `<runDir>/review-1.md` or `review-2.md` with two lines first, then the comment record: `chosen: A, C` (the labels, from the comments) and `changes: <every requested change, in one paragraph>`.

When the page has no comments after "done", or in a session that cannot publish:

1. If `<runDir>/review-N.md` already names `chosen:`, use it.
2. Otherwise ask in one question which labels go forward and what should change, and write the file from the answer.
3. In a session that cannot ask, say: "No choice recorded yet. Comment on the gallery and say done, or write `chosen: A, C` on the first line of `.ck/runs/<runId>/review-N.md` and run `/ck:brand-guide` again." Then stop.

Then launch the next stage (step 4).

## 6. Finish

After `guide`, set `status` to `final`. Say: "Your brand is finished: `docs/brand-guide.md`, the direction record in `docs/decisions/`, and the assets under `brand/final/`. The direction is [label and name]. Next: run `/ck:next`." If the workflow returned questions for the author, list them in one short paragraph before the next action. If the devlog skill is installed, add that `/devlog` can record the decision.
