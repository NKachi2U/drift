extends Node
## Background music. Silent until play() is called, then loops one track at a time and
## crossfades between them.

const TRACKS = {
	"main": preload("res://assets/Main.wav"),
	"memories": preload("res://assets/Memories.wav"),
}
const FADE_TIME = 1.2
const SILENT_DB = -40.0

var _current := ""
var _players := {}
var _tween: Tween

func _ready() -> void:
	for track_name: String in TRACKS:
		var player := AudioStreamPlayer.new()
		player.stream = TRACKS[track_name]
		player.volume_db = SILENT_DB
		player.finished.connect(player.play)
		add_child(player)
		_players[track_name] = player

## Fades to the named track. The track being left pauses and picks up where it stopped next time.
func play(track_name: String) -> void:
	if track_name == _current or not _players.has(track_name):
		return
	_current = track_name
	if _tween:
		_tween.kill()
	_tween = create_tween().set_parallel(true)
	for other: String in _players:
		var player: AudioStreamPlayer = _players[other]
		if other == track_name:
			if player.stream_paused:
				player.stream_paused = false
			elif not player.playing:
				player.play()
			_tween.tween_property(player, "volume_db", 0.0, FADE_TIME)
		elif player.playing:
			_tween.tween_property(player, "volume_db", SILENT_DB, FADE_TIME)
			_tween.tween_callback(player.set_stream_paused.bind(true)).set_delay(FADE_TIME)

## Fades everything out. The next play() starts its track from the top.
func stop() -> void:
	if _current == "":
		return
	_current = ""
	if _tween:
		_tween.kill()
	_tween = create_tween().set_parallel(true)
	for player: AudioStreamPlayer in _players.values():
		if player.playing or player.stream_paused:
			_tween.tween_property(player, "volume_db", SILENT_DB, FADE_TIME)
			_tween.tween_callback(_silence.bind(player)).set_delay(FADE_TIME)

func _silence(player: AudioStreamPlayer) -> void:
	player.stream_paused = false
	player.stop()
