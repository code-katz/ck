# Filing a run's faults

All of a run's drafts go on one review page and are filed on one word, `file`. Nothing goes to GitHub before it. The filing rules are `/ck:issue`'s: `<the plugin's root>/skills/issue/SKILL.md`, called the issue command below. Read it; follow its steps as they are, with only the changes this file names.

## 1. A regression first

For each App wrong row, run `<cards> match <row>`. It prints `#<N><TAB><title>`, one line per closed issue labelled `verified` whose `Test case:` line names that row, and nothing when there is none. When one is the same fault, the row re-opens it instead of a new issue: write `.ck/issues/reopen-<N>.md` with first line `Re-opens #<N> <title>`, then `---`, then what you saw, in the words of a re-open in `verify.md`. A different fault, or no line, goes on to step 2.

## 2. Draft each new fault

Rows that show one fault make one report. For each, follow the issue command's steps 1 to 6, the report being your log of those rows, with these changes:

- Step 1 runs once for the run, not once per draft.
- Step 3: a required field the log does not give is left `_No response_` and named in a line under the draft's title, not asked.
- Step 5: a closed match or a doubt is written as a line under the draft's title (`Closed #N <title> looks the same; join it?`), not asked.
- Step 6: the body starts with the `Test case:` line, by the issue command's rule.

Skip step 7. The drafts are in `.ck/issues/`.

## 3. One page

Join the drafts, the re-opens first, into `.ck/issues/CHECK-<n>.md`: a `## ` heading per draft with its title, then its lines up to `---` in a code block, then its body. Publish it by `<the plugin's root>/skills/review-page/SKILL.md`, section 1, titled `CHECK-<n> drafts`, with the question "Are these the issues to file?". Then say "Comment on the page and say done, or say `file` to file them all." and wait.

On `done`, follow the review page's section 2, making each approved change in the draft's own file, then rebuild and republish the joined page. A change that drops a draft deletes its file.

## 4. File

Only the bare word `file` files. For each new issue or join, the issue command's step 8 on its draft. For each re-open, `<cards> reopen <N> .ck/issues/reopen-<N>.md` (see `verify.md`), then delete the file. Then delete `.ck/issues/CHECK-<n>.md`. A failed call: say which draft and the line it printed, and go on with the rest.
