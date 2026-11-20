#!/usr/bin/env python3
"""cards.py: the GitHub side of /ck:cards, Robin's journey-card loop.

Usage, from the repository's top folder:
  cards.py list                  closed bugs with a Test case: line and no `verified` label, then a line per card;
                                 changes nothing on GitHub
  cards.py verified N COMMIT ROWS   adds `verified`, removes `to verify`, comments the rows that passed
  cards.py reopen N FILE         re-opens N, removes both labels, comments the file's text
  cards.py match ROW             closed `verified` bugs whose Test case: line names ROW
  cards.py merged PR             after a merge: `to verify` on each issue PR closed that has a Test case: line
  cards.py page --out FILE       writes the project's bug list page from GitHub; prints its saved link, or `new`
  cards.py page --link URL       saves the page's link, kept beside the repository's .git for every worktree

The page shows every open issue, the closed ones of each open epic, and closed ones labelled `to verify`
or closed in the last 14 days. Elsewhere, from an issue it reads only its Test case: line (bold or not), its state and its labels (and prints its title).
A row is NN-Xn, as 09-D4. Every value goes to gh as an argument. Standard library only; a failed gh call prints
one line and exits 1, never a traceback.
"""

import datetime
import html
import json
import os
import re
import subprocess
import sys

TO_VERIFY, VERIFIED = "to verify", "verified"
LINE = re.compile(r"^\s*(?:\*\*)?Test case:(?:\*\*)?(.*)$", re.M)
ROW = re.compile(r"\b(\d\d)-([A-Z])(\d+)\b")


class Failed(Exception):
    pass


def gh(*args):
    r = subprocess.run(["gh", *args], capture_output=True, text=True, timeout=20)
    if r.returncode:
        why = (r.stderr.strip().splitlines() or ["no message"])[-1]
        raise Failed(f"gh {' '.join(args[:2])} failed: {why}")
    return r.stdout


def rows(body):
    """The rows the issue's first Test case: line names, in order, once each; None when it has no such line."""
    m = LINE.search(body or "")
    if not m:
        return None
    text = re.sub(r"\]\([^)]*\)", "]", m.group(1))  # a link's address is not a row
    return list(dict.fromkeys(m.group(0) for m in ROW.finditer(text)))


def key(row):
    nn, letter, n = ROW.fullmatch(row).groups()
    return nn, letter, int(n)


def closed(*search):
    return json.loads(gh("issue", "list", "--state", "closed", "--limit", "1000",
                         "--search", " ".join(('in:body "Test case"',) + search),
                         "--json", "number,title,body,labels"))


def labels(issue):
    return {label["name"] for label in issue.get("labels") or []}


def list_():
    bugs = [(i["number"], rows(i["body"]), i["title"]) for i in closed("-label:verified")
            if VERIFIED not in labels(i)]
    bugs = sorted((b for b in bugs if b[1]), key=lambda b: b[0])
    if not bugs:
        print("none")
        return
    cards = {}
    for n, rs, title in bugs:
        print(f"bug\t#{n}\t{','.join(rs)}\t{title}")
        for r in rs:
            last, nums = cards.setdefault(r[:2], [r, []])
            cards[r[:2]][0] = max(last, r, key=key)
            if f"#{n}" not in nums:
                nums.append(f"#{n}")
    for nn in sorted(cards):
        print(f"card\t{nn}\t{cards[nn][0]}\t{' '.join(cards[nn][1])}")


def verified(n, commit, rs):
    gh("issue", "edit", n, "--add-label", VERIFIED, "--remove-label", TO_VERIFY)
    gh("issue", "comment", n, "--body", f"Verified by Robin on `{commit}`: rows {', '.join(rs.split(','))} pass.")
    print(f"#{n} verified")


def reopen(n, path):
    text = open(path, encoding="utf-8").read().strip()
    gh("issue", "edit", n, "--remove-label", f"{TO_VERIFY},{VERIFIED}")
    gh("issue", "reopen", n, "--comment", text)
    print(f"#{n} re-opened")


def match(row):
    for i in closed(f"label:{VERIFIED}"):
        if VERIFIED in labels(i) and row in (rows(i["body"]) or []):
            print(f"#{i['number']}\t{i['title']}")


def merged(pr):
    """Lines saying which issues the merged pull request closed and got `to verify`."""
    refs = json.loads(gh("pr", "view", pr, "--json", "closingIssuesReferences")).get("closingIssuesReferences") or []
    out = []
    for ref in refs:
        n, repo = str(ref["number"]), ref["repository"]["owner"]["login"] + "/" + ref["repository"]["name"]
        issue = json.loads(gh("issue", "view", n, "--repo", repo, "--json", "body"))
        if rows(issue["body"]) is not None:
            gh("issue", "edit", n, "--repo", repo, "--add-label", TO_VERIFY, "--remove-label", VERIFIED)
            out.append(f"#{n} to verify")
    return out


def after_merge(pr):
    """For cost.py's merge step: the lines to show, never an exception."""
    try:
        return merged(pr)
    except Exception as e:
        return [f"ck cards: the to verify label was not set: {e}"]


# The bug list page: what GitHub holds, nothing more.
RECENT = 14  # days a closed issue stays on the page
SEVERITY = ("blocks play", "hurts play", "rough edge")
FIELDS = """number title url state body createdAt closedAt issueType { name } labels(first: 30) { nodes { name } }
parent { number title url state } subIssues { totalCount }
closedByPullRequestsReferences(first: 5, includeClosedPrs: true) { nodes { number url state } }
timelineItems(itemTypes: [REOPENED_EVENT]) { totalCount }"""
Q_OPEN = """query($owner: String!, $name: String!, $after: String) { repository(owner: $owner, name: $name) {
issues(states: OPEN, first: 25, after: $after) { pageInfo { hasNextPage endCursor }
nodes { %s subIssues(first: 100) { totalCount nodes { %s } } } } } }""" % (FIELDS.replace("subIssues { totalCount }", ""), FIELDS)
Q_FIND = """query($q: String!, $after: String) { search(query: $q, type: ISSUE, first: 50, after: $after) {
pageInfo { hasNextPage endCursor } nodes { ... on Issue { %s } } } }""" % FIELDS


def graphql(query, key, **vars):
    out, after = [], None
    while True:
        args = ["api", "graphql", "-f", f"query={query}"]
        for k, v in list(vars.items()) + ([("after", after)] if after else []):
            args += ["-f", f"{k}={v}"]
        data = json.loads(gh(*args))["data"]
        conn = data["repository"]["issues"] if key == "issues" else data["search"]
        out += conn["nodes"]
        if not conn["pageInfo"]["hasNextPage"]:
            return out
        after = conn["pageInfo"]["endCursor"]


def link_file():
    git = subprocess.run(["git", "rev-parse", "--path-format=absolute", "--git-common-dir"],
                         capture_output=True, text=True)
    if git.returncode:
        raise Failed("this folder is not a git repository")
    return os.path.join(git.stdout.strip(), "ck-bug-list-link")


def issues(repo):
    owner, name = repo.split("/")
    seen = {}
    for i in graphql(Q_OPEN, "issues", owner=owner, name=name):
        subs = i.pop("subIssues")
        if subs["totalCount"]:  # an epic: its open and closed issues, not itself
            for s in subs["nodes"]:
                s["parent"] = {k: i[k] for k in ("number", "title", "url", "state")}
                seen[s["number"]] = s
        else:
            seen.setdefault(i["number"], i)
    since = (datetime.date.today() - datetime.timedelta(days=RECENT)).isoformat()
    for q in (f'repo:{repo} is:issue is:closed label:"{TO_VERIFY}"', f"repo:{repo} is:issue is:closed closed:>={since}"):
        for i in graphql(Q_FIND, "search", q=q):
            if i and not i["subIssues"]["totalCount"]:
                seen.setdefault(i["number"], i)
    for i in seen.values():
        i["labels"] = i["labels"]["nodes"]
    return list(seen.values())


def short(title):
    return re.sub(r"^\(\w+\)\s*", "", title)


def kind(i):
    t = (i.get("issueType") or {}).get("name", "")
    return {"Feature": "wish", "Task": "task"}.get(t, "bug")


def pills(i):
    e, ls, out = html.escape, labels(i), []
    prs = (i.get("closedByPullRequestsReferences") or {}).get("nodes") or []
    fix = next((p for p in prs if p["state"] == "MERGED"), None)
    work = next((p for p in prs if p["state"] == "OPEN"), None)
    a = lambda cls, text, p: f'<a class="pill {cls}" href="{e(p["url"])}">{text} #{p["number"]}</a>'
    if i["state"] == "CLOSED":
        if VERIFIED in ls:
            out.append(a("verified", "verified", fix) if fix else '<span class="pill verified">verified</span>')
        else:
            out.append(a("closed", "closed", fix) if fix else '<span class="pill closed">closed</span>')
        if TO_VERIFY in ls:
            out.append('<span class="pill verify">to verify</span>')
    else:
        if i["timelineItems"]["totalCount"]:
            out.append('<span class="pill reopened">re-opened</span>')
        if work:
            out.append(a("work", "at work", work))
    sev = next((s for s in SEVERITY if s in ls), None)
    k = kind(i)
    if k == "bug":
        out.append(f'<span class="pill {sev.split()[0] if sev else "unrated"}">{sev or "unrated"}</span>')
    else:
        out.append(f'<span class="pill {k}">{k}</span>')
    if "launch blocker" in ls:
        out.append('<span class="pill blocks">launch blocker</span>')
    rs = rows(i.get("body"))
    if rs:
        out.append(f'<span class="pill case">test case {e(", ".join(rs))}</span>')
    return "".join(out)


def order(i):
    ls, k = labels(i), kind(i)
    sev = next((n for n, s in enumerate(SEVERITY) if s in ls), 3)
    return (i["state"] == "CLOSED", {"bug": 0, "wish": 1, "task": 2}[k], sev, i["number"])


def render(repo, items):
    e = html.escape
    open_ = [i for i in items if i["state"] == "OPEN"]
    bugs = [i for i in open_ if kind(i) == "bug"]
    sev = lambda s: sum(1 for i in bugs if s in labels(i))
    waiting = sum(1 for i in items if i["state"] == "CLOSED" and TO_VERIFY in labels(i))
    epics, groups = {}, {}
    for i in items:
        p = i.get("parent")
        n = p["number"] if p else 0
        epics.setdefault(n, p)
        groups.setdefault(n, []).append(i)
    keys = sorted((n for n in groups if n), key=lambda n: (epics[n]["state"] == "CLOSED", n)) + ([0] if 0 in groups else [])
    stats = [(len(open_), "open issues", f"{len(bugs)} bugs, {len(open_) - len(bugs)} wishes and tasks"),
             (len(bugs), "open bugs", f"{sev('blocks play')} block play, {sev('hurts play')} hurt it, "
                                      f"{sev('rough edge')} rough edges"),
             (waiting, "to verify", "fixed, waiting for Robin"),
             (len(keys) - (0 in groups), "epics", f"holding {sum(len(groups[n]) for n in keys if n)} shown here")]
    out = []
    for n in keys:
        g = sorted(groups[n], key=order)
        shut = sum(1 for i in g if i["state"] == "CLOSED")
        hurt = sum(1 for i in g if i["state"] == "OPEN" and {"blocks play", "hurts play"} & labels(i))
        nb = sum(1 for i in g if kind(i) == "bug")
        if n:
            p = epics[n]
            head = (f'<p class="eyebrow">Epic <a href="{e(p["url"])}">{n}</a>{", closed" if p["state"] == "CLOSED" else ""}</p>'
                    f'<h3>{e(short(p["title"]))}</h3>')
        else:
            head = '<p class="eyebrow">Outside the epics</p><h3>Standing alone</h3>'
        tally = (f'<p class="tally"><b>{nb}</b> bugs, <b>{len(g) - nb}</b> wishes and tasks, '
                 f'<b>{hurt}</b> still hurting play, <b>{shut}</b> closed of {len(g)}</p>')
        rows_ = "".join(
            f'<li class="row{" shut" if i["state"] == "CLOSED" else ""}"><a class="num" href="{e(i["url"])}">{i["number"]}</a>'
            f'<div><p class="ttl">{e(short(i["title"]))}</p><p class="pills">{pills(i)}</p></div></li>' for i in g)
        out.append(f'<section class="epic"><header>{head}{tally}</header><ol class="rows">{rows_}</ol></section>')
    today = datetime.date.today()
    day = f"{today.day} {today:%B %Y}"
    stat = "".join(f'<div class="stat"><span class="fig">{f}</span><span class="what">{w}</span>'
                   f'<span class="sub">{e(s)}</span></div>' for f, w, s in stats)
    return f"""<!doctype html><html lang="en"><head><meta charset="utf-8">
<meta name="viewport" content="width=device-width,initial-scale=1"><title>{e(repo.split("/")[1])} bug list</title><style>
:root{{--bg:#faf9f5;--ink:#141413;--muted:#5f5d55;--rule:#e8e6dc;--red:#b42318;--orange:#c4581a;--blue:#2f6db0;--green:#2f7a3d;--gold:#9a6b12;--violet:#6b47b8}}
@media (prefers-color-scheme:dark){{:root:not([data-theme="light"]){{--bg:#141413;--ink:#faf9f5;--muted:#b0aea5;--rule:#2b2a26;--red:#f0857d;--orange:#f0a35e;--blue:#7fb0e8;--green:#86c98f;--gold:#e0b55a;--violet:#b79cf0}}}}
:root[data-theme="dark"]{{--bg:#141413;--ink:#faf9f5;--muted:#b0aea5;--rule:#2b2a26;--red:#f0857d;--orange:#f0a35e;--blue:#7fb0e8;--green:#86c98f;--gold:#e0b55a;--violet:#b79cf0}}
*{{box-sizing:border-box}}body{{margin:0;background:var(--bg);color:var(--ink);font:16px/1.5 -apple-system,BlinkMacSystemFont,"Segoe UI",sans-serif}}
main{{max-width:880px;margin:0 auto;padding:40px 16px 72px;display:flex;flex-direction:column;gap:36px}}
a{{color:var(--blue);text-decoration:none}}a:hover{{text-decoration:underline}}p{{margin:0}}h1,h3{{margin:0;line-height:1.15}}h1{{font-size:36px}}h3{{font-size:22px}}
.eyebrow{{font-size:12px;font-weight:600;letter-spacing:.1em;text-transform:uppercase;color:var(--muted)}}
.stats{{display:grid;grid-template-columns:repeat(4,minmax(0,1fr));gap:1px;background:var(--rule);border:1px solid var(--rule)}}
.stat{{background:var(--bg);padding:14px 16px;display:flex;flex-direction:column;gap:2px}}.fig{{font-size:34px;font-weight:700;line-height:1;font-variant-numeric:tabular-nums}}
.what{{font-weight:600}}.sub,.tally,footer{{color:var(--muted);font-size:14px}}.tally b{{color:var(--ink)}}
.epic{{display:flex;flex-direction:column;gap:10px;padding-top:20px;border-top:1px solid var(--rule)}}.epic header{{display:flex;flex-direction:column;gap:4px}}
.rows{{list-style:none;margin:0;padding:0}}.row{{display:grid;grid-template-columns:3.4rem minmax(0,1fr);gap:4px 12px;padding:10px 0;border-bottom:1px solid var(--rule)}}
.num{{font-weight:700;font-size:18px;font-variant-numeric:tabular-nums}}.shut .ttl{{color:var(--muted)}}
.pills{{display:flex;flex-wrap:wrap;gap:6px;margin-top:4px}}
.pill{{font-size:12px;font-weight:600;padding:1px 8px 2px;border:1px solid currentColor;border-radius:4px;white-space:nowrap}}
.blocks{{color:var(--red)}}.hurts{{color:var(--orange)}}.rough{{color:var(--muted)}}.unrated{{color:var(--ink);border-style:dashed}}
.wish{{color:var(--blue)}}.task{{color:var(--muted)}}.closed{{color:var(--green)}}.work{{color:var(--gold);border-style:dashed}}
.case{{color:var(--violet)}}.verify{{color:var(--gold)}}.verified{{color:var(--bg);background:var(--green);border-color:var(--green)}}
.reopened{{color:var(--bg);background:var(--red);border-color:var(--red)}}
@media (max-width:640px){{.stats{{grid-template-columns:repeat(2,minmax(0,1fr))}}h1{{font-size:30px}}}}
</style></head><body><main>
<header><p class="eyebrow">{e(repo)}, read from GitHub on {day}</p><h1>The bug list</h1></header>
<div class="stats">{stat}</div>
{"".join(out) or '<p>No open issue.</p>'}
<footer>Built by ck from GitHub: every open issue, the closed ones of each open epic, and those labelled to verify or closed in the last {RECENT} days.</footer>
</main></body></html>
"""


def page(flag, value):
    path = link_file()
    if flag == "--link":
        if not value.startswith("https://claude.ai/"):
            raise Failed("a page link starts with https://claude.ai/")
        with open(path, "w", encoding="utf-8") as f:
            f.write(value + "\n")
        print("saved")
        return
    repo = gh("repo", "view", "--json", "nameWithOwner", "--jq", ".nameWithOwner").strip()
    text = render(repo, issues(repo))
    os.makedirs(os.path.dirname(os.path.abspath(value)), exist_ok=True)
    with open(value, "w", encoding="utf-8") as f:
        f.write(text)
    print(open(path, encoding="utf-8").read().strip() if os.path.exists(path) else "new")


def main():
    a = sys.argv[1:]
    if a == ["list"]:
        list_()
    elif len(a) == 4 and a[0] == "verified":
        verified(*a[1:])
    elif len(a) == 3 and a[0] == "reopen":
        reopen(*a[1:])
    elif len(a) == 2 and a[0] == "match" and ROW.fullmatch(a[1]):
        match(a[1])
    elif len(a) == 2 and a[0] == "merged":
        for line in merged(a[1]):
            print(line)
    elif len(a) == 3 and a[0] == "page" and a[1] in ("--out", "--link"):
        page(a[1], a[2])
    else:
        print("usage: cards.py list | verified N COMMIT ROWS | reopen N FILE | match NN-Xn | merged PR"
              " | page --out FILE | page --link URL", file=sys.stderr)
        return 2
    return 0


if __name__ == "__main__":
    try:
        sys.exit(main())
    except Exception as e:
        print(f"cards.py: {e}")
        sys.exit(1)
