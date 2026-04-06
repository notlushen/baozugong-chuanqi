class_name OfflineSummaryDialog
extends Control

signal dialog_closed

var _offline_income: float = 0.0

var time_label: Label
var income_label: Label
var efficiency_label: Label
var collect_btn: Button


func _ready() -> void:
	_build_ui()
	_show_summary()


func _build_ui() -> void:
	# Root container - full screen
	var root = Control.new()
	root.layout_mode = 1
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(root)

	# Overlay
	var overlay = ColorRect.new()
	overlay.layout_mode = 1
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.color = Color(0, 0, 0, 0.8)
	root.add_child(overlay)

	# Center panel using CenterContainer
	var center = CenterContainer.new()
	center.layout_mode = 1
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_child(center)

	var panel = PanelContainer.new()
	panel.custom_minimum_size = Vector2(400, 240)
	center.add_child(panel)

	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 12)
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	panel.add_child(vbox)

	var title_label = Label.new()
	title_label.text = "🏠 欢迎回来，包租公！"
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.add_theme_font_size_override("font_size", 20)
	vbox.add_child(title_label)

	time_label = Label.new()
	time_label.text = "您离开了 0 小时 0 分钟"
	time_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(time_label)

	income_label = Label.new()
	income_label.text = "离线收益: 💰 0"
	income_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	income_label.add_theme_font_size_override("font_size", 18)
	vbox.add_child(income_label)

	efficiency_label = Label.new()
	efficiency_label.text = "(已应用 50% 离线效率)"
	efficiency_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	efficiency_label.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
	vbox.add_child(efficiency_label)

	collect_btn = Button.new()
	collect_btn.text = "好的，收租！"
	collect_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.add_child(collect_btn)

	collect_btn.pressed.connect(_on_collect_pressed)


func _show_summary() -> void:
	var last_save_time = GameState.last_save_time
	if last_save_time == 0.0:
		queue_free()
		return

	var current_time = Time.get_unix_time_from_system()
	var elapsed = current_time - last_save_time
	if elapsed <= 0:
		queue_free()
		return

	var max_offline = 28800.0  # 8 hours
	if elapsed > max_offline:
		elapsed = max_offline

	var has_boost = GameState.get_upgrade_level("offline_efficiency") > 0
	var efficiency = 1.0 if has_boost else 0.5

	# Calculate income per second from loaded properties
	var ips = _calculate_ips_from_properties()
	_offline_income = elapsed * ips * efficiency

	var hours = int(elapsed / 3600)
	var minutes = int((elapsed - hours * 3600) / 60)
	time_label.text = "您离开了 " + str(hours) + " 小时 " + str(minutes) + " 分钟"

	income_label.text = "离线收益: " + NumberFormatter.format_money(_offline_income)

	efficiency_label.text = "(已应用 " + str(int(50 if not has_boost else 100)) + "% 离线效率)"


func _calculate_ips_from_properties() -> float:
	var total: float = 0.0
	var global_mult = GameState.get_global_multiplier()
	var prestige_mult = GameState.get_prestige_multiplier()

	for prop_id in Economy.PROPERTY_DATA:
		var prop_data = Economy.PROPERTY_DATA[prop_id]
		var count = GameState.get_property_count(prop_id)
		if count <= 0:
			continue
		var level = GameState.get_property_level(prop_id)
		var base_rent = prop_data["base_rent"]
		var rent_growth = prop_data["rent_growth"]
		var rent = base_rent * pow(1.0 + rent_growth, level) * global_mult * prestige_mult
		total += rent * count

	return total


func _on_collect_pressed() -> void:
	if _offline_income > 0:
		GameState.add_gold(_offline_income)
		SaveSystem.save_game()
	dialog_closed.emit()
	queue_free()
