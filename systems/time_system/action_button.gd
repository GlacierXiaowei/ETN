extends Button

@export var action_id: String = ""
@export var action_name: String = ""
@export var action_cost: int = 1

signal action_pressed(action_id: String)

func _ready() -> void:
	text = action_name + " (" + str(action_cost) + "点)"
	TimeSystem.action_points_changed.connect(_on_action_points_changed)
	pressed.connect(_on_pressed)
	update_state()

func _on_action_points_changed(_points: int) -> void:
	update_state()

func update_state() -> void:
	disabled = TimeSystem.action_points < action_cost

func _on_pressed() -> void:
	action_pressed.emit(action_id)