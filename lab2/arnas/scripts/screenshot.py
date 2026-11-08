#!/usr/bin/env python3
"""LD2 (Arnas): ekrano kopijos iš išsaugotų žurnalų ir HTML ataskaitų.

Žurnalo failas (ar jo eilučių intervalas) atvaizduojamas kaip terminalo
tekstas HTML puslapyje, o puslapis nufotografuojamas antraštiniu Firefox.
Tekstas nekeičiamas – rodomas toks, kokį įrašė įrankis.

Naudojimas (iš repozitorijos šaknies):
  python3 lab2/arnas/scripts/screenshot.py log <out.png> <antraštė> <failas>[:nuo-iki] ...
  python3 lab2/arnas/scripts/screenshot.py page <out.png> <failas.html> [nuo_y-iki_y]
  python3 lab2/arnas/scripts/screenshot.py table <out.png> <matrix.md>
"""

import html
import shutil
import subprocess
import sys
import tempfile
from pathlib import Path

from PIL import Image

LINE_PX = 18
WIDTH = 1500


def firefox(url, out, height):
    with tempfile.TemporaryDirectory() as profile:
        subprocess.run(['firefox', '--headless', '--no-remote', '-profile', profile,
                        f'--window-size={WIDTH},{height}', '--screenshot', str(Path(out).resolve()), url],
                       check=True, capture_output=True, timeout=120)


def log(out, title, specs):
    blocks, total = [], 0
    for spec in specs:
        path, _, rng = spec.partition(':')
        lines = Path(path).read_text(errors='replace').splitlines()
        if rng:
            start, end = (int(x) for x in rng.split('-'))
            lines, label = lines[start - 1:end], f'{path} (eilutės {start}–{end})'
        else:
            label = path
        total += sum(len(l) // 150 + 1 for l in lines) + 3
        blocks.append(f'<div class="file">$ cat {html.escape(label)}</div>'
                      f'<pre>{html.escape(chr(10).join(lines))}</pre>')
    page = f'''<!doctype html><meta charset="utf-8"><style>
body {{ margin: 0; background: #1e1e1e; color: #d4d4d4; font: 14px/{LINE_PX}px "DejaVu Sans Mono", monospace; }}
h1 {{ margin: 0; padding: 10px 16px; font: bold 15px sans-serif; background: #333; color: #fff; }}
.file {{ padding: 8px 16px 0; color: #6a9955; }}
pre {{ margin: 0; padding: 4px 16px 8px; white-space: pre-wrap; }}
</style><h1>{html.escape(title)}</h1>{"".join(blocks)}'''
    with tempfile.NamedTemporaryFile('w', suffix='.html', delete=False) as f:
        f.write(page)
    height = 60 + total * LINE_PX + 40
    firefox(f'file://{f.name}', out, height)
    trim(out)


def page(out, path, rng=None):
    if rng:
        top, bottom = (int(x) for x in rng.split('-'))
        firefox(f'file://{Path(path).resolve()}', out, bottom + 20)
        Image.open(out).crop((0, top, WIDTH, bottom)).save(out)
    else:
        firefox(f'file://{Path(path).resolve()}', out, 1400)


def table(out, path):
    """Markdown matricą atvaizduoja HTML lentelėmis. Testai be nė vieno ✓
    konkrečiai funkcijai praleidžiami (tai parašoma po lentele)."""
    parts, rows, in_table, header, skipped = [], 0, False, True, 0

    def close():
        nonlocal in_table, skipped
        if in_table:
            parts.append('</table>')
            if skipped:
                parts.append(f'<p class="note">Praleista testų be nė vieno ✓: {skipped}</p>')
        in_table, skipped = False, 0

    for line in Path(path).read_text().splitlines():
        if line.startswith('|'):
            if line.startswith('|---'):
                continue
            cells = [c.strip() for c in line.strip('|').split('|')]
            if not in_table:
                parts.append('<table>')
                in_table, header = True, True
            if not header and not any(c == '✓' for c in cells[1:]):
                skipped += 1
                continue
            tag = 'th' if header else 'td'
            parts.append('<tr>' + ''.join(f'<{tag}>{html.escape(c)}</{tag}>' for c in cells) + '</tr>')
            header = False
            rows += 1
        else:
            close()
            if line.startswith('#'):
                parts.append(f'<h2>{html.escape(line.lstrip("# "))}</h2>')
            elif line.strip():
                parts.append(f'<p>{html.escape(line)}</p>')
    close()
    page = '''<!doctype html><meta charset="utf-8"><style>
body { margin: 16px; font: 13px sans-serif; color: #222; background: #fff; }
h2 { font-size: 15px; margin: 14px 0 6px; } p { margin: 4px 0; } .note { color: #666; }
table { border-collapse: collapse; } th, td { border: 1px solid #bbb; padding: 3px 6px; text-align: center; }
th { background: #eee; } td:first-child, th:first-child { text-align: left; max-width: 640px; }
</style>''' + ''.join(parts)
    with tempfile.NamedTemporaryFile('w', suffix='.html', delete=False) as f:
        f.write(page)
    firefox(f'file://{f.name}', out, 260 + rows * 30)
    trim(out)


def trim(out):
    """Nukerpa tuščią apačią (vienspalvį foną)."""
    img = Image.open(out).convert('RGB')
    bg = img.getpixel((img.width - 1, img.height - 1))
    bottom = img.height
    while bottom > 1 and all(img.getpixel((x, bottom - 1)) == bg for x in range(0, img.width, 7)):
        bottom -= 1
    img.crop((0, 0, img.width, min(img.height, bottom + 12))).save(out)


if __name__ == '__main__':
    if not shutil.which('firefox'):
        sys.exit('Reikia firefox')
    mode, out = sys.argv[1], Path(sys.argv[2])
    out.parent.mkdir(parents=True, exist_ok=True)
    if mode == 'log':
        log(out, sys.argv[3], sys.argv[4:])
    elif mode == 'table':
        table(out, sys.argv[3])
    elif mode == 'page':
        page(out, sys.argv[3], sys.argv[4] if len(sys.argv) > 4 else None)
    else:
        sys.exit(__doc__)
