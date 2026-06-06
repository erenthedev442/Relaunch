"""Cache helper for gen_naked_item_stats.py.

Subcommands:

  next [N]                                   print next N items to fetch
  add  <itemId> <url> <wiki_name> -- <stats> add an entry to the cache
  flag <itemId> <reason>                     mark unresolved (no stats available)
  count                                      summary of cache state
"""
import json
import os
import sys
import urllib.parse

REPO  = os.path.normpath(os.path.join(os.path.dirname(__file__), ".."))
AUDIT = os.path.join(REPO, "tools", "gear_stat_audit.json")
CACHE = os.path.join(REPO, "tools", "bgwiki_stats_cache.json")

sys.path.insert(0, os.path.dirname(__file__))
from _make_url_list import candidate_name, to_url


def load_audit():
    with open(AUDIT, "r", encoding="utf-8") as f:
        return json.load(f)["naked_items"]


def load_cache():
    if not os.path.exists(CACHE):
        return {}
    with open(CACHE, "r", encoding="utf-8") as f:
        return json.load(f)


def save_cache(c):
    with open(CACHE, "w", encoding="utf-8") as f:
        json.dump(c, f, indent=2, ensure_ascii=False, sort_keys=True)


def cmd_next(n=10):
    items = load_audit()
    cache = load_cache()
    out = []
    for it in items:
        key = str(it["itemId"])
        if key in cache:
            continue
        name = candidate_name(it["shortName"])
        url  = to_url(name)
        out.append((it["itemId"], it["shortName"], it["context"], name, url))
        if len(out) >= n:
            break
    for row in out:
        print("\t".join(str(x) for x in row))


def cmd_add(item_id, url, name, stats):
    cache = load_cache()
    cache[str(item_id)] = {
        "url":   url,
        "name":  name,
        "stats": stats,
    }
    save_cache(cache)
    print(f"cached {item_id} -> {name}")


def cmd_flag(item_id, reason, url=None):
    cache = load_cache()
    entry = {"reason": reason}
    if url:
        entry["url"] = url
    cache[str(item_id)] = entry
    save_cache(cache)
    print(f"flagged {item_id}: {reason}")


def cmd_count():
    items = load_audit()
    cache = load_cache()
    total = len(items)
    cached = sum(1 for it in items if str(it["itemId"]) in cache)
    resolved = sum(1 for it in items
                   if str(it["itemId"]) in cache and cache[str(it["itemId"])].get("stats"))
    flagged = cached - resolved
    print(f"total={total}  cached={cached}  resolved={resolved}  flagged={flagged}  remaining={total-cached}")


if __name__ == "__main__":
    if len(sys.argv) < 2:
        print(__doc__)
        sys.exit(1)
    cmd = sys.argv[1]
    if cmd == "next":
        n = int(sys.argv[2]) if len(sys.argv) > 2 else 10
        cmd_next(n)
    elif cmd == "add":
        # add <itemId> <url> <wiki_name> -- <stats>
        idx = sys.argv.index("--")
        cmd_add(int(sys.argv[2]), sys.argv[3], " ".join(sys.argv[4:idx]),
                " ".join(sys.argv[idx+1:]))
    elif cmd == "flag":
        cmd_flag(int(sys.argv[2]), " ".join(sys.argv[3:]))
    elif cmd == "count":
        cmd_count()
    else:
        print(__doc__)
        sys.exit(1)
