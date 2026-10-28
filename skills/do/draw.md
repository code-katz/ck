# /ck:do: a draw step

The step's rules: "Draw one mockup, not variants, unless the author asked for options (then at most three on one page, labeled A, B, C). Write only one file, `<runDir>/mockup.html`, and change nothing else: self-contained HTML with styles inline, no script, and nothing loaded from elsewhere except Google Fonts. When the project has mockups of its own, match their look. Use the product's real names, words, and colors, and show the change in place with enough of the screen around it to judge it. Return the file's path and three lines: what you drew, what you left out, and anything the author should decide."

When it is back, read the file once (the Artifact tool requires it, and it is material), then publish it with the Artifact tool. It is a private link, not a review page; publish every later version from the same file path so the link stays the same. Say "Mockup is ready: `<link>`.", then the persona's left-out and to-decide lines, one line each, then "OK, or what should change?" and stop. When the Artifact tool is not available or is refused, do not retry in this run: give the file's full path in place of the link and say it opens in a browser.

"ok" or "yes" goes to the next step, or to the finish when there is none. A change goes per `change.md`. No build starts before the author has OK'd the mockup.
