-- =====================================================================
-- trust_meat.sql  --  "Meat, the Immovable"  (the ULTIMATE TANK trust)
--
-- Repurposes a weak stock trust slot -- Excenmille (spell 899) -- into a
-- custom, UNKILLABLE tank trust named "Meat", mirroring how trust_skoll.sql
-- repurposed Nanaa Mihgo (901).
--
--   * Trust MENU shows "Excenmille" client-side (it has a client name, so the
--     entry is always visible/selectable). Casting it summons "Meat" -- a
--     tiny Tarutaru (Koru-Moru trust model) named "Meat" over its head + in the
--     party list (packet_name).
--   * Both existing characters already own spell 899, so Meat is available
--     IMMEDIATELY after the map-server restart -- no vendor / unlock needed.
--   * Behaviour lives in scripts/actions/spells/trust/meat.lua, bound by
--     spell_list.name = 'meat'. The stock excenmille.lua goes unreferenced.
--
-- Job: main PLD (7) / sub WAR (1) -> Provoke (WAR) + Flash / Sentinel / Rampart
-- / Cover (PLD), the full enmity-tank kit. Minimal DPS by design: cmbDmgMult 10
-- and skill_list_id 0 (no native TP moves) -- it swings only to build hate.
--
-- HOW THE TRUST LOADS (trustutils::LoadTrustList): INNER-JOINs spell_list x
-- mob_pools (poolid = spellid + 5000) x mob_family_system (speciesid) x
-- mob_resistances (resist_id). speciesID 255 (kept for stats; look set via modelid below) + resist_id 153 are
-- already present, so we only overwrite the three rows that define slot 899.
--
-- APPLYING:
--   1) "C:\Program Files\MariaDB 10.6\bin\mysql.exe" -u root -pwarrior3 xidb < modules/custom/sql/trust_meat.sql
--   2) RESTART THE MAP SERVER (LoadTrustList / LoadSpellList run only at boot).
--
-- Re-runnable: REPLACE INTO keys on the primary keys; the spell-list section
-- DELETEs slot 899 first so no stock Excenmille spells leak into Meat.
-- =====================================================================

-- ---- 1. Overwrite spell slot 899 (Excenmille -> Meat) ----------------
--   group 8 = SPELLGROUP_TRUST, validTargets 1 = self-cast, animation 939 =
--   generic trust-call. name 'meat' binds it to trust/meat.lua.
REPLACE INTO spell_list
    (spellid, name,   jobs, `group`, family, element, zonemisc, validTargets,
     skill, mpCost, castTime, recastTime, message, magicBurstMessage,
     animation, animationTime, AOE, base, multiplier, CE, VE,
     requirements, spell_range, radius, content_tag)
VALUES
    (899, 'meat', '', 8, 0, 7, 0, 1,
     0, 0, 2000, 240000, 0, 0,
     939, 1500, 0, 0, 1.00, 0, 0,
     0, 0, 0, NULL);

-- ---- 2. Overwrite mob pool 5899 (= 899 + 5000) with a Hume Male knight -
--   speciesid 255 (kept for stats/family). modelid is now a size=1 EQUIPMENT
--   look (look_t): Hume Male (race 1) in Terminal Helm + Terminal Plate + Thick
--   Mufflers + Envy Flanchard + Envy Sollerets, wielding Helheim (greatsword).
--   Each look_t slot is the item's RAW MId (head/body 409, hands 58, legs 16877,
--   feet 20973, main 546) -- field position sets the slot, NO offset (charutils
--   EquipItem). NOTE: the sub shield (Duban) has model 0 in item_equipment
--   (flagged "not implemented"), so no shield renders -- with a 2-handed
--   greatsword it is hidden anyway. The face byte (0x01) is a placeholder: the
--   Terminal Helm hides the head, and the "Hume Male Fomor" NPC face is not a
--   standard 0-15 id. mJob 7 / sJob 1 = PLD / WAR. cmbDmgMult 10 = MINIMAL melee
--   damage (swings only to feed cumulative enmity, never DPS). skill_list_id 0 =
--   no native mob TP moves. spellList 899 -> the gambit spell pool (section 3).
--   Trust flags name_prefix 32 / entityFlags 3 from Skoll. resist_id 153 exists.
--   modelSize / modelHitboxSize are collision only -- tune in-game if it clips.
REPLACE INTO mob_pools
    (poolid, name,   packet_name, speciesid, modelid,
     mJob, sJob, cmbSkill, cmbDelay, cmbDmgMult,
     behavior, aggro, true_detection, links, mobType, immunity,
     name_prefix, flag, entityFlags, animationsub, hasSpellScript,
     spellList, namevis, roamflag, skill_list_id, resist_id,
     modelSize, modelHitboxSize)
VALUES
    (5899, 'meat', 'Meat', 255, UNHEX('0100010159115821003058410350B46000700000'), -- FJB: valid Hume Male knight look. Prior blob's gear words were missing their slot-marker nibbles (head 0x1n / body 0x2n / ...), so the client dropped the spawn -> blank name + no model.
     7, 1, 0, 240, 10,
     0, 0, 0, 0, 0, 0,
     32, 0, 3, 0, 0,
     899, 0, 0, 0, 153,
     1, 15);

-- ---- 3. Meat's gambit spell list (spell_list_id 899) -----------------
--   DELETE first so no stock Excenmille spells survive, then INSERT only Meat's.
--   JAs (Provoke, Sentinel, Rampart, Cover) are NOT spell-list gated -> no rows.
--   min_level 1 / max_level 255 => always castable (trust spawns at master lvl).
DELETE FROM mob_spell_lists WHERE spell_list_id = 899;
INSERT INTO mob_spell_lists
    (spell_list_name, spell_list_id, spell_id, min_level, max_level)
VALUES
    ('meat', 899, 112, 1, 255),   -- Flash      (enmity + accuracy down)
    ('meat', 899, 106, 1, 255),   -- Phalanx    (flat physical damage cut)
    ('meat', 899,  47, 1, 255),   -- Protect V  (self DEF)
    ('meat', 899,  97, 1, 255),   -- Reprisal   (block -> spike + damage cut)
    ('meat', 899,   4, 1, 255);   -- Cure IV    (backup self-heal; rarely needed)

-- =====================================================================
-- REVERSE (manual rollback -- restores the stock Excenmille trust):
--   Re-import the canonical rows from sql/spell_list.sql, sql/mob_pools.sql,
--   and sql/mob_spell_lists.sql for id 899 / pool 5899 (or restore from a
--   backup), then remove scripts/actions/spells/trust/meat.lua.
-- =====================================================================
