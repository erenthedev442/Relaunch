-- ============================================================================
-- reforge_catalog_finder.sql
--
-- Helper queries to enumerate reforged-armor item IDs for the Reforge Armor
-- system catalog (modules/custom/lua/reforge_catalog.lua).
--
-- Reforged item name patterns (LandSandBoat / FFXI):
--   <set>_<piece>            base
--   <set>_<piece>_+1
--   <set>_<piece>_+2
--   <set>_<piece>_+3
--
-- Set names per job vary. Examples:
--   RDM:  warlock's (AF) / vitiation (Relic) / lethargic (Empyrean)
--   BLM:  sorcerer's (AF) / archmage's (Relic) / spaekona's (Empyrean)
--   WAR:  warrior's (AF) / agoge (Relic) / boii (Empyrean)
--
-- See https://www.bg-wiki.com/ffxi/Reforged_Artifact_Armor for the full list.
-- ============================================================================


-- ----------------------------------------------------------------------------
-- Query 1: All four tiers of a known reforged set
--   Edit @set_root and you get 5 rows (one per slot) × 4 tiers.
-- ----------------------------------------------------------------------------
SET @set_root := 'warlock''s';   -- e.g. 'warlock''s' for RDM AF
                                 --      'vitiation'  for RDM Relic
                                 --      'lethargic'  for RDM Empyrean

SELECT
    itemid,
    name,
    CASE
        WHEN name LIKE '%\_+1' ESCAPE '\\' THEN '+1'
        WHEN name LIKE '%\_+2' ESCAPE '\\' THEN '+2'
        WHEN name LIKE '%\_+3' ESCAPE '\\' THEN '+3'
        ELSE 'base'
    END AS tier
FROM      item_basic
WHERE     name LIKE CONCAT(@set_root, '\_%')   ESCAPE '\\'
   OR     name LIKE CONCAT(REPLACE(@set_root, '''', ''), '\_%') ESCAPE '\\'
ORDER BY  name;


-- ----------------------------------------------------------------------------
-- Query 2: All reforged armor that a single JOB can equip
--   Pulls anything in item_equipment matching the job bit, with the +N tier.
-- ----------------------------------------------------------------------------
SET @job_bit := 16;  -- 16 = RDM. WAR=1, MNK=2, WHM=4, BLM=8, RDM=16, THF=32,
                     -- PLD=64, DRK=128, BST=256, BRD=512, RNG=1024,
                     -- SAM=2048, NIN=4096, DRG=8192, SMN=16384, BLU=32768,
                     -- COR=65536, PUP=131072, DNC=262144, SCH=524288,
                     -- GEO=1048576, RUN=2097152

SELECT
    e.itemId,
    e.name,
    e.level                                    AS lv,
    e.ilevel                                   AS ilv,
    e.slot,
    CASE e.slot
        WHEN  16 THEN 'head'
        WHEN  32 THEN 'body'
        WHEN  64 THEN 'hands'
        WHEN 128 THEN 'legs'
        WHEN 256 THEN 'feet'
        ELSE          CAST(e.slot AS CHAR)
    END                                        AS slot_label,
    CASE
        WHEN e.name LIKE '%\_+1' ESCAPE '\\' THEN '+1'
        WHEN e.name LIKE '%\_+2' ESCAPE '\\' THEN '+2'
        WHEN e.name LIKE '%\_+3' ESCAPE '\\' THEN '+3'
        ELSE                                       'base'
    END                                        AS tier
FROM      item_equipment e
WHERE     (e.jobs & @job_bit) > 0
      AND e.slot IN (16, 32, 64, 128, 256)     -- Head/Body/Hands/Legs/Feet
      AND (e.ilevel >= 109                     -- Reforged sits at ilv 109+
           OR e.name LIKE '%\_+%' ESCAPE '\\') -- or has a +N suffix
ORDER BY  e.name, tier;


-- ----------------------------------------------------------------------------
-- Query 3: Lua-ready output for ONE set (paste directly into catalog.pieces)
--   Edit @set_root to AF/Relic/Empy name root. Outputs four item IDs per slot
--   formatted as { base, +1, +2, +3 } so you can paste each row into the
--   matching catalog.pieces[jobId][setKey][slot] entry.
-- ----------------------------------------------------------------------------
SET @set_root := 'warlock''s';

WITH tiered AS (
    SELECT
        b.itemid,
        b.name,
        e.slot,
        CASE
            WHEN b.name LIKE '%\_+3' ESCAPE '\\' THEN 4
            WHEN b.name LIKE '%\_+2' ESCAPE '\\' THEN 3
            WHEN b.name LIKE '%\_+1' ESCAPE '\\' THEN 2
            ELSE                                      1
        END AS tier_order
    FROM      item_basic     b
    JOIN      item_equipment e ON e.itemId = b.itemid
    WHERE     (b.name LIKE CONCAT(@set_root, '\_%') ESCAPE '\\'
            OR b.name LIKE CONCAT(REPLACE(@set_root, '''', ''), '\_%') ESCAPE '\\')
          AND e.slot IN (16, 32, 64, 128, 256)
)
SELECT
    CASE slot
        WHEN  16 THEN 'head'
        WHEN  32 THEN 'body'
        WHEN  64 THEN 'hands'
        WHEN 128 THEN 'legs'
        WHEN 256 THEN 'feet'
    END                                                       AS slot_label,
    CONCAT(
        '{ ',
        MAX(CASE WHEN tier_order = 1 THEN itemid ELSE NULL END), ', ',
        MAX(CASE WHEN tier_order = 2 THEN itemid ELSE NULL END), ', ',
        MAX(CASE WHEN tier_order = 3 THEN itemid ELSE NULL END), ', ',
        MAX(CASE WHEN tier_order = 4 THEN itemid ELSE NULL END),
        ' },  -- ', MAX(CASE WHEN tier_order = 1 THEN name ELSE NULL END)
    )                                                         AS lua_row
FROM      tiered
GROUP BY  slot
ORDER BY  FIELD(slot, 16, 32, 64, 128, 256);


-- ============================================================================
-- WORKFLOW
-- ----------------------------------------------------------------------------
-- 1. For each job × set combo, set @set_root to the set's name root
--    (e.g. 'warlock''s', 'vitiation', 'lethargic') and run Query 3.
-- 2. Copy each `lua_row` value into the matching slot in
--    modules/custom/lua/reforge_catalog.lua under
--    catalog.pieces[xi.job.JOB][setKey][slot].
-- 3. If the +1/+2/+3 IDs are NULL for some tiers, that piece doesn't exist
--    yet in your item_basic.sql.  Either leave the slot at zero (the system
--    ignores zero IDs) or import the reforged item rows from upstream LSB.
-- ============================================================================
