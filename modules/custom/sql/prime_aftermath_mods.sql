-- ============================================================================
-- prime_aftermath_mods.sql  --  Wire AFTERMATH (mod 256) onto the Prime weapons
-- ----------------------------------------------------------------------------
-- Gives the 9 Prime weapons that grant a Prime weaponskill their Prime
-- Aftermath, faithful to retail (bg-wiki.com/ffxi/Prime_Aftermath). The
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
-- The remaining Prime items (dagger/blade/pickaxe/horn/shield) grant NO Prime
-- weaponskill, so they cannot carry WS-triggered aftermath -- intentionally
-- omitted here (a separate gap in how those were forged).
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
    (22102, 256, 48)   -- prime_staff     (Oshala WS, Opashoro)  -> MAB + Magic Damage
ON DUPLICATE KEY UPDATE `value` = VALUES(`value`);
