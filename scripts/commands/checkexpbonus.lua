-----------------------------------
-- func: checkexpbonus
-- desc: Prints your current EXP_BONUS mod (gear/augments that boost EXP gain)
--       and the per-kill effect it has. Useful for verifying that an EXP
--       augment is actually attached to the player after equipping the piece.
--
--       The engine reads Mod::EXP_BONUS (382) once per kill in
--       charutils::AddExperiencePoints and applies it as a percentage to
--       the EXP awarded. So a value of 33 means each kill grants 33% more
--       EXP than the base amount.
-----------------------------------
---@type TCommand
local commandObj = {}

commandObj.cmdprops =
{
    permission = 0,
    parameters = ''
}

commandObj.onTrigger = function(player)
    local bonus = player:getMod(xi.mod.EXP_BONUS)

    if bonus == 0 then
        player:printToPlayer(
            'EXP Bonus: 0%. Nothing equipped that grants Mod::EXP_BONUS (mod 382).',
            xi.msg.channel.SYSTEM_3
        )
        player:printToPlayer(
            'If you augmented a piece with Exp. Point +33%, re-zone or relog so the mod attaches.',
            xi.msg.channel.SYSTEM_3
        )
        return
    end

    local example = 100
    local boosted = math.floor(example + (example * bonus / 100))
    player:printToPlayer(
        string.format('EXP Bonus: +%d%%. A %d-EXP kill becomes %d EXP.', bonus, example, boosted),
        xi.msg.channel.SYSTEM_3
    )
end

return commandObj
