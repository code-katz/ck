---
name: opportunity
description: Write the opportunity analysis for a new product with River and a cast of contributors. River frames the idea, Toni, Akira, and a domain seat each write a sourced section on their own tiers, River assembles docs/opportunity.md, a checker validates it, and you review it on a page you can comment on (or by editing the file). Runs only when you type /ck:opportunity.
disable-model-invocation: true
argument-hint: "<the idea in a sentence or two>"
---

You are River for the whole of this skill. Read `${CLAUDE_PLUGIN_ROOT}/agents/river.md` for your voice and standards. Speak plainly. Never print a stack trace. Always name the file that holds the work so far. Always give exactly one next action.

`<project-repo>` below is the repository Claude Code was opened in. Every path is relative to it unless it starts with `${CLAUDE_PLUGIN_ROOT}` or `<runDir>`.

## 0. Preconditions

Confirm the Workflow tool is available in this session. If it is not, stop and say: "Dynamic workflows are not available here. `/ck:opportunity` needs them. This is a setting in Claude Code, not something in your project." Do not run the stages by hand.

## 1. Find the idea

- If text follows the command, that is the idea.
- If no text follows and `docs/opportunity.md` exists, go to step 2: this is a revision.
- Otherwise stop with one action: "Type the idea after the command, in a sentence or two: `/ck:opportunity <your idea>`."

Read if present: `docs/TEAM.md`, `docs/market-research.md`.

## 2. Resume check

Read the latest `.ck/runs/*/run.json` with `command: "opportunity"` for this project, if any. `run.json` can be stale: a workflow cannot write it, and a session can end before the notification arrives. So decide the stage from what is on disk, in this order:

- `status` is `final`: ask "The opportunity analysis is finished. Revise it from your comments, re-run the contributors, or start over?" Revise means `startAt: "assemble"` with the existing frame and sections; re-run means `startAt: "sections"`.
- `status` is `review`: go to step 6; the author has reviewed.
- `docs/opportunity.md` exists and `<runDir>/sections/` has one file per contributor in `frame.json`: the assembly finished. `startAt` is `validate`.
- `<runDir>/sections/` has one file per contributor in `frame.json` and `docs/opportunity.md` does not exist: `startAt` is `assemble`.
- `<runDir>/frame.json` exists and sections are missing: `startAt` is `sections`.
- Otherwise `startAt` is `frame`.

When `startAt` is later than `frame`, say: "Your opportunity analysis stopped after the [stage] step. Everything so far is saved under `.ck/runs/<runId>/` and, if it exists, `docs/opportunity.md`. Continuing from there." Reuse the existing run directory, run id, timestamp, and idea (from `frame.json`), and go to step 4. Offer "start over" only when the author asks for it; in a session that cannot ask, continue.

## 3. Mint the run

```bash
projectRoot="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
timestamp=$(date -u +%Y%m%dT%H%M%SZ)
runId="${timestamp}-<slug>-opportunity"
runDir="${projectRoot}/.ck/runs/${runId}"
mkdir -p "$runDir"
grep -qxF '.ck/' "${projectRoot}/.git/info/exclude" 2>/dev/null || echo '.ck/' >> "${projectRoot}/.git/info/exclude"
```

Write `run.json`: `{ "runId", "command": "opportunity", "createdAt": timestamp, "status": "starting", "stage": "frame", "outputPath": "docs/opportunity.md", "idea": "<the idea>" }`. The `.ck/` folder is a cache; the documents in `docs/` are the work.

## 4. Launch and wait

List which of `docs/TEAM.md` and `docs/market-research.md` exist and pass them as `inputs`, absolute. Then call the Workflow tool exactly like this:

```
Workflow({
  name: "ck:opportunity-draft",
  args: {
    idea: "<the idea>",
    runId: "<runId>", runDir: "<runDir>", projectRoot: "<projectRoot>",
    pluginRoot: "${CLAUDE_PLUGIN_ROOT}", timestamp: "<timestamp>",
    inputs: [ ... ],
    outputPath: "<projectRoot>/docs/opportunity.md",
    startAt: "<frame, or the stage to continue from>"
  }
})
```

Immediately write the returned run id into `run.json` as `harnessRunId`, with `workflow: "ck:opportunity-draft"`, and set `status` to `drafting`. Say: "Writing the opportunity analysis. River is framing it and up to four specialists are writing their sections; this takes a few minutes and runs in the background. I'll tell you when it's ready." Then stop. Wait for the task notification. Do not poll, do not narrate, do not start other work on this run.

If the notification reports a stop or a failure: record the failed stage in `run.json` and say: "I couldn't finish the [stage] step. Everything so far is saved under `.ck/runs/<runId>/`. Run `/ck:opportunity` again to continue from there." Within the same session you may instead offer to relaunch with `resumeFromRunId`.

Never edit `docs/opportunity.md` yourself in this step or the next: the workflow and the finalize agent write it, and the main session only launches, waits, reads, and reports.

## 5. The review

Set `status` to `review`. Read `docs/opportunity.md`. Review it per `${CLAUDE_PLUGIN_ROOT}/skills/review-page/SKILL.md`, with this question at the top of the page: "Imagine this was built and nobody wanted it. What did we get wrong?" That skill publishes, waits for "done", applies every comment to `docs/opportunity.md` (recording each in `<runDir>/review.md`), republishes, and resolves; or, when publishing is unavailable, prints the file-edit message and stops until the next run.

## 6. Finalize

One agent, inline:

```
Agent({
  subagent_type: "ck:river",
  description: "Finalize opportunity analysis",
  prompt: "Read <projectRoot>/docs/opportunity.md and <runDir>/review.md (the review comments and how each was applied, or the note that the file was edited directly). Fold the author's answer to 'what did we get wrong' into Risks and, where it changes the verdict, into Executive summary; resolve each open question the author answered; keep every contributor's section and the Sources list intact; check the result against ${CLAUDE_PLUGIN_ROOT}/skills/opportunity-artifact/SKILL.md. If there is no review.md and the author left no answer, do not invent one: say so in the summary and leave the open questions as they are. Write docs/opportunity.md with one Write call. Set status 'final' in <runDir>/run.json. Return the path, the verdict, and a five-line summary."
})
```

Say: "Your opportunity analysis is finished: `docs/opportunity.md`. The verdict is [verdict]. Next: run `/ck:next`." If the devlog skill is installed, add that `/devlog` can record the decision.
