-----------------------------------
-- !silencega  --  AoE Silence on your battle target and nearby enemies.
--
-- Silencega is spell 359. Unlike Divine Aegis/Convergence it is a STOCK
-- spell ID (it ships in sql/spell_list.sql with a real animation), so a
-- normal client may also be able to /ma "Silencega" once the scroll is
-- learned. This command guarantees it works regardless of client support
-- and gives the three custom spells a uniform interface.
--
-- Effect: a resist-checked Silence (Wind / Enfeebling Magic) on the target
-- and every enemy within range. WHM 40 / RDM 50 / SCH 50, 32 MP, 20s recast.
--
-- Lives in modules/custom/commands/ -> auto-registers as !silencega.
-----------------------------------
require('scripts/globals/combat/magic_hit_rate')
local gate = require('modules/custom/lua/custom_spell_command')

local SPELL_GROUP = 6    -- matches silencega's spell_list `group`
local AOE_RANGE   = 10   -- yalms (same radius divine_aegis uses for its AoE)
local BASE_DUR    = 120  -- seconds of Silence on a clean landing

local cfg =
{
    name    = 'Silencega',
    spellId = 359,
    jobs    = { [xi.job.WHM] = 40, [xi.job.RDM] = 50, [xi.job.SCH] = 50 },
    reqText = 'WHM 40 / RDM 50 / SCH 50',
    mp      = 32,
    recast  = 20,
    cdVar   = 'cmdspell_silencega_cd',
}

-- Resist-check + apply Silence to a single enemy. Returns true on landing.
local function trySilence(caster, enemy)
    if enemy == nil or enemy:isDead() then
        return false
    end
    local resistRate = xi.combat.magicHitRate.calculateResistRate(
        caster, enemy,
        SPELL_GROUP,
        xi.skill.ENFEEBLING_MAGIC,
        0,
        xi.element.WIND,
        xi.mod.MND,
        xi.effect.SILENCE,
        0)
    if resistRate == 0 then
        return false
    end
    enemy:addStatusEffect(xi.effect.SILENCE, {
        power    = 1,
        duration = math.floor(BASE_DUR * resistRate),
        origin   = caster,
        tick     = 0,
    })
    return true
end

---@type TCommand
local commandObj = {}

commandObj.cmdprops =
{
    permission = 0,
    parameters = '',
}

commandObj.onTrigger = function(player)
    if not gate.check(player, cfg) then
        return
    end

    local target = player:getTarget()
    if target == nil or target:isDead() then
        player:printToPlayer('Silencega: engage an enemy first (no valid target).', xi.msg.channel.SYSTEM_3)
        return
    end

    gate.commit(player, cfg)

    local seen   = {}
    local landed = 0
    local function handle(enemy)
        if enemy == nil or enemy:getID() == player:getID() then
            return
        end
        local id = enemy:getID()
        if seen[id] then
            return
        end
        seen[id] = true
        if trySilence(player, enemy) then
            landed = landed + 1
        end
    end

    -- Primary target first (guaranteed), then the AoE around the caster.
    -- Same getEntitiesInRange call divine_aegis.lua uses to find enemies.
    handle(target)
    local enemies = player:getEntitiesInRange(
        player,
        xi.aoeType.ROUND,
        xi.aoeRadius.ATTACKER,
        AOE_RANGE,
        0,
        xi.targetType.SELF + xi.targetType.ANY_ALLEGIANCE)
    for _, enemy in ipairs(enemies) do
        handle(enemy)
    end

    player:printToPlayer(
        string.format('Silencega: silenced %d enem%s.', landed, landed == 1 and 'y' or 'ies'),
        xi.msg.channel.SYSTEM_3)
end

return commandObj
