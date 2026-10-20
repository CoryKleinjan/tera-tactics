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
	if cls == "BOSS":
		s *= 1.12
	elif cls == "GOB" or cls == "GARC":
		s *= 0.92
	c.draw_set_transform(feet, 0.0, Vector2(s * face, s))
	match cls:
		"HERO": _hero()
		"KNT": _knight()
		"WARR": _warrior()
		"ACHR": _archer()
		"MAGE": _mage()
		"HEAL": _healer()
		"GOB": _goblin()
		"GARC": _goblin_archer()
		"DWF": _dwarf()
		"DMAG": _dark_mage()
		"BOSS": _boss()
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

static func _goblin_body(tunic: String) -> void:
	body(tunic, GOB, "#4b3a22", "#3d2b18", GOB, GOB)
	poly([[-4, -29], [-11, -32], [-5, -25]], GOB)
	poly([[3, -30], [8, -35], [5, -26]], GOB)
	rect(2.5, -27, 1.8, 1.8, "#ff3b30")

static func _goblin() -> void:
	_goblin_body("#7a5a36")
	line(7, -13, 13, -30, "#6b4a2a", 3.6)
	circ(13.5, -31, 3.4, "#5a3d22")
	circ(7, -14, 2.2, GOB)

static func _goblin_archer() -> void:
	_goblin_body("#5d4a7a")
	half(0, -28, 6, "#4a3a62")
	bow(GOB)

static func _dwarf() -> void:
	rect(-11, -18, 3, 8, "#4b4960")
	rect(-6, -7, 5, 7, "#33313f")
	rect(1, -7, 5, 7, "#33313f")
	rect(-9, -19, 18, 12, "#56546b")
	rect(-9, -10, 18, 2, "#2c2a36")
	circ(0, -23, 5.5, "#d9a07a")
	poly([[-5, -22], [6, -22], [3, -11], [-3, -11]], "#aeb0ba")
	half(0, -24, 6.2, "#33313f")
	rect(-6.2, -25, 12.4, 1.6, "#24222c")
	poly([[-1.5, -30], [1.5, -30], [0, -35]], "#8d93a0")
	rect(2, -23.5, 2, 1.6, "#ff4d3a")
	line(7, -6, 9, -30, "#4a3622", 2.4)
	poly([[9, -30], [16, -33], [16, -22], [9, -24]], "#8d93a0")
	circ(7.5, -12, 2.2, "#d9a07a")

static func _dark_mage() -> void:
	robe("#3e2566", "#8b5cf6", "#1b1230")
	half(0, -27.5, 7, "#2a1848")
	rect(-7, -28, 3.5, 8, "#2a1848")
	poly([[-4, -33], [4, -33], [-2, -39]], "#2a1848")
	rect(1, -27.5, 1.8, 1.4, "#86f0ff")
	rect(4, -27.5, 1.8, 1.4, "#86f0ff")
	line(8, -2, 9, -34, "#262130", 2.2)
	orb(9.5, -37, "#59d0ff")
	circ(8.5, -16, 2.2, "#1b1230")

static func _boss() -> void:
	poly([[-7, -24], [6, -24], [9, 0], [-14, 0]], "#8e1b1b")
	rect(-5, -10, 4, 9, "#24222f")
	rect(1, -10, 4, 9, "#24222f")
	rect(-6, -3, 5, 3, "#15141c")
	rect(1, -3, 6, 3, "#15141c")
	rect(-8, -23, 16, 14, "#34323f")
	rect(-2, -20, 4, 7, "#c62828")
	rect(-8, -12, 16, 2, "#1c1b24")
	circ(-8, -22, 4, "#4a4759")
	circ(8, -22, 4, "#4a4759")
	circ(0, -28, 6.4, "#34323f")
	rect(1, -28.5, 5, 1.6, "#ff4d3a")
	poly([[-5, -32], [-9, -41], [-3, -34]], "#ddd2bd")
	poly([[4, -33], [8, -42], [6, -32]], "#ddd2bd")
	line(7, -14, 19, -41, "#9aa3b5", 4)
	line(7, -14, 19, -41, "#dfe5ef", 1.2)
	line(3.5, -16, 10, -12.5, "#c9a227", 2.4)
	circ(6.5, -14.5, 2.4, "#4a4759")
