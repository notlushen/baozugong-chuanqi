class_name CoinRainGame
extends Control

@onready var score_label: Label = $ScoreLabel
@onready var timer_label: Label = $TimerLabel
@onready var coins_container: Node2D = $CoinsContainer
@onready var close_btn: Button = $CloseBtn
@onready var game_timer: Timer = $GameTimer
@onready var spawn_timer: Timer = $SpawnTimer

var _score: int = 0
var _time_left: float = 15.0
var _is_playing: bool = false

signal game_closed
signal game_finished(total_reward: float)


func _ready() -> void:
	game_timer.timeout.connect(_on_game_timer_timeout)
	spawn_timer.timeout.connect(_spawn_coin)
	close_btn.pressed.connect(_on_close_pressed)
	start_game()


func start_game() -> void:
	_is_playing = true
	_score = 0
	_time_left = 15.0
	game_timer.wait_time = 15.0
	game_timer.start()
	spawn_timer.wait_time = 0.25
	spawn_timer.start()
	_update_displays()


func _spawn_coin() -> void:
	if not _is_playing:
		return

	var coin = Label.new()
	coin.text = "💰"
	coin.mouse_filter = Control.MOUSE_FILTER_STOP
	coin.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	coin.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	coin.offset_left = 0
	coin.offset_top = 0
	coin.offset_right = 40
	coin.offset_bottom = 40

	var viewport_width = get_viewport_rect().size.x
	var x_pos = randf_range(40, viewport_width - 40)
	coin.position = Vector2(x_pos, -30)

	coins_container.add_child(coin)

	# Animate falling using tween on full position vector
	var target_pos = Vector2(x_pos, get_viewport_rect().size.y + 30)
	var tween = create_tween()
	tween.set_ease(Tween.EASE_IN)
	tween.tween_property(coin, "position", target_pos, 3.0)
	tween.tween_callback(coin.queue_free)

	# Connect click
	coin.gui_input.connect(_on_coin_clicked.bind(coin))


func _on_coin_clicked(event: InputEvent, coin: Node) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_score += 1
		_update_displays()
		coin.queue_free()


func _on_game_timer_timeout() -> void:
	_is_playing = false
	spawn_timer.stop()

	var reward = float(_score) * Economy.get_income_per_second() * 0.1
	if reward < 10:
		reward = 10.0
	GameState.add_gold(reward)

	score_label.text = "获得: " + NumberFormatter.format_money(reward)
	game_finished.emit(reward)


func _update_displays() -> void:
	score_label.text = "已收集: " + str(_score) + " 金币"
	var display_time = maxf(_time_left, 0.0)
	timer_label.text = "剩余时间: " + str(snapped(display_time, 0.1)) + "s"


func _process(delta: float) -> void:
	if _is_playing:
		_time_left -= delta
		_update_displays()


func _on_close_pressed() -> void:
	if _is_playing:
		_is_playing = false
		game_timer.stop()
		spawn_timer.stop()
	game_closed.emit()
