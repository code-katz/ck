#!/usr/bin/env python3
"""cost.py: what one Claude Code session cost, in tokens and dollars, by lane and by kind of token.

Usage:
  cost.py [SESSION ID | TRANSCRIPT]    the session's cost summary as a Markdown table; the default is the
                                       newest session of the repository in the current folder (or a worktree)
  cost.py history                      one row per merged pull request, from ~/.claude/ck-cost.jsonl
  cost.py stop                         Stop hook: once the session has a pull request, one cost line
  cost.py merge                        PostToolUse hook: after gh pr merge, posts the table to the pull
                                       request and adds a line to ~/.claude/ck-cost.jsonl

Lanes are the main session, each subagent by its type (ck:<name> for a persona), and background: what
Claude Code's own record (the transcript's last cost-state) counts beyond the transcripts. Prices come
from Anthropic's pricing page, fetched at most once a day into ~/.cache/ck/pricing.md (CK_PRICING_FILE
names a copy to use instead). A model the page does not list, or a fast-mode request, is priced as ?,
never $0. Standard library only; prints no message text; never a traceback.
"""

import json
import os
import re
import subprocess
import sys
import time
import urllib.request
from collections import defaultdict
from pathlib import Path

PRICING_URL = "https://platform.claude.com/docs/en/about-claude/pricing.md"
CACHE = Path.home() / ".cache/ck/pricing.md"
LOG = Path.home() / ".claude/ck-cost.jsonl"
PROJECTS = Path.home() / ".claude/projects"
KINDS = ("input", "output", "write", "read")
FIELDS = ("inputTokens", "outputTokens", "cacheCreationInputTokens", "cacheReadInputTokens")
HEAD = "| Input | Output | Cache write | Cache read | Total |"


def parse(text):
    """{model id: (input, 5m write, 1h write, cache read, output) in dollars per token} from the page's table."""
    prices, cols = {}, None
    for line in text.splitlines():
        cells = [c.strip() for c in line.strip().strip("|").split("|")]
        if "1h cache writes" in line:
            want = ("Base input", "5m cache", "1h cache", "Cache hits", "Output")
            cols = [next(i for i, c in enumerate(cells) if c.startswith(w)) for w in want]
        elif cols and not line.startswith("|") and prices:
            break
        elif cols and cells[0].startswith("Claude"):
            long = "over 100,000" in cells[0]
            name = re.sub(r"\(.*", "", cells[0]).strip().lower()
            try:
                prices[re.sub(r"[ .]", "-", name) + (">100k" if long else "")] = tuple(
                    float(re.search(r"\$([\d.]+)", cells[i]).group(1)) / 1e6 for i in cols)
            except (AttributeError, IndexError, ValueError):
                pass
    return prices


def pricing():
    """The prices, and a line saying where they came from."""
    path = Path(os.environ.get("CK_PRICING_FILE") or CACHE)
    if "CK_PRICING_FILE" not in os.environ and (not path.exists() or time.time() - path.stat().st_mtime > 86400):
        try:
            request = urllib.request.Request(PRICING_URL, headers={"User-Agent": "ck-cost"})
            text = urllib.request.urlopen(request, timeout=10).read().decode()
            if parse(text):
                path.parent.mkdir(parents=True, exist_ok=True)
                path.write_text(text)
        except Exception:
            pass
    try:
        prices = parse(path.read_text())
        day = time.strftime("%Y-%m-%d", time.localtime(path.stat().st_mtime))
    except OSError:
        prices = {}
    if not prices:
        return {}, "No prices: the pricing page could not be read and there is no saved copy, so every $ is ?."
    return prices, f"Prices from {PRICING_URL}, as of {day}."


def priced(prices, model, t, per_request=True):
    """Dollars per kind for one set of tokens, or None when it cannot be priced."""
    m = re.sub(r"-\d{8}$", "", re.sub(r"\[.*\]$", "", model or ""))
    prompt = t["input"] + t["w5"] + t["w1"] + t["read"]
    p = prices.get(m + ">100k") if per_request and prompt > 100000 else None
    p = p or prices.get(m)
    if not p or t.get("fast"):
        return None
    base, c5, c1, hit, out = p
    return {"input": t["input"] * base, "output": t["output"] * out, "write": t["w5"] * c5 + t["w1"] * c1,
            "read": t["read"] * hit}


def tokens(u):
    w = u.get("cache_creation") if isinstance(u.get("cache_creation"), dict) else None
    return {"input": u.get("input_tokens") or 0, "output": u.get("output_tokens") or 0,
            "w5": (w.get("ephemeral_5m_input_tokens") or 0) if w else (u.get("cache_creation_input_tokens") or 0),
            "w1": (w.get("ephemeral_1h_input_tokens") or 0) if w else 0,
            "read": u.get("cache_read_input_tokens") or 0, "fast": u.get("speed") == "fast"}


def add(row, t, dollars):
    for k in KINDS:
        row[k][0] += t["w5"] + t["w1"] if k == "write" else t[k]
        row[k][1] = None if dollars is None or row[k][1] is None else row[k][1] + dollars[k]


def read(transcript, prices):
    """{(lane, model): {kind: [tokens, dollars or None]}}, the title, Claude Code's record, the pull request link."""
    rows = defaultdict(lambda: {k: [0, 0.0] for k in KINDS})
    names, state, pr, seen = {}, None, None, set()
    base = Path(transcript)
    files = [(base, "main")]
    for f in sorted(base.with_suffix("").glob("subagents/**/*.jsonl")):
        try:
            lane = json.loads(f.with_suffix(".meta.json").read_text()).get("agentType") or "subagent"
        except (OSError, ValueError):
            lane = "subagent"
        files.append((f, lane))
    for path, lane in files:
        last = {}
        for line in open(path, errors="replace"):
            try:
                d = json.loads(line)
            except ValueError:
                continue
            kind = d.get("type")
            if kind == "assistant" and isinstance(d.get("message"), dict):
                last[d["message"].get("id") or id(d)] = d["message"]
            elif lane == "main" and kind in ("custom-title", "ai-title"):
                names[kind] = d.get("customTitle") or d.get("aiTitle") or names.get(kind)
            elif lane == "main" and kind == "cost-state":
                state = d
            elif lane == "main" and kind == "pr-link":
                pr = d
        for key, m in last.items():
            if key in seen or not isinstance(m.get("usage"), dict) or m.get("model") == "<synthetic>":
                continue
            seen.add(key)
            t = tokens(m["usage"])
            add(rows[(lane, m.get("model"))], t, priced(prices, m.get("model"), t))
    for model, v in ((state or {}).get("modelUsage") or {}).items():
        mine = combine(r for (_, mo), r in list(rows.items()) if mo == model)
        extra = {k: max(0, (v.get(f) or 0) - mine[k][0]) for k, f in zip(KINDS, FIELDS)}
        if any(extra.values()):
            t = {"input": extra["input"], "output": extra["output"], "w5": extra["write"], "w1": 0, "read": extra["read"]}
            d = priced(prices, model, t, per_request=False)
            if d is not None:
                # The record does not split cache writes by duration: they take what is left of Claude Code's
                # figure, between the 5-minute and the 1-hour price.
                hi = priced(prices, model, dict(t, w5=0, w1=extra["write"]), per_request=False)["write"]
                rest = (v.get("costUSD") or 0) - (total(mine)[1] or 0) - d["input"] - d["output"] - d["read"]
                d["write"] = min(max(rest, d["write"]), hi)
            add(rows[("background", model)], t, d)
    title = names.get("custom-title") or names.get("ai-title") or "Session " + base.stem[:8]
    return rows, title, state, pr


def combine(rows):
    whole = {k: [0, 0.0] for k in KINDS}
    for r in rows:
        for k in KINDS:
            whole[k][0] += r[k][0]
            whole[k][1] = None if r[k][1] is None or whole[k][1] is None else whole[k][1] + r[k][1]
    return whole


def total(row):
    dollars = [row[k][1] for k in KINDS]
    return sum(row[k][0] for k in KINDS), None if None in dollars else sum(dollars)


def disagree(prices, state):
    """Models whose Claude Code figure is outside what ck's prices allow for Claude Code's own token counts."""
    out = []
    for model, v in ((state or {}).get("modelUsage") or {}).items():
        t = dict(zip(("input", "output", "w5", "read"), (v.get(f) or 0 for f in FIELDS)), w1=0)
        lo, hi = priced(prices, model, t, False), priced(prices, model, dict(t, w5=0, w1=t["w5"]))
        if lo and hi and not v.get("webSearchRequests") and not (
                0.98 * sum(lo.values()) <= (v.get("costUSD") or 0) <= 1.02 * sum(hi.values())):
            out.append(short(model))
    return out


def num(n):
    return f"{n / 1e6:.1f}M" if n >= 1e6 else f"{n / 1e3:.1f}k" if 1e3 <= n < 1e4 else f"{n / 1e3:.0f}k" if n >= 1e4 else str(n)


def cell(n, dollars):
    return f"{num(n)} · " + ("?" if dollars is None else f"${dollars:.2f}")


def short(model):
    return (model or "?").removeprefix("claude-")


def table(session, prices, source):
    rows, title, state, _ = session
    out = [f"**{title} cost summary**", "", "| Lane | Model " + HEAD, "|---|---|--:|--:|--:|--:|--:|"]
    for lane, model in sorted(rows, key=lambda r: (r[0] != "main", r[0] == "background", r[0], r[1] or "")):
        r = rows[(lane, model)]
        out.append(f"| {lane} | {short(model)} | " + " | ".join(cell(*r[k]) for k in KINDS) + f" | **{cell(*total(r))}** |")
    whole = combine(rows.values())
    out.append("| **All** | | " + " | ".join(cell(*whole[k]) for k in KINDS) + f" | **{cell(*total(whole))}** |")
    out += ["", source]
    if any(lane == "background" for lane, _ in rows):
        out.append("Background is what Claude Code billed beyond the transcripts: its own calls.")
    mine, theirs = total(whole)[1], (state or {}).get("totalCostUSD")
    if theirs is None:
        out.append("Claude Code wrote no cost record for this session, so background calls are not counted.")
    else:
        out.append(f"Claude Code's own figure: ${theirs:.2f}.")
        if mine is not None and mine > 1.03 * theirs:
            out.append("Claude Code's record was written before the session's last turns, so its figure is lower.")
    if disagree(prices, state):
        out.append(f"The pricing page and Claude Code's own figure disagree for {', '.join(disagree(prices, state))}: one of them has an old price.")
    return "\n".join(out)


def newest(cwd):
    """The most recent transcript of the repository in cwd, its worktrees included."""
    git = subprocess.run(["git", "rev-parse", "--path-format=absolute", "--git-common-dir"], cwd=cwd,
                         capture_output=True, text=True, timeout=10).stdout.strip()
    mangled = re.sub(r"[^A-Za-z0-9]", "-", str(Path(git).parent) if git else cwd)
    files = list(PROJECTS.glob(f"{mangled}/*.jsonl")) + list(PROJECTS.glob(f"{mangled}--claude-worktrees-*/*.jsonl"))
    return max(files, key=os.path.getmtime, default=None)


def stop(hook, prices, source):
    rows, _, _, pr = read(hook["transcript_path"], prices)
    if not pr:
        return
    models = {m: total(combine(r for (_, mo), r in rows.items() if mo == m)) for _, m in rows}
    parts = ", ".join(f"{short(m)} {cell(*v)}" for m, v in sorted(models.items(), key=lambda i: -(i[1][1] or 0)))
    print(json.dumps({"systemMessage": f"ck cost so far: {cell(*total(combine(rows.values())))} ({parts})"}))


def merge(hook, prices, source):
    command = (hook.get("tool_input") or {}).get("command") or ""
    number = re.search(r"\bgh\s+pr\s+merge\s+(?:-\S+\s+)*#?(\d+)", command)

    def gh(*args):
        return subprocess.run(["gh", *args], cwd=hook.get("cwd"), capture_output=True, text=True, timeout=20).stdout

    info = json.loads(gh("pr", "view", *([number.group(1)] if number else []), "--json", "number,state,mergeCommit,url"))
    if info.get("state") != "MERGED" or (LOG.exists() and f'"{info["url"]}"' in LOG.read_text()):
        return
    session = read(hook["transcript_path"], prices)
    gh("pr", "comment", str(info["number"]), "--body", table(session, prices, source))
    n, d = total(combine(session[0].values()))
    LOG.parent.mkdir(parents=True, exist_ok=True)
    with open(LOG, "a") as f:
        f.write(json.dumps({"date": time.strftime("%Y-%m-%d"), "url": info["url"], "commit": (info.get("mergeCommit") or {}).get("oid"),
                            "session": Path(hook["transcript_path"]).stem, "title": session[1], "tokens": n, "dollars": d}) + "\n")


def history():
    out = ["**Merged pull requests**", "", "| Date | Pull request | Commit | Session | Tokens | $ |", "|---|---|---|---|--:|--:|"]
    for line in LOG.read_text().splitlines() if LOG.exists() else []:
        try:
            e = json.loads(line)
            pr = re.sub(r"https://github.com/(.+)/pull/(\d+)", r"\1#\2", e["url"])
            out.append(f"| {e['date']} | [{pr}]({e['url']}) | {(e.get('commit') or '')[:7]} | {e['title']} | {num(e['tokens'])} | "
                       + ("?" if e.get("dollars") is None else f"${e['dollars']:.2f}") + " |")
        except (ValueError, KeyError, TypeError):
            continue
    return "\n".join(out) if len(out) > 4 else "No merged pull requests are logged yet in " + str(LOG) + "."


def main():
    args = sys.argv[1:]
    if args[:1] in (["stop"], ["merge"]):
        hook = json.load(sys.stdin)
        if args[0] == "stop":
            stop(hook, *pricing())
        elif re.search(r"\bgh\s+pr\s+merge\b", (hook.get("tool_input") or {}).get("command") or ""):
            merge(hook, *pricing())
        return 0
    if args in (["history"], ["--history"]):
        print(history())
        return 0
    if args[:1] == ["--session"]:
        args = args[1:]
    if len(args) > 1 or args[:1] and args[0].startswith("-"):
        print("usage: cost.py [SESSION ID | TRANSCRIPT] | history | stop | merge", file=sys.stderr)
        return 2
    if not args:
        path = newest(os.getcwd())
    elif Path(args[0]).is_file():
        path = args[0]
    else:
        path = max(PROJECTS.glob(f"*/{args[0]}*.jsonl"), key=os.path.getmtime, default=None)
    if not path:
        print("No session transcript found under ~/.claude/projects" + (f" for {args[0]}." if args else " for this project."))
        return 1
    prices, source = pricing()
    print(table(read(path, prices), prices, source))
    return 0


if __name__ == "__main__":
    try:
        sys.exit(main())
    except Exception as e:
        if sys.argv[1:2] in (["stop"], ["merge"]):
            sys.exit(0)
        print(f"cost.py: {e}", file=sys.stderr)
        sys.exit(1)
