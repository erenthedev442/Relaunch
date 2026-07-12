-- =====================================================================
-- restore_dynamis_attestation_pops.sql
-- GUARD for the Dynamis-Beaucedine Attestation NM chain (player request:
-- Discord "Aeonic Attestation", Burtgang, 2026-07-10):
--   Hydra Corps Fomors drop 5 Fortune parchments (3359-3363, 5%) ->
--   trade to the ??? qm NPCs to force-pop the 5 Fomor NMs ->
--   each NM kill drops 1 Attestation (100%, one-of-group).
-- Attestations are the SAME items the Aeonic Weapon Forge consumes, so this
-- chain is the in-Dynamis alternate to farming Escha Geas Fete bosses.
--
-- As of 2026-07-11 the live xi_relaunch DB already had every row below
-- (verified by hand) -- players believed the pop items were scrubbed because
-- the Dynamis no-gear announcement read as "currency/materials only", and no
-- parchment has ever been looted. This file exists so the chain can never
-- silently regress: mob_droplist has NO primary key and lives outside normal
-- deploys (a deploy does not reimport sql/mob_droplist.sql), so a GM scrub or
-- partial wipe (see restore_city_dynamis_mobs.sql, 2026-06-15 incident) would
-- otherwise stick forever. dynamis_no_gear_drops.sql is safe (equipment +
-- '%-1' only -- verified it matches zero of these rows) but runs every deploy,
-- so this guard runs every deploy too, right after it alphabetically.
--
-- Idempotent: deletes EXACTLY the rows it re-inserts (scoped dropId+itemId),
-- then re-inserts stock values from sql/mob_droplist.sql. Safe to re-run.
-- Droplists are cached at map boot -- live effect needs an xi_map restart
-- (every deploy restarts, so no extra step on the normal path).
-- =====================================================================

-- ---- pop parchments: Hydra Corps Fomor trash, Rare (5%) ----
-- 3359 Despot's / 3360 Sadist's / 3361 Villain's / 3362 Deluder's /
-- 3363 Traitor's Fortune parchment
DELETE FROM `mob_droplist`
WHERE `dropId` IN (1102,1103,1104,1343,1344,1345,3143,3144,3145,3146,
                   3213,3214,3215,3216,3217,3218,3219,3220)
  AND `itemId` BETWEEN 3359 AND 3363;

INSERT INTO `mob_droplist` VALUES (1102,0,0,1000,3359,50);
INSERT INTO `mob_droplist` VALUES (1103,0,0,1000,3360,50);
INSERT INTO `mob_droplist` VALUES (1104,0,0,1000,3361,50);
INSERT INTO `mob_droplist` VALUES (1343,0,0,1000,3359,50);
INSERT INTO `mob_droplist` VALUES (1344,0,0,1000,3360,50);
INSERT INTO `mob_droplist` VALUES (1345,0,0,1000,3361,50);
INSERT INTO `mob_droplist` VALUES (3143,0,0,1000,3362,50);
INSERT INTO `mob_droplist` VALUES (3144,0,0,1000,3362,50);
INSERT INTO `mob_droplist` VALUES (3145,0,0,1000,3363,50);
INSERT INTO `mob_droplist` VALUES (3146,0,0,1000,3363,50);
INSERT INTO `mob_droplist` VALUES (3213,0,0,1000,3359,50);
INSERT INTO `mob_droplist` VALUES (3214,0,0,1000,3359,50);
INSERT INTO `mob_droplist` VALUES (3215,0,0,1000,3360,50);
INSERT INTO `mob_droplist` VALUES (3216,0,0,1000,3360,50);
INSERT INTO `mob_droplist` VALUES (3217,0,0,1000,3361,50);
INSERT INTO `mob_droplist` VALUES (3218,0,0,1000,3362,50);
INSERT INTO `mob_droplist` VALUES (3219,0,0,1000,3363,50);
INSERT INTO `mob_droplist` VALUES (3220,0,0,1000,3363,50);

-- ---- NM attestations: grouped drop, exactly one per kill ----
-- 559 Dagourmarche / 1211 Goublefaupe / 1672 Mildaunegeux /
-- 2066 Quiebitiel / 2577 Velosareon
DELETE FROM `mob_droplist`
WHERE `dropId` IN (559,1211,1672,2066,2577)
  AND `itemId` IN (1556,1557,1558,1559,1560,1561,1562,1563,1564,
                   1565,1566,1567,1568,1569,1570,1821);

INSERT INTO `mob_droplist` VALUES (559,1,1,1000,1560,333);   -- Attestation of Bravery
INSERT INTO `mob_droplist` VALUES (559,1,1,1000,1563,333);   -- Attestation of Fortitude
INSERT INTO `mob_droplist` VALUES (559,1,1,1000,1567,333);   -- Attestation of Virtue
INSERT INTO `mob_droplist` VALUES (1211,1,1,1000,1558,250);  -- Attestation of Glory
INSERT INTO `mob_droplist` VALUES (1211,1,1,1000,1559,250);  -- Attestation of Righteousness
INSERT INTO `mob_droplist` VALUES (1211,1,1,1000,1561,250);  -- Attestation of Force
INSERT INTO `mob_droplist` VALUES (1211,1,1,1000,1821,250);  -- Attestation of Invulnerability
INSERT INTO `mob_droplist` VALUES (1672,1,1,1000,1556,333);  -- Attestation of Might
INSERT INTO `mob_droplist` VALUES (1672,1,1,1000,1564,333);  -- Attestation of Legerity
INSERT INTO `mob_droplist` VALUES (1672,1,1,1000,1570,333);  -- Attestation of Accuracy
INSERT INTO `mob_droplist` VALUES (2066,1,1,1000,1557,333);  -- Attestation of Celerity
INSERT INTO `mob_droplist` VALUES (2066,1,1,1000,1566,333);  -- Attestation of Sacrifice
INSERT INTO `mob_droplist` VALUES (2066,1,1,1000,1569,333);  -- Attestation of Harmony
INSERT INTO `mob_droplist` VALUES (2577,1,1,1000,1562,333);  -- Attestation of Vigor
INSERT INTO `mob_droplist` VALUES (2577,1,1,1000,1565,333);  -- Attestation of Decisiveness
INSERT INTO `mob_droplist` VALUES (2577,1,1,1000,1568,333);  -- Attestation of Transcendence
