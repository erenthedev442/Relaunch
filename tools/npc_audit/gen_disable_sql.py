#!/usr/bin/env python3
"""Generate the status=2 (DISAPPEAR) SQL that hides the audited 'extra' NPCs --
plus a matching rollback. Applies NOTHING; it only writes .sql files.

Reads the reviewed proposal (npc_disable_candidates.json: {folder: [npcid,...]})
and writes:
  sql/npc_declutter.sql            UPDATE npc_list SET status = 2 ...  (hide)
  sql/npc_declutter_ROLLBACK.sql   UPDATE npc_list SET status = 0 ...  (undo)

NOTE on the file names: deliberately NOT prefixed `zz_`. The Azure deploy
(tools/_azure_update_remote.sh) auto-applies every sql/zz_*.sql on each deploy --
so a `zz_` rollback would cancel the disable, and the declutter would ride every
unrelated deploy. Keeping these OUT of that glob makes the declutter a deliberate,
standalone action: fire it with tools/npc_audit/apply_declutter.sh when YOU decide.

status=2 is reversible and the entity still LOADS -- verified in zoneutils.cpp:
the NPC loader filters by zone only, never by status -- so GetNPCByID references
can't nil-crash. The change only becomes visible after a map restart (NPCs load
at boot), so applying the SQL mid-session disturbs nobody until you restart.

Usage:
  python gen_disable_sql.py                 # FLAVOR bucket, all reviewed zones
  python gen_disable_sql.py Port_Windurst   # PILOT: FLAVOR, one zone only
  python gen_disable_sql.py --cutscene      # FLAVOR + CUTSCENE, all zones
  python gen_disable_sql.py --cutscene Port_Windurst   # both buckets, one zone

The CUTSCENE bucket is riskier (a few may be mission cutscene steps), so it's
opt-in -- the default is the conservative flavor-only set.
"""
import json
import sys
from pathlib import Path

ROOT         = Path(r"D:/server")
JSON         = ROOT / "tools" / "npc_audit" / "npc_disable_candidates.json"
JSON_CUT     = ROOT / "tools" / "npc_audit" / "npc_disable_candidates_cutscene.json"
EXCLUDE      = ROOT / "tools" / "npc_audit" / "npc_disable_exclude.json"
OUT_DISABLE  = ROOT / "sql" / "npc_declutter.sql"
OUT_ROLLBACK = ROOT / "sql" / "npc_declutter_ROLLBACK.sql"

# Endgame "god" / instanced zones: nearly every NPC is a warp/altar/mechanism
# (Monolith, Cermet Portal/Alcove, Auroral Updraft, Dimensional Portal, Radiant
# Aureole, Swirling Vortex, Gilded Doors...), NOT town clutter. Decluttering value
# here is ~zero and the mislabel risk is high, so skip these zones wholesale.
ZONE_EXCLUDE = {
    "AlTaieu", "Grand_Palace_of_HuXzoi", "The_Garden_of_RuHmet",
    "The_Shrine_of_RuAvitau", "VeLugannon_Palace", "Hall_of_the_Gods",
    "Walk_of_Echoes",
}

# Flags (any order) + an optional zone-folder positional.
args        = sys.argv[1:]
include_cut = ("--cutscene" in args) or ("--both" in args)
zone_args   = [a for a in args if not a.startswith("-")]
only        = zone_args[0] if zone_args else None

proposal: dict[str, list[int]] = json.loads(JSON.read_text(encoding="utf-8"))
if include_cut and JSON_CUT.exists():
    # Fold the riskier CUTSCENE bucket in on request (default = flavor only).
    for folder, ids in json.loads(JSON_CUT.read_text(encoding="utf-8")).items():
        proposal[folder] = sorted(set(proposal.get(folder, [])) | set(ids))

# Safety net: subtract any ids the name-scan flagged as actually-functional
# (Spatial Displacement warps, Nomad Moogles, Salvage doors, Pso'Xja lifts...).
# Regenerate it with tools/npc_audit/safety_scan.py --write.  This is a hard
# floor -- nothing on this list can be hidden, even on a full regen.
# Drop the wholesale-excluded endgame zones first.
zoned = 0
for folder in list(proposal):
    if folder in ZONE_EXCLUDE:
        zoned += len(proposal[folder])
        del proposal[folder]
if zoned:
    print(f"zone-excluded {zoned} NPC(s) across {len(ZONE_EXCLUDE)} endgame zone(s)")

excluded = set()
if EXCLUDE.exists():
    excluded = set(json.loads(EXCLUDE.read_text(encoding="utf-8")))
    dropped = 0
    for folder in list(proposal):
        kept = [n for n in proposal[folder] if n not in excluded]
        dropped += len(proposal[folder]) - len(kept)
        if kept:
            proposal[folder] = kept
        else:
            del proposal[folder]
    if dropped:
        print(f"safety_scan excluded {dropped} functional NPC(s) "
              f"({len(excluded)} on the do-not-hide list)")

if only:
    if only not in proposal:
        sys.exit(f"zone folder '{only}' not in proposal. Example keys: "
                 + ", ".join(sorted(proposal)[:6]) + " ...")
    proposal = {only: proposal[only]}


def build(target_status: int, undo: bool) -> tuple[str, int]:
    """Render one .sql; returns (text, npc_count). `undo` flips the guard so the
    rollback only touches rows we actually hid (status = 2)."""
    suffix = "_ROLLBACK" if undo else ""
    verb   = "RESTORE (undo)" if undo else "HIDE (status=2 DISAPPEAR)"
    guard  = "= 2" if undo else "<> 2"   # undo: only re-show what we hid
    out = [
        "-- ============================================================",
        f"-- zz_npc_declutter{suffix}.sql  --  {verb}",
        "-- GENERATED by tools/npc_audit/gen_disable_sql.py from the reviewed",
        "-- npc_disable_candidates.json.  status=2 hides, status=0 restores.",
        "-- Entity still LOADS either way (loader filters by zone only), so",
        "-- GetNPCByID refs are safe.  Takes effect on the next map restart.",
        "-- ============================================================",
        "",
    ]
    total = 0
    for folder in sorted(proposal):
        ids = sorted(set(proposal[folder]))
        if not ids:
            continue
        total += len(ids)
        out.append(f"-- {folder.replace('_', ' ')}  ({len(ids)} NPC(s))")
        out.append(f"UPDATE npc_list SET status = {target_status} "
                   f"WHERE status {guard} AND npcid IN ({', '.join(map(str, ids))});")
        out.append("")
    return "\n".join(out) + "\n", total


dis_text, n = build(2, undo=False)
rb_text, _  = build(0, undo=True)
OUT_DISABLE.write_text(dis_text, encoding="utf-8")
OUT_ROLLBACK.write_text(rb_text, encoding="utf-8")

scope = f"zone '{only}'" if only else f"{len(proposal)} zone(s)"
print(f"HIDE  -> {OUT_DISABLE}  ({n} NPCs, {scope})")
print(f"UNDO  -> {OUT_ROLLBACK}")
print()
print("Fire it (deliberate, standalone -- backs up, applies, restarts xi_map only):")
print("  # on the Azure box, from the server checkout root:")
print("  git pull && sudo bash tools/npc_audit/apply_declutter.sh")
print("Undo everything:")
print("  sudo bash tools/npc_audit/apply_declutter.sh --rollback")
