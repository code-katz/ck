#!/usr/bin/env python3
"""claude-md.py: read and write the "How we work" section that /ck:claude-md tailors for a project.

Usage:
  claude-md.py status FILE [--templates DIR]
  claude-md.py template [--templates DIR]
  claude-md.py diff FROM TO [--templates DIR]
  claude-md.py write FILE --section DRAFT [--templates DIR]

The section is every line from the opening marker, <!-- ck:how-we-work VERSION -->, to the
closing marker, <!-- /ck:how-we-work -->, both included. VERSION names the template it was
tailored from. ck ships one template per version, as templates/how-we-work/VERSION.md beside
this script's folder; the newest is the current one.

status prints the file's state, one of:
  none     no file, or a file with no markers (and whether it has a "## How we work" heading)
  stamped  a section with its version, and whether a newer template has shipped since
  broken   an opening with no end, an end with no opening, two of either, or a missing version
template prints the current template's version and path. diff prints the change between two
shipped templates. write puts DRAFT, a tailored section with both markers and a version, in
place of the file's section: a missing file is created with a "## How we work" heading and the
section, a file whose section is already DRAFT is left alone, and every byte outside the
section is kept as it was. write refuses a broken file, a file with no markers, and a draft
with a blank still in it ({{...}}), and names why.

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
BLANK_RE = re.compile(r'\{\{[^{}\n]*\}\}')
HEADING_RE = re.compile(r'##\s+How we work\s*')
TEMPLATES = os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), 'templates', 'how-we-work')
USAGE = ('usage: claude-md.py status FILE | template | diff FROM TO | write FILE --section DRAFT'
         ' [--templates DIR]')


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
    """A version as a tuple of numbers, or None when it is missing or not a version."""
    if text is None or not VERSION_RE.fullmatch(text):
        return None
    return tuple(int(part) for part in text.split('.'))


def marker(line, pattern):
    return pattern.fullmatch(line.rstrip('\r\n').rstrip())


def find(lines):
    """The section's first and last line indexes, or None when there are no markers.

    Raises Refuse with the line to look at when the markers are broken."""
    opens = [i for i, line in enumerate(lines) if marker(line, OPEN_RE)]
    closes = [i for i, line in enumerate(lines) if marker(line, CLOSE_RE)]
    if not opens and not closes:
        return None
    if len(opens) > 1:
        raise Refuse('line %d opens a second ck:how-we-work section; the first opens on line %d' % (opens[1] + 1, opens[0] + 1))
    if len(closes) > 1:
        raise Refuse('line %d closes a second ck:how-we-work section; the first closes on line %d' % (closes[1] + 1, closes[0] + 1))
    if not closes:
        raise Refuse('line %d opens the ck:how-we-work section and no line closes it' % (opens[0] + 1))
    if not opens:
        raise Refuse('line %d closes a ck:how-we-work section that no line opens' % (closes[0] + 1))
    if closes[0] < opens[0]:
        raise Refuse('line %d closes the ck:how-we-work section before line %d opens it' % (closes[0] + 1, opens[0] + 1))
    return opens[0], closes[0]


def shipped(folder):
    """Every shipped template, as {version text: path}."""
    try:
        names = os.listdir(folder)
    except OSError:
        raise Fail('cannot read the templates folder %s' % folder)
    found = {n[:-3]: os.path.join(folder, n) for n in names if n.endswith('.md') and version(n[:-3])}
    if not found:
        raise Fail('no template in %s' % folder)
    return found


def current(folder):
    found = shipped(folder)
    newest = max(found, key=version)
    return newest, found[newest]


def section(text, what):
    """Check that text is one whole section with a version, and return the version and the text."""
    if not text.endswith('\n'):
        text += '\n'
    lines = text.splitlines(keepends=True)
    opening = marker(lines[0], OPEN_RE) if lines else None
    try:
        whole = find(lines) == (0, len(lines) - 1)
    except Refuse:
        whole = False
    if not opening or version(opening.group(1)) is None or not whole:
        raise Fail('%s is not one ck:how-we-work section with a version on its opening line' % what)
    return opening.group(1), text


def status(path, folder):
    newest, _ = current(folder)
    if not os.path.exists(path):
        return ['state: none', 'file: absent', 'heading: no', 'template: %s' % newest]
    lines = read(path).splitlines(keepends=True)
    heading = 'yes' if any(HEADING_RE.fullmatch(l.rstrip('\r\n')) for l in lines) else 'no'
    try:
        span = find(lines)
    except Refuse as broken:
        return ['state: broken', 'file: present', 'reason: %s' % broken, 'template: %s' % newest]
    if span is None:
        return ['state: none', 'file: present', 'heading: %s' % heading, 'template: %s' % newest]
    first, last = span
    stamp = marker(lines[first], OPEN_RE).group(1)
    if version(stamp) is None:
        return ['state: broken', 'file: present', 'reason: line %d opens the section with no version' % (first + 1), 'template: %s' % newest]
    return ['state: stamped', 'file: present', 'section: lines %d-%d' % (first + 1, last + 1), 'stamp: %s' % stamp,
            'template: %s' % newest, 'behind: %s' % ('yes' if version(stamp) < version(newest) else 'no')]


def diff(old, new, folder):
    found = shipped(folder)
    for v in (old, new):
        if v not in found:
            raise Refuse('ck has no template %s; it has %s' % (v, ', '.join(sorted(found, key=version))))
    a, b = read(found[old]), read(found[new])
    return [line.rstrip('\n') for line in difflib.unified_diff(
        a.splitlines(keepends=True), b.splitlines(keepends=True), 'template %s' % old, 'template %s' % new)]


def write(path, draft_path, folder):
    stamp, draft = section(read(draft_path), draft_path)
    if stamp not in shipped(folder):
        raise Refuse('not written: %s is stamped %s, and ck has no template %s' % (draft_path, stamp, stamp))
    blanks = BLANK_RE.findall(draft)
    if blanks:
        raise Refuse('not written: %s still has a blank to fill: %s' % (draft_path, ', '.join(sorted(set(blanks)))))
    if not os.path.exists(path):
        text = '## How we work\n\n' + draft
        was = 'new file'
    else:
        lines = read(path).splitlines(keepends=True)
        try:
            span = find(lines)
        except Refuse as broken:
            raise Refuse('not written: %s: %s' % (path, broken))
        if span is None:
            raise Refuse('not written: %s has no ck:how-we-work markers; put an empty pair, '
                         '<!-- ck:how-we-work --> and <!-- /ck:how-we-work -->, where the section goes' % path)
        first, last = span
        old = ''.join(lines[first:last + 1])
        if old == draft or old + '\n' == draft:
            return ['unchanged: %s already has this section' % path]
        text = ''.join(lines[:first]) + draft + ''.join(lines[last + 1:])
        was = 'was stamped %s' % (marker(lines[first], OPEN_RE).group(1) or 'none')
    try:
        with open(path, 'w', encoding='utf-8', newline='') as f:
            f.write(text)
    except OSError as error:
        raise Fail('cannot write %s: %s' % (path, error.strerror or type(error).__name__))
    return ['wrote: %s, section stamped %s (%s)' % (path, stamp, was)]


def run(argv):
    args, opts = [], {'--templates': TEMPLATES, '--section': None}
    i = 0
    while i < len(argv):
        if argv[i] in opts and i + 1 < len(argv):
            opts[argv[i]] = argv[i + 1]
            i += 2
            continue
        if argv[i].startswith('--'):
            raise Fail(USAGE)
        args.append(argv[i])
        i += 1
    folder = opts['--templates']
    if args[:1] == ['status'] and len(args) == 2:
        return 0, status(args[1], folder)
    if args == ['template']:
        newest, path = current(folder)
        return 0, ['template: %s' % newest, 'path: %s' % path]
    if args[:1] == ['diff'] and len(args) == 3:
        return 0, diff(args[1], args[2], folder)
    if args[:1] == ['write'] and len(args) == 2 and opts['--section']:
        return 0, write(args[1], opts['--section'], folder)
    raise Fail(USAGE)


def main(argv):
    try:
        try:
            status_code, lines = run(argv)
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
        return status_code
    except KeyboardInterrupt:
        return 130
    except Exception:
        return 2


if __name__ == '__main__':
    sys.exit(main(sys.argv[1:]))
