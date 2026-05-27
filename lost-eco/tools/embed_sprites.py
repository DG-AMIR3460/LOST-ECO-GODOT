import base64
import os

BASE = os.path.join(os.path.dirname(__file__), "..", "assets", "sprites")
OUT = os.path.join(os.path.dirname(__file__), "..", "scripts", "systems", "CharacterSpritesData.gd")
KEYS = [
    "alex", "susurrantes", "ahogados", "hombre_lodo", "parasito",
    "humo_negro", "vigilantes", "espectro", "exploradora", "nina_perdida",
]

lines = [
    "extends RefCounted",
    "class_name CharacterSpritesData",
    "",
    "const EMBEDDED: Dictionary = {",
]

for key in KEYS:
    path = os.path.join(BASE, key + ".png")
    if not os.path.exists(path):
        continue
    with open(path, "rb") as f:
        b64 = base64.b64encode(f.read()).decode("ascii")
    lines.append(f'\t"{key}": "{b64}",')

lines.append("}")
lines.append("")

with open(OUT, "w", encoding="utf-8") as f:
    f.write("\n".join(lines))

print("Wrote", OUT, os.path.getsize(OUT), "bytes")
