extends PanelContainer

@export var property_id: String = ""

@onready var name_label: Label = $VBox/NameLabel
@onready var count_label: Label = $VBox/CountLabel
@onready var rent_label: Label = $VBox/RentLabel
@onready var cost_label: Label = $VBox/CostLabel
@onready var buy_btn: Button = $VBox/HBox/BuyBtn
@onready var upgrade_btn: Button = $VBox/HBox/UpgradeBtn


func _ready() -> void:
	buy_btn.pressed.connect(_on_buy_pressed)
	upgrade_btn.pressed.connect(_on_upgrade_pressed)
	update_display()


func update_display() -> void:
	if property_id == "":
		return

	var name = Economy.get_property_name(property_id)
	var icon = Economy.get_property_icon(property_id)
	var count = GameState.get_property_count(property_id)
	var level = GameState.get_property_level(property_id)
	var cost = Economy.get_property_cost(property_id)
	var rent = Economy.get_property_rent(property_id)
	var upgrade_cost = Economy.get_upgrade_cost(property_id)
	var max_count = Economy.get_property_max_count(property_id)

	name_label.text = icon + " " + name

	if count > 0:
		var max_level = count
		count_label.text = "拥有: " + str(count) + "/" + str(max_count) + " (Lv." + str(level) + "/" + str(max_level) + ")"
		var total_rent = rent * count
		rent_label.text = "每套: +" + NumberFormatter.format_number(rent) + "/秒 | 总计: +" + NumberFormatter.format_number(total_rent) + "/秒"
	else:
		count_label.text = "拥有: 0/" + str(max_count)
		rent_label.text = "每套: +" + NumberFormatter.format_number(rent) + "/秒"

	cost_label.text = "购买: " + NumberFormatter.format_money(cost) + " | 升级: " + NumberFormatter.format_money(upgrade_cost)

	# Check if at max count
	var is_max_count = (count >= max_count)
	
	# Update button states
	buy_btn.disabled = is_max_count or not GameState.can_afford(cost)
	if is_max_count:
		buy_btn.text = "已满"
	else:
		buy_btn.text = "购买"
	
	var is_max_level = (count > 0 and level >= count)
	upgrade_btn.disabled = is_max_level or not GameState.can_afford(upgrade_cost) or count == 0


func _on_buy_pressed() -> void:
	if Economy.buy_property(property_id):
		update_display()


func _on_upgrade_pressed() -> void:
	if Economy.upgrade_property(property_id):
		update_display()
