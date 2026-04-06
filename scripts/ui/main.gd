extends Control

const PROPERTY_PANEL_SCENE = preload("res://scenes/ui/property_panel.tscn")
const SLOT_MACHINE_SCENE = preload("res://scenes/minigames/slot_machine.tscn")
const COIN_RAIN_SCENE = preload("res://scenes/minigames/coin_rain.tscn")
const URGE_RENT_SCENE = preload("res://scenes/events/urge_rent_event.tscn")
const REPAIR_EVENT_SCENE = preload("res://scenes/events/repair_event.tscn")
const PRESTIGE_SHOP_SCENE = preload("res://scenes/ui/prestige_shop.tscn")
const PRESTIGE_CONFIRM_DIALOG = preload("res://scenes/dialogs/prestige_confirm_dialog.tscn")
const OFFLINE_SUMMARY_SCENE = preload("res://scenes/dialogs/offline_summary.tscn")

# Retro theme reference
const RetroTheme = preload("res://scripts/utils/pixel_theme.gd")

var gold_label: Label
var ips_label: Label
var prestige_label: Label
var property_list: VBoxContainer
var slot_machine_btn: Button
var coin_rain_btn: Button
var prestige_btn: Button
var collect_rent_btn: Button
var menu_btn: Button
var save_btn: Button

var _active_popup: Control = null
var _event_popup: Control = null
var _refresh_timer: float = 0.0
var _coin_particles: Array[Node] = []
var _city_view_container: Control = null
var _building_containers: Array[Control] = []


func _ready() -> void:
	_build_ui()

	_update_gold_display(GameState.money)
	_update_pending_rent_display(GameState.pending_rent)
	_update_ips_display(GameState.income_per_second)
	_update_prestige_display(GameState.prestige_level, GameState.prestige_points)

	# Connect signals
	GameState.money_changed.connect(_update_gold_display)
	GameState.pending_rent_changed.connect(_update_pending_rent_display)
	GameState.income_per_second_changed.connect(_update_ips_display)
	GameState.prestige_changed.connect(_on_prestige_changed)

	# Button signals
	slot_machine_btn.pressed.connect(_on_slot_machine_btn_pressed)
	coin_rain_btn.pressed.connect(_on_coin_rain_btn_pressed)
	prestige_btn.pressed.connect(_on_prestige_btn_pressed)

	# Build property panel
	_build_property_panel()

	# Event manager signals
	EventManager.event_triggered.connect(_on_event_triggered)

	# Try to load saved game
	if SaveSystem.has_save_file():
		SaveSystem.load_game()
		if GameState.last_save_time > 0:
			var elapsed = Time.get_unix_time_from_system() - GameState.last_save_time
			if elapsed > 5.0:
				_show_offline_summary()
		SaveSystem.save_game()
	else:
		SaveSystem.save_game()


func _build_ui() -> void:
	# Apply retro theme to this control
	theme = RetroTheme.get_theme()
	
	# Root VBoxContainer
	var root_vbox = VBoxContainer.new()
	root_vbox.layout_mode = 1
	root_vbox.anchor_left = 0.0
	root_vbox.anchor_top = 0.0
	root_vbox.anchor_right = 1.0
	root_vbox.anchor_bottom = 1.0
	root_vbox.grow_horizontal = 2
	root_vbox.grow_vertical = 2
	root_vbox.add_theme_constant_override("separation", 4)
	add_child(root_vbox)

	# Header with prominent pixel styling
	var header_panel = PanelContainer.new()
	header_panel.custom_minimum_size = Vector2(0, 90)
	header_panel.add_theme_stylebox_override("panel", RetroTheme.create_panel_style(
		RetroTheme.COLOR_BG, RetroTheme.COLOR_BORDER, 3))
	root_vbox.add_child(header_panel)

	var header_vbox = VBoxContainer.new()
	header_panel.add_child(header_vbox)
	
	# Title label
	var title_label = Label.new()
	title_label.text = "🏙️ 房产大亨"
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.add_theme_font_size_override("font_size", 24)
	header_vbox.add_child(title_label)
	
	# Stats row
	var header_hbox = HBoxContainer.new()
	header_hbox.add_theme_constant_override("separation", 40)
	header_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	header_vbox.add_child(header_hbox)

	var spacer1 = Control.new()
	spacer1.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header_hbox.add_child(spacer1)

	gold_label = Label.new()
	gold_label.text = "0"
	gold_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	gold_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	gold_label.add_theme_font_size_override("font_size", 20)
	header_hbox.add_child(gold_label)

	ips_label = Label.new()
	ips_label.text = "+0/秒"
	ips_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ips_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	ips_label.add_theme_font_size_override("font_size", 16)
	header_hbox.add_child(ips_label)

	prestige_label = Label.new()
	prestige_label.text = "⭐ Lv.0 (0)"
	prestige_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	prestige_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	prestige_label.add_theme_font_size_override("font_size", 16)
	header_hbox.add_child(prestige_label)

	# Prestige button removed - use bottom button instead

	var spacer2 = Control.new()
	spacer2.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header_hbox.add_child(spacer2)

	# Pixel-style separator
	var top_separator = HSeparator.new()
	top_separator.add_theme_stylebox_override("separator", RetroTheme.create_pixel_border(
		RetroTheme.COLOR_BORDER, 2))
	root_vbox.add_child(top_separator)

	# Main HSplitContainer
	var main_container = HSplitContainer.new()
	main_container.size_flags_vertical = Control.SIZE_EXPAND_FILL
	main_container.split_offset = 250
	root_vbox.add_child(main_container)

	# Property panel (left)
	var property_panel = PanelContainer.new()
	property_panel.custom_minimum_size = Vector2(250, 0)
	property_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	property_panel.add_theme_stylebox_override("panel", RetroTheme.create_panel_style(
		RetroTheme.COLOR_PANEL, RetroTheme.COLOR_BORDER, 2))
	main_container.add_child(property_panel)

	var property_scroll = ScrollContainer.new()
	property_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	property_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	property_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	property_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	property_panel.add_child(property_scroll)

	property_list = VBoxContainer.new()
	property_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	property_list.size_flags_vertical = Control.SIZE_EXPAND_FILL
	property_list.add_theme_constant_override("separation", 8)
	property_scroll.add_child(property_list)

	# City view (center) - replaced placeholder with actual pixel buildings
	var game_view = PanelContainer.new()
	game_view.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	game_view.size_flags_vertical = Control.SIZE_EXPAND_FILL
	game_view.custom_minimum_size = Vector2(0, 200)  # 固定最小高度
	game_view.add_theme_stylebox_override("panel", RetroTheme.create_panel_style(
		RetroTheme.COLOR_BG, RetroTheme.COLOR_SECONDARY, 2))
	main_container.add_child(game_view)
	
	# ScrollContainer for city buildings - 防止内容过多导致底部按钮被挤出
	var city_scroll = ScrollContainer.new()
	city_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	city_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	city_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	city_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	game_view.add_child(city_scroll)
	
	# City container for buildings - use GridContainer for better layout
	_city_view_container = GridContainer.new()
	_city_view_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_city_view_container.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_city_view_container.columns = 6  # 6 buildings per row
	_city_view_container.add_theme_constant_override("h_separation", 4)
	_city_view_container.add_theme_constant_override("v_separation", 4)
	city_scroll.add_child(_city_view_container)
	
	# Initialize city view with buildings
	_build_city_view()

	# Bottom separator
	var mid_separator = HSeparator.new()
	mid_separator.add_theme_stylebox_override("separator", RetroTheme.create_pixel_border(
		RetroTheme.COLOR_BORDER, 2))
	root_vbox.add_child(mid_separator)

	# Mini-game panel (bottom)
	var minigame_panel = PanelContainer.new()
	minigame_panel.custom_minimum_size = Vector2(0, 70)
	minigame_panel.add_theme_stylebox_override("panel", RetroTheme.create_panel_style(
		RetroTheme.COLOR_PANEL, RetroTheme.COLOR_BORDER, 2))
	root_vbox.add_child(minigame_panel)

	var minigame_hbox = HBoxContainer.new()
	minigame_hbox.add_theme_constant_override("separation", 10)
	minigame_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	minigame_panel.add_child(minigame_hbox)

	collect_rent_btn = Button.new()
	collect_rent_btn.text = "🏠 收租"
	collect_rent_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	collect_rent_btn.pressed.connect(_on_collect_rent_pressed)
	minigame_hbox.add_child(collect_rent_btn)

	slot_machine_btn = Button.new()
	slot_machine_btn.text = "🎰 老虎机"
	minigame_hbox.add_child(slot_machine_btn)

	coin_rain_btn = Button.new()
	coin_rain_btn.text = "🌧️ 金币雨"
	minigame_hbox.add_child(coin_rain_btn)

	var spacer3 = Control.new()
	spacer3.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	minigame_hbox.add_child(spacer3)

	prestige_btn = Button.new()
	prestige_btn.text = "⭐ 声望"
	minigame_hbox.add_child(prestige_btn)

	var spacer4 = Control.new()
	spacer4.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	minigame_hbox.add_child(spacer4)

	save_btn = Button.new()
	save_btn.text = "💾 存档"
	minigame_hbox.add_child(save_btn)

	menu_btn = Button.new()
	menu_btn.text = "🏠 菜单"
	minigame_hbox.add_child(menu_btn)

	# Connect save and menu buttons
	save_btn.pressed.connect(_on_save_pressed)
	menu_btn.pressed.connect(_on_menu_pressed)


func _process(delta: float) -> void:
	_refresh_timer += delta
	if _refresh_timer >= 0.5:
		_refresh_timer = 0.0
		_refresh_property_panel()


func _show_offline_summary() -> void:
	var dialog = OFFLINE_SUMMARY_SCENE.instantiate()
	dialog.dialog_closed.connect(_on_offline_summary_closed)
	add_child(dialog)


func _on_offline_summary_closed() -> void:
	SaveSystem.save_game()


func _build_property_panel() -> void:
	for child in property_list.get_children():
		child.queue_free()

	var panel = PROPERTY_PANEL_SCENE.instantiate()
	property_list.add_child(panel)


func _update_gold_display(value: float) -> void:
	if gold_label:
		gold_label.text = "💰 " + NumberFormatter.format_money(value)


func _update_pending_rent_display(value: float) -> void:
	if collect_rent_btn:
		if value > 0:
			collect_rent_btn.text = "🏠 收租 (" + NumberFormatter.format_money(value) + ")"
		else:
			collect_rent_btn.text = "🏠 收租"


func _update_ips_display(ips: float) -> void:
	if ips_label:
		ips_label.text = NumberFormatter.format_income(ips)


func _update_prestige_display(level: int, points: int) -> void:
	if prestige_label:
		prestige_label.text = "⭐ Lv." + str(level) + " (" + str(points) + ")"


func _on_prestige_changed(level: int, _points: int) -> void:
	_update_prestige_display(level, _points)


func _refresh_property_panel() -> void:
	for child in property_list.get_children():
		if child.has_method("refresh_all"):
			child.refresh_all()
	
	# Also refresh city buildings when properties change
	_update_city_buildings()


func _build_city_view() -> void:
	# Clear existing buildings
	for child in _city_view_container.get_children():
		child.queue_free()
	_building_containers.clear()
	
	# Show initial empty state - buildings will be added when player buys property
	_update_city_buildings()


# Mapping of building types to asset files
const BUILDING_ASSETS = {
	"house": "res://assets/apartment.png",
	"apartment": "res://assets/two_bedroom.png",
	"shop": "res://assets/townhouse.png",
	"office": "res://assets/shop.png",
	"factory": "res://assets/office.png",
	"warehouse": "res://assets/hotel.png",
	"hotel": "res://assets/skyscraper.png",
	"skyscraper": "res://assets/skyscraper.png",
}

func _add_building_to_city(building_type: String, building_name: String, _index: int) -> void:
	var building_container = HBoxContainer.new()
	building_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	building_container.alignment = BoxContainer.ALIGNMENT_CENTER
	_city_view_container.add_child(building_container)
	
	# Create pixel-style building visual
	var building_panel = PanelContainer.new()
	building_panel.custom_minimum_size = Vector2(55, 45)
	building_panel.add_theme_stylebox_override("panel", 
		RetroTheme.create_panel_style(RetroTheme.get_building_color(building_type), 
		RetroTheme.COLOR_BORDER, 1))
	building_container.add_child(building_panel)
	
	var building_vbox = VBoxContainer.new()
	building_vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	building_vbox.add_theme_constant_override("separation", 0)
	building_panel.add_child(building_vbox)
	
	# Building type icon - use SVG image instead of emoji
	var icon_texture = TextureRect.new()
	icon_texture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon_texture.custom_minimum_size = Vector2(40, 40)
	icon_texture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	
	# Load the appropriate texture
	var asset_path = BUILDING_ASSETS.get(building_type, "res://assets/apartment.png")
	if ResourceLoader.exists(asset_path):
		icon_texture.texture = ResourceLoader.load(asset_path)
	else:
		# Fallback to emoji if asset not found
		var icon_label = Label.new()
		icon_label.text = "🏠"
		icon_label.add_theme_font_size_override("font_size", 24)
		building_vbox.add_child(icon_label)
		return
	
	building_vbox.add_child(icon_texture)


func _update_city_buildings() -> void:
	# Clear existing buildings first
	for child in _city_view_container.get_children():
		child.queue_free()
	_building_containers.clear()
	
	var properties = GameState.properties
	
	if properties.is_empty():
		# Show "build your city" message with icon
		var empty_container = HBoxContainer.new()
		empty_container.alignment = BoxContainer.ALIGNMENT_CENTER
		empty_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		_city_view_container.add_child(empty_container)
		
		var empty_icon = TextureRect.new()
		empty_icon.custom_minimum_size = Vector2(32, 32)
		empty_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		empty_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		if ResourceLoader.exists("res://assets/apartment.png"):
			empty_icon.texture = ResourceLoader.load("res://assets/apartment.png")
		empty_container.add_child(empty_icon)
		
		var empty_label = Label.new()
		empty_label.text = " 购买房产开始经营"
		empty_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		empty_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		empty_label.add_theme_font_size_override("font_size", 18)
		empty_label.modulate = RetroTheme.COLOR_TEXT_DIM
		_city_view_container.add_child(empty_label)
		return
	
	# Add buildings based on owned properties - show COUNT number of buildings for each type
	for property_id in properties.keys():
		var prop_data = properties[property_id]
		var count = prop_data.get("count", 0)
		if count <= 0:
			continue
		
		var building_type = _get_building_type_for_property_id(property_id)
		var building_name = Economy.get_property_name(property_id)
		
		# Add multiple buildings based on count
		for j in range(count):
			_add_building_to_city(building_type, building_name + " #" + str(j + 1), j)


func _get_building_type_for_property(prop: Dictionary) -> String:
	# Map property tier to building type
	var tier = prop.get("tier", 1)
	match tier:
		1:
			return "house"
		2:
			return "apartment"
		3:
			return "shop"
		4:
			return "office"
		5:
			return "factory"
		6:
			return "warehouse"
		7:
			return "hotel"
		8:
			return "skyscraper"
		_:
			return "house"


func _get_building_type_for_property_id(property_id: String) -> String:
	# Map property_id to building type
	match property_id:
		"apartment":
			return "house"
		"two_bedroom":
			return "apartment"
		"townhouse":
			return "shop"
		"shop":
			return "office"
		"office":
			return "factory"
		"hotel":
			return "warehouse"
		"skyscraper":
			return "hotel"
		_:
			return "house"


func _on_collect_rent_pressed() -> void:
	var collected = GameState.collect_pending_rent()
	if collected > 0:
		_spawn_coin_animation(collected)


func _spawn_coin_animation(amount: float) -> void:
	# Create floating coin particles
	var coin_count = mini(int(amount / 10) + 3, 20)  # 3-20 coins based on amount

	for i in range(coin_count):
		var coin = Label.new()
		coin.text = "💰"
		coin.size = Vector2(30, 30)
		coin.layout_mode = 1
		coin.anchor_left = 0.5
		coin.anchor_top = 0.5
		coin.anchor_right = 0.5
		coin.anchor_bottom = 0.5

		# Random starting position near center
		var start_x = randf_range(-100, 100)
		var start_y = randf_range(-50, 50)
		coin.offset_left = start_x
		coin.offset_top = start_y
		coin.offset_right = start_x + 30
		coin.offset_bottom = start_y + 30

		add_child(coin)
		_coin_particles.append(coin)

		# Animate: fly up and fade out
		var tween = create_tween()
		var end_x = start_x + randf_range(-150, 150)
		var end_y = start_y - randf_range(100, 300)

		tween.set_parallel(true)
		tween.tween_property(coin, "offset_left", end_x, 1.0 + randf() * 0.5)
		tween.tween_property(coin, "offset_top", end_y, 1.0 + randf() * 0.5)
		tween.tween_property(coin, "modulate:a", 0.0, 1.0 + randf() * 0.5)
		tween.set_ease(Tween.EASE_OUT)

		tween.tween_callback(coin.queue_free)

	# Animate gold label - pulse effect
	if gold_label:
		var label_tween = create_tween()
		label_tween.tween_property(gold_label, "scale", Vector2(1.3, 1.3), 0.15)
		label_tween.set_ease(Tween.EASE_OUT)
		label_tween.tween_property(gold_label, "scale", Vector2(1.0, 1.0), 0.3)
		label_tween.set_ease(Tween.EASE_IN)


func _on_slot_machine_btn_pressed() -> void:
	if _active_popup != null:
		return
	if not MiniGameManager.start_game("slot_machine"):
		var cd = MiniGameManager.get_cooldown_time("slot_machine")
		print("老虎机冷却中: " + str(snapped(cd, 0.1)) + "s")
		return
	var game = SLOT_MACHINE_SCENE.instantiate()
	game.game_closed.connect(_on_popup_closed)
	add_child(game)
	_active_popup = game


func _on_coin_rain_btn_pressed() -> void:
	if _active_popup != null:
		return
	if not MiniGameManager.start_game("coin_rain"):
		var cd = MiniGameManager.get_cooldown_time("coin_rain")
		print("金币雨冷却中: " + str(snapped(cd, 0.1)) + "s")
		return
	var game = COIN_RAIN_SCENE.instantiate()
	game.game_closed.connect(_on_coin_rain_closed)
	game.game_finished.connect(_on_coin_rain_finished)
	add_child(game)
	_active_popup = game


func _on_coin_rain_finished(_reward: float) -> void:
	pass


func _on_coin_rain_closed() -> void:
	MiniGameManager.end_game("coin_rain")
	_on_popup_closed()


func _on_prestige_btn_pressed() -> void:
	if _active_popup != null:
		return
	var shop = PRESTIGE_SHOP_SCENE.instantiate()
	shop.shop_closed.connect(_on_popup_closed)
	add_child(shop)
	_active_popup = shop
	# Center the shop
	await get_tree().process_frame
	var screen_size = get_viewport().get_visible_rect().size
	var shop_size = shop.size
	shop.position = (screen_size - shop_size) / 2


func _on_popup_closed() -> void:
	if _active_popup != null:
		_active_popup.queue_free()
		_active_popup = null


func _on_save_pressed() -> void:
	SaveSystem.save_game()
	# Show brief save confirmation
	var label = Label.new()
	label.text = "💾 已保存!"
	label.add_theme_font_size_override("font_size", 24)
	label.position = Vector2(100, 100)
	add_child(label)
	# Fade out and remove
	var tween = create_tween()
	tween.tween_interval(1.0)
	tween.tween_callback(label.queue_free)


func _on_menu_pressed() -> void:
	# Save before going back to menu
	SaveSystem.save_game()
	get_tree().change_scene_to_file("res://scenes/start_screen.tscn")

func _on_event_triggered(event_type: String, data: Dictionary) -> void:
	if _event_popup != null:
		return

	match event_type:
		"urge_rent":
			_show_event_popup(URGE_RENT_SCENE, event_type, data)
		"repair":
			_show_event_popup(REPAIR_EVENT_SCENE, event_type, data)


func _show_event_popup(scene: PackedScene, event_type: String, data: Dictionary) -> void:
	var popup = scene.instantiate()
	popup.event_completed.connect(_on_event_completed.bind(event_type))
	popup.event_dismissed.connect(_on_event_dismissed.bind(event_type))
	add_child(popup)
	_event_popup = popup

	if popup.has_method("start_event"):
		popup.start_event(data)


func _on_event_completed(reward: float, event_type: String) -> void:
	EventManager.complete_event(reward)
	_event_popup = null


func _on_event_dismissed(event_type: String) -> void:
	EventManager.dismiss_event()
	_event_popup = null
