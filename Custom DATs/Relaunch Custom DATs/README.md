# Relaunch Custom DATs

Optional client-side DAT overrides for Relaunch.

These files update client display text, names, icons, or descriptions for custom
Relaunch content. They do not affect gameplay, stats, equip rules, damage,
augments, or server-side balance — the server is always the source of truth.

## Easiest: run the installer (recommended for players)

1. Unzip this whole folder anywhere.
2. Double-click **`Install Relaunch DATs.bat`** and approve the admin prompt.
3. It finds your FINAL FANTASY XI install, backs up every original file, and
   installs ALL of the pack's overrides (Legendary Ring + Legendary Track Suit).
   Restart the game client — done.

To revert at any time, double-click **`Uninstall Relaunch DATs.bat`** (it
restores the original from the backup the installer made).

The installer simply replaces the client DATs listed below (each with a `.orig`
backup), so it works no matter which launcher you use — Windower, Ashita, or none.

## Alternative: XIPivot overlay (advanced, non-destructive)

Prefer not to touch client files? Load it as an overlay instead:

1. Place the `Relaunch Custom DATs` folder inside your XIPivot overlay folder.
2. Keep the internal `ROM/...` folder structure exactly as provided.
3. Enable the overlay in XIPivot.
4. Restart the game client.

## Current Overrides

### Legendary Track Suit (cosmetic set)

- Items: `23875` Track Jacket, `23876` Track Pants, `23877` Track Shoes,
  `23878` Legend Sweater — all Lv.1, all jobs/races, zero stats (pure glamour)
- Client models `515` (suit) and `615` (sweater + scarf) — unused by any other
  item on Relaunch — custom-repainted for ALL 8 race/gender variants:
  suit in **blue/white**, sweater in **crimson/white**
- Files: `ROM/339/21-36.DAT` (suit textures), `ROM/341/16,18,20,22,24,26,28.DAT`
  (sweater textures), plus item names/tooltips in `ROM/286/73.DAT`
- Without this pack the set still equips and works — it just shows the models'
  original colors (black/silver suit, dusty-red sweater) and blank item names

### Legendary Ring

- Item ID: `26169`
- Retail item reused: `Reraise Ring`
- Server item name: `Legendary Ring`
- Purpose: the one functional Legacy migration reward (recognition for time on Legendary)
- Server behavior: Rare/Ex, all jobs, Lv.1 ring — EXP +50%, Capacity +50%, Auto-Reraise

If you do not install this pack, the Legendary Ring still works exactly the same
in-game — your client just shows the original retail `Reraise Ring` name and help
text instead of the `Legendary Ring` text below.

## DAT Editing Notes

Use a DAT tool such as POLUtils to search the retail client files for:

```text
Reraise Ring
```

Then edit that item's name + help text to the Legendary Ring display text (see
`manifest.md`). After editing, place the modified DAT into this package using the
same `ROM/...` path it came from in the retail client.

Do not include the whole FFXI ROM folder. Only include DAT files that Relaunch
actually overrides.
