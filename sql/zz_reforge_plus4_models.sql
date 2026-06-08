-- ---------------------------------------------------------------------------
-- zz_reforge_plus4_models.sql
--
-- The +4 reforge items were created in item_equipment with MId = 0 (no model),
-- so they equip and apply stats but render NOTHING -- the character looks naked.
-- Every +4 piece shares its visual with its lower tiers (the +1/+2/+3 of the
-- same armor), so we copy the model id from a lower-tier counterpart.
--
-- zz_ prefix + sql/ location => loads AFTER sql/item_equipment.sql (which
-- recreates the table with MId=0), so this wins. Idempotent (only touches rows
-- still at MId=0). item_equipment is read at map-server startup -> RESTART to
-- apply in-game. Reverse: delete this file + re-import sql/item_equipment.sql.
--
-- Accessories/ammo (neck, ammo, etc.) legitimately have MId=0 in every tier
-- (they don't render a body model) and are intentionally left alone.
-- ---------------------------------------------------------------------------

-- (1) Bulk: +4 inherits its +3 counterpart's model (covers ~219 pieces).
UPDATE `item_equipment` e4
    JOIN `item_basic` b4 ON b4.itemid = e4.itemId
    JOIN `item_basic` b3 ON b3.name   = REPLACE(b4.name, '+4', '+3')
    JOIN `item_equipment` e3 ON e3.itemId = b3.itemid
SET e4.MId = e3.MId
WHERE b4.name LIKE '%+4' AND e4.MId = 0 AND e3.MId <> 0;

-- (2) Orphans whose lower tiers use a different spelling (plural / French /
--     "finger gauntlets" vs "gauntlets"), so the +3 name-match above misses them.
UPDATE `item_equipment` e JOIN `item_basic` b ON b.itemid = e.itemId SET e.MId = 167 WHERE b.name = 'laksamana_tricorne_+4'        AND e.MId = 0; -- <- laksamanas_tricorne
UPDATE `item_equipment` e JOIN `item_basic` b ON b.itemid = e.itemId SET e.MId = 167 WHERE b.name = 'laksamana_frac_+4'            AND e.MId = 0; -- <- laksamanas_frac
UPDATE `item_equipment` e JOIN `item_basic` b ON b.itemid = e.itemId SET e.MId = 167 WHERE b.name = 'laksamana_bottes_+4'          AND e.MId = 0; -- <- laksamanas_bottes
UPDATE `item_equipment` e JOIN `item_basic` b ON b.itemid = e.itemId SET e.MId = 78  WHERE b.name = 'ignominy_finger_gauntlets_+4' AND e.MId = 0; -- <- ignominy_gauntlets
UPDATE `item_equipment` e JOIN `item_basic` b ON b.itemid = e.itemId SET e.MId = 338 WHERE b.name = 'runeist_boots_+4'             AND e.MId = 0; -- <- runeist_bottes
