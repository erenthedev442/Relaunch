-----------------------------------
-- Shared travel refusal for player warp commands.
-- Jail stays a separate check so !unstick can recover a jailed character
-- without also inheriting the first-login stay-put lock.
-----------------------------------
local jail = require('modules/custom/lua/mordion_jail')

local guard = {}

function guard.refuseTravel(player)
    if jail.refuseTravel(player) then
        return true
    end

    local upgrade = xi.characterUpgrade
    if upgrade and upgrade.refuseTravel and upgrade.refuseTravel(player) then
        return true
    end

    return false
end

return guard
