-----------------------------------
-- gauntlet_catalog.lua
--
-- Config constants for The Gauntlet (10-level challenge in Riverne Site A01).
-- NM HP doubles each level. Reaching and defeating level 10 grants a massive
-- reward and an NPC named after the champion in the Hall of Champions (B01).
-----------------------------------
local C = {}

-- Zone IDs
C.GROUP_ZONE = 210  -- mob template zone (GM Home -- all Apex groups defined here)
C.ARENA_ZONE = 30   -- Riverne-Site_A01 (the 10-level combat zone)
C.HALL_ZONE  = 29   -- Riverne-Site_B01 (Hall of Champions, read-only display)

-- Spawn positions (verified from zone scripts)
C.WARP_IN  = { x = 732.55, y = -32.5, z = -506.544, rot = 90 }  -- Riverne A01 default spawn
C.HALL_IN  = { x = 729.749, y = -20.319, z = 407.153, rot = 90 } -- Riverne B01 default spawn
C.EXIT_POS = { x = 0.0, y = 0.0, z = 0.0, rot = 0, zoneId = 210 } -- back to GM Home

-- NM pool by level (groupIds from zone 210; all confirmed in mob_groups)
C.NM_POOL = {
    [1]  = { groupId = 11360, name = 'Aquarius' },
    [2]  = { groupId = 11361, name = 'Serket' },
    [3]  = { groupId = 11363, name = 'Simurgh' },
    [4]  = { groupId = 11364, name = 'Nidhogg' },
    [5]  = { groupId = 11365, name = 'King Behemoth' },
    [6]  = { groupId = 11362, name = 'Vrtra' },
    [7]  = { groupId = 11366, name = 'Kirin' },
    [8]  = { groupId = 11367, name = 'Absolute Virtue' },
    [9]  = { groupId = 11368, name = 'Pandemonium Warden' },
    [10] = { groupId = 11369, name = 'Shinryu' },
}

-- HP doubles per level: level 1 = 100k, level 10 ≈ 51M
C.NM_BASE_HP = 100000
function C.nmHp(level)
    return math.floor(C.NM_BASE_HP * (2 ^ (level - 1)))
end

-- Mob level scales from 80 (lv1) to 152 (lv10)
function C.nmLevel(level)
    return 72 + level * 8
end

-- Stat scaling per level (0 at level 1, multiplied by (level-1))
-- These are additive mods on top of the mob's template stats.
C.ATT_PER_LEVEL = 300
C.DEF_PER_LEVEL = 250
C.ACC_PER_LEVEL = 80
C.EVA_PER_LEVEL = 60
C.STR_PER_LEVEL = 30
C.DEX_PER_LEVEL = 20
C.VIT_PER_LEVEL = 25
C.AGI_PER_LEVEL = 20

-- Flat stat mod table for a given Gauntlet level (xi.mod.* resolved at call time)
function C.nmMods(level)
    local t = level - 1
    return {
        [xi.mod.ATT] = t * C.ATT_PER_LEVEL,
        [xi.mod.DEF] = t * C.DEF_PER_LEVEL,
        [xi.mod.ACC] = t * C.ACC_PER_LEVEL,
        [xi.mod.EVA] = t * C.EVA_PER_LEVEL,
        [xi.mod.STR] = t * C.STR_PER_LEVEL,
        [xi.mod.DEX] = t * C.DEX_PER_LEVEL,
        [xi.mod.VIT] = t * C.VIT_PER_LEVEL,
        [xi.mod.AGI] = t * C.AGI_PER_LEVEL,
    }
end

-- Human-readable HP display (e.g. "12.8M")
function C.formatHp(hp)
    if hp >= 1000000 then
        return string.format('%.1fM', hp / 1000000)
    elseif hp >= 1000 then
        return string.format('%.0fk', hp / 1000)
    end
    return tostring(hp)
end

-- Final clear reward (level 10 NM kill)
C.FINAL_REWARD = {
    gil    = 500000000,  -- 500M gil
    pp     = 50000,      -- Paragon Points
    infamy = 50000,      -- Infamy
}

-- Champion NPC appearance in Hall of Champions
C.CHAMPION_LOOK = 2419  -- same heroic model as Rupture Sage

-- Data file for persistent champion list (io.write pattern from setbonus.lua)
C.CHAMPION_DATA_FILE = 'modules/custom/lua/gauntlet_champion_data.lua'

-- NPC spawn offsets within zone 30 (relative to player warp-in position)
C.SAFE_NPC_OFFSET  = { x = -5.0, z = 0.0 }
C.FIGHT_NPC_OFFSET = { x =  5.0, z = 0.0 }
C.NM_SPAWN_OFFSET  = { x = 0.0,  z = 18.0 }  -- in front of player

return C
