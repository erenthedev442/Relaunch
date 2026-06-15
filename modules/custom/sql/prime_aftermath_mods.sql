-- ============================================================================
-- prime_aftermath_mods.sql  --  Wire AFTERMATH (mod 256) onto the Prime weapons
-- ----------------------------------------------------------------------------
-- Gives 10 Prime weapons their Prime Aftermath: the 9 that already grant a
-- Prime weaponskill + prime_dagger (granted one below). Faithful to retail
-- (bg-wiki.com/ffxi/Prime_Aftermath). The
-- AFTERMATH mod (256) value is the aftermath ID defined in scripts/globals/
-- aftermath.lua (xi.aftermath.effects):
--   46 = Physical Primes -> Physical Damage Limit+ (INERT on the 131,071 cap)
--   47 = Prime Club / Lorg Mor (Dagda)   -> Magic Damage + Cure potency  (WHM)
--   48 = Prime Staff / Opashoro (Oshala) -> Magic Attack Bonus + Magic Damage  (BLM)
--
-- The weapon's own Prime WS (imperator/disaster/origin/diarmuid/dragon_blow/
-- sarv/terminus/oshala/dagda) calls xi.aftermath.addStatusEffect(..., PRIME)
-- to apply it, TP-tiered (Lv.1/2/3 at 1000/2000/3000 TP).
--
-- Still omitted: prime_blade (Great Sword) & prime_pickaxe (Axe) have NO Prime
-- WS in LSB to grant; prime_horn is a wind instrument (can't weaponskill);
-- prime_shield is not a weapon. None of those four can carry aftermath here.
--
-- mod 256 = MOD_AFTERMATH. Idempotent / re-runnable. item_mods load at map
-- boot -> needs an xi_map restart to take effect.
-- ============================================================================

INSERT INTO `item_mods` (`itemid`, `modid`, `value`) VALUES
    -- Physical Primes (aftermath 46: Physical Damage Limit +6/9/12%)
    (21642, 256, 46),  -- prime_sword     (Imperator)
    (21781, 256, 46),  -- prime_great_axe (Disaster)
    (21833, 256, 46),  -- prime_scythe    (Origin)
    (21887, 256, 46),  -- prime_lance     (Diarmuid)
    (21531, 256, 46),  -- prime_fists     (Dragon Blow)
    (22155, 256, 46),  -- prime_bow       (Sarv)
    (22159, 256, 46),  -- prime_gun       (Terminus)
    -- Magic Primes
    (21999, 256, 47),  -- prime_maul/club (Dagda WS, Lorg Mor)   -> Magic Damage + Cure
    (22102, 256, 48),  -- prime_staff     (Oshala WS, Opashoro)  -> MAB + Magic Damage
    -- prime_dagger (21586, Dagger) had NO Prime WS forged onto it, unlike the 9
    -- above. Grant it the Prime Dagger WS (Merciless Strike, 232) via
    -- ADDS_WEAPONSKILL (mod 355) AND the physical aftermath (46), so it works
    -- like the rest. (Great Sword / Axe Primes have no LSB Prime WS to grant;
    -- the horn is an instrument and the shield isn't a weapon -- all omitted.)
    (21586, 355, 232), -- ADDS_WEAPONSKILL -> Merciless Strike (Prime Dagger WS)
    (21586, 256,  46)  -- AFTERMATH        -> physical Damage Limit (Prime)
ON DUPLICATE KEY UPDATE `value` = VALUES(`value`);
