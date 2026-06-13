#!/usr/bin/env python3
"""Pre-launch safety net for the NPC declutter.

The classifier reads only each NPC's local script, so two kinds of mislabel slip
through into the disable set:
  * interactive movement NPCs (Spatial Displacement warps, Conflux, waypoints)
    whose script is just startEvent -> warp -- they read as CUTSCENE.
  * objects whose `name` is a placeholder (_210) so the door/lever/etc. only
    shows in `polutils_name` -- the is_object() filter keyed on `name` misses them.

Hiding either kind would break traversal/content.  This scans both candidate
JSONs against the live npc_list.sql names and prints anything that smells
functional, grouped by reason.  With --write it also drops the flagged ids into
npc_disable_exclude.json, which gen_disable_sql.py honours.
"""
import json
import re
import sys
from pathlib import Path

ROOT      = Path(r"D:/server")
NPC_SQL   = ROOT / "sql" / "npc_list.sql"
JSON_FLV  = ROOT / "tools" / "npc_audit" / "npc_disable_candidates.json"
JSON_CUT  = ROOT / "tools" / "npc_audit" / "npc_disable_candidates_cutscene.json"
EXCLUDE   = ROOT / "tools" / "npc_audit" / "npc_disable_exclude.json"

# Substrings (case-insensitive, matched against BOTH name and polutils_name) that
# mark an NPC as too functional to hide.  Movement, services, and clickable objects.
DANGER = {
    "warp/movement": [
        "displacement", "conflux", "waypoint", "warp", "telepoint", "teleporter",
        "runic portal", "survival guide", "home point", "homepoint", "waystone",
        "monument", "moogle ferry", "ferry", "lift", "elevator", "transport",
        "geomagnetron", "boulder", "draw bridge", "drawbridge",
    ],
    "object/door": [
        "door", "doors", "gate", "lever", "switch", "mechanism", "console",
        "lamp", "lantern", "barrier", "wall", "panel", "valve", "crank",
        "pillar", "platform", "bridge", "ladder", "stairs", "elevator",
        "markings", "bones",  # examine-points that drive quests
    ],
    "portal/warp-object": [
        # glowing-portal naming = battlefield/zone warps & entry circles, NOT flavor
        "aureole", "shimmering", "radiant", "luminous", "glowing", "glittering",
        "gleaming", "prismatic", "circle", "vortex", "rift", "portal", "maw",
        "cracked mirror", "elemental ward", "wending", "membrane", "cipher",
        "burning circle",
    ],
    "service": [
        "shop", "merchant", "vendor", "moogle", "auction", "porter", "nomad",
        "chocobo", "stabler", "stable", "guard", "gatekeeper", "guildmaster",
        "broker", "banker", "delivery", "linkshell", "armoir", "armoire",
        "storage", "field manual", "grounds tome", "field_manual",
        "grounds_tome", "magian", "curio", "goblin footprint", "mystery box",
        "guildworker", "guild ", "examiner", "appraiser",
    ],
}


def load_names():
    """npcid -> (name, polutils_name, status) from npc_list.sql."""
    out = {}
    pat = re.compile(r"VALUES \((\d+),'((?:[^']|'')*)','((?:[^']|'')*)',(.*?)\);")
    for line in NPC_SQL.read_text(encoding="utf-8", errors="replace").splitlines():
        m = pat.search(line)
        if not m:
            continue
        npcid = int(m.group(1))
        name = m.group(2)
        polu = m.group(3)
        rest = m.group(4).split(",")
        # rest = [field4, x, y, z, f8, f9, f10, f11, f12, status, ...]; status = idx 9
        status = rest[9].strip() if len(rest) > 9 else "?"
        out[npcid] = (name, polu, status)
    return out


def classify(name, polu):
    # No display name = infrastructure (zone helper / object), not "flavor you
    # look at" -- the whole premise of the declutter. Never hide these.
    if not polu.strip():
        return "no-name/infra", "<empty polutils>"
    hay = f"{name} {polu}".lower().replace("_", " ")
    for reason, words in DANGER.items():
        for w in words:
            if w in hay:
                return reason, w
    return None, None


def main():
    names = load_names()
    flv = json.loads(JSON_FLV.read_text(encoding="utf-8"))
    cut = json.loads(JSON_CUT.read_text(encoding="utf-8"))
    buckets = {"flavor": flv, "cutscene": cut}

    # Pre-pass: a display name that repeats within one zone is an object/generic
    # cluster (Signpost, Handle, Monolith, Tome of Magic...), never unique flavor
    # townsfolk -- those have unique names. Strong catch-all for objects the
    # is_object() classifier missed.
    from collections import Counter
    zone_name_counts = Counter()
    for data in buckets.values():
        for folder, ids in data.items():
            for npcid in ids:
                _, polu, _ = names.get(npcid, ("?", "?", "?"))
                if polu.strip():
                    zone_name_counts[(folder, polu.lower().strip())] += 1

    flagged = {}  # reason -> list[(npcid, name, polu, folder, bucket, word)]
    exclude_ids = set()
    for bucket, data in buckets.items():
        for folder, ids in data.items():
            for npcid in ids:
                name, polu, _ = names.get(npcid, ("?", "?", "?"))
                reason, word = classify(name, polu)
                if not reason and zone_name_counts[(folder, polu.lower().strip())] >= 2:
                    reason, word = "dup-name cluster", f"{polu} x{zone_name_counts[(folder, polu.lower().strip())]}"
                if reason:
                    flagged.setdefault(reason, []).append(
                        (npcid, name, polu, folder, bucket, word))
                    exclude_ids.add(npcid)

    total = sum(len(v) for v in flagged.values())
    print(f"Scanned 1,047 candidates -> {total} flagged as likely-functional\n")
    for reason in ("warp/movement", "object/door", "portal/warp-object",
                   "service", "no-name/infra", "dup-name cluster"):
        hits = flagged.get(reason, [])
        if not hits:
            continue
        print(f"=== {reason}  ({len(hits)}) ===")
        # collapse by polutils name to keep it readable
        by_name = {}
        for npcid, name, polu, folder, bucket, word in hits:
            by_name.setdefault((polu, bucket), []).append((folder, npcid))
        for (polu, bucket), rows in sorted(by_name.items(), key=lambda x: -len(x[1])):
            folders = sorted({f for f, _ in rows})
            fshow = ", ".join(folders[:3]) + (" ..." if len(folders) > 3 else "")
            print(f"  {len(rows):>3}x  {polu:<24} [{bucket}]  {fshow}")
        print()

    if "--write" in sys.argv:
        EXCLUDE.write_text(
            json.dumps(sorted(exclude_ids), indent=1), encoding="utf-8")
        print(f"wrote {len(exclude_ids)} ids -> {EXCLUDE}")
    else:
        print(f"(dry run -- pass --write to emit {EXCLUDE.name} for gen_disable_sql.py)")


if __name__ == "__main__":
    main()
