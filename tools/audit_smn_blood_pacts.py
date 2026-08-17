#!/usr/bin/env python3
"""Fail when an enabled SMN Blood Pact has no loadable player-pet script.

The canonical enabled set is every uncommented ``pet_skills`` row carrying a
Blood Pact Rage or Ward flag. Odin remains excluded because its rows are not
enabled in ``sql/pet_skills.sql``.
"""
from __future__ import annotations

import re
import sys
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
PET_SKILLS = ROOT / "sql" / "pet_skills.sql"
SCRIPT_DIR = ROOT / "scripts" / "actions" / "abilities" / "pets"
SPECIAL_HANDLER_EXCEPTIONS = {
    "chronoshift",       # Atomos transfer step
    "deconstruction",    # Atomos steal step
    "perfect_defense",   # Alexander Astral Flow lifecycle
}

ROW_RE = re.compile(
    r"^\s*INSERT\s+INTO\s+`pet_skills`\s+VALUES\s*"
    r"\(\s*(\d+)\s*,.*?'([A-Za-z0-9_]+)'.*?"
    r"(@SKILLFLAG_BLOODPACT_(?:RAGE|WARD)).*?\)\s*;",
    re.IGNORECASE,
)


def enabled_blood_pacts() -> list[tuple[int, str, str]]:
    rows: list[tuple[int, str, str]] = []
    for line in PET_SKILLS.read_text(encoding="utf-8").splitlines():
        if line.lstrip().startswith("--"):
            continue
        match = ROW_RE.match(line)
        if match:
            rows.append((int(match.group(1)), match.group(2), match.group(3)))
    return rows


def validate_script(path: Path, name: str) -> list[str]:
    if not path.is_file():
        return ["missing script"]

    source = path.read_text(encoding="utf-8")
    errors = []
    if "abilityObject.onAbilityCheck" not in source:
        errors.append("missing onAbilityCheck")
    if "abilityObject.onPetAbility" not in source:
        errors.append("missing onPetAbility")
    if name not in SPECIAL_HANDLER_EXCEPTIONS:
        if "xi.job_utils.summoner.canUseBloodPact" not in source:
            errors.append("missing canUseBloodPact")
        if "xi.job_utils.summoner.onUseBloodPact" not in source:
            errors.append("missing onUseBloodPact")
    if not re.search(r"\breturn\s+abilityObject\s*$", source):
        errors.append("does not return abilityObject")
    return errors


def main() -> int:
    rows = enabled_blood_pacts()
    failures = []
    seen_names: set[str] = set()

    for skill_id, name, flag in rows:
        if name in seen_names:
            failures.append(f"{skill_id} {name}: duplicate enabled Blood Pact name")
        seen_names.add(name)

        errors = validate_script(SCRIPT_DIR / f"{name}.lua", name)
        if errors:
            failures.append(f"{skill_id} {name} ({flag}): {', '.join(errors)}")

    if failures:
        print("SMN Blood Pact coverage audit failed:", file=sys.stderr)
        for failure in failures:
            print(f"  - {failure}", file=sys.stderr)
        return 1

    print(f"SMN Blood Pact coverage audit passed: {len(rows)} enabled scripts")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
