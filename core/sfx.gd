extends Node
## Автозагрузка «Sfx»: короткие звуки. Звук кнопок подключается автоматически ко всем BaseButton.
## Чтобы заменить звук — подложите свой .wav с тем же именем в assets/sfx/.

const SOUNDS := {
	"click": "res://assets/sfx/click.wav",
	"correct": "res://assets/sfx/correct.wav",
	"wrong": "res://assets/sfx/wrong.wav",
	"win": "res://assets/sfx/win.wav",
	"finish": "res://assets/sfx/finish.wav",
}
const POOL_SIZE := 4

var _players: Array[AudioStreamPlayer] = []
var _streams := {}


func _ready() -> void:
	for i in POOL_SIZE:
		var p := AudioStreamPlayer.new()
		add_child(p)
		_players.append(p)
	for key in SOUNDS:
		var path: String = SOUNDS[key]
		if ResourceLoader.exists(path):
			_streams[key] = load(path)
	get_tree().node_added.connect(_on_node_added)


func play(sound: String) -> void:
	if not Store.sound_enabled or not _streams.has(sound):
		return
	var player: AudioStreamPlayer = _players[0]
	for p in _players:
		if not p.playing:
			player = p
			break
	player.stream = _streams[sound]
	player.play()


func _on_node_added(node: Node) -> void:
	var button := node as BaseButton
	if button != null:
		button.pressed.connect(_on_any_button_pressed.bind(button))


func _on_any_button_pressed(button: BaseButton) -> void:
	# Кнопки, у которых свой звук (ответы в игре), помечают себя мета-флагом "silent".
	if is_instance_valid(button) and not button.has_meta("silent"):
		play("click")
