-- ---------------------------------------------------------------------------
-- zz_reforge_plus3_models.sql
--
-- Same bug as the +4 line: the +3 reforge items were created with MId = 0
-- (no model) -> they render nothing (naked) when worn. Copy each +3 piece's
-- model from a lower tier of the same armor (base / +2 / +1; the model is
-- identical across tiers). Cascade + idempotent (only touches MId=0).
--
-- zz_ + sql/ => loads after sql/item_equipment.sql. RESTART to apply in-game.
-- Accessories/ammo legitimately have MId=0 in every tier and are left alone.
-- ---------------------------------------------------------------------------

-- (1) +3 inherits the BASE item's model (name with '_+3' removed).
UPDATE `item_equipment` e3
    JOIN `item_basic` b3 ON b3.itemid = e3.itemId
    JOIN `item_basic` b0 ON b0.name = REPLACE(b3.name, '_+3', '')
    JOIN `item_equipment` e0 ON e0.itemId = b0.itemid
SET e3.MId = e0.MId
WHERE b3.name LIKE '%+3' AND e3.MId = 0 AND e0.MId <> 0;

-- (2) Remaining: inherit from the +2 counterpart.
UPDATE `item_equipment` e3
    JOIN `item_basic` b3 ON b3.itemid = e3.itemId
    JOIN `item_basic` b2 ON b2.name = REPLACE(b3.name, '+3', '+2')
    JOIN `item_equipment` e2 ON e2.itemId = b2.itemid
SET e3.MId = e2.MId
WHERE b3.name LIKE '%+3' AND e3.MId = 0 AND e2.MId <> 0;

-- (3) Remaining: inherit from the +1 counterpart.
UPDATE `item_equipment` e3
    JOIN `item_basic` b3 ON b3.itemid = e3.itemId
    JOIN `item_basic` b1 ON b1.name = REPLACE(b3.name, '+3', '+1')
    JOIN `item_equipment` e1 ON e1.itemId = b1.itemid
SET e3.MId = e1.MId
WHERE b3.name LIKE '%+3' AND e3.MId = 0 AND e1.MId <> 0;

-- (4) Orphan: pluralised name ('flanchards' vs base 'flanchard').
UPDATE `item_equipment` e JOIN `item_basic` b ON b.itemid = e.itemId SET e.MId = 289 WHERE b.name = 'heathens_flanchards_+3' AND e.MId = 0; -- <- heathens_flanchard
