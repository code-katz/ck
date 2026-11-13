#!/usr/bin/env python3
"""installs.py: keeps a ck channel's install records on one version.

Claude Code keeps a record per folder where ck was installed, in ~/.claude/plugins/installed_plugins.json,
and a session reads the first record that belongs to its repository, a worktree's record included. So when
a release sets only the main folder's record, a session there can still load the older ck an old worktree's
record names. From 2026-11-07 to 2026-11-13 d20mob and hireling sessions ran ck 0.1.29 this way.

  installs.py set <version> [--sha <commit>] [--marketplace ck-next] [--plugins <dir>]
      Sets every ck@<marketplace> record to <version>, whichever folder it is for, so any record a session
      reads names the release. The version's folder must already be in the plugin cache.
  installs.py check [--root <plugin root>]
      The SessionStart hook: one sentence when the ck this session loaded is not the version its
      project's main folder is installed at. Silent otherwise, and never blocks a session.
  installs.py verify <version> [--marketplace ck-next] [--plugins <dir>] [<folder> ...]
      The release check: starts a fresh session in each folder (by default the main folder of every
      ck@<marketplace> record), one short Haiku turn, and reads which ck it loaded. Fails unless every
      folder loaded <version>.
"""
import datetime
import json
import os
import shutil
import subprocess
import sys

KEY = 'ck@%s'
PROBE = ['-p', '--model', 'claude-haiku-5-5', '--max-turns', '1', '--output-format', 'stream-json', '--verbose',
         'Reply with ok.']


def plugins_dir(opts):
    return opts.get('--plugins') or os.path.join(os.path.expanduser('~'), '.claude', 'plugins')


def records_path(plugins):
    return os.path.join(plugins, 'installed_plugins.json')


def cmd_set(args, opts):
    if len(args) != 1:
        return 'usage: installs.py set <version> [--sha <commit>] [--marketplace ck-next] [--plugins <dir>]'
    version, market = args[0], opts.get('--marketplace', 'ck-next')
    plugins = plugins_dir(opts)
    folder = os.path.join(plugins, 'cache', market, 'ck', version)
    if not os.path.isfile(os.path.join(folder, '.claude-plugin', 'plugin.json')):
        return '%s is not in the plugin cache, so no record was changed' % folder
    with open(records_path(plugins)) as f:
        data = json.load(f)
    records = data.get('plugins', {}).get(KEY % market, [])
    if not records:
        return 'there is no %s record to set' % (KEY % market)
    sha = opts.get('--sha') or next((r.get('gitCommitSha') for r in records if r.get('version') == version), None)
    if not sha:
        return 'no record is on %s yet, so give its commit with --sha' % version
    now = datetime.datetime.now(datetime.timezone.utc).strftime('%Y-%m-%dT%H:%M:%S.000Z')
    was = {}
    for record in records:
        was[record.get('version')] = was.get(record.get('version'), 0) + 1
        record.update(version=version, installPath=folder, gitCommitSha=sha, lastUpdated=now)
    shutil.copyfile(records_path(plugins), records_path(plugins) + '.ck-backup')
    tmp = records_path(plugins) + '.ck-tmp'
    with open(tmp, 'w') as f:
        json.dump(data, f, indent=2)
    os.replace(tmp, records_path(plugins))
    print('%s: %d records on %s (they were %s)' % (KEY % market, len(records), version,
                                                    ', '.join('%s x%d' % kv for kv in sorted(was.items()))))
    return None


def cmd_check(args, opts):
    root = os.path.abspath(opts.get('--root') or os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
    try:
        cwd = json.loads(sys.stdin.read() or '{}').get('cwd') or os.getcwd()
    except ValueError:
        cwd = os.getcwd()
    parts = root.split(os.sep)
    if len(parts) < 5 or parts[-4] != 'cache' or parts[-2] != 'ck':
        return None                                          # not loaded from the plugin cache
    plugins, market = os.sep.join(parts[:-4]), parts[-3]
    with open(os.path.join(root, '.claude-plugin', 'plugin.json')) as f:
        loaded = json.load(f).get('version')
    with open(records_path(plugins)) as f:
        records = json.load(f).get('plugins', {}).get(KEY % market, [])
    main = cwd.split(os.sep + '.claude' + os.sep + 'worktrees' + os.sep)[0].rstrip(os.sep)
    want = next((r.get('version') for r in records if (r.get('projectPath') or '').rstrip(os.sep) == main), None)
    if want and want != loaded:
        print('ck %s is loaded in this session, but %s is installed at ck %s: Claude Code read an older '
              'worktree\'s install record first, so stage names and cards here come from ck %s. Run '
              '`python3 "%s" set %s` and start a new session.'
              % (loaded, main, want, loaded, os.path.abspath(__file__), want))
    return None


def loaded_in(folder, market):
    """The ck version a fresh session in this folder loads from the marketplace, or None."""
    claude = os.environ.get('CK_CLAUDE', 'claude')
    try:
        out = subprocess.run([claude] + PROBE, cwd=folder, capture_output=True, text=True, timeout=180).stdout
    except (OSError, subprocess.TimeoutExpired):
        return None
    for line in out.splitlines():
        try:
            event = json.loads(line)
        except ValueError:
            continue
        if event.get('subtype') == 'init':
            return next((p.get('version') for p in event.get('plugins', [])
                         if p.get('name') == 'ck' and p.get('source') == KEY % market), None)
    return None


def cmd_verify(args, opts):
    if not args:
        return 'usage: installs.py verify <version> [--marketplace ck-next] [--plugins <dir>] [<folder> ...]'
    version, folders, market = args[0], args[1:], opts.get('--marketplace', 'ck-next')
    if not folders:
        with open(records_path(plugins_dir(opts))) as f:
            records = json.load(f).get('plugins', {}).get(KEY % market, [])
        folders = sorted({r['projectPath'] for r in records if r.get('projectPath')
                          and '/.claude/worktrees/' not in r['projectPath'] and os.path.isdir(r['projectPath'])})
    if not folders:
        return 'there is no folder with a %s install to verify' % (KEY % market)
    wrong = 0
    for folder in folders:
        got = loaded_in(folder, market)
        wrong += got != version
        print('%s  %s: a fresh session loads %s' % ('ok  ' if got == version else 'FAIL', folder,
                                                    'ck ' + got if got else 'no ck from ' + market))
    return '%d of %d folders do not load ck %s' % (wrong, len(folders), version) if wrong else None


def main(argv):
    args, opts, i = [], {}, 0
    while i < len(argv):
        if argv[i].startswith('--') and i + 1 < len(argv):
            opts[argv[i]], i = argv[i + 1], i + 2
        else:
            args.append(argv[i])
            i += 1
    if not args or args[0] not in ('set', 'check', 'verify'):
        print(__doc__.strip(), file=sys.stderr)
        return 2
    if args[0] == 'check':
        try:
            cmd_check(args[1:], opts)
        except (OSError, ValueError, AttributeError):
            pass                                             # a hook never blocks a session
        return 0
    problem = (cmd_set if args[0] == 'set' else cmd_verify)(args[1:], opts)
    if problem:
        print('installs.py: ' + problem, file=sys.stderr)
        return 1
    return 0


if __name__ == '__main__':
    sys.exit(main(sys.argv[1:]))
