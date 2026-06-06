#!/usr/bin/env python3
"""Generate augment_catalog.lua with strict thematic+obtainable matching.

This is the canonical generator. It combines:

  1. Thematic categorization (STR augs -> fiery items, MP augs -> dark items, ...).
  2. Obtainability filter -- catalyst MUST be in `mob_droplist` (mob drops only).
     Crafted, fished, guild-shop, gardened, and synergy items are NOT eligible:
     the augment NPC trades in monster materials only.
  3. No-food rule -- @USABLE_TYPE is excluded outright (catches food, drinks,
     papillion, mandragora buds, weather cells, and other consumables), and the
     food AH categories (@FISH .. @INGREDIENTS) are excluded as a safety net.
  4. Crafting-kit exclusion -- any item whose short_name contains 'kit' is
     dropped from the catalyst pool (leather/smith/cloth crafting kits etc).
  5. Equippable / scroll / automaton / furnishing / medicine / currency
     exclusions on the AH category and item-type axes.
  6. Item-id floor (>= 768, start of gems/materials block) and reserved
     crystal/cluster range (4096-4111).

For each augment, the eligible pool is SCORED against the augment's category
keywords. The highest-scoring unused item wins. If no item scores > 0 against
the augment's category, the augment is DROPPED -- no non-thematic fallback.
"""
import re
from pathlib import Path

ROOT = Path(r"D:/server")
SQL = ROOT / "sql"
AUG_SQL = SQL / "augments.sql"
ITEM_SQL = SQL / "item_basic.sql"
OUT_LUA = ROOT / "modules" / "custom" / "lua" / "augment_catalog.lua"

MOB_DROPLIST = SQL / "mob_droplist.sql"

# Reserved IDs used as crystals/clusters per scripts/enum/item.lua.
RESERVED = set(range(4096, 4112))
# Floor at the gems/materials block (item 768 = flint_stone). Beds/furniture
# below this are caught by @FURNISHING_TYPE, but the floor saves a lot of
# lookups and rules out the test/placeholder rows.
MIN_ITEM_ID = 768

# AH categories to exclude from catalyst pool.
# The @FISH .. @INGREDIENTS block (51-59) is "Food->*". @USABLE_TYPE catches
# most of these anyway, but the AH cat filter also catches @GENERAL_TYPE items
# that happen to be filed under Food (rare but possible).
EXCLUDED_AH = {
    "@MEDICINES",
    "@SONGS",
    "@AUTOMATON",
    "@FURNISHINGS",
    "@INVALID",
    "@CURSED_ITEMS",
    "@WHITE_MAGIC",
    "@BLACK_MAGIC",
    "@SUMMONING",
    "@NINJUTSU",
    "@GEOMANCER",
    # Food categories (Food->Fish/Meals/Ingredients):
    "@FISH",
    "@MEAT_EGGS",
    "@SEAFOOD",
    "@VEGETABLES",
    "@SOUPS",
    "@BREADS_RICE",
    "@SWEETS",
    "@DRINKS",
    "@INGREDIENTS",
}

EXCLUDED_TYPE = {
    "@EQUIPMENT_TYPE", "@WEAPON_TYPE",
    "@LINKSHELL_TYPE", "@FURNISHING_TYPE", "@PUPPET_TYPE",
    "@CURRENCY_TYPE",
    # @USABLE_TYPE = food/drink/consumable. The user wants catalysts to be
    # mob-drop materials, not consumables, so block this type wholesale.
    # This catches papillion (@ALCHEMY_2 AH but @USABLE_TYPE), buds, cells,
    # and the entire Food->Meals block in one shot.
    "@USABLE_TYPE",
}

GOOD_WHEN_NEGATIVE = (
    "enmity", "dmg.taken", "dmg taken", "damage taken",
    "interruption", "interrupt", "intr.rate",
    "weight", "slow", "pdt", "mdt",
)

# =========================================================================
# Thematic categories. Each entry: (name, label_patterns, item_keywords).
# The keyword pool is what we SCORE against (not just first-match). Each
# keyword contributes 1 point per appearance in the short_name.
# =========================================================================
CATEGORIES = [
    (
        "Strength / Attack / Phys.dmg.taken",
        [
            r"\bstr\s*[+-]",
            r"\battack\s*[+-]", r"\batk\s*[+-]",
            r"rng\.?\s*atk", r"ranged\s*atk", r"ranged\s*attack",
            r"phys\.?\s*dmg\.?\s*taken", r"phys\s*dmg\s*taken",
            r"\bpdt[+-]", r"\bpdt\b",
            r"\bdamage\s*taken", r"\bdmg\s*taken",
            r"dbl\.?\s*at[tk]", r"double\s*at[tk]",
            r"triple\s*at[tk]", r"\bcounter\s*[+-]",
            r"dual\s*wield", r"martial\s*arts", r"kick\s*attacks?",
            r"\bzanshin", r"\bdaken\b", r"\bbarrage\b",
            r"conserve\s*tp", r"\bsave\s*tp", r"\btp\s*bonus",
            r"reverse\s*flourish", r"\bsneak\s*at[tk]",
            r"physical\s*damage\s*limit",
        ],
        # Themed at predator/melee monsters and fiery materials. All keywords
        # must match short_names of items in mob_droplist (no foods).
        ["fire", "flame", "ruby", "bismuth", "molten",
         "tusk", "fang", "claw", "talon", "horn", "tooth",
         "hide", "pelt", "fur", "tail",
         "raptor", "drake", "behemoth", "manticore",
         "bugard", "lion", "tiger", "wolf", "buffalo_horn",
         "bone_chip", "giant_bird_feather", "war"],
    ),
    (
        "Dexterity / Accuracy / Crit",
        [
            r"\bdex\s*[+-]",
            r"accuracy", r"rng\.?\s*acc", r"ranged\s*acc",
            r"crit\.?\s*hit\s*rate", r"crit\s*rate", r"critical\s*hit",
            r"crit\.?\s*hit\s*damage", r"crit\s*damage",
            r"\brapid\s*shot", r"\bstore\s*tp",
            r"\bsubtle\s*blow",
        ],
        # Wind-themed, agile/avian/ranged materials.
        ["wind", "peridot", "feather", "quill", "wing",
         "eagle", "hawk", "falcon", "sparrow", "swallow",
         "crow", "raven", "puk", "cockatrice",
         "arrow", "bolt", "eye", "vulture"],
    ),
    (
        "Vitality / Defense / Stoneskin",
        [
            r"\bvit\s*[+-]", r"\bdef\s*[+-]", r"stoneskin",
            r"mag\.?\s*def\.?\s*bns", r"magic\s*def",
            r"\bmagic\s*dmg\.?\s*taken", r"\bbreath\s*dmg\.?\s*taken",
            r"shield\s*mastery", r"chance\s*of\s*successful\s*block",
            r"phalanx\s*received", r"parrying\s*rate",
        ],
        # Earth-themed sturdy/armored mob materials. Pure ores/ingots/lumber
        # are CRAFTED so we lean on monster-derived sturdy parts: shells,
        # plates, scales, bones, carapaces.
        ["earth", "terra", "topaz", "stone", "rock",
         "shell", "carapace", "plate", "scale",
         "crab", "snail", "tortoise", "turtle",
         "armor_plate", "bone", "skull", "femur",
         "iron_ore", "iron_sand", "rock_salt",
         "boulder", "granite"],
    ),
    (
        "Agility / Evasion / Haste",
        [
            r"\bagi\s*[+-]", r"evasion", r"\bhaste",
            r"\bdelay\s*[:+-]", r"\bslow\s*[+-]",
            r"\bsnapshot", r"\brecycle\b",
            r"waltz\s*potency", r"waltz\s*tp\s*cost",
        ],
        # Lightning-themed swift creatures + threads/silk drops.
        ["thunder", "lightning", "chrysoberyl", "spark",
         "silk", "velvet", "thread", "cloth", "wool", "cotton",
         "linen", "rainbow", "saruta",
         "spider", "antlion", "mosquito", "wasp", "bee", "beehive",
         "wamoura", "raven", "skin",
         "fluorite", "wisp", "leaf", "whisker",
         "antican", "qiqirn", "yagudo",
         "pugil", "manta", "eft"],
    ),
    (
        "Intelligence / Magic offense",
        [
            r"\bint\s*[+-]",
            r"mag\.?\s*atk", r"mag\.?\s*acc",
            r"magic\s*damage", r"magic\s*atk", r"magic\s*acc",
            r"fast\s*cast", r"spell\s*interruption",
            r"elemental\s*magic\s*skill",
            r"magic\s*burst", r"mag\.?\s*crit\.?\s*hit",
            r"occult\s*acumen", r"\bdrain.*aspir",
            r"helix\s*effect", r"sword\s*enhancement\s*spell\s*damage",
            r"enhancing\s*magic\s*effect", r"meditate\s*effect",
        ],
        # Ice-themed and arcane mob drops: imp horns, mage parts, eyes.
        ["ice", "frost", "glacier", "sapphire", "mercury",
         "imp_wing", "imp_horn", "ahriman_lens",
         "evil_eye", "eye_of", "brain",
         "magic", "rune", "demon_horn", "demon_wing",
         "skull", "spirit", "cursed",
         "wivre", "magus"],
    ),
    (
        "Mind / Healing / Cure",
        [
            r"\bmnd\s*[+-]",
            r"mag\.?\s*evasion", r"magic\s*evasion",
            r"healing\s*magic", r"\bcure",
            r"\bmp\s*recovered", r"\bbreath\s*dmg\s*taken",
        ],
        # Water-themed and gentle/holy materials.
        ["water", "aqua", "aquamarine", "pearl", "coral",
         "seashell", "uragnite", "rafflesia",
         "tear", "essence", "phial", "drop_of",
         "moko_grass", "morion", "angelstone",
         "sage", "white_wool"],
    ),
    (
        "Charisma / Charm / Enmity",
        [
            r"\bchr\s*[+-]", r"charm", r"enmity",
            r"\ball\s*songs", r"\bsong\s*[+-]",
            r"treasure\s*hunter", r"gilfinder",
            r"song\s*spellcasting",
        ],
        # Light-themed, shiny/precious, and bright mob materials.
        ["light", "lumin", "diamond", "silver", "gold",
         "voucher", "kupon", "ribbon", "mane",
         "mythril", "platinum",
         "siren_shell", "succubus", "lilim",
         "venomous_claw", "demon_horn"],
    ),
    (
        "HP / Regen",
        [
            r"\bhp\s*[+-]", r"hp\s*recovered", r"\bregen",
        ],
        # Life-themed: vital organs, hides from large beasts, blood.
        ["dragon_blood", "behemoth", "dragon",
         "wyvern_skin", "wyvern_scale", "dragon_scale",
         "hide", "leather", "skin", "bone",
         "heart", "liver", "marrow", "tongue",
         "rarab_tail", "tonberry", "saliva"],
    ),
    (
        "MP / Refresh",
        [
            r"\bmp\s*[+-]", r"\brefresh",
        ],
        # Dark/arcane mob materials: bones, skulls, fiend/imp/demon parts.
        ["dark", "obsidian", "onyx", "shadow",
         "vampire", "doomed", "tomb", "tomb_mold",
         "skeleton_bone", "skeleton_skull", "cold_bone",
         "imp_horn", "ahriman", "demon_horn", "demon_wing",
         "ghost", "shade", "wraith", "specter",
         "azure", "ebon", "midnight",
         "moss", "mold", "yagudo_feather",
         "forgotten", "morbol", "tonberry"],
    ),
    (
        "Pet",
        [
            r"pet\s*:",
            r"avatar\s*[:.]", r"avatar\s*perpetuation",
            r"blood\s*boon", r"elemental\s*siphon",
            r"\bsummon", r"thunder\s*affinity",
        ],
        # Pet/jug/familiar theme: nests, cocoons, raw materials from
        # creatures bst/smn naturally interact with.
        ["cocoon", "nest", "egg_of_",
         "mandragora", "lizard", "crawler", "worm",
         "puk_egg", "chocobo", "moogle",
         "carrot", "moth", "diremite", "leech",
         "tear", "fang", "claw_of"],
    ),
    (
        "Elemental resistance",
        [
            r"resist", r"\bfire\b", r"\bice\b", r"\bwind\b",
            r"\bearth\b", r"\blightning\b", r"\bwater\b",
            r"\blight\b", r"\bdark\b",
        ],
        # Elemental beasts, weather drops, and tarot-card drops (which the
        # FFXI db files under @CARDS and represent elemental affinities).
        ["elemental", "rune", "talisman", "amulet",
         "cluster", "core", "spirit", "ember",
         "djinn", "salamander", "ahriman_wing",
         "card", "cup", "sword", "wand", "coin", "tarot",
         "yggrete", "whiteshell", "jadeshell", "bronzepiece",
         "celadon", "zaffre", "vermilion", "ochre",
         "ace_of", "two_of", "three_of", "four_of", "five_of",
         "six_of", "seven_of", "eight_of", "nine_of", "ten_of"],
    ),
    (
        "Skill+",
        [
            r"skill\s*[+-]",
        ],
        # Skill-up themed: hide-tanning materials, polishing items, and
        # specialty drops associated with training (wax, oil, amber, resin).
        ["whetstone", "polish", "oil", "lacquer",
         "wax", "amber", "resin", "honey",
         "fish_scale", "puk_skin", "thrall",
         "moss", "vine", "root", "needle",
         "dryad", "treant", "morbol",
         "stinger", "venom", "jaw"],
    ),
    (
        "Weaponskill DMG+",
        [
            r":\s*dmg\s*\+", r"dmg\s*[:+]\s*[+-]?\d",
            r"\bdmg:[+-]\d", r"\bdmg:\+", r"\bdmg:-",
            r"rudra", r"last\s*stand", r"resolution",
            r"tachi\s*:", r"blade\s*:", r"ruinator",
            r"savage\s*blade", r"upheaval", r"requiescat", r"jishnu",
            r"victory\s*smite", r"\bws\s*:",
            r"weapon\s*skill", r"weaponskill",
            r"sklchn\.?\s*dmg",
        ],
        # Trophy/elite-mob materials + signature NM-tier drops. The pool here
        # has to be broad because WS DMG+ augments are the most numerous in
        # the augments table.
        ["alexandrite", "byne_bill",
         "skull", "femur", "talon", "tooth", "jaw",
         "shadescale", "shadowscale",
         "blood", "vial_of", "cell_of", "phial_of", "drop_of",
         "tinnin", "tiamat", "wyrm", "nidhogg",
         "horn_of", "fang_of", "claw_of",
         "stinger", "venom", "spike",
         "shell", "carapace", "armor_plate",
         "high-quality", "kings", "queens",
         "ancient", "archaic", "primal", "savage", "elder",
         "morbol", "tarasque", "lindwurm", "amemet",
         "gargantuan", "giant", "great", "elder",
         "scorpion", "antlion", "beetle",
         "behemoth", "manticore", "buffalo",
         "obi", "yggdrasil", "remi",
         "handful_of", "set_of", "chunk_of", "pile_of",
         "adamantoise", "fafnir"],
    ),
    (
        "Other",
        [],
        [],
    ),
]

CAT_NAMES = [c[0] for c in CATEGORIES]
CAT_LABEL_RES = [
    [re.compile(p, re.IGNORECASE) for p in patterns]
    for _name, patterns, _keys in CATEGORIES
]
CAT_KEYS = [keys for _name, _patterns, keys in CATEGORIES]
FALLBACK_INDEX = len(CATEGORIES) - 1


def categorize_label(label: str) -> int:
    for idx, regexes in enumerate(CAT_LABEL_RES):
        for rx in regexes:
            if rx.search(label):
                return idx
    return FALLBACK_INDEX


def score_item_for_category(short_name: str, cat_idx: int) -> int:
    """Score how well an item matches a category (count keyword hits)."""
    s = short_name.lower()
    score = 0
    for k in CAT_KEYS[cat_idx]:
        if k in s:
            score += 1
    return score


# =========================================================================
# Generic SQL VALUES splitter (handles quoted strings + escaped '').
# =========================================================================
def split_fields(payload: str) -> list[str]:
    parts = []
    in_q = False
    buf: list[str] = []
    i = 0
    while i < len(payload):
        ch = payload[i]
        if ch == "'":
            if in_q and i + 1 < len(payload) and payload[i + 1] == "'":
                buf.append("''")
                i += 2
                continue
            in_q = not in_q
            buf.append(ch)
        elif ch == "," and not in_q:
            parts.append("".join(buf).strip())
            buf = []
        else:
            buf.append(ch)
        i += 1
    if buf:
        parts.append("".join(buf).strip())
    return parts


# =========================================================================
# Obtainability parser. The user requested that catalysts come from mob
# drops only (no crafted/fished/guild-shop/gardened/synergy items), so this
# is the sole source of truth for what's eligible.
# =========================================================================
def parse_mob_droplist() -> set[int]:
    rx = re.compile(
        r"^INSERT INTO `mob_droplist` VALUES "
        r"\(\s*\d+\s*,\s*\d+\s*,\s*\d+\s*,\s*\d+\s*,\s*(\d+)\s*,"
    )
    out: set[int] = set()
    for line in MOB_DROPLIST.read_text(encoding="utf-8").splitlines():
        m = rx.match(line)
        if m:
            iid = int(m.group(1))
            if iid > 0:
                out.add(iid)
    return out


# =========================================================================
# Augment + item parsing.
# =========================================================================
row_re = re.compile(
    r"^INSERT INTO `augments` VALUES "
    r"\((\d+),(-?\d+),(\d+),(-?\d+),(\d+),(\d+)\);"
    r"(?:\s*--\s*(.*))?$"
)
neg_label_re = re.compile(r"[A-Za-z][A-Za-z.%]*-\d")
item_line_re = re.compile(r"^INSERT INTO `item_basic` VALUES \((.*)\);$")


def parse_augments() -> dict[int, dict]:
    augs: dict[int, dict] = {}
    for line in AUG_SQL.read_text(encoding="utf-8").splitlines():
        m = row_re.match(line)
        if not m:
            continue
        aug_id = int(m.group(1))
        mod_id = int(m.group(3))
        value = int(m.group(4))
        comment = (m.group(7) or "").strip()
        entry = augs.setdefault(aug_id, {"label": "", "rows": []})
        entry["rows"].append((mod_id, value))
        if comment and not comment.startswith("Cont."):
            if not entry["label"]:
                entry["label"] = comment
    for aug_id, entry in augs.items():
        if not entry["label"]:
            entry["label"] = f"augment {aug_id}"
    return augs


def has_useful_mod(entry: dict) -> bool:
    return any(mod_id != 0 for mod_id, _ in entry["rows"])


def is_bad_negative(entry: dict) -> bool:
    has_neg_row = any(v < 0 for _, v in entry["rows"])
    if not has_neg_row:
        return False
    label_lc = entry["label"].lower()
    if not neg_label_re.search(entry["label"]):
        return False
    for kw in GOOD_WHEN_NEGATIVE:
        if kw in label_lc:
            return False
    if re.search(r"\bdt[-+]\d", label_lc) or re.search(r"\bdt\b", label_lc):
        return False
    return True


def parse_items() -> dict[int, dict]:
    out: dict[int, dict] = {}
    for line in ITEM_SQL.read_text(encoding="utf-8").splitlines():
        m = item_line_re.match(line)
        if not m:
            continue
        fields = split_fields(m.group(1))
        if len(fields) < 9:
            continue
        try:
            item_id = int(fields[0])
        except ValueError:
            continue
        out[item_id] = {
            "short_name": fields[2].strip("'"),
            "type": fields[5],
            "flags": fields[7],
            "category": fields[8],
        }
    return out


def is_eligible_catalyst(item_id: int, info: dict) -> bool:
    if item_id in RESERVED:
        return False
    if item_id < MIN_ITEM_ID:
        return False
    if info["type"] in EXCLUDED_TYPE:
        return False
    if info["category"] in EXCLUDED_AH:
        return False
    # Crafting kits -- short_name contains 'kit'.
    if "kit" in info["short_name"].lower():
        return False
    return True


# =========================================================================
# Main generator.
# =========================================================================
def main():
    print("=" * 70)
    print("Building obtainable item set (mob drops only)...")
    drop_set = parse_mob_droplist()
    print(f"  mob_droplist:        {len(drop_set):>6}")

    # Mob drops are the ONLY source of catalysts -- the user wants the
    # Augment NPC to trade in monster materials, not crafted/fished items.
    obtainable = drop_set
    print(f"  TOTAL eligible IDs:  {len(obtainable):>6}")

    augs = parse_augments()
    print(f"\nParsed {len(augs)} unique augIds from augments.sql")
    augs = {a: e for a, e in augs.items() if has_useful_mod(e)}
    augs = {a: e for a, e in augs.items() if not is_bad_negative(e)}
    aug_ids_sorted = sorted(augs.keys())
    print(f"After filters: {len(aug_ids_sorted)} augs remain")

    items = parse_items()
    print(f"Parsed {len(items)} item rows from item_basic.sql")

    # Build eligible+obtainable pool. Exclude items with 'kit' in short_name.
    eligible_pool: list[tuple[int, str]] = []
    kit_excluded = 0
    other_rejected = 0
    for iid in sorted(obtainable):
        info = items.get(iid)
        if info is None:
            continue
        if iid in RESERVED or iid < MIN_ITEM_ID:
            other_rejected += 1
            continue
        if info["type"] in EXCLUDED_TYPE:
            other_rejected += 1
            continue
        if info["category"] in EXCLUDED_AH:
            other_rejected += 1
            continue
        if "kit" in info["short_name"].lower():
            kit_excluded += 1
            continue
        eligible_pool.append((iid, info["short_name"]))

    print(f"Eligible+obtainable catalyst pool: {len(eligible_pool)} items")
    print(f"  (excluded as crafting kits: {kit_excluded})")
    print(f"  (rejected by other catalyst filters: {other_rejected})")

    # Categorize each augment.
    aug_cat: dict[int, int] = {}
    for aid in aug_ids_sorted:
        aug_cat[aid] = categorize_label(augs[aid]["label"])

    # For each category (except fallback "Other"), score every eligible item.
    # We build per-category sorted lists [(score, item_id, short_name), ...]
    # then greedy-assign to augments in augId order so the entry distribution
    # is deterministic.
    cat_scored: list[list[tuple[int, int, str]]] = [[] for _ in CATEGORIES]
    for iid, sname in eligible_pool:
        # Score against EVERY category; an item may be a top candidate in
        # multiple, but each item can be used at most once total. We sort
        # so highest-score-first within a category.
        for cidx in range(len(CATEGORIES) - 1):  # skip the "Other" fallback
            sc = score_item_for_category(sname, cidx)
            if sc > 0:
                cat_scored[cidx].append((sc, iid, sname))

    # Sort each category by score desc, then by item_id asc for determinism.
    for cidx in range(len(CATEGORIES)):
        cat_scored[cidx].sort(key=lambda t: (-t[0], t[1]))

    print("\nThematic candidate counts per category (score > 0):")
    for idx, name in enumerate(CAT_NAMES):
        print(f"  {idx+1:2d}. {name:40s} {len(cat_scored[idx])} candidates")

    # Greedy assignment by augId order.
    mapping: list[tuple] = []  # (itemId, augId, label, cat_idx, short_name)
    dropped_augs: list[tuple[int, str, int]] = []
    used_items: set[int] = set()
    # Position cursors per category.
    cursor = [0] * len(CATEGORIES)

    for aid in aug_ids_sorted:
        cidx = aug_cat[aid]
        # If the augment landed in the "Other" fallback (no thematic match
        # from its label), DROP it -- per spec.
        if cidx == FALLBACK_INDEX:
            dropped_augs.append((aid, augs[aid]["label"], cidx))
            continue
        # Walk the scored list for this category, skipping already-used items.
        cand_list = cat_scored[cidx]
        chosen = None
        while cursor[cidx] < len(cand_list):
            sc, iid, sname = cand_list[cursor[cidx]]
            cursor[cidx] += 1
            if iid in used_items:
                continue
            chosen = (iid, sname, sc)
            break
        if chosen is None:
            dropped_augs.append((aid, augs[aid]["label"], cidx))
            continue
        iid, sname, _sc = chosen
        used_items.add(iid)
        mapping.append((iid, aid, augs[aid]["label"], cidx, sname))

    print(f"\nAssigned {len(mapping)} augments to thematic catalysts.")
    print(f"  Dropped (no thematic match in obtainable pool): "
          f"{len(dropped_augs)}")

    # Verify integrity.
    item_ids_used = [m[0] for m in mapping]
    aug_ids_used = [m[1] for m in mapping]
    assert len(set(item_ids_used)) == len(item_ids_used), "duplicate itemId"
    assert len(set(aug_ids_used)) == len(aug_ids_used), "duplicate augId"
    for iid in item_ids_used:
        assert iid in obtainable, f"itemId {iid} not in obtainable union"
        assert iid >= MIN_ITEM_ID, f"itemId {iid} below floor"
        assert iid not in RESERVED, f"itemId {iid} reserved"
        sname = items[iid]["short_name"].lower()
        assert "kit" not in sname, f"kit leaked: {sname}"

    # Per-category final breakdown.
    final_counts = [0] * len(CATEGORIES)
    for _iid, _aid, _lbl, cidx, _sn in mapping:
        final_counts[cidx] += 1
    print("\nFinal augment placement per category:")
    for idx, name in enumerate(CAT_NAMES):
        print(f"  {idx+1:2d}. {name:40s} {final_counts[idx]} augs")

    # Sort by augId within each category for Lua output. We group by category
    # in the canonical order, then sort augIds within each group.
    by_cat: dict[int, list[tuple]] = {}
    for entry in mapping:
        by_cat.setdefault(entry[3], []).append(entry)
    for cidx in by_cat:
        by_cat[cidx].sort(key=lambda r: r[1])

    aug_width = len(str(max(aug_ids_used)))
    item_width = len(str(max(item_ids_used)))

    def lua_str(s: str) -> str:
        s = s.replace("\\", "\\\\").replace("'", "\\'")
        return f"'{s}'"

    lines = [
        "-----------------------------------",
        "-- augment_catalog.lua",
        "-- Maps catalyst item IDs to augment definitions.",
        "-- One catalyst per augmentId. Trade the catalyst to the Augment Moogle",
        "-- to apply the augment. The exdata value is 0 (uses the SQL base value).",
        "--",
        "-- Filters applied:",
        "--   - Skipped augments with no functional modifier (modId=0)",
        "--   - Skipped negative-value augments on good-when-positive stats",
        "--   - Every catalyst is verified obtainable via mob_droplist (mob drops",
        "--     only, no crafted/fished/guild/gardened/synergy items)",
        "--   - Foods, drinks, medicines, and other @USABLE_TYPE consumables are",
        "--     excluded -- catalysts must be material drops from monsters",
        "--   - Crafting kits excluded from the catalyst pool",
        "--   - Augments dropped entirely if no thematic mob-drop catalyst exists",
        "--",
        "-- Each entry: { augId = N, base = N, cat = N, label = '...' }",
        "--   augId : index into sql/augments.sql (used for the actual augment)",
        "--   base  : single-trade stat value (stacks multiply: base * count)",
        "--   cat   : 1..13 thematic category, see CAT_NAMES in the generator.",
        "--           Used by Augment_Sage to apply per-NM affinity bonuses.",
        "--   label : human-readable augment description (shown in trade msg)",
        "--",
        "-- Generated from sql/augments.sql + sql/mob_droplist.sql.",
        "-----------------------------------",
        "return {",
    ]

    first_cat = True
    for cidx in range(len(CATEGORIES)):
        entries = by_cat.get(cidx, [])
        if not entries:
            continue
        if not first_cat:
            lines.append("")
        first_cat = False
        lines.append(f"    -- {CAT_NAMES[cidx]}")
        for iid, aid, label, _cat_idx, _sname in entries:
            aug_str = f"{aid},".ljust(aug_width + 1)
            id_str = f"[{iid}]".ljust(item_width + 2)
            rows = augs[aid]["rows"]
            base_val = abs(rows[0][1]) if rows else 0
            base_str = f"{base_val},".ljust(4)
            # cat: 1-indexed category. Lets the Augment Moogle look up the
            # affinity bit + apply Sage Mastery / NM-affinity multipliers
            # without re-parsing the augment label at trade time.
            cat_str = f"{_cat_idx + 1},".ljust(3)
            lines.append(
                f"    {id_str} = {{ augId = {aug_str} base = {base_str} "
                f"cat = {cat_str} label = {lua_str(label)} }},"
            )
    lines.append("}")
    lines.append("")

    OUT_LUA.write_text("\n".join(lines), encoding="utf-8")
    print(f"\nWrote {OUT_LUA} ({len(mapping)} entries)")

    # ----- Report -----
    print("\n" + "=" * 70)
    print("REPORT")
    print("=" * 70)
    print(f"1. Final entry count: {len(mapping)}")
    print(f"2. Per-category breakdown:")
    for idx, name in enumerate(CAT_NAMES):
        if final_counts[idx] > 0:
            print(f"   {name:40s} {final_counts[idx]}")
    print(f"\n3. Sample entries (first 5):")
    for i, (iid, aid, lbl, cidx, sname) in enumerate(mapping[:5]):
        print(f"   [{iid}] {sname} -> aug {aid} '{lbl[:50]}' "
              f"({CAT_NAMES[cidx]})")
    print(f"\n4. Dropped (no thematic obtainable catalyst): {len(dropped_augs)}")
    if dropped_augs:
        # Drop-reason breakdown by category.
        from collections import Counter
        drop_by_cat = Counter(CAT_NAMES[c] for _aid, _lbl, c in dropped_augs)
        for cat_name, n in drop_by_cat.most_common():
            print(f"   {n:4d}  {cat_name}")


if __name__ == "__main__":
    main()
