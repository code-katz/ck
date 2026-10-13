#!/usr/bin/env python3
"""proof-guard.py: refuse a file that a proof must not publish.

Usage:
  proof-guard.py FILE

Run it inside the project, on one file. FILE is read from the folder the command runs in, and
where it leads counts, not how it is spelled: a link is judged by the file at its end.

  status 0    The file may be published as a proof. Nothing is printed.
  status 1    The file is refused: one sentence on stdout names the reason, and repeats nothing
              from inside the file.
  any other   The guard could not answer: one line on stderr. That is never a refusal, and
              never a yes.

A file is refused when it is outside the repository the command runs in; not there, or not a
file; inside .ck/, the run cache, or .git/; written by a pipeline command, which is every
document /ck:next looks for and any plan under docs/plan/; ignored by git; not a .md file; not
UTF-8 text; or empty. The file is opened only for the last two. Standard library only. Needs
git on PATH.
"""
import os
import subprocess
import sys

# The documents the pipeline commands write, as the look in skills/next/SKILL.md lists them, each
# with the command that writes it. The suite reads that look at run time and tries every document
# in it against the guard, so a document added there without a line here fails the suite.
OWNED = {
    'docs/opportunity.md': 'opportunity',
    'docs/market-research.md': 'market-research',
    'docs/brief.md': 'brief',
    'docs/TEAM.md': 'team',
    'docs/PRD.md': 'prd',
    'ROADMAP.md': 'roadmap',
    'docs/ARCHITECTURE.md': 'architecture',
    'docs/brand-guide.md': 'brand-guide',
    'docs/build-plan.md': 'plan',
}
PLANS = 'docs/plan'      # every plan for one piece of work: the folder belongs to /ck:plan
CACHE = '.ck'            # the run cache; a command tells git to ignore it when it first mints a run
GIT = '.git'             # git's own files, which check-ignore does not report as ignored


class Fail(Exception):
    """One plain line for stderr: the guard could not answer. Status 2."""


class Refuse(Exception):
    """One sentence for stdout: the file is not published. Status 1."""


def run_git(*args):
    """(status, stdout, the first line of stderr) of a git command."""
    try:
        done = subprocess.run(['git', *args], capture_output=True, stdin=subprocess.DEVNULL)
    except OSError:
        raise Fail('proof-guard.py needs git on PATH') from None
    return (done.returncode, done.stdout.decode('utf-8', 'surrogateescape').strip(),
            done.stderr.decode('utf-8', 'replace').strip().split('\n')[0])


def shown(path):
    """The path as typed, kept to one line: a character that cannot be printed becomes a space."""
    return ''.join(c if c.isprintable() else ' ' for c in path)


def same(a, b):
    """True when two paths lead to one file. A file system that ignores case says so here, where
    the spelling of a path cannot."""
    try:
        return os.path.samefile(a, b)
    except OSError:
        return False


def inside(resolved, top, folder):
    """True when the file is under top/folder, however the path spells the folder."""
    target = os.path.join(top, folder)
    parent = os.path.dirname(resolved)
    while len(parent) > len(top):
        if same(parent, target):
            return True
        parent = os.path.dirname(parent)
    return False


def owner(resolved, top, rel):
    """The command that writes this file, or None."""
    if rel in OWNED:
        return OWNED[rel]
    for path, command in OWNED.items():
        if same(resolved, os.path.join(top, path)):
            return command
    if rel.startswith(PLANS + '/') or inside(resolved, top, PLANS):
        return 'plan'
    return None


def check(path):
    """Returns when the file may be published; raises Refuse or Fail otherwise."""
    status, out, err = run_git('rev-parse', '--show-toplevel')
    if status:
        raise Fail(err or 'git rev-parse stopped with status %d' % status)
    top = os.path.realpath(out)
    # The folder the command runs in is resolved first, so that a link on the way to it (such as
    # /var on macOS) does not count as a link on the way to the file.
    spelled = os.path.normpath(os.path.join(os.path.realpath(os.getcwd()), path))
    resolved = os.path.realpath(spelled)
    name = shown(path)
    be = '%s leads to a file that is' % name if resolved != spelled else '%s is' % name
    if os.path.commonpath([resolved, top]) != top:
        raise Refuse('%s outside the repository, and a proof publishes only a file inside it.' % be)
    if not os.path.exists(resolved):
        raise Refuse('%s not there.' % be)
    if os.path.isdir(resolved):
        raise Refuse('%s a folder, not a file.' % ('%s leads to' % name if resolved != spelled else '%s is' % name))
    if not os.path.isfile(resolved):
        raise Refuse('%s is not a file.' % name)
    rel = os.path.relpath(resolved, top)
    if rel.startswith(CACHE + '/') or inside(resolved, top, CACHE):
        raise Refuse('%s inside .ck/, the run cache, which is never published.' % be)
    if rel.startswith(GIT + '/') or inside(resolved, top, GIT):
        raise Refuse('%s inside .git/, which holds the repository itself and is never published.' % be)
    command = owner(resolved, top, rel)
    if command:
        raise Refuse('%s written by /ck:%s: run that command for its proof.' % (be, command))
    # Git is asked about the file where it is, not where the path started: a link to an ignored
    # file is itself not ignored. A tracked file is not ignored whatever the rules say, which is
    # git's own reading; the security read of this guard decides whether that is enough.
    status, _, err = run_git('-C', top, 'check-ignore', '-q', '--', rel)
    if status == 0:
        raise Refuse('%s ignored by git, and a file git ignores is never published.' % be)
    if status != 1:
        raise Fail(err or 'git check-ignore stopped with status %d' % status)
    if os.path.splitext(rel)[1].lower() != '.md':
        raise Refuse('%s not markdown, and a proof is made from a .md file.' % be)
    try:
        with open(resolved, 'rb') as handle:
            data = handle.read()
    except OSError as error:
        raise Fail('cannot read %s: %s' % (name, error.strerror or 'it is not a file')) from None
    try:
        text = data.decode('utf-8-sig')                      # a byte order mark is not a word
    except UnicodeDecodeError:
        raise Refuse('%s not UTF-8 text, so it cannot be read as markdown.' % be) from None
    if not text.split():
        raise Refuse('%s empty: it has no words to publish.' % be)


def emit(stream, text):
    try:
        stream.buffer.write((text + '\n').encode('utf-8', 'replace'))
        stream.buffer.flush()
    except BrokenPipeError:
        os.dup2(os.open(os.devnull, os.O_WRONLY), stream.fileno())   # the reader left; stay quiet


def one_line(text):
    return text.replace('\r', ' ').replace('\n', ' ')


def main(argv):
    try:
        # Status 0 means yes, so even the help leaves with another status: nothing was checked.
        if argv in (['-h'], ['--help']):
            emit(sys.stdout, __doc__.strip())
            return 2
        if len(argv) != 1 or not argv[0] or argv[0].startswith('-'):
            emit(sys.stderr, 'usage: proof-guard.py FILE')
            return 2
        try:
            check(argv[0])
        except Fail as failure:
            emit(sys.stderr, one_line(str(failure)))
            return 2
        except Refuse as refusal:
            emit(sys.stdout, one_line(str(refusal)))
            return 1
        except Exception as error:                           # never a traceback, whatever the input
            emit(sys.stderr, 'proof-guard.py could not finish: %s' % type(error).__name__)
            return 2
        return 0
    except KeyboardInterrupt:
        return 130
    except Exception:
        return 2


if __name__ == '__main__':
    sys.exit(main(sys.argv[1:]))
