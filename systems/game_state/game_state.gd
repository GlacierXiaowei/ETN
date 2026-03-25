extends Node

var g_value: int = 0
var d_value: int = 0

var chapter: int = 1
var chapter_stage: String = ""

signal g_changed(new_value: int)
signal d_changed(new_value: int)
signal chapter_changed(new_chapter: int)
signal chapter_stage_changed(new_stage: String)

func add_g(amount: int) -> void:
	g_value = clampi(g_value + amount, 0, 120)
	g_changed.emit(g_value)

func add_d(amount: int) -> void:
	d_value = clampi(d_value + amount, 0, 120)
	d_changed.emit(d_value)

func set_chapter(new_chapter: int) -> void:
	chapter = new_chapter
	chapter_changed.emit(chapter)

func set_chapter_stage(new_stage: String) -> void:
	chapter_stage = new_stage
	chapter_stage_changed.emit(chapter_stage)