#!/usr/bin/env bash
# tests/run.sh: static checks for the ck plugin (PRD section 9, tests 1 to 11), and
# the workflow scripts run with stub agents (section 14, tests/workflows.mjs).
#
# Usage: bash tests/run.sh
#
# Needs Bash 4+, python3 (for JSON and list parsing), and node (for the workflow
# script checks). Runs the skills' exact commands under zsh too when it is installed
# (section 15). Touches nothing outside a temporary directory.

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
section() { printf "\n\033[1m%s\033[0m\n" "$1"; }

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

# ─── 8. Gate-owning skills reference review-page ─────────────────────────────
section "8. Gate mechanics live in one place"
for f in skills/plan/SKILL.md skills/brief/SKILL.md skills/team/SKILL.md skills/roadmap/SKILL.md skills/market-research/SKILL.md skills/prd/SKILL.md skills/architecture/SKILL.md skills/opportunity/SKILL.md skills/brand-guide/SKILL.md skills/design/SKILL.md; do
  if grep -q 'review-page/SKILL.md' "$f"; then ok "$f references skills/review-page/SKILL.md"; else fail "$f does not reference review-page"; fi
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
for f in skills/next/SKILL.md skills/do/SKILL.md skills/plan/SKILL.md skills/start/SKILL.md skills/brief/SKILL.md skills/team/SKILL.md skills/roadmap/SKILL.md skills/market-research/SKILL.md skills/prd/SKILL.md skills/architecture/SKILL.md skills/opportunity/SKILL.md skills/brand-guide/SKILL.md skills/design/SKILL.md skills/review-page/SKILL.md; do
  prose=$(awk '/^```/ { fence = !fence; next } !fence' "$f")
  if printf '%s' "$prose" | grep -qiE '[0-9][0-9,.]*k? tokens'; then fail "$f prints a token count"; else ok "$f prints no token count"; fi
  if printf '%s' "$prose" | grep -q '—'; then fail "$f has an em-dash in prose"; else ok "$f has no em-dash in prose"; fi
done
for f in skills/*-artifact/SKILL.md; do
  prose=$(awk '/^```/ { fence = !fence; next } !fence' "$f")
  if printf '%s' "$prose" | grep -q '—'; then fail "$f has an em-dash in prose"; else ok "$f has no em-dash in prose"; fi
done

# ─── 12. Review page renderer ────────────────────────────────────────────────
section "12. Review page renderer"
if python3 scripts/render-review.py --in tests/fixtures/game/docs/PRD.md --out "$TMP/review.html" --title "Fixture PRD" --question "What went wrong?" >/dev/null 2>"$TMP/rr.err"; then
  ok "render-review.py renders the fixture PRD"
  h_src=$(grep -cE '^##+ ' tests/fixtures/game/docs/PRD.md); h_out=$(grep -o '<h[234] id=' "$TMP/review.html" | wc -l | tr -d ' ')
  [[ "$h_src" == "$h_out" ]] && ok "every heading is on the page ($h_out)" || fail "headings: $h_src in the source, $h_out on the page"
  grep -q 'comment mode' "$TMP/review.html" && grep -q 'Do not send the comment to Claude' "$TMP/review.html" && ! grep -q '@claude' "$TMP/review.html" && ok "the banner carries the four comment steps" || fail "banner steps missing"
  grep -q 'What went wrong?' "$TMP/review.html" && ok "the gate's question is in the banner" || fail "question missing"
  grep -q '<div class="table-wrap"><table>' "$TMP/review.html" && ok "tables scroll in their own container" || fail "table wrapper missing"
else
  fail "render-review.py failed: $(cat "$TMP/rr.err")"
fi
printf '# T\n\n**Bold with `code` inside.** Plain `code` and *em*.\n' > "$TMP/bold.md"
if python3 scripts/render-review.py --in "$TMP/bold.md" --out "$TMP/bold.html" --title "Bold" >/dev/null 2>&1 \
   && grep -q '<strong>Bold with <code>code</code> inside.</strong>' "$TMP/bold.html" && ! grep -q '\*\*' "$TMP/bold.html"; then
  ok "render-review.py renders a bold phrase that contains a code span"
else
  fail "render-review.py leaves literal ** around a bold phrase with a code span"
fi
printf '# T\n\n- ~~A line the template now covers.~~\n' > "$TMP/del.md"
python3 scripts/render-review.py --in "$TMP/del.md" --out "$TMP/del.html" --title "Del" >/dev/null 2>&1 \
  && grep -q '<del>A line the template now covers.</del>' "$TMP/del.html" && ok "render-review.py strikes out ~~text~~" || fail "render-review.py does not strike out ~~text~~"
printf '# T\n\n```mermaid\nsequenceDiagram\n  A->>B: hi\n```\n' > "$TMP/mm.md"
if python3 scripts/render-review.py --in "$TMP/mm.md" --out "$TMP/mm.html" --title "MM" >/dev/null 2>&1 \
   && grep -q '<pre class="mermaid">' "$TMP/mm.html" && grep -q 'cdnjs.cloudflare.com/ajax/libs/mermaid' "$TMP/mm.html"; then
  ok "render-review.py draws a mermaid fence and loads the library"
else
  fail "render-review.py does not render mermaid fences"
fi
printf '# T\n\n| Rule | Note |\n|---|---|\n| `^(Write|Edit)$` | one |\n' > "$TMP/bar-code.md"
python3 scripts/render-review.py --in "$TMP/bar-code.md" --out "$TMP/bar-code.html" --title "Bar" >/dev/null 2>&1 \
  && grep -qF '<tr><td><code>^(Write|Edit)$</code></td><td>one</td></tr>' "$TMP/bar-code.html" && ok "render-review.py keeps a bar inside a code span in its table cell" || fail "render-review.py splits a table cell at a bar inside a code span"
printf '# T\n\n| Rule | Note |\n|---|---|\n| a \\| b | one |\n' > "$TMP/bar-esc.md"
python3 scripts/render-review.py --in "$TMP/bar-esc.md" --out "$TMP/bar-esc.html" --title "Bar" >/dev/null 2>&1 \
  && grep -qF '<tr><td>a | b</td><td>one</td></tr>' "$TMP/bar-esc.html" && ok "render-review.py keeps an escaped bar in its table cell" || fail "render-review.py splits a table cell at an escaped bar"
if grep -q 'libs/mermaid' "$TMP/bold.html"; then fail "render-review.py loads mermaid on a page without a diagram"; else ok "render-review.py loads mermaid only when a page has a diagram"; fi

# ─── 13. Gallery renderer ────────────────────────────────────────────────────
section "13. Gallery renderer"
if python3 scripts/render-gallery.py --in tests/fixtures/gallery/brand.json --out "$TMP/gallery.html" >/dev/null 2>"$TMP/rg.err"; then
  ok "render-gallery.py renders the brand fixture from one JSON file"
  [[ $(grep -c 'class="variant"' "$TMP/gallery.html") -eq 2 ]] && grep -q 'id="variant-A"' "$TMP/gallery.html" && grep -q 'id="variant-B"' "$TMP/gallery.html" && ok "two variants, labeled A and B, with matching ids" || fail "variant sections or ids missing"
  grep -q 'comment mode' "$TMP/gallery.html" && grep -q 'Do not send the comment to Claude' "$TMP/gallery.html" && ! grep -q '@claude' "$TMP/gallery.html" && ok "the banner carries the four comment steps" || fail "banner steps missing"
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
section "18. /ck:do, the quick path, and scripts/do.sh"
mkdir -p "$TMP/do"
if python3 - > "$TMP/do/static.out" 2>&1 <<'EOF'
import re, pathlib
problems = []
skill = pathlib.Path('skills/do/SKILL.md').read_text()
front = skill.split('---', 2)[1]
for key, pat in (('name: do', r'^name: do$'), ('disable-model-invocation: true', r'^disable-model-invocation: true$'), ('an argument hint', r'^argument-hint: ')):
    if not re.search(pat, front, re.M): problems.append(f'frontmatter lacks {key}')
files = sorted(pathlib.Path('skills/do').glob('*.md'))
text = '\n'.join(p.read_text() for p in files)
for n in sorted(set(re.findall(r'/ck:([a-z-]+)', text)) - {'do'}):
    if not (pathlib.Path(f'skills/{n}/SKILL.md').exists() or pathlib.Path(f'workflows/{n}.js').exists()):
        problems.append(f'names /ck:{n}, which is not a command')
for n in sorted(set(re.findall(r'`(?:\$\{CLAUDE_PLUGIN_ROOT\}/skills/do/)?([a-z-]+\.md)`', text))):
    if not pathlib.Path(f'skills/do/{n}').exists(): problems.append(f'points to skills/do/{n}, which does not exist')
script = pathlib.Path('scripts/do.sh').read_text()
for c in sorted(set(re.findall(r'`<do> ([a-z]+)', text))):
    if not re.search(rf'^{c}\)', script, re.M): problems.append(f'runs do.sh {c}, which the script does not have')
# Claude Code replaces $0, $1, ... in a typed skill with the words typed after the command.
for p in files:
    for m in re.finditer(r'\$[0-9]', p.read_text()): problems.append(f'{p} has {m.group()}, which Claude Code replaces with a word of the task')
for p in problems: print(p)
raise SystemExit(1 if problems else 0)
EOF
then ok "skills/do: typed only; every command, file, and do.sh command it names exists; no dollar sign before a digit"
else while IFS= read -r l; do fail "skills/do: $l"; done < "$TMP/do/static.out"; fi
if grep -q '^| `/ck:do <task>`' README.md; then ok "README.md has a row for /ck:do"; else fail "README.md has no row for /ck:do"; fi

# scripts/do.sh in a plain folder, a repository, and a linked worktree.
DOSH="$PWD/scripts/do.sh"; w="$TMP/do"
do_git() { git -c user.name=t -c user.email=t@example.com -c init.defaultBranch=main "$@"; }
personas=$(grep -c '^| [a-z]* |' profiles/ROSTER.md)
mkdir -p "$w/plain" "$w/repo/docs"
(cd "$w/plain" && bash "$DOSH" look) > "$w/out" 2> "$w/err"; rc=$?
if [[ $rc -eq 0 && ! -s "$w/err" && "$(head -3 "$w/out")" == $'root: \nbranch: \nuncommitted: 0' && "$(grep -c '^roster: [a-z]*, .*, \(fable\|opus\|sonnet\|haiku\)$' "$w/out")" == "$personas" && "$(wc -l < "$w/out" | tr -d ' ')" == $((personas + 3)) ]]
then ok "look in a plain folder: three empty answers and the $personas personas, no documents"
else fail "look in a plain folder: exit $rc, '$(cat "$w/out" "$w/err" | tr '\n' ' ')'"; fi
(cd "$w/repo" && do_git init -q && git config user.name t && git config user.email t@example.com && echo x > CLAUDE.md && echo t > docs/TEAM.md && echo p > page.html && do_git add -A && do_git commit -q -m first)
root="$(cd "$w/repo" && pwd -P)"; base="$(git -C "$w/repo" rev-parse HEAD)"
(cd "$w/repo" && bash "$DOSH" look) > "$w/out" 2> "$w/err"; rc=$?
if [[ $rc -eq 0 && ! -s "$w/err" && "$(head -3 "$w/out")" == "root: $root"$'\nbranch: main\nuncommitted: 0' && "$(grep -v '^roster: ' "$w/out" | tail -n +4)" == $'CLAUDE.md\ndocs/TEAM.md' ]]
then ok "look in a repository: the root, the branch, a clean count, and the documents that exist"
else fail "look in a repository: exit $rc, '$(cat "$w/out" "$w/err" | tr '\n' ' ')'"; fi
(cd "$w/repo" && bash "$DOSH" start 'Rulebook icons!' && bash "$DOSH" start 'Rulebook icons!') > "$w/out" 2> "$w/err"; rc=$?
run="$(sed -n 's/^runDir: //p' "$w/out" | head -1)"; exclude="$w/repo/.git/info/exclude"
if [[ $rc -eq 0 && ! -s "$w/err" && -d "$run" && "$run" == "$root/.ck/runs/"*"-rulebook-icons-do" && "$(grep -c '^slug: rulebook-icons$' "$w/out")" == 2 && "$(grep -c "^base: $base$" "$w/out")" == 2 \
      && "$(grep -cxF '.ck/' "$exclude")" == 1 && "$(grep -cxF '.claude/worktrees/' "$exclude")" == 1 && -z "$(git -C "$w/repo" status --porcelain)" ]]
then ok "start: makes the run folder from a clean slug, prints the base, excludes the cache once, leaves the checkout clean"
else fail "start in a repository: exit $rc, '$(cat "$w/out" "$w/err" | tr '\n' ' ')', exclude '$(tr '\n' ' ' < "$exclude")'"; fi
do_git -C "$w/repo" worktree add -q --detach "$w/linked" HEAD
(cd "$w/linked" && bash "$DOSH" start icons) > "$w/out" 2> "$w/err"; rc=$?
if [[ $rc -eq 0 && ! -s "$w/err" && -d "$(sed -n 's/^runDir: //p' "$w/out")" && -z "$(git -C "$w/linked" status --porcelain)" ]]; then ok "start works in a linked worktree and leaves it clean"
else fail "start in a linked worktree: exit $rc, '$(cat "$w/out" "$w/err" | tr '\n' ' ')'"; fi
(cd "$w/plain" && bash "$DOSH" start icons) > "$w/out" 2> "$w/err"; rc=$?
if [[ $rc -eq 0 && ! -s "$w/err" && -d "$(sed -n 's/^runDir: //p' "$w/out")" && "$(sed -n 's/^base: //p' "$w/out")" == "" ]]; then ok "start works with no repository"
else fail "start with no repository: exit $rc, '$(cat "$w/out" "$w/err" | tr '\n' ' ')'"; fi

# A build as build.md describes it: a worktree branch do/<slug> with one commit on the base.
build() { do_git -C "$w/repo" worktree add -q "$w/$1" -b "do/$1" "$base"; }
build icons; (cd "$w/icons" && echo more >> page.html && do_git commit -q -am "icons beside the headings")
bash "$DOSH" back "$w/icons" "$base" > "$w/out" 2> "$w/err"; rc=$?
if [[ $rc -eq 0 && ! -s "$w/err" ]] && grep -qxF 'branch: do/icons' "$w/out" && grep -qxF "from base: $base" "$w/out" && grep -q 'icons beside the headings$' "$w/out" \
      && grep -q '1 file changed' "$w/out" && grep -qxF 'uncommitted: 0' "$w/out" && grep -qxF 'ready: yes' "$w/out"
then ok "back: the branch, the base, the commit, the files, a clean count, and ready"
else fail "back on a good build: exit $rc, '$(cat "$w/out" "$w/err" | tr '\n' ' ')'"; fi
build empty
bash "$DOSH" back "$w/empty" "$base" | grep -qxF 'ready: no, nothing was committed' && ok "back: no commit is not ready" || fail "back with no commit says it is ready"
echo loose > "$w/icons/loose.txt"
bash "$DOSH" back "$w/icons" "$base" | grep -qxF 'ready: no, 1 files are not committed' && ok "back: uncommitted files are not ready" || fail "back with an uncommitted file says it is ready"
rm "$w/icons/loose.txt"
(cd "$w/empty" && do_git checkout -q --orphan stray && do_git commit -q -m stray --allow-empty)
bash "$DOSH" back "$w/empty" "$base" | grep -qxF 'ready: no, it did not grow from the base' && ok "back: a branch not grown from the base is not ready" || fail "back on an unrelated branch says it is ready"

# merge, pr, and discard.
out=$(bash "$DOSH" merge "$w/repo" "$w/icons" do/icons 2>&1); rc=$?
if [[ $rc -eq 0 && "$out" == 'merged: do/icons into main' && ! -d "$w/icons" ]] && ! git -C "$w/repo" rev-parse -q --verify do/icons >/dev/null && grep -qx more <(tail -1 "$w/repo/page.html")
then ok "merge: merges, removes the worktree, deletes the branch"
else fail "merge of a clean build: exit $rc, '$out'"; fi
build clash; (cd "$w/clash" && echo theirs > CLAUDE.md && do_git commit -q -am theirs); (cd "$w/repo" && echo ours > CLAUDE.md && do_git commit -q -am ours)
out=$(bash "$DOSH" merge "$w/repo" "$w/clash" do/clash 2>&1); rc=$?
if [[ $rc -ne 0 && "$out" == 'not merged: conflicts, so the merge was undone; do/clash is kept' && -d "$w/clash" && -z "$(git -C "$w/repo" status --porcelain)" ]] && git -C "$w/repo" rev-parse -q --verify do/clash >/dev/null
then ok "merge with conflicts: undoes the merge, keeps the branch and the worktree"
else fail "merge with conflicts: exit $rc, '$out', status '$(git -C "$w/repo" status --porcelain | tr '\n' ' ')'"; fi
out=$(bash "$DOSH" merge "$w/linked" "$w/clash" do/clash 2>&1); rc=$?
[[ $rc -ne 0 && "$out" == 'not merged: you are not on a branch; do/clash is kept' ]] && ok "merge off a branch: refuses and keeps the branch" || fail "merge from a detached checkout: exit $rc, '$out'"
out=$(bash "$DOSH" pr "$w/repo" "$w/clash" do/clash 2>&1); rc=$?
[[ $rc -ne 0 && "$out" == 'no pull request: this repository has no remote' && -d "$w/clash" ]] && ok "pr with no remote: says so and keeps the worktree" || fail "pr with no remote: exit $rc, '$out'"
out=$(bash "$DOSH" discard "$w/repo" "$w/clash" do/clash 2>&1); rc=$?
if [[ $rc -eq 0 && "$out" == 'discarded: do/clash' && ! -d "$w/clash" ]] && ! git -C "$w/repo" rev-parse -q --verify do/clash >/dev/null; then ok "discard: removes the worktree and the branch"
else fail "discard: exit $rc, '$out'"; fi

# ─── 19. The staged plan ─────────────────────────────────────────────────────
section "19. The staged plan: /ck:plan, /ck:start, and scripts/plan.py"
if python3 - > "$TMP/plan-static.out" 2>&1 <<'EOF'
import re, sys, pathlib
problems = []
def front(path):
    return pathlib.Path(path).read_text().split('---', 2)[1]
plan = pathlib.Path('skills/plan/SKILL.md').read_text()
start = ''.join(f.read_text() for f in sorted(pathlib.Path('skills/start').glob('*.md')))
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
# The script makes the fix card and puts the model check in every card; the contract names a fix's session.
for need in ('check your own model', '--fix'):
    if script and need not in script: problems.append(f'scripts/plan.py lacks: {need}')
if '[A31-P1-S5 fix] [Akira Fable]' not in contract: problems.append('the contract lacks the name of a fix session, "[A31-P1-S5 fix] [Akira Fable]"')
for p in problems: print(p)
sys.exit(1 if problems else 0)
EOF
then ok "skills/plan and skills/start: typed only; every plan.py command they run exists; the contract's fixed words are the script's"
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

# ─── 20. /ck:claude-md ───────────────────────────────────────────────────────
section "20. /ck:claude-md: scripts/claude-md.py and the command"
CM="python3 scripts/claude-md.py"
mkdir -p "$TMP/cm"
state_of() { $CM status "$@" | sed -n 's/^state: //p'; }
# A tailored draft: the current template with every blank filled.
sed 's/{{[^}]*}}/filled/g' templates/how-we-work/0.1.14.md > "$TMP/cm/draft.md"

# The command runs only when the User types it, and ships no hook of its own.
if grep -qx 'disable-model-invocation: true' skills/claude-md/SKILL.md && ! grep -q 'claude-md' hooks/hooks.json; then
  ok "/ck:claude-md runs only when typed, and no hook starts it"
else
  fail "/ck:claude-md can be started by Claude or by a hook"
fi

# A new section: the file is made with the heading and the draft, stamped with the template's version.
$CM write "$TMP/cm/new.md" --section "$TMP/cm/draft.md" >/dev/null; rc=$?
if [[ $rc -eq 0 && "$(cat "$TMP/cm/new.md")" == "$(printf '## How we work\n\n'; cat "$TMP/cm/draft.md")" && "$(state_of "$TMP/cm/new.md")" == stamped ]] \
   && $CM status "$TMP/cm/new.md" | grep -qx 'stamp: 0.1.14' && $CM status "$TMP/cm/new.md" | grep -qx 'behind: no'; then
  ok "a new section is written under the heading, stamped 0.1.14, not behind"
else
  fail "a new section: exit $rc, state $(state_of "$TMP/cm/new.md")"
fi
cp templates/how-we-work/0.1.14.md "$TMP/cm/blank.md"
out=$($CM write "$TMP/cm/blank2.md" --section "$TMP/cm/blank.md"); rc=$?
[[ $rc -eq 1 && "$out" == *'{{lanes}}'* && ! -e "$TMP/cm/blank2.md" ]] && ok "a draft with a blank left in it is refused, and the blank is named" || fail "a draft with a blank: exit $rc, '$out'"

# A second run changes nothing, byte for byte.
cp "$TMP/cm/new.md" "$TMP/cm/new.before"
out=$($CM write "$TMP/cm/new.md" --section "$TMP/cm/draft.md"); rc=$?
if [[ $rc -eq 0 && "$out" == unchanged:* ]] && cmp -s "$TMP/cm/new.md" "$TMP/cm/new.before"; then ok "a second run changes nothing"; else fail "a second run: exit $rc, '$out'"; fi

# Broken markers are refused, the line is named, and the file is left as it was.
printf '# P\n\n<!-- ck:how-we-work 0.1.12 -->\n- a rule\n' > "$TMP/cm/open.md"
cat "$TMP/cm/draft.md" "$TMP/cm/draft.md" > "$TMP/cm/two.md"
printf '<!-- /ck:how-we-work -->\n<!-- ck:how-we-work 0.1.12 -->\n' > "$TMP/cm/order.md"
broken_ok=1
for f in open two order; do
  cp "$TMP/cm/$f.md" "$TMP/cm/$f.before"
  out=$($CM write "$TMP/cm/$f.md" --section "$TMP/cm/draft.md"); rc=$?
  [[ "$(state_of "$TMP/cm/$f.md")" == broken && $rc -eq 1 && "$out" == *"line "[0-9]* ]] && cmp -s "$TMP/cm/$f.md" "$TMP/cm/$f.before" || { fail "broken markers ($f): exit $rc, '$out'"; broken_ok=0; }
done
[[ $broken_ok -eq 1 ]] && ok "an opening with no end, two sections, and an end before the opening are refused with the line named"
printf '# P\n\n## How we work\n\n- A rule.\n' > "$TMP/cm/plain.md"; cp "$TMP/cm/plain.md" "$TMP/cm/plain.before"
out=$($CM write "$TMP/cm/plain.md" --section "$TMP/cm/draft.md"); rc=$?
[[ $rc -eq 1 && "$(state_of "$TMP/cm/plain.md")" == none ]] && $CM status "$TMP/cm/plain.md" | grep -qx 'heading: yes' && cmp -s "$TMP/cm/plain.md" "$TMP/cm/plain.before" \
  && ok "a file with a How we work heading and no markers is refused, left as it was, and its heading is seen" || fail "a file with no markers: exit $rc, '$out'"

# Text outside the markers is kept byte for byte, whatever the section held.
printf '# P\r\n\r\nAbove, with CRLF.\n\n## How we work\n\n' > "$TMP/cm/head"
printf '\n- The project'"'"'s own rule, after the section.\n\n## Other\n\n- trailing line with no newline' > "$TMP/cm/tail"
for body in '' $'- **Writing.** Edited here.\n'; do
  { cat "$TMP/cm/head"; printf '<!-- ck:how-we-work -->\n%s<!-- /ck:how-we-work -->\n' "$body"; cat "$TMP/cm/tail"; } > "$TMP/cm/outside.md"
  $CM write "$TMP/cm/outside.md" --section "$TMP/cm/draft.md" >/dev/null
  { cat "$TMP/cm/head" "$TMP/cm/draft.md" "$TMP/cm/tail"; } > "$TMP/cm/outside.want"
  label=${body%$'\n'}
  cmp -s "$TMP/cm/outside.md" "$TMP/cm/outside.want" || { fail "text outside the markers changed (section: ${label:-an empty pair})"; continue; }
  ok "text outside the markers is untouched (section: ${label:-an empty pair})"
done

# Every rule of the old "How we work" is accounted for: among the template's rules, after the marker, or missing.
printf '# P\n\n## How we work\n\n- **Questions.** Old words.\n- **Our own rule.** Kept by the project.\n\n## Next\n' > "$TMP/cm/old.md"
{ printf '# P\n\n## How we work\n\n'; cat "$TMP/cm/draft.md"; } > "$TMP/cm/dropped.md"
{ printf '# P\n\n## How we work\n\n'; cat "$TMP/cm/draft.md"; printf -- '- **Our own rule.** Kept by the project.\n\n## Next\n'; } > "$TMP/cm/kept.md"
out=$($CM kept "$TMP/cm/old.md" "$TMP/cm/dropped.md"); rc=$?
out2=$($CM kept "$TMP/cm/old.md" "$TMP/cm/kept.md"); rc2=$?
if [[ $rc -eq 1 && "$out" == *'missing: our own rule'* && "$out" == *"kept: questions (among the template's rules)"* \
   && $rc2 -eq 0 && "$out2" == *'kept: our own rule (after the closing marker)'* ]]; then
  ok "a rule the draft drops is named as missing; kept after the marker, it passes"
else
  fail "the kept check: exit $rc '$out'; exit $rc2 '$out2'"
fi

# Two shipped templates: the diff shows the change, and a section from the older one is behind.
mkdir -p "$TMP/cm/templates"
cp templates/how-we-work/0.1.14.md "$TMP/cm/templates/0.1.14.md"
sed -e 's/ck:how-we-work 0.1.14/ck:how-we-work 0.1.15/' -e 's/^- \*\*Drawings first\.\*\* .*/- **Drawings first.** Changed in 0.1.15./' templates/how-we-work/0.1.14.md > "$TMP/cm/templates/0.1.15.md"
d=$($CM diff 0.1.14 0.1.15 --templates "$TMP/cm/templates")
if [[ "$d" == *'+- **Drawings first.** Changed in 0.1.15.'* && "$d" == *'-- **Drawings first.** A screen is drawn'* ]] \
   && $CM template --templates "$TMP/cm/templates" | grep -qx 'template: 0.1.15' \
   && $CM status "$TMP/cm/new.md" --templates "$TMP/cm/templates" | grep -qx 'behind: yes'; then
  ok "the diff between two templates shows the change, 0.1.15 is current, and a section stamped 0.1.14 is behind"
else
  fail "two templates: diff '$d'"
fi

# ─── 21. The memory gate ─────────────────────────────────────────────────────
section "21. The memory gate: scripts/memory-gate.py"
MG="python3 scripts/memory-gate.py check"
MEM="$HOME/.claude/projects/x/memory"
gate() { printf '%s' "$1" | $MG; }
call() { python3 -c 'import json,sys; print(json.dumps({"tool_name": sys.argv[1], "tool_input": {sys.argv[2]: sys.argv[3]}, "cwd": "/tmp"}))' "$@"; }
asks=1
for c in "Write file_path $MEM/a.md" "Edit file_path $MEM/MEMORY.md"; do
  read -r tool key path <<<"$c"
  gate "$(call "$tool" "$key" "$path")" | grep -q '"permissionDecision": "ask"' || { fail "the gate does not ask for a $tool to $path"; asks=0; }
done
for cmd in 'echo hi >> ~/.claude/projects/x/memory/MEMORY.md' 'mv /tmp/a.md "$HOME/.claude/projects/x/memory/"' 'mem=~/.claude/projects/x/memory; echo y > "$mem/b.md"'; do
  gate "$(call Bash command "$cmd")" | grep -q '"permissionDecision": "ask"' || { fail "the gate does not ask for: $cmd"; asks=0; }
done
[[ $asks -eq 1 ]] && ok "the gate asks for a Write, an Edit, an append, a mv, and a write through a variable into a memory folder"
step3=$(python3 -c 'import re; s=open("skills/claude-md/SKILL.md").read(); print(re.search(r"## 3\. Read the project.s memory.*?```bash\n(.*?)\n```", s, re.S).group(1))')
out="$(gate "$(call Write file_path /tmp/x.md)")$(gate "$(call Bash command 'cat ~/.claude/projects/x/memory/a.md')")$(gate "$(call Bash command "$step3")")"
[[ -z "$out" ]] && ok "the gate passes a write elsewhere, a cat of a memory, and /ck:claude-md's read command, with no output" || fail "the gate asked for a call that writes no memory: $out"
python3 -c 'import json; h=json.load(open("hooks/hooks.json"))["hooks"]; assert any("memory-gate.py\" check" in x["command"] for e in h["PreToolUse"] for x in e["hooks"]); assert any("memory-gate.py\" rule" in x["command"] for e in h["SessionStart"] for x in e["hooks"])' \
  && ok "hooks.json runs the gate before tool calls and prints its rule at session start" || fail "hooks.json does not wire the memory gate"

# ─── Summary ─────────────────────────────────────────────────────────────────
printf "\n%d passed, %d failed\n" "$PASS" "$FAIL"
if (( FAIL > 0 )); then
  printf "\nFailures:\n"
  for e in "${ERRORS[@]}"; do printf "  - %s\n" "$e"; done
  exit 1
fi
