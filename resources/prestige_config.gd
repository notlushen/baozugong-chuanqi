class_name PrestigeConfig
extends Object

const PRESTIGE_TIERS = [
	{"level": 1, "total_earned_req": 10000000, "points_reward": 10, "multiplier": 1.25},
	{"level": 2, "total_earned_req": 100000000, "points_reward": 25, "multiplier": 1.50},
	{"level": 3, "total_earned_req": 1000000000, "points_reward": 50, "multiplier": 2.00},
	{"level": 4, "total_earned_req": 10000000000, "points_reward": 100, "multiplier": 2.75},
	{"level": 5, "total_earned_req": 100000000000, "points_reward": 200, "multiplier": 3.75},
]

const PRESTIGE_SHOP_UPGRADES = {
	"rent_bonus": {"name": "租金加成", "base_cost": 5, "effect": "全局租金 +5%", "max_level": 20},
	"offline_efficiency": {"name": "离线效率", "base_cost": 10, "effect": "离线收益 50% → 100%", "max_level": 1},
	"minigame_bonus": {"name": "小游戏加成", "base_cost": 8, "effect": "小游戏奖励 +10%", "max_level": 10},
	"price_discount": {"name": "价格折扣", "base_cost": 15, "effect": "房产价格 -3%", "max_level": 5},
	"auto_collect": {"name": "自动收租", "base_cost": 25, "effect": "离线时自动收集随机事件", "max_level": 1},
	"double_prestige": {"name": "双倍声望", "base_cost": 50, "effect": "声望点获取 ×2", "max_level": 1},
}


static func get_next_prestige_level(current_level: int) -> Dictionary:
	if current_level >= PRESTIGE_TIERS.size():
		return {}
	return PRESTIGE_TIERS[current_level]


static func can_prestige(total_earned: float, current_level: int) -> bool:
	var next = get_next_prestige_level(current_level)
	if next.is_empty():
		return false
	return total_earned >= next["total_earned_req"]


static func get_upgrade_cost(upgrade_id: String, current_level: int) -> int:
	var upgrade = PRESTIGE_SHOP_UPGRADES.get(upgrade_id, {})
	if upgrade.is_empty():
		return 0
	return int(upgrade["base_cost"] * (1.0 + current_level * 0.5))


static func is_upgrade_maxed(upgrade_id: String, current_level: int) -> bool:
	var upgrade = PRESTIGE_SHOP_UPGRADES.get(upgrade_id, {})
	if upgrade.is_empty():
		return true
	return current_level >= upgrade["max_level"]
