#!/usr/bin/env python3
"""render-proof.py: turn a markdown document into a self-contained proof, the page a document is reviewed on.

Usage:
  render-proof.py --in docs/PRD.md --out .ck/runs/<id>/review.html --title "Ardennes Hour PRD" \
      [--question "Imagine this shipped and did not move the number. What went wrong?"] [--meta "Revision 1"]

Standard library only. The page carries the four comment steps in its banner, a sticky
table of contents from the ## and ### headings, tables and code that scroll inside their
own container, and light and dark themes. Publish the output with the Artifact tool.

A file that holds a key shape is refused before anything is rendered: the status is 1, no
page is written, and the message names each line and never prints the key. The check knows
seven shapes and is not a secret scanner.
"""
import argparse, html, re, pathlib, sys

def slug(text):
    s = re.sub(r'[^a-z0-9]+', '-', text.lower()).strip('-')
    return s or 'section'

def inline(text):
    # Code spans and the opening tag of a link are lifted out first. Bold and emphasis can then
    # run across the whole line, and they can never reach inside a tag: a bold phrase that
    # contains a code span would otherwise never match, and an address that holds asterisks
    # would be rewritten. A quote in an address would end the href and start an attribute of
    # the author's choosing, so the address is percent-encoded here, once, before it is held.
    held = []
    def hold(tag):
        held.append(tag)
        return '\x00%d\x00' % (len(held) - 1)
    def link(m):
        address = m.group(2).replace('"', '%22').replace("'", '%27')
        return hold('<a href="' + address + '">') + m.group(1) + '</a>'
    p = re.sub(r'`([^`\n]*)`', lambda m: hold('<code>' + html.escape(m.group(1)) + '</code>'), text)
    p = html.escape(p, quote=False)
    p = re.sub(r'\[([^\]]+)\]\((https?://[^)\s\x00]+)\)', link, p)
    p = re.sub(r'\*\*(.+?)\*\*', r'<strong>\1</strong>', p)
    p = re.sub(r'(?<![\w*])\*(?!\s)(.+?)(?<!\s)\*(?![\w*])', r'<em>\1</em>', p)
    return re.sub(r'\x00(\d+)\x00', lambda m: held[int(m.group(1))], p)

CODE_SPAN = re.compile(r'`[^`\n]*`')

def split_row(line):
    # A bar ends a cell, with two exceptions. A bar after a backslash belongs to the cell, and
    # the backslash is dropped. A bar inside a code span belongs to the cell, and a code span is
    # what inline() reads as one: the same pattern. A backslash before another backslash is
    # kept as two, so that \\| is a backslash and then the end of a cell.
    s = line.strip()
    if s.startswith('|'): s = s[1:]
    cells, cur, i = [], [], 0
    while i < len(s):
        c = s[i]
        span = CODE_SPAN.match(s, i) if c == '`' else None
        if c == '\\' and s[i + 1:i + 2] in ('|', '\\'):
            cur.append('|' if s[i + 1] == '|' else '\\\\'); i += 2
        elif span:
            cur.append(span.group().replace('\\|', '|')); i = span.end()
        elif c == '|':
            cells.append(''.join(cur).strip()); cur = []; i += 1
        else:
            cur.append(c); i += 1
    last = ''.join(cur).strip()
    if last: cells.append(last)  # no last cell when the row ends with a bar
    return cells

# The seven shapes of a key, each with a beginning and a length, so that a beginning alone, or
# a word that holds one (risk-based, task-list, desk-bound), is not a key. A shape that starts
# with a letter must not follow a letter or digit, which is what keeps those words out. This is
# a check for the shapes that did the most harm, not a secret scanner.
KEY_SHAPES = [
    ('an AWS access key id', re.compile(r'(?<![A-Za-z0-9])(?:AKIA|ASIA)[0-9A-Z]{16}')),
    ('a private key header', re.compile(r'-----BEGIN [A-Z ]*PRIVATE KEY(?: BLOCK)?-----')),
    ('an sk- or sk_ key', re.compile(r'(?<![A-Za-z0-9])sk[-_][A-Za-z0-9_-]{20,}')),
    ('a GitHub token', re.compile(r'(?<![A-Za-z0-9])(?:gh[pousr]_[A-Za-z0-9]{36,}|github_pat_[A-Za-z0-9_]{22,})')),
    ('a Slack token', re.compile(r'(?<![A-Za-z0-9])xox[abprs]-[A-Za-z0-9-]{10,}')),
    ('a Google API key', re.compile(r'(?<![A-Za-z0-9])AIza[0-9A-Za-z_-]{35}')),
    # The dash is in the boundary so that eyJeyJeyJ... is tried once, not at every eyJ: the match
    # then takes time in proportion to the line, and a long line cannot stall the render.
    ('a JSON web token', re.compile(r'(?<![A-Za-z0-9_-])eyJ[A-Za-z0-9_-]{10,}\.eyJ[A-Za-z0-9_-]{10,}\.[A-Za-z0-9_-]{10,}')),
]

def find_keys(md):
    # One hit per line, in line order: (line number, the shape's name). The whole text is read,
    # code fences included, because a key most often sits in one. The text of a hit is never kept.
    hits = []
    for number, line in enumerate(md.split('\n'), 1):
        for name, shape in KEY_SHAPES:
            if shape.search(line):
                hits.append((number, name)); break
    return hits

def refusal(src, hits):
    shown = ['  line %d: %s' % hit for hit in hits[:10]]
    if len(hits) > 10: shown.append('  and %d more lines' % (len(hits) - 10))
    return '\n'.join(['refused: %s holds what looks like a key. No page was written.' % src] + shown + [
        'Take each key out of the file, name the setting and not its value, and render again.',
        'This check knows seven key shapes and is not a secret scanner: a file that passes it has not been searched for secrets.'])

def render(md):
    lines = md.split('\n')
    out, toc = [], []
    i, n = 0, len(lines)
    para = []
    def flush_para():
        if para:
            out.append('<p>' + inline(' '.join(s.strip() for s in para)) + '</p>')
            para.clear()
    list_stack = []  # (indent, tag)
    def close_lists(to_indent=-1):
        while list_stack and list_stack[-1][0] > to_indent:
            out.append('</li></' + list_stack.pop()[1] + '>')
    while i < n:
        line = lines[i]
        stripped = line.strip()
        # fenced code
        if stripped.startswith('```'):
            flush_para(); close_lists()
            fence = stripped[:3]
            lang = stripped[3:].strip().lower()
            buf = []
            i += 1
            while i < n and not lines[i].strip().startswith(fence):
                buf.append(lines[i]); i += 1
            if lang == 'mermaid':
                out.append('<pre class="mermaid">' + html.escape('\n'.join(buf)) + '</pre>')
            else:
                out.append('<pre><code>' + html.escape('\n'.join(buf)) + '</code></pre>')
            i += 1
            continue
        if stripped.startswith('````'):
            i += 1; continue
        # heading
        m = re.match(r'^(#{1,4})\s+(.*)$', line)
        if m:
            flush_para(); close_lists()
            level = len(m.group(1)); text = m.group(2).strip()
            if level == 1:
                i += 1; continue  # the banner carries the title
            sid = slug(re.sub(r'`', '', text))
            if level in (2, 3): toc.append((level, sid, re.sub(r'`', '', text)))
            out.append(f'<h{level} id="{sid}">{inline(text)} <a class="anchor" href="#{sid}" aria-label="Link to this section">§</a></h{level}>')
            i += 1; continue
        # hr
        if re.match(r'^\s*(-{3,}|\*{3,})\s*$', line):
            flush_para(); close_lists(); out.append('<hr>'); i += 1; continue
        # table
        if stripped.startswith('|') and i + 1 < n and re.match(r'^\s*\|?\s*:?-{2,}', lines[i + 1]):
            flush_para(); close_lists()
            header = split_row(stripped)
            i += 2
            rows = []
            while i < n and lines[i].strip().startswith('|'):
                rows.append(split_row(lines[i])); i += 1
            out.append('<div class="table-wrap"><table><thead><tr>' + ''.join('<th>' + inline(c) + '</th>' for c in header) + '</tr></thead><tbody>')
            for r in rows:
                out.append('<tr>' + ''.join('<td>' + inline(c) + '</td>' for c in r) + '</tr>')
            out.append('</tbody></table></div>')
            continue
        # blockquote
        if stripped.startswith('>'):
            flush_para(); close_lists()
            buf = []
            while i < n and lines[i].strip().startswith('>'):
                buf.append(lines[i].strip()[1:].strip()); i += 1
            out.append('<blockquote>' + ''.join('<p>' + inline(b) + '</p>' for b in buf if b) + '</blockquote>')
            continue
        # list item
        m = re.match(r'^(\s*)([-*]|\d+\.)\s+(.*)$', line)
        if m:
            flush_para()
            indent = len(m.group(1)); tag = 'ol' if m.group(2)[0].isdigit() else 'ul'
            text = m.group(3)
            cls = ''
            if text.startswith('[ ] '): text = text[4:]; cls = ' class="task"'
            elif text.startswith('[x] '): text = text[4:]; cls = ' class="task done"'
            if list_stack and indent > list_stack[-1][0]:
                out.append('<' + tag + '><li' + cls + '>' + inline(text)); list_stack.append((indent, tag))
            else:
                close_lists(indent)
                if list_stack and list_stack[-1][0] == indent:
                    out.append('</li><li' + cls + '>' + inline(text))
                else:
                    out.append('<' + tag + '><li' + cls + '>' + inline(text)); list_stack.append((indent, tag))
            i += 1; continue
        # blank
        if not stripped:
            flush_para()
            if list_stack and (i + 1 >= n or not re.match(r'^\s*([-*]|\d+\.)\s+', lines[i + 1])):
                close_lists()
            i += 1; continue
        # continuation of a list item
        if list_stack and line.startswith(' '):
            out.append(' ' + inline(stripped)); i += 1; continue
        para.append(line); i += 1
    flush_para(); close_lists()
    return '\n'.join(out), toc

def toc_html(toc):
    if not toc: return ''
    h = ['<ul>']; depth = 2
    for level, sid, text in toc:
        if level > depth: h.append('<ul>'); depth = level
        while level < depth: h.append('</ul>'); depth -= 1
        h.append(f'<li><a href="#{sid}">{html.escape(text)}</a></li>')
    while depth > 2: h.append('</ul>'); depth -= 1
    h.append('</ul>')
    return '\n'.join(h)

CSS = """
:root{--bg:#faf9f5;--ink:#141413;--muted:#5f5d55;--rule:#e8e6dc;--rule-strong:#b0aea5;--surface:#f2f0e8;--accent:#d97757;--link:#a3492a;--banner:#141413;--banner-ink:#faf9f5;--banner-muted:#b0aea5}
@media (prefers-color-scheme:dark){:root:not([data-theme="light"]){--bg:#141413;--ink:#faf9f5;--muted:#b0aea5;--rule:#2b2a26;--rule-strong:#4a4842;--surface:#1e1d1a;--link:#e69a74;--banner:#1e1d1a}}
:root[data-theme="dark"]{--bg:#141413;--ink:#faf9f5;--muted:#b0aea5;--rule:#2b2a26;--rule-strong:#4a4842;--surface:#1e1d1a;--link:#e69a74;--banner:#1e1d1a}
*{box-sizing:border-box}body{margin:0;background:var(--bg);color:var(--ink);font:400 17px/1.65 Georgia,'Times New Roman',serif}
a{color:var(--link)}.banner{background:var(--banner);color:var(--banner-ink);border-bottom:3px solid var(--accent)}
.banner-inner{max-width:1180px;margin:0 auto;padding:32px 24px 28px;display:grid;gap:18px}
.eyebrow{font:500 12px/1 system-ui,sans-serif;letter-spacing:.12em;text-transform:uppercase;color:var(--accent);margin:0 0 10px}
.banner h1{font:600 clamp(26px,4vw,38px)/1.15 system-ui,sans-serif;margin:0 0 8px}.banner .meta{margin:0;color:var(--banner-muted);font-size:15px}
.banner code{background:rgba(250,249,245,.1);color:var(--banner-ink)}
.howto{display:grid;gap:14px;grid-template-columns:repeat(auto-fit,minmax(280px,1fr))}.howto>div{border:1px solid var(--rule-strong);border-radius:6px;padding:14px 16px}
.howto h2{font:600 13px/1 system-ui,sans-serif;letter-spacing:.1em;text-transform:uppercase;margin:0 0 10px;color:var(--banner-muted)}
.howto p,.howto li{font-size:15.5px;line-height:1.5}.howto p{margin:0 0 8px}.howto ol{margin:0 0 8px;padding-left:22px}.howto .q{font-style:italic}
.page{max-width:1180px;margin:0 auto;padding:28px 24px 90px;display:grid;grid-template-columns:240px minmax(0,1fr);gap:48px;align-items:start}
nav.toc{position:sticky;top:20px;max-height:calc(100vh - 40px);overflow:auto;font:13px/1.4 system-ui,sans-serif}nav.toc ul{list-style:none;margin:0;padding:0}
nav.toc ul ul{margin:4px 0 6px 12px;border-left:1px solid var(--rule);padding-left:10px}nav.toc li{margin:0 0 6px}nav.toc a{color:var(--ink);text-decoration:none}
article{max-width:74ch;min-width:0}h2{font:600 26px/1.25 system-ui,sans-serif;margin:52px 0 14px;padding-top:24px;border-top:1px solid var(--rule-strong)}
article>h2:first-of-type{margin-top:6px;padding-top:0;border-top:0}h3{font:600 19px/1.3 system-ui,sans-serif;margin:32px 0 10px}h4{font:600 15px/1.3 system-ui,sans-serif;margin:22px 0 8px}
.anchor{font:400 14px/1 system-ui,sans-serif;color:var(--rule-strong);text-decoration:none;margin-left:6px}p{margin:0 0 15px}ul,ol{padding-left:26px;margin:0 0 15px}li{margin:0 0 5px}
blockquote{margin:0 0 18px;padding:12px 18px;border-left:3px solid var(--accent);background:var(--surface)}blockquote p{margin:0 0 6px}
code{font-family:ui-monospace,Menlo,Consolas,monospace;font-size:.86em;background:var(--surface);padding:1px 5px;border-radius:3px}
pre.mermaid{background:var(--surface);border:1px solid var(--rule);border-radius:6px;padding:14px;overflow-x:auto;margin:0 0 18px;text-align:center}pre{background:var(--surface);border:1px solid var(--rule);border-radius:6px;padding:14px 16px;overflow-x:auto;margin:0 0 18px;font-size:13px;line-height:1.55}pre code{background:none;padding:0;font-size:inherit}
.table-wrap{overflow-x:auto;margin:0 0 22px;border:1px solid var(--rule);border-radius:6px}table{border-collapse:collapse;width:100%;font-size:14.5px;line-height:1.45}
th{text-align:left;font:600 11.5px/1.3 system-ui,sans-serif;letter-spacing:.08em;text-transform:uppercase;color:var(--muted);padding:10px 12px;border-bottom:1px solid var(--rule-strong);background:var(--surface);white-space:nowrap}
td{padding:10px 12px;border-bottom:1px solid var(--rule);vertical-align:top}tr:last-child td{border-bottom:0}li.task{list-style:'\\2610  '}li.task.done{list-style:'\\2611  '}
@media (max-width:900px){.page{grid-template-columns:minmax(0,1fr);gap:20px;padding:22px 18px 70px}nav.toc{position:static;max-height:none}body{font-size:16px}}
"""

STEPS = """<ol>
<li>Open this link signed in to your Claude account.</li>
<li>Switch the page to <strong>comment mode</strong> from the bar at the top.</li>
<li>Click the passage, type your comment, and leave <strong>Queue for Claude</strong> ticked. Your session answers in the thread.</li>
<li>If your session was closed, or no answer comes, open it and say <strong>done</strong>. It then reads every comment on this page.</li>
</ol>"""

def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--in', dest='src', required=True)
    ap.add_argument('--out', dest='out', required=True)
    ap.add_argument('--title', required=True)
    ap.add_argument('--question', default='')
    ap.add_argument('--meta', default='')
    a = ap.parse_args()
    md = pathlib.Path(a.src).read_text(encoding='utf-8')
    hits = find_keys(md)
    if hits: sys.exit(refusal(a.src, hits))
    body, toc = render(md)
    q = ''
    if a.question:
        q = ('<div><h2>One question first</h2><p class="q">' + html.escape(a.question) +
             '</p><p>Answer it as a comment on this box.</p></div>')
    meta = ('<p class="meta">' + html.escape(a.meta) + '</p>') if a.meta else ''
    mermaid = ('<script src="https://cdnjs.cloudflare.com/ajax/libs/mermaid/11.4.1/mermaid.min.js"></script>\n'
               '<script>mermaid.initialize({startOnLoad:true,theme:window.matchMedia("(prefers-color-scheme: dark)").matches?"dark":"neutral"});</script>\n'
               ) if 'class="mermaid"' in body else ''
    page = (f'<title>{html.escape(a.title)}</title>\n<style>{CSS}</style>\n{mermaid}'
            f'<header class="banner"><div class="banner-inner"><div><p class="eyebrow">Code Katz · proof</p>'
            f'<h1>{html.escape(a.title)}</h1>{meta}</div>'
            f'<div class="howto"><div><h2>How to comment</h2>{STEPS}</div>{q}</div></div></header>\n'
            f'<div class="page"><nav class="toc" aria-label="Contents">{toc_html(toc)}</nav><article>\n{body}\n</article></div>\n')
    pathlib.Path(a.out).parent.mkdir(parents=True, exist_ok=True)
    pathlib.Path(a.out).write_text(page, encoding='utf-8')
    print(f'wrote {a.out} ({len(page)} bytes, {len(toc)} headings)')

if __name__ == '__main__':
    main()
