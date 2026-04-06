extends Node

signal cooldown_updated(minigame_id: String, time_left: float)
signal game_started(minigame_id: String)
signal game_ended(minigame_id: String)

var _cooldowns: Dictionary = {}
var _active_game: String = ""


func _ready() -> void:
	pass


func _process(delta: float) -> void:
	for key in _cooldowns:
		if _cooldowns[key] > 0:
			_cooldowns[key] -= delta
			if _cooldowns[key] <= 0:
				_cooldowns[key] = 0.0
				cooldown_updated.emit(key, _cooldowns[key])


func can_play(minigame_id: String) -> bool:
	return _cooldowns.get(minigame_id, 0.0) <= 0.0


func get_cooldown_time(minigame_id: String) -> float:
	return _cooldowns.get(minigame_id, 0.0)


func start_game(minigame_id: String) -> bool:
	if not can_play(minigame_id):
		return false
	var config = MiniGameConfig.get_minigame(minigame_id)
	if config.is_empty():
		return false
	_cooldowns[minigame_id] = config.get("cooldown", 60.0)
	_active_game = minigame_id
	game_started.emit(minigame_id)
	return true


func end_game(minigame_id: String) -> void:
	_active_game = ""
	game_ended.emit(minigame_id)


func get_active_game() -> String:
	return _active_game
