extends MarginContainer

@onready var day_label: Label = $VBoxContainer/HBoxContainer/day_label
@onready var weekday_label: Label = $VBoxContainer/HBoxContainer/weekday_label
@onready var period_label: Label = $VBoxContainer/HBoxContainer/period_label
@onready var points_label: Label = $VBoxContainer/HBoxContainer2/points_label
@onready var points_text: Label = $VBoxContainer/HBoxContainer2/points_text

func _ready() -> void:
    TimeSystem.period_changed.connect(_on_period_changed)
    TimeSystem.day_changed.connect(_on_day_changed)
    TimeSystem.action_points_changed.connect(_on_action_points_changed)
    update_display()

func update_display() -> void:
    day_label.text = "第" + str(TimeSystem.current_day) + "天"
    weekday_label.text = TimeSystem.get_weekday_name()
    period_label.text = TimeSystem.get_period_name()
    points_label.text = "行动点: "
    points_text.text = str(TimeSystem.action_points)

func _on_period_changed(_period: String, _is_weekend: bool) -> void:
    update_display()

func _on_day_changed(_day: int, _weekday: int) -> void:
    update_display()

func _on_action_points_changed(_points: int) -> void:
    points_text.text = str(_points)