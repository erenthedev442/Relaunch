"""Render a live server economy + population dashboard onto
docs/community/economy.md.

Reads aggregate, *anonymous* figures from the live database — gil supply,
Auction House depth + velocity, and population — and writes them between
DOCGEN markers. No character is named: this is a macro view of the server
economy, so the leaderboard opt-out doesn't apply (nothing here identifies
an individual). GM / test characters (`chars.gmlevel > 0`) are excluded so
the numbers reflect the real player economy.

Schema notes (confirmed against the live LSB DB):
  * Gil lives in `char_inventory` at `itemId = 65535` — exactly one row per
    character, so `SUM(quantity)` is the true money supply.
  * The Auction House market-maker NPC lists under `seller = 0`
    (`seller_name = 'AH-Jeuno'`); player listings carry a real seller charid.
    A *sale* whose original seller is 0 is a gil **sink** — that gil leaves
    circulation to the NPC — which we surface separately from player↔player
    volume.
  * `auction_house.price` is the asking price (used for live shelf value);
    `auction_house.sale` is the realized price on a completed sale, with
    `sell_date` the Unix timestamp it cleared.
  * `chars.last_logout` / `chars.timecreated` are DATETIMEs (so the
    population windows use `NOW() - INTERVAL n DAY`).

Each section is fetched independently and degrades to a fallback on error,
so a single bad query can't blank the whole page. The whole module no-ops
silently when the database is unreachable (e.g. CI without
LEGENDARY_LIVE_ROOT), leaving the previously-published numbers in place.
"""
from __future__ import annotations

from pathlib import Path

from tools.docgen._db import connect
from tools.docgen._markers import write_between_markers


_GIL_ITEM_ID = 65535
_HOT_LIMIT = 15


# ---------------------------------------------------------------------------
# Formatting helpers
# ---------------------------------------------------------------------------
def _compact(n: int) -> str:
    """Big number -> short human form: 64_763_100 -> '64.76M'."""
    n = int(n)
    if abs(n) >= 1_000_000_000:
        return f"{n / 1_000_000_000:.2f}B"
    if abs(n) >= 1_000_000:
        return f"{n / 1_000_000:.2f}M"
    if abs(n) >= 1_000:
        return f"{n / 1_000:.1f}K"
    return f"{n:,}"


def _plural(n: int, unit: str) -> str:
    return f"{n:,} {unit}{'' if n == 1 else 's'}"


def _format_playtime(seconds: int) -> str:
    """Cumulative playtime -> 'N years, M days' / 'M days, H hours' / 'H hours'."""
    seconds = int(seconds)
    days = seconds // 86400
    hours = (seconds % 86400) // 3600
    if days >= 365:
        years = days // 365
        rem_days = days % 365
        return f"{_plural(years, 'year')}, {_plural(rem_days, 'day')}"
    if days >= 1:
        return f"{_plural(days, 'day')}, {_plural(hours, 'hour')}"
    return _plural(hours, "hour")


def _pretty_item(name: str) -> str:
    """item_basic.name ('cotton_cloth') -> 'Cotton Cloth'."""
    return (name or "").replace("_", " ").strip().title() or "(unknown item)"


def _median(values: list[int]) -> int:
    if not values:
        return 0
    vals = sorted(values)
    n = len(vals)
    mid = n // 2
    if n % 2:
        return vals[mid]
    return (vals[mid - 1] + vals[mid]) // 2


# ---------------------------------------------------------------------------
# Data collection (each piece guarded independently)
# ---------------------------------------------------------------------------
def _safe(label: str, fn, default):
    try:
        return fn()
    except Exception as e:  # noqa: BLE001 - degrade gracefully, never abort the page
        print(f"[economy] {label}: query failed ({e}); using fallback")
        return default


def _collect(cur) -> dict:
    d: dict = {}

    def gil_list():
        cur.execute(
            """
            SELECT ci.quantity
              FROM char_inventory ci
              JOIN chars c ON c.charid = ci.charid
             WHERE ci.itemId = %s AND ci.quantity > 0 AND c.gmlevel = 0
            """,
            (_GIL_ITEM_ID,),
        )
        return [int(r[0]) for r in cur.fetchall()]

    d["gil_list"] = _safe("gil_list", gil_list, [])

    def pop():
        out: dict = {}
        cur.execute("SELECT COUNT(*) FROM accounts_sessions")
        out["online"] = int(cur.fetchone()[0])
        cur.execute("SELECT COUNT(*), COALESCE(SUM(playtime), 0) FROM chars WHERE gmlevel = 0")
        r = cur.fetchone()
        out["chars"] = int(r[0])
        out["playtime"] = int(r[1])
        for days in (7, 30):
            cur.execute(
                f"SELECT COUNT(*) FROM chars WHERE gmlevel = 0 "
                f"AND timecreated > NOW() - INTERVAL {days} DAY"
            )
            out[f"new_{days}"] = int(cur.fetchone()[0])
            cur.execute(
                f"SELECT COUNT(*) FROM chars WHERE gmlevel = 0 "
                f"AND last_logout > NOW() - INTERVAL {days} DAY"
            )
            out[f"active_{days}"] = int(cur.fetchone()[0])
        return out

    d["pop"] = _safe("population", pop, {})

    def ah_listings():
        cur.execute(
            """
            SELECT
              COALESCE(SUM(seller = 0), 0)  AS mm,
              COALESCE(SUM(seller <> 0), 0) AS player,
              COUNT(*)                      AS total,
              COUNT(DISTINCT itemid)        AS distinct_items,
              COALESCE(SUM(price), 0)       AS shelf_value
            FROM auction_house
            WHERE sale = 0
            """
        )
        r = cur.fetchone()
        return {
            "mm": int(r[0]),
            "player": int(r[1]),
            "total": int(r[2]),
            "distinct": int(r[3]),
            "shelf": int(r[4]),
        }

    d["ah"] = _safe("ah_listings", ah_listings, {})

    def velocity():
        out: dict = {}
        for days in (1, 7, 30):
            cur.execute(
                """
                SELECT COUNT(*),
                       COALESCE(SUM(sale), 0),
                       COALESCE(SUM(CASE WHEN seller = 0 THEN sale ELSE 0 END), 0)
                  FROM auction_house
                 WHERE sale > 0 AND sell_date > UNIX_TIMESTAMP() - %s
                """,
                (days * 86400,),
            )
            r = cur.fetchone()
            out[days] = {"n": int(r[0]), "gil": int(r[1]), "sunk": int(r[2])}
        return out

    d["velocity"] = _safe("velocity", velocity, {})

    def hot():
        cur.execute(
            """
            SELECT ah.itemid, ib.name, COUNT(*) AS units, COALESCE(SUM(ah.sale), 0) AS gil
              FROM auction_house ah
              JOIN item_basic ib ON ib.itemid = ah.itemid
             WHERE ah.sale > 0 AND ah.sell_date > UNIX_TIMESTAMP() - %s
          GROUP BY ah.itemid, ib.name
          ORDER BY units DESC, gil DESC
             LIMIT %s
            """,
            (30 * 86400, _HOT_LIMIT),
        )
        return [(int(r[0]), r[1], int(r[2]), int(r[3])) for r in cur.fetchall()]

    d["hot"] = _safe("hot_items", hot, [])

    return d


# ---------------------------------------------------------------------------
# Section renderers (pure formatting; never raise on missing data)
# ---------------------------------------------------------------------------
def _render_overview(d: dict) -> str:
    gil_list = d.get("gil_list") or []
    pop = d.get("pop") or {}
    ah = d.get("ah") or {}
    total_gil = sum(gil_list)
    lines = [
        "A live snapshot of the server economy and population. All figures "
        "exclude GM / test characters and refresh each time the site is "
        "rebuilt.",
        "",
        "| Metric | Value |",
        "|---|---:|",
        f"| Gil in circulation | **{_compact(total_gil)}** gil |",
        f"| Players online now | **{pop.get('online', 0):,}** |",
        f"| Characters (non-GM) | {pop.get('chars', 0):,} |",
        f"| Active in last 7 days | {pop.get('active_7', 0):,} |",
        f"| AH listings (live) | {ah.get('total', 0):,} |",
        f"| Cumulative playtime | {_format_playtime(pop.get('playtime', 0))} |",
    ]
    return "\n".join(lines)


def _render_gil(d: dict) -> str:
    gil_list = d.get("gil_list") or []
    total = sum(gil_list)
    n = len(gil_list)
    avg = total // n if n else 0
    med = _median(gil_list)
    share = 0.0
    if n and total:
        k = max(1, n // 10)
        top = sum(sorted(gil_list, reverse=True)[:k])
        share = 100.0 * top / total
    lines = [
        "Total gil held by player characters — the money supply. Gil sitting "
        "in Auction House escrow (unsold listings) and on GM characters is "
        "not counted.",
        "",
        "| Measure | Value |",
        "|---|---:|",
        f"| Total gil in circulation | {total:,} gil |",
        f"| Characters holding gil | {n:,} |",
        f"| Average per character | {avg:,} gil |",
        f"| Median per character | {med:,} gil |",
        f"| Wealthiest 10% hold | {share:.1f}% of all gil |",
    ]
    return "\n".join(lines)


def _render_ah(d: dict) -> str:
    ah = d.get("ah") or {}
    lines = [
        "Open Auction House listings right now. The market-maker (an NPC "
        "seller, **AH-Jeuno**) keeps a price floor and a deep catalog of gear "
        "on the shelf; player listings are everything posted by real "
        "characters.",
        "",
        "| Measure | Value |",
        "|---|---:|",
        f"| Live listings (total) | {ah.get('total', 0):,} |",
        f"| — Market-maker (AH-Jeuno) | {ah.get('mm', 0):,} |",
        f"| — Player-listed | {ah.get('player', 0):,} |",
        f"| Distinct items available | {ah.get('distinct', 0):,} |",
        f"| Total shelf value (asking) | {ah.get('shelf', 0):,} gil |",
    ]
    return "\n".join(lines)


def _render_velocity(d: dict) -> str:
    v = d.get("velocity") or {}
    lines = [
        "Completed Auction House sales over recent windows. **Gil volume** is "
        "the total that changed hands; **gil sunk** is the portion spent "
        "buying from the market-maker, which removes that gil from the economy "
        "for good.",
        "",
        "| Window | Lots sold | Gil volume | Gil sunk to AH |",
        "|---|---:|---:|---:|",
    ]
    for days, label in ((1, "Last 24 hours"), (7, "Last 7 days"), (30, "Last 30 days")):
        w = v.get(days) or {}
        lines.append(
            f"| {label} | {w.get('n', 0):,} | {w.get('gil', 0):,} gil | "
            f"{w.get('sunk', 0):,} gil |"
        )
    return "\n".join(lines)


def _render_hot(d: dict) -> str:
    hot = d.get("hot") or []
    lines = [
        "The most actively traded items on the Auction House over the last 30 "
        "days, by number of lots sold.",
        "",
    ]
    if not hot:
        lines.append(
            "_No completed sales in the last 30 days yet — once trading picks "
            "up, the hottest items will appear here._"
        )
        return "\n".join(lines)
    lines.append("| # | Item | Lots sold | Gil volume |")
    lines.append("|---:|---|---:|---:|")
    for i, (_itemid, name, units, gil) in enumerate(hot, start=1):
        lines.append(f"| {i} | {_pretty_item(name)} | {units:,} | {gil:,} gil |")
    return "\n".join(lines)


def _render_population(d: dict) -> str:
    pop = d.get("pop") or {}
    lines = [
        "Who's around. **Active** counts characters that logged out within the "
        "window (a proxy for recent play); **new** counts characters created "
        "in the window.",
        "",
        "| Measure | Value |",
        "|---|---:|",
        f"| Online right now | {pop.get('online', 0):,} |",
        f"| Total characters | {pop.get('chars', 0):,} |",
        f"| Active — last 7 days | {pop.get('active_7', 0):,} |",
        f"| Active — last 30 days | {pop.get('active_30', 0):,} |",
        f"| New — last 7 days | {pop.get('new_7', 0):,} |",
        f"| New — last 30 days | {pop.get('new_30', 0):,} |",
        f"| Cumulative playtime (all chars) | {_format_playtime(pop.get('playtime', 0))} |",
    ]
    return "\n".join(lines)


# ---------------------------------------------------------------------------
# Entry point
# ---------------------------------------------------------------------------
def generate(repo_root: Path, docs_dir: Path) -> None:
    conn = connect(repo_root)
    if conn is None:
        print("[economy] skip: no DB connection (LEGENDARY_LIVE_ROOT unset / DB unreachable)")
        return

    page = docs_dir / "community" / "economy.md"
    if not page.exists():
        print(f"[economy] skip: page not found ({page})")
        conn.close()
        return

    cur = conn.cursor()
    written = 0
    try:
        d = _collect(cur)
        blocks = {
            "econ-overview":   _render_overview(d),
            "econ-gil":        _render_gil(d),
            "econ-ah":         _render_ah(d),
            "econ-velocity":   _render_velocity(d),
            "econ-hot":        _render_hot(d),
            "econ-population": _render_population(d),
        }
        for marker, content in blocks.items():
            if write_between_markers(page, marker, content):
                written += 1
            else:
                print(f"[economy] {marker}: marker missing in {page.name}")
    finally:
        cur.close()
        conn.close()

    print(f"[economy] {written} section(s) written into markers")
