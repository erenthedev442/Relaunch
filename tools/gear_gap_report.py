"""Read-only coverage gap report for the gear-vendor catalogs.

Parses a gear catalog (armor_catalog.lua / accessory_catalog.lua) and, for
each Bronze/Silver/Gold tier x slot, counts how many items each of the 22
jobs can equip. Flags cells where a job has ZERO options (a hard gap, e.g.
the melee/tank body gap) or only ONE. Also prints the per-role mix.

Does NOT touch the DB, the server, or rewrite any catalog -- pure analysis.

Usage:
    python tools/gear_gap_report.py [catalog.lua ...]
    (defaults to armor_catalog.lua)
"""
import re
import sys
from collections import defaultdict
from pathlib import Path

JOBS = ['WAR', 'MNK', 'WHM', 'BLM', 'RDM', 'THF', 'PLD', 'DRK', 'BST', 'BRD',
        'RNG', 'SAM', 'NIN', 'DRG', 'SMN', 'BLU', 'COR', 'PUP', 'DNC', 'SCH',
        'GEO', 'RUN']
TIER_ORDER = ['bronze', 'silver', 'gold']

_local_re = re.compile(r"local\s+(\w+)\s*=\s*catalog\.(\w+)")
_row_re = re.compile(
    r"table\.insert\(\s*(\w+)\.(\w+)\s*,\s*\{[^}]*jobs\s*=\s*'([^']*)'[^}]*\}\)"
    r"\s*(?:--\s*(\w+)\s+score)?"
)


def analyze(path: str) -> None:
    var2tier: dict[str, str] = {}
    buckets: dict[tuple[str, str], list[tuple[set[str], str]]] = defaultdict(list)

    for line in Path(path).read_text(encoding='utf-8', errors='replace').splitlines():
        lm = _local_re.search(line)
        if lm:
            var2tier[lm.group(1)] = lm.group(2)
            continue
        m = _row_re.search(line)
        if m:
            var, slot, jobs, role = m.groups()
            tier = var2tier.get(var)
            if tier in TIER_ORDER:
                # Accessories use jobs='All' for unrestricted gear -> expand to every job.
                jset = set(JOBS) if jobs.strip() in ('All', 'All Jobs', 'ALL', 'all') else set(jobs.split('/'))
                buckets[(tier, slot)].append((jset, role or '?'))

    slots = sorted({s for (_, s) in buckets})
    print(f"\n=== {Path(path).name} ===")
    for tier in TIER_ORDER:
        for slot in slots:
            items = buckets.get((tier, slot))
            if items is None:
                continue
            cnt = {j: sum(1 for js, _ in items if j in js) for j in JOBS}
            zero = [j for j in JOBS if cnt[j] == 0]
            thin = [j for j in JOBS if cnt[j] == 1]
            roles: dict[str, int] = defaultdict(int)
            for _, r in items:
                roles[r] += 1
            rolestr = ' '.join(f"{r}:{roles[r]}" for r in ('DPS', 'WS', 'TANK', 'CASTER', 'HEAL') if roles.get(r))
            flag = '   <<< GAP' if zero else ''
            print(f"  {tier:>6} {slot:<6} {len(items):>2} items  [{rolestr}]{flag}")
            if zero:
                print(f"           0 options: {', '.join(zero)}")
            if thin:
                print(f"           1 option : {', '.join(thin)}")


if __name__ == '__main__':
    paths = sys.argv[1:] or [r"D:/server/modules/custom/lua/armor_catalog.lua"]
    for p in paths:
        analyze(p)
