# tests/checks/P1-S3.sh: the checks for stage P1-S3, Write the document contract.
#
# Written in stage P0-S1, before the work, and moved here when the work was done. Section 21 of
# tests/run.sh says how this file is run and what it may use. Tighten a check when the work shows
# it is too weak. Never loosen one.
#
# The contract's headings were its stage's to choose, so no check here fixes a heading's words.
# The checks hold the shape the proposal fixes: one contract for the three kinds, written the
# way the other contracts are, in which every kind opens with one sentence and then the decisions
# the reader must make, and ends with the open questions and then what was read.
#
# The first five checks are as stage P0-S1 wrote them. The stage added the eight after them, each
# for a contract the first five pass and that would still be wrong:
#   - Three lists written under one "Section order" read as one long list, and only the first
#     list's opening and the last list's ending are then looked at. So no list names a heading
#     twice, and there is one list for all three kinds or one for each, under a heading that
#     names its kind.
#   - "Opens the same way" was held by one word in each heading. The headings are now the same.
#   - A heading for each kind was enough to say how the kinds differ. They now stand side by side.
#   - The command counts a document's words, writes it under docs/<kind>/, and sends a plan to
#     /ck:plan. A contract with no size, no path, or a plan among its kinds leaves each of those
#     to the command alone.
#   - A proof's list of contents is made from these headings. Two headings that the page gives
#     one place would send a reader, and a comment, to the wrong section.
#
# Whether its list of headings equals the list the proof command writes to is stage P1-S4's check:
# the command is not written when this stage is done. The rule against an em-dash in prose
# reaches this contract through section 11 of tests/run.sh, which reads every contract.

# relay <what was read>: turns a program's lines, "ok<TAB>name" or "fail<TAB>name: why", into
# checks. The program ends with the line "end", so one that stops early is a failed check and not
# a shorter list.
relay() {
  local verdict message ended=0
  while IFS=$'\t' read -r verdict message; do
    case "$verdict" in ok) ok "$message" ;; fail) fail "$message" ;; end) ended=1 ;; esac
  done
  (( ended )) || fail "the reading of $1 stopped before its last check"
}

python3 - skills/doc-artifact/SKILL.md "$PAGE_RENDERER" "$SCRATCH" <<'EOF' | relay "the document contract"
import html, pathlib, re, subprocess, sys
path = pathlib.Path(sys.argv[1])
text = path.read_text(encoding='utf-8') if path.is_file() else ''
absent = '' if text else f'{path} is not written'
def say(name, why=''):
    print(('fail\t' + name + ': ' + why) if why else ('ok\t' + name))

front = text.split('---', 2)[1] if text.startswith('---') and text.count('---') >= 2 else ''
lacks = [key for key, pattern in (('name: doc-artifact', r'^name: doc-artifact$'), ('user-invocable: false', r'^user-invocable: false$'), ('a description', r'^description: \S'))
         if not re.search(pattern, front, re.M)]
say('the document contract is skills/doc-artifact/SKILL.md, named doc-artifact, described, and not for typing',
    absent or ('its frontmatter lacks ' + ', '.join(lacks) if lacks else ''))

# Each "## Section order" holds the numbered headings of one document, as in every other contract.
# The contract may have one list for all three kinds, or one list for each kind.
orders = [re.findall(r'^\d+\. `## (.+?)`', part.split('\n## Checklist', 1)[0].split('\n# ', 1)[0], re.M)
          for part in text.split('## Section order')[1:]]
say('it lists its headings as the other contracts do: numbered, under Section order, with a Checklist after',
    absent or ('it has no "## Section order" with numbered `## ` headings' if not orders or not all(orders)
               else 'it has no "## Checklist"' if '\n## Checklist' not in text
               else 'a list has fewer than four headings' if min(len(o) for o in orders) < 4 else ''))

listed = bool(orders) and all(len(o) >= 4 for o in orders)
first = [o[:2] for o in orders if not (re.search(r'sentence', o[0], re.I) and re.search(r'decision', o[1], re.I))] if listed else []
say('every kind opens with one sentence, and then the decisions the reader must make',
    absent or ('it has no list of headings to read' if not listed else f'a document opens with {first[0]}' if first else ''))

last = [o[-2:] for o in orders if not (re.search(r'open question|question.{0,15}\bopen\b', o[-2], re.I) and re.search(r'\bread\b', o[-1], re.I))] if listed else []
say('every kind ends with the open questions, and then what was read',
    absent or ('it has no list of headings to read' if not listed else f'a document ends with {last[0]}' if last else ''))

# How the kinds differ is said kind by kind: a row, an item, or a heading that begins with the kind,
# or one table with a column for each.
three = ('proposal', 'analysis', 'note')
entry = lambda kind: re.search(r'^[\s|>#*\-\d.`_]*' + kind + r'\b', text, re.I | re.M)
columns = any(all(re.search(r'\|[\s*`_]*' + kind + r'\b', line, re.I) for kind in three) for line in text.split('\n'))
kinds = [] if columns else [kind for kind in three if not entry(kind)]
say('it says how the three kinds differ, with a row, an item, a heading, or a column for a proposal, an analysis, and a note',
    absent or ('nothing begins with ' + ', '.join(kinds) if kinds else ''))

# ─── What the stage added ────────────────────────────────────────────────────
renderer, scratch = sys.argv[2], pathlib.Path(sys.argv[3])
lines = text.split('\n')
unread = absent or ('' if listed else 'it has no list of headings to read')

# The proposal's words are "opens the same way". A word in common is not the same heading.
pairs = sorted({(tuple(o[:2]), tuple(o[-2:])) for o in orders})
say('every kind opens with the same two headings and ends with the same two, word for word',
    unread or ('' if len(pairs) == 1 else f'one list opens with {list(pairs[0][0])} and ends with {list(pairs[0][1])}, '
                                          f'and another opens with {list(pairs[1][0])} and ends with {list(pairs[1][1])}'))

twice = sorted({h for o in orders for h in o if o.count(h) > 1})
say('no list names a heading twice', unread or (f'a list names `## {twice[0]}` more than once' if twice else ''))

# The heading a list stands under is the nearest one above its "Section order", outside a code fence.
def heading_above(position):
    found, fence = '', False
    for line in lines[:text.count('\n', 0, position)]:
        if line.startswith('```'): fence = not fence
        elif not fence and line.startswith('#'): found = line
    return found
heads = [heading_above(m.start()) for m in re.finditer('## Section order', text)]
named = [[kind for kind in three if re.search(r'\b' + kind + r'\b', head, re.I)] for head in heads]
say('it has one list of headings for all three kinds, or one for each kind, under a heading that names that kind and no other',
    unread or ('' if len(orders) == 1
               else f'it has {len(orders)} lists of headings' if len(orders) != 3
               else '' if sorted(sum(named, [])) == sorted(three) and all(len(n) == 1 for n in named)
               else 'its lists stand under ' + ', '.join('"' + head + '"' for head in heads)))

# Side by side is one table or one list: lines with no blank line between them.
start = r'^[\s|>#*\-\d.`_]*'
together = any(all(re.search(start + kind + r'\b', block, re.I | re.M) for kind in three) for block in re.split(r'\n[ \t]*\n', text))
say('it sets the three kinds side by side, in one table or one list',
    absent or ('' if together or columns else 'no one table or list has a row, an item, or a column for each of the three kinds'))

# The command counts a document's words. A count is of use only against a size, counted one way.
unsized = [kind for kind in three
           if not any(re.search(r'\d[\d,]* words\b', line) for line in lines if re.search(start + kind + r'\b', line, re.I))]
say('it gives each kind a size in words, on a row or an item that begins with the kind, and has the words counted with wc -w',
    absent or ('it gives no size in words for ' + ', '.join(unsized) if unsized else '' if 'wc -w' in text else 'it does not say to count with wc -w'))

say('it says where a document lives: docs/<kind>/<date>-<slug>.md',
    absent or ('' if 'docs/<kind>/<date>-<slug>.md' in text else 'it does not name docs/<kind>/<date>-<slug>.md'))

# A rule is one item of a list, or one paragraph, as the check files for the loop and the command
# read one. Here one sentence of it says a plan is no kind of this contract's, and it names the command.
units, item = [], []
for line in lines + ['']:
    if not line.strip() or re.match(r'(\d+\.|[-*]|#+) ', line):
        if item: units.append(' '.join(item))
        item = []
    if line.strip(): item.append(line.strip())
refuses = lambda unit: any(re.search(r'\bplan\b', sentence, re.I) and re.search(r'\b(none|not|never|no)\b', sentence, re.I)
                           for sentence in re.split(r'(?<=[.!?])\s+', unit))
say('it says a plan is none of its kinds, and names /ck:plan for one',
    absent or ('' if any('/ck:plan' in unit and refuses(unit) for unit in units)
               else 'no item or paragraph of it names /ck:plan and has a sentence that holds plan with none, not, never, or no'))

# A proof's list of contents is made from a document's headings. So a document with each list's
# headings goes through the page renderer, and each heading must come out once, in order, with a
# place of its own: two headings that differ only in a mark are one place to the page.
problems = []
for n, order in enumerate(orders if listed else [], 1):
    doc, page = scratch / f'list-{n}.md', scratch / f'list-{n}.html'
    doc.write_text('# A document\n\n' + ''.join(f'## {heading}\n\nWords.\n\n' for heading in order), encoding='utf-8')
    done = subprocess.run([sys.executable, renderer, '--in', str(doc), '--out', str(page), '--title', 'Check'], capture_output=True, text=True)
    if done.returncode != 0 or not page.is_file():
        said = (done.stderr or done.stdout).strip().splitlines()
        problems.append(f'the renderer made no page for list {n}: ' + (said[-1] if said else 'it said nothing')); continue
    contents = re.search(r'<nav class="toc"[^>]*>(.*?)</nav>', page.read_text(encoding='utf-8'), re.S)
    entries = re.findall(r'<a href="#([^"]+)">(.*?)</a>', contents.group(1) if contents else '', re.S)
    places, names = [place for place, name in entries], [html.unescape(name) for place, name in entries]
    shared = sorted({place for place in places if places.count(place) > 1})
    if names != order: problems.append(f'the page lists {names} for list {n}, and the contract lists {order}')
    elif shared: problems.append(f'two headings of list {n} share the place #{shared[0]} on the page')
say("a document written under each list's headings becomes a proof whose list of contents holds each heading once, in the contract's order",
    unread or (problems[0] if problems else ''))
print('end')
EOF
