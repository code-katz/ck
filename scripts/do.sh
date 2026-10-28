#!/usr/bin/env bash
# The git side of /ck:do. Each command prints plain lines for the skill to relay.
#   look                              what the skill needs before the plan
#   start <slug>                      the run folder and the base commit
#   back <worktree> <base>            what the build left, and whether it is ready
#   merge <root> <worktree> <branch>  merge, then remove the worktree and the branch
#   pr <root> <worktree> <branch>     push and open a draft pull request
#   discard <root> <worktree> <branch>
set -u
cmd="${1:-}"
[ $# -gt 0 ] && shift

case "$cmd" in
look)
  echo "root: $(git rev-parse --show-toplevel 2>/dev/null)"
  echo "branch: $(git branch --show-current 2>/dev/null)"
  echo "uncommitted: $(git status --porcelain 2>/dev/null | wc -l | tr -d ' ')"
  # The roster, one persona per line: name, role, and tier (fable, opus, sonnet).
  awk -F' [|] ' '/^[|] [a-z]+ [|]/ { sub(/^[|] /, ""); split($3, m, "-"); print "roster: " $1 ", " $2 ", " m[2] }' \
    "$(dirname "$0")/../profiles/ROSTER.md"
  for p in CLAUDE.md docs/TEAM.md docs/PRD.md docs/brand-guide.md docs/design; do
    if [ -e "$p" ]; then echo "$p"; fi
  done
  ;;
start)
  slug="$(printf '%s' "${1:-task}" | tr 'A-Z' 'a-z' | tr -cs 'a-z0-9' '-' | sed 's/^-*//; s/-*$//')"
  root="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
  run="$root/.ck/runs/$(date -u +%Y%m%dT%H%M%SZ)-${slug:-task}-do"
  mkdir -p "$run"
  exclude="$(git rev-parse --git-path info/exclude 2>/dev/null)"
  if [ -n "$exclude" ]; then
    for line in '.ck/' '.claude/worktrees/'; do
      grep -qxF "$line" "$exclude" 2>/dev/null || echo "$line" >> "$exclude"
    done
  fi
  echo "projectRoot: $root"
  echo "runDir: $run"
  echo "slug: ${slug:-task}"
  echo "base: $(git rev-parse HEAD 2>/dev/null)"
  ;;
back)
  w="$1"; b="$2"
  from="$(git -C "$w" merge-base "$b" HEAD 2>/dev/null)"
  n="$(git -C "$w" rev-list --count "$b..HEAD" 2>/dev/null || echo 0)"
  u="$(git -C "$w" status --porcelain | wc -l | tr -d ' ')"
  echo "branch: $(git -C "$w" branch --show-current)"
  echo "from base: $from"
  git -C "$w" log --oneline "$b..HEAD" 2>/dev/null
  git -C "$w" diff --stat "$b...HEAD" 2>/dev/null
  echo "uncommitted: $u"
  if [ "$from" != "$b" ]; then echo "ready: no, it did not grow from the base"
  elif [ "$n" = 0 ]; then echo "ready: no, nothing was committed"
  elif [ "$u" != 0 ]; then echo "ready: no, $u files are not committed"
  else echo "ready: yes"; fi
  ;;
merge)
  root="$1"; w="$2"; br="$3"
  into="$(git -C "$root" branch --show-current)"
  if [ -z "$into" ]; then echo "not merged: you are not on a branch; $br is kept"; exit 1; fi
  if ! out="$(git -C "$root" merge --no-ff --no-edit "$br" 2>&1)"; then
    if git -C "$root" rev-parse -q --verify MERGE_HEAD >/dev/null; then
      git -C "$root" merge --abort
      echo "not merged: conflicts, so the merge was undone; $br is kept"
    else
      echo "not merged: $(printf '%s' "$out" | tail -1)"
    fi
    exit 1
  fi
  echo "merged: $br into $into"
  git -C "$root" worktree remove "$w" 2>&1 | sed 's/^/worktree kept: /'
  git -C "$root" branch -d "$br" >/dev/null 2>&1 || echo "branch kept: git would not delete $br"
  ;;
pr)
  root="$1"; w="$2"; br="$3"
  if ! git -C "$w" remote get-url origin >/dev/null 2>&1; then echo "no pull request: this repository has no remote"; exit 1; fi
  if ! command -v gh >/dev/null 2>&1; then echo "no pull request: gh is not installed"; exit 1; fi
  if ! out="$(git -C "$w" push -u origin "$br" 2>&1)"; then echo "no pull request: the push failed: $(printf '%s' "$out" | tail -1)"; exit 1; fi
  if ! url="$(cd "$w" && gh pr create --draft --fill --head "$br" 2>&1)"; then echo "no pull request: $(printf '%s' "$url" | tail -1)"; exit 1; fi
  echo "pull request: $(printf '%s' "$url" | tail -1)"
  git -C "$root" worktree remove "$w" 2>&1 | sed 's/^/worktree kept: /'
  ;;
discard)
  root="$1"; w="$2"; br="$3"
  git -C "$root" worktree remove --force "$w" && git -C "$root" branch -D "$br" >/dev/null && echo "discarded: $br"
  ;;
*)
  echo "usage: do.sh look | start <slug> | back <worktree> <base> | merge|pr|discard <root> <worktree> <branch>" >&2
  exit 2
  ;;
esac
