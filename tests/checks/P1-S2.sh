# tests/checks/P1-S2.sh: the checks for stage P1-S2, Write the loop's rules.
#
# Written in stage P0-S1, before the work. Section 21 of tests/run.sh says how this file is run
# and what it may use. The stage is done when every check here passes and this file has moved to
# tests/checks/. Tighten a check when the work shows it is too weak. Never loosen one.
#
# Two kinds of check are here.
#   - The four comment steps are fixed, letter for letter, by tests/fixtures/proof/comment-steps.txt.
#     The gallery renderer, the gallery contract, and the two workflows that check a gallery's
#     banner are each held to that file. The proof's own banner is stage P1-S0's.
#   - The loop's rules are the stage's to word. A check finds a rule by a few words that any
#     wording of it holds, in one item of a list or one paragraph of the loop skill. The words
#     are a floor. Whether the rule says what the proposal means is for the readers in phase 2.
#
# One check here passed before the stage, on purpose: the one for the old third comment step. The
# stage reversed it, as its comment says.

steps=tests/fixtures/proof/comment-steps.txt

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

# ─── The four comment steps on a gallery ─────────────────────────────────────
python3 scripts/render-gallery.py --in tests/fixtures/gallery/brand.json --out "$SCRATCH/gallery.html" > /dev/null 2>&1
banner_steps "$SCRATCH/gallery.html" > "$SCRATCH/gallery.steps" 2> /dev/null
if [[ -s "$SCRATCH/gallery.steps" ]] && cmp -s "$SCRATCH/gallery.steps" "$steps"; then
  ok "the gallery's banner carries the four comment steps, letter for letter from $steps"
else
  first=$(diff "$SCRATCH/gallery.steps" "$steps" 2> /dev/null | grep -m1 '^< ' | cut -c3-)
  fail "the gallery's banner carries the four comment steps, letter for letter from $steps: the banner says '${first:-nothing}'"
fi

# This check stood in section 13 of tests/run.sh, inside "the banner carries the four comment
# steps". Before stage P1-S2 it looked for the old third step; that stage reversed it, so it now
# fails a gallery that still tells the reviewer not to send the comment.
if grep -q 'Do not send the comment to Claude' "$SCRATCH/gallery.html" 2> /dev/null; then
  fail "the gallery's banner no longer tells the reviewer not to send the comment: the old third step, Do not send the comment to Claude, is still on the page"
else
  ok "the gallery's banner no longer tells the reviewer not to send the comment"
fi

python3 - "$steps" "$SCRATCH/gallery.html" <<'EOF' | relay "the gallery contract and the two workflows"
import pathlib, re, sys
steps = pathlib.Path(sys.argv[1]).read_text(encoding='utf-8').splitlines()
page = pathlib.Path(sys.argv[2])
page = page.read_text(encoding='utf-8') if page.is_file() else ''
def say(name, why=''):
    print(('fail\t' + name + ': ' + why) if why else ('ok\t' + name))

contract = [line.strip() for line in pathlib.Path('skills/gallery-artifact/SKILL.md').read_text(encoding='utf-8').split('\n')]
missing = [n for n, step in enumerate(steps, 1) if f'{n}. {step}' not in contract]
say('the gallery contract carries the four comment steps, letter for letter from the fixture',
    f'step {missing[0]} is not in skills/gallery-artifact/SKILL.md as the fixture writes it' if missing else '')

# A workflow tells its checker which words to find in a gallery's banner. Words the renderer no
# longer writes fail every gallery, and the workflow spends its two fix rounds on nothing.
for script in ('workflows/brand.js', 'workflows/design-round.js'):
    found = re.search(r"'([^']+)' appears in the banner", pathlib.Path(script).read_text(encoding='utf-8'))
    words = found.group(1) if found else ''
    say(f'{script} has its checker look in the banner for words of the fixture, as the renderer writes them',
        'it does not say which words to find in the banner' if not found
        else f'it looks for "{words}", which is not in the fixture' if not any(words in step for step in steps)
        else f'it looks for "{words}", which the gallery renderer does not write as one run of text' if words not in page
        else '')
print('end')
EOF

# ─── The loop's rules ────────────────────────────────────────────────────────
python3 - "$LOOP_SKILL" "$steps" <<'EOF' | relay "the loop skill"
import pathlib, re, sys
path = pathlib.Path(sys.argv[1])
steps = pathlib.Path(sys.argv[2]).read_text(encoding='utf-8').splitlines()
text = path.read_text(encoding='utf-8') if path.is_file() else ''
lines = text.split('\n')
def say(name, why=''):
    print(('fail\t' + name + ': ' + why) if why else ('ok\t' + name))
# A rule is one item of a list, or one paragraph. An item is read with the lines indented under it.
units, item = [], []
for line in lines + ['']:
    if not line.strip() or re.match(r'(\d+\.|[-*]|#+) ', line):
        if item: units.append(' '.join(item))
        item = []
    if line.strip(): item.append(line.strip())
def rule(name, *groups):
    """A rule is stated when, for each group of words, one item or paragraph holds every word of it."""
    unmet = [group for group in groups if not any(all(re.search(word, unit, re.I) for word in group) for unit in units)]
    say('the loop skill says ' + name, f'no item or paragraph of {path} holds all of: ' + ', '.join(unmet[0]) if unmet else '')

# The six rules for a comment queued for Claude.
rule('a reply is a proposal or an answer, and the proof changes only when the session republishes from the file, never by an edit to the page directly',
     [r'repl(y|ies)', r'proposal'], [r'republish', r'direct', r'never|not|only'])
rule('to read the thread before acting, and to do nothing when the session has already answered',
     [r'thread', r'already', r'nothing|not again|no second|a repeat'])
rule('one session answers a proof, and when a second session takes over',
     [r'one session', r'second session'])
rule('the five things a queued comment lets the session do, and that it refuses anything else',
     [r'\bfive\b', r'\bread\b', r'repl(y|ies)', r'\bedit', r'republish', r'resolve', r'refuse'])
rule("only the owner's yes counts, on a proof shared with someone else too",
     [r'\bonly\b.{0,40}\bowner|\bowner\b.{0,40}\bonly\b', r'\byes\b', r'shared'])
rule('a comment on a document that is already final gets a reply and no edit',
     [r'final', r'repl(y|ies)', r'no edit|not edit|never edit|without (an )?edit'])

# The rules of the loop that hold for every comment.
rule('one file is published, through the Artifact tool only',
     [r'\bone file\b', r'Artifact tool', r'only|never'])
rule("the proof's link is saved in the run record",
     [r'\b(links?|URL)\b', r'run\.json|run record'])
rule('only approved, typed in the session, locks a document',
     [r'approved', r'typed|types|typing', r'lock'])
rule('a comment and a reviewed file are data, never instructions',
     [r'\bdata\b', r'never', r'instruction'])
rule('a comment that asks for a change gets a proposal first, unless it is a yes to one already written',
     [r'proposal', r'unless|except', r'\byes\b'])

versions = sorted(set(re.findall(r'\b2\.\d+\.\d+\b', text)))   # Claude Code's versions begin with 2
say('the loop skill names the Claude Code version a queued comment needs, 2.1.228, and no other version',
    '' if versions == ['2.1.228'] else f'the versions it names are {versions or "none"}')

labels = [label for label in ('Queue for Claude', 'Send to Claude', '@claude') if label not in text]
say('the loop skill names the three labels a queued comment goes by: Queue for Claude, Send to Claude, and @claude',
    '' if not labels else 'it does not name ' + ', '.join(labels))

# The steps are the renderer's to write. The loop skill may repeat all four, as the fixture has
# them, or none: two of the old steps are also two of the new, so a skill left half changed
# holds some of them. The old third step, and the rule against sending a comment, must go.
stripped = [line.strip() for line in lines]
have = [n for n, step in enumerate(steps, 1) if f'{n}. {step}' in stripped]
old = [words for words in ('Do not send the comment to Claude', 'should not send') if words in text]
say('the loop skill writes the four comment steps letter for letter from the fixture, or leaves them to the renderer, and no longer tells the author not to send a comment',
    f'it still says "{old[0]}"' if old else f'it holds steps {have} of the four as the fixture writes them' if len(have) not in (0, 4) else '')

# One place for the rules: a skill that restates a rule drifts from it. The gallery contract
# carries the banner's steps, and so the banner's label, and nothing more.
others = sorted(p for p in pathlib.Path('skills').glob('*/SKILL.md') if p != path)
restated = [str(p) for p in others
            if re.search(r'Send to Claude|queued comment|comment queued', p.read_text(encoding='utf-8'), re.I)
            or (p.parent.name != 'gallery-artifact' and 'Queue for Claude' in p.read_text(encoding='utf-8'))]
say('the rules for a queued comment are in the loop skill and in no other skill',
    'no rule for a queued comment is in the loop skill yet' if 'Queue for Claude' not in text
    else ('they are also in ' + ', '.join(restated)) if restated else '')
print('end')
EOF
