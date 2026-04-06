extends Control

signal confirmed
signal cancelled

@onready var current_level_label: Label = $Panel/VBox/CurrentInfo/CurrentLevelLabel
@onready var current_points_label: Label = $Panel/VBox/CurrentInfo/CurrentPointsLabel
@onready var next_level_label: Label = $Panel/VBox/NextInfo/NextLevelLabel
@onready var next_req_label: Label = $Panel/VBox/NextInfo/NextReqLabel
@onready var next_reward_label: Label = $Panel/VBox/NextInfo/NextRewardLabel
@onready var confirm_btn: Button = $Panel/VBox/ButtonBox/ConfirmBtn
@onready var cancel_btn: Button = $Panel/VBox/ButtonBox/CancelBtn


func _ready() -> void:
	cancel_btn.pressed.connect(_on_cancel_pressed)
	confirm_btn.pressed.connect(_on_confirm_pressed)
	_update_display()


func _update_display() -> void:
	# Current info
	current_level_label.text = "当前声望等级: Lv." + str(GameState.prestige_level)
	current_points_label.text = "当前声望点: " + str(GameState.prestige_points)
	
	# Next tier info
	var next_info = PrestigeSystem.get_next_prestige_info()
	if next_info.is_empty():
		next_level_label.text = "已满级"
		next_req_label.text = ""
		next_reward_label.text = ""
		confirm_btn.disabled = true
		confirm_btn.text = "已满级"
	else:
		next_level_label.text = "下一级: Lv." + str(next_info["level"])
		next_req_label.text = "要求: " + NumberFormatter.format_money(next_info["total_earned_req"]) + " 总收入"
		next_reward_label.text = "奖励: " + str(next_info["points_reward"]) + " 声望点, " + str(next_info["multiplier"]) + "x 倍率"


func _on_cancel_pressed() -> void:
	cancelled.emit()
	queue_free()


func _on_confirm_pressed() -> void:
	confirmed.emit()
	queue_free()
