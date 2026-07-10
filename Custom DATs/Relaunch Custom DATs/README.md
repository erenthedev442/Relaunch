# Relaunch Custom DATs

Optional client-side DAT overrides for Relaunch.

These files update client display text, names, icons, or descriptions for custom
Relaunch content. They do not affect gameplay, stats, equip rules, damage,
augments, or server-side balance — the server is always the source of truth.

## Easiest: run the installer (recommended for players)

1. Unzip this whole folder anywhere.
2. Double-click **`Install Legendary Ring.bat`** and approve the admin prompt.
3. It finds your FINAL FANTASY XI install, backs up the original file, and drops
   in the Legendary Ring DAT. Restart the game client — done.

To revert at any time, double-click **`Uninstall Legendary Ring.bat`** (it
restores the original from the backup the installer made).

The installer simply replaces the client's item DAT (with a `.orig` backup), so
it works no matter which launcher you use — Windower, Ashita, or none.

## Alternative: XIPivot overlay (advanced, non-destructive)

Prefer not to touch client files? Load it as an overlay instead:

1. Place the `Relaunch Custom DATs` folder inside your XIPivot overlay folder.
2. Keep the internal `ROM/...` folder structure exactly as provided.
3. Enable the overlay in XIPivot.
4. Restart the game client.

## Current Override

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
