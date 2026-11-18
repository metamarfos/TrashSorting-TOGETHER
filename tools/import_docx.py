#!/usr/bin/env python3
"""
Импорт таблицы отходов из ТЗ (docx) в проект Godot.

Что делает:
  * читает все таблицы вида «фото | название | класс опасности | куда выкидывать»;
  * приводит названия в порядок (заглавная буква, лишние пробелы, незакрытые скобки);
  * сопоставляет текст «Куда выкидывать» с id баков (gray/blue/bunker/hazard/social);
  * сохраняет картинки в assets/waste/<id>.webp (не больше 640 px по длинной стороне);
  * сохраняет картинки баков в assets/bins/<id>.png;
  * пишет data/waste_default.json.

Запуск (нужны python-docx и Pillow):
    python3 tools/import_docx.py путь/к/игра.docx

Приложению этот скрипт НЕ нужен — это одноразовый конвертер.
Папка tools/ исключена из экспорта (см. export_presets.cfg).
"""
import json
import re
import sys
from pathlib import Path

import docx
from docx.oxml.ns import qn
from PIL import Image

ROOT = Path(__file__).resolve().parent.parent
MAX_SIDE = 640
WEBP_QUALITY = 88

# Картинки баков в docx (в таблице «Серый бак / синий бак / …»), по порядку.
BIN_IMAGES = ["gray", "blue", "bunker", "hazard", "social"]
BIN_IMAGE_SRC = ["image2.png", "image3.png", "image4.png", "image5.png", "image6.png"]

# Таблицы с отходами в документе (индексы по порядку появления).
WASTE_TABLES = [3, 4, 5, 6, 7]  # таблица 8 в ТЗ помечена «Не надо» — не импортируется


def clean_text(s: str) -> str:
    s = re.sub(r"\s+", " ", s).strip()
    s = re.sub(r"\s+,", ",", s)
    return s


def fix_name(s: str) -> str:
    s = clean_text(s)
    if not s:
        return s
    s = re.sub(r"^паковка\b", "Упаковка", s)  # опечатка в исходной таблице
    if s.count("(") > s.count(")"):
        s += ")" * (s.count("(") - s.count(")"))
    return s[0].upper() + s[1:]


def parse_class(s: str) -> int:
    m = re.search(r"[1-5]", s)
    return int(m.group(0)) if m else 0


def parse_bins(s: str):
    t = s.lower()
    out = []
    if "сер" in t:
        out.append("gray")
    if "син" in t:
        out.append("blue")
    if "бункер" in t:
        out.append("bunker")
    if "опасн" in t:
        out.append("hazard")
    if "соц" in t:
        out.append("social")
    # В исходнике встречается обрезанное «Синий бак или» — по смыслу вторая
    # половина «…или соцпроект» (старую обувь принимают соцпроекты).
    if t.strip().endswith("или") and "social" not in out:
        out.append("social")
    return out


def cell_images(cell, rels):
    names = []
    for blip in cell._tc.iter(qn("a:blip")):
        rid = blip.get(qn("r:embed"))
        if rid and rid in rels:
            names.append(rels[rid].target_ref.split("/")[-1])
    return names


def save_image(blob_getter, out_path: Path, keep_png=False):
    im = Image.open(blob_getter())
    im.load()
    has_alpha = im.mode in ("RGBA", "LA", "P") and (
        im.mode != "P" or "transparency" in im.info
    )
    im = im.convert("RGBA" if has_alpha else "RGB")
    if has_alpha:
        alpha_min = im.getchannel("A").getextrema()[0]
        if alpha_min >= 250:  # фактически непрозрачная
            im = im.convert("RGB")
            has_alpha = False
    w, h = im.size
    k = min(1.0, MAX_SIDE / max(w, h))
    if k < 1.0:
        im = im.resize((max(1, round(w * k)), max(1, round(h * k))), Image.LANCZOS)
    if keep_png:
        im.save(out_path.with_suffix(".png"), optimize=True)
    else:
        im.save(out_path.with_suffix(".webp"), quality=WEBP_QUALITY, method=6)


def main():
    if len(sys.argv) < 2:
        print(__doc__)
        sys.exit(1)
    d = docx.Document(sys.argv[1])
    rels = d.part.rels

    def blob_of(name):
        import io
        for rel in rels.values():
            if rel.target_ref.split("/")[-1] == name:
                return lambda: io.BytesIO(rel.target_part.blob)
        raise KeyError(name)

    # ---- баки
    (ROOT / "assets/bins").mkdir(parents=True, exist_ok=True)
    for bid, src in zip(BIN_IMAGES, BIN_IMAGE_SRC):
        im = Image.open(blob_of(src)()).convert("RGBA")
        im.save(ROOT / f"assets/bins/{bid}.png", optimize=True)

    # ---- отходы
    items = []
    prev_name = ""
    prev_class = 0
    n = 0
    (ROOT / "assets/waste").mkdir(parents=True, exist_ok=True)
    for ti in WASTE_TABLES:
        t = d.tables[ti]
        for r in t.rows:
            seen, cells = set(), []
            for c in r.cells:
                if id(c._tc) in seen:
                    continue
                seen.add(id(c._tc))
                cells.append(c)
            if len(cells) < 4:
                continue
            c_photo, c_name, c_class, c_bin = cells[0], cells[1], cells[2], cells[3]
            note = clean_text(c_photo.text)
            name = fix_name(c_name.text)
            cls = parse_class(c_class.text)
            bin_txt = clean_text(c_bin.text)
            imgs = cell_images(c_photo, rels)
            if note.lower() == "фото":  # шапка таблицы
                continue
            if not name and not imgs:
                continue
            if not name and imgs:  # вторая фотография того же отхода без подписи
                name, cls = prev_name, cls or prev_class
            n += 1
            wid = f"w{n:03d}"
            image = ""
            if imgs:
                save_image(blob_of(imgs[0]), ROOT / f"assets/waste/{wid}")
                image = f"res://assets/waste/{wid}.webp"
            items.append(
                {
                    "id": wid,
                    "name": name,
                    "hazard_class": cls,
                    "bins": parse_bins(bin_txt),
                    "image": image,
                    "note": note,
                    "source_bin_text": bin_txt,
                }
            )
            prev_name, prev_class = name, cls

    # ---- конфликты в исходных данных (один и тот же отход — разные баки)
    by_name = {}
    for it in items:
        by_name.setdefault(it["name"].lower(), []).append(it)
    conflicts = []
    for nm, lst in by_name.items():
        variants = {tuple(sorted(i["bins"])) for i in lst if i["bins"]}
        if len(variants) > 1:
            conflicts.append((nm, [(i["id"], i["bins"]) for i in lst]))
    flagged = {i for _, lst in conflicts for i, _ in lst}
    for it in items:
        if it["id"] in flagged:
            warn = "Проверить: в исходной таблице у отхода с таким названием указаны разные баки."
            it["note"] = (it["note"] + " | " if it["note"] else "") + warn
        it.pop("source_bin_text", None)

    out = {"version": 1, "items": items}
    (ROOT / "data").mkdir(exist_ok=True)
    (ROOT / "data/waste_default.json").write_text(
        json.dumps(out, ensure_ascii=False, indent=1), encoding="utf-8"
    )
    playable = [i for i in items if i["image"] and i["bins"]]
    print(f"Записей: {len(items)}, годных для игры: {len(playable)}")
    for nm, lst in conflicts:
        print("КОНФЛИКТ:", nm, lst)


if __name__ == "__main__":
    main()
