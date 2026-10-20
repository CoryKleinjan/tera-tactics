## Battle controller: turn order, player input, combat rules, enemy AI and EXP.
extends Node2D

const D = preload("res://scripts/data.gd")
const UnitScript = preload("res://scripts/unit.gd")
const Terrain = preload("res://scripts/terrain.gd")
const Board = preload("res://scripts/board.gd")
const Hud = preload("res://scripts/hud.gd")

const TS := D.TS
const COLS := D.COLS
const ROWS := D.ROWS
const DIRS := [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]
const BOARD_POS := Vector2(24, 84)

signal turn_done
signal msg_closed

var units: Array = []
var mode := "intro"  # intro | busy | move | menu | list | target | over
var cur = null
var reach_r: Dictionary = {}
var orig := Vector2i.ZERO
var cursor = null
var targets: Array = []
var t_idx := 0
var action: Dictionary = {}
var inspect = null
var threat: Dictionary = {}
var hover = null
var tile_hover = null
var order: Array = []
var round_n := 0
var range_cells: Dictionary = {}
var pending: Dictionary = {}
var fx: Array = []
var parts: Array = []
var floats: Array = []
var msg_speed := 1.0
var autoplay := false

var msg_text := ""
var msg_i := 0.0
var msg_typing := false
var msg_hold := 0.0
var msg_active := false
var ui_timer := 0.0

var board
var hud


func _ready() -> void:
	randomize()
	var terrain = Terrain.new()
	terrain.position = BOARD_POS
	add_child(terrain)
	board = Board.new()
	board.position = BOARD_POS
	board.game = self
	add_child(board)
	var layer := CanvasLayer.new()
	add_child(layer)
	hud = Hud.new()
	layer.add_child(hud)
	hud.cmd.connect(do_cmd)
	hud.cancel.connect(func(): if mode == "target": cancel_target())
	hud.speed.connect(_toggle_speed)
	hud.start.connect(_on_start)
	setup()
	hud.show_intro()
	hud.set_hint("Read the briefing, then begin the battle.")
	autoplay = "--autoplay" in OS.get_cmdline_user_args()
	if "--screens" in OS.get_cmdline_user_args():
		_screens.call_deferred()
	if autoplay:
		msg_speed = 0.02
		get_tree().create_timer(600.0).timeout.connect(func(): print("AUTOPLAY TIMEOUT"); get_tree().quit(1))
		_on_start.call_deferred()


func setup() -> void:
	units.clear()
	var i := 0
	for d in D.PARTY:
		units.append(UnitScript.from_dict(d, "p", i))
		i += 1
	for d in D.ENEMIES:
		units.append(UnitScript.from_dict(d, "e", i))
		i += 1
	mode = "intro"
	cur = null
	round_n = 0
	order = []
	fx.clear()
	parts.clear()
	floats.clear()
	pending.clear()


func now() -> float:
	return Time.get_ticks_msec() / 1000.0


func wait(sec: float) -> void:
	await get_tree().create_timer(sec).timeout


# ---------- grid helpers ----------
func key(x: int, y: int) -> int:
	return y * COLS + x

func kx(k: int) -> int:
	return k % COLS

func ky(k: int) -> int:
	return k / COLS

func in_b(x: int, y: int) -> bool:
	return x >= 0 and y >= 0 and x < COLS and y < ROWS

func ter(x: int, y: int) -> Dictionary:
	return D.TER[D.MAP[y][x]]

func cls_of(u) -> Dictionary:
	return D.CLASSES[u.cls]

func mdist(a, b) -> int:
	return absi(a.x - b.x) + absi(a.y - b.y)

func land_of(u) -> float:
	return ter(u.x, u.y).land / 100.0

func unit_at(x: int, y: int):
	for u in units:
		if u.alive and u.x == x and u.y == y:
			return u
	return null

func in_r(a, t, r: Array) -> bool:
	var d := mdist(a, t)
	return d >= r[0] and d <= r[1]

func foes_in_range(u, r: Array) -> Array:
	return units.filter(func(t): return t.alive and t.team != u.team and in_r(u, t, r))

func hurt_allies_in_range(u, r: Array) -> Array:
	return units.filter(func(t): return t.alive and t.team == u.team and t.hp < t.mhp and in_r(u, t, r))

func spell_targets(u, sid: String) -> Array:
	var sp: Dictionary = D.SPELLS[sid]
	return hurt_allies_in_range(u, sp.range) if sp.kind == "heal" else foes_in_range(u, sp.range)


# ---------- pathing ----------
## Dijkstra over move costs. Allies can be passed through, enemies block.
func reach(u, budget := -1) -> Dictionary:
	if budget < 0:
		budget = u.mov
	var mt: String = cls_of(u).mt
	var dist := {}
	var prev := {}
	var start := key(u.x, u.y)
	dist[start] = 0
	var q := [[0, u.x, u.y]]
	while q.size() > 0:
		q.sort_custom(func(a, b): return a[0] < b[0])
		var it: Array = q.pop_front()
		var d: int = it[0]
		var x: int = it[1]
		var y: int = it[2]
		if d > dist[key(x, y)]:
			continue
		for dir in DIRS:
			var nx: int = x + dir.x
			var ny: int = y + dir.y
			if not in_b(nx, ny):
				continue
			var c: int = ter(nx, ny).cost.get(mt, 0)
			if c == 0:
				continue
			var o = unit_at(nx, ny)
			if o != null and o.team != u.team:
				continue
			var nd := d + c
			if nd > budget:
				continue
			var k := key(nx, ny)
			if dist.has(k) and dist[k] <= nd:
				continue
			dist[k] = nd
			prev[k] = key(x, y)
			q.append([nd, nx, ny])
	return {"dist": dist, "prev": prev, "start": start}


func path_to(r: Dictionary, k: int) -> Array:
	var p := []
	var c = k
	while c != r.start and c != null:
		p.append(c)
		c = r.prev.get(c)
	p.reverse()
	return p


func free_dest(r: Dictionary, u) -> Array:
	var out := []
	for k in r.dist.keys():
		var o = unit_at(kx(k), ky(k))
		if o == null or o == u:
			out.append(k)
	return out


## Travel cost from every tile to the nearest foe of u, ignoring units.
func dist_field(u) -> Dictionary:
	var mt: String = cls_of(u).mt
	var f := {}
	var q := []
	for p in units:
		if p.alive and p.team != u.team:
			f[key(p.x, p.y)] = 0
			q.append([0, p.x, p.y])
	while q.size() > 0:
		q.sort_custom(func(a, b): return a[0] < b[0])
		var it: Array = q.pop_front()
		var d: int = it[0]
		var x: int = it[1]
		var y: int = it[2]
		if d > f[key(x, y)]:
			continue
		for dir in DIRS:
			var nx: int = x + dir.x
			var ny: int = y + dir.y
			if not in_b(nx, ny):
				continue
			var c: int = ter(nx, ny).cost.get(mt, 0)
			if c == 0:
				continue
			var k := key(nx, ny)
			if not f.has(k) or f[k] > d + c:
				f[k] = d + c
				q.append([d + c, nx, ny])
	return f


func cells_in_range(u, r: Array) -> Dictionary:
	var s := {}
	for y in ROWS:
		for x in COLS:
			var d := absi(x - u.x) + absi(y - u.y)
			if d >= r[0] and d <= r[1]:
				s[key(x, y)] = true
	return s


func threat_of(e) -> Dictionary:
	var r := reach(e)
	var s := {}
	var rr: Array = cls_of(e).range.duplicate()
	for sid in e.spells:
		var sp: Dictionary = D.SPELLS[sid]
		if sp.kind != "heal":
			rr = [mini(rr[0], sp.range[0]), maxi(rr[1], sp.range[1])]
	for k in free_dest(r, e):
		var x := kx(k)
		var y := ky(k)
		s[k] = true
		for dy in range(-rr[1], rr[1] + 1):
			for dx in range(-rr[1], rr[1] + 1):
				var d := absi(dx) + absi(dy)
				if d < maxi(1, rr[0]) or d > rr[1]:
					continue
				if in_b(x + dx, y + dy):
					s[key(x + dx, y + dy)] = true
	return s


# ---------- messages ----------
func say(text: String, hold := 0.6) -> void:
	msg_text = text
	msg_i = 0.0
	msg_typing = true
	msg_hold = hold * msg_speed
	msg_active = true
	hud.show_msg(cur != null and cur.y >= ROWS / 2.0)
	await msg_closed


func _msg_finish() -> void:
	msg_typing = false
	hud.set_msg(msg_text)


func _msg_close() -> void:
	msg_active = false
	msg_closed.emit()


func msg_skip() -> void:
	if msg_typing:
		_msg_finish()
	else:
		_msg_close()


func _process(delta: float) -> void:
	if msg_active:
		if msg_typing:
			msg_i += delta * 60.0 * (4.0 if msg_speed < 1.0 else 1.0)
			var n := int(msg_i)
			hud.set_msg(msg_text.substr(0, n))
			if n >= msg_text.length():
				_msg_finish()
		else:
			msg_hold -= delta
			if msg_hold <= 0.0:
				_msg_close()
	ui_timer -= delta
	if ui_timer <= 0.0:
		ui_timer = 0.14
		_update_ui()


func _toggle_speed() -> void:
	msg_speed = 0.35 if msg_speed == 1.0 else 1.0
	hud.speed_btn.text = "Text speed: %s" % ("Normal" if msg_speed == 1.0 else "Fast")


# ---------- animation ----------
func move_along(u, path: Array) -> void:
	for k in path:
		var nx := kx(k)
		var ny := ky(k)
		if nx != roundi(u.px):
			u.face = 1 if nx > u.px else -1
		var tw := create_tween()
		tw.tween_property(u, "px", float(nx), 0.085)
		tw.parallel().tween_property(u, "py", float(ny), 0.085)
		await tw.finished
	if path.size() > 0:
		u.x = kx(path[-1])
		u.y = ky(path[-1])
	u.px = u.x
	u.py = u.y


func face(a, t) -> void:
	if t.x != a.x:
		a.face = 1 if t.x > a.x else -1


func lunge(a, t) -> void:
	var d := Vector2(signi(t.x - a.x), signi(t.y - a.y)) * 11.0
	var tw := create_tween()
	tw.tween_property(a, "ox", d.x, 0.11)
	tw.parallel().tween_property(a, "oy", d.y, 0.11)
	tw.tween_property(a, "ox", 0.0, 0.13)
	tw.parallel().tween_property(a, "oy", 0.0, 0.13)
	await tw.finished


func tile_center(u) -> Vector2:
	return Vector2(u.x * TS + TS * 0.5, u.y * TS + TS * 0.5)


func float_text(u, text: String, col: Color) -> void:
	floats.append({"x": u.x * TS + TS * 0.5, "y": u.y * TS + 8.0, "text": text, "col": col, "t0": now()})


func burst(u, kind: String) -> void:
	var cols: Array = {"fire": ["#ffe066", "#ff9a2e", "#ff512f"], "ice": ["#f0fdff", "#9be8ff", "#5fb6ff"], "heal": ["#c8ffd6", "#5fdc77", "#f2ffe0"], "level": ["#fff4b8", "#f5cd55", "#ffffff"]}[kind]
	var up := kind == "heal" or kind == "level"
	var c := tile_center(u)
	for i in 30:
		var a := randf() * TAU
		var sp := 30.0 + randf() * 70.0
		var vel := Vector2(cos(a) * sp * (0.25 if up else 1.0), -(30.0 + randf() * 55.0) if up else sin(a) * sp - 30.0)
		parts.append({"pos": c + Vector2(randf() - 0.5, randf() - 0.5) * 16.0, "vel": vel, "life": 0.0, "max": 0.45 + randf() * 0.5, "col": Color(cols[i % cols.size()]), "size": 1.8 + randf() * 3.0, "kind": kind})


func shoot_arrow(a, t) -> void:
	fx.append({"type": "arrow", "t0": now(), "dur": 0.24, "a": tile_center(a) - Vector2(0, 6), "b": tile_center(t)})
	await wait(0.25)


func glow(a, kind: String) -> void:
	var col := {"fire": Color(1.0, 0.6, 0.18), "ice": Color(0.6, 0.9, 1.0), "heal": Color(0.37, 0.86, 0.47)}[kind] as Color
	fx.append({"type": "ring", "t0": now(), "dur": 0.38, "p": tile_center(a), "col": col})
	await wait(0.38)


# ---------- combat ----------
func lvf(a, t) -> float:
	return clampf(1.0 + (t.lv - a.lv) * 0.25, 0.25, 2.0)

func gain(u, n: float) -> void:
	if u.team == "p" and u.alive:
		pending[u] = pending.get(u, 0.0) + n

func hit_chance(a, t) -> float:
	return clampf(0.92 - (t.agi - a.agi) * 0.02 - land_of(t) * 0.12, 0.6, 0.98)

func base_dmg(a, t) -> float:
	return maxf(1.0, a.atk - t.def * 0.6) * (1.0 - land_of(t))

func exp_dmg(a, t) -> float:
	return base_dmg(a, t) * hit_chance(a, t)

func roll_dmg(a, t, crit: bool) -> int:
	var d := base_dmg(a, t) * (0.85 + randf() * 0.3)
	if crit:
		d = d * 1.5 + 1.0
	return maxi(1, roundi(d))


func hurt(t, dmg: int) -> void:
	t.hp = maxi(0, t.hp - dmg)
	t.flash_until = now() + 0.15
	t.shake_until = now() + 0.26
	float_text(t, str(dmg), Color.WHITE)
	t.awake = true


func defeat(t, by) -> void:
	t.alive = false
	create_tween().tween_property(t, "alpha", 0.0, 0.5)
	if t.team == "e":
		await say("%s is defeated!" % t.name)
		if by != null and by.team == "p":
			gain(by, 24.0 * lvf(by, t))
			by.kills += 1
	else:
		await say("%s has fallen!" % t.name, 0.8)


func strike(a, t) -> void:
	if mdist(a, t) > 1:
		await shoot_arrow(a, t)
	else:
		await lunge(a, t)
	if randf() > hit_chance(a, t):
		float_text(t, "MISS", Color("#cfd8ff"))
		await say("%s dodged the attack!" % t.name)
		return
	var crit := randf() < 1.0 / 16.0
	var dmg := roll_dmg(a, t, crit)
	hurt(t, dmg)
	await say(("Critical hit! %s takes %d damage." if crit else "%s takes %d damage.") % [t.name, dmg])
	if a.team == "p":
		gain(a, float(dmg) / t.mhp * 40.0 * lvf(a, t))
	if t.hp <= 0:
		await defeat(t, a)


func do_attack(a, t, counter := false) -> void:
	face(a, t)
	face(t, a)
	await say(("%s counterattacks!" if counter else "%s attacks!") % a.name, 0.35)
	await strike(a, t)
	if t.alive and a.alive and randf() < 1.0 / 16.0:
		await say("Second attack!", 0.3)
		await strike(a, t)
	if not counter and t.alive and a.alive and in_r(t, a, cls_of(t).range) and randf() < 0.2:
		await do_attack(t, a, true)


func cast_spell(a, sid: String, c) -> void:
	var sp: Dictionary = D.SPELLS[sid]
	a.mp -= sp.mp
	face(a, c)
	await say("%s casts %s!" % [a.name, sp.name], 0.35)
	await glow(a, sp.kind)
	var heal: bool = sp.kind == "heal"
	var hits := units.filter(func(u): return u.alive and mdist(u, c) <= sp.area and ((u.team == a.team) if heal else (u.team != a.team)))
	for t in hits:
		burst(t, sp.kind)
		await wait(0.16)
		if heal:
			var amt := mini(t.mhp - t.hp, sp.power + randi_range(-1, 1))
			t.hp += amt
			float_text(t, "+%d" % amt, Color("#8dffab"))
			await say("%s recovers %d HP." % [t.name, amt])
			gain(a, 6.0 + float(amt) / t.mhp * 30.0)
		else:
			var dmg := maxi(1, roundi(sp.power * (0.9 + randf() * 0.2) * (1.0 - land_of(t) * 0.5)))
			hurt(t, dmg)
			await say("%s takes %d damage." % [t.name, dmg])
			if a.team == "p":
				gain(a, float(dmg) / t.mhp * 40.0 * lvf(a, t))
			if t.hp <= 0:
				await defeat(t, a)


func use_item(a, id: String, t) -> void:
	var it: Dictionary = D.ITEMS[id]
	a.items.erase(id)
	face(a, t)
	await say("%s uses a %s." % [a.name, it.name], 0.35)
	burst(t, "heal")
	await wait(0.2)
	var amt := mini(t.mhp - t.hp, it.heal)
	t.hp += amt
	float_text(t, "+%d" % amt, Color("#8dffab"))
	await say("%s recovers %d HP." % [t.name, amt])
	gain(a, 5.0)


func flush_exp() -> void:
	for u in pending.keys():
		if not u.alive:
			continue
		var n := clampi(roundi(pending[u]), 1, 49)
		await say("%s gains %d EXP." % [u.name, n], 0.45)
		u.xp += n
		while u.xp >= 100:
			u.xp -= 100
			await level_up(u)
	pending.clear()


func level_up(u) -> void:
	var gr: Dictionary = cls_of(u).get("grow", {})
	var g := {}
	u.lv += 1
	for s in ["hp", "mp", "atk", "def", "agi"]:
		var r: Array = gr.get(s, [0, 0])
		g[s] = randi_range(r[0], r[1])
	u.mhp += g.hp
	u.hp += g.hp
	u.mmp += g.mp
	u.mp += g.mp
	u.atk += g.atk
	u.def += g.def
	u.agi += g.agi
	float_text(u, "LEVEL UP", Color("#f5cd55"))
	burst(u, "level")
	await say("%s is now level %d!" % [u.name, u.lv], 0.7)
	var bits := []
	for s in ["hp", "mp", "atk", "def", "agi"]:
		if g[s] > 0:
			bits.append("%s +%d" % [s.to_upper(), g[s]])
	if bits.size() > 0:
		await say("   ".join(bits), 0.9)
	var learn: Dictionary = cls_of(u).get("learn", {})
	if learn.has(u.lv):
		var sid: String = learn[u.lv]
		u.spells.append(sid)
		await say("%s learned %s!" % [u.name, D.SPELLS[sid].name], 0.9)


# ---------- player turn ----------
func side_right() -> bool:
	return cur.x < COLS / 2.0


func begin_move(u) -> void:
	mode = "move"
	hud.hide_menus()
	hud.hide_msg()
	orig = Vector2i(u.x, u.y)
	reach_r = reach(u)
	cursor = Vector2i(u.x, u.y)
	inspect = null
	threat = {}
	hud.set_hint("[b]%s's turn.[/b] Choose a blue square to move to, or select %s to stay in place." % [u.name, u.name])
	if autoplay:
		_auto_turn()


func commit_move(k: int) -> void:
	var u = cur
	mode = "busy"
	threat = {}
	inspect = null
	await move_along(u, path_to(reach_r, k))
	open_menu()


func undo_move() -> void:
	var u = cur
	u.x = orig.x
	u.y = orig.y
	u.px = u.x
	u.py = u.y
	begin_move(u)


func open_menu() -> void:
	var u = cur
	mode = "menu"
	var can := {"attack": foes_in_range(u, cls_of(u).range).size() > 0, "magic": u.spells.size() > 0, "item": u.items.size() > 0, "stay": true, "back": true}
	hud.show_cmd(can, side_right(), "attack" if can.attack else "stay")
	hud.set_hint("[b]%s:[/b] choose a command.%s" % [u.name, "" if can.attack else " No enemy is in weapon range."])


func do_cmd(a: String) -> void:
	if mode != "menu":
		return
	var u = cur
	match a:
		"attack":
			begin_target({"type": "attack"}, foes_in_range(u, cls_of(u).range), cls_of(u).range)
		"magic":
			open_list("magic")
		"item":
			open_list("item")
		"stay":
			end_player_turn()
		"back":
			undo_move()


func open_list(kind: String) -> void:
	var u = cur
	mode = "list"
	var entries := []
	if kind == "magic":
		for sid in u.spells:
			var sp: Dictionary = D.SPELLS[sid]
			var tg := spell_targets(u, sid)
			var ok: bool = u.mp >= sp.mp and tg.size() > 0
			var why := "Not enough MP" if u.mp < sp.mp else ("No wounded ally in range" if sp.kind == "heal" else "No enemy in range")
			entries.append({"label": sp.name, "meta": "%d MP" % sp.mp, "ok": ok, "why": why,
				"cb": func(): begin_target({"type": "spell", "spell": sid, "back": "magic"}, tg, sp.range, sp.area)})
	else:
		var counts := {}
		for i in u.items:
			counts[i] = counts.get(i, 0) + 1
		for id in counts:
			var it: Dictionary = D.ITEMS[id]
			var tg := hurt_allies_in_range(u, it.range)
			entries.append({"label": it.name, "meta": "x%d" % counts[id], "ok": tg.size() > 0, "why": "No wounded ally in reach",
				"cb": func(): begin_target({"type": "item", "item": id, "back": "item"}, tg, it.range)})
	hud.show_list("Magic" if kind == "magic" else "Items", entries, side_right(), func(): if mode == "list": open_menu())
	hud.set_hint("[b]%s:[/b] choose %s." % [u.name, "a spell" if kind == "magic" else "an item"])


func begin_target(act: Dictionary, tg: Array, r: Array, area := 0) -> void:
	if mode != "menu" and mode != "list":
		return
	var u = cur
	mode = "target"
	action = act.duplicate()
	action.range = r
	action.area = area
	targets = tg
	t_idx = 0
	hud.hide_menus()
	range_cells = cells_in_range(u, r)
	cursor = Vector2i(tg[0].x, tg[0].y)
	hud.show_cancel(true)
	var verb := "attack"
	if act.type == "spell":
		verb = "target with %s" % D.SPELLS[act.spell].name
	elif act.type == "item":
		verb = "give the herb to"
	hud.set_hint("[b]%s:[/b] choose who to %s. Arrow keys cycle targets." % [u.name, verb])


func cancel_target() -> void:
	hud.show_cancel(false)
	range_cells = {}
	if action.has("back"):
		mode = "menu"
		open_list(action.back)
	else:
		open_menu()


func execute(t) -> void:
	if mode != "target":
		return
	var u = cur
	var a := action
	mode = "busy"
	hud.hide_menus()
	range_cells = {}
	inspect = null
	hud.set_hint("[b]%s[/b] is acting." % u.name)
	match a.type:
		"attack":
			await do_attack(u, t)
		"spell":
			await cast_spell(u, a.spell, t)
		_:
			await use_item(u, a.item, t)
	await flush_exp()
	end_player_turn()


func end_player_turn() -> void:
	mode = "busy"
	hud.hide_menus()
	turn_done.emit()


# ---------- enemy turn ----------
func enemy_turn(u) -> void:
	hud.set_hint("[b]Enemy turn:[/b] %s" % u.name)
	await wait(0.16 * msg_speed + 0.08)
	var foes := units.filter(func(p): return p.alive and p.team != u.team)
	if not u.awake and foes.any(func(p): return mdist(p, u) <= u.aggro):
		u.awake = true
		if u.boss:
			await say("Gorgath: So you crossed the river. Your march ends on my blade!", 1.0)
	var r := reach(u, u.mov if u.awake else 0)
	var best := {}
	for k in free_dest(r, u):
		var x := kx(k)
		var y := ky(k)
		var land: int = D.TER[D.MAP[y][x]].land
		var mc: int = r.dist[k]
		for p in foes:
			var d := absi(p.x - x) + absi(p.y - y)
			var bonus: float = (3.0 if p.cls == "HERO" else 0.0) + (1.0 - float(p.hp) / p.mhp) * 5.0 + land * 0.06 - mc * 0.02
			var wr: Array = cls_of(u).range
			if d >= wr[0] and d <= wr[1]:
				var e := exp_dmg(u, p)
				var s: float = e + (30.0 if e >= p.hp else 0.0) + bonus
				if best.is_empty() or s > best.s:
					best = {"k": k, "type": "attack", "t": p, "s": s}
			for sid in u.spells:
				var sp: Dictionary = D.SPELLS[sid]
				if sp.kind == "heal" or u.mp < sp.mp:
					continue
				if d >= sp.range[0] and d <= sp.range[1]:
					var e: float = sp.power * (1.0 - land_of(p) * 0.5)
					var s: float = e + 2.0 + (30.0 if e >= p.hp else 0.0) + bonus
					if best.is_empty() or s > best.s:
						best = {"k": k, "type": "spell", "spell": sid, "t": p, "s": s}
	if not best.is_empty():
		await move_along(u, path_to(r, best.k))
		if best.type == "attack":
			await do_attack(u, best.t)
		else:
			await cast_spell(u, best.spell, best.t)
		await flush_exp()
		return
	if not u.awake:
		return
	var f := dist_field(u)
	var bk := key(u.x, u.y)
	var bv: int = f.get(bk, 1000000)
	var bl := -1
	for k in free_dest(r, u):
		var v: int = f.get(k, 1000000)
		var l: int = D.TER[D.MAP[ky(k)][kx(k)]].land
		if v < bv or (v == bv and l > bl):
			bk = k
			bv = v
			bl = l
	if bk != key(u.x, u.y):
		await move_along(u, path_to(r, bk))


# ---------- battle loop ----------
func check_end() -> String:
	for u in units:
		if u.cls == "HERO" and not u.alive:
			return "lose"
	for u in units:
		if u.boss and not u.alive:
			return "win"
	if not units.any(func(u): return u.team == "e" and u.alive):
		return "win"
	return ""


func run_battle() -> String:
	round_n = 0
	while true:
		round_n += 1
		var live := units.filter(func(u): return u.alive)
		for u in live:
			u.acted = false
		var keyed := live.map(func(u): return [u.agi * (0.875 + randf() * 0.25), u])
		keyed.sort_custom(func(a, b): return a[0] > b[0])
		order = keyed.map(func(e): return e[1])
		for u in order:
			if not u.alive:
				continue
			cur = u
			hover = null
			if u.team == "p":
				begin_move(u)
				await turn_done
			else:
				mode = "busy"
				cursor = null
				await enemy_turn(u)
			u.acted = true
			var r := check_end()
			if r != "":
				return r
	return ""


func _on_start() -> void:
	if mode == "over":
		setup()
	if mode != "intro":
		return
	hud.hide_overlay()
	mode = "busy"
	cur = units[0]
	hud.set_hint("The Rune Order holds the far bank.")
	await say("Gorgath: The bridge at Varn belongs to the Rune Order now. Turn back, Lanternguard.", 1.1)
	await say("Aren: Not while the people of Varn are trapped on the far bank. Everyone, with me!", 1.1)
	await say("Defeat Gorgath to win. If Aren falls, the battle is lost.", 1.1)
	hud.hide_msg()
	var r := await run_battle()
	hud.hide_menus()
	mode = "busy"
	if r == "win" and units.any(func(u): return u.team == "e" and u.alive):
		await say("With Gorgath beaten, the Rune Order soldiers scatter into the hills!", 1.0)
	hud.hide_msg()
	mode = "over"
	cur = null
	cursor = null
	var rows := []
	for u in units:
		if u.team == "p":
			rows.append([u.name, cls_of(u).label, u.lv, u.kills, "%d/%d" % [u.hp, u.mhp] if u.alive else "Fallen"])
	hud.show_result(r == "win", rows, round_n)
	hud.set_hint("Victory! Start again to try for a faster clear." if r == "win" else "Defeat. Start again when you are ready.")
	if autoplay:
		print("RESULT ", r, " rounds=", round_n)
		for row in rows:
			print("  ", row)
		get_tree().quit()


# ---------- input ----------
func inspect_unit(o) -> void:
	inspect = o
	threat = threat_of(o) if o.team == "e" else {}


func on_tile(x: int, y: int) -> void:
	if msg_active:
		msg_skip()
		return
	var o = unit_at(x, y)
	if mode == "move":
		cursor = Vector2i(x, y)
		var k := key(x, y)
		if reach_r.dist.has(k) and (o == null or o == cur):
			commit_move(k)
			return
		if o != null:
			inspect_unit(o)
		else:
			inspect = null
			threat = {}
	elif mode == "target":
		for i in targets.size():
			if targets[i].x == x and targets[i].y == y:
				t_idx = i
				execute(targets[i])
				return
	elif o != null and mode != "intro" and mode != "over":
		inspect = o


func _board_tile():
	var p: Vector2 = board.get_local_mouse_position()
	var x := int(floor(p.x / TS))
	var y := int(floor(p.y / TS))
	return Vector2i(x, y) if in_b(x, y) else null


func _unhandled_input(ev: InputEvent) -> void:
	if ev is InputEventMouseButton and ev.pressed and ev.button_index == MOUSE_BUTTON_LEFT:
		if msg_active:
			msg_skip()
			return
		var t = _board_tile()
		if t != null:
			on_tile(t.x, t.y)
	elif ev is InputEventMouseMotion:
		var t = _board_tile()
		tile_hover = t
		if t == null:
			hover = null
			return
		hover = unit_at(t.x, t.y)
		if mode == "move":
			cursor = t
		elif mode == "target":
			for i in targets.size():
				if targets[i].x == t.x and targets[i].y == t.y:
					t_idx = i
					cursor = t


func _input(ev: InputEvent) -> void:
	if not (ev is InputEventKey) or not ev.pressed:
		return
	var ok: bool = ev.is_action_pressed("ui_accept") or ev.keycode == KEY_Z
	var back: bool = ev.is_action_pressed("ui_cancel") or ev.keycode == KEY_X or ev.keycode == KEY_BACKSPACE
	var d := Vector2i.ZERO
	if ev.is_action_pressed("ui_up", true):
		d = Vector2i(0, -1)
	elif ev.is_action_pressed("ui_down", true):
		d = Vector2i(0, 1)
	elif ev.is_action_pressed("ui_left", true):
		d = Vector2i(-1, 0)
	elif ev.is_action_pressed("ui_right", true):
		d = Vector2i(1, 0)
	if msg_active and (ok or back):
		msg_skip()
		get_viewport().set_input_as_handled()
		return
	match mode:
		"move":
			if d != Vector2i.ZERO:
				if cursor == null:
					cursor = Vector2i(cur.x, cur.y)
				cursor = Vector2i(clampi(cursor.x + d.x, 0, COLS - 1), clampi(cursor.y + d.y, 0, ROWS - 1))
				hover = unit_at(cursor.x, cursor.y)
				tile_hover = cursor
				get_viewport().set_input_as_handled()
			elif ok:
				on_tile(cursor.x, cursor.y)
				get_viewport().set_input_as_handled()
		"target":
			if d != Vector2i.ZERO:
				var n := targets.size()
				t_idx = (t_idx + (1 if d.x + d.y > 0 else -1) + n) % n
				cursor = Vector2i(targets[t_idx].x, targets[t_idx].y)
				hover = targets[t_idx]
				get_viewport().set_input_as_handled()
			elif ok:
				execute(targets[t_idx])
				get_viewport().set_input_as_handled()
			elif back:
				cancel_target()
				get_viewport().set_input_as_handled()
		"menu":
			if d != Vector2i.ZERO:
				hud.focus_cmd({Vector2i(0, -1): "attack", Vector2i(-1, 0): "magic", Vector2i(1, 0): "item", Vector2i(0, 1): "stay"}[d])
				get_viewport().set_input_as_handled()
			elif back:
				undo_move()
				get_viewport().set_input_as_handled()
		"list":
			if back:
				open_menu()
				get_viewport().set_input_as_handled()


# ---------- side panel ----------
func _update_ui() -> void:
	var u = hover if hover != null else (inspect if inspect != null else (cur if cur != null else units[0]))
	var tl := ter(u.x, u.y)
	var bits := []
	for s in u.spells:
		bits.append(D.SPELLS[s].name)
	if u.items.size() > 0:
		bits.append("%d Medical Herb%s" % [u.items.size(), "s" if u.items.size() > 1 else ""])
	hud.update_card(u, cls_of(u).label, tl.n, tl.land, "  ·  ".join(bits))
	hud.update_order(order if order.size() > 0 else units, cur, round_n)
	var tt = tile_hover if tile_hover != null else cursor
	if tt != null:
		var t2 := ter(tt.x, tt.y)
		hud.set_tile_info("%s  ·  land effect %d%%%s" % [t2.n, t2.land, "" if t2.cost.size() > 0 else "  ·  impassable"])
	else:
		hud.set_tile_info("")


# ---------- autoplay (test harness: run with -- --autoplay) ----------
func _auto_turn() -> void:
	await wait(0.03)
	var u = cur
	var foes := units.filter(func(e): return e.alive and e.team == "e")
	var best := -1
	var bsc := 1000000
	var want := 2 if u.cls == "ACHR" else 1
	for k in free_dest(reach_r, u):
		var dmin := 1000
		for f in foes:
			dmin = mini(dmin, absi(f.x - kx(k)) + absi(f.y - ky(k)))
		var sc := absi(dmin - want)
		if sc < bsc:
			bsc = sc
			best = k
	on_tile(kx(best), ky(best))
	while mode != "menu":
		await get_tree().process_frame
	if foes_in_range(u, cls_of(u).range).size() > 0:
		do_cmd("attack")
		execute(targets[0])
		return
	for sid in u.spells:
		var tg := spell_targets(u, sid)
		if u.mp >= D.SPELLS[sid].mp and tg.size() > 0:
			mode = "list"
			begin_target({"type": "spell", "spell": sid}, tg, D.SPELLS[sid].range, D.SPELLS[sid].area)
			execute(targets[0])
			return
	do_cmd("stay")


## Saves screenshots of the briefing, a move turn and the command menu (run with -- --screens).
func _screens() -> void:
	await wait(1.5)
	get_viewport().get_texture().get_image().save_png("user://shot_intro.png")
	msg_speed = 0.02
	_on_start()
	while mode != "move":
		await get_tree().process_frame
	inspect_unit(units[13])
	inspect = null
	threat = {}
	cursor = Vector2i(cur.x + 1, cur.y - 2)
	await wait(0.6)
	get_viewport().get_texture().get_image().save_png("user://shot_move.png")
	on_tile(cur.x, cur.y)
	while mode != "menu":
		await get_tree().process_frame
	await wait(0.4)
	get_viewport().get_texture().get_image().save_png("user://shot_menu.png")
	print("SHOTS ", OS.get_user_data_dir())
	get_tree().quit()
