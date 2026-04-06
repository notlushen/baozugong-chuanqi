extends Node

## Event Manager for idle game random event system.
## Handles scheduling and triggering of random events.

const EVENT_CONFIG = {
	"urge_rent": {"min_interval": 120.0, "max_interval": 300.0, "duration": 8.0, "reward_base": 10.0, "reward_max": 30.0},
	"repair": {"min_interval": 180.0, "max_interval": 480.0, "duration": 5.0, "reward_base": 5.0, "reward_max": 15.0},
}

var _event_timers: Dictionary = {}
var active_event: String = ""
var event_data: Dictionary = {}

signal event_triggered(event_type: String, data: Dictionary)
signal event_completed(event_type: String, reward: float)
signal event_dismissed(event_type: String)


func _ready() -> void:
	_schedule_all_events()


func _schedule_all_events() -> void:
	for event_type in EVENT_CONFIG.keys():
		_reschedule_event(event_type)


func _trigger_event(event_type: String) -> void:
	if active_event != "":
		_reschedule_event(event_type)
		return
	
	active_event = event_type
	var config = EVENT_CONFIG[event_type]
	event_data = {
		"duration": config["duration"],
		"reward_base": config["reward_base"],
		"reward_max": config["reward_max"],
	}
	event_triggered.emit(event_type, event_data)


func complete_event(reward: float) -> void:
	if active_event == "":
		return
	
	var event_type = active_event
	event_completed.emit(event_type, reward)
	active_event = ""
	event_data.clear()
	_reschedule_event(event_type)


func dismiss_event() -> void:
	if active_event == "":
		return
	
	var event_type = active_event
	event_dismissed.emit(event_type)
	active_event = ""
	event_data.clear()
	_reschedule_event(event_type)


func get_active_event_type() -> String:
	return active_event


func get_event_config(event_type: String) -> Dictionary:
	return EVENT_CONFIG.get(event_type, {})


func _reschedule_event(event_type: String) -> void:
	if _event_timers.has(event_type):
		var old_timer = _event_timers[event_type]
		if is_instance_valid(old_timer):
			old_timer.queue_free()
	
	var config = EVENT_CONFIG[event_type]
	var wait_time = randf_range(config["min_interval"], config["max_interval"])
	
	var timer = Timer.new()
	timer.wait_time = wait_time
	timer.one_shot = true
	timer.timeout.connect(_trigger_event.bind(event_type))
	add_child(timer)
	timer.start()
	
	_event_timers[event_type] = timer
