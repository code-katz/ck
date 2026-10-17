# tests/pending/P0-S4.sh: the checks for stage P0-S4, Move the tiers to current models.
#
# Written with the stage's row, before the work. Section 21 of tests/run.sh says how this file is
# run and what it may use. The stage is done when every check here passes and this file has moved
# to tests/checks/. Tighten a check when the work shows it is too weak. Never loosen one.
#
# An old id is one not followed by another digit group: claude-opus-5 and claude-sonnet-5 are old,
# claude-opus-5-5 and claude-sonnet-5-5 are not. tests/plan-cases.py is left out on purpose: its
# cases test how a model word fits an id, and may name any id.

old_ids='claude-(opus|sonnet)-5([^-0-9]|$)|claude-haiku-4-5'
scope=(tiers.conf workflows skills agents profiles scripts README.md)

found=$(grep -rnE "$old_ids" "${scope[@]}" 2>/dev/null | head -5)
if [[ -z $found ]]; then ok "no old model id is left in the tier file, the workflows, the skills, the agents, the profiles, the scripts, or the README"
else fail "an old model id is still written here: $(printf '%s' "$found" | head -1)"; fi

opus=$(grep -cE '^[a-z]+ claude-opus-5-5$' tiers.conf)
sonnet=$(grep -cE '^[a-z]+ claude-sonnet-5-5$' tiers.conf)
fable=$(grep -cE '^[a-z]+ claude-fable-5-1$' tiers.conf)
if (( opus == 11 && sonnet == 4 && fable == 6 )); then ok "tiers.conf keeps every persona on its tier, with Opus 5.5, Sonnet 5.5, and Fable 5.1"
else fail "tiers.conf has $fable on Fable 5.1, $opus on Opus 5.5, and $sonnet on Sonnet 5.5, not 6, 11, and 4"; fi

stale=$(grep -lE "$old_ids" agents/*.md skills/roster/SKILL.md profiles/ROSTER.md 2>/dev/null | head -1)
if [[ -z $stale ]] && grep -q 'claude-opus-5-5' profiles/ROSTER.md; then ok "the agents and the roster were regenerated from the new tier file"
else fail "the generated files still carry an old id, or the roster names no Opus 5.5: ${stale:-profiles/ROSTER.md}"; fi

if grep -qE '^\| *Craft *\| *Opus 5\.5 *\|' README.md && grep -qE '^\| *Execution *\| *Sonnet 5\.5 *\|' README.md && grep -q 'Haiku 5.5' README.md; then
  ok "the README's Models table names Opus 5.5, Sonnet 5.5, and Haiku 5.5"
else fail "the README's Models table does not name Opus 5.5 for Craft, Sonnet 5.5 for Execution, and Haiku 5.5 for validators"; fi

panel=$(grep -oE "model: 'claude-[a-z0-9-]+'" workflows/panel.js | sort -u | wc -l | tr -d ' ')
if (( panel == 3 )); then ok "the panel's three lenses are still on three different models"
else fail "the panel's lenses are on $panel different models, not 3"; fi
