extends Node


signal prestige_completed(new_level: int, new_points: int)


func can_prestige() -> bool:
	return PrestigeConfig.can_prestige(GameState.total_earned, GameState.prestige_level)


func get_next_prestige_info() -> Dictionary:
	return PrestigeConfig.get_next_prestige_level(GameState.prestige_level)


func do_prestige() -> void:
	var next = get_next_prestige_info()
	if next.is_empty():
		return

	var points_multiplier = 1
	if GameState.get_upgrade_level("double_prestige") > 0:
		points_multiplier = 2

	GameState.prestige_level = next["level"]
	GameState.prestige_points += next["points_reward"] * points_multiplier
	GameState.reset_for_prestige()

	prestige_completed.emit(GameState.prestige_level, GameState.prestige_points)
	GameState.prestige_changed.emit(GameState.prestige_level, GameState.prestige_points)
	SaveSystem.save_game()


func get_prestige_shop_upgrades() -> Dictionary:
	return PrestigeConfig.PRESTIGE_SHOP_UPGRADES


func buy_upgrade(upgrade_id: String) -> bool:
	var current_level = GameState.get_upgrade_level(upgrade_id)
	if PrestigeConfig.is_upgrade_maxed(upgrade_id, current_level):
		return false

	var cost = PrestigeConfig.get_upgrade_cost(upgrade_id, current_level)
	if GameState.prestige_points < cost:
		return false

	GameState.prestige_points -= cost
	GameState.set_upgrade(upgrade_id, current_level + 1)
	SaveSystem.save_game()
	return true


func get_upgrade_cost_display(upgrade_id: String) -> String:
	var current_level = GameState.get_upgrade_level(upgrade_id)
	if PrestigeConfig.is_upgrade_maxed(upgrade_id, current_level):
		return "已满级"
	var cost = PrestigeConfig.get_upgrade_cost(upgrade_id, current_level)
	return "⭐ " + str(cost) + " (Lv." + str(current_level) + " → " + str(current_level + 1) + ")"
