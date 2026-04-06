class_name RepairEvent
extends Control

const REPAIR_TYPES = [
	"🔧 水管爆裂",
	"💡 电路故障",
	"🚪 门锁损坏",
	"🪟 玻璃破碎",
]

@onready var title_label: Label = $Panel/VBox/TitleLabel
@onready var dialogue_label: Label = $Panel/VBox/DialogueLabel
@onready var repair_btn: Button = $Panel/VBox/RepairBtn
@onready var close_btn: Button = $Panel/VBox/CloseBtn
@onready var indicator: ColorRect = $Panel/VBox/Indicator

var _time_left: float = 5.0
var _timer: Timer
var _can_click: bool = false
var _blink_timer: Timer

signal event_completed(reward: float)
signal event_dismissed


func _ready() -> void:
	repair_btn.pressed.connect(_on_repair_pressed)
	close_btn.pressed.connect(_on_close_pressed)

	# Randomize repair type
	dialogue_label.text = REPAIR_TYPES[randi() % REPAIR_TYPES.size()]

	# Start countdown timer
	_timer = Timer.new()
	_timer.wait_time = 1.0
	_timer.timeout.connect(_on_timer_timeout)
	add_child(_timer)
	_timer.start()

	# Start blink timer
	_blink_timer = Timer.new()
	_blink_timer.wait_time = 0.5
	_blink_timer.timeout.connect(_on_blink_timeout)
	add_child(_blink_timer)
	_blink_timer.start()

	indicator.visible = false


func start_event(data: Dictionary) -> void:
	_time_left = data.get("duration", 5.0)


func _on_repair_pressed() -> void:
	if _can_click:
		_complete_event(true)
	else:
		_complete_event(false)


func _complete_event(success: bool) -> void:
	var ips = Economy.get_income_per_second()
	if ips < 1:
		ips = 1.0
	var reward: float
	if success:
		reward = randf_range(ips * 5.0, ips * 15.0)
	else:
		reward = ips * 2.0
	GameState.add_gold(reward)
	event_completed.emit(reward)
	queue_free()


func _on_timer_timeout() -> void:
	_time_left -= 1.0
	if _time_left <= 0:
		_complete_event(false)


func _on_blink_timeout() -> void:
	_can_click = not _can_click
	if _can_click:
		indicator.color = Color(0, 1, 0, 1)
	else:
		indicator.color = Color(1, 0, 0, 0.3)
	indicator.visible = true


func _on_close_pressed() -> void:
	_complete_event(false)
