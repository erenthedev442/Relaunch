"""Generate item_mods for the 86 statless Zurim (Domain Points vendor) items.

Context (2026-07-10, owner request): the stock Zurim NPC in Norg sells the full
retail Domain Invasion / Geas Fete catalog for domain_points, but 86 of the 196
items shipped from upstream LSB with item_equipment/item_weapon rows and EMPTY
item_mods -- purchasable, equippable, zero stats. This script gives every one of
them its REAL retail stats parsed from BG-Wiki (tools/bgwiki_stats_cache.json),
reusing the verified parser from tools/gen_naked_item_stats.py.

Rules applied on top of the raw wiki string:
  * "Domain Invasion: ..." latent suffix -- STRIPPED. The latent condition isn't
    implemented server-side, and upstream's already-implemented siblings (e.g.
    Heidrek Harness) carry base stats only, so base-only matches the house style.
    EXCEPTION: items whose ENTIRE stat line is the latent (Voluspa Grip) get the
    latent values at 50%, always-on -- otherwise fixing them would leave them
    naked again.
  * "Boost: ..." conditional (Ask Sash) -- same 50% always-on treatment.
  * "Pet: ..." suffix -- stripped (pet mods live in item_mods_pet; out of scope).
  * "DMG:/Delay:" prefixes on weapons -- stripped (item_weapon already has them).
  * Combat-skill tokens ("Club skill +242", "Parrying skill +242", "Magic Accuracy
    skill +188") are dropped on WEAPONS -- those are intrinsic ilvl_skill /
    ilvl_parry / ilvl_macc columns in item_weapon (already populated upstream),
    NOT item_mods rows. On ARMOR (the 600pt skill earrings) they ARE item_mods
    and are kept. Mirrors tools/reconcile_gear_mods.py WEAPON_INTRINSIC.

Anything unparseable is emitted as a TODO comment, never guessed.

Run:    python tools/balance/generate_zurim_mods.py
Output: sql/zz_zurim_gear_mods.sql   (INSERT IGNORE; zz_ prefix so it loads after
        item_mods.sql's DROP TABLE in a full dbtool update)
"""
from __future__ import annotations

import json
import re
import sys
from pathlib import Path

REPO = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(REPO))

import tools.gen_naked_item_stats as naked  # parser + rules + mod-enum loader

# The 86 statless Zurim items (id -> item_basic name), from the 2026-07-10 audit
# of scripts/zones/Norg/npcs/Zurim.lua vs item_mods coverage.
ITEMS: dict[int, str] = {
    # 40pt Domain Invasion armor (13)
    23738: 'hervor_galea', 23741: 'hervor_haubert', 23744: 'hervor_mouffles',
    23747: 'hervor_brayettes', 23750: 'hervor_sollerets',
    23739: 'heidrek_mask', 23745: 'heidrek_gloves', 23748: 'heidrek_brais', 23751: 'heidrek_boots',
    23743: 'angantyr_robe', 23746: 'angantyr_mittens', 23749: 'angantyr_tights', 23752: 'angantyr_boots',
    # 80pt Voluspa odds and ends (2)
    22219: 'voluspa_grip', 26413: 'voluspa_shield',
    # 100pt dragon accessories (3)
    26163: 'etana_ring', 27616: 'izdubar_mantle', 26245: 'solemnity_cape',
    # 200pt T2 Geas Fete weapons (17)
    21084: 'queller_rod', 20702: 'emissary', 20598: 'shijo', 20700: 'nixxer',
    20892: 'deathbane', 20797: 'skullrender', 20599: 'kali', 21215: 'vijaya_bow',
    21027: 'ichigohitofuri', 20979: 'aizushintogo', 20937: 'rhomphaia',
    21149: 'espiritus', 20701: 'iris', 20597: 'enchufla', 21150: 'akademos',
    21085: 'solstice', 21698: 'bidenhander',
    # 600pt skill earrings (18)
    26092: 'hretha_earring', 26089: 'ran_earring', 26091: 'foresti_earring',
    26090: 'hermodr_earring', 26093: 'saxnot_earring', 26098: 'meili_earring',
    26095: 'mimir_earring', 26096: 'vor_earring', 26097: 'ilmr_earring',
    26094: 'mani_earring', 26099: 'lodurr_earring', 26104: 'njordr_earring',
    26101: 'bragi_earring', 26103: 'dellingr_earring', 26102: 'gersemi_earring',
    26100: 'hnoss_earring', 26105: 'gna_earring', 26106: 'fulla_earring',
    # 800pt Reisenjima Fete weapons (8)
    20579: 'skinflayer', 21686: 'zulfiqar', 21746: 'digirbalag', 21754: 'aganoshe',
    21804: 'obschine', 21904: 'kanaria', 21021: 'umaru', 21072: 'gada',
    # 800pt Reisenjima Fete armor (15)
    25640: 'odyssean_helm', 25716: 'odyssean_chestplate', 27138: 'odyssean_gauntlets',
    25840: 'odyssean_cuisses', 27494: 'odyssean_greaves',
    25641: 'valorous_mask', 27139: 'valorous_mitts', 25841: 'valorous_hose', 27495: 'valorous_greaves',
    25720: 'chironic_doublet', 27142: 'chironic_gloves', 27498: 'chironic_slippers',
    25719: 'merlinic_jubbah', 27141: 'merlinic_dastanas', 25843: 'merlinic_shalwar',
    # 1000pt accessories/ammo (10)
    22294: 'hauksbok_bolt', 22295: 'hauksbok_bullet', 22296: 'voluspa_tathlum',
    26353: 'ask_sash', 26354: 'embla_sash', 26355: 'audumbla_sash',
    26111: 'beyla_earring', 26112: 'tuisto_earring', 26113: 'nehalennia_earring',
    26110: 'sjofn_earring',
    # 2026-07-10 gap fill: 14 statless Voluspa weapons (latent-only -> Domain
    # Invasion latent at 50% always-on, like Voluspa Grip) + 2 armor bases.
    21510: 'voluspa_knuckles', 21566: 'voluspa_knife', 21622: 'voluspa_sword',
    21665: 'voluspa_blade', 21712: 'voluspa_axe', 21769: 'voluspa_chopper',
    21822: 'voluspa_scythe', 21864: 'voluspa_lance', 21912: 'voluspa_katana',
    21976: 'voluspa_tachi', 22006: 'voluspa_hammer', 22088: 'voluspa_pole',
    22133: 'voluspa_bow', 22144: 'voluspa_gun',
    23740: 'angantyr_beret', 25717: 'valorous_mail',
}

# Combat-skill mod ids that are INTRINSIC on weapons (item_weapon ilvl columns),
# copied from tools/reconcile_gear_mods.py WEAPON_INTRINSIC.
WEAPON_INTRINSIC = {80, 81, 82, 83, 84, 85, 86, 87, 88, 89, 90, 91,
                    104, 105, 106, 107, 108, 110}

OUTPUT = REPO / 'sql' / 'zz_zurim_gear_mods.sql'


def load_weapon_ids() -> set[int]:
    ids = set()
    for line in open(REPO / 'sql' / 'item_weapon.sql', encoding='utf-8', errors='replace'):
        m = re.search(r'VALUES \((\d+),', line)
        if m:
            ids.add(int(m.group(1)))
    return ids


def main() -> int:
    modmap = naked.load_mod_enum(str(REPO / 'scripts' / 'enum' / 'mod.lua'))
    name_by_id = {v: k for k, v in modmap.items()}
    cache = json.loads((REPO / 'tools' / 'bgwiki_stats_cache.json').read_text(encoding='utf-8'))
    weapon_ids = load_weapon_ids()

    # Extra rules for tokens the base parser lacks (appended AFTER the base
    # rules; none of these collide with base patterns). Same (regex, MOD, xform)
    # shape. Verified against scripts/enum/mod.lua:
    #   CONVMPTOHP=4 CONVHPTOMP=7 CHARMRES=252 WALTZ_POTENCY=491 ENF_MAG_DURATION=1151
    extra_rules = [
        (re.compile(r'Converts?\s+(\d+)\s+MP to HP', re.IGNORECASE), 'CONVMPTOHP', naked._ident),
        (re.compile(r'Converts?\s+(\d+)\s+HP to MP', re.IGNORECASE), 'CONVHPTOMP', naked._ident),
        (re.compile(r'"?Resist Charm"?\s*\+?(\d+)', re.IGNORECASE), 'CHARMRES', naked._ident),
        (re.compile(r'\bWaltz potency\s*\+?(\d+)%?', re.IGNORECASE), 'WALTZ_POTENCY', naked._ident),
        (re.compile(r'\bEnfeebling magic duration\s*\+?(\d+)%?', re.IGNORECASE), 'ENF_MAG_DURATION', naked._ident),
        (re.compile(r'\bSpell interruption rate down\s*\+?(\d+)%?', re.IGNORECASE), 'SPELLINTERRUPT', naked._ident),
    ]
    naked.PARSE_RULES = naked.PARSE_RULES + extra_rules

    lines: list[str] = []
    lines.append('-- ============================================================')
    lines.append('-- zz_zurim_gear_mods.sql   (generated by tools/balance/generate_zurim_mods.py)')
    lines.append('--')
    lines.append('-- Real retail stats (BG-Wiki) for the 86 Zurim / Domain-Points items that')
    lines.append('-- upstream LSB shipped with EMPTY item_mods. "Domain Invasion:" / "Boost:"')
    lines.append('-- latents are stripped (unimplemented) except latent-only items, which get')
    lines.append('-- 50% always-on. Weapon combat-skill lines are intrinsic item_weapon columns,')
    lines.append('-- not mods. INSERT IGNORE: re-runnable, never clobbers existing rows.')
    lines.append('-- zz_ prefix: loads after item_mods.sql (its DROP TABLE) in dbtool full update.')
    lines.append('-- ============================================================')
    lines.append('')

    total_rows = 0
    unresolved: list[str] = []
    for item_id in sorted(ITEMS):
        entry = cache.get(str(item_id))
        disp = ITEMS[item_id]
        if not entry or not entry.get('stats'):
            unresolved.append(f'{item_id} {disp} (no cache entry)')
            continue
        stats = entry['stats']

        halved = False
        # DMG:/Delay: prefixes (weapons) -- intrinsic, strip for clean parsing.
        # Optional '+' covers the latent form (e.g. "DMG:+86").
        stats = re.sub(r'\bDMG:\s*\+?\d+\s*', ' ', stats)
        stats = re.sub(r'\bDelay:\s*\+?\d+\s*', ' ', stats)
        # Weapon combat-skill tokens ("Great Sword skill +215", "Magic Accuracy
        # skill +215", ...) are intrinsic item_weapon columns. Strip the TEXT here
        # (not just post-parse) so a weapon whose entire BASE line is skills is
        # correctly detected as latent-only below (e.g. every Voluspa weapon).
        if item_id in weapon_ids:
            stats = re.sub(r'[A-Za-z][A-Za-z.\- ]*?\bskill \+\d+', ' ', stats)
        # Pet: suffix -- out of scope (item_mods_pet).
        stats = re.split(r'\bPet:', stats)[0]
        # Latent handling.
        for latent in ('Domain Invasion:', 'Boost:'):
            if latent in stats:
                base, _, latent_part = stats.partition(latent)
                if base.strip():
                    stats = base          # base stats exist: drop the latent
                else:
                    stats = latent_part   # latent-only: keep at 50% always-on
                    halved = True

        rows, unknown = naked.parse_stats(stats, modmap)
        if item_id in weapon_ids:
            rows = [r for r in rows if r[0] not in WEAPON_INTRINSIC]
        if halved:
            rows = [(mid, max(1, round(val / 2)), f'{lbl} (50% of latent)') for mid, val, lbl in rows]

        if not rows:
            unresolved.append(f'{item_id} {disp} (nothing parseable: {stats!r})')
            continue

        note = '  [latent-only: values at 50%, always-on]' if halved else ''
        lines.append(f'-- {disp} ({item_id}) -- {entry.get("name", disp)}{note}')
        for mod_id, value, label in rows:
            lines.append(f'INSERT IGNORE INTO `item_mods` VALUES ({item_id}, {mod_id}, {value});   '
                         f'-- {name_by_id.get(mod_id, f"mod{mod_id}")} ({label})')
            total_rows += 1
        for tok in unknown:
            lines.append(f'-- TODO {disp}: unparsed token: {tok}')
        lines.append('')

    OUTPUT.write_text('\n'.join(lines), encoding='utf-8', newline='\n')
    print(f'Wrote {OUTPUT}')
    print(f'  {total_rows} mod rows across {len(ITEMS) - len(unresolved)} of {len(ITEMS)} items')
    if unresolved:
        print('  UNRESOLVED:')
        for u in unresolved:
            print(f'    {u}')
    return 0


if __name__ == '__main__':
    sys.exit(main())
