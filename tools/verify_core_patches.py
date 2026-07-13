#!/usr/bin/env python3
"""
verify_core_patches.py -- confirm the in-place LSB core patches survived.

D:\\server is a customized LandSandBoat fork. Most custom content lives in NEW
files (safe), but ~31 edits to EXISTING LSB files are conflict-prone: a
`git merge origin/base` (LSB upstream) can silently revert them, and the rebuilt
binary would then ship MISSING your customizations.

This script greps the source for each high-value / easy-to-lose patch and prints
a PASS/FAIL table. It exits 0 if every check passes, 1 if ANY fails -- so the
deploy bats (deploy-everything.bat / deploy-no-rebuild.bat) and the Azure-side
rebuild (_azure_update_remote.sh) can gate on it and refuse to ship reverted code.

Mirrors memory/reference_lsb_core_patches.md. When you add a core patch, add a
check here. Runs the same on Windows (python) and the Azure box (python3) -- pure
stdlib, no shelling out.

Usage:  python tools/verify_core_patches.py        (exit code 0=OK, 1=FAIL)
"""
import os
import re
import sys

REPO = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SCAN_EXTS = ('.cpp', '.h', '.lua', '.txt', '.sql')

# (label, path[file|dir], regex, mode, threshold)
#   mode 'present' -> >=1 match    'absent' -> exactly 0 matches    'min' -> >=threshold
CHECKS = [
    ("Damage cap raised to 131071 (battleutils.cpp)",
     "src/map/utils/battleutils.cpp", r"131071", "min", 4),
    ("Damage cap: no stray 99999 left (battleutils.cpp)",
     "src/map/utils/battleutils.cpp", r"\b99999\b", "absent", 0),
    ("Damage cap: no stray 99999 left (scripts/globals)",
     "scripts/globals", r"\b99999\b", "absent", 0),
    ("CP-suppression: MOBMOD_NO_CAPACITY_POINTS=200 (mob_modifier.h)",
     "src/map/mob_modifier.h", r"MOBMOD_NO_CAPACITY_POINTS\s*=\s*200", "present", 1),
    ("CP-suppression: Lua enum mirror =200 (mob_mod.lua)",
     "scripts/enum/mob_mod.lua", r"NO_CAPACITY_POINTS\s*=\s*200", "present", 1),
    ("CP-suppression: charutils early-return uses flag",
     "src/map/utils/charutils.cpp", r"NO_CAPACITY_POINTS", "present", 1),
    ("Sub-job gear-equip clause (charutils EquipArmor)",
     "src/map/utils/charutils.cpp", r"GetSJob\(\)\s*>\s*0", "present", 1),
    ("MAX_JOB_POINTS read from settings (job_points.cpp)",
     "src/map/job_points.cpp", r"MAX_JOB_POINTS", "present", 1),
    ("Trust/COR/BRD markers intact (lua_baseentity.cpp)",
     "src/map/lua/lua_baseentity.cpp", r"LEGENDARY[- ]CUSTOM", "present", 1),
    ("COR max phantom rolls = 6 (lua_baseentity.cpp)",
     "src/map/lua/lua_baseentity.cpp", r"maxRolls\s*=\s*6", "present", 1),
    ("Module loader: custom/lua enabled (init.txt) [CRITICAL]",
     "modules/init.txt", r"(?m)^\s*custom/lua/\s*$", "present", 1),
    ("Module loader: custom/sql enabled (init.txt) [CRITICAL]",
     "modules/init.txt", r"(?m)^\s*custom/sql/\s*$", "present", 1),
    ("Module loader: custom/commands enabled (init.txt) [CRITICAL]",
     "modules/init.txt", r"(?m)^\s*custom/commands/\s*$", "present", 1),
    # Boom custom job (relaunch): the onJobChange hook spans 3 stock files; a
    # merge reverting ANY link breaks instant /job-swap trait reconciliation.
    ("Boom: onJobChange call in 0x100 job handler",
     "src/map/packets/c2s/0x100_myroom_job.cpp", r"luautils::OnJobChange", "present", 1),
    ("Boom: OnJobChange wired in luautils.cpp",
     "src/map/lua/luautils.cpp", r"xi\.player\.onJobChange", "present", 1),
    ("Boom: onJobChange Lua stub (player.lua)",
     "scripts/globals/player.lua", r"xi\.player\.onJobChange", "present", 1),
    # Reward accepts Pet Roborant/Poultice (2026-07-11, player report): the
    # stock LSB checkReward only allows the biscuit id range, rejecting the
    # pet medicines !shop sells. An upstream merge of beastmaster.lua would
    # silently re-break them.
    ("Reward: Pet Roborant/Poultice accepted (beastmaster.lua)",
     "scripts/globals/job_utils/beastmaster.lua", r"PET_ROBORANT", "min", 2),
    # Nyzul: ACTIVATE_ALL_LAMPS objective excluded from the floor pool (2026-07-13,
    # owner/Bro) -- lamp objectives are impossible solo. A merge of the upstream
    # instance script would re-add the un-soloable objective.
    ("Nyzul: lamps objective excluded from floor pool (nyzul_isle_investigation.lua)",
     "scripts/zones/Nyzul_Isle/instances/nyzul_isle_investigation.lua",
     r"~=\s*xi\.nyzul\.objective\.ACTIVATE_ALL_LAMPS", "present", 1),
    ("Patch markers present across src/ (broad-revert tripwire)",
     "src", r"FJB|LEGENDARY[- ]CUSTOM", "min", 30),
]


def gather(rel):
    full = os.path.join(REPO, rel)
    if os.path.isfile(full):
        return [full]
    if os.path.isdir(full):
        out = []
        for root, _dirs, files in os.walk(full):
            for fn in files:
                if fn.endswith(SCAN_EXTS):
                    out.append(os.path.join(root, fn))
        return out
    return None  # path missing entirely


def count_matches(files, rx):
    total = 0
    for f in files:
        try:
            with open(f, encoding='utf-8', errors='replace') as fh:
                total += len(rx.findall(fh.read()))
        except OSError:
            pass
    return total


def main():
    rows = []
    fails = 0
    for label, path, pat, mode, thr in CHECKS:
        files = gather(path)
        if files is None:
            rows.append(("MISS", label, "%s NOT FOUND" % path))
            fails += 1
            continue
        rx = re.compile(pat)
        n = count_matches(files, rx)
        if mode == "present":
            ok, detail = n >= 1, "%d match(es)" % n
        elif mode == "absent":
            ok, detail = n == 0, "%d match(es), want 0" % n
        else:  # min
            ok, detail = n >= thr, "%d match(es), want >=%d" % (n, thr)
        rows.append(("OK" if ok else "FAIL", label, detail))
        if not ok:
            fails += 1

    width = max(len(r[1]) for r in rows)
    bar = "=" * (width + 28)
    print(bar)
    print(" LSB CORE-PATCH VERIFY   (mirrors reference_lsb_core_patches.md)")
    print(bar)
    for status, label, detail in rows:
        tag = {"OK": "[ OK ]", "FAIL": "[FAIL]", "MISS": "[MISS]"}[status]
        print(" %s %-*s  %s" % (tag, width, label, detail))
    print("-" * (width + 28))
    if fails:
        print("CORE-PATCHES: FAIL  (%d of %d checks failed)" % (fails, len(rows)))
        print("  --> DO NOT DEPLOY. A patch was reverted (likely a `git merge origin/base`).")
        print("  --> Re-apply from reference_lsb_core_patches.md  /  `git diff 54bd6e24f9 HEAD`.")
        return 1
    print("CORE-PATCHES: OK  (all %d checks passed)" % len(rows))
    return 0


if __name__ == "__main__":
    sys.exit(main())
