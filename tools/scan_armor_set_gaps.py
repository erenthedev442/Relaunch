#!/usr/bin/env python3
"""Scan curated gear vendors for armor SETS missing pieces; name the fill-in item.

Vendors scanned: Armor NPC (armor_catalog.lua, bronze/silver/gold tiers) + the
Infamy Vendor (infamy_vendor_catalog.lua). The 5 set slots are head / body /
hands / legs / feet (shields and accessories are not "set" slots here).

Set root = display name with a trailing "+N" stripped and the final (slot) word
dropped, with the two-word "Finger Gauntlets" hands slot collapsed to one word
so "Fallens Finger Gauntlets +4" -> "fallens" (not "fallens finger"). Sets are
aggregated across tiers and vendors (a set split Armor-NPC + Infamy still counts
as one).

For each set missing 1-2 slots, item_equipment is searched for any real item
sharing the set's first word in the missing slot, and the script flags whether
that piece is (a) already on a vendor -- a grouping artifact, set is really whole
-- or (b) sittable in the DB but unsold -- a TRUE gap you can fill, with the id.
"""
from __future__ import annotations
import os, re
from collections import defaultdict

REPO       = os.path.normpath(os.path.join(os.path.dirname(__file__), ".."))
ARMOR_CAT  = os.path.join(REPO, "modules", "custom", "lua", "armor_catalog.lua")
INFAMY_CAT = os.path.join(REPO, "modules", "custom", "lua", "infamy_vendor_catalog.lua")
ITEM_EQUIP = os.path.join(REPO, "sql", "item_equipment.sql")

ARMOR_SLOTS    = ["head", "body", "hands", "legs", "feet"]
SLOT_BIT       = {16: "head", 32: "body", 64: "hands", 128: "legs", 256: "feet"}
TWO_WORD_TAILS = ("finger gauntlets", "toe shoes")


def norm(name):
    n = name.lower().replace("_", " ").strip()
    return re.sub(r"\s*\+\s*\d+\s*$", "", n)

def set_root(name):
    n = norm(name)
    for t in TWO_WORD_TAILS:
        if n.endswith(t):
            return n[:-len(t)].strip()
    p = n.split()
    return n if len(p) <= 1 else " ".join(p[:-1])

def first_word(name):
    p = norm(name).split()
    return p[0] if p else ""


def load_equip():
    """id -> (internal_name, slot_name) for the 5 armor slots."""
    d = {}
    for line in open(ITEM_EQUIP, encoding="utf-8", errors="ignore"):
        if "`item_equipment`" not in line or "VALUES" not in line:
            continue
        s = line[line.find("VALUES (") + 8:]
        s = s[:s.rfind(")")]
        p = [x.strip().strip("'") for x in s.split(",")]
        try:
            iid, name, slot = int(p[0]), p[1], int(p[8])
        except (ValueError, IndexError):
            continue
        for bit, nm in SLOT_BIT.items():
            if slot & bit:
                d[iid] = (name, nm)
                break
    return d


def parse_armor_catalog():
    out, skipped = [], 0
    alias_tier, cur = {}, None
    item_re  = re.compile(r"table\.insert\(\s*(\w+)\.(head|body|hands|legs|feet|shields)\s*,\s*\{\s*id\s*=\s*(\d+)\s*,\s*name\s*=\s*[\"']([^\"']+)[\"']")
    const_re = re.compile(r"table\.insert\(\s*\w+\.\w+\s*,\s*\{\s*id\s*=\s*xi\.item\.")
    for line in open(ARMOR_CAT, encoding="utf-8", errors="ignore"):
        a = re.search(r"local\s+(\w+)\s*=\s*catalog\.(bronze|silver|gold)\b", line)
        if a:
            alias_tier[a.group(1)] = a.group(2); cur = a.group(2); continue
        m = item_re.search(line)
        if m:
            alias, slot, iid, name = m.group(1), m.group(2), int(m.group(3)), m.group(4)
            if slot != "shields":
                out.append((iid, name, slot, "Armor NPC", alias_tier.get(alias, cur or "?")))
        elif const_re.search(line):
            skipped += 1
    return out, skipped


def parse_infamy_catalog(equip):
    out = []
    txt = open(INFAMY_CAT, encoding="utf-8", errors="ignore").read()
    for m in re.finditer(r"\{\s*id\s*=\s*(\d+)\s*,\s*name\s*=\s*[\"']([^\"']+)[\"']", txt):
        iid, name = int(m.group(1)), m.group(2)
        info = equip.get(iid)
        if info and info[1] in ARMOR_SLOTS:
            out.append((iid, name, info[1], "Infamy Vendor", "-"))
    return out


def main():
    equip = load_equip()
    arm, skipped = parse_armor_catalog()
    inf = parse_infamy_catalog(equip)
    rows = arm + inf
    vendor_ids = {r[0] for r in rows}

    db_idx = defaultdict(list)                 # (first_word, slot) -> [(id, name)]
    for iid, (name, slot) in equip.items():
        db_idx[(first_word(name), slot)].append((iid, name))

    sets = defaultdict(lambda: defaultdict(list))
    seen = set()
    for iid, name, slot, vendor, tier in rows:
        k = (set_root(name), slot, iid)
        if k in seen:
            continue
        seen.add(k)
        sets[set_root(name)][slot].append((name, vendor, tier, iid))

    by_count = defaultdict(list)
    for root, slots in sets.items():
        present = [s for s in ARMOR_SLOTS if s in slots]
        by_count[len(present)].append((root, slots))

    def slot_line(slots, s):
        if s in slots:
            ps = "; ".join(f"{nm}{' /'+ti if ti not in ('-','?') else ''}"
                           for nm, _, ti, _ in sorted(slots[s]))
            return f"      {s:5}: {ps}"
        return f"      {s:5}: --- MISSING"

    def suggest(root, s):
        cands = db_idx.get((root.split()[0], s), [])
        tight = [(i, n) for i, n in cands if set_root(n) == root]
        use = tight or cands
        if not use:
            return "             (no such piece exists in the item DB)"
        sold = sorted({n for i, n in use if i in vendor_ids})
        if sold:
            return f"             !! actually SOLD as {', '.join(sold)} -- set is really complete (grouping split)"
        unsold = sorted({(n, i) for i, n in use})
        shown = ", ".join(f"{n} [{i}]" for n, i in unsold[:5])
        return f"             -> fill with: {shown}"

    print("=" * 80)
    print("ARMOR SET COMPLETENESS  --  Armor NPC (bronze/silver/gold) + Infamy Vendor")
    print("=" * 80)
    print(f"armor pieces scanned : {len(rows)}  ({len(arm)} Armor NPC + {len(inf)} Infamy)")
    if skipped:
        print(f"  !! {skipped} Armor-NPC rows used xi.item.* constants (skipped)")
    print(f"distinct sets        : {len(sets)}")
    for c in (5, 4, 3, 2, 1):
        lbl = {5: 'complete (5/5)', 4: 'missing 1 (4/5)', 3: 'missing 2 (3/5)',
               2: 'missing 3 (2/5)', 1: 'lone piece (1/5)'}[c]
        print(f"  {lbl:18}: {len(by_count[c])}")
    print()

    for cnt in (4, 3):
        groups = sorted(by_count[cnt], key=lambda x: x[0])
        print("#" * 80)
        print(f"#  {cnt}/5 SETS  --  missing {5 - cnt} piece(s)   ({len(groups)} sets)")
        print("#" * 80)
        for root, slots in groups:
            missing = [s for s in ARMOR_SLOTS if s not in slots]
            print(f"\n{root.title()}   << missing: {', '.join(m.upper() for m in missing)} >>")
            for s in ARMOR_SLOTS:
                print(slot_line(slots, s))
                if s in missing:
                    print(suggest(root, s))
        print()

    if by_count[2]:
        print("#" * 80)
        print(f"#  2/5 SETS  ({len(by_count[2])} sets -- summary only)")
        print("#" * 80)
        for root, slots in sorted(by_count[2]):
            present = [s for s in ARMOR_SLOTS if s in slots]
            print(f"  {root.title():24} has {'+'.join(present)}")
    print()
    print("complete sets:", ", ".join(r.title() for r, _ in sorted(by_count[5])))


if __name__ == "__main__":
    main()
