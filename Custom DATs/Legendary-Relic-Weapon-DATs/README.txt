Legendary Relic Weapon DATs
===========================

CANONICAL COPY: this folder in the Relaunch repo
  Custom DATs\Legendary-Relic-Weapon-DATs\

Do not treat C:\Users\Sion\Downloads\Legendary-Relic-Weapon-DATs as source
of truth (and do not use the 29 Aug zip — that pack has no Epeo/Idris).

This pack is SEPARATE from Custom DATs\Relaunch Custom DATs
(Legendary Ring + Track Suit). XIPivot needs BOTH overlays.

These client files do two jobs:

1) Extra jobs on the listed relic lines (same as before)
2) New unused-ID records for Epeolatry / Idris 99 and 119 I

Files
-----
ROM\118\108.DAT   English weapons
ROM\0\6.DAT       base / Japanese weapons

New items (empty retail hole 19968-20479)
-----------------------------------------
19968  Epeolatry   99      RUN       cloned look from 20753, DMG 154, no ilvl
19969  Epeolatry   119 I   RUN       cloned look from 20753, DMG 199 (below 20753's 243)
19970  Idris       99      GEO       cloned look from 21070, DMG 80, no ilvl
19971  Idris       119 I   GEO       cloned look from 21070, DMG 110 (below 21070's 139), no GEO+10

Also patched so every Epeo stage stays RUN-only:
20753  Epeolatry   119     RUN
21685  Epeolatry   119 III RUN

Idris 21070 / 21080 were already GEO.
21070 examine no longer lists Geomancy +10 (that line stays on 21080 only).

Intended ladder (server SQL still needed)
-----------------------------------------
Epeolatry:  19968 -> 19969 -> 20753 -> 21685
Idris:      19970 -> 19971 -> 21070 -> 21080

Relic extra jobs (unchanged)
----------------------------
Mandau       +DNC   18270, 18271, 18638, 18652, 18666, 19747, 19840, 20555, 20556, 20583
Excalibur    +BLU   18276, 18277, 18639, 18653, 18667, 19748, 19841, 20645, 20646, 20685
Spharai      +PUP   18264, 18265, 18637, 18651, 18665, 19746, 19839, 20480, 20481, 20509
Ragnarok     +RUN   18282, 18283, 18640, 18654, 18668, 19749, 19842, 20745, 20746, 21683
Mjollnir     +GEO   18324, 18325, 18647, 18661, 18675, 19756, 19849, 21060, 21061, 21077
Claustrum    +SCH   18330, 18331, 18648, 18662, 18676, 19757, 19850, 21135, 21136, 22060
Annihilator  +COR   18336, 18337, 18649, 18663, 18677, 19758, 19851, 21260, 21261, 21267, 22140

Installation
------------
XIPivot (preferred): add this folder as an overlay (keep ROM\118 and ROM\0).
Also keep "Relaunch Custom DATs" enabled for Ring + Track Suit.

Or copy into the client:
1. Exit FINAL FANTASY XI and PlayOnline.
2. BACK UP the original DAT files before installing:
   C:\Program Files (x86)\PlayOnline\SquareEnix\FINAL FANTASY XI\ROM\118\108.DAT
   C:\Program Files (x86)\PlayOnline\SquareEnix\FINAL FANTASY XI\ROM\0\6.DAT
3. Copy the included ROM folder into:
   C:\Program Files (x86)\PlayOnline\SquareEnix\FINAL FANTASY XI
   and allow only these two matching DAT paths to be replaced.

WARNING: Keep your backups. PlayOnline/FFXI updates may overwrite these files
or re-version the item DATs. After a client update, run _rebuild.ps1 to
regenerate this pack from the new retail files.

The DAT pack is visual only (name, icon, examine text, client job mask).
Server item_weapon / item_equipment / the Weapon Forge catalog still have
to issue 19968-19971 before anyone can hold them.
