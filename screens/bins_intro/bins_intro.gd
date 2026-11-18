extends BaseScreen
## Вводный экран игры «Выбери бак»: список баков (нажми — узнаешь, что в него выбрасывать) + «Начать игру».

const BinRowScene := preload("res://screens/bins_intro/bin_row.tscn")
const BinInfoPopupScene := preload("res://screens/bins_intro/bin_info_popup.tscn")

@onready var _header: ScreenHeader = %Header
@onready var _list: VBoxContainer = %List
@onready var _start: Button = %StartButton
@onready var _rounds_value: Label = %RoundsValue
@onready var _time_value: Label = %TimeValue

const GAME_ID := "bins"
const ROUNDS_MIN := 3
const ROUNDS_MAX := 30
const TIME_MIN := 3
const TIME_MAX := 30

var _rounds: int = 10
var _seconds: int = 10


func _ready() -> void:
	_header.back_pressed.connect(on_back_requested)
	for b in BinDB.bins:
		var row: BinRow = BinRowScene.instantiate()
		row.setup(b)
		row.tapped.connect(_on_row_tapped.bind(row))
		_list.add_child(row)
	_start.pressed.connect(_on_start_pressed)
	var game: Dictionary = GameRegistry.get_game(GAME_ID)
	_rounds = Store.get_level_setting(GAME_ID, "rounds", int(game.get("rounds", 10)))
	_seconds = Store.get_level_setting(GAME_ID, "time_per_item", int(game.get("time_per_item", 10)))
	%RoundsMinus.pressed.connect(_change_rounds.bind(-1))
	%RoundsPlus.pressed.connect(_change_rounds.bind(1))
	%TimeMinus.pressed.connect(_change_time.bind(-1))
	%TimePlus.pressed.connect(_change_time.bind(1))
	_refresh_settings()


func _change_rounds(delta: int) -> void:
	_rounds = clampi(_rounds + delta, ROUNDS_MIN, ROUNDS_MAX)
	Store.set_level_setting(GAME_ID, "rounds", _rounds)
	_refresh_settings()


func _change_time(delta: int) -> void:
	_seconds = clampi(_seconds + delta, TIME_MIN, TIME_MAX)
	Store.set_level_setting(GAME_ID, "time_per_item", _seconds)
	_refresh_settings()


func _refresh_settings() -> void:
	_rounds_value.text = str(_rounds)
	_time_value.text = "%d с" % _seconds


func _on_row_tapped(row: BinRow) -> void:
	var popup: BinInfoPopup = BinInfoPopupScene.instantiate()
	popup.setup(row.get_bin())
	show_modal(popup)


func _on_start_pressed() -> void:
	Router.go("bins_game")
