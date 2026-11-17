# ARCHITECTURE — «Сортируем вместе»

## 1. Структура проекта (`res://`)

```
project.godot
scenes/
  boot/            # загрузочная сцена (инициализация, переход в меню)
  menu/            # main_menu.tscn, settings_screen.tscn  (popup «Скоро» — ui/coming_soon_popup.gd)
  games/
    sort_bin/      # game_sort_bin.tscn, results.tscn, bin_info_popup.tscn
  editor/          # waste_editor.tscn, waste_item_form.tscn
scripts/
  autoload/        # scene_router.gd, waste_db.gd, settings.gd, audio_bus.gd
  core/            # game_mode_registry.gd, waste_item.gd (resource-класс), utils
  games/sort_bin/  # логика игры «Выбери бак»
  editor/
components/        # переиспользуемые: draggable_item, drop_zone, bin_view,
                   # timer_bar, progress_counter, feedback_overlay
ui/                # кнопки, карточки, popup, стили
themes/            # main_theme.tres, цвета (colors.gd), StyleBox-ресурсы
data/
  waste_base.json        # базовая база (только чтение, из ТЗ)
  containers.json        # 5 приёмников: id, название, описание, иконка, цвет
  hazard_classes.json    # I–V: римская цифра, название, цвет
  modes.json             # реестр режимов (меню строится из него)
  config.json            # настройки игры по умолчанию (время, число отходов…)
assets/
  images/waste/ images/bins/ images/ui/ images/placeholders/
  audio/ fonts/ icons/
documentation/           # *.md + source/ (ТЗ, макет, сырые таблицы)
```

Корневые документы: REQUIREMENTS, ARCHITECTURE, TODO, PROJECT_STATUS, TECHNICAL_NOTES, HANDOFF.

## 2. Ключевые решения

**Экран.** База 1080×1920, `stretch/mode = canvas_items`, `aspect = expand`: на вытянутых экранах добавляется высота. Ориентация portrait. UI на контейнерах и якорях, учитывается safe area (вырез).

**Автозагрузки (4, не больше).**
- `SceneRouter`: смена сцен с затемнением, стек «назад», кнопка «Назад» Android.
- `WasteDB`: загрузка базы + пользовательских правок, выборка (случайная/последовательная), CRUD для редактора. Не знает про UI.
- `Settings`: настройка уровня (число отходов, время, секунды, порядок, попытки, звук), пресеты; сохранение в `user://settings.json`. Игра читает уровень только отсюда.
- `AudioBus`: проигрывание эффектов; безопасно работает без файлов звука.

**Данные.**
- Запись отхода: `id, name, display_name, image, hazard_class (1..5), correct_bin, accepted_bins[], description, image_status, review_flag, extra{}`.
- Пользовательский слой `user://waste_user.json`: `{added:[...], modified:{id:{поля}}, deleted:[id]}`. Итоговая база = base + слой. Обновление `waste_base.json` не затирает правки.
- Пользовательские изображения копируются в `user://images/`.
- Путь картинки с префиксом `res://` или `user://`; загрузка через общий метод `WasteDB.load_texture()`.
- Бак отхода ссылается на `containers.json` по id: `gray`, `blue`, `bunker`, `hazard`, `social`.

**Drag & Drop (свой, без встроенного `_get_drag_data`).**
- `DraggableItem` слушает `InputEventScreenTouch/Drag` (и мышь для ПК-отладки), следует за пальцем, поднимается над остальным, сигналы `drag_started`, `drag_moved`, `drag_released(global_pos)`, `drag_cancelled`. Не знает о баках и картинках.
- `DropZone` отдаёт `contains_point(global_pos)` с расширенным hit-box; при перетаскивании подсвечивается ближайшая зона.
- Игровая сцена сопоставляет точку отпускания с зоной, проверяет ответ и командует возвратом/сменой объекта.
- Решение «свой hit-test, а не встроенный drag-n-drop Godot» принято из-за ненадёжности встроенного механизма на сенсорных экранах и необходимости плавного следования за пальцем.

**Режимы.** `modes.json` (id, title, icon, scene, enabled). Меню строит карточки; `enabled:false` показывает Coming Soon. Новая игра = новая папка в `scenes/games/` + строка в реестре.

**Игровой цикл «Выбери бак».** `GameSession` (RefCounted): очередь отходов, индекс, счёт, ошибки, таймер; сигналы `item_changed`, `answer_checked(correct)`, `finished(stats)`. UI подписан на сигналы, логика отделена от отображения.

**Дизайн.** Единая тема `themes/main_theme.tres` + `colors.gd` (палитра). Замена оформления не трогает логику. Цвета классов: I–III оттенки красного (ТЗ), IV голубой, V зелёный (ориентир макета).

**Android.** Только `user://` для записи, права на галерею в Этапе 5 (системный FileDialog/нативный выбор), экспорт-пресет готовится на Этапе 7.

## 3. Принципы
Игры независимы; базу можно менять без правки кода; новые отходы только через JSON/редактор; без избыточной архитектуры.
