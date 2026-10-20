# Tera Tactics

A Shining Force style tactical RPG prototype, built in Godot 4.3 (GDScript, Compatibility renderer, so it can export to web, desktop and mobile).

## Run it
1. Install Godot 4.3 or newer from https://godotengine.org/download.
2. In the Project Manager choose **Import**, pick `project.godot` in this folder, then press **Run** (F5).

## How it plays
Chapter 1, "The Bridge at Varn": six heroes (Swordsman, Knight, Warrior, Archer, Mage, Healer) cross a river to beat Gorgath the Rune Knight and his seven soldiers.
- Turn order is rolled from agility every round, with allies and enemies mixed together.
- Movement ranges follow terrain costs. Forest and hills cut the damage a unit takes (land effect), and the river can only be crossed at the bridges or a slow ford.
- Each turn: move, then pick from the four-way Attack / Magic / Item / Stay menu. The middle button undoes the move.
- Hits, misses, criticals, second attacks and counters. Blaze, Heal and Freeze spells, plus Medical Herbs.
- EXP from damage, kills and heals. 100 EXP is a level, with random stat growth, and new spells come at level 4.
- Enemy AI scores every reachable square and attack. Guards hold position until you get close.

Controls: mouse (or touch), or the arrow keys, Enter to confirm and Esc to go back.

## Where things live
| File | What it holds |
| --- | --- |
| `scripts/data.gd` | Map, terrain, classes, spells, items, starting armies. Change balance here. |
| `scripts/main.gd` | Turn loop, player input, combat rules, enemy AI, EXP and levels. |
| `scripts/board.gd` | Range overlays, cursor, units and effects drawn on the map. |
| `scripts/terrain.gd` | Draws the map tiles. |
| `scripts/sprites.gd` | Procedural unit sprites (swap for real pixel art later). |
| `scripts/hud.gd` | Side panel, message box, command menu, briefing and results screens. |

## Test hooks
- `godot --headless --path . -- --autoplay` plays a full battle with a simple bot and prints the result.
- `godot --path . -- --screens` saves three screenshots to the Godot user data folder.

## Not built yet
Promotions (planned for level 10), towns and story scenes between battles, more chapters, saving, sound, and real sprite art.
