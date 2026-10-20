## All tunable game data: the map, terrain, classes, spells, items and the starting armies.
extends RefCounted

const TS := 48
const COLS := 16
const ROWS := 12

## One character per tile. See TER for the legend.
const MAP := [
	"mm...ff...hh.mmm",
	"m....ffr..hh..mm",
	"..f....r......hm",
	"..ff..rr...f....",
	".....rr....ff...",
	"wwwwwbwwswwwbwww",
	"..h..r......r...",
	".hh..r..ff..r.f.",
	".....r..ff..rr..",
	"..f..rrrrrrrr...",
	".ff...........h.",
	"mm.........m..hh",
]

## land = % damage reduction for a unit standing there. cost = move points per movement type; missing = impassable.
const TER := {
	".": {"n": "Grass", "land": 10, "cost": {"foot": 1, "horse": 1}},
	"r": {"n": "Road", "land": 0, "cost": {"foot": 1, "horse": 1}},
	"f": {"n": "Forest", "land": 25, "cost": {"foot": 2, "horse": 3}},
	"h": {"n": "Hills", "land": 30, "cost": {"foot": 2, "horse": 3}},
	"s": {"n": "Ford", "land": 0, "cost": {"foot": 3, "horse": 3}},
	"b": {"n": "Bridge", "land": 0, "cost": {"foot": 1, "horse": 1}},
	"w": {"n": "River", "land": 0, "cost": {}},
	"m": {"n": "Crags", "land": 0, "cost": {}},
}

const SPELLS := {
	"blaze1": {"name": "Blaze 1", "mp": 3, "range": [1, 2], "area": 0, "power": 9, "kind": "fire"},
	"blaze2": {"name": "Blaze 2", "mp": 6, "range": [1, 2], "area": 1, "power": 10, "kind": "fire"},
	"heal1": {"name": "Heal 1", "mp": 3, "range": [0, 1], "area": 0, "power": 12, "kind": "heal"},
	"heal2": {"name": "Heal 2", "mp": 5, "range": [0, 2], "area": 0, "power": 16, "kind": "heal"},
	"freeze1": {"name": "Freeze 1", "mp": 3, "range": [1, 2], "area": 0, "power": 8, "kind": "ice"},
}

const ITEMS := {
	"herb": {"name": "Medical Herb", "heal": 10, "range": [0, 1]},
}

## grow = random [min, max] stat gain per level. learn = spell gained at a level.
const CLASSES := {
	"HERO": {"label": "Swordsman", "mt": "foot", "range": [1, 1], "grow": {"hp": [1, 3], "atk": [1, 2], "def": [1, 2], "agi": [1, 2]}},
	"KNT": {"label": "Knight", "mt": "horse", "range": [1, 1], "grow": {"hp": [1, 3], "atk": [1, 2], "def": [1, 2], "agi": [0, 2]}},
	"WARR": {"label": "Warrior", "mt": "foot", "range": [1, 1], "grow": {"hp": [2, 3], "atk": [1, 2], "def": [1, 2], "agi": [0, 1]}},
	"ACHR": {"label": "Archer", "mt": "foot", "range": [2, 3], "grow": {"hp": [1, 2], "atk": [1, 2], "def": [0, 1], "agi": [1, 2]}},
	"MAGE": {"label": "Mage", "mt": "foot", "range": [1, 1], "grow": {"hp": [1, 2], "mp": [2, 3], "atk": [0, 1], "def": [0, 1], "agi": [1, 2]}, "learn": {4: "blaze2"}},
	"HEAL": {"label": "Healer", "mt": "foot", "range": [1, 1], "grow": {"hp": [1, 2], "mp": [2, 3], "atk": [0, 1], "def": [1, 1], "agi": [0, 1]}, "learn": {4: "heal2"}},
	"TEARLING": {"label": "Tearling", "mt": "foot", "range": [1, 1]},
	"TEARARC": {"label": "Tearling Archer", "mt": "foot", "range": [2, 2]},
	"BRUTE": {"label": "Riftbrute", "mt": "foot", "range": [1, 1]},
	"SEER": {"label": "Hollow Seer", "mt": "foot", "range": [1, 1]},
	"BEAST": {"label": "Tear Beast", "mt": "foot", "range": [1, 1]},
}

const PARTY := [
	{"cls": "HERO", "name": "{hero}", "x": 3, "y": 10, "hp": 16, "atk": 10, "def": 5, "agi": 7, "mov": 5, "items": ["herb"]},
	{"cls": "KNT", "name": "Kessa", "x": 5, "y": 9, "hp": 15, "atk": 10, "def": 6, "agi": 5, "mov": 7, "items": ["herb"]},
	{"cls": "WARR", "name": "Gord", "x": 6, "y": 10, "hp": 18, "atk": 11, "def": 7, "agi": 3, "mov": 4, "items": ["herb"]},
	{"cls": "ACHR", "name": "Rhys", "x": 5, "y": 11, "hp": 12, "atk": 9, "def": 4, "agi": 6, "mov": 5},
	{"cls": "MAGE", "name": "Mira", "x": 3, "y": 11, "hp": 10, "mp": 12, "atk": 5, "def": 3, "agi": 6, "mov": 5, "spells": ["blaze1"]},
	{"cls": "HEAL", "name": "{girl}", "x": 2, "y": 11, "hp": 12, "mp": 14, "atk": 6, "def": 4, "agi": 5, "mov": 5, "spells": ["heal1"], "items": ["herb"]},
]

## ai "guard" units hold position until a foe comes within aggro tiles or they get hurt.
## shards = Dawnshards picked up when the party defeats the unit.
const ENEMIES := [
	{"cls": "TEARLING", "name": "Tearling", "x": 4, "y": 3, "lv": 1, "hp": 12, "atk": 9, "def": 4, "agi": 5, "mov": 5, "shards": 6},
	{"cls": "TEARLING", "name": "Tearling", "x": 9, "y": 4, "lv": 1, "hp": 12, "atk": 9, "def": 4, "agi": 5, "mov": 5, "shards": 6},
	{"cls": "TEARLING", "name": "Tearling", "x": 14, "y": 7, "lv": 1, "hp": 12, "atk": 9, "def": 4, "agi": 5, "mov": 5, "shards": 6},
	{"cls": "BRUTE", "name": "Riftbrute", "x": 6, "y": 1, "lv": 2, "hp": 15, "atk": 11, "def": 6, "agi": 3, "mov": 4, "shards": 10},
	{"cls": "BRUTE", "name": "Riftbrute", "x": 13, "y": 4, "lv": 2, "hp": 15, "atk": 11, "def": 6, "agi": 3, "mov": 4, "shards": 10},
	{"cls": "TEARARC", "name": "Tearling Archer", "x": 8, "y": 2, "lv": 2, "hp": 10, "atk": 9, "def": 3, "agi": 6, "mov": 5, "shards": 8},
	{"cls": "SEER", "name": "Hollow Seer", "x": 12, "y": 2, "lv": 3, "hp": 12, "mp": 12, "atk": 6, "def": 3, "agi": 7, "mov": 5, "spells": ["freeze1"], "ai": "guard", "aggro": 6, "shards": 12},
	{"cls": "BEAST", "name": "Tear Beast", "x": 11, "y": 1, "lv": 5, "hp": 24, "atk": 12, "def": 7, "agi": 6, "mov": 6, "ai": "guard", "aggro": 4, "boss": true, "shards": 40},
]

## Where the tear hangs open on the map (drawn behind units).
const TEAR := Vector2i(11, 0)
