# tests/pending/P1-S5.sh: the checks for stage P1-S5, Update README and version.
#
# Written in stage P0-S1, before the work. Section 21 of tests/run.sh says how this file is run
# and what it may use. The stage is done when every check here passes and this file has moved to
# tests/checks/. Tighten a check when the work shows it is too weak. Never loosen one.
#
# Sections 17 and 19 of tests/run.sh keep holding the tables this stage adds to: the pipeline
# table gains no row, and the README's table of paths stays equal to what the pipeline writes.
# So where a proof's document goes is said in a sentence, as it is for a plan for one piece of work.
#
# One check here asks for more than the stage's entry in the plan says. The README's account of
# how a run works still tells the author to comment without sending the comment to Claude. The
# banner now says the opposite, and README.md is this stage's file, so the sentence is this stage's.

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

python3 - "$LOOP_SKILL" <<'EOF' | relay "the README, /ck:next, and the manifest"
import json, pathlib, re, sys
readme = pathlib.Path('README.md').read_text(encoding='utf-8')
prose = [line for line in readme.split('\n') if not line.startswith('|')]
def say(name, why=''):
    print(('fail\t' + name + ': ' + why) if why else ('ok\t' + name))

say('the README has a row for /ck:proof in its table of commands',
    '' if re.search(r'^\| `/ck:proof\b', readme, re.M) else 'no row of README.md begins with `/ck:proof')

where = [line for line in prose if '/ck:proof' in line]
folders = any('docs/<kind>/' in line or all(f'docs/{kind}/' in line for kind in ('proposal', 'analysis', 'note')) for line in where)
say('the README has a paragraph on /ck:proof that says where its document goes',
    'no line of README.md outside a table names /ck:proof' if not where
    else '' if folders else 'the paragraph does not name docs/<kind>/, or the three folders docs/proposal/, docs/analysis/, and docs/note/')

# The loop skill names the one Claude Code version a queued comment needs. The README names the same.
loop = pathlib.Path(sys.argv[1])
version = r'\b2\.\d+\.\d+\b'
ours = sorted({v for line in prose if re.search(r'queue|comment', line, re.I) for v in re.findall(version, line)})
theirs = sorted(set(re.findall(version, loop.read_text(encoding='utf-8')))) if loop.is_file() else []
say('the README names the Claude Code version a queued comment needs, the same one the loop skill names',
    'no line of README.md about comments names a Claude Code version' if not ours
    else '' if ours == theirs and len(ours) == 1
    else f'README.md names {", ".join(ours)} beside comments, and {loop} names {", ".join(theirs) or "no version"}')

say('the README no longer tells the author to comment without sending the comment to Claude',
    'README.md still says "without sending comments to Claude"' if re.search(r'without sending comments? to Claude', readme, re.I) else '')

# One line under the pipeline table, and no row: /ck:proof is not a step of the pipeline.
nxt = pathlib.Path('skills/next/SKILL.md').read_text(encoding='utf-8')
say('/ck:next names /ck:proof in a line under the pipeline table',
    '' if any('/ck:proof' in line for line in nxt.split('\n') if not line.startswith('|')) else 'no line of skills/next/SKILL.md outside a table names /ck:proof')

manifest = json.loads(pathlib.Path('.claude-plugin/plugin.json').read_text(encoding='utf-8'))
version = tuple(int(part) for part in re.findall(r'\d+', manifest.get('version', '0')))
say("the plugin's version is past 0.1.10, and its description names /ck:proof",
    f'the version is still {manifest.get("version")}' if version <= (0, 1, 10)
    else '' if '/ck:proof' in manifest.get('description', '') else 'the description does not name /ck:proof')
print('end')
EOF
