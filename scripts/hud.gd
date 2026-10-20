## All on-screen interface: title, side panel, message box, command cross, lists, overlays.
extends Control

signal cmd(action: String)
signal cancel
signal speed
signal start

const Portrait = preload("res://scripts/portrait.gd")
const BOARD_POS := Vector2(24, 84)
const BOARD_SIZE := Vector2(768, 576)

const INK := Color("#0c1029")
const BTN := Color("#0f1a4d")
const PANEL := Color("#1f3a96")
const FRAME := Color("#e8ecf7")
const GOLD := Color("#f5cd55")
const TEXT := Color("#f5f2e8")
const MUTED := Color("#b7c1e6")
const HP := Color("#5fdc77")
const MP := Color("#62b8ff")
const ALLY := "#6cc3ff"
const FOE := "#ff6e5e"

var msg_panel: PanelContainer
var msg_label: Label
var cmd_panel: PanelContainer
var cmd_buttons := {}
var cmd_label: Label
var list_panel: PanelContainer
var list_title: Label
var list_box: VBoxContainer
var cancel_btn: Button
var overlay: ColorRect
var ov_content: VBoxContainer
var hint: RichTextLabel
var tile_info: Label
var portrait
var card_name: RichTextLabel
var card_cls: Label
var hp_row: Array
var mp_row: Array
var xp_row: Array
var stats: Label
var land: Label
var extra: Label
var order_title: Label
var order_text: RichTextLabel
var speed_btn: Button

const LABELS := {"attack": "Attack", "magic": "Magic", "item": "Item", "stay": "Stay", "back": "Undo move"}


func _ready() -> void:
	position = Vector2.ZERO
	size = Vector2(1280, 720)
	mouse_filter = MOUSE_FILTER_IGNORE
	theme = _make_theme()
	_build()


# ---------- theme ----------
func _box(bg: Color, border: Color, bw: int, margin: float) -> StyleBoxFlat:
	var b := StyleBoxFlat.new()
	b.bg_color = bg
	b.border_color = border
	b.set_border_width_all(bw)
	b.set_corner_radius_all(6)
	b.set_content_margin_all(margin)
	return b


func _make_theme() -> Theme:
	var th := Theme.new()
	th.default_font_size = 16
	var p := _box(PANEL, FRAME, 3, 12)
	p.shadow_color = Color(0, 0, 0, 0.45)
	p.shadow_size = 5
	th.set_stylebox("panel", "PanelContainer", p)
	var bn := _box(BTN, FRAME, 2, 6)
	var bh := _box(GOLD, FRAME, 2, 6)
	var bd := _box(Color(BTN, 0.45), Color(FRAME, 0.3), 2, 6)
	th.set_stylebox("normal", "Button", bn)
	th.set_stylebox("hover", "Button", bh)
	th.set_stylebox("pressed", "Button", bh)
	th.set_stylebox("focus", "Button", bh)
	th.set_stylebox("disabled", "Button", bd)
	th.set_color("font_color", "Button", TEXT)
	for k in ["font_hover_color", "font_pressed_color", "font_focus_color", "font_hover_pressed_color"]:
		th.set_color(k, "Button", INK)
	th.set_color("font_disabled_color", "Button", Color(TEXT, 0.35))
	th.set_color("font_color", "Label", TEXT)
	th.set_color("default_color", "RichTextLabel", TEXT)
	th.set_stylebox("background", "ProgressBar", _box(Color(0, 0, 0, 0.45), Color(FRAME, 0.35), 1, 0))
	return th


# ---------- helpers ----------
func _label(text: String, fs := 16, col := TEXT) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", fs)
	l.add_theme_color_override("font_color", col)
	l.mouse_filter = MOUSE_FILTER_IGNORE
	return l


func _rich(fs := 16) -> RichTextLabel:
	var r := RichTextLabel.new()
	r.bbcode_enabled = true
	r.fit_content = true
	r.scroll_active = false
	r.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	r.add_theme_font_size_override("normal_font_size", fs)
	r.add_theme_font_size_override("bold_font_size", fs)
	r.mouse_filter = MOUSE_FILTER_IGNORE
	return r


func _bar(col: Color) -> Array:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	var name_l := _label("", 13, MUTED)
	name_l.custom_minimum_size.x = 30
	var bar := ProgressBar.new()
	bar.show_percentage = false
	bar.custom_minimum_size = Vector2(0, 10)
	bar.size_flags_horizontal = SIZE_EXPAND_FILL
	bar.size_flags_vertical = SIZE_SHRINK_CENTER
	var fill := _box(col, col, 0, 0)
	fill.set_corner_radius_all(3)
	bar.add_theme_stylebox_override("fill", fill)
	var val := _label("", 15)
	val.custom_minimum_size.x = 56
	val.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	row.add_child(name_l)
	row.add_child(bar)
	row.add_child(val)
	return [row, name_l, bar, val]


func _panel(title: String) -> Array:
	var pc := PanelContainer.new()
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 8)
	pc.add_child(v)
	v.add_child(_label(title.to_upper(), 13, GOLD))
	return [pc, v]


func _btn(text: String, fs := 16) -> Button:
	var b := Button.new()
	b.text = text
	b.add_theme_font_size_override("font_size", fs)
	return b


# ---------- layout ----------
func _build() -> void:
	var head := HBoxContainer.new()
	head.position = Vector2(24, 18)
	head.add_theme_constant_override("separation", 18)
	var title := _label("TERA TACTICS", 34, GOLD)
	title.add_theme_color_override("font_outline_color", Color("#14235e"))
	title.add_theme_constant_override("outline_size", 8)
	head.add_child(title)
	var sub := _label("Chapter 1  ·  The Bridge at Varn", 16, MUTED)
	sub.size_flags_vertical = SIZE_SHRINK_END
	head.add_child(sub)
	add_child(head)

	hint = _rich(15)
	hint.position = Vector2(24, 668)
	hint.size = Vector2(560, 44)
	hint.add_theme_color_override("default_color", MUTED)
	add_child(hint)
	tile_info = _label("", 15, MUTED)
	tile_info.position = Vector2(592, 668)
	tile_info.size = Vector2(200, 24)
	tile_info.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	add_child(tile_info)

	# Side column
	var side := VBoxContainer.new()
	side.position = Vector2(816, 84)
	side.custom_minimum_size = Vector2(440, 0)
	side.add_theme_constant_override("separation", 12)
	add_child(side)

	var card := _panel("Unit")
	side.add_child(card[0])
	var ch := HBoxContainer.new()
	ch.add_theme_constant_override("separation", 14)
	card[1].add_child(ch)
	portrait = Portrait.new()
	portrait.custom_minimum_size = Vector2(96, 96)
	portrait.size_flags_vertical = SIZE_SHRINK_BEGIN
	ch.add_child(portrait)
	var info := VBoxContainer.new()
	info.size_flags_horizontal = SIZE_EXPAND_FILL
	info.add_theme_constant_override("separation", 4)
	ch.add_child(info)
	card_name = _rich(18)
	info.add_child(card_name)
	card_cls = _label("", 14, MUTED)
	info.add_child(card_cls)
	hp_row = _bar(HP)
	mp_row = _bar(MP)
	xp_row = _bar(GOLD)
	hp_row[1].text = "HP"
	mp_row[1].text = "MP"
	xp_row[1].text = "EXP"
	for r in [hp_row, mp_row, xp_row]:
		info.add_child(r[0])
	stats = _label("", 15)
	info.add_child(stats)
	land = _label("", 13, MUTED)
	info.add_child(land)
	extra = _label("", 13, MUTED)
	extra.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	info.add_child(extra)

	var ord := _panel("Turn order")
	side.add_child(ord[0])
	order_title = ord[1].get_child(0)
	order_text = _rich(15)
	ord[1].add_child(order_text)

	var help := _panel("How to play")
	side.add_child(help[0])
	var ht := _rich(14)
	ht.add_theme_color_override("default_color", MUTED)
	ht.text = "[b]Move:[/b] click a blue square, or your own unit to stay put.\n[b]Command:[/b] Attack, Magic, Item, Stay. The middle button undoes the move.\n[b]Scout:[/b] click an enemy to see its reach in orange.\n[b]Terrain:[/b] forest and hills cut damage taken.\n[b]Keys:[/b] arrows, Enter to confirm, Esc to go back."
	help[1].add_child(ht)
	speed_btn = _btn("Text speed: Normal", 14)
	speed_btn.size_flags_horizontal = SIZE_SHRINK_BEGIN
	speed_btn.focus_mode = FOCUS_NONE
	speed_btn.pressed.connect(func(): speed.emit())
	help[1].add_child(speed_btn)

	# Message box
	msg_panel = PanelContainer.new()
	msg_panel.mouse_filter = MOUSE_FILTER_IGNORE
	msg_panel.custom_minimum_size = Vector2(BOARD_SIZE.x - 48, 66)
	msg_label = _label("", 20)
	msg_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	msg_label.custom_minimum_size.x = BOARD_SIZE.x - 80
	msg_panel.add_child(msg_label)
	msg_panel.visible = false
	add_child(msg_panel)

	# Command cross
	cmd_panel = PanelContainer.new()
	var cv := VBoxContainer.new()
	cv.alignment = BoxContainer.ALIGNMENT_CENTER
	cmd_panel.add_child(cv)
	var grid := GridContainer.new()
	grid.columns = 3
	grid.add_theme_constant_override("h_separation", 4)
	grid.add_theme_constant_override("v_separation", 4)
	cv.add_child(grid)
	var layout := ["", "attack", "", "magic", "back", "item", "", "stay", ""]
	for a in layout:
		if a == "":
			var sp := Control.new()
			sp.custom_minimum_size = Vector2(72, 52)
			sp.mouse_filter = MOUSE_FILTER_IGNORE
			grid.add_child(sp)
		else:
			var b := _btn("Undo" if a == "back" else LABELS[a], 14)
			b.custom_minimum_size = Vector2(72, 52)
			b.pressed.connect(func(): cmd.emit(a))
			b.mouse_entered.connect(func(): cmd_label.text = LABELS[a].to_upper())
			b.focus_entered.connect(func(): cmd_label.text = LABELS[a].to_upper())
			grid.add_child(b)
			cmd_buttons[a] = b
	cmd_label = _label("", 14, GOLD)
	cmd_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	cv.add_child(cmd_label)
	cmd_panel.visible = false
	add_child(cmd_panel)

	# Spell / item list
	list_panel = PanelContainer.new()
	list_panel.custom_minimum_size.x = 260
	var lv := VBoxContainer.new()
	lv.add_theme_constant_override("separation", 6)
	list_panel.add_child(lv)
	list_title = _label("", 13, GOLD)
	lv.add_child(list_title)
	list_box = VBoxContainer.new()
	list_box.add_theme_constant_override("separation", 6)
	lv.add_child(list_box)
	list_panel.visible = false
	add_child(list_panel)

	cancel_btn = _btn("Back", 14)
	cancel_btn.position = BOARD_POS + Vector2(BOARD_SIZE.x - 96, 14)
	cancel_btn.custom_minimum_size = Vector2(80, 36)
	cancel_btn.focus_mode = FOCUS_NONE
	cancel_btn.pressed.connect(func(): cancel.emit())
	cancel_btn.visible = false
	add_child(cancel_btn)

	# Overlay for briefing and results
	overlay = ColorRect.new()
	overlay.color = Color(0.02, 0.03, 0.1, 0.55)
	overlay.position = BOARD_POS
	overlay.size = BOARD_SIZE
	add_child(overlay)
	var cc := CenterContainer.new()
	cc.size = BOARD_SIZE
	overlay.add_child(cc)
	var ob := PanelContainer.new()
	ob.custom_minimum_size.x = 540
	cc.add_child(ob)
	ov_content = VBoxContainer.new()
	ov_content.add_theme_constant_override("separation", 12)
	ob.add_child(ov_content)


# ---------- message box ----------
func show_msg(top: bool) -> void:
	msg_label.text = ""
	msg_panel.visible = true
	msg_panel.reset_size()
	var y := BOARD_POS.y + 16 if top else BOARD_POS.y + BOARD_SIZE.y - msg_panel.size.y - 16
	msg_panel.position = Vector2(BOARD_POS.x + 24, y)


func set_msg(text: String) -> void:
	msg_label.text = text


func hide_msg() -> void:
	msg_panel.visible = false


# ---------- commands ----------
func _place(p: Control, right: bool) -> void:
	p.reset_size()
	var sz := p.get_combined_minimum_size()
	var x := BOARD_POS.x + BOARD_SIZE.x - sz.x - 20 if right else BOARD_POS.x + 20
	p.position = Vector2(x, BOARD_POS.y + (BOARD_SIZE.y - sz.y) * 0.5)


func show_cmd(can: Dictionary, right: bool, default: String) -> void:
	hide_menus()
	for a in cmd_buttons:
		cmd_buttons[a].disabled = not can.get(a, false)
	cmd_panel.visible = true
	_place(cmd_panel, right)
	focus_cmd(default)


func focus_cmd(a: String) -> void:
	var b: Button = cmd_buttons[a]
	if b.disabled:
		return
	b.grab_focus()
	cmd_label.text = LABELS[a].to_upper()


## entries: [{label, meta, ok, why, cb: Callable}]
func show_list(title: String, entries: Array, right: bool, back: Callable) -> void:
	hide_menus()
	list_title.text = title.to_upper()
	for ch in list_box.get_children():
		list_box.remove_child(ch)
		ch.queue_free()
	var first: Button = null
	for e in entries:
		var b := _btn("%s    %s%s" % [e.label, e.meta, "" if e.ok else "\n" + e.why], 15)
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		b.disabled = not e.ok
		b.pressed.connect(e.cb)
		list_box.add_child(b)
		if e.ok and first == null:
			first = b
	var bb := _btn("Back", 15)
	bb.alignment = HORIZONTAL_ALIGNMENT_LEFT
	bb.pressed.connect(back)
	list_box.add_child(bb)
	list_panel.visible = true
	_place(list_panel, right)
	(first if first else bb).grab_focus()


func show_cancel(v: bool) -> void:
	cancel_btn.visible = v


func hide_menus() -> void:
	cmd_panel.visible = false
	list_panel.visible = false
	cancel_btn.visible = false
	var f := get_viewport().gui_get_focus_owner()
	if f:
		f.release_focus()


func set_hint(t: String) -> void:
	hint.text = t


func set_tile_info(t: String) -> void:
	tile_info.text = t


# ---------- side panel ----------
func update_card(u, cls_label: String, ter_name: String, ter_land: int, extras: String) -> void:
	portrait.unit = u
	card_name.text = "[b]%s[/b]   [color=%s]%s[/color]" % [u.name, ALLY if u.team == "p" else FOE, "ALLY" if u.team == "p" else "ENEMY"]
	card_cls.text = "%s  ·  LV %d%s" % [cls_label, u.lv, "" if u.alive else "  ·  Fallen"]
	hp_row[2].max_value = u.mhp
	hp_row[2].value = u.hp
	hp_row[3].text = "%d/%d" % [u.hp, u.mhp]
	mp_row[0].visible = u.mmp > 0
	mp_row[2].max_value = max(1, u.mmp)
	mp_row[2].value = u.mp
	mp_row[3].text = "%d/%d" % [u.mp, u.mmp]
	xp_row[0].visible = u.team == "p"
	xp_row[2].max_value = 100
	xp_row[2].value = u.xp
	xp_row[3].text = str(u.xp)
	stats.text = "ATK %d    DEF %d    AGI %d    MOV %d" % [u.atk, u.def, u.agi, u.mov]
	land.text = "Standing on %s  ·  land effect %d%%" % [ter_name.to_lower(), ter_land]
	extra.text = extras
	extra.visible = extras != ""


func update_order(order: Array, cur, round_n: int) -> void:
	order_title.text = "TURN ORDER  ·  ROUND %d" % round_n if round_n > 0 else "TURN ORDER"
	var parts := []
	for o in order:
		if not o.alive:
			continue
		var col: String = ALLY if o.team == "p" else FOE
		if o.acted and o != cur:
			col += "70"
		var n: String = o.name
		if o == cur:
			n = "[b][u]%s[/u][/b]" % n
		parts.append("[color=%s]%s[/color]" % [col, n])
	order_text.text = "   ".join(parts)


# ---------- overlays ----------
func _clear_overlay() -> void:
	for ch in ov_content.get_children():
		ov_content.remove_child(ch)
		ch.queue_free()


func show_intro() -> void:
	_clear_overlay()
	ov_content.add_child(_label("CHAPTER 1", 13, MUTED))
	ov_content.add_child(_label("The Bridge at Varn", 28, GOLD))
	var p := _label("The Rune Order has seized the only crossing on the Varn river. Lead the Lanternguard over the water and break their commander, Gorgath the Rune Knight.", 16)
	p.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	p.custom_minimum_size.x = 510
	ov_content.add_child(p)
	var r := _rich(15)
	r.add_theme_color_override("default_color", MUTED)
	r.text = "[b]Win:[/b] defeat Gorgath.\n[b]Lose:[/b] Aren, your Swordsman, falls.\nTurn order is set by agility each round, friend and foe mixed."
	ov_content.add_child(r)
	var b := _btn("BEGIN BATTLE", 16)
	b.size_flags_horizontal = SIZE_SHRINK_BEGIN
	b.custom_minimum_size = Vector2(180, 42)
	b.pressed.connect(func(): start.emit())
	ov_content.add_child(b)
	overlay.visible = true
	b.grab_focus.call_deferred()


func show_result(win: bool, rows: Array, round_n: int) -> void:
	_clear_overlay()
	ov_content.add_child(_label(("CHAPTER 1 CLEARED  ·  %d ROUNDS" if win else "BATTLE LOST  ·  ROUND %d") % round_n, 13, MUTED))
	ov_content.add_child(_label("Victory at Varn" if win else "Aren has fallen", 28, GOLD))
	var p := _label("Gorgath is beaten and the bridge is open. The Lanternguard marches on." if win else "The Lanternguard pulls back across the river. Regroup and try a different approach.", 16)
	p.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	p.custom_minimum_size.x = 510
	ov_content.add_child(p)
	var g := GridContainer.new()
	g.columns = 5
	g.add_theme_constant_override("h_separation", 22)
	g.add_theme_constant_override("v_separation", 4)
	for h in ["NAME", "CLASS", "LV", "KILLS", "HP"]:
		g.add_child(_label(h, 12, MUTED))
	for row in rows:
		for i in row.size():
			var fallen: bool = i == 4 and row[i] == "Fallen"
			g.add_child(_label(str(row[i]), 15, Color(FOE) if fallen else TEXT))
	ov_content.add_child(g)
	var b := _btn("PLAY AGAIN" if win else "TRY AGAIN", 16)
	b.size_flags_horizontal = SIZE_SHRINK_BEGIN
	b.custom_minimum_size = Vector2(160, 42)
	b.pressed.connect(func(): start.emit())
	ov_content.add_child(b)
	overlay.visible = true
	b.grab_focus.call_deferred()


func hide_overlay() -> void:
	overlay.visible = false
