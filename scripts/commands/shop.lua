-----------------------------------
-- func: shop
-- desc: Opens a browsable shop menu, then the selected native buy/sell window.
--       Usage: !shop
--       (Augment catalysts are NO LONGER sold for gil -- they drop from NMs.
--        Farm them, then trade to the Augment Moogle at GM Home to apply.)
-----------------------------------
---@type TCommand
local commandObj = {}

commandObj.cmdprops =
{
    permission = 0,
    parameters = '',
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
        { 27556,                          100000 },  -- Echad Ring
        { 27557,                          100000 },  -- Trizek Ring
        { 27604,                          300000 },  -- Aptitude Mantle +1
    },

    consumables =
    {
        { xi.item.BOTTLE_OF_ANTACID,         200 },
        { xi.item.ANTIDOTE,                  50 },
        { xi.item.FLASK_OF_ECHO_DROPS,       100 },
        { xi.item.ELIXIR,                  2000 },
        { xi.item.ETHER,                     300 },
        { xi.item.FLASK_OF_EYE_DROPS,        50 },
        { xi.item.HI_ETHER,                 1000 },
        { xi.item.HI_POTION,                 400 },
        { xi.item.FLASK_OF_HOLY_WATER,       100 },
        { xi.item.POTION,                    100 },
        { xi.item.REMEDY,                    500 },
        { xi.item.FLASK_OF_SLEEPING_POTION,  200 },
        { xi.item.VILE_ELIXIR,             3000 },
        { xi.item.VILE_ELIXIR_P1,          5000 },
        { xi.item.X_POTION,                 1000 },
    },

    weapons =
    {
        { 17859,    10000 },  -- Animator     (PUP, Lv1)
        { 17857,    50000 },  -- Animator +1  (PUP, Lv71)
        { 21392,  500000 },  -- Animator Z   (PUP, iLvl 119) -- Animator P / P+1 / P II line reserved for !hunt
        { 21460,    10000 },  -- Matre Bell   (Lv.1 GEO handbell, MP+5)
        { 21463,   250000 },  -- Nepote Bell  (Lv.99 GEO handbell, Geomancy+5)
    },

    armor =
    {
        { xi.item.CASSIE_EARRING,  250000 },             -- Cassie Earring
        { 10293,                    50000 },              -- Chocobo Shirt
        { 11811,                    50000 },              -- Destrier Beret
        { 14724,                   500000 },              -- Moldavite Earring
        { 13122,                    50000 },              -- Miner's Pendant (neck, gathering utility)
        { 11009,                   100000 },              -- Shaper's Shawl (back, crafting/utility)
        { 28509,                   250000 },              -- She-Slime Earring
        { 28511,                   250000 },              -- Slime Earring
    },

    -- Absolute-best endgame foods (max 16 slots). One BiS per role; each
    -- entry's comment explains what the food gives and who it's for.
    -- Raw IDs are used where no xi.item.* constant exists for the +1
    -- variant (verified against item_basic.sql).
    food =
    {
        { 6540,                              2000 },  -- Altana's Repast +2      -- all attributes + Acc/Att (premium all-round)
        { 6465,                              2000 },  -- Behemoth Steak +1       -- Attack +24% (cap 165), +STR8 +DEX8
        { 5764,                              2000 },  -- Black Curry Bun +1      -- HP / Att / Def hybrid
        { 5177,                              2000 },  -- Bream Sushi +1          -- Acc+18, Att+12
        { 5925,                              2000 },  -- Charred Salisbury Steak -- Attack +22% (cap 165), +STR8
        { 5167,                              2000 },  -- Coeurl Sub +1           -- STR / DEX
        { 5722,                              2000 },  -- Crab Sushi +1           -- Acc, Att, crit
        { 5179,                              2000 },  -- Dorado Sushi +1         -- DEX, AGI
        { 5666,                              2000 },  -- Fin Sushi +1            -- RACC, DEX+8
        { 6344,                              2000 },  -- Grape Daifuku +1        -- TP Bonus +50 (BiS for SAM/COR/RNG WS sets)
        { 5603,                              2000 },  -- Hydra Kofte +1          -- Attack / STR / Acc (melee)
        { 6072,                              2000 },  -- Magma Steak +1          -- Attack +24% (cap 185), +STR9
        { 5744,                              2000 },  -- Marinara Pizza +1       -- Enmity (PLD / RUN)
        { 5694,                              2000 },  -- Octopus Sushi +1        -- STR, VIT
        { xi.item.FLASK_OF_PEAR_AU_LAIT,     2000 },  -- Pear au Lait            -- Macc, MAB, MP
        { xi.item.FLASK_OF_PERSIKOS_AU_LAIT, 2000 },  -- Persikos au Lait        -- MP refresh tick
        { 5765,                              2000 },  -- Red Curry Bun +1        -- MAB / INT (nuker)
        { 5664,                              2000 },  -- Salmon Sushi +1         -- RACC, DEX
        { 5692,                              2000 },  -- Shrimp Sushi +1         -- STR, DEX
        { 5924,                              2000 },  -- Smoldering Salisbury Steak -- STR / Att (heavy melee)
        { 5163,                              2000 },  -- Sole Sushi +1           -- Acc+18 (Acc-capped fights)
        { 6459,                              2000 },  -- Soy Ramen +1            -- Acc+15, Att+15 (top all-round DD)
        { 5199,                              2000 },  -- Spaghetti Carbonara +1  -- STR / VIT / HP (DD + survivability)
        { 5162,                              2000 },  -- Squid Sushi +1          -- RACC+18, RATT+13% (RNG / COR)
        { 6469,                              2000 },  -- Sublime Sushi +1        -- Macc+25, INT+9, MAB+15 (best caster food)
        { 5216,                              2000 },  -- Tentacle Sushi +1       -- INT, Macc
        { 5160,                              2000 },  -- Urchin Sushi +1         -- MND, CHR (support)
        { 4330,                              2000 },  -- Witch Risotto           -- Magic defense (mage burns)
        { 5763,                              2000 },  -- Yellow Curry Bun +1     -- STR / Acc hybrid
    },

    -- Corsair dice: each die TEACHES its Phantom Roll when used by a COR of the
    -- required level (e.g. Monk Die -> Monk's Roll). Rolls are item-taught on
    -- this server, so a cheap dice shop lets COR players assemble their full kit
    -- without AH hunting. 1 gil each. (Shop > Job Supplies > Corsair Dice)
    dice =
    {
        { 5502, 1 },  -- Allies' Die       -> Allies' Roll
        { 5505, 1 },  -- Avenger's Die     -> Avenger's Roll
        { 5486, 1 },  -- Bard Die          -> Choral Roll
        { 5485, 1 },  -- Beastmaster Die   -> Beast Roll
        { 5480, 1 },  -- Black Mage Die    -> Wizard's Roll
        { 5500, 1 },  -- Blitzer's Die     -> Blitzer's Roll
        { 5492, 1 },  -- Blue Mage Die     -> Magus's Roll
        { 5497, 1 },  -- Bolter's Die      -> Bolter's Roll
        { 5498, 1 },  -- Caster's Die      -> Caster's Roll
        { 5504, 1 },  -- Companion's Die   -> Companion's Roll
        { 5493, 1 },  -- Corsair Die       -> Corsair's Roll
        { 5499, 1 },  -- Courser's Die     -> Courser's Roll
        { 5495, 1 },  -- Dancer Die        -> Dancer's Roll
        { 5484, 1 },  -- Dark Knight Die   -> Chaos Roll
        { 5490, 1 },  -- Dragoon Die       -> Drachen Roll
        { 6368, 1 },  -- Geomancer Die     -> Naturalist's Roll
        { 5503, 1 },  -- Miser's Die       -> Miser's Roll
        { 5478, 1 },  -- Monk Die          -> Monk's Roll
        { 5489, 1 },  -- Ninja Die         -> Ninja Roll
        { 5483, 1 },  -- Paladin Die       -> Gallant's Roll
        { 5494, 1 },  -- Puppetmaster Die  -> Puppet Roll
        { 5487, 1 },  -- Ranger Die        -> Hunter's Roll
        { 5481, 1 },  -- Red Mage Die      -> Warlock's Roll
        { 6369, 1 },  -- Rune Fencer Die   -> Runeist's Roll
        { 5488, 1 },  -- Samurai Die       -> Samurai Roll
        { 5496, 1 },  -- Scholar Die       -> Scholar's Roll
        { 5491, 1 },  -- Summoner Die      -> Evoker's Roll
        { 5501, 1 },  -- Tactician's Die   -> Tactician's Roll
        { 5482, 1 },  -- Thief Die         -> Rogue's Roll
        { 5477, 1 },  -- Warrior Die       -> Fighter's Roll
        { 5479, 1 },  -- White Mage Die    -> Healer's Roll
    },

    -- Ranged ammo for RNG / COR / NIN. A leveling-friendly ladder per type
    -- (cheap stacks, so a leveler is never stranded without arrows) plus a
    -- Lv99 endgame option. Shops sell per-unit; buy a stack of up to 99.
    ammo =
    {
        { 21307, 100 },  -- Achiyalabopa Arrow  (Lv99/iLvl119, RNG)
        { 21321, 100 },  -- Achiyalabopa Bolt   (Lv99/iLvl119, RNG)
        { 21337, 100 },  -- Achiyalabopa Bullet (Lv99/iLvl119, RNG)
        { 18259,  50 },  -- Angon               (Lv62, DRG)
        { 22308,  50 },  -- Bayeux Bullet       (Prime gun ammo, RARE/EX)
        { 21295,  50 },  -- Beryllium Arrow     (Lv99, DMG 77)
        { 17319,   2 },  -- Bone Arrow          (Lv7)
        { 17343,   2 },  -- Bronze Bullet       (Lv1)
        { 17340,   3 },  -- Bullet              (Lv22)
        { 21297,  50 },  -- Chrono Arrow        (Lv99)
        { 21296,  50 },  -- Chrono Bullet       (Lv99)
        { 26350, 50000 }, -- Chrono Bullet Pouch (waist, RATT20/RACC20, RNG/COR)
        { 17336,   2 },  -- Crossbow Bolt       (Lv1)
        { 18159,  10 },  -- Demon Arrow         (Lv60)
        { 26349, 50000 }, -- Devastating Bullet Pouch (waist, RACC35/MACC35, RNG/COR)
        { 21302,  50 },  -- Eminent Arrow       (Lv99, EX, DMG 79)
        { 21316,  50 },  -- Eminent Bolt        (Lv99)
        { 21331,  50 },  -- Eminent Bullet      (Lv99)
        { 26347, 50000 }, -- Eradicating Bullet Pouch (waist, RATT30/RACC30, RNG)
        { 17304,  20 },  -- Fuma Shuriken       (Lv60)
        { 19197,  20 },  -- Fusion Bolt         (Lv79)
        { 21353,  50 },  -- Happo Shuriken      (Lv99)
        { 17320,   3 },  -- Iron Arrow          (Lv14)
        { 17302,   5 },  -- Juji Shuriken       (Lv28)
        { 17325,  20 },  -- Kabura Arrow        (Lv70)
        { 26348, 50000 }, -- Living Bullet Pouch (waist, MATT35/MACC25, COR)
        { 17303,   8 },  -- Manji Shuriken      (Lv48)
        { 17337,   5 },  -- Mythril Bolt        (Lv40)
        { 21311,  50 },  -- Quelling Bolt       (Lv99, RNG, Add. Effect: Slow)
        { 21310,  50 },  -- Raetic Arrow        (Lv99, DMG 80)
        { 18155,   5 },  -- Scorpion Arrow      (Lv40)
        { 17301,   3 },  -- Shuriken            (Lv18)
        { 17341,   8 },  -- Silver Bullet       (Lv50)
        { 18160,   5 },  -- Spartan Bullet      (Lv30)
        { 18723,  20 },  -- Steel Bullet        (Lv66)
        { 18258,  50 },  -- Throwing Tomahawk   (Lv75, WAR)
    },

    -- Ninja TOOLBAGS at 1 gil. Each toolbag, when USED, opens into a full stack of
    -- 99 of that tool (scripts/items/toolbag_*.lua) -- so one 1-gil purchase = 99
    -- charges, and toolbags stack to 12 (a NIN can carry ~1,188 charges of one tool
    -- in a single inventory slot). The three "card" toolbags are the universal tools
    -- a MAIN-job NIN can sub for ANY elemental ninjutsu (see HasNinjaTool in
    -- battleutils.cpp). (A NIN *subjob* still needs the specific tool, e.g. Shihei.)
    ninja =
    {
        { 5869, 1 },  -- Toolbag (Cho)   -> 99x Chonofuda       -- Universal: any elemental ninjutsu
        { 6266, 1 },  -- Toolbag (Furu)  -> 99x Furusumi        -- Doton: San / higher-tier earth
        { 5312, 1 },  -- Toolbag (Hira)  -> 99x Hiraishin       -- Raiton (lightning)
        { 5867, 1 },  -- Toolbag (Ino)   -> 99x Inoshishinofuda -- Universal: any elemental ninjutsu
        { 5864, 1 },  -- Toolbag (Jinko) -> 99x Jinko           -- Innin: Ichi (acc/eva from behind)
        { 5315, 1 },  -- Toolbag (Jusa)  -> 99x Jusatsu         -- Kurayami: Ichi/Ni (Blind)
        { 5863, 1 },  -- Toolbag (Kaben) -> 99x Kabenro         -- Yonin: Ichi (hate-down ninjutsu)
        { 5316, 1 },  -- Toolbag (Kagi)  -> 99x Kaginawa        -- Hojo: Ichi/Ni (Slow)
        { 5310, 1 },  -- Toolbag (Kawa)  -> 99x Kawahori-ogi    -- Huton (wind)
        { 5318, 1 },  -- Toolbag (Kodo)  -> 99x Kodoku          -- Dokumori: Ichi (poison / enmity)
        { 5311, 1 },  -- Toolbag (Maki)  -> 99x Makibishi       -- Doton (earth)
        { 5313, 1 },  -- Toolbag (Mizu)  -> 99x Mizu-deppo      -- Suiton (water)
        { 5866, 1 },  -- Toolbag (Moku)  -> 99x Mokujin         -- Sange (shurikenspam JA)
        { 6265, 1 },  -- Toolbag (Ranka) -> 99x Ranka           -- Katon: San / higher-tier fire
        { 5865, 1 },  -- Toolbag (Ryuno) -> 99x Ryuno           -- Migawari: Ichi (1-hit dodge)
        { 5317, 1 },  -- Toolbag (Sai)   -> 99x Sairui-ran      -- Monomi: Ichi (Sneak)
        { 5417, 1 },  -- Toolbag (Sanja) -> 99x Sanjaku-tenugui -- Tonko: Ichi/Ni (Invisible)
        { 5314, 1 },  -- Toolbag (Shihe) -> 99x Shihei          -- Utsusemi: Ichi/Ni (shadows)
        { 5868, 1 },  -- Toolbag (Shika) -> 99x Shikanofuda     -- Universal: any elemental ninjutsu
        { 5319, 1 },  -- Toolbag (Shino) -> 99x Shinobi-tabi   -- Tonko: Ichi/Ni (Sneak/Invisible)
        { 5734, 1 },  -- Toolbag (Soshi) -> 99x Soshi           -- Kakka: Ichi (Enfire/etc.)
        { 5309, 1 },  -- Toolbag (Tsura) -> 99x Tsurara         -- Hyoton (ice)
        { 5308, 1 },  -- Toolbag (Uchi)  -> 99x Uchitake        -- Katon (fire)
    },

    -- Corsair Quick Draw cards (ammo slot, consumed on Quick Draw). Cheap --
    -- a COR burns through these fast, so keep a stack handy. (Shop > Job Supplies > Corsair Cards)
    cards =
    {
        { 2176, 50 },  -- Fire Card
        { 2177, 50 },  -- Ice Card
        { 2178, 50 },  -- Wind Card
        { 2179, 50 },  -- Earth Card
        { 2180, 50 },  -- Thunder Card
        { 2181, 50 },  -- Water Card
        { 2182, 50 },  -- Light Card
        { 2183, 50 },  -- Dark Card
        { 2974, 50 },  -- Trump Card
    },

    -- QoL "Instant" scrolls: self-warp, reraise, and instant buffs.
    scrolls =
    {
        { 4181, 500 },  -- Instant Warp
        { 4182, 500 },  -- Instant Reraise
        { 5428, 500 },  -- Instant Retrace
        { 5988, 300 },  -- Instant Protect
        { 5989, 300 },  -- Instant Shell
        { 5990, 300 },  -- Instant Stoneskin
    },

    -- Crafting crystals + clusters, one of each element.
    crystals =
    {
        { 4096, 100 },   -- Fire Crystal
        { 4097, 100 },   -- Ice Crystal
        { 4098, 100 },   -- Wind Crystal
        { 4099, 100 },   -- Earth Crystal
        { 4100, 100 },   -- Lightning Crystal
        { 4101, 100 },   -- Water Crystal
        { 4102, 200 },   -- Light Crystal
        { 4103, 200 },   -- Dark Crystal
        { 4104, 500 },   -- Fire Cluster
        { 4105, 500 },   -- Ice Cluster
        { 4106, 500 },   -- Wind Cluster
        { 4107, 500 },   -- Earth Cluster
        { 4108, 500 },   -- Lightning Cluster
        { 4109, 500 },   -- Water Cluster
        { 4110, 1000 },  -- Light Cluster
        { 4111, 1000 },  -- Dark Cluster
    },

    -- Dungeon coffer keys -- open the ??? coffers for gear/mats/gil. Niche,
    -- for treasure-hunters (16-slot window cap, so this is the coffer set).
    keys =
    {
        { 1042, 5000 },  -- Davoi Coffer Key
        { 1043, 5000 },  -- Beadeaux Coffer Key
        { 1044, 5000 },  -- Oztroja Coffer Key
        { 1045, 5000 },  -- Nest Coffer Key
        { 1046, 5000 },  -- Eldieme Coffer Key
        { 1047, 5000 },  -- Garlaige Coffer Key
        { 1048, 5000 },  -- Zvahl Coffer Key
        { 1049, 5000 },  -- Uggalepih Coffer Key
        { 1050, 5000 },  -- Den Coffer Key
        { 1051, 5000 },  -- Kuftal Coffer Key
        { 1052, 5000 },  -- Boyahda Coffer Key
        { 1053, 5000 },  -- Cauldron Coffer Key
        { 1054, 5000 },  -- Quicksand Coffer Key
        { 1057, 5000 },  -- Toraimarai Coffer Key
        { 1058, 5000 },  -- Ru'Aun Coffer Key
        { 1060, 5000 },  -- Ve'Lugannon Coffer Key
    },
}

-- Bound budget accessories. Native shop windows hold at most 16 items, so
-- these are split into thematic Equipment submenu pages. Their item
-- restrictions and 5,000-gil NPC resale value are applied by
-- modules/custom/sql/zz_shop_armor_rare_ex.sql.
local armorStock =
{
    rings =
    {
        { 27564, 10000 }, -- Ifrit Ring
        { 27566, 10000 }, -- Leviathan Ring
        { 27568, 10000 }, -- Ramuh Ring
        { 27570, 10000 }, -- Titan Ring
        { 27572, 10000 }, -- Garuda Ring
        { 27574, 10000 }, -- Shiva Ring
        { 27576, 10000 }, -- Carbuncle Ring
        { 27578, 10000 }, -- Fenrir Ring
        { 26179, 10000 }, -- Varar Ring
    },

    pearls =
    {
        { 11014, 10000 }, -- Flame Pearl
        { 11015, 10000 }, -- Snow Pearl
        { 11016, 10000 }, -- Breeze Pearl
        { 11017, 10000 }, -- Soil Pearl
        { 11018, 10000 }, -- Thunder Pearl
        { 11019, 10000 }, -- Aqua Pearl
        { 11020, 10000 }, -- Light Pearl
        { 11021, 10000 }, -- Darkness Pearl
    },

    accessories =
    {
        { 10964, 10000 }, -- Eloquence Cape
        { 10966, 10000 }, -- Aisance Mantle
        { 10968, 10000 }, -- Vigilance Mantle
        { 10831, 10000 }, -- Paewr Belt
        { 10832, 10000 }, -- Carrier's Sash
        { 10836, 10000 }, -- Phos Belt
        { 10817, 10000 }, -- Moepapa Stone
        { 10839, 10000 }, -- Othila Sash
        { 10397, 10000 }, -- Ishtar's Collar
        { 10939, 10000 }, -- Dualism Collar
        { 10941, 10000 }, -- Tjukurrpa Medal
        { 10942, 10000 }, -- Aife's Medal
        { 10943, 10000 }, -- Moepapa Medal
        { 10945, 10000 }, -- Waylayer's Scarf
    },

    combat =
    {
        { 19779, 10000 }, -- Potestas Bomblet
        { 19777, 10000 }, -- Ombre Tathlum
        { 19773, 10000 }, -- Hagneia Stone
        { 19771, 10000 }, -- Strobilus
        { 19767, 10000 }, -- Oneiros Pebble
        { 18818, 10000 }, -- Dilettante's Grip
        { 18816, 10000 }, -- Wizzan Grip
        { 18825, 10000 }, -- Shamatha Grip
    },
}

-----------------------------------
-- Augment catalysts: the gil-purchase shop was REMOVED for relaunch (owner
-- request 2026-06-24). Catalysts must now be FARMED FROM NMs and traded to the
-- Augment Moogle at GM Home -- there is no longer a gil shortcut. The whole
-- old augment category (catalog pull, 13 thematic groups, the EXP/Capacity
-- 'points' group, and the Maat's Cap prepend) is gone.

-----------------------------------
-- BST pets: jug broths (summon a pet) + pet food (heal/feed it).
-- Split into two sub-pages because a FFXI shop window holds only 16 items:
--   Jug Pets -> curated best/most-used jug pets
--   Pet Food -> pet food biscuits
-- Buy a broth, then use Call Beast / Bestial Loyalty to summon it.
-- NOTE: the broth->pet link is data/C++-driven, so the pet labels below are
-- best-effort -- players buy by the broth's in-game name. Prices easily tuned.
-----------------------------------
local petStock =
{
    jugs =
    {
        { 21446, 1000 },  -- Airy Broth         -- utility jug
        { 17922, 1000 },  -- Blackwater Broth   -- DD jug
        { 17917, 1000 },  -- Bubbly Broth       -- strong melee-DD jug
        { 21498, 1000 },  -- Crackling Broth    -- melee-DD jug
        { 21493, 1000 },  -- Deepwater Broth    -- ranged/bird jug
        { 21449, 1000 },  -- Dire Broth         -- melee-DD jug
        { 21450, 1000 },  -- Electrified Broth  -- thunder-DD jug
        { 21496, 1000 },  -- Furious Broth      -- melee-DD jug
        { 21441, 1000 },  -- Glazed Broth       -- DD jug (HQ broth)
        { 21495, 1000 },  -- Heavenly Broth     -- utility jug
        { 21444, 1000 },  -- Livid Broth        -- melee-DD jug
        { 17902, 1000 },  -- Lucky Broth        -> CourierCarrie (crab): Metallic Body, heavy PDT -- top tank/utility jug
        { 21445, 1000 },  -- Lyrical Broth      -- support jug
        { 21497, 1000 },  -- Rapid Broth        -- fast multi-hit jug
        { 21440, 1000 },  -- Sugary Broth       -- DD jug
        { 21494, 1000 },  -- Wetlands Broth     -- utility jug
    },

    -- Additional Call Beast / Bestial Loyalty items. Kept on separate pages:
    -- a client shop window supports a maximum of 16 entries.
    jugsAdvanced =
    {
        { 17900, 1000 },  -- Cloudy Wheat Broth
        { 17903, 1000 },  -- Shadowy Broth
        { 21447, 1000 },  -- Crumbly Soil
        { 21470, 1000 },  -- Decaying Broth
        { 21471, 1000 },  -- Putrescent Broth
        { 21451, 1000 },  -- Bug-Ridden Broth
        { 21466, 1000 },  -- Frizzante Broth
        { 21467, 1000 },  -- Spumante Broth
        { 17912, 1000 },  -- Fizzy Broth
        { 21492, 1000 },  -- Insipid Broth
        { 21448, 1000 },  -- Pale Sap
        { 21438, 1000 },  -- Poisonous Broth
        { 21439, 1000 },  -- Venomous Broth
        { 21488, 1000 },  -- Pristine Sap
        { 21489, 1000 },  -- Truly Pristine Sap
        { 17913, 1000 },  -- Saline Broth
    },

    jugsSpecialist =
    {
        { 21464, 1000 },  -- Rancid Broth
        { 21465, 1000 },  -- Pungent Broth
        { 17911, 1000 },  -- Salubrious Broth
        { 17918, 1000 },  -- Windy Greens
        { 17908, 1000 },  -- Shimmering Broth
        { 17916, 1000 },  -- Fermented Broth
        { 21442, 1000 },  -- Sticky Webbing
        { 21443, 1000 },  -- Slimy Webbing
        { 17915, 1000 },  -- Viscous Broth
        { 17910, 1000 },  -- Translucent Broth
        { 21472, 1000 },  -- Turpid Broth
        { 21473, 1000 },  -- Feculent Broth
        { 17914, 1000 },  -- Wispy Broth
        { 21468, 1000 },  -- Zestful Sap
        { 21469, 1000 },  -- Gassy Sap
    },

    food =
    {
        { 17016, 500 },  -- Pet Food Alpha Biscuit
        { 17017, 500 },  -- Pet Food Beta Biscuit
        { 17019, 500 },  -- Pet Food Delta Biscuit
        { 17020, 500 },  -- Pet Food Epsilon Biscuit
        { 17022, 500 },  -- Pet Food Eta Biscuit
        { 17018, 500 },  -- Pet Food Gamma Biscuit
        { 17023, 500 },  -- Pet Food Theta Biscuit
        { 17021, 500 },  -- Pet Food Zeta Biscuit
        { 19251, 500 },  -- Pet Roborant  (cures the pet's status ailments)
        { 19252, 500 },  -- Pet Poultice  (restores the pet's HP)
    },
}

-- Reforged armor (FREE claim): each job's ilvl-109 AF/Relic/Empy BASE pieces
-- from modules/custom/lua/reforge_catalog. Missing 109 pieces can be claimed
-- again after a drop. A slot that already has +1/+2/+3 is left alone so
-- upgrading does not mint a second base.
local reforgeCatalog
do
    local ok, cat = pcall(require, 'modules/custom/lua/reforge_catalog')
    if ok and type(cat) == 'table' and cat.pieces then
        reforgeCatalog = cat
    end
end
local genderedArmor = require('modules/custom/lua/gendered_armor')

local showMainMenu
local showEquipmentMenu
local showSuppliesMenu
local showJobSuppliesMenu
local showTravelCraftMenu
local showPetMenu
local showReforgeMenu

local function openMenu(player, title, options)
    player:timer(30, function(p)
        p:customMenu({ title = title, options = options })
    end)
end

local function openStock(player, items)
    player:timer(30, function(p)
        -- Retail city shops strip equipment in disable_retail_gear_shops.lua.
        -- !shop is an intentional Relaunch vendor and must keep its gear pages.
        p:setLocalVar('[ShopAllowGear]', 1)
        xi.shop.general(p, items)
        p:setLocalVar('[ShopAllowGear]', 0)
    end)
end

local function ownsReforgeSlot(player, slot)
    for _, itemId in ipairs(slot) do
        if itemId and itemId > 0 and genderedArmor.has(player, itemId) then
            return true
        end
    end

    return false
end

local function claimReforgeSet(player, setKey)
    local H = xi.msg.channel.SYSTEM_3
    if not reforgeCatalog then
        player:printToPlayer('The reforge claim is unavailable (catalog failed to load).', H)
        return
    end

    local job = player:getMainJob()
    local jobPieces = reforgeCatalog.pieces[job]
    if not jobPieces then
        player:printToPlayer('Your current main job has no reforged set configured yet.', H)
        return
    end

    local setLabels = { af = 'Artifact (AF)', relic = 'Relic', empy = 'Empyrean' }
    local toGrant   = setKey == 'all' and { 'af', 'relic', 'empy' } or { setKey }
    local granted, owned, failed = 0, 0, 0

    for _, key in ipairs(toGrant) do
        local set = jobPieces[key]
        if set then
            for _, slot in pairs(set) do
                local baseId = slot[1]
                if baseId and baseId > 0 then
                    if ownsReforgeSlot(player, slot) then
                        owned = owned + 1
                    else
                        local giveId = genderedArmor.resolve(player, baseId)
                        if player:addItem(giveId) then
                            granted = granted + 1
                        else
                            failed = failed + 1
                        end
                    end
                end
            end
        end
    end

    local label = setKey == 'all' and 'All reforged sets' or (setLabels[setKey] .. ' set')
    player:printToPlayer(string.format(
        '[Reforge] %s -- %d granted, %d already owned.',
        label, granted, owned), H)
    if failed > 0 then
        player:printToPlayer(string.format(
            '  %d piece(s) could not be added -- free inventory space and try again.', failed), H)
    end
end

showEquipmentMenu = function(player)
    openMenu(player, 'Shop: Equipment',
    {
        { 'Weapons',           function(p) openStock(p, stock.weapons) end },
        { 'Standard Armor',    function(p) openStock(p, stock.armor) end },
        { 'Rings',             function(p) openStock(p, armorStock.rings) end },
        { 'Earrings / Pearls', function(p) openStock(p, armorStock.pearls) end },
        { 'Accessories',       function(p) openStock(p, armorStock.accessories) end },
        { 'Combat Gear',       function(p) openStock(p, armorStock.combat) end },
        { 'Back',              function(p) showMainMenu(p) end },
    })
end

showSuppliesMenu = function(player)
    openMenu(player, 'Shop: Supplies',
    {
        { 'Consumables', function(p) openStock(p, stock.consumables) end },
        { 'Food',        function(p) openStock(p, stock.food) end },
        { 'Ammunition',  function(p) openStock(p, stock.ammo) end },
        { 'Back',        function(p) showMainMenu(p) end },
    })
end

showJobSuppliesMenu = function(player)
    openMenu(player, 'Shop: Job Supplies',
    {
        { 'Corsair Dice',  function(p) openStock(p, stock.dice) end },
        { 'Corsair Cards', function(p) openStock(p, stock.cards) end },
        { 'Ninja Tools',   function(p) openStock(p, stock.ninja) end },
        { 'Back',          function(p) showMainMenu(p) end },
    })
end

showTravelCraftMenu = function(player)
    openMenu(player, 'Shop: Travel / Craft',
    {
        { 'Instant Scrolls', function(p) openStock(p, stock.scrolls) end },
        { 'Crystals',        function(p) openStock(p, stock.crystals) end },
        { 'Coffer Keys',     function(p) openStock(p, stock.keys) end },
        { 'Back',            function(p) showMainMenu(p) end },
    })
end

showPetMenu = function(player)
    openMenu(player, 'Shop: Beastmaster',
    {
        { 'Jug Pets I',   function(p) openStock(p, petStock.jugs) end },
        { 'Jug Pets II',  function(p) openStock(p, petStock.jugsAdvanced) end },
        { 'Jug Pets III', function(p) openStock(p, petStock.jugsSpecialist) end },
        { 'Pet Food',     function(p) openStock(p, petStock.food) end },
        { 'Back',         function(p) showMainMenu(p) end },
    })
end

showReforgeMenu = function(player)
    openMenu(player, 'Free i109 Reforged Sets',
    {
        { 'Artifact (AF)', function(p) claimReforgeSet(p, 'af') end },
        { 'Relic',         function(p) claimReforgeSet(p, 'relic') end },
        { 'Empyrean',      function(p) claimReforgeSet(p, 'empy') end },
        { 'All Three',     function(p) claimReforgeSet(p, 'all') end },
        { 'Back',          function(p) showMainMenu(p) end },
    })
end

showMainMenu = function(player)
    openMenu(player, 'Relaunch Shop',
    {
        { 'General',        function(p) openStock(p, stock.general) end },
        { 'Equipment',      function(p) showEquipmentMenu(p) end },
        { 'Supplies',       function(p) showSuppliesMenu(p) end },
        { 'Job Supplies',   function(p) showJobSuppliesMenu(p) end },
        { 'Travel / Craft', function(p) showTravelCraftMenu(p) end },
        { 'Beastmaster',    function(p) showPetMenu(p) end },
        { 'Reforged Gear',  function(p) showReforgeMenu(p) end },
        { 'Close',          function(_) end },
    })
end

commandObj.onTrigger = function(player)
    showMainMenu(player)
end

return commandObj
