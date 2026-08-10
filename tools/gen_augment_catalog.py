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
  7. RARE / EX exclusion -- @FLAG_RARE items (you can hold only one, so you can
     never stack the 4 a trade needs) and @FLAG_EX items (cannot be traded at
     all) are dropped from the catalyst pool.
  8. Superseded-augment collapse -- when a higher-power augment of the EXACT
     same stat already exists (e.g. Attack+33 vs Attack+1), the lesser one is
     dropped so the catalog keeps only the top tier per stat (drop_superseded).

For each augment, the eligible pool is SCORED against the augment's category
keywords. The highest-scoring unused item wins. If no item scores > 0 against
the augment's category, the augment is DROPPED -- no non-thematic fallback.
"""
import json
import os
import re
from pathlib import Path

ROOT = Path(os.environ.get("LEGENDARY_LIVE_ROOT", r"D:/server"))
SQL = ROOT / "sql"
AUG_SQL = SQL / "augments.sql"
ITEM_SQL = SQL / "item_basic.sql"
OUT_LUA = ROOT / "modules" / "custom" / "lua" / "augment_catalog.lua"
# Structured sibling of the .lua, emitted from the SAME data in the same run.
# The docs site (tools/docgen/generators/augments.py) consumes THIS, not a
# regex scrape of the .lua text -- so a new catalog field can never again
# silently drop an entry from the website (that broke 'All songs' 2026-06-19).
OUT_JSON = ROOT / "modules" / "custom" / "lua" / "augment_catalog.json"
# Live-DB override applied AFTER the stock augments.sql import. The generator
# reconciles it so the catalog shows the SAME effective numbers the engine uses.
OVERRIDE_SQL = ROOT / "modules" / "custom" / "sql" / "zz_augment_rebalance.sql"

# Mods stored at xN of their human value (mirrors MOD_SCALE in
# tools/docgen/generators/gear_finder.py). Stored per-entry as `disp` so the
# Moogle / !augstats / docs divide the raw (base+boost)*mult back to the
# meaningful number (a maxed Damage-Taken augment is 12800 raw = 128% / piece).
# modIds not listed are 1:1. The haste family (167/383/384) is stored /1024, so its
# divisor is 1024/100 = 10.24 to read as %; the haste augments are also re-tuned to a
# sane ~1%->25% curve in zz_augment_rebalance.sql so that % is meaningful.
MOD_DISPLAY_SCALE = {
    160: 100, 161: 100, 162: 100, 163: 100, 164: 100,   # damage-taken family -> %
    175: 100,                                            # skillchain dmg -> %
    506: 10,                                             # proc chance -> %
    507: 100,                                            # occ. extra
    167: 10.24, 383: 10.24, 384: 10.24,                 # haste (gear/magic/ability) /1024 -> %
}

# Forced catalyst assignments: pin a specific augId to a specific catalyst
# itemId, bypassing the thematic greedy pass. Use when an augment we WANT in the
# catalog keeps losing the greedy contest for its category's scarce items. The
# item is reserved up-front so the greedy pass can't take it, and it must be a
# valid obtainable (mob-drop, non-RARE/EX, id>=768) item or the integrity
# asserts in main() will catch it.
#   896 = "Sword Enhancement Spell Damage" (Enspell Dmg, mod 432). It already
#   exists in the augments table but cat 5 is item-starved (17 candidates, 16
#   placed, 21 dropped), so the greedy pass never reaches it. Wamoura Scale is a
#   mob-drop alchemy reagent left unused by every category -- free to claim.
FORCED_CATALYST = {
    896: 2338,   # Enspell Dmg -> Wamoura Scale
    # INT (augId 516) lives in cat 5 (Intelligence / Magic offense), which is
    # item-starved, so the greedy pass never gives it a catalyst and it gets
    # dropped. Pin it to Bottle of Ahriman Tears (921) -- a thematic dark-magic
    # mob drop -- so it's emitted on every regeneration AND reserved, which keeps
    # it from colliding with Conserve MP (the greedy then relocates Conserve MP to
    # its own item instead of double-booking 921). value/mult come from the
    # zz_augment_rebalance.sql override (value=1, mult=1, matching MND).
    516: 921,    # INT -> Bottle of Ahriman Tears
    # Flat weapon Dmg+ (top tier), restored 2026-06-20 (owner request). Pinned so the
    # generator emits them; value rebalanced to +1..32/slot in zz_augment_rebalance.sql
    # (stock +97 is absurd stacked across 5 slots).
    743: 889,    # DMG (melee)  -> Beetle Shell
    749: 908,    # DMG (ranged) -> Adamantoise Shell
    # ---- Owner request 2026-06-20: offer 22 previously-dropped real augments ----
    # All have a real mod in augments.sql (value=1 -> +1..32/slot via Augment Sage)
    # but landed in item-starved categories and got dropped. Pinned to score-0,
    # unused, obtainable (mob-drop, non-RARE/EX) catalysts so reserving them
    # displaces no thematic augment. (Job skills, Magic Damage, quickens-cast,
    # effect durations, and the utility/pet picks.)
    # job skills (11)
    215: 1269,   # Ninja Tool Expertise  -> mana_barrel
    288: 1725,   # Divine magic skill    -> snow_lily
    290: 1740,   # Enhancing magic skill -> iolite
    291: 1817,   # Enfeebling magic skill-> cactus_arm
    292: 1854,   # Elemental magic skill -> deed_of_moderation
    295: 2154,   # Ninjutsu skill        -> orobon_lure
    296: 2155,   # Singing skill         -> lesser_chigoe
    297: 2161,   # String instr. skill   -> troll_vambrace
    299: 2171,   # Blue Magic skill      -> colibri_beak
    300: 2212,   # Geomancy skill        -> gunpowder_swathe
    301: 2334,   # Handbell skill        -> poroggo_hat
    # magic offense (2)
    362: 2498,   # Magic Damage          -> briareuss_sash
    351: 2507,   # Occ. quickens spellcasting -> lycopodium_flower
    # effect durations (4)
    1248: 2510,  # Enhancing Magic Duration -> orc_helmet
    1249: 2640,  # Helix Effect Duration    -> murex_spicule
    1250: 2641,  # Indi Effect Duration     -> amoeban_pseudopod
    1264: 2711,  # Meditate Effect Duration -> khroma_nugget
    # utility / pet (5)
    341: 2729,   # Repair potency        -> hydrangea
    61: 2831,    # Occ. resist ailments  -> yellow_brass_chain
    1157: 2834,  # Spell Interruption Down-> immortal_molt
    1793: 2842,  # Pet: DEX              -> flawed_garnet
    1796: 2847,  # Pet: INT             -> blue_jasper
}

# Display-label overrides keyed by augId, applied after clean_label(). For when
# the augments.sql comment is technically correct but not what players call it.
LABEL_OVERRIDE = {
    896: 'Enspell Dmg',   # vs the stock "Sword Enhancement Spell Damage"
    # augId 343's comment -- "Drain" and "Aspir" Potency +1 -- STARTS with a quote,
    # so clean_label() strips from the first " to end-of-string -> empty -> the
    # generic 'Augment' fallback. It is the ONLY quote-first comment in augments.sql
    # (swept 2026-06-20), so this single override fixes the whole class. (Keep the
    # value quote-free: a literal " in a Moogle/customMenu label corrupts the menu.)
    343: 'Drain/Aspir Potency',
    # Damage-taken pairs: the tier-I mod (DMGPHYS 54 / DMGMAGIC 55) shares the
    # -50% DT cap; the tier-II mod (DMGPHYS_II 1155 / DMGMAGIC_II 1156) bypasses
    # that cap (down to -87.5%). The stock SQL comments ("Phys. dmg. taken" vs
    # "Physical Damage Taken") only differ by casing and are indistinguishable in
    # the Moogle menu, so relabel to the compact I/II form (owner request
    # 2026-08-10). Kept <=18 chars for the Moogle menu truncation; the full
    # cap-vs-bypass explanation lives on the augments docs page.
    54:   'Phys DT',
    55:   'Magic DT',
    1155: 'Phys DT II',
    1156: 'Magic DT II',
}

# Progression augments (Exp. Point / Cap. Point). These are leveling-currency
# bonuses, NOT combat stats, so categorize_label() can't place them -- they land
# in the "Other" bucket and the thematic greedy pass discards them. For a long
# time they were maintained BY HAND as a trailing "Progression (Exp / Cap)"
# section appended to the catalog... which every regeneration silently wiped,
# because the generator never knew they existed. That is exactly the regression
# this block fixes: the entries are pinned here so the generator emits them and
# they survive future regenerations.
#
# They bypass the augs[] pipeline entirely (see main()): augId 73 has modId=0 in
# stock augments.sql so has_useful_mod() already drops it, and augId 75 would be
# discarded by the "Other"-bucket rule. So we emit them straight from this table.
#
#   augId 73  Exp. Point: ships with modId=0 in sql/augments.sql -- an upstream
#     bug (nothing attaches to the player when the gear is equipped). The LIVE DB
#     repoints it at Mod::EXP_BONUS (382) via
#     modules/custom/sql/fix_aug_73_exp_bonus.sql; that SQL must be applied + map
#     restarted or the augment is cosmetic. (Apply is idempotent.)
#   augId 75  Cap. Point: already modId=915 (Mod::CAPACITY_BONUS) in stock
#     augments.sql -- works out of the box, no DB fix needed.
#
#   base = 1 keeps the per-slot FLOOR modest and gates real power behind Augment
#     Sage progress (the server-wide "augments scale with the Sage" rule): a
#     fully-slotted 5-catalyst piece gives ~+5% at rank 0, climbing to ~+160% at
#     rank-5 + affinity + crit (boost 31/slot). Bumping base toward 33 (the stock
#     augments.sql value) makes it strong immediately -- a deliberate balance knob.
#   cat = 12 (Skill+) so the Sage's Skill+ NM affinity also boosts these.
#
# Each entry: augId -> (catalystItemId, base, mult, disp, cat, label)
# Catalysts must be unused, obtainable (mob-drop), non-RARE/EX, id >= MIN_ITEM_ID
# items -- the asserts in main() enforce it. peiste_skin kept from the historical
# section; philosophers_stone replaces the old marid_tusk catalyst (id 2147),
# which a later regen handed to a different augment.
PROGRESSION_AUGS = {
    # base = 33 MIRRORS the live `augments` table (engine applies value=33; the
    # site must match the game). audit_augment_page.py flags drift if the DB value
    # ever changes -- keep these in sync with augId 73/75 in sql/augments.sql.
    73: (2523, 33, 1, 1, 12, 'Exp. Point +33%'),   # peiste_skin
    75: (942,  33, 1, 1, 12, 'Cap. Point +33%'),   # philosophers_stone
}

# Custom-mod augments emitted directly (same bypass as PROGRESSION_AUGS) for an
# augId whose STOCK augments.sql row is a dead modId=0 filler -- a custom SQL file
# repoints it at a real engine mod. The generator can't learn the real mod from
# augments.sql (it still reads modId=0 there and would drop it), so the full
# catalog entry is specified here. Each: augId -> (catalystItemId, base, mult,
# disp, cat, label, maxBoost).
#   2046 -> Mod::PHANTOM_ROLL (881) "Phantom Roll+ effect" (the SOA-ring potency
#     mod). Repointed by modules/custom/sql/aug_phantom_roll_potency.sql. value=1
#     => +1 per augment slot; maxBoost=0 => FIXED (no Sage scaling) because the
#     effect is tiny and HARD-CAPPED at +3 in scripts/globals/job_utils/corsair.lua
#     (a piece's 5 slots sum, so the cap lives in the roll code, not here). cat 4
#     groups it with the Phantom Roll ability-delay augment on the site.
CUSTOM_AUGS = {
    2046: (1875, 1, 1, 1, 4, 'Phantom Roll effect', 0),  # ancient_beastcoin (a coin -> gambler's roll)
    # 2045 -> Mod::SPIKES_DMG (344) "Spikes Dmg": flat Blaze/Ice/Shock spikes
    #   damage, repointed by modules/custom/sql/aug_spikes_dmg.sql. base/mult = 1
    #   + maxBoost = 31 => scales with the Augment Sage exactly like Enspell Dmg
    #   (a fully-slotted 5-catalyst piece reaches ~+160 at max rank). cat 5 groups
    #   it with the Enspell Dmg / Magic-offense augments. Owner request 2026-06-21.
    2045: (2531, 1, 1, 1, 5, 'Spikes Dmg', 31),  # shard_of_obsidian (sharp volcanic shard)
    # 2044 -> Mod::HELIX_EFFECT (478) "Helix Damage": % bonus to SCH Helix-spell
    #   damage, repointed by modules/custom/sql/aug_helix_damage.sql. The stock
    #   engine NEVER read HELIX_EFFECT; the helix spell scripts now scale the DoT
    #   by (100 + HELIX_EFFECT)% AND the per-tick clamp was raised 9999 -> 65535
    #   (the uint16 effect-power cap). base=1 / mult=15 => +15%/boost, ~+480% at a
    #   maxed slot; maxBoost=31 scales with the Augment Sage. cat 5 (Magic offense).
    #   Owner request 2026-06-22.
    2044: (2335, 1, 15, 1, 5, 'Helix Damage', 31),  # soulflayer_tentacle (dark/soul creature -> Helix dmg)
    # 2048 / 2100: hand-added augments (commits 7e97e79a3b / 47756957f1) that a
    #   catalog REGEN silently wiped on 2026-06-23 -- they were never in the
    #   generator's source, so re-emitting the catalog dropped them (the exact
    #   "every regeneration silently wiped" failure the PROGRESSION_AUGS note warns
    #   about). Pinned here so they survive future regens. Immunobreak Chance+ =
    #   Mod 1197 (sql/augments.sql 2048); Beast Affinity = Mod 1200 (modules/custom/
    #   sql/bst_beast_affinity_augment.sql 2100). Catalysts validated obtainable.
    2048: (2875, 1, 1, 1, 5,  'Immunobreak Chance+', 31), # ethereal_squama -- SLACK catalyst (orig ameretat_vine 2361 is greedy-USED -> pinning it evicts Parrying Skill)
    2100: (2518, 5, 1, 1, 10, 'Beast Affinity',      31), # smilodon_hide -- SLACK beast drop (orig gold_beastcoin 748 < MIN_ITEM_ID 768)
}

# Augments to DROP from the catalog entirely, keyed by augId. The augment still
# exists in the engine/DB (and on any gear already carrying it) -- it is just no
# longer offered by the Augment Moogle, !shop, or the docs, and its catalyst is
# freed for other augments. Applied as a skip in the greedy assignment in main().
#   380 = "Physical Damage Limit" raises the per-hit physical damage CAP, which is
#         moot now that the server-wide damage cap was raised to 131,071 -- removed
#         to declutter cat 1 and free its catalyst.
EXCLUDED_AUGS = {
    380,
    # Dual Wield (146) KILLED 2026-06-23 (owner request). The off-hand delay
    # multiplier saturates the engine's minDelay floor at ~80% DW, and gear +
    # the cross-job DW trait (+15) + Ascension/Rebirth DW (+25 each) already
    # reach that on their own -- so a stackable +1..32/slot Dual Wield augment
    # (up to +160 on one piece via 5 slots) was pure overkill and the source of
    # the "Dual Wield +105 -> attacks SLOWER" overflow report. Catalyst 897
    # (Scorpion Claw) is freed back to the greedy pool. The engine row in
    # augments.sql is left intact, so gear already carrying augId 146 keeps it
    # (now harmless -- the multiplier is floored at 0 in battleentity.cpp).
    146,
    # 2-stat "STR + X" augments removed 2026-06-19 by owner request (whole set):
    550,  # STR DEX  (Buffalo Hide 1628)
    551,  # STR VIT  (Bugard Skin 1640)
    552,  # STR AGI  (High-Quality Bugard Skin 1680)
    557,  # STR CHR  (Wyrm Horn 1816)
    558,  # STR INT  (Ovinnik Hide 2121)
    559,  # STR MND  (Catoblepas Hide 2123)
    # More 2-stat pairs removed 2026-06-19 (owner request):
    553,  # DEX AGI    (Regurgitated Wing 2499)
    555,  # MND CHR    (Southern Pearl 1274)
    # Flat weapon-Dmg: the TOP tier is RESTORED 2026-06-20 (owner request) -- 743
    # (melee) + 749 (ranged) are placed via FORCED_CATALYST below + rebalanced to
    # +1..32/slot in zz_augment_rebalance.sql. The lower +1/+33/+65 tiers stay
    # excluded so they don't supersede-compete with the rebalanced top tier, and the
    # Dmg:-1/-33 negatives stay excluded as junk.
    740, 741, 742,  # Dmg:+1/+33/+65 melee  (lower tiers, superseded by 743)
    744, 745,       # Dmg:-1/-33 melee      (negatives)
    746, 747, 748,  # Dmg:+1/+33/+65 ranged (lower tiers, superseded by 749)
    750, 751,       # Dmg:-1/-33 ranged     (negatives)
    # (327 "Weapon skill damage" was excluded 2026-06-14 -- cheap/farmable HQ
    #  Scorpion Shell catalyst -> stackable WSD+ -- then RESTORED exactly as
    #  before 2026-06-15 by owner request. See augment_catalog.lua [1473].)
    #
    # All 35 SPECIFIC per-weaponskill DMG augments (1024-1058) removed 2026-06-20
    # (owner request): "Backhand Blow DMG" .. "Blade Ten DMG" -- the named-WS damage
    # boosts. KEPT: GENERIC "Weapon skill damage" (327), "Sklchn.dmg" (332), "Weapon
    # Skill Acc" (326), flat weapon Dmg+ (743/749). The 35 catalysts are banned in
    # EXCLUDED_ITEMS so this is a clean removal (no catalyst churn into other augs).
    *range(1024, 1059),
    # Treasure Hunter (147): removed 2026-06-24, then RE-ENABLED 2026-06-30
    # (owner request, relaunch). TH is wanted endgame content now -- it's live in
    # the catalog at [908], the engine caps were removed (uncapped TH, commit
    # 62545389e5), and players augment it intentionally. So 147 is NOT excluded.
    # (Its old alt-catalyst 1844 stays banned in EXCLUDED_ITEMS; 908 is the live
    # catalyst, untouched.)
    # Pet STR (1792) removed 2026-06-30 (owner request, relaunch): a flat
    # single-stat Pet STR augment, redundant alongside the multi-stat "Pet STR
    # DEX VIT" (1806) and the rest of the pet-stat set. Catalyst 2168 (Cerberus
    # Claw) is freed back to the greedy pool. The augments.sql row is left intact
    # so gear already carrying 1792 keeps it (harmless); clean_banned_augments.py
    # zeroes it from inventories on the next run.
    1792,
    # All elemental resists -1 (797) removed 2026-06-30 (owner request, relaunch):
    # a pure-downside augment (-1 to every elemental resist) -- nothing a character
    # would ever WANT. Its +10 twin (796 / Square of Raxa) is kept. Banned so
    # clean_banned_augments.py strips the penalty from any gear already carrying it.
    797,
    # Redundant augments removed 2026-07-05 (owner request, relaunch tier redesign):
    # replaced by "all-in-one" versions that cover the same stat categories.
    #
    # 9x per-element Affinity Magic Accuracy (covered by "Magic Accuracy" augId 79):
    *range(936, 944), 960,
    # 8x per-element Avatar perpetuation cost (covered by "Avatar perpetuation cost" augId 80):
    *range(952, 960),
    # 8x individual element Affinities (covered by umbrella resist augments):
    *range(928, 936),
    # 15x individual weapon skills (covered by "Melee skill" 285 / "Ranged skill" 284):
    *range(257, 269), 281, 282, 283,
    # 14x individual magic skills (covered by "Magic skill" 302; Shield 286 + Parrying 287 KEPT):
    *range(288, 302),
    # Spell interruption rate down 1% (53) — 2% version (augId 54) kept:
    53,
    # Duplicate Enmity (40) — augId 39 kept:
    40,
    # Duplicate Pet Accuracy Rng.Acc (106) — augId 96 kept:
    106,
}

# Per-augment boost ceiling (0..31). The Augment Moogle clamps the baked boost
# to this at augment time (Augment_Moogle.lua def.maxBoost). It MUST live here so
# the generator re-emits it: this script reruns every 4h on the box
# (refresh_site_azure.sh [0c/4]), and any maxBoost only hand-edited into
# augment_catalog.lua gets WIPED on the next regen. augId -> maxBoost; omit = 31.
MAXBOOST = {
    # All songs -- successively nerfed. Stock maxBoost 31 => per-slot cap (1+31)=32.
    #   2026-06-19: -> 7  (cap 8/slot, a 75% cut of the prior cap).
    #   2026-06-20: -> 1  (cap 2/slot, ANOTHER 75% cut, owner request).
    #   2026-07-11: tier-fixed (TIER_VALUE below): single catalyst, +2..+10 by
    #   Augment Tier. maxBoost 1 kept as the safety floor for consumers that
    #   don't know the tierValue flag.
    67: 1,

    # ── 2026-07-09 premium-mod balance pass ──────────────────────────────────
    # Most augments sit at the +32/slot floor (base/mult 1/1). That's fine for a
    # plain stat, but for premium % mods +32 means +32% -- and stacking one across
    # all 5 slots hit absurd item totals (+160% Double Attack, +320 MP/tick Refresh).
    # DT (~10%) and Haste (~6%) were already capped via mult/disp; do the same for
    # the rest via maxBoost. Per-slot cap = (1 + maxBoost) * mult.
    # -- multi-attack (worst; best gear gives single-digit % total) --
    354: 2,   # Quadruple Attack           -> +3%/slot   (was +32)
    144: 4,   # Triple Atk                 -> +5%/slot   (was +32)
    143: 7,   # Dbl.Atk                    -> +8%/slot   (was +32)
    132: 7,   # Dbl.Atk. Crit.hit rate     -> +8 each    (combo)
    44:  14,  # Store TP Subtle Blow       -> +15 each   (combo)
    # -- crit / weaponskill / skillchain --
    41:  9,   # Crit.hit rate              -> +10%       (was +32)
    328: 9,   # Crit. hit damage           -> +10%
    327: 9,   # Weapon skill damage        -> +10%
    332: 9,   # Sklchn.dmg (mult 100)      -> +10%
    # -- caster tempo / magic --
    140: 9,   # Fast Cast                  -> +10%
    351: 9,   # Occ. quickens (Quick Magic)-> +10%
    334: 9,   # Magic burst dmg            -> +10%
    133: 14,  # Mag.Atk.Bns                -> +15
    2044: 7,  # Helix Damage (mult 15)     -> +120%      (was +480)
    1370: 7,  # Enhances (mult 10)         -> +80        (was +320)
    # -- resource / sustain --
    138: 4,   # Refresh (mult 2)           -> +10/tick   (was +64)
    137: 5,   # Regen (mult 4)             -> +24/tick   (was +128)
    51:  15,  # HP recovered while healing (mult 4) -> +64 (was +128)
    52:  15,  # MP recovered while healing (mult 4) -> +64
    # -- strong (milder trims) --
    142: 14,  # Store TP                   -> +15        (was +32)
    195: 14,  # Subtle Blow                -> +15
    363: 9,   # Chance of successful block -> +10%
    329: 14,  # Cure potency               -> +15%
    369: 11,  # Avatar Blood Pact Dmg      -> +12%

    # Treasure Hunter -- tier-fixed since 2026-07-11 (see TIER_VALUE below).
    # maxBoost 0 is kept as a safety floor for any consumer that doesn't know
    # the tierValue flag (it then behaves like the old fixed +1/slot).
    147: 0,
}

# Tier-fixed augments (owner requests 2026-07-11): a SINGLE catalyst whose
# value is STEP x the player's Augment Tier -- the Moogle writes boost =
# STEP*tier - base so the engine's (base + boost) renders exactly STEP*tier
# (requires effective mult 1). Emitted as `tierValue = STEP`; Augment_Moogle,
# !reroll, and the docgen augments/calculator generators all read the flag.
# augId -> step.
TIER_VALUE = {
    147: 1,  # Treasure Hunter  -> +1 at T1 .. +5 at T5
    67:  2,  # All songs        -> +2 at T1 .. +10 at T5
}

# Specific item IDs kept OUT of the catalyst pool entirely -- never offered as
# an augment catalyst regardless of score, and (unlike EXCLUDED_AUGS) never
# freed for re-assignment to another augment. Add item IDs here to ban one.
#   (1473 = High-Quality Scorpion Shell was banned 2026-06-14, then RESTORED
#    2026-06-15 by owner request as the WS-Damage catalyst -- no longer banned.)
EXCLUDED_ITEMS = {
    # The 6 catalysts of the removed STR-pair augments (2026-06-19) — banned so
    # they aren't re-assigned to other augments (a clean removal, not a swap).
    1628, 1640, 1680, 1816, 2121, 2123,
    # Catalysts of the DEX/AGI + MND/CHR pairs (2026-06-19) and the junk lower/negative
    # weapon-Dmg tiers. Beetle Shell 889 + Adamantoise Shell 908 were FREED 2026-06-20
    # to catalyze the restored top-tier Dmg+ (743/749) -- see FORCED_CATALYST.
    2499, 1274, 893, 896, 924, 930,
    # The 35 catalysts of the removed specific-WS DMG augments (1024-1058), banned
    # 2026-06-20 so the removal is clean (not a swap). Each was only ever used by its
    # now-removed augment, so banning them frees nothing into other augments.
    1016, 2013, 2014, 2015, 2229, 2365, 843, 866, 1155, 1157,
    1455, 1456, 1466, 1469, 1517, 1618, 1626, 1650, 1700, 1703,
    1704, 1719, 1852, 1855, 1871, 1875, 1885, 1899, 1900, 2175,
    2488, 2849, 2851, 2859, 3503,
    # Treasure Hunter catalyst (item 1844) -- banned with its augment (augId 147,
    # EXCLUDED_AUGS) so the removal is clean and 1844 isn't reassigned elsewhere.
    1844,
    # Catalysts of redundant augments removed 2026-07-05 (owner request, relaunch
    # tier redesign). Banned so they aren't reassigned to other augments.
    # Per-element Affinity Magic Accuracy (9):
    2506, 2509, 2522, 2749, 2890, 2938, 3502, 3930, 3941,
    # Per-element Avatar perpetuation cost (8):
    1268, 1270, 1295, 1311, 1313, 1414, 1443, 1830,
    # Individual element Affinities (8):
    1165, 1186, 1187, 1200, 1201, 1236, 1237, 1263,
    # Individual weapon skills (15):
    923, 864, 894, 916, 920, 925, 940, 944, 953, 1264, 1446, 1592, 2361, 2513, 2524,
    # Individual magic skills (12) + Healing (792) + Summoning (1015):
    1725, 824, 1740, 1817, 1854, 2154, 2155, 2161, 831, 2171, 2212, 2334, 792, 1015,
    # Spell interruption 1% (854), duplicate Enmity (901), duplicate Pet Acc (1124):
    854, 901, 1124,
}

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
        # FFXI has FAR more elemental-resist augments (~71) than there are
        # strictly-elemental, non-Rare mob drops, so this catalyst pool is
        # layered: (1) elemental creatures / affinity materials, (2) crystalline
        # / mineral wards, then (3) a broad set of general monster-material drops
        # to cover the remainder. The OLD design leaned on @CARDS (tarot cards)
        # here -- but cards are @FLAG_RARE (you can't hold the 4 a trade needs),
        # so they are now filtered out (is_rare_or_ex) and removed. The filler
        # tokens were picked to NOT overlap any other category's thematic pool --
        # verified by simulation: adding them moves ONLY this category's count
        # (12 -> 71) and leaves every other category unchanged.
        [# 1. elemental creatures / affinity materials
         "elemental", "rune", "talisman", "amulet",
         "cluster", "core", "spirit", "ember",
         "djinn", "salamander", "ahriman_wing",
         "yggrete", "whiteshell", "jadeshell", "bronzepiece",
         "celadon", "zaffre", "vermilion", "ochre",
         # 2. crystalline / mineral wards (gems, ingots, ash, shards)
         "ingot", "shard", "slab", "chip", "lump", "gem",
         "jadeite", "painite", "zircon",
         # 3. general monster-material fillers (elemental drops are too few to
         #    cover all the resist augments; these fill the gap left by cards)
         "pinch", "square", "bag", "sack", "fiber", "sprig", "hair",
         "piece", "bulb", "web", "carnation", "dahlia", "southern",
         "animal", "virtue", "recollection", "soulflayer", "lancewood",
         "twincoon", "gizmo",
         "moblin", "goblin", "gigas", "qutrub", "mamool", "corse",
         "mask", "pauldron", "armlet", "shank", "pincer"],
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
        mult   = int(m.group(2))   # field 2 = multiplier (augments table schema)
        mod_id = int(m.group(3))
        value = int(m.group(4))
        comment = (m.group(7) or "").strip()
        entry = augs.setdefault(aug_id, {"label": "", "rows": [], "mult": 0})
        entry["rows"].append((mod_id, value))
        entry["mult"] = max(entry["mult"], mult)
        if comment and not comment.startswith("Cont."):
            if not entry["label"]:
                entry["label"] = comment
    for aug_id, entry in augs.items():
        if not entry["label"]:
            entry["label"] = f"augment {aug_id}"
    return augs


# =========================================================================
# Live-DB override reconciliation + label cleanup.
#
# zz_augment_rebalance.sql re-tunes value+multiplier for the "marquee" + recovery
# augments AFTER the stock import. The generator MUST fold it in so the catalog
# (and thus the Moogle trade message + !augstats, which read base+mult) shows the
# exact numbers the engine applies: (base + sageBoost 0..31) * (mult>1 ? mult : 1).
# =========================================================================
_override_re = re.compile(
    r"UPDATE\s+`?augments`?\s+SET\s+`?value`?\s*=\s*(-?\d+)\s*,\s*"
    r"`?multiplier`?\s*=\s*(\d+)\s+WHERE\s+`?augmentId`?\s*=\s*(\d+)",
    re.IGNORECASE)

# A RANGE override (`WHERE augmentId BETWEEN lo AND hi`) applies the same
# value/multiplier to EVERY augId in [lo, hi]. The single-id regex above
# silently skipped these, so a BETWEEN rebalance (e.g. the WS DMG augs
# 1024-1058: value=9/mult=1 -> 200%) never reached the catalog and the docs
# reverted to the stock value (1/5 -> 800%). Match it too.
_override_between_re = re.compile(
    r"UPDATE\s+`?augments`?\s+SET\s+`?value`?\s*=\s*(-?\d+)\s*,\s*"
    r"`?multiplier`?\s*=\s*(\d+)\s+WHERE\s+`?augmentId`?\s+BETWEEN\s+(\d+)\s+AND\s+(\d+)",
    re.IGNORECASE)


def parse_override() -> dict:
    out: dict = {}
    if not OVERRIDE_SQL.exists():
        return out
    for line in OVERRIDE_SQL.read_text(encoding="utf-8").splitlines():
        mb = _override_between_re.search(line)
        if mb:
            value, mult, lo, hi = (int(g) for g in mb.groups())
            for aug_id in range(lo, hi + 1):
                out[aug_id] = (value, mult)
            continue
        m = _override_re.search(line)
        if m:
            value, mult, aug_id = int(m.group(1)), int(m.group(2)), int(m.group(3))
            out[aug_id] = (value, mult)
    return out


def effective(aug_id: int, entry: dict, override: dict) -> tuple:
    """The (base_value, multiplier) the ENGINE actually applies: override wins,
    else the stock augments.sql row. Engine = (value+boost)*(mult>1?mult:1), so
    we normalise mult to >= 1."""
    if aug_id in override:
        value, mult = override[aug_id]
        value = abs(value)   # catalog base is a magnitude; the engine keeps the sign
    else:
        rows = entry["rows"]
        value = abs(rows[0][1]) if rows else 0
        mult = entry.get("mult", 0)
    return value, (mult if mult > 1 else 1)


def clean_label(label: str) -> str:
    """Strip the stock '+97 / +33 / +1%' magnitudes and dev-note asides from a
    label, leaving just the stat name. Every augment now scales with the Augment
    Sage, so the flat numbers are misleading; the real per-slot/total value is
    shown live by the Moogle and !augstats from base*mult."""
    # Drop parentheticals EXCEPT melee/ranged disambiguators (Dmg/Delay variants).
    label = re.sub(
        r"\s*\(([^)]*)\)",
        lambda m: m.group(0) if re.search(r"melee|ranged", m.group(1), re.I) else "",
        label)
    # Drop trailing dev-notes, quoted asides, and '?'-tails.
    label = re.sub(
        r'\s*(?:"[^"]*".*|\?.*|--.*|'
        r"(?:could not|assuming|use multiplier|mod undefined|as of yet|"
        r"leaving blank|tested in retail|increases? by|additional shots).*)$",
        "", label, flags=re.IGNORECASE)
    # Strip flat numeric magnitudes (+97, +33, -1, +1%). Note: no trailing \s*
    # after the digits, or "HP+33 MP+33" would lose the space and become "HPMP".
    label = re.sub(r"\s*[+\-]\s*\d+%?", "", label)
    # Colons -> spaces; collapse whitespace; trim stray punctuation.
    label = re.sub(r"\s*:\s*", " ", label)
    label = re.sub(r"\s{2,}", " ", label).strip(" ,.-")
    return label or "Augment"


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


def drop_superseded(augs: dict) -> dict:
    """Drop an augment when a strictly higher-power augment of the EXACT same
    mod-set already exists -- a redundant 'lesser' version (e.g. Attack+1 when
    Attack+33 exists; HP+33 / HP+65 when HP+97 exists). Keeps only the top tier
    of each stat.

    Conservative: it ONLY collapses clean POSITIVE bonuses. It deliberately
    leaves alone:
      * Delay augments -- for Delay, LESS is better, so a bigger number is not
        'higher power';
      * negative-value penalties / debuff counterparts (Dmg:-33, Enmity-1,
        Slow+1, 'resists -1') -- the opposite of the buff, not a weaker copy;
      * 'Pet:' mods vs the player-stat version -- a different effect even where
        they happen to share a modId.
    """
    from collections import defaultdict
    groups: dict[tuple, list] = defaultdict(list)
    for aug_id, e in augs.items():
        rows = e["rows"]
        modset = tuple(sorted(mid for mid, _ in rows if mid != 0))
        if not modset:
            continue
        # signed value of the dominant (largest-magnitude) mod
        sv = max((v for mid, v in rows if mid != 0), key=lambda v: abs(v), default=0)
        groups[modset].append((sv, aug_id))

    drop: set[int] = set()
    for _modset, lst in groups.items():
        if len(lst) < 2:
            continue
        best_sv = max(sv for sv, _ in lst)
        if best_sv <= 0:
            continue  # no positive 'best' -> all penalties/delay; leave the group
        best_is_pet = any("pet:" in augs[aid]["label"].lower()
                          for sv, aid in lst if sv == best_sv)
        for sv, aid in lst:
            if sv >= best_sv:
                continue
            label = augs[aid]["label"].lower()
            if sv > 0 and "delay" not in label and ("pet:" in label) == best_is_pet:
                drop.add(aid)
    # Never collapse an owner-pinned augment: if it's in FORCED_CATALYST the owner
    # explicitly wants it offered, even if a higher-tier sibling exists (e.g. the
    # +1 'Occ. resist to stat ailments' #61, requested 2026-06-20).
    drop -= set(FORCED_CATALYST)
    return {a: e for a, e in augs.items() if a not in drop}


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


def is_rare_or_ex(info: dict) -> bool:
    """True if the item is RARE (hold only one) or EX (untradeable).

    Either flag makes the item useless as a catalyst you trade up to 4 at a
    time: RARE caps you at holding ONE (so you can never stack 4), and EX
    can't be traded to the NPC at all. The flags column is a '@FLAG_A | @FLAG_B'
    string, so we tokenize on '|' and test for the exact flag names.
    """
    toks = {t.strip() for t in info["flags"].split("|")}
    return "@FLAG_RARE" in toks or "@FLAG_EX" in toks


def is_eligible_catalyst(item_id: int, info: dict) -> bool:
    if item_id in RESERVED:
        return False
    if item_id < MIN_ITEM_ID:
        return False
    if info["type"] in EXCLUDED_TYPE:
        return False
    if info["category"] in EXCLUDED_AH:
        return False
    # RARE (can't hold 4 to trade) or EX (can't trade at all): useless catalyst.
    if is_rare_or_ex(info):
        return False
    # Crafting kits -- short_name contains 'kit'.
    if "kit" in info["short_name"].lower():
        return False
    return True


# =========================================================================
# Main generator.
# =========================================================================
def main():
    # GUARD (2026-06-28): the relaunch augment_catalog.lua was HAND-MIGRATED to the
    # 24-category scheme (cats 1-24, matching augment_affinity_catalog.lua) + a per-entry
    # tier field after the affinity split. This generator still emits the OLD 14-category
    # scheme and would silently clobber that work + drop tiers on a full regen. Refuse to
    # overwrite a migrated catalog unless explicitly forced. See project_relaunch_server.
    if OUT_LUA.exists():
        _existing = OUT_LUA.read_text(encoding="utf-8", errors="ignore")
        _cats = [int(c) for c in re.findall(r"\bcat\s*=\s*(\d+)", _existing)]
        _migrated = (bool(_cats) and max(_cats) > 14) or bool(re.search(r"\btier\s*=", _existing))
        if _migrated and os.environ.get("AUGMENT_REGEN_FORCE") != "1":
            # SKIP (not abort) so the hourly docs refresh never breaks on this: if a
            # deploy puts the hand-migrated 24-cat .lua on the box, the generator just
            # leaves it in place instead of clobbering it back to the 14-cat scheme +
            # dropping tiers. Set AUGMENT_REGEN_FORCE=1 to regen anyway. The proper
            # long-term fix is to reconcile CATEGORIES/CAT_NAMES to 24 cats.
            print(f"[gen_augment_catalog] SKIP: {OUT_LUA} looks hand-migrated "
                  "(24-cat / tier) and this generator emits the old 14-cat scheme -- "
                  "preserving it (set AUGMENT_REGEN_FORCE=1 to override).")
            return
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
    override = parse_override()
    print(f"Override rows from zz_augment_rebalance.sql: {len(override)} augIds")
    augs = {a: e for a, e in augs.items() if has_useful_mod(e)}
    augs = {a: e for a, e in augs.items() if not is_bad_negative(e)}
    _before_super = len(augs)
    augs = drop_superseded(augs)
    print(f"Dropped {_before_super - len(augs)} augments superseded by a "
          f"higher-power version of the same stat")
    aug_ids_sorted = sorted(augs.keys())
    print(f"After filters: {len(aug_ids_sorted)} augs remain")

    items = parse_items()
    print(f"Parsed {len(items)} item rows from item_basic.sql")

    # Build eligible+obtainable pool. Exclude items with 'kit' in short_name.
    eligible_pool: list[tuple[int, str]] = []
    kit_excluded = 0
    rare_ex_excluded = 0
    other_rejected = 0
    for iid in sorted(obtainable):
        info = items.get(iid)
        if info is None:
            continue
        if iid in RESERVED or iid < MIN_ITEM_ID:
            other_rejected += 1
            continue
        if iid in EXCLUDED_ITEMS:
            other_rejected += 1
            continue
        if info["type"] in EXCLUDED_TYPE:
            other_rejected += 1
            continue
        if info["category"] in EXCLUDED_AH:
            other_rejected += 1
            continue
        # RARE (can't hold 4 to trade) or EX (untradeable): drop from the pool.
        if is_rare_or_ex(info):
            rare_ex_excluded += 1
            continue
        if "kit" in info["short_name"].lower():
            kit_excluded += 1
            continue
        eligible_pool.append((iid, info["short_name"]))

    print(f"Eligible+obtainable catalyst pool: {len(eligible_pool)} items")
    print(f"  (excluded as crafting kits: {kit_excluded})")
    print(f"  (excluded as RARE/EX: {rare_ex_excluded})")
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

    # Forced catalysts: reserve their items up-front so the greedy pass below
    # can't consume them, guaranteeing the pinned augId gets exactly that item.
    forced = {aid: iid for aid, iid in FORCED_CATALYST.items()
              if aid in augs and iid in items}
    for _fiid in forced.values():
        used_items.add(_fiid)

    # Progression augments: reserve their catalysts too, so the thematic greedy
    # pass can't hand peiste_skin / philosophers_stone to some other augment.
    # These augIds never enter augs[] (Exp. Point has modId=0; Cap. Point lands
    # in "Other"), so they're emitted directly from PROGRESSION_AUGS below -- the
    # reservation just protects their catalyst items from being claimed twice.
    for _piid, *_prest in PROGRESSION_AUGS.values():
        if _piid in items:
            used_items.add(_piid)

    # Custom-mod augments: reserve their catalysts the same way.
    for _ciid, *_crest in CUSTOM_AUGS.values():
        if _ciid in items:
            used_items.add(_ciid)

    for aid in aug_ids_sorted:
        # Explicitly-excluded augments (EXCLUDED_AUGS) are skipped entirely: no
        # catalyst, no catalog entry. They stay in the engine, just unoffered.
        if aid in EXCLUDED_AUGS:
            continue
        # Forced assignment wins over the thematic greedy pass.
        if aid in forced:
            _fiid = forced[aid]
            mapping.append((_fiid, aid, augs[aid]["label"], aug_cat[aid],
                            items[_fiid]["short_name"]))
            continue
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
        assert not is_rare_or_ex(items[iid]), f"RARE/EX leaked: {iid} ({sname})"

    # Progression catalysts must be valid, obtainable, and NOT collide with a
    # thematic entry (the reservation above guarantees the last point).
    _used_set = set(item_ids_used)
    for _aid, (_piid, *_prest) in PROGRESSION_AUGS.items():
        assert _piid in items, f"progression catalyst {_piid} (aug {_aid}) not in item_basic"
        assert _piid in obtainable, f"progression catalyst {_piid} (aug {_aid}) not a mob drop"
        assert _piid >= MIN_ITEM_ID, f"progression catalyst {_piid} (aug {_aid}) below floor"
        assert _piid not in RESERVED, f"progression catalyst {_piid} (aug {_aid}) reserved"
        assert _piid not in _used_set, f"progression catalyst {_piid} (aug {_aid}) collides with a thematic entry"
        assert not is_rare_or_ex(items[_piid]), f"progression catalyst {_piid} (aug {_aid}) is RARE/EX"

    # Custom-mod catalysts: same validity guarantees.
    for _aid, (_ciid, *_crest) in CUSTOM_AUGS.items():
        assert _ciid in items, f"custom catalyst {_ciid} (aug {_aid}) not in item_basic"
        assert _ciid in obtainable, f"custom catalyst {_ciid} (aug {_aid}) not a mob drop"
        assert _ciid >= MIN_ITEM_ID, f"custom catalyst {_ciid} (aug {_aid}) below floor"
        assert _ciid not in RESERVED, f"custom catalyst {_ciid} (aug {_aid}) reserved"
        assert _ciid not in _used_set, f"custom catalyst {_ciid} (aug {_aid}) collides with a thematic entry"
        assert not is_rare_or_ex(items[_ciid]), f"custom catalyst {_ciid} (aug {_aid}) is RARE/EX"

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
        "--   - RARE / EX items excluded (a Rare item can't be held in the",
        "--     quantity a 4-at-a-time trade needs; an EX item can't be traded)",
        "--   - Lesser augments dropped when a higher-power version of the same",
        "--     stat already exists (e.g. Attack+1 removed; Attack+33 kept)",
        "--   - Crafting kits excluded from the catalyst pool",
        "--   - Augments dropped entirely if no thematic mob-drop catalyst exists",
        "--",
        "-- Each entry: { augId = N, base = N, mult = N, cat = N, label = '...' }",
        "--   augId : index into sql/augments.sql (used for the actual augment)",
        "--   base  : EFFECTIVE per-slot base the engine applies (the live value",
        "--           after modules/custom/sql/zz_augment_rebalance.sql).",
        "--   mult  : EFFECTIVE multiplier (engine uses mult>1 ? mult : 1).",
        "--           Real per-slot value = (base + sageBoost 0..31) * mult.",
        "--   disp  : display divisor -- mods stored at xN (damage-taken /100,",
        "--           skillchain /100, ...) are divided by this so the Moogle /",
        "--           !augstats / docs show the meaningful number. 1 = no scaling.",
        "--   cat   : 1..13 thematic category, see CAT_NAMES in the generator.",
        "--           Used by Augment_Sage to apply per-NM affinity bonuses.",
        "--   label : stat NAME only -- flat numbers are stripped because every",
        "--           augment scales with Augment Sage progress (see !augstats).",
        "--",
        "-- Generated from sql/augments.sql + sql/mob_droplist.sql.",
        "-----------------------------------",
        "return {",
    ]

    # Structured mirror of the .lua, accumulated in lockstep so the website
    # reads data instead of regex-scraping text. Shape mirrors docgen's
    # _parse_catalog: ordered [{category, entries:[{...}]}].
    json_groups: list[dict] = []
    first_cat = True
    for cidx in range(len(CATEGORIES)):
        entries = by_cat.get(cidx, [])
        if not entries:
            continue
        if not first_cat:
            lines.append("")
        first_cat = False
        lines.append(f"    -- {CAT_NAMES[cidx]}")
        jentries: list[dict] = []
        for iid, aid, label, _cat_idx, _sname in entries:
            aug_str = f"{aid},".ljust(aug_width + 1)
            id_str = f"[{iid}]".ljust(item_width + 2)
            base_val, mult_val = effective(aid, augs[aid], override)
            _rows = augs[aid]["rows"]
            disp_val = MOD_DISPLAY_SCALE.get(_rows[0][0], 1) if _rows else 1
            base_str = f"{base_val},".ljust(4)
            mult_str = f"{mult_val},".ljust(3)
            disp_str = f"{disp_val},".ljust(5)
            # cat: 1-indexed category. Lets the Augment Moogle look up the
            # affinity bit + apply Sage Mastery / NM-affinity multipliers
            # without re-parsing the augment label at trade time.
            cat_str = f"{_cat_idx + 1},".ljust(3)
            label_final = LABEL_OVERRIDE.get(aid, clean_label(label))
            mb_val = MAXBOOST.get(aid)
            mb_suffix = f", maxBoost = {mb_val}" if mb_val is not None else ""
            tv_suffix = f", tierValue = {TIER_VALUE[aid]}" if aid in TIER_VALUE else ""
            lines.append(
                f"    {id_str} = {{ augId = {aug_str} base = {base_str} "
                f"mult = {mult_str} disp = {disp_str} cat = {cat_str} "
                f"label = {lua_str(label_final)}{mb_suffix}{tv_suffix} }},"
            )
            jentries.append({
                "itemId": iid, "augId": aid, "label": label_final,
                "base": base_val, "mult": mult_val, "disp": disp_val,
                "cat": _cat_idx + 1, "maxBoost": mb_val,
                "tierValue": TIER_VALUE.get(aid, 0),
            })
        json_groups.append({"category": CAT_NAMES[cidx], "entries": jentries})

    # -- Progression (Exp / Cap) ------------------------------------------------
    # Emitted as a dedicated trailing section, NOT through the thematic pass:
    # these are leveling-currency augments, so the scorer's "Other" bucket would
    # drop them. The SINGLE-dash header below is what docgen treats as the
    # category title; the TRIPLE-dash lines are explanatory only (docgen's header
    # regex needs a letter right after "--", so "---" lines are skipped) and the
    # main entry regex tolerates the trailing "-- name" hint.
    if PROGRESSION_AUGS:
        lines.append("")
        lines.append("    -- Progression (Exp / Cap)")
        lines.append("    ---   Cap. Point +33% (augId 75) uses Mod::CAPACITY_BONUS (915) in")
        lines.append("    ---   sql/augments.sql and works out of the box.")
        lines.append("    ---   Exp. Point +33% (augId 73) shipped with modId=0 upstream -- a real")
        lines.append("    ---   bug (nothing attaches when the gear is equipped). Fixed in the live")
        lines.append("    ---   DB by modules/custom/sql/fix_aug_73_exp_bonus.sql, which repoints it")
        lines.append("    ---   at Mod::EXP_BONUS (382). Apply that SQL once and restart map.")
        lines.append("    ---   base = 33 mirrors the live augments-table value so the site matches the")
        lines.append("    ---   game (cap 64/slot); cat = 12 (Skill+) so the Sage's Skill+ affinity boosts.")
        pj: list[dict] = []
        for aid in sorted(PROGRESSION_AUGS):
            iid, base_val, mult_val, disp_val, cat_val, label = PROGRESSION_AUGS[aid]
            id_str   = f"[{iid}]".ljust(item_width + 2)
            aug_str  = f"{aid},".ljust(aug_width + 1)
            base_str = f"{base_val},".ljust(4)
            mult_str = f"{mult_val},".ljust(3)
            disp_str = f"{disp_val},".ljust(5)
            cat_str  = f"{cat_val},".ljust(3)
            sname    = items[iid]["short_name"] if iid in items else "?"
            lines.append(
                f"    {id_str} = {{ augId = {aug_str} base = {base_str} "
                f"mult = {mult_str} disp = {disp_str} cat = {cat_str} label = {lua_str(label)} }},  -- {sname}"
            )
            pj.append({
                "itemId": iid, "augId": aid, "label": label,
                "base": base_val, "mult": mult_val, "disp": disp_val,
                "cat": cat_val, "maxBoost": MAXBOOST.get(aid),
            })
        json_groups.append({"category": "Progression (Exp / Cap)", "entries": pj})

    # -- Custom-mod augments (direct-emit, see CUSTOM_AUGS) ----------------------
    # Same bypass as the progression block: the augId is a repurposed dead modId=0
    # slot whose real mod is set by a custom SQL file, so the entry is specified
    # by hand. Single-dash header -> docgen treats it as the category title.
    if CUSTOM_AUGS:
        lines.append("")
        lines.append("    -- Corsair (Phantom Roll)")
        lines.append("    ---   Phantom Roll effect (augId 2046) grants Mod::PHANTOM_ROLL (881) via")
        lines.append("    ---   modules/custom/sql/aug_phantom_roll_potency.sql (repoints a dead modId=0")
        lines.append("    ---   slot). +1 per augment slot, HARD-CAPPED at +3/piece in corsair.lua.")
        cj: list[dict] = []
        for aid in sorted(CUSTOM_AUGS):
            iid, base_val, mult_val, disp_val, cat_val, label, mb_val = CUSTOM_AUGS[aid]
            id_str   = f"[{iid}]".ljust(item_width + 2)
            aug_str  = f"{aid},".ljust(aug_width + 1)
            base_str = f"{base_val},".ljust(4)
            mult_str = f"{mult_val},".ljust(3)
            disp_str = f"{disp_val},".ljust(5)
            cat_str  = f"{cat_val},".ljust(3)
            sname    = items[iid]["short_name"] if iid in items else "?"
            mb_suffix = f", maxBoost = {mb_val}" if mb_val is not None else ""
            lines.append(
                f"    {id_str} = {{ augId = {aug_str} base = {base_str} "
                f"mult = {mult_str} disp = {disp_str} cat = {cat_str} label = {lua_str(label)}{mb_suffix} }},  -- {sname}"
            )
            cj.append({
                "itemId": iid, "augId": aid, "label": label,
                "base": base_val, "mult": mult_val, "disp": disp_val,
                "cat": cat_val, "maxBoost": mb_val,
            })
        json_groups.append({"category": "Corsair (Phantom Roll)", "entries": cj})

    lines.append("}")
    lines.append("")

    OUT_LUA.write_text("\n".join(lines), encoding="utf-8")
    print(f"\nWrote {OUT_LUA} ({len(mapping)} thematic + "
          f"{len(PROGRESSION_AUGS)} progression + {len(CUSTOM_AUGS)} custom = "
          f"{len(mapping) + len(PROGRESSION_AUGS) + len(CUSTOM_AUGS)} entries)")

    # Structured sibling for the docs site (single source of truth -- see
    # OUT_JSON comment up top). Stable key order + trailing newline so git
    # diffs stay clean across regens.
    _json_total = sum(len(g["entries"]) for g in json_groups)
    OUT_JSON.write_text(
        json.dumps({"schema": 1, "total": _json_total, "groups": json_groups},
                   indent=2, ensure_ascii=False) + "\n",
        encoding="utf-8",
    )
    print(f"Wrote {OUT_JSON} ({_json_total} entries, {len(json_groups)} categories)")

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
