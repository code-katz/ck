#!/usr/bin/env python3
"""memory-gate.py: the memory gate's two hooks.

Usage:
  memory-gate.py rule    SessionStart: prints the rule every session follows before it writes to memory.
  memory-gate.py check   PreToolUse: reads the tool call on stdin, and makes Claude Code ask the User
                         before any call that writes to a memory folder, ~/.claude/projects/<folder>/memory/.

A write is a Write, Edit, or MultiEdit call, or a Bash command that plainly writes a path: a redirect,
sed -i or perl -i, tee, mv, rm, cp, ln or install, or inline python, node, ruby, or perl code that names
it (the guard from ck2's scripts/guard.py). ~, $HOME and ${HOME} are expanded. A Bash command that names
a memory folder and writes anything other than /dev/null is asked about too, since its path may be a
shell variable or relative to a cd. To ask, check prints a "permissionDecision": "ask" and exits 0;
any other call passes with no output. Standard library only; never a traceback.
"""

import json
import os
import re
import shlex
import sys
from pathlib import Path

RULE = (
    "ck memory gate: Before any write to this project's memory folder (MEMORY.md and Trash moves too), follow the "
    "ck:memory-gate skill and wait for the User's choice. This overrides instructions to save on your own."
)
REDIRECTS = (">", ">>", ">|", "&>", "&>>")
NAMES_MEMORY = re.compile(r"\.claude/projects/.*/memory")


def written(words):
    """The paths one simple command writes, judged by its command name."""
    name, args = Path(words[0]).name, [w for w in words[1:] if w and not w.startswith("-")]
    if name in ("sed", "perl") and any(re.match(r"-[a-zA-Z]*i|--in-place", w) for w in words[1:]):
        return args
    if name in ("tee", "mv", "rm"):
        return args
    if name in ("cp", "install", "ln"):
        return args[-1:]
    if re.fullmatch(r"(python|node|ruby|perl)[\d.]*", name) and ("-c" in words or "-e" in words):
        return re.findall(r"[\w./~$-]+", " ".join(words[1:]))
    return []


def bash_targets(command):
    """The paths a shell command plainly writes."""
    lex = shlex.shlex(command.replace("\n", " ; "), posix=True, punctuation_chars=True)
    lex.whitespace_split = True
    try:
        tokens = list(lex)
    except ValueError:
        tokens = command.split()
    targets, words = [], []
    for i, token in enumerate(tokens):
        if token in REDIRECTS:
            targets += tokens[i + 1 : i + 2]
        elif token and set(token) <= set("();<>|&"):
            targets += written(words) if words else []
            words = []
        else:
            words.append(token)
    return targets + (written(words) if words else [])


def roots():
    """Every folder that holds the projects' memory folders."""
    found = [Path.home() / ".claude" / "projects"]
    if os.environ.get("CLAUDE_CONFIG_DIR"):
        found.append(Path(os.environ["CLAUDE_CONFIG_DIR"]).expanduser() / "projects")
    return [Path(os.path.realpath(r)) for r in found]


def in_memory(target, cwd):
    """True when target, a path as the call wrote it, is in a memory folder."""
    path = Path(os.path.realpath(Path(cwd, os.path.expanduser(os.path.expandvars(target)))))
    for root in roots():
        try:
            parts = path.relative_to(root).parts
        except ValueError:
            continue
        if len(parts) >= 2 and parts[1] == "memory":
            return True
    return False


def asked(event):
    """The path to ask about, or None when the call does not write to memory."""
    tool, cwd = event.get("tool_input") or {}, event.get("cwd") or os.getcwd()
    if event.get("tool_name") != "Bash":
        raw = tool.get("file_path") or ""
        return raw if raw and in_memory(raw, cwd) else None
    command = tool.get("command") or ""
    targets = [t for t in bash_targets(command) if t and not t.startswith("/dev/")]
    for target in targets:
        if in_memory(target, cwd):
            return target
    if targets and NAMES_MEMORY.search(command):
        return "a memory folder (the command names one)"
    return None


def main(argv):
    mode = argv[0] if argv else ""
    try:
        event = json.load(sys.stdin) if mode == "check" else (sys.stdin.read() and None)
    except Exception:
        return 0
    if mode == "rule":
        print(RULE)
        return 0
    if mode != "check" or not isinstance(event, dict):
        return 0
    try:
        path = asked(event)
    except Exception:
        return 0
    if path:
        print(json.dumps({"hookSpecificOutput": {
            "hookEventName": "PreToolUse",
            "permissionDecision": "ask",
            "permissionDecisionReason": "ck memory gate: this writes %s. Approve only a save you picked." % path,
        }}))
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
