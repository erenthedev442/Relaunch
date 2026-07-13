#!/usr/bin/env python3
"""audit_player_gear.py

Cross-checks every non-GM player's held gear against the progression gates
each item's known sources require. An item is flagged as "shouldn't have" when
NONE of its sources are reachable by that player's current progression state.

Designed to run ON THE OVH LIVE BOX (has local DB + repo checkout).

    ssh Administrator@15.204.112.102
    cd C:\\server
    python tools\\audit_player_gear.py

Reads:
  docs/assets/gear-data.json                          -- item source map (docgen)
  modules/custom/lua/accessory_catalog.lua            -- HL Accessory NPC tiers
  modules/custom/lua/armor_catalog.lua                -- HL Armor NPC tiers
  modules/custom/lua/gear_progression_catalog.lua     -- HL Weapons NPC tiers
  modules/custom/lua/infamy_vendor_catalog.lua        -- Infamy Vendor

DB (xi_relaunch, credentials from settings/network.lua):
  chars, char_inventory, char_vars

Writes:
  exports/player_gear_audit.csv                       -- one row per anomaly (item held above progression)
  exports/player_gear_audit.json                      -- structured (same data)
  exports/player_gear_audit.summary.md                -- Item | Character detail table + aggregates
  exports/player_gear_audit.locked.csv                -- items on the server the char can't unlock yet
  exports/player_gear_audit.locked.summary.md         -- per-character locked-items table

Flagging philosophy:
  An item's sources are the UNION of every path the item can legitimately
  come from (vendors, drops, quests, crafts, retail loot, universal-pool
  drops like Domain Invasion). If AT LEAST ONE of those paths is reachable
  by the player (they meet its gate), the item is fine. Only when EVERY
  path is either gated content they haven't reached OR untraceable is the
  item flagged. This keeps false positives low: someone lucky at Domain
  Invasion legitimately holds a lot of gear, and items with any craft or
  retail-drop source are effectively obtainable by anyone.

Locked-items scan (2nd pass):
  For every character, walks every server item that has a KNOWN gated source
  and reports the ones where the char meets none of the gates. Filters out
  items whose only sources are UNGATED_LABELS (Craft/Retail/AH/etc.) since
  those are effectively obtainable by anyone. Bounded by the size of the
  gated-source pool (~a few hundred items), not by player count.
"""
from __future__ import annotations

import csv
import json
import os
import re
import subprocess
import sys
import textwrap
from dataclasses import dataclass, field
from pathlib import Path

# ---------------------------------------------------------------------------
# Paths (run from C:\server on OVH, or D:\server_relaunch on dev)
# ---------------------------------------------------------------------------
HERE      = Path(__file__).resolve().parent
REPO_ROOT = HERE.parent

GEAR_DATA_PATH   = REPO_ROOT / 'docs' / 'assets' / 'gear-data.json'
ACCESSORY_PATH   = REPO_ROOT / 'modules' / 'custom' / 'lua' / 'accessory_catalog.lua'
ARMOR_PATH       = REPO_ROOT / 'modules' / 'custom' / 'lua' / 'armor_catalog.lua'
WEAPONS_PATH     = REPO_ROOT / 'modules' / 'custom' / 'lua' / 'gear_progression_catalog.lua'
INFAMY_PATH      = REPO_ROOT / 'modules' / 'custom' / 'lua' / 'infamy_vendor_catalog.lua'
NETWORK_LUA_PATH = REPO_ROOT / 'settings' / 'network.lua'

OUT_DIR         = REPO_ROOT / 'exports'
OUT_CSV         = OUT_DIR / 'player_gear_audit.csv'
OUT_JSON        = OUT_DIR / 'player_gear_audit.json'
OUT_SUMM        = OUT_DIR / 'player_gear_audit.summary.md'
OUT_LOCKED_CSV  = OUT_DIR / 'player_gear_audit.locked.csv'
OUT_LOCKED_SUMM = OUT_DIR / 'player_gear_audit.locked.summary.md'

# Cap the number of locked-items rows shown per character in the markdown
# summary (the CSV always has the full list). Keeps the summary readable
# when a low-progression char is locked out of ~all vendor tiers at once.
LOCKED_MD_ROWS_PER_CHAR = 40
# Cap the flat (Item x Character) table in the locked summary. A live server
# with 20+ chars easily produces 40k+ locked rows; a markdown table that big
# is unreadable and the CSV has the full list.
LOCKED_MD_FLAT_MAX = 500

# ---------------------------------------------------------------------------
# MySQL client
# ---------------------------------------------------------------------------
MYSQL_BIN = r'C:\Program Files\MariaDB 10.6\bin\mysql.exe'

def read_db_creds() -> tuple[str, str, str]:
    """Pull SQL_LOGIN / SQL_PASSWORD / SQL_DATABASE from network.lua."""
    text = NETWORK_LUA_PATH.read_text(encoding='utf-8', errors='replace')
    def grab(key):
        m = re.search(rf"{key}\s*=\s*'([^']*)'", text)
        return m.group(1) if m else None
    login = grab('SQL_LOGIN')  or 'root'
    passw = grab('SQL_PASSWORD') or ''
    db    = grab('SQL_DATABASE') or 'xi_relaunch'
    return login, passw, db

def mysql_query(sql: str) -> list[dict]:
    """Run a SELECT and return list of dict rows. Tab-separated output parse."""
    login, passw, db = read_db_creds()
    cmd = [MYSQL_BIN, '-N', '-B', f'-u{login}', f'-p{passw}', db, '-e', sql]
    # -N: no column headers on first row  -B: tab-separated (batch)
    # NOTE: we DO want headers, so drop -N and parse row 0 as headers
    cmd_with_headers = [MYSQL_BIN, '-B', f'-u{login}', f'-p{passw}', db, '-e', sql]
    proc = subprocess.run(
        cmd_with_headers,
        stdout=subprocess.PIPE, stderr=subprocess.PIPE,
        text=True, encoding='utf-8', errors='replace',
    )
    if proc.returncode != 0:
        raise RuntimeError(f'mysql failed: {proc.stderr.strip()}')
    lines = proc.stdout.splitlines()
    if not lines:
        return []
    headers = lines[0].split('\t')
    rows: list[dict] = []
    for line in lines[1:]:
        parts = line.split('\t')
        rows.append(dict(zip(headers, parts)))
    return rows

# ---------------------------------------------------------------------------
# Gear-data source map
# ---------------------------------------------------------------------------
@dataclass
class ItemSources:
    itemid: int
    name: str
    system_labels: list[str] = field(default_factory=list)    # e.g. ["Voidwatch"]
    drop_mobs:     list[dict] = field(default_factory=list)   # [{m: ..., z: ..., p: ...}]

    def is_untracked(self) -> bool:
        """True if this item has no known source at all (orphan)."""
        return not self.system_labels and not self.drop_mobs

def load_gear_sources() -> dict[int, ItemSources]:
    with GEAR_DATA_PATH.open(encoding='utf-8') as f:
        data = json.load(f)
    items = data.get('items', data) if isinstance(data, dict) else data
    result: dict[int, ItemSources] = {}
    for it in items:
        iid = it.get('i')
        if not iid:
            continue
        srcs = it.get('src') or []
        sys_labels = [s['s'] for s in srcs if isinstance(s, dict) and s.get('s')]
        drop_rows  = [s     for s in srcs if isinstance(s, dict) and s.get('m')]
        result[iid] = ItemSources(
            itemid=iid,
            name=it.get('n', '?'),
            system_labels=sys_labels,
            drop_mobs=drop_rows,
        )
    return result

# ---------------------------------------------------------------------------
# Vendor tier gates -- parse the 4 vendor catalogs to know which tier each
# item lives in, so we can gate them by HL_Tier / Infamy_Lifetime.
# ---------------------------------------------------------------------------
# HL_Tier charvar: 0 Initiate, 1 Bronze, 2 Silver, 3 Gold, 4 Legend
HL_TIER_BRONZE = 1
HL_TIER_SILVER = 2
HL_TIER_GOLD   = 3

TIER_VAR_MAP = {'bronze': HL_TIER_BRONZE, 'silver': HL_TIER_SILVER, 'gold': HL_TIER_GOLD}

@dataclass
class VendorGate:
    kind: str            # 'hl_tier', 'infamy_lifetime', 'unknown'
    required: int = 0    # HL_Tier N, or Infamy_Lifetime N
    note: str = ''

# id -> VendorGate for items sold by a vendor
vendor_gates: dict[int, VendorGate] = {}

# scan_vendor_catalog: extract (id, tier) from a Lua catalog.
# HL catalogs use local 'b'/'s'/'g' after `local b = catalog.bronze` etc.
# Infamy vendor has `vendorItems = { { id = X, cost = N, ... }, ... }`.

_TIER_ASSIGN_PAT = re.compile(
    r"local\s+(\w+)\s*=\s*catalog\.(bronze|silver|gold)\b"
)
_INSERT_PAT = re.compile(
    r"table\.insert\s*\(\s*(\w+)\s*\.\s*\w+\s*,\s*\{[^{}]*\bid\s*=\s*(\d{3,5})\b"
)
# gear_progression_catalog uses inline `local inf_swords = cat(catalog.infamy.weapons, ...)`.
_CAT_ASSIGN_PAT = re.compile(
    r"local\s+(\w+)\s*=\s*cat\s*\(\s*catalog\.(\w+)\.\w+\b"
)
_INSERT_PAT_ALT = re.compile(
    r"table\.insert\s*\(\s*(\w+)\s*,\s*\{[^{}]*\bid\s*=\s*(\d{3,5})\b"
)

def scan_hl_vendor(path: Path, kind_label: str) -> None:
    """HL accessory / armor catalog: local b/s/g -> catalog.bronze/silver/gold."""
    if not path.exists():
        return
    src = path.read_text(encoding='utf-8', errors='replace')
    alias_to_tier: dict[str, str] = {}
    for m in _TIER_ASSIGN_PAT.finditer(src):
        alias_to_tier[m.group(1)] = m.group(2)
    for m in _INSERT_PAT.finditer(src):
        alias, iid = m.group(1), int(m.group(2))
        tier = alias_to_tier.get(alias)
        if tier and tier in TIER_VAR_MAP:
            vendor_gates.setdefault(iid, VendorGate(
                kind='hl_tier',
                required=TIER_VAR_MAP[tier],
                note=f'{kind_label} {tier} tier',
            ))

def scan_hl_weapons(path: Path) -> None:
    """gear_progression_catalog: local inf_swords = cat(catalog.infamy.weapons, ...)."""
    if not path.exists():
        return
    src = path.read_text(encoding='utf-8', errors='replace')
    # First: bronze/silver/gold rings via catalog.bronze/silver/gold
    scan_hl_vendor(path, 'HL Weapons')
    # Second: infamy-tagged aliases
    alias_to_bucket: dict[str, str] = {}
    for m in _CAT_ASSIGN_PAT.finditer(src):
        alias, bucket = m.group(1), m.group(2)
        alias_to_bucket[alias] = bucket
    for m in _INSERT_PAT_ALT.finditer(src):
        alias, iid = m.group(1), int(m.group(2))
        bucket = alias_to_bucket.get(alias)
        if bucket == 'infamy':
            # Weapons in infamy bucket cost 500 Infamy per line -- read the cost
            # from the same insert line if we can, else fall back to 500.
            line_start = src.rfind('table.insert(' + alias, 0, m.end())
            line_end   = src.find('\n', m.end())
            insert_line = src[line_start:line_end] if line_start != -1 else ''
            cost_m = re.search(r"cost\s*=\s*(\d+)", insert_line)
            cost   = int(cost_m.group(1)) if cost_m else 500
            vendor_gates.setdefault(iid, VendorGate(
                kind='infamy_lifetime',
                required=cost,
                note=f'HL Weapons infamy bucket ({cost} infamy)',
            ))

_INFAMY_VENDOR_ROW = re.compile(
    r"\{\s*id\s*=\s*(\d{3,5})[^{}]*cost\s*=\s*(\d+)",
)

def scan_infamy_vendor(path: Path) -> None:
    """infamy_vendor_catalog.lua: vendorItems = { { id=X, cost=N, ... }, ... }."""
    if not path.exists():
        return
    src = path.read_text(encoding='utf-8', errors='replace')
    for m in _INFAMY_VENDOR_ROW.finditer(src):
        iid, cost = int(m.group(1)), int(m.group(2))
        vendor_gates.setdefault(iid, VendorGate(
            kind='infamy_lifetime',
            required=cost,
            note=f'Infamy Vendor ({cost} infamy)',
        ))

def load_vendor_gates() -> None:
    scan_hl_vendor(ACCESSORY_PATH, 'HL Accessories')
    scan_hl_vendor(ARMOR_PATH,     'HL Armor')
    scan_hl_weapons(WEAPONS_PATH)
    scan_infamy_vendor(INFAMY_PATH)

# ---------------------------------------------------------------------------
# System-label -> gate check.
#
# Each system label maps to a check function that returns True if the player's
# progression state SATISFIES that source. If ANY source of an item passes,
# the item is legitimate.
# ---------------------------------------------------------------------------
def _cv(state: dict, name: str) -> int:
    try:
        return int(state.get(name, 0) or 0)
    except (TypeError, ValueError):
        return 0

# Open-world / craft sources -- no meaningful gate; anyone can hit these.
UNGATED_LABELS = {
    'Craft', 'Retail Drop', 'Retail', 'Quest', 'Quest Reward',
    'Zeni', 'AH', 'Bazaar', 'Gil', 'Gil Shop', 'Gil Vendor',
    'NPC', 'NPC Shop', 'Domain Invasion',   # universal wildcard pool
    'Sparks', 'Bayld', 'Cruor', 'Aman Vouchers', 'Records of Eminence',
    'Coalition',
}

def gate_ok(label: str, iid: int, state: dict) -> bool:
    """True if this SYSTEM label's gate is met by the player."""
    if label in UNGATED_LABELS:
        return True

    # Vendor: use the tier map we built.
    if label == 'Gear Vendor':
        vg = vendor_gates.get(iid)
        if not vg or vg.kind == 'unknown':
            # We don't know which vendor -- assume vendor-buyable = open enough.
            return True
        if vg.kind == 'hl_tier':
            return _cv(state, 'HL_Tier') >= vg.required
        if vg.kind == 'infamy_lifetime':
            return _cv(state, 'Infamy_Lifetime') >= vg.required
        return True

    if label == 'Infamy Vendor':
        vg = vendor_gates.get(iid)
        need = vg.required if vg else 3000
        return _cv(state, 'Infamy_Lifetime') >= need

    # HTBF: catch-all -- any T1/T2/T3 clear counts as "unlocked HTBF".
    if label == 'HTBF':
        return (_cv(state, 'HTBF_Cleared_T1') +
                _cv(state, 'HTBF_Cleared_T2') +
                _cv(state, 'HTBF_Cleared_T3')) > 0

    # Voidwatch: any Voidwalker credit = open.
    if label == 'Voidwatch':
        return _cv(state, 'Voidwalker_Kills') > 0 or _cv(state, 'Voidwatch_Kills') > 0

    if label == 'Ambuscade':
        return _cv(state, 'Amb_HM_Earned') > 0 or _cv(state, 'Amb_Cap_Month') > 0

    if label.startswith('Prime') or label == 'Prime Armory':
        return any(_cv(state, f'PW_Trial{i}_Done') > 0 for i in (1, 2, 3, 4, 5))

    if label == 'Reforge' or label.startswith('Reforge'):
        return _cv(state, 'Reforge_Unlocked') > 0 or _cv(state, 'Job_Mastery_Total') > 0

    if label.startswith('Dynamis'):
        return _cv(state, 'Dynamis_Clears') > 0 or _cv(state, 'Dynamis_D_Clears') > 0

    if label == 'Custom Dungeon' or label.startswith('Dungeon'):
        return _cv(state, 'Dungeon_Clears_Total') > 0

    if label == 'HNM' or label.endswith(' King') or label.startswith('HNM'):
        return _cv(state, 'HNM_King_Kills') > 0

    if label == 'Weapon Forge' or label == 'Forge':
        return _cv(state, 'Weapon_Forge_Progress') > 0

    if label == 'Nyzul':
        return _cv(state, 'Nyzul_Floor_Cleared') > 0

    # Unknown label -- err on the side of "assume reachable" so we don't
    # generate noise from a new label the mapping hasn't been updated for.
    return True

# ---------------------------------------------------------------------------
# Player state fetch
# ---------------------------------------------------------------------------
# All char_inventory locations we consider "holding" -- includes wardrobes,
# safes, storage, satchel, sack, case, locker. Excludes temp (3), recycle bin
# (14+), and mannequin heads.
HOLD_LOCATIONS = [0, 1, 2, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13]

@dataclass
class Player:
    charid: int
    name: str
    gmlevel: int
    state: dict[str, int] = field(default_factory=dict)
    items: dict[int, int] = field(default_factory=dict)  # itemid -> quantity

def fetch_players() -> list[Player]:
    rows = mysql_query('SELECT charid, charname, gmlevel FROM chars ORDER BY charid')
    out: list[Player] = []
    for r in rows:
        try:
            gml = int(r.get('gmlevel', 0) or 0)
        except ValueError:
            gml = 0
        if gml >= 1:
            continue  # skip GM chars
        out.append(Player(
            charid=int(r['charid']),
            name=r['charname'],
            gmlevel=gml,
        ))
    return out

def populate_player(p: Player) -> None:
    # Inventory across all holding locations.
    locs = ','.join(str(x) for x in HOLD_LOCATIONS)
    rows = mysql_query(
        f'SELECT itemId, SUM(quantity) AS qty FROM char_inventory '
        f'WHERE charid = {p.charid} AND location IN ({locs}) '
        f'GROUP BY itemId'
    )
    for r in rows:
        try:
            iid = int(r['itemId']); qty = int(r['qty'])
        except (KeyError, ValueError):
            continue
        if iid == 0 or iid == 65535:
            continue
        p.items[iid] = p.items.get(iid, 0) + qty
    # Charvars (all of them -- overkill but bounded and simplifies future gates).
    rows = mysql_query(f'SELECT varname, value FROM char_vars WHERE charid = {p.charid}')
    for r in rows:
        vn = r.get('varname')
        try:
            v = int(r.get('value', 0) or 0)
        except ValueError:
            v = 0
        if vn:
            p.state[vn] = v

# ---------------------------------------------------------------------------
# Anomaly detection
# ---------------------------------------------------------------------------
@dataclass
class Finding:
    charid:   int
    charname: str
    itemid:   int
    itemname: str
    quantity: int
    reason:   str        # 'no_source' | 'all_gated'
    sources:  list[str]  # human-readable list of the item's sources

def check_item(state: dict, iid: int, qty: int, sources: ItemSources) -> Finding | None:
    if sources.is_untracked():
        # No known source in gear-data.json. Interesting only for equippable items
        # -- consumables/materials without a source flood the report. Filter by
        # gear-data.json presence: if the item made the source-map cut it's an
        # equippable (they're what the map indexes), so it's worth flagging.
        return Finding(
            charid=0, charname='',
            itemid=iid, itemname=sources.name, quantity=qty,
            reason='no_source', sources=[],
        )

    # Scan all sources: if ANY passes, item is legit.
    label_reasons: list[str] = []
    for lbl in sources.system_labels:
        label_reasons.append(f'sys:{lbl}')
        if gate_ok(lbl, iid, state):
            return None
    for d in sources.drop_mobs:
        mob = d.get('m', '?')
        z   = d.get('z', '?')
        label_reasons.append(f'drop:{mob}({z})')
        # Drop-source gates: parenthesized system tag in mob name, else zone.
        pm = re.search(r'\(([^)]+)\)', mob)
        drop_sys = pm.group(1) if pm else z
        if drop_sys and gate_ok(drop_sys, iid, state):
            return None

    return Finding(
        charid=0, charname='',
        itemid=iid, itemname=sources.name, quantity=qty,
        reason='all_gated', sources=label_reasons,
    )

# ---------------------------------------------------------------------------
# Locked-items scan (2nd pass)
#
# For each character, walk every item in the source map and report items the
# character can't currently obtain (no source's gate is met). Bounded to
# items that have at least ONE non-ungated source -- if every source is
# ungated (Craft/AH/Retail Drop/Domain Invasion), the item is effectively
# open to everyone and doesn't belong on a "locked" report.
# ---------------------------------------------------------------------------
@dataclass
class LockedItem:
    charid:   int
    charname: str
    itemid:   int
    itemname: str
    sources:  list[str]     # every known source with (met/unmet) tag

def _source_line(label: str, iid: int, state: dict, sub: str = '') -> str:
    """Human-readable 'system-label(needs=...)' tag for a locked-source row."""
    if label in UNGATED_LABELS:
        return f'{label}[open]'
    vg = vendor_gates.get(iid)
    if label == 'Gear Vendor' and vg and vg.kind == 'hl_tier':
        return f'{label}[need HL_Tier>={vg.required}]'
    if label in ('Gear Vendor', 'Infamy Vendor') and vg and vg.kind == 'infamy_lifetime':
        return f'{label}[need Infamy_Lifetime>={vg.required}]'
    return f'{label}[gate not met]'

def has_any_progression_gate(src: ItemSources) -> bool:
    """True if any of the item's sources is NOT in UNGATED_LABELS.

    Items whose only sources are Craft/AH/Retail Drop/Domain Invasion etc.
    are effectively open to everyone; filtering them out keeps the locked
    report focused on progression-content-gated items.
    """
    for lbl in src.system_labels:
        if lbl not in UNGATED_LABELS:
            return True
    for d in src.drop_mobs:
        mob = d.get('m', '?')
        z   = d.get('z', '?')
        pm = re.search(r'\(([^)]+)\)', mob)
        drop_sys = pm.group(1) if pm else z
        if drop_sys and drop_sys not in UNGATED_LABELS:
            return True
    return False

def find_locked_items(state: dict, sources_map: dict[int, ItemSources]) -> list[LockedItem]:
    """Return items the char can't obtain: every source's gate fails."""
    out: list[LockedItem] = []
    for iid, src in sources_map.items():
        if src.is_untracked():
            continue
        if not has_any_progression_gate(src):
            continue   # open to everyone -- not "locked"
        # any source reachable? then it's obtainable, skip.
        reachable = False
        source_tags: list[str] = []
        for lbl in src.system_labels:
            if gate_ok(lbl, iid, state):
                reachable = True
                break
            source_tags.append(_source_line(lbl, iid, state))
        if reachable:
            continue
        for d in src.drop_mobs:
            mob = d.get('m', '?')
            z   = d.get('z', '?')
            pm = re.search(r'\(([^)]+)\)', mob)
            drop_sys = pm.group(1) if pm else z
            if drop_sys and gate_ok(drop_sys, iid, state):
                reachable = True
                break
            source_tags.append(f'drop:{mob}({z})[gate not met]')
        if reachable:
            continue
        out.append(LockedItem(
            charid=0, charname='',
            itemid=iid, itemname=src.name,
            sources=source_tags,
        ))
    return out

# ---------------------------------------------------------------------------
# Output
# ---------------------------------------------------------------------------
def _md_escape(text: str) -> str:
    """Escape pipe chars so cell content doesn't break table columns."""
    return text.replace('|', '\\|')

def write_outputs(findings: list[Finding], player_count: int) -> None:
    OUT_DIR.mkdir(exist_ok=True)

    # CSV -- one row per (character, item) finding. Item first so a text-sort
    # groups by item across characters (useful when triaging a single mis-drop).
    with OUT_CSV.open('w', newline='', encoding='utf-8') as f:
        w = csv.writer(f)
        w.writerow(['itemname', 'itemid', 'charname', 'charid', 'quantity',
                    'reason', 'sources'])
        for x in sorted(findings, key=lambda x: (x.itemname.lower(), x.charname.lower())):
            w.writerow([x.itemname, x.itemid, x.charname, x.charid, x.quantity,
                        x.reason, ' | '.join(x.sources)])

    # JSON
    with OUT_JSON.open('w', encoding='utf-8') as f:
        json.dump([x.__dict__ for x in findings], f, indent=2)

    # Summary: single Item | Character detail table (the deliverable) followed
    # by count aggregates for scanning at a glance.
    by_reason: dict[str, int]  = {}
    by_item:   dict[str, int]  = {}
    by_char:   dict[str, int]  = {}
    for x in findings:
        by_reason[x.reason] = by_reason.get(x.reason, 0) + 1
        by_item[x.itemname] = by_item.get(x.itemname, 0) + 1
        by_char[x.charname] = by_char.get(x.charname, 0) + 1

    top_items = sorted(by_item.items(), key=lambda kv: -kv[1])[:25]
    top_chars = sorted(by_char.items(), key=lambda kv: -kv[1])[:25]

    with OUT_SUMM.open('w', encoding='utf-8') as f:
        f.write('# Player gear audit -- items held above progression\n\n')
        f.write(f'- Non-GM characters scanned: **{player_count}**\n')
        f.write(f'- Total findings: **{len(findings)}**\n\n')
        f.write('## By reason\n\n')
        for k, v in sorted(by_reason.items(), key=lambda kv: -kv[1]):
            f.write(f'- **{k}**: {v}\n')

        # The requested table: Item + Character in the same row, alphabetized
        # by item so the same item across multiple players is contiguous.
        f.write('\n## Findings (Item x Character)\n\n')
        if findings:
            f.write('| Item | Item ID | Character | Qty | Reason | Sources |\n')
            f.write('|---|---:|---|---:|---|---|\n')
            for x in sorted(findings, key=lambda x: (x.itemname.lower(), x.charname.lower())):
                srcs = _md_escape(' \\| '.join(x.sources) if x.sources else '(none)')
                f.write(
                    f'| {_md_escape(x.itemname)} | {x.itemid} '
                    f'| {_md_escape(x.charname)} | {x.quantity} '
                    f'| {x.reason} | {srcs} |\n'
                )
        else:
            f.write('_No anomalies._\n')

        f.write('\n## Top 25 items (most-flagged)\n\n')
        f.write('| Item | Count |\n|---|---:|\n')
        for name, c in top_items:
            f.write(f'| {_md_escape(name)} | {c} |\n')
        f.write('\n## Top 25 characters (most-flagged)\n\n')
        f.write('| Character | Count |\n|---|---:|\n')
        for name, c in top_chars:
            f.write(f'| {_md_escape(name)} | {c} |\n')

def write_locked_outputs(locked: list[LockedItem], player_count: int) -> None:
    """Write the 2nd-pass 'items on the server the char can't unlock' report.

    CSV has every row; the markdown summary caps per-character rows at
    LOCKED_MD_ROWS_PER_CHAR to stay readable for low-progression chars who
    are locked out of nearly every vendor tier at once.
    """
    OUT_DIR.mkdir(exist_ok=True)

    with OUT_LOCKED_CSV.open('w', newline='', encoding='utf-8') as f:
        w = csv.writer(f)
        w.writerow(['itemname', 'itemid', 'charname', 'charid', 'locked_sources'])
        for x in sorted(locked, key=lambda x: (x.itemname.lower(), x.charname.lower())):
            w.writerow([x.itemname, x.itemid, x.charname, x.charid,
                        ' | '.join(x.sources)])

    # Per-character bucket for the summary markdown.
    by_char: dict[str, list[LockedItem]] = {}
    for x in locked:
        by_char.setdefault(x.charname, []).append(x)

    with OUT_LOCKED_SUMM.open('w', encoding='utf-8') as f:
        f.write('# Player gear audit -- items available but not yet unlocked\n\n')
        f.write(f'- Non-GM characters scanned: **{player_count}**\n')
        f.write(f'- Total locked-item rows: **{len(locked)}**\n')
        f.write(f'- Characters with at least one locked item: **{len(by_char)}**\n\n')
        f.write(
            'Each row is an item that exists on the server with at least one\n'
            'progression-gated source, but the character hasn\'t met any of\n'
            f'those gates. Full detail in `{OUT_LOCKED_CSV.name}`; summary caps\n'
            f'at {LOCKED_MD_ROWS_PER_CHAR} rows per character.\n\n'
        )

        # Flat "Item x Character" table so this file mirrors the anomaly
        # summary's shape. Capped at LOCKED_MD_FLAT_MAX rows -- the CSV is the
        # complete list. Pick the first N alphabetized rows so the sample is
        # deterministic and consecutive characters/items stay together.
        f.write('## Locked items (Item x Character)\n\n')
        if locked:
            flat = sorted(locked, key=lambda x: (x.itemname.lower(), x.charname.lower()))
            f.write(f'Showing first **{min(len(flat), LOCKED_MD_FLAT_MAX)}** of '
                    f'**{len(flat)}** rows. Full list in `{OUT_LOCKED_CSV.name}`.\n\n')
            f.write('| Item | Item ID | Character | Locked sources |\n')
            f.write('|---|---:|---|---|\n')
            for x in flat[:LOCKED_MD_FLAT_MAX]:
                srcs = _md_escape(' \\| '.join(x.sources) if x.sources else '(none)')
                f.write(
                    f'| {_md_escape(x.itemname)} | {x.itemid} '
                    f'| {_md_escape(x.charname)} | {srcs} |\n'
                )
        else:
            f.write('_No locked items._\n')

        # Per-character breakdown, capped for readability.
        f.write('\n## By character\n\n')
        for name in sorted(by_char):
            rows = sorted(by_char[name], key=lambda x: x.itemname.lower())
            f.write(f'### {name} ({len(rows)} locked)\n\n')
            f.write('| Item | Item ID | Locked sources |\n')
            f.write('|---|---:|---|\n')
            for x in rows[:LOCKED_MD_ROWS_PER_CHAR]:
                srcs = _md_escape(' \\| '.join(x.sources) if x.sources else '(none)')
                f.write(f'| {_md_escape(x.itemname)} | {x.itemid} | {srcs} |\n')
            if len(rows) > LOCKED_MD_ROWS_PER_CHAR:
                f.write(f'\n_...{len(rows) - LOCKED_MD_ROWS_PER_CHAR} more in `{OUT_LOCKED_CSV.name}`._\n')
            f.write('\n')

# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------
def main() -> int:
    if not GEAR_DATA_PATH.exists():
        print(f'ERROR: gear-data.json not found at {GEAR_DATA_PATH}', file=sys.stderr)
        return 2
    print(f'Loading gear-data.json ...', flush=True)
    sources = load_gear_sources()
    print(f'  {len(sources)} items with a source record')

    load_vendor_gates()
    print(f'  {len(vendor_gates)} items mapped to a vendor tier gate')

    print(f'Fetching non-GM players from xi_relaunch ...', flush=True)
    players = fetch_players()
    print(f'  {len(players)} characters to scan')

    findings: list[Finding] = []
    locked:   list[LockedItem] = []
    for i, p in enumerate(players, 1):
        if i % 50 == 0 or i == len(players):
            print(
                f'  {i}/{len(players)} {p.name} '
                f'({len(findings)} findings, {len(locked)} locked so far)',
                flush=True,
            )
        populate_player(p)
        for iid, qty in p.items.items():
            src = sources.get(iid)
            if not src:
                # Item not indexed in gear-data.json at all -- almost certainly
                # a non-equippable (consumable/material/currency). Skip.
                continue
            f = check_item(p.state, iid, qty, src)
            if f:
                f.charid   = p.charid
                f.charname = p.name
                findings.append(f)

        # 2nd pass: items on the server this char hasn't unlocked yet.
        for li in find_locked_items(p.state, sources):
            li.charid   = p.charid
            li.charname = p.name
            locked.append(li)

    print(f'\nTotal findings: {len(findings)}')
    print(f'Total locked-item rows: {len(locked)}')
    write_outputs(findings, len(players))
    write_locked_outputs(locked, len(players))
    print(f'Wrote {OUT_CSV}')
    print(f'Wrote {OUT_JSON}')
    print(f'Wrote {OUT_SUMM}')
    print(f'Wrote {OUT_LOCKED_CSV}')
    print(f'Wrote {OUT_LOCKED_SUMM}')
    return 0

if __name__ == '__main__':
    sys.exit(main())
