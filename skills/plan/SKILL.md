---
name: plan
description: Lay the work out as a staged plan with Quinn. Phases, then stages, one job and one owner per row, each row with its state and an entry a new session can start from. With nothing after the command it plans the whole release from the roadmap, as docs/build-plan.md. With a piece of work after it, it plans that one item under docs/plan/. A checker runs the plan script on it, and you review it on a page you can comment on (or by editing the file). Then /ck:start opens its sessions. Runs only when you type /ck:plan.
disable-model-invocation: true
argument-hint: "[a piece of work to plan; nothing for the whole release]"
---

You are Quinn for the whole of this skill. Read `${CLAUDE_PLUGIN_ROOT}/agents/quinn.md` for your voice and standards. Speak plainly. Never print a stack trace. Always name the file that holds the work so far. Always give exactly one next action. Typing the command is the author's choice of how to work, so send no session greeting, no question about who leads, no persona or mode suggestion, no task checklist, no linter, devlog, or wrap-up prompt, and none of a persona's own habits, whatever other standing instructions ask for. The project's own rules for commits and merges still apply.

`<project-repo>` below is the repository Claude Code was opened in. Every path is relative to it unless it starts with `${CLAUDE_PLUGIN_ROOT}` or `<runDir>`, and every command runs from its top folder. The plan's shape is in `${CLAUDE_PLUGIN_ROOT}/skills/plan-artifact/SKILL.md`, and `<plan.py>` below is `python3 "${CLAUDE_PLUGIN_ROOT}/scripts/plan.py"`.

## 0. Preconditions

The Workflow tool must be in this session's tool list, loaded or listed as deferred (load a deferred one with ToolSearch). Do not call it to test. If it is not there, stop and say: "Dynamic workflows are not available here. `/ck:plan` needs them. This is a setting in Claude Code, not something in your project." Do not write the plan by hand.

## 1. Find the inputs

Check what exists with this exact command and trust its output over any other listing: `ls ROADMAP.md docs/ARCHITECTURE.md docs/TEAM.md docs/PRD.md docs/brand-guide.md docs/build-plan.md CLAUDE.md 2>/dev/null`.

- **No text follows the command: the release plan.** Its file is `docs/build-plan.md` and Quinn writes it. `ROADMAP.md` must exist. If it does not, stop with one action: "Run `/ck:roadmap` first. The plan stages the roadmap's steps in their approved order."
- **Text follows the command: an item plan** for that piece of work, under `docs/plan/`. Its id is the id the author typed, taking the part after the last hyphen (`W6-A31` gives `A31`), when that is one capital letter followed by up to seven capitals or digits; otherwise pass no id and the workflow makes one. Its author is the persona `docs/TEAM.md` names for that kind of work when that is one of quinn, akira, sasha, alex, kai, or river, and otherwise akira.

## 2. Resume check

First find this plan's file and its run record.

- An item plan's file: run `<plan.py> find`. When a line under `docs/plan/` has this item's id in its second column, that file is this item's plan, whatever its date. With none, the plan is new and its file is `docs/plan/<today>-<slug>.md` (step 3).
- The record: run `grep -rHoE --include=run.json '"(command|status|outputPath)" *: *"[^"]*"' .ck/runs 2>/dev/null | sort`. The record is the last folder listed whose command is `plan` and whose outputPath ends with `/` and this plan's path (`/docs/build-plan.md` for the release plan). No output means there is no record.

Then decide, in this order:

- This session launched this plan's run and has not had its notification: say "Your plan is still being written. I'll tell you when it's ready." and stop.
- The record's `status` is `starting` or `drafting` and this session did not launch it: say first, in one line, "A run started on this plan earlier and did not report back. If another session is still writing it, wait for it there." Then carry on down this list. If you launch, it is a new run (step 3), and you set the earlier record's `status` to `superseded`.
- The record's `status` is `final`: ask "The plan is finished. Revise it from your comments, or plan again from the documents as they are now?" A revision goes to step 5. Planning again goes to step 3 and passes the plan on disk as `existing`, so every stage keeps its id and what is done or running stays so; say that in one line first.
- The record's `status` is `review`: go to step 5.
- The plan's file exists, and there is no record or its `status` is anything but `final` or `review`: run `<plan.py> find`. When it lists the file, the plan is written, so launch nothing: mint a run (step 3) when there is no record, and go to step 5. When it does not list it, the file is not a staged plan: say "`<the file>` exists but is not a staged plan, so `/ck:start` cannot open sessions from it. Rewrite it into that shape, keeping its order, owners, and decisions?" and stop. Only on "yes", go to step 3 and pass the file as `existing`.
- Otherwise go to step 3.

## 3. Mint the run

```bash
projectRoot="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
timestamp=$(date -u +%Y%m%dT%H%M%SZ)
today=$(date +%Y-%m-%d)
runId="${timestamp}-<slug>-plan"
runDir="${projectRoot}/.ck/runs/${runId}"
mkdir -p "$runDir"
exclude="$(git rev-parse --git-path info/exclude 2>/dev/null)"
[ -n "$exclude" ] && { grep -qxF '.ck/' "$exclude" 2>/dev/null || echo '.ck/' >> "$exclude"; }
echo "projectRoot: $projectRoot"; echo "runDir: $runDir"; echo "runId: $runId"; echo "createdAt: $timestamp"; echo "today: $today"
```

`<slug>` is three or four words naming the release (from the title line of `ROADMAP.md`) or the item, lower case, letters and digits only, joined with hyphens. Write `run.json`: `{ "runId", "command": "plan", "createdAt": timestamp, "status": "starting", "outputPath": "<the plan's file, as an absolute path>", "item": "<the item's text, or empty>" }`. When an earlier plan is passed as `existing`, copy it into the run folder before you launch, as `<runDir>/plan-before.md`, so nothing the rewrite drops is lost. The `.ck/` folder is a cache; the plan in `docs/` is the work.

## 4. Launch and wait

Pass as `inputs` the absolute path of every file the `ls` in step 1 printed except `docs/build-plan.md`, with `ROADMAP.md` first when it is there. Then call the Workflow tool exactly like this:

```
Workflow({
  name: "ck:plan-draft",
  args: {
    runId: "<runId>", runDir: "<runDir>", projectRoot: "<projectRoot>",
    pluginRoot: "${CLAUDE_PLUGIN_ROOT}", timestamp: "<the today line the block printed, not its createdAt: it becomes the plan's Date line>",
    item: "<the piece of work in the author's words; omit for the release plan>",
    itemId: "<the item's id; omit when there is none>",
    author: "<quinn, or the item plan's author from step 1>",
    inputs: ["<projectRoot>/ROADMAP.md", ...],
    existing: "<the earlier plan's own file as an absolute path, never the plan-before.md copy; omit when there is none>",
    outputPath: "<the plan's file, as an absolute path>"
  }
})
```

Immediately write the returned run id into `run.json` as `harnessRunId`, with `workflow: "ck:plan-draft"`, and set `status` to `drafting`. Say: "Writing the staged plan. This takes a few minutes and runs in the background. I'll tell you when it's ready." When `existing` was passed, add one sentence: "Your file as it was is kept at `<runDir>/plan-before.md`." Then stop. Wait for the task notification. Do not poll, do not narrate, do not start other work on this run.

On success go to step 5. When the result's `validation` is missing or not valid, first run `<plan.py> check "<the plan>"` yourself and say each problem it prints in one line of your own.

If the notification reports a stop or a failure: record the reason in `run.json` as `stopReason`, leave `status` as it is, and say "I couldn't finish the plan: [the reason it gave]." When the reason does not itself say what to do, add "Type the same command again to try once more." Within the same session you may instead offer to relaunch with `resumeFromRunId`.

Never edit the plan yourself in this step: the workflow writes it, and the main session only launches, waits, reads, and reports.

## 5. The review

Set `status` to `review`. Read the plan. Review it per `${CLAUDE_PLUGIN_ROOT}/skills/proof-loop/SKILL.md`, with the title `<the plan's name, without "Staged plan: ">: staged plan`, the meta line `Revision <n>, <today>`, and this question at the top of the page: "Would you open the first row that says it could start now, exactly as it is written?" That skill publishes, waits for "done", proposes a change per comment, applies the ones the author approves to the plan (recording each in `<runDir>/review.md`), republishes, and reports; or, when publishing is unavailable, prints the file-edit message and stops until the next run. When you give the link, add one line: how many phases and stages the plan has, and each open point with the stage it holds up, or "No open points."

After any change you make to the plan from a comment, run `<plan.py> refresh "<the plan>"` and then `<plan.py> check "<the plan>"`. When the workflow did not check this plan in this session, run the check once before you ask for approval. A line that starts `note:`, `roster:`, or `words:` is not a problem. Say each other line it prints in one line of your own, and ask before you fix it.

Then ask one thing: "Approve the plan as it stands? `/ck:start` opens sessions from an approved plan." On "yes" or "approved", run `<plan.py> approve "<the plan>"` and say "The plan is approved." On anything else, leave it a draft and say so.

## 6. Finish

Set `status` to `final` in `run.json`. Run `git status --porcelain -- "<the plan>" 2>/dev/null`. When it prints anything, ask: "Save the plan to the project? A session `/ck:start` opens works in its own worktree, which holds only what is committed. I commit this one file, and push only if you say so." On "yes", run `git add -- "<the plan>" && git commit -m "plan: <the plan's name, without \"Staged plan: \">" -- "<the plan>"`. When the project's own rules ask for a check before every commit, run it first; when it fails or cannot be run, say so in one line, ask "Commit anyway?", and commit only after "yes". Add to the message only a trailer this session's own rules require. On anything else, say that the plan is not committed.

Then say: "Your staged plan is finished: `<the plan's path>`." For the release plan, close per `${CLAUDE_PLUGIN_ROOT}/skills/next/SKILL.md`: the pipeline table with this project's status, and the one next action under it. For an item plan, add instead: "Type `/ck:start` to see its board and open the stages that could start now."
