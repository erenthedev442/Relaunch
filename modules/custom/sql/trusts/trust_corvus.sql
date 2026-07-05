-- =====================================================================
-- trust_corvus.sql
-- Makes "Trust: Corvus, the Black Arrow" load + appear in the Trust menu by
-- REPURPOSING the retail Curilla trust slot (spell 902) -- the same technique
-- Gemma uses on Nanaa Mihgo (901) and Meat on Excenmille (899).
--
-- WHY REPURPOSE 902 (Curilla)
--   The Trust MENU label is drawn from the CLIENT's spell table by spell ID.
--   902 ("Curilla") already has a client name, so the entry is always visible
--   and selectable. Curilla is a stock San d'Oria Trust nobody runs at endgame,
--   so the slot costs nothing -- and the Void Keeper grants spell 902 on
--   purchase. Net: the Trust menu shows "Curilla", but casting it summons
--   CORVUS -- a ranged damage dealer who shoots from the back line.
--
--   COLLISION NOTE (handled elsewhere): 902 is a REAL retail trust with a free
--   grant path (Chateau d'Oraguille / Curilla NPC, csid 573). Like Meat (899),
--   that free grant is blocked by modules/custom/lua/block_curilla_retail_grant.lua
--   and 902 is excluded from every bulk grant in Character_Upgrader.lua. Without
--   both, Corvus would leak for free. (Gemma/901 had no retail NPC, so it only
--   needed the bulk-grant exclusion.)
--
-- HOW THE TRUST LOADS (trustutils::LoadTrustList -> BuildTrustData)
--   INNER-JOINs spell_list x mob_pools (poolid = spellid + 5000) x
--   mob_family_system (by speciesid) x mob_resistances (by resist_id) at boot.
--   We overwrite the two rows that define slot 902:
--     - spell_list.spellid 902 -> name 'corvus' so it binds to
--                                 scripts/actions/spells/trust/corvus.lua
--                                 (the stock curilla.lua goes unreferenced --
--                                 harmless, exactly like nanaa_mihgo.lua).
--     - mob_pools.poolid   5902 (= 902 + 5000) -> RNG/SAM, ranged-DD combat
--                                 stats, a Hume look, name 'Corvus'.
--   speciesid 246 (Fenrir Prime) + resist_id 153 are reused from Gemma -- both
--   already exist in mob_family_system / mob_resistances. With a size=1
--   equipment look_t the RACE byte (not the species) drives the visible model.
--
--   spellList 0: Corvus casts NOTHING (he is a pure physical ranged DD), so the
--   "spellList must be non-empty or gambits drop" trap that bit Gemma does NOT
--   apply -- his gambits are RATTACK / weaponskills, which are not spell-gated.
--   No mob_spell_lists rows are needed.
--
-- APPLYING
--   1) sudo mariadb xidb < modules/custom/sql/trust_corvus.sql
--   2) RESTART THE MAP SERVER (LoadTrustList runs only at boot).
--
-- Re-runnable: REPLACE INTO keys on the primary keys (spellid / poolid).
-- =====================================================================

-- ---- 1. Overwrite spell slot 902 (Curilla -> Corvus) -----------------
--   group 8 = SPELLGROUP_TRUST, validTargets 1 = self, animation 939 =
--   generic trust-call. name 'corvus' binds it to trust/corvus.lua.
REPLACE INTO spell_list
    (spellid, name,     jobs, `group`, family, element, zonemisc, validTargets,
     skill, mpCost, castTime, recastTime, message, magicBurstMessage,
     animation, animationTime, AOE, base, multiplier, CE, VE,
     requirements, spell_range, radius, content_tag)
VALUES
    (902, 'corvus', '', 8, 0, 7, 0, 1,
     0, 0, 2000, 240000, 0, 0,
     939, 1500, 0, 0, 1.00, 0, 0,
     0, 0, 0, NULL);

-- ---- 2. TP skill list for Corvus (Jishnu's Radiance, player WS 202) ------
--   trustutils::LoadTrustStatsAndSkills reads mob_skill_lists via
--   battleutils::GetMobSkillList(PTrust->m_MobSkillList) where m_MobSkillList
--   comes from mob_pools.skill_list_id.  mob_skill_id <= 255 is treated as a
--   player weaponskill ID (not a mob skill), so 202 = Jishnu's Radiance.
--   setTrustTPSkillSettings in corvus.lua then fires it via TryTrustSkill().
REPLACE INTO mob_skill_lists (skill_list_name, skill_list_id, mob_skill_id)
VALUES ('corvus_jishnu', 5902, 202);

-- ---- 3. Overwrite mob pool 5902 (= 902 + 5000) with Corvus ------------
--   look_t (size=1 MODEL_EQUIPPED): byte order = size(u16 LE=1), face(u8),
--   race(u8), then head/body/hands/legs/feet/main/sub/ranged (u16 LE, raw
--   item_equipment.MId, NO slot offset).
--   *** LOOK: Galka Male (race 05, face 02), full Taeon set (MId 326 = 0x0146 LE
--   -> bytes 0x46,0x01), Fail-not bow (MId 133 = 0x85 -> bytes 0x85,0x00).
--   Taeon is dark leather ranger armour; Fail-not is the legendary "never-miss"
--   bow -- fits the Black Arrow lore perfectly.
--   TWEAKS: face byte (3rd) = 0x00-0x07 for different Galka heads. BOW SWAP:
--   change last 2 bytes (ranged LE), e.g. Gandiva 0x62 00, Fomalhaut 0x86 00.
--   ARMOR SWAP: set the 5 head/body/hands/legs/feet u16 pairs to any MId.
--
--   mJob 11 / sJob 12 = RNG / SAM.  skill_list_id 5902 -> mob_skill_lists row
--   above -> WS 202 fed into TryTrustSkill (set in corvus.lua via
--   setTrustTPSkillSettings).  spellList 0 = no magic spells.
REPLACE INTO mob_pools
    (poolid, name,     packet_name, speciesid, modelid,
     mJob, sJob, cmbSkill, cmbDelay, cmbDmgMult,
     behavior, aggro, true_detection, links, mobType, immunity,
     name_prefix, flag, entityFlags, animationsub, hasSpellScript,
     spellList, namevis, roamflag, skill_list_id, resist_id,
     modelSize, modelHitboxSize)
VALUES
    (5902, 'corvus', 'Corvus', 246, UNHEX('0100020546014601460146014601000000008500'),
     17, 11, 25, 240, 250,
     0, 0, 0, 0, 0, 0,
     32, 0, 3, 0, 0,
     0, 0, 0, 5902, 153,
     1, 12);
