## Unit portrait in the side panel.
extends Control

const Sprites = preload("res://scripts/sprites.gd")

var unit = null


func _process(_delta: float) -> void:
	queue_redraw()


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Color("#0f1a4d"))
	draw_rect(Rect2(Vector2.ZERO, size), Color("#e8ecf7"), false, 2.0)
	if unit:
		Sprites.draw_unit(self, unit.cls, Vector2(size.x * 0.5, size.y * 0.86), size.y / 52.0, 1, 0.0, 1.0, Time.get_ticks_msec() / 1000.0)
