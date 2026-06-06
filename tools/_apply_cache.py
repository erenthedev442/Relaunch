"""Apply a batch of cache updates from stdin (JSON dict).

Usage:
  python tools/_apply_cache.py < updates.json

Or:
  echo '{"11697": {"url": "...", "name": "...", "stats": "..."}}' | python tools/_apply_cache.py
"""
import json
import os
import sys

REPO  = os.path.normpath(os.path.join(os.path.dirname(__file__), ".."))
CACHE = os.path.join(REPO, "tools", "bgwiki_stats_cache.json")


def main():
    if not os.path.exists(CACHE):
        cache = {}
    else:
        with open(CACHE, "r", encoding="utf-8") as f:
            cache = json.load(f)
    updates = json.loads(sys.stdin.read())
    for k, v in updates.items():
        cache[str(k)] = v
    with open(CACHE, "w", encoding="utf-8") as f:
        json.dump(cache, f, indent=2, ensure_ascii=False, sort_keys=True)
    print(f"applied {len(updates)} entries  total cache: {len(cache)}")


if __name__ == "__main__":
    main()
