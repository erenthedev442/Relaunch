-----------------------------------
-- func: shop (category) (subcategory)
-- desc: Opens an NPC-style item shop menu for players.
--       Categories: general, weapons, armor, consumables, food
--       Usage: !shop  OR  !shop weapons
--       (Augment catalysts are NO LONGER sold for gil -- they drop from NMs.
--        Farm them, then trade to the Augment Moogle at GM Home to apply.)
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
         { 27557,   100000 },  --Trizek Ring
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
        { xi.item.TRUMP_CARD,                 50 },  -- Trump Card
        { xi.item.TRUMP_CARD_CASE,            50 },  -- Trump Card Case
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
        { xi.item.BOTTLE_OF_ANTACID,         500 },
        { xi.item.VILE_ELIXIR,             10000 },
        { xi.item.VILE_ELIXIR_P1,          18000 },
    },

    weapons =
    {
        { 21460,    15000 },  -- Matre Bell   (Lv.1 GEO handbell, MP+5)
        { 21463,   150000 },  -- Nepote Bell  (Lv.99 GEO handbell, Geomancy+5)
        { 17859,    10000 },  -- Animator     (PUP, Lv1)
        { 17857,    50000 },  -- Animator +1  (PUP, Lv71)
        { 21392,  1000000 },  -- Animator Z   (PUP, iLvl 119) -- Animator P / P+1 / P II line reserved for !hunt
    },

    armor =
    {
        { 11009,  300000 }, -- Shaper's Shawl (back, crafting/utility)
        { 28509,  300000 }, -- She-Slime Earring
        { 28511,  300000 }, -- Slime Earring
        { 10293,   50000 }, -- Chocobo Shirt
        { 11811,   50000 }, -- Destrier Beret
        { xi.item.CASSIE_EARRING, 300000 },
        { 14724,  600000 }, -- Moldavite Earring
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
        { 5664,                                 5000 },  -- Salmon Sushi +1      -- RACC, DEX
        { 5666,                                 5000 },  -- Fin Sushi +1         -- RACC, DEX+8

        -- ===== Additional sushi +1 =====
        { 5160,                                 5000 },  -- Urchin Sushi +1      -- MND, CHR (support)
        { 5179,                                 5000 },  -- Dorado Sushi +1      -- DEX, AGI
        { 5216,                                 5000 },  -- Tentacle Sushi +1    -- INT, Macc
        { 5692,                                 5000 },  -- Shrimp Sushi +1      -- STR, DEX
        { 5694,                                 5000 },  -- Octopus Sushi +1     -- STR, VIT

        -- ===== Hybrid =====
        { 5199,                                 5000 },  -- Spaghetti Carbonara +1 -- STR / VIT / HP (DD + survivability)

        -- ===== Tank =====
        { 5744,                                 5000 },  -- Marinara Pizza +1    -- Enmity (PLD / RUN)
        { 4330,                                 5000 },  -- Witch Risotto        -- Magic defense (mage burns)
    },

    -- Corsair dice: each die TEACHES its Phantom Roll when used by a COR of the
    -- required level (e.g. Monk Die -> Monk's Roll). Rolls are item-taught on
    -- this server, so a cheap dice shop lets COR players assemble their full kit
    -- without AH hunting. 1 gil each.  (!shop dice)
    dice =
    {
        { 5477, 1 },  -- Warrior Die       -> Fighter's Roll
        { 5478, 1 },  -- Monk Die          -> Monk's Roll
        { 5479, 1 },  -- White Mage Die    -> Healer's Roll
        { 5480, 1 },  -- Black Mage Die    -> Wizard's Roll
        { 5481, 1 },  -- Red Mage Die      -> Warlock's Roll
        { 5482, 1 },  -- Thief Die         -> Rogue's Roll
        { 5483, 1 },  -- Paladin Die       -> Gallant's Roll
        { 5484, 1 },  -- Dark Knight Die   -> Chaos Roll
        { 5485, 1 },  -- Beastmaster Die   -> Beast Roll
        { 5486, 1 },  -- Bard Die          -> Choral Roll
        { 5487, 1 },  -- Ranger Die        -> Hunter's Roll
        { 5488, 1 },  -- Samurai Die       -> Samurai Roll
        { 5489, 1 },  -- Ninja Die         -> Ninja Roll
        { 5490, 1 },  -- Dragoon Die       -> Drachen Roll
        { 5491, 1 },  -- Summoner Die      -> Evoker's Roll
        { 5492, 1 },  -- Blue Mage Die     -> Magus's Roll
        { 5493, 1 },  -- Corsair Die       -> Corsair's Roll
        { 5494, 1 },  -- Puppetmaster Die  -> Puppet Roll
        { 5495, 1 },  -- Dancer Die        -> Dancer's Roll
        { 5496, 1 },  -- Scholar Die       -> Scholar's Roll
        { 5497, 1 },  -- Bolter's Die      -> Bolter's Roll
        { 5498, 1 },  -- Caster's Die      -> Caster's Roll
        { 5499, 1 },  -- Courser's Die     -> Courser's Roll
        { 5500, 1 },  -- Blitzer's Die     -> Blitzer's Roll
        { 5501, 1 },  -- Tactician's Die   -> Tactician's Roll
        { 5502, 1 },  -- Allies' Die       -> Allies' Roll
        { 5503, 1 },  -- Miser's Die       -> Miser's Roll
        { 5504, 1 },  -- Companion's Die   -> Companion's Roll
        { 5505, 1 },  -- Avenger's Die     -> Avenger's Roll
        { 6368, 1 },  -- Geomancer Die     -> Naturalist's Roll
        { 6369, 1 },  -- Rune Fencer Die   -> Runeist's Roll
    },

    -- Ranged ammo for RNG / COR / NIN. A leveling-friendly ladder per type
    -- (cheap stacks, so a leveler is never stranded without arrows) plus a
    -- Lv99 endgame option. Shops sell per-unit; buy a stack of up to 99.
    ammo =
    {
        -- Arrows (bows)
        { 17319,   2 },  -- Bone Arrow      (Lv7)
        { 17320,   3 },  -- Iron Arrow      (Lv14)
        { 18155,   5 },  -- Scorpion Arrow  (Lv40)
        { 18159,  10 },  -- Demon Arrow     (Lv60)
        { 17325,  20 },  -- Kabura Arrow    (Lv70)
        { 21297,  50 },  -- Chrono Arrow    (Lv99)
        { 21295,  50 },  -- Beryllium Arrow (Lv99, DMG 77)
        { 21302,  50 },  -- Eminent Arrow   (Lv99, EX, DMG 79)
        { 21310,  50 },  -- Raetic Arrow    (Lv99, DMG 80)
        { 21307, 100 },  -- Achiyalabopa Arrow  (Lv99/iLvl119, RNG)
        -- Bolts (crossbows)
        { 17336,   2 },  -- Crossbow Bolt   (Lv1)
        { 17337,   5 },  -- Mythril Bolt    (Lv40)
        { 19197,  20 },  -- Fusion Bolt     (Lv79)
        { 21316,  50 },  -- Eminent Bolt    (Lv99)
        { 21311,  50 },  -- Quelling Bolt   (Lv99, RNG, Add. Effect: Slow)
        { 21321, 100 },  -- Achiyalabopa Bolt   (Lv99/iLvl119, RNG)
        -- Bullets (guns)
        { 17343,   2 },  -- Bronze Bullet   (Lv1)
        { 17340,   3 },  -- Bullet          (Lv22)
        { 18160,   5 },  -- Spartan Bullet  (Lv30)
        { 17341,   8 },  -- Silver Bullet   (Lv50)
        { 18723,  20 },  -- Steel Bullet    (Lv66)
        { 21331,  50 },  -- Eminent Bullet  (Lv99)
        { 21337, 100 },  -- Achiyalabopa Bullet (Lv99/iLvl119, RNG)
        -- Infinite-ammo WAIST pouches: wear one + a stack of any bullets and the
        -- bullets are never consumed (RECYCLE 100), plus ranged stats. RARE, hold
        -- 1. (See bullet_pouches_waist.sql.)
        { 26348, 50000 },  -- Living Bullet Pouch      (waist, MATT35/MACC25, COR)
        { 26349, 50000 },  -- Devastating Bullet Pouch (waist, RACC35/MACC35, RNG/COR)
        { 26347, 50000 },  -- Eradicating Bullet Pouch (waist, RATT30/RACC30, RNG)
        { 26350, 50000 },  -- Chrono Bullet Pouch      (waist, RATT20/RACC20, RNG/COR)
        -- Job-specific throwing weapons
        { 18259,  50 },  -- Angon           (Lv62, DRG)
        { 18258,  50 },  -- Throwing Tomahawk (Lv75, WAR)
        -- Shuriken (NIN throwing)
        { 17301,   3 },  -- Shuriken        (Lv18)
        { 17302,   5 },  -- Juji Shuriken   (Lv28)
        { 17303,   8 },  -- Manji Shuriken  (Lv48)
        { 17304,  20 },  -- Fuma Shuriken   (Lv60)
        { 21353,  50 },  -- Happo Shuriken  (Lv99)
        -- Sachets (throwing, ammo slot)
        { 21383,  50 },  -- Eminent Sachet  (Lv99)
    },

    -- Ninja TOOLBAGS at 1 gil. Each toolbag, when USED, opens into a full stack of
    -- 99 of that tool (scripts/items/toolbag_*.lua) -- so one 1-gil purchase = 99
    -- charges, and toolbags stack to 12 (a NIN can carry ~1,188 charges of one tool
    -- in a single inventory slot). The three "card" toolbags are the universal tools
    -- a MAIN-job NIN can sub for ANY elemental ninjutsu (see HasNinjaTool in
    -- battleutils.cpp). (A NIN *subjob* still needs the specific tool, e.g. Shihei.)
    ninja =
    {
        -- Universal toolbags -- a MAIN-job NIN can use these for ANY elemental ninjutsu.
        { 5867, 1 },  -- Toolbag (Ino)   -> 99x Inoshishinofuda
        { 5868, 1 },  -- Toolbag (Shika) -> 99x Shikanofuda
        { 5869, 1 },  -- Toolbag (Cho)   -> 99x Chonofuda
        -- Elemental wheel toolbags -- the 6 per-element tools for Katon/Hyoton/Huton/
        -- Raiton/Doton/Suiton ninjutsu. Main NIN can use the universal cards above
        -- instead; these are needed when NIN is a subjob or for specific element choice.
        { 5308, 1 },  -- Toolbag (Uchi)  -> 99x Uchitake       -- Katon (fire)
        { 5309, 1 },  -- Toolbag (Tsura) -> 99x Tsurara        -- Hyoton (ice)
        { 5310, 1 },  -- Toolbag (Kawa)  -> 99x Kawahori-ogi   -- Huton (wind)
        { 5312, 1 },  -- Toolbag (Hira)  -> 99x Hiraishin      -- Raiton (lightning)
        { 5311, 1 },  -- Toolbag (Maki)  -> 99x Makibishi      -- Doton (earth)
        { 5313, 1 },  -- Toolbag (Mizu)  -> 99x Mizu-deppo     -- Suiton (water)
        -- Specific toolbags -- a SUBJOB ninja gets no substitution, so it needs these
        -- by name (Shihei is the big one: Utsusemi). Also handy for main-NIN utility.
        { 5314, 1 },  -- Toolbag (Shihe) -> 99x Shihei          -- Utsusemi: Ichi/Ni (shadows)
        { 5417, 1 },  -- Toolbag (Sanja) -> 99x Sanjaku-tenugui -- Tonko: Ichi/Ni (Invisible)
        { 5317, 1 },  -- Toolbag (Sai)   -> 99x Sairui-ran      -- Monomi: Ichi (Sneak)
        { 5315, 1 },  -- Toolbag (Jusa)  -> 99x Jusatsu         -- Kurayami: Ichi/Ni (Blind)
        { 5318, 1 },  -- Toolbag (Kodo)  -> 99x Kodoku          -- Dokumori: Ichi (poison / enmity)
        { 5316, 1 },  -- Toolbag (Kagi)  -> 99x Kaginawa        -- Hojo: Ichi/Ni (Slow)
        { 5319, 1 },  -- Toolbag (Shino) -> 99x Shinobi-tabi    -- Tonko: Ichi/Ni (Sneak/Invisible)
        { 5734, 1 },  -- Toolbag (Soshi) -> 99x Soshi           -- Kakka: Ichi (Enfire/etc.)
        { 5863, 1 },  -- Toolbag (Kaben) -> 99x Kabenro         -- Yonin: Ichi (hate-down ninjutsu)
        { 5864, 1 },  -- Toolbag (Jinko) -> 99x Jinko           -- Innin: Ichi (acc/eva from behind)
        { 5865, 1 },  -- Toolbag (Ryuno) -> 99x Ryuno           -- Migawari: Ichi (1-hit dodge)
        { 5866, 1 },  -- Toolbag (Moku)  -> 99x Mokujin         -- Sange (shurikenspam JA)
        { 6265, 1 },  -- Toolbag (Ranka) -> 99x Ranka           -- Katon: San / higher-tier fire
        { 6266, 1 },  -- Toolbag (Furu)  -> 99x Furusumi        -- Doton: San / higher-tier earth
    },
}

-----------------------------------
-- Augment catalysts: the gil-purchase shop was REMOVED for relaunch (owner
-- request 2026-06-24). Catalysts must now be FARMED FROM NMs and traded to the
-- Augment Moogle at GM Home -- there is no longer a gil shortcut. The whole
-- "!shop augments" category (catalog pull, 13 thematic groups, the EXP/Capacity
-- 'points' group, and the Maat's Cap prepend) is gone; see validCategories and
-- the onTrigger handler below.

-----------------------------------
-- BST pets: jug broths (summon a pet) + pet food (heal/feed it).
-- Split into two sub-pages because a FFXI shop window holds only 16 items:
--   !shop pets        -> curated best/most-used jug pets
--   !shop pets food   -> pet food biscuits
-- Buy a broth, then use Call Beast / Bestial Loyalty to summon it.
-- NOTE: the broth->pet link is data/C++-driven, so the pet labels below are
-- best-effort -- players buy by the broth's in-game name. Prices easily tuned.
-----------------------------------
local petStock =
{
    jugs =
    {
        { 17902, 1000 },  -- Lucky Broth        -> CourierCarrie (crab): Metallic Body, heavy PDT -- top tank/utility jug
        { 17917, 1000 },  -- Bubbly Broth       -- strong melee-DD jug
        { 21498, 1000 },  -- Crackling Broth    -- melee-DD jug
        { 21496, 1000 },  -- Furious Broth      -- melee-DD jug
        { 21497, 1000 },  -- Rapid Broth        -- fast multi-hit jug
        { 21493, 1000 },  -- Deepwater Broth    -- ranged/bird jug
        { 21495, 1000 },  -- Heavenly Broth     -- utility jug
        { 21494, 1000 },  -- Wetlands Broth     -- utility jug
        { 21449, 1000 },  -- Dire Broth         -- melee-DD jug
        { 21450, 1000 },  -- Electrified Broth  -- thunder-DD jug
        { 21444, 1000 },  -- Livid Broth        -- melee-DD jug
        { 21445, 1000 },  -- Lyrical Broth      -- support jug
        { 21446, 1000 },  -- Airy Broth         -- utility jug
        { 21440, 1000 },  -- Sugary Broth       -- DD jug
        { 21441, 1000 },  -- Glazed Broth       -- DD jug (HQ broth)
        { 17922, 1000 },  -- Blackwater Broth   -- DD jug
    },

    food =
    {
        { 17016, 500 },  -- Pet Food Alpha Biscuit
        { 17017, 500 },  -- Pet Food Beta Biscuit
        { 17018, 500 },  -- Pet Food Gamma Biscuit
        { 17019, 500 },  -- Pet Food Delta Biscuit
        { 17020, 500 },  -- Pet Food Epsilon Biscuit
        { 17021, 500 },  -- Pet Food Zeta Biscuit
        { 17022, 500 },  -- Pet Food Eta Biscuit
        { 17023, 500 },  -- Pet Food Theta Biscuit
    },
}

-- Reforged armor (FREE claim): pulls each job's ilvl-109 AF/Relic/Empy BASE pieces
-- live from modules/custom/lua/reforge_catalog, so this stays in sync with the
-- Reforge system's own data. catalog.buildJobLootPool(job, setKey) returns a set's
-- base item IDs for one job.
local reforgeCatalog
do
    local ok, cat = pcall(require, 'modules/custom/lua/reforge_catalog')
    if ok and type(cat) == 'table' and cat.pieces then
        reforgeCatalog = cat
    end
end

local validCategories = 'general, weapons, armor, consumables, food, dice, ammo, ninja, pets, reforge'

commandObj.onTrigger = function(player, category, subcat)
    local cat = category and category:lower() or 'general'

    -- Augment catalysts are no longer sold for gil (removed for relaunch) --
    -- they now drop from NMs. Point players at the farm path.
    if cat == 'augments' then
        player:printToPlayer('Augment catalysts are no longer sold for gil -- farm them from NMs, then trade them to the Augment Moogle at GM Home to apply.', xi.msg.channel.SYSTEM_3)
        return
    end

    -- BST pets: curated jug broths, with a pet-food sub-page.
    if cat == 'pets' then
        local sub = subcat and subcat:lower() or ''
        if sub == 'food' or sub == 'pots' or sub == 'biscuits' then
            player:printToPlayer('BST pet food -- feed/heal your jug pet.', xi.msg.channel.SYSTEM_3)
            xi.shop.general(player, petStock.food)
        else
            player:printToPlayer('BST jug pets -- buy a broth, then Call Beast / Bestial Loyalty to summon it.', xi.msg.channel.SYSTEM_3)
            player:printToPlayer('Pet food page: !shop pets food', xi.msg.channel.SYSTEM_3)
            xi.shop.general(player, petStock.jugs)
        end
        return
    end

    -- Reforged armor: claim your CURRENT MAIN JOB's ilvl-109 AF/Relic/Empy set(s),
    -- FREE. Reads the live reforge_catalog so it always matches the Reforge system.
    if cat == 'reforge' then
        local H = xi.msg.channel.SYSTEM_3
        if not reforgeCatalog then
            player:printToPlayer('The reforge claim is unavailable (catalog failed to load).', H)
            return
        end

        local job       = player:getMainJob()
        local jobPieces = reforgeCatalog.pieces[job]
        if not jobPieces then
            player:printToPlayer('Your current main job has no reforged set configured yet.', H)
            return
        end

        local setLabels = { af = 'Artifact (AF)', relic = 'Relic', empy = 'Empyrean' }
        local sub       = subcat and subcat:lower() or ''

        -- No / invalid set name: show the claim menu.
        if sub ~= 'af' and sub ~= 'relic' and sub ~= 'empy' and sub ~= 'all' then
            player:printToPlayer('Reforged armor -- claim your main-job ilvl-109 set, FREE:', H)
            player:printToPlayer('  !shop reforge af     - Artifact set (5 pieces)', H)
            player:printToPlayer('  !shop reforge relic  - Relic set (5 pieces)', H)
            player:printToPlayer('  !shop reforge empy   - Empyrean set (5 pieces)', H)
            player:printToPlayer('  !shop reforge all    - all three sets (15 pieces)', H)
            player:printToPlayer('  Grants pieces for the job you are CURRENTLY on; switch jobs for another.', H)
            return
        end

        -- ONCE per character per job per set. The granted pieces are tradable
        -- (NOAUCTION, not RARE/EX), so without a guard a player could claim, trade
        -- to an alt, and re-claim forever = an unlimited free-gear faucet. Track
        -- claimed sets in a per-job bitmask charvar.
        local SETBIT     = { af = 1, relic = 2, empy = 4 }
        local claimedVar = 'ReforgeClaimed_' .. tostring(job)
        local claimed    = player:getCharVar(claimedVar)

        local toGrant = (sub == 'all') and { 'af', 'relic', 'empy' } or { sub }
        local granted, owned, already, failed = 0, 0, 0, 0
        local newBits = 0
        for _, setKey in ipairs(toGrant) do
            local b = SETBIT[setKey]
            if bit.band(claimed, b) ~= 0 then
                already = already + 1
            else
                local setFailed = false
                for _, itemId in ipairs(reforgeCatalog.buildJobLootPool(job, setKey)) do
                    if player:hasItem(itemId) then
                        owned = owned + 1
                    elseif player:addItem(itemId) then
                        granted = granted + 1
                    else
                        failed = failed + 1
                        setFailed = true
                    end
                end
                -- Only lock the set once every piece landed; a full-inventory partial
                -- can be freed up and re-run.
                if not setFailed then
                    newBits = bit.bor(newBits, b)
                end
            end
        end
        if newBits ~= 0 then
            player:setCharVar(claimedVar, bit.bor(claimed, newBits))
        end

        local label = (sub == 'all') and 'All reforged sets' or (setLabels[sub] .. ' set')
        player:printToPlayer(string.format('[Reforge] %s -- %d granted, %d already owned%s.', label, granted, owned,
            already > 0 and string.format(', %d set(s) already claimed', already) or ''), H)
        if failed > 0 then
            player:printToPlayer(string.format('  %d piece(s) could not be added -- free inventory space and re-run.', failed), H)
        end
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
