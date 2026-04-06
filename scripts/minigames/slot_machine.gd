class_name SlotMachineGame
extends Control

# 5 reels, 10 furniture symbols
const FURNITURE_SYMBOLS = ["🪑", "🛋️", "🛏️", "🪴", "💡", "🖼️", "🪟", "🟫", "🕐", "🏺"]
const SPIN_DURATION = 2.0
const REEL_STOP_DELAY = 0.3  # Each reel stops 0.3s after the previous
const FURNITURE_DROP_CHANCE = 0.3  # 30% chance to win furniture on 3+ match

@onready var reels_container: HBoxContainer = $VBox/ReelsContainer
@onready var result_label: Label = $VBox/ResultLabel
@onready var prize_label: Label = $VBox/PrizeLabel
@onready var bet_label: Label = $VBox/BetLabel
@onready var spin_btn: Button = $VBox/ButtonHBox/SpinBtn
@onready var close_btn: Button = $VBox/ButtonHBox/CloseBtn
@onready var bet_tiers_container: HBoxContainer = $VBox/BetTiersContainer

var _is_spinning: bool = false
var _current_bet_index: int = 0
var _reel_labels: Array[Label] = []
var _animation_timers: Array[Timer] = []
var _final_symbols: Array[String] = []

signal game_closed


func _ready() -> void:
	spin_btn.pressed.connect(_on_spin_pressed)
	close_btn.pressed.connect(_on_close_pressed)
	_build_bet_tiers()
	_build_reels()
	_update_bet_display()


func _build_bet_tiers() -> void:
	var tiers = MiniGameConfig.SLOT_MACHINE["bet_tiers"]
	for i in range(tiers.size()):
		var tier = tiers[i]
		var btn = Button.new()
		btn.text = tier["icon"] + " " + tier["name"] + " (" + NumberFormatter.format_money(tier["cost"]) + ")"
		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		btn.pressed.connect(_on_bet_tier_pressed.bind(i))
		if i == _current_bet_index:
			btn.disabled = true
			btn.modulate = Color(0.5, 1, 0.5)
		bet_tiers_container.add_child(btn)


func _build_reels() -> void:
	for i in range(5):
		var reel = Label.new()
		reel.text = FURNITURE_SYMBOLS[randi() % FURNITURE_SYMBOLS.size()]
		reel.size = Vector2(80, 100)
		reel.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		reel.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		reel.add_theme_font_size_override("font_size", 50)
		reels_container.add_child(reel)
		_reel_labels.append(reel)


func _on_bet_tier_pressed(index: int) -> void:
	_current_bet_index = index
	_update_bet_display()
	# Update button states
	for i in range(bet_tiers_container.get_child_count()):
		var btn = bet_tiers_container.get_child(i)
		if i == _current_bet_index:
			btn.disabled = true
			btn.modulate = Color(0.5, 1, 0.5)
		else:
			btn.disabled = false
			btn.modulate = Color(1, 1, 1)


func _get_current_bet() -> Dictionary:
	return MiniGameConfig.SLOT_MACHINE["bet_tiers"][_current_bet_index]


func _update_bet_display() -> void:
	var bet = _get_current_bet()
	bet_label.text = "当前下注: " + bet["icon"] + " " + bet["name"] + " - " + NumberFormatter.format_money(bet["cost"])


func _on_spin_pressed() -> void:
	if _is_spinning:
		return

	var bet = _get_current_bet()
	var cost = bet["cost"]

	if not GameState.can_afford(cost):
		result_label.text = "💸 金币不足！"
		result_label.add_theme_color_override("font_color", Color(1, 0.3, 0.3))
		return

	GameState.spend_gold(cost)
	_is_spinning = true
	spin_btn.disabled = true
	result_label.text = ""
	prize_label.text = ""

	# Disable bet buttons during spin
	for btn in bet_tiers_container.get_children():
		btn.disabled = true

	# Start reel animations with staggered stops
	var spin_timer = Timer.new()
	spin_timer.wait_time = SPIN_DURATION
	spin_timer.one_shot = true
	spin_timer.timeout.connect(_stop_reels)
	add_child(spin_timer)
	spin_timer.start()

	# Start rapid symbol changes
	for i in range(5):
		var timer = Timer.new()
		timer.wait_time = 0.05
		timer.timeout.connect(_animate_reel.bind(i))
		add_child(timer)
		timer.start()
		_animation_timers.append(timer)


func _animate_reel(reel_index: int) -> void:
	if reel_index < _reel_labels.size():
		_reel_labels[reel_index].text = FURNITURE_SYMBOLS[randi() % FURNITURE_SYMBOLS.size()]


func _stop_reels() -> void:
	# Determine final symbols
	_final_symbols = []
	for i in range(5):
		_final_symbols.append(FURNITURE_SYMBOLS[randi() % FURNITURE_SYMBOLS.size()])

	# Stop reels one by one with delay
	for i in range(5):
		var delay = i * REEL_STOP_DELAY
		var timer = Timer.new()
		timer.wait_time = delay
		timer.one_shot = true
		timer.timeout.connect(_stop_single_reel.bind(i))
		add_child(timer)
		timer.start()

	# After all reels stopped, calculate result
	var total_delay = 4 * REEL_STOP_DELAY + 0.5
	var result_timer = Timer.new()
	result_timer.wait_time = total_delay
	result_timer.one_shot = true
	result_timer.timeout.connect(_calculate_result)
	add_child(result_timer)
	result_timer.start()


func _stop_single_reel(reel_index: int) -> void:
	if reel_index < _reel_labels.size() and reel_index < _final_symbols.size():
		_reel_labels[reel_index].text = _final_symbols[reel_index]
		# Stop the animation timer for this reel
		if reel_index < _animation_timers.size():
			_animation_timers[reel_index].stop()
			_animation_timers[reel_index].queue_free()


func _calculate_result() -> void:
	# Clean up remaining timers
	for timer in _animation_timers:
		if is_instance_valid(timer):
			timer.stop()
			timer.queue_free()
	_animation_timers.clear()

	var bet = _get_current_bet()
	var cost = bet["cost"]

	# Count matching symbols
	var symbol_counts: Dictionary = {}
	for sym in _final_symbols:
		symbol_counts[sym] = symbol_counts.get(sym, 0) + 1

	# Find the best match
	var max_match = 0
	var matched_symbol = ""
	for sym in symbol_counts:
		if symbol_counts[sym] > max_match:
			max_match = symbol_counts[sym]
			matched_symbol = sym

	# Calculate payout
	var payout: float = 0.0
	var prize_text = ""

	if max_match >= 3:
		var multiplier: float
		if max_match == 3:
			multiplier = randf_range(2.0, 5.0)
		elif max_match == 4:
			multiplier = randf_range(10.0, 20.0)
		else:  # 5 match
			multiplier = randf_range(50.0, 100.0)

		payout = cost * multiplier
		GameState.add_gold(payout)

		if max_match == 5:
			result_label.text = "🎉🎉🎉 头奖！5个" + matched_symbol + "！🎉🎉🎉"
			result_label.add_theme_color_override("font_color", Color(1, 0.8, 0))
		elif max_match == 4:
			result_label.text = "✨ 大奖！4个" + matched_symbol + "！✨"
			result_label.add_theme_color_override("font_color", Color(1, 0.6, 0))
		else:
			result_label.text = "🎊 中奖！3个" + matched_symbol + "！"
			result_label.add_theme_color_override("font_color", Color(0.5, 1, 0.5))

		prize_text = "获得: " + NumberFormatter.format_money(payout)

		# Bonus: chance to win furniture on 3+ match
		if randf() < 0.3:  # 30% chance
			var furn_ids = MiniGameConfig.get_all_furniture_ids()
			var furn_id = furn_ids[randi() % furn_ids.size()]
			var furn_data = MiniGameConfig.get_furniture(furn_id)
			GameState.add_furniture(furn_id)
			prize_text += "\n🎁 额外奖励: " + furn_data["icon"] + " " + furn_data["name"] + " (租金+" + str(int(furn_data["rent_bonus"] * 100)) + "%)"
	elif max_match == 2:
		# Small consolation: return 50% of bet
		payout = cost * 0.5
		GameState.add_gold(payout)
		result_label.text = "差一点！2个" + matched_symbol
		result_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
		prize_text = "安慰奖: " + NumberFormatter.format_money(payout)
	else:
		result_label.text = "😔 未中奖..."
		result_label.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
		prize_text = "再试一次吧！"

	prize_label.text = prize_text

	# Re-enable controls
	_is_spinning = false
	spin_btn.disabled = false
	for i in range(bet_tiers_container.get_child_count()):
		var btn = bet_tiers_container.get_child(i)
		if i == _current_bet_index:
			btn.disabled = true
			btn.modulate = Color(0.5, 1, 0.5)
		else:
			btn.disabled = false
			btn.modulate = Color(1, 1, 1)

	_update_bet_display()


func _on_close_pressed() -> void:
	if _is_spinning:
		return
	game_closed.emit()
