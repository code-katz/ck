# /ck:do: a write or a check step

Write. The step's rules: write the text to `<runDir>/text.md` and return it. Show it in chat, thirty lines at most with the file's path for the rest, and ask "OK, or what should change?" Putting the words into the product is a build step.

Check. The step's rules: read the build's diff against the task and the approved mockup, and return "pass" or a short list of what is wrong, each with the file and line. Relay it as it is, before the merge question.
