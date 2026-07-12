"""Regenerate the portal's static data files.

  python data/regen.py            # run from tools/player_portal/

Rebuilds:
  data/mod_names.json        modId -> readable stat label (from sql/item_mods.sql
                             row comments). Used by the gear set builder.
  data/augment_catalog.json  the relaunch augment catalog (catalyst -> augment,
                             value ranges) for the augment planner. Enriched with
                             catalyst item names/images from data/item_thumbs.json.

Point AUGMENT_LUA / ITEMMODS_SQL at your local trees. Safe to re-run.
"""
import json
import os
import re

HERE = os.path.dirname(os.path.abspath(__file__))
# The portal lives at <repo>/tools/player_portal/ inside the Relaunch repo, so
# both sources resolve repo-relative by default; env vars override for odd trees.
REPO = os.path.abspath(os.path.join(HERE, "..", "..", ".."))
ITEMMODS_SQL = os.environ.get("ITEMMODS_SQL", os.path.join(REPO, "sql", "item_mods.sql"))
AUGMENT_LUA = os.environ.get(
    "AUGMENT_LUA",
    os.path.join(REPO, "modules", "custom", "lua", "augment_catalog.lua"))

CATS = {1: "Base Stats", 2: "Melee", 3: "Magic", 4: "Defense", 5: "Delays", 6: "Duration",
        7: "Pets", 8: "Potency", 9: "Skills", 10: "Exp / Cap Points", 11: "Job Utilities"}


def gen_mod_names():
    rx = re.compile(r"VALUES\s*\(\s*\d+\s*,\s*(\d+)\s*,\s*-?\d+\s*\)\s*;\s*--\s*([^:]+):")
    names = {}
    with open(ITEMMODS_SQL, encoding="utf-8", errors="replace") as f:
        for line in f:
            m = rx.search(line)
            if m:
                names.setdefault(int(m.group(1)), m.group(2).strip())
    out = {str(k): v for k, v in sorted(names.items())}
    json.dump(out, open(os.path.join(HERE, "mod_names.json"), "w"), indent=0)
    print(f"mod_names.json: {len(out)} mods")


def gen_augments():
    thumbs = json.load(open(os.path.join(HERE, "item_thumbs.json"), encoding="utf-8"))
    # base/mult/disp may be floats (Haste disp=10.24); maxBoost is optional and
    # MUST be honored -- the engine scales the 0-31 roll into [0, maxBoost]
    # (Augment_Moogle.lua scaleRoll), so an uncapped min/max here overstates
    # every capped augment (pre-2026-07-11 versions of this file did exactly that).
    rx = re.compile(
        r"\[(\d+)\]\s*=\s*\{\s*augId\s*=\s*(\d+),\s*base\s*=\s*([\d.]+),\s*mult\s*=\s*([\d.]+),"
        r"\s*disp\s*=\s*([\d.]+),\s*cat\s*=\s*(\d+),\s*tier\s*=\s*(\d+),\s*label\s*=\s*'([^']*)'"
        r"(?:\s*,\s*maxBoost\s*=\s*(\d+))?")
    entries = []
    for m in rx.finditer(open(AUGMENT_LUA, encoding="utf-8").read()):
        iid, aug, base, mult, disp, cat, _tier, label, maxb = m.groups()
        iid, cat = int(iid), int(cat)
        base, mult, disp = float(base), float(mult), float(disp)
        cap = min(31, int(maxb)) if maxb is not None else 31
        t = thumbs.get(str(iid), {})

        def val(boost):
            v = (base + boost) * mult / disp
            return int(v + 0.5)  # engine: floor(x + 0.5)
        def num(x):
            return int(x) if float(x).is_integer() else x
        entries.append({"itemId": iid, "augId": int(aug), "label": label, "cat": cat,
                        "catName": CATS.get(cat, "Other"),
                        "base": num(base), "mult": num(mult), "disp": num(disp),
                        "maxBoost": cap,
                        "item": t.get("n") or f"item {iid}", "img": t.get("img"),
                        "min": val(0), "max": val(cap)})
    entries.sort(key=lambda e: (e["cat"], e["label"]))
    json.dump({"cats": CATS,
               "formula": "(base + round(roll*maxBoost/31)) * mult / disp, roll 0-31",
               "count": len(entries), "augments": entries},
              open(os.path.join(HERE, "augment_catalog.json"), "w"), indent=0)
    print(f"augment_catalog.json: {len(entries)} augments")


if __name__ == "__main__":
    gen_mod_names()
    gen_augments()
