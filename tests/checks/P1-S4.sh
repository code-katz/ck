# tests/checks/P1-S4.sh: the checks for stage P1-S4, Write the proof command.
#
# Written in stage P0-S1, before the work, and moved here when the work was done. Section 21 of
# tests/run.sh says how this file is run and what it may use. Tighten a check when the work shows
# it is too weak. Never loosen one.
#
# The command is skills/proof/SKILL.md. Its words are the stage's. A check finds a rule by a few
# words that any wording of it holds, in one item of a list or one paragraph of the skill. The
# words are a floor.
#
# Two checks run the skill's own commands, as section 15 of tests/run.sh runs the other skills',
# and for those the skill keeps the shape those skills have:
#   - a step headed "Resume check", with the listing under the words "exact command", in a bash fence
#   - a step headed "Mint the run", with the lines that set timestamp and runId from <slug>
# A placeholder in a command is written in angle brackets, as <slug>, <kind>, <date>, and <file>.

skill=skills/proof/SKILL.md

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

# ─── What the skill says ─────────────────────────────────────────────────────
mkdir -p "$SCRATCH/commands"
python3 - "$skill" "$LOOP_SKILL" "$SCRATCH/commands" <<'EOF' | relay "the proof command"
import pathlib, re, sys
path, loop, out = pathlib.Path(sys.argv[1]), sys.argv[2], pathlib.Path(sys.argv[3])
text = path.read_text(encoding='utf-8') if path.is_file() else ''
lines = text.split('\n')
absent = '' if text else f'{path} is not written'
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
    say('the command ' + name, absent or (f'no item or paragraph of {path} holds all of: ' + ', '.join(unmet[0]) if unmet else ''))

front = text.split('---', 2)[1] if text.startswith('---') and text.count('---') >= 2 else ''
lacks = [key for key, pattern in (('name: proof', r'^name: proof$'), ('disable-model-invocation: true', r'^disable-model-invocation: true$'), ('an argument hint', r'^argument-hint: \S'))
         if not re.search(pattern, front, re.M)]
say('the command is skills/proof/SKILL.md, named proof, run only when typed, with an argument hint',
    absent or ('its frontmatter lacks ' + ', '.join(lacks) if lacks else ''))

say('the command hands its document to the loop skill, and restates neither the comment steps nor the loop',
    absent or (f'it does not name {loop}' if loop not in text else 'it restates the comment steps' if re.search(r'comment mode', text, re.I) else ''))

# The headings the command writes to are the contract's. It may name the contract and no heading,
# or name headings: every one it names is then one of the contract's.
contract = pathlib.Path('skills/doc-artifact/SKILL.md')
ours = set(re.findall(r'^\d+\. `## (.+?)`', contract.read_text(encoding='utf-8'), re.M)) if contract.is_file() else set()
named = [h for h in re.findall(r'`## ([^`]+)`', text) if h not in ours]
say('the command writes to the document contract, and every heading it names is one of the contract\'s',
    absent or (f'it does not name {contract}' if str(contract) not in text
               else f'{contract} is not written' if not ours
               else f'it names `## {named[0]}`, which the contract does not have' if named else ''))

kinds = [kind for kind in ('proposal', 'analysis', 'note') if not re.search(r'\b' + kind + r'\b', text, re.I)]
say('the command writes one document, at docs/<kind>/<date>-<slug>.md, where kind is proposal, analysis, or note',
    absent or ('it does not name the path docs/<kind>/<date>-<slug>.md' if 'docs/<kind>/<date>-<slug>.md' not in text
               else ('it does not name the kind ' + ', '.join(kinds)) if kinds else ''))

rule('writes nothing when it is asked for a plan, and says a plan is a staged plan, written by /ck:plan',
     [r'staged plan', r'/ck:plan', r'nothing|no file|never writes?|does not write|refuse'])
rule('counts the words of the document with wc', [r'wc -w'])
say('the command runs the guard on a file that exists, before anything is published',
    absent or ('it does not name scripts/proof-guard.py' if 'scripts/proof-guard.py' not in text else ''))
rule('says one line that names the file, its word count, and its first heading, and waits for yes',
     [r'word count|words', r'first heading', r'\byes\b'])
rule('takes the plan this session wrote in plan mode when nothing follows the command',
     [r'plan mode', r'nothing|no text|no argument|on its own|by itself'])
rule('locks a document only when the author types approved',
     [r'approved', r'typed|types|typing', r'lock'])
rule('stops at approved with one next action, and does not start building',
     [r'approved', r'one next action'], [r'(not|never) (starts? |begins? )?build|builds? nothing'])
rule('reads without changing anything, and never installs, builds, or runs tests',
     [r'never|not', r'install', r'build', r'tests?\b'])

# House style, as section 11 of tests/run.sh holds every other command to it.
prose, fence = [], False
for line in lines:
    if line.startswith('```'): fence = not fence
    elif not fence: prose.append(line)
prose = '\n'.join(prose)
say('the command prints no token count and has no em-dash in prose',
    absent or ('it prints a token count' if re.search(r'[0-9][0-9,.]*k? tokens', prose, re.I) else 'it has an em-dash in prose' if chr(8212) in prose else ''))

# The exact commands, pulled out as section 15 pulls them, each with its placeholders filled in.
sample = {'slug': 'pricing', 'kind': 'note', 'date': '2026-10-12', 'file': 'docs/note/2026-10-12-pricing.md'}
fill = lambda cmd: re.sub(r'<([a-z][a-z -]*)>', lambda m: sample.get(m.group(1), 'x'), cmd)
problems, heading, n = [], '', 0
for i, line in enumerate(lines):
    if line.startswith('## '): heading = line[3:]
    if 'exact command' not in line: continue
    j = next((k for k in range(i + 1, len(lines)) if lines[k].strip()), i)
    if lines[j] == '```bash' and '```' in lines[j + 1:]:
        cmd = '\n'.join(lines[j + 1:lines.index('```', j + 1)])
    else:
        span = re.search(r'exact commands?[^`]*`([^`]+)`', line)
        cmd = span.group(1) if span else ''
    if not cmd:
        problems.append(f'under "{heading}", the words "exact command" have no command after them'); continue
    n += 1
    if re.search(r'[*?\[]', re.sub(r"'[^']*'|\"[^\"]*\"", '', cmd)):
        problems.append(f'under "{heading}", a file pattern stands outside quotes in: {cmd[:70]}')
    if 'Resume check' in heading: (out / 'resume.sh').write_text(fill(cmd) + '\n')
mint = re.search(r'^## \d+\. Mint the run\n(.*?)(?=^## |\Z)', text, re.M | re.S)
mint = [l for l in (mint.group(1).split('\n') if mint else []) if re.match(r'(timestamp|runId)=', l)]
if len(mint) == 2 and any('<slug>' in l for l in mint): (out / 'mint.sh').write_text('\n'.join(mint) + '\n')
say('the command has exact commands, and none leaves a file pattern for the shell to expand',
    absent or (problems[0] if problems else 'no line of it says "exact command"' if n == 0 else ''))
print('end')
EOF

# ─── What its listing does ───────────────────────────────────────────────────
# zsh stops a command whose file pattern matches nothing before the command runs, and the files
# that do exist are never listed. And a listing that finds another subject's run takes a new
# request into an old review. So the resume listing is run, in both shells, in a project with two
# documents: one on pricing, and one on annual pricing, whose name ends with the other's.
resume="$SCRATCH/commands/resume.sh"; mint="$SCRATCH/commands/mint.sh"
why=''
if [[ ! -f "$skill" ]]; then why="$skill is not written"
elif [[ ! -f "$resume" ]]; then why='the step headed "Resume check" has no exact command to run'
elif [[ ! -f "$mint" ]]; then why='the step headed "Mint the run" does not set timestamp and runId from <slug>'
fi
shells=0
for sh in bash zsh; do
  [[ -z "$why" ]] || break
  command -v "$sh" > /dev/null 2>&1 || continue
  shells=$((shells + 1))
  project="$SCRATCH/$sh-project"; mkdir -p "$project/empty" "$project/two"
  (cd "$project/empty" && "$sh" "$resume") > "$project/out" 2> "$project/err"
  if [[ -s "$project/out" || -s "$project/err" ]]; then why="$sh: in an empty project the listing prints '$(cat "$project/out" "$project/err" | head -2 | tr '\n' ' ')'"; break; fi
  for slug in pricing annual-pricing; do
    # A run folder named as the skill's own Mint step names it, so the listing and the name cannot drift apart.
    run=$(eval "$(sed "s/<slug>/$slug/g" "$mint")"; printf '%s' "${runId:-}")
    if [[ "$run" != *"$slug"* ]]; then why="$sh: the Mint step gives the run id '$run' for the slug $slug"; break 2; fi
    mkdir -p "$project/two/.ck/runs/$run"
    touch "$project/two/.ck/runs/$run/run.json" "$project/two/.ck/runs/$run/review.md" "$project/two/.ck/runs/$run/review.html"
    for kind in proposal analysis note; do mkdir -p "$project/two/docs/$kind"; touch "$project/two/docs/$kind/2026-10-12-$slug.md"; done
  done
  (cd "$project/two" && "$sh" "$resume") > "$project/out" 2> "$project/err"
  if [[ -s "$project/err" ]]; then why="$sh: the listing writes to stderr: $(head -1 "$project/err")"
  elif grep -q 'annual-pricing' "$project/out"; then why="$sh: the listing for pricing lists the run or the document for annual pricing: $(grep -m1 'annual-pricing' "$project/out")"
  elif ! grep -q 'pricing' "$project/out"; then why="$sh: the listing for pricing lists neither its run folder nor its document"
  fi
done
[[ -n "$why" || $shells -gt 0 ]] || why="neither bash nor zsh is here to run the listing"
if [[ -z "$why" ]]; then ok "the resume listing runs as written under bash and zsh, prints nothing in an empty project, and a second document on another subject does not resume the first"
else fail "the resume listing runs as written under bash and zsh, prints nothing in an empty project, and a second document on another subject does not resume the first: $why"; fi
