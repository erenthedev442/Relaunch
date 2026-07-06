#!/usr/bin/env python3
"""
gen_reforge_plus4_map.py

Build an authoritative map from each reforged-armor +3 item ID to its +4
counterpart, so an upgrade NPC can turn a +3 piece into its +4.

METHOD (name-pairing -- robust against ID-block irregularities):
  * Parse sql/item_basic.sql. The 3rd VALUES field is the lowercase internal
    name (e.g. 'boii_mask_+3', 'archmages_petasos_+4'). Tier suffix is _+1.._+4.
  * Collect every item whose name ends _+3 and every item ending _+4.
  * Pair them where the BASE (name minus the tier suffix) is identical:
        map[<+3 id>] = <+4 id>
  * For each pair pull job + slot from sql/item_equipment.sql (VALUES layout:
        0=id 1=name 2=level 3=ilvl 4=jobs_bitmask 5..7=unused 8=slot_bitmask).
    Keep only the 5 armor slots (head/body/hands/legs/feet). Single-set bit in
    the jobs mask -> 3-letter job (1<<(jobId-1)); multi-job pieces are still
    recorded but flagged.

OUTPUT: modules/custom/lua/reforge_plus4_map.lua
        [<+3id>] = { result = <+4id>, slot = '<slot>', job = '<JOB>', name = '<Pretty +4>' }
        sorted by job then slot.

Run from the worktree root:  python tools/gen_reforge_plus4_map.py
"""

import re
import sys
from pathlib import Path

REPO = Path(__file__).resolve().parents[1]

ITEM_BASIC     = REPO / 'sql' / 'item_basic.sql'
ITEM_EQUIPMENT = REPO / 'sql' / 'item_equipment.sql'
OUT_LUA        = REPO / 'modules' / 'custom' / 'lua' / 'reforge_plus4_map.lua'

# Slot bitmask -> canonical slot key (only the 5 reforge armor slots).
SLOT_MAP = {
    16:  'head',
    32:  'body',
    64:  'hands',
    128: 'legs',
    256: 'feet',
}
SLOT_ORDER = {'head': 0, 'body': 1, 'hands': 2, 'legs': 3, 'feet': 4}

# jobId -> 3-letter code. Job bit in the mask = 1 << (jobId - 1).
JOB_BY_ID = {
    1: 'WAR', 2: 'MNK', 3: 'WHM', 4: 'BLM', 5: 'RDM', 6: 'THF', 7: 'PLD',
    8: 'DRK', 9: 'BST', 10: 'BRD', 11: 'RNG', 12: 'SAM', 13: 'NIN', 14: 'DRG',
    15: 'SMN', 16: 'BLU', 17: 'COR', 18: 'PUP', 19: 'DNC', 20: 'SCH',
    21: 'GEO', 22: 'RUN',
}
# Reverse: 3-letter code -> jobId. Used to derive the Paragon job card id
# (pcard = 9280 + jobId; 9281=WAR .. 9302=RUN).
ID_BY_JOB = {code: jid for jid, code in JOB_BY_ID.items()}

# Manual +3 -> +4 id pairs that name-pairing misses (the +3 and +4 internal
# base names differ, e.g. 'laksamanas_*_+3' vs 'laksamana_*_+4', or the +4 row
# dropped/changed the tier suffix). Processed exactly like a normal pair:
# slot/job/name are still derived from the DB via the +4 item_equipment row.
OVERRIDES = {
    23391: 23911,  # Laksamana(s) Tricorne +3 -> +4  (COR head)
    23458: 23956,  # Laksamana(s) Frac +3 -> +4      (COR body)
    23659: 24091,  # Laksamana(s) Bottes +3 -> +4    (COR feet)
    23512: 23988,  # Spaekona's Gloves +3 -> +4      (BLM hands)
    23516: 23992,  # Ignominy Gauntlets +3 -> Finger Gauntlets +4 (DRK hands)
    23665: 24097,  # Runeist Bottes +3 -> Runeist Boots +4        (RUN feet)
}

TIER_RE = re.compile(r'_\+(\d)$')


def die(msg):
    sys.stderr.write('ERROR: ' + msg + '\n')
    sys.exit(1)


def split_values(chunk):
    """Split a VALUES(...) inner body on top-level commas, ignoring commas
    inside single-quoted strings. Returns the raw field strings (untrimmed)."""
    fields = []
    buf = []
    in_str = False
    i = 0
    n = len(chunk)
    while i < n:
        c = chunk[i]
        if in_str:
            if c == "'":
                # doubled '' escape inside a SQL string
                if i + 1 < n and chunk[i + 1] == "'":
                    buf.append("''")
                    i += 2
                    continue
                in_str = False
            buf.append(c)
        else:
            if c == "'":
                in_str = True
                buf.append(c)
            elif c == ',':
                fields.append(''.join(buf))
                buf = []
            else:
                buf.append(c)
        i += 1
    fields.append(''.join(buf))
    return fields


# Matches:  INSERT INTO `item_basic` VALUES (....);  (also without backticks)
INSERT_RE = re.compile(
    r"INSERT\s+INTO\s+`?(?P<table>\w+)`?\s+VALUES\s*\((?P<body>.*)\)\s*;",
    re.IGNORECASE,
)


def parse_item_basic(path):
    """Return (name_to_id, dup_names, id_to_name).
    name_to_id indexes id keyed by internal name (tier filtering happens later).
    id_to_name is the authoritative id->name (some names are shared by an NQ and
    a reforged id, so name_to_id loses one; id_to_name never collides)."""
    if not path.exists():
        die(f'missing {path}')
    name_to_id = {}
    dup_names = {}
    id_to_name = {}
    with path.open('r', encoding='utf-8', errors='replace') as fh:
        for line in fh:
            if 'INSERT' not in line:
                continue
            m = INSERT_RE.search(line)
            if not m or m.group('table').lower() != 'item_basic':
                continue
            fields = split_values(m.group('body'))
            if len(fields) < 3:
                continue
            try:
                item_id = int(fields[0].strip())
            except ValueError:
                continue
            name = fields[2].strip().strip("'")
            if not name:
                continue
            if name in name_to_id and name_to_id[name] != item_id:
                dup_names.setdefault(name, [name_to_id[name]]).append(item_id)
            name_to_id[name] = item_id
            id_to_name[item_id] = name
    return name_to_id, dup_names, id_to_name


def parse_item_equipment(path):
    """Return dict id -> (jobs_bitmask, slot_bitmask) for every row."""
    if not path.exists():
        die(f'missing {path}')
    equip = {}
    with path.open('r', encoding='utf-8', errors='replace') as fh:
        for line in fh:
            if 'INSERT' not in line:
                continue
            m = INSERT_RE.search(line)
            if not m or m.group('table').lower() != 'item_equipment':
                continue
            fields = split_values(m.group('body'))
            if len(fields) < 9:
                continue
            try:
                item_id = int(fields[0].strip())
                jobs = int(fields[4].strip())
                slot = int(fields[8].strip())
            except ValueError:
                continue
            equip[item_id] = (jobs, slot)
    return equip


def jobs_from_mask(mask):
    """Return list of 3-letter job codes whose bit is set in the mask."""
    out = []
    for job_id, code in JOB_BY_ID.items():
        if mask & (1 << (job_id - 1)):
            out.append(code)
    return out


def pretty_name(internal_plus4):
    """'archmages_petasos_+4' -> 'Archmages Petasos +4'."""
    # keep the +N token intact; title-case the words only.
    parts = internal_plus4.split('_')
    out = []
    for p in parts:
        if p.startswith('+'):
            out.append(p)
        elif p == '':
            continue
        else:
            out.append(p[:1].upper() + p[1:])
    return ' '.join(out)


def main():
    name_to_id, dup_names, id_to_name = parse_item_basic(ITEM_BASIC)
    equip = parse_item_equipment(ITEM_EQUIPMENT)

    # Bucket names by tier suffix -> { base_name : id }
    plus3 = {}
    plus4 = {}
    for name, item_id in name_to_id.items():
        m = TIER_RE.search(name)
        if not m:
            continue
        tier = m.group(1)
        base = name[: m.start()]  # strip the _+N suffix
        if tier == '3':
            plus3[base] = (name, item_id)
        elif tier == '4':
            plus4[base] = (name, item_id)

    # Diagnostics accumulators (printed to stderr, not into the .lua).
    anomalies = []

    entries = []          # kept armor-slot pairs
    multijob = []         # pairs recorded but multi-job
    skipped = {'nonarmor': 0}  # paired but slot not one of the 5 armor slots
    unmapped_slot = []    # paired but +4 id missing from item_equipment
    seen_id3 = set()      # guard against a +3 id being emitted twice

    def build_entry(id3, id4, n4, base):
        """Derive slot/job/name/pcard for one +3->+4 pair from the DB and
        append it to `entries` (or record a diagnostic and skip). Shared by the
        name-paired pass and the manual OVERRIDES so both behave identically."""
        if id3 in seen_id3:
            return
        eq4 = equip.get(id4)
        eq3 = equip.get(id3)
        # Prefer the +4 row for job/slot; fall back to the +3 row.
        src = eq4 if eq4 is not None else eq3
        if src is None:
            unmapped_slot.append((base, id3, id4))
            return
        jobs_mask, slot_mask = src

        slot = SLOT_MAP.get(slot_mask)
        if slot is None:
            skipped['nonarmor'] += 1
            return

        job_codes = jobs_from_mask(jobs_mask)
        if len(job_codes) == 1:
            job = job_codes[0]
        elif len(job_codes) == 0:
            job = '???'
            anomalies.append(f'{n4} (id {id4}) has EMPTY jobs mask {jobs_mask}')
        else:
            job = job_codes[0]
            multijob.append((n4, id4, job_codes, slot))

        # Paragon job card (the material gate). pcard = 9280 + jobId.
        # '???' (empty jobs mask) has no card; leave pcard = 0 so the forge
        # module can skip/flag it rather than pointing at a bogus id 9280.
        job_id = ID_BY_JOB.get(job, 0)
        pcard = (9280 + job_id) if job_id else 0

        seen_id3.add(id3)
        entries.append({
            'id3': id3,
            'id4': id4,
            'slot': slot,
            'job': job,
            'pcard': pcard,
            'name': pretty_name(n4),
            'multijob': job_codes if len(job_codes) > 1 else None,
        })

        # sanity: +3 and +4 should agree on slot when both present
        if eq3 is not None and eq4 is not None:
            s3 = SLOT_MAP.get(eq3[1])
            s4 = SLOT_MAP.get(eq4[1])
            if s3 != s4:
                anomalies.append(
                    f'{base}: +3 slot {s3} != +4 slot {s4} (ids {id3}/{id4})')

    # ---- name-paired pass ----
    for base, (n3, id3) in plus3.items():
        if base not in plus4:
            continue  # dead-end +3 (reported later against reforge_catalog)
        n4, id4 = plus4[base]
        build_entry(id3, id4, n4, base)

    # ---- manual overrides (name-pairing missed these) ----
    for id3, id4 in OVERRIDES.items():
        n4 = id_to_name.get(id4, 'item_%d' % id4)
        base = n4  # only used for diagnostics
        build_entry(id3, id4, n4, base)

    # Sort by job (catalog job order) then slot.
    job_rank = {code: i for i, (jid, code) in enumerate(JOB_BY_ID.items())}
    entries.sort(key=lambda e: (job_rank.get(e['job'], 99),
                                SLOT_ORDER.get(e['slot'], 9),
                                e['id3']))

    # ---- write the Lua ----
    lines = []
    lines.append('-- AUTO-GENERATED by tools/gen_reforge_plus4_map.py -- do not hand-edit.')
    lines.append('-- Maps each reforged-armor +3 item ID to its +4 counterpart (name-paired')
    lines.append('-- from sql/item_basic.sql; job/slot from sql/item_equipment.sql).')
    lines.append(f'-- {len(entries)} pairs across the 5 armor slots (head/body/hands/legs/feet).')
    lines.append('return {')
    cur_job = None
    for e in entries:
        if e['job'] != cur_job:
            lines.append(f"    -- {e['job']}")
            cur_job = e['job']
        tag = ''
        if e['multijob']:
            tag = '  -- MULTI-JOB: ' + '/'.join(e['multijob'])
        lines.append(
            "    [%d] = { result = %d, slot = '%s', job = '%s', pcard = %d, name = '%s' },%s"
            % (e['id3'], e['id4'], e['slot'], e['job'], e['pcard'],
               e['name'].replace("'", "\\'"), tag)
        )
    lines.append('}')
    lines.append('')

    OUT_LUA.parent.mkdir(parents=True, exist_ok=True)
    OUT_LUA.write_text('\n'.join(lines), encoding='utf-8')

    # ---- diagnostics to stderr ----
    def err(s=''):
        sys.stderr.write(s + '\n')

    err(f'Wrote {OUT_LUA} with {len(entries)} entries.')
    err(f'  +3 names in item_basic: {len(plus3)}')
    err(f'  +4 names in item_basic: {len(plus4)}')
    err(f'  paired but non-armor slot (skipped): {skipped["nonarmor"]}')
    err(f'  paired but +4 missing from item_equipment: {len(unmapped_slot)}')
    if multijob:
        err(f'  MULTI-JOB pairs recorded: {len(multijob)}')
        for n4, id4, codes, slot in multijob[:10]:
            err(f'    {n4} (id {id4}) [{slot}] jobs={"/".join(codes)}')
    if anomalies:
        err(f'  ANOMALIES: {len(anomalies)}')
        for a in anomalies[:20]:
            err('    ' + a)
    if dup_names:
        reforge_dups = {k: v for k, v in dup_names.items()
                        if TIER_RE.search(k)}
        if reforge_dups:
            err(f'  DUPLICATE tiered names in item_basic: {len(reforge_dups)}')
            for k, v in list(reforge_dups.items())[:10]:
                err(f'    {k}: {v}')

    # Machine-readable tail the wrapper report can grep.
    print(f'ENTRIES={len(entries)}')
    print(f'PLUS3_NAMES={len(plus3)}')
    print(f'PLUS4_NAMES={len(plus4)}')


if __name__ == '__main__':
    main()
