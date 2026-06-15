#!/usr/bin/env bash
# ============================================================================
# ah_status.sh  --  AH market-maker status + transaction history.
# Invoked by "Legendary - AH Bot Status.bat" (which pipes this to the box's
# bash). READ-ONLY: only queries the live DB + reads the cron/log. Safe anytime.
# ============================================================================
set -uo pipefail
LOG="$HOME/ah_market_maker.log"

echo "===================== AH MARKET-MAKER ====================="
echo " now (UTC):  $(date -u '+%Y-%m-%d %H:%M:%S')"

# ---- health: how long since the last run? (cron runs every 2h) -------------
if [ -f "$LOG" ]; then
  AGE=$(( $(date +%s) - $(date -r "$LOG" +%s) ))
  H=$(( AGE / 3600 )); M=$(( (AGE % 3600) / 60 ))
  if [ "$AGE" -lt 10800 ]; then
    echo " STATUS:     HEALTHY  (last run ${H}h ${M}m ago)"
  else
    echo " STATUS:     *** STALE *** (last run ${H}h ${M}m ago; cron is every 2h -- check it)"
  fi
else
  echo " STATUS:     *** NO LOG FILE -- the bot may never have run ***"
fi

echo
echo "--- schedule ---"
crontab -l 2>/dev/null | grep -iE "ah_market|market_maker" | sed 's/^/  /' || echo "  !! no AH entry in the azureuser crontab"
[ -f /etc/cron.d/ah-market-maker ] && echo "  (note: a duplicate /etc/cron.d/ah-market-maker also fires daily at 04:00 UTC)"

echo
echo "--- last run output (log tail) ---"
tail -5 "$LOG" 2>/dev/null | sed 's/^/  /'

echo
echo "===================== TRANSACTION SUMMARY ====================="
sudo mariadb xidb -t -e "
SELECT 'Buybacks TOTAL (bot paid players)' metric, COUNT(*) n, CONCAT(FORMAT(IFNULL(SUM(sale),0),0),' g') gil FROM auction_house WHERE buyer_name='AH-Jeuno'
UNION ALL SELECT 'Buybacks last 24h', COUNT(*), CONCAT(FORMAT(IFNULL(SUM(sale),0),0),' g') FROM auction_house WHERE buyer_name='AH-Jeuno' AND sell_date>=UNIX_TIMESTAMP(NOW()-INTERVAL 24 HOUR)
UNION ALL SELECT 'Buybacks last 7d',  COUNT(*), CONCAT(FORMAT(IFNULL(SUM(sale),0),0),' g') FROM auction_house WHERE buyer_name='AH-Jeuno' AND sell_date>=UNIX_TIMESTAMP(NOW()-INTERVAL 7 DAY)
UNION ALL SELECT 'Gear SOLD TOTAL (gil sink)', COUNT(*), CONCAT(FORMAT(IFNULL(SUM(sale),0),0),' g') FROM auction_house WHERE seller=0 AND sell_date>0
UNION ALL SELECT 'Gear SOLD last 24h', COUNT(*), CONCAT(FORMAT(IFNULL(SUM(sale),0),0),' g') FROM auction_house WHERE seller=0 AND sell_date>=UNIX_TIMESTAMP(NOW()-INTERVAL 24 HOUR)
UNION ALL SELECT 'Stock available now', COUNT(*), '' FROM auction_house WHERE seller=0 AND sell_date=0
UNION ALL SELECT 'Pending buyback pool', COUNT(*), '(player listings awaiting next run)' FROM auction_house WHERE seller<>0 AND sell_date=0;" 2>/dev/null

echo
echo "--- last 15 BUYBACKS (bot paid players) ---"
sudo mariadb xidb -t -e "
SELECT FROM_UNIXTIME(a.sell_date) sold_utc, b.name item, a.stack, CONCAT(FORMAT(a.sale,0),' g') paid, a.seller_name to_player
FROM auction_house a LEFT JOIN item_basic b ON b.itemid=a.itemid
WHERE a.buyer_name='AH-Jeuno' AND a.sell_date>0 ORDER BY a.sell_date DESC LIMIT 15;" 2>/dev/null

echo
echo "--- last 15 GEAR SALES (players bought from the bot) ---"
sudo mariadb xidb -t -e "
SELECT FROM_UNIXTIME(a.sell_date) sold_utc, b.name item, CONCAT(FORMAT(a.sale,0),' g') price, a.buyer_name bought_by
FROM auction_house a LEFT JOIN item_basic b ON b.itemid=a.itemid
WHERE a.seller=0 AND a.sell_date>0 ORDER BY a.sell_date DESC LIMIT 15;" 2>/dev/null

echo
echo "(read-only snapshot -- run the bat anytime)"
