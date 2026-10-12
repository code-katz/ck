# tests/pending/P1-S0.sh: the checks for stage P1-S0, Mend and guard the renderer.
#
# Written in stage P0-S1, before the work. Section 21 of tests/run.sh says how this file is run
# and what it may use. The stage is done when every check here passes and this file has moved to
# tests/checks/. Tighten a check when the work shows it is too weak. Never loosen one.
#
# What the renderer must do, as these checks read it:
#   - A file that holds a key shape is refused: a status other than 0, no page written, and a
#     message that names the line, never prints the key, and says the check is not a secret scanner.
#   - The seven shapes are an AWS access key id, a private key header, an sk- or sk_ key, a GitHub
#     token, a Slack token, a Google API key, and a JSON web token. The proposal counts seven and
#     does not list them: these are the seven its security review named. Each has a beginning and
#     a length. A beginning alone, the words risk-based and task-list, and a file's name are not keys.
#   - The check reads the whole file as text, so a key inside a code fence stops the render too.
#   - The stage may know more shapes than these. It may not know fewer.
#
# One check here passes today, on purpose: the one for the old third comment step. It says so.

renderer="$PWD/$PAGE_RENDERER"
steps=tests/fixtures/proof/comment-steps.txt

# render <markdown> <page>: runs the renderer. What it printed is in <page>.said.
render() { python3 "$renderer" --in "$1" --out "$2" --title "Check" > "$2.said" 2>&1; }

# ─── The four comment steps ──────────────────────────────────────────────────
render tests/fixtures/game/docs/PRD.md "$SCRATCH/prd.html"
banner_steps "$SCRATCH/prd.html" > "$SCRATCH/prd.steps" 2> /dev/null
if [[ -s "$SCRATCH/prd.steps" ]] && cmp -s "$SCRATCH/prd.steps" "$steps"; then
  ok "the proof's banner carries the four comment steps, letter for letter from $steps"
else
  first=$(diff "$SCRATCH/prd.steps" "$steps" 2> /dev/null | grep -m1 '^< ' | cut -c3-)
  fail "the proof's banner carries the four comment steps, letter for letter from $steps: the banner says '${first:-nothing}'"
fi

# This check stood in section 12 of tests/run.sh, inside "the banner carries the four comment
# steps". It passes today, and it is the one check in this file that does: it looks for the old
# third step, which this stage replaces. When the four new steps are on the page, reverse it, so
# that it fails a page that still tells the reviewer not to send the comment.
if grep -q 'Do not send the comment to Claude' "$SCRATCH/prd.html" 2> /dev/null; then
  ok "the proof's banner still carries the old third step, Do not send the comment to Claude (until this stage reverses this check)"
else
  fail "the proof's banner still carries the old third step: it is gone, so reverse this check as the comment above it says"
fi

# ─── The two faults ──────────────────────────────────────────────────────────
render tests/fixtures/proof/link-quote.md "$SCRATCH/link.html"
why=$(python3 - "$SCRATCH/link.html" <<'EOF' 2>&1
import pathlib, sys
from html.parser import HTMLParser
path = pathlib.Path(sys.argv[1])
if not path.is_file():
    print('the renderer wrote no page'); sys.exit()
tags = []
class Reader(HTMLParser):
    def handle_starttag(self, tag, attrs): tags.append((tag, dict(attrs)))
Reader().feed(path.read_text(encoding='utf-8'))
# The links in the document: not the contents list's, and not the heading anchors. A link may
# carry what a careful renderer adds to one (rel, target, title, class). It carries nothing else:
# the fixture's addresses would add a handler, and a style.
links = [a for tag, a in tags if tag == 'a' and not (a.get('href') or '').startswith('#')]
handlers = sorted({name for _, a in tags for name in a if name.startswith('on')})
extra = sorted({name for a in links for name in a if name not in ('href', 'rel', 'target', 'title', 'class')})
if handlers: print('an element has the attribute ' + ', '.join(handlers))
elif extra: print('a link has an attribute its address gave it: ' + ', '.join(extra))
elif not any(a.get('href') == 'https://example.com/docs' for a in links): print('the plain link is no longer a link')
EOF
)
if [[ -z "$why" ]]; then ok "a quote in a link address adds no attribute, and a plain link is still a link"
else fail "a quote in a link address adds no attribute, and a plain link is still a link: $why"; fi

render tests/fixtures/proof/table-bar.md "$SCRATCH/table.html"
# third_cell <row> <the text its third cell must hold> [<the code span it must hold>]: prints
# nothing when the row has three cells and the third holds that text. Otherwise prints why not.
third_cell() {
  python3 - "$SCRATCH/table.html" "$@" <<'EOF' 2>&1
import html, pathlib, re, sys
path, row, want = pathlib.Path(sys.argv[1]), int(sys.argv[2]), sys.argv[3]
code = sys.argv[4] if len(sys.argv) > 4 else None
if not path.is_file():
    print('the renderer wrote no page'); sys.exit()
body = path.read_text(encoding='utf-8').split('<tbody>', 1)[-1].split('</tbody>', 1)[0]
rows = [re.findall(r'<td[^>]*>(.*?)</td>', r, re.S) for r in re.findall(r'<tr[^>]*>(.*?)</tr>', body, re.S)]
text = lambda cell: ' '.join(html.unescape(re.sub(r'<[^>]+>', '', cell)).split())
if len(rows) != 3: print(f'the table has {len(rows)} rows, not 3')
elif len(rows[row - 1]) != 3: print(f'row {row} has {len(rows[row - 1])} cells, not 3: {[text(c) for c in rows[row - 1]]}')
elif len(rows[2]) != 3: print(f'row 3, which holds no bar, has {len(rows[2])} cells, not 3')
elif text(rows[row - 1][2]) != want: print(f'the third cell of row {row} reads "{text(rows[row - 1][2])}", not "{want}"')
elif code and [html.unescape(c) for c in re.findall(r'<code>(.*?)</code>', rows[row - 1][2], re.S)] != [code]: print(f'the third cell of row {row} does not hold the code span "{code}"')
EOF
}
why=$(third_cell 1 'bash tests/run.sh | grep -c FAIL prints 0' 'bash tests/run.sh | grep -c FAIL')
if [[ -z "$why" ]]; then ok "a bar inside a code span stays inside its table cell"
else fail "a bar inside a code span stays inside its table cell: $why"; fi
why=$(third_cell 2 'a | b')
if [[ -z "$why" ]]; then ok "a bar written with a backslash stays inside its table cell, and the backslash is not shown"
else fail "a bar written with a backslash stays inside its table cell, and the backslash is not shown: $why"; fi

# ─── The check for keys ──────────────────────────────────────────────────────
# Every key is built here, at run time, from a beginning and a filler. No file in the repository
# holds one, and none may: a scanner on the repository would stop the push, and it would be right.
filler() { local unit=$1 n=$2 out=''; while (( ${#out} < n )); do out+=$unit; done; printf '%s' "${out:0:n}"; }
upper=$(filler A1B2 12)     # twelve characters of the filler in each key below; never printed
mixed=$(filler a1B2 12)
dashes=$(filler - 5)
aws="The key is AKIA$(filler A1B2 16) for now."

# notes <a line>...: a document of ordinary prose. The first line given is line 12 of it.
notes() {
  printf '# Notes\n\n'
  for _ in 1 2 3 4 5 6 7 8 9; do printf 'A line of ordinary prose.\n'; done
  printf '%s\n' "$@"
  printf '\nA last line of ordinary prose.\n'
}

# key_stops <name> <never printed> <a line>...: prints nothing when a file that holds a key, on
# line 12 unless key_line says another, is refused as a key must be, and the same file without the
# key renders. Otherwise prints what went wrong. The renderer runs inside the folder, on file
# names that hold no number, so the only number its message need hold is the line's.
key_stops() {
  local name=$1 secret=$2 dir="$SCRATCH/key-$1" line=${key_line:-12} rc; shift 2
  mkdir -p "$dir"
  notes "$@" > "$dir/with.md"
  notes 'The key was taken out of this line.' > "$dir/without.md"
  (cd "$dir" && python3 "$renderer" --in with.md --out with.html --title Notes) > "$dir/said" 2>&1; rc=$?
  if [[ $rc -eq 0 ]]; then printf 'the file was rendered'
  elif [[ -e "$dir/with.html" ]]; then printf 'the render stopped with status %s, and the page was written all the same' "$rc"
  elif ! grep -qE "(^|[^0-9])$line([^0-9]|\$)" "$dir/said"; then printf 'the message does not name line %s' "$line"
  elif grep -qF -- "$secret" "$dir/said"; then printf 'the message prints the key'
  elif ! (cd "$dir" && python3 "$renderer" --in without.md --out without.html --title Notes) > /dev/null 2>&1 || [[ ! -s "$dir/without.html" ]]; then printf 'the same file without the key is refused too'
  fi
}

# every_key_stops <key_stops arguments> [-- <the next sample's>]...: prints nothing when every
# sample stops the render. Otherwise prints the first sample that does not, and what went wrong.
every_key_stops() {
  local sample why
  while (( $# > 0 )); do
    sample=()
    while (( $# > 0 )) && [[ "$1" != -- ]]; do sample+=("$1"); shift; done
    if (( $# > 0 )); then shift; fi
    why=$(key_stops "${sample[@]}")
    if [[ -n "$why" ]]; then printf '%s: %s' "${sample[0]}" "$why"; return; fi
  done
}

# shape <what holds the key> <every_key_stops arguments>: one check for one of the seven shapes.
shape() {
  local title=$1 why; shift
  why=$(every_key_stops "$@")
  if [[ -z "$why" ]]; then ok "$title stops the render: its line is named, the key is not printed, and no page is written"
  else fail "$title stops the render: $why"; fi
}

shape "an AWS access key id" aws "$upper" "$aws"
shape "a private key header" \
  rsa-header "$mixed" "${dashes}BEGIN RSA PRIVATE KEY${dashes}" "$(filler a1B2 64)" -- \
  openssh-header "$mixed" "${dashes}BEGIN OPENSSH PRIVATE KEY${dashes}" "$(filler a1B2 64)" -- \
  plain-header "$mixed" "${dashes}BEGIN PRIVATE KEY${dashes}" "$(filler a1B2 64)"
shape "a GitHub token" github "$mixed" "token: ghp_$(filler a1B2 36)"
shape "a Slack token" slack "$mixed" "SLACK_TOKEN=xoxb-$(filler 1234567890 12)-$(filler a1B2 24)"
shape "a Google API key" google "$mixed" "key=AIza$(filler a1B2 35)"
shape "a JSON web token" jwt "$mixed" "Authorization: Bearer eyJ$(filler a1B2 24).eyJ$(filler a1B2 24).$(filler a1B2 24)"

# The sk shape is the one a plain word can look like. The word risk-based holds sk-, and so does
# task-list: a check with no word boundary stops a plan that is only being careful, and its
# author learns to ignore the check. A key written with an underscore is a key all the same.
why=$(every_key_stops \
  sk-hyphen "$mixed" "OPENAI_API_KEY=sk-$(filler a1B2 24)" -- \
  sk-ant "$mixed" "ANTHROPIC_API_KEY=sk-ant-api03-$(filler a1B2 24)" -- \
  sk-underscore "$mixed" "STRIPE_KEY=sk_live_$(filler a1B2 24)")
if [[ -z "$why" ]]; then
  mkdir -p "$SCRATCH/words"
  notes 'This is a risk-based plan with a task-list.' 'A risk-based-and-task-list-driven-approach to desk-bound work is still only words.' > "$SCRATCH/words/risk.md"
  render "$SCRATCH/words/risk.md" "$SCRATCH/words/risk.html" && [[ -s "$SCRATCH/words/risk.html" ]] \
    || why="a document with the words risk-based and task-list is refused"
fi
if [[ -z "$why" ]]; then ok "an sk- or sk_ key stops the render, and the words risk-based and task-list do not"
else fail "an sk- or sk_ key stops the render, and the words risk-based and task-list do not: $why"; fi

# The check reads what is in a file, never what the file is called.
mkdir -p "$SCRATCH/names/plain" "$SCRATCH/names/key"
notes 'How the keyboard shortcuts work.' > "$SCRATCH/names/plain/keyboard.md"
notes 'How the hockey rota works.' > "$SCRATCH/names/plain/hockey.md"
notes "$aws" > "$SCRATCH/names/key/keyboard.md"
why=''
for name in keyboard hockey; do
  (cd "$SCRATCH/names/plain" && python3 "$renderer" --in "$name.md" --out "$name.html" --title Notes) > /dev/null 2>&1 && [[ -s "$SCRATCH/names/plain/$name.html" ]] \
    || why="a file named $name.md with no key in it is refused"
done
if [[ -z "$why" ]] && (cd "$SCRATCH/names/key" && python3 "$renderer" --in keyboard.md --out keyboard.html --title Notes) > /dev/null 2>&1; then
  why="a file named keyboard.md that holds a key is rendered"
fi
if [[ -z "$why" ]]; then ok "a file named keyboard.md renders, and stops the render only when it holds a key"
else fail "a file named keyboard.md renders, and stops the render only when it holds a key: $why"; fi

# A document about keys names how they begin. That is not a key.
why=$(key_stops whole "$upper" "$aws")
if [[ -z "$why" ]]; then
  mkdir -p "$SCRATCH/whole"
  notes 'The check knows these beginnings: AKIA, ghp_, sk-, sk_live_, xoxb-, AIza, and eyJ.' 'It also knows the words BEGIN PRIVATE KEY between two runs of five dashes.' > "$SCRATCH/whole/about.md"
  render "$SCRATCH/whole/about.md" "$SCRATCH/whole/about.html" && [[ -s "$SCRATCH/whole/about.html" ]] \
    || why="a document that only names how keys begin is refused"
fi
if [[ -z "$why" ]]; then ok "a key is its whole shape: a whole key stops the render, and the beginnings alone do not"
else fail "a key is its whole shape: a whole key stops the render, and the beginnings alone do not: $why"; fi

# Most keys in a document sit in a code fence, as a line of a config file. The fence opens on
# line 12 here, so the key is on line 13.
why=$(key_line=13 key_stops fenced "$mixed" '```' "export GITHUB_TOKEN=ghp_$(filler a1B2 36)" '```')
if [[ -z "$why" ]]; then ok "a key inside a code fence stops the render"
else fail "a key inside a code fence stops the render: $why"; fi

# The check is not a secret scanner, and it says so, so that nobody takes a rendered proof for a
# searched one.
key_stops scanner "$upper" "$aws" > /dev/null
if [[ ! -e "$SCRATCH/key-scanner/with.html" ]] && grep -qi 'not a secret scanner' "$SCRATCH/key-scanner/said" 2> /dev/null; then ok "the refusal says the check is not a secret scanner"
else fail "the refusal says the check is not a secret scanner: a file with a key gets '$(head -1 "$SCRATCH/key-scanner/said" 2> /dev/null | cut -c1-80)'"; fi
