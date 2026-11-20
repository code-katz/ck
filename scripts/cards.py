#!/usr/bin/env python3
"""cards.py: the GitHub side of /ck:cards, Robin's journey-card loop.

Usage, from the repository's top folder:
  cards.py list                  closed bugs with a Test case: line and no `verified` label, then a line per card;
                                 changes nothing on GitHub
  cards.py verified N COMMIT ROWS   adds `verified`, removes `to verify`, comments the rows that passed
  cards.py reopen N FILE         re-opens N, removes both labels, comments the file's text
  cards.py match ROW             closed `verified` bugs whose Test case: line names ROW
  cards.py merged PR             after a merge: `to verify` on each issue PR closed that has a Test case: line

From an issue it reads only its Test case: line (bold or not), its state and its labels (and prints its title).
A row is NN-Xn, as 09-D4. Every value goes to gh as an argument. Standard library only; a failed gh call prints
one line and exits 1, never a traceback.
"""

import json
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
    else:
        print("usage: cards.py list | verified N COMMIT ROWS | reopen N FILE | match NN-Xn | merged PR", file=sys.stderr)
        return 2
    return 0


if __name__ == "__main__":
    try:
        sys.exit(main())
    except Exception as e:
        print(f"cards.py: {e}")
        sys.exit(1)
