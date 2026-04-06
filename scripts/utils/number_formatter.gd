class_name NumberFormatter
extends RefCounted

const SUFFIXES = ["", "K", "M", "B", "T", "Qa", "Qi", "Sx", "Sp", "Oc", "No", "Dc"]


static func format_number(value: float) -> String:
	var sign_char = "-" if value < 0 else ""
	var abs_value = abs(value)
	var base = 1000.0
	if abs_value < base:
		return sign_char + str(int(abs_value))
	var tier = int(floor(log(abs_value) / log(base)))
	var max_tier = SUFFIXES.size() - 1
	if tier > max_tier:
		tier = max_tier
	var scaled = abs_value / pow(base, tier)
	var decimals = 1 if scaled >= 100.0 else 2
	var fmt = "%." + str(decimals) + "f"
	var scaled_str = fmt % scaled
	return sign_char + scaled_str + SUFFIXES[tier]


static func format_money(value: float) -> String:
	return "💰 " + format_number(value)


static func format_income(value: float) -> String:
	var sign_char = "+" if value >= 0 else "-"
	var abs_val = abs(value)
	var formatted = format_number(abs_val)
	return sign_char + formatted + "/秒"


func _ready() -> void:
	# Self-test outputs
	print(format_number(520))
	print(format_number(1500))
	print(format_number(1500000))
	print(format_number(2800000000))
