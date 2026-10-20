## Procedural unit sprites. Every sprite is drawn around its feet at (0, 0), facing right,
## in a 40px-tile coordinate space; draw_unit() scales and flips it.
extends RefCounted

static var c: CanvasItem
static var flash := 0.0
static var alpha := 1.0
static var t := 0.0

const SKIN := "#f2c79e"
const GOB := "#7dbb4a"
const EYE := "#1d1a2e"


static func draw_unit(canvas: CanvasItem, cls: String, feet: Vector2, scale: float, face: int, flash_v: float, alpha_v: float, time: float) -> void:
	c = canvas
	flash = flash_v
	alpha = alpha_v
	t = time
	var s := scale
	if cls == "BEAST":
		s *= 0.82
	elif cls == "TEARLING" or cls == "TEARARC":
		s *= 0.92
	c.draw_set_transform(feet, 0.0, Vector2(s * face, s))
	match cls:
		"HERO": _hero()
		"KNT": _knight()
		"WARR": _warrior()
		"ACHR": _archer()
		"MAGE": _mage()
		"HEAL": _healer()
		"TEARLING": _tearling()
		"TEARARC": _tearling_archer()
		"BRUTE": _brute()
		"SEER": _seer()
		"BEAST": _beast()
	c.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


# ---------- primitives ----------
static func k(hex: String) -> Color:
	var col := Color(hex).lerp(Color.WHITE, flash)
	col.a *= alpha
	return col

static func rect(x: float, y: float, w: float, h: float, hex: String) -> void:
	c.draw_rect(Rect2(x, y, w, h), k(hex))

static func circ(x: float, y: float, r: float, hex: String) -> void:
	c.draw_circle(Vector2(x, y), r, k(hex))

static func ell(x: float, y: float, rx: float, ry: float, hex: String) -> void:
	var pts := PackedVector2Array()
	for i in 20:
		var a := TAU * i / 20.0
		pts.append(Vector2(x + cos(a) * rx, y + sin(a) * ry))
	c.draw_colored_polygon(pts, k(hex))

## Top half of a circle (a helmet or hood).
static func half(x: float, y: float, r: float, hex: String) -> void:
	var pts := PackedVector2Array()
	for i in 13:
		var a := PI + PI * i / 12.0
		pts.append(Vector2(x + cos(a) * r, y + sin(a) * r))
	c.draw_colored_polygon(pts, k(hex))

static func line(x1: float, y1: float, x2: float, y2: float, hex: String, w: float) -> void:
	c.draw_line(Vector2(x1, y1), Vector2(x2, y2), k(hex), w, true)

static func poly(pts: Array, hex: String) -> void:
	var p := PackedVector2Array()
	for q in pts:
		p.append(Vector2(q[0], q[1]))
	c.draw_colored_polygon(p, k(hex))

static func orb(x: float, y: float, hex: String) -> void:
	var gl := 0.55 + 0.45 * sin(t * 5.0)
	var halo := k(hex)
	halo.a *= gl * 0.45
	c.draw_circle(Vector2(x, y), 5.5, halo)
	circ(x, y, 3, hex)
	circ(x - 1, y - 1, 1, "#ffffff")

static func bow(hand: String) -> void:
	c.draw_arc(Vector2(4, -19), 11, -1.15, 1.15, 12, k("#8b5a2b"), 2.2, true)
	line(4 + 11 * cos(-1.15), -19 + 11 * sin(-1.15), 4 + 11 * cos(1.15), -19 + 11 * sin(1.15), "#ece6d4", 0.8)
	circ(13, -19, 2.2, hand)

static func body(tunic: String, legs: String, boots: String, belt := "", skin := SKIN, sleeve := "") -> void:
	rect(-9, -21, 3, 9, sleeve if sleeve != "" else tunic)
	rect(-5, -10, 4, 9, legs)
	rect(1, -10, 4, 9, legs)
	rect(-6, -3, 5, 3, boots)
	rect(1, -3, 6, 3, boots)
	rect(-7, -22, 14, 13, tunic)
	if belt != "":
		rect(-7, -12, 14, 2, belt)
	circ(0, -27, 5.5, skin)
	rect(2.5, -27, 1.6, 2, EYE)

static func robe(col: String, trim: String, skin := SKIN) -> void:
	rect(-9, -21, 3, 9, col)
	poly([[-6, -22], [6, -22], [9, 0], [-9, 0]], col)
	rect(-9, -2, 18, 2, trim)
	circ(0, -27, 5.5, skin)
	rect(2.5, -27, 1.6, 2, EYE)


# ---------- classes ----------
static func _hero() -> void:
	body("#3466d6", "#2b3050", "#6b4423", "#c9a227")
	rect(-7, -22, 14, 2.5, "#5b86ea")
	half(0, -28, 6, "#7a4a1f")
	poly([[-6, -28], [-3, -28], [-6, -23]], "#7a4a1f")
	rect(-6, -29.5, 12, 1.8, "#e53935")
	line(-6, -28.5, -11, -25, "#e53935", 1.6)
	line(6, -15, 15, -35, "#e6edf5", 2.6)
	line(3.5, -16.5, 8.5, -13.5, "#f5cd55", 2.2)
	circ(6, -15, 2.2, SKIN)

static func _knight() -> void:
	line(-12, -15, -17, -6, "#3b2412", 3)
	rect(-10, -10, 3, 10, "#6d4320")
	rect(-5, -10, 3, 10, "#5e3a1c")
	rect(4, -10, 3, 10, "#6d4320")
	rect(9, -10, 3, 10, "#5e3a1c")
	ell(0, -13, 13, 6.5, "#8d5a2b")
	poly([[7, -17], [13, -29], [18, -27], [14, -13]], "#8d5a2b")
	ell(18, -27, 5, 3.2, "#8d5a2b")
	poly([[8, -18], [12, -29], [14, -29], [10, -18]], "#3b2412")
	rect(19, -28.5, 1.5, 1.5, "#111111")
	rect(-5, -19, 11, 6, "#2f63c9")
	rect(-5, -14, 11, 1.5, "#f5cd55")
	rect(-4, -31, 9, 12, "#a9bccf")
	circ(1, -35, 4.8, SKIN)
	half(1, -35, 5.4, "#c7d3df")
	rect(-4.4, -35.5, 10.8, 1.6, "#c7d3df")
	line(0, -40, -4, -44, "#e53935", 2)
	rect(3.5, -34.5, 1.5, 1.8, EYE)
	line(-8, -20, 22, -42, "#cfd5dc", 2.2)
	poly([[25, -44], [19, -41.5], [22.5, -38]], "#eef2f6")
	circ(4, -26, 2, SKIN)

static func _warrior() -> void:
	body("#8a5a2c", "#4a3a2a", "#3a2a1a", "#2e1f12", SKIN, "#a06b38")
	circ(1, -23, 3.8, "#c76b29")
	half(0, -28, 6.2, "#9aa1aa")
	rect(-6.2, -29, 12.4, 1.6, "#7d848e")
	poly([[-6, -30], [-10, -37], [-4, -32]], "#efe6d2")
	poly([[6, -30], [10, -37], [4, -32]], "#efe6d2")
	line(7, -11, 9, -35, "#6d4c2b", 2.4)
	poly([[9, -35], [16, -38], [17, -27], [9, -29]], "#d3dae2")
	circ(7.5, -15, 2.2, SKIN)

static func _archer() -> void:
	rect(-11, -27, 4, 11, "#6d4c2b")
	line(-10, -27, -8, -31, "#ece6d4", 1.5)
	body("#3f8f4a", "#5b4a2e", "#4a3520", "#6d4c2b")
	half(0, -27.5, 6.5, "#2e6b37")
	rect(-6.5, -28, 3, 6, "#2e6b37")
	bow(SKIN)

static func _mage() -> void:
	robe("#c8452f", "#f5cd55")
	ell(0, -30, 9, 2.4, "#8e2a1d")
	poly([[-6, -30], [6, -30], [1, -45]], "#8e2a1d")
	rect(-5.5, -32, 11, 1.6, "#f5cd55")
	line(8, -2, 10, -34, "#7a5230", 2.2)
	orb(10.5, -37, "#ffd54f")
	circ(8.5, -16, 2.2, SKIN)

static func _healer() -> void:
	robe("#ebe7da", "#4a7bd0")
	rect(-1, -22, 2, 20, "#4a7bd0")
	half(0, -27.5, 6.6, "#cfc9b8")
	rect(-6.6, -28, 3, 7, "#cfc9b8")
	line(8, -2, 9, -33, "#c9a227", 2)
	c.draw_arc(Vector2(9, -36.5), 3.2, 0, TAU, 16, k("#f5cd55"), 1.8, true)
	circ(8.5, -16, 2.2, SKIN)

const TEAR_SKIN := "#4a3f70"
const TEAR_GLOW := "#7ff3ff"


static func _tearling_body(tunic: String) -> void:
	body(tunic, TEAR_SKIN, "#1b1630", "#14102a", TEAR_SKIN, TEAR_SKIN)
	poly([[-4, -29], [-11, -33], [-5, -25]], TEAR_SKIN)
	poly([[3, -30], [8, -36], [5, -26]], TEAR_SKIN)
	rect(2.5, -27, 1.8, 1.8, TEAR_GLOW)
	line(-3, -19, 2, -14, TEAR_GLOW, 0.9)

static func _tearling() -> void:
	_tearling_body("#241d3a")
	poly([[6, -14], [16, -30], [13, -31], [5, -16]], "#8d93a0")
	circ(7, -14, 2.2, TEAR_SKIN)

static func _tearling_archer() -> void:
	_tearling_body("#2e2448")
	half(0, -28, 6, "#1b1630")
	bow(TEAR_SKIN)

static func _brute() -> void:
	rect(-11, -18, 3, 8, "#4b4960")
	rect(-6, -7, 5, 7, "#33313f")
	rect(1, -7, 5, 7, "#33313f")
	rect(-9, -19, 18, 12, "#5b5a6e")
	line(-6, -17, -1, -11, TEAR_GLOW, 1.0)
	line(-1, -11, 4, -16, TEAR_GLOW, 1.0)
	rect(-9, -10, 18, 2, "#2c2a36")
	circ(0, -23, 5.8, "#6b6a80")
	half(0, -24, 6.4, "#3a3850")
	poly([[-4, -29], [-8, -36], [-2, -30]], "#ddd2bd")
	poly([[3, -30], [6, -37], [5, -29]], "#ddd2bd")
	rect(1.5, -23.5, 2.5, 1.8, TEAR_GLOW)
	line(7, -6, 9, -30, "#3a2c20", 2.6)
	poly([[9, -30], [17, -26], [9, -21]], "#555a66")
	circ(7.5, -12, 2.4, "#6b6a80")

static func _seer() -> void:
	robe("#3e2566", "#8b5cf6", "#1b1230")
	half(0, -27.5, 7, "#2a1848")
	rect(-7, -28, 3.5, 8, "#2a1848")
	poly([[-4, -33], [4, -33], [-2, -39]], "#2a1848")
	rect(1, -27.5, 1.8, 1.4, TEAR_GLOW)
	rect(4, -27.5, 1.8, 1.4, TEAR_GLOW)
	line(8, -2, 9, -34, "#262130", 2.2)
	orb(9.5, -37, "#59d0ff")
	circ(8.5, -16, 2.2, "#1b1230")

## The giant beast from the tear. Roughly two tiles wide.
static func _beast() -> void:
	line(-22, -22, -32, -34, "#2b2540", 4.5)
	circ(-32, -35, 2.5, "#b388ff")
	rect(-19, -15, 6, 15, "#2b2540")
	rect(-10, -15, 6, 15, "#3a3256")
	rect(8, -15, 6, 15, "#2b2540")
	rect(17, -15, 6, 15, "#3a3256")
	for fx in [-19.0, -10.0, 8.0, 17.0]:
		rect(fx - 0.5, -2, 7, 2, "#ddd2bd")
	ell(0, -23, 25, 12, "#3a3256")
	ell(-3, -28, 18, 6, "#4a4170")
	line(-14, -29, -5, -20, TEAR_GLOW, 1.6)
	line(-5, -20, 2, -28, TEAR_GLOW, 1.6)
	line(7, -18, 13, -25, "#b388ff", 1.6)
	poly([[14, -31], [24, -42], [33, -35], [22, -21]], "#3a3256")
	ell(31, -37, 9, 6.5, "#3a3256")
	poly([[35, -36], [44, -33], [35, -30]], "#2b2540")
	poly([[37, -32], [39, -28.5], [40.5, -32]], "#ffffff")
	poly([[41, -32], [42.5, -29], [43.5, -32]], "#ffffff")
	poly([[26, -42], [20, -55], [29, -44]], "#ddd2bd")
	poly([[31, -43], [34, -56], [35, -42]], "#ddd2bd")
	rect(33, -39.5, 3.5, 2.2, TEAR_GLOW)
