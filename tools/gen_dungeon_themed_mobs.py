#!/usr/bin/env python3
# ---------------------------------------------------------------------------
# gen_dungeon_themed_mobs.py
#
# Generates modules/custom/sql/dungeon_themed_mobs.sql -- the themed
# mob_groups block (11500-11579) that re-skins all 8 DungeonSystem dungeons
# so each has a DISTINCT mob family. The dungeon spawns by groupId ->
# mob_groups.poolid -> mob_pools.modelid; these new groups point each dungeon
# at renderable, zone-appropriate poolids.
#
# Every poolid below was sourced from a live-DB query of the dungeon's Dynamis
# zone's native (renderable) mobs:
#   39/40/41  -> the Nightmare_* Divergence set (shared, confirmed native)
#   135       -> Animated weapons + the demon peerage (Xarcabard-native)
#   188       -> the named Dynamis-Jeuno goblins
#   185/186/187 -> canonical Orc / Quadav / Yagudo pools (those zones load no
#                  server-side mobs, but the client loads their beastman army;
#                  the current dungeons already render non-native HNMs there)
#
# Registered under BOTH zone 210 (catalog.groupZoneId) and 288 (parity with the
# existing 11355-11369 dungeon groups). spawntype=128, respawntime=0, dropid=0
# (no stray HNM loot -- rewards come from DungeonSystem, not mob drops). HP=0 on
# trash/minibosses (the engine scales HP from the spawned level); bosses carry a
# 60k base like the existing boss groups.
#
# Idempotent: DELETEs the 11500-11599 range before INSERT, so the deploy's
# custom-SQL applier can re-run it harmlessly.
#
# Re-generate:  python tools/gen_dungeon_themed_mobs.py
# ---------------------------------------------------------------------------
import os

# (groupid, poolid, name, hp)  -- name is internal; players see the catalog's
# `names` override. boss rows carry hp=60000.
GROUPS = [
    # ---- D1  THE OUTER BASTION (185) -- ORCISH HORDE ----
    (11500, 3009, 'Bastion Trooper',          0),
    (11501, 3016, 'Bastion Brute',            0),
    (11502, 3015, 'Bastion Gladiator',        0),
    (11503, 3039, 'Bastion Footman',          0),
    (11504, 2998, 'Bastion Marauder',         0),
    (11505, 3034, 'Bastion Siegeworks',       0),
    (11506, 2996, 'Orcish Beastlord',         0),   # mini
    (11507, 3029, 'Orcish Predator',          0),   # mini
    (11508, 3006, 'Orcish Dragoon',           0),   # mini
    (11509, 3000, 'Warchief of the Bastion',  60000),  # boss
    # ---- D2  THE VOIDWALKER ARENA (186) -- QUADAV LEGION ----
    (11510,  103, 'Voidforged Amber',         0),
    (11511,  107, 'Voidforged Amethyst',      0),
    (11512,  525, 'Voidforged Brass',         0),
    (11513,  538, 'Voidforged Bronze',        0),
    (11514,  753, 'Voidforged Cobalt',        0),
    (11515,  791, 'Voidforged Copper',        0),
    (11516,  907, 'Darksteel Warden',         0),   # mini
    (11517, 1034, 'Diamond Warden',           0),   # mini
    (11518, 1207, 'Emerald Warden',           0),   # mini
    (11519,   46, 'The Adamant Sovereign',    60000),  # boss
    # ---- D3  THE EMPYREAL PARADOX (187) -- YAGUDO THEOMILITARY ----
    (11520, 4459, 'Paradox Votary',           0),
    (11521, 4405, 'Paradox Acolyte',          0),
    (11522, 4426, 'Paradox Initiate',         0),
    (11523, 4456, 'Paradox Theologist',       0),
    (11524, 4461, 'Paradox Zealot',           0),
    (11525, 5494, 'Yagudo Prelate',           0),   # mini
    (11526, 4439, 'Yagudo Persecutor',        0),   # mini
    (11527, 4437, 'Yagudo Oracle',            0),   # mini
    (11528, 4437, 'The Empyreal Doomsayer',   60000),  # boss
    # ---- D4  THE ETERNAL THRONE (188) -- GOBLIN SYNDICATE ----
    (11530,  194, 'Throne Saboteur',          0),
    (11531,  449, 'Throne Bonebreaker',       0),
    (11532,  505, 'Throne Jackboot',          0),
    (11533,  745, 'Throne Longnail',          0),
    (11534, 1052, 'Throne Cutpurse',          0),
    (11535, 1251, 'Throne Snitch',            0),
    (11536, 1444, 'Goblin Magus',             0),   # mini
    (11537, 1935, 'Goblin Reaver',            0),   # mini
    (11538, 2115, 'Goblin Trapmaster',        0),   # mini
    (11539, 4388, 'The Goblin Overboss',      60000),  # boss
    # ---- D5  THE SHATTERED COAST (39) -- NIGHTMARE FLORA ----
    (11540, 5107, 'Coastal Funguar',          0),
    (11541, 5109, 'Coastal Flytrap',          0),
    (11542, 5108, 'Coastal Treant',           0),
    (11543, 5110, 'Coastal Goobbue',          0),
    (11544, 2865, 'Coastal Sabotender',       0),
    (11545, 5109, 'Snapjaw Bloom',            0),   # mini (Flytrap)
    (11546, 5110, 'Ancient Goobbue',          0),   # mini (Goobbue)
    (11547, 5108, 'Elder Treant',             0),   # mini (Treant)
    (11548, 5108, 'The Eldest Bough',         60000),  # boss (Treant)
    # ---- D6  THE FORSAKEN PENINSULA (40) -- FERAL BEASTS ----
    (11550, 2860, 'Feral Manticore',          0),
    (11551, 2871, 'Feral Tiger',              0),
    (11552, 2867, 'Feral Ram',                0),
    (11553, 2844, 'Feral Hare',               0),
    (11554, 2849, 'Feral Dhalmel',            0),
    (11555, 2854, 'Feral Hippogryph',         0),
    (11556, 2843, 'Dire Bugard',              0),   # mini
    (11557, 2870, 'Dire Taurus',              0),   # mini
    (11558,  199, 'Apocalyptic Weapon',       0),   # mini
    (11559,  198, 'The Apex Predator',        60000),  # boss (Apocalyptic Beast)
    # ---- D7  THE DARK CITADEL (135) -- DEMON LEGION ----
    (11560,  143, 'Animated Claymore',        0),
    (11561,  145, 'Animated Great Axe',       0),
    (11562,  152, 'Animated Longsword',       0),
    (11563,  153, 'Animated Scythe',          0),
    (11564,  155, 'Animated Spear',           0),
    (11565,  158, 'Animated Tachi',           0),
    (11566, 6056, 'Baron Avnas',              0),   # mini
    (11567, 6057, 'Count Haagenti',           0),   # mini
    (11568, 1131, 'Duke Berith',              0),   # mini
    (11569, 1154, 'The Dark Sovereign',       60000),  # boss (Dynamis Lord)
    # ---- D8  THE SUNKEN SPIRE (41) -- DROWNED DEPTHS ----
    (11570, 2856, 'Spire Kraken',             0),
    (11571, 2847, 'Spire Crab',               0),
    (11572, 2850, 'Spire Diremite',           0),
    (11573, 2869, 'Spire Stirge',             0),
    (11574, 2872, 'Spire Uragnite',           0),
    (11575, 2868, 'Spire Snoll',              0),
    (11576, 2858, 'Abyssal Makara',           0),   # mini
    (11577, 2857, 'Abyssal Leech',            0),   # mini
    (11578, 2875, 'Abyssal Worm',             0),   # mini
    (11579, 2856, 'The Abyssal Maw',          60000),  # boss (Kraken)
]

ZONES = (210, 288)

def main():
    here = os.path.dirname(os.path.abspath(__file__))
    out_path = os.path.join(here, '..', 'modules', 'custom', 'sql', 'dungeon_themed_mobs.sql')
    out_path = os.path.normpath(out_path)

    lines = []
    lines.append('-- ---------------------------------------------------------------------------')
    lines.append('-- dungeon_themed_mobs.sql  --  AUTO-GENERATED by tools/gen_dungeon_themed_mobs.py')
    lines.append('-- Themed mob_groups (11500-11579) giving each of the 8 dungeons a distinct')
    lines.append('-- mob family. Edit the roster in the generator, not here. Idempotent.')
    lines.append('-- ---------------------------------------------------------------------------')
    lines.append('DELETE FROM mob_groups WHERE groupid BETWEEN 11500 AND 11599;')
    lines.append('INSERT INTO mob_groups')
    lines.append('  (groupid, poolid, zoneid, name, respawntime, spawntype, dropid, HP, MP, allegiance, content_tag)')
    lines.append('VALUES')

    rows = []
    for gid, pool, name, hp in GROUPS:
        nm = name.replace("'", "''")
        for z in ZONES:
            rows.append("  ({gid}, {pool}, {z}, '{nm}', 0, 128, 0, {hp}, 0, 0, NULL)".format(
                gid=gid, pool=pool, z=z, nm=nm, hp=hp))
    lines.append(',\n'.join(rows) + ';')
    lines.append('')

    with open(out_path, 'w', encoding='utf-8', newline='\n') as fh:
        fh.write('\n'.join(lines))

    print('wrote {} ({} groups, {} rows)'.format(out_path, len(GROUPS), len(GROUPS) * len(ZONES)))

if __name__ == '__main__':
    main()
