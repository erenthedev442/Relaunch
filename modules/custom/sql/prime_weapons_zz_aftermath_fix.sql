-- ============================================================================
-- prime_weapons_zz_aftermath_fix.sql
--
-- FIX: "Feonaria Aftermath not working" (+ every other Prime weapon's aftermath).
--
-- ROOT CAUSE: prime_weapons_gear.sql does `DELETE FROM item_mods ... ; INSERT ...`
-- for each Prime weapon but the INSERT omits the AFTERMATH mod (256). It sorts
-- AFTER prime_aftermath_mods.sql (which DID set 256), so the gear file's DELETE
-- WIPES the aftermath -> no Prime weapon actually carries mod 256 ->
-- xi.aftermath.addStatusEffect(..., PRIME) reads weapon:getMod(AFTERMATH)=0 and
-- applies nothing (verified live: foenaria 21837 had 355=110 but no 256).
--
-- This file's name sorts AFTER prime_weapons_gear.sql, so its mods land on TOP of
-- the gear re-insert and survive. Re-applies AFTERMATH (256) to all 9 Prime-WS
-- weapons whose WS script calls addStatusEffect(PRIME) -- the set listed in
-- prime_aftermath_mods.sql: imperator/disaster/origin/diarmuid/dragon_blow/
-- sarv/terminus (physical, aftermath 46), dagda (club, 47), oshala (staff, 48) --
-- across BOTH their base prime_* item and their Prime-Vendor "III" form. ALSO
-- grants Origin (355=110) to the foenaria upgrade stages 21834-21836, which the
-- gear file never wired (only 21833 + 21837 had it).
--
-- Aftermath ids (scripts/globals/aftermath.lua): 46 = Physical Damage Limit,
-- 47 = Magic Dmg + Cure (Lorg Mor/Dagda), 48 = MAB + Magic Dmg (Opashoro/Oshala).
--
-- Idempotent (ON DUPLICATE KEY UPDATE). item_mods load at map boot -> RESTART
-- xi_map to apply. NOT a one-time migration -- safe to re-run every deploy.
-- ============================================================================
INSERT INTO `item_mods` (`itemId`, `modId`, `value`) VALUES
    -- ----- Scythe / Foenaria -> Origin (the reported bug) ------------------
    -- grant Origin to the upgrade stages that lacked ADDS_WEAPONSKILL
    (21834, 355, 110), (21835, 355, 110), (21836, 355, 110),
    -- physical Prime Aftermath (46) on the base Prime Scythe + all 4 Foenaria
    (21833, 256, 46), (21834, 256, 46), (21835, 256, 46), (21836, 256, 46), (21837, 256, 46),
    -- ----- the other physical Prime-WS weapons (aftermath 46) --------------
    (21531, 256, 46),                    -- Prime Fists      (Dragon Blow)
    (21642, 256, 46), (21646, 256, 46),  -- Prime Sword / Caliburnus (Imperator)
    (21781, 256, 46), (21785, 256, 46),  -- Prime Great Axe / Laphria (Disaster)
    (21887, 256, 46), (21891, 256, 46),  -- Prime Lance / Gae Buide (Diarmuid)
    (22155, 256, 46), (22163, 256, 46),  -- Prime Bow / Pinaka (Sarv)
    (22159, 256, 46), (22164, 256, 46),  -- Prime Gun / Earp (Terminus)
    -- ----- Club (Dagda) -> aftermath 47 -----------------------------------
    (21999, 256, 47), (22002, 256, 47),  -- Prime Maul / Lorg Mor
    -- ----- Staff (Oshala) -> aftermath 48 ---------------------------------
    (22102, 256, 48), (22106, 256, 48)   -- Prime Staff / Opashoro
ON DUPLICATE KEY UPDATE `value` = VALUES(`value`);
