-----------------------------------
-- Character_Upgrader.lua
-- Grants weaponskills, spells, capped skills, and trusts
-- Zone: GM Home (zone 210)
-----------------------------------
require('modules/module_utils')
require('scripts/zones/GM_Home/Zone')
-----------------------------------
local m = Module:new('character_upgrader')

-- Skoll/Gemma (spell 901, the repurposed Nanaa Mihgo slot) and Meat (spell 899,
-- the repurposed Excenmille slot) are PAID custom trusts -- earned from the Void
-- Keeper for 50M gil each, never handed out by the bulk grants below. Meat sits
-- on the RETAIL Excenmille spell id (899), so without this exclusion every
-- giveAllSpells / giveAllTrusts / !addalltrusts hands it out for free. The
-- fallbacks cover module load order (custom_spell_ids may register the enums
-- after this file is required); EXCENMILLE is a core enum so 899 always resolves.
-- Corvus (spell 902, the repurposed Curilla slot) is a third PAID custom trust;
-- like Meat it sits on a REAL retail id with a free quest grant (blocked in
-- block_curilla_retail_grant.lua), so it must be excluded here too. CURILLA is a
-- core enum so 902 always resolves.
local SKOLL_SPELL  = (xi.magic and xi.magic.spell and xi.magic.spell.SKOLL) or 901
local MEAT_SPELL   = (xi.magic and xi.magic.spell and xi.magic.spell.EXCENMILLE) or 899
local CORVUS_SPELL = (xi.magic and xi.magic.spell and xi.magic.spell.CURILLA) or 902
local ALDO_SPELL   = (xi.magic and xi.magic.spell and xi.magic.spell.ALDO) or 930
local ALDO_UC_SPELL = (xi.magic and xi.magic.spell and xi.magic.spell.ALDO_UC) or 1007

m:addOverride('xi.zones.GM_Home.Zone.onInitialize', function(zone)
    super(zone)

    -----------------------------------
    -- Custom (paid) trusts withheld from the bulk grants: Gemma/Skoll (901) and
    -- Meat (899). Both are SPELLGROUP_TRUST spells in the id range that
    -- giveAllSpells / giveAllTrusts sweep, so exclude them by id -- otherwise the
    -- Void Keeper's 50M-gil trusts get handed out for free.
    -----------------------------------
    local EXCLUDED_SPELLS = { [SKOLL_SPELL] = true, [MEAT_SPELL] = true, [CORVUS_SPELL] = true, [ALDO_SPELL] = true, [ALDO_UC_SPELL] = true }

    local menu         = { title = 'Unlocker', options = {} }
    local mainMenu     = {}
    local teleportMenu = {}   -- forward decl; populated after the confirm submenus

    local delaySendMenu = function(player)
        -- Snapshot before the deferred send: `menu` is a shared scratch
        -- table, and another player's interaction inside the 50ms window
        -- would otherwise swap its contents mid-flight.
        local snapshot = { title = menu.title, options = menu.options }
        player:timer(30, function(playerArg)
            playerArg:customMenu(snapshot)
        end)
    end

    -- Patience heads-up. Printed on the tick the player PICKS a grant (which then
    -- opens that grant's confirm submenu) -- deliberately NOT inside the grant.
    -- Each grant runs its loops in a single synchronous pass, and packets pushed
    -- during that pass only flush to the client AFTER it returns -- so a warning
    -- printed there would arrive bundled with the "...granted, kupo!" messages,
    -- too late to help. Here it lands a tick early, before the player confirms
    -- and before the client may briefly pause while the work runs.
    local warnPatience = function(player, lead)
        player:printToPlayer(lead or 'This can take a hot minute, kupo!', 0, 'Unlocker')
        player:printToPlayer('After you confirm, please be patient - the game may pause a moment while I work.', 0, 'Unlocker')
    end

    -----------------------------------
    -- GRANT ALL WEAPON SKILLS
    -----------------------------------
    local function giveAllWeaponSkills(player)
        for i = 1, 256 do
            pcall(function()
                player:addWeaponSkill(i)
            end)
        end
        -- Grant quest-unlocked weapon skills (Blade: Ku, Evisceration, Savage Blade, etc.)
        for _, unlockId in pairs(xi.wsUnlock) do
            pcall(function()
                player:addLearnedWeaponskill(unlockId)
            end)
        end
        player:printToPlayer('All weapon skills granted, kupo!', 0, 'Unlocker')
    end

    -----------------------------------
    -- GRANT ALL SPELLS
    -----------------------------------
    local function giveAllSpells(player)
        for i = 1, 1024 do
            pcall(function()
                if not EXCLUDED_SPELLS[i] and not player:hasSpell(i) then
                    player:addSpell(i)
                end
            end)
        end
        player:printToPlayer('All spells granted, kupo!', 0, 'Unlocker')
    end

    -----------------------------------
    -- CAP ALL SKILLS
    -----------------------------------
    local function capAllSkills(player)
        player:capAllSkills()
        player:printToPlayer('All skills capped, kupo!', 0, 'Unlocker')
    end

    -----------------------------------
    -- GRANT ALL TRUSTS
    -----------------------------------
    local function giveAllTrusts(player)
        local added = 0
        for i = 1, 10000 do
            pcall(function()
                if not EXCLUDED_SPELLS[i] then
                    local result = player:addTrust(i)
                    if result then
                        added = added + 1
                    end
                end
            end)
        end
        player:printToPlayer(string.format(
            'All trusts granted, kupo! Added: %d', added
        ), 0, 'Unlocker')
    end

    -----------------------------------
    -- UNLOCK + COMPLETE ALL QUESTS
    -- For every quest in every area, accept it then mark it complete.
    -- pcall guards against IDs that don't exist or are out of range.
    -----------------------------------
    local function completeAllQuests(player)
        local count = 0
        for logId, areaKey in pairs(xi.quest.area) do
            if logId >= 0 then -- skip xi.questLog.NONE = -1
                local areaQuests = xi.quest.id[areaKey]
                if areaQuests then
                    for _, questId in pairs(areaQuests) do
                        pcall(function()
                            player:addQuest(logId, questId)
                            player:completeQuest(logId, questId)
                            count = count + 1
                        end)
                    end
                end
            end
        end
        player:printToPlayer(string.format(
            'All %d quests unlocked and completed, kupo!', count
        ), 0, 'Unlocker')
    end

    -----------------------------------
    -- GRANT ALL MAPS
    -----------------------------------
    local function giveAllMaps(player)
        local added = 0
        for name, kiId in pairs(xi.ki) do
            if string.sub(name, 1, 7) == 'MAP_OF_' and not player:hasKeyItem(kiId) then
                pcall(function()
                    player:addKeyItem(kiId)
                    added = added + 1
                end)
            end
        end
        player:printToPlayer(string.format(
            'All maps granted, kupo! Added: %d', added
        ), 0, 'Unlocker')
    end

    -----------------------------------
    -- GRANT ALL OUTPOST WARPS
    -- Outpost teleports are stored per-nation; bit = region + 5.
    -----------------------------------
    local function giveAllOutpostWarps(player)
        for _, nation in pairs({ xi.nation.SANDORIA, xi.nation.BASTOK, xi.nation.WINDURST }) do
            for region = xi.region.RONFAURE, xi.region.TAVNAZIANARCH do
                pcall(function()
                    player:addTeleport(nation, region + 5)
                end)
            end
        end
        player:printToPlayer('All outpost warps granted, kupo!', 0, 'Unlocker')
    end

    -----------------------------------
    -- GRANT ALL HOMEPOINTS
    -----------------------------------
    local function giveAllHomepoints(player)
        for i = 0, 121 do
            local hpBit = i % 32
            local hpSet = math.floor(i / 32)
            pcall(function()
                player:addTeleport(xi.teleport.type.HOMEPOINT, hpBit, hpSet)
            end)
        end
        player:printToPlayer('All homepoints granted, kupo!', 0, 'Unlocker')
    end

    -----------------------------------
    -- GRANT ALL SURVIVAL GUIDES
    -----------------------------------
    local function giveAllSurvivalGuides(player)
        for groupIndex = 0, 31 do
            for group = 0, 2 do
                pcall(function()
                    player:addTeleport(xi.teleport.type.SURVIVAL, groupIndex, group)
                end)
            end
        end
        player:printToPlayer('All survival guides granted, kupo!', 0, 'Unlocker')
    end

    -----------------------------------
    -- BUMP ALL WARDROBE SIZES
    -- Upstream charCreate only resizes Inventory + Mog Satchel, leaving
    -- wardrobes 1-8 at the engine default of 0 slots. This retroactively
    -- bumps them to START_INVENTORY (80 on Legendary). changeContainerSize
    -- is a delta function, so we subtract the current size to avoid
    -- overshooting on a partially-bumped char.
    -----------------------------------
    local function bumpWardrobeSizes(player)
        local target = xi.settings.main.START_INVENTORY
        local locations = {
            xi.inv.WARDROBE,  xi.inv.WARDROBE2, xi.inv.WARDROBE3, xi.inv.WARDROBE4,
            xi.inv.WARDROBE5, xi.inv.WARDROBE6, xi.inv.WARDROBE7, xi.inv.WARDROBE8,
        }
        local bumped = 0
        for _, loc in ipairs(locations) do
            local delta = target - player:getContainerSize(loc)
            if delta > 0 then
                player:changeContainerSize(loc, delta)
                bumped = bumped + 1
            end
        end
        player:printToPlayer(string.format(
            '%d wardrobe(s) bumped to %d slots, kupo!', bumped, target
        ), 0, 'Unlocker')
    end

    -----------------------------------
    -- UNLOCK ALL AUTOMATON PARTS (PUP)
    -- Mirrors the stock !addallattachments: unlockAttachment() sets the per-
    -- character bit for every automaton head/frame/attachment so they become
    -- assignable at the Automaton menu / Tinkerer's Bench. (Buying the item
    -- alone does NOT unlock it -- the engine checks HasAttachment before letting
    -- you equip one.) Idempotent. List mirrors scripts/commands/
    -- addallattachments.lua: heads 8193-8198, frames 8224-8227, attachments 8449+.
    -----------------------------------
    local AUTOMATON_PARTS =
    {
        8193, 8194, 8195, 8196, 8197, 8198, 8224, 8225, 8226, 8227,
        8449, 8450, 8451, 8452, 8453, 8454, 8455, 8456, 8457, 8458,
        8459, 8460, 8461, 8462, 8463, 8464, 8465, 8466, 8481, 8482,
        8483, 8484, 8485, 8486, 8487, 8488, 8489, 8490, 8491, 8492,
        8493, 8494, 8495, 8496, 8497, 8498, 8513, 8514, 8515, 8516,
        8517, 8518, 8519, 8520, 8521, 8522, 8523, 8524, 8525, 8526,
        8527, 8528, 8545, 8546, 8547, 8548, 8549, 8550, 8551, 8552,
        8553, 8554, 8555, 8556, 8557, 8577, 8578, 8579, 8580, 8581,
        8582, 8583, 8584, 8585, 8586, 8587, 8588, 8589, 8590, 8609,
        8610, 8611, 8612, 8613, 8614, 8615, 8616, 8617, 8618, 8619,
        8620, 8621, 8622, 8641, 8642, 8643, 8644, 8645, 8646, 8648,
        8649, 8650, 8651, 8652, 8653, 8654, 8655, 8673, 8674, 8675,
        8676, 8677, 8678, 8680, 8681, 8682, 8683,
    }

    local function giveAllAttachments(player)
        for _, id in ipairs(AUTOMATON_PARTS) do
            pcall(function() player:unlockAttachment(id) end)
        end
        player:printToPlayer('All automaton frames, heads & attachments unlocked, kupo!', 0, 'Unlocker')
    end

    -----------------------------------
    -- GRANT EVERYTHING
    -----------------------------------
    local function giveEverything(player)
        giveAllWeaponSkills(player)
        giveAllSpells(player)
        capAllSkills(player)
        giveAllTrusts(player)
        completeAllQuests(player)
        giveAllMaps(player)
        giveAllOutpostWarps(player)
        giveAllHomepoints(player)
        giveAllSurvivalGuides(player)
        bumpWardrobeSizes(player)
        giveAllAttachments(player)
        player:printToPlayer('Everything granted, kupo! You\'re unstoppable!', 0, 'Unlocker')
    end

    -----------------------------------
    -- CONFIRM MENUS
    -----------------------------------
    local confirmWS =
    {
        {
            'Yes - Give me all weapon skills!',
            function(player)
                giveAllWeaponSkills(player)
                menu.options = mainMenu
                delaySendMenu(player)
            end,
        },
        {
            'No - Go back.',
            function(player)
                menu.options = mainMenu
                delaySendMenu(player)
            end,
        },
    }

    local confirmSP =
    {
        {
            'Yes - Give me all spells!',
            function(player)
                giveAllSpells(player)
                menu.options = mainMenu
                delaySendMenu(player)
            end,
        },
        {
            'No - Go back.',
            function(player)
                menu.options = mainMenu
                delaySendMenu(player)
            end,
        },
    }

    local confirmSK =
    {
        {
            'Yes - Cap all my skills!',
            function(player)
                capAllSkills(player)
                menu.options = mainMenu
                delaySendMenu(player)
            end,
        },
        {
            'No - Go back.',
            function(player)
                menu.options = mainMenu
                delaySendMenu(player)
            end,
        },
    }

    local confirmTR =
    {
        {
            'Yes - Give me all trusts!',
            function(player)
                giveAllTrusts(player)
                menu.options = mainMenu
                delaySendMenu(player)
            end,
        },
        {
            'No - Go back.',
            function(player)
                menu.options = mainMenu
                delaySendMenu(player)
            end,
        },
    }

    local confirmQU =
    {
        {
            'Yes - Unlock and complete all quests!',
            function(player)
                completeAllQuests(player)
                menu.options = mainMenu
                delaySendMenu(player)
            end,
        },
        {
            'No - Go back.',
            function(player)
                menu.options = mainMenu
                delaySendMenu(player)
            end,
        },
    }

    -- Teleport-family confirms return to teleportMenu (the submenu) instead
    -- of mainMenu, so the player can chain "give me maps -> homepoints ->
    -- survival guides" without bouncing back to the top each time.
    local confirmMP =
    {
        {
            'Yes - Give me all maps!',
            function(player)
                giveAllMaps(player)
                menu.options = teleportMenu
                delaySendMenu(player)
            end,
        },
        {
            'No - Go back.',
            function(player)
                menu.options = teleportMenu
                delaySendMenu(player)
            end,
        },
    }

    local confirmOP =
    {
        {
            'Yes - Give me all outpost warps!',
            function(player)
                giveAllOutpostWarps(player)
                menu.options = teleportMenu
                delaySendMenu(player)
            end,
        },
        {
            'No - Go back.',
            function(player)
                menu.options = teleportMenu
                delaySendMenu(player)
            end,
        },
    }

    local confirmHP =
    {
        {
            'Yes - Give me all homepoints!',
            function(player)
                giveAllHomepoints(player)
                menu.options = teleportMenu
                delaySendMenu(player)
            end,
        },
        {
            'No - Go back.',
            function(player)
                menu.options = teleportMenu
                delaySendMenu(player)
            end,
        },
    }

    local confirmSG =
    {
        {
            'Yes - Give me all survival guides!',
            function(player)
                giveAllSurvivalGuides(player)
                menu.options = teleportMenu
                delaySendMenu(player)
            end,
        },
        {
            'No - Go back.',
            function(player)
                menu.options = teleportMenu
                delaySendMenu(player)
            end,
        },
    }

    local confirmAT =
    {
        {
            'Yes - Unlock all automaton parts!',
            function(player)
                giveAllAttachments(player)
                menu.options = teleportMenu
                delaySendMenu(player)
            end,
        },
        {
            'No - Go back.',
            function(player)
                menu.options = teleportMenu
                delaySendMenu(player)
            end,
        },
    }

    local confirmWD =
    {
        {
            'Yes - Bump all my wardrobes!',
            function(player)
                bumpWardrobeSizes(player)
                menu.options = mainMenu
                delaySendMenu(player)
            end,
        },
        {
            'No - Go back.',
            function(player)
                menu.options = mainMenu
                delaySendMenu(player)
            end,
        },
    }

    local confirmAL =
    {
        {
            'Yes - Give me EVERYTHING!',
            function(player)
                giveEverything(player)
                menu.options = mainMenu
                delaySendMenu(player)
            end,
        },
        {
            'No - Go back.',
            function(player)
                menu.options = mainMenu
                delaySendMenu(player)
            end,
        },
    }

    -----------------------------------
    -- MAIN MENU
    -----------------------------------
    -- NOTE: customMenu encodes title + all option labels into a single
    -- packet payload capped at 150 bytes (see src/map/packets/s2c/0x017_chat_std.h).
    -- Keep labels short here or the trailing options get silently dropped.
    mainMenu =
    {
        {
            'Weapon Skills',
            function(player)
                warnPatience(player)
                menu.options = confirmWS
                delaySendMenu(player)
            end,
        },
        {
            'Spells',
            function(player)
                warnPatience(player)
                menu.options = confirmSP
                delaySendMenu(player)
            end,
        },
        {
            'Cap Skills',
            function(player)
                warnPatience(player)
                menu.options = confirmSK
                delaySendMenu(player)
            end,
        },
        {
            'Trusts',
            function(player)
                warnPatience(player)
                menu.options = confirmTR
                delaySendMenu(player)
            end,
        },
        {
            'Quests',
            function(player)
                warnPatience(player)
                menu.options = confirmQU
                delaySendMenu(player)
            end,
        },
        {
            -- Single entry that opens the Teleports submenu. Without this
            -- collapse the top-level menu had 11 options, but the FFXI client
            -- GMPROMPT UI only renders the first 8 - so options 9+ were
            -- silently dropped (the user couldn't see Survival Guides /
            -- Wardrobes / Give Me Everything!).
            'Teleports / Pets',
            function(player)
                menu.options = teleportMenu
                delaySendMenu(player)
            end,
        },
        {
            'Wardrobes',
            function(player)
                warnPatience(player)
                menu.options = confirmWD
                delaySendMenu(player)
            end,
        },
        {
            'Give Me Everything!',
            function(player)
                warnPatience(player, 'Granting EVERYTHING takes a hot minute, kupo!')
                menu.options = confirmAL
                delaySendMenu(player)
            end,
        },
    }

    teleportMenu =
    {
        {
            'Maps',
            function(player)
                warnPatience(player)
                menu.options = confirmMP
                delaySendMenu(player)
            end,
        },
        {
            'Outpost Warps',
            function(player)
                warnPatience(player)
                menu.options = confirmOP
                delaySendMenu(player)
            end,
        },
        {
            'Homepoints',
            function(player)
                warnPatience(player)
                menu.options = confirmHP
                delaySendMenu(player)
            end,
        },
        {
            'Survival Guides',
            function(player)
                warnPatience(player)
                menu.options = confirmSG
                delaySendMenu(player)
            end,
        },
        {
            'Pet Attachments',
            function(player)
                warnPatience(player)
                menu.options = confirmAT
                delaySendMenu(player)
            end,
        },
        {
            'Back',
            function(player)
                menu.options = mainMenu
                delaySendMenu(player)
            end,
        },
    }

    menu.options = mainMenu

    -----------------------------------
    -- NPC ENTITY
    -----------------------------------
    local CharacterUpgrader = zone:insertDynamicEntity({
        objtype    = xi.objType.NPC,
        name       = 'Character_Upgrader',
        packetName = string.format('%sUnlocker', xi.icon.STAR_LARGE),
        look       = 3000,
        -- GM Home Utility cluster (z=-14): Unlocker / KeyItem / Mission Skip.
        x          =  1.500,
        y          =  0.000,
        z          =  -5.000,
        rotation   =  128,
        widescan   =  1,

        onTrade = function(player, npc, trade)
            player:printToPlayer('No trades, kupo!', 0, npc:getPacketName())
        end,

        onTrigger = function(player, npc)
            menu.options = mainMenu
            local snapshot = { title = menu.title, options = menu.options }  -- shared table + deferred send
            player:timer(30, function(playerArg)
                playerArg:customMenu(snapshot)
            end)
        end,
    })
    utils.unused(CharacterUpgrader)
end)

-----------------------------------
-- Also withhold the paid custom trusts -- Gemma/Skoll (901) AND Meat (899) -- from
-- the GM-only "!addalltrusts" command (permission 1), which mirrors this NPC's bulk
-- grant. The stock command (scripts/commands/addalltrusts.lua) hardcodes the trust
-- list and forwards it to !addallspells. Rather than edit that tracked core file
-- (upstream merge risk), override its onTrigger: temporarily wrap addallspells to
-- strip both paid ids from the forwarded list, run the original via super, then
-- restore. Wrapping (instead of copying the id list) keeps us correct if upstream
-- changes which trusts exist.
-----------------------------------
m:addOverride('xi.commands.addalltrusts.onTrigger', function(player, target)
    local addallspells = xi.commands.addallspells
    -- If addallspells is somehow unavailable, defer to the stock command (it
    -- prints its own error). Avoids indexing a nil command table.
    if not (addallspells and type(addallspells.onTrigger) == 'function') then
        return super(player, target)
    end

    local realOnTrigger = addallspells.onTrigger
    addallspells.onTrigger = function(p, t, spellList)
        if spellList then
            local filtered = {}
            for _, id in ipairs(spellList) do
                if id ~= SKOLL_SPELL and id ~= MEAT_SPELL and id ~= CORVUS_SPELL and id ~= ALDO_SPELL and id ~= ALDO_UC_SPELL then
                    filtered[#filtered + 1] = id
                end
            end
            spellList = filtered
        end
        return realOnTrigger(p, t, spellList)
    end

    -- Always restore the stock command, even if the original errors mid-run.
    local ok, err = pcall(super, player, target)
    addallspells.onTrigger = realOnTrigger
    if not ok then
        error(err)
    end
end)

return m
