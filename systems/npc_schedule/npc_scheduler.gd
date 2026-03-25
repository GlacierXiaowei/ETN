extends Node

signal npc_state_changed(npc_id: String, location: String, state: String, visible: bool)

var _database: NPCScheduleDatabase
var _current_states: Dictionary = {}

var debug_mode: bool = false

func _ready() -> void:
	debug_mode = GameSettings.debug_mode
	GameSettings.debug_mode_changed.connect(_on_debug_mode_changed)
	_load_database()
	_connect_time_signals()
	_update_all_npc_states()

func _on_debug_mode_changed(enabled: bool) -> void:
	debug_mode = enabled

func _log(message: String) -> void:
	if debug_mode:
		print("[NPCScheduler] %s" % message)

func _load_database() -> void:
	var db_path = "res://data/npc_schedules.tres"
	if ResourceLoader.exists(db_path):
		_database = load(db_path)
		_database.build_index()
		_log("Database loaded, entries: %d, NPCs: %d" % [_database.entries.size(), _database.get_all_npc_ids().size()])
	else:
		_database = _create_test_database()
		_log("Database not found, created test database with %d entries" % _database.entries.size())

func _create_test_database() -> NPCScheduleDatabase:
	var db = NPCScheduleDatabase.new()
	
	var schedules = [
		# 肖迟日程
		{"npc_id": "xiao_chi", "chapter": 1, "chapter_stage": "", "day": 0, "period": "morning_class", "location": "classroom_302", "state": "sit", "visible": true},
		{"npc_id": "xiao_chi", "chapter": 1, "chapter_stage": "", "day": 0, "period": "break", "location": "classroom_302", "state": "stand", "visible": true},
		{"npc_id": "xiao_chi", "chapter": 1, "chapter_stage": "", "day": 0, "period": "lunch", "location": "canteen_1", "state": "stand", "visible": true},
		{"npc_id": "xiao_chi", "chapter": 1, "chapter_stage": "", "day": 0, "period": "after_school", "location": "playground", "state": "stand", "visible": true},
		{"npc_id": "xiao_chi", "chapter": 1, "chapter_stage": "", "day": 0, "period": "night", "location": "dorm_301", "state": "sit", "visible": true},
		# 何景明日程
		{"npc_id": "he_jingming", "chapter": 1, "chapter_stage": "", "day": 0, "period": "morning_class", "location": "classroom_302", "state": "sit", "visible": true},
		{"npc_id": "he_jingming", "chapter": 1, "chapter_stage": "", "day": 0, "period": "lunch", "location": "canteen_2", "state": "stand", "visible": true},
		{"npc_id": "he_jingming", "chapter": 1, "chapter_stage": "", "day": 0, "period": "after_school", "location": "club_room", "state": "stand", "visible": true},
		{"npc_id": "he_jingming", "chapter": 1, "chapter_stage": "", "day": 0, "period": "night", "location": "dorm_302", "state": "sit", "visible": true},
		# 林小婉日程
		{"npc_id": "lin_xiaowan", "chapter": 1, "chapter_stage": "", "day": 0, "period": "morning_class", "location": "classroom_302", "state": "sit", "visible": true},
		{"npc_id": "lin_xiaowan", "chapter": 1, "chapter_stage": "", "day": 0, "period": "lunch", "location": "library", "state": "sit", "visible": true},
		{"npc_id": "lin_xiaowan", "chapter": 1, "chapter_stage": "", "day": 0, "period": "after_school", "location": "classroom_302", "state": "sit", "visible": true},
		{"npc_id": "lin_xiaowan", "chapter": 1, "chapter_stage": "", "day": 0, "period": "night", "location": "dorm_303", "state": "sit", "visible": true},
		# 林小婉第3天请假
		{"npc_id": "lin_xiaowan", "chapter": 1, "chapter_stage": "", "day": 3, "period": "", "location": "", "state": "", "visible": false},
	]
	
	for data in schedules:
		var entry = NPCScheduleEntry.new()
		entry.npc_id = data["npc_id"]
		entry.chapter = data["chapter"]
		entry.chapter_stage = data["chapter_stage"]
		entry.day = data["day"]
		entry.period = data["period"]
		entry.location = data["location"]
		entry.state = data["state"]
		entry.visible = data["visible"]
		db.entries.append(entry)
	
	db.build_index()
	return db

func _connect_time_signals() -> void:
	TimeSystem.period_changed.connect(_on_period_changed)
	TimeSystem.day_changed.connect(_on_day_changed)

func get_npc_state(npc_id: String) -> Dictionary:
	return _current_states.get(npc_id, {})

func get_all_npc_states() -> Dictionary:
	return _current_states.duplicate()

func _on_period_changed(new_period: String, is_weekend: bool) -> void:
	_log("Period changed: %s" % new_period)
	_update_all_npc_states()

func _on_day_changed(new_day: int, new_weekday: int) -> void:
	_log("Day changed: %d" % new_day)
	_update_all_npc_states()

func _update_all_npc_states() -> void:
	if not _database:
		return
	
	for npc_id in _database.get_all_npc_ids():
		var entry = _database.get_entry(
			npc_id,
			GameState.chapter,
			GameState.chapter_stage,
			TimeSystem.current_day,
			TimeSystem.current_period
		)
		
		if entry:
			_current_states[npc_id] = {
				"location": entry.location,
				"state": entry.state,
				"visible": entry.visible
			}
			npc_state_changed.emit(npc_id, entry.location, entry.state, entry.visible)
			_log("NPC %s: location=%s, state=%s, visible=%s" % [npc_id, entry.location, entry.state, entry.visible])
		else:
			_current_states[npc_id] = {
				"location": "unknown",
				"state": "idle",
				"visible": false
			}
			npc_state_changed.emit(npc_id, "unknown", "idle", false)
			_log("NPC %s: no matching entry, hidden" % npc_id)
