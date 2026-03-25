extends Control

@export var npc_id: String = ""
@export var npc_display_name: String = ""

@onready var _name_label: Label = $VBoxContainer/NameLabel
@onready var _location_label: Label = $VBoxContainer/LocationLabel
@onready var _state_label: Label = $VBoxContainer/StateLabel
@onready var _visible_label: Label = $VBoxContainer/VisibleLabel

func _ready() -> void:
	_name_label.text = "NPC: %s" % npc_display_name
	NPCScheduler.npc_state_changed.connect(_on_npc_state_changed)
	call_deferred("_update_display")

func _on_npc_state_changed(id: String, _location: String, _state: String, _visible: bool) -> void:
	if id == npc_id:
		_update_display()

func _update_display() -> void:
	var state_data = NPCScheduler.get_npc_state(npc_id)
	
	if state_data.is_empty():
		_location_label.text = "位置: 未知"
		_state_label.text = "状态: 未知"
		_visible_label.text = "可见: 否"
		return
	
	_location_label.text = "位置: %s" % state_data.get("location", "未知")
	_state_label.text = "状态: %s" % state_data.get("state", "未知")
	_visible_label.text = "可见: %s" % ("是" if state_data.get("visible", true) else "否")
	visible = state_data.get("visible", true)

func _on_detail_button_pressed() -> void:
	var state_data = NPCScheduler.get_npc_state(npc_id)
	var info = """[%s] 详细状态:
章节: %d
阶段: %s
天数: %d
时段: %s
位置: %s
状态: %s
可见: %s""" % [
		npc_display_name,
		GameState.chapter,
		GameState.chapter_stage if GameState.chapter_stage != "" else "(默认)",
		TimeSystem.current_day,
		TimeSystem.get_period_name(),
		state_data.get("location", "未知"),
		state_data.get("state", "未知"),
		"是" if state_data.get("visible", true) else "否"
	]
	print(info)
