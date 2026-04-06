class_name MiniGameConfig
extends Object

const SLOT_MACHINE = {
	"id": "slot_machine",
	"name": "幸运老虎机",
	"icon": "🎰",
	"cooldown": 60.0,
	"bet_tiers": [
		{"id": "small", "name": "小注", "cost": 100, "icon": "🪙"},
		{"id": "medium", "name": "中注", "cost": 500, "icon": "💰"},
		{"id": "large", "name": "大注", "cost": 2000, "icon": "💎"},
		{"id": "jackpot", "name": "豪赌", "cost": 10000, "icon": "👑"},
	],
	# Payout multipliers based on match count
	"payouts_3_match": {"min": 2.0, "max": 5.0},
	"payouts_4_match": {"min": 10.0, "max": 20.0},
	"payouts_5_match": {"min": 50.0, "max": 100.0},
}

# Furniture prizes that permanently boost rent income
const FURNITURE_PRIZES = {
	"chair": {"name": "椅子", "icon": "🪑", "rent_bonus": 0.02},
	"sofa": {"name": "沙发", "icon": "🛋️", "rent_bonus": 0.02},
	"bed": {"name": "床", "icon": "🛏️", "rent_bonus": 0.02},
	"plant": {"name": "盆栽", "icon": "🪴", "rent_bonus": 0.02},
	"lamp": {"name": "灯具", "icon": "💡", "rent_bonus": 0.02},
	"painting": {"name": "画框", "icon": "🖼️", "rent_bonus": 0.02},
	"curtain": {"name": "窗帘", "icon": "🪟", "rent_bonus": 0.02},
	"rug": {"name": "地毯", "icon": "🟫", "rent_bonus": 0.02},
	"clock": {"name": "挂钟", "icon": "🕐", "rent_bonus": 0.02},
	"vase": {"name": "花瓶", "icon": "🏺", "rent_bonus": 0.02},
}

# Complete set bonus
const FURNITURE_SET_BONUS = 0.10  # +10% for collecting all 10
const FURNITURE_MAX_PER_TYPE = 10  # Max copies of each furniture

const COIN_RAIN = {
	"id": "coin_rain",
	"name": "金币雨",
	"icon": "🌧️",
	"cooldown": 120.0,
	"duration": 15.0,
	"coin_spawn_rate": 4.0,
	"coin_value_multiplier": 0.1,
}

const FLEA_MARKET = {
	"id": "flea_market",
	"name": "跳蚤市场",
	"icon": "🏪",
	"cooldown": 300.0,
	"duration": 30.0,
}

const RENT_CHALLENGE = {
	"id": "rent_challenge",
	"name": "收租挑战",
	"icon": "🎯",
	"cooldown": 180.0,
	"duration": 20.0,
}

const ALL_MINIGAMES = [SLOT_MACHINE, COIN_RAIN, FLEA_MARKET, RENT_CHALLENGE]


static func get_minigame(id: String) -> Dictionary:
	for mg in ALL_MINIGAMES:
		if mg["id"] == id:
			return mg
	return {}


static func get_all_ids() -> Array[String]:
	var ids: Array[String] = []
	for mg in ALL_MINIGAMES:
		ids.append(mg["id"])
	return ids


static func get_furniture(id: String) -> Dictionary:
	return FURNITURE_PRIZES.get(id, {})


static func get_all_furniture_ids() -> Array[String]:
	var ids: Array[String] = []
	for key in FURNITURE_PRIZES:
		ids.append(key)
	return ids
