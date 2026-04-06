extends Control

const MAIN_SCENE = preload("res://scenes/main.tscn")
const RetroTheme = preload("res://scripts/utils/pixel_theme.gd")
const SAVE_PATH = "user://baozugong_save_data.json"

var continue_btn: Button
var new_game_btn: Button
var delete_save_btn: Button
var export_save_btn: Button
var import_save_btn: Button
var save_info_label: Label
var _has_save: bool = false


func _ready() -> void:
	_build_ui()
	_check_save_file()


func _build_ui() -> void:
	# Apply retro theme first (must be before adding children)
	theme = RetroTheme.get_theme()
	
	# Background
	var bg = ColorRect.new()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.color = Color(0.05, 0.05, 0.12, 1)
	add_child(bg)

	# Center container
	var center = CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center)

	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 16)
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	center.add_child(vbox)

	# Title
	var title = Label.new()
	title.text = "🏠 包租公传奇"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 48)
	title.add_theme_color_override("font_color", Color(1, 0.85, 0.3))
	vbox.add_child(title)

	# Subtitle
	var subtitle = Label.new()
	subtitle.text = "从小房东到地产帝国"
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.add_theme_font_size_override("font_size", 18)
	subtitle.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
	vbox.add_child(subtitle)

	# Spacer
	var spacer1 = Control.new()
	spacer1.custom_minimum_size = Vector2(0, 30)
	vbox.add_child(spacer1)

	# Save info label
	save_info_label = Label.new()
	save_info_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	save_info_label.add_theme_font_size_override("font_size", 14)
	save_info_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
	save_info_label.visible = false
	vbox.add_child(save_info_label)

	# Spacer
	var spacer2 = Control.new()
	spacer2.custom_minimum_size = Vector2(0, 10)
	vbox.add_child(spacer2)

	# Continue button
	continue_btn = Button.new()
	continue_btn.text = "📂 继续游戏"
	continue_btn.custom_minimum_size = Vector2(250, 45)
	continue_btn.disabled = true
	vbox.add_child(continue_btn)

	# New game button
	new_game_btn = Button.new()
	new_game_btn.text = "🎮 新的游戏"
	new_game_btn.custom_minimum_size = Vector2(250, 45)
	vbox.add_child(new_game_btn)

	# Delete save button
	delete_save_btn = Button.new()
	delete_save_btn.text = "🗑️ 删除存档"
	delete_save_btn.custom_minimum_size = Vector2(250, 45)
	delete_save_btn.visible = false
	vbox.add_child(delete_save_btn)

	# Export save button
	export_save_btn = Button.new()
	export_save_btn.text = "📤 导出存档"
	export_save_btn.custom_minimum_size = Vector2(250, 45)
	export_save_btn.visible = false
	vbox.add_child(export_save_btn)

	# Import save button
	import_save_btn = Button.new()
	import_save_btn.text = "📥 导入存档"
	import_save_btn.custom_minimum_size = Vector2(250, 45)
	vbox.add_child(import_save_btn)

	# Connect signals
	continue_btn.pressed.connect(_on_continue_pressed)
	new_game_btn.pressed.connect(_on_new_game_pressed)
	delete_save_btn.pressed.connect(_on_delete_save_pressed)
	export_save_btn.pressed.connect(_on_export_save_pressed)
	import_save_btn.pressed.connect(_on_import_save_pressed)


func _check_save_file() -> void:
	_has_save = SaveSystem.has_save_file()
	continue_btn.disabled = not _has_save
	delete_save_btn.visible = _has_save
	export_save_btn.visible = _has_save

	if _has_save:
		var info = _get_save_info()
		save_info_label.text = info
		save_info_label.visible = true
	else:
		save_info_label.text = ""
		save_info_label.visible = false


func _get_save_info() -> String:
	if not FileAccess.file_exists(SAVE_PATH):
		return ""

	var file = FileAccess.open(SAVE_PATH, FileAccess.READ)
	if not file:
		return ""

	var json_string = file.get_as_text()
	file.close()

	var json = JSON.new()
	var err = json.parse(json_string)
	if err != OK:
		return ""

	var data = json.get_data()
	var money = data.get("money", 0.0)
	var prestige = data.get("prestige_level", 0)
	var properties = data.get("properties", {})
	var total_props = 0
	for key in properties:
		total_props += properties[key].get("count", 0)

	var info = "📂 存档信息:\n"
	info += "💰 金币: " + NumberFormatter.format_money(money) + "\n"
	info += "🏠 房产: " + str(total_props) + " 套\n"
	info += "⭐ 声望: Lv." + str(prestige)

	return info


func _on_continue_pressed() -> void:
	if not _has_save:
		return
	SaveSystem.load_game()
	get_tree().change_scene_to_packed(MAIN_SCENE)


func _on_new_game_pressed() -> void:
	# Reset to initial state
	GameState.money = 500.0
	GameState.pending_rent = 0.0
	GameState.total_earned = 500.0
	GameState.prestige_level = 0
	GameState.prestige_points = 0
	GameState.properties.clear()
	GameState.upgrades.clear()
	GameState.furniture.clear()
	GameState.achievements.clear()
	GameState.last_save_time = 0.0

	# Delete old save if exists
	if FileAccess.file_exists(SAVE_PATH):
		DirAccess.remove_absolute(SAVE_PATH)

	get_tree().change_scene_to_packed(MAIN_SCENE)


func _on_delete_save_pressed() -> void:
	if FileAccess.file_exists(SAVE_PATH):
		DirAccess.remove_absolute(SAVE_PATH)
		_has_save = false
		_check_save_file()


func _on_export_save_pressed() -> void:
	if not _has_save:
		return
	
	var save_json = SaveSystem.export_save()
	var file_name = "baozugong_save_" + str(Time.get_unix_time_from_system()) + ".json"
	
	# Desktop fallback - save to user directory
	var fallback_path = "user://exports/" + file_name
	var dir = DirAccess.open("user://")
	if dir and not dir.dir_exists("exports"):
		dir.make_dir("exports")
	var file = FileAccess.open(fallback_path, FileAccess.WRITE)
	if file:
		file.store_string(save_json)
		file.close()
		save_info_label.text = "存档已导出到:\n" + fallback_path + "\n请从用户文件夹复制"
		save_info_label.visible = true


func _on_import_save_pressed() -> void:
	# Show message asking user to paste save data
	save_info_label.text = "请在新窗口中粘贴存档JSON数据"
	save_info_label.visible = true
	
	# Use a simple approach: read from clipboard
	var clipboard_text = DisplayServer.clipboard_get()
	
	if clipboard_text.is_empty():
		save_info_label.text = "剪贴板为空\n请先复制存档JSON，然后点击导入按钮"
		save_info_label.visible = true
		return
	
	# Try to parse and validate as JSON first
	var json = JSON.new()
	var parse_result = json.parse(clipboard_text)
	
	if parse_result != OK:
		save_info_label.text = "剪贴板内容不是有效的JSON\n请确保复制了正确的存档数据"
		save_info_label.visible = true
		return
	
	var save_data = json.get_data()
	if typeof(save_data) != TYPE_DICTIONARY or not save_data.has("money"):
		save_info_label.text = "存档格式无效"
		save_info_label.visible = true
		return
	
	# Import the save
	if SaveSystem.import_save(clipboard_text):
		save_info_label.text = "✅ 存档导入成功!"
		save_info_label.visible = true
		_check_save_file()
	else:
		save_info_label.text = "❌ 存档导入失败"
		save_info_label.visible = true
