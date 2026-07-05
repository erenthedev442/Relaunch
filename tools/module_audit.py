"""Static ownership/collision audit for modules/custom.

Implements the automated checks recommended by SOURCE_MODULE_AUDIT_2026-07-04:
scans the auto-loaded custom Lua tree and reports

  1. override-target census   — every xi.* callback and which files wrap it
  2. duplicate entity names    — two insertDynamicEntity() with the same internal
                                 `name` in the same zone (name-lookup ambiguity)
  3. direct xi.* replacements  — `xi.foo.bar = function` assignments that bypass
                                 the module override registry entirely
  4. per-file ownership        — override targets + entity names + CharVars touched

No third-party deps. Two modes:

  python tools/module_audit.py            # print report, write docs/admin/module-ownership.md
  python tools/module_audit.py --check    # exit 1 if any HARD problem is found (CI gate)

HARD problems (fail --check): duplicate entity name in one zone, direct xi.*
function replacement not in ALLOW_DIRECT. Deep override chains are reported but
are NOT failures on their own — most are legitimate super() chains.
"""
from __future__ import annotations

import re
import sys
from collections import defaultdict
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parents[1]
LUA_DIR = REPO_ROOT / "modules" / "custom" / "lua"
REPORT_PATH = REPO_ROOT / "docs" / "admin" / "module-ownership.md"

# Direct xi.* assignments that are knowingly accepted. Everything else that
# patches a namespace the file doesn't own is flagged so NEW ones can't sneak in.
#
# Two kinds live here:
#   - intentional engine-behavior replacements (ranged penalty, unity trigger);
#   - grandfathered custom hooks bolted onto an engine namespace. These are new
#     fields (not replacements) so they're low-risk, but ideally they'd move to a
#     self-owned namespace (e.g. xi.abysseaMarks) so this baseline can shrink.
ALLOW_DIRECT: set[str] = {
    # intentional replacements of existing engine functions
    "xi.combat.ranged.attackDistancePenalty",
    "xi.combat.ranged.accuracyDistancePenalty",
    "xi.unity.onTrigger",
    # grandfathered: AbysseaMarks custom hooks on engine namespaces (new fields)
    "xi.abyssea.marksPopHook",
    "xi.mob.marksRewardHook",
}

_ADD_OVERRIDE = re.compile(r"""addOverride\(\s*['"]([^'"]+)['"]""")
_ZONE_TARGET = re.compile(r"^xi\.zones\.([A-Za-z0-9_]+)\.")
_INSERT_ENTITY = re.compile(r"insertDynamicEntity")
_NAME_FIELD = re.compile(r"""\bname\s*=\s*['"]([^'"]+)['"]""")
_DIRECT_ASSIGN = re.compile(r"""^\s*(xi\.[A-Za-z0-9_.]+)\s*=\s*function\b""")
# A module declaring its OWN namespace: `xi.foo = xi.foo or {}` / `xi.foo = {}`.
_NS_DECLARE = re.compile(r"""^\s*xi\.([A-Za-z0-9_]+)\s*=\s*(?:xi\.[A-Za-z0-9_]+\s+or\s+)?\{\s*\}""", re.MULTILINE)
_CHARVAR = re.compile(r"""(?:get|set)CharVar\(\s*[^,]+,\s*['"]([^'"]+)['"]""")


def _lua_files() -> list[Path]:
    return sorted(LUA_DIR.rglob("*.lua"))


def scan() -> dict:
    overrides: dict[str, list[str]] = defaultdict(list)   # target -> [file, ...]
    zone_names: dict[tuple[str, str], list[str]] = defaultdict(list)  # (zone,name)->[file]
    direct: list[tuple[str, str, int]] = []               # (target, file, line)
    per_file: dict[str, dict] = {}

    for path in _lua_files():
        rel = path.relative_to(REPO_ROOT).as_posix()
        text = path.read_text(encoding="utf-8", errors="replace")
        lines = text.splitlines()

        # Namespaces this file declares itself (so `xi.fellow.x = function` in a
        # file that owns `xi.fellow` is a definition, not a replacement).
        declared_ns = set(_NS_DECLARE.findall(text))

        f_targets: list[str] = []
        f_names: list[str] = []
        f_charvars: set[str] = set()

        # Track the most recent addOverride zone so an insertDynamicEntity can be
        # attributed to the zone whose onInitialize placed it.
        cur_zone = "?"
        for i, line in enumerate(lines):
            mo = _ADD_OVERRIDE.search(line)
            if mo:
                target = mo.group(1)
                overrides[target].append(rel)
                f_targets.append(target)
                zt = _ZONE_TARGET.match(target)
                if zt:
                    cur_zone = zt.group(1)

            if _INSERT_ENTITY.search(line):
                # look ahead a small window for the entity's name field
                for j in range(i, min(i + 20, len(lines))):
                    nm = _NAME_FIELD.search(lines[j])
                    if nm:
                        name = nm.group(1)
                        zone_names[(cur_zone, name)].append(rel)
                        f_names.append(f"{cur_zone}:{name}")
                        break

            da = _DIRECT_ASSIGN.match(line)
            if da:
                target = da.group(1)
                ns = target.split(".")[1] if target.count(".") >= 1 else ""
                self_owned = ns in declared_ns
                direct.append((target, rel, i + 1, self_owned))

            for cv in _CHARVAR.findall(line):
                f_charvars.add(cv)

        per_file[rel] = {
            "targets": f_targets,
            "names": f_names,
            "charvars": sorted(f_charvars),
        }

    return {
        "overrides": overrides,
        "zone_names": zone_names,
        "direct": direct,
        "per_file": per_file,
    }


def hard_problems(data: dict) -> list[str]:
    problems: list[str] = []
    for (zone, name), files in sorted(data["zone_names"].items()):
        if len(files) > 1:
            problems.append(
                f"duplicate entity name '{name}' in zone {zone}: {', '.join(files)}"
            )
    for target, rel, line, self_owned in data["direct"]:
        # Defining your own namespace is fine. Patching a namespace you don't
        # own (and that isn't explicitly allow-listed) is the flagged pattern.
        if self_owned or target in ALLOW_DIRECT:
            continue
        problems.append(f"patches un-owned namespace: {target} at {rel}:{line}")
    return problems


def render(data: dict) -> str:
    overrides = data["overrides"]
    dup_targets = {t: f for t, f in overrides.items() if len(f) > 1}
    problems = hard_problems(data)

    out: list[str] = []
    out.append("# Module ownership manifest\n")
    out.append("!!! note \"Auto-generated — do not edit by hand\"")
    out.append("    Regenerate with `python tools/module_audit.py`. Static scan of the")
    out.append("    auto-loaded `modules/custom/lua` tree. Implements the collision checks")
    out.append("    from the 2026-07-04 source/module audit.\n")

    out.append("## Hard problems\n")
    if problems:
        out.append("These fail `--check`:\n")
        for p in problems:
            out.append(f"- ⚠️ {p}")
    else:
        out.append("None. No duplicate entity names per zone and no un-allow-listed "
                   "`xi.* = function` replacements.")
    out.append("")

    out.append("## Override-target census (multiple writers)\n")
    out.append("Deep chains are not inherently bugs — most are legitimate `super()` chains — "
               "but every target with >1 writer is listed so overlap is visible.\n")
    out.append("| Target | Writers | Files |")
    out.append("|---|---:|---|")
    for target in sorted(dup_targets, key=lambda t: (-len(dup_targets[t]), t)):
        files = dup_targets[target]
        shown = ", ".join(f"`{Path(f).name}`" for f in files)
        out.append(f"| `{target}` | {len(files)} | {shown} |")
    out.append("")

    out.append("## Direct `xi.*` function assignments\n")
    out.append("`self` = the file declares this namespace (definition, fine). "
               "`allow` = explicitly allow-listed replacement. "
               "**patch** = assigns into a namespace it doesn't own (review).\n")
    if data["direct"]:
        out.append("| Target | File | Kind |")
        out.append("|---|---|:--:|")
        for target, rel, line, self_owned in sorted(data["direct"]):
            if self_owned:
                kind = "self"
            elif target in ALLOW_DIRECT:
                kind = "allow"
            else:
                kind = "**patch**"
            out.append(f"| `{target}` | `{rel}`:{line} | {kind} |")
    else:
        out.append("None found.")
    out.append("")

    out.append("## Per-file ownership\n")
    out.append("| File | Override targets | Entity names (zone:name) | CharVars |")
    out.append("|---|---:|---|---|")
    for rel in sorted(data["per_file"]):
        info = data["per_file"][rel]
        if not (info["targets"] or info["names"] or info["charvars"]):
            continue
        names = ", ".join(f"`{n}`" for n in info["names"]) or "—"
        cvs = ", ".join(f"`{c}`" for c in info["charvars"]) or "—"
        out.append(f"| `{Path(rel).name}` | {len(info['targets'])} | {names} | {cvs} |")
    out.append("")

    return "\n".join(out)


def main(argv: list[str]) -> int:
    if not LUA_DIR.is_dir():
        print(f"[module_audit] no such dir: {LUA_DIR}", file=sys.stderr)
        return 2
    data = scan()
    problems = hard_problems(data)

    if "--check" in argv:
        if problems:
            print(f"[module_audit] {len(problems)} hard problem(s):")
            for p in problems:
                print(f"  - {p}")
            return 1
        print("[module_audit] OK — no hard problems")
        return 0

    report = render(data)
    REPORT_PATH.parent.mkdir(parents=True, exist_ok=True)
    REPORT_PATH.write_text(report + "\n", encoding="utf-8")
    n_files = len(data["per_file"])
    n_dup = sum(1 for f in data["overrides"].values() if len(f) > 1)
    print(f"[module_audit] scanned {n_files} lua files, {n_dup} multi-writer targets, "
          f"{len(problems)} hard problem(s)")
    print(f"[module_audit] wrote {REPORT_PATH.relative_to(REPO_ROOT).as_posix()}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main(sys.argv[1:]))
