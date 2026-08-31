-- =====================================================================
-- hydra_corps_beaucedine_currency.sql
-- Dynamis-Beaucedine Hydra Corps NMs (zone 134). Attestations stay
-- stripped (see strip_dynamis_attestation_drops.sql). These five lists
-- were empty after that, which logged LoadMOBList errors and felt blank.
--
-- Two independent grouped rolls per kill, each a random 100-piece:
--   Group 1: 50%  Lungo-Nango Jadeshell / Montiont Silverpiece / 100 Byne
--   Group 2: 20%  same three, so a lucky kill can pay two 100-pieces.
--
-- Idempotent. Droplists are cached at boot -- restart xi_map after apply.
-- =====================================================================

-- 559 Dagourmarche / 1211 Goublefaupe / 1672 Mildaunegeux /
-- 2066 Quiebitiel / 2577 Velosareon
-- 1450 Jadeshell / 1453 Silverpiece / 1456 One Hundred Byne Bill
DELETE FROM `mob_droplist`
WHERE `dropId` IN (559, 1211, 1672, 2066, 2577)
  AND `itemId` IN (1450, 1453, 1456);

-- dropType 1 = grouped. groupRate is per-1000. itemRate is weight inside
-- the group (334+333+333 = 1000) so each 100-piece is equally likely.
INSERT INTO `mob_droplist` (`dropId`, `dropType`, `groupId`, `groupRate`, `itemId`, `itemRate`) VALUES
    -- Dagourmarche
    (559,  1, 1, 500, 1450, 334),
    (559,  1, 1, 500, 1453, 333),
    (559,  1, 1, 500, 1456, 333),
    (559,  1, 2, 200, 1450, 334),
    (559,  1, 2, 200, 1453, 333),
    (559,  1, 2, 200, 1456, 333),
    -- Goublefaupe
    (1211, 1, 1, 500, 1450, 334),
    (1211, 1, 1, 500, 1453, 333),
    (1211, 1, 1, 500, 1456, 333),
    (1211, 1, 2, 200, 1450, 334),
    (1211, 1, 2, 200, 1453, 333),
    (1211, 1, 2, 200, 1456, 333),
    -- Mildaunegeux
    (1672, 1, 1, 500, 1450, 334),
    (1672, 1, 1, 500, 1453, 333),
    (1672, 1, 1, 500, 1456, 333),
    (1672, 1, 2, 200, 1450, 334),
    (1672, 1, 2, 200, 1453, 333),
    (1672, 1, 2, 200, 1456, 333),
    -- Quiebitiel
    (2066, 1, 1, 500, 1450, 334),
    (2066, 1, 1, 500, 1453, 333),
    (2066, 1, 1, 500, 1456, 333),
    (2066, 1, 2, 200, 1450, 334),
    (2066, 1, 2, 200, 1453, 333),
    (2066, 1, 2, 200, 1456, 333),
    -- Velosareon
    (2577, 1, 1, 500, 1450, 334),
    (2577, 1, 1, 500, 1453, 333),
    (2577, 1, 1, 500, 1456, 333),
    (2577, 1, 2, 200, 1450, 334),
    (2577, 1, 2, 200, 1453, 333),
    (2577, 1, 2, 200, 1456, 333);
