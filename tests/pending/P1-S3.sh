# tests/pending/P1-S3.sh: the checks for stage P1-S3, Write the document contract.
#
# Written in stage P0-S1, before the work. Section 21 of tests/run.sh says how this file is run
# and what it may use. The stage is done when every check here passes and this file has moved to
# tests/checks/. Tighten a check when the work shows it is too weak. Never loosen one.
#
# The contract's headings are this stage's to choose, so no check here fixes a heading's words.
# The checks hold the shape the proposal fixes: one contract for the three kinds, written the
# way the other contracts are, in which every kind opens with one sentence and then the decisions
# the reader must make, and ends with the open questions and then what was read.
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

python3 - skills/doc-artifact/SKILL.md <<'EOF' | relay "the document contract"
import pathlib, re, sys
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
print('end')
EOF
