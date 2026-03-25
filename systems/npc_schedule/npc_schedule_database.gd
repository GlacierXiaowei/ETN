class_name NPCScheduleDatabase extends Resource

@export var entries: Array[NPCScheduleEntry] = []

var _index: Dictionary = {}
var _npc_ids: Array[String] = []

func build_index() -> void:
	_index.clear()
	_npc_ids.clear()
	
	for entry in entries:
		if entry.npc_id not in _npc_ids:
			_npc_ids.append(entry.npc_id)
		
		var key = _make_key(entry.chapter, entry.chapter_stage, entry.npc_id, entry.day, entry.period)
		_index[key] = entry

func _make_key(chapter: int, stage: String, npc_id: String, day: int, period: String) -> String:
	return "%d|%s|%s|%d|%s" % [chapter, stage, npc_id, day, period]

func get_entry(npc_id: String, chapter: int, stage: String, day: int, period: String) -> NPCScheduleEntry:
	var exact_key = _make_key(chapter, stage, npc_id, day, period)
	if _index.has(exact_key):
		return _index[exact_key]
	
	var patterns = [
		_make_key(chapter, stage, npc_id, day, ""),
		_make_key(chapter, stage, npc_id, 0, period),
		_make_key(chapter, stage, npc_id, 0, ""),
		_make_key(chapter, "", npc_id, day, period),
		_make_key(chapter, "", npc_id, day, ""),
		_make_key(chapter, "", npc_id, 0, period),
		_make_key(chapter, "", npc_id, 0, ""),
		_make_key(0, stage, npc_id, day, period),
		_make_key(0, stage, npc_id, day, ""),
		_make_key(0, stage, npc_id, 0, period),
		_make_key(0, stage, npc_id, 0, ""),
		_make_key(0, "", npc_id, day, period),
		_make_key(0, "", npc_id, day, ""),
		_make_key(0, "", npc_id, 0, period),
		_make_key(0, "", npc_id, 0, ""),
	]
	
	for pattern in patterns:
		if _index.has(pattern):
			return _index[pattern]
	
	return null

func get_all_npc_ids() -> Array[String]:
	return _npc_ids.duplicate()