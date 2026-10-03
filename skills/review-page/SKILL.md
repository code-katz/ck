---
name: review-page
description: How every ck gate publishes a document or gallery for review, waits for "done", proposes a change per comment, applies the ones the author approves, republishes, and reports. Read by the gate-owning skills; not run on its own.
user-invocable: false
---

# The review page

Every document or gallery that needs a decision is reviewed on a page in Claude's built-in review and comment system: a private page, published with the Artifact tool, that the reviewer switches to comment mode. `ck` builds nothing of its own for this. The session that wrote the document is the only session that changes it; the author's comments stay on the page, and this session reads them when the author says "done". When the Artifact tool is not available in the session, use the file-edit path at the end.

## 1. Publish

1. Build the page with one command, never by writing HTML yourself: `python3 "${CLAUDE_PLUGIN_ROOT}/scripts/render-review.py" --in <the document> --out <runDir>/review.html --title "<product>: <document>" --question "<the gate's question, if any>" --meta "<revision and date>"`. It renders the markdown with the banner below, a sticky table of contents so a comment can point at a section, tables and code that scroll inside their own container, and light and dark themes. For a gallery, the workflow has already written the page to the gallery contract; publish that file.
2. The banner carries, in this order: the product name and what is being reviewed; the round or revision; the one question the gate asks, when it has one (the PRD's premortem question, for example); and these four steps, verbatim (the renderer writes them; a gallery page must carry them too):
   1. Open this link signed in to your Claude account.
   2. Switch the page to comment mode from the bar at the top.
   3. Click the passage or the variant you want to comment on and type. Do not send the comment to Claude; this session reads it.
   4. Say "done" in your Claude Code session when you have finished.
3. Publish with the Artifact tool. The first publish of a page sets its favicon; every later publish of the same file path keeps the same URL. One page per review; never a new URL for a revision.
4. Tell the reviewer the link and one sentence: "Comment on the page, then say done here."
5. Stop and wait. Do not poll, do not narrate.

## 2. When the reviewer says "done"

Propose first, change nothing until the author agrees.

1. Read every comment thread on the page.
2. For each thread, in the order they appear in the document, write one line in chat: the passage it is on (a few words), what the comment says, and what you propose to change, in a sentence. When the comment is ambiguous, ask instead of proposing: name the two readings and ask which. When you would not change anything, say why. Number the lines.
3. Ask the author to answer by number: yes, no, or a correction. Wait.
4. Apply only the changes the author approved, to the file on disk (the document is the state), each as the smallest edit that does what was agreed. Record every thread in `<runDir>/review.md`: the comment, what was proposed, the author's answer, and what changed.
5. Republish the same page from the updated file, once.
6. Say in chat what changed, one line per approved thread, and that the author can resolve the threads on the page. This session cannot reply on or resolve a thread that was not sent to Claude, and the author should not send them: a comment sent to Claude wakes a cloud session, which cannot see the file on this machine. If one was sent anyway, say so and treat its thread like the others.
7. Continue to the skill's next step (finalize, or the next stage).

## 3. Galleries

A gallery review is the same loop. The reviewer's comments name a label (A, B, C) to pick and ask for changes; confirm the pick in the same numbered list, record it in `<runDir>/review.md` as `chosen: <label>` before continuing, and pass it to the next stage in `args`.

## 4. File-edit path (when the Artifact tool is unavailable)

Say: "Your <document> is at `<path>`. Open it, change anything you like, save, and run `<command>` again. I'll fold your edits in." Set `status: review` in `run.json` and stop. On the next run, the skill sees `review` and continues from the edited file. For a gallery, ask for the label in one question and continue.

## 5. Never

Never change the document before the author has approved the change. Never ask the reviewer to approve in a form. Never open a second page for a revision. Never delete a comment thread. Never restate these steps in another skill; reference this file.
