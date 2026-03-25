extends VBoxContainer

@onready var _npc_container: VBoxContainer = $NPCContainer
@onready var _day_label: Label = $TestControls/DayLabel
@onready var _chapter_label: Label = $TestControls/ChapterLabel

func _ready() -> void:
	_setup_npcs()
	_connect_signals()
	_update_labels()

func _setup_npcs() -> void:
	var npc_prototype = preload("res://systems/npc_schedule/npc_prototype.tscn")
	
	var npcs = [
		{"id": "xiao_chi", "name": "肖迟"},
		{"id": "he_jingming", "name": "何景明"},
		{"id": "lin_xiaowan", "name": "林小婉"}
	]
	
	for npc_data in npcs:
		var instance = npc_prototype.instantiate()
		instance.npc_id = npc_data["id"]
		instance.npc_display_name = npc_data["name"]
		_npc_container.add_child(instance)

func _connect_signals() -> void:
	TimeSystem.day_changed.connect(_on_day_changed)
	TimeSystem.period_changed.connect(_on_period_changed)

func _on_day_changed(_day: int, _weekday: int) -> void:
	_update_labels()

func _on_period_changed(_period: String, _is_weekend: bool) -> void:
	_update_labels()

func _update_labels() -> void:
	_day_label.text = "当前天数: %d" % TimeSystem.current_day
	_chapter_label.text = "章节: %d | 阶段: %s" % [GameState.chapter, GameState.chapter_stage if GameState.chapter_stage != "" else "(默认)"]

func _on_advance_period_pressed() -> void:
	TimeSystem.advance_period()

func _on_advance_day_pressed() -> void:
	TimeSystem.advance_day()

func _on_set_day_3_pressed() -> void:
	TimeSystem.current_day = 3
	TimeSystem.day_changed.emit(3, TimeSystem.current_weekday)

func _on_set_chapter_2_pressed() -> void:
	GameState.set_chapter(2)
