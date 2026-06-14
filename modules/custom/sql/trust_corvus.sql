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

-- ---- 2. Overwrite mob pool 5902 (= 902 + 5000) with Corvus ------------
--   look_t (size=1 MODEL_EQUIPPED): byte order = size(u16 LE=1), face(u8),
--   race(u8), then head/body/hands/legs/feet/main/sub/ranged (u16 LE, raw
--   item_equipment.MId, NO slot offset). Race 01 = Hume Male.
--   *** LOOK: the Orion set -- RNG relic, a dark hooded marksman (fits "the Black
--   Arrow") ***: race 03 (Elvaan Male), face 0x04, the FULL Orion relic set in every
--   armor slot (head/body/hands/legs/feet all MId 84 -- a relic set shares one model
--   number across its slots), no melee weapon, and Gandiva (empyrean bow, MId 98) in
--   the `ranged` slot. Values are raw item_equipment.MId.
--   TWEAKS: the `face` byte (3rd byte of the UNHEX, 0x04) picks the Elvaan face + hair
--   (0x00-0x07). BOW SWAP: change the last 2 bytes (ranged) -- e.g. Gandiva 0x62(98),
--   Perdu Bow 0x28(40), or a plain Longbow 0x25(37). ARMOR SWAP: set the head..feet
--   pairs to any item_equipment.MId for a different outfit (all 5 = one MId for a set).
--
--   mJob 11 / sJob 12 = RNG / SAM. RNG main = the ranged-DD identity; SAM sub
--   grants Store TP for faster weaponskills (trustutils computes sub-job skill
--   at the master's full level). cmbDmgMult 250 makes each shot/hit hurt;
--   cmbDelay 240 = standard. skill_list_id 0 (no native mob TP moves) +
--   spellList 0 (no spells) -- his damage is RATTACK + weaponskills, configured
--   in corvus.lua. packet_name 'Corvus' shows over his head + in the party list
--   (corvus.lua also renameEntity's it for the equipped-look name path).
REPLACE INTO mob_pools
    (poolid, name,     packet_name, speciesid, modelid,
     mJob, sJob, cmbSkill, cmbDelay, cmbDmgMult,
     behavior, aggro, true_detection, links, mobType, immunity,
     name_prefix, flag, entityFlags, animationsub, hasSpellScript,
     spellList, namevis, roamflag, skill_list_id, resist_id,
     modelSize, modelHitboxSize)
VALUES
    (5902, 'corvus', 'Corvus', 246, UNHEX('0100040354005400540054005400000000006200'),
     11, 12, 0, 240, 250,
     0, 0, 0, 0, 0, 0,
     32, 0, 3, 0, 0,
     0, 0, 0, 0, 153,
     1, 12);
