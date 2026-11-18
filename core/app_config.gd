class_name AppConfig
extends RefCounted
## Константы приложения, не связанные с дизайном (дизайн — в design/design_tokens.gd).

const APP_NAME := "Сортируем вместе"

const BINS_PATH := "res://data/bins.json"
const GAMES_PATH := "res://data/games.json"
const WASTE_DEFAULT_PATH := "res://data/waste_default.json"

## Редактируемая таблица отходов лежит в пользовательской папке приложения.
const WASTE_USER_PATH := "user://waste.json"
const USER_IMAGES_DIR := "user://waste_images"
const SETTINGS_PATH := "user://settings.cfg"

const DB_VERSION := 1
## Картинки, добавленные в редакторе, уменьшаются до этого размера по длинной стороне.
const MAX_USER_IMAGE_SIDE := 640
