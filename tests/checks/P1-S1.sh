# tests/checks/P1-S1.sh: the checks for stage P1-S1, Build the publish guard.
#
# Written in stage P0-S1, before the work, and moved here when the work was done. Section 21 of
# tests/run.sh says how this file is run and what it may use. Tighten a check when the work shows
# it is too weak. Never loosen one.
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

# The pattern was any reason; the stage that built the guard made it the reason at the link's end.
check "a link inside the repository is refused when it leads out of it, or to a file git ignores" \
  "$(refused docs/note/linked-out.md "$in_repo")" "$(refused docs/note/linked-ignored.md ignore)"

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

# ─── Added by the stage that built the guard ─────────────────────────────────
# Each check below pins a choice the guard made that the checks above leave open, so that a
# later change to it is seen here.

# A path that is not there, and a folder, are refused like any other file: status 1 and one
# sentence, so the command can say it. The guard fails, with neither a yes nor a refusal, only
# when it was not given one file.
no_answer() {  # <arguments>...: prints nothing when the guard stops with a status other than 0 and 1.
  local rc
  [[ -f "$guard" ]] || { printf 'scripts/proof-guard.py is not written'; return; }
  (cd "$repo" && python3 "$guard" "$@") > "$SCRATCH/said" 2>&1; rc=$?
  [[ $rc -ne 0 && $rc -ne 1 ]] || printf 'given "%s" the guard stops with status %s, which is an answer' "$*" "$rc"
}
check "a path that is not there, and a folder, are refused with one sentence, and the guard fails only when it is not given one file" \
  "$(refused docs/note/missing.md 'not there')" "$(refused docs/note folder)" \
  "$(no_answer)" "$(no_answer README.md docs/note/draft.md)" "$(no_answer --help)"

# Where a path leads counts: an absolute path, and one that wanders, lead to the same file as the
# plain one; a link to a folder is followed like a link to a file; and a link is judged by the
# file at its end, whatever the link itself is named.
ln -s ../../private "$repo/docs/note/linked-folder"
ln -s notes.txt "$repo/docs/note/linked-txt.md"
ln -s nowhere.md "$repo/docs/note/linked-gone.md"
check "a file inside the repository is accepted by an absolute path, and by one that wanders" \
  "$(accepted "$repo/README.md")" "$(accepted ./docs/../README.md)"
check "a link is followed wherever it stands on the path, and judged by the file at its end" \
  "$(refused docs/note/linked-folder/plan.md ignore)" "$(refused docs/note/linked-txt.md 'markdown|\.md')" \
  "$(refused docs/note/linked-gone.md 'not there')"

# A byte order mark is not a word. And the sentence is one line whatever the path holds, so a
# name with a line break in it is shown on one.
printf '\xef\xbb\xbf' > "$repo/docs/note/bom.md"
: > "$repo/docs/note/two"$'\n'"lines.md"
check "a file that holds only a byte order mark is empty, and the sentence stays one line when the path holds a line break" \
  "$(refused docs/note/bom.md 'empty|no words|nothing')" "$(refused "docs/note/two"$'\n'"lines.md" 'empty|no words|nothing')"

# docs/plan/ belongs to /ck:plan whole, so a plan deeper inside it is refused too.
mkdir -p "$repo/docs/plan/old"; doc twenty-two > "$repo/docs/plan/old/2026-01-01-pricing.md"
check "a plan anywhere under docs/plan/ is refused, and the sentence names /ck:plan" \
  "$(refused docs/plan/old/2026-01-01-pricing.md '/ck:plan([^a-z-]|$)')"

# On a file system that ignores case, docs/prd.md leads to docs/PRD.md, and where a path leads
# counts. On one that tells case apart, the other spelling leads nowhere.
spelled() {  # <a path in another case> <the reason when it leads to the file>: like refused.
  if [[ -e "$repo/$1" ]]; then refused "$1" "$2"; else refused "$1" 'not there'; fi
}
check "a path in another case is judged by where it leads on this file system" \
  "$(spelled docs/prd.md '/ck:prd([^a-z-]|$)')" "$(spelled Docs/Plan/2026-10-12-pricing.md '/ck:plan([^a-z-]|$)')" \
  "$(spelled .CK/runs/20261012T000000Z-pricing-proof/review.md '\.ck|cache')"

# .git/ is never published, and git itself does not report a file inside it as ignored.
mkdir -p "$repo/.git/note"; doc twenty-three > "$repo/.git/note/plan.md"
check "a file inside .git/ is refused" "$(refused .git/note/plan.md '\.git')"

# The guard opens a file only to see whether it has words: a file it refuses for where it is, or
# for its name, is never read. These cannot be read at all, and are refused all the same.
doc twenty-four > "$repo/private/sealed.md"; doc twenty-five > "$repo/docs/note/sealed.txt"; doc twenty-six > "$outside/sealed.md"
chmod 000 "$repo/private/sealed.md" "$repo/docs/note/sealed.txt" "$outside/sealed.md"
check "a file refused for where it is, or for its name, is never opened" \
  "$(refused private/sealed.md ignore)" "$(refused docs/note/sealed.txt 'markdown|\.md')" "$(refused ../outside/sealed.md "$in_repo")"
