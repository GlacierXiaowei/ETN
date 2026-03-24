extends Node

signal period_changed(new_period: String, is_weekend: bool)
signal day_changed(new_day: int, new_weekday: int)
signal action_points_changed(new_points: int)
signal action_points_depleted()
signal activity_started(activity_id: String)
signal activity_finished(activity_id: String)
signal activity_cancelled(activity_id: String, refunded: bool)

enum Weekday { MON, TUE, WED, THU, FRI, SAT, SUN }

var debug_mode: bool = false

var current_day: int = 1
var current_weekday: Weekday = Weekday.MON
var current_period: String = "morning_class"
var is_weekend: bool = false
var action_points: int = 0
var config: Dictionary = {}

var current_activity: String = ""
var activity_cost: int = 0
var is_activity_started: bool = false

var weekday_periods: Array[String] = ["morning_class", "break", "lunch", "after_school", "night"]
var weekend_periods: Array[String] = ["morning", "afternoon", "night"]

func _ready() -> void:
	debug_mode = GameSettings.debug_mode
	GameSettings.debug_mode_changed.connect(_on_debug_mode_changed)
	load_config()
	init_time()

func _on_debug_mode_changed(enabled: bool) -> void:
	debug_mode = enabled

func _log(message: String) -> void:
	if debug_mode:
		print("[TimeSystem] %s" % message)

func get_default_config() -> Dictionary:
	return {
		"periods": {
			"weekday": [
				{ "id": "morning_class", "name": "早读", "action_points": 0 },
				{ "id": "break", "name": "大课间", "action_points": 1 },
				{ "id": "lunch", "name": "午休", "action_points_random": [1, 2] },
				{ "id": "after_school", "name": "放学后", "action_points_random": [1, 2] },
				{ "id": "night", "name": "夜间", "action_points": 2 }
			],
			"weekend": [
				{ "id": "morning", "name": "上午", "action_points": 3 },
				{ "id": "afternoon", "name": "下午", "action_points": 3 },
				{ "id": "night", "name": "夜间", "action_points": 3 }
			]
		},
		"weekday_names": ["周一", "周二", "周三", "周四", "周五", "周六", "周日"],
		"actions": [
			{ "id": "idle", "name": "发呆", "cost": 1, "type": "instant" },
			{ "id": "rest", "name": "休息", "cost": 1, "type": "instant" },
			{ "id": "eat", "name": "吃饭", "cost": 0, "type": "instant" },
			{ "id": "library", "name": "去图书馆", "cost": 1, "type": "scene" },
			{ "id": "playground", "name": "去操场", "cost": 1, "type": "scene" },
			{ "id": "social", "name": "社交", "cost": 2, "type": "scene" }
		]
	}

func load_config() -> void:
	var file = FileAccess.open("res://data/time_config.json", FileAccess.READ)
	if file:
		var json = JSON.new()
		var error = json.parse(file.get_as_text())
		if error == OK:
			config = json.data
			_log("Config loaded successfully")
		else:
			_log("JSON parse error, using default config")
			config = get_default_config()
	else:
		_log("Config file not found, using default config")
		config = get_default_config()

func init_time() -> void:
	current_day = 1
	current_weekday = Weekday.MON
	is_weekend = false
	current_period = "morning_class"
	update_action_points()
	_log("Time initialized: day=1, weekday=MON, period=morning_class")

func get_period_name() -> String:
	var periods: Array = config.periods.weekday if not is_weekend else config.periods.weekend
	for p in periods:
		if p.id == current_period:
			return p.name
	return current_period

func get_weekday_name() -> String:
	return config.weekday_names[current_weekday]

func update_action_points() -> void:
	var periods: Array = config.periods.weekday if not is_weekend else config.periods.weekend
	for p in periods:
		if p.id == current_period:
			if p.has("action_points"):
				action_points = p.action_points
			elif p.has("action_points_random"):
				action_points = p.action_points_random[randi() % 2]
			break
	action_points_changed.emit(action_points)
	_log("Action points updated: %d" % action_points)

func execute_action(action_id: String) -> bool:
	_log("execute_action: '%s', points=%d" % [action_id, action_points])
	for action in config.actions:
		if action.id == action_id:
			if action_points >= action.cost:
				action_points -= action.cost
				_log("Action executed: %s, cost=%d, remaining=%d" % [action.name, action.cost, action_points])
				action_points_changed.emit(action_points)
				
				if action_points <= 0:
					_log("Action points depleted, advancing period")
					action_points_depleted.emit()
					advance_period()
				return true
			else:
				_log("Not enough points: %d < %d" % [action_points, action.cost])
				return false
	_log("Action not found: %s" % action_id)
	return false

func advance_period() -> void:
	var periods = weekday_periods if not is_weekend else weekend_periods
	var current_index = periods.find(current_period)
	
	if current_index < periods.size() - 1:
		current_period = periods[current_index + 1]
	else:
		advance_day()
		return
	
	update_action_points()
	period_changed.emit(current_period, is_weekend)
	_log("Period advanced to: %s" % current_period)

func advance_day() -> void:
	current_day += 1
	var new_weekday_int: int = (int(current_weekday) + 1) % 7
	current_weekday = new_weekday_int as Weekday
	
	if current_weekday >= Weekday.SAT:
		is_weekend = true
	else:
		is_weekend = false
	
	current_period = weekend_periods[0] if is_weekend else weekday_periods[0]
	
	day_changed.emit(current_day, current_weekday)
	update_action_points()
	period_changed.emit(current_period, is_weekend)
	_log("Day advanced: day=%d, weekday=%d, is_weekend=%s" % [current_day, current_weekday, is_weekend])

func start_activity(activity_id: String) -> bool:
	_log("start_activity: '%s', points=%d" % [activity_id, action_points])
	for action in config.actions:
		if action.id == activity_id:
			if action_points >= action.cost:
				current_activity = activity_id
				activity_cost = action.cost
				is_activity_started = false
				action_points -= activity_cost
				_log("Activity started: %s, cost=%d, remaining=%d" % [action.name, activity_cost, action_points])
				action_points_changed.emit(action_points)
				activity_started.emit(activity_id)
				return true
			else:
				_log("Not enough points for activity")
				return false
	_log("Activity not found: %s" % activity_id)
	return false

func mark_activity_started() -> void:
	if current_activity != "":
		is_activity_started = true
		_log("Activity marked as started: %s (no refund on cancel)" % current_activity)

func finish_activity() -> void:
	if current_activity == "":
		return
	_log("Activity finished: %s" % current_activity)
	activity_finished.emit(current_activity)
	current_activity = ""
	activity_cost = 0
	is_activity_started = false
	if action_points <= 0:
		_log("Action points depleted after activity, advancing period")
		action_points_depleted.emit()
		advance_period()

func cancel_activity() -> bool:
	if current_activity == "":
		_log("No activity to cancel")
		return false
	
	var refunded: bool = false
	if not is_activity_started:
		action_points += activity_cost
		action_points_changed.emit(action_points)
		refunded = true
		_log("Activity cancelled with refund: %s, refunded=%d" % [current_activity, activity_cost])
	else:
		_log("Activity cancelled without refund: %s (already started)" % current_activity)
	
	activity_cancelled.emit(current_activity, refunded)
	current_activity = ""
	activity_cost = 0
	is_activity_started = false
	return refunded

func is_in_activity() -> bool:
	return current_activity != ""

func can_refund_activity() -> bool:
	return current_activity != "" and not is_activity_started
