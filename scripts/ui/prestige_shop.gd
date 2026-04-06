extends Control

@onready var points_label: Label = $Panel/VBox/PointsLabel
@onready var progress_bar: ProgressBar = $Panel/VBox/ProgressSection/ProgressBar
@onready var next_tier_label: Label = $Panel/VBox/ProgressSection/NextTierLabel
@onready var prestige_btn: Button = $Panel/VBox/PrestigeBtn
@onready var status_label: Label = $Panel/VBox/StatusLabel
@onready var upgrades_container: ScrollContainer = $Panel/VBox/UpgradesContainer
@onready var close_btn: Button = $Panel/VBox/CloseBtn

signal shop_closed

var _confirm_dialog: Control = null


func _ready() -> void:
	close_btn.pressed.connect(_on_close_pressed)
	prestige_btn.pressed.connect(_on_prestige_btn_pressed)
	_build_upgrades()
	_update_display()
	
	# Connect to prestige changes
	GameState.prestige_changed.connect(_on_prestige_changed)
	
	# Center after a frame to get correct size
	await get_tree().process_frame
	_center_shop()


func _center_shop() -> void:
	var screen_size = get_viewport().get_visible_rect().size
	var shop_size = size
	position = (screen_size - shop_size) / 2


func _build_upgrades() -> void:
	# Clear existing
	for child in upgrades_container.get_children():
		child.queue_free()
	
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 8)
	upgrades_container.add_child(vbox)
	
	var upgrades = PrestigeSystem.get_prestige_shop_upgrades()
	for upgrade_id in upgrades:
		var card = _create_upgrade_card(upgrade_id, upgrades[upgrade_id])
		vbox.add_child(card)


func _create_upgrade_card(upgrade_id: String, data: Dictionary) -> Control:
	var panel = PanelContainer.new()
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 4)

	var name_label = Label.new()
	name_label.text = data["name"]
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

	var desc_label = Label.new()
	desc_label.text = data["effect"]
	desc_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	desc_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))

	var current_level = GameState.get_upgrade_level(upgrade_id)
	var level_label = Label.new()
	level_label.text = "等级: " + str(current_level) + "/" + str(data["max_level"])
	level_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

	var buy_btn = Button.new()
	buy_btn.text = PrestigeSystem.get_upgrade_cost_display(upgrade_id)
	buy_btn.pressed.connect(_on_upgrade_pressed.bind(upgrade_id))

	if PrestigeConfig.is_upgrade_maxed(upgrade_id, current_level):
		buy_btn.disabled = true
	else:
		var cost = PrestigeConfig.get_upgrade_cost(upgrade_id, current_level)
		if GameState.prestige_points < cost:
			buy_btn.disabled = true

	vbox.add_child(name_label)
	vbox.add_child(desc_label)
	vbox.add_child(level_label)
	vbox.add_child(buy_btn)
	panel.add_child(vbox)

	return panel


func _on_upgrade_pressed(upgrade_id: String) -> void:
	if PrestigeSystem.buy_upgrade(upgrade_id):
		_update_display()
		# Refresh all buttons
		_build_upgrades()


func _update_display() -> void:
	# Points
	points_label.text = "⭐ 声望点: " + str(GameState.prestige_points) + " | 倍率: " + str(GameState.get_prestige_multiplier()) + "x"
	
	# Progress to next tier
	var next_info = PrestigeSystem.get_next_prestige_info()
	if next_info.is_empty():
		progress_bar.value = 100.0
		next_tier_label.text = "已满级!"
		status_label.text = "状态: 已满级"
		prestige_btn.disabled = true
		prestige_btn.text = "⭐ 已满级"
	else:
		var current_earned = GameState.total_earned
		var required = next_info["total_earned_req"]
		var progress = min(current_earned / required * 100.0, 100.0)
		progress_bar.value = progress
		next_tier_label.text = "下一级: Lv." + str(next_info["level"]) + " (需要 " + NumberFormatter.format_money(required) + ")"
		
		var can_prestige = PrestigeSystem.can_prestige()
		prestige_btn.disabled = not can_prestige
		prestige_btn.text = "🔄 进行声望重置" if can_prestige else "🔒 条件不足"


func _on_prestige_btn_pressed() -> void:
	if not PrestigeSystem.can_prestige():
		return
	
	# Show confirmation dialog
	_show_confirm_dialog()


func _show_confirm_dialog() -> void:
	if _confirm_dialog != null:
		return
	
	var ConfirmDialog = preload("res://scenes/dialogs/prestige_confirm_dialog.tscn")
	_confirm_dialog = ConfirmDialog.instantiate()
	_confirm_dialog.confirmed.connect(_on_confirm_accepted)
	_confirm_dialog.cancelled.connect(_on_confirm_closed)
	add_child(_confirm_dialog)


func _on_confirm_accepted() -> void:
	PrestigeSystem.do_prestige()
	_confirm_dialog = null
	_update_display()


func _on_confirm_closed() -> void:
	_confirm_dialog = null


func _on_close_pressed() -> void:
	shop_closed.emit()
	queue_free()


func _on_prestige_changed(_level: int, _points: int) -> void:
	_update_display()
