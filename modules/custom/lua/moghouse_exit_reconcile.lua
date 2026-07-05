-----------------------------------
-- moghouse_exit_reconcile.lua
--
-- FIX (player report 2026-07-03, "Mog House Exits"): the multi-district Mog
-- House exit menu is driven by the character's bit-packed moghouse flag
-- (getMoghouseFlag), NOT the quest log:
--   0x0001 San d'Oria  (quest: Growing Flowers)
--   0x0002 Bastok      (quest: A Lady's Heart)
--   0x0004 Windurst    (quest: Flower Child)
--   0x0008 Jeuno       (quest: Pretty Little Things)
--   0x0010 Aht Urhgan  (quest: Keeping Notes)
-- Only the five quest scripts' own completion cutscenes set those bits. The
-- GM Home quest-completion NPC marks the quests COMPLETED in the log but
-- never sets the bits -> exits stay one-way "as if the quest was never
-- done". (Adoulin exits don't use this flag, which is why they worked.)
--
-- FIX: on every Mog House zone-in, reconcile -- any exit quest that reads
-- completed but whose flag bit is missing gets the bit set. Self-heals every
-- affected character on their next MH visit, and keeps the NPC-completion
-- flow working forever.
--
-- Immediate per-player relief without a restart: !exec player:setMoghouseFlag(31)
-- (plus 0x0020 if they had 2F unlocked -- check getMoghouseFlag first).
--
-- Pure Lua override -> takes effect on the next map restart.
-----------------------------------
require('modules/module_utils')
require('scripts/globals/moghouse')

local m = Module:new('moghouse_exit_reconcile')

local EXIT_QUESTS =
{
    { flagBit = 0x0001, log = xi.questLog.SANDORIA,   id = xi.quest.id.sandoria.GROWING_FLOWERS },
    { flagBit = 0x0002, log = xi.questLog.BASTOK,     id = xi.quest.id.bastok.A_LADYS_HEART },
    { flagBit = 0x0004, log = xi.questLog.WINDURST,   id = xi.quest.id.windurst.FLOWER_CHILD },
    { flagBit = 0x0008, log = xi.questLog.JEUNO,      id = xi.quest.id.jeuno.PRETTY_LITTLE_THINGS },
    { flagBit = 0x0010, log = xi.questLog.AHT_URHGAN, id = xi.quest.id.ahtUrhgan.KEEPING_NOTES },
}

m:addOverride('xi.moghouse.onMoghouseZoneIn', function(player, prevZone)
    local mhflag  = player:getMoghouseFlag()
    local updated = mhflag

    for _, q in ipairs(EXIT_QUESTS) do
        if
            bit.band(updated, q.flagBit) == 0 and
            player:hasCompletedQuest(q.log, q.id)
        then
            updated = bit.bor(updated, q.flagBit)
        end
    end

    if updated ~= mhflag then
        player:setMoghouseFlag(updated)
    end

    return super(player, prevZone)
end)

return m
