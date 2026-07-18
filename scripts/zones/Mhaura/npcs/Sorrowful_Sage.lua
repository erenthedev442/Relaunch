-----------------------------------
-- Area: Mhaura (249)
-- NPC:  Sorrowful Sage  !pos -25.200 -15.990 52.565 249
--
-- RELAUNCH Nyzul Isle Investigation entry. Registers the Nyzul Isle
-- Investigation instance (id 7704) directly, skipping the retail ToAU Assault
-- prerequisites (Whitegate questline / Immortal Sentries mission / Runic Portal /
-- Nyzul Isle Assault Orders). createInstance() bypasses the registryRequirements
-- key-item gate; the player lands in the Nyzul staging room where the existing
-- Rune of Transfer (Rune_of_Transfer_Start) runs the retail floor-selection,
-- saved-progress (Runic Disc) and reward flow unchanged.
--
-- DB row: modules/custom/sql/nyzul_relaunch.sql.  Exit returns to Mhaura
-- (patched in scripts/zones/Nyzul_Isle/instances/nyzul_isle_investigation.lua).
-----------------------------------
local NYZUL_INSTANCE = 7704
local SYS            = xi.msg.channel.SYSTEM_3
---@type TNpcEntity
local entity = {}

local function beginAssault(player)
    if player:getInstance() then
        player:printToPlayer('[Nyzul Isle] You are already inside an assault.', SYS)
        return
    end
    -- Pre-grant the Runic Disc so the in-instance Rune of Transfer opens the floor
    -- menu on the FIRST touch. Stock Rune_of_Transfer_Start issues the disc on the
    -- first touch and only shows the floor menu on a SECOND touch -- which
    -- contradicts the "touch to choose your floor" instruction below and reads as a
    -- dead gate to new players (Herdofturtles report 2026-07-07).
    if not player:hasKeyItem(xi.ki.RUNIC_DISC) then
        player:addKeyItem(xi.ki.RUNIC_DISC)
    end

    -- Warps the registrant (and nearby party) straight into the Nyzul staging room.
    player:createInstance(NYZUL_INSTANCE)
    player:printToPlayer('[Nyzul Isle] Commencing transport. Touch the Rune of Transfer inside to choose your starting floor.', SYS)
end

entity.onTrigger = function(player, npc)
    local snapshot =
    {
        title = 'Nyzul Isle Investigation',
        options =
        {
            { 'Begin assault',     function(pp) beginAssault(pp) end },
            { 'How does it work?', function(pp)
                pp:printToPlayer('[Nyzul Isle] 100 floors, 30-min limit. Clear each floor objective, ride the Rune of Transfer upward.', SYS)
                pp:printToPlayer('[Nyzul Isle] Bosses every 20 floors drop vigil weapons (Mythic path) + Askar/Denali/Goliard gear. Floor 100 grants the Runic Key to the Runic Disc holder.', SYS)
                pp:printToPlayer('[Nyzul Isle] Only the player who selects the climb records floor progress. Exit before timeout to bank that progress and earned tokens.', SYS)
            end },
            { 'Leave',             function(pp) end },
        },
    }
    player:timer(30, function(pp) pp:customMenu(snapshot) end)
end

return entity
