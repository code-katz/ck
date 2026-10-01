#!/usr/bin/env python3
"""render-gallery.py: build a gallery page of labeled variants to the gallery contract.

Usage:
  render-gallery.py --in <variants.json> --out <gallery.html>
  render-gallery.py --dir <round directory> --out <gallery.html>

The JSON: {"product": str, "round": str, "kind": "brand" | "design", "skin": str (optional note), "variants": [ {
    "label": "A", "name": str, "rationale": str, "tradeoff": str, "satisfies": str,
    "mood": [str], "swatches": [{"name": str, "hex": "#rrggbb", "role": str}],
    "typePair": {"heading": str, "body": str}, "typeScale": [{"role": str, "family": str, "size": str, "weight": str}],
    "markSvg": "<svg ...>", "surfaceHtml": "<div ...>", "assets": [{"name": str, "svg": "<svg ...>"}],
    "screens": [{"name": str, "html": str, "states": {"empty": str, "loading": str, "error": str}}]
} ] }
Brand variants use mood, swatches, typePair, typeScale, markSvg, surfaceHtml, assets. Design variants use screens.

With --dir, the JSON is <dir>/variants.json and the authors' files fill in what it leaves out, so each
author writes files once and nobody pastes SVG into JSON:
    <dir>/<label>/mark.svg          markSvg
    <dir>/<label>/surface.html      surfaceHtml (an HTML fragment with inline styles)
    <dir>/<label>/*.svg             every other SVG becomes an asset tile, captioned with its file name
    <dir>/<label>/<screen>.html     a design screen's html, <screen> being the screen name slugified
    <dir>/<label>/<screen>.<state>.html   its empty, loading, and error states
A brand variant without a mark or a surface, or a design screen without its file, is an error that names the file.

Standard library only. Every asset is inline; the page loads nothing but Google Fonts. Fails if the output
would exceed 16 MB or if labels are not consecutive capital letters from A.
"""
import argparse, html, json, pathlib, re, sys

STEPS = """<ol>
<li>Open this link signed in to your Claude account.</li>
<li>Switch the page to <strong>comment mode</strong> from the bar at the top.</li>
<li>Click the variant or the passage you want to comment on and type.</li>
<li>Put <strong>@claude</strong> in the comment so Claude can reply to it and resolve it.</li>
<li>Say <strong>done</strong> in the chat when you have finished.</li>
</ol>"""

CSS = """
:root{--bg:#faf9f5;--ink:#141413;--muted:#5f5d55;--rule:#e8e6dc;--rule-strong:#b0aea5;--surface:#f2f0e8;--accent:#d97757;--banner:#141413;--banner-ink:#faf9f5;--banner-muted:#b0aea5}
@media (prefers-color-scheme:dark){:root:not([data-theme="light"]){--bg:#141413;--ink:#faf9f5;--muted:#b0aea5;--rule:#2b2a26;--rule-strong:#4a4842;--surface:#1e1d1a;--banner:#1e1d1a}}
:root[data-theme="dark"]{--bg:#141413;--ink:#faf9f5;--muted:#b0aea5;--rule:#2b2a26;--rule-strong:#4a4842;--surface:#1e1d1a;--banner:#1e1d1a}
*{box-sizing:border-box}body{margin:0;background:var(--bg);color:var(--ink);font:400 16px/1.55 system-ui,-apple-system,sans-serif}
.banner{background:var(--banner);color:var(--banner-ink);border-bottom:3px solid var(--accent)}.banner-inner{max-width:1240px;margin:0 auto;padding:28px 24px;display:grid;gap:16px}
.eyebrow{font:500 12px/1 system-ui,sans-serif;letter-spacing:.12em;text-transform:uppercase;color:var(--accent);margin:0 0 8px}.banner h1{font:600 clamp(24px,3.5vw,34px)/1.15 system-ui,sans-serif;margin:0 0 6px}
.banner .meta{margin:0;color:var(--banner-muted);font-size:15px}.howto{border:1px solid var(--rule-strong);border-radius:6px;padding:14px 16px;max-width:760px}
.howto h2{font:600 13px/1 system-ui,sans-serif;letter-spacing:.1em;text-transform:uppercase;margin:0 0 10px;color:var(--banner-muted)}.howto ol{margin:0;padding-left:22px;font-size:15px;line-height:1.5}.howto li{margin:0 0 4px}
.strip{position:sticky;top:0;z-index:2;background:var(--bg);border-bottom:1px solid var(--rule);padding:10px 24px;display:flex;gap:8px;flex-wrap:wrap}
.strip a{display:inline-block;padding:6px 12px;border:1px solid var(--rule-strong);border-radius:999px;color:var(--ink);text-decoration:none;font-weight:600;font-size:14px}.strip a:hover{border-color:var(--accent);color:var(--accent)}
.page{max-width:1240px;margin:0 auto;padding:24px 24px 90px}
.variant{border:1px solid var(--rule-strong);border-radius:10px;padding:22px 24px;margin:0 0 32px;background:var(--surface)}
.variant h2{font:600 24px/1.2 system-ui,sans-serif;margin:0 0 14px}.variant h2 .label{display:inline-block;min-width:36px;text-align:center;background:var(--accent);color:#fff;border-radius:6px;padding:2px 8px;margin-right:10px}
.variant h3{font:600 12px/1 system-ui,sans-serif;letter-spacing:.1em;text-transform:uppercase;color:var(--muted);margin:18px 0 8px}
.variant p{margin:0 0 8px}.render{display:grid;gap:18px;grid-template-columns:repeat(auto-fit,minmax(280px,1fr));align-items:start}
.mark{background:#fff;border:1px solid var(--rule);border-radius:8px;padding:16px;min-height:160px;display:flex;align-items:center;justify-content:center}.mark svg{max-width:100%;max-height:220px}
.swatches{display:flex;flex-wrap:wrap;gap:8px}.swatch{width:112px;border:1px solid var(--rule);border-radius:6px;overflow:hidden;font-size:12px}.swatch i{display:block;height:48px}.swatch b{display:block;padding:4px 6px 0}.swatch span{display:block;padding:0 6px 6px;color:var(--muted)}
.specimen{background:#fff;color:#141413;border:1px solid var(--rule);border-radius:8px;padding:14px}.specimen .h{font-size:26px;line-height:1.15;margin:0 0 6px}.specimen .b{font-size:15px;line-height:1.5;margin:0}.specimen table{border-collapse:collapse;font-size:13px;margin-top:8px}.specimen td{padding:4px 10px 4px 0;color:#5f5d55;vertical-align:baseline}
.frame{background:#fff;color:#141413;border:1px solid var(--rule);border-radius:8px;overflow:auto;max-width:100%}.frame>*{max-width:100%}
.assets{display:grid;gap:10px;grid-template-columns:repeat(auto-fill,minmax(150px,1fr))}.asset{margin:0;background:#fff;border:1px solid var(--rule);border-radius:8px;padding:10px;display:grid;gap:6px}.asset div{min-height:90px;display:flex;align-items:center;justify-content:center}.asset svg{max-width:100%;max-height:120px}.asset figcaption{font-size:12px;color:var(--muted);text-align:center;word-break:break-all}
.screens{display:grid;gap:18px;grid-template-columns:repeat(auto-fit,minmax(300px,1fr))}.device{border:10px solid #222;border-radius:28px;background:#fff;color:#141413;overflow:hidden;width:100%;max-width:360px;aspect-ratio:9/19}.device>*{width:100%;height:100%;overflow:auto}
.states{display:grid;gap:12px;grid-template-columns:repeat(auto-fit,minmax(200px,1fr))}.state{border:1px dashed var(--rule-strong);border-radius:8px;overflow:auto;background:#fff;color:#141413;max-height:280px}.state .cap{font:600 11px/1 system-ui,sans-serif;letter-spacing:.08em;text-transform:uppercase;color:var(--muted);padding:6px 8px;background:var(--surface)}
.mood{display:flex;gap:6px;flex-wrap:wrap}.mood span{border:1px solid var(--rule-strong);border-radius:999px;padding:2px 10px;font-size:13px}
@media (max-width:700px){.page{padding:18px 14px 70px}.variant{padding:16px}}
"""

def esc(s): return html.escape(str(s), quote=False)

def slug(s): return re.sub(r'[^a-z0-9]+', '-', str(s).lower()).strip('-')

def read_fragment(path):
    text = pathlib.Path(path).read_text()
    text = re.sub(r'<\?xml[^>]*\?>\s*', '', text)
    text = re.sub(r'<!DOCTYPE[^>]*>\s*', '', text, flags=re.I)
    return text.strip()

def fill_from_dir(d, dirpath):
    """Fill each variant's inline parts from the author files under <dir>/<label>/."""
    missing = []
    for v in d.get('variants') or []:
        ld = dirpath / str(v.get('label', ''))
        if d.get('kind', 'brand') == 'brand':
            if not v.get('markSvg'):
                if (ld / 'mark.svg').exists(): v['markSvg'] = read_fragment(ld / 'mark.svg')
                else: missing.append(str(ld / 'mark.svg'))
            if not v.get('surfaceHtml'):
                if (ld / 'surface.html').exists(): v['surfaceHtml'] = read_fragment(ld / 'surface.html')
                else: missing.append(str(ld / 'surface.html'))
            if ld.is_dir():
                extra = [f for f in sorted(ld.glob('*.svg')) if f.name != 'mark.svg']
                if extra and not v.get('assets'):
                    v['assets'] = [{'name': f.name, 'svg': read_fragment(f)} for f in extra]
        else:
            for s in v.get('screens') or []:
                base = ld / slug(s.get('name', 'screen'))
                if not s.get('html'):
                    if base.with_suffix('.html').exists(): s['html'] = read_fragment(base.with_suffix('.html'))
                    else: missing.append(str(base.with_suffix('.html')))
                st = s.setdefault('states', {})
                for k in ('empty', 'loading', 'error'):
                    f = ld / (base.name + '.' + k + '.html')
                    if not st.get(k):
                        if f.exists(): st[k] = read_fragment(f)
                        else: missing.append(str(f))
    if missing:
        sys.exit('missing author files:\n  ' + '\n  '.join(missing))

def fonts_link(variants):
    fams = []
    for v in variants:
        tp = v.get('typePair') or {}
        for k in ('heading', 'body'):
            f = tp.get(k)
            if f and f not in fams: fams.append(f)
        for row in v.get('typeScale') or []:
            f = row.get('family')
            if f and f not in fams: fams.append(f)
    if not fams: return ''
    q = '&'.join('family=' + re.sub(r'\s+', '+', f) + ':wght@400;600;700' for f in fams)
    return f'<link rel="preconnect" href="https://fonts.googleapis.com"><link rel="stylesheet" href="https://fonts.googleapis.com/css2?{q}&display=swap">'

def brand_render(v):
    parts = []
    if v.get('markSvg'):
        parts.append('<div><h3>Mark</h3><div class="mark">' + v['markSvg'] + '</div></div>')
    if v.get('swatches'):
        sw = ''.join(f'<div class="swatch"><i style="background:{esc(s.get("hex",""))}"></i><b>{esc(s.get("name",""))}</b><span>{esc(s.get("hex",""))} · {esc(s.get("role",""))}</span></div>' for s in v['swatches'])
        parts.append('<div><h3>Palette</h3><div class="swatches">' + sw + '</div></div>')
    tp = v.get('typePair') or {}
    if tp:
        h = esc(tp.get('heading', 'serif')); b = esc(tp.get('body', 'sans-serif'))
        scale = ''
        if v.get('typeScale'):
            scale = '<table>' + ''.join(f'<tr><td style="font-family:\'{esc(r.get("family",""))}\';font-size:{esc(r.get("size",""))};font-weight:{esc(r.get("weight",""))};line-height:1.1;color:#141413">{esc(r.get("role",""))}</td><td>{esc(r.get("family",""))} {esc(r.get("size",""))} {esc(r.get("weight",""))}</td></tr>' for r in v['typeScale']) + '</table>'
        parts.append(f'<div><h3>Type</h3><div class="specimen"><p class="h" style="font-family:\'{h}\',serif">{esc(v.get("name",""))}: the quick brown fox</p><p class="b" style="font-family:\'{b}\',sans-serif">Body in {b}. Heading in {h}. Jumps over the lazy dog, 0123456789.</p>{scale}</div></div>')
    wide = []
    if v.get('surfaceHtml'):
        wide.append('<h3>UI surface</h3><div class="frame">' + v['surfaceHtml'] + '</div>')
    if v.get('assets'):
        tiles = ''.join(f'<figure class="asset"><div>{a.get("svg","")}</div><figcaption>{esc(a.get("name",""))}</figcaption></figure>' for a in v['assets'])
        wide.append('<h3>Logo system and assets</h3><div class="assets">' + tiles + '</div>')
    mood = v.get('mood')
    if isinstance(mood, str): mood = [m.strip() for m in mood.replace(';', ',').split(',') if m.strip()]
    if mood:
        wide.append('<h3>Mood</h3><div class="mood">' + ''.join(f'<span>{esc(m)}</span>' for m in mood) + '</div>')
    return '<div class="render">' + ''.join(parts) + '</div>' + ''.join(wide)

def design_render(v):
    out = []
    for s in v.get('screens') or []:
        out.append(f'<div><h3>{esc(s.get("name",""))}</h3><div class="device"><div>{s.get("html","")}</div></div></div>')
    return '<div class="screens">' + ''.join(out) + '</div>'

def design_states(v):
    rows = []
    for s in v.get('screens') or []:
        st = s.get('states') or {}
        cells = ''.join(f'<div class="state"><div class="cap">{esc(s.get("name",""))} · {k}</div>{st.get(k,"")}</div>' for k in ('empty', 'loading', 'error') if st.get(k))
        if cells: rows.append(cells)
    return ('<h3>States</h3><div class="states">' + ''.join(rows) + '</div>') if rows else ''

def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--in', dest='src'); ap.add_argument('--dir'); ap.add_argument('--out', required=True)
    a = ap.parse_args()
    if not a.src and not a.dir: sys.exit('give --in <variants.json> or --dir <round directory>')
    src = pathlib.Path(a.src) if a.src else pathlib.Path(a.dir) / 'variants.json'
    if not src.exists(): sys.exit(f'{src} does not exist')
    d = json.loads(src.read_text())
    kind = d.get('kind', 'brand'); product = d.get('product', ''); rnd = d.get('round', '')
    variants = d.get('variants') or []
    if not variants: sys.exit('variants is empty')
    labels = [v.get('label', '') for v in variants]
    expected = [chr(ord('A') + i) for i in range(len(variants))]
    if labels != expected:
        sys.exit(f'labels must be consecutive capital letters from A: got {labels}')
    if a.dir: fill_from_dir(d, pathlib.Path(a.dir))
    title = f'{product}: {rnd}' if rnd else product
    strip = ''.join(f'<a href="#variant-{esc(l)}">{esc(l)} · {esc(v.get("name",""))}</a>' for l, v in zip(labels, variants))
    skin = f' {esc(d["skin"])}' if d.get('skin') else ''
    body = []
    for v in variants:
        l = v['label']
        render = brand_render(v) if kind == 'brand' else design_render(v)
        body.append(f'<section class="variant" id="variant-{esc(l)}"><h2><span class="label">{esc(l)}</span>{esc(v.get("name",""))}</h2>'
                    f'{render}<h3>Rationale</h3><p>{esc(v.get("rationale",""))}</p><h3>Trade-off</h3><p>{esc(v.get("tradeoff",""))}</p>'
                    f'<h3>Satisfies</h3><p>{esc(v.get("satisfies",""))}</p>{design_states(v) if kind == "design" else ""}</section>')
    page = (f'<title>{esc(title)}</title>\n{fonts_link(variants)}\n<style>{CSS}</style>\n'
            f'<header class="banner"><div class="banner-inner"><div><p class="eyebrow">Code Katz · gallery review</p><h1>{esc(title)}</h1>'
            f'<p class="meta">{len(variants)} labeled variants. Comment on the one you want, and on what to change.{skin}</p></div>'
            f'<div class="howto"><h2>How to comment</h2>{STEPS}</div></div></header>\n'
            f'<nav class="strip" aria-label="Variants">{strip}</nav>\n<main class="page">\n' + '\n'.join(body) + '\n</main>\n')
    if len(page.encode()) > 16 * 1024 * 1024: sys.exit('the page would exceed 16 MB')
    if re.search(r'<script\b', page, re.I): sys.exit('scripts are not allowed in a gallery')
    ext = re.findall(r'(?:src|href)=["\'](https?://[^"\']+)', page) + re.findall(r'url\(["\']?(https?://[^)"\']+)', page)
    bad = [u for u in ext if not u.startswith('https://fonts.g')]
    if bad: sys.exit('external references are not allowed: ' + ', '.join(bad[:3]))
    pathlib.Path(a.out).parent.mkdir(parents=True, exist_ok=True)
    pathlib.Path(a.out).write_text(page)
    print(f'wrote {a.out} ({len(page)} bytes, {len(variants)} variants)')

if __name__ == '__main__':
    main()
