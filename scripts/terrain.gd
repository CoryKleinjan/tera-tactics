## Draws the battle map once. Redraws only if queue_redraw() is called.
extends Node2D

const D = preload("res://scripts/data.gd")
const TS := D.TS


func _draw() -> void:
	for y in D.ROWS:
		for x in D.COLS:
			_tile(x, y, D.MAP[y][x])
	var grid := Color(0, 0, 0, 0.13)
	for x in D.COLS + 1:
		draw_line(Vector2(x * TS, 0), Vector2(x * TS, D.ROWS * TS), grid, 1.0)
	for y in D.ROWS + 1:
		draw_line(Vector2(0, y * TS), Vector2(D.COLS * TS, y * TS), grid, 1.0)


func _wet(ch: String) -> bool:
	return ch == "w" or ch == "b" or ch == "s"


func _r(rng: RandomNumberGenerator) -> float:
	return rng.randf()


func _grass(o: Vector2, rng: RandomNumberGenerator, base: String) -> void:
	draw_rect(Rect2(o, Vector2(TS, TS)), Color(base))
	for i in 16:
		var p := o + Vector2(rng.randf() * TS, rng.randf() * TS)
		draw_rect(Rect2(p, Vector2(1.8, 3.6)), Color("#4d8834") if rng.randf() < 0.5 else Color("#73b54f"))


func _ell(cx: float, cy: float, rx: float, ry: float, col: Color, top_only := false) -> void:
	var pts := PackedVector2Array()
	var n := 18
	for i in n + 1 if top_only else n:
		var a := (PI + PI * i / float(n)) if top_only else (TAU * i / float(n))
		pts.append(Vector2(cx + cos(a) * rx, cy + sin(a) * ry))
	draw_colored_polygon(pts, col)


func _tile(x: int, y: int, ch: String) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = x * 7349 + y * 1931 + 17
	var o := Vector2(x * TS, y * TS)
	var s := TS / 40.0  # art was laid out on a 40px grid
	match ch:
		".":
			_grass(o, rng, "#5c9b3e")
		"r":
			draw_rect(Rect2(o, Vector2(TS, TS)), Color("#c9a66b"))
			for i in 10:
				draw_circle(o + Vector2(rng.randf() * TS, rng.randf() * TS), (0.8 + rng.randf() * 1.4) * s, Color("#b08e55") if rng.randf() < 0.5 else Color("#dcc08a"))
		"f":
			_grass(o, rng, "#4f8a35")
			for p in [Vector2(11, 15), Vector2(29, 13), Vector2(20, 30)]:
				var q: Vector2 = o + p * s
				_ell(q.x, q.y + 8 * s, 8 * s, 3 * s, Color(0, 0, 0, 0.25))
				draw_rect(Rect2(q + Vector2(-1.5, 2) * s, Vector2(3, 6) * s), Color("#5a3b1e"))
				draw_circle(q, 8.5 * s, Color("#2b6428"))
				draw_circle(q + Vector2(-2.5, -2.5) * s, 4.5 * s, Color("#3f8a37"))
		"h":
			_grass(o, rng, "#6b9a40")
			for h in [Vector3(13, 26, 12), Vector3(28, 20, 10)]:
				var q: Vector2 = o + Vector2(h.x, h.y) * s
				var r: float = h.z * s
				_ell(q.x, q.y, r, r * 0.7, Color("#7f9b45"), true)
				_ell(q.x - 2 * s, q.y - 1 * s, r * 0.55, r * 0.4, Color("#9cb85a"), true)
				draw_rect(Rect2(q.x - r, q.y, r * 2, 1.5 * s), Color("#5d7a33"))
		"w", "b", "s":
			draw_rect(Rect2(o, Vector2(TS, TS)), Color("#4f8fc0") if ch == "s" else Color("#2d68ad"))
			for i in 6:
				draw_rect(Rect2(o + Vector2(rng.randf() * TS, rng.randf() * TS), Vector2(7, 1.8)), Color("#5fa0cf") if ch == "s" else Color("#285f9e"))
			if y > 0 and not _wet(D.MAP[y - 1][x]):
				draw_rect(Rect2(o, Vector2(TS, 3.5)), Color("#3c6f2a"))
			if y < D.ROWS - 1 and not _wet(D.MAP[y + 1][x]):
				draw_rect(Rect2(o + Vector2(0, TS - 3.5), Vector2(TS, 3.5)), Color("#3c6f2a"))
			if ch == "s":
				for i in 5:
					_ell(o.x + (6 + rng.randf() * 28) * s, o.y + (8 + rng.randf() * 24) * s, (3 + rng.randf() * 2) * s, 2 * s, Color("#9aa3a8"))
			if ch == "b":
				draw_rect(Rect2(o + Vector2(6, 0) * s, Vector2(28 * s, TS)), Color("#9a6a3a"))
				var i := 0.0
				while i < TS:
					draw_rect(Rect2(o + Vector2(6 * s, i), Vector2(28 * s, 1.4)), Color("#6e4826"))
					i += 6 * s
				draw_rect(Rect2(o + Vector2(5, 0) * s, Vector2(3 * s, TS)), Color("#5a3a1e"))
				draw_rect(Rect2(o + Vector2(32, 0) * s, Vector2(3 * s, TS)), Color("#5a3a1e"))
		"m":
			_grass(o, rng, "#5d6e45")
			for tri in [[[3, 36], [15, 8], [27, 36], "#7b808d"], [[15, 8], [27, 36], [19, 36], "#626775"], [[15, 8], [11, 17], [18, 15], "#c9ced8"], [[18, 37], [29, 16], [39, 37], "#8a8f9c"], [[29, 16], [39, 37], [33, 37], "#6b707c"]]:
				var pts := PackedVector2Array()
				for j in 3:
					pts.append(o + Vector2(tri[j][0], tri[j][1]) * s)
				draw_colored_polygon(pts, Color(tri[3]))
