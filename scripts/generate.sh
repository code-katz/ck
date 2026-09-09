#!/usr/bin/env bash
# generate.sh: derive every generated surface from profiles/<name>.md and tiers.conf.
#
#   agents/<name>.md          the persona as a ck:<name> subagent, on its tier, with
#                             "Required Interactive Behaviors" rewritten for output
#   skills/<name>/SKILL.md    the persona as the /ck:<name> session switch, verbatim
#   profiles/ROSTER.md        one row per persona: name, role, tier model, domain
#
# profiles/ is the only place persona text is edited. Re-run after editing any
# profile or tiers.conf:
#
#   bash scripts/generate.sh            regenerate in place (refuses to overwrite
#                                       uncommitted hand edits to generated files)
#   bash scripts/generate.sh --force    overwrite them anyway
#   OUT_DIR=/tmp/x bash scripts/generate.sh
#                                       generate into another directory (the drift test)

set -euo pipefail

if [[ -z "${BASH_VERSINFO:-}" ]] || (( BASH_VERSINFO[0] < 4 )); then
  echo "error: generate.sh requires Bash 4 or newer (this is ${BASH_VERSION:-not bash})." >&2
  echo "macOS ships Bash 3.2; install a current Bash with: brew install bash" >&2
  exit 1
fi

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
OUT_DIR="${OUT_DIR:-$REPO_DIR}"
PROFILES="$REPO_DIR/profiles"
TIERS="$REPO_DIR/tiers.conf"
FORCE=0
[[ "${1:-}" == "--force" ]] && FORCE=1

PREAMBLE='You are running with no user present. Every behavior below still applies, in output form. Where a behavior tells you to ask, halt, interrupt, or require an answer before proceeding: do not stop. State the question verbatim under `questions` (addressed to `author` or to a named teammate), state the assumption you will proceed on, and proceed. Where a behavior produces an artifact (table, diagram, scenario, counter-proposal, pitch), produce it in full. Where it requires a decision from the user, give your recommendation with evidence and mark the decision as open.'

TRAILER='You are running as a delegated subagent. When the prompt names a project root and a run directory, read inputs from the project and write outputs only where the prompt says. If a schema is imposed, fill every required field; anything you would have asked goes in `questions`. Return findings first, detail after.'

# The persona names, from the profiles directory. ROSTER.md is generated and skipped.
names=()
for profile in "$PROFILES"/*.md; do
  n=$(basename "$profile" .md)
  case "$n" in ROSTER | coordinator*) continue ;; esac
  names+=("$n")
done

# Refuse to overwrite uncommitted hand edits to generated files: the fix for a
# generated file is an edit to its profile, never to the file itself.
if [[ "$OUT_DIR" == "$REPO_DIR" && $FORCE -eq 0 ]] && git -C "$REPO_DIR" rev-parse --verify HEAD >/dev/null 2>&1; then
  generated=(agents profiles/ROSTER.md)
  for n in "${names[@]}"; do generated+=("skills/$n"); done
  if [[ -n "$(git -C "$REPO_DIR" status --porcelain -- "${generated[@]}" 2>/dev/null)" ]]; then
    echo "error: generated files have uncommitted changes. Edit the profile, not the generated file; commit or discard, or pass --force." >&2
    exit 1
  fi
fi

# Everything above "## Greeting", with the blank lines that precede it dropped.
profile_body() {
  awk '
    /^## Greeting$/ { exit }
    NF == 0         { blanks = blanks $0 "\n"; next }
                    { printf "%s", blanks; blanks = ""; print }
  ' "$1"
}

# The subagent form: the heading renamed and the preamble inserted under it. The
# text beneath stays verbatim. Reads the body on stdin.
subagent_form() {
  awk -v pre="$PREAMBLE" '
    /^## Required Interactive Behaviors$/ { print "## Required Behaviors (subagent form)"; print ""; print pre; next }
    { print }
  '
}

# The first bullet under "## Domain Expertise", for the roster. Falls back to the role.
profile_domain() {
  awk '
    /^## Domain Expertise$/ { found = 1; next }
    found && /^## /         { exit }
    found && /^- /          { sub(/^- /, ""); print; exit }
  ' "$1"
}

mkdir -p "$OUT_DIR/agents" "$OUT_DIR/skills" "$OUT_DIR/profiles"
roster_rows=()
count=0

for name in "${names[@]}"; do
  profile="$PROFILES/$name.md"
  title=$(grep -m1 '^# ' "$profile" | sed 's/^# //')
  role="${title#*— }"
  display="${title%% —*}"
  model=$(awk -v p="$name" '$1 == p { print $2; exit }' "$TIERS")
  if [[ -z "$model" ]]; then
    echo "error: $name has no line in tiers.conf." >&2
    exit 1
  fi
  for heading in '## Required Interactive Behaviors' '## Handoff Brief' '## Greeting'; do
    if ! grep -qx "$heading" "$profile"; then
      echo "error: $profile has no '$heading' section." >&2
      exit 1
    fi
  done
  domain=$(profile_domain "$profile")
  [[ -z "$domain" ]] && domain="$role"
  role_lc=$(printf '%s' "$role" | tr '[:upper:]' '[:lower:]')

  {
    printf -- '---\n'
    printf 'name: %s\n' "$name"
    printf 'description: %s, %s. Reviews and drafts from the %s perspective for ck workflows and delegation; returns structured findings.\n' "$display" "$role" "$role_lc"
    printf 'model: %s\n' "$model"
    printf -- '---\n\n'
    printf '<!-- GENERATED from profiles/%s.md by scripts/generate.sh; edit the profile, not this file. -->\n\n' "$name"
    profile_body "$profile" | subagent_form
    printf '\n---\n\n%s\n' "$TRAILER"
  } > "$OUT_DIR/agents/$name.md"

  mkdir -p "$OUT_DIR/skills/$name"
  {
    printf -- '---\n'
    printf 'name: %s\n' "$name"
    printf 'description: Switch this session to %s, %s.\n' "$display" "$role"
    printf 'disable-model-invocation: true\n'
    printf -- '---\n\n'
    printf '<!-- GENERATED from profiles/%s.md by scripts/generate.sh; edit the profile, not this file. -->\n\n' "$name"
    printf 'You are now %s for the rest of this session. You run on this session'"'"'s model, not on your tier; to run on your tier, delegate to the `ck:%s` subagent.\n\n---\n\n' "$display" "$name"
    cat "$profile"
  } > "$OUT_DIR/skills/$name/SKILL.md"

  roster_rows+=("| $name | $role | $model | $domain |")
  count=$((count + 1))
done

{
  printf '# ck roster\n\n'
  printf '<!-- GENERATED from profiles/*.md and tiers.conf by scripts/generate.sh; edit those, not this file. -->\n\n'
  printf 'One row per persona. Workflows read this file when choosing a cast.\n\n'
  printf '| Persona | Role | Tier model | Domain |\n|---|---|---|---|\n'
  printf '%s\n' "${roster_rows[@]}"
} > "$OUT_DIR/profiles/ROSTER.md"

echo "Generated $count agents, $count switch skills, and profiles/ROSTER.md in $OUT_DIR"
if [[ "$OUT_DIR" == "$REPO_DIR" ]] && git -C "$REPO_DIR" rev-parse --verify HEAD >/dev/null 2>&1; then
  git -C "$REPO_DIR" --no-pager diff --stat -- agents profiles/ROSTER.md skills || true
fi
