#!/usr/bin/env python3
"""validate_runtime_consumers.py

Guard-rail for the owner spider-web rule, extended to RUNTIME Lua (commands +
custom modules) -- the blind spot the docs audits (sync_audit/coverage_check)
don't cover. It exists because `!affinitynm` silently drifted for a month: it
kept its OWN hardcoded copy of the affinity-NM roster instead of reading
augment_affinity_catalog.lua, so the 2026-07-06 rework (24 stat-families -> 11
categories) never pulled it along and it warped players to reworked-out NMs.

Checks (ERROR = fails CI; WARN = human review):
  1. BROKEN REFS (ERROR): every hardcoded `id=`/`itemId=` in a custom command
     or module must resolve to a real item (item_basic, across stock + custom +
     zz SQL). Catches references to deleted/renamed items.
  2. REGISTRY DRIFT (WARN): a configured "roster" catalog owns a set of named
     entities. Any runtime file (outside the roster's own internals) that still
     names a DEPRECATED entity near the registry's context keyword is surfaced
     for review -- this is exactly the class that broke !affinitynm.
  3. CATALOG DUPLICATION (WARN): a runtime file that hardcodes a big chunk of a
     catalog's item-id set WITHOUT `require`-ing it is likely a private copy that
     will drift -- refactor it to read the catalog.
  4. AFFINITY ROSTER (ERROR): the canonical 24-NM catalog must match its SQL
     spawn IDs, and !affinitypop must use the shared configureMob path.

Run:  python tools/validate_runtime_consumers.py            (report)
      python tools/validate_runtime_consumers.py --strict   (exit 1 on ERROR)
"""
from __future__ import annotations
import re, glob, sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
SQL  = ROOT / "sql"
LUA  = ROOT / "modules" / "custom" / "lua"
CMD  = ROOT / "modules" / "custom" / "commands"


def _read(p: Path) -> str:
    return p.read_text(encoding="utf-8", errors="replace") if p.exists() else ""


def load_item_ids() -> set[int]:
    ids: set[int] = set()
    srcs = [SQL / "item_basic.sql"] + list(SQL.glob("zz*.sql")) + list((ROOT / "modules/custom/sql").glob("*.sql"))
    pat = re.compile(r"INSERT(?:\s+IGNORE)?\s+INTO\s+`?item_basic`?[^;]*?VALUES(.*?);", re.S | re.I)
    for p in srcs:
        for blk in pat.finditer(_read(p)):
            for tup in re.finditer(r"\(\s*(\d+)\s*,", blk.group(1)):
                ids.add(int(tup.group(1)))
    return ids


def load_zone_ids() -> set[int]:
    return {int(m.group(1)) for m in re.finditer(r"=\s*(\d+),", _read(ROOT / "scripts/enum/zone.lua"))}


def strip_comments(txt: str) -> str:
    return "\n".join(l.split("--", 1)[0] for l in txt.splitlines())


def runtime_files() -> list[Path]:
    return sorted(list(CMD.glob("*.lua")) + list(LUA.glob("*.lua")))


# ── Registries: catalog-owned vocabularies a runtime file must not drift from ─
# The affinity registry is keyed on the affinity *label* (the category a trophy
# grants), NOT the NM name -- the NMs are shared retail mobs used by many
# unrelated systems (HNM, Hunter's Guild, Geas Fete...), so naming one is not
# drift. But writing an "Affinity: <label>" that isn't one of the catalog's live
# categories IS drift -- that's how the 2026-07-06 24->11 rework left stale
# `Augment Affinity: DEX/Accuracy` references behind.
def _affinity_labels() -> set[str]:
    cat = _read(LUA / "augment_affinity_catalog.lua")
    labels = set(re.findall(r"label='([^']+)'", cat))
    # single stat words a live label implies, so "Affinity: Defense" isn't flagged
    return {l.lower() for l in labels} | {"pet"}  # 'Pets' <-> 'Pet'


def check_broken_refs(item_ids: set[int], zone_ids: set[int]) -> list[str]:
    errors = []
    for f in runtime_files():
        body = strip_comments(_read(f))
        for m in re.finditer(r"\b(?:id|itemId)\s*=\s*(\d{3,5})\b", body):
            iid = int(m.group(1))
            if iid >= 256 and iid not in item_ids:
                errors.append(f"[broken-ref] {f.name}: item id {iid} does not exist")
        for m in re.finditer(r"\bzoneId?\s*=\s*(\d{1,3})\b", body):
            z = int(m.group(1))
            if z and z not in zone_ids:
                errors.append(f"[broken-ref] {f.name}: zone id {z} is not a valid zone")
    return errors


def check_affinity_labels() -> list[str]:
    """Flag `Affinity: <label>` references whose label isn't a live category."""
    live = _affinity_labels()
    if not live:
        return []
    warns = []
    # Match a labelled affinity like "(Augment Affinity: DEX/Accuracy)": a space
    # before "Affinity" (not the Augment_Affinities charvar), a colon, then a
    # Capitalised category token. Lowercase tails ("Affinity: roll twice") and
    # code ("Augment_Affinities = ...") are excluded.
    pat = re.compile(r"(?:^|\s)Affinity:\s*([A-Z][\w+]*(?:[/ ][A-Za-z][\w+]*)*)")
    for f in runtime_files():
        for i, line in enumerate(_read(f).splitlines(), 1):
            for m in pat.finditer(line):
                terms = re.split(r"[/ ]+", m.group(1).strip())
                stale = [t for t in terms if t and t.lower() not in live]
                if stale:
                    warns.append(f"[affinity-label] {f.name}:{i}: '{m.group(1).strip()}' is not a live "
                                 f"affinity category -- stale since the 2026-07-06 rework")
    return warns


def check_duplication(item_ids: set[int]) -> list[str]:
    # catalog -> its hardcoded item-id set
    cat_ids: dict[str, set[int]] = {}
    for c in LUA.glob("*catalog*.lua"):
        s = {int(m.group(1)) for m in re.finditer(r"\b(?:id|itemId)\s*=\s*(\d{3,5})\b", strip_comments(_read(c)))}
        if len(s) >= 8:
            cat_ids[c.name] = s
    warns = []
    for f in runtime_files():
        if "catalog" in f.name:
            continue
        txt = _read(f)
        fids = {int(m.group(1)) for m in re.finditer(r"\b(?:id|itemId)\s*=\s*(\d{3,5})\b", strip_comments(txt))}
        if len(fids) < 8:
            continue
        for cname, cset in cat_ids.items():
            req = f"require('modules/custom/lua/{cname[:-4]}')"
            if req in txt:
                continue
            shared = fids & cset
            if len(shared) >= 8 and len(shared) >= 0.6 * len(fids):
                warns.append(f"[duplication] {f.name}: hardcodes {len(shared)} item ids also in {cname} "
                             f"(not required) -- likely a private copy that will drift")
    return warns


def check_affinity_roster() -> list[str]:
    """Keep the canonical 24-NM catalog synchronized with SQL and GM tooling."""
    errors = []
    catalog = _read(LUA / "affinity_nm_catalog.lua")
    spawn_sql = _read(ROOT / "modules/custom/sql/affinity_nm_spawns.sql")
    command = _read(CMD / "affinitypop.lua")

    catalog_ids = {int(value) for value in re.findall(r"\bmobId\s*=\s*(\d+)", catalog)}
    spawn_block = ""
    marker = "INSERT INTO `mob_spawn_points` VALUES"
    if marker in spawn_sql:
        spawn_block = spawn_sql.split(marker, 1)[1].split(";", 1)[0]
    sql_ids = {int(value) for value in re.findall(r"^\s*\(\s*(\d+)", spawn_block, re.M)}
    if len(catalog_ids) != 24:
        errors.append(f"[affinity-roster] catalog defines {len(catalog_ids)} unique mob IDs, expected 24")
    if catalog_ids != sql_ids:
        errors.append("[affinity-roster] catalog mob IDs do not match affinity_nm_spawns.sql")
    if "affinity_nm_catalog" not in command or ".configureMob(entry.mobId)" not in command:
        errors.append("[affinity-roster] !affinitypop does not use the canonical roster/configureMob path")

    return errors


def generate(repo_root, docs_dir=None) -> None:
    """Docgen-audit entry point (wired into tools/docgen/generate.py). Prints
    `[runtime-consumers]`-tagged findings that the site drift monitor scans, so a
    future rework that leaves a runtime consumer behind surfaces the same hour --
    the automated tripwire the docs-only audits never had. Advisory: never raises
    (mirrors sync_audit / coverage_check)."""
    global ROOT, SQL, LUA, CMD
    ROOT = Path(repo_root)
    SQL = ROOT / "sql"
    LUA = ROOT / "modules" / "custom" / "lua"
    CMD = ROOT / "modules" / "custom" / "commands"
    item_ids, zone_ids = load_item_ids(), load_zone_ids()
    errs = check_broken_refs(item_ids, zone_ids) + check_affinity_roster()
    warns = check_affinity_labels() + check_duplication(item_ids)
    for e in errs:
        print(f"[runtime-consumers] ERROR {e}")
    for w in warns:
        print(f"[runtime-consumers] WARN {w}")
    print(f"[runtime-consumers] {len(errs)} error(s), {len(warns)} warning(s)")


def main() -> int:
    strict = "--strict" in sys.argv
    item_ids, zone_ids = load_item_ids(), load_zone_ids()
    errors = check_broken_refs(item_ids, zone_ids) + check_affinity_roster()
    warns = check_affinity_labels() + check_duplication(item_ids)

    print(f"[validate_runtime_consumers] item ids={len(item_ids)} zones={len(zone_ids)} "
          f"files={len(runtime_files())}")
    for e in errors:
        print("ERROR " + e)
    for w in warns:
        print("WARN  " + w)
    print(f"\n{len(errors)} error(s), {len(warns)} warning(s)")
    return 1 if (errors and strict) else 0


if __name__ == "__main__":
    raise SystemExit(main())
