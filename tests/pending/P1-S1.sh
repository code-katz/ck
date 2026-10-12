# tests/pending/P1-S1.sh: the checks for stage P1-S1, Build the publish guard.
#
# Written in stage P0-S1, before the work. Section 21 of tests/run.sh says how this file is run
# and what it may use. The stage is done when every check here passes and this file has moved to
# tests/checks/. Tighten a check when the work shows it is too weak. Never loosen one.
#
# The guard, as these checks read it. It is one command, run inside the project, on one file:
#     python3 scripts/proof-guard.py <file>
#   status 0    The file may be published as a proof.
#   status 1    The file is refused. The command prints one sentence that names the reason, and
#               repeats nothing from inside the file.
#   any other   The guard itself failed. That is never a refusal, and never a yes.
# scripts/plan.py keeps the same three statuses for the same three cases. A path is read from the
# folder the command runs in, and where a path leads counts, not how it is spelled.
#
# The checks fix the reason a sentence names by one or two words of it, and leave the sentence to
# the stage. The repository below is built here, at run time: a file git ignores, and a file
# outside the repository, cannot be committed as fixtures.
#
# Not checked here, and left to the security read (P2-S1): a path that differs from an owned one
# only by case on a file system that ignores case, and a file that is tracked although a rule
# ignores it.

guard="$PWD/scripts/proof-guard.py"
repo="$SCRATCH/repo"
outside="$SCRATCH/outside"
g() { git -c user.name=t -c user.email=t@example.com -c init.defaultBranch=main "$@"; }
# doc <a word>: a document. If the guard repeated a word of it, the word would be known.
doc() { printf '# Pelican harbour ledger\n\nThe quokka counted %s lanterns.\n' "$1"; }

mkdir -p "$repo/docs/note" "$repo/docs/plan" "$repo/private" "$repo/scratch" "$repo/.ck/runs/20261012T000000Z-pricing-proof" "$outside"
: > "$SCRATCH/no-rules"
(
  cd "$repo" && g init -q . || exit
  # Only this repository's own rules decide what is ignored here, on any machine.
  g config core.excludesFile "$SCRATCH/no-rules"
  printf 'private/\n*.local.md\n' > .gitignore
  printf 'scratch/\n' >> .git/info/exclude
  doc nine > README.md
  doc ten > docs/note/2026-10-12-pricing.md
  g add -A && g commit -q -m first
  doc eleven > docs/note/draft.md
  doc twelve > private/plan.md
  doc thirteen > docs/note/keys.local.md
  doc fourteen > scratch/idea.md
  doc fifteen > .ck/runs/20261012T000000Z-pricing-proof/review.md
  doc sixteen > docs/note/notes.txt
  doc seventeen > docs/note/page.html
  : > docs/note/empty.md
  printf '\n  \n\t\n' > docs/note/blank.md
  doc eighteen > docs/plan/2026-10-12-pricing.md
  doc nineteen > "$outside/notes.md"
  ln -s "$outside/notes.md" docs/note/linked-out.md
  ln -s ../../private/plan.md docs/note/linked-ignored.md
) > "$SCRATCH/setup.log" 2>&1

# accepted <file> [<folder to run in>]: prints nothing when the guard says yes to the file.
accepted() {
  local file=$1 dir=${2:-$repo} rc
  [[ -f "$guard" ]] || { printf 'scripts/proof-guard.py is not written'; return; }
  (cd "$dir" && python3 "$guard" "$file") > "$SCRATCH/said" 2>&1; rc=$?
  if [[ $rc -ne 0 ]]; then printf '%s is not accepted (status %s): %s' "$file" "$rc" "$(head -1 "$SCRATCH/said" | cut -c1-90)"; fi
}

# refused <file> <a pattern the sentence must match> [<folder to run in>]: prints nothing when the
# guard refuses the file as it must. Otherwise prints what went wrong.
refused() {
  local file=$1 reason=$2 dir=${3:-$repo} rc lines
  [[ -f "$guard" ]] || { printf 'scripts/proof-guard.py is not written'; return; }
  (cd "$dir" && python3 "$guard" "$file") > "$SCRATCH/said" 2>&1; rc=$?
  lines=$(grep -c '[^[:space:]]' "$SCRATCH/said")
  if [[ $rc -eq 0 ]]; then printf '%s is accepted' "$file"
  elif [[ $rc -ne 1 ]]; then printf 'for %s the guard stops with status %s, not 1: %s' "$file" "$rc" "$(head -1 "$SCRATCH/said" | cut -c1-90)"
  elif [[ $lines -ne 1 ]]; then printf 'for %s the guard prints %s lines, not one sentence' "$file" "$lines"
  elif grep -qiE 'pelican|harbour|ledger|quokka|lantern' "$SCRATCH/said"; then printf 'for %s the guard repeats words from inside the file' "$file"
  elif ! grep -qiE -- "$reason" "$SCRATCH/said"; then printf 'for %s the sentence does not name the reason (%s): %s' "$file" "$reason" "$(head -1 "$SCRATCH/said" | cut -c1-90)"
  fi
}

# check <what must hold> <a reason, or nothing>...: ok when every reason is empty, else the first.
check() {
  local title=$1 why; shift
  for why in "$@"; do [[ -n "$why" ]] && { fail "$title: $why"; return; }; done
  ok "$title"
}

if [[ ! -d "$repo/.git" || ! -L "$repo/docs/note/linked-out.md" ]]; then
  fail "the guard's fixture repository could not be built here: $(tail -1 "$SCRATCH/setup.log")"
fi

# ─── What it says yes to ─────────────────────────────────────────────────────
never_yes=''
if [[ -f "$guard" ]]; then
  for file in docs/note/missing.md docs/note; do
    (cd "$repo" && python3 "$guard" "$file") > /dev/null 2>&1 && never_yes="$file, which is not a file that is there, is accepted"
  done
fi
check "a markdown file in the repository is accepted, committed or not, and a file that is not there never is" \
  "$(accepted docs/note/2026-10-12-pricing.md)" "$(accepted docs/note/draft.md)" "$(accepted README.md)" "$never_yes"

# ─── The refusals, one file to each ──────────────────────────────────────────
in_repo='outside|inside|repositor|project'
check "a file outside the repository is refused, however the path is written and wherever the command runs" \
  "$(refused "$outside/notes.md" "$in_repo")" "$(refused ../outside/notes.md "$in_repo")" \
  "$(refused ../../outside/notes.md "$in_repo" "$repo/docs")" "$(accepted ../README.md "$repo/docs")"

check "a link inside the repository is refused when it leads out of it, or to a file git ignores" \
  "$(refused docs/note/linked-out.md .)" "$(refused docs/note/linked-ignored.md .)"

check "a file that is not markdown is refused" \
  "$(refused docs/note/notes.txt 'markdown|\.md')" "$(refused docs/note/page.html 'markdown|\.md')"

check "a file git ignores is refused, whether .gitignore names it or the repository's own exclude file does" \
  "$(refused private/plan.md ignore)" "$(refused docs/note/keys.local.md ignore)" "$(refused scratch/idea.md ignore)"

# In a fresh clone nothing ignores .ck/: a command writes that rule when it first mints a run.
# So the run cache is refused by its path, and this repository leaves it out of every ignore rule.
check "a file in the run cache is refused, in a repository where no rule ignores the cache" \
  "$( (cd "$repo" && g check-ignore -q .ck/runs/20261012T000000Z-pricing-proof/review.md) && printf 'the fixture is wrong: a rule ignores .ck/ here')" \
  "$(refused .ck/runs/20261012T000000Z-pricing-proof/review.md '\.ck|cache')"

# The line the command says before it publishes names the file's word count and its first
# heading. A file with no words has neither, so it is empty whatever its size.
check "an empty file is refused, and so is a file with no words in it" \
  "$(refused docs/note/empty.md 'empty|no words|nothing')" "$(refused docs/note/blank.md 'empty|no words|nothing')"

# The documents a pipeline command owns are the ones /ck:next looks for, read here from the first
# line of its look, each with the command of the row that writes it. Read at run time, so the
# guard and /ck:next cannot come to disagree unseen.
owned=$(python3 - <<'EOF' 2> /dev/null
import pathlib, re
text = pathlib.Path('skills/next/SKILL.md').read_text()
look = text.split('```bash\n', 1)[1].split('\n', 1)[0]
rows = [[c.strip() for c in line.strip().strip('|').split('|')] for line in text.split('\n') if re.match(r'^\| (\d+|any) \|', line)]
for path in (w for w in look.split() if w.endswith('.md')):
    owner = next((re.search(r'`/ck:([a-z-]+)', r[1]).group(1) for r in rows if '`' + path + '`' in r[3]), '?')
    print(path, owner)
EOF
)
why=''
[[ $(printf '%s\n' "$owned" | grep -c '\.md ') -ge 9 ]] || why="the look in skills/next/SKILL.md lists fewer than nine documents"
while read -r path owner; do
  [[ -z "$why" && -n "$path" ]] || continue
  if [[ "$owner" == '?' ]]; then why="no row of the pipeline table writes $path"; continue; fi
  mkdir -p "$repo/$(dirname "$path")"; doc twenty > "$repo/$path"
  why=$(refused "$path" "/ck:$owner([^a-z-]|\$)")
done <<< "$owned"
check "every document /ck:next looks for is refused, and the sentence names the command that owns it" "$why"

# The two plan paths: the release's plan, and any plan for one piece of work.
doc twenty-one > "$repo/docs/build-plan.md"
check "a staged plan is refused, and the sentence names /ck:plan" \
  "$(refused docs/build-plan.md '/ck:plan([^a-z-]|$)')" "$(refused docs/plan/2026-10-12-pricing.md '/ck:plan([^a-z-]|$)')"
