-----------------------------------
-- func: killtrial <player> [boss]
-- desc: Finds a live Ascension Trial boss in the current zone and kills it
--       via takeDamage, crediting the kill to <player>. This fires the
--       Altar's onMobDeath callback which clears the "already alive" flag
--       and stamps the trial charVar -- no server restart needed.
--
--       boss defaults to 'diabolos' if omitted.
--
--       Usage (GM must be inside Provenance):
--         !killtrial PlayerName
--         !killtrial PlayerName medusa
-----------------------------------
---@type TCommand
local commandObj = {}

commandObj.cmdprops =
{
    permission = 5,
    parameters = 'ss',
}

commandObj.onTrigger = function(player, targetName, bossArg)
    if not targetName then
        player:printToPlayer('Usage: !killtrial <player> [boss_name]')
        return
    end

    local targ = GetPlayerByName(targetName)
    if not targ then
        player:printToPlayer(string.format('[KillTrial] Player "%s" not found (must be online).', targetName))
        return
    end

    local zone = player:getZone()
    if not zone then
        player:printToPlayer('[KillTrial] You are not in a zone.')
        return
    end

    local nameFilter = (bossArg or 'diabolos'):lower()

    -- Find the mob by name in the current zone.
    local victim = nil
    local mobs   = zone:getMobs()
    if mobs then
        for _, m in pairs(mobs) do
            if m:isSpawned() and m:getHPP() > 0 then
                if m:getName():lower():find(nameFilter, 1, true) then
                    victim = m
                    break
                end
            end
        end
    end

    if not victim then
        player:printToPlayer(string.format(
            '[KillTrial] No live mob named "%s" found in %s.', nameFilter, zone:getName()))
        player:printToPlayer('  Use !mobs to see what is alive here.')
        return
    end

    -- Kill via takeDamage, crediting targ as the attacker.
    -- This fires the mob\'s onMobDeath callback which:
    --   (a) clears summonedTrial[targ:getID()] -> Altar menu unblocks
    --   (b) calls m.onLegendKill(targ, gid)   -> stamps trial charVar
    local lethal = victim:getMaxHP() * 10
    victim:takeDamage(lethal, targ, xi.attackType.PHYSICAL, xi.damageType.SLASHING,
        { wakeUp = true, breakBind = true, bypassGlobalHpDamageCap = true })

    player:printToPlayer(string.format(
        '[KillTrial] %s killed, credited to %s. They can now use the Altar.',
        victim:getName(), targetName))
    targ:printToPlayer(
        '[Ascension] Trial boss slain (GM assist). Commune with the Altar to continue.',
        xi.msg.channel.SYSTEM_3)
end

return commandObj
