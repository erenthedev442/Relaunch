-----------------------------------
-- func: shop (category) (subcategory)
-- desc: Opens an NPC-style item shop menu for players.
--       Categories: general, weapons, armor, consumables, food, augments
--       Usage: !shop  OR  !shop weapons
--       Augment catalysts: "!shop augments" lists the thematic groups, then
--       "!shop augments <group>" (e.g. !shop augments str) opens that group.
--       Every augment catalyst is 1,000,000 gil -- buy it here, then trade it
--       to the Augment Moogle at GM Home to apply the augment.
-----------------------------------
---@type TCommand
local commandObj = {}

commandObj.cmdprops =
{
    permission = 0,
    parameters = 'ss',
}

-----------------------------------
-- Shop inventory
-- Format: { itemId, price }
-- Max 16 items per category (FFXI shop window limit)
-- Use xi.item.CONSTANT names or raw numeric IDs
-- Tip: search scripts/enum/item.lua for exact constant names
-----------------------------------
local stock =
{
    general =
    {
         { 27556,   100000 },  --Echad Ring
        { xi.item.HI_POTION,                 600 },
        { xi.item.X_POTION,                 1800 },
        { xi.item.ETHER,                     800 },
        { xi.item.HI_ETHER,                 2400 },
        { xi.item.ANTIDOTE,                  100 },
        { xi.item.FLASK_OF_ECHO_DROPS,       250 },
        { xi.item.FLASK_OF_EYE_DROPS,        150 },
        { xi.item.FLASK_OF_HOLY_WATER,       200 },
        { xi.item.FLASK_OF_SLEEPING_POTION,  300 },
        { xi.item.STRIP_OF_MEAT_JERKY,       120 },
    },

    consumables =
    {
        { xi.item.POTION,                    150 },
        { xi.item.TOOLBAG_SHIHEI,                    15000 },
        { xi.item.HI_POTION,                 600 },
        { xi.item.X_POTION,                 1800 },
        { xi.item.ETHER,                     800 },
        { xi.item.HI_ETHER,                 2400 },
        { xi.item.ELIXIR,                  12000 },
        { xi.item.ANTIDOTE,                  100 },
        { xi.item.FLASK_OF_ECHO_DROPS,       250 },
        { xi.item.FLASK_OF_EYE_DROPS,        150 },
        { xi.item.FLASK_OF_HOLY_WATER,       200 },
        { xi.item.FLASK_OF_SLEEPING_POTION,  300 },
        { xi.item.VILE_ELIXIR,             10000 },
        { xi.item.VILE_ELIXIR_P1,          18000 },
    },

    weapons =
    {
        { xi.item.BRONZE_SWORD,    20000 },
        { 17175,     15000 },--shortbow +1
        { 21340,     150000 },--Halakaaala
        { 18510,     15000 }, --vermeil bhuj
        { 18171,     15000 }, --platoon disc
        { xi.item.BRONZE_DAGGER,   15000 },
		  { 16822,   100000 },  --crimson blade
		  { 16923,   100000 },  --Kabutowari +1
		  { 17440,   4000000 },  --Kraken Club
		    { 16605,   100000 },  --Enhancing Sword
		    { 19104,   100000 },  --Darksteel jambiya +1
		    { 16878,   100000 },  --Darksteel Lance +1
		    { 18175,   100000 },  --Optical Needle
    },

    armor =
    {
        { 12486,   50000 }, --seers crown +1
        { 11003,   500000 }, --prodigious mantle
        { 28440,   500000 }, --wind buffet belt +1
        { 28365,   500000 }, --nefarious collar +1
        { 13014,   25000 },
        { 13056,   50000 },
        { 13281,   50000 },
        { 26164,   100000 },
        { 15457,   100000 }, --swift belt
        { 12579,   100000 }, --Scorpion Harness      
--        { 15166,   5000 },
--        { xi.item.SHADE_HARNESS,     1200 },
--        { xi.item.SHADE_MITTENS,    800 },
 --       { xi.item.SHADE_TIGHTS, 1000 },
 --       { xi.item.SHADE_LEGGINGS,        6000 },
        { xi.item.CASSIE_EARRING,          300000 },
        { 14724,          600000 }, -- moldavite earring
        { xi.item.CHAIN_MITTENS,    3000 },
        { xi.item.CHAIN_HOSE,       4500 },
        { xi.item.GREAVES,          3000 },
        { xi.item.IRON_MASK,        4000 },
    },

    -- Absolute-best endgame foods (max 16 slots). One BiS per role; each
    -- entry's comment explains what the food gives and who it's for.
    -- Raw IDs are used where no xi.item.* constant exists for the +1
    -- variant (verified against item_basic.sql).
    food =
    {
        -- ===== Mage / caster =====
        { 6469,                                 5000 },  -- Sublime Sushi +1     -- Macc+25, INT+9, MAB+15 (best caster food)
        { xi.item.FLASK_OF_PEAR_AU_LAIT,        5000 },  -- Pear au Lait         -- Macc, MAB, MP
        { xi.item.FLASK_OF_PERSIKOS_AU_LAIT,    5000 },  -- Persikos au Lait     -- MP refresh tick
        { 5765,                                  5000 },  -- Red Curry Bun +1     -- MAB / INT (nuker)

        -- ===== TP / weaponskill =====
        { 6344,                                 5000 },  -- Grape Daifuku +1     -- TP Bonus +50 (BiS for SAM/COR/RNG WS sets)

        -- ===== Melee DD =====
        { 6459,                                 5000 },  -- Soy Ramen +1         -- Acc+15, Att+15 (top all-round DD)
        { 5163,                                 5000 },  -- Sole Sushi +1        -- Acc+18 (Acc-capped fights)
        { 5177,                                 5000 },  -- Bream Sushi +1       -- Acc+18, Att+12
        { 5722,                                 5000 },  -- Crab Sushi +1        -- Acc, Att, crit
        { 5924,                                 5000 },  -- Smoldering Salisbury Steak -- STR / Att (heavy melee)
        { 5167,                                 5000 },  -- Coeurl Sub +1        -- STR / DEX
        { 5763,                                 5000 },  -- Yellow Curry Bun +1  -- STR / Acc hybrid

        -- ===== Attack% (best vs high-DEF mobs -- e.g. the Prestige trial bosses) =====
        { 6072,                                 5000 },  -- Magma Steak +1       -- Attack +24% (cap 185) -- highest attack food, +STR9
        { 6465,                                 5000 },  -- Behemoth Steak +1    -- Attack +24% (cap 165), +STR8 +DEX8 (attack + a little acc)
        { 5925,                                 5000 },  -- Charred Salisbury Steak -- Attack +22% (cap 165), +STR8

        -- ===== Ranged DD =====
        { 5162,                                 5000 },  -- Squid Sushi +1       -- RACC+18, RATT+13% (RNG / COR)

        -- ===== Hybrid =====
        { 5199,                                 5000 },  -- Spaghetti Carbonara +1 -- STR / VIT / HP (DD + survivability)

        -- ===== Tank =====
        { 5744,                                 5000 },  -- Marinara Pizza +1    -- Enmity (PLD / RUN)
        { 4330,                                 5000 },  -- Witch Risotto        -- Magic defense (mage burns)
    },
}

-----------------------------------
-- Augment catalysts (custom gil sink)
-- Pulled live from the Augment Moogle catalog (augment_catalog.lua) so this
-- shop always matches what the moogle accepts. Every catalyst sells for a
-- flat 1,000,000 gil. The catalog holds ~379 catalysts -- far more than the
-- 255-item shop-window cap -- so they are split into the same 13 thematic
-- groups the catalog already tags via its `cat` field (1-13).
-----------------------------------
local AUGMENT_PRICE     = 1000000
local AUGMENT_PRICE_STR = '1,000,000'

-- cat index (1-13) -> { token for "!shop augments <token>", display name }
local augmentGroups =
{
    [1]  = { 'str',    'STR / Attack / Phys.Dmg' },
    [2]  = { 'dex',    'DEX / Accuracy / Crit'   },
    [3]  = { 'vit',    'VIT / Defense'           },
    [4]  = { 'agi',    'AGI / Evasion / Haste'   },
    [5]  = { 'int',    'INT / Magic Offense'     },
    [6]  = { 'mnd',    'MND / Healing'           },
    [7]  = { 'chr',    'CHR / Charm / Enmity'    },
    [8]  = { 'hp',     'HP / Regen'              },
    [9]  = { 'mp',     'MP / Refresh'            },
    [10] = { 'pet',    'Pet'                     },
    [11] = { 'resist', 'Resist / Affinity'       },
    [12] = { 'skill',  'Skill+'                  },
    [13] = { 'ws',     'Weaponskill DMG'         },
}

local augmentStock = {} -- token -> { { itemId, price }, ... }
local augmentOrder = {} -- ordered { token, name, count } for the index menu

do
    local ok, catalog = pcall(require, 'modules/custom/lua/augment_catalog')
    if ok and type(catalog) == 'table' then
        local byToken = {}
        for itemId, def in pairs(catalog) do
            if type(def) == 'table' and def.cat then
                local grp   = augmentGroups[def.cat]
                local token = grp and grp[1] or 'other'
                byToken[token] = byToken[token] or {}
                table.insert(byToken[token], itemId)
            end
        end

        local function finalize(token, name)
            local ids = byToken[token]
            if ids and #ids > 0 then
                table.sort(ids) -- stable display order
                local list = {}
                for _, itemId in ipairs(ids) do
                    list[#list + 1] = { itemId, AUGMENT_PRICE }
                end
                augmentStock[token]             = list
                augmentOrder[#augmentOrder + 1] = { token, name, #list }
            end
        end

        for cat = 1, 13 do
            finalize(augmentGroups[cat][1], augmentGroups[cat][2])
        end
        finalize('other', 'Other') -- safety net for any cat outside 1-13
    end
end

local validCategories = 'general, weapons, armor, consumables, food, augments'

commandObj.onTrigger = function(player, category, subcat)
    local cat = category and category:lower() or 'general'

    -- Augment catalyst shop: split into thematic sub-groups.
    if cat == 'augments' then
        if #augmentOrder == 0 then
            player:printToPlayer('The augment catalyst shop is unavailable (catalog failed to load).')
            return
        end

        -- No group given: print the index of groups.
        if subcat == nil or subcat == '' then
            player:printToPlayer(string.format('Augment catalysts -- %s gil each. Choose a group with  !shop augments <group>', AUGMENT_PRICE_STR), xi.msg.channel.SYSTEM_3)
            for _, g in ipairs(augmentOrder) do
                player:printToPlayer(string.format('  augments %-7s  %s (%d)', g[1], g[2], g[3]), xi.msg.channel.SYSTEM_3)
            end
            return
        end

        local sub  = subcat:lower()
        local list = augmentStock[sub]
        if not list then
            local toks = {}
            for _, g in ipairs(augmentOrder) do
                toks[#toks + 1] = g[1]
            end
            player:printToPlayer(string.format('Unknown augment group "%s". Valid groups: %s', sub, table.concat(toks, ', ')), xi.msg.channel.SYSTEM_3)
            return
        end

        player:printToPlayer(string.format('Augment catalysts -- %s gil each. Trade purchases to the Augment Moogle at GM Home to apply.', AUGMENT_PRICE_STR), xi.msg.channel.SYSTEM_3)
        xi.shop.general(player, list)
        return
    end

    local shopStock = stock[cat]

    if not shopStock then
        player:printToPlayer(string.format('Unknown shop category "%s". Valid categories: %s', cat, validCategories))
        return
    end 
  
    player:printToPlayer(string.format('Available shop categories: %s', validCategories), xi.msg.channel.SYSTEM_3)
    player:printToPlayer(string.format('Usage: !shop <category>  (currently browsing: %s)', cat), xi.msg.channel.SYSTEM_3)
    xi.shop.general(player, shopStock)
end

return commandObj
