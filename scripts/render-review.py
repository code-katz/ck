#!/usr/bin/env python3
"""render-review.py: turn a markdown document into a self-contained review page.

Usage:
  render-review.py --in docs/PRD.md --out .ck/runs/<id>/review.html --title "Ardennes Hour PRD" \
      [--question "Imagine this shipped and did not move the number. What went wrong?"] [--meta "Revision 1"]

Standard library only. The page carries the five comment steps in its banner, a sticky
table of contents from the ## and ### headings, tables and code that scroll inside their
own container, and light and dark themes. Publish the output with the Artifact tool.
"""
import argparse, html, re, sys, pathlib

def slug(text):
    s = re.sub(r'[^a-z0-9]+', '-', text.lower()).strip('-')
    return s or 'section'

def inline(text):
    parts = re.split(r'(`[^`\n]*`)', text)
    out = []
    for p in parts:
        if p.startswith('`') and p.endswith('`') and len(p) >= 2:
            out.append('<code>' + html.escape(p[1:-1]) + '</code>')
            continue
        p = html.escape(p, quote=False)
        p = re.sub(r'\[([^\]]+)\]\((https?://[^)\s]+)\)', r'<a href="\2">\1</a>', p)
        p = re.sub(r'\*\*(.+?)\*\*', r'<strong>\1</strong>', p)
        p = re.sub(r'(?<![\w*])\*(?!\s)(.+?)(?<!\s)\*(?![\w*])', r'<em>\1</em>', p)
        out.append(p)
    return ''.join(out)

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
            buf = []
            i += 1
            while i < n and not lines[i].strip().startswith(fence):
                buf.append(lines[i]); i += 1
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
            header = [c.strip() for c in stripped.strip('|').split('|')]
            i += 2
            rows = []
            while i < n and lines[i].strip().startswith('|'):
                rows.append([c.strip() for c in lines[i].strip().strip('|').split('|')]); i += 1
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
pre{background:var(--surface);border:1px solid var(--rule);border-radius:6px;padding:14px 16px;overflow-x:auto;margin:0 0 18px;font-size:13px;line-height:1.55}pre code{background:none;padding:0;font-size:inherit}
.table-wrap{overflow-x:auto;margin:0 0 22px;border:1px solid var(--rule);border-radius:6px}table{border-collapse:collapse;width:100%;font-size:14.5px;line-height:1.45}
th{text-align:left;font:600 11.5px/1.3 system-ui,sans-serif;letter-spacing:.08em;text-transform:uppercase;color:var(--muted);padding:10px 12px;border-bottom:1px solid var(--rule-strong);background:var(--surface);white-space:nowrap}
td{padding:10px 12px;border-bottom:1px solid var(--rule);vertical-align:top}tr:last-child td{border-bottom:0}li.task{list-style:'\\2610  '}li.task.done{list-style:'\\2611  '}
@media (max-width:900px){.page{grid-template-columns:minmax(0,1fr);gap:20px;padding:22px 18px 70px}nav.toc{position:static;max-height:none}body{font-size:16px}}
"""

STEPS = """<ol>
<li>Open this link signed in to your Claude account.</li>
<li>Switch the page to <strong>comment mode</strong> from the bar at the top.</li>
<li>Click the passage you want to comment on and type.</li>
<li>Put <strong>@claude</strong> in the comment so Claude can reply to it and resolve it.</li>
<li>Say <strong>done</strong> in the chat when you have finished.</li>
</ol>
<p>Claude then works through every comment, changes the document, republishes this same page, and resolves each comment with one line saying what changed.</p>"""

def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--in', dest='src', required=True)
    ap.add_argument('--out', dest='out', required=True)
    ap.add_argument('--title', required=True)
    ap.add_argument('--question', default='')
    ap.add_argument('--meta', default='')
    a = ap.parse_args()
    md = pathlib.Path(a.src).read_text()
    body, toc = render(md)
    q = ''
    if a.question:
        q = ('<div><h2>One question first</h2><p class="q">' + html.escape(a.question) +
             '</p><p>Answer it as a comment on this box.</p></div>')
    meta = ('<p class="meta">' + html.escape(a.meta) + '</p>') if a.meta else ''
    page = (f'<title>{html.escape(a.title)}</title>\n<style>{CSS}</style>\n'
            f'<header class="banner"><div class="banner-inner"><div><p class="eyebrow">Code Katz · review page</p>'
            f'<h1>{html.escape(a.title)}</h1>{meta}</div>'
            f'<div class="howto"><div><h2>How to comment</h2>{STEPS}</div>{q}</div></div></header>\n'
            f'<div class="page"><nav class="toc" aria-label="Contents">{toc_html(toc)}</nav><article>\n{body}\n</article></div>\n')
    pathlib.Path(a.out).parent.mkdir(parents=True, exist_ok=True)
    pathlib.Path(a.out).write_text(page)
    print(f'wrote {a.out} ({len(page)} bytes, {len(toc)} headings)')

if __name__ == '__main__':
    main()
