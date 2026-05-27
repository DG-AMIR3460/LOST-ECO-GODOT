"""Convierte un .md del proyecto a PDF usando Edge headless.

Uso:
  python tools/md_to_pdf.py
  python tools/md_to_pdf.py SUSTENTACION_LOST_ECO.md
  python tools/md_to_pdf.py DOCUMENTACION_CODIGO.md
"""
import subprocess
import sys
from pathlib import Path

import markdown

ROOT = Path(__file__).resolve().parent.parent

CSS = """
@page { margin: 18mm 16mm; }
body {
  font-family: "Segoe UI", Arial, sans-serif;
  font-size: 11pt;
  line-height: 1.45;
  color: #1a1a1a;
  max-width: 100%;
}
h1 { color: #2c3e6b; border-bottom: 2px solid #c9a227; padding-bottom: 6px; font-size: 22pt; }
h2 { color: #3d4f7c; margin-top: 1.2em; font-size: 14pt; page-break-after: avoid; }
h3 { color: #555; font-size: 12pt; page-break-after: avoid; }
code, pre { background: #f4f4f8; font-size: 9pt; }
pre { padding: 10px; border-radius: 4px; overflow-x: auto; white-space: pre-wrap; }
table { border-collapse: collapse; width: 100%; margin: 12px 0; font-size: 10pt; page-break-inside: avoid; }
th, td { border: 1px solid #ccc; padding: 6px 8px; text-align: left; }
th { background: #eef1f8; }
blockquote { border-left: 4px solid #c9a227; margin-left: 0; padding-left: 12px; color: #444; font-style: italic; }
hr { border: none; border-top: 1px solid #ddd; margin: 20px 0; }
ul, ol { margin: 8px 0; }
"""

HTML_TEMPLATE = """<!DOCTYPE html>
<html lang="es">
<head>
<meta charset="utf-8"/>
<title>{title}</title>
<style>{css}</style>
</head>
<body>
{body}
</body>
</html>
"""


def convert_md_to_pdf(md_name: str) -> int:
	md_path = ROOT / md_name
	if not md_path.is_file():
		print(f"No existe: {md_path}", file=sys.stderr)
		return 1

	stem = md_path.stem
	html_path = ROOT / f"{stem}.html"
	pdf_path = ROOT / f"{stem}.pdf"
	title = stem.replace("_", " ")

	text = md_path.read_text(encoding="utf-8")
	body = markdown.markdown(
		text,
		extensions=["tables", "fenced_code", "toc"],
	)
	html = HTML_TEMPLATE.format(css=CSS, body=body, title=title)
	html_path.write_text(html, encoding="utf-8")

	edge = Path(r"C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe")
	if not edge.is_file():
		edge = Path(r"C:\Program Files\Microsoft\Edge\Application\msedge.exe")
	if not edge.is_file():
		print(f"Microsoft Edge no encontrado. Abre {html_path.name} e imprime a PDF.", file=sys.stderr)
		return 1

	url = html_path.as_uri()
	cmd = [
		str(edge),
		"--headless",
		"--disable-gpu",
		f"--print-to-pdf={pdf_path}",
		"--no-pdf-header-footer",
		url,
	]
	subprocess.run(cmd, check=True, timeout=90)
	print(f"PDF creado: {pdf_path}")
	return 0


def main() -> int:
	md_name = sys.argv[1] if len(sys.argv) > 1 else "DOCUMENTACION_CODIGO.md"
	return convert_md_to_pdf(md_name)


if __name__ == "__main__":
	raise SystemExit(main())
