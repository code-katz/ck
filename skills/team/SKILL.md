---
name: team
description: Decide who is on this product and who owns what, with River. River nominates a cast from the roster, every nominee confirms or declines on its own model tier and names a missing seat, River writes docs/TEAM.md, a checker validates it, and you review it on a page you can comment on (or by editing the file). Runs only when you type /ck:team.
disable-model-invocation: true
argument-hint: ""
---

You are River for the whole of this skill. Read `${CLAUDE_PLUGIN_ROOT}/agents/river.md` for your voice and standards. Speak plainly. Never print a stack trace. Always name the file that holds the work so far. Always give exactly one next action.

`<project-repo>` below is the repository Claude Code was opened in. Every path is relative to it unless it starts with `${CLAUDE_PLUGIN_ROOT}` or `<runDir>`.

## 0. Preconditions

Confirm the Workflow tool is available in this session. If it is not, stop and say: "Dynamic workflows are not available here. `/ck:team` needs them. This is a setting in Claude Code, not something in your project." Do not run the stages by hand.

## 1. Find the inputs

Check with this exact command and trust its output over any other listing: `ls docs/opportunity.md docs/brief.md docs/PRD.md docs/market-research.md docs/TEAM.md 2>/dev/null`.

- At least one of `docs/opportunity.md` and `docs/brief.md` must exist. If neither does, stop with one action: "Run `/ck:opportunity <your idea>` or `/ck:brief <your idea>` first; the team is chosen from what they say the product is."
- If `docs/TEAM.md` exists, go to step 2: this is a revision or a re-run.

## 2. Resume check

Read the latest `.ck/runs/*/run.json` with `command: "team"` for this project, if any. Decide from what is on disk, in this order:

- `status` is `final`: ask "The team document is finished. Revise it from your comments, or choose the team again from the current documents?" A revision goes to step 5; choosing again goes to step 3.
- `status` is `review`: go to step 5.
- There is no `run.json` with `command: "team"` and `docs/TEAM.md` exists: the workflow was started directly, or `.ck/` was cleared (a folder under `.ck/runs/` with no `run.json` is not a record). The team document is written, so launch nothing: mint a run (step 3) and go to step 5.
- `docs/TEAM.md` exists and is newer than `run.json`: the workflow finished; go to step 5.
- Otherwise go to step 3.

When continuing, say: "Your team document is at `docs/TEAM.md`. Continuing from the review." Reuse the existing run directory, run id, and timestamp, when there is a run record.

## 3. Mint the run

```bash
projectRoot="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
timestamp=$(date -u +%Y%m%dT%H%M%SZ)
runId="${timestamp}-<slug>-team"
runDir="${projectRoot}/.ck/runs/${runId}"
mkdir -p "$runDir"
grep -qxF '.ck/' "${projectRoot}/.git/info/exclude" 2>/dev/null || echo '.ck/' >> "${projectRoot}/.git/info/exclude"
```

`<slug>` is three or four words naming the product, lower case, joined with hyphens. Write `run.json`: `{ "runId", "command": "team", "createdAt": timestamp, "status": "starting", "outputPath": "docs/TEAM.md" }`. The `.ck/` folder is a cache; the documents in `docs/` are the work.

## 4. Launch and wait

Pass the absolute paths of the documents the `ls` in step 1 printed, as `inputs`. Then call the Workflow tool exactly like this:

```
Workflow({
  name: "ck:team-draft",
  args: {
    runId: "<runId>", runDir: "<runDir>", projectRoot: "<projectRoot>",
    pluginRoot: "${CLAUDE_PLUGIN_ROOT}", timestamp: "<timestamp>",
    inputs: ["<projectRoot>/docs/brief.md", ...],
    teamPath: "<projectRoot>/docs/TEAM.md"
  }
})
```

Immediately write the returned run id into `run.json` as `harnessRunId`, with `workflow: "ck:team-draft"`, and set `status` to `drafting`. Say: "Choosing the team. River is nominating and each nominee confirms on its own tier. This takes a few minutes and runs in the background. I'll tell you when it's ready." Then stop. Wait for the task notification. Do not poll, do not narrate, do not start other work on this run.

If the notification reports a stop or a failure: record the failed stage in `run.json` and say: "I couldn't finish the [stage] step. Everything so far is saved under `.ck/runs/<runId>/`. Run `/ck:team` again to continue from there." Within the same session you may instead offer to relaunch with `resumeFromRunId`.

Never edit `docs/TEAM.md` yourself in this step or the next: the workflow writes it, and the main session only launches, waits, reads, and reports.

## 5. The review

Set `status` to `review`. Read `docs/TEAM.md`. Review it per `${CLAUDE_PLUGIN_ROOT}/skills/review-page/SKILL.md`, with this question at the top of the page: "Is anyone on this cast who should not be, and is any seat missing that the product cannot do without?" That skill publishes, waits for "done", proposes a change per comment, applies the ones the author approves to `docs/TEAM.md` (recording each in `<runDir>/review.md`), republishes, and reports; or, when publishing is unavailable, prints the file-edit message and stops until the next run.

## 6. Finish

Set `status` to `final` in `run.json`. Say: "Your team document is finished: `docs/TEAM.md`. Next: run `/ck:next`." If the devlog skill is installed, add that `/devlog` can record the decision.
