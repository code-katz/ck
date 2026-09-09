#!/usr/bin/env bash
# tests/run.sh: static checks for the ck plugin (PRD section 9, tests 1 to 11).
#
# Usage: bash tests/run.sh
#
# Needs Bash 4+, python3 (for JSON and list parsing), and node (for the workflow
# script check). Touches nothing outside a temporary directory.

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
opus=$(grep -c ' claude-opus-5$' tiers.conf)
sonnet=$(grep -c ' claude-sonnet-5$' tiers.conf)
if [[ "$tier_lines" == "${#personas[@]}" ]]; then ok "one tier line per persona ($tier_lines)"; else fail "tiers.conf has $tier_lines persona lines, expected ${#personas[@]}"; fi
if [[ "$fable" == 6 && "$opus" == 11 && "$sonnet" == 4 ]]; then ok "six Fable 5.1, eleven Opus 5, four Sonnet 5"; else fail "tier counts: $fable Fable, $opus Opus, $sonnet Sonnet"; fi
unknown=$(grep -E '^[a-z]+ ' tiers.conf | awk '{print $1}' | while read -r n; do [[ -f "profiles/$n.md" ]] || echo "$n"; done)
if [[ -z "$unknown" ]]; then ok "every tier line names a profile"; else fail "tier lines without a profile: $unknown"; fi
other=$(grep -E '^[a-z]+ ' tiers.conf | grep -vE ' claude-(fable-5-1|opus-5|sonnet-5)$' || true)
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
def contract_sections(path):
    text = pathlib.Path(path).read_text()
    body = text.split('## Section order', 1)[1].split('## Checklist', 1)[0] if '## Section order' in text else ''
    return re.findall(r'^\d+\. `## (.+?)`', body, re.M)
def js_list(text):
    return re.findall(r"'((?:[^'\\]|\\.)*)'", text)
problems = []
# brief.js and team.js declare SECTIONS
for script, contract in (('workflows/brief.js', 'skills/brief-artifact/SKILL.md'), ('workflows/team.js', 'skills/team-artifact/SKILL.md')):
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
for p in problems: print(p, file=sys.stderr)
sys.exit(1 if problems else 0)
EOF
then ok "brief, team, prd, and architecture section lists match their contracts"; else fail "contract and script section lists differ (see above)"; fi

# ─── 8. Gate-owning skills reference review-page ─────────────────────────────
section "8. Gate mechanics live in one place"
for f in skills/prd/SKILL.md; do
  if grep -q 'review-page/SKILL.md' "$f"; then ok "$f references skills/review-page/SKILL.md"; else fail "$f does not reference review-page"; fi
  if grep -qi 'comment mode' "$f"; then fail "$f restates the comment steps"; else ok "$f does not restate the comment steps"; fi
done

# ─── 9. Workflow scripts ─────────────────────────────────────────────────────
section "9. Workflow scripts"
for f in workflows/*.js; do
  name=$(basename "$f" .js)
  # Scripts use top-level return and await; check them the way the runtime runs them.
  sed '0,/^export const meta/s//const meta/' "$f" > "$TMP/$name.body.js"
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
for f in skills/next/SKILL.md skills/prd/SKILL.md skills/review-page/SKILL.md; do
  prose=$(awk '/^```/ { fence = !fence; next } !fence' "$f")
  if printf '%s' "$prose" | grep -qiE '[0-9][0-9,.]*k? tokens'; then fail "$f prints a token count"; else ok "$f prints no token count"; fi
  if printf '%s' "$prose" | grep -q '—'; then fail "$f has an em-dash in prose"; else ok "$f has no em-dash in prose"; fi
done
for f in skills/*-artifact/SKILL.md; do
  prose=$(awk '/^```/ { fence = !fence; next } !fence' "$f")
  if printf '%s' "$prose" | grep -q '—'; then fail "$f has an em-dash in prose"; else ok "$f has no em-dash in prose"; fi
done

# ─── Summary ─────────────────────────────────────────────────────────────────
printf "\n%d passed, %d failed\n" "$PASS" "$FAIL"
if (( FAIL > 0 )); then
  printf "\nFailures:\n"
  for e in "${ERRORS[@]}"; do printf "  - %s\n" "$e"; done
  exit 1
fi
