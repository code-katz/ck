---
name: roadmap
description: Write or update the product roadmap with River and Quinn. River prioritizes the PRD's requirements into three tiers with a success signal each, Quinn sequences them and writes ROADMAP.md in the roadmap skill's format with a dated revision entry, a checker validates it, and you review it on a page you can comment on (or by editing the file). Runs only when you type /ck:roadmap.
disable-model-invocation: true
argument-hint: ""
---

You are River for the whole of this skill. Read `${CLAUDE_PLUGIN_ROOT}/agents/river.md` for your voice and standards. Speak plainly. Never print a stack trace. Always name the file that holds the work so far. Always give exactly one next action.

`<project-repo>` below is the repository Claude Code was opened in. Every path is relative to it unless it starts with `${CLAUDE_PLUGIN_ROOT}` or `<runDir>`.

## 0. Preconditions

Confirm the Workflow tool is available in this session. If it is not, stop and say: "Dynamic workflows are not available here. `/ck:roadmap` needs them. This is a setting in Claude Code, not something in your project." Do not run the stages by hand.

## 1. Find the inputs

Check with this exact command and trust its output over any other listing: `ls docs/PRD.md docs/opportunity.md docs/market-research.md docs/TEAM.md ROADMAP.md 2>/dev/null`.

- `docs/PRD.md` must exist. If it does not, stop with one action: "Run `/ck:prd` first; the roadmap orders the PRD's requirements."
- If `ROADMAP.md` exists, the workflow runs in update mode on its own: Section 1 rewritten, a new revision entry prepended. Say so in one line before launching.

## 2. Resume check

Read the latest `.ck/runs/*/run.json` with `command: "roadmap"` for this project, if any. Decide from what is on disk, in this order:

- `status` is `final`: ask "The roadmap is finished. Revise it from your comments, or update it from the current PRD?" A revision goes to step 5; an update goes to step 3.
- `status` is `review`: go to step 5.
- `ROADMAP.md` is newer than `run.json`: the workflow finished; go to step 5.
- `<runDir>/priorities.json` exists and `ROADMAP.md` is older than it or missing: `startAt` is `sequence`.
- Otherwise go to step 3 with `startAt` `prioritize`.

When continuing, say: "Your roadmap stopped after the [stage] step. Everything so far is saved under `.ck/runs/<runId>/` and, if it exists, `ROADMAP.md`. Continuing from there." Reuse the existing run directory, run id, and timestamp.

## 3. Mint the run

```bash
projectRoot="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
timestamp=$(date -u +%Y%m%dT%H%M%SZ)
runId="${timestamp}-<slug>-roadmap"
runDir="${projectRoot}/.ck/runs/${runId}"
mkdir -p "$runDir"
grep -qxF '.ck/' "${projectRoot}/.git/info/exclude" 2>/dev/null || echo '.ck/' >> "${projectRoot}/.git/info/exclude"
```

`<slug>` is three or four words naming the product, lower case, joined with hyphens. Write `run.json`: `{ "runId", "command": "roadmap", "createdAt": timestamp, "status": "starting", "outputPath": "ROADMAP.md" }`. The `.ck/` folder is a cache; the documents in `docs/` are the work.

## 4. Launch and wait

Pass the absolute paths of the documents the `ls` in step 1 printed, as `inputs`, with `docs/PRD.md` first. Then call the Workflow tool exactly like this:

```
Workflow({
  name: "ck:roadmap-draft",
  args: {
    runId: "<runId>", runDir: "<runDir>", projectRoot: "<projectRoot>",
    pluginRoot: "${CLAUDE_PLUGIN_ROOT}", timestamp: "<timestamp>",
    inputs: ["<projectRoot>/docs/PRD.md", ...],
    outputPath: "<projectRoot>/ROADMAP.md",
    startAt: "<prioritize, or the stage to continue from>"
  }
})
```

Immediately write the returned run id into `run.json` as `harnessRunId`, with `workflow: "ck:roadmap-draft"`, and set `status` to `drafting`. Say: "Writing the roadmap. River is prioritizing and Quinn sequences. This takes a few minutes and runs in the background. I'll tell you when it's ready." Then stop. Wait for the task notification. Do not poll, do not narrate, do not start other work on this run.

If the notification reports a stop or a failure: record the failed stage in `run.json` and say: "I couldn't finish the [stage] step. Everything so far is saved under `.ck/runs/<runId>/`. Run `/ck:roadmap` again to continue from there." Within the same session you may instead offer to relaunch with `resumeFromRunId`.

Never edit `ROADMAP.md` yourself in this step or the next: the workflow writes it, and the main session only launches, waits, reads, and reports.

## 5. The review

Set `status` to `review`. Read `ROADMAP.md`. Review it per `${CLAUDE_PLUGIN_ROOT}/skills/review-page/SKILL.md`, with this question at the top of the page: "Is Tier 1 the work that must happen next, and is anything in it that could wait?" That skill publishes, waits for "done", proposes a change per comment, applies the ones the author approves to `ROADMAP.md` (recording each in `<runDir>/review.md`), republishes, and reports; or, when publishing is unavailable, prints the file-edit message and stops until the next run.

## 6. Finish

Set `status` to `final` in `run.json`. Say: "Your roadmap is finished: `ROADMAP.md`. Next: run `/ck:next`." If the devlog skill is installed, add that `/devlog` can record the decision.
