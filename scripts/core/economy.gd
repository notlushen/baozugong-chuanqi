extends Node


const PROPERTY_DATA = {
	"apartment": {"name": "单间公寓", "base_cost": 100, "base_rent": 5.0, "cost_growth": 1.15, "rent_growth": 0.08, "icon": "🏠", "max_count": 100},
	"two_bedroom": {"name": "两居室", "base_cost": 1100, "base_rent": 28.0, "cost_growth": 1.15, "rent_growth": 0.08, "icon": "🏢", "max_count": 80},
	"townhouse": {"name": "联排别墅", "base_cost": 12000, "base_rent": 140.0, "cost_growth": 1.15, "rent_growth": 0.08, "icon": "🏘️", "max_count": 60},
	"shop": {"name": "商业商铺", "base_cost": 130000, "base_rent": 780.0, "cost_growth": 1.15, "rent_growth": 0.08, "icon": "🏬", "max_count": 50},
	"office": {"name": "写字楼", "base_cost": 1400000, "base_rent": 4200.0, "cost_growth": 1.15, "rent_growth": 0.08, "icon": "🏗️", "max_count": 40},
	"hotel": {"name": "豪华酒店", "base_cost": 20000000, "base_rent": 26000.0, "cost_growth": 1.15, "rent_growth": 0.08, "icon": "🏰", "max_count": 30},
	"skyscraper": {"name": "摩天大楼", "base_cost": 330000000, "base_rent": 150000.0, "cost_growth": 1.15, "rent_growth": 0.08, "icon": "🌆", "prestige_req": 1, "max_count": 20}
}

const TICK_INTERVAL = 0.1

const UPGRADE_COST_TABLE = [0.5, 1.2, 2.5, 5.0, 8.0, 12.0, 18.0, 25.0]

var _income_timer: Timer


func _ready() -> void:
	_income_timer = Timer.new()
	_income_timer.wait_time = TICK_INTERVAL
	_income_timer.timeout.connect(_on_income_tick)
	add_child(_income_timer)
	_income_timer.start()


func get_property_cost(property_id: String) -> float:
	var data = PROPERTY_DATA[property_id]
	var base_cost = data["base_cost"]
	var count = GameState.get_property_count(property_id)
	var cost_growth = data["cost_growth"]
	var cost = base_cost * pow(cost_growth, count)
	
	var discount = 0.0
	if GameState.get_upgrade_level("price_discount") > 0:
		discount = 0.03 * GameState.get_upgrade_level("price_discount")
	cost *= (1.0 - discount)
	
	return cost


func get_property_rent(property_id: String) -> float:
	var data = PROPERTY_DATA[property_id]
	var base_rent = data["base_rent"]
	var level = GameState.get_property_level(property_id)
	var rent_growth = data["rent_growth"]
	var rent = base_rent * pow(1.0 + rent_growth, level)
	rent *= GameState.get_global_multiplier()
	rent *= GameState.get_prestige_multiplier()
	return rent


func get_income_per_second() -> float:
	var total_income = 0.0
	for property_id in PROPERTY_DATA.keys():
		var count = GameState.get_property_count(property_id)
		if count > 0:
			var rent = get_property_rent(property_id)
			total_income += rent * count
	return total_income


func buy_property(property_id: String) -> bool:
	# Check if property has reached max count
	var current_count = GameState.get_property_count(property_id)
	var max_count = get_property_max_count(property_id)
	if current_count >= max_count:
		return false
	
	var cost = get_property_cost(property_id)
	if GameState.can_afford(cost):
		GameState.spend_gold(cost)
		var new_count = current_count + 1
		# Preserve current level when buying additional properties
		var current_level = GameState.get_property_level(property_id)
		GameState.set_property(property_id, new_count, current_level)
		return true
	return false


func upgrade_property(property_id: String) -> bool:
	var count = GameState.get_property_count(property_id)
	if count == 0:
		return false  # Can't upgrade what you don't own
	var level = GameState.get_property_level(property_id)
	if level >= count:
		return false  # Level cap reached: Level cannot exceed Count
	var cost = get_upgrade_cost(property_id)
	if GameState.can_afford(cost):
		GameState.spend_gold(cost)
		var new_level = level + 1
		GameState.set_property(property_id, count, new_level)
		return true
	return false


func get_upgrade_cost(property_id: String) -> float:
	var data = PROPERTY_DATA[property_id]
	var base_cost = data["base_cost"]
	var level = GameState.get_property_level(property_id)
	var table_index = min(level, UPGRADE_COST_TABLE.size() - 1)
	return base_cost * UPGRADE_COST_TABLE[table_index]


func _on_income_tick() -> void:
	var income = get_income_per_second() * TICK_INTERVAL
	if income > 0:
		GameState.add_pending_rent(income)
		GameState.update_income_per_second(get_income_per_second())


func get_property_ids() -> Array:
	return PROPERTY_DATA.keys()


func get_property_name(property_id: String) -> String:
	return PROPERTY_DATA[property_id]["name"]


func get_property_icon(property_id: String) -> String:
	return PROPERTY_DATA[property_id]["icon"]


func is_property_unlocked(property_id: String) -> bool:
	var data = PROPERTY_DATA[property_id]
	if "prestige_req" in data:
		return GameState.prestige_level >= data["prestige_req"]
	return true


func get_property_max_count(property_id: String) -> int:
	var data = PROPERTY_DATA[property_id]
	return data.get("max_count", 999)
