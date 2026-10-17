#!/usr/bin/env bash
# tests/run.sh: static checks for the ck plugin (PRD section 9, tests 1 to 11), and
# the workflow scripts run with stub agents (section 14, tests/workflows.mjs).
#
# Usage: bash tests/run.sh
#
# Needs Bash 4+, python3 (for JSON and list parsing), and node (for the workflow
# script checks). Runs the skills' exact commands under zsh too when it is installed
# (section 15), and Ruff over the Python when it is installed (section 20). Touches
# nothing outside a temporary directory.
#
# A stage of a staged plan keeps its checks in a file of its own: under tests/checks/ they
# count, and under tests/pending/ they wait for the stage's work (sections 21 and 22).

set -uo pipefail

if [[ -z "${BASH_VERSINFO:-}" ]] || (( BASH_VERSINFO[0] < 4 )); then
  echo "error: tests/run.sh requires Bash 4 or newer (this is ${BASH_VERSION:-not bash})." >&2
  echo "macOS ships Bash 3.2; install a current Bash with: brew install bash" >&2
  exit 1
fi
for tool in python3 node; do
  if ! command -v "$tool" >/dev/null 2>&1; then
    echo "error: tests/run.sh needs $tool on PATH." >&2
    exit 1
  fi
done

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO_DIR" || exit 1
TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT

PASS=0
FAIL=0
ERRORS=()
ok()   { PASS=$((PASS + 1)); printf "  \033[32m✓\033[0m %s\n" "$1"; }
fail() { FAIL=$((FAIL + 1)); ERRORS+=("$1"); printf "  \033[31m✗\033[0m %s\n" "$1"; }
# A line that is not a check: something could not run here, or there was nothing to run. It is
# not counted, and it is never silent.
note() { printf "  \033[33m-\033[0m %s\n" "$1"; }
section() { printf "\n\033[1m%s\033[0m\n" "$1"; }

# banner_steps <page>: the comment steps in a page's banner, one line each, as a reader sees them
# (tags dropped, entities read). Sections 12 and 13 count them, and the check files compare them
# with tests/fixtures/proof/comment-steps.txt.
banner_steps() {
  python3 - "$1" <<'EOF'
import html, re, sys
page = open(sys.argv[1], encoding='utf-8').read()
steps = re.search(r'<h2>How to comment</h2>\s*<ol>(.*?)</ol>', page, re.S)
for item in re.findall(r'<li[^>]*>(.*?)</li>', steps.group(1) if steps else '', re.S):
    print(' '.join(html.unescape(re.sub(r'<[^>]+>', '', item)).split()))
EOF
}

# The persona names, from profiles/, skipping the generated roster.
personas=()
for p in profiles/*.md; do
  n=$(basename "$p" .md)
  [[ "$n" == "ROSTER" ]] && continue
  personas+=("$n")
done

# ─── 1. Manifest ─────────────────────────────────────────────────────────────
section "1. Manifest"
if python3 - <<'EOF'
import json, re, sys
d = json.load(open('.claude-plugin/plugin.json'))
assert d.get('name') == 'ck', d.get('name')
assert re.fullmatch(r'\d+\.\d+\.\d+', d.get('version', '')), d.get('version')
EOF
then ok "plugin.json parses, name is ck, version is semver"; else fail "plugin.json manifest"; fi

# ─── 2. Drift ────────────────────────────────────────────────────────────────
section "2. Generated files match profiles/ and tiers.conf"
if OUT_DIR="$TMP/gen" bash scripts/generate.sh >/dev/null 2>"$TMP/gen.err"; then
  ok "generate.sh runs into a scratch directory"
else
  fail "generate.sh failed: $(cat "$TMP/gen.err")"
fi
stale=()
for n in "${personas[@]}"; do
  diff -q "agents/$n.md" "$TMP/gen/agents/$n.md" >/dev/null 2>&1 || stale+=("agents/$n.md")
  diff -q "skills/$n/SKILL.md" "$TMP/gen/skills/$n/SKILL.md" >/dev/null 2>&1 || stale+=("skills/$n/SKILL.md")
done
diff -q profiles/ROSTER.md "$TMP/gen/profiles/ROSTER.md" >/dev/null 2>&1 || stale+=("profiles/ROSTER.md")
diff -q skills/roster/SKILL.md "$TMP/gen/skills/roster/SKILL.md" >/dev/null 2>&1 || stale+=("skills/roster/SKILL.md")
if (( ${#stale[@]} == 0 )); then ok "no drift between profiles/ and the committed generated files"; else fail "stale generated files: ${stale[*]} (run bash scripts/generate.sh)"; fi

# ─── 3. Counts ───────────────────────────────────────────────────────────────
section "3. Counts"
agent_count=$(ls agents/*.md 2>/dev/null | wc -l | tr -d ' ')
skill_count=0
for n in "${personas[@]}"; do [[ -f "skills/$n/SKILL.md" ]] && skill_count=$((skill_count + 1)); done
roster_rows=$(grep -c '^| [a-z]' profiles/ROSTER.md 2>/dev/null)
if [[ "$agent_count" == "${#personas[@]}" && "$skill_count" == "${#personas[@]}" && "$roster_rows" == "${#personas[@]}" ]]; then
  ok "${#personas[@]} profiles, $agent_count agents, $skill_count switch skills, $roster_rows roster rows"
else
  fail "counts differ: ${#personas[@]} profiles, $agent_count agents, $skill_count switch skills, $roster_rows roster rows"
fi

# ─── 4. Per persona ──────────────────────────────────────────────────────────
section "4. Each agent and switch skill"
preamble='You are running with no user present.'
switch_line='for the rest of this session. You run on this session'
bad=()
for n in "${personas[@]}"; do
  a="agents/$n.md"; s="skills/$n/SKILL.md"
  tier=$(awk -v p="$n" '$1 == p { print $2; exit }' tiers.conf)
  grep -qx "model: $tier" "$a"            || bad+=("$a: model is not the tiers.conf value ($tier)")
  grep -qx "name: $n" "$a"                || bad+=("$a: name is not $n")
  grep -q '^name: .*:' "$a"               && bad+=("$a: name contains a colon")
  grep -qx '## Handoff Brief' "$a"        || bad+=("$a: no Handoff Brief")
  grep -qx '## Greeting' "$a"             && bad+=("$a: Greeting present")
  grep -qF "$preamble" "$a"               || bad+=("$a: subagent preamble missing")
  grep -qx '## Required Behaviors (subagent form)' "$a" || bad+=("$a: behaviors heading not renamed")
  grep -q '^effort:' "$a"                 && bad+=("$a: effort line present")
  grep -qx '## Required Interactive Behaviors' "$s" || bad+=("$s: interactive behaviors missing")
  grep -qx '## Greeting' "$s"             || bad+=("$s: Greeting missing")
  grep -qF "$switch_line" "$s"            || bad+=("$s: switch sentence missing")
  grep -qx 'disable-model-invocation: true' "$s" || bad+=("$s: not user-only")
done
if (( ${#bad[@]} == 0 )); then ok "every agent is on its tier, renamed, trailered; every switch skill is verbatim"; else for b in "${bad[@]}"; do fail "$b"; done; fi

# ─── 5. Tiers ────────────────────────────────────────────────────────────────
section "5. tiers.conf"
tier_lines=$(grep -cE '^[a-z]+ claude-' tiers.conf)
fable=$(grep -c ' claude-fable-5-1$' tiers.conf)
opus=$(grep -c ' claude-opus-5-5$' tiers.conf)
sonnet=$(grep -c ' claude-sonnet-5-5$' tiers.conf)
if [[ "$tier_lines" == "${#personas[@]}" ]]; then ok "one tier line per persona ($tier_lines)"; else fail "tiers.conf has $tier_lines persona lines, expected ${#personas[@]}"; fi
if [[ "$fable" == 6 && "$opus" == 11 && "$sonnet" == 4 ]]; then ok "six Fable 5.1, eleven Opus 5.5, four Sonnet 5.5"; else fail "tier counts: $fable Fable, $opus Opus, $sonnet Sonnet"; fi
unknown=$(grep -E '^[a-z]+ ' tiers.conf | awk '{print $1}' | while read -r n; do [[ -f "profiles/$n.md" ]] || echo "$n"; done)
if [[ -z "$unknown" ]]; then ok "every tier line names a profile"; else fail "tier lines without a profile: $unknown"; fi
other=$(grep -E '^[a-z]+ ' tiers.conf | grep -vE ' claude-(fable-5-1|opus-5-5|sonnet-5-5)$' || true)
if [[ -z "$other" ]]; then ok "every model is one of the three tier IDs"; else fail "unexpected models: $other"; fi

# ─── 6. River's behaviors in the interactive skills ─────────────────────────
section "6. River's three behaviors"
mapfile -t river_headings < <(grep -E '^### [0-9]+\. ' profiles/river.md)
for f in skills/prd/SKILL.md skills/river/SKILL.md; do
  missing=()
  for h in "${river_headings[@]}"; do grep -qxF "$h" "$f" || missing+=("$h"); done
  if (( ${#missing[@]} == 0 )); then ok "$f carries ${#river_headings[@]} behavior headings from profiles/river.md"; else fail "$f is missing: ${missing[*]}"; fi
done

# ─── 7. Contract sections equal script sections ─────────────────────────────
section "7. Contracts and scripts agree on section order"
if python3 - <<'EOF'
import re, sys, pathlib
def contract_sections(path, part=None):
    text = pathlib.Path(path).read_text()
    if part: text = text.split('# Part ' + part, 1)[1]
    body = text.split('## Section order', 1)[1].split('## Checklist', 1)[0] if '## Section order' in text else ''
    return re.findall(r'^\d+\. `## (.+?)`', body, re.M)
def js_list(text):
    return re.findall(r"'((?:[^'\\]|\\.)*)'", text)
problems = []
# brief.js and team.js declare SECTIONS
for script, contract in (('workflows/brief-draft.js', 'skills/brief-artifact/SKILL.md'), ('workflows/team-draft.js', 'skills/team-artifact/SKILL.md'), ('workflows/opportunity-draft.js', 'skills/opportunity-artifact/SKILL.md'), ('workflows/market-research-draft.js', 'skills/market-research-artifact/SKILL.md'), ('workflows/plan-draft.js', 'skills/plan-artifact/SKILL.md')):
    js = pathlib.Path(script).read_text()
    m = re.search(r'const SECTIONS = \[(.*?)\]', js, re.S)
    got = js_list(m.group(1)) if m else []
    want = contract_sections(contract)
    if got != want: problems.append(f'{script} vs {contract}: script {got} contract {want}')
# draft.js declares sections per artifact
js = pathlib.Path('workflows/draft.js').read_text()
for art, contract in (('prd', 'skills/prd-artifact/SKILL.md'), ('architecture', 'skills/architecture-artifact/SKILL.md')):
    m = re.search(art + r": \{.*?sections: \[(.*?)\]", js, re.S)
    got = js_list(m.group(1)) if m else []
    want = contract_sections(contract)
    if got != want: problems.append(f'draft.js[{art}] vs {contract}: script {got} contract {want}')
# brand.js declares the record's and the guide's sections
js = pathlib.Path('workflows/brand.js').read_text()
for const, part in (('RECORD_SECTIONS', 'A'), ('GUIDE_SECTIONS', 'B')):
    m = re.search(r'const ' + const + r' = \[(.*?)\]', js, re.S)
    got = js_list(m.group(1)) if m else []
    want = contract_sections('skills/brand-artifact/SKILL.md', part)
    if got != want: problems.append(f'brand.js[{const}] vs brand-artifact Part {part}: script {got} contract {want}')
# design-round.js declares the spec's sections
js = pathlib.Path('workflows/design-round.js').read_text()
m = re.search(r'const SPEC_SECTIONS = \[(.*?)\]', js, re.S)
got = js_list(m.group(1)) if m else []
want = contract_sections('skills/design-spec-artifact/SKILL.md')
if got != want: problems.append(f'design-round.js[SPEC_SECTIONS] vs design-spec-artifact: script {got} contract {want}')
for p in problems: print(p, file=sys.stderr)
sys.exit(1 if problems else 0)
EOF
then ok "brief, team, opportunity, market-research, prd, architecture, brand, and design spec section lists match their contracts"; else fail "contract and script section lists differ (see above)"; fi

# ─── 8. Gate-owning skills reference proof-loop ──────────────────────────────
section "8. Gate mechanics live in one place"
for f in skills/plan/SKILL.md skills/brief/SKILL.md skills/team/SKILL.md skills/roadmap/SKILL.md skills/market-research/SKILL.md skills/prd/SKILL.md skills/architecture/SKILL.md skills/opportunity/SKILL.md skills/brand-guide/SKILL.md skills/design/SKILL.md; do
  if grep -q 'proof-loop/SKILL.md' "$f"; then ok "$f references skills/proof-loop/SKILL.md"; else fail "$f does not reference proof-loop"; fi
  if grep -qi 'comment mode' "$f"; then fail "$f restates the comment steps"; else ok "$f does not restate the comment steps"; fi
done

# ─── 9. Workflow scripts ─────────────────────────────────────────────────────
section "9. Workflow scripts"
for f in workflows/*.js; do
  name=$(basename "$f" .js)
  # Scripts use top-level return and await; check them the way the runtime runs them.
  awk '!done && /^export const meta/ { sub(/^export /, ""); done = 1 } { print }' "$f" > "$TMP/$name.body.js"
  { printf '(async () => {\n'; cat "$TMP/$name.body.js"; printf '\n})()\n'; } > "$TMP/$name.wrapped.mjs"
  if node --check "$TMP/$name.wrapped.mjs" 2>"$TMP/$name.err"; then ok "$f parses as the runtime runs it"; else fail "$f: $(head -3 "$TMP/$name.err" | tr '\n' ' ')"; fi
  first=$(grep -m1 -vE '^\s*(//.*)?$' "$f")
  if [[ "$first" == "export const meta = {"* ]]; then ok "$f starts with export const meta"; else fail "$f does not start with export const meta"; fi
  if python3 - "$f" <<'EOF'
import re, sys, pathlib
text = pathlib.Path(sys.argv[1]).read_text()
meta = text.split('\n}\n', 1)[0]
for k in ('name', 'description', 'phases', 'personas'):
    assert re.search(r'^\s*' + k + r':', meta, re.M), k
m = re.search(r'personas: \[(.*?)\]', meta, re.S)
for p in re.findall(r"'([a-z]+)'", m.group(1)):
    assert pathlib.Path(f'profiles/{p}.md').exists(), p
EOF
  then ok "$f meta has name, description, phases, personas, and every persona has a profile"; else fail "$f meta is incomplete or names an unknown persona"; fi
  if grep -nE 'Date\.now|Math\.random|new Date\(\)|require\(|import\(' "$f" >/dev/null; then fail "$f uses a forbidden call"; else ok "$f uses no forbidden call"; fi
  # Every nested workflow and contract it names must exist.
  for w in $(grep -oE "workflow\('ck:[a-z-]+'" "$f" | sed "s/workflow('ck://; s/'//"); do
    [[ -f "workflows/$w.js" ]] && ok "$f nests workflows/$w.js, which exists" || fail "$f nests ck:$w, which has no script"
  done
  for c in $(grep -oE 'skills/[a-z-]+-artifact/SKILL\.md' "$f" | sort -u); do
    [[ -f "$c" ]] && ok "$f reads $c, which exists" || fail "$f reads $c, which is missing"
  done
  for c in $(grep -oE 'skill ck:[a-z-]+' "$f" | sed 's/skill ck://' | sort -u); do
    [[ -f "skills/$c/SKILL.md" ]] && ok "$f loads the skill ck:$c, which exists" || fail "$f loads the skill ck:$c, which is missing"
  done
done

# Every validator that judges a capped document counts it with wc first.
for f in workflows/brief-draft.js workflows/team-draft.js workflows/market-research-draft.js workflows/opportunity-draft.js workflows/draft.js workflows/design-round.js; do
  if grep -q 'wc -w' "$f"; then ok "$f: the validator counts words with wc"; else fail "$f: no validator counts words with wc"; fi
done
for f in workflows/brand.js workflows/design-round.js; do
  if grep -q "'@claude' appears" "$f"; then fail "$f checks the gallery banner for @claude, which the renderer no longer writes"; else ok "$f does not look for @claude in the banner"; fi
done

# ─── 10. Hooks ───────────────────────────────────────────────────────────────
section "10. Hooks"
if python3 - <<'EOF'
import json
d = json.load(open('hooks/hooks.json'))
assert d['hooks']['SubagentStart'][0]['matcher'] == '^ck:'
assert 'SessionStart' in d['hooks']
EOF
then ok "hooks.json parses; SubagentStart matcher is ^ck:; SessionStart present"; else fail "hooks.json"; fi
for s in scripts/*.sh; do bash -n "$s" && [[ -x "$s" ]] && ok "$s parses and is executable" || fail "$s does not parse or is not executable"; done
export CLAUDE_PLUGIN_DATA="$TMP/data"
printf '{"session_id":"s1","agent_id":"a1","agent_type":"ck:river","cwd":"/x","hook_event_name":"SubagentStart"}' | bash scripts/usage-log.sh; rc=$?
if [[ $rc -eq 0 ]] && [[ $(wc -l < "$TMP/data/usage.jsonl") -eq 1 ]] && python3 -c 'import json,sys; d=json.loads(open(sys.argv[1]).read()); assert d.get("agent_type")=="ck:river" or "raw" in d' "$TMP/data/usage.jsonl"; then
  ok "usage-log.sh appends one valid JSON line and exits 0"
else
  fail "usage-log.sh: exit $rc, $(cat "$TMP/data/usage.jsonl" 2>/dev/null)"
fi
printf 'not json at all' | bash scripts/usage-log.sh; rc=$?
[[ $rc -eq 0 && $(wc -l < "$TMP/data/usage.jsonl") -eq 2 ]] && ok "usage-log.sh survives garbage input" || fail "usage-log.sh on garbage: exit $rc"
mkdir -p "$TMP/home/.claude/team"
out=$(HOME="$TMP/home" bash scripts/check-prereqs.sh </dev/null); rc=$?
[[ $rc -eq 0 && "$out" == *"old team tool"* ]] && ok "check-prereqs.sh warns when the old tool is present" || fail "check-prereqs.sh with the old tool present: exit $rc, output '$out'"
mkdir -p "$TMP/home2"
out=$(HOME="$TMP/home2" bash scripts/check-prereqs.sh </dev/null); rc=$?
[[ $rc -eq 0 && -z "$out" ]] && ok "check-prereqs.sh is silent when it is absent" || fail "check-prereqs.sh with a clean home: exit $rc, output '$out'"

# ─── 11. House style ─────────────────────────────────────────────────────────
section "11. House style in user-facing skills"
for f in skills/next/SKILL.md skills/do/SKILL.md skills/plan/SKILL.md skills/start/SKILL.md skills/brief/SKILL.md skills/team/SKILL.md skills/roadmap/SKILL.md skills/market-research/SKILL.md skills/prd/SKILL.md skills/architecture/SKILL.md skills/opportunity/SKILL.md skills/brand-guide/SKILL.md skills/design/SKILL.md skills/proof-loop/SKILL.md; do
  prose=$(awk '/^```/ { fence = !fence; next } !fence' "$f")
  if printf '%s' "$prose" | grep -qiE '[0-9][0-9,.]*k? tokens'; then fail "$f prints a token count"; else ok "$f prints no token count"; fi
  if printf '%s' "$prose" | grep -q '—'; then fail "$f has an em-dash in prose"; else ok "$f has no em-dash in prose"; fi
done
for f in skills/*-artifact/SKILL.md; do
  prose=$(awk '/^```/ { fence = !fence; next } !fence' "$f")
  if printf '%s' "$prose" | grep -q '—'; then fail "$f has an em-dash in prose"; else ok "$f has no em-dash in prose"; fi
done

# ─── 12. Proof renderer ──────────────────────────────────────────────────────
section "12. Proof renderer"
if python3 scripts/render-proof.py --in tests/fixtures/game/docs/PRD.md --out "$TMP/review.html" --title "Fixture PRD" --question "What went wrong?" >/dev/null 2>"$TMP/rr.err"; then
  ok "render-proof.py renders the fixture PRD"
  h_src=$(grep -cE '^##+ ' tests/fixtures/game/docs/PRD.md); h_out=$(grep -o '<h[234] id=' "$TMP/review.html" | wc -l | tr -d ' ')
  [[ "$h_src" == "$h_out" ]] && ok "every heading is on the page ($h_out)" || fail "headings: $h_src in the source, $h_out on the page"
  # What the steps say is checked in the check file of the stage that writes them, P1-S0.sh, and the
  # check for the old third step that stood here moved there. What stays holds for any wording.
  [[ $(banner_steps "$TMP/review.html" 2>/dev/null | wc -l) -eq 4 ]] && grep -q 'comment mode' "$TMP/review.html" && ! grep -q '@claude' "$TMP/review.html" && ok "the banner carries four comment steps, with comment mode in them and @claude in none" || fail "banner steps missing"
  grep -q 'What went wrong?' "$TMP/review.html" && ok "the gate's question is in the banner" || fail "question missing"
  grep -q '<div class="table-wrap"><table>' "$TMP/review.html" && ok "tables scroll in their own container" || fail "table wrapper missing"
else
  fail "render-proof.py failed: $(cat "$TMP/rr.err")"
fi
printf '# T\n\n**Bold with `code` inside.** Plain `code` and *em*.\n' > "$TMP/bold.md"
if python3 scripts/render-proof.py --in "$TMP/bold.md" --out "$TMP/bold.html" --title "Bold" >/dev/null 2>&1 \
   && grep -q '<strong>Bold with <code>code</code> inside.</strong>' "$TMP/bold.html" && ! grep -q '\*\*' "$TMP/bold.html"; then
  ok "render-proof.py renders a bold phrase that contains a code span"
else
  fail "render-proof.py leaves literal ** around a bold phrase with a code span"
fi
printf '# T\n\n```mermaid\nsequenceDiagram\n  A->>B: hi\n```\n' > "$TMP/mm.md"
if python3 scripts/render-proof.py --in "$TMP/mm.md" --out "$TMP/mm.html" --title "MM" >/dev/null 2>&1 \
   && grep -q '<pre class="mermaid">' "$TMP/mm.html" && grep -q 'cdnjs.cloudflare.com/ajax/libs/mermaid' "$TMP/mm.html"; then
  ok "render-proof.py draws a mermaid fence and loads the library"
else
  fail "render-proof.py does not render mermaid fences"
fi
if grep -q 'libs/mermaid' "$TMP/bold.html"; then fail "render-proof.py loads mermaid on a page without a diagram"; else ok "render-proof.py loads mermaid only when a page has a diagram"; fi

# ─── 13. Gallery renderer ────────────────────────────────────────────────────
section "13. Gallery renderer"
if python3 scripts/render-gallery.py --in tests/fixtures/gallery/brand.json --out "$TMP/gallery.html" >/dev/null 2>"$TMP/rg.err"; then
  ok "render-gallery.py renders the brand fixture from one JSON file"
  [[ $(grep -c 'class="variant"' "$TMP/gallery.html") -eq 2 ]] && grep -q 'id="variant-A"' "$TMP/gallery.html" && grep -q 'id="variant-B"' "$TMP/gallery.html" && ok "two variants, labeled A and B, with matching ids" || fail "variant sections or ids missing"
  # As in section 12: what the steps say, and the check for the old third step, are in P1-S2.sh.
  [[ $(banner_steps "$TMP/gallery.html" 2>/dev/null | wc -l) -eq 4 ]] && grep -q 'comment mode' "$TMP/gallery.html" && ! grep -q '@claude' "$TMP/gallery.html" && ok "the banner carries four comment steps, with comment mode in them and @claude in none" || fail "banner steps missing"
  parts_ok=1
  for part in 'class="mark"' 'class="swatches"' 'class="specimen"' 'class="frame"' '<h3>Rationale</h3>' '<h3>Trade-off</h3>' '<h3>Satisfies</h3>'; do
    [[ $(grep -o "$part" "$TMP/gallery.html" | wc -l | tr -d ' ') -eq 2 ]] || { fail "each variant should have $part once"; parts_ok=0; }
  done
  [[ $parts_ok -eq 1 ]] && ok "every variant has the mark, palette, type, surface, rationale, trade-off, and satisfies parts"
  [[ -z "$(grep -oE '(src|href)="https?://[^"]+' "$TMP/gallery.html" | grep -v fonts.g)" ]] && ok "no external references other than Google Fonts" || fail "external reference found"
else
  fail "render-gallery.py --in failed: $(cat "$TMP/rg.err")"
fi
if python3 scripts/render-gallery.py --dir tests/fixtures/gallery/dir --out "$TMP/gallery2.html" >/dev/null 2>"$TMP/rg2.err"; then
  ok "render-gallery.py renders a round directory (variants.json plus the authors' files)"
  grep -q 'icon.svg' "$TMP/gallery2.html" && ok "an extra SVG in a variant's folder becomes an asset tile" || fail "asset tile missing"
  grep -q '<?xml' "$TMP/gallery2.html" && fail "an XML prolog leaked into the page" || ok "XML prologs are stripped from inlined SVG"
  [[ $(grep -o '<span>quiet</span>' "$TMP/gallery2.html" | wc -l | tr -d ' ') -eq 1 && -z "$(grep -o '<span>q</span>' "$TMP/gallery2.html")" ]] && ok "a mood written as one string is split on commas, not letters" || fail "string mood not split on commas"
else
  fail "render-gallery.py --dir failed: $(cat "$TMP/rg2.err")"
fi
if python3 scripts/render-gallery.py --dir tests/fixtures/gallery/design --out "$TMP/gallery5.html" >/dev/null 2>"$TMP/rg5.err"; then
  ok "render-gallery.py renders a design round (screens and states from the authors' files)"
  [[ $(grep -o 'class="device' "$TMP/gallery5.html" | wc -l | tr -d ' ') -eq 2 && $(grep -c '<h3>States</h3>' "$TMP/gallery5.html") -eq 2 ]] && ok "every design variant has its device frame and its states row" || fail "device frames or states rows missing"
  grep -q 'device desktop' "$TMP/gallery5.html" && ok "a screen can ask for a desktop frame" || fail "desktop frame missing"
  grep -q 'Neutral skin' "$TMP/gallery5.html" && grep -q '/ck:brand-guide' "$TMP/gallery5.html" && ok "the banner carries the skin note and names /ck:brand-guide" || fail "skin note missing"
  if python3 scripts/render-gallery.py --dir tests/fixtures/gallery/design --chosen B --out "$TMP/chosen.html" >/dev/null 2>"$TMP/rg6.err"; then
    [[ $(grep -c 'class="variant"' "$TMP/chosen.html") -eq 1 && $(grep -c '· success' "$TMP/chosen.html") -eq 1 ]] && ! grep -q 'comment mode' "$TMP/chosen.html" && ok "--chosen renders one variant with its success state and no comment steps" || fail "--chosen output is wrong"
  else
    fail "render-gallery.py --chosen failed: $(cat "$TMP/rg6.err")"
  fi
else
  fail "render-gallery.py --dir (design) failed: $(cat "$TMP/rg5.err")"
fi
mkdir -p "$TMP/badround/A" && cp tests/fixtures/gallery/dir/variants.json "$TMP/badround/"
if python3 scripts/render-gallery.py --dir "$TMP/badround" --out "$TMP/gallery3.html" >/dev/null 2>"$TMP/rg3.err"; then fail "render-gallery.py should refuse a round with missing author files"; else grep -q 'mark.svg' "$TMP/rg3.err" && ok "a missing author file is refused and named" || fail "the refusal does not name the file"; fi
printf '{"product":"x","kind":"brand","variants":[{"label":"B","name":"n"}]}' > "$TMP/badlabels.json"
python3 scripts/render-gallery.py --in "$TMP/badlabels.json" --out "$TMP/gallery4.html" >/dev/null 2>&1 && fail "render-gallery.py should refuse labels that do not start at A" || ok "labels that do not run from A are refused"

# ─── 14. Workflow scripts, run with stub agents ──────────────────────────────
section "14. Workflow scripts, run with stub agents"
# tests/workflows.mjs runs each script as the runtime does, with no model: a stop signal a full answer
# would trip, and a step that cannot be started at, both show up here. One line per check.
node tests/workflows.mjs >"$TMP/wf.out" 2>"$TMP/wf.err"; rc=$?
wf_lines=0
while IFS=$'\t' read -r verdict message; do
  case "$verdict" in
    ok)   ok "$message"; wf_lines=$((wf_lines + 1)) ;;
    fail) fail "$message"; wf_lines=$((wf_lines + 1)) ;;
  esac
done < "$TMP/wf.out"
if [[ $rc -ne 0 || $wf_lines -eq 0 ]]; then fail "tests/workflows.mjs did not run to the end: exit $rc, $(head -3 "$TMP/wf.err" | tr '\n' ' ')"; fi

# ─── 15. Exact commands ──────────────────────────────────────────────────────
section "15. The exact commands in the gate-owning skills"
# A skill that says "exact command" has its output trusted, so the command must run as written
# in the shells Claude Code uses. zsh stops a command whose file pattern matches nothing before
# the command runs, and the files that do exist are never listed.
mkdir -p "$TMP/exact/all" "$TMP/exact/resume" "$TMP/exact/empty"
if python3 - "$TMP/exact" brief team roadmap market-research prd architecture opportunity brand-guide design <<'EOF'
import re, sys, pathlib
out, problems = pathlib.Path(sys.argv[1]), []
for skill in sys.argv[2:]:
    lines = pathlib.Path(f'skills/{skill}/SKILL.md').read_text().split('\n')
    heading, n = '', 0
    for i, line in enumerate(lines):
        if line.startswith('## '): heading = line[3:]
        if 'exact command' not in line: continue
        # The command is the bash fence under the sentence, or the code span after the phrase.
        j = next((k for k in range(i + 1, len(lines)) if lines[k].strip()), i)
        if lines[j] == '```bash':
            cmd = '\n'.join(lines[j + 1:lines.index('```', j + 1)])
        else:
            span = re.search(r'exact commands?[^`]*`([^`]+)`', line)
            cmd = span.group(1) if span else ''
        if not cmd:
            problems.append(f'skills/{skill}/SKILL.md, {heading}: "exact command" with no command after it')
            continue
        n += 1
        if re.search(r'[*?\[]', re.sub(r"'[^']*'|\"[^\"]*\"", '', cmd)):
            problems.append(f'skills/{skill}/SKILL.md, {heading}: a file pattern outside quotes in: {cmd}')
        cmd = cmd.replace('<slug>', 'turn-timer') + '\n'
        (out / 'all' / f'{skill}.{n}.sh').write_text(cmd)
        if 'Resume check' in heading: (out / 'resume' / f'{skill}.sh').write_text(cmd)
for skill in ('brand-guide', 'design'):
    if not (out / 'resume' / f'{skill}.sh').exists(): problems.append(f'skills/{skill}/SKILL.md: no exact command under Resume check')
for p in problems: print(p, file=sys.stderr)
sys.exit(1 if problems else 0)
EOF
then ok "$(ls "$TMP/exact/all" | wc -l | tr -d ' ') exact commands, none with a file pattern for the shell to expand"; else fail "an exact command in a gate-owning skill has a file pattern outside quotes, or is missing (see above)"; fi

# listing_is <shell> <skill> <project> <the state> [<line it must print>...]: the resume listing
# prints those lines and no others, the run folders oldest first, and nothing on stderr.
listing_is() {
  local sh=$1 skill=$2 dir=$3 state=$4; shift 4
  [[ -f "$TMP/exact/resume/$skill.sh" ]] || { fail "$sh: /ck:$skill has no resume listing to run"; return; }
  (cd "$dir" && "$sh" "$TMP/exact/resume/$skill.sh") > "$TMP/listing.out" 2> "$TMP/listing.err"
  if [[ ! -s "$TMP/listing.err" && "$(sort "$TMP/listing.out")" == "$(printf '%s\n' "$@" | sort)" ]] && sed -n '/^\.ck\/runs\//p' "$TMP/listing.out" | sort -c 2>/dev/null; then
    ok "$sh: /ck:$skill, $state"
  else
    fail "$sh: /ck:$skill, $state: the listing printed '$(cat "$TMP/listing.out" "$TMP/listing.err" | tr '\n' ' ')'"
  fi
}
for sh in bash zsh; do
  command -v "$sh" >/dev/null 2>&1 || continue
  loud=()
  for f in "$TMP"/exact/all/*.sh; do
    (cd "$TMP/exact/empty" && "$sh" "$f") > "$TMP/exact.out" 2> "$TMP/exact.err"
    [[ -s "$TMP/exact.out" || -s "$TMP/exact.err" ]] && loud+=("$(basename "$f" .sh) printed '$(cat "$TMP/exact.out" "$TMP/exact.err" | tr '\n' ' ')'")
  done
  if (( ${#loud[@]} == 0 )); then ok "$sh: every exact command prints nothing in an empty project"; else for l in "${loud[@]}"; do fail "$sh: in an empty project, $l"; done; fi

  # /ck:brand-guide: a run folder with no review file yet must not hide the gallery that is waiting.
  p="$TMP/exact/$sh-brand"; run1="$p/.ck/runs/20261001T000000Z-brand"
  mkdir -p "$p/brand/proposals" "$run1"
  touch "$p/brand/proposals/gallery.html" "$run1/run.json"
  listing_is "$sh" brand-guide "$p" "the proposals are waiting for review" 'brand/proposals/gallery.html'
  mkdir -p "$p/brand/finalists" "$p/.ck/runs/20261002T000000Z-turn-timer-design" "$p/.ck/runs/20261003T000000Z-brand"
  touch "$p/brand/finalists/gallery.html" "$run1/review-1.md" "$p/.ck/runs/20261002T000000Z-turn-timer-design/review.md" "$p/.ck/runs/20261003T000000Z-brand/review-1.md"
  listing_is "$sh" brand-guide "$p" "the first review is done: both galleries, the brand reviews oldest run first, no other command's review" \
    'brand/finalists/gallery.html' 'brand/proposals/gallery.html' '.ck/runs/20261001T000000Z-brand/review-1.md' '.ck/runs/20261003T000000Z-brand/review-1.md'
  mkdir -p "$p/docs"; touch "$p/docs/brand-guide.md" "$run1/review-2.md"
  listing_is "$sh" brand-guide "$p" "the guide is written" \
    'brand/finalists/gallery.html' 'brand/proposals/gallery.html' 'docs/brand-guide.md' '.ck/runs/20261001T000000Z-brand/review-1.md' '.ck/runs/20261001T000000Z-brand/review-2.md' '.ck/runs/20261003T000000Z-brand/review-1.md'

  # /ck:design, with turn-timer for <slug>: the same, and another feature's run folder is not this one's,
  # not even a feature whose name ends with this one's.
  p="$TMP/exact/$sh-design"; run1="$p/.ck/runs/20261001T000000Z-turn-timer-design"
  mkdir -p "$p/docs/design/turn-timer" "$run1"
  for other in lobby first-turn-timer; do
    mkdir -p "$p/.ck/runs/20261002T000000Z-$other-design"
    touch "$p/.ck/runs/20261002T000000Z-$other-design/feature.md" "$p/.ck/runs/20261002T000000Z-$other-design/review.md"
  done
  touch "$run1/feature.md"
  listing_is "$sh" design "$p" "the feature is extracted and there is no gallery" '.ck/runs/20261001T000000Z-turn-timer-design/feature.md'
  rm "$run1/feature.md"; touch "$p/docs/design/turn-timer/gallery.html"
  listing_is "$sh" design "$p" "the variants are waiting for review and the run folder is empty" 'docs/design/turn-timer/gallery.html'
  touch "$run1/feature.md" "$run1/review.md" "$p/docs/design/turn-timer/spec.md"
  listing_is "$sh" design "$p" "the spec is written" \
    'docs/design/turn-timer/gallery.html' 'docs/design/turn-timer/spec.md' '.ck/runs/20261001T000000Z-turn-timer-design/feature.md' '.ck/runs/20261001T000000Z-turn-timer-design/review.md'
  # The listing knows a run folder by the name step 3 gives it, so mint one as step 3 does: the two cannot drift apart.
  minted=$(eval "$(awk '/^## 3\. Mint the run$/ { s = 1 } s && /^(timestamp|runId)=/' skills/design/SKILL.md | sed 's/<slug>/turn-timer/g')"; printf '%s' "${runId:-}")
  if [[ "$minted" == *-turn-timer-design ]]; then
    mkdir -p "$p/.ck/runs/$minted"; touch "$p/.ck/runs/$minted/review.md"
    listing_is "$sh" design "$p" "a run named as step 3 names it is listed" \
      'docs/design/turn-timer/gallery.html' 'docs/design/turn-timer/spec.md' '.ck/runs/20261001T000000Z-turn-timer-design/feature.md' '.ck/runs/20261001T000000Z-turn-timer-design/review.md' ".ck/runs/$minted/review.md"
  else
    fail "$sh: /ck:design step 3 mints no run id for the slug (got '$minted')"
  fi
done

# ─── 16. No run record ───────────────────────────────────────────────────────
section "16. A document with no run record"
# A workflow started directly keeps its files in .ck/runs/<name>-latest/ and writes no run.json, and
# .ck/ is a cache that a clone does not have. A finished document with no record goes to the review
# with a new run. The branch is third, after the two that read a record's status and ahead of every
# branch that reads a run folder or launches, and the steps it names are the skill's own.
for pair in brief:docs/brief.md team:docs/TEAM.md roadmap:ROADMAP.md market-research:docs/market-research.md prd:docs/PRD.md architecture:docs/ARCHITECTURE.md opportunity:docs/opportunity.md; do
  f="skills/${pair%%:*}/SKILL.md"
  if python3 - "$f" "${pair%%:*}" "${pair#*:}" <<'EOF' 2>"$TMP/norecord.err"
import re, sys, pathlib
text, cmd, doc = pathlib.Path(sys.argv[1]).read_text(), sys.argv[2], sys.argv[3]
steps = dict(re.findall(r'^## (\d+)\. (.+)$', text, re.M))
resume = re.search(r'^## \d+\. Resume check\n(.*?)^## ', text, re.M | re.S).group(1)
bullets = [l for l in resume.split('\n') if l.startswith('- ')]
assert bullets[0].startswith('- `status` is `final`') and bullets[1].startswith('- `status` is `review`'), 'the first two branches do not read the status'
b = bullets[2]
assert b.startswith(f'- There is no `run.json` with `command: "{cmd}"`'), 'the third branch is not the one for no run record'
assert f'`{doc}`' in b, f'the branch does not name {doc}'
m = re.search(r'launch nothing: mint a run \(step (\d+)\) and go to step (\d+)\.$', b)
assert m, 'the branch does not end by minting a run and going to the review without launching'
assert steps[m.group(1)] == 'Mint the run' and steps[m.group(2)] == 'The review', f'steps {m.group(1)} and {m.group(2)} are not Mint the run and The review'
if cmd in ('prd', 'architecture'):
    # A draft with its premortem still pending is not finished: it resumes at validate, and that needs a run too.
    assert 'its Appendix B has the premortem, not a note that it is pending' in b, 'the branch does not tell a finished document from a draft'
    assert f'or mint a run first (step {m.group(1)}) when there is no run record' in resume, 'resuming a draft with no run record mints no run'
if cmd == 'roadmap':
    # An existing roadmap with no sign of a direct run is updated, as step 1 says; the sign is the workflow's own folder.
    assert '`.ck/runs/roadmap-latest/priorities.json` exists' in b, 'the branch does not look for the direct run'
    js = pathlib.Path('workflows/roadmap-draft.js').read_text()
    assert "'/.ck/runs/roadmap-latest'" in js and 'priorities.json' in js, 'workflows/roadmap-draft.js no longer writes roadmap-latest/priorities.json'
EOF
  then ok "$f: a finished document with no run record goes to the review with a new run, ahead of every branch that launches"; else fail "$f: $(tail -1 "$TMP/norecord.err")"; fi
done

# ─── 17. The pipeline table ──────────────────────────────────────────────────
section "17. The pipeline table in /ck:next"
if python3 - <<'EOF'
import re, sys, pathlib
text = pathlib.Path('skills/next/SKILL.md').read_text()
readme = pathlib.Path('README.md').read_text()
def table(src, header):
    lines = src.split('\n')
    rows = []
    for line in lines[lines.index(header) + 2:]:
        if not line.startswith('|'): break
        rows.append([c.strip() for c in line.strip().strip('|').split('|')])
    return rows
def ticks(cell):
    return re.findall(r'`([^`]+)`', cell)
problems = []
steps = ['opportunity', 'market-research', 'brief', 'team', 'prd', 'roadmap', 'architecture', 'brand-guide', 'design', 'plan']
rows = table(text, '| # | Step | What it does | Writes | Status |')
# One row per step, in the pipeline's order, then the panel.
got = [(r[0], (re.search(r'`/ck:([a-z-]+)', r[1]) or [None, None])[1]) for r in rows]
want = [(str(i + 1), s) for i, s in enumerate(steps)] + [('any', 'panel')]
if got != want: problems.append(f'rows are {got}, expected {want}')
for s in steps:
    if not pathlib.Path(f'skills/{s}/SKILL.md').exists(): problems.append(f'/ck:{s} has no skill')
if not any('optional' in r[1] for r in rows if 'market-research' in r[1]): problems.append('market research is not marked optional')
# One sentence on what each step does; no status filled in.
for r in rows:
    if not r[2].endswith('.') or re.search(r'[.!?] ', r[2]): problems.append(f'not one sentence: {r[2]}')
    if r[4]: problems.append(f'status is filled in the skill for row {r[0]}')
# Every document a row writes is in the README's table of paths, and the other way round.
writes = {p for r in rows for p in ticks(r[3])}
where = {p for r in table(readme, '| Document | Path |') for p in ticks(r[1])}
if writes != where: problems.append(f'Writes and README paths differ: {sorted(writes ^ where)}')
# The look lists every single-file document the table names.
look = text.split('```bash\n', 1)[1].split('```', 1)[0]
for p in sorted(writes):
    if p.endswith('.md') and p not in look.split('\n')[0]: problems.append(f'the look does not list {p}')
# The seven statuses, in the order they are tried.
statuses = [ticks(r[0])[0] for r in table(text, '| Status | When |')]
if statuses != ['running', 'in review', 'stopped partway', 'done', 'next', 'skipped', 'not started']: problems.append(f'statuses are {statuses}')
# Every step can be the next one: a sentence names its command.
says = ' '.join(r[1] for r in table(text, '| State | Say |'))
for s in steps:
    if f'`/ck:{s}' not in says: problems.append(f'no sentence names /ck:{s}')
for p in problems: print(p, file=sys.stderr)
sys.exit(1 if problems else 0)
EOF
then ok "ten steps in order and the panel, one sentence each, paths match the README, seven statuses, every step can be next"; else fail "skills/next/SKILL.md pipeline table (see above)"; fi

# The look runs as written in the shells Claude Code uses: nothing matched is no error and no output.
awk '/^```bash$/ { f = 1; next } /^```$/ { if (f) exit } f' skills/next/SKILL.md > "$TMP/look.sh"
mkdir -p "$TMP/empty" "$TMP/proj"
cp -R tests/fixtures/game/docs "$TMP/proj/docs"
mkdir -p "$TMP/proj/docs/design/turn" "$TMP/proj/docs/design/lobby" "$TMP/proj/.ck/runs/20261001T000000Z-fixture-brief" "$TMP/proj/.ck/runs/20261002T000000Z-fixture" "$TMP/proj/.ck/runs/team-latest"
touch "$TMP/proj/docs/design/turn/gallery.html" "$TMP/proj/docs/design/turn/spec.md" "$TMP/proj/docs/design/lobby/gallery.html"
printf '{\n  "runId": "x",\n  "command": "brief",\n  "status": "final"\n}\n' > "$TMP/proj/.ck/runs/20261001T000000Z-fixture-brief/run.json"
printf '{"runId":"y","command":"prd","status":"review"}' > "$TMP/proj/.ck/runs/20261002T000000Z-fixture/run.json"
printf '{"command": "team", "status": "final"}' > "$TMP/proj/.ck/runs/team-latest/nominations.json"
for sh in bash zsh; do
  command -v "$sh" >/dev/null 2>&1 || continue
  (cd "$TMP/empty" && "$sh" "$TMP/look.sh") > "$TMP/look.out" 2> "$TMP/look.err"
  [[ ! -s "$TMP/look.out" && ! -s "$TMP/look.err" ]] && ok "$sh: the look prints nothing in an empty project" || fail "$sh: the look in an empty project printed: $(cat "$TMP/look.out" "$TMP/look.err")"
  (cd "$TMP/proj" && "$sh" "$TMP/look.sh") > "$TMP/look.out" 2> "$TMP/look.err"
  look_ok=1
  for line in 'docs/brief.md' 'docs/PRD.md' 'docs/design/turn/spec.md' 'docs/design/turn/gallery.html' 'docs/design/lobby/gallery.html' \
              '.ck/runs/20261001T000000Z-fixture-brief/run.json:"command": "brief"' '.ck/runs/20261001T000000Z-fixture-brief/run.json:"status": "final"' \
              '.ck/runs/20261002T000000Z-fixture/run.json:"command":"prd"' '.ck/runs/20261002T000000Z-fixture/run.json:"status":"review"'; do
    grep -qxF -- "$line" "$TMP/look.out" || { fail "$sh: the look does not print $line"; look_ok=0; }
  done
  [[ -s "$TMP/look.err" ]] && { fail "$sh: the look wrote to stderr: $(cat "$TMP/look.err")"; look_ok=0; }
  [[ $(wc -l < "$TMP/look.out" | tr -d ' ') -eq 9 ]] || { fail "$sh: the look printed $(wc -l < "$TMP/look.out" | tr -d ' ') lines, expected 9 (a folder with no run.json is not a record)"; look_ok=0; }
  [[ "$(grep '"command"' "$TMP/look.out" | tail -1)" == *'"prd"' ]] || { fail "$sh: the newest run record is not printed last"; look_ok=0; }
  [[ $look_ok -eq 1 ]] && ok "$sh: the look lists the documents, the designs, and the run records oldest first"
done

# Every gate-owning skill closes with the table by reference, and none restates it.
for f in skills/plan/SKILL.md skills/brief/SKILL.md skills/team/SKILL.md skills/roadmap/SKILL.md skills/market-research/SKILL.md skills/prd/SKILL.md skills/architecture/SKILL.md skills/opportunity/SKILL.md skills/brand-guide/SKILL.md skills/design/SKILL.md; do
  if grep -q 'close per `${CLAUDE_PLUGIN_ROOT}/skills/next/SKILL.md`' "$f"; then ok "$f closes per skills/next/SKILL.md"; else fail "$f does not close per skills/next/SKILL.md"; fi
  if grep -qF '| # | Step |' "$f" || grep -q 'run `/ck:next`' "$f"; then fail "$f restates the pipeline table or sends the reader to /ck:next for it"; else ok "$f does not restate the table or add a hop to /ck:next"; fi
done

# ─── 18. /ck:do ──────────────────────────────────────────────────────────────
section "18. /ck:do, the quick path"
DO=skills/do/SKILL.md
mkdir -p "$TMP/do"
if python3 - "$DO" "$TMP/do" > "$TMP/do/static.out" 2>&1 <<'EOF'
import re, sys, pathlib
t = pathlib.Path(sys.argv[1]).read_text()
out = pathlib.Path(sys.argv[2])
problems = []
front = t.split('---', 2)[1]
for key, pat in (('name: do', r'^name: do$'), ('disable-model-invocation: true', r'^disable-model-invocation: true$'), ('an argument hint', r'^argument-hint: ')):
    if not re.search(pat, front, re.M): problems.append(f'frontmatter lacks {key}')
# Every command it sends the author to exists.
named = set(re.findall(r'/ck:([a-z-]+)', t)) - {'do'}
for n in sorted(named):
    if not (pathlib.Path(f'skills/{n}/SKILL.md').exists() or pathlib.Path(f'workflows/{n}.js').exists()):
        problems.append(f'names /ck:{n}, which is not a command')
for n in ('opportunity', 'market-research', 'brief', 'prd', 'team', 'roadmap', 'architecture', 'brand-guide', 'design', 'panel', 'plan'):
    if n not in named: problems.append(f'does not name /ck:{n} for work that belongs to it')
# Every owner in the step table is on the roster.
personas = {p.stem for p in pathlib.Path('profiles').glob('*.md')} - {'ROSTER'}
rows = [l for l in t.split('\n') if re.match(r'^\| (Draw|Write|Build|Check) \|', l)]
if len(rows) != 4: problems.append(f'the step table has {len(rows)} of its four rows')
for l in rows:
    who = l.split('|')[2]
    if not [w for w in re.findall(r'\b[A-Z][a-z]+\b', who) if w.lower() in personas]:
        problems.append(f'no roster persona owns the {l.split("|")[1].strip()} step')
for name in re.findall(r'\(([A-Z][a-z]+)\)`', t):
    if name.lower() not in personas: problems.append(f'example step name uses {name}, who is not on the roster')
# It is the quick path: no proof, no pipeline record, no pipeline table.
for word in ('proof-loop', 'render-proof', 'run.json', 'close per'):
    if word in t: problems.append(f'mentions {word}; /ck:do publishes no proof and keeps its record in do.json so /ck:next does not read it')
if 'do.json' not in t: problems.append('does not name its record, do.json')
for stop in ('Go?', 'OK, or what should change?', 'Merge into `'):
    if stop not in t: problems.append(f'lacks the stop "{stop}"')
for rule in ('No agent runs before "go"', 'Never merge, push, open a pull request, or discard without the author', 'git reset --hard <base>', 'isolation: "worktree"'):
    if rule not in t: problems.append(f'lacks the rule: {rule}')
# The exact commands, pulled out as section 15 pulls them.
lines, cmds = t.split('\n'), []
for i, line in enumerate(lines):
    if 'exact command' not in line: continue
    j = next((k for k in range(i + 1, len(lines)) if lines[k].strip()), i)
    if lines[j] != '```bash': problems.append(f'"exact command" with no bash block after it: {line[:60]}'); continue
    cmd = '\n'.join(lines[j + 1:lines.index('```', j + 1)])
    if re.search(r'[*?\[]', re.sub(r"'[^']*'|\"[^\"]*\"", '', cmd).replace('[ -n', '')): problems.append(f'a file pattern outside quotes in: {cmd[:80]}')
    cmds.append(cmd)
if len(cmds) != 3: problems.append(f'{len(cmds)} exact commands, expected 3 (look, start, look back)')
for name, cmd in zip(('look', 'start', 'back'), cmds): (out / f'{name}.sh').write_text(cmd.replace('<slug>', 'rulebook-icons') + '\n')
for p in problems: print(p)
sys.exit(1 if problems else 0)
EOF
then ok "skills/do: typed only; every command and persona it names exists; no proof, record in do.json; three stops and four rules present"
else while IFS= read -r l; do fail "skills/do: $l"; done < "$TMP/do/static.out"; fi
if grep -q '^| `/ck:do <task>`' README.md; then ok "README.md has a row for /ck:do"; else fail "README.md has no row for /ck:do"; fi

# The exact commands run as written in both shells, in a repository, a linked worktree, and a plain folder.
do_git() { git -c user.name=t -c user.email=t@example.com -c init.defaultBranch=main "$@"; }
for sh in bash zsh; do
  command -v "$sh" >/dev/null 2>&1 || continue
  [[ -f "$TMP/do/look.sh" && -f "$TMP/do/start.sh" && -f "$TMP/do/back.sh" ]] || { fail "$sh: /ck:do has no exact commands to run"; continue; }
  w="$TMP/do/$sh"; mkdir -p "$w/plain" "$w/repo/docs"
  (cd "$w/plain" && "$sh" "$TMP/do/look.sh") > "$w/out" 2> "$w/err"; rc=$?
  if [[ $rc -eq 0 && ! -s "$w/err" && "$(cat "$w/out")" == $'root: \nbranch: \nuncommitted: 0' ]]; then ok "$sh: the look exits 0 and prints three empty answers in a plain folder"
  else fail "$sh: the look in a plain folder: exit $rc, '$(cat "$w/out" "$w/err" | tr '\n' ' ')'"; fi
  (cd "$w/repo" && do_git init -q && echo x > CLAUDE.md && echo t > docs/TEAM.md && echo p > page.html && do_git add -A && do_git commit -q -m first)
  root="$(cd "$w/repo" && pwd -P)"; base="$(git -C "$w/repo" rev-parse HEAD)"
  (cd "$w/repo" && "$sh" "$TMP/do/look.sh") > "$w/out" 2> "$w/err"; rc=$?
  if [[ $rc -eq 0 && ! -s "$w/err" && "$(cat "$w/out")" == "root: $root"$'\nbranch: main\nuncommitted: 0\nCLAUDE.md\ndocs/TEAM.md' ]]; then ok "$sh: the look prints the root, the branch, a clean count, and the documents that exist"
  else fail "$sh: the look in a repository: exit $rc, '$(cat "$w/out" "$w/err" | tr '\n' ' ')'"; fi
  (cd "$w/repo" && "$sh" "$TMP/do/start.sh" && "$sh" "$TMP/do/start.sh") > "$w/out" 2> "$w/err"; rc=$?
  run="$(sed -n 's/^runDir: //p' "$w/out" | head -1)"; exclude="$w/repo/.git/info/exclude"
  if [[ $rc -eq 0 && ! -s "$w/err" && -d "$run" && "$run" == "$root/.ck/runs/"*"-rulebook-icons-do" && "$(grep -c '^base: '"$base"'$' "$w/out")" == 2 \
        && "$(grep -cxF '.ck/' "$exclude")" == 1 && "$(grep -cxF '.claude/worktrees/' "$exclude")" == 1 && -z "$(git -C "$w/repo" status --porcelain)" ]]; then
    ok "$sh: the start makes the run folder, prints the base, excludes the cache once, and leaves the checkout clean"
  else fail "$sh: the start in a repository: exit $rc, '$(cat "$w/out" "$w/err" | tr '\n' ' ')', exclude '$(tr '\n' ' ' < "$exclude")'"; fi
  do_git -C "$w/repo" worktree add -q --detach "$w/linked" HEAD
  (cd "$w/linked" && "$sh" "$TMP/do/start.sh") > "$w/out" 2> "$w/err"; rc=$?
  if [[ $rc -eq 0 && ! -s "$w/err" && -d "$(sed -n 's/^runDir: //p' "$w/out")" && -z "$(git -C "$w/linked" status --porcelain)" ]]; then ok "$sh: the start works in a linked worktree and leaves it clean"
  else fail "$sh: the start in a linked worktree: exit $rc, '$(cat "$w/out" "$w/err" | tr '\n' ' ')', status '$(git -C "$w/linked" status --porcelain | tr '\n' ' ')'"; fi
  (cd "$w/plain" && "$sh" "$TMP/do/start.sh") > "$w/out" 2> "$w/err"; rc=$?
  if [[ $rc -eq 0 && ! -s "$w/err" && -d "$(sed -n 's/^runDir: //p' "$w/out")" && "$(sed -n 's/^base: //p' "$w/out")" == "" ]]; then ok "$sh: the start works with no repository"
  else fail "$sh: the start with no repository: exit $rc, '$(cat "$w/out" "$w/err" | tr '\n' ' ')'"; fi
  # A build as step 6 describes it: a worktree branch named do/<slug>, one commit on the base.
  do_git -C "$w/repo" worktree add -q "$w/build" -b do/rulebook-icons "$base"
  (cd "$w/build" && echo more >> page.html && do_git commit -q -am "icons beside the headings")
  sed -e "s|<worktree>|$w/build|g" -e "s|<base>|$base|g" "$TMP/do/back.sh" > "$w/back.sh"
  (cd "$w/repo" && "$sh" "$w/back.sh") > "$w/out" 2> "$w/err"; rc=$?
  if [[ $rc -eq 0 && ! -s "$w/err" ]] && grep -qxF 'branch: do/rulebook-icons' "$w/out" && grep -qxF "from base: $base" "$w/out" \
        && grep -q 'icons beside the headings$' "$w/out" && grep -q '1 file changed' "$w/out" && grep -qxF 'uncommitted: 0' "$w/out" && grep -q 'page.html' "$w/out"; then
    ok "$sh: the look back prints the branch, the base it grew from, the commit, the files, and a clean count"
  else fail "$sh: the look back: exit $rc, '$(cat "$w/out" "$w/err" | tr '\n' ' ')'"; fi
done

# ─── 19. The staged plan ─────────────────────────────────────────────────────
section "19. The staged plan: /ck:plan, /ck:start, and scripts/plan.py"
if python3 - > "$TMP/plan-static.out" 2>&1 <<'EOF'
import re, sys, pathlib
problems = []
def front(path):
    return pathlib.Path(path).read_text().split('---', 2)[1]
plan, start = pathlib.Path('skills/plan/SKILL.md').read_text(), pathlib.Path('skills/start/SKILL.md').read_text()
contract = pathlib.Path('skills/plan-artifact/SKILL.md').read_text()
script = pathlib.Path('scripts/plan.py').read_text() if pathlib.Path('scripts/plan.py').exists() else ''
if not script: problems.append('scripts/plan.py is missing')
for name in ('plan', 'start'):
    f = front(f'skills/{name}/SKILL.md')
    for key, pat in ((f'name: {name}', rf'^name: {name}$'), ('disable-model-invocation: true', r'^disable-model-invocation: true$'), ('an argument hint', r'^argument-hint: ')):
        if not re.search(pat, f, re.M): problems.append(f'skills/{name}: frontmatter lacks {key}')
if not re.search(r'^user-invocable: false$', front('skills/plan-artifact/SKILL.md'), re.M): problems.append('skills/plan-artifact is not marked as not for typing')
# Every plan.py command a skill or the workflow runs is one the script has.
used = set(re.findall(r'<plan\.py> ([a-z]+)', plan + start)) | set(re.findall(r'plan\.py" ([a-z]+)', pathlib.Path('workflows/plan-draft.js').read_text()))
for c in sorted(used):
    if not re.search(rf"['\"]{c}['\"]", script): problems.append(f'a skill or the workflow runs plan.py {c}, which the script does not have')
for c in ('find', 'rows', 'ready', 'set', 'board', 'card'):
    if c not in used: problems.append(f'/ck:start or /ck:plan never runs plan.py {c}')
# The words the contract fixes are the words the script knows.
for word in ('running in its session', 'not started; could start now', 'not started; follows', 'design round', 'yours', 'Fable', 'Opus', 'Sonnet', 'Haiku', '| Stage | What | Who | State |'):
    if word not in contract: problems.append(f'the contract lacks "{word}"')
    # The script reads the header by its four cells, so aligned columns still count; it need not hold the row as text.
    if script and not word.startswith('|') and word not in script: problems.append(f'scripts/plan.py lacks "{word}", which the contract fixes')
# /ck:plan: the workflow it launches exists, it reviews on the page, and it approves with the script.
if 'name: "ck:plan-draft"' not in plan or not pathlib.Path('workflows/plan-draft.js').exists(): problems.append('skills/plan does not launch ck:plan-draft, or the workflow is missing')
for need in ('<plan.py> approve', '<plan.py> refresh', '<plan.py> check', 'docs/build-plan.md', 'docs/plan/', 'Run `/ck:roadmap` first', 'plan-before.md', 'git add -- "<the plan>" && git commit -m', 'pass the file as `existing`', 'passes the plan on disk as `existing`'):
    if need not in plan: problems.append(f'skills/plan lacks: {need}')
# /ck:start: cards through the app's tool, a way without it, and its limits.
for need in ('mcp__ccd_session__spawn_task', 'mcp__ccd_session_mgmt__list_sessions', 'mcp__ccd_session_mgmt__set_session_title', 'mcp__ccd_session_mgmt__set_session_model',
             'paste this as its first message', 'you never start one', 'Never mark a row done without a merged pull request or the author', 'Never merge without the author',
             'git-common-dir', 'starts with `[<the row\'s full id>] [`', '[dropped]', 'gh pr checks', 'in its own worktree', 'git add -- "<the plan>" && git commit -m'):
    if need not in start: problems.append(f'skills/start lacks: {need}')
# A fix to a finished stage: the card command as it is run, the model check, and what a fix never does.
for need in ('--fix - --title "<the title>"', "<<'CK_FAULT'", 'stays done on the board', 'It checks its own model before it works', 'Never change a State for a fix',
             'gh pr view <n> --json title', 'back fix',
             # Faults a review confirmed, each held shut by the words that cure it.
             'When a line of the words is exactly `CK_FAULT`, use another word that no line of them equals for both markers',
             'unless `fix` was typed, leave out any plan', "whose title's first brackets hold a row's full id followed by ` fix`",
             'When the fix has a pull request, say `merge` and its number here.', "only when it is a stage's pull request: a fix's is never marked"):
    if need not in start: problems.append(f'skills/start lacks: {need}')
if "<its pull request's number>" in start: problems.append('skills/start promises every fix a pull request number; a fix to a stage that hands back a report opens none')
for word in ('proof-loop', 'run.json', 'Workflow('):
    if word in start: problems.append(f'skills/start mentions {word}; it launches nothing and reviews nothing')
# The script makes the fix card and puts the model check in every card; the contract names a fix's session.
for need in ('check your own model', '--fix'):
    if script and need not in script: problems.append(f'scripts/plan.py lacks: {need}')
if '[A31-P1-S5 fix] [Akira Fable]' not in contract: problems.append('the contract lacks the name of a fix session, "[A31-P1-S5 fix] [Akira Fable]"')
for p in problems: print(p)
sys.exit(1 if problems else 0)
EOF
then ok "skills/plan and skills/start: typed only; every plan.py command they run exists; the contract's fixed words are the script's; cards, the paste fallback, the fix step, the model check, and the limits are there"
else while IFS= read -r l; do fail "the staged plan: $l"; done < "$TMP/plan-static.out"; fi
for row in '| `/ck:plan [work]`' '| `/ck:start [stage]`' '| Staged build plan | `docs/build-plan.md` |'; do
  if grep -qF -- "$row" README.md; then ok "README.md has: $row"; else fail "README.md lacks: $row"; fi
done
start_row="$(grep -F -- '| `/ck:start [stage]`' README.md)"
if [[ "$start_row" == *'fix <stage> <what is wrong>'* ]]; then ok "README.md's row for /ck:start has: fix <stage> <what is wrong>"; else fail "README.md's row for /ck:start lacks: fix <stage> <what is wrong>"; fi
for f in tests/fixtures/plan/project/docs/build-plan.md tests/fixtures/plan/project/docs/plan/2026-10-11-encounter-refactor.md; do
  python3 scripts/plan.py check "$f" > "$TMP/plan-check.out" 2>&1; rc=$?
  if [[ $rc -eq 0 && "$(grep -vc '^words: ' "$TMP/plan-check.out")" == 0 ]]; then ok "plan.py check passes $f"; else fail "plan.py check on $f: exit $rc, $(head -3 "$TMP/plan-check.out" | tr '\n' ' ')"; fi
done
# tests/plan-cases.py was written from the specification by someone who did not write the script.
python3 tests/plan-cases.py > "$TMP/plan-cases.out" 2> "$TMP/plan-cases.err"; rc=$?
pc_lines=0
while IFS=$'\t' read -r verdict message; do
  case "$verdict" in
    ok)   ok "plan.py: $message"; pc_lines=$((pc_lines + 1)) ;;
    fail) fail "plan.py: $message"; pc_lines=$((pc_lines + 1)) ;;
  esac
done < "$TMP/plan-cases.out"
if [[ $rc -ne 0 || $pc_lines -eq 0 ]]; then fail "tests/plan-cases.py did not run to the end: exit $rc, $(head -3 "$TMP/plan-cases.err" | tr '\n' ' ')"; fi

# ─── 20. Lint ────────────────────────────────────────────────────────────────
section "20. Lint"
# Ruff reads ruff.toml: pyflakes and bugbear over the Python in scripts/ and tests/, and any syntax
# newer than the Python macOS ships. An undefined name is found here without a check that happens
# to run the line. The Python inside the heredocs of this file and of the check files is not linted.
if [[ -f ruff.toml ]]; then ok "ruff.toml is present"; else fail "ruff.toml is missing"; fi
if command -v ruff >/dev/null 2>&1; then
  ruff check --no-cache --output-format concise scripts tests > "$TMP/ruff.out" 2>&1; rc=$?
  # A lint that checks no file is clean too, so each file is looked for in the list Ruff works from.
  ruff check --no-cache --show-files scripts tests > "$TMP/ruff.files" 2>/dev/null
  unlinted=()
  for f in scripts/*.py tests/*.py; do
    [[ -f "$f" ]] || continue
    grep -q "/$f\$" "$TMP/ruff.files" || unlinted+=("$f")
  done
  if [[ $rc -ne 0 && $rc -ne 1 ]]; then
    fail "ruff check could not run (exit $rc): $(head -2 "$TMP/ruff.out" | tr '\n' ' ')"
  elif (( ${#unlinted[@]} > 0 )); then
    fail "Ruff does not check ${unlinted[*]}: ruff.toml or an ignore rule leaves it out"
  elif [[ $rc -eq 0 ]]; then
    ok "ruff check scripts tests is clean ($(wc -l < "$TMP/ruff.files" | tr -d ' ') files)"
  else
    fail "ruff check scripts tests: $(grep -cE '^[^ ]+:[0-9]+:[0-9]+: ' "$TMP/ruff.out") finding(s), the first: $(grep -m1 -E '^[^ ]+:[0-9]+:[0-9]+: ' "$TMP/ruff.out")"
  fi
elif [[ -n "${CI:-}" ]]; then
  # On a developer's machine a missing Ruff is a note. In CI nobody reads a note, so it is a failure.
  fail "Ruff is not installed, and CI is set: the lint must run here (pipx install ruff)"
else
  note "Ruff is not installed, so the Python is not linted on this machine (pipx install ruff)"
fi

# ─── 21. Stage checks that count ─────────────────────────────────────────────
# A stage of a staged plan can have its checks written before its work. They are one Bash file,
# named for the stage, of checks written like the ones above: each calls ok or fail once.
#
#   tests/checks/<stage>.sh    The work is done. Its checks count like any other check.
#   tests/pending/<stage>.sh   The work is not done. Its checks are run and listed as waiting.
#                              They do not count, and the suite still passes.
#
# A stage finishes by making every check in its file pass and moving the file to tests/checks/.
# So a waiting file whose checks all pass fails the suite: its stage is done and its file was not
# moved. A stage may tighten the checks in its file. It never loosens one.
#
# This file reads a check file inside a subshell, from the repository's root. The check file has
# ok, fail, banner_steps, and $TMP, and these three. Nothing it sets or changes comes back.
#   $SCRATCH        an empty folder of its own, removed with $TMP
#   $LOOP_SKILL     the loop skill
#   $PAGE_RENDERER  the page renderer
# No check file spells those two paths, so a rename changes the two lines below and no check file.
# A check file must run to its last line: one that stops early, or holds no check, fails the suite
# in either folder.
LOOP_SKILL=skills/proof-loop/SKILL.md
PAGE_RENDERER=scripts/render-proof.py
WAITING=0
WAITING_FILES=0

run_check_file() {  # <file> <counted|waiting>
  local file=$1 mode=$2 stage verdict message passed failed ended=0
  stage=$(basename "$file" .sh)
  local scratch="$TMP/stage/$mode/$stage"
  rm -rf "$scratch"; mkdir -p "$scratch"
  # The file runs from a copy with one more line after its last. A file that stops early (an exit,
  # a return, a line that does not parse, a name that is not set) never reaches that line.
  { cat "$file"; printf '\nreached_the_last_line\n'; } > "$scratch.sh"
  (
    SCRATCH=$scratch
    ok()   { printf 'ok\t%s\n' "${1//[$'\t\n']/ }" >&3; }
    fail() { printf 'fail\t%s\n' "${1//[$'\t\n']/ }" >&3; }
    reached_the_last_line() { printf 'end\t\n' >&3; }
    # shellcheck disable=SC1090
    source "$scratch.sh"
  ) 3> "$scratch.results" > "$scratch.log" 2>&1 < /dev/null
  passed=$(grep -c $'^ok\t' "$scratch.results")
  failed=$(grep -c $'^fail\t' "$scratch.results")
  grep -q $'^end\t' "$scratch.results" && ended=1
  if [[ $mode == waiting ]]; then
    WAITING_FILES=$((WAITING_FILES + 1))
    printf "  %s: %d waiting" "$file" "$failed"
    if (( passed > 0 )); then printf ", %d passing already" "$passed"; fi
    printf "\n"
  fi
  while IFS=$'\t' read -r verdict message; do
    case "$mode:$verdict" in
      counted:ok)   ok "$stage: $message" ;;
      counted:fail) fail "$stage: $message" ;;
      waiting:ok)   printf "    \033[2m✓ passes already: %s\033[0m\n" "$message" ;;
      waiting:fail) WAITING=$((WAITING + 1)); printf "    \033[33m…\033[0m %s\n" "$message" ;;
    esac
  done < "$scratch.results"
  if [[ $ended -eq 0 ]]; then
    fail "$file did not run to its last line: $(tail -1 "$scratch.log")"
  elif (( passed + failed == 0 )); then
    fail "$file holds no check"
  elif [[ $mode == waiting && $failed -eq 0 ]]; then
    fail "every check in $file passes, so its stage is done: move the file to tests/checks/"
  fi
}

section "21. Stage checks that count (tests/checks/)"
# First the runner itself, on throwaway files: what one file adds to the suite's three counts.
# counts_for <counted|waiting> <a line of a check file>...: prints "<passed> <failed> <waiting>".
counts_for() {
  local mode=$1; shift
  printf '%s\n' "$@" > "$TMP/throwaway.sh"
  ( PASS=0; FAIL=0; WAITING=0; ERRORS=()
    run_check_file "$TMP/throwaway.sh" "$mode" > "$TMP/throwaway.out" 2>&1
    printf '%s %s %s' "$PASS" "$FAIL" "$WAITING" )
}
got=$(counts_for waiting 'fail "the work is not built"' 'ok "this part is"')
[[ "$got" == "0 0 1" ]] && grep -q 'the work is not built' "$TMP/throwaway.out" && ok "a failing check in a waiting file is listed as waiting, and neither passes nor fails the suite" || fail "a waiting file with one failing and one passing check added '$got' to passed, failed, waiting (expected '0 0 1')"
got=$(counts_for waiting 'ok "built"' 'ok "and this"')
[[ "$got" == "0 1 0" ]] && grep -q 'move the file to tests/checks/' "$TMP/throwaway.out" && ok "a waiting file whose checks all pass fails the suite and says to move the file" || fail "a waiting file whose checks all pass added '$got' (expected '0 1 0')"
got=$(counts_for counted 'ok "built"' 'fail "not built"')
[[ "$got" == "1 1 0" ]] && ok "the same checks under tests/checks/ pass and fail the suite like any other" || fail "a counted file with one passing and one failing check added '$got' (expected '1 1 0')"
stops=()
for early in 'exit 0' 'return 0' 'if then' 'printf "%s" "$never_set"'; do
  [[ "$(counts_for waiting 'fail "before"' "$early" 'fail "after"')" == "0 1 1" && "$(counts_for counted 'ok "before"' "$early" 'ok "after"')" == "1 1 0" ]] || stops+=("$early")
done
(( ${#stops[@]} == 0 )) && ok "a check file that stops before its last line fails the suite in either folder (an exit, a return, a line that does not parse, a name that is not set)" || fail "a check file that stops early is not caught when it stops with: ${stops[*]}"
[[ "$(counts_for waiting ': no check here')" == "0 1 0" && "$(counts_for counted ': no check here')" == "0 1 0" ]] && ok "a check file that holds no check fails the suite in either folder" || fail "a check file with no check in it is not caught"
# A rename that changes the two names above to a path that is not there would leave every check
# file reading nothing, and its checks waiting for good.
[[ -f "$LOOP_SKILL" && -f "$PAGE_RENDERER" ]] && ok "the loop skill and the page renderer are where the check files are told to find them" || fail "the check files are told to find the loop skill at $LOOP_SKILL and the page renderer at $PAGE_RENDERER, and one of them is not there"

counted_files=0
for f in tests/checks/*.sh; do
  [[ -f "$f" ]] || continue
  counted_files=$((counted_files + 1)); run_check_file "$f" counted
done
(( counted_files > 0 )) || note "no stage has moved its check file to tests/checks/ yet"

# ─── 22. Stage checks that wait ──────────────────────────────────────────────
section "22. Stage checks waiting for their stage (tests/pending/)"
for f in tests/pending/*.sh; do
  [[ -f "$f" ]] || continue
  run_check_file "$f" waiting
done
(( WAITING_FILES > 0 )) || note "nothing is waiting: tests/pending/ holds no check file"

# ─── Summary ─────────────────────────────────────────────────────────────────
printf "\n%d passed, %d failed" "$PASS" "$FAIL"
if (( WAITING_FILES > 0 )); then printf ", %d waiting for their stage (check files under tests/pending/: %d)" "$WAITING" "$WAITING_FILES"; fi
printf "\n"
if (( FAIL > 0 )); then
  printf "\nFailures:\n"
  for e in "${ERRORS[@]}"; do printf "  - %s\n" "$e"; done
  exit 1
fi
