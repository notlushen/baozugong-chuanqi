extends Node


# Core currency values
var money: float = 500.0  # Starting capital
var pending_rent: float = 0.0  # Unclaimed rent income
var total_earned: float = 500.0  # Starting capital counts as earned
var prestige_level: int = 0
var prestige_points: int = 0

# Property management: property_id (String) -> {count: int, level: int}
var properties: Dictionary = {}

# Upgrade management: upgrade_id (String) -> level (int)
var upgrades: Dictionary = {}

# Furniture collection: furniture_id (String) -> count (int)
var furniture: Dictionary = {}

# Achievement tracking: achievement_id (String) -> unlocked (bool)
var achievements: Dictionary = {}

# Time tracking for offline progress
var last_save_time: float = 0.0

# Cached income per second (updated by Economy singleton)
var income_per_second: float = 0.0


# Signals
signal money_changed(new_value: float)
signal pending_rent_changed(new_value: float)
signal total_earned_changed(new_value: float)
signal prestige_changed(level: int, points: int)
signal property_changed(property_id: String, count: int, level: int)
signal upgrade_changed(upgrade_id: String, level: int)
signal income_per_second_changed(new_ips: float)


func add_gold(amount: float) -> void:
	money += amount
	total_earned += amount
	money_changed.emit(money)
	total_earned_changed.emit(total_earned)


func add_pending_rent(amount: float) -> void:
	pending_rent += amount
	pending_rent_changed.emit(pending_rent)


func collect_pending_rent() -> float:
	var collected = pending_rent
	if collected > 0:
		money += collected
		total_earned += collected
		pending_rent = 0.0
		money_changed.emit(money)
		total_earned_changed.emit(total_earned)
		pending_rent_changed.emit(pending_rent)
	return collected


func spend_gold(amount: float) -> bool:
	if money >= amount:
		money -= amount
		money_changed.emit(money)
		return true
	return false


func can_afford(amount: float) -> bool:
	return money >= amount


func get_property_count(property_id: String) -> int:
	if properties.has(property_id):
		return properties[property_id].get("count", 0)
	return 0


func get_property_level(property_id: String) -> int:
	if properties.has(property_id):
		return properties[property_id].get("level", 0)
	return 0


func set_property(property_id: String, count: int, level: int) -> void:
	properties[property_id] = {"count": count, "level": level}
	property_changed.emit(property_id, count, level)


func get_upgrade_level(upgrade_id: String) -> int:
	return upgrades.get(upgrade_id, 0)


func set_upgrade(upgrade_id: String, level: int) -> void:
	upgrades[upgrade_id] = level
	upgrade_changed.emit(upgrade_id, level)


func add_furniture(furniture_id: String, amount: int = 1) -> void:
	if not furniture.has(furniture_id):
		furniture[furniture_id] = 0
	var max_count = MiniGameConfig.FURNITURE_MAX_PER_TYPE
	furniture[furniture_id] = mini(furniture[furniture_id] + amount, max_count)


func get_furniture_count(furniture_id: String) -> int:
	return furniture.get(furniture_id, 0)


func get_furniture_bonus() -> float:
	# Calculate bonus from individual furniture pieces
	var bonus: float = 0.0
	for furn_id in furniture:
		var count = furniture[furn_id]
		if count > 0:
			var furn_data = MiniGameConfig.get_furniture(furn_id)
			if not furn_data.is_empty():
				bonus += furn_data.get("rent_bonus", 0.0) * count

	# Check for complete set bonus
	var all_ids = MiniGameConfig.get_all_furniture_ids()
	var has_complete_set = true
	for furn_id in all_ids:
		if get_furniture_count(furn_id) < 1:
			has_complete_set = false
			break
	if has_complete_set:
		bonus += MiniGameConfig.FURNITURE_SET_BONUS

	return bonus


func reset_for_prestige() -> void:
	money = 500.0  # Starting capital like new game
	pending_rent = 0.0
	total_earned = 500.0  # Starting capital counts as earned
	properties.clear()
	upgrades.clear()
	# Keep furniture collection - it's permanent!

	# Keep prestige_level, prestige_points, achievements
	money_changed.emit(money)
	pending_rent_changed.emit(pending_rent)
	total_earned_changed.emit(total_earned)
	prestige_changed.emit(prestige_level, prestige_points)


func update_income_per_second(ips: float) -> void:
	income_per_second = ips
	income_per_second_changed.emit(income_per_second)


func get_prestige_multiplier() -> float:
	match prestige_level:
		0: return 1.0
		1: return 1.25
		2: return 1.50
		3: return 2.00
		4: return 2.75
		5: return 3.75
		_: return 3.75 + (prestige_level - 5) * 0.5


func get_global_multiplier() -> float:
	var multiplier: float = 1.0

	if upgrades.has("rent_bonus"):
		var rent_level: int = upgrades["rent_bonus"]
		multiplier *= (1.0 + 0.05 * rent_level)

	# Add furniture bonus
	var furn_bonus = get_furniture_bonus()
	multiplier *= (1.0 + furn_bonus)

	return multiplier
