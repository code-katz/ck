#!/usr/bin/env python3
"""claude-md.py: read and write the general block of a project's CLAUDE.md, ck's "How we work" rules.

Usage:
  claude-md.py status FILE [--template PATH]
  claude-md.py diff FILE [--template PATH]
  claude-md.py write FILE [--template PATH]

The block is every line from the opening marker, <!-- ck:how-we-work VERSION -->, to the
closing marker, <!-- /ck:how-we-work -->, both included. The template (by default
templates/how-we-work.md beside this script) is that block as ck ships it, markers and all.

status prints the file's state, one of:
  none     no file, or a file with no markers
  current  the block is the template, byte for byte
  behind   the block's stamp is older than the template's, or it has none
  edited   the block differs from the template and its stamp is not older
  broken   an opening with no end, an end with no opening, or two of either
and the lines it found. diff prints the change from the block to the template. write puts
the template in place of the block; a file that is current is left alone, a missing file is
created with a "## How we work" heading and the block, and every byte outside the block is
kept as it was. write refuses a broken file and a file with no markers, and names why.

Standard library only. A usage error or an unreadable file is one plain line on stderr and
exit status 2, never a traceback. A refusal is one plain line on stdout and exit status 1.
"""
import difflib
import os
import re
import sys

OPEN_RE = re.compile(r'<!-- ck:how-we-work(?: (\S+))? -->')
CLOSE_RE = re.compile(r'<!-- /ck:how-we-work -->')
VERSION_RE = re.compile(r'[0-9]{1,6}(?:\.[0-9]{1,6}){0,3}')
TEMPLATE = os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), 'templates', 'how-we-work.md')
USAGE = 'usage: claude-md.py status|diff|write FILE [--template PATH]'


class Fail(Exception):
    """One plain line for stderr. The run ends with status 2."""


class Refuse(Exception):
    """One plain line for stdout. The run ends with status 1."""


def read(path):
    try:
        with open(path, encoding='utf-8', newline='') as f:
            return f.read()
    except UnicodeDecodeError:
        raise Fail('%s is not UTF-8 text' % path)
    except OSError as error:
        raise Fail('cannot read %s: %s' % (path, error.strerror or type(error).__name__))


def version(text):
    """A stamp as a tuple of numbers, or None when it is missing or not a version."""
    if text is None or not VERSION_RE.fullmatch(text):
        return None
    return tuple(int(part) for part in text.split('.'))


def marker(line, pattern):
    return pattern.fullmatch(line.rstrip('\r\n').rstrip())


def load_template(path):
    text = read(path)
    lines = text.splitlines(keepends=True)
    opening = marker(lines[0], OPEN_RE) if lines else None
    if not opening or version(opening.group(1)) is None or not marker(lines[-1], CLOSE_RE):
        raise Fail('%s is not a ck:how-we-work block with a version on its opening line' % path)
    if not text.endswith('\n'):
        text += '\n'
    return text, opening.group(1)


def find(lines):
    """The block's first and last line indexes, or None when there are no markers.

    Raises Refuse with the line to look at when the markers are broken."""
    opens = [i for i, line in enumerate(lines) if marker(line, OPEN_RE)]
    closes = [i for i, line in enumerate(lines) if marker(line, CLOSE_RE)]
    if not opens and not closes:
        return None
    if len(opens) > 1:
        raise Refuse('line %d opens a second ck:how-we-work block; the first opens on line %d' % (opens[1] + 1, opens[0] + 1))
    if len(closes) > 1:
        raise Refuse('line %d closes a second ck:how-we-work block; the first closes on line %d' % (closes[1] + 1, closes[0] + 1))
    if not closes:
        raise Refuse('line %d opens the ck:how-we-work block and no line closes it' % (opens[0] + 1))
    if not opens:
        raise Refuse('line %d closes a ck:how-we-work block that no line opens' % (closes[0] + 1))
    if closes[0] < opens[0]:
        raise Refuse('line %d closes the ck:how-we-work block before line %d opens it' % (closes[0] + 1, opens[0] + 1))
    return opens[0], closes[0]


def inspect(path, template_path):
    """Everything status, diff, and write need: a dict with the state and what was found."""
    template, template_version = load_template(template_path)
    found = {'path': path, 'template': template, 'template_version': template_version}
    if not os.path.exists(path):
        return dict(found, state='none', present=False)
    text = read(path)
    lines = text.splitlines(keepends=True)
    found.update(present=True, text=text, lines=lines)
    try:
        span = find(lines)
    except Refuse as broken:
        return dict(found, state='broken', reason=str(broken))
    if span is None:
        return dict(found, state='none')
    first, last = span
    block = ''.join(lines[first:last + 1])
    if not block.endswith('\n'):
        block += '\n'
    stamp = marker(lines[first], OPEN_RE).group(1)
    if block == template:
        state = 'current'
    elif version(stamp) is None or version(stamp) < version(template_version):
        state = 'behind'
    else:
        state = 'edited'
    return dict(found, state=state, first=first, last=last, block=block, stamp=stamp)


def report(found):
    out = ['state: %s' % found['state'], 'file: %s' % ('present' if found['present'] else 'absent')]
    if found['state'] == 'broken':
        out.append('reason: %s' % found['reason'])
    if 'first' in found:
        out.append('block: lines %d-%d' % (found['first'] + 1, found['last'] + 1))
        out.append('stamp: %s' % (found['stamp'] or 'none'))
    out.append('template: %s' % found['template_version'])
    return out


def diff(found):
    if found['state'] == 'broken':
        raise Refuse('%s: %s' % (found['path'], found['reason']))
    if 'block' not in found:
        raise Refuse('%s has no ck:how-we-work block to compare' % found['path'])
    return [line.rstrip('\n') for line in difflib.unified_diff(
        found['block'].splitlines(keepends=True), found['template'].splitlines(keepends=True),
        'in %s' % found['path'], 'ck template %s' % found['template_version'])]


def write(found):
    path, template = found['path'], found['template']
    if found['state'] == 'broken':
        raise Refuse('not written: %s: %s' % (path, found['reason']))
    if found['state'] == 'current':
        return ['unchanged: %s already has template %s' % (path, found['template_version'])]
    if not found['present']:
        text = '## How we work\n\n' + template
    elif 'first' not in found:
        raise Refuse('not written: %s has no ck:how-we-work markers; put an empty pair, '
                     '<!-- ck:how-we-work --> and <!-- /ck:how-we-work -->, where the block goes' % path)
    else:
        lines = found['lines']
        text = ''.join(lines[:found['first']]) + template + ''.join(lines[found['last'] + 1:])
    try:
        with open(path, 'w', encoding='utf-8', newline='') as f:
            f.write(text)
    except OSError as error:
        raise Fail('cannot write %s: %s' % (path, error.strerror or type(error).__name__))
    was = 'new file' if not found['present'] else 'was %s, stamp %s' % (found['state'], found['stamp'] or 'none')
    return ['wrote: %s, template %s (%s)' % (path, found['template_version'], was)]


def run(argv):
    args, template = [], TEMPLATE
    i = 0
    while i < len(argv):
        if argv[i] == '--template' and i + 1 < len(argv):
            template = argv[i + 1]
            i += 2
            continue
        if argv[i].startswith('--'):
            raise Fail(USAGE)
        args.append(argv[i])
        i += 1
    if len(args) != 2 or args[0] not in ('status', 'diff', 'write'):
        raise Fail(USAGE)
    command, path = args
    found = inspect(path, template)
    if command == 'status':
        return 0, report(found)
    if command == 'diff':
        return 0, diff(found)
    return 0, write(found)


def main(argv):
    try:
        try:
            status, lines = run(argv)
        except Fail as failure:
            print(str(failure).replace('\n', ' '), file=sys.stderr)
            return 2
        except Refuse as refusal:
            print(str(refusal).replace('\n', ' '))
            return 1
        except Exception as error:                           # never a traceback, whatever the input
            print('claude-md.py could not finish: %s' % type(error).__name__, file=sys.stderr)
            return 2
        for line in lines:
            print(line)
        return status
    except KeyboardInterrupt:
        return 130
    except Exception:
        return 2


if __name__ == '__main__':
    sys.exit(main(sys.argv[1:]))
