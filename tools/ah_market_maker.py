#!/usr/bin/python3
"""
AH market-maker bot for LandSandBoat.

Keeps the auction house stocked to a per-item target and buys back excess
player supply by writing directly to the `auction_house` table. It leans on
two triggers that already exist in sql/triggers.sql:

  - auction_house_list (BEFORE INSERT): auto-adds the itemid to the
        auction_house_items browse whitelist, so freshly listed items show up.
  - auction_house_buy  (BEFORE UPDATE): when a row's `sale` becomes non-zero
        AND OLD.seller != 0, it pays that seller `sale` gil via delivery_box.

seller = 0 is therefore the "system seller": the bot's own listings pay nobody
when a player buys them (a pure gil sink), while buying a real player's listing
pays that player automatically (a gil faucet). The bot needs no character,
inventory, or gil of its own - it just writes rows.

Target basis: target_qty counts ALL unsold listings (players + bot). Each pass,
per configured (itemid, stack):
  - under target  -> insert bot listings to fill the gap (priced at sell_price)
  - over target   -> first delist the bot's own surplus (free), then buy the
                     cheapest player listings priced <= sell_price, paying
                     sell_price each, until back at target

The bot buys and sells at the same single price (sell_price): a fixed-price
market maker. Listings asking more than sell_price are left alone.

Rules: besides hand-listed `items`, the config supports `rules` - auto-selected
item sets handled with set-based SQL. The "non_ilvl_gear" rule keeps every
auctionable piece of equipment that has no item level stocked at a level-scaled
price. The bot always keeps its own target listed (independent of players), and
(optionally) buys player listings of those items priced at or below the bot's
price, paying the bot's price. See the config _README.

Safe by default: this is a DRY RUN unless you pass --commit. A dry run only
prints the actions it would take and never modifies the database.

Usage:
    python ah_market_maker.py                      # dry run, one pass
    python ah_market_maker.py --commit             # apply once (use w/ Task Scheduler)
    python ah_market_maker.py --commit --loop 300  # apply every 300 seconds

Reads DB credentials from ../settings/network.lua (same as give_items.py) and
item config from ah_market_maker_config.json next to this script.
"""
import argparse
import json
import os
import re
import time

import mariadb

# Best-effort heartbeat so the docs status page can flag this job if it dies
# silently. _heartbeat.py sits next to this script (tools/), which is on
# sys.path when run directly. Degrade to a no-op if it's ever absent.
try:
    from _heartbeat import write_heartbeat
except Exception:
    def write_heartbeat(*_a, **_k):
        return False

SELLER_ID = 0            # system seller: its sales pay nobody (gil sink)
SELLER_NAME = "AH-Jeuno" # cosmetic, stored in auction_house.seller_name (<=15 chars)

SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
SERVER_DIR = os.path.dirname(SCRIPT_DIR)


def load_credentials():
    path = os.path.join(SERVER_DIR, "settings", "network.lua")
    creds = {}
    with open(path) as f:
        for line in f:
            match = re.findall(r"(SQL_\w+)\s*=\s*(?:['\"](.*?)['\"]|([^'\s,]+)),", line)
            if match:
                creds[match[0][0]] = match[0][2] if match[0][2] else match[0][1]
    return creds


def connect():
    c = load_credentials()
    db = mariadb.connect(
        host=c["SQL_HOST"],
        port=int(c["SQL_PORT"]),
        user=c["SQL_LOGIN"],
        passwd=c["SQL_PASSWORD"],
        db=c["SQL_DATABASE"],
    )
    print("Connected to database: " + c["SQL_DATABASE"])
    return db


def load_config():
    path = os.path.join(SCRIPT_DIR, "ah_market_maker_config.json")
    with open(path) as f:
        return json.load(f)


def count_unsold(cur, itemid, stack):
    """Every unsold listing of this item/stack, players + bot."""
    cur.execute(
        "SELECT COUNT(*) FROM auction_house "
        "WHERE itemid = %s AND stack = %s AND buyer_name IS NULL",
        (itemid, stack),
    )
    return cur.fetchone()[0]


def count_bot_unsold(cur, itemid, stack):
    cur.execute(
        "SELECT COUNT(*) FROM auction_house "
        "WHERE itemid = %s AND stack = %s AND buyer_name IS NULL AND seller = %s",
        (itemid, stack, SELLER_ID),
    )
    return cur.fetchone()[0]


def count_buyable(cur, itemid, stack, max_price, limit):
    """How many player listings the buy-back would take this pass (preview)."""
    cur.execute(
        "SELECT COUNT(*) FROM (SELECT id FROM auction_house "
        "WHERE itemid = %s AND stack = %s AND buyer_name IS NULL "
        "AND seller <> %s AND price <= %s ORDER BY price ASC LIMIT " + str(int(limit)) + ") t",
        (itemid, stack, SELLER_ID, max_price),
    )
    return cur.fetchone()[0]


def stock_up(cur, item, n):
    for _ in range(n):
        cur.execute(
            "INSERT INTO auction_house (itemid, stack, seller, seller_name, date, price) "
            "VALUES (%s, %s, %s, %s, UNIX_TIMESTAMP(), %s)",
            (item["itemid"], item["stack"], SELLER_ID, SELLER_NAME, item["sell_price"]),
        )


def remove_bot_surplus(cur, item, n):
    # Free: the bot's own unsold stock, no payout and no item to return.
    cur.execute(
        "DELETE FROM auction_house "
        "WHERE itemid = %s AND stack = %s AND buyer_name IS NULL AND seller = %s "
        "LIMIT " + str(int(n)),
        (item["itemid"], item["stack"], SELLER_ID),
    )
    return cur.rowcount


def buy_back(cur, item, n):
    # Buy the cheapest eligible player listings (asking <= sell_price) and pay
    # each seller exactly sell_price; the auction_house_buy trigger delivers it.
    price = item["sell_price"]
    cur.execute(
        "UPDATE auction_house SET buyer_name = %s, sale = %s, sell_date = UNIX_TIMESTAMP() "
        "WHERE itemid = %s AND stack = %s AND buyer_name IS NULL AND seller <> %s AND price <= %s "
        "ORDER BY price ASC LIMIT " + str(int(n)),
        (SELLER_NAME, price, item["itemid"], item["stack"], SELLER_ID, price),
    )
    return cur.rowcount


def process_item(cur, item, commit):
    itemid = item["itemid"]
    stack = item.get("stack", 0)
    target = item["target_qty"]
    sell_price = item["sell_price"]
    do_buyback = item.get("buyback", True)
    label = "{} {}".format(item.get("name", "item %d" % itemid), "(stack)" if stack else "(single)")

    total = count_unsold(cur, itemid, stack)

    if total < target:
        need = target - total
        if commit:
            stock_up(cur, item, need)
        print("  {}: {}/{} -> stock +{} @ {}g".format(label, total, target, need, item["sell_price"]))

    elif total > target:
        excess = total - target
        if commit:
            removed = remove_bot_surplus(cur, item, excess)
        else:
            removed = min(excess, count_bot_unsold(cur, itemid, stack))
        excess -= removed

        bought = 0
        if excess > 0 and do_buyback:
            bought = buy_back(cur, item, excess) if commit else count_buyable(cur, itemid, stack, sell_price, excess)

        leftover = (total - target) - removed - bought
        actions = []
        if removed:
            actions.append("delist {} bot".format(removed))
        if bought:
            actions.append("buy {} player @ {}g".format(bought, sell_price))
        if leftover > 0:
            actions.append("{} left ({})".format(leftover, "above {}g".format(sell_price) if do_buyback else "buy-back off"))
        print("  {}: {}/{} over by {} -> {}".format(label, total, target, total - target, ", ".join(actions) or "no action"))

    else:
        print("  {}: {}/{} ok".format(label, total, target))


# =====================================================================
# Rule-based mode: auto-selected item sets handled with set-based SQL,
# because per-item config doesn't scale to thousands of items. One rule
# type today: "non_ilvl_gear".
# =====================================================================

# Auctionable equipment with no item level. All conditions required:
#   e.ilevel = 0     -> no item level (excludes all iLvl endgame gear)
#   b.aH <> 0        -> has a real AH browse category. The search server
#                       lists items by `WHERE aH = ?`, so an aH=0 item would
#                       never appear in any browse category even if listed.
#   NoAuction clear  -> the engine lets players list it (flag 0x40 = 64)
#   Exclusive clear  -> not bind-on-pickup / untradeable (flag 0x4000 = 16384)
# Aliases: e = item_equipment, b = item_basic. ~5,786 items match.
GEAR_FROM = "item_equipment e JOIN item_basic b ON b.itemid = e.itemId"
GEAR_WHERE = ("e.ilevel = 0 AND b.aH <> 0 "
              "AND (b.flags & 64) = 0 AND (b.flags & 16384) = 0")


def price_case(brackets, col="e.level"):
    """SQL CASE mapping equip level to price from [[maxlvl, price], ...].

    The last bracket's price is the ELSE (covers everything above the final
    threshold, e.g. level 99). All numbers are int-coerced, so the resulting
    string is safe to inline into a query.
    """
    parts = ["CASE"]
    for maxlvl, price in brackets[:-1]:
        parts.append("WHEN {} <= {} THEN {}".format(col, int(maxlvl), int(price)))
    parts.append("ELSE {} END".format(int(brackets[-1][1])))
    return " ".join(parts)


def gear_topup(cur, brackets, target, commit):
    """Keep `target` of the BOT's own (seller=0) listings per gear item.

    Counts only the bot's own unsold listings, independent of players, so a
    player listing high never displaces the bot's cheap copy. Each call inserts
    one row per under-stocked item; loops up to `target` times to fill from
    zero. Returns (rows_inserted, items_short_of_target).
    """
    pc = price_case(brackets)
    countsub = ("(SELECT COUNT(*) FROM auction_house ah "
                "WHERE ah.itemid = e.itemId AND ah.stack = 0 "
                "AND ah.buyer_name IS NULL AND ah.seller = {})".format(SELLER_ID))

    if not commit:
        cur.execute(
            "SELECT COALESCE(SUM(GREATEST(0, {t} - cnt)), 0), "
            "       COALESCE(SUM(CASE WHEN cnt < {t} THEN 1 ELSE 0 END), 0) "
            "FROM (SELECT {sub} AS cnt FROM {frm} WHERE {w}) x".format(
                t=int(target), sub=countsub, frm=GEAR_FROM, w=GEAR_WHERE))
        row = cur.fetchone()
        return int(row[0]), int(row[1])

    inserted = 0
    for _ in range(int(target)):
        cur.execute(
            "INSERT INTO auction_house (itemid, stack, seller, seller_name, date, price) "
            "SELECT e.itemId, 0, {sid}, %s, UNIX_TIMESTAMP(), {pc} "
            "FROM {frm} WHERE {w} AND {sub} < {t}".format(
                sid=SELLER_ID, pc=pc, frm=GEAR_FROM, w=GEAR_WHERE,
                sub=countsub, t=int(target)),
            (SELLER_NAME,))
        added = cur.rowcount
        inserted += added
        if added == 0:
            break
    return inserted, inserted


def gear_buyback(cur, brackets, cap, commit):
    """Buy the cheapest player gear listings priced <= the bot's bracket price.

    Pays each seller exactly the bracket price (the auction_house_buy trigger
    delivers the gil). At most `cap` listings per pass - a safety valve against
    a runaway gil faucet. Returns the number bought (or that would be bought).
    """
    pc = price_case(brackets)
    cur.execute(
        "SELECT ah.id, {pc} AS botprice "
        "FROM auction_house ah JOIN {frm} ON e.itemId = ah.itemid "
        "WHERE ah.stack = 0 AND ah.buyer_name IS NULL AND ah.seller <> {sid} "
        "AND {w} AND ah.price <= ({pc}) "
        "ORDER BY ah.price ASC LIMIT {cap}".format(
            pc=pc, frm=GEAR_FROM, sid=SELLER_ID, w=GEAR_WHERE, cap=int(cap)))
    rows = cur.fetchall()
    if not commit or not rows:
        return len(rows)

    for ah_id, botprice in rows:
        cur.execute(
            "UPDATE auction_house SET buyer_name = %s, sale = %s, "
            "sell_date = UNIX_TIMESTAMP() WHERE id = %s",
            (SELLER_NAME, int(botprice), ah_id))
    return len(rows)


def process_rule(cur, rule, commit):
    if rule.get("type") != "non_ilvl_gear":
        print("  rule '{}': unknown type, skipped".format(rule.get("type")))
        return

    target = rule.get("target_qty", 1)
    brackets = rule["level_price_brackets"]
    do_buyback = rule.get("buyback", True)
    cap = rule.get("max_buyback_per_pass", 50)

    added, short = gear_topup(cur, brackets, target, commit)
    print("  non_ilvl_gear: keep {} each -> +{} listings across {} item(s) short".format(
        target, added, short))

    if do_buyback:
        bought = gear_buyback(cur, brackets, cap, commit)
        if bought:
            print("  non_ilvl_gear: buy {} player listing(s) at bot price (cap {}/pass)".format(bought, cap))
        else:
            print("  non_ilvl_gear: no player listings at/below bot price")


def run_pass(db, cfg, commit):
    mode = "COMMIT" if commit else "DRY RUN"
    print("[{}] AH market-maker pass ({})".format(time.strftime("%Y-%m-%d %H:%M:%S"), mode))
    cur = db.cursor()

    # ── Pre-pass cleanup ────────────────────────────────────────────────────
    # When buy_back() marks a player listing as bought by 'AH-Jeuno'
    # (charid=0), the search server delivers the purchased item to the
    # system account's delivery_box.  That row is never consumed, so the
    # next pass hits a duplicate PRIMARY KEY (charid=0, box=1, itemid=X)
    # for every item the bot has ever bought back.
    #
    # The system account has no real delivery box — clear it before every
    # commit pass so the rows don't accumulate.  DRY RUN skips this (no
    # buy_back runs, nothing to clean), but we report the pending backlog.
    if commit:
        cur.execute("DELETE FROM delivery_box WHERE charid = %s", (SELLER_ID,))
        deleted = cur.rowcount
        if deleted:
            print("  pre-pass: cleared {} stale item(s) from system delivery_box (charid={})".format(
                deleted, SELLER_ID))
        db.commit()
    else:
        cur.execute("SELECT COUNT(*) FROM delivery_box WHERE charid = %s", (SELLER_ID,))
        pending = cur.fetchone()[0]
        if pending:
            print("  pre-pass: {} item(s) in system delivery_box would be cleared on --commit".format(pending))

    for rule in cfg.get("rules", []):
        try:
            process_rule(cur, rule, commit)
            if commit:
                db.commit()
        except Exception as err:
            db.rollback()
            print("  ERROR on rule {}: {}".format(rule.get("type"), err))

    for item in cfg.get("items", []):
        try:
            process_item(cur, item, commit)
            if commit:
                db.commit()
        except Exception as err:
            db.rollback()
            print("  ERROR on item {}: {}".format(item.get("itemid"), err))

    cur.close()


def main():
    ap = argparse.ArgumentParser(description="AH market-maker bot for LandSandBoat.")
    ap.add_argument("--commit", action="store_true", help="actually write to the DB (default: dry run)")
    ap.add_argument("--loop", type=int, metavar="SECONDS", help="run forever, sleeping SECONDS between passes")
    args = ap.parse_args()

    cfg = load_config()
    if not cfg.get("rules") and not cfg.get("items"):
        print("Nothing configured in ah_market_maker_config.json (no rules or items)")
        return

    db = connect()
    try:
        while True:
            run_pass(db, cfg, args.commit)
            write_heartbeat(SERVER_DIR, "ah_market_maker", ok=True,
                            detail=("commit" if args.commit else "dry-run") + " pass")
            if not args.loop:
                break
            time.sleep(args.loop)
    finally:
        db.close()


if __name__ == "__main__":
    main()
