# Tera Tactics

A Shining Force style tactical RPG prototype, built in Godot 4.3 (GDScript, Compatibility renderer, so it can export to web, desktop and mobile).

## Run it
1. Install Godot 4.3 or newer from https://godotengine.org/download.
2. In the Project Manager choose **Import**, pick `project.godot` in this folder, then press **Run** (F5).

## Story
The hero washes up in Morrowmere, one of countless worlds called dawns, with no memory. A girl (Tera, whose name stays hidden until Act 3) finds them and teaches them the basics. The full outline, all five acts and the three endings are in `scripts/story.gd`.

What plays today:
- **Prologue, Washed Ashore:** the beach scene and the first dawnshard.
- **Act 1, The Tear on the River Road:** a tear opens during a Celest prisoner transfer and a giant beast steps out. The girl's tutorial lines run during your first turn. Afterwards, Celest's scholars begin studying the tears.

Acts 2 to 5 and the endings are recorded as data but not built yet. Scene dialogue is placeholder writing that follows the outline; replace any line in `story.gd`. The hero's name is `HERO_NAME` there.

## How it plays
In Act 1, six heroes (Swordsman, Knight, Warrior, Archer, Mage, Healer) hold a river crossing against the Tear Beast and the creatures that came through with it.
- Turn order is rolled from agility every round, with allies and enemies mixed together.
- Movement ranges follow terrain costs. Forest and hills cut the damage a unit takes (land effect), and the river can only be crossed at the bridges or a slow ford.
- Each turn: move, then pick from the four-way Attack / Magic / Item / Stay menu. The middle button undoes the move.
- Defeated tear creatures drop Dawnshards, the money of the world, tallied after the battle.
- Hits, misses, criticals, second attacks and counters. Blaze, Heal and Freeze spells, plus Medical Herbs.
- EXP from damage, kills and heals. 100 EXP is a level, with random stat growth, and new spells come at level 4.
- Enemy AI scores every reachable square and attack. Guards hold position until you get close.

Controls: mouse (or touch), or the arrow keys, Enter to confirm and Esc to go back.

## Where things live
| File | What it holds |
| --- | --- |
| `scripts/story.gd` | Story outline, acts, scenes, tutorial lines, endings, hero name. |
| `scripts/data.gd` | Map, terrain, classes, spells, items, starting armies, the tear's position. Change balance here. |
| `scripts/main.gd` | Turn loop, player input, combat rules, enemy AI, EXP and levels. |
| `scripts/board.gd` | Range overlays, cursor, units and effects drawn on the map. |
| `scripts/terrain.gd` | Draws the map tiles. |
| `scripts/sprites.gd` | Procedural unit sprites (swap for real pixel art later). |
| `scripts/hud.gd` | Side panel, message box, command menu, briefing and results screens. |

## Test hooks
- `godot --headless --path . -- --autoplay` plays a full battle with a simple bot and prints the result.
- `godot --path . -- --screens` saves screenshots of the title, a story scene, the tutorial and a move turn to the Godot user data folder.

## Not built yet
Acts 2 to 5 and their battles, the three endings, the Act 3 name reveal, spending Dawnshards (shops), promotions (planned for level 10), saving, sound, and real sprite art.
