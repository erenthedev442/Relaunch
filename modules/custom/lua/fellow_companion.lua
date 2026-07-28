-----------------------------------
-- fellow_companion.lua  --  "Adventuring Fellow", reimagined as an RPG companion
--
-- A personal, persistent companion ANY job can summon, that the player BUILDS:
-- it levels from your kills, and you spend the points it earns on the stats you
-- choose, plus pick its NAME and APPEARANCE. Inspired by retail's Adventuring
-- Fellow, but the progression is fully player-driven.
--
-- WHY A TRUST (converted from a pet, 2026-07-12): the Fellow used to be a raw
-- pet, which occupies the engine's SINGLE pet slot -- so a DRG wyvern / BST jug
-- / SMN avatar / PUP automaton could not be out at the same time. A TRUST is a
-- party ally, NOT a pet, so the Fellow now COEXISTS with any job pet. It's
-- spawned via RAW player:spawnTrust(baseTrustId) -- a raw spawn that bypasses
-- the learned / party-space / cap checks (like the old raw spawnPet did) -- and
-- CTrustEntity is a CMobEntity, so the exact stat/name/model/ability overlay we
-- used on the pet ports over unchanged (addMod / setDamage / setMaxHP /
-- renameEntity / setModelId / useMobAbility). The Fellow-trust is flagged
-- (localVar fellowApplied) and made EXEMPT from the trust-count cap
-- (trust_progression_cap.lua) so it is a FREE EXTRA, not one of your slots.
-- Dismiss uses player:despawnTrust(trust) (a relaunch C++ binding -- vanilla
-- clearTrusts is all-or-nothing and would wipe the player's real trusts).
--
-- Combat: a trust follows the master and assists the master's target on its own
-- AI (so the old petAttack auto-assist is gone); the combat loop exclusively
-- fires the player's selected role TP move and runs the role behaviours
-- (heal/tank/nuke). Autonomous Naji/list TP moves are disabled.
--
-- NAME + APPEARANCE:
--   * NAME  -> trust:renameEntity(str, true). Sets the LIVE displayed name to
--     an arbitrary string on the trust entity. Re-applied each spawn.
--   * MODEL -> the base trust is spawned, then trust:setModelId(id) overlays an
--     NPC/mob model. NPC/mob model IDs work; player-character looks do not.
--
-- PHASE 1 (MVP): summon/dismiss, allocate stat points, pick role, name + model,
--   kill-XP -> levels, keeper + onGameIn persistence. Roles: Vanguard / Bulwark.
-- PHASE 2+: ability/trait tree, Oracle/Magus/Hunter behaviours, humanoid
--   appearance, a physical Hall NPC.
--   * Respec: Fellow Officer -> Allocate Points -> Reset Points.
--     Refunds the allocated pool minus a RESET_PENALTY_PCT (10%) loss.
--
-- ALL balance + name/model lists live in CONFIG -> tuning is a hot-reload.
-- Override module (onGameIn / onMobDeathEx) -> needs ONE map restart to load.
-----------------------------------
require('modules/module_utils')
local FN = require('modules/custom/lua/fellow_name')  -- custom free-text name (replaced the preset list)
local progression = require('modules/custom/lua/standard_ws_tuning_catalog')

local m   = Module:new('fellow_companion')
local SYS = xi.msg.channel.SYSTEM_3

-- ════════════════════════════════ CONFIG ════════════════════════════════════
local CONFIG =
{
    -- BASE TRUST loaded as the Fellow's chassis. spawnTrust(id) is a RAW spawn
    -- (bypasses the trust cap / party-space / learned checks), and a trust does
    -- NOT occupy the pet slot -- so the Fellow now COEXISTS with a DRG wyvern /
    -- BST jug / SMN avatar / PUP automaton (owner change 2026-07-12; it used to
    -- be a pet, which blocked those). A melee base gives the follow-and-assist
    -- AI; the Fellow's model / name / stats / role TP moves are overlaid on top
    -- (setModelId / renameEntity / addMod / useMobAbility all work on a trust,
    -- which is a CMobEntity). The Fellow-trust is flagged (localVar fellowApplied)
    -- so it is EXEMPT from the trust-count cap (trust_progression_cap.lua) -- a
    -- free extra ally, not one of your trust slots.
    baseTrustId = 897,  -- Naji (WAR trust): a plain melee follow/assist chassis

    maxLevel       = 120,
    startingPoints = 6,        -- granted once, when the Fellow is first created
    pointsPerLevel = 3,        -- stat points granted per level-up
    -- Post-cap progression: once the Fellow hits maxLevel you can BUY stat points
    -- with gil at the Fellow Officer and keep progressing toward Mastery.
    buyPointsCost  = 50000,    -- gil per purchased point (tunable)
    -- Every track is deliberately bounded so no mod approaches the engine's
    -- signed-int16 storage limit.
    -- v2 progression: 100 ranks in each of 14 tracks.  A fully levelled Fellow
    -- earns 363 naturally; the remaining 1,037 cost 51.85m gil at the rate above.
    statCap        = 100,
    -- Bulk allocation: amounts offered in the per-stat quantity picker (plus a
    -- "Max" option that fills to the cap or spends all remaining points). Lets
    -- players dump many points at once instead of one click per point.
    allocSteps     = { 1, 5, 10, 25, 50 },

    -- XP: each kill grants clamp(mobLevel * xpPerMobLevel, xpMin, xpMax), but only
    -- while your Fellow is summoned. xpToNext(L) = xpBase * L (linear ramp).
    xpPerMobLevel = 3,
    xpMin         = 5,
    xpMax         = 200,
    xpBase        = 80,
    partyWideXp   = true,      -- party members with a Fellow out also earn from the kill

    -- Per-allocated-point -> mods. One point in a stat adds ALL of its mods.
    statMods =
    {
        -- Attributes: each point adds the attribute + a derived combat stat.
        STR = { { xi.mod.STR, 1 }, { xi.mod.ATT, 3 } },
        DEX = { { xi.mod.DEX, 1 }, { xi.mod.ACC, 3 } },
        VIT = { { xi.mod.VIT, 1 }, { xi.mod.DEF, 3 } },
        AGI = { { xi.mod.AGI, 1 }, { xi.mod.EVA, 3 } },
        INT = { { xi.mod.INT, 1 }, { xi.mod.MATT, 3 } },
        MND = { { xi.mod.MND, 1 }, { xi.mod.MDEF, 3 } },
        -- Advanced categories: focused combat mods that STACK on top of the attributes.
        Ferocity  = { { xi.mod.ATTP, 0.25 } },                              -- +25% at rank 100
        Critical  = { { xi.mod.CRITHITRATE, 0.15 } },                       -- +15% at rank 100
        Frenzy    = { { xi.mod.DOUBLE_ATTACK, 0.15 } },                     -- +15% at rank 100
        Onslaught = { { xi.mod.TRIPLE_ATTACK, 0.08 }, { xi.mod.STORETP, 0.4 } },
        Sorcery   = { { xi.mod.MATT, 3 }, { xi.mod.MACC, 3 } },
        Celerity  = { { xi.mod.HASTE_GEAR, 25 } },                          -- 2500 = 25%
        Warding   = { { xi.mod.DMGPHYS, -15 }, { xi.mod.DMGMAGIC, -15 } },  -- -15% at rank 100
        Vigor     = { { xi.mod.REGEN, 1 } },
    },
    statOrder = { 'STR', 'DEX', 'VIT', 'AGI', 'INT', 'MND',
                  'Ferocity', 'Critical', 'Frenzy', 'Onslaught', 'Sorcery', 'Celerity', 'Warding', 'Vigor' },

    -- Flat base that scales with Fellow level (×level). ATT/ACC are shared (all
    -- roles melee); DEF is a small shared floor. Survivability is NOT shared -- it
    -- is owned by each role's explicit hpMin/hpMax and PDT/MDT block below.
    perLevel = { { xi.mod.ATT, 4 }, { xi.mod.ACC, 3 }, { xi.mod.DEF, 2 } },
    -- pdt/mdt are ONLY fallbacks if a role omits survival.pdt/mdt. Every role below
    -- sets its own, so the durability of a Fellow is defined by its role: a Bulwark
    -- is a wall, a Magus is glass. Values are % damage taken (100 = 1%; - reduces).
    pdt          = -1500,
    mdt          = -1500,

    -- PHYSICAL SCALING (2026-07-09 rebalance). The Fellow is a raw Lynx pet whose
    -- base weapon DMG is tiny, so autos + physical WS were stuck (~600 / ~4k) no
    -- matter how much ATT it piled on -- ATT only raises pDIF (caps ~3x); it can't
    -- fix a small base. setDamage() gives the Fellow a REAL weapon that scales with
    -- LEVEL, so physical output tracks the Fellow's level, and STR investment
    -- (-> ATT -> pDIF) then scales it further. Both knobs are playtest-tunable.
    -- Autos start around an ordinary trust and rise moderately. Signature moves
    -- temporarily use each role's wsDamage range below, keeping autos sane while
    -- letting the visible TP move reach the approved 5-8k -> 30-40k target.
    dmgBase           = 20,
    dmgPerMasterLevel = 1.25,
    dmgPerLevel       = 0.8,

    -- MAGIC CEILING (2026-07-09 rebalance). Magic mob skills (Magus Fire IV, Oracle
    -- Divine Judgment) multiply off MATT, which used to reach ~30,800 (INT 10/pt +
    -- Sorcery 12/pt x 1400 cap) and produced 280k-800k hits. MATT is now clamped
    -- AFTER all mods so magic still grows with INT/Sorcery investment but tops out
    -- in the same band as physical. Raise this to make magic builds stronger.
    mattCap      = 5000,

    -- Each role owns:
    --   mods     = flat OFFENSE/utility mods applied on spawn (identity of the role).
    --   survival = { hpMin, hpMax, pdt, mdt } -> explicit durability targets.
    --   behavior = optional per-tick ('heal'/'tank'/...) in scheduleCombatLoop.
    -- Every role still melee-assists + uses its signature TP move.
    roles =
    {
        -- `defaultWs` = fired at TP cap when the player picks "(Default)" in the Role menu.
        -- `moves`     = curated per-role list shown in the TP Move picker (replaces the old
        --               shared global tpMoves pool). Index stored in Fellow_TP_<role> charVar.
        vanguard  =
        {
            name = 'Vanguard', blurb = 'Balanced melee damage dealer.', defaultWs = xi.mobSkill.COMBO_1,
            mods     = { { xi.mod.ATTP, 20 }, { xi.mod.DOUBLE_ATTACK, 10 } },
            survival = { hpMin = 2700, hpMax = 5000, pdt = -1500, mdt = -1500 },
            wsDamage = { 1800, 9000 },
            moves =
            {
                { name = 'Penta Thrust',     ws = xi.mobSkill.PENTA_THRUST       },  -- 5-hit barrage
                { name = 'Vorpal Blade',     ws = xi.mobSkill.VORPAL_BLADE_1     },  -- fast slash
                { name = 'Combo',      ws = xi.mobSkill.COMBO_1      },  -- heavy crush (Antican)
                { name = 'Circle Blade',  ws = xi.mobSkill.CIRCLE_BLADE_1  },  -- spinning multi-hit
                { name = 'Blade Rin',      ws = xi.mobSkill.BLADE_RIN        },  -- sonic cutting wave
            },
        },
        berserker =
        {
            name = 'Berserker', blurb = 'All-out melee offense; hits like a truck but fragile.', defaultWs = xi.mobSkill.SAVAGE_BLADE_1,
            mods     = { { xi.mod.ATTP, 35 }, { xi.mod.DOUBLE_ATTACK, 20 }, { xi.mod.TRIPLE_ATTACK, 8 } },
            survival = { hpMin = 2300, hpMax = 4500, pdt = -500, mdt = -1000 },
            wsDamage = { 2200, 8000 },
            moves =
            {
                { name = 'Raging Fists', ws = xi.mobSkill.RAGING_FISTS_1 },  -- massive single hit
                { name = 'Evisceration',  ws = xi.mobSkill.EVISCERATION   },  -- heavy scythe
                { name = 'Savage Blade', ws = xi.mobSkill.SAVAGE_BLADE_1   },  -- dark scythe
                { name = 'Wheeling Thrust', ws = xi.mobSkill.WHEELING_THRUST },
                { name = 'Tachi: Kasha',    ws = xi.mobSkill.TACHI_KASHA    },  -- brutal backhand
            },
        },
        bulwark   =
        {
            name = 'Bulwark', blurb = 'Tank: huge HP, heavy mitigation, holds hate. The only real tank.', defaultWs = xi.mobSkill.URIEL_BLADE_1,
            mods     = { { xi.mod.DEF, 300 }, { xi.mod.ENMITY, 25 } }, behavior = 'tank',
            survival = { hpMin = 3200, hpMax = 6000, pdt = -2500, mdt = -2000 },
            wsDamage = { 800, 5000 },
            moves =
            {
                { name = 'Earth Pounder',      ws = xi.mobSkill.EARTH_POUNDER        },  -- reliable ground slam
                { name = 'Dominion Slash',     ws = xi.mobSkill.DOMINION_SLASH_TRUST },  -- reliable tank shockwave
                { name = 'Silence Gas',        ws = xi.mobSkill.SILENCE_GAS_2        },  -- AoE hate pull
                { name = 'Uriel Blade',      ws = xi.mobSkill.URIEL_BLADE_1        },  -- tremor
            },
        },
        oracle    =
        {
            name = 'Oracle', blurb = 'Primary healer: cures and cleanses first, then contributes light offense.', defaultWs = xi.mobSkill.DIVINE_SPEAR,
            mods     = { { xi.mod.MND, 150 }, { xi.mod.DEF, 100 }, { xi.mod.MDEF, 100 }, { xi.mod.REFRESH, 20 } }, behavior = 'heal',
            survival = { hpMin = 2500, hpMax = 4000, pdt = -1000, mdt = -1500 },
            magicPower = { 1200, 3800 },
            -- Mob-skill fTP varies wildly, so tune offensive magic per move
            -- instead of applying one MAGIC_DAMAGE value to all three.
            magicDamageByMove =
            {
                [xi.mobSkill.DIVINE_SPEAR]      = 100,
                [xi.mobSkill.EMPTY_SALVATION_1] = 900,
                [xi.mobSkill.CURSED_SPHERE_1]   = 900,
            },
            mpPool = { 1200, 3000 },
            healPower = { 1500, 5000 },
            wsDamage = { 700, 4500 },
            moves =
            {
                { name = 'Divine Spear',     ws = xi.mobSkill.DIVINE_SPEAR       },  -- holy lance
                { name = 'Empty Salvation',  ws = xi.mobSkill.EMPTY_SALVATION_1  },  -- light nova
                { name = 'Cursed Sphere',    ws = xi.mobSkill.CURSED_SPHERE_1    },  -- dark burst
            },
        },
        magus     =
        {
            name = 'Magus', blurb = 'Battle-mage: elemental power, but glass -- keep it off the tank spot.', defaultWs = xi.mobSkill.THUNDER_IV,
            mods     = { { xi.mod.INT, 100 }, { xi.mod.MACC, 200 } }, behavior = 'nuke',
            survival = { hpMin = 2200, hpMax = 3800, pdt = -500, mdt = -1000 },
            magicPower = { 1800, 5000 },
            -- MAGIC_DAMAGE is multiplied by each spell/mob-skill's fTP. Around
            -- 1,000 here puts capped Magus nukes near the intended 30k band
            -- without creating six-figure Thunder IV hits.
            magicDamage = { 500, 1000 },
            mpPool = { 1200, 3000 },
            moves =
            {
                { name = 'Thunder IV',      ws = xi.mobSkill.THUNDER_IV        },
                { name = 'Thunderstrike',    ws = xi.mobSkill.THUNDERSTRIKE      },  -- fTP 9, AoE stun
                { name = 'Double Slap',          ws = xi.mobSkill.DOUBLE_SLAP            },
                { name = 'Double Punch',         ws = xi.mobSkill.DOUBLE_PUNCH           },
            },
        },
        hunter    =
        {
            name = 'Hunter', blurb = 'Ranger: high accuracy and evasion; survives by dodging, not soaking.', defaultWs = xi.mobSkill.EAGLE_EYE_SHOT_HUMANOID,
            behavior = 'ranged',
            mods     = {
                { xi.mod.AGI, 100 }, { xi.mod.ACC, 200 }, { xi.mod.RACC, 500 },
                { xi.mod.RATT, 300 }, { xi.mod.EVA, 100 },
            },
            survival = { hpMin = 2600, hpMax = 4400, pdt = -1000, mdt = -1000 },
            wsDamage = { 2500, 11000 },
            -- Owner-curated ranger pool 2026-07-16 (proven on Semih Lafihna / Qultada
            -- / Lion trusts). Literal mob_skill_ids used because these are custom
            -- ranged WSes not present in scripts/enum/mob_skill.lua. Autonomous AI
            -- picks from skill_list_id 9805 (fellow_role_skill_lists.sql, same 5 IDs).
            moves =
            {
                { name = 'Arching Arrow',  ws = 3488 },  -- fTP 3.5, crit scales w/TP, ignores parry/guard/block, 16y
                { name = 'Lux Arrow',      ws = 3490 },  -- light-elemental arrow, 16y
                { name = 'Stellar Arrow',  ws = 3489 },  -- AoE arrow burst around the target, 16y
                { name = 'Sniper Shot',    ws =  210 },  -- single-target gun shot, 15y
                { name = 'Grapeshot',      ws = 3491 },  -- short-range 7y pistol cone AoE
            },
        },
        -- MASTERED: the prestige capstone. UNLOCKS only once ALL 14 categories are
        -- capped at statCap (51.85m gil beyond natural level points). It is a
        -- flex / show-off form, NOT an endgame power spike: the fully-capped allocation
        -- already supplies the raw stats, so these role mods are a modest "best of every
        -- role" garnish on top. behaviours combine Oracle's self-heal + Bulwark's hate-hold.
        --
        -- Mastered combines reduced versions of support behaviours; it does not
        -- inherit Oracle or Bulwark at full strength.
        mastered  =
        {
            name = 'Mastered', blurb = 'PRESTIGE: the effects of every role combined. A flex, not an endgame weapon.',
            defaultWs = xi.mobSkill.DANCING_EDGE,
            mods =
            {
                { xi.mod.ATTP, 40 }, { xi.mod.DOUBLE_ATTACK, 15 }, { xi.mod.TRIPLE_ATTACK, 8 },  -- Vanguard / Berserker
                { xi.mod.DEF, 200 }, { xi.mod.ENMITY, 30 },                                      -- Bulwark
                { xi.mod.MATT, 200 }, { xi.mod.MACC, 100 },                                      -- Magus (int16-capped garnish)
                { xi.mod.ACC, 100 }, { xi.mod.EVA, 80 },                                         -- Hunter
                { xi.mod.REGEN, 2 }, { xi.mod.REFRESH, 1 },                                      -- Oracle / Vigor
            },
            behaviors = { heal = true, tank = true },
            survival  = { hpMin = 4000, hpMax = 5200, pdt = -1500, mdt = -1500 },
            magicPower = { 2500, 3500 },
            magicDamage = { 500, 1000 },
            wsDamage = { 2200, 8500 },
            moves =
            {
                { name = 'Penta Thrust',     ws = xi.mobSkill.PENTA_THRUST       },  -- Vanguard
                { name = 'Vorpal Blade',     ws = xi.mobSkill.VORPAL_BLADE_1     },
                { name = 'Auroral Uppercut', ws = xi.mobSkill.AURORAL_UPPERCUT_1 },  -- Berserker
                { name = 'Earth Pounder',    ws = xi.mobSkill.EARTH_POUNDER      },  -- Bulwark
                { name = 'Maelstrom',        ws = xi.mobSkill.MAELSTROM_1        },
                { name = 'Blizzard IV',      ws = xi.mobSkill.BLIZZARD_IV        },  -- Magus
                { name = 'Aero IV',          ws = xi.mobSkill.AERO_IV            },
                { name = 'Stellar Arrow',    ws = 3489                           },  -- functional Hunter finisher
                { name = 'Arching Arrow',    ws = 3488                           },
                { name = 'Dancing Edge',     ws = xi.mobSkill.DANCING_EDGE       },  -- signature default
            },
        },
    },
    -- 'mastered' is index 7 but is HIDDEN from the Role picker until unlocked (openRole
    -- only appends it when isMastered() is true), and getRole() falls a stored Mastered
    -- selection back to the default if the caps are ever respec'd away.
    roleOrder   = { 'vanguard', 'berserker', 'bulwark', 'oracle', 'magus', 'hunter', 'mastered' },
    defaultRole = 'vanguard',

    -- NAME picker: curated person-names (lifted from the engine's dead fellowNames
    -- table in fellowentity.cpp). renameEntity wire limit ~15 chars -> keep short.
    names =
    {
        'Siegward', 'Theobald', 'Gunnar', 'Ferdinand', 'Beatrice', 'Henrietta',
        'Karyn', 'Nanako', 'Gauldeval', 'Romidiant', 'Liabelle', 'Radille',
        'Nokum-Akkum', 'Yawawa', 'Cupapa', 'Raka Maimhov', 'Voldai', 'Zoldof',
    },

    -- APPEARANCE picker: each entry has a modelId applied via setModelId() right after
    -- spawn. The spawn chassis is always LYNX_FAMILIAR (combat AI); only the visual
    -- is swapped. Model IDs derived from mob_pools.modelid bytes [2-3] little-endian.
    --
    -- CRASH RISK (report 2026-07-09, Duff): the pet's TP move is chosen by ROLE,
    -- independent of the appearance. If the displayed model's skeleton lacks the
    -- performed mob-skill's animation, the CLIENT force-closes (confirmed:
    -- Cardian + Thunderstrike). `disabled = true` hides a look from the picker AND
    -- makes any stored selection of it fall back to the default Lynx chassis, so
    -- nobody is stuck on a crashy model. Disabled below = the confirmed crasher +
    -- the most non-standard skeletons (floating / legless / plant / imp), which are
    -- the highest risk of missing an arbitrary mob-skill animation.
    -- NOTE: this is CURATION, not a guarantee -- a kept model can still crash on a
    -- specific move (the Cardian crash was a caster model that DID have cast anims).
    -- Toggle `disabled` as in-game testing confirms each look. Indices are stable,
    -- so flipping the flag never shifts anyone's saved appearance.
    models =
    {
        -- `ws` = this form's SIGNATURE TP move, forced at TP cap (useMobAbility).
        { name = 'Moogle',     modelId = 3035, ws = xi.mobSkill.METEORITE,          disabled = true },  -- CRASH-RISK: floating/tiny skeleton
        { name = 'Mandragora', modelId = 300,  ws = xi.mobSkill.AERO_IV,            disabled = true },  -- CRASH-RISK: legless plant skeleton
        { name = 'Coeurl',     modelId = 367,  ws = xi.mobSkill.CHARGED_WHISKER    },  -- thunder (coeurl signature) -- PENDING TEST
        { name = 'Sabotender', modelId = 372,  ws = xi.mobSkill.THOUSAND_NEEDLES_1, disabled = true },  -- CRASH-RISK: rigid cactus skeleton
        { name = 'Cardian',    modelId = 431,  ws = xi.mobSkill.FIRE_IV,            disabled = true },  -- CONFIRMED CRASH (Thunderstrike)
        { name = 'Goblin',     modelId = 484,  ws = xi.mobSkill.BOMB_TOSS_1        },  -- Bomb Toss (goblin). 484 = Goblin_Brigand humanoid; 292 was the Slime family (bug, 2026-07-07). -- PENDING TEST
        { name = 'Yagudo',     modelId = 580,  ws = xi.mobSkill.DANCING_EDGE       },  -- multi-hit physical (yagudo) -- PENDING TEST
        { name = 'Tonberry',   modelId = 1177, ws = xi.mobSkill.CURSED_SPHERE_1    },  -- dark burst -- PENDING TEST
        { name = 'Antican',    modelId = 1280, ws = xi.mobSkill.ROCK_BUSTER        },  -- earth physical -- PENDING TEST
        { name = 'Boggart',    modelId = 451,  ws = xi.mobSkill.BLIZZARD_IV,        disabled = true },  -- CRASH-RISK: imp skeleton
        { name = 'Goobbue',    modelId = 296,  ws = xi.mobSkill.AURORAL_UPPERCUT_1, disabled = true },  -- CRASH-RISK: plant-beast skeleton
        { name = 'Adventurer', modelId = 3119, ws = xi.mobSkill.CRESCENT_FANG      },  -- strong physical -- PENDING TEST
    },

    -- OUTFIT picker: humanoid job-class themes applied on top of Appearance.
    -- When an outfit is set it overrides the Appearance model entirely.
    -- Model IDs are the trust-era (0C-range) npc_list look values for iconic FFXI
    -- characters: bytes[2]|(bytes[3]<<8) from HEX(SUBSTR(look,1,4)) -- same LE formula
    -- as mob_pools.modelid. Select "(None)" to revert to the Appearance model.
    outfits =
    {
        { name = 'Thief',       modelId = 3011 },  -- Lion (trust era)
        { name = 'Monk',        modelId = 3017 },  -- Prishe (trust era)
        { name = 'Red Mage',    modelId = 3049 },  -- Lilisette (trust era)
        { name = 'Ranger',      modelId = 3034 },  -- Aldo (trust era)
        { name = 'Dark Knight', modelId = 3010 },  -- Zeid (trust era)
        { name = 'Warrior',     modelId = 3007 },  -- Volker (trust era)
        { name = 'Paladin',     modelId = 3009 },  -- Trion (trust era)
        { name = 'Black Mage',  modelId = 3000 },  -- Shantotto (trust era)
        { name = 'Scholar',     modelId = 3008 },  -- Ajido-Marujido (trust era)
        { name = 'Bard',        modelId = 3018 },  -- Ulmia (trust era)
    },

    autoReadyTP         = 1000,
    combatLoopMs        = 2000,
    wsCooldownSec       = 8,
    nukeCooldownSec     = 10,
    burstCooldownSec    = 3,
    summonCooldownSec   = 300,

    healHpp             = 70,
    healMin             = 300,
    healMax             = 1500,
    healCooldownSec     = 5,
    cleanseCooldownSec  = 6,
    tauntMinCE          = 400,
    tauntMaxCE          = 800,
    tauntMinVE          = 800,
    tauntMaxVE          = 1600,
    tauntCooldownSec    = 6,

    keeperMs            = 10000,
    firstMs             = 4000,
    namesPerPage        = 6,   -- customMenu caps: keep page + nav <= 8 options / 150 bytes
}

local GRADES =
{
    { name = 'Initiate',  level =   1, points =    0, damage = '5-8k' },
    { name = 'Bonded',    level =  30, points =   75, damage = '8-12k' },
    { name = 'Veteran',   level =  60, points =  175, damage = '12-18k' },
    { name = 'Elite',     level =  90, points =  275, damage = '16-23k' },
    { name = 'Ascendant', level = 120, points =  350, damage = '20-28k' },
    { name = 'Empowered', level = 120, points =  700, damage = '24-32k' },
    { name = 'Exalted',   level = 120, points = 1050, damage = '28-36k' },
    { name = 'Mastered',  level = 120, points = 1400, damage = '30-40k' },
}

-- charVar keys (per-character; ALL INTEGER).
local V =
{
    active   = 'Fellow_Active',
    born     = 'Fellow_Born',
    level    = 'Fellow_Level',
    xp       = 'Fellow_XP',
    points   = 'Fellow_Points',
    role     = 'Fellow_Role',     -- index into CONFIG.roleOrder
    nameIdx  = 'Fellow_NameIdx',  -- index into CONFIG.names
    modelPet = 'Fellow_ModelPet', -- index into CONFIG.models (each carries a petId)
    outfit   = 'Fellow_Outfit',  -- 0 = none (use Appearance); N = CONFIG.outfits[N]
    mastered = 'Fellow_Mastered', -- 1 once the "all 14 capped" unlock message has fired (one-time)
    schema   = 'Fellow_StatSchema',
}
local SUMMONED_AT_LOCAL_VAR = 'fellowSummonedAt'
local function statVar(stat) return 'Fellow_' .. stat end

-- ════════════════════════════ Data-model helpers ════════════════════════════
local function getN(p, k)     return p:getCharVar(k) or 0 end
local function setN(p, k, n)  p:setCharVar(k, math.max(0, math.floor(n))) end

local function getLevel(p)  return math.max(1, getN(p, V.level)) end
local function getPoints(p) return getN(p, V.points) end
local function getStatPts(p, stat) return getN(p, statVar(stat)) end
local function allocatedTotal(p)
    local total = 0
    for _, stat in ipairs(CONFIG.statOrder) do total = total + getStatPts(p, stat) end
    return total
end

local function migrateProgression(p)
    if getN(p, V.schema) >= 2 then return end
    local lvl = getLevel(p)
    local converted = 0
    for _, stat in ipairs(CONFIG.statOrder) do
        local old = getStatPts(p, stat)
        local new = math.min(CONFIG.statCap, math.ceil(old / 14))
        setN(p, statVar(stat), new)
        converted = converted + new
    end
    local pool = math.ceil(getPoints(p) / 14)
    local natural = CONFIG.startingPoints + math.max(0, lvl - 1) * CONFIG.pointsPerLevel
    pool = math.max(pool, natural - converted)
    setN(p, V.points, pool)
    setN(p, V.schema, 2)
end

-- Mastery gate: TRUE only when every allocatable category is at the cap. This is
-- the 1,400-point "cap everything" milestone that unlocks the Mastered role. Cheap
-- (14 in-memory charVar reads); safe to call from the combat loop / menus.
local function isMastered(p)
    for _, stat in ipairs(CONFIG.statOrder) do
        if getStatPts(p, stat) < CONFIG.statCap then return false end
    end
    return true
end

-- Role is stored as an INTEGER index into CONFIG.roleOrder (charVars are ints,
-- not strings). 0/unset -> default.
local function getRole(p)
    local key = CONFIG.roleOrder[getN(p, V.role)]
    -- The Mastered role only holds while all 14 caps are maintained; if a player
    -- respecs a category below cap, a stored Mastered selection reverts to default
    -- (they keep the index, so re-capping restores Mastered automatically).
    if key == 'mastered' and not isMastered(p) then return CONFIG.defaultRole end
    if key and CONFIG.roles[key] then return key end
    return CONFIG.defaultRole
end
local function roleDef(p) return CONFIG.roles[getRole(p)] or CONFIG.roles[CONFIG.defaultRole] end

-- Appearance = NPC model ID applied via setModelId after spawn; Name = live display name.
local function chosenModelId(p)
    local mdl = CONFIG.models[getN(p, V.modelPet)]
    -- A disabled (crash-risk) or missing look falls back to the default Lynx
    -- chassis (no overlay) so a stored selection can never crash the client.
    if not mdl or mdl.disabled then return nil end
    return mdl.modelId
end
-- Outfit overrides Appearance when set (0 = no outfit).
local function getOutfitModelId(p)
    local entry = CONFIG.outfits[getN(p, V.outfit)]
    return entry and entry.modelId
end
-- Per-role TP-move override charVar (0/unset = use the role's defaultWs).
local function tpVar(roleKey) return 'Fellow_TP_' .. roleKey end
-- The signature TP move fired at TP cap, resolved PER ROLE (not by appearance):
--   per-role override (Fellow_TP_<role>) -> the role's defaultWs -> appearance ws.
-- nil -> the combat loop falls back to a chassis-picked Ready move.
local function chosenWs(p)
    local roleKey = getRole(p)
    local choice  = getN(p, tpVar(roleKey))
    if choice > 0 then
        local rd    = CONFIG.roles[roleKey]
        local entry = rd and rd.moves and rd.moves[choice]
        if entry and entry.ws then return entry.ws end
    end
    local rd = CONFIG.roles[roleKey]
    if rd and rd.defaultWs then return rd.defaultWs end
    local mdl = CONFIG.models[getN(p, V.modelPet)]
    return mdl and mdl.ws
end

local MAGUS_MOVE_ELEMENTS =
{
    [xi.mobSkill.THUNDER_IV]    = xi.element.THUNDER,
    [xi.mobSkill.THUNDERSTRIKE] = xi.element.THUNDER,
}

local function chosenMagusElement(p)
    return MAGUS_MOVE_ELEMENTS[chosenWs(p)]
end

local function masterHasTargetEnmity(master, target)
    if not master or not target or target:isDead() then
        return false
    end

    local ok, hasEnmity = pcall(function()
        return target:getCE(master) + target:getVE(master) > 0
    end)

    return ok and hasEnmity
end
-- Naming is free-text via the !fellowname command (fellow_name.lua). The old
-- preset name list (CONFIG.names / Fellow_NameIdx) was replaced 2026-07-09;
-- fall back to a generic default until the player sets a custom name.
local DEFAULT_FELLOW_NAME = 'Fellow'
local function chosenName(p)
    return FN.read(p) or CONFIG.names[getN(p, V.nameIdx)] or DEFAULT_FELLOW_NAME
end

local function xpToNext(level) return CONFIG.xpBase * level end

local function levelProgress(p)
    return math.max(0, math.min(1, (getLevel(p) - 1) / (CONFIG.maxLevel - 1)))
end

local function investmentProgress(p)
    return math.max(0, math.min(1, allocatedTotal(p) / (CONFIG.statCap * #CONFIG.statOrder)))
end

local function combatProgress(p)
    return 0.45 * levelProgress(p) + 0.55 * investmentProgress(p)
end

-- Full Fellow bonuses unlock at main-job level 99. Below 99, offensive power
-- follows the current job level so a progressed Fellow cannot erase low-level
-- content after its owner changes to a level-1 job.
local function masterPowerProgress(p)
    local level = math.max(1, math.min(99, p:getMainLvl() or 1))
    return math.max(0, math.min(1, (level - 1) / 98))
end

-- Offensive power requires all four progression axes. Small non-zero gates let
-- a new Fellow participate, but full output requires Fellow level 120, every
-- attribute capped, a Lv99 master, and 2,100 spent Job Points.
local function fellowPowerProgress(p)
    local levelGate      = 0.10 + 0.90 * levelProgress(p)
    local investmentGate = 0.10 + 0.90 * investmentProgress(p)
    local masteryGate    = 0.15 + 0.85 * progression.getMasteryProgress(p)

    return levelGate * investmentGate * masterPowerProgress(p) * masteryGate
end

local function lerp(a, b, t)
    return math.floor(a + (b - a) * math.max(0, math.min(1, t)))
end

local function scaledRoleValue(p, range)
    return math.floor(range[2] * fellowPowerProgress(p))
end

local function normalWeaponDamage(p)
    local masterLvl = math.max(1, p:getMainLvl() or 1)
    return math.max(1, math.floor((
        CONFIG.dmgBase +
        CONFIG.dmgPerMasterLevel * math.min(99, masterLvl) +
        CONFIG.dmgPerLevel * math.max(0, getLevel(p) - 1)) * fellowPowerProgress(p)))
end

local function fellowDamageCap(p, target)
    local fullPowerCap = math.min(99999, progression.getDamageBonus(
        p:getMainLvl(), target:getMainLvl(), target:getMaxHP()))

    return math.max(1, math.floor(fullPowerCap * fellowPowerProgress(p)))
end

local function currentGrade(p)
    local lvl, points = getLevel(p), allocatedTotal(p)
    local grade = GRADES[1]
    for _, candidate in ipairs(GRADES) do
        if lvl >= candidate.level and points >= candidate.points then grade = candidate end
    end
    return grade
end

-- Create-on-first-use: grant starting points + sensible defaults exactly once.
local function ensureBorn(p)
    if getN(p, V.born) == 1 then
        migrateProgression(p)
        return
    end
    p:setCharVar(V.born, 1)
    setN(p, V.schema, 2)
    setN(p, V.level, 1)
    setN(p, V.points, CONFIG.startingPoints)
    setN(p, V.role, 1)      -- defaultRole
    setN(p, V.nameIdx, 1)   -- a proper name by default; player can re-pick
    setN(p, V.modelPet, 1)  -- default chassis (Lynx)
end

-- ════════════════════════════ Stat application ══════════════════════════════
local scheduleCombatLoop -- fwd

-- Layer the Fellow's full stat block + chosen name onto a freshly-spawned pet.
-- Guarded so it runs once per spawned entity.
local function applyFellow(p, pet)
    if not pet or pet:getLocalVar('fellowApplied') ~= 0 then return end
    pet:setLocalVar('fellowApplied', 1)

    local lvl  = getLevel(p)
    local role = roleDef(p)

    local masterPower = fellowPowerProgress(p)
    pet:setLocalVar(
        'EncounterOutgoingDamageCap',
        math.max(1, math.floor(99999 * masterPower)))
    for _, mv in ipairs(CONFIG.perLevel) do
        pet:addMod(mv[1], math.floor(mv[2] * lvl * masterPower))
    end
    for _, mv in ipairs(role.mods or {}) do
        pet:addMod(mv[1], math.floor(mv[2] * masterPower))
    end

    for stat, mods in pairs(CONFIG.statMods) do
        local pts = getStatPts(p, stat)
        if pts > 0 then
            for _, mv in ipairs(mods) do
                pet:addMod(mv[1], math.floor(mv[2] * pts * masterPower))
            end
        end
    end

    if role.magicPower then
        pet:addMod(xi.mod.MATT, scaledRoleValue(p, role.magicPower))
    end
    if role.magicDamage then
        pet:addMod(xi.mod.MAGIC_DAMAGE, scaledRoleValue(p, role.magicDamage))
    end
    if role.mpPool then
        local targetMP = lerp(role.mpPool[1], role.mpPool[2], combatProgress(p))
        pet:setMaxMP(targetMP)
        pet:setMP(targetMP)
    end

    -- PHYSICAL: give the Fellow a real, level-scaling weapon so autos + physical WS
    -- track level (see CONFIG.dmgBase/dmgPerLevel). STR investment (-> ATT -> pDIF)
    -- scales it further. pcall-guarded: a pet always has a weapon, but never let a
    -- nil weapon abort the whole apply.
    pcall(function()
        pet:setDamage(normalWeaponDamage(p))
    end)

    -- MAGIC: clamp MATT AFTER every mod source (attributes + role + advanced
    -- categories) so magic mob skills grow with INT/Sorcery investment but can't
    -- runaway-scale into the 100k-800k hits players were seeing. See CONFIG.mattCap.
    if pet:getMod(xi.mod.MATT) > CONFIG.mattCap then
        pet:setMod(xi.mod.MATT, CONFIG.mattCap)
    end

    -- HP is an explicit role target, not an additive bonus on Naji's chassis.
    -- This guarantees the approved hard ceilings (Oracle 4k, Bulwark 6k).
    local surv   = role.survival or {}
    pet:addMod(xi.mod.DMGPHYS,  surv.pdt or CONFIG.pdt)
    pet:addMod(xi.mod.DMGMAGIC, surv.mdt or CONFIG.mdt)

    local targetHP = lerp(surv.hpMin or 2500, surv.hpMax or 5000, combatProgress(p))
    pet:setMaxHP(targetHP)
    pet:setHP(targetHP)

    local roleKey = getRole(p)
    -- Disable autonomous trust TP moves. The combat loop below exclusively
    -- fires the move selected in the Fellow menu, so Naji/list randomness can
    -- no longer consume TP on a different move.
    pet:setMobMod(xi.mobMod.SKILL_LIST, 9999)

    -- Give the two specialist roles real trust-controller behavior instead of
    -- making Naji's melee chassis pretend to cast or shoot.
    if roleKey == 'oracle' then
        -- Kupipi's full healer list gives Oracle visible Cure and -na/Erase
        -- casts. The Lua emergency heal below remains a safety net so healing
        -- always wins over offense when the trust controller is busy.
        pet:setSpellList(310)
        pet:addMod(xi.mod.CURE_POTENCY, 50)
        pet:addMod(xi.mod.FASTCAST, 50)
        pet:addGambit(ai.t.PARTY, { ai.c.STATUS, xi.effect.POISON }, { ai.r.MA, ai.s.SPECIFIC, xi.magic.spell.POISONA })
        pet:addGambit(ai.t.PARTY, { ai.c.STATUS, xi.effect.PARALYSIS }, { ai.r.MA, ai.s.SPECIFIC, xi.magic.spell.PARALYNA })
        pet:addGambit(ai.t.PARTY, { ai.c.STATUS, xi.effect.BLINDNESS }, { ai.r.MA, ai.s.SPECIFIC, xi.magic.spell.BLINDNA })
        pet:addGambit(ai.t.PARTY, { ai.c.STATUS, xi.effect.SILENCE }, { ai.r.MA, ai.s.SPECIFIC, xi.magic.spell.SILENA })
        pet:addGambit(ai.t.PARTY, { ai.c.STATUS, xi.effect.PETRIFICATION }, { ai.r.MA, ai.s.SPECIFIC, xi.magic.spell.STONA })
        pet:addGambit(ai.t.PARTY, { ai.c.STATUS, xi.effect.DISEASE }, { ai.r.MA, ai.s.SPECIFIC, xi.magic.spell.VIRUNA })
        pet:addGambit(ai.t.PARTY, { ai.c.STATUS, xi.effect.CURSE_I }, { ai.r.MA, ai.s.SPECIFIC, xi.magic.spell.CURSNA })
        pet:addGambit(ai.t.PARTY, { ai.c.STATUS_FLAG, xi.effectFlag.ERASABLE }, { ai.r.MA, ai.s.SPECIFIC, xi.magic.spell.ERASE })
        pet:setMobMod(xi.mobMod.TRUST_DISTANCE, xi.trust.movementType.NO_MOVE)
    elseif roleKey == 'magus' then
        -- The combat loop casts only the spell/move selected in the Fellow
        -- menu. Keep it inside the selected move's 10-yalm range; LONG_RANGE
        -- holds at 12 yalms and makes useMobAbility silently reject Thunder IV.
        pet:setMobMod(xi.mobMod.TRUST_DISTANCE, 7)
    elseif roleKey == 'hunter' then
        pet:addGambit(ai.t.TARGET, { ai.c.ALWAYS, 0 }, { ai.r.RATTACK, 0, 0 })
        pet:addMod(xi.mod.STORETP, 86)
        pet:setMobMod(xi.mobMod.TRUST_DISTANCE, xi.trust.movementType.LONG_RANGE)
    elseif roleKey == 'bulwark' then
        -- Fellows suppress Naji's inherited Provoke at raw spawn. Add it back
        -- only for the dedicated tank role; otherwise NOT_HAS_TOP_ENMITY keeps
        -- non-tanks queueing Provoke and starves their spells/TP moves.
        pet:addGambit(
            ai.t.SELF,
            { ai.c.NOT_HAS_TOP_ENMITY, 0 },
            { ai.r.JA, ai.s.SPECIFIC, xi.ja.PROVOKE })

        -- Use the same sustained-enmity system as the server's real trust tanks.
        -- This profile supplies the CE/VE pressure and retargeting needed to
        -- hold against players and other trusts instead of merely flashing Provoke.
        xi.trust.enableTankEnmity(pet,
        {
            profile = 'strong',
            drainMaster = 15,
            includeParty = true,
            listenerName = 'FELLOW_BULWARK_TANK_ENMITY',
        })

        -- Silence Gas is globally capped at 800 and randomly lasts 15-60s.
        -- Normalize only the Fellow version: modest 2.5k total damage and a
        -- predictable 30-second Silence without changing every funguar.
        pet:addListener('WEAPONSKILL_USE', 'FELLOW_BULWARK_SILENCE_GAS', function(tank, target, skill, tp, action, damage)
            if skill:getID() ~= xi.mobSkill.SILENCE_GAS_2 or not target or target:isDead() then
                return
            end

            local desiredDamage = 2500
            if p:getMainLvl() < 99 then
                desiredDamage = math.min(desiredDamage, progression.getDamageBonus(
                    p:getMainLvl(), target:getMainLvl(), target:getMaxHP()))
            end

            local bonus = math.max(0, desiredDamage - (damage or 0))
            if bonus > 0 then
                target:takeDamage(bonus, tank, xi.attackType.BREATH, xi.damageType.DARK)
            end

            local silence = target:getStatusEffect(xi.effect.SILENCE)
            if silence then
                silence:setDuration(30000)
            end
        end)
    end

    -- Forced role moves are queued asynchronously. Only consume TP and start
    -- cooldown after the move actually fires; a busy/out-of-range queue attempt
    -- must not silently eat TP and leave the Fellow idle.
    pet:addListener('WEAPONSKILL_USE', 'FELLOW_ROLE_MOVE_COMPLETE', function(actor)
        actor:setTP(0)
        actor:setLocalVar('fellowMovePendingAt', 0)
        actor:setLocalVar('fellowProgressionDamageCap', 0)
        actor:setLocalVar('fellowAoEDamageScale', 0)
        actor:setLocalVar('fellowCanMagicBurst', 0)
        if getRole(p) == 'magus' then
            actor:setLocalVar('fellowNukeAt', os.time())
        else
            actor:setLocalVar('fellowWsAt', os.time())
        end
    end)

    -- A defeated Fellow stays down like a trust. The player must explicitly
    -- summon it again once the cooldown is ready.
    pet:addListener('DEATH', 'FELLOW_DEATH', function()
        setN(p, V.active, 0)
        p:setLocalVar('fellowSummonPending', 0)
    end)

    -- Live display name (arbitrary string; silent=true to avoid console spam).
    local nm = chosenName(p)
    if nm then pcall(function() pet:renameEntity(nm, true) end) end

    -- Visual NPC model overlay. Outfit overrides Appearance when set.
    local mdlId = getOutfitModelId(p) or chosenModelId(p)
    if mdlId then pcall(function() pet:setModelId(mdlId) end) end

    scheduleCombatLoop(p, pet)
end

-- Self-rescheduling COMBAT loop. Jug pets DON'T assist a non-BST master on their
-- own, and a non-pet job has no Fight/Sic command -- so each tick we:
--   * AUTO-ASSIST: if the master is engaged and the Fellow is idle, order it onto
--     the master's battle target (master:petAttack = the BST Fight order, not
--     job-gated; master:getTarget() = the battle target, same as allyassist).
--   * AUTO-READY: if engaged with capped TP, fire its TP move.
-- Bails when the pet dies/despawns. The master ref is captured in the closure; by
-- the time it could go invalid the pet has already despawned (pets die with their
-- master) so the loop has stopped -- and all master access is pcall-guarded.
scheduleCombatLoop = function(master, pet)
    pet:timer(CONFIG.combatLoopMs, function(p)
        -- TEARDOWN GUARD (2026-07-17 crash fix): both refs can be userdata
        -- wrapping freed entities after a logout. pcall catches Lua-raised
        -- errors; the nil-guarded getZone() catches the invalid-entity case
        -- (engine warns + returns nil instead of dereferencing). Bail without
        -- re-arming on any doubt -- the keeper respawns a fresh Fellow.
        local okZ, zoned = pcall(function()
            return p ~= nil and p:getZone() ~= nil
               and master ~= nil and master:getZone() ~= nil
        end)
        if not okZ or not zoned then return end

        if not p:isAlive() then return end
        pcall(function()
            if not (master and master:isAlive()) then return end
            local rdef = roleDef(master)
            local beh  = rdef.behavior
            local behs = rdef.behaviors               -- optional set { name = true } for multi-role forms (Mastered)
            local function hasBeh(name) return beh == name or (behs and behs[name]) end
            local lvl  = getLevel(master)
            local now  = os.time()
            local masterTarget = master:getTarget()
            local active = masterHasTargetEnmity(master, masterTarget)

            -- Match normal trust behavior: drawing a weapon is not enough.
            -- The Fellow assists only after the master has generated enmity.
            -- Hunter uses ranged attacks, so its melee auto-attack stays disabled.
            p:setAutoAttackEnabled(active and not hasBeh('ranged'))
            if not active then
                if p:isEngaged() then p:disengage() end
                p:setLocalVar('fellowCombatStartedAt', 0)
                return
            end
            if (p:getLocalVar('fellowCombatStartedAt') or 0) == 0 then
                p:setLocalVar('fellowCombatStartedAt', now)
            end
            if not p:isEngaged() then
                p:engage(masterTarget:getTargID())
            end

            -- Oracle is a healer first. Its pulse selects the most injured
            -- player, trust, or Fellow and begins healing at 70% HP. This is
            -- the sole HP-heal path, avoiding competing queued overheals.
            if hasBeh('heal')
               and now - (p:getLocalVar('fellowHealAt') or 0) >= CONFIG.healCooldownSec then
                local healTarget = master
                local lowestHpp = master:getHP() * 100 / math.max(1, master:getMaxHP())
                local okParty, party = pcall(function() return master:getPartyWithTrusts() end)
                if okParty and party then
                    for _, member in pairs(party) do
                        if member and member:isAlive() and member:getZoneID() == master:getZoneID() then
                            local hpp = member:getHP() * 100 / math.max(1, member:getMaxHP())
                            if hpp < lowestHpp then healTarget = member; lowestHpp = hpp end
                        end
                    end
                end

                if lowestHpp <= CONFIG.healHpp then
                    local range = rdef.healPower or { CONFIG.healMin, CONFIG.healMax }
                    local amount = math.max(CONFIG.healMin, scaledRoleValue(master, range))
                    if getRole(master) == 'mastered' then amount = math.floor(amount * 0.7) end
                    healTarget:addHP(amount)
                    p:setLocalVar('fellowHealAt', now)
                end
            end

            if hasBeh('heal') and master:isEngaged()
               and now - (p:getLocalVar('fellowCleanseAt') or 0) >= CONFIG.cleanseCooldownSec then
                local removable =
                {
                    xi.effect.POISON, xi.effect.PARALYSIS, xi.effect.BLINDNESS,
                    xi.effect.SILENCE, xi.effect.CURSE_I, xi.effect.DISEASE,
                    xi.effect.PLAGUE,
                }

                local cleanseTargets = { master }
                local okParty, party = pcall(function() return master:getPartyWithTrusts() end)
                if okParty and party then cleanseTargets = party end

                local removed = false
                for _, member in pairs(cleanseTargets) do
                    if member and member:isAlive() and member:getZoneID() == master:getZoneID() then
                        for _, effect in ipairs(removable) do
                            if member:hasStatusEffect(effect) then
                                member:delStatusEffect(effect)
                                p:setLocalVar('fellowCleanseAt', now)
                                removed = true
                                break
                            end
                        end
                    end
                    if removed then break end
                end
            end

            -- Bulwark adds steady hate but never drains the player's enmity, so
            -- sufficiently active/high-damage players can still pull hate.
            if hasBeh('tank') and master:isEngaged()
               and now - (p:getLocalVar('fellowTauntAt') or 0) >= CONFIG.tauntCooldownSec then
                local tgt = master:getTarget()
                if tgt and not tgt:isDead() and p:isEngaged() then
                    pcall(function()
                        local ce = lerp(CONFIG.tauntMinCE, CONFIG.tauntMaxCE, combatProgress(master))
                        local ve = lerp(CONFIG.tauntMinVE, CONFIG.tauntMaxVE, combatProgress(master))
                        if getRole(master) == 'mastered' then ce = math.floor(ce * 0.6); ve = math.floor(ve * 0.6) end
                        tgt:addEnmity(p, ce, ve)
                        p:setLocalVar('fellowTauntAt', now)
                    end)
                end
            end

            -- Combat: every role fights (assist when idle, Ready at TP cap).
            -- CLAIM FIX (2026-07-12): reports of "lose claim when my Fellow attacks"
            -- in Ambuscade. Old code only re-claimed when master:isEngaged(); if the
            -- Fellow (Bulwark) taunted/hit a wave mob first, or the mob's highest
            -- enmity flipped from master to Fellow mid-fight, the client would show
            -- the mob as "not yours" until master hit again. Now: assert master
            -- ownership on BOTH targets (master's + Fellow's) every tick regardless
            -- of master's engaged state, so as long as the Fellow is out, whatever
            -- it's fighting is claimed to the master.
            local mtgt = master:getTarget()
            local ptgt = p:getTarget()
            local function forceClaim(t)
                if not t or t:isDead() then return end
                pcall(function() t:updateClaim(master) end)
            end
            -- [FellowDbg] toggle with `!setplayervar FellowExpDbg 1` (0 to stop).
            -- Logged BEFORE the claim force, so it shows the NATURAL state.
            if master:getCharVar('FellowExpDbg') == 1 then
                local dbgTgt = mtgt or ptgt
                if dbgTgt and not dbgTgt:isDead() then
                    pcall(function()
                        if not master:hasClaim(dbgTgt) then
                            master:printToPlayer(string.format(
                                '[FellowDbg] you do NOT own %s (mobLv%d, you Lv%d, pet Lv%d) -- forcing claim',
                                dbgTgt:getName(), dbgTgt:getMainLvl() or 0, master:getMainLvl() or 0, p:getMainLvl() or 0),
                                xi.msg.channel.SYSTEM_3)
                        end
                    end)
                end
            end
            forceClaim(mtgt)
            if ptgt and ptgt ~= mtgt then forceClaim(ptgt) end
            local combatTarget = ptgt or mtgt
            if p:isEngaged() and combatTarget and not combatTarget:isDead() then
                local tgt = combatTarget
                local pendingAt = p:getLocalVar('fellowMovePendingAt') or 0
                local movePending = pendingAt > 0 and now - pendingAt < 4
                -- Magus uses a visible magical mob skill on its own cadence rather
                -- than invisible takeDamage. This exercises the normal action,
                -- resistance, message and magic-burst systems.
                local magusElement = hasBeh('nuke') and chosenMagusElement(master) or nil
                local burstTier = 0
                if magusElement and xi.magicburst and xi.magicburst.formMagicBurst then
                    burstTier = xi.magicburst.formMagicBurst(tgt, magusElement)
                end
                local burstReady = burstTier > 0

                if hasBeh('nuke') and p:isEngaged() and tgt and not tgt:isDead()
                   and not movePending
                   and p:canUseAbilities()
                   and now - (p:getLocalVar('fellowNukeAt') or 0) >=
                       (burstReady and CONFIG.burstCooldownSec or CONFIG.nukeCooldownSec) then
                    local spellMove = chosenWs(master)
                    if spellMove and spellMove > 0 then
                        p:setLocalVar(
                            'fellowProgressionDamageCap',
                            fellowDamageCap(master, tgt))
                        p:setLocalVar('fellowAoEDamageScale',
                            spellMove == xi.mobSkill.THUNDERSTRIKE and 25 or 0)
                        p:setLocalVar('fellowCanMagicBurst', burstReady and 1 or 0)
                        p:setLocalVar('fellowMovePendingAt', now)
                        p:useMobAbility(spellMove, tgt)
                    end
                end

                -- As a TRUST the Fellow follows the master and engages the
                -- master's target on its own AI (no petAttack needed -- that was
                -- a BST/pet order). We just force its signature role TP move when
                -- it's engaged with capped TP.
                if not hasBeh('nuke') and p:isEngaged() and p:getTP() >= CONFIG.autoReadyTP
                   and not movePending
                   and p:canUseAbilities()
                   and now - (p:getLocalVar('fellowWsAt') or 0) >= CONFIG.wsCooldownSec then
                    local ws = chosenWs(master)
                    if ws and ws > 0 and tgt and not tgt:isDead() then
                        -- Every role is constrained by the same composite
                        -- Fellow/master progression curve, including at 99.
                        p:setLocalVar(
                            'fellowProgressionDamageCap',
                            fellowDamageCap(master, tgt))
                        p:setLocalVar('fellowAoEDamageScale', 0)

                        if rdef.wsDamage then
                            local normalDmg = normalWeaponDamage(master)
                            p:setDamage(math.max(normalDmg, scaledRoleValue(master, rdef.wsDamage)))
                            p:timer(2500, function(pp)
                                if pp and pp:isAlive() then pp:setDamage(normalDmg) end
                            end)
                        end
                        if rdef.magicDamageByMove and rdef.magicDamageByMove[ws] then
                            local normalMagicDamage = p:getMod(xi.mod.MAGIC_DAMAGE)
                            p:setMod(xi.mod.MAGIC_DAMAGE,
                                math.floor(rdef.magicDamageByMove[ws] * fellowPowerProgress(master)))
                            p:timer(2500, function(pp)
                                if pp and pp:isAlive() then
                                    pp:setMod(xi.mod.MAGIC_DAMAGE, normalMagicDamage)
                                end
                            end)
                        end
                        p:setLocalVar('fellowMovePendingAt', now)
                        p:useMobAbility(ws, tgt)  -- completion listener consumes TP and starts cooldown
                    end
                end
                -- NOTE (fix): Magus/Hunter formerly added silent per-tick damage via
                -- bare tgt:takeDamage(). That bypasses the action system entirely, so
                -- it produced NO "hits for X" message, AND at 1500+/tick of flat,
                -- defense-ignoring damage it one-shot weak mobs the instant the master
                -- engaged -- before the player (or the Fellow's own melee) could land a
                -- blow, leaving only the "defeats" line and a "cannot attack" error.
                -- Removed: every role now fights VISIBLY through melee (petAttack) + its
                -- signature TP move (useMobAbility, above). Magus/Hunter stay distinct
                -- via their stat block + elemental/physical signature move. Real per-tick
                -- magic/ranged is a Phase-2 job, done through proper VISIBLE casts
                -- (pet:castSpell / a ranged mob skill), not bare takeDamage.
            end
        end)
        scheduleCombatLoop(master, p)
    end)
end

-- The Fellow runs as a TRUST (party ally), NOT a pet, so it coexists with a real
-- job pet. entityIsFellow flags the live trust; getFellowTrust finds it among the
-- player's party-with-trusts (nil if none out).
local function entityIsFellow(e)
    return e ~= nil and e:getLocalVar('fellowApplied') == 1
end
local function getFellowTrust(p)
    local ok, party = pcall(function() return p:getPartyWithTrusts() end)
    if not ok or not party then return nil end
    for _, member in pairs(party) do
        -- Per-member pcall: a despawning trust can sit in the party snapshot
        -- with an already-invalidated base pointer (the 03:20:41 getLocalVar
        -- "dead/null entity" warn). Probe it inside a pcall and skip on any
        -- error instead of letting one corpse abort the whole scan.
        local okM, isFellow = pcall(function()
            return member ~= nil
                and member:getObjType() == xi.objType.TRUST
                and entityIsFellow(member)
        end)
        if okM and isFellow then
            return member
        end
    end
    return nil
end
local function hasFellowOut(p) return getFellowTrust(p) ~= nil end

-- ════════════════════════════ Summon / keeper ═══════════════════════════════
local genByName = {}

local function canChangeFellow(player)
    if player:isEngaged() or player:hasEnmity() then
        player:printToPlayer('[Fellow] You cannot summon or change modes while engaged or carrying enmity.', SYS)
        return false
    end
    return true
end

-- Keeper: completes an explicit summon request and maintains its safety checks.
-- It never recreates a Fellow after death, despawn, or zoning.
local function keeper(p, name, gen)
    if not p or genByName[name] ~= gen then return end

    -- TEARDOWN GUARD (2026-07-17 crash fix): when the master logs out, queued
    -- keeper timers still fire against the PChar mid-teardown. The guarded C++
    -- bindings survive that (they warn and return nil) but spawnTrust into a
    -- half-freed party ACCESS_VIOLATIONs (see dmp/xi_map.exe_17-7_3-20-41).
    -- getZone() is nil-guarded engine-side, so nil == teardown: bail WITHOUT
    -- re-arming. onGameIn re-arms the keeper on the next login/zone-in.
    local okZ, zone = pcall(function() return p:getZone() end)
    if not okZ or zone == nil then return end

    if getN(p, V.active) ~= 1 then return end

    -- Raw spawnTrust bypasses xi.trust.canCast(), so enforce the same zone rule
    -- here as normal trusts. Never let the keeper smuggle a Fellow into
    -- solo/no-trust content.
    if not p:canUseMisc(xi.zoneMisc.TRUST) then
        setN(p, V.active, 0)
        p:setLocalVar('fellowSummonPending', 0)
        return
    end

    -- Complete only a pending player-requested summon. A trust does not use the
    -- pet slot, so this never conflicts with a job pet. spawnTrust is a raw
    -- spawn; applyFellow overlays the model/name/stats.
    if not hasFellowOut(p) then
        local pending = p:getLocalVar('fellowSummonPending') == 1
        if pending then
            if p:isEngaged() or p:hasEnmity() then
                setN(p, V.active, 0)
                p:setLocalVar('fellowSummonPending', 0)
                return
            end

            pcall(function()
                -- Naji normally installs a NOT_HAS_TOP_ENMITY Provoke gambit in
                -- onMobSpawn. Mark only this synchronous raw spawn so the base
                -- script leaves role behavior to applyFellow().
                p:setLocalVar('fellowTrustSpawn', 1)
                local spawned, trust = pcall(function()
                    return p:spawnTrust(CONFIG.baseTrustId)
                end)
                p:setLocalVar('fellowTrustSpawn', 0)

                if spawned and trust then
                    p:setLocalVar('fellowSummonPending', 0)
                    applyFellow(p, trust)
                end
            end)
        else
            -- Never recreate a defeated/despawned Fellow automatically.
            setN(p, V.active, 0)
            return
        end
    end

    p:timer(CONFIG.keeperMs, function(pp) keeper(pp, name, gen) end)
end

local function armKeeper(p, delayMs)
    local name = p:getName()
    local gen  = (genByName[name] or 0) + 1
    genByName[name] = gen
    p:timer(delayMs or CONFIG.firstMs, function(pp) keeper(pp, name, gen) end)
end

local function summon(p)
    ensureBorn(p)
    if hasFellowOut(p) or getN(p, V.active) == 1 then
        p:printToPlayer('[Fellow] Your Fellow is already active.', SYS)
        return
    end
    if not canChangeFellow(p) then return end
    if not p:canUseMisc(xi.zoneMisc.TRUST) then
        p:printToPlayer('[Fellow] Adventuring Fellows cannot be called in areas where trusts are restricted.', SYS)
        return
    end
    local remaining = CONFIG.summonCooldownSec -
        (os.time() - (p:getLocalVar(SUMMONED_AT_LOCAL_VAR) or 0))
    if remaining > 0 then
        p:printToPlayer(string.format('[Fellow] Your Fellow needs %d more second(s) before another summon.', remaining), SYS)
        return
    end
    setN(p, V.active, 1)
    p:setLocalVar(SUMMONED_AT_LOCAL_VAR, os.time())
    p:setLocalVar('fellowSummonPending', 1)
    -- No "dismiss your pet first" -- the Fellow is a trust now and coexists
    -- with any job pet.
    armKeeper(p, 30)
    p:printToPlayer('[Fellow] Your Adventuring Fellow heeds the call.', SYS)
end

local function dismiss(p)
    setN(p, V.active, 0)
    p:setLocalVar('fellowSummonPending', 0)
    genByName[p:getName()] = (genByName[p:getName()] or 0) + 1
    local trust = getFellowTrust(p)
    if trust then
        pcall(function() p:despawnTrust(trust) end)  -- despawns ONLY the Fellow, not real trusts
    end
    p:printToPlayer('[Fellow] Your Adventuring Fellow returns to rest.', SYS)
end

-- Re-spawn the live Fellow now (used after an appearance change). No-op if not out.
local function respawnIfOut(p)
    if getN(p, V.active) ~= 1 then return end
    local trust = getFellowTrust(p)
    if trust then
        pcall(function() p:despawnTrust(trust) end)
    end
    p:setLocalVar('fellowSummonPending', 1)
    armKeeper(p, 700)  -- keeper re-spawns the new chassis shortly
end

-- ════════════════════════════════ Respec ════════════════════════════════════
-- Reset penalty: on a stats reset you get back the pool of allocated points
-- MINUS this percent (rounded DOWN, so tiny builds lose nothing). Discourages
-- constant flip-flopping without punishing an honest rebuild too hard.
local RESET_PENALTY_PCT = 10

local function totalAllocated(p)
    local t = 0
    for _, stat in ipairs(CONFIG.statOrder) do t = t + getStatPts(p, stat) end
    return t
end

-- Sum the points currently allocated across a list of stats, and how many of
-- them actually carry points (for messaging).
local function sumStats(p, stats)
    local total, touched = 0, 0
    for _, stat in ipairs(stats) do
        local pts = getStatPts(p, stat)
        if pts > 0 then total = total + pts; touched = touched + 1 end
    end
    return total, touched
end

-- Preview (total, lost, refund) for resetting a given stat list. The penalty is
-- always applied to the COMBINED total, never per-stat -- that's deliberate:
-- flooring 10% per stat would let a player reset small stats one at a time and
-- dodge the penalty (floor(9*0.1)=0). Batching the selection closes that.
local function resetPreviewList(p, stats)
    local total = sumStats(p, stats)
    local lost  = math.floor(total * RESET_PENALTY_PCT / 100)
    return total, lost, total - lost
end

-- Full-reset preview (all categories) -- used by the "Reset ALL" confirm.
local function resetPreview(p) return resetPreviewList(p, CONFIG.statOrder) end

-- Respec core: pool the points from `stats` back into the unspent pool, minus
-- the reset penalty on the combined total. Zeroing the Fellow_<stat> charVars +
-- a respawn makes applyFellow recompute ALL mods from scratch -- the only correct
-- path (liveAddStat has no inverse). Points BOUGHT with gil are refunded like any
-- other, minus the same penalty; gil itself is never returned.
local function resetStatsList(p, stats)
    local total, touched, lost, refund = sumStats(p, stats)
    lost   = math.floor(total * RESET_PENALTY_PCT / 100)
    refund = total - lost
    if total <= 0 then
        p:printToPlayer('[Fellow] No allocated points to reset there.', SYS)
        return
    end
    for _, stat in ipairs(stats) do setN(p, statVar(stat), 0) end
    setN(p, V.points, getPoints(p) + refund)
    respawnIfOut(p)  -- fresh applyFellow rebuilds every mod from the zeroed stats
    p:printToPlayer(string.format(
        '[Fellow] Reset %d categor%s -- refunded %d of %d points (%d%% penalty, -%d). Unspent: %d.',
        touched, (touched == 1 and 'y' or 'ies'), refund, total, RESET_PENALTY_PCT, lost, getPoints(p)), SYS)
end

-- Full reset (every category).
local function resetStats(p) resetStatsList(p, CONFIG.statOrder) end

-- Transient per-player selection for the "Choose Categories" reset. Keyed by
-- player name; holds a set { [stat] = true }. Cleared on Apply / Back.
local resetSel = {}
local function selSet(p)   local k = p:getName(); resetSel[k] = resetSel[k] or {}; return resetSel[k] end
local function selClear(p) resetSel[p:getName()] = nil end

-- ════════════════════════════════ XP / levels ═══════════════════════════════
local function addXp(p, amount)
    if amount <= 0 then return end
    local lvl     = getLevel(p)
    local xp      = getN(p, V.xp) + amount
    local gained  = 0
    while lvl < CONFIG.maxLevel and xp >= xpToNext(lvl) do
        xp  = xp - xpToNext(lvl)
        lvl = lvl + 1
        gained = gained + CONFIG.pointsPerLevel
    end
    setN(p, V.level, lvl)
    setN(p, V.xp, (lvl >= CONFIG.maxLevel) and 0 or xp)
    if gained > 0 then
        setN(p, V.points, getPoints(p) + gained)
        p:printToPlayer(string.format(
            '[Fellow] Your Fellow reached level %d! +%d points to spend (%d unspent).',
            lvl, gained, getPoints(p)), SYS)
    end
end

-- ════════════════════════════════ Status ════════════════════════════════════
local function statusReport(p)
    ensureBorn(p)
    local lvl  = getLevel(p)
    local role = roleDef(p)
    local nm   = chosenName(p) or '(unnamed)'
    local outfitEntry = CONFIG.outfits[getN(p, V.outfit)]
    local mdl         = CONFIG.models[getN(p, V.modelPet)]
    local lookName    = (outfitEntry and outfitEntry.name) or (mdl and mdl.name) or 'Moogle'
    p:printToPlayer(string.format('=== %s ===  Lv.%d %s  (%s)',
        nm, lvl, role.name, lookName), SYS)
    local grade = currentGrade(p)
    p:printToPlayer(string.format('  Grade: %s   |   Upgrade target: %s TP move/spell',
        grade.name, grade.damage), SYS)
    if lvl < CONFIG.maxLevel then
        p:printToPlayer(string.format('  XP: %d / %d to next level   |   Unspent points: %d',
            getN(p, V.xp), xpToNext(lvl), getPoints(p)), SYS)
    else
        p:printToPlayer(string.format('  Level MAX   |   Unspent points: %d', getPoints(p)), SYS)
    end
    local parts = {}
    for _, stat in ipairs(CONFIG.statOrder) do
        local v = getStatPts(p, stat)
        if v > 0 then parts[#parts + 1] = string.format('%s %d', stat, v) end
    end
    p:printToPlayer('  Allocation: ' .. (#parts > 0 and table.concat(parts, '  ') or 'none yet'), SYS)
    -- Mastery progress: how many of the 14 categories are at the cap. At 14/14 the
    -- Mastered role is available in Choose Role (a prestige flex; see checkMasteredUnlock).
    local capped = 0
    for _, stat in ipairs(CONFIG.statOrder) do
        if getStatPts(p, stat) >= CONFIG.statCap then capped = capped + 1 end
    end
    if capped >= #CONFIG.statOrder then
        p:printToPlayer('  Mastery: 14/14 capped -- MASTERED role UNLOCKED (set it in Choose Role).', SYS)
    else
        p:printToPlayer(string.format('  Mastery: %d/%d categories capped (all 14 unlocks the Mastered role).',
            capped, #CONFIG.statOrder), SYS)
    end
    -- TP move in effect for the current role (per-role override, else role default).
    local roleKey  = getRole(p)
    local tpChoice  = getN(p, tpVar(roleKey))
    local roleMoves = (CONFIG.roles[roleKey] or {}).moves or {}
    local tpName    = (tpChoice > 0 and roleMoves[tpChoice] and roleMoves[tpChoice].name)
        or '(role default)'
    p:printToPlayer(string.format('  TP move (%s): %s', role.name, tpName), SYS)
end

-- Off-role guidance: some allocatable stats only pay off for a matching Role, so
-- pumping them elsewhere reads as "does nothing". Magic offense (INT/Sorcery) is
-- only used by the Magus (the sole casting Role); physical offense (STR/Ferocity/
-- Frenzy/Onslaught) is wasted on the Magus (it nukes, barely melees). DEX/AGI/VIT/
-- MND/Warding help every Role (accuracy / survival) so they are never flagged.
local STAT_SCHOOL =
{
    INT = 'magic', Sorcery = 'magic',
    STR = 'phys', Ferocity = 'phys', Frenzy = 'phys', Onslaught = 'phys',
}
-- Roles whose damage scales off MATT/MACC (magical WS and/or nuke behaviour), so
-- their magic stats are NOT off-role. The Oracle heals AND fires magical WS
-- (Divine Judgment / Empty Salvation / Cursed Sphere), which scale off MATT that
-- Sorcery/INT feed -- the old "magus-only" test wrongly flagged Sorcery on an
-- Oracle even though it visibly boosted its damage (report: Spyro 2026-07-08).
local MAGIC_ROLES = { magus = true, oracle = true, mastered = true }
local function offRoleReason(roleKey, stat)
    if roleKey == 'mastered' then return nil end  -- Mastered uses every stat; nothing is off-role
    local school = STAT_SCHOOL[stat]
    if not school then return nil end
    local isCaster = MAGIC_ROLES[roleKey] == true
    if school == 'magic' and not isCaster then
        return 'a magic stat; only casting Roles (Magus / Oracle) use it'
    elseif school == 'phys' and roleKey == 'magus' then
        -- Only the pure-nuke Magus barely melees; the Oracle still auto-attacks,
        -- so physical stats are NOT off-role for it.
        return 'a melee stat; your Magus deals magic damage, not melee'
    end
    return nil
end

-- ════════════════════════════════ Mastery unlock ════════════════════════════
-- Fire once, the moment a player first caps all 14 categories: flag it (so it never
-- repeats), tell the player, and broadcast the flex server-wide. Called after every
-- allocation. Selecting the Mastered role itself is done in the Choose Role menu,
-- which surfaces it whenever isMastered() is true (this is purely the announcement).
local function checkMasteredUnlock(p)
    if not isMastered(p) or getN(p, V.mastered) == 1 then return end
    setN(p, V.mastered, 1)
    p:printToPlayer('[Fellow] *** MASTERY ACHIEVED! *** Every category is capped. The Mastered role is now available in Choose Role.', SYS)
    -- Best-effort server-wide shout (same pattern as the Hunters Guild rank broadcast).
    pcall(function()
        p:PrintToArea(string.format(
            '%s has mastered their Adventuring Fellow, kupo! Every stat forged to the limit!', p:getName()),
            xi.msg.channel.SYSTEM_3, xi.msg.area.SYSTEM)
    end)
end

-- ════════════════════════════════ Menus ═════════════════════════════════════
local openMain, openCommandMain, openProgress, openAllocate, openAllocateStat, openRole, openName, openModel, openOutfit, openTpMove, openBuyPoints
local openResetMenu, openResetConfirm, openResetCategory
local roleMenuContext = {}

local function show(p, title, options)
    local snapshot = { title = title, options = options }
    p:timer(30, function(pp) pp:customMenu(snapshot) end)
end

openMain = function(p)
    ensureBorn(p)
    local lvl = getLevel(p)
    roleMenuContext[p:getName()] = 'upgrade'
    local options =
    {
        { string.format('Allocate Points (%d)', getPoints(p)), function(pp) openAllocate(pp) end },
        { 'Upgrade Path', function(pp) openProgress(pp) end },
        { 'Choose Role',  function(pp) openRole(pp) end },
        { 'Name',         function(pp) openName(pp) end },
        { 'Appearance',   function(pp) openModel(pp, 0) end },
        { 'Outfit',       function(pp) openOutfit(pp, 0) end },
        { 'View Status',  function(pp) statusReport(pp); openMain(pp) end },
        { 'Close',        function(pp) end },
    }
    show(p, string.format('Fellow Officer  Lv.%d', lvl), options)
end

openCommandMain = function(p)
    ensureBorn(p)
    roleMenuContext[p:getName()] = 'command'
    local out = getN(p, V.active) == 1
    show(p, string.format('Fellow  Lv.%d', getLevel(p)),
    {
        { out and 'Dismiss Fellow' or 'Summon Fellow',
          function(pp) if getN(pp, V.active) == 1 then dismiss(pp) else summon(pp) end end },
        { 'Choose Mode', function(pp) openRole(pp) end },
        { 'Close', function(pp) end },
    })
end

openProgress = function(p)
    ensureBorn(p)
    local grade = currentGrade(p)
    local nextGrade
    for _, candidate in ipairs(GRADES) do
        if getLevel(p) < candidate.level or allocatedTotal(p) < candidate.points then
            nextGrade = candidate
            break
        end
    end
    p:printToPlayer(string.format('[Fellow] Grade: %s | Lv%d | %d/1400 allocated | target %s.',
        grade.name, getLevel(p), allocatedTotal(p), grade.damage), SYS)
    if nextGrade then
        p:printToPlayer(string.format('[Fellow] Next: %s -- Lv%d and %d allocated points (target %s).',
            nextGrade.name, nextGrade.level, nextGrade.points, nextGrade.damage), SYS)
    else
        p:printToPlayer('[Fellow] Maximum grade achieved. Every stat track is capped.', SYS)
    end
    show(p, 'Upgrade Path',
    {
        { 'Allocate Points', function(pp) openAllocate(pp, 0) end },
        { 'View Status', function(pp) statusReport(pp); openProgress(pp) end },
        { 'Back', function(pp) openMain(pp) end },
    })
end

openAllocate = function(p, page)
    local pts   = getPoints(p)
    local atMax = getLevel(p) >= CONFIG.maxLevel
    -- At max level you can buy points, so let players in even with 0 unspent.
    if pts <= 0 and not atMax then
        p:printToPlayer('[Fellow] No unspent points. Defeat foes with your Fellow out to earn more.', SYS)
        openMain(p)
        return
    end
    page = page or 0
    local order = CONFIG.statOrder
    -- Keep each page within the 8-option customMenu cap. Fixed rows below the
    -- stats: [More>>]? + [Buy Points]? (max level) + Reset Points + Back. So the
    -- stat slots are capped at 4 (max level: +Buy) / 5 (otherwise).
    local per   = atMax and 4 or 5
    local pages = math.max(1, math.ceil(#order / per))
    page = page % pages
    local roleKey = getRole(p)
    local options = {}
    local anyOff  = false
    for i = page * per + 1, math.min((page + 1) * per, #order) do
        local s      = order[i]
        local reason = offRoleReason(roleKey, s)
        if reason then anyOff = true end
        -- Clicking a stat now opens its quantity picker (+1/+5/.../Max) instead
        -- of adding a single point, so bulk allocation is one or two clicks.
        options[#options + 1] =
        {
            string.format('%s (%d)%s', s, getStatPts(p, s), reason and ' *' or ''),
            function(pp) openAllocateStat(pp, s, page) end,
        }
    end
    if pages > 1 then
        options[#options + 1] = { 'More >>', function(pp) openAllocate(pp, page + 1) end }
    end
    if atMax then
        options[#options + 1] = { 'Buy Points', function(pp) openBuyPoints(pp) end }
    end
    options[#options + 1] = { 'Reset Points', function(pp) openResetMenu(pp) end }
    options[#options + 1] = { 'Back', function(pp) openMain(pp) end }
    show(p, string.format('Allocate (%d left)%s', pts, anyOff and '  (*=off-role)' or ''), options)
end

-- Per-stat quantity picker: choose HOW MANY points to pour into one stat at once
-- (CONFIG.allocSteps + "Max"). Each amount is clamped to what you can afford and
-- the stat's headroom to the cap, so a big step never overspends or overflows.
openAllocateStat = function(p, stat, backPage)
    local roleKey = getRole(p)
    local reason  = offRoleReason(roleKey, stat)

    local function applyN(pp, n)
        n = math.min(n, getPoints(pp), CONFIG.statCap - getStatPts(pp, stat))
        if n <= 0 then
            if getPoints(pp) <= 0 then
                pp:printToPlayer('[Fellow] No unspent points.', SYS)
            else
                pp:printToPlayer(string.format('[Fellow] %s is at the cap (%d).', stat, CONFIG.statCap), SYS)
            end
            openAllocateStat(pp, stat, backPage); return
        end
        setN(pp, V.points, getPoints(pp) - n)
        setN(pp, statVar(stat), getStatPts(pp, stat) + n)
        respawnIfOut(pp)
        pp:printToPlayer(string.format('[Fellow] %s +%d -> %d. (%d points left)',
            stat, n, getStatPts(pp, stat), getPoints(pp)), SYS)
        checkMasteredUnlock(pp)  -- fires the one-time Mastery unlock if this filled the last cap
        if reason then
            pp:printToPlayer(string.format('[Fellow] Heads up: %s is OFF-ROLE for your %s -- %s.',
                stat, (CONFIG.roles[roleKey] or {}).name or roleKey, reason), SYS)
        end
        openAllocateStat(pp, stat, backPage)
    end

    local options = {}
    for _, step in ipairs(CONFIG.allocSteps) do
        local n = step
        options[#options + 1] = { string.format('+%d', n), function(pp) applyN(pp, n) end }
    end
    -- "Max" = spend every remaining point into this stat, up to its cap.
    options[#options + 1] =
    {
        'Max',
        function(pp) applyN(pp, math.min(getPoints(pp), CONFIG.statCap - getStatPts(pp, stat))) end,
    }
    options[#options + 1] = { 'Back', function(pp) openAllocate(pp, backPage) end }

    show(p, string.format('%s %d  (avail %d / cap %d)%s',
        stat, getStatPts(p, stat), getPoints(p), CONFIG.statCap, reason and '  *off-role' or ''), options)
end

-- Post-cap gil -> points exchange. Only reachable from openAllocate at max level.
openBuyPoints = function(p)
    local cost    = CONFIG.buyPointsCost
    local bundles = { 1, 10, 50, 100 }
    local options = {}
    local headroom = CONFIG.statCap * #CONFIG.statOrder - totalAllocated(p) - getPoints(p)
    for _, n in ipairs(bundles) do
        local qty   = math.min(n, math.max(0, headroom))
        local price = cost * qty
        if qty > 0 then options[#options + 1] =
        {
            string.format('Buy %d (%dg)', qty, price),
            function(pp)
                if pp:getGil() < price then
                    pp:printToPlayer(string.format('[Fellow] Need %d gil (have %d).', price, pp:getGil()), SYS)
                    openBuyPoints(pp); return
                end
                pp:delGil(price)
                setN(pp, V.points, getPoints(pp) + qty)
                pp:printToPlayer(string.format('[Fellow] Bought %d point(s) for %d gil. Unspent: %d.',
                    qty, price, getPoints(pp)), SYS)
                openBuyPoints(pp)
            end,
        } end
    end
    options[#options + 1] = { 'Spend Points', function(pp) openAllocate(pp, 0) end }
    options[#options + 1] = { 'Back',         function(pp) openMain(pp) end }
    show(p, string.format('Buy Points (have %dg)', p:getGil()), options)
end

-- Reset hub: pick between wiping EVERYTHING or choosing specific categories.
openResetMenu = function(p)
    local total = totalAllocated(p)
    if total <= 0 then
        p:printToPlayer('[Fellow] No allocated points to reset.', SYS)
        openAllocate(p, 0)
        return
    end
    selClear(p)  -- start each visit with a clean category selection
    local _, lost, refund = resetPreview(p)
    local options =
    {
        { string.format('Reset ALL (refund %d, -%d)', refund, lost), function(pp) openResetConfirm(pp) end },
        { 'Choose Categories',                                       function(pp) openResetCategory(pp, 0) end },
        { 'Back',                                                    function(pp) openAllocate(pp, 0) end },
    }
    show(p, string.format('Reset -- %d points allocated', total), options)
end

-- Confirm gate for a FULL reset. Shows the exact refund/loss so a misclick can't
-- silently nuke a hand-tuned build.
openResetConfirm = function(p)
    local total, lost, refund = resetPreview(p)
    if total <= 0 then
        p:printToPlayer('[Fellow] No allocated points to reset.', SYS)
        openAllocate(p, 0)
        return
    end
    local options =
    {
        { string.format('YES -- refund %d (lose %d)', refund, lost),
          function(pp) resetStats(pp); openAllocate(pp, 0) end },
        { 'NO -- keep my build', function(pp) openResetMenu(pp) end },
    }
    show(p, string.format('Reset ALL %d points?  -%d%% (-%d)', total, RESET_PENALTY_PCT, lost), options)
end

-- Category picker: tap stats to select (marked '*'), then Apply to reset just
-- those. The 10%% penalty is charged on the selected total (see resetStatsList),
-- so batching a selection is how the penalty is meant to be paid -- you can't
-- reset one small stat at a time to floor it away. Only stats that actually have
-- points are listed. per=4 keeps the page under the 8-option / 150-byte caps.
openResetCategory = function(p, page)
    local allocated = {}
    for _, stat in ipairs(CONFIG.statOrder) do
        if getStatPts(p, stat) > 0 then allocated[#allocated + 1] = stat end
    end
    if #allocated == 0 then
        p:printToPlayer('[Fellow] No allocated categories to reset.', SYS)
        selClear(p); openAllocate(p, 0)
        return
    end

    local sel   = selSet(p)
    local per   = 4
    local pages = math.max(1, math.ceil(#allocated / per))
    page = page % pages

    local options = {}
    for i = page * per + 1, math.min((page + 1) * per, #allocated) do
        local stat = allocated[i]
        options[#options + 1] =
        {
            string.format('%s%s %d', sel[stat] and '* ' or '', stat, getStatPts(p, stat)),
            function(pp)
                local s = selSet(pp)
                s[stat] = (not s[stat]) or nil  -- toggle
                openResetCategory(pp, page)
            end,
        }
    end
    if pages > 1 then
        options[#options + 1] = { 'More >>', function(pp) openResetCategory(pp, page + 1) end }
    end

    -- Selected list + total (only stats that still have points).
    local selList, selTotal = {}, 0
    for _, stat in ipairs(CONFIG.statOrder) do
        if sel[stat] and getStatPts(p, stat) > 0 then
            selList[#selList + 1] = stat
            selTotal = selTotal + getStatPts(p, stat)
        end
    end
    if selTotal > 0 then
        local lost = math.floor(selTotal * RESET_PENALTY_PCT / 100)
        options[#options + 1] =
        {
            string.format('Apply -%d%% (refund %d)', RESET_PENALTY_PCT, selTotal - lost),
            function(pp) resetStatsList(pp, selList); selClear(pp); openAllocate(pp, 0) end,
        }
    end
    options[#options + 1] = { 'Back', function(pp) selClear(pp); openAllocate(pp, 0) end }

    show(p, string.format('Reset which? (%d sel)', #selList), options)
end

openRole = function(p, page)
    page = page or 0
    local cur = getRole(p)
    -- Visible roles = the 6 base roles, PLUS Mastered appended only once unlocked
    -- (all 14 capped). 'mastered' is skipped in the base pass so it never shows early.
    local vis = {}
    for i, key in ipairs(CONFIG.roleOrder) do
        if key ~= 'mastered' then vis[#vis + 1] = { idx = i, key = key } end
    end
    if isMastered(p) then
        for i, key in ipairs(CONFIG.roleOrder) do
            if key == 'mastered' then vis[#vis + 1] = { idx = i, key = key }; break end
        end
    end
    -- 6 roles fit on one page (6 + SetTP + Back = 8). With Mastered unlocked (7) we
    -- paginate at 5/page so [More>>] + Set TP Move + Back still fit the 8-option cap.
    local paged = #vis > 6
    local per   = paged and 5 or #vis
    local pages = math.max(1, math.ceil(#vis / per))
    page = page % pages
    local options = {}
    for i = page * per + 1, math.min((page + 1) * per, #vis) do
        local e     = vis[i]
        local r     = CONFIG.roles[e.key]
        local label = (e.key == cur) and (r.name .. ' *') or r.name
        options[#options + 1] =
        {
            label,
            function(pp)
                if not canChangeFellow(pp) then
                    openRole(pp, page)
                    return
                end
                setN(pp, V.role, e.idx)
                respawnIfOut(pp)
                pp:printToPlayer(string.format('[Fellow] Mode set: %s -- %s',
                    r.name, r.blurb), SYS)
                openRole(pp, page)
            end,
        }
    end
    if paged then
        options[#options + 1] = { 'More >>', function(pp) openRole(pp, page + 1) end }
    end
    -- TP move is configured PER ROLE; edit the current role's move here.
    options[#options + 1] = { 'Set TP Move', function(pp) openTpMove(pp, 0) end }
    options[#options + 1] =
    {
        'Back',
        function(pp)
            if roleMenuContext[pp:getName()] == 'command' then openCommandMain(pp) else openMain(pp) end
        end,
    }
    show(p, 'Choose Role', options)
end

-- Preset names are available directly at the Officer; free-text remains
-- available through !fellowname because the client menu has no text input.
openName = function(p, page)
    page = page or 0
    local per = 5
    local pages = math.max(1, math.ceil(#CONFIG.names / per))
    page = page % pages
    local custom = FN.read(p)
    local selected = getN(p, V.nameIdx)
    local options = {}
    for i = page * per + 1, math.min((page + 1) * per, #CONFIG.names) do
        local idx, name = i, CONFIG.names[i]
        options[#options + 1] =
        {
            (not custom and selected == idx) and (name .. ' *') or name,
            function(pp)
                FN.clear(pp)
                setN(pp, V.nameIdx, idx)
                local fellow = getFellowTrust(pp)
                if fellow then pcall(function() fellow:renameEntity(name, true) end) end
                pp:printToPlayer(string.format('[Fellow] Name set to "%s".', name), SYS)
                openName(pp, page)
            end,
        }
    end
    if pages > 1 then options[#options + 1] = { 'More >>', function(pp) openName(pp, page + 1) end } end
    options[#options + 1] =
    {
        'Custom name help',
        function(pp)
            pp:printToPlayer('[Fellow] Type !fellowname <name> (letters/spaces, max 15 characters).', SYS)
            openName(pp, page)
        end,
    }
    options[#options + 1] = { 'Back', function(pp) openMain(pp) end }
    show(p, string.format('Name: %s', chosenName(p)), options)
end

-- Paginated appearance picker -> swaps the spawn chassis (petId); re-summon to apply.
openModel = function(p, page)
    page = page or 0
    -- Only list enabled looks. Disabled ones are crash-risk models pending
    -- verification (see CONFIG.models). Keep each look's ORIGINAL index so a
    -- stored Fellow_ModelPet never shifts when the disabled flags change.
    local enabled = {}
    for idx, m in ipairs(CONFIG.models) do
        if not m.disabled then enabled[#enabled + 1] = { idx = idx, name = m.name } end
    end
    local per    = CONFIG.namesPerPage
    local pages  = math.max(1, math.ceil(#enabled / per))
    page = page % pages
    local cur    = getN(p, V.modelPet)
    local options = {}
    for i = page * per + 1, math.min((page + 1) * per, #enabled) do
        local e     = enabled[i]
        local label = (e.idx == cur) and (e.name .. ' *') or e.name
        options[#options + 1] =
        {
            label,
            function(pp)
                setN(pp, V.modelPet, e.idx)
                respawnIfOut(pp)  -- live-swap the chassis if the Fellow is out
                pp:printToPlayer(string.format('[Fellow] Appearance set: %s.', e.name), SYS)
                openModel(pp, page)
            end,
        }
    end
    if pages > 1 then
        options[#options + 1] = { 'More >>', function(pp) openModel(pp, page + 1) end }
    end
    options[#options + 1] = { 'Back', function(pp) openMain(pp) end }
    show(p, 'Appearance', options)
end

-- Paginated outfit picker: humanoid job-class themes that override Appearance.
-- "(None)" at index 0 reverts to the Appearance model; each numbered entry maps
-- to CONFIG.outfits[N]. Re-spawns the Fellow live if it is currently out.
openOutfit = function(p, page)
    page = page or 0
    -- Prepend "(None)" so realIdx 0 = clear outfit; realIdx N = CONFIG.outfits[N].
    local all = { { name = '(None)' } }
    for _, o in ipairs(CONFIG.outfits) do all[#all + 1] = o end
    local per   = CONFIG.namesPerPage
    local pages = math.max(1, math.ceil(#all / per))
    page = page % pages
    local cur   = getN(p, V.outfit)
    local options = {}
    for i = page * per + 1, math.min((page + 1) * per, #all) do
        local idx      = i
        local entry    = all[idx]
        local realIdx  = idx - 1
        local label    = (cur == realIdx) and (entry.name .. ' *') or entry.name
        options[#options + 1] =
        {
            label,
            function(pp)
                setN(pp, V.outfit, realIdx)
                respawnIfOut(pp)
                if realIdx == 0 then
                    pp:printToPlayer('[Fellow] Outfit cleared; using Appearance model.', SYS)
                else
                    pp:printToPlayer(string.format('[Fellow] Outfit: %s.', entry.name), SYS)
                end
                openOutfit(pp, page)
            end,
        }
    end
    if pages > 1 then
        options[#options + 1] = { 'More >>', function(pp) openOutfit(pp, page + 1) end }
    end
    options[#options + 1] = { 'Back', function(pp) openMain(pp) end }
    show(p, 'Choose Outfit', options)
end

-- Paginated TP-move picker for the CURRENT role. "(Default)" at realIdx 0 uses the
-- role's defaultWs; each numbered entry maps to that role's moves[N]. Applies live --
-- the combat loop reads chosenWs() each tick, so no re-summon is needed.
openTpMove = function(p, page)
    page = page or 0
    local roleKey  = getRole(p)
    local roleName = (CONFIG.roles[roleKey] or {}).name or roleKey
    local roleMoves = (CONFIG.roles[roleKey] or {}).moves or {}
    -- Prepend "(Default)" so realIdx 0 = role default; realIdx N = role's moves[N].
    local all = { { name = '(Default)' } }
    for _, t in ipairs(roleMoves) do all[#all + 1] = t end
    local per   = CONFIG.namesPerPage
    local pages = math.max(1, math.ceil(#all / per))
    page = page % pages
    local cur   = getN(p, tpVar(roleKey))
    local options = {}
    for i = page * per + 1, math.min((page + 1) * per, #all) do
        local idx     = i
        local entry   = all[idx]
        local realIdx = idx - 1
        local label   = (cur == realIdx) and (entry.name .. ' *') or entry.name
        options[#options + 1] =
        {
            label,
            function(pp)
                if not canChangeFellow(pp) then
                    openTpMove(pp, page)
                    return
                end
                setN(pp, tpVar(roleKey), realIdx)
                if realIdx == 0 then
                    pp:printToPlayer(string.format('[Fellow] %s TP move: Default.', roleName), SYS)
                else
                    pp:printToPlayer(string.format('[Fellow] %s TP move: %s.', roleName, entry.name), SYS)
                end
                openTpMove(pp, page)
            end,
        }
    end
    if pages > 1 then
        options[#options + 1] = { 'More >>', function(pp) openTpMove(pp, page + 1) end }
    end
    options[#options + 1] = { 'Back', function(pp) openRole(pp) end }
    show(p, string.format('TP Move: %s', roleName), options)
end

-- ════════════════════════════════ Faucet ════════════════════════════════════
m:addOverride('xi.mob.onMobDeathEx', function(mob, player, isKiller, isWeaponSkillKill)
    super(mob, player, isKiller, isWeaponSkillKill)
    pcall(function()
        if player == nil or player:getObjType() ~= xi.objType.PC then return end

        -- [FellowDbg] `player` here IS the mob's resolved PC owner (mobentity OnDeath
        -- passes the owner, or nil when nobody owns it -> in which case this hook never
        -- runs). So seeing this line = the kill WAS credited to you and EXP was paid.
        -- If you kill with the Fellow out and DON'T see it, ownership didn't resolve.
        -- Levels are logged too: a credited kill despite pet Lv>you proves the 10-level
        -- gap is NOT counting the Fellow. Toggle: !setplayervar FellowExpDbg 1
        if player:getCharVar('FellowExpDbg') == 1 and hasFellowOut(player) then
            pcall(function()
                local ft = getFellowTrust(player)
                player:printToPlayer(string.format(
                    '[FellowDbg] kill CREDITED to you: %s (mobLv%d) | you Lv%d, fellowLv%d | isKiller=%s',
                    mob:getName(), mob:getMainLvl() or 0, player:getMainLvl() or 0,
                    (ft and ft:getMainLvl()) or 0, tostring(isKiller)), xi.msg.channel.SYSTEM_3)
            end)
        end

        local mobLvl = mob:getMainLvl() or 1
        local xp     = math.max(CONFIG.xpMin, math.min(CONFIG.xpMax, mobLvl * CONFIG.xpPerMobLevel))

        local function credit(pc)
            if pc and pc:getObjType() == xi.objType.PC
               and getN(pc, V.active) == 1 and hasFellowOut(pc) then
                addXp(pc, xp)
            end
        end

        if isKiller and CONFIG.partyWideXp then
            local zoneId = mob:getZoneID()
            local ok, party = pcall(function() return player:getParty() end)
            if ok and party and #party > 0 then
                for _, mem in ipairs(party) do
                    if mem and mem:getZoneID() == zoneId then credit(mem) end
                end
                return
            end
        end
        if isKiller then credit(player) end
    end)
end)

-- ════════════════════════════════ Login re-arm ══════════════════════════════
m:addOverride('xi.player.onGameIn', function(player, gameLogin, zoning)
    super(player, gameLogin, zoning)
    pcall(function()
        if getN(player, V.born) == 1 then migrateProgression(player) end
        -- Trusts are dismissed by the engine at a zone line. Mirror that
        -- behavior instead of having the keeper silently recreate the Fellow.
        if zoning then
            setN(player, V.active, 0)
            player:setLocalVar('fellowSummonPending', 0)
            player:setLocalVar(SUMMONED_AT_LOCAL_VAR, 0)
        elseif getN(player, V.active) == 1 then
            armKeeper(player, CONFIG.firstMs)
        end
    end)
end)

-- (The 2026-07-12 job-pet auto-yield overrides were REMOVED with the trust
-- conversion -- the Fellow is a trust now, not a pet, so it no longer occupies
-- the pet slot and job pets are never blocked. Nothing to yield.)

-- ════════════════════════════════ Public API ════════════════════════════════
xi.fellow = xi.fellow or {}
xi.fellow.openMenu    = function(p) openCommandMain(p) end
xi.fellow.openUpgradeMenu = function(p) openMain(p) end
xi.fellow.summon      = function(p) summon(p) end
xi.fellow.dismiss     = function(p) dismiss(p) end
xi.fellow.status      = function(p) statusReport(p) end
xi.fellow.getTrust    = function(p) return getFellowTrust(p) end
xi.fellow.addXp       = function(p, n) addXp(p, n) end
xi.fellow.grantPoints = function(p, n) ensureBorn(p); setN(p, V.points, getPoints(p) + math.max(0, n)) end

-- Diagnostic (!fellow debug): dump the LIVE Fellow's ACTUAL mods, read straight off
-- the spawned pet. Spend a point (it applies instantly while the Fellow is out) and
-- re-run to watch the matching number move -- verifiable proof the allocation lands.
xi.fellow.debug = function(p)
    local pet = getFellowTrust(p)
    if not pet then
        p:printToPlayer('[Fellow] Summon your Fellow first -- this reads mods off the live Fellow.', SYS)
        return
    end
    local function m(mod) return pet:getMod(mod) end
    p:printToPlayer('=== Fellow live mods (straight off the spawned pet) ===', SYS)
    p:printToPlayer(string.format('  ATT %d  ACC %d  DEF %d  EVA %d', m(xi.mod.ATT), m(xi.mod.ACC), m(xi.mod.DEF), m(xi.mod.EVA)), SYS)
    p:printToPlayer(string.format('  MATT %d  MACC %d  MDEF %d', m(xi.mod.MATT), m(xi.mod.MACC), m(xi.mod.MDEF)), SYS)
    p:printToPlayer(string.format('  ATK%% %d  Crit %d  DA %d  TA %d  StoreTP %d  HasteGear %d',
        m(xi.mod.ATTP), m(xi.mod.CRITHITRATE), m(xi.mod.DOUBLE_ATTACK), m(xi.mod.TRIPLE_ATTACK), m(xi.mod.STORETP), m(xi.mod.HASTE_GEAR)), SYS)
    p:printToPlayer(string.format('  PDT %d  MDT %d  Regen %d  Refresh %d', m(xi.mod.DMGPHYS), m(xi.mod.DMGMAGIC), m(xi.mod.REGEN), m(xi.mod.REFRESH)), SYS)
    p:printToPlayer(string.format('  STR %d  DEX %d  VIT %d  AGI %d  INT %d  MND %d',
        m(xi.mod.STR), m(xi.mod.DEX), m(xi.mod.VIT), m(xi.mod.AGI), m(xi.mod.INT), m(xi.mod.MND)), SYS)
    p:printToPlayer(string.format('  MaxHP %d   TP %d/3000   Engaged %s   (fires a Ready move at TP>=%d)',
        pet:getMaxHP(), pet:getTP(), tostring(pet:isEngaged()), CONFIG.autoReadyTP), SYS)
end

-- Reverse mod-id -> name for readable audit rows (built once).
local MODNAME = {}
for k, v in pairs(xi.mod) do if type(v) == 'number' then MODNAME[v] = MODNAME[v] or k end end

-- (!fellowaudit) Prove every allocation LANDS on the live pet. For each mod the
-- Fellow build should add, sum the EXPECTED total from every source (per-level,
-- role, survival, and each allocated stat's mods) and compare to the pet's actual
-- getMod. Any row flagged ** LOW ** means that mod isn't fully reaching the entity
-- (a Lua application/clobber bug) -- the direct answer to "does boosting STR
-- actually boost the Fellow?". (Whether the engine then USES a mod is a separate
-- question; see the mods known to be read by mob combat in the audit footer.)
xi.fellow.audit = function(p)
    local pet = getFellowTrust(p)
    if not pet then
        p:printToPlayer('[Fellow] Summon your Fellow first -- the audit reads mods off the live Fellow.', SYS)
        return
    end
    local lvl     = getLevel(p)
    local roleKey = getRole(p)
    local role    = CONFIG.roles[roleKey] or {}

    local expected, source = {}, {}
    local function add(mod, val, src)
        if not mod or val == 0 then return end
        expected[mod] = (expected[mod] or 0) + val
        source[mod]   = source[mod] and (source[mod] .. '+' .. src) or src
    end

    -- Every source applyFellow() adds, mirrored here 1:1.
    local masterPower = fellowPowerProgress(p)
    for _, mv in ipairs(CONFIG.perLevel) do
        add(mv[1], math.floor(mv[2] * lvl * masterPower), 'lvl')
    end
    for _, mv in ipairs(role.mods or {}) do
        add(mv[1], math.floor(mv[2] * masterPower), 'role')
    end
    local surv = role.survival or {}
    add(xi.mod.DMGPHYS,  surv.pdt or CONFIG.pdt, 'role')
    add(xi.mod.DMGMAGIC, surv.mdt or CONFIG.mdt, 'role')
    for stat, mods in pairs(CONFIG.statMods) do
        local pts = getStatPts(p, stat)
        if pts > 0 then
            for _, mv in ipairs(mods) do
                add(mv[1], math.floor(mv[2] * pts * masterPower), stat .. 'x' .. pts)
            end
        end
    end

    local rows = {}
    for mod in pairs(expected) do rows[#rows + 1] = mod end
    table.sort(rows)

    p:printToPlayer(string.format('=== Fellow audit -- Lv%d, role %s -- expected vs LIVE ===', lvl, roleKey), SYS)
    p:printToPlayer('  mod             expect   live   status   (sources)', SYS)
    local lowCount = 0
    for _, mod in ipairs(rows) do
        local exp = expected[mod]
        local act = pet:getMod(mod)
        local ok  = (exp >= 0 and act >= exp) or (exp < 0 and act <= exp)
        if not ok then lowCount = lowCount + 1 end
        p:printToPlayer(string.format('  %-14s %6d %6d   %s   (%s)',
            MODNAME[mod] or ('mod' .. mod), exp, act, ok and 'OK' or '**LOW**', source[mod]), SYS)
    end
    if lowCount == 0 then
        p:printToPlayer('  All allocated mods landed on the pet. Spend a point + re-run to watch a row move.', SYS)
    else
        p:printToPlayer(string.format('  ** %d mod(s) LOW -- not fully applied to the entity (bug). **', lowCount), SYS)
    end
    -- Engine-usage note (verified against combat code): STR/DEX/VIT/AGI (+ATT/ACC/
    -- DEF/EVA), ATTP, DOUBLE/TRIPLE_ATTACK, STORETP (melee TP return, tp.lua) and
    -- DMGPHYS/DMGMAGIC are all read by mob combat. MATT/MACC/MDEF are read too, but
    -- only exercised when the Fellow CASTS -- a melee-role Fellow never triggers them.
    p:printToPlayer('  Note: MATT/MACC only matter for a CASTING role (Magus); a melee Fellow never uses them.', SYS)
end

return m
