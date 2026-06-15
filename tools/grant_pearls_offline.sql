-- grant_pearls_offline.sql
-- Inserts a Legendary linkpearl into the inventory of every OFFLINE
-- character that does not already own one (itemId 514 pearlsack or
-- 515 linkpearl) and has at least one free inventory slot.
--
-- Run this on the Azure box AFTER running !grantpearls in-game (which
-- covers online players via the live Lua API):
--
--   sudo mysql xidb < ~/server/tools/grant_pearls_offline.sql
--
-- Safe to re-run: the NOT EXISTS guards prevent duplicates.
-- Chars with a full bag (slot 79 already taken) are skipped silently.
-- ---------------------------------------------------------------

INSERT INTO char_inventory
    (charid, location, slot, itemId, quantity, bazaar, signature, extra)
SELECT
    t.charid,
    0              AS location,
    t.next_slot    AS slot,
    515            AS itemId,
    1              AS quantity,
    0              AS bazaar,
    'Legendary'    AS signature,
    0x01000000000000F0039851C538405267F000000000000000 AS extra
FROM (
    SELECT
        c.charid,
        COALESCE(
            (SELECT MAX(m.slot) + 1
             FROM char_inventory m
             WHERE m.charid = c.charid AND m.location = 0),
            0
        ) AS next_slot
    FROM chars c
    WHERE
        -- offline only
        NOT EXISTS (
            SELECT 1 FROM accounts_sessions s WHERE s.charid = c.charid
        )
        -- no pearl or sack of any kind
        AND NOT EXISTS (
            SELECT 1 FROM char_inventory ci
            WHERE ci.charid = c.charid AND ci.itemId IN (514, 515)
        )
) t
-- skip anyone whose bag is full (START_INVENTORY = 80, slots 0-79)
WHERE t.next_slot < 80;

SELECT ROW_COUNT() AS pearls_inserted;
