-- ---------------------------------------------------------------------------
-- zz_reforge_plus12_models.sql
--
-- Same MId=0 (invisible) bug as the +3/+4 lines, for the +1 and +2 reforged
-- tiers. Copy each piece's model from a lower tier of the same armor.
-- zz_ + sql/ => loads after sql/item_equipment.sql. RESTART to apply in-game.
-- Idempotent (only touches MId=0).
-- ---------------------------------------------------------------------------

-- +2 inherits the BASE model.
UPDATE `item_equipment` e2
    JOIN `item_basic` b2 ON b2.itemid = e2.itemId
    JOIN `item_basic` b0 ON b0.name = REPLACE(b2.name, '_+2', '')
    JOIN `item_equipment` e0 ON e0.itemId = b0.itemid
SET e2.MId = e0.MId
WHERE b2.name LIKE '%+2' AND e2.MId = 0 AND e0.MId <> 0;

-- +1 inherits the BASE model.
UPDATE `item_equipment` e1
    JOIN `item_basic` b1 ON b1.itemid = e1.itemId
    JOIN `item_basic` b0 ON b0.name = REPLACE(b1.name, '_+1', '')
    JOIN `item_equipment` e0 ON e0.itemId = b0.itemid
SET e1.MId = e0.MId
WHERE b1.name LIKE '%+1' AND e1.MId = 0 AND e0.MId <> 0;

-- +2 fallback: inherit from +1.
UPDATE `item_equipment` e2
    JOIN `item_basic` b2 ON b2.itemid = e2.itemId
    JOIN `item_basic` b1 ON b1.name = REPLACE(b2.name, '+2', '+1')
    JOIN `item_equipment` e1 ON e1.itemId = b1.itemid
SET e2.MId = e1.MId
WHERE b2.name LIKE '%+2' AND e2.MId = 0 AND e1.MId <> 0;
