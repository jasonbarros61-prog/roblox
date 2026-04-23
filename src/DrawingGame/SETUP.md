# Drawing Game — Studio Setup Guide

## Script placement

| File | Type | Goes in |
|------|------|---------|
| `ShapeData.lua` | ModuleScript | `ReplicatedStorage` → rename to **ShapeData** |
| `GameConfig.lua` | ModuleScript | `ReplicatedStorage` → rename to **GameConfig** |
| `GameManager.lua` | Script | `ServerScriptService` → rename to **GameManager** |
| `DrawingGui.lua` | LocalScript | `StarterGui` → rename to **DrawingGui** |
| `SeatHandler.lua` | LocalScript | `StarterPlayerScripts` → rename to **SeatHandler** |

## Workspace setup (chairs + table)

1. **Create a Model** — name it `DrawingTable_1` (unique name per table).
2. Inside the Model add:
   - One `Part` for the tabletop (anchor it).
   - Two `Seat` parts facing each other — name both **DrawingSeat**.
3. *(Optional)* Set a **string Attribute** `Shape` on each Seat to lock it to one shape.  
   Leave blank to randomise each round.
4. Duplicate the Model for more tables (each must have a different Model name so sessions stay separate).

## Shape rewards

| Shape | Coins (win) | Difficulty |
|-------|-------------|------------|
| Circle | 350 | Easy |
| Triangle | 400 | Medium |
| Pentagon | 700 | Hard |

Full coins require **≥ 70 %** accuracy.  
Partial coins are awarded down to **25 %** accuracy (scaled).  
Below 25 % — no coins.

## Tweaking

All tunable values live in `GameConfig.lua`:

- `DRAW_TIME` — seconds per round (default 45)
- `WIN_THRESHOLD` — % for full coins (default 70)
- `ACCURACY_THRESHOLD` — pixel tolerance when scoring a "hit" (default 28)
- `LINE_THICKNESS` — stroke width in pixels (default 5)
