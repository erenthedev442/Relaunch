-- ============================================================================
-- Fellow role-specific skill lists (owner ask 2026-07-16)
-- ----------------------------------------------------------------------------
-- Every Fellow chassis is a raw Naji trust (mob_pools.name='naji',
-- skill_list_id=1012). Naji's skill list contains only three Sword WSes
-- (burning_blade 33, red_lotus_blade 34, vorpal_blade 40), so the trust's
-- autonomous AI keeps picking those regardless of the Fellow's role.
--
-- Each role now gets a tiny skill list containing its role-signature WS
-- (matches the role's defaultWs in fellow_companion.lua CONFIG.roles).
-- fellow_companion.lua's applyFellow() calls
--   pet:setMobMod(xi.mobMod.SKILL_LIST, ROLE_SKILL_LIST_IDS[role])
-- so the Fellow's autonomous AI picks from the role list, not Naji's chassis.
--
-- ID range 9800-9806 reserved for these lists (below the 10000+ range used by
-- other custom pools; well above the 1000-4000 range used by retail).
--
-- REQUIRES MAP RESTART: mob_skill_lists is cached at map-server boot. Until
-- the next restart, MOBMOD_SKILL_LIST will point at an empty list and
-- autonomous WSes will fizzle -- forced role WSes at TP cap still fire (that
-- path goes through useMobAbility which reads global mob_skills directly).
-- ============================================================================

REPLACE INTO `mob_skill_lists` VALUES ('FELLOW_Vanguard',  9800,   23);  -- DANCING_EDGE
REPLACE INTO `mob_skill_lists` VALUES ('FELLOW_Berserker', 9801,  357);  -- HEAVY_BLOW
REPLACE INTO `mob_skill_lists` VALUES ('FELLOW_Bulwark',   9802,  178);  -- EARTH_CRUSHER
REPLACE INTO `mob_skill_lists` VALUES ('FELLOW_Oracle',    9803, 2147);  -- DIVINE_JUDGMENT
REPLACE INTO `mob_skill_lists` VALUES ('FELLOW_Magus',     9804,  845);  -- FIRE_IV
REPLACE INTO `mob_skill_lists` VALUES ('FELLOW_Hunter',    9805,  413);  -- EAGLE_EYE_SHOT_HUMANOID
REPLACE INTO `mob_skill_lists` VALUES ('FELLOW_Mastered',  9806,   23);  -- DANCING_EDGE (same as Vanguard for now)
