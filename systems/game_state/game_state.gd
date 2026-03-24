extends Node

var g_value: int = 0
var d_value: int = 0

signal g_changed(new_value: int)
signal d_changed(new_value: int)

func add_g(amount: int) -> void:
    g_value = clampi(g_value + amount, 0, 120)
    g_changed.emit(g_value)

func add_d(amount: int) -> void:
    d_value = clampi(d_value + amount, 0, 120)
    d_changed.emit(d_value)