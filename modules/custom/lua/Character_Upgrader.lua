-----------------------------------
-- Character_Upgrader.lua
-- Grants weaponskills, spells, capped skills, and trusts
-- Zone: GM Home (zone 210)
-----------------------------------
require('modules/module_utils')
require('scripts/zones/GM_Home/Zone')
-----------------------------------
local m = Module:new('character_upgrader')

-- Skoll (spell 901, the repurposed Nanaa Mihgo slot -> "Trust: Skoll, the
-- Voidhound") is meant to be EARNED from the Void Keeper, never handed out by
-- the bulk grants. The fallback to 901 covers module load order: custom_spell_ids
-- may register xi.magic.spell.SKOLL after this file is required.
local SKOLL_SPELL = (xi.magic and xi.magic.spell and xi.magic.spell.SKOLL) or 901

m:addOverride('xi.zones.GM_Home.Zone.onInitialize', function(zone)
    super(zone)

    -----------------------------------
    -- Custom trusts withheld from the bulk grants. Skoll is a SPELLGROUP_TRUST
    -- spell, so it lands in the spell-id range that giveAllSpells/giveAllTrusts
    -- sweep; exclude it by id.
    -----------------------------------
    local EXCLUDED_SPELLS = { [SKOLL_SPELL] = true }

    local menu         = { title = 'Unlocker', options = {} }
    local mainMenu     = {}
    local teleportMenu = {}   -- forward decl; populated after the confirm submenus

    local delaySendMenu = function(player)
        -- Snapshot before the deferred send: `menu` is a shared scratch
        -- table, and another player's interaction inside the 50ms window
        -- would otherwise swap its contents mid-flight.
        local snapshot = { title = menu.title, options = menu.options }
        player:timer(50, function(playerArg)
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
            'Teleports',
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
        x          = -3.000,
        y          =  0.000,
        z          = -14.000,
        rotation   =  128,
        widescan   =  1,

        onTrade = function(player, npc, trade)
            player:printToPlayer('No trades, kupo!', 0, npc:getPacketName())
        end,

        onTrigger = function(player, npc)
            menu.options = mainMenu
            local snapshot = { title = menu.title, options = menu.options }  -- shared table + deferred send
            player:timer(50, function(playerArg)
                playerArg:customMenu(snapshot)
            end)
        end,
    })
    utils.unused(CharacterUpgrader)
end)

-----------------------------------
-- Also withhold Skoll from the GM-only "!addalltrusts" command (permission 1),
-- which mirrors this NPC's bulk grant. The stock command (scripts/commands/
-- addalltrusts.lua) hardcodes spell 901 in its trust list and forwards it to
-- !addallspells. Rather than edit that tracked core file (upstream merge risk),
-- override its onTrigger: temporarily wrap addallspells to strip 901 from the
-- forwarded list, run the original via super, then restore. Wrapping (instead of
-- copying the id list) keeps us correct if upstream changes which trusts exist.
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
                if id ~= SKOLL_SPELL then
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
