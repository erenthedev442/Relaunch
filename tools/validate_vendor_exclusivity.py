"""validate_vendor_exclusivity.py

Guard-rail for the medal vendor (Armor / Accessory / GearProgression NPCs).

Vendor placement is HUMAN-CURATED and decoupled from the gear scorer -- the scoring
model exists only to power the gear RECOMMENDATION tool ("what should I get to
maximize my character"), never to decide what the vendor sells. This checker enforces
the one hard rule that remains on the curated catalogs:

    the bronze/silver/gold tiers may only sell gear that is EXCLUSIVE to the vendor
    -- nothing also obtainable from mob drops, crafting, or another custom-content /
    vendor / forge catalog.

Run it after editing any medal catalog:

    python tools/validate_vendor_exclusivity.py

Exit 0 = clean. Exit 1 = at least one bronze/silver/gold item is obtainable elsewhere
(the offenders are listed with WHERE they leak from). The Infamy tier is a separate
vendor and is exempt, so everything from the "-- INFAMY TIER" header down is skipped.
"""
from __future__ import annotations
import re
import sys
from pathlib import Path

ROOT  = Path(__file__).resolve().parents[1]
SQL   = ROOT / "sql"
LUA   = ROOT / "modules" / "custom" / "lua"
MEDAL = ["armor_catalog.lua", "accessory_catalog.lua", "gear_progression_catalog.lua"]


# ---- SQL/Lua parsing (mirrors gen_vendor_exclusions.py, but keeps per-source) ----
def _rows(path: Path, table: str):
    pat = re.compile(rf"INSERT INTO `{table}` VALUES \((.*)\);")
    for line in path.read_text(encoding="utf-8", errors="replace").splitlines():
        m = pat.search(line)
        if m:
            yield m.group(1)


def _fields(blob: str):
    out, buf, q = [], [], False
    for ch in blob:
        if ch == "'":
            q = not q; buf.append(ch)
        elif ch == "," and not q:
            out.append("".join(buf).strip()); buf = []
        else:
            buf.append(ch)
    out.append("".join(buf).strip())
    return out


# real ilvl>=119 equipment -- the only thing the vendor deals in
gear: set[int] = set()
for blob in _rows(SQL / "item_equipment.sql", "item_equipment"):
    f = _fields(blob)
    if len(f) > 3 and f[0].isdigit() and f[3].isdigit() and int(f[3]) >= 119:
        gear.add(int(f[0]))

# id -> set of human-readable "obtainable here" sources (restricted to real gear)
source: dict[int, set[str]] = {}
def _add(i: int, label: str):
    if i in gear:
        source.setdefault(i, set()).add(label)

for blob in _rows(SQL / "mob_droplist.sql", "mob_droplist"):
    f = _fields(blob)
    if len(f) > 4 and f[4].isdigit():
        _add(int(f[4]), "mob drop")

for blob in _rows(SQL / "synth_recipes.sql", "synth_recipes"):
    f = _fields(blob)
    for v in f[-10:-6]:                      # result + HQ1..3
        if v.isdigit() and int(v) > 0:
            _add(int(v), "crafting")

_idpat = re.compile(r"\bid\s*=\s*(\d{4,5})")
for p in sorted(LUA.glob("*catalog*.lua")):
    if p.name in MEDAL:
        continue
    for m in _idpat.finditer(p.read_text(encoding="utf-8", errors="replace")):
        _add(int(m.group(1)), p.stem)

# Prime Armory weapons are forge-only earned rewards -- every upgrade stage id, keyed by
# the shared item_basic name (a Prime weapon like Mpu Gandring spans several ids). They
# are NOT a *catalog*.lua source, so add them explicitly (bypassing the ilvl gate).
_PRIME_FAMS = {"caliburnus", "dokoku", "earp", "foenaria", "gae_buide", "helheim",
               "kusanagi-no-tsurugi", "laphria", "lorg_mor", "loughnashade", "mpu_gandring",
               "naegling", "opashoro", "pinaka", "spalirisos", "varga_purnikawa"}
for line in (SQL / "item_basic.sql").read_text(encoding="utf-8", errors="replace").splitlines():
    m = re.match(r"INSERT INTO `item_basic` VALUES \((\d+),[^,]*,'([^']*)'", line)
    if m and (m.group(2) in _PRIME_FAMS or m.group(2).startswith("prime_")):
        source.setdefault(int(m.group(1)), set()).add("Prime Armory (forge-only)")

# Ambuscade weapons (every stage of the Tokko->Ajja->Eletta->Kaja->Final chains) are
# EARNED from Ambuscade (Hallmark base + upgrades, scripts/globals/ambuscade.lua) and
# scrubbed from the medal vendor at runtime -- flag any that leak back into a medal tier.
_ambu = LUA / "ambuscade_weapons_catalog.lua"
if _ambu.exists():
    for m in re.finditer(r"stages\s*=\s*\{([^}]*)\}", _ambu.read_text(encoding="utf-8", errors="replace")):
        for x in re.findall(r"\d+", m.group(1)):
            source.setdefault(int(x), set()).add("Ambuscade (earned)")


# ---- read each medal catalog's bronze/silver/gold segment (Infamy excluded) ----
_INFAMY = re.compile(r"--+\s*INFAMY TIER", re.IGNORECASE)
_pair   = re.compile(r"id\s*=\s*(\d{4,5})[^}]*?name\s*=\s*[\"']([^\"']+)[\"']")

def _bsg_segment(text: str) -> str:
    m = _INFAMY.search(text)
    return text[:m.start()] if m else text


violations: list[tuple[str, int, str, str]] = []   # (catalog, id, name, sources)
for cat in MEDAL:
    path = LUA / cat
    if not path.exists():
        continue
    seg   = _bsg_segment(path.read_text(encoding="utf-8", errors="replace"))
    names = {int(m.group(1)): m.group(2) for m in _pair.finditer(seg)}
    ids   = {int(m.group(1)) for m in _idpat.finditer(seg)}
    for i in sorted(ids & source.keys()):
        violations.append((cat, i, names.get(i, "?"), ", ".join(sorted(source[i]))))


if not violations:
    print("OK  -- every bronze/silver/gold item is exclusive to the medal vendor.")
    sys.exit(0)

print(f"FAIL -- {len(violations)} bronze/silver/gold item(s) are obtainable elsewhere:\n")
namew = max(len(v[2]) for v in violations)
cur = None
for cat, i, nm, src in violations:
    if cat != cur:
        print(f"  {cat}:")
        cur = cat
    print(f"    {i:<6} {nm:<{namew}}   leaks from: {src}")
print("\nFix: remove each from bronze/silver/gold, or move it to the Infamy tier (exempt).")
sys.exit(1)
