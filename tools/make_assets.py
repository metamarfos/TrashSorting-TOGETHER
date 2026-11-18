#!/usr/bin/env python3
"""
Генератор служебных ассетов: иконка приложения, иконки игр (SVG), звуки (WAV).

Всё это — заглушки-«по умолчанию», которые можно спокойно заменить своими файлами
с теми же именами. Запуск (нужны numpy и rsvg-convert для PNG-иконок):
    python3 tools/make_assets.py
"""
import math
import subprocess
import wave
from pathlib import Path

import numpy as np

ROOT = Path(__file__).resolve().parent.parent

# ------------------------------------------------------------------ иконки игр
STROKE = 'fill="none" stroke="#FFFFFF" stroke-width="7" stroke-linecap="round" stroke-linejoin="round"'
GAME_ICONS = {
    "hazard_class": f'<path d="M48 14 L86 80 H10 Z" {STROKE}/><path d="M48 38 V57" {STROKE}/><circle cx="48" cy="69" r="3.5" fill="#FFFFFF"/>',
    "bins": f'<path d="M25 34 H71 L66 84 H30 Z" {STROKE}/><path d="M18 26 H78" {STROKE}/><path d="M39 26 V17 H57 V26" {STROKE}/><path d="M42 47 V71 M54 47 V71" {STROKE}/>',
    "what_from_what": f'<circle cx="48" cy="48" r="36" {STROKE}/><path d="M36 39 C36 24 60 24 60 39 C60 49 48 50 48 60" {STROKE}/><circle cx="48" cy="72" r="3.5" fill="#FFFFFF"/>',
    "prepare": f'<path d="M48 12 C48 12 23 43 23 60 A25 25 0 0 0 73 60 C73 43 48 12 48 12 Z" {STROKE}/><path d="M37 62 A12 12 0 0 0 48 73" {STROKE}/>',
    "waste_path": f'<circle cx="20" cy="74" r="8" {STROKE}/><circle cx="76" cy="22" r="8" {STROKE}/><path d="M27 68 C58 62 30 36 69 28" {STROKE} stroke-dasharray="2 12"/>',
}


def write_game_icons():
    d = ROOT / "assets/ui"
    d.mkdir(parents=True, exist_ok=True)
    for name, body in GAME_ICONS.items():
        (d / f"game_{name}.svg").write_text(
            f'<svg xmlns="http://www.w3.org/2000/svg" width="96" height="96" viewBox="0 0 96 96">{body}</svg>\n',
            encoding="utf-8",
        )


# ------------------------------------------------------------------ иконка приложения
GLYPH = """
<g>
  <path d="M300 380 H724 L684 880 H340 Z" fill="#FFFFFF"/>
  <rect x="250" y="300" width="524" height="64" rx="32" fill="#FFFFFF"/>
  <path d="M410 300 V250 Q410 214 446 214 H578 Q614 214 614 250 V300" fill="none" stroke="#FFFFFF" stroke-width="44" stroke-linejoin="round"/>
  <path d="M512 520 c-70 20 -92 90 -60 150 c70 -4 130 -50 120 -126 c-18 -20 -40 -26 -60 -24 z" fill="#2E9E5B"/>
  <path d="M470 690 C490 640 520 600 560 560" fill="none" stroke="#FFFFFF" stroke-width="14" stroke-linecap="round"/>
</g>
"""
GRAD = """<defs><linearGradient id="g" x1="0" y1="0" x2="0" y2="1">
<stop offset="0" stop-color="#43C07A"/><stop offset="1" stop-color="#1F7A44"/></linearGradient></defs>"""


def write_app_icons():
    full = f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 1024 1024">{GRAD}<rect width="1024" height="1024" rx="230" fill="url(#g)"/>{GLYPH}</svg>'
    (ROOT / "icon.svg").write_text(full, encoding="utf-8")
    fg = f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 1024 1024"><g transform="translate(512 512) scale(0.62) translate(-512 -540)">{GLYPH}</g></svg>'
    bg = f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 1024 1024">{GRAD}<rect width="1024" height="1024" fill="url(#g)"/></svg>'
    tmp = ROOT / "assets/android"
    tmp.mkdir(parents=True, exist_ok=True)
    for name, svg, size in (
        ("icon_main_192.png", full, 192),
        ("icon_fg_432.png", fg, 432),
        ("icon_bg_432.png", bg, 432),
    ):
        src = tmp / (name + ".svg")
        src.write_text(svg, encoding="utf-8")
        subprocess.run(
            ["rsvg-convert", "-w", str(size), "-h", str(size), str(src), "-o", str(tmp / name)],
            check=True,
        )
        src.unlink()


# ------------------------------------------------------------------ звуки
SR = 22050


def tone(freq, dur, vol=0.5, decay=6.0, harm=0.25):
    t = np.linspace(0, dur, int(SR * dur), endpoint=False)
    wave_ = np.sin(2 * np.pi * freq * t) + harm * np.sin(2 * np.pi * freq * 2 * t)
    env = np.exp(-decay * t / dur) * np.minimum(1.0, t / 0.005)
    return vol * wave_ * env / (1 + harm)


def seq(notes):
    return np.concatenate([tone(*n) for n in notes])


def save_wav(name, data):
    d = ROOT / "assets/sfx"
    d.mkdir(parents=True, exist_ok=True)
    data = np.clip(data, -1, 1)
    pcm = (data * 32767).astype("<i2")
    with wave.open(str(d / f"{name}.wav"), "wb") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(SR)
        w.writeframes(pcm.tobytes())


def write_sounds():
    C5, E5, G5, C6 = 523.25, 659.25, 783.99, 1046.5
    save_wav("click", tone(900, 0.06, 0.45, 8))
    save_wav("correct", seq([(C5, 0.09, 0.5, 3), (E5, 0.09, 0.5, 3), (G5, 0.28, 0.5, 5)]))
    save_wav("wrong", seq([(247, 0.16, 0.5, 3, 0.6), (185, 0.30, 0.5, 4, 0.6)]))
    save_wav("win", seq([(C5, 0.1, 0.5, 3), (E5, 0.1, 0.5, 3), (G5, 0.1, 0.5, 3), (C6, 0.45, 0.5, 4)]))
    save_wav("finish", seq([(G5, 0.14, 0.45, 3), (E5, 0.14, 0.45, 3), (C5, 0.35, 0.45, 5)]))


if __name__ == "__main__":
    write_game_icons()
    write_app_icons()
    write_sounds()
    print("ok")
