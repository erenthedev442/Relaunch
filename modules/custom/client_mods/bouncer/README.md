# Bouncer — Client Relabel Pack

Makes the FFXI **client** display the repurposed GEO job slot as **BOUNCER** —
the **job name**, the **9 Job Ability names**, and their **menu descriptions**.
This is **cosmetic and client-side only**: the server doesn't know or care about
these strings; they live in your local game files (`FFXiMain.dll` + two ROM DATs).

Players **without** this pack play the exact same job; their screen just says
"Geomancer / GEO" with the stock GEO ability names. Mechanics are 100% identical
either way.

## What it changes

**Job name** — three ASCII strings inside `FFXiMain.dll` (same byte length):

| Where you see it | Stock | Bouncer |
|------------------|-------|---------|
| Status / equip / job menus (full name) | `Geomancer` | `Bouncer` |
| Caps full name (job-change, titles) | `GEOMANCER` | `BOUNCER` |
| 3-letter tag (party list, `Lv99 ___`) | `GEO` | `BNC` |

**Ability names** — the 9 repurposed Job Abilities, in `ROM\181\72.DAT` (the
client's ability-name table). These are what show in the **JA menu** and the
**"\<player\> uses ..."** message:

| Stock (GEO) | Bouncer |
|-------------|---------|
| Bolster | Last Call |
| Full Circle | Step Outside |
| Ecliptic Attrition | Sucker Punch |
| Widened Compass | Crowd Control |
| Collimated Fervor | Bodyguard |
| Life Cycle | Retaliate |
| Blaze of Glory | Brace |
| Dematerialize | Hold the Line |
| Theurgic Focus | Bloodbind |

**Ability descriptions** — the JA-menu help text for those same 9 abilities, in
`ROM\181\74.DAT` (the parallel ability-description table). Rewritten to describe
the Bouncer behaviour instead of the donor GEO flavour:

| Ability | Bouncer description |
|---------|---------------------|
| Last Call | Cannot be knocked out; reflects all damage. |
| Step Outside | Provokes a single enemy. |
| Sucker Punch | Delivers a stunning blow that claims the enemy. |
| Crowd Control | Reinforces your enmity toward nearby enemies. |
| Bodyguard | Shields a party member from all damage briefly. |
| Retaliate | Reflects damage taken and absorbs it as HP. |
| Brace | Reduces damage taken by 25% for a short time. |
| Hold the Line | Briefly negates all damage you take. |
| Bloodbind | Restores HP equal to 25% of your maximum. |

> These are short, qualitative summaries of the live Bouncer behaviour (see
> `bouncer_abilities.lua`), not the exact durations/numbers — kept concise so each
> fits inside the slot the old GEO description occupied (the file size never
> changes).

## Install (one click does it all)

1. Make sure FFXI / PlayOnline is **fully closed**.
2. Double-click **`install.bat`** and approve the UAC prompt. It:
   - backs up the originals once (`FFXiMain.dll.orig`, `ROM\181\72.DAT.orig`,
     `ROM\181\74.DAT.orig`),
   - installs the patched DLL (job name),
   - patches the ability **names** in place (`patch_abilities.ps1`), then
   - patches the ability **descriptions** in place (`patch_descriptions.ps1`).
3. Relaunch through Windower/Ashita. `!changejob GEO` → you're a **Bouncer**, and
   your JAs read as the Bouncer kit (name **and** description).

## Uninstall / revert

Run **`uninstall.bat`** — restores `FFXiMain.dll.orig`, `ROM\181\72.DAT.orig`,
and `ROM\181\74.DAT.orig`. A PlayOnline client update can also overwrite any of
these with a stock copy; if that happens and you want Bouncer back, just run
`install.bat` again.

## Notes

- The 3-letter tag is **BNC**. Want a different one (e.g. `BOU`)? Ask — it must
  stay exactly 3 letters. Because that string is also what `/sea` parses, searching
  by job becomes `/sea all BNC` on this client. Cosmetic.
- Both DAT patches are keyed by the stock GEO **text** (names in `72.DAT`,
  descriptions in `74.DAT`), so they're **idempotent** (re-runs skip entries that
  are already done) and **reversible**. If a future client patch changes a DAT and
  the stock string isn't found, the patcher warns and skips it rather than
  corrupting anything. Each new string is written in place over the old one and the
  remainder is null-cleared, so both DATs keep their exact original size.
- Files in this pack: `FFXiMain.dll` (patched job name), `FFXiMain.dll.orig`
  (pristine backup), `patch_abilities.ps1` (ability-name patcher),
  `patch_descriptions.ps1` (ability-description patcher), `install.bat`,
  `uninstall.bat`. Backups made on the client side at install time:
  `FFXiMain.dll.orig`, `ROM\181\72.DAT.orig`, and `ROM\181\74.DAT.orig`.
