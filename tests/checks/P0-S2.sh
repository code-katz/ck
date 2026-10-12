# tests/pending/P0-S2.sh: the checks for stage P0-S2, Rename the page to proof.
#
# Written in stage P0-S1, before the work. Section 21 of tests/run.sh says how this file is run
# and what it may use. The stage is done when every check here passes and this file has moved to
# tests/checks/. Tighten a check when the work shows it is too weak. Never loosen one.
#
# Every check here fails until the rename is made. The lines of tests/run.sh that spell the old
# paths are this stage's to change in place, since tests/run.sh is in its Files: sections 8, 11,
# 12, 18, and 19, and the two names above section 21 that every check file reads.
#
# This file spells the old names because it forbids them, so its own search leaves it out.

loop=skills/proof-loop/SKILL.md
renderer=scripts/render-proof.py

# ─── The two files, under their new names ────────────────────────────────────
if [[ ! -f $loop ]]; then fail "the loop skill is at $loop: it is not there"
elif ! grep -qx 'name: proof-loop' "$loop"; then fail "the loop skill is at $loop: its name is not proof-loop"
elif ! grep -qx 'user-invocable: false' "$loop"; then fail "the loop skill is at $loop: it is no longer marked as not for typing"
else ok "the loop skill is at $loop, named proof-loop, and not for typing"; fi

if [[ ! -f $renderer ]]; then fail "the page renderer is at $renderer: it is not there"
elif [[ ! -x $renderer ]]; then fail "the page renderer is at $renderer: it is not executable"
else ok "the page renderer is at $renderer and is executable"; fi

still=()
for old in skills/review-page scripts/render-review.py; do [[ -e $old ]] && still+=("$old"); done
if (( ${#still[@]} == 0 )); then ok "the old skill folder and the old renderer are gone"
else fail "the old skill folder and the old renderer are gone: ${still[*]} is still there"; fi

# Every check file reads the two paths from tests/run.sh, so the suite must name the new ones.
if [[ "$LOOP_SKILL" == "$loop" && "$PAGE_RENDERER" == "$renderer" ]]; then ok "tests/run.sh names the loop skill and the page renderer by their new paths for the check files"
else fail "tests/run.sh names the loop skill and the page renderer by their new paths for the check files: it has $LOOP_SKILL and $PAGE_RENDERER"; fi

# ─── The line above the title ────────────────────────────────────────────────
python3 "$PAGE_RENDERER" --in tests/fixtures/game/docs/PRD.md --out "$SCRATCH/page.html" --title "Fixture PRD" > /dev/null 2>&1
eyebrow=$(grep -oE '<p class="eyebrow">[^<]*</p>' "$SCRATCH/page.html" 2>/dev/null | head -1)
eyebrow=${eyebrow#*>}; eyebrow=${eyebrow%<*}
if [[ "$eyebrow" =~ [Pp]roof && ! "$eyebrow" =~ [Rr]eview ]]; then ok "the line above a proof's title says proof"
else fail "the line above a proof's title says proof: it says '$eyebrow'"; fi

# ─── Every reference follows ─────────────────────────────────────────────────
# The product's own files, and nothing a session or a cache leaves beside them.
product_files() {
  git ls-files -co --exclude-standard -- .claude-plugin .github README.md ROADMAP.md agents docs hooks profiles scripts skills tests tiers.conf workflows 2>/dev/null \
    || find .claude-plugin .github README.md ROADMAP.md agents docs hooks profiles scripts skills tests tiers.conf workflows -type f 2>/dev/null
}
# The old name may stay in the drill logs and the devlog, which are history, in the proposal and the
# plan for this change, which describe the rename, and in this file. File names inside a run folder
# (review.html, review.md, review-1.md) are not the old name, and they stay.
left=()
while IFS= read -r f; do
  case "$f" in
    tests/drill/*|DEVLOG.md) continue ;;
    docs/proposal/2026-10-11-any-document-as-a-proof.md|docs/plan/2026-10-12-any-document-as-a-proof.md) continue ;;
    tests/pending/P0-S2.sh|tests/checks/P0-S2.sh) continue ;;
  esac
  [[ -f "$f" ]] && grep -qiIE '(^|[^A-Za-z])(review-page|render-review|review page)' "$f" && left+=("$f")
done < <(product_files)
if (( ${#left[@]} == 0 )); then ok "the old name is left only in the drill logs, the devlog, and the proposal and plan for this change"
else fail "the old name is left only in the drill logs, the devlog, and the proposal and plan for this change: it is in ${#left[@]} other files (${left[*]:0:6}$( (( ${#left[@]} > 6 )) && printf ' ...'))"; fi

# Two checks in tests/run.sh forbid /ck:do and /ck:start to name the loop skill or its renderer.
# With the old names gone from every file they would pass whatever those skills said, so they
# forbid the new names instead. Each is found by the other word its list holds.
if awk -v q="'" 'index($0, q "close per" q) && index($0, q "proof-loop" q) && index($0, q "render-proof" q) { found = 1 } END { exit !found }' tests/run.sh \
   && awk -v q="'" 'index($0, q "Workflow(" q) && index($0, q "proof-loop" q) { found = 1 } END { exit !found }' tests/run.sh; then
  ok "the two checks that forbade the old names in /ck:do and /ck:start forbid the new ones"
else
  fail "the two checks that forbade the old names in /ck:do and /ck:start forbid the new ones: the lists in sections 18 and 19 of tests/run.sh do not hold 'proof-loop' and 'render-proof'"
fi

if grep -q 'proof-loop' README.md && grep -q 'render-proof\.py' README.md; then ok "the README's layout lists proof-loop and render-proof.py"
else fail "the README's layout lists proof-loop and render-proof.py: one of them is not in README.md"; fi

# ─── What must not change ────────────────────────────────────────────────────
# A run in progress resumes from the files in its run folder, so their names stay as they are.
# Sections 15 and 16 of tests/run.sh hold the names the resume listings read. This holds the loop's.
if [[ ! -f $loop ]]; then fail "the loop skill still writes review.html and review.md in the run folder: $loop is not there"
elif grep -qF '<runDir>/review.html' "$loop" && grep -qF '<runDir>/review.md' "$loop"; then ok "the loop skill still writes review.html and review.md in the run folder"
else fail "the loop skill still writes review.html and review.md in the run folder: $loop no longer names one of them"; fi
