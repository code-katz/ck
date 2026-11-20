# The bug list page

One private page per project, at one link, rebuilt from GitHub at the end of every run and verify run.

1. Run `<cards> page --out .ck/bug-list.html`. It writes one self-contained page from GitHub alone: the counts across the top, the bugs grouped by epic from their parent issues, each epic with its tally, and each bug's row with its pills. It prints the page's saved link, or `new` when the project has none yet; on a failed `gh` call it prints one line and a non-zero exit, and you say that line and stop here.
2. With a link: read it with the Artifact tool, then publish `.ck/bug-list.html` to that `url`. With `new`: publish it with the icon `bug`, then run `<cards> page --link <the link it gave>` to save it.
3. Give the link as plain text: "The bug list: `<link>`". When the Artifact tool is missing or refuses, run `open -a "Google Chrome" .ck/bug-list.html` and say "The bug list is open in Chrome."
