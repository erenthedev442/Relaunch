-- ---------------------------------------------------------------------------
-- jse_capes_stats.sql
-- Bakes the JSE / Ambuscade "best augment" build onto the 22 per-job capes
-- (ids 26246-26267) so they carry real stats when sold by the Infamy Vendor
-- (infamy_vendor_catalog.lua, 4,000 Infamy each).
--
-- WHY: upstream LSB only ships item_mods for 7 of the 22 capes (Cichol's,
-- Alaunus's, Sucellos's, Toutatis's, Andartia's, Campestres's, Visucius's) and
-- even those are partial; the other 15 are blank shells (no DEF, no stats).
-- This file gives every cape its full DEF + augment build using real engine
-- mods (all verified in scripts/enum/mod.lua). DELETE+INSERT so the result is
-- deterministic regardless of what the base item_mods.sql already set.
--
-- Brigantia's Mantle (26259, DRG) is intentionally NOT here -- it is already
-- statted in sql/zz_infamy_extra_mods.sql (DEF 18 / JUMP_DOUBLE_ATTACK 888=20 /
-- WYVERN_BREATH 402=15). Touching it in two files would risk drift.
--
-- A few screenshot effects have NO dedicated gear mod in LSB and are therefore
-- omitted (noted per-cape below): BLM "Mana Wall", DRK "Last Resort duration",
-- NIN "Migawari", BLU "Efflux TP bonus". Two more are mapped to the closest
-- real mod (noted): MNK "Kick Attacks attack" -> ATT, RNG "Double Shot damage"
-- -> Ranged Attack.
-- ---------------------------------------------------------------------------

DELETE FROM `item_mods` WHERE `itemId` IN
 (26246,26247,26248,26249,26250,26251,26252,26253,26254,26255,26256,26257,
  26258,26260,26261,26262,26263,26264,26265,26266,26267);

-- WAR  Cichol's Mantle (26246)
INSERT INTO `item_mods` VALUES (26246,1,18);     -- DEF
INSERT INTO `item_mods` VALUES (26246,1038,20);  -- DOUBLE_ATTACK_DMG: "Double Attack" damage +20
INSERT INTO `item_mods` VALUES (26246,954,15);   -- BERSERK_DURATION: "Berserk" effect duration +15

-- MNK  Segomo's Mantle (26247)
INSERT INTO `item_mods` VALUES (26247,1,16);     -- DEF
INSERT INTO `item_mods` VALUES (26247,292,10);   -- KICK_ATTACK_RATE: "Kick Attacks" +10
INSERT INTO `item_mods` VALUES (26247,23,25);    -- ATT (substitute for "Kick Attacks attack +25"; no kick-attack-attack mod exists)

-- WHM  Alaunus's Cape (26248)
INSERT INTO `item_mods` VALUES (26248,1,15);     -- DEF
INSERT INTO `item_mods` VALUES (26248,293,10);   -- AFFLATUS_SOLACE: "Afflatus Solace" +10
INSERT INTO `item_mods` VALUES (26248,310,25);   -- ENHANCES_CURSNA: "Cursna" +25

-- BLM  Taranus's Cape (26249)   [omitted: "Mana Wall +10%" -- no gear mod in LSB]
INSERT INTO `item_mods` VALUES (26249,1,15);     -- DEF
INSERT INTO `item_mods` VALUES (26249,487,5);    -- MAGIC_BURST_BONUS_CAPPED: Magic burst damage +5

-- RDM  Sucellos's Cape (26250)
INSERT INTO `item_mods` VALUES (26250,1,15);     -- DEF
INSERT INTO `item_mods` VALUES (26250,113,20);   -- ENHANCE: "Enhancing magic" effect duration +20
INSERT INTO `item_mods` VALUES (26250,114,10);   -- ENFEEBLE: "Enfeebling magic" effect +10

-- THF  Toutatis's Cape (26251)
INSERT INTO `item_mods` VALUES (26251,1,16);     -- DEF
INSERT INTO `item_mods` VALUES (26251,1039,20);  -- TRIPLE_ATTACK_DMG: "Triple Attack" damage +20
INSERT INTO `item_mods` VALUES (26251,874,10);   -- SNEAK_ATK_DEX: "Sneak Attack" +10

-- PLD  Rudianos's Mantle (26252)
INSERT INTO `item_mods` VALUES (26252,1,20);     -- DEF
INSERT INTO `item_mods` VALUES (26252,426,5);    -- ABSORB_PHYSDMG_TO_MP: converts 5% phys dmg taken to MP
INSERT INTO `item_mods` VALUES (26252,518,3);    -- SHIELDBLOCKRATE: chance of successful block +3

-- DRK  Ankou's Mantle (26253)   [omitted: "Last Resort duration +15" -- no mod]
INSERT INTO `item_mods` VALUES (26253,1,18);     -- DEF
INSERT INTO `item_mods` VALUES (26253,1136,10);  -- ENHANCES_ABSORB_EFFECTS: "Absorb" duration +10s

-- BST  Artio's Mantle (26254)
INSERT INTO `item_mods` VALUES (26254,1,18);     -- DEF
INSERT INTO `item_mods` VALUES (26254,364,30);   -- REWARD_HP_BONUS: "Reward" +30
INSERT INTO `item_mods` VALUES (26254,1157,10);  -- ENHANCES_SPUR: "Spur" +10

-- BRD  Intarabus's Cape (26255)
INSERT INTO `item_mods` VALUES (26255,1,15);     -- DEF
INSERT INTO `item_mods` VALUES (26255,438,1);    -- MADRIGAL_EFFECT: "Madrigal" +1
INSERT INTO `item_mods` VALUES (26255,448,1);    -- PRELUDE_EFFECT: "Prelude" +1

-- RNG  Belenus's Cape (26256)
INSERT INTO `item_mods` VALUES (26256,1,16);     -- DEF
INSERT INTO `item_mods` VALUES (26256,424,2);    -- VELOCITY_RATT_BONUS: "Velocity Shot" +2
INSERT INTO `item_mods` VALUES (26256,24,20);    -- RATT (substitute for "Double Shot damage +20"; no double-shot-dmg mod)

-- SAM  Smertrios's Mantle (26257)
INSERT INTO `item_mods` VALUES (26257,1,18);     -- DEF
INSERT INTO `item_mods` VALUES (26257,94,8);     -- MEDITATE_DURATION: "Meditate" duration +8
INSERT INTO `item_mods` VALUES (26257,174,3);    -- SKILLCHAINBONUS: Skillchain bonus +3

-- NIN  Andartia's Mantle (26258)   [omitted: "Migawari +5" -- no mod]
INSERT INTO `item_mods` VALUES (26258,1,16);     -- DEF
INSERT INTO `item_mods` VALUES (26258,900,1);    -- UTSUSEMI_BONUS: "Utsusemi" extra shadow +1

-- SMN  Campestres's Cape (26260)
INSERT INTO `item_mods` VALUES (26260,1,15);     -- DEF
INSERT INTO `item_mods` VALUES (26260,1040,1);   -- AVATAR_LVL_BONUS: Avatar: Lv.+1
INSERT INTO `item_mods` VALUES (26260,126,5);    -- BP_DAMAGE: "Blood Pact" damage +5

-- BLU  Rosmerta's Cape (26261)   [omitted: "Efflux TP bonus +250" -- no mod]
INSERT INTO `item_mods` VALUES (26261,1,16);     -- DEF
INSERT INTO `item_mods` VALUES (26261,1155,10);  -- ENHANCES_MONSTER_CORRELATION: monster correlation +10

-- COR  Camulus's Mantle (26262)
INSERT INTO `item_mods` VALUES (26262,1,16);     -- DEF
INSERT INTO `item_mods` VALUES (26262,882,30);   -- PHANTOM_DURATION: "Phantom Roll" duration +30
INSERT INTO `item_mods` VALUES (26262,999,5);    -- TRIPLE_SHOT_RATE: "Triple Shot" +5%

-- PUP  Visucius's Mantle (26263)
INSERT INTO `item_mods` VALUES (26263,1,16);     -- DEF
INSERT INTO `item_mods` VALUES (26263,1044,1);   -- AUTOMATON_LVL_BONUS: Automaton: Lv.+1
INSERT INTO `item_mods` VALUES (26263,505,10);   -- OVERLOAD_THRESH: "Overload" rate -10

-- DNC  Senuna's Mantle (26264)
INSERT INTO `item_mods` VALUES (26264,1,16);     -- DEF
INSERT INTO `item_mods` VALUES (26264,490,15);   -- SAMBA_DURATION: "Samba" duration +15
INSERT INTO `item_mods` VALUES (26264,421,5);    -- CRIT_DMG_INCREASE: Critical hit damage +5%

-- SCH  Lugh's Cape (26265)
INSERT INTO `item_mods` VALUES (26265,1,15);     -- DEF
INSERT INTO `item_mods` VALUES (26265,174,10);   -- SKILLCHAINBONUS: Skillchain bonus +10
INSERT INTO `item_mods` VALUES (26265,339,15);   -- REGEN_DURATION: "Regen" duration +15

-- GEO  Nantosuelta's Cape (26266)
INSERT INTO `item_mods` VALUES (26266,1,15);     -- DEF
INSERT INTO `item_mods` VALUES (26266,960,20);   -- INDI_DURATION: "Indicolure" duration +20
INSERT INTO `item_mods` VALUES (26266,1029,10);  -- LIFE_CYCLE_EFFECT: "Life Cycle" +10

-- RUN  Ogma's Cape (26267)
INSERT INTO `item_mods` VALUES (26267,1,18);     -- DEF
INSERT INTO `item_mods` VALUES (26267,963,3);    -- INQUARTATA: "Inquartata" +3
INSERT INTO `item_mods` VALUES (26267,1010,15);  -- VALIANCE_VALLATION_DURATION: "Vallation"/"Valiance" duration +15
