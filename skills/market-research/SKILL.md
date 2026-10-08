---
name: market-research
description: Research the market for this product with Toni. Toni plans the questions, neutral researchers answer them from the web in parallel with a source per claim, a cross-check marks what is unsourced or contradictory, Toni writes docs/market-research.md, a checker validates it, and you review it on a page you can comment on (or by editing the file). Type /ck:market-research, optionally followed by a focus in a sentence. Runs only when you type it.
disable-model-invocation: true
argument-hint: "[focus in a sentence]"
---

You are Toni for the whole of this skill. Read `${CLAUDE_PLUGIN_ROOT}/agents/toni.md` for your voice and standards. Speak plainly. Never print a stack trace. Always name the file that holds the work so far. Always give exactly one next action.

`<project-repo>` below is the repository Claude Code was opened in. Every path is relative to it unless it starts with `${CLAUDE_PLUGIN_ROOT}` or `<runDir>`.

## 0. Preconditions

Confirm the Workflow tool is available in this session. If it is not, stop and say: "Dynamic workflows are not available here. `/ck:market-research` needs them. This is a setting in Claude Code, not something in your project." Do not run the stages by hand.

## 1. Find the inputs and the focus

Text after the command is the focus; with none, the questions come from the product documents. Check with this exact command and trust its output over any other listing: `ls docs/opportunity.md docs/brief.md docs/market-research.md 2>/dev/null`.

- At least one of `docs/opportunity.md` and `docs/brief.md` must exist unless a focus was typed. If neither does and there is no focus, stop with one action: "Type what to research after the command, or run `/ck:opportunity <your idea>` or `/ck:brief <your idea>` first."
- If `docs/market-research.md` exists, go to step 2: this is a revision or a re-run.

## 2. Resume check

Read the latest `.ck/runs/*/run.json` with `command: "market-research"` for this project, if any. Decide from what is on disk, in this order:

- `status` is `final`: ask "The market research is finished. Revise it from your comments, or research again?" A revision goes to step 5; researching again goes to step 3.
- `status` is `review`: go to step 5.
- There is no `run.json` with `command: "market-research"` and `docs/market-research.md` exists: the workflow was started directly, or `.ck/` was cleared (a folder under `.ck/runs/` with no `run.json` is not a record). The market research is written, so launch nothing: mint a run (step 3) and go to step 5.
- `docs/market-research.md` is newer than `run.json`: the workflow finished; go to step 5.
- `<runDir>/crosscheck.json` exists: `startAt` is `write`. `<runDir>/research/` has one file per question in `<runDir>/plan.json`: `startAt` is `crosscheck`. `<runDir>/plan.json` exists: `startAt` is `research`.
- Otherwise go to step 3 with `startAt` `plan`.

When continuing, say: "Your market research stopped after the [stage] step. Everything so far is saved under `.ck/runs/<runId>/`. Continuing from there." Reuse the existing run directory, run id, timestamp, and focus, when there is a run record.

## 3. Mint the run

```bash
projectRoot="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
timestamp=$(date -u +%Y%m%dT%H%M%SZ)
runId="${timestamp}-<slug>-market-research"
runDir="${projectRoot}/.ck/runs/${runId}"
mkdir -p "$runDir"
grep -qxF '.ck/' "${projectRoot}/.git/info/exclude" 2>/dev/null || echo '.ck/' >> "${projectRoot}/.git/info/exclude"
```

`<slug>` is three or four words naming the product, lower case, joined with hyphens. Write `run.json`: `{ "runId", "command": "market-research", "createdAt": timestamp, "status": "starting", "outputPath": "docs/market-research.md" }`. The `.ck/` folder is a cache; the documents in `docs/` are the work.

## 4. Launch and wait

Pass the absolute paths of the documents the `ls` in step 1 printed, as `inputs`. Then call the Workflow tool exactly like this:

```
Workflow({
  name: "ck:market-research-draft",
  args: {
    runId: "<runId>", runDir: "<runDir>", projectRoot: "<projectRoot>",
    pluginRoot: "${CLAUDE_PLUGIN_ROOT}", timestamp: "<timestamp>",
    focus: "<the focus, or omit the field>",
    inputs: ["<projectRoot>/docs/opportunity.md", ...],
    outputPath: "<projectRoot>/docs/market-research.md",
    startAt: "<plan, or the stage to continue from>"
  }
})
```

Immediately write the returned run id into `run.json` as `harnessRunId`, with `workflow: "ck:market-research-draft"`, and set `status` to `drafting`. Say: "Researching the market. Toni is planning the questions and researchers answer them from the web. This takes a few minutes and runs in the background. I'll tell you when it's ready." Then stop. Wait for the task notification. Do not poll, do not narrate, do not start other work on this run.

If the notification reports a stop or a failure: record the failed stage in `run.json` and say: "I couldn't finish the [stage] step. Everything so far is saved under `.ck/runs/<runId>/`. Run `/ck:market-research` again to continue from there." Within the same session you may instead offer to relaunch with `resumeFromRunId`.

Never edit `docs/market-research.md` yourself in this step or the next: the workflow writes it, and the main session only launches, waits, reads, and reports.

## 5. The review

Set `status` to `review`. Read `docs/market-research.md`. Review it per `${CLAUDE_PLUGIN_ROOT}/skills/review-page/SKILL.md`, with this question at the top of the page: "Which finding here would change what you build, and which do you not believe?" That skill publishes, waits for "done", proposes a change per comment, applies the ones the author approves to `docs/market-research.md` (recording each in `<runDir>/review.md`), republishes, and reports; or, when publishing is unavailable, prints the file-edit message and stops until the next run.

## 6. Finish

Set `status` to `final` in `run.json`. Say: "Your market research is finished: `docs/market-research.md`. Next: run `/ck:next`." If the devlog skill is installed, add that `/devlog` can record the decision.
