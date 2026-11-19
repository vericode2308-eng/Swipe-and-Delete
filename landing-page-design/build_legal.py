#!/usr/bin/env python3
"""Builds privacy.html, terms.html, licenses.html (from ../legal/*.md) and support.html.
The Markdown in ../legal is the single source of truth; re-run after editing it:
    python3 landing-page-design/build_legal.py
"""
import html, re, pathlib

HERE = pathlib.Path(__file__).parent
LEGAL = HERE.parent / "legal"
EMAIL = "support@vericodestudio.com"

def inline(s):
    s = html.escape(s, quote=False)
    s = re.sub(r"`([^`]+)`", r"<code>\1</code>", s)
    s = re.sub(r"\*\*([^*]+)\*\*", r"<strong>\1</strong>", s)
    s = re.sub(r"(?<![\w/@>])([\w.+-]+@[\w-]+\.[\w.]+[\w])", r'<a href="mailto:\1">\1</a>', s)
    s = re.sub(r"(?<![\"'>=/\w])(https?://[^\s<)]+[^\s<).,;])", r'<a href="\1" rel="noopener">\1</a>', s)
    return s

def slug(t):
    return re.sub(r"[^a-z0-9]+", "-", t.lower()).strip("-")

def convert(md):
    title, meta, out, toc = "", [], [], []
    para, bullets, rows = [], [], []
    def flush():
        nonlocal para, bullets, rows
        if para: out.append("<p>" + "<br>".join(inline(x) for x in para) + "</p>"); para = []
        if bullets: out.append("<ul>" + "".join(f"<li>{inline(b)}</li>" for b in bullets) + "</ul>"); bullets = []
        if rows:
            head, body = rows[0], rows[1:]
            out.append('<div class="tbl"><table><thead><tr>' + "".join(f"<th>{inline(c)}</th>" for c in head) + "</tr></thead><tbody>"
                       + "".join("<tr>" + "".join(f"<td>{inline(c)}</td>" for c in r) + "</tr>" for r in body) + "</tbody></table></div>")
            rows = []
    for raw in md.split("\n"):
        line = raw.strip()
        if not line: flush(); continue
        if line.startswith("## "):
            flush(); h = line[3:]; toc.append(h); out.append(f'<h2 id="{slug(h)}">{inline(h)}</h2>')
        elif line.startswith("# "): title = line[2:].replace("Lighter — ", "")
        elif line == "---": flush(); out.append("<hr>")
        elif line.startswith("- "): 
            if para: flush()
            bullets.append(line[2:])
        elif line.startswith("|"):
            cells = [c.strip() for c in line.strip("|").split("|")]
            if all(set(c) <= set("-: ") for c in cells): continue
            rows.append(cells)
        else:
            if bullets or rows: flush()
            if not out and not title: continue
            # the first plain lines under the title are document metadata
            (meta if not toc and not out else para).append(line)
    flush()
    return title, meta, "\n".join(out), toc

HEAD = """<!doctype html>
<html lang="en-GB">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1, viewport-fit=cover">
<title>{title} | Lighter</title>
<meta name="description" content="{desc}">
<meta name="theme-color" content="#1A1F29" media="(prefers-color-scheme: dark)">
<meta name="theme-color" content="#EEF1F6" media="(prefers-color-scheme: light)">
<link rel="canonical" href="{page}">
<link rel="icon" type="image/png" sizes="32x32" href="assets/favicon-32.png">
<link rel="apple-touch-icon" href="assets/apple-touch-icon.png">
<link rel="preconnect" href="https://fonts.googleapis.com">
<link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
<link href="https://fonts.googleapis.com/css2?family=Cormorant+Garamond:ital,wght@0,500;0,600;1,500&family=Montserrat:wght@400;500;600&display=swap" rel="stylesheet">
<link rel="stylesheet" href="styles.css">
<link rel="stylesheet" href="legal.css">
</head>
<body>
<a class="skip" href="#main">Skip to content</a>
<div class="ambient" aria-hidden="true"><div class="blob b1"></div><div class="blob b2"></div><div class="blob b3"></div></div>
<header class="doc-head">
  <a class="brand" href="index.html" aria-label="Lighter, home"><img src="assets/icon-512.png" alt="" width="40" height="40"><span class="wordmark">Lighter</span></a>
  <nav class="doc-nav glass" aria-label="Pages">{nav}</nav>
</header>
<main id="main" class="doc">
"""
FOOT = """</main>
<footer>
  <div class="wrap">
    <a class="wordmark" href="index.html">Lighter</a>
    <nav aria-label="Legal"><ul>{nav}</ul></nav>
    <small>© 2026 VeriCode. iPhone and App Store are trademarks of Apple Inc.</small>
  </div>
</footer>
</body>
</html>
"""
PAGES = [("privacy.html", "Privacy Policy"), ("terms.html", "Terms of Use"), ("support.html", "Support"), ("licenses.html", "Licences")]

def nav(cur, li=False):
    parts = []
    for f, n in PAGES:
        cur_attr = ' aria-current="page"' if f == cur else ""
        a = f'<a href="{f}"{cur_attr}>{n}</a>'
        parts.append(f"<li>{a}</li>" if li else a)
    return "".join(parts)

def write(fname, title, desc, body):
    page = HEAD.format(title=title, desc=desc, page=fname, nav=nav(fname)) + body + FOOT.format(nav=nav(fname, True))
    (HERE / fname).write_text(page, encoding="utf-8")

def doc_page(fname, src, desc):
    t, meta, body, toc = convert((LEGAL / src).read_text(encoding="utf-8"))
    head = f'<h1>{html.escape(t)}</h1><p class="meta">' + "<br>".join(inline(m) for m in meta) + "</p>"
    strip = lambda h: re.sub(r"^\d+\.\s*", "", h)
    items = "".join('<li><a href="#%s">%s</a></li>' % (slug(h), html.escape(strip(h))) for h in toc)
    tocs = '<nav class="toc glass" aria-label="On this page"><ol>' + items + "</ol></nav>" if len(toc) > 3 else ""
    write(fname, t, desc, f'<article>{head}{tocs}{body}</article>')

doc_page("privacy.html", "PRIVACY_POLICY.md", "How Lighter handles your photos and data. Photos stay on your iPhone; there is no account, server, advertising or analytics.")
doc_page("terms.html", "TERMS_OF_USE.md", "The terms for using Lighter, the swipe photo cleaner for iPhone.")
doc_page("licenses.html", "LICENSES.md", "Open-source licences used by Lighter.")

support = f"""<article>
<h1>Support</h1>
<p class="meta">Lighter for iPhone by VeriCode</p>
<p>Email <a href="mailto:{EMAIL}">{EMAIL}</a> for help, bug reports, privacy requests or questions about these pages. Tell us your iPhone model, your iOS version and what you were doing, and we will look into it. Please do not email photos.</p>
<h2 id="common">Common questions</h2>
<h3>Lighter cannot see my photos</h3>
<p>Open iOS Settings, then Photos, then Lighter, and choose Full Access or Limited Access. In Lighter, Settings, Photo Access opens that page.</p>
<h3>I deleted a photo by mistake</h3>
<p>Deleted photos move to Recently Deleted in the Photos app, where you can restore them for 30 days. Lighter only deletes after you confirm in the standard iOS prompt.</p>
<h3>Space did not come back after deleting</h3>
<p>Storage returns once Recently Deleted is emptied, either by you or automatically after 30 days.</p>
<h3>Restoring a purchase</h3>
<p>In Lighter, open Settings and choose Restore Purchases while signed in with the Apple Account that bought it.</p>
<h3>Do you keep my photos or data?</h3>
<p>No. Lighter has no account or server, and photos are never uploaded. Read the <a href="privacy.html">Privacy Policy</a> for the full detail.</p>
<h2 id="more">More</h2>
<ul><li><a href="privacy.html">Privacy Policy</a></li><li><a href="terms.html">Terms of Use</a></li><li><a href="licenses.html">Open-source licences</a></li></ul>
</article>
"""
write("support.html", "Support", "Help with Lighter, the swipe photo cleaner for iPhone: photo access, restoring purchases and contact details.", support)
print("built", ", ".join(f for f, _ in PAGES))
