#!/usr/bin/env python3
"""One-shot: remove every `action='adds'` (servitor) phase entry from the NM
system catalogs. Brace-matched so it handles single-line, {-on-action-line, and
{-on-own-line shapes. Removes the WHOLE table element (incl. trailing comma);
leaves every other mechanic and the array structure intact. Reports each removal.
"""
import re
from pathlib import Path

ROOT = Path("modules/custom/lua")
FILES = [
    "apex_catalog.lua", "endless_tower.lua", "colosseum_catalog.lua",
    "hunting_league_catalog.lua", "Invasion.lua", "job_mastery.lua",
    "reforge_catalog.lua", "Tournament.lua", "voidspire_catalog.lua",
    "world_boss.lua",
]
ADDS = re.compile(r"action\s*=\s*['\"]adds['\"]")


def non_string_braces(text):
    """Yield (idx, ch) for every { or } not inside a Lua string OR comment.
    Handles -- line comments, --[[ ]] block comments, and '/" strings so that
    apostrophes/braces inside comments or strings don't corrupt the matching."""
    out, i, n = [], 0, len(text)
    while i < n:
        c = text[i]
        # comments
        if c == "-" and i + 1 < n and text[i + 1] == "-":
            if text[i + 2 : i + 4] == "[[":          # block comment
                end = text.find("]]", i + 4)
                i = (end + 2) if end != -1 else n
            else:                                     # line comment
                nlp = text.find("\n", i)
                i = (nlp + 1) if nlp != -1 else n
            continue
        # strings
        if c in ("'", '"'):
            q = c
            i += 1
            while i < n:
                if text[i] == "\\":
                    i += 2
                    continue
                if text[i] == q:
                    i += 1
                    break
                i += 1
            continue
        if c in "{}":
            out.append((i, c))
        i += 1
    return out


def enclosing_span(text, braces, pos):
    """Return (open_idx, close_idx) of the innermost {..} containing char pos."""
    stack = []
    for idx, ch in braces:
        if ch == "{":
            stack.append(idx)
        else:  # }
            open_idx = stack.pop()
            if open_idx < pos < idx:
                return open_idx, idx
    raise RuntimeError(f"no enclosing braces for pos {pos}")


total = 0
for name in FILES:
    p = ROOT / name
    text = p.read_text(encoding="utf-8")
    nl = "\r\n" if "\r\n" in text else "\n"
    braces = non_string_braces(text)

    # Collect char-spans of every adds entry.
    spans = []
    for m in ADDS.finditer(text):
        o, c = enclosing_span(text, braces, m.start())
        # extend close past a trailing comma
        c2 = c + 1
        while c2 < len(text) and text[c2] in " \t":
            c2 += 1
        if c2 < len(text) and text[c2] == ",":
            c2 += 1
        spans.append((o, c2))

    # Convert each char-span to a whole-line range and remove those lines.
    # (Entries occupy dedicated lines in every one of these files.)
    starts = [0]
    for ch in text:
        starts.append(starts[-1] + 1)
    lines = text.split(nl)
    line_start_idx = []
    acc = 0
    for ln in lines:
        line_start_idx.append(acc)
        acc += len(ln) + len(nl)

    def line_of(idx):
        lo, hi = 0, len(line_start_idx) - 1
        while lo < hi:
            mid = (lo + hi + 1) // 2
            if line_start_idx[mid] <= idx:
                lo = mid
            else:
                hi = mid - 1
        return lo

    drop = set()
    report = []
    for o, c in spans:
        l0, l1 = line_of(o), line_of(c - 1)
        for L in range(l0, l1 + 1):
            drop.add(L)
        report.append((l0 + 1, l1 + 1, lines[l0].strip()[:70]))

    if not drop:
        print(f"{name}: (no adds entries)")
        continue
    new_lines = [ln for i, ln in enumerate(lines) if i not in drop]
    p.write_text(nl.join(new_lines), encoding="utf-8")
    print(f"\n{name}: removed {len(report)} entries, {len(drop)} lines")
    for a, b, preview in report:
        print(f"    L{a}-{b}: {preview}")
        total += 1

print(f"\nTOTAL adds entries removed: {total}")
