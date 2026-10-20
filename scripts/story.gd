## The story, as data. Acts, scenes, tutorial lines and endings all live here.
## Text tokens: {hero} is the hero's name, {girl} is the girl's name ("???" until Act 3 reveals her as Tera).
extends RefCounted

## Placeholder name for the amnesiac hero. Change it here.
const HERO_NAME := "Aren"
const GIRL_TRUE_NAME := "Tera"
const GIRL_HIDDEN_NAME := "???"

const WORLD := {
	"name": "Morrowmere",
	"lore": "Morrowmere is one of countless worlds, called dawns. Dawnshards, the money, are fragments of the last dawn and hold memories.",
}

## status: "playable" or "planned". battle names a battle in data.gd, or "" for none yet.
const ACTS := [
	{"id": "prologue", "title": "Prologue", "name": "Washed Ashore", "status": "playable", "battle": "",
		"summary": "The hero washes up on a beach in Morrowmere with no memory. A girl finds them and teaches them the basics. She is Tera, Elder Rowan's granddaughter, but her name stays hidden until much later."},
	{"id": "act1", "title": "Act 1", "name": "The Tear on the River Road", "status": "playable", "battle": "act1",
		"summary": "A tear in the air interrupts the prisoner transfer and a giant beast steps out. Celest's scholars start to study the tears."},
	{"id": "act2", "title": "Act 2", "name": "Starfall Ridge", "status": "planned", "battle": "",
		"summary": "Entering a tear over Starfall Ridge pulls the hero into a grey, silent ruined town. It's their home, though they don't know that yet."},
	{"id": "act3", "title": "Act 3", "name": "The Dawn Curse", "status": "planned", "battle": "",
		"summary": "The big reveal: Tera holds the Dawn curse, which is ripping holes between worlds."},
	{"id": "act4", "title": "Act 4", "name": "Other Dawns", "status": "planned", "battle": "",
		"summary": "The hero crosses to other dawns, looking for a way to save Tera and remove the curse."},
	{"id": "act5", "title": "Act 5", "name": "The Harbinger", "status": "planned", "battle": "",
		"summary": "The hero is the harbinger. A warrior sent them to cull worlds his master no longer thinks are worth keeping. Tera got the curse because she was the first person he touched."},
]

const ENDINGS := {
	"end": {"title": "Everything Ends", "summary": "Kill Tera, and everything ends."},
	"cycle": {"title": "And the Cycle Continues...", "summary": "The hero takes the curse and leaves for a dead world. The king just sends another harbinger."},
	"new_dawn": {"title": "A New Dawn", "summary": "The hero opens a tear into the king's kingdom and slays him, which ends the curse."},
}

## Speaker id -> [display name token, sprite class for the portrait]. "" class = no portrait.
const SPEAKERS := {
	"narrator": ["", ""],
	"hero": ["{hero}", "HERO"],
	"girl": ["{girl}", "HEAL"],
	"captain": ["Captain Kessa", "KNT"],
	"scholar": ["Mira", "MAGE"],
	"beast": ["The Beast", "BEAST"],
}

## Placeholder scene writing that follows the outline. Each line is [speaker, text].
## bg is the backdrop colour behind the scene.
const SCENES := {
	"prologue_shore": {"place": "Morrowmere  ·  The Shore", "bg": "#1b2a45", "lines": [
		["narrator", "Waves. Cold sand. A sky you don't recognize."],
		["girl", "Hey. Hey! You're breathing. Good."],
		["girl", "You washed up with the tide. Do you remember anything? Your name?"],
		["hero", "Nothing. Only a name... {hero}."],
		["girl", "Then that's where we start, {hero}. Up you get. This is Morrowmere, and the beach isn't safe at dusk."],
		["hero", "And you are?"],
		["girl", "Someone who found you. Stay close and I'll teach you how to get by out here."],
	]},
	"prologue_shard": {"place": "Morrowmere  ·  The Shore", "bg": "#1b2a45", "lines": [
		["hero", "This was in my hand when I woke up."],
		["girl", "A dawnshard. Folk spend them like coin, but they're pieces of the last dawn."],
		["girl", "Morrowmere is one dawn out of countless many. Hold a shard long enough and you'll catch a memory that isn't yours."],
		["narrator", "The shard is warm. For a moment you see a grey, silent town. Then nothing."],
	]},
	"act1_transfer": {"place": "Morrowmere  ·  The River Road", "bg": "#22331f", "lines": [
		["narrator", "Celest soldiers march a prisoner along the river road toward the bridge."],
		["captain", "Clear the road, you two. Prisoner transfer, by order of Celest."],
		["girl", "We'll keep out of your way, Captain."],
		["narrator", "Above the far bank, the air splits open like torn cloth."],
		["beast", "RRRAAAGH!"],
		["narrator", "Something enormous steps out of the tear, and smaller shapes spill after it."],
		["captain", "Guard the prisoner! Everyone else, hold the bridge!"],
		["girl", "{hero}, you're with me. Remember what I showed you."],
	]},
	"act1_aftermath": {"place": "Morrowmere  ·  The River Road", "bg": "#22331f", "lines": [
		["narrator", "The beast falls. The tear shrinks to a hairline, then it's gone."],
		["scholar", "That was no creature of Morrowmere. The scholars of Celest will want every scrap of this."],
		["scholar", "We'll study these tears. Wherever the next one opens, we'll be watching."],
		["girl", "You fought like you'd done it before, {hero}."],
		["hero", "Maybe I have. I wish I knew."],
	]},
}

## Lines said during the battle itself, as "Speaker: text" messages.
const BATTLE := {
	"act1": {
		"chapter": "Act 1  ·  The Tear on the River Road",
		"start": [["narrator", "Defeat the beast from the tear. If {hero} falls, the battle is lost."]],
		"boss_wakes": [["beast", "RRRAAAGH!"], ["narrator", "The beast lowers its horns. The tear behind it flickers."]],
		"boss_falls": [["narrator", "With the beast down, the tear creatures scatter and fade."]],
		"win_title": "Act 1 cleared",
		"win_text": "The tear has closed and the river road is safe, for now.",
		"lose_text": "The tear creatures overrun the bridge. Regroup and try again.",
		"next": "Next: Act 2, Starfall Ridge. Not built yet.",
	},
}

## The girl teaching the basics on the hero's first turns.
const TUTORIAL := {
	"move": [
		["girl", "Blue squares show how far you can walk. Pick one, or pick yourself to stay put."],
		["girl", "Click an enemy to see where it can reach. Forest and hills soften the blows you take."],
	],
	"menu": [
		["girl", "Now choose what to do. Attack if something's in reach, or Stay to end your turn."],
		["girl", "The middle button takes your step back, if you change your mind."],
	],
}


static func fmt(text: String, revealed := false) -> String:
	return text.replace("{hero}", HERO_NAME).replace("{girl}", GIRL_TRUE_NAME if revealed else GIRL_HIDDEN_NAME)


static func speaker_name(id: String, revealed := false) -> String:
	return fmt(SPEAKERS[id][0], revealed)


static func speaker_class(id: String) -> String:
	return SPEAKERS[id][1]
