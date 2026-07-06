-----------------------------------
-- gil_race_changer.lua
-- Race Changer: pay 100M gil to change your character's race AND pick a
-- new face/look. The fifth gil sink in the GIL SERVICES row at GM Home
-- (z=-35), sitting at x=7.5 just past the Gil Exchange.
--
-- Menu is FOUR LEVELS. FFXI's GMPROMPT only renders 8 rows and the whole
-- menu packet caps at ~150 bytes, so the 16 faces (8 shapes x A/B hair)
-- can't share one screen. The face list is split into 3 groups so every
-- screen stays <= 8 rows WITH a Back row (no dead-ends):
--   1. Pick a target race      (your current race is omitted)
--   2. Pick a face group        (Faces 1-3 / 4-6 / 7-8)
--   3. Pick the exact face+hair  (e.g. Face 8B)
--   4. Confirm  ->  charge gil, then force-rezone into the new look
--
-- Size is preserved (valid for every race); race + face are chosen.
-- player:raceChange() (src/map/utils/charutils.cpp) writes char_look,
-- unequips any gear the new race can't wear, and force-rezones so the
-- new model loads on the client.
-----------------------------------
require('modules/module_utils')
require('scripts/zones/Celennia_Memorial_Library/Zone')

local m = Module:new('gil_race_changer')

local config = {
    npcName = 'Race Changer',
    npcLook = 3000,
    npcPos  = { x = -102.000, y = -2.150, z = -100.000, rot = 190 },
    cost    = 100000000,   -- 100M gil
}

-- The player's current race is filtered out at menu-build time, so the
-- live race list is at most 7 rows + Close = 8 -- exactly the GMPROMPT cap.
local races = {
    { race = xi.race.HUME_M,   label = 'Hume Male'       },
    { race = xi.race.HUME_F,   label = 'Hume Female'     },
    { race = xi.race.ELVAAN_M, label = 'Elvaan Male'     },
    { race = xi.race.ELVAAN_F, label = 'Elvaan Female'   },
    { race = xi.race.TARU_M,   label = 'Tarutaru Male'   },
    { race = xi.race.TARU_F,   label = 'Tarutaru Female' },
    { race = xi.race.MITHRA,   label = 'Mithra'          },
    { race = xi.race.GALKA,    label = 'Galka'           },
}

-- 16 faces (CharFace enum 0..15: Face1A..Face8B) split into 3 groups so
-- each face screen is <= 6 rows + a Back row. The raw `face` value is the
-- CharFace enum index passed straight to raceChange().
local faceGroups = {
    {
        label = 'Faces 1-3',
        faces = {
            { face =  0, label = 'Face 1A' }, { face =  1, label = 'Face 1B' },
            { face =  2, label = 'Face 2A' }, { face =  3, label = 'Face 2B' },
            { face =  4, label = 'Face 3A' }, { face =  5, label = 'Face 3B' },
        },
    },
    {
        label = 'Faces 4-6',
        faces = {
            { face =  6, label = 'Face 4A' }, { face =  7, label = 'Face 4B' },
            { face =  8, label = 'Face 5A' }, { face =  9, label = 'Face 5B' },
            { face = 10, label = 'Face 6A' }, { face = 11, label = 'Face 6B' },
        },
    },
    {
        label = 'Faces 7-8',
        faces = {
            { face = 12, label = 'Face 7A' }, { face = 13, label = 'Face 7B' },
            { face = 14, label = 'Face 8A' }, { face = 15, label = 'Face 8B' },
        },
    },
}

m:addOverride('xi.zones.Celennia_Memorial_Library.Zone.onInitialize', function(zone)
    super(zone)

    local menu = { title = '', options = {} }

    -- Forward declarations: each level's Back row calls the level above it.
    local buildRaceMenu, buildGroupMenu, buildFaceMenu, buildConfirmMenu

    buildConfirmMenu = function(player, raceDef, faceDef, group)
        menu.title   = 'Confirm Race Change'
        menu.options = {
            {
                string.format('Yes - Become %s (%s) (100M gil)', raceDef.label, faceDef.label),
                function(p)
                    if p:getGil() < config.cost then
                        p:printToPlayer(
                            string.format('Not enough gil! Need %d, have %d.',
                                config.cost, p:getGil()),
                            xi.msg.channel.SYSTEM_3)
                        return
                    end
                    -- Belt-and-suspenders: the current race is excluded from
                    -- the race list, so this should never fire, but never
                    -- charge 100M for a no-op change.
                    if p:getRace() == raceDef.race then
                        p:printToPlayer(
                            string.format('You are already %s.', raceDef.label),
                            xi.msg.channel.SYSTEM_3)
                        return
                    end

                    p:delGil(config.cost)
                    p:printToPlayer(
                        string.format('Now %s (%s)! Rezoning to apply your new look... (-%d gil)',
                            raceDef.label, faceDef.label, config.cost),
                        xi.msg.channel.SYSTEM_3)

                    -- Preserve size; race + face change. Defer the raceChange
                    -- one tick: it force-rezones (clearPacketList), so we let
                    -- the gil-update + chat packets flush first. If the DB
                    -- write fails it returns false WITHOUT rezoning, so refund
                    -- the gil rather than eating 100M on a transient error.
                    local newRace = raceDef.race
                    local newFace = faceDef.face
                    local size    = p:getSize()
                    p:timer(1500, function(pp)
                        if not pp:raceChange(newRace, newFace, size) then
                            pp:addGil(config.cost)
                            pp:printToPlayer('Race change failed -- gil refunded.',
                                xi.msg.channel.SYSTEM_3)
                        end
                    end)
                end,
            },
            {
                '<< Back',
                function(p) buildFaceMenu(p, raceDef, group) end,
            },
        }
        local snapshot = { title = menu.title, options = menu.options }  -- shared table + deferred send
        player:timer(30, function(p) p:customMenu(snapshot) end)
    end

    buildFaceMenu = function(player, raceDef, group)
        local options = {}
        for _, def in ipairs(group.faces) do
            local d = def
            table.insert(options, {
                d.label,
                function(p) buildConfirmMenu(p, raceDef, d, group) end,
            })
        end
        table.insert(options, {
            '<< Back',
            function(p) buildGroupMenu(p, raceDef) end,
        })

        menu.title   = string.format('%s - %s', raceDef.label, group.label)
        menu.options = options
        local snapshot = { title = menu.title, options = menu.options }  -- shared table + deferred send
        player:timer(30, function(p) p:customMenu(snapshot) end)
    end

    buildGroupMenu = function(player, raceDef)
        local options = {}
        for _, grp in ipairs(faceGroups) do
            local g = grp
            table.insert(options, {
                g.label,
                function(p) buildFaceMenu(p, raceDef, g) end,
            })
        end
        table.insert(options, {
            '<< Back',
            function(p) buildRaceMenu(p) end,
        })

        menu.title   = string.format('%s - pick a face', raceDef.label)
        menu.options = options
        local snapshot = { title = menu.title, options = menu.options }  -- shared table + deferred send
        player:timer(30, function(p) p:customMenu(snapshot) end)
    end

    buildRaceMenu = function(player)
        local currentRace = player:getRace()
        local options     = {}
        for _, def in ipairs(races) do
            if def.race ~= currentRace then
                local d = def
                table.insert(options, {
                    d.label,
                    function(p) buildGroupMenu(p, d) end,
                })
            end
        end
        table.insert(options, {
            'Close',
            function(p) p:printToPlayer('Come back anytime.', xi.msg.channel.SYSTEM_3) end,
        })

        menu.title   = string.format('Race Change  (Gil: %d)', player:getGil())
        menu.options = options
        local snapshot = { title = menu.title, options = menu.options }  -- shared table + deferred send
        player:timer(30, function(p) p:customMenu(snapshot) end)
    end

    local RaceChanger = zone:insertDynamicEntity({
        objtype    = xi.objType.NPC,
        name       = 'Race_Changer',
        packetName = string.format('%s%s', xi.icon.STAR_LARGE, config.npcName),
        look       = 174,
        x          = config.npcPos.x,
        y          = config.npcPos.y,
        z          = config.npcPos.z,
        rotation   = config.npcPos.rot,
        widescan   = 1,

        onTrade = function(player, npc, trade)
            player:printToPlayer('Use the menu, friend!', xi.msg.channel.SYSTEM_3)
        end,

        onTrigger = function(player, npc)
            buildRaceMenu(player)
        end,
    })
    utils.unused(RaceChanger)
end)

return m
