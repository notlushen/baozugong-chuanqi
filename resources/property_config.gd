class_name PropertyConfig
extends Object

const PROPERTIES = {
	"apartment": {"name": "单间公寓", "base_cost": 100, "base_rent": 5.0, "cost_growth": 1.15, "rent_growth": 0.08, "icon": "🏠", "prestige_req": 0},
	"two_bedroom": {"name": "两居室", "base_cost": 1100, "base_rent": 28.0, "cost_growth": 1.15, "rent_growth": 0.08, "icon": "🏢", "prestige_req": 0},
	"townhouse": {"name": "联排别墅", "base_cost": 12000, "base_rent": 140.0, "cost_growth": 1.15, "rent_growth": 0.08, "icon": "🏘️", "prestige_req": 0},
	"shop": {"name": "商业商铺", "base_cost": 130000, "base_rent": 780.0, "cost_growth": 1.15, "rent_growth": 0.08, "icon": "🏬", "prestige_req": 0},
	"office": {"name": "写字楼", "base_cost": 1400000, "base_rent": 4200.0, "cost_growth": 1.15, "rent_growth": 0.08, "icon": "🏗️", "prestige_req": 0},
	"hotel": {"name": "豪华酒店", "base_cost": 20000000, "base_rent": 26000.0, "cost_growth": 1.15, "rent_growth": 0.08, "icon": "🏰", "prestige_req": 0},
	"skyscraper": {"name": "摩天大楼", "base_cost": 330000000, "base_rent": 150000.0, "cost_growth": 1.15, "rent_growth": 0.08, "icon": "🌆", "prestige_req": 1}
}


static func get_property(property_id: String) -> Dictionary:
	return PROPERTIES.get(property_id, {})


static func get_all_ids() -> Array[String]:
	var ids: Array[String] = []
	for key in PROPERTIES:
		ids.append(key)
	return ids


static func is_unlocked(property_id: String, prestige_level: int) -> bool:
	var data = get_property(property_id)
	if data.is_empty():
		return false
	var req = data.get("prestige_req", 0)
	return prestige_level >= req
