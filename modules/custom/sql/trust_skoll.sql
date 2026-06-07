-- =====================================================================
-- trust_skoll.sql
-- Makes "Trust: Skoll, the Voidhound" load + appear in the Trust menu by
-- REPURPOSING a weak stock trust slot: Nanaa Mihgo (spell 901).
--
-- WHY REPURPOSE 901 INSTEAD OF USING SPELL 1000
--   The Void Keeper grants the spell via addSpell(), but the Trust MENU
--   label is drawn from the CLIENT's spell table by spell ID, not from
--   our server. Spell 1000 has NO client name (verified against the
--   client spell resource) -> it would render as a blank, easy-to-miss
--   menu entry, and some clients hide unnamed spells outright. Spell 901
--   ("Nanaa Mihgo") already HAS a client name, so the entry is always
--   visible and selectable. Nanaa Mihgo is a bottom-tier trust nobody
--   runs, so repurposing the slot costs nothing -- and on this server
--   both characters already own every trust anyway.
--
--   Net effect: the Trust menu shows "Nanaa Mihgo", but casting it
--   summons Gemma -- a Hume Female with club + shield in a swimsuit-style
--   outfit, named "Gemma" over her head and in the party list.
--
-- HOW THE TRUST LOADS (trustutils::LoadTrustList -> BuildTrustData)
--   INNER-JOINs FOUR tables at boot:
--       spell_list  x  mob_pools          (poolid = spellid + 5000)
--                   x  mob_family_system   (by speciesid)
--                   x  mob_resistances     (by resist_id)
--   We overwrite the two rows that define slot 901 and add Skoll's gambit
--   spell list:
--     - spell_list.spellid = 901   -> name 'skoll' so it binds to
--                                     scripts/actions/spells/trust/skoll.lua
--     - mob_pools.poolid   = 5901  (= 901 + 5000) -> Fenrir Prime look,
--                                     spellList 901 -> Skoll's castable kit
--     - mob_spell_lists (spell_list_id 901) -> the spells the gambits in
--                                     skoll.lua cast (section 3; required,
--                                     or every gambit is dropped at load)
--   Already present (no change): mob_family_system.speciesID 246
--   (Fenrir Prime) and mob_resistances.resist_id 153.
--
-- SPELL <-> SCRIPT BINDING
--   Spell behavior loads from scripts/actions/spells/trust/<name>.lua, so
--   spell_list.name MUST stay 'skoll' to bind to skoll.lua. The stock
--   nanaa_mihgo.lua simply goes unreferenced -- harmless.
--
-- APPLYING (both steps)
--   1) Import:
--        "C:\Program Files\MariaDB 10.6\bin\mysql.exe" -u root -pwarrior3 xidb < modules\custom\sql\trust_skoll.sql
--   2) RESTART THE MAP SERVER (LoadTrustList/LoadSpellList run only at boot).
--   Both existing characters already know spell 901, so Skoll appears
--   under "Nanaa Mihgo" immediately after the restart -- the Void Keeper
--   purchase is kept for flavor / future characters.
--
-- Re-runnable: REPLACE INTO keys on the primary keys (spellid / poolid).
-- =====================================================================

-- ---- 1. Overwrite spell slot 901 (Nanaa Mihgo -> Skoll) --------------
--   group 8 = SPELLGROUP_TRUST, validTargets 1 = self, animation 939 =
--   generic trust-call. name 'skoll' binds it to trust/skoll.lua.
REPLACE INTO spell_list
    (spellid, name,   jobs, `group`, family, element, zonemisc, validTargets,
     skill, mpCost, castTime, recastTime, message, magicBurstMessage,
     animation, animationTime, AOE, base, multiplier, CE, VE,
     requirements, spell_range, radius, content_tag)
VALUES
    (901, 'skoll', '', 8, 0, 7, 0, 1,
     0, 0, 2000, 240000, 0, 0,
     939, 1500, 0, 0, 1.00, 0, 0,
     0, 0, 0, NULL);

-- ---- 2. Overwrite mob pool 5901 (= 901 + 5000) with the model --------
--   modelid is a size=1 EQUIPMENT look (look_t), NOT a fixed model: Hume
--   Female (race 2), face F3A, wielding Asclepius (club) + Aegis (shield),
--   wearing Dream Hat / Marine Top / Starlet Gloves / Dream Boots (legs +
--   ranged empty). Each look_t slot holds the item's RAW model id straight
--   from item_equipment.MId (head 140, body 334, hands 408, feet 140, main
--   818, sub 51) -- NO slot offset; the slot is fixed by field position, the
--   way charutils sets look.head = getModelId(). (The mannequin packet 0x026
--   adds +0x1000 etc., but that is a separate furniture display, NOT the live
--   look_t -- do not copy those offsets here.) A PC-skeleton look animates
--   fully in combat (cast/attack), unlike a static cutscene model.
--   skill_list_id 0 -> no native mob
--   TP moves. spellList 901 -> the gambit spell pool from section 3; the
--   trust AI never auto-casts from it (trusts are 100% gambit-driven), but
--   the gambits in skoll.lua REQUIRE it: a spell missing from the list is
--   rejected by CanUseSpell and its gambit is dropped at load (this was the
--   "Skoll does nothing" bug -- spellList was 0, i.e. the empty list).
--   packet_name 'Gemma' is what shows over her head + in the party list.
--   name_prefix 32 + entityFlags 3 are the trust flags.
--   mJob 17 / sJob 5 = COR / RDM. COR MAIN is MANDATORY for the Corsair
--   rolls added in skoll.lua: lua_baseentity.cpp::addCorsairRoll caps a
--   non-COR caster at 1 active roll, and corsair.lua scales a non-COR roll's
--   power to ~0 (getActiveJobLevel(COR) == 0). RDM sub still grants full
--   Enfeebling / Enhancing / Healing skill -- trustutils.cpp computes sub-job
--   magic skill at the master's level, not a halved sub level -- so the
--   debuff / buff / cure kit is unchanged (Dia is Enfeebling, cures/-na are
--   Healing, buffs are Enhancing). Nothing Skoll casts is Divine, so dropping
--   WHM costs nothing. Neither job grants Singing skill, so skoll.lua grants it
--   directly (mob:setSkillLevel) -- his songs run at FULL power, not base.
REPLACE INTO mob_pools
    (poolid, name,    packet_name, speciesid, modelid,
     mJob, sJob, cmbSkill, cmbDelay, cmbDmgMult,
     behavior, aggro, true_detection, links, mobType, immunity,
     name_prefix, flag, entityFlags, animationsub, hasSpellScript,
     spellList, namevis, roamflag, skill_list_id, resist_id,
     modelSize, modelHitboxSize)
VALUES
    (5901, 'skoll', 'Gemma', 246, UNHEX('010000024B004E010000C5010000000000000000'), -- FJB Gemma look (per AltanaView): Hume Female (race 2), face F1A (0), Assassin's Bonnet (head 75) + Marine Top (body 334) + Pretty Pink Subligar (legs 453), no weapon. look_t byte order = size(u16=1 MODEL_EQUIPPED), face(u8), race(u8), head/body/hands/legs/feet/main/sub/ranged(u16 LE). Name shows via renameEntity in skoll.lua (isRenamed branch handles the equipped-look name collision).
     17, 5, 0, 240, 0,
     0, 0, 0, 0, 0, 0,
     32, 0, 3, 0, 0,
     901, 0, 0, 0, 153,
     1, 12);

-- ---- 3. Skoll's gambit spell list (spell_list_id 901) ----------------
--   WITHOUT THIS, SKOLL DOES NOTHING. skoll.lua drives Skoll entirely via
--   gambits, and every gambit that casts magic is gated -- both at load
--   time and at cast time -- by the spell living in THIS list:
--     * Load time: a trust gambit is dropped during AddGambit unless
--       spell::CanUseSpell passes. For TYPE_TRUST that checks the spell's
--       min_level in the trust's spell list; a spell that's absent reads as
--       level 255, so (trust level < 255) -> the gambit is silently removed
--       and that action never fires. (This is the bug that made Skoll inert
--       when spellList was 0 / the empty list.)
--     * Cast time (HIGHEST family gambits: Cure / Protectra / Shellra /
--       Regen): GetBestAvailable(family) returns the LAST matching spell in
--       the container. Container order follows min_level ASC (LoadMobSpell-
--       List's ORDER BY), so Cure V (min_level 2) is appended after Cure
--       (min_level 1) and wins -> the HIGHEST cure casts Cure V.
--   min_level 1 / max_level 255 => always in range (a trust spawns at the
--   master's level, trustutils.cpp ~376). Cure V's min_level 2 is only to
--   sort it after Cure. Every spell_id below is canonical and exists in
--   spell_list -- required, since LoadMobSpellList INNER-JOINs spell_list.
--   Re-runnable: REPLACE INTO keys on PK (spell_list_id, spell_id).
REPLACE INTO mob_spell_lists
    (spell_list_name, spell_list_id, spell_id, min_level, max_level)
VALUES
    -- Heal family (HIGHEST cure -> Cure V; plain Cure also cast SPECIFIC to wake sleep)
    ('skoll', 901,   1, 1, 255),   -- Cure
    ('skoll', 901,   5, 2, 255),   -- Cure V    (min_level 2 -> sorts after Cure)
    -- Buff families (HIGHEST) + specific buffs
    ('skoll', 901, 129, 1, 255),   -- Protectra V
    ('skoll', 901, 134, 1, 255),   -- Shellra V
    ('skoll', 901, 504, 1, 255),   -- Regen V
    ('skoll', 901, 511, 1, 255),   -- Haste II
    -- (Refresh III removed -- owner wants no MP buffs; see DELETE in section 4.)
    -- Status removal (Erase + -na suite)
    ('skoll', 901, 143, 1, 255),   -- Erase
    ('skoll', 901,  14, 1, 255),   -- Poisona
    ('skoll', 901,  15, 1, 255),   -- Paralyna
    ('skoll', 901,  16, 1, 255),   -- Blindna
    ('skoll', 901,  17, 1, 255),   -- Silena
    ('skoll', 901,  18, 1, 255),   -- Stona
    ('skoll', 901,  19, 1, 255),   -- Viruna
    ('skoll', 901,  20, 1, 255),   -- Cursna
    -- Enemy debuffs
    ('skoll', 901,  79, 1, 255),   -- Slow II
    ('skoll', 901,  80, 1, 255),   -- Paralyze II
    ('skoll', 901, 276, 1, 255),   -- Blind II
    ('skoll', 901,  25, 1, 255),   -- Dia III
    ('skoll', 901,  59, 1, 255),   -- Silence
    -- Bard songs (cast SPECIFIC; sung on self, AoE to party). REQUIRED here
    -- or skoll.lua's song gambits are dropped at load. skoll.lua grants Singing
    -- skill (mob:setSkillLevel), so these run at FULL power, not base.
    ('skoll', 901, 420, 1, 255),   -- Victory March
    ('skoll', 901, 398, 1, 255),   -- Valor Minuet V
    ('skoll', 901, 399, 1, 255),   -- Sword Madrigal
    ('skoll', 901, 470, 1, 255),   -- Sentinel's Scherzo  (4th song: party phys+magic damage-taken down)
    -- (Mage's Ballad III (388) removed -- it is an MP-refresh song; see section 4.)
    -- Elemental nukes for MAGIC BURST (gambit: MB_AVAILABLE -> MA / MB_ELEMENT in
    -- skoll.lua). MB_ELEMENT scans ONLY the single-target damage list (m_damage-
    -- List, mob_spell_container.cpp), so every nuke here is single-target; a -ga
    -- would fall into the ga-list and never be picked. One nuke per element keeps
    -- the element->spell match exact. Ancient Magic II = the hardest-hitting
    -- single-target nukes in the game (huge base damage, very long base cast --
    -- exactly why Skoll runs maxed fast cast). Comet covers Dark. No Light nuke
    -- exists in Elemental magic, but Light / Light II / Fusion skillchains still
    -- burst via their Fire/Wind/Thunder element, so only a pure-Transfixion
    -- (light-only) chain has no match -- a rare, accepted gap. Each spell_id is
    -- canonical and exists in spell_list (LoadMobSpellList INNER-JOINs spell_list).
    ('skoll', 901, 205, 1, 255),   -- Flare II    (Fire)
    ('skoll', 901, 207, 1, 255),   -- Freeze II   (Ice)
    ('skoll', 901, 209, 1, 255),   -- Tornado II  (Wind)
    ('skoll', 901, 211, 1, 255),   -- Quake II    (Earth)
    ('skoll', 901, 213, 1, 255),   -- Burst II    (Thunder)
    ('skoll', 901, 215, 1, 255),   -- Flood II    (Water)
    ('skoll', 901, 219, 1, 255),   -- Comet       (Dark)
    -- Premium 500M upgrades (gambits in skoll.lua). All are RDM-sub skills at the
    -- master's full level: Arise/Raise = Healing, Phalanx II/Aquaveil = Enhancing,
    -- Distract/Dispel = Enfeebling -- so each lands / heals at full potency.
    ('skoll', 901, 494, 1, 255),   -- Arise        (rez the fallen; HIGHEST RAISE picks it over lower Raise tiers)
    ('skoll', 901, 107, 1, 255),   -- Phalanx II   (party flat damage reduction; validTargets allow allies)
    ('skoll', 901,  55, 1, 255),   -- Aquaveil     (self: casts can't be interrupted)
    ('skoll', 901, 842, 1, 255),   -- Distract II  (enemy evasion down -> melee lands)
    ('skoll', 901, 260, 1, 255);   -- Dispel       (strip enemy buffs)

-- ---- 4. Drop spells removed from the rotation ------------------------------
--   REPLACE INTO above can't delete rows a prior run already inserted, so any
--   spell pulled from Skoll's kit must be removed explicitly here. Idempotent:
--   a no-op once they're gone.
--     894 Refresh III, 388 Mage's Ballad III   -- MP buffs (owner wants none)
--     844 Frazzle II, 884 Addle II, 216 Gravity -- removed from his rotation by request
DELETE FROM mob_spell_lists WHERE spell_list_id = 901 AND spell_id IN (894, 388, 844, 884, 216);
