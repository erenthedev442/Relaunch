# Relaunch Custom DAT Manifest

This manifest tracks every client DAT override included in the Relaunch Custom
DATs pack.

## Included DATs

| File | Overrides | Notes |
|------|-----------|-------|
| `ROM/286/73.DAT` | item text: `26169` Legendary Ring; `23875-78` Track Suit set | Ring: 114-byte record edit. Track Suit: 4 free-id records cloned from donor armor (24213/23859/23831) with Lv.1/all-jobs/all-races attrs + new names. |
| `ROM/339/21-36.DAT` (16 files) | model 515 textures, all 8 races | Legendary Track Suit: body/legs/feet repainted **blue/white** (DXT3 color blocks only; alpha + file size byte-identical to retail). |
| `ROM/341/16,18,20,22,24,26,28.DAT` (7 files) | model 615 textures, all races | Legend Sweater + scarf repainted **crimson/white** (same integrity guarantees). |

Models 515/615 are referenced by no other item on Relaunch (verified against
item_equipment 2026-07-10), so these repaints change only the new custom items.

The edit was made by decoding the retail item block (FFXI items are ROR-5
bit-rotated), rewriting the four strings in place, and re-encoding. The retail
`Reraise Ring` name/help text became the Legendary Ring text below; nothing else
in the 17 MB file changed.

## Overrides

| Item ID | Retail Name  | Relaunch Name  | Status | Notes |
|--------:|--------------|----------------|--------|-------|
| `26169` | Reraise Ring | Legendary Ring | Done (`ROM/286/73.DAT`) | Functional Legacy migration reward. |

## Required Display Text

Suggested player-facing text for item `26169` (matches the server-side stats in
`modules/custom/sql/legendary_ring.sql`):

```text
Legendary Ring
[Ring] All Races
Experience Points Boost +300%
Capacity Points Boost +300%
Auto Reraise (III) Effect
Movement Speed +25%
Retains all EXP on death
No Weakness after Reraise
Enchantment: toggle Vanish / Transform
Lv.1 All Jobs
```

Name string: `Legendary Ring`

The `[Ring] All Races` and `Lv.1 All Jobs` header lines are auto-rendered by the
client from the item's binary attributes (slot=Rings, races=All, level 1, jobs
All) — already correct on item 26169, so only the name + the three effect lines
above are stored as edited text.

## Server-Side Source Of Truth

The server-side behavior lives in:

- `modules/custom/sql/legendary_ring.sql`  (item_basic / item_equipment / item_mods)
- `modules/custom/lua/legacy_ring_grant.lua`  (login grant)

The DAT pack is visual only. If DAT text disagrees with the server, the server
wins.

## Windower Resource Addon

The DAT pack fixes what the FFXI client DISPLAYS. It does NOT fix what
Windower / GearSwap SEE by name — those read `res\items.lua` inside
Windower4, a static file baked from RETAIL DATs. Without an override,
`left_ring = "Legendary Ring"` in a GearSwap set fails to resolve
(Windower still thinks item 26169 is "Reraise Ring"), and the four
Track Suit pieces (23875–78) don't exist in Windower's table at all.

The bundled addon `Windower/addons/relaunch/relaunch.lua` fixes both:

| Addon action | Item id | Result in Windower / GearSwap |
|---|--:|---|
| Rename       | `26169` | `res.items[26169].en = "Legendary Ring"` |
| Insert       | `23875` | Cloned from Arrogance Jacket → "Track Jacket" |
| Insert       | `23876` | Cloned from Arrogance Brais  → "Track Pants"  |
| Insert       | `23877` | Cloned from Emerald Crackows → "Track Shoes"  |
| Insert       | `23878` | Cloned from Arrogance Jacket → "Legend Sweater" |

Install auto-detects Windower4 and copies the addon into `addons\relaunch\`;
if it finds `Windower4\scripts\init.txt` it offers to append `lua load relaunch`
so the overrides apply every session. Uninstall reverses both.

Verify inside the game:

```text
//relaunch check Legendary Ring   -- should print: id 26169 (Legendary Ring)
//relaunch show 23875              -- should print: id 23875: en="Track Jacket" ...
```
