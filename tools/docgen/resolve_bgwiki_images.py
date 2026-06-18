"""Resolve each linked item's real BG-Wiki title and cache its description-box
image URL (`<RealTitle>_description.png`) so hover pop-ups show the in-game
STAT BOX (DEF, effects, jobs) instead of a bare icon.

Caches id -> image URL in bgwiki_images.json; `_bgwiki.urls_for_item` reads it
so docgen never touches the network. Re-run when you add items:

    LEGENDARY_LIVE_ROOT=D:/server python tools/docgen/resolve_bgwiki_images.py

BG-Wiki abbreviates ("Mallquis Chapeau +2" -> "Mall. Chapeau +2") and uses
apostrophes the catalogs drop ("Bunzis Hat" -> "Bunzi's Hat"). We resolve real
titles via the MediaWiki API in BATCHES of 50 (its api.php rate-limits rapid
single requests, but batched title queries are few and cheap), retry the
leftovers with apostrophe variants, then HEAD-check each description image on
the static image host. A null cache value = "no description image" -> the
caller falls back to the FFXIAH icon; it's cached so we don't re-query it.
Only uncached / previously-null ids are re-resolved, so re-runs are cheap.
"""
from __future__ import annotations

import hashlib
import json
import os
import re
import time
from concurrent.futures import ThreadPoolExecutor, as_completed
from pathlib import Path
import urllib.request
import urllib.parse
import urllib.error

_UA = {"User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64)"}
_HERE = Path(__file__).resolve().parent
_DOCS = _HERE.parents[1] / "docs"
_CACHE = _HERE / "bgwiki_images.json"
_LIVE = Path(os.environ.get("LEGENDARY_LIVE_ROOT", "D:/server"))
_ITEM_BASIC = _LIVE / "sql" / "item_basic.sql"
_API = "https://www.bg-wiki.com/api.php"

_ITEM_RE = re.compile(
    r"INSERT INTO `item_basic` VALUES\s*\(\s*(\d+)\s*,\s*\d+\s*,\s*'([^']*)'")
_LINK_RE = re.compile(r"ffxiah\.com/item/(\d+)|icon/(\d+)\.png")


def _http(url, head=False, attempts=4):
    for a in range(attempts):
        req = urllib.request.Request(url, headers=_UA, method="HEAD" if head else "GET")
        try:
            r = urllib.request.urlopen(req, timeout=30)
            return r.status, (None if head else r.read())
        except urllib.error.HTTPError as e:
            if e.code == 429 and a < attempts - 1:
                time.sleep(20 * (a + 1)); continue   # rate limited: wait longer
            if e.code in (403, 503) and a < attempts - 1:
                time.sleep(2 * (a + 1)); continue
            return e.code, None
        except Exception:
            if a < attempts - 1:
                time.sleep(1.0 * (a + 1)); continue
            return -1, None
    return -1, None


def _wait_for_api(max_min=None):
    """api.php Cloudflare-rate-limits bursts (HTTP 429 / error 1015). If a prior
    run tripped it, poll once a minute until it clears before resolving. Cap =
    RESOLVE_MAX_WAIT_MIN (default 45; the deploy sets a small value so a
    rate-limit can't stall a publish -- new items just wait for the next run)."""
    if max_min is None:
        max_min = int(os.environ.get("RESOLVE_MAX_WAIT_MIN", "45"))
    probe = _API + "?" + urllib.parse.urlencode(
        {"action": "query", "format": "json", "titles": "Naegling"})
    for attempt in range(max_min):
        st, _ = _http(probe, attempts=1)
        if st == 200:
            if attempt:
                print(f"  api.php available after ~{attempt} min")
            return True
        print(f"  api.php rate-limited (status {st}); waiting 60s ({attempt + 1}/{max_min})")
        time.sleep(60)
    return False


def _id_to_name():
    out = {}
    with _ITEM_BASIC.open(encoding="utf-8", errors="replace") as f:
        for line in f:
            m = _ITEM_RE.search(line)
            if m:
                out[int(m.group(1))] = m.group(2).replace("_", " ").title()
    return out


def _linked_ids():
    ids = set()
    for md in _DOCS.rglob("*.md"):
        for m in _LINK_RE.finditer(md.read_text(encoding="utf-8", errors="replace")):
            ids.add(int(m.group(1) or m.group(2)))
    return ids


def _gear_data_ids():
    """Every item id in the interactive Gear Finder's dataset (the `i` field),
    so its 15k-item hover pop-ups get stat boxes too."""
    gd = _DOCS / "assets" / "gear-data.json"
    if not gd.exists():
        return set()
    try:
        data = json.loads(gd.read_text(encoding="utf-8"))
    except Exception:
        return set()
    return {it["i"] for it in data.get("items", []) if isinstance(it.get("i"), int)}


def _chunks(seq, n):
    for i in range(0, len(seq), n):
        yield seq[i:i + n]


def _titles_batch(names):
    """Resolve up to ~50 names at once -> {name: real_title or None}."""
    result = {n: None for n in names}
    if not names:
        return result
    url = _API + "?" + urllib.parse.urlencode(
        {"action": "query", "format": "json", "redirects": "1", "titles": "|".join(names)})
    st, body = _http(url)
    if st != 200 or not body:
        return result
    try:
        q = json.loads(body).get("query", {})
    except Exception:
        return result
    norm = {x["from"]: x["to"] for x in q.get("normalized", [])}
    redir = {x["from"]: x["to"] for x in q.get("redirects", [])}
    existing = {p["title"] for pid, p in q.get("pages", {}).items() if int(pid) > 0}
    for n in names:
        t = norm.get(n, n)
        t = redir.get(t, t)
        if t in existing:
            result[n] = t
    return result


def _apostrophe_variants(name):
    words = name.split()
    out = []
    for i, w in enumerate(words):
        if w.endswith("s") and len(w) > 2:
            c = words[:]
            c[i] = w[:-1] + "'s"
            out.append(" ".join(c))
    return out


def _descimg_if_exists(title):
    fn = title.replace(" ", "_") + "_description.png"
    h = hashlib.md5(fn.encode("utf-8")).hexdigest()
    url = f"https://www.bg-wiki.com/images/{h[0]}/{h[:2]}/{urllib.parse.quote(fn)}"
    st, _ = _http(url, head=True)
    return url if st == 200 else None


def main():
    if not _ITEM_BASIC.exists():
        print(f"ERROR: {_ITEM_BASIC} not found (set LEGENDARY_LIVE_ROOT)")
        return 1
    names = _id_to_name()
    ids = sorted(_linked_ids() | _gear_data_ids())
    cache = {}
    if _CACHE.exists():
        try:
            cache = json.loads(_CACHE.read_text(encoding="utf-8"))
        except Exception:
            cache = {}
    # Default: resolve only UNCACHED ids (new items) -> a fast no-op once warm,
    # so it's safe to run on every deploy. Set RESOLVE_RETRY_MISSES=1 to also
    # retry cached nulls (items where no image was found) -- use that after a
    # rate-limited run, not on every deploy.
    if os.environ.get("RESOLVE_RETRY_MISSES"):
        todo = [i for i in ids if (str(i) not in cache or cache.get(str(i)) is None) and i in names]
    else:
        todo = [i for i in ids if str(i) not in cache and i in names]
    print(f"ids: {len(ids)}   cached hits: {sum(1 for v in cache.values() if v)}"
          f"   to resolve: {len(todo)}")

    if todo and not _wait_for_api():
        print("api.php still rate-limited after the wait; try again later.")
        return 2

    uniq = sorted({names[i] for i in todo})
    title_by_name = {}
    for bi, batch in enumerate(_chunks(uniq, 50)):
        title_by_name.update(_titles_batch(batch))
        time.sleep(4)   # throttle: stay well under the rate limit
        if bi % 5 == 0:
            print(f"  titles: {min((bi + 1) * 50, len(uniq))}/{len(uniq)}")

    # Apostrophe-variant retry for names with no direct page.
    unresolved = [n for n in uniq if not title_by_name.get(n)]
    variant_to_name, variants = {}, []
    for n in unresolved:
        for v in _apostrophe_variants(n):
            variant_to_name[v] = n
            variants.append(v)
    for batch in _chunks(variants, 50):
        for v, t in _titles_batch(batch).items():
            if t and not title_by_name.get(variant_to_name[v]):
                title_by_name[variant_to_name[v]] = t
        time.sleep(4)
    print(f"  titles resolved: {sum(1 for t in title_by_name.values() if t)}/{len(uniq)}")

    # Image existence checks (static host tolerates concurrency).
    have = {n: t for n, t in title_by_name.items() if t}
    img_by_name = {}
    done = 0
    with ThreadPoolExecutor(max_workers=6) as ex:
        futs = {ex.submit(_descimg_if_exists, t): n for n, t in have.items()}
        for fut in as_completed(futs):
            img_by_name[futs[fut]] = fut.result()
            done += 1
            if done % 200 == 0:
                print(f"  images: {done}/{len(have)}")

    for i in todo:
        cache[str(i)] = img_by_name.get(names[i])
    _CACHE.write_text(json.dumps(cache, indent=0, sort_keys=True), encoding="utf-8")
    hits = sum(1 for v in cache.values() if v)
    print(f"DONE. cache: {len(cache)} ids, {hits} with stat-box images "
          f"({len(cache) - hits} icon-fallback).")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
