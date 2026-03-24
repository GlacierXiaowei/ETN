extends HBoxContainer

@export var npc_name: String = "小明"
var current_location: String = "教室"

@onready var name_label: Label = $name_label
@onready var location_label: Label = $location_label

func _ready() -> void:
    name_label.text = npc_name + ": "
    location_label.text = current_location
    TimeSystem.period_changed.connect(_on_period_changed)

func _on_period_changed(new_period: String, _is_weekend: bool) -> void:
    match new_period:
        "lunch":
            current_location = "食堂"
        "after_school":
            current_location = "操场"
        "night":
            current_location = "寝室"
        _:
            current_location = "教室"
    location_label.text = current_location