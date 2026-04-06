class_name UrgeRentEvent
extends Control

const DIALOGUES = [
	"房东，再宽限几天吧...",
	"工资还没发，下个月一定交！",
	"我这就转给你！",
	"最近手头有点紧...",
	"房租能便宜点吗？",
]

@onready var title_label: Label = $Panel/VBox/TitleLabel
@onready var dialogue_label: Label = $Panel/VBox/DialogueLabel
@onready var progress_bar: ProgressBar = $Panel/VBox/ProgressBar
@onready var urge_btn: Button = $Panel/VBox/UrgeBtn
@onready var close_btn: Button = $Panel/VBox/CloseBtn

var _clicks: int = 0
var _required_clicks: int = 10
var _time_left: float = 8.0
var _timer: Timer

signal event_completed(reward: float)
signal event_dismissed


func _ready() -> void:
	urge_btn.pressed.connect(_on_urge_pressed)
	close_btn.pressed.connect(_on_close_pressed)

	# Randomize dialogue
	dialogue_label.text = DIALOGUES[randi() % DIALOGUES.size()]

	# Start countdown timer
	_timer = Timer.new()
	_timer.wait_time = 1.0
	_timer.timeout.connect(_on_timer_timeout)
	add_child(_timer)
	_timer.start()

	progress_bar.max_value = _required_clicks
	progress_bar.value = 0


func start_event(_data: Dictionary) -> void:
	_time_left = _data.get("duration", 8.0)


func _on_urge_pressed() -> void:
	_clicks += 1
	progress_bar.value = _clicks
	if _clicks >= _required_clicks:
		_complete_event(true)


func _complete_event(success: bool) -> void:
	var ips = Economy.get_income_per_second()
	if ips < 1:
		ips = 1.0
	var reward: float
	if success:
		reward = randf_range(ips * 10.0, ips * 30.0)
	else:
		reward = ips * 2.0
	GameState.add_gold(reward)
	event_completed.emit(reward)
	queue_free()


func _on_timer_timeout() -> void:
	_time_left -= 1.0
	if _time_left <= 0:
		_complete_event(false)


func _on_close_pressed() -> void:
	_complete_event(false)
