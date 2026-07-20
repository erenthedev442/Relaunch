-- ============================================================
-- undertuned_nm_hp.sql
--
-- HP-audit fixes (owner-approved 2026-07-19): NMs whose real in-game HP was
-- confirmed one-weapon-skill trivial by the full-pipeline HP audit
-- (exports/mob_hp_audit_final.csv -- engine formula + every runtime scaler).
-- No runtime system touches these zones, so the DB value IS the fight.
--
--   * The six elemental Prime avatars (Full Moon Fountain "Waking the
--     Beast" fights, zone 170 groups 9-14) sat at 5,000 HP -- the avatar
--     unlock fight ended in one WS. Raised to 90,000 (the Lv90-99 NM
--     median from the audit). Carbuncle Prime (20,000) and Fenrir Prime
--     (12,500) were NOT flagged and are left alone.
--   * Olla Grande (The Shrine of Ru'Avitau, zone 178 group 26) sat at
--     5,300. Same raise.
--
-- ACTIVATION: mob_groups.HP is loaded into HPmodifier at map boot
-- (mobutils LoadMobList) -- takes effect at the next restart/deploy.
-- Idempotent (plain UPDATEs).
-- ============================================================

-- Full Moon Fountain -- elemental Prime avatars (Lv85) 5,000 -> 90,000
UPDATE `mob_groups` SET `HP` = 90000 WHERE `zoneid` = 170 AND `groupid` =  9;  -- Ifrit Prime
UPDATE `mob_groups` SET `HP` = 90000 WHERE `zoneid` = 170 AND `groupid` = 10;  -- Shiva Prime
UPDATE `mob_groups` SET `HP` = 90000 WHERE `zoneid` = 170 AND `groupid` = 11;  -- Garuda Prime
UPDATE `mob_groups` SET `HP` = 90000 WHERE `zoneid` = 170 AND `groupid` = 12;  -- Titan Prime
UPDATE `mob_groups` SET `HP` = 90000 WHERE `zoneid` = 170 AND `groupid` = 13;  -- Ramuh Prime
UPDATE `mob_groups` SET `HP` = 90000 WHERE `zoneid` = 170 AND `groupid` = 14;  -- Leviathan Prime

-- The Shrine of Ru'Avitau -- Olla Grande (Lv85) 5,300 -> 90,000
UPDATE `mob_groups` SET `HP` = 90000 WHERE `zoneid` = 178 AND `groupid` = 26;  -- Olla Grande
