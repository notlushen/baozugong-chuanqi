extends VBoxContainer

const PROPERTY_CARD_SCENE = preload("res://scenes/ui/property_card.tscn")


func _ready() -> void:
	_build_cards()


func _build_cards() -> void:
	for property_id in Economy.get_property_ids():
		if Economy.is_property_unlocked(property_id):
			var card = PROPERTY_CARD_SCENE.instantiate()
			card.property_id = property_id
			add_child(card)
		else:
			var lock_label = Label.new()
			lock_label.text = "🔒 需要声望等级 1 解锁"
			lock_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			lock_label.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
			add_child(lock_label)


func refresh_all() -> void:
	for child in get_children():
		if child.has_method("update_display"):
			child.update_display()
