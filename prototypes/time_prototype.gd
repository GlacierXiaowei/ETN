extends VBoxContainer

@onready var action_container: GridContainer = $GridContainer
@onready var skip_button: Button = $SkipButton
@onready var debug_check_box: CheckBox = $DebugCheckBox

func _ready() -> void:
	setup_action_buttons()
	TimeSystem.action_points_changed.connect(_on_action_points_changed)
	skip_button.pressed.connect(_on_skip_pressed)
	debug_check_box.button_pressed = GameSettings.debug_mode
	debug_check_box.toggled.connect(_on_debug_toggled)
	GameSettings.debug_mode_changed.connect(_on_debug_mode_changed)
	update_skip_button()

func setup_action_buttons() -> void:
	var actions: Array = TimeSystem.config.actions
	for child in action_container.get_children():
		child.queue_free()
	
	for action in actions:
		var btn = preload("res://systems/time_system/action_button.tscn").instantiate()
		btn.action_id = action.id
		btn.action_name = action.name
		btn.action_cost = action.cost
		btn.action_pressed.connect(_on_action_pressed)
		action_container.add_child(btn)

func _on_action_pressed(action_id: String) -> void:
	var action_type: String = get_action_type(action_id)
	
	if action_type == "scene":
		var success = TimeSystem.start_activity(action_id)
		if success:
			TimeSystem.mark_activity_started()
			TimeSystem.finish_activity()
		else:
			print("行动点不足！")
	else:
		var success = TimeSystem.execute_action(action_id)
		if not success:
			print("行动点不足！")

func get_action_type(action_id: String) -> String:
	var actions: Array = TimeSystem.config.actions
	for action in actions:
		if action.id == action_id:
			return action.get("type", "instant")
	return "instant"

func get_action_scene(action_id: String) -> String:
	var actions: Array = TimeSystem.config.actions
	for action in actions:
		if action.id == action_id:
			return action.get("scene", "")
	return ""

func _on_action_points_changed(_points: int) -> void:
	update_skip_button()

func update_skip_button() -> void:
	skip_button.visible = TimeSystem.action_points <= 0

func _on_skip_pressed() -> void:
	TimeSystem.advance_period()

func _on_debug_toggled(enabled: bool) -> void:
	GameSettings.set_debug_mode(enabled)

func _on_debug_mode_changed(enabled: bool) -> void:
	debug_check_box.button_pressed = enabled
