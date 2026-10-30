#!/usr/bin/env python3
"""team.py: this project's ck team, the core below plus the changes in <project>/.claude/ck-team.conf.

Usage:
  team.py show                     the team, who is invited or dropped and why, and who is not on it
  team.py roster                   the roster's rows for the team only
  team.py context                  SessionStart: one paragraph naming the team
  team.py invite <persona> [why]   put a persona on the team
  team.py drop <persona> [why]     take a persona off the team

The file holds one line per change to the core, `invite <persona> <why>` or `drop <persona> <why>`, and
`#` comments. The last line about a persona wins. With no file the team is the core. The project is the
nearest folder, from the current one up, that has .claude/ck-team.conf or .git. Standard library only;
an error is one plain line, never a traceback.
"""
import os
import re
import sys
from pathlib import Path

ROSTER = Path(__file__).resolve().parent.parent / 'profiles' / 'ROSTER.md'
CORE = ['river', 'quinn', 'akira', 'sasha', 'kai', 'robin', 'alex', 'morgan']
HEAD = '# ck team. The core comes from the plugin; this file invites and drops. Change it with /ck:team invite or drop.'
VERBS = ('invite', 'drop')


class Fail(Exception):
    pass


def roster():
    """Persona name to its row in profiles/ROSTER.md, in the roster's order."""
    rows = {}
    for line in ROSTER.read_text().splitlines():
        m = re.match(r'\| ([a-z]+) \|', line)
        if m:
            rows[m.group(1)] = line
    return rows


def project(start=None):
    """The project's folder, or None outside any repository with no team file."""
    here = Path(start or os.getcwd()).resolve()
    for d in [here, *here.parents]:
        if (d / '.claude' / 'ck-team.conf').is_file() or (d / '.git').exists():
            return d
    return None


def team_file(start=None):
    return (project(start) or Path(start or os.getcwd()).resolve()) / '.claude' / 'ck-team.conf'


def changes(path):
    """Persona to (verb, why, line number), from the last line about each persona."""
    found = {}
    if path.is_file():
        for n, line in enumerate(path.read_text().splitlines(), 1):
            words = line.split(None, 2)
            if len(words) > 1 and words[0] in VERBS:
                found[words[1].lower()] = (words[0], words[2] if len(words) > 2 else '', n)
    return found


def team(start=None):
    """The team's persona names: the core that is not dropped, then those invited."""
    names, found = roster(), changes(team_file(start))
    members = [p for p in CORE if found.get(p, ('invite',))[0] == 'invite']
    return members + [p for p, c in found.items() if c[0] == 'invite' and p not in CORE and p in names]


def show():
    names, path = roster(), team_file()
    found, members = changes(path), team()
    out = ['team: ' + ', '.join(members)]
    for verb in VERBS:
        said = ['%s%s' % (p, ' (%s)' % c[1] if c[1] else '') for p, c in found.items() if c[0] == verb and p in names]
        if said:
            out.append('%s: %s' % ('invited' if verb == 'invite' else 'dropped', ', '.join(said)))
    out.append('not on the team: ' + (', '.join(p for p in names if p not in members) or 'nobody'))
    out.append('file: .claude/ck-team.conf' if path.is_file() else 'file: none, so the team is the core')
    out += ['note: line %d names %s, who is not on the ck roster, so it is skipped' % (c[2], p)
            for p, c in found.items() if p not in names]
    return out


def context():
    names = ', '.join(p.capitalize() for p in team())
    return [("ck team for this project: %s. Suggest and cast only these seats. Before using anyone else, ask once; "
             "/ck:team invite <name> adds a lasting member. A pipeline command's own fixed seats always run." % names)]


def edit(verb, name, why):
    name = name.lower()
    if name not in roster():
        raise Fail('%s is not on the ck roster.' % name)
    path = team_file()
    before = name in team()
    lines = path.read_text().splitlines() if path.is_file() else [HEAD]
    lines = [l for l in lines if not (len(l.split()) > 1 and l.split()[0] in VERBS and l.split()[1].lower() == name)]
    if (verb == 'invite') != (name in CORE):                 # the file holds only what differs from the core
        lines.append(('%s %s %s' % (verb, name, why)).rstrip())
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text('\n'.join(lines) + '\n')
    after = name in team()
    word = 'on' if after else 'off'
    said = '%s is %s this project\'s team.' % (name, ('now ' if before != after else 'already ') + word)
    return [said] + show()


def main(argv):
    cmd, args = (argv[0] if argv else ''), argv[1:]
    if cmd in ('show', 'roster', 'context') and not args:
        if cmd == 'show':
            return show()
        if cmd == 'context':
            return context()
        rows = roster()
        return ['| Persona | Role | Tier model | Domain |', '|---|---|---|---|'] + [rows[p] for p in rows if p in team()]
    if cmd in VERBS and args:
        return edit(cmd, args[0], ' '.join(args[1:]))
    raise Fail('usage: team.py show | roster | context | invite <persona> [why] | drop <persona> [why]')


if __name__ == '__main__':
    try:
        print('\n'.join(main(sys.argv[1:])))
    except Fail as e:
        print(e, file=sys.stderr)
        sys.exit(1)
    except Exception as e:                                   # a hook must never fail a session
        print('team.py: %s' % e, file=sys.stderr)
        sys.exit(0 if sys.argv[1:2] == ['context'] else 2)
