#!/usr/bin/env python3
"""Validate Relaunch BST Ready charge timing across SQL and C++."""
from __future__ import annotations

import re
import sys
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
CHARGES_SQL = ROOT / "sql" / "abilities_charges.sql"
SOA_SQL = ROOT / "modules" / "soa" / "sql" / "job_adjustments.sql"
DEPLOY_SQL = ROOT / "modules" / "custom" / "sql" / "bst_ready_recast.sql"
CHAR_CPP = ROOT / "src" / "map" / "entities" / "charentity.cpp"


def ready_charge_time(merit_reduction: int, gear_reduction: int) -> int:
    return max(3, 10 - max(0, merit_reduction) - max(0, gear_reduction))


def main() -> int:
    charges = CHARGES_SQL.read_text(encoding="utf-8")
    soa = SOA_SQL.read_text(encoding="utf-8")
    deploy = DEPLOY_SQL.read_text(encoding="utf-8")
    cpp = CHAR_CPP.read_text(encoding="utf-8")
    failures: list[str] = []

    charge_row = re.search(
        r"INSERT INTO `abilities_charges` VALUES "
        r"\(102,\s*9,\s*25,\s*(\d+),\s*(\d+),\s*902\);",
        charges,
    )
    if not charge_row:
        failures.append("missing BST recast-group 102 charge row")
    elif charge_row.groups() != ("3", "10"):
        failures.append(
            "BST Ready must retain 3 charges with a 10-second base interval"
        )

    if not re.search(
        r"UPDATE merits SET value = 1 WHERE name = 'sic_recast';", soa
    ):
        failures.append("Sic Recast merit must be 1 second per rank")

    if not re.search(
        r"UPDATE `abilities_charges`[\s\S]*?`chargeTime` = 10"
        r"[\s\S]*?`recastId` = 102;",
        deploy,
    ):
        failures.append("deploy SQL does not enforce the live 10-second interval")

    if "this->getMod(Mod::SIC_READY_RECAST)" not in cpp:
        failures.append("Ready charge math does not consume SIC_READY_RECAST")
    if "PAbility->getRecastId() == Recast::Sic ? 3s : 0s" not in cpp:
        failures.append("Ready charge math does not enforce the 3-second floor")

    timing_cases = {
        "baseline": (0, 0, 10),
        "max merits": (5, 0, 5),
        "max investment": (5, 2, 3),
        "overcapped": (99, 99, 3),
        "malformed negatives": (-5, -5, 10),
    }
    for label, (merits, gear, expected) in timing_cases.items():
        actual = ready_charge_time(merits, gear)
        if actual != expected:
            failures.append(
                f"{label} timing is {actual}s; expected {expected}s"
            )

    if ready_charge_time(5, 2) * 2 != 6:
        failures.append("two-charge Ready moves must recover in 6 seconds at cap")

    if failures:
        print("BST Ready audit failed:", file=sys.stderr)
        for failure in failures:
            print(f"  - {failure}", file=sys.stderr)
        return 1

    print(
        "BST Ready audit passed: 3 charges, "
        "10s baseline / 5s merits / 3s geared floor"
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
