#!/usr/bin/env python3
"""Audit every BST jug pet for missing / dead Ready-move (mob skill) scripts.

A jug pet's Ready moves come from its mob pool's skill list:

    pet_list (petid -> poolid)
      -> mob_pools (poolid -> skill_list_id)
        -> mob_skill_lists (skill_list_id -> [mob_skill_id ...])
          -> mob_skills (mob_skill_id -> mob_skill_name, mob_anim_id)
            -> scripts/actions/mobskills/<mob_skill_name>.lua

When a pet fires a Ready move (useMobAbility), luautils::OnMobWeaponSkill looks
up xi.actions.mobskills[<name>].onMobWeaponSkill. If that script does not exist
it returns 0 -- the move animates but does ZERO damage / no effect. This audit
flags three failure classes for jug pets (petid >= 21):

  (B) NAMED skill in mob_skills but NO script file  -> dead move, codeable
  (A) DANGLING skill id (in a list, not in mob_skills) -> deleted by
      fix_dangling_mob_skills.sql; cannot be scripted without defining it first
  (Z) pet has skill_list_id == 0 or an empty list      -> no Ready moves at all

Pure stdlib; reads the repo SQL (the canonical, deployed source). Run:
    python tools/audit_jugpet_skills.py
"""
from __future__ import annotations

import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
SQL = ROOT / "sql"
MOBSKILL_DIR = ROOT / "scripts" / "actions" / "mobskills"

JUG_MIN = 21  # petid 0-7 spirits, 8-20 SMN avatars, 21+ jug pets


def _tokenize_value_tuples(payload: str):
    """Yield one list-of-strings per (...) tuple in a VALUES payload.

    Quote- and paren-aware so it survives the binary 0x.. modelid blob, quoted
    names with embedded commas, and multi-row INSERTs."""
    rows, cur, buf = [], [], []
    depth, in_str = 0, False
    i, n = 0, len(payload)
    while i < n:
        c = payload[i]
        if in_str:
            if c == "\\" and i + 1 < n:
                buf.append(payload[i + 1]); i += 2; continue
            if c == "'":
                if i + 1 < n and payload[i + 1] == "'":
                    buf.append("'"); i += 2; continue
                in_str = False; i += 1; continue
            buf.append(c); i += 1; continue
        if c == "'":
            in_str = True; i += 1; continue
        if c == "(":
            depth += 1
            if depth == 1:
                cur, buf = [], []
                i += 1; continue
        if c == ")":
            depth -= 1
            if depth == 0:
                cur.append("".join(buf).strip()); buf = []
                rows.append(cur)
            i += 1; continue
        if c == "," and depth == 1:
            cur.append("".join(buf).strip()); buf = []; i += 1; continue
        if depth >= 1:
            buf.append(c)
        i += 1
    return rows


def inserts(filename: str, table: str):
    raw = (SQL / filename).read_text(encoding="utf-8", errors="replace")
    # Drop full-line SQL comments -- some are commented-out INSERTs (and a few
    # lack a trailing ';', which would make a non-greedy match run past them).
    text = "\n".join(ln for ln in raw.splitlines() if not ln.lstrip().startswith("--"))
    for m in re.finditer(
        r"INSERT INTO `%s`\s*(?:\([^)]*\))?\s*VALUES\s*(.*?);" % re.escape(table),
        text, re.DOTALL,
    ):
        yield from _tokenize_value_tuples(m.group(1))


def unq(tok: str) -> str:
    return tok.strip().strip("'")


# --- parse the four tables ------------------------------------------------
# pet_list: petid, name, poolid, minLevel, maxLevel, time, element, damageType
jugpets = {}
for r in inserts("pet_list.sql", "pet_list"):
    petid = int(r[0])
    if petid >= JUG_MIN:
        jugpets[petid] = {"name": unq(r[1]), "poolid": int(r[2]),
                          "minLevel": int(r[3]), "maxLevel": int(r[4])}

# mob_pools: skill_list_id is column index 24
pool_skilllist = {}
pool_name = {}
for r in inserts("mob_pools.sql", "mob_pools"):
    pool_skilllist[int(r[0])] = int(r[24])
    pool_name[int(r[0])] = unq(r[1])

# mob_skill_lists: skill_list_name, skill_list_id, mob_skill_id
list_skills = {}
list_name = {}
for r in inserts("mob_skill_lists.sql", "mob_skill_lists"):
    sid, mid = int(r[1]), int(r[2])
    list_skills.setdefault(sid, set()).add(mid)
    list_name[sid] = unq(r[0])

# Merge additive Ready-move wiring from modules/custom/sql/*.sql (e.g.
# jugpet_ready_moves.sql) so the audit reflects the deployed state, not just
# the base dump. Supports INSERT [IGNORE] INTO `mob_skill_lists` ... VALUES ...
CUSTOM = ROOT / "modules" / "custom" / "sql"
for f in sorted(CUSTOM.glob("*.sql")):
    raw = f.read_text(encoding="utf-8", errors="replace")
    txt = "\n".join(ln for ln in raw.splitlines() if not ln.lstrip().startswith("--"))
    for m in re.finditer(
        r"INSERT(?:\s+IGNORE)?\s+INTO\s+`mob_skill_lists`\s*(?:\([^)]*\))?\s*VALUES\s*(.*?);",
        txt, re.DOTALL | re.IGNORECASE,
    ):
        for r in _tokenize_value_tuples(m.group(1)):
            if len(r) >= 3 and r[1].isdigit() and r[2].isdigit():
                list_skills.setdefault(int(r[1]), set()).add(int(r[2]))
                list_name.setdefault(int(r[1]), unq(r[0]))

# mob_skills: mob_skill_id, mob_anim_id, mob_skill_name, ...
skill_name = {}
skill_anim = {}
for r in inserts("mob_skills.sql", "mob_skills"):
    skill_name[int(r[0])] = unq(r[2])
    skill_anim[int(r[0])] = int(r[1])

have_script = {p.stem for p in MOBSKILL_DIR.glob("*.lua")}

# --- join & classify ------------------------------------------------------
missing_named = {}   # skill_name -> {"id","anim","pets":set()}
dangling = {}        # skill_id   -> set(pets)
no_list = []         # (petid, name)
per_pet = {}

for petid, info in sorted(jugpets.items()):
    sid = pool_skilllist.get(info["poolid"], 0)
    skills = sorted(list_skills.get(sid, set()))
    rows = []
    if sid == 0 or not skills:
        no_list.append((petid, info["name"]))
    for mid in skills:
        nm = skill_name.get(mid)
        if nm is None:
            dangling.setdefault(mid, set()).add(petid)
            rows.append((mid, "<DANGLING>", False))
            continue
        ok = nm in have_script
        rows.append((mid, nm, ok))
        if not ok:
            e = missing_named.setdefault(nm, {"id": mid, "anim": skill_anim.get(mid), "pets": set()})
            e["pets"].add(petid)
    per_pet[petid] = {"sid": sid, "lname": list_name.get(sid, "-"), "rows": rows,
                      "name": info["name"], "maxLevel": info["maxLevel"]}

# Self-buff / SP / job-ability "Ready" moves -- working, but they do NO damage,
# so a pet whose only working move is one of these cannot DD on auto-ready.
BUFF_SET = {
    "perfect_dodge", "invincible", "blood_weapon", "soul_voice", "sentinel",
    "charm", "meikyo_shisui", "mijin_gakure", "bubble_armor", "promyvion_barrier",
    "howl", "boost", "focus", "dodge", "chakra", "hide", "counterstance_2",
    "berserk", "defender", "aggressor", "last_resort", "souleater", "sharpshot",
    "camouflage", "barrage", "familiar", "call_wyvern", "astral_flow", "evasion",
    "stasis", "mighty_strikes", "hundred_fists", "manafont", "chainspell",
    "benediction", "perfect_defense", "spirit_link",
}

# --- group jug pets by their family skill list ----------------------------
families = {}  # sid -> {"lname","pets":[(petid,name,maxLv)],"rows":[(id,name,ok)]}
for petid, d in per_pet.items():
    fam = families.setdefault(d["sid"], {"lname": d["lname"], "pets": [], "rows": d["rows"]})
    fam["pets"].append((petid, d["name"], d["maxLevel"]))


def classify(rows):
    working = [(mid, nm) for mid, nm, ok in rows if ok]
    offensive = [nm for _, nm in working if nm not in BUFF_SET]
    if not working:
        return "NONE", working, offensive
    if not offensive:
        return "BUFFS-ONLY", working, offensive
    return "OK", working, offensive


order = {"NONE": 0, "BUFFS-ONLY": 1, "OK": 2}
rep = []
for sid, fam in families.items():
    verdict, working, offensive = classify(fam["rows"])
    rep.append((order[verdict], verdict, sid, fam, working, offensive))
rep.sort(key=lambda x: (x[0], -len(x[3]["pets"])))

# --- report ---------------------------------------------------------------
print(f"Jug pets audited (petid >= {JUG_MIN}): {len(jugpets)}   families: {len(families)}")
print(f"Existing mob skill scripts: {len(have_script)}")
counts = {"NONE": 0, "BUFFS-ONLY": 0, "OK": 0}
for _, v, _, fam, _, _ in rep:
    counts[v] += 1
print(f"Family verdicts -> OK: {counts['OK']}   BUFFS-ONLY: {counts['BUFFS-ONLY']}   "
      f"NONE: {counts['NONE']}\n")

label = {
    "NONE": ">>> NONE      (no working Ready move at all -- pet does nothing)",
    "BUFFS-ONLY": ">>  BUFFS-ONLY (only self-buffs work -- no damaging Ready move)",
    "OK": "OK         (has >=1 working offensive Ready move)",
}
last = None
for _, verdict, sid, fam, working, offensive in rep:
    if verdict != last:
        print("=" * 78)
        print(label[verdict])
        print("=" * 78)
        last = verdict
    pets = ", ".join(n for _, n, _ in fam["pets"])
    work_str = ", ".join(nm for _, nm in working) or "-"
    off_str = ", ".join(offensive) or "-"
    dead = [mid for mid, _, ok in fam["rows"] if not ok]
    print(f"\n  list {sid} '{fam['lname']}'  ({len(fam['pets'])} pets)")
    print(f"    pets    : {pets}")
    print(f"    working : {work_str}")
    if verdict != "OK":
        print(f"    OFFENSE : {off_str}")
    if dead:
        print(f"    dead ids: {dead}")

# Non-BST pets flagged separately (named-but-no-script: automaton/wyvern)
if missing_named:
    print("\n" + "=" * 78)
    print("NAMED moves with no script (note: these belong to NON-jug pets)")
    print("=" * 78)
    for nm, e in sorted(missing_named.items()):
        pets = ", ".join(jugpets[p]["name"] for p in sorted(e["pets"]))
        print(f"  {nm:<22} id={e['id']:<5} anim={e['anim']:<5} -> {pets}")
