-----------------------------------
-- Spark Shop
-- TO DO: Add Naakaul Seven Treasures
-----------------------------------
require('scripts/globals/npc_util')
require('scripts/globals/extravaganza')
-----------------------------------
xi = xi or {}
xi.sparkshop = xi.sparkshop or {}

local optionToItem =
{
    [1] = -- Items page
    {
        [ 0] = { cost =    10, id =  4181 }, -- Scroll of Instant Warp
        [ 1] = { cost =    10, id =  4182 }, -- Scroll of Instant Reraise
        [ 2] = { cost =  7500, id =  4064 }, -- Copy of Rem's Tale, chapter 1
        [ 3] = { cost =  7500, id =  4065 }, -- Copy of Rem's Tale, chapter 2
        [ 4] = { cost =  7500, id =  4066 }, -- Copy of Rem's Tale, chapter 3
        [ 5] = { cost =  7500, id =  4067 }, -- Copy of Rem's Tale, chapter 4
        [ 6] = { cost =  7500, id =  4068 }, -- Copy of Rem's Tale, chapter 5
        [ 7] = { cost = 15000, id =  4069 }, -- Copy of Rem's Tale, chapter 6
        [ 8] = { cost = 15000, id =  4070 }, -- Copy of Rem's Tale, chapter 7
        [ 9] = { cost = 15000, id =  4071 }, -- Copy of Rem's Tale, chapter 8
        [10] = { cost = 15000, id =  4072 }, -- Copy of Rem's Tale, chapter 9
        [11] = { cost = 15000, id =  4073 }, -- Copy of Rem's Tale, chapter 10
        [12] = { cost =  5000, id = 28546 }, -- Capacity Ring
        [13] = { cost = 10000, id =  9009 }, -- Etched Memory
    },

    -- [2] Skill-increasing tomes: removed (Relaunch).
    [2] = {},

    [3] = -- Equipment (Lv.1 - 9)
    {
        [ 0] = { cost = 50, id = 16385 }, -- Cesti
        [ 1] = { cost = 50, id = 16390 }, -- Bronze knuckles
        [ 2] = { cost = 50, id = 16391 }, -- Brass knuckles
        [ 3] = { cost = 50, id = 16448 }, -- Bronze dagger
        [ 4] = { cost = 50, id = 16465 }, -- Bronze knife
        [ 5] = { cost = 50, id = 16454 }, -- Blind dagger
        [ 6] = { cost = 50, id = 16471 }, -- Blind knife
        [ 7] = { cost = 50, id = 16449 }, -- Brass dagger
        [ 8] = { cost = 50, id = 16600 }, -- Wax sword
        [ 9] = { cost = 50, id = 16530 }, -- Xiphos
        [10] = { cost = 50, id = 16640 }, -- Bronze axe
        [11] = { cost = 50, id = 16641 }, -- Brass axe
        [12] = { cost = 50, id = 16704 }, -- Butterfly axe
        [13] = { cost = 50, id = 16709 }, -- Inferno axe
        [14] = { cost = 50, id = 16768 }, -- Bronze zaghnal
        [15] = { cost = 50, id = 16832 }, -- Harpoon
        [16] = { cost = 50, id = 16833 }, -- Bronze spear
        [17] = { cost = 50, id = 16896 }, -- Kunai
        [18] = { cost = 50, id = 16900 }, -- Wakizashi
        [19] = { cost = 50, id = 16966 }, -- Tachi
        [20] = { cost = 50, id = 17024 }, -- Ash club
        [21] = { cost = 50, id = 17034 }, -- Bronze mace
        [22] = { cost = 50, id = 17042 }, -- Bronze hammer
        [23] = { cost = 50, id = 17059 }, -- Bronze rod
        [24] = { cost = 50, id = 17050 }, -- Willow wand
        [25] = { cost = 50, id = 17088 }, -- Ash staff
        [26] = { cost = 50, id = 17095 }, -- Ash pole
        [27] = { cost = 50, id = 17152 }, -- Shortbow
        [28] = { cost = 50, id = 17160 }, -- Longbow
        [29] = { cost = 50, id = 17153 }, -- Self bow
        [30] = { cost = 50, id = 17216 }, -- Light crossbow
        [31] = { cost = 50, id = 19224 }, -- Musketoon
        [32] = { cost = 50, id = 17345 }, -- Flute
        [33] = { cost = 50, id = 17344 }, -- Cornette
        [34] = { cost = 50, id = 17347 }, -- Piccolo
        [35] = { cost = 50, id = 17353 }, -- Maple harp
        [36] = { cost = 50, id = 12448 }, -- Bronze cap
        [37] = { cost = 50, id = 12576 }, -- Bronze harness
        [38] = { cost = 50, id = 12704 }, -- Bronze mittens
        [39] = { cost = 50, id = 12832 }, -- Bronze subligar
        [40] = { cost = 50, id = 12960 }, -- Bronze Leggings
        [41] = { cost = 50, id = 12472 }, -- Circlet
        [42] = { cost = 50, id = 12600 }, -- Robe
        [43] = { cost = 50, id = 12728 }, -- Cuffs
        [44] = { cost = 50, id = 12856 }, -- Slops
        [45] = { cost = 50, id = 12984 }, -- Ash clogs
        [46] = { cost = 50, id = 12440 }, -- Leather bandana
        [47] = { cost = 50, id = 12568 }, -- Leather vest
        [48] = { cost = 50, id = 12696 }, -- Leather gloves
        [49] = { cost = 50, id = 12824 }, -- Leather trousers
        [50] = { cost = 50, id = 12952 }, -- Leather highboots
        [51] = { cost = 50, id = 12608 }, -- Tunic
        [52] = { cost = 50, id = 12736 }, -- Mitts
        [53] = { cost = 50, id = 12864 }, -- Slacks
        [54] = { cost = 50, id = 12992 }, -- Solea
        [55] = { cost = 50, id = 12456 }, -- Hachimaki
        [56] = { cost = 50, id = 12584 }, -- Kenpogi
        [57] = { cost = 50, id = 12712 }, -- Tekko
        [58] = { cost = 50, id = 12840 }, -- Sitabaki
        [59] = { cost = 50, id = 12968 }, -- Kyahan
        [60] = { cost = 50, id = 12289 }, -- Lauan shield
        [61] = { cost = 50, id = 12415 }, -- Shell shield
        [62] = { cost = 50, id = 12290 }, -- Maple shield
        [63] = { cost = 50, id = 12299 }, -- Aspis
    },

    [4] = -- Equipment (Lv.10 - 19)
    {
        [ 0] = { cost =  60, id = 16407 }, -- Brass baghnakhs
        [ 1] = { cost =  60, id = 16450 }, -- Dagger
        [ 2] = { cost =  60, id = 16466 }, -- Knife
        [ 3] = { cost =  80, id = 16455 }, -- Baselard
        [ 4] = { cost =  70, id = 16572 }, -- Bee spatha
        [ 5] = { cost =  80, id = 16531 }, -- Brass xiphos
        [ 6] = { cost = 132, id = 16536 }, -- Iron sword
        [ 7] = { cost =  60, id = 16583 }, -- Claymore
        [ 8] = { cost =  98, id = 16588 }, -- Flame Claymore
        [ 9] = { cost =  93, id = 16642 }, -- Bone axe
        [10] = { cost =  60, id = 16649 }, -- Bone pick
        [11] = { cost =  91, id = 16705 }, -- Greataxe
        [12] = { cost =  60, id = 16769 }, -- Brass zaghnal
        [13] = { cost = 177, id = 16774 }, -- Scythe
        [14] = { cost =  60, id = 16834 }, -- Brass spear
        [15] = { cost =  60, id = 18076 }, -- Spark spear
        [16] = { cost =  93, id = 16919 }, -- Shinobi-gatana
        [17] = { cost =  89, id = 16906 }, -- Mokuto
        [18] = { cost =  68, id = 16960 }, -- Uchigatana
        [19] = { cost = 135, id = 16982 }, -- Nodachi
        [20] = { cost =  60, id = 17043 }, -- Brass hammer
        [21] = { cost =  60, id = 17081 }, -- Brass rod
        [22] = { cost =  60, id = 17025 }, -- Chestnut club
        [23] = { cost =  60, id = 17051 }, -- Yew wand
        [24] = { cost =  81, id = 17035 }, -- Mace
        [25] = { cost =  60, id = 17089 }, -- Holly staff
        [26] = { cost =  60, id = 17096 }, -- Holly pole
        [27] = { cost =  99, id = 17161 }, -- Power bow
        [28] = { cost =  60, id = 17217 }, -- Crossbow
        [29] = { cost = 200, id = 17257 }, -- Bandit's gun
        [30] = { cost = 187, id = 17265 }, -- Tanegashima
        [31] = { cost =  86, id = 17351 }, -- Gemshorn
        [32] = { cost =  60, id = 17354 }, -- Harp
        [33] = { cost =  60, id = 12432 }, -- Faceguard
        [34] = { cost =  60, id = 12560 }, -- Scale mail
        [35] = { cost =  60, id = 12688 }, -- Scale finger gauntlets
        [36] = { cost =  60, id = 12816 }, -- Scale cuisses
        [37] = { cost =  60, id = 12944 }, -- Scale greaves
        [38] = { cost =  60, id = 12464 }, -- Headgear
        [39] = { cost =  60, id = 12592 }, -- Doublet
        [40] = { cost =  60, id = 12720 }, -- Gloves
        [41] = { cost =  60, id = 12848 }, -- Brais
        [42] = { cost =  60, id = 12976 }, -- Gaiters
        [43] = { cost =  65, id = 12454 }, -- Bone mask
        [44] = { cost =  60, id = 12582 }, -- Bone Harness
        [45] = { cost =  60, id = 12710 }, -- Bone mittens
        [46] = { cost =  60, id = 12834 }, -- Bone Subligar
        [47] = { cost =  60, id = 12966 }, -- Bone Leggings
        [48] = { cost =  60, id = 12441 }, -- Lizard helm
        [49] = { cost =  60, id = 12569 }, -- Lizard jerkin
        [50] = { cost =  60, id = 12697 }, -- Lizard gloves
        [51] = { cost =  60, id = 12825 }, -- Lizard trousers
        [52] = { cost =  60, id = 12953 }, -- Lizard Ledelsens
        [53] = { cost =  60, id = 12291 }, -- Elm shield
    },

    [5] = -- Equipment (Lv.20 - 29)
    {
        [ 0] = { cost =  87, id = 16392 }, -- Metal knuckles
        [ 1] = { cost = 144, id = 16406 }, -- Baghnakhs
        [ 2] = { cost =  99, id = 16387 }, -- Poison cesti
        [ 3] = { cost = 103, id = 16473 }, -- Kukri
        [ 4] = { cost =  96, id = 16496 }, -- Poison dagger
        [ 5] = { cost = 123, id = 16472 }, -- Poison knife
        [ 6] = { cost = 143, id = 16451 }, -- Mythril dagger
        [ 7] = { cost = 170, id = 16517 }, -- Degen
        [ 8] = { cost = 215, id = 16513 }, -- Tuck
        [ 9] = { cost = 269, id = 16532 }, -- Gladius
        [10] = { cost =  70, id = 16593 }, -- Plain sword
        [11] = { cost = 349, id = 16594 }, -- Inferno sword
        [12] = { cost = 136, id = 16643 }, -- Battleaxe
        [13] = { cost =  83, id = 17942 }, -- Tomahawk
        [14] = { cost = 209, id = 16770 }, -- Zaghnal
        [15] = { cost =  84, id = 16835 }, -- Spear
        [16] = { cost = 103, id = 17776 }, -- Hibari
        [17] = { cost = 120, id = 16907 }, -- Busuto
        [18] = { cost = 109, id = 17044 }, -- Warhammer
        [19] = { cost =  70, id = 17090 }, -- Elm staff
        [20] = { cost =  70, id = 17424 }, -- Spiked club
        [21] = { cost = 132, id = 17154 }, -- Wrapped bow
        [22] = { cost = 520, id = 17248 }, -- Arquebus
        [23] = { cost = 432, id = 17259 }, -- Pirate's gun
        [24] = { cost =  70, id = 15207 }, -- Trader's chapeau
        [25] = { cost =  71, id = 14446 }, -- Trader's saio
        [26] = { cost =  70, id = 14053 }, -- Trader's cuffs
        [27] = { cost =  70, id = 15404 }, -- Trader's slops
        [28] = { cost =  70, id = 15343 }, -- Trader's pigaches
        [29] = { cost = 171, id = 12424 }, -- Iron mask
        [30] = { cost = 264, id = 12552 }, -- Chainmail
        [31] = { cost = 141, id = 12680 }, -- Chain mittens
        [32] = { cost = 210, id = 12808 }, -- Chain hose
        [33] = { cost = 129, id = 12936 }, -- Greaves
        [34] = { cost = 195, id = 15165 }, -- Shade tiara
        [35] = { cost = 525, id = 14426 }, -- Shade harness
        [36] = { cost = 301, id = 14858 }, -- Shade mittens
        [37] = { cost = 354, id = 14327 }, -- Shade tights
        [38] = { cost = 379, id = 15315 }, -- Shade leggings
        [39] = { cost = 250, id = 15167 }, -- Eisenschaller
        [40] = { cost = 250, id = 14431 }, -- Eisenbrust
        [41] = { cost = 170, id = 14860 }, -- Eisenhentzes
        [42] = { cost = 140, id = 14329 }, -- Eisendiechlings
        [43] = { cost = 290, id = 15317 }, -- Eisenschuhs
        [44] = { cost =  70, id = 15163 }, -- Seer's crown
        [45] = { cost = 234, id = 14424 }, -- Seer's tunic
        [46] = { cost =  97, id = 14856 }, -- Seer's mitts
        [47] = { cost = 137, id = 14325 }, -- Seer's slacks
        [48] = { cost = 157, id = 15313 }, -- Seer's pumps
        [49] = { cost =  83, id = 12292 }, -- Mahogany shield
        [50] = { cost =  70, id = 12414 }, -- Turtle shield
        [51] = { cost = 153, id = 12306 }, -- Kite shield
    },

    [6] = -- Equipment (Lv.30 - 39)
    {
        [ 0] = { cost = 182, id = 16411 }, -- Claws
        [ 1] = { cost = 194, id = 16399 }, -- Katars
        [ 2] = { cost = 230, id = 16393 }, -- Mythril Knuckles
        [ 3] = { cost = 317, id = 19105 }, -- Thug's jambiya
        [ 4] = { cost = 248, id = 16475 }, -- Mythril kukri
        [ 5] = { cost = 198, id = 16456 }, -- Mythril baselard
        [ 6] = { cost = 334, id = 16545 }, -- Broadsword
        [ 7] = { cost = 497, id = 16576 }, -- Hunting sword
        [ 8] = { cost = 430, id = 16581 }, -- Holy sword
        [ 9] = { cost = 493, id = 16549 }, -- Divine sword
        [10] = { cost = 532, id = 18375 }, -- Falx
        [11] = { cost = 525, id = 16584 }, -- Mythril claymore
        [12] = { cost =  80, id = 17955 }, -- Plain pick
        [13] = { cost = 540, id = 16644 }, -- Mythril axe
        [14] = { cost = 297, id = 18214 }, -- Voulge
        [15] = { cost = 515, id = 16706 }, -- Heavy axe
        [16] = { cost = 154, id = 16845 }, -- Lance
        [17] = { cost = 144, id = 18078 }, -- Spark lance
        [18] = { cost = 135, id = 16836 }, -- Halberd
        [19] = { cost = 130, id = 18122 }, -- Broach lance
        [20] = { cost = 168, id = 16901 }, -- Kodachi
        [21] = { cost = 230, id = 16973 }, -- Homura
        [22] = { cost = 325, id = 16962 }, -- Ashura
        [23] = { cost = 324, id = 16970 }, -- Hosodachi
        [24] = { cost = 228, id = 17045 }, -- Maul
        [25] = { cost =  80, id = 17052 }, -- Chestnut wand
        [26] = { cost =  80, id = 17061 }, -- Mythril rod
        [27] = { cost = 226, id = 17036 }, -- Mythril mace
        [28] = { cost = 319, id = 17080 }, -- Holy maul
        [29] = { cost =  80, id = 17097 }, -- Elm pole
        [30] = { cost = 122, id = 17091 }, -- Oak staff
        [31] = { cost = 312, id = 17162 }, -- Great bow
        [32] = { cost = 125, id = 17155 }, -- Composite bow
        [33] = { cost = 171, id = 17218 }, -- Zamburak
        [34] = { cost = 340, id = 18715 }, -- Mars's hexagun
        [35] = { cost = 185, id = 18704 }, -- Darksteel hexagun
        [36] = { cost = 210, id = 17348 }, -- Traversiere
        [37] = { cost = 250, id = 17355 }, -- Rose harp
        [38] = { cost =  80, id = 15164 }, -- Garish crown
        [39] = { cost = 265, id = 14425 }, -- Garish tunic
        [40] = { cost =  84, id = 14857 }, -- Garish mitts
        [41] = { cost = 190, id = 14326 }, -- Garish slacks
        [42] = { cost = 124, id = 15314 }, -- Garish pumps
        [43] = { cost =  80, id = 15161 }, -- Noct beret
        [44] = { cost = 198, id = 14422 }, -- Noct doublet
        [45] = { cost = 136, id = 14854 }, -- Noct gloves
        [46] = { cost = 135, id = 14323 }, -- Noct brais
        [47] = { cost = 192, id = 15311 }, -- Noct gaiters
        [48] = { cost = 174, id = 12610 }, -- Cloak
        [49] = { cost =  82, id = 12738 }, -- Linen mitts
        [50] = { cost = 188, id = 12866 }, -- Linen slacks
        [51] = { cost = 110, id = 12994 }, -- Shoes
        [52] = { cost =  85, id = 12450 }, -- Padded cap
        [53] = { cost = 393, id = 12578 }, -- Padded armor
        [54] = { cost = 216, id = 12706 }, -- Iron mittens
        [55] = { cost = 316, id = 12836 }, -- Iron subligar
        [56] = { cost = 196, id = 12962 }, -- Leggings
        [57] = { cost = 125, id = 12466 }, -- Red cap
        [58] = { cost = 250, id = 12594 }, -- Gambison
        [59] = { cost =  80, id = 12722 }, -- Bracers
        [60] = { cost = 175, id = 12850 }, -- Hose
        [61] = { cost = 200, id = 12978 }, -- Socks
        [62] = { cost = 285, id = 12475 }, -- Velvet hat
        [63] = { cost = 425, id = 12603 }, -- Velvet robe
        [64] = { cost = 240, id = 12731 }, -- Velvet cuffs
        [65] = { cost = 347, id = 12859 }, -- Velvet slops
        [66] = { cost = 134, id = 12987 }, -- Ebony sabots
        [67] = { cost = 302, id = 13871 }, -- Iron visor
        [68] = { cost = 464, id = 13783 }, -- Iron scale mail
        [69] = { cost = 248, id = 14001 }, -- Iron finger gauntlets
        [70] = { cost = 226, id = 14118 }, -- Iron greaves
        [71] = { cost =  80, id = 12300 }, -- Targe
        [72] = { cost = 195, id = 12293 }, -- Oak shield
        [73] = { cost = 256, id = 12364 }, -- Nymph shield
    },

    -- [7]-[10] Equipment Lv.40+: removed (Relaunch).
    [7] = {},
    [8] = {},
    [9] = {},
    [10] = {},
    [12] = -- Alter Ego Extravaganza Trusts
    {
        [10133] = { cost =  500, id = xi.item.CIPHER_OF_F_COFFINS_ALTER_EGO }, -- F. Coffin
        [10138] = { cost =  500, id = xi.item.CIPHER_OF_CIDS_ALTER_EGO }, -- Cid
        [10148] = { cost =  500, id = xi.item.CIPHER_OF_GILGAMESHS_ALTER_EGO }, -- Gilgamesh
        [10152] = { cost =  500, id = xi.item.CIPHER_OF_QULTADAS_ALTER_EGO }, -- Qultada
        [10181] = { cost =  500, id = xi.item.CIPHER_OF_KINGS_ALTER_EGO }, -- King
    },

    -- [20]/[30] A.M.A.N. voucher exchange: removed (Relaunch).
    [20] = {},

}

function xi.sparkshop.onTrade(player, npc, trade, eventid)
    -- A.M.A.N. voucher deposit / exchange removed (Relaunch).
    if trade:getItemQty(xi.item.COPPER_AMAN_VOUCHER) > 0 then
        player:printToPlayer(
            '[Sparks] A.M.A.N. voucher exchange is no longer available here.',
            xi.msg.channel.SYSTEM_3)
    end
end

function xi.sparkshop.onTrigger(player, npc, event)
    local sparks = player:getCurrency('spark_of_eminence')
    local remainingLimit = xi.settings.main.WEEKLY_EXCHANGE_LIMIT - player:getCharVar('weekly_sparks_spent')
    local cipher = xi.extravaganza.campaignActive() * 16 * 65536 -- Trust Alter Ego Extravaganza
    local naakual = 0 -- TODO: Naakual Seven Treasures Item Logic

    -- vouchers param forced to 0 so the A.M.A.N. exchange branch stays inert.
    player:startEvent(event, 0, sparks, 0, naakual, cipher, remainingLimit)
end

function xi.sparkshop.onEventUpdate(player, csid, option, npc)
    local sparks = player:getCurrency('spark_of_eminence')
    local weeklySparksSpent = player:getCharVar('weekly_sparks_spent')
    local remainingLimit = xi.settings.main.WEEKLY_EXCHANGE_LIMIT - weeklySparksSpent
    local category = bit.band(option, 0xFF)
    local selection = bit.rshift(option, 16)

    -- Relaunch: no skill tomes (2), no Lv.40+ gear (7-10), no A.M.A.N. voucher
    -- currency/provisions (20/30). Lv.1-39 gear (3-6) and Items/Trusts remain.
    if category == 2 then
        player:updateEvent(sparks, 0, 0, 0, 0, remainingLimit)
        player:printToPlayer('[Sparks] Skill-increasing tomes are no longer sold here.', xi.msg.channel.SYSTEM_3)
        return
    end

    if category >= 7 and category <= 10 then
        player:updateEvent(sparks, 0, 0, 0, 0, remainingLimit)
        player:printToPlayer(
            '[Sparks] Level 40+ gear is no longer sold here. Farm Hunting League medals at Escha - Zi\'Tah for gear.',
            xi.msg.channel.SYSTEM_3)
        return
    end

    if category == 20 or category == 30 then
        player:updateEvent(sparks, 0, 0, 0, 0, remainingLimit)
        player:printToPlayer('[Sparks] A.M.A.N. voucher exchange is no longer available here.', xi.msg.channel.SYSTEM_3)
        return
    end

    local qty = 1
    local requestedQty = bit.band(bit.rshift(option, 10), 0x3F)

    -- qty > 1 only for remaining multi-buy categories (none currently; kept for ammo specials)
    if category == 2 or category == 20 or category == 30 then
        qty = requestedQty
    end

    -- Sparks item purchases (Items, Lv.1-39 gear, Trust ciphers).
    if (category >= 1 and category <= 6) or category == 12 then
        local itemCategory = optionToItem[category]
        local item         = itemCategory and itemCategory[selection]

        if not item then
            -- No catalog entry for this menu slot. Refresh the menu instead of
            -- returning silently: a bare return sends NO updateEvent, so the
            -- client locks forever waiting for a reply (the Rolandienne freeze).
            player:updateEvent(sparks, 0, 0, 0, 0, remainingLimit)
            return
        end

        local cost = item.cost * qty

        -- handles eminent ammo (catalog emptied for Lv.99, kept for safety)
        local emminentAmmoCosts = { [21302] = 5000, [21316] = 5000, [21331] = 5000, [21355] = 7000 }
        local ammoCost = emminentAmmoCosts[item.id]
        if ammoCost then
            qty  = 99
            cost = ammoCost
        end

        -- verifies and finishes transaction
        if cost > remainingLimit and xi.settings.main.ENABLE_EXCHANGE_LIMIT == 1 then
            player:messageSpecial(zones[player:getZoneID()].text.MAX_SPARKS_LIMIT_REACHED, xi.settings.main.WEEKLY_EXCHANGE_LIMIT)
        elseif sparks >= cost then
            if npcUtil.giveItem(player, { { item.id, qty } }) then
                sparks = sparks - cost
                player:delCurrency('spark_of_eminence', cost)
                if xi.settings.main.ENABLE_EXCHANGE_LIMIT == 1 then
                    remainingLimit = remainingLimit - cost
                    player:setCharVar('weekly_sparks_spent', weeklySparksSpent + cost)
                end
            end
        else
            player:messageSpecial(zones[player:getZoneID()].text.NOT_ENOUGH_SPARKS)
        end

        player:updateEvent(sparks, 0, 0, 0, 0, remainingLimit)
    else
        -- Any category the handler doesn't recognize still gets a menu refresh,
        -- so the client can never wedge waiting for a reply that never comes.
        player:updateEvent(sparks, 0, 0, 0, 0, remainingLimit)
    end
end

function xi.sparkshop.onEventFinish(player, csid, option, npc)
end
