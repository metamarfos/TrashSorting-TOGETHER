#!/usr/bin/env python3
"""Статическая проверка проекта без запуска Godot: пути ресурсов, %-узлы, варианты темы, JSON.
Запуск из корня проекта:  python3 tools/check_project.py"""
import json, re, sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
errors = []
def err(m): errors.append(m)
def exists(p): return (ROOT / p.replace("res://", "")).exists()

tscns = list(ROOT.rglob("*.tscn")); gds = list(ROOT.rglob("*.gd"))
tb = (ROOT / "design/theme_builder.gd").read_text(encoding="utf-8")
variations = set(re.findall(r'(?:_variation\(th, |set_type_variation\()"(\w+)"', tb)) | {"ProgressBar"}

scene_script, scene_uniques = {}, {}
for t in tscns:
    txt = t.read_text(encoding="utf-8")
    ids = {}
    for m in re.finditer(r'\[ext_resource type="(\w+)" path="([^"]+)" id="([^"]+)"\]', txt):
        ids[m.group(3)] = m.group(2)
        if not exists(m.group(2)): err(f"{t.name}: нет ресурса {m.group(2)}")
    names = set(); uniq = set()
    blocks = re.split(r'\n(?=\[node )', txt)
    for b in blocks[1:]:
        h = re.match(r'\[node name="([^"]+)"(?: type="\w+")?(?: parent="([^"]*)")?', b)
        if not h: err(f"{t.name}: странный узел"); continue
        n, parent = h.group(1), h.group(2)
        path = n if parent is None else (n if parent == "." else f"{parent}/{n}")
        if parent not in (None, ".") and parent not in names: err(f"{t.name}: родитель '{parent}' узла {n} не найден")
        names.add(path)
        if "unique_name_in_owner = true" in b: uniq.add(n)
        for v in re.findall(r'theme_type_variation = &"(\w+)"', b):
            if v not in variations: err(f"{t.name}: вариант темы {v} не объявлен")
        for ref in re.findall(r'ExtResource\("([^"]+)"\)', b):
            if ref not in ids: err(f"{t.name}: ExtResource {ref} не объявлен")
    s = re.search(r'^script = ExtResource\("([^"]+)"\)', txt, re.M)
    scene_script[t] = ids.get(s.group(1)) if s else None
    scene_uniques[t] = uniq

for g in gds:
    txt = g.read_text(encoding="utf-8")
    for p in re.findall(r'(?:load|preload)\("(res://[^"]+)"\)', txt):
        if not exists(p): err(f"{g.name}: нет файла {p}")
    for v in re.findall(r'&"(\w+(?:Button|Label|Panel|Bar))"', txt):
        if v not in variations: err(f"{g.name}: вариант {v} не объявлен")
    rel = "res://" + str(g.relative_to(ROOT))
    users = [t for t, s in scene_script.items() if s == rel]
    # скрипты-наследники (extends TapRow и т.п.) тоже привязаны к своей сцене
    for u in re.findall(r'%([A-Z]\w+)', txt):
        if users and not any(u in scene_uniques[t] for t in users):
            err(f"{g.name}: узел %{u} не найден в сцене {users[0].name}")
        if not users and "class_name" not in txt and False: pass

for f in ["data/bins.json", "data/games.json", "data/waste_default.json"]:
    try: d = json.loads((ROOT / f).read_text(encoding="utf-8"))
    except Exception as e: err(f"{f}: {e}"); continue
    for p in re.findall(r'res://[^"]+', json.dumps(d)):
        if not exists(p): err(f"{f}: нет файла {p}")
bins = {b["id"] for b in json.loads((ROOT/"data/bins.json").read_text(encoding="utf-8"))["bins"]}
for it in json.loads((ROOT/"data/waste_default.json").read_text(encoding="utf-8"))["items"]:
    if not set(it["bins"]) <= bins: err(f"неизвестный бак у {it['id']}")
for p in re.findall(r'"\*?(res://[^"]+)"', (ROOT/"project.godot").read_text(encoding="utf-8")):
    if not exists(p): err(f"project.godot: нет {p}")

print(f"сцен: {len(tscns)}, скриптов: {len(gds)}")
print("\n".join(errors) if errors else "OK: проблем не найдено")
sys.exit(1 if errors else 0)
