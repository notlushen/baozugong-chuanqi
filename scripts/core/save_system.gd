extends Node

## Save System for idle game
## Handles JSON save/load with auto-save functionality using LocalStorage for web persistence
## Will be autoloaded as a singleton

const SAVE_KEY: String = "baozugong_save_data"
const AUTO_SAVE_INTERVAL: float = 30.0
const MAX_OFFLINE_SECONDS: int = 28800  # 8 hours
const OFFLINE_EFFICIENCY_DEFAULT: float = 0.5
const OFFLINE_EFFICIENCY_BOOSTED: float = 1.0

var _auto_save_timer: Timer
var _is_loaded: bool = false

signal game_saved
signal game_loaded


func _ready() -> void:
	_auto_save_timer = Timer.new()
	_auto_save_timer.wait_time = AUTO_SAVE_INTERVAL
	_auto_save_timer.timeout.connect(_auto_save)
	add_child(_auto_save_timer)
	_auto_save_timer.start()


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		save_game()


func _is_web() -> bool:
	return OS.get_name() == "Web"


func save_game() -> void:
	var save_data: Dictionary = {
		"version": 1,
		"money": GameState.money,
		"pending_rent": GameState.pending_rent,
		"total_earned": GameState.total_earned,
		"prestige_level": GameState.prestige_level,
		"prestige_points": GameState.prestige_points,
		"properties": GameState.properties.duplicate(true),
		"upgrades": GameState.upgrades.duplicate(true),
		"furniture": GameState.furniture.duplicate(true),
		"last_save_time": Time.get_unix_time_from_system(),
		"achievements": GameState.achievements.duplicate(true)
	}

	var json_string = JSON.stringify(save_data)

	if _is_web():
		# Use LocalStorage for web
		var escaped = json_string.replace("'", "\\'")
		JavaScriptBridge.eval("localStorage.setItem('" + SAVE_KEY + "', '" + escaped + "');")
	else:
		# Desktop fallback - use FileAccess
		var file = FileAccess.open("user://" + SAVE_KEY + ".json", FileAccess.WRITE)
		if file:
			file.store_string(json_string)
			file.close()

	game_saved.emit()


func load_game() -> bool:
	var json_string: String = ""

	if _is_web():
		# Load from LocalStorage for web
		json_string = str(JavaScriptBridge.eval("localStorage.getItem('" + SAVE_KEY + "');"))
		if json_string == "null" or json_string.is_empty():
			return false
	else:
		# Desktop fallback - use FileAccess
		if not FileAccess.file_exists("user://" + SAVE_KEY + ".json"):
			return false
		var file = FileAccess.open("user://" + SAVE_KEY + ".json", FileAccess.READ)
		if not file:
			return false
		json_string = file.get_as_text()
		file.close()

	var json = JSON.new()
	var parse_result = json.parse(json_string)

	if parse_result != OK:
		push_error("Failed to parse save file JSON")
		return false

	var save_data: Dictionary = json.get_data()

	GameState.money = save_data.get("money", 500.0)
	GameState.pending_rent = save_data.get("pending_rent", 0.0)
	GameState.total_earned = save_data.get("total_earned", 500.0)
	GameState.prestige_level = save_data.get("prestige_level", 0)
	GameState.prestige_points = save_data.get("prestige_points", 0)
	GameState.properties = save_data.get("properties", {})
	GameState.upgrades = save_data.get("upgrades", {})
	GameState.furniture = save_data.get("furniture", {})
	GameState.last_save_time = save_data.get("last_save_time", 0.0)
	GameState.achievements = save_data.get("achievements", {})

	_is_loaded = true
	game_loaded.emit()
	return true


func _auto_save() -> void:
	save_game()


func calculate_offline_income() -> float:
	var last_save_time: float = GameState.last_save_time

	if last_save_time == 0.0:
		return 0.0

	var current_time: float = Time.get_unix_time_from_system()
	var elapsed_seconds: float = current_time - last_save_time

	if elapsed_seconds <= 0:
		return 0.0

	# Cap at 8 hours
	if elapsed_seconds > MAX_OFFLINE_SECONDS:
		elapsed_seconds = float(MAX_OFFLINE_SECONDS)

	# Check for offline efficiency upgrade
	var has_offline_boost: bool = GameState.get_upgrade_level("offline_efficiency") > 0

	var efficiency: float = OFFLINE_EFFICIENCY_BOOSTED if has_offline_boost else OFFLINE_EFFICIENCY_DEFAULT

	# Calculate income using Economy singleton
	var income_per_second = Economy.get_income_per_second()
	var income: float = elapsed_seconds * income_per_second * efficiency

	return income


func has_save_file() -> bool:
	if _is_web():
		var result = str(JavaScriptBridge.eval("localStorage.getItem('" + SAVE_KEY + "');"))
		return result != "null" and not result.is_empty()
	else:
		return FileAccess.file_exists("user://" + SAVE_KEY + ".json")


func get_save_data() -> Dictionary:
	"""Get current save data as dictionary for export"""
	return {
		"version": 1,
		"money": GameState.money,
		"pending_rent": GameState.pending_rent,
		"total_earned": GameState.total_earned,
		"prestige_level": GameState.prestige_level,
		"prestige_points": GameState.prestige_points,
		"properties": GameState.properties.duplicate(true),
		"upgrades": GameState.upgrades.duplicate(true),
		"furniture": GameState.furniture.duplicate(true),
		"last_save_time": Time.get_unix_time_from_system(),
		"achievements": GameState.achievements.duplicate(true)
	}


func export_save() -> String:
	"""Export save data as JSON string for manual backup"""
	var save_data = get_save_data()
	return JSON.stringify(save_data)


func import_save(json_string: String) -> bool:
	"""Import save data from JSON string. Returns true if successful."""
	var json = JSON.new()
	var parse_result = json.parse(json_string)
	
	if parse_result != OK:
		push_error("Failed to parse import data")
		return false
	
	var save_data: Dictionary = json.get_data()
	
	if typeof(save_data) != TYPE_DICTIONARY:
		push_error("Invalid save data format")
		return false
	
	# Validate minimum required fields
	if not save_data.has("money") or not save_data.has("properties"):
		push_error("Save data missing required fields")
		return false
	
	# Apply save data with fallbacks for missing fields
	GameState.money = save_data.get("money", 500.0)
	GameState.pending_rent = save_data.get("pending_rent", 0.0)
	GameState.total_earned = save_data.get("total_earned", 500.0)
	GameState.prestige_level = save_data.get("prestige_level", 0)
	GameState.prestige_points = save_data.get("prestige_points", 0)
	GameState.properties = save_data.get("properties", {})
	GameState.upgrades = save_data.get("upgrades", {})
	GameState.furniture = save_data.get("furniture", {})
	GameState.last_save_time = save_data.get("last_save_time", Time.get_unix_time_from_system())
	GameState.achievements = save_data.get("achievements", {})
	
	# Save the imported data immediately
	save_game()
	
	game_loaded.emit()
	return true
