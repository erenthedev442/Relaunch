-----------------------------------
-- PrimeVendor_NPC.lua
-- "Prime Vendor" -- a GM Home NPC that sells the 16 retail Prime Weapons
-- (Level 119 III / final forms). PURCHASE IS GATED: a character may only buy
-- here once ALL FOUR Prime Weapon Trials are complete (PW_Trial1-4_Done) --
-- the trials ARE the cost, so the weapons themselves are handed over free.
--
-- Each weapon is EX/RARE, so the client naturally limits a character to one of
-- each (the vendor refuses if you already hold it / have no free slot).
--
-- IDs are the final ("Level 119 III") form per weapon. Stats/mods on the 14
-- non-Varga/Mpu weapons are currently EMPTY in the DB (LSB ships them
-- `TODO: Not implemented`) -- they get their stat package from
-- modules/custom/sql/prime_weapons_gear.sql (extend it to cover all 16).
--
-- Zone: GM Home (zone 210).
-----------------------------------
require('modules/module_utils')
require('scripts/zones/GM_Home/Zone')

local m = Module:new('prime_vendor')

local S = xi.msg.channel.SYSTEM_3

-- The four trial charVars shared with the Prime Armory.
local TRIAL_VARS = { 'PW_Trial1_Done', 'PW_Trial2_Done', 'PW_Trial3_Done', 'PW_Trial4_Done' }

-- The 16 Prime Weapons -- final ("Level 119 III") form id per weapon.
-- { id, name, type } -- type is display-only.
local WEAPONS =
{
    { id = 21535, name = 'Varga Purnikawa', type = 'Hand-to-Hand' },
    { id = 21590, name = 'Mpu Gandring',    type = 'Dagger' },
    { id = 21646, name = 'Caliburnus',      type = 'Sword' },
    { id = 21653, name = 'Helheim',         type = 'Great Sword' },
    { id = 21730, name = 'Spalirisos',      type = 'Axe' },
    { id = 21785, name = 'Laphria',         type = 'Great Axe' },
    { id = 21837, name = 'Foenaria',        type = 'Scythe' },
    { id = 21891, name = 'Gae Buide',       type = 'Polearm' },
    { id = 21932, name = 'Dokoku',          type = 'Katana' },
    { id = 21986, name = 'Kusanagi',        type = 'Great Katana' },
    { id = 22002, name = 'Lorg Mor',        type = 'Club' },
    { id = 22106, name = 'Opashoro',        type = 'Staff' },
    { id = 22163, name = 'Pinaka',          type = 'Archery' },
    { id = 22164, name = 'Earp',            type = 'Marksmanship' },
    { id = 26495, name = 'Duban',           type = 'Shield' },
    { id = 22307, name = 'Loughnashade',    type = 'String' },
}

local PAGE_SIZE = 4   -- keeps every customMenu page under the ~150-byte cap

m:addOverride('xi.zones.GM_Home.Zone.onInitialize', function(zone)
    super(zone)

    local function sendMenu(player, menu)
        local snapshot = { title = menu.title, options = menu.options }
        player:timer(30, function(p) p:customMenu(snapshot) end)
    end

    local function trialsComplete(player)
        for _, v in ipairs(TRIAL_VARS) do
            if (player:getCharVar(v) or 0) == 0 then return false end
        end
        return true
    end

    -- Hand over the chosen weapon (free; EX-limited to one per character).
    local function buy(player, weapon)
        if not trialsComplete(player) then
            player:printToPlayer('[Prime Vendor] Complete all four Prime Trials first, kupo!', S)
            return
        end
        if player:getItemCount(weapon.id) > 0 then
            player:printToPlayer(string.format('[Prime Vendor] You already carry %s (it is Rare/Ex), kupo!', weapon.name), S)
            return
        end
        if player:getFreeSlotsCount() == 0 then
            player:printToPlayer('[Prime Vendor] Free an inventory slot first, kupo!', S)
            return
        end
        player:addItem({ id = weapon.id, quantity = 1 })
        player:printToPlayer(string.format('[Prime Vendor] %s (%s) is yours. Wield it well, kupo!', weapon.name, weapon.type), S)
    end

    local showList   -- forward declaration

    -- Per-weapon confirm.
    local function showWeapon(player, weapon, page)
        sendMenu(player, {
            title   = weapon.name,
            options =
            {
                { string.format('Purchase (%s)', weapon.type), function(p) buy(p, weapon) end },
                { '<< Back',                                   function(p) showList(p, page) end },
            },
        })
    end

    -- Paginated weapon list.
    showList = function(player, page)
        page = page or 1
        local totalPages = math.ceil(#WEAPONS / PAGE_SIZE)
        local startIdx   = (page - 1) * PAGE_SIZE + 1
        local endIdx     = math.min(startIdx + PAGE_SIZE - 1, #WEAPONS)

        local options = {}
        for i = startIdx, endIdx do
            local weapon = WEAPONS[i]
            table.insert(options, {
                string.format('%s (%s)', weapon.name, weapon.type),
                function(p) showWeapon(p, weapon, page) end,
            })
        end
        if page < totalPages then table.insert(options, { 'Next >>', function(p) showList(p, page + 1) end }) end
        if page > 1          then table.insert(options, { '<< Prev', function(p) showList(p, page - 1) end }) end

        sendMenu(player, {
            title   = totalPages > 1 and string.format('Prime Vendor (%d/%d)', page, totalPages) or 'Prime Vendor',
            options = options,
        })
    end

    zone:insertDynamicEntity({
        objtype    = xi.objType.NPC,
        name       = 'Prime_Vendor',
        packetName = string.format('%sPrime Vendor', xi.icon.STAR_LARGE),
        look       = 3000,
        x          = -3.000,
        y          =  0.000,
        z          = -20.000,
        rotation   =  128,
        widescan   =  1,

        onTrade = function(player, npc, trade)
            player:printToPlayer('[Prime Vendor] No trading -- browse the menu, kupo!', S)
        end,

        onTrigger = function(player, npc)
            if not trialsComplete(player) then
                player:printToPlayer('[Prime Vendor] These Prime Weapons are for proven heroes only. Complete all FOUR Prime Trials, then return, kupo!', S)
                return
            end
            player:printToPlayer('[Prime Vendor] All trials cleared! Choose your Prime Weapon, kupo!', S)
            showList(player)
        end,
    })
end)

return m
