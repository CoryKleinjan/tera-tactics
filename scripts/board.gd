## Draws everything on the map that changes: range overlays, cursor, units, effects.
extends Node2D

const D = preload("res://scripts/data.gd")
const Sprites = preload("res://scripts/sprites.gd")
const TS := D.TS

var game  # main.gd
var font: Font


func _ready() -> void:
	font = ThemeDB.fallback_font


func _process(delta: float) -> void:
	var i: int = game.parts.size() - 1
	while i >= 0:
		var p: Dictionary = game.parts[i]
		p.life += delta
		if p.life >= p.max:
			game.parts.remove_at(i)
		else:
			p.pos += p.vel * delta
			if p.kind == "fire":
				p.vel.y -= 48.0 * delta
		i -= 1
	queue_redraw()


func _cell(k: int, col: Color) -> void:
	draw_rect(Rect2(Vector2(k % D.COLS, k / D.COLS) * TS + Vector2.ONE, Vector2(TS - 2, TS - 2)), col)


func _center(k: int) -> Vector2:
	return Vector2(k % D.COLS, k / D.COLS) * TS + Vector2(TS, TS) * 0.5


func _draw() -> void:
	var t: float = game.now()
	var s := TS / 40.0
	var pulse := 0.5 + 0.5 * sin(t * 3.8)
	# Water glints
	for y in D.ROWS:
		for x in D.COLS:
			if D.MAP[y][x] == "w":
				var o := fmod(t * 11.0 + x * 13 + y * 7, TS)
				var wy := y * TS + 14 * s + sin(t * 2.0 + x) * 2
				draw_line(Vector2(x * TS + o * 0.8, wy), Vector2(x * TS + o * 0.8 + 8, wy), Color(1, 1, 1, 0.22), 1.4)
				var o2 := fmod(t * 8.0 + x * 29, TS)
				draw_line(Vector2(x * TS + o2 * 0.8, y * TS + 33 * s), Vector2(x * TS + o2 * 0.8 + 6, y * TS + 33 * s), Color(1, 1, 1, 0.22), 1.4)

	var mode: String = game.mode
	if mode == "move" and not game.reach_r.is_empty():
		for k in game.free_dest(game.reach_r, game.cur):
			_cell(k, Color(0.35, 0.69, 1.0, 0.26 + 0.14 * pulse))
		if game.cursor != null:
			var ck: int = game.key(game.cursor.x, game.cursor.y)
			var o = game.unit_at(game.cursor.x, game.cursor.y)
			if game.reach_r.dist.has(ck) and (o == null or o == game.cur):
				for k in game.path_to(game.reach_r, ck):
					draw_circle(_center(k), 3.0, Color(1, 1, 1, 0.85))
		for k in game.threat:
			_cell(k, Color(1.0, 0.55, 0.24, 0.22 + 0.1 * pulse))
	if mode == "target":
		for k in game.range_cells:
			_cell(k, Color(1.0, 0.35, 0.31, 0.14))
		for u in game.targets:
			_cell(game.key(u.x, u.y), Color(1.0, 0.31, 0.27, 0.35 + 0.2 * pulse))
		var area: int = game.action.get("area", 0)
		if area > 0 and game.t_idx < game.targets.size():
			var c = game.targets[game.t_idx]
			for y in D.ROWS:
				for x in D.COLS:
					if absi(x - c.x) + absi(y - c.y) <= area:
						_cell(game.key(x, y), Color(1.0, 0.75, 0.31, 0.28))
	if game.cursor != null and (mode == "move" or mode == "target"):
		var p := Vector2(game.cursor.x, game.cursor.y) * TS
		var a := 2.0 + pulse * 2.0
		var L := 11.0
		var col := Color("#fff7d6")
		for corner in [[Vector2(-a + 2, -a + 2), Vector2(1, 1)], [Vector2(TS + a - 2, -a + 2), Vector2(-1, 1)], [Vector2(-a + 2, TS + a - 2), Vector2(1, -1)], [Vector2(TS + a - 2, TS + a - 2), Vector2(-1, -1)]]:
			var q: Vector2 = p + corner[0]
			var dir: Vector2 = corner[1]
			draw_polyline(PackedVector2Array([q + Vector2(0, dir.y * L), q, q + Vector2(dir.x * L, 0)]), col, 3.0)

	# The tear, behind the units
	if game.tear_open > 0.01:
		var open: float = game.tear_open
		var tc := Vector2(D.TEAR) * TS + Vector2(TS * 0.5, TS * 0.6)
		var h := 34.0 * open
		for layer in [[16.0, Color(0.55, 0.35, 1.0, 0.28)], [8.0, Color(0.5, 0.95, 1.0, 0.55)], [2.6, Color(0.92, 1.0, 1.0, 0.95)]]:
			var w: float = layer[0] * open
			var pts := PackedVector2Array()
			for i in 17:
				var k := i / 16.0
				pts.append(tc + Vector2(w * sin(PI * k) * (1.0 + 0.18 * sin(t * 7.0 + i * 1.7)), -h + 2.0 * h * k))
			for i in range(15, 0, -1):
				var k := i / 16.0
				pts.append(tc + Vector2(-w * sin(PI * k) * (1.0 + 0.18 * sin(t * 6.0 + i * 2.3)), -h + 2.0 * h * k))
			draw_colored_polygon(pts, layer[1])

	# Units, back to front
	var list: Array = game.units.filter(func(u): return u.alive or u.alpha > 0.0)
	list.sort_custom(func(a, b): return a.py < b.py)
	for u in list:
		var bob := 0.0
		if game.cur == u and mode != "busy":
			bob = sin(t * 6.2) * 1.8
		else:
			bob = sin(t * 2.4 + u.id) * 0.6
		var sx := sin(t * 55.0) * 2.6 if u.shake_until > t else 0.0
		var feet := Vector2(u.px * TS + TS * 0.5 + u.ox + sx, u.py * TS + TS * 0.9 + u.oy)
		var ring := Color("#6cc3ff") if u.team == "p" else Color("#ff6e5e")
		ring.a = 0.9 * u.alpha
		_ellipse(feet, 15.6, 5.4, Color(0, 0, 0, 0.32 * u.alpha), true)
		_ellipse(feet, 15.6, 5.4, ring, false)
		Sprites.draw_unit(self, u.cls, feet + Vector2(0, bob), s, u.face, 0.85 if u.flash_until > t else 0.0, u.alpha, t)
		if u.alive:
			var w := 29.0
			var bp := Vector2(u.px * TS + (TS - w) * 0.5 + u.ox, u.py * TS + TS * 0.94 + u.oy)
			var r: float = float(u.hp) / u.mhp
			draw_rect(Rect2(bp - Vector2(0.5, 0.5), Vector2(w + 1, 4.6)), Color(0.04, 0.03, 0.12, 0.75))
			draw_rect(Rect2(bp, Vector2(w * r, 3.6)), Color("#5fdc77") if r > 0.5 else (Color("#f5cd55") if r > 0.25 else Color("#ff6e5e")))

	# Marker over the acting unit
	if game.cur != null and game.cur.alive and mode != "over" and mode != "intro":
		var u = game.cur
		var top := -14.0 - (5.0 if u.cls == "KNT" else (16.0 if u.cls == "BEAST" else 0.0))
		var m := Vector2(u.px * TS + TS * 0.5 + u.ox, u.py * TS + top + sin(t * 5.0) * 2.5)
		var tri := PackedVector2Array([m + Vector2(-6, -6), m + Vector2(6, -6), m + Vector2(0, 1)])
		draw_colored_polygon(tri, Color("#f5cd55"))
		draw_polyline(PackedVector2Array([tri[0], tri[1], tri[2], tri[0]]), Color("#120f26"), 1.2)

	# Effects
	var i: int = game.fx.size() - 1
	while i >= 0:
		var e: Dictionary = game.fx[i]
		var kk: float = (t - e.t0) / e.dur
		if kk >= 1.0:
			game.fx.remove_at(i)
		else:
			kk = maxf(kk, 0.0)
			if e.type == "arrow":
				var a: Vector2 = e.a
				var b: Vector2 = e.b
				var pos := a.lerp(b, kk) - Vector2(0, sin(kk * PI) * 16)
				var ang := (b - a).angle()
				var dirv := Vector2.from_angle(ang)
				draw_line(pos - dirv * 10, pos + dirv * 4, Color("#e9e2cf"), 2.0)
				draw_colored_polygon(PackedVector2Array([pos + dirv * 7, pos + dirv * 2 + dirv.orthogonal() * 3, pos + dirv * 2 - dirv.orthogonal() * 3]), Color("#dfe6ee"))
			elif e.type == "ring":
				var rc: Color = e.col
				rc.a = 1.0 - kk
				draw_arc(e.p, 7 + kk * 22, 0, TAU, 28, rc, 3.0, true)
		i -= 1
	for p in game.parts:
		var col: Color = p.col
		col.a = 1.0 - p.life / p.max
		var q: Vector2 = p.pos
		var z: float = p.size
		match p.kind:
			"heal", "level":
				draw_rect(Rect2(q.x - z / 2, q.y - 0.7, z, 1.4), col)
				draw_rect(Rect2(q.x - 0.7, q.y - z / 2, 1.4, z), col)
			"ice":
				draw_colored_polygon(PackedVector2Array([q + Vector2(0, -z), q + Vector2(z * 0.6, 0), q + Vector2(0, z), q + Vector2(-z * 0.6, 0)]), col)
			_:
				draw_circle(q, z, col)
	i = game.floats.size() - 1
	while i >= 0:
		var f: Dictionary = game.floats[i]
		var kk: float = (t - f.t0) / 0.95
		if kk >= 1.0:
			game.floats.remove_at(i)
		else:
			var col: Color = f.col
			col.a = 1.0 if kk < 0.75 else 1.0 - (kk - 0.75) / 0.25
			var pos := Vector2(f.x - 60, f.y - kk * 22)
			draw_string_outline(font, pos, f.text, HORIZONTAL_ALIGNMENT_CENTER, 120, 15, 5, Color(0.07, 0.06, 0.15, col.a))
			draw_string(font, pos, f.text, HORIZONTAL_ALIGNMENT_CENTER, 120, 15, col)
		i -= 1

	# Frame
	draw_rect(Rect2(Vector2(-3, -3), Vector2(D.COLS * TS + 6, D.ROWS * TS + 6)), Color("#e8ecf7"), false, 3.0)


func _ellipse(c: Vector2, rx: float, ry: float, col: Color, filled: bool) -> void:
	var pts := PackedVector2Array()
	for i in 24:
		var a := TAU * i / 24.0
		pts.append(c + Vector2(cos(a) * rx, sin(a) * ry))
	if filled:
		draw_colored_polygon(pts, col)
	else:
		pts.append(pts[0])
		draw_polyline(pts, col, 1.8, true)
