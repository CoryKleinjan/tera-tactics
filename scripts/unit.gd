## One unit on the battlefield, ally or enemy.
extends RefCounted

var id := 0
var team := "p"
var cls := ""
var name := ""
var x := 0
var y := 0
## Drawn position in tiles; differs from x/y while walking.
var px := 0.0
var py := 0.0
var lv := 1
var hp := 0
var mhp := 0
var mp := 0
var mmp := 0
var atk := 0
var def := 0
var agi := 0
var mov := 0
var xp := 0
var kills := 0
var spells: Array = []
var items: Array = []
var ai := "charge"
var aggro := 0
var boss := false
var awake := true
var alive := true
var acted := false
# Animation state
var alpha := 1.0
var flash_until := 0.0
var shake_until := 0.0
var face := 1
var ox := 0.0
var oy := 0.0


static func from_dict(d: Dictionary, team_id: String, uid: int):
	var u = load("res://scripts/unit.gd").new()
	u.id = uid
	u.team = team_id
	u.cls = d.cls
	u.name = d.name
	u.x = d.x
	u.y = d.y
	u.px = d.x
	u.py = d.y
	u.lv = d.get("lv", 1)
	u.hp = d.hp
	u.mhp = d.hp
	u.mp = d.get("mp", 0)
	u.mmp = u.mp
	u.atk = d.atk
	u.def = d.def
	u.agi = d.agi
	u.mov = d.mov
	u.spells = d.get("spells", []).duplicate()
	u.items = d.get("items", []).duplicate()
	u.ai = d.get("ai", "charge")
	u.aggro = d.get("aggro", 0)
	u.boss = d.get("boss", false)
	u.awake = u.ai != "guard"
	u.face = 1 if team_id == "p" else -1
	return u
