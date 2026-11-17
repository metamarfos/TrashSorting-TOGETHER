# TECHNICAL NOTES

Архитектура: `ARCHITECTURE.md`. Требования: `REQUIREMENTS.md`. Решения: `documentation/DECISIONS.md`.

## Зависимости
Godot 4.7.2, GDScript, без плагинов. Рендерер GL Compatibility (максимальная совместимость с Android).

## Реализовано в Этапе 1
- `project.godot`: 1080×1920, stretch `canvas_items`, aspect `expand`, портрет (`handheld/orientation=1`), `quit_on_go_back=false`, эмуляция касаний мышью для отладки на ПК, окно на ПК 540×960.
- Автозагрузки: `SceneRouter` (fade, история, back-кнопка Android/Esc; сцена может определить `on_back_requested()`), `Settings` (defaults/presets из `data/config.json`, пользовательские значения в `user://settings.json`; JSON-числа приводятся к int).
- UI строится из кода (`UIKit`, `Palette`); .tscn минимальные (корневой узел + скрипт). Цвета/стили меняются в `palette.gd` и `ui_kit.gd`.
- Меню строится из `data/modes.json`; режим включается `enabled:true` и путём к сцене.
- Классы-помощники с `class_name`: `Palette`, `UIKit`, `GameModes`, `ComingSoonPopup`.

## Особенности
- Среда разработки без Godot/сети: код проверен только статически.
- Сырые таблицы ТЗ: `documentation/source/tz_tables_raw.json`.
