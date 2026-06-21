-----------------------------------
-- abyssea_su5_drops.lua
-- Superior Lv5 (Dynamis Divergence) weapon drops in Abyssea. Owner request 2026-06-21.
--
-- On ANY regular mob killed in an Abyssea zone: ONE 5% roll per kill; on a hit, a
-- random one of the 22 NQ Su5 weapons (one per job) is added to the treasure pool
-- (the whole alliance can lot it), exactly like the Al Zahbi loot fountain.
--
-- Hooks the GLOBAL mob-death handler (xi.mob.onMobDeathEx) like alzahbi_loot.lua, so
-- it covers EVERY mob in every Abyssea zone with no per-mob DB / droplist edits.
-- Gated on:
--   * isKiller -> the core calls onMobDeathEx once per alliance member; isKiller
--                 marks the killing blow, so we roll ONCE per kill (not per member).
--   * mob's zone is one of the 10 Abyssea zones.
--
-- Deploy: new override module -> needs a map RESTART to register (it does NOT
-- hot-reload). Pure Lua, no SQL.
-----------------------------------
require('modules/module_utils')
require('scripts/globals/mobs')

local m = Module:new('abyssea_su5_drops')

local DROP_CHANCE = 0.05   -- 5% total per kill; on a hit, ONE random weapon below

-- The 22 NQ Superior Lv5 "Dynamis Divergence" weapons, one per job. All verified
-- present + statted (item_mods) in this server's DB.
local SU5_WEAPONS =
{
    21878, -- Aram          (Polearm,       DRG)
    22035, -- Asclepius     (Club,          WHM)
    21578, -- Barfawc       (Dagger,        BRD)
    22038, -- Bhima         (Club,          GEO)
    21627, -- Crocea Mors   (Sword,         RDM)
    22096, -- Draumstafir   (Staff,         SMN)
    21825, -- Father Time   (Scythe,        DRK)
    21917, -- Fudo Masamune (Katana,        NIN)
    21970, -- Fusenaikyo    (Great Katana,  SAM)
    21575, -- Gandring      (Dagger,        THF)
    22093, -- Kaumodaki     (Staff,         BLM)
    21774, -- Labraunda     (Great Axe,     WAR)
    21630, -- Moralltach    (Sword,         PLD)
    21669, -- Morgelai      (Great Sword,   RUN)
    22099, -- Musa          (Staff,         SCH)
    21717, -- Pangu         (Axe,           BST)
    21581, -- Rostam        (Dagger,        COR)
    21523, -- Sagitta       (Hand-to-Hand,  MNK)
    21584, -- Setan Kober   (Dagger,        DNC)
    22149, -- Sharanga      (Marksmanship,  RNG)
    21526, -- Xiucoatl      (Hand-to-Hand,  PUP)
    21633, -- Zomorrodnegar (Sword,         BLU)
}

local ABYSSEA_ZONES = set
{
    xi.zone.ABYSSEA_KONSCHTAT,  xi.zone.ABYSSEA_TAHRONGI,   xi.zone.ABYSSEA_LA_THEINE,
    xi.zone.ABYSSEA_ATTOHWA,    xi.zone.ABYSSEA_MISAREAUX,  xi.zone.ABYSSEA_VUNKERL,
    xi.zone.ABYSSEA_ALTEPA,     xi.zone.ABYSSEA_ULEGUERAND, xi.zone.ABYSSEA_GRAUBERG,
    xi.zone.ABYSSEA_EMPYREAL_PARADOX,
}

m:addOverride('xi.mob.onMobDeathEx', function(mob, player, isKiller, isWeaponSkillKill)
    super(mob, player, isKiller, isWeaponSkillKill)

    -- Once per kill (isKiller), real player, Abyssea zones only.
    if mob == nil or player == nil or not isKiller then
        return
    end
    if player:getObjType() ~= xi.objType.PC then
        return
    end
    if not ABYSSEA_ZONES[mob:getZoneID()] then
        return
    end

    if math.random() < DROP_CHANCE then
        local id = SU5_WEAPONS[math.random(#SU5_WEAPONS)]
        pcall(function() player:addTreasure(id, mob) end)
    end
end)

return m
