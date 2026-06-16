#!/usr/bin/env python3
# Throwaway: find augment_catalog.lua entries the docs generator (augments.py)
# silently drops because its _ENTRY_RE doesn't match their format.
import re, sys

path = sys.argv[1] if len(sys.argv) > 1 else 'modules/custom/lua/augment_catalog.lua'
t = open(path, encoding='utf-8').read()

# Every catalyst entry: a single-line brace block that contains augId.
ALL = re.compile(r"\[\s*(\d+)\s*\]\s*=\s*\{[^{}]*?\baugId\s*=\s*(\d+)[^{}]*?\}")
all_entries = {m.group(1): m.group(0) for m in ALL.finditer(t)}

# The EXACT regex augments.py uses to render the website table.
ENTRY = re.compile(
    r"\[\s*(\d+)\s*\]\s*=\s*\{\s*augId\s*=\s*(\d+)\s*,\s*"
    r"(?:\w+\s*=\s*[^,}]+,\s*)*"
    r"label\s*=\s*'((?:[^'\\]|\\.)*)'\s*\}",
)
matched = {m.group(1) for m in ENTRY.finditer(t)}

allids = set(all_entries)
dropped = sorted(allids - matched, key=int)

print(f"file: {path}")
print(f"total catalysts: {len(allids)} | docgen(website) renders: {len(matched)} | website DROPS: {len(dropped)}")
for i in dropped:
    print("  WEBSITE-DROPS [%s]: %s" % (i, all_entries[i][:150]))

# The SHOP requires a `cat` field (shop.lua: `if type(def)=='table' and def.cat`).
# The website does NOT. So entries with no cat = on website, NOT in shop.
CAT = re.compile(r"\bcat\s*=\s*\d+")
no_cat = sorted([i for i, raw in all_entries.items() if not CAT.search(raw)], key=int)
print(f"\nentries WITHOUT a cat field -> SHOP EXCLUDES but WEBSITE SHOWS: {len(no_cat)}")
for i in no_cat:
    print("  SHOP-MISSING [%s]: %s" % (i, all_entries[i][:150]))
