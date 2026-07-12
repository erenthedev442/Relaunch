-----------------------------------
-- Geas_Fete.lua
--
-- Escha Geas Fete for the relaunch server.
-- Two Warding Circle NPCs (one per Escha zone) let players pop
-- retail-faithful Geas Fete NMs tier-by-tier.
--
-- Pop mechanic: walk up to the Warding Circle, pick a tier, pick an NM.
-- No separate pop items required (relaunch-friendly).
-- Per-player per-NM cooldown stored as charVar GF_<zoneId>_<groupId>.
--
-- Currency (UNIFIED 2026-07-09 -- REAL char_points currency, Currencies II tab):
--   ALL Escha kills (Zi'Tah AND Ru'Aun) → escha_beads.
--   One pool funds BOTH Warding Circle exchanges, the Temprix Aeonic vendor, and
--   the WeaponForge Aeonic steps. Dead legacy charVars (Escha_Beads/Escha_Silt)
--   are folded into escha_beads on first access. The real escha_silt CURRENCY is
--   left alone -- it's the Eschan portal travel cost + Domain Invasion fuel.
-- Exchange at the Warding Circle for Beitetsu / Riftcinder / Riftborn Boulder.
--
-- Drop materials from kills (Lua-only, no mob_droplist rows needed):
--   T1: 1-2 Beitetsu, rare Riftcinder
--   T2: 2-3 Beitetsu, 1-2 Riftcinder, chance Riftborn Boulder
--   T3: 3-5 Beitetsu, 2-3 Riftcinder, 1-2 Riftborn Boulder
--   Boss: 5-8 Beitetsu, 3-5 Riftcinder, 2-4 Riftborn Boulder, Eschalixir+2
--
-- All NMs spawn via insertDynamicEntity (no mob_spawn_points rows needed).
-- restart-gated (addOverride).
-----------------------------------
require('modules/module_utils')
require('scripts/zones/Escha_ZiTah/Zone')
require('scripts/zones/Escha_RuAun/Zone')
require('scripts/zones/Reisenjima/Zone')  -- for the redirect signpost override

local m = Module:new('geas_fete')
local S = xi.msg.channel.SYSTEM_3

-- ===================================================================
-- ITEMS
-- ===================================================================
-- Per-item roll chance for the retail signature drops (NM_CATALOG drops = {}).
local FETE_DROP_RATE      = 0.15
local FETE_BOSS_DROP_RATE = 0.25

local BEITETSU         = 4060  -- chunk of beitetsu
local RIFTBORN_BOULDER = 4061  -- riftborn boulder
local RIFTCINDER       = 3499  -- pinch of riftcinder
local ESCHALIXIR_2     = 9086  -- eschalixir +2

-- Reisenjima-crafted armor (retail: crafted from geas-fete NM materials;
-- relaunch: direct drops off the NMs themselves, owner call 2026-07-12 --
-- pulled from the HL gear vendors the same day, this is their only source).
-- Tier gates in awardDrops: T2 rolls NQ, T3/T4 roll NQ + HQ (+1).
-- Naga is a 5-piece NQ-only set (no +1 exists in the item data).
local GEAR_NQ = {
    25613, 27473, 25686, 27302, 27117,  -- Adhemar  bonnet/gamashes/jacket/kecks/wristbands
    26672, 26848, 27024, 27200, 27376,  -- Argosy   celata/hauberk/mufflers/breeches/sollerets
    26678, 26854, 27030, 27206, 27382,  -- Carmine  mask/scale mail/fng. gauntlets/cuisses/greaves
    26674, 26850, 27026, 27202, 27378,  -- Rao      kabuto/togi/kote/haidate/sune-ate
    25611, 25684, 27115, 27300, 27471,  -- Ryuo     somen/domaru/tekko/hakama/sune-ate
    26670, 26846, 27022, 27198, 27374,  -- Souveran schaller/cuirass/handschuhs/diechlings/schuhs
    26793, 26949, 27099, 27284, 27459,  -- Naga     somen/samue/tekko/hakama/kyahan (NQ only)
}
local GEAR_HQ = {
    25614, 27474, 25687, 27303, 27118,  -- Adhemar +1
    26673, 26849, 27025, 27201, 27377,  -- Argosy +1
    26679, 26855, 27031, 27207, 27383,  -- Carmine +1
    26675, 26851, 27027, 27203, 27379,  -- Rao +1
    25612, 25685, 27116, 27301, 27472,  -- Ryuo +1
    26671, 26847, 27023, 27199, 27375,  -- Souveran +1
}

-- Attestations (retail IDs 1556-1569) — weapon-type-specific Aeonic materials.
-- Bosses (tier 4) drop 1-2 random Attestations; players collect the one
-- matching their desired Aeonic weapon type.
local ATTESTATIONS = {
    1556, -- attestation_of_might          (H2H     / Godhands)
    1557, -- attestation_of_celerity       (Dagger  / Aeneas)
    1558, -- attestation_of_glory          (Sword   / Sequence)
    1559, -- attestation_of_righteousness  (GSword  / Lionheart)
    1560, -- attestation_of_bravery        (Axe     / Tri-edge)
    1561, -- attestation_of_force          (GAxe    / Chango)
    1562, -- attestation_of_vigor          (Scythe  / Anguta)
    1563, -- attestation_of_fortitude      (Polearm / Trishula)
    1564, -- attestation_of_legerity       (Katana  / Heishi Shorinken)
    1565, -- attestation_of_decisiveness   (GKatana / Dojikiri Yasutsuna)
    1566, -- attestation_of_sacrifice      (Club    / Tishtrya)
    1567, -- attestation_of_virtue         (Staff   / Khatvanga)
    1568, -- attestation_of_transcendence  (Archery / Fail-not)
    1569, -- attestation_of_harmony        (Marks   / Fomalhaut)
}

-- ===================================================================
-- NM CATALOG
-- Fields:
--   name     : display name (spaces OK, gets underscore-replaced for entity name)
--   gid      : mob_groups.groupid scoped to this zone
--   tier     : 1 / 2 / 3 / 4 (boss)
--   hp       : max HP (0 = server default from mob_pools stats)
--   currency : Escha Beads or Silt awarded on kill
--   cooldown : seconds before the NM can be re-popped per player
-- ===================================================================
local ZITAH = xi.zone.ESCHA_ZITAH  -- 288
local RUAUN = xi.zone.ESCHA_RUAUN  -- 289

local NM_CATALOG = {
    -- Full retail Geas Fete roster (BG-wiki, 2026-07-12) + the relaunch
    -- originals. gids are stock mob_groups rows for zones 288/289. Each
    -- retail NM carries its retail signature drops (drops = {...}); the
    -- roll happens in awardDrops (FETE_DROP_RATE / FETE_BOSS_DROP_RATE).
    -- Kirin has no retail gear table -- he pays beads + the T3 material
    -- spread. Retail tiering: 119->T1, 125->T2, 135/HELM/AA/gods->T3.
    [ZITAH] = {
        -- Tier 1 (retail 119) ------------------------------------------
        { name='Wepwawet', gid=37, tier=1, hp=130000, currency=350, cooldown=1800, drops = { { id=27099, name='Naga Tekko' }, { id=27461, name='Pursuer\'s Gaiters' }, { id=21413, name='Clemency Grip' }, { id=26791, name='Eschite Helm' } } },
        { name='Lustful Lydia', gid=38, tier=1, hp=130000, currency=350, cooldown=1800, drops = { { id=26947, name='Eschite Breastplate' }, { id=27284, name='Naga Hakama' }, { id=26796, name='Psycloth Tiara' }, { id=22250, name='Seraphic Ampulla' } } },
        { name='Aglaophotis', gid=39, tier=1, hp=130000, currency=350, cooldown=1800, drops = { { id=27097, name='Eschite Gauntlets' }, { id=26952, name='Psycloth Vest' }, { id=27459, name='Naga Kyahan' }, { id=27512, name='Marked Gorget' } } },
        { name='Tangata Manu', gid=40, tier=1, hp=130000, currency=350, cooldown=1800, drops = { { id=27282, name='Eschite Cuisses' }, { id=27102, name='Psycloth Manillas' }, { id=28474, name='Mendicant\'s Earring' }, { id=26794, name='Rawhide Mask' } } },
        { name='Vidala', gid=41, tier=1, hp=130000, currency=350, cooldown=1800, drops = { { id=27552, name='Overbearing Ring' }, { id=27287, name='Psycloth Lappas' }, { id=26950, name='Rawhide Vest' }, { id=27457, name='Eschite Greaves' } } },
        { name='Gestalt', gid=42, tier=1, hp=130000, currency=350, cooldown=1800, drops = { { id=27462, name='Psycloth Boots' }, { id=26792, name='Despair Helm' }, { id=27606, name='Disperser\'s Cape' }, { id=27100, name='Rawhide Gloves' } } },
        { name='Angrboda', gid=43, tier=1, hp=130000, currency=350, cooldown=1800, drops = { { id=28416, name='Lucidity Sash' }, { id=26948, name='Despair Mail' }, { id=26797, name='Vanya Hood' }, { id=27285, name='Rawhide Trousers' } } },
        { name='Cunnast', gid=44, tier=1, hp=130000, currency=350, cooldown=1800, drops = { { id=26953, name='Vanya Robe' }, { id=27098, name='Despair Finger Gauntlets' }, { id=27460, name='Rawhide Boots' }, { id=21414, name='Willpower Grip' } } },
        { name='Revetaur', gid=45, tier=1, hp=130000, currency=350, cooldown=1800, drops = { { id=26795, name='Pursuer\'s Beret' }, { id=27103, name='Vanya Cuffs' }, { id=27283, name='Despair Cuisses' }, { id=22251, name='Grenade Core' } } },
        { name='Ferrodon', gid=46, tier=1, hp=130000, currency=350, cooldown=1800, drops = { { id=27458, name='Despair Greaves' }, { id=27513, name='Subtlety Spectacles' }, { id=26951, name='Pursuer\'s Doublet' }, { id=27288, name='Vanya Slops' } } },
        { name='Gulltop', gid=47, tier=1, hp=130000, currency=350, cooldown=1800, drops = { { id=27101, name='Pursuer\'s Cuffs' }, { id=26793, name='Naga Somen' }, { id=27463, name='Vanya Clogs' }, { id=28475, name='Infused Earring' } } },
        { name='Vyala', gid=48, tier=1, hp=130000, currency=350, cooldown=1800, drops = { { id=27553, name='Resonance Ring' }, { id=27286, name='Pursuer\'s Pants' }, { id=26949, name='Naga Samue' } } },
        -- Tier 1 (relaunch originals) ----------------------------------
        { name='Hugemaw Harold', gid=24, tier=1, hp=130000, currency=350, cooldown=1800 },
        { name='Prickly Pitriv', gid=25, tier=1, hp=130000, currency=350, cooldown=1800 },
        { name='Serpopard Ninlil', gid=26, tier=1, hp=130000, currency=350, cooldown=1800 },
        { name='Abyssdiver', gid=27, tier=1, hp=130000, currency=350, cooldown=1800 },
        { name='Eschan Jewelweed', gid=36, tier=1, hp=130000, currency=350, cooldown=1800 },
        -- Tier 2 (retail 125) ------------------------------------------
        { name='Ionos', gid=55, tier=2, hp=320000, currency=800, cooldown=3600, drops = { { id=20524, name='Nibiru Sainti' }, { id=21216, name='Nibiru Bow' }, { id=20895, name='Nibiru Sickle' }, { id=27607, name='Thaumaturge\'s Cape' } } },
        { name='Sensual Sandy', gid=56, tier=2, hp=320000, currency=800, cooldown=3600, drops = { { id=20600, name='Nibiru Knife' }, { id=20939, name='Nibiru Lance' }, { id=21273, name='Nibiru Gun' }, { id=28417, name='Sinew Belt' } } },
        { name='Nosoi', gid=57, tier=2, hp=320000, currency=800, cooldown=3600, drops = { { id=20710, name='Nibiru Blade' }, { id=28476, name='Calamitous Earring' }, { id=20983, name='Mijin' }, { id=27642, name='Nibiru Shield' } } },
        { name='Brittlis', gid=58, tier=2, hp=320000, currency=800, cooldown=3600, drops = { { id=27554, name='Purity Ring' }, { id=21699, name='Nibiru Faussar' }, { id=21399, name='Nibiru Harp' }, { id=21031, name='Sensui' } } },
        { name='Kamohoalii', gid=59, tier=2, hp=320000, currency=800, cooldown=3600, drops = { { id=20801, name='Nibiru Tabar' }, { id=21092, name='Nibiru Cudgel' }, { id=21415, name='Forefathers\' Grip' } } },
        { name='Umdhlebi', gid=60, tier=2, hp=320000, currency=800, cooldown=3600, drops = { { id=20848, name='Nibiru Chopper' }, { id=21156, name='Nibiru Staff' }, { id=22252, name='Sapience Orb' } } },
        -- Tier 2 (relaunch originals) ----------------------------------
        { name='Keeper of Heiligtum', gid=28, tier=2, hp=320000, currency=800, cooldown=3600 },
        { name='Jester Malatrix', gid=33, tier=2, hp=320000, currency=800, cooldown=3600 },
        { name='Immanibugard', gid=34, tier=2, hp=320000, currency=800, cooldown=3600 },
        { name='Beist', gid=35, tier=2, hp=320000, currency=800, cooldown=3600 },
        -- Tier 3 (retail 135 + HELM NMs) -------------------------------
        { name='Fleetstalker', gid=61, tier=3, hp=550000, currency=1300, cooldown=5400, drops = { { id=27605, name='Penetrating Cape' }, { id=26958, name='Sweller\'s Harness' }, { id=20847, name='Router' }, { id=27104, name='Shrieker\'s Cuffs' } } },
        { name='Shockmaw', gid=62, tier=3, hp=550000, currency=1300, cooldown=5400, drops = { { id=27464, name='Inspirited Boots' }, { id=27289, name='Doyen Pants' }, { id=27511, name='Dampener\'s Torque' }, { id=20938, name='Annealed Lance' } } },
        { name='Urmahlullu', gid=63, tier=3, hp=550000, currency=1300, cooldown=5400, drops = { { id=26963, name='Onca Suit' }, { id=28415, name='Eschan Stone' }, { id=27783, name='Skormoth Mask' }, { id=20523, name='Chastisers' } } },
        { name='Alpluachra', gid=52, tier=3, hp=550000, currency=1300, cooldown=5400, drops = { { id=28477, name='Hermetic Earring' }, { id=26960, name='Annointed Kalasiris' } } },
        { name='Bucca', gid=50, tier=3, hp=550000, currency=1300, cooldown=5400, drops = { { id=28477, name='Hermetic Earring' }, { id=26960, name='Annointed Kalasiris' } } },
        { name='Puca', gid=51, tier=3, hp=550000, currency=1300, cooldown=5400, drops = { { id=28477, name='Hermetic Earring' }, { id=26960, name='Annointed Kalasiris' } } },
        { name='Blazewing', gid=49, tier=3, hp=550000, currency=1300, cooldown=5400, drops = { { id=22253, name='Falcon Eye' }, { id=26959, name='Kubira Meikogai' } } },
        { name='Pazuzu', gid=53, tier=3, hp=550000, currency=1300, cooldown=5400, drops = { { id=27514, name='Empath Necklace' }, { id=26961, name='Makora Meikogai' } } },
        { name='Wrathare', gid=54, tier=3, hp=550000, currency=1300, cooldown=5400, drops = { { id=27555, name='Warden\'s Ring' }, { id=26962, name='Enforcer\'s Harness' } } },
        { name='Voso', gid=32, tier=3, hp=550000, currency=1500, cooldown=5400 },
        -- Boss ---------------------------------------------------------
        { name='Azi Dahaka', gid=64, tier=4, hp=1500000, currency=5000, cooldown=86400 },
    },
    [RUAUN] = {
        -- Tier 1 (Six Warders) — label= short menu text (150-byte menu cap)
        { name='Warder of Temperance', label='Temperance', gid=29, tier=1, hp=170000, currency=475, cooldown=1800 },
        { name='Warder of Faith', label='Faith', gid=31, tier=1, hp=170000, currency=475, cooldown=1800 },
        { name='Warder of Justice', label='Justice', gid=32, tier=1, hp=170000, currency=475, cooldown=1800 },
        { name='Warder of Hope', label='Hope', gid=34, tier=1, hp=170000, currency=475, cooldown=1800 },
        { name='Warder of Prudence', label='Prudence', gid=35, tier=1, hp=170000, currency=475, cooldown=1800 },
        { name='Warder of Love', label='Love', gid=36, tier=1, hp=170000, currency=475, cooldown=1800 },
        -- Tier 1 (retail 119) ------------------------------------------
        { name='Bia', gid=45, tier=1, hp=170000, currency=475, cooldown=1800, drops = { { id=21390, name='Albin Bane' }, { id=27521, name='Reti Pendant' } } },
        { name='Ruea', gid=46, tier=1, hp=170000, currency=475, cooldown=1800, drops = { { id=10772, name='Petrov Ring' }, { id=27522, name='Diemer Gorget' } } },
        { name='Ma', gid=47, tier=1, hp=170000, currency=475, cooldown=1800, drops = { { id=21410, name='Giuoco Grip' }, { id=27611, name='Philidor Mantle' } } },
        { name='Khon', gid=48, tier=1, hp=170000, currency=475, cooldown=1800, drops = { { id=27612, name='Sokolski Mantle' }, { id=27523, name='Caro Necklace' } } },
        { name='Met', gid=49, tier=1, hp=170000, currency=475, cooldown=1800, drops = { { id=22262, name='Amar Cluster' }, { id=27534, name='Evans Earring' } } },
        { name='Khun', gid=50, tier=1, hp=170000, currency=475, cooldown=1800, drops = { { id=28408, name='Grunfeld Rope' }, { id=27535, name='Halasz Earring' } } },
        { name='Wasserspeier', gid=51, tier=1, hp=170000, currency=475, cooldown=1800, drops = { { id=28409, name='Porous Rope' }, { id=27613, name='Quarrel Mantle' } } },
        { name='Emputa', gid=52, tier=1, hp=170000, currency=475, cooldown=1800, drops = { { id=10773, name='Fortified Ring' }, { id=27536, name='Assuage Earring' } } },
        { name='Peirithoos', gid=53, tier=1, hp=170000, currency=475, cooldown=1800, drops = { { id=27537, name='Ishvara Earring' }, { id=22263, name='Hydrocera' } } },
        { name='Asida', gid=54, tier=1, hp=170000, currency=475, cooldown=1800, drops = { { id=21411, name='Balarama Grip' }, { id=10774, name='Vertigo Ring' } } },
        { name='Tenodera', gid=55, tier=1, hp=170000, currency=475, cooldown=1800, drops = { { id=28410, name='Sulla Belt' }, { id=22264, name='Mantoptera Eye' } } },
        { name='Sava Savanovic', gid=56, tier=1, hp=170000, currency=475, cooldown=1800, drops = { { id=27524, name='Nodens Gorget' }, { id=26160, name='Evanescence Ring' } } },
        -- Tier 2 (retail 125) ------------------------------------------
        { name='Palila', gid=57, tier=2, hp=380000, currency=1050, cooldown=3600, drops = { { id=20700, name='Nixxer' }, { id=20979, name='Aizushintogo' }, { id=20519, name='Hammerfists' }, { id=20845, name='Instigator' } } },
        { name='Hanbi', gid=59, tier=2, hp=380000, currency=1050, cooldown=3600, drops = { { id=20597, name='Enchufla' }, { id=21149, name='Espiritus' }, { id=21150, name='Akademos' }, { id=20937, name='Rhomphaia' } } },
        { name='Yilan', gid=61, tier=2, hp=380000, currency=1050, cooldown=3600, drops = { { id=20701, name='Iris' }, { id=21151, name='Lathi' }, { id=20702, name='Emissary' }, { id=21084, name='Queller Rod' } } },
        { name='Amymone', gid=63, tier=2, hp=380000, currency=1050, cooldown=3600, drops = { { id=21482, name='Compensator' }, { id=20892, name='Deathbane' }, { id=20598, name='Shijo' }, { id=21698, name='Bidenhander' } } },
        { name='Naphula', gid=65, tier=2, hp=380000, currency=1050, cooldown=3600, drops = { { id=21085, name='Solstice' }, { id=20797, name='Skullrender' }, { id=21215, name='Vijaya Bow' } } },
        { name='Kammavaca', gid=67, tier=2, hp=380000, currency=1050, cooldown=3600, drops = { { id=20599, name='Kali' }, { id=21027, name='Ichigohitofuri' }, { id=20520, name='Midnights' } } },
        -- Tier 3 (retail 135) ------------------------------------------
        { name='Pakecet', gid=72, tier=3, hp=650000, currency=1800, cooldown=7200, drops = { { id=27614, name='Xucau Mantle' }, { id=27490, name='Tutyr Sabots' }, { id=25703, name='Uac Jerkin' }, { id=27134, name='Kurys Gloves' } } },
        { name='Duke Vepar', gid=74, tier=3, hp=650000, currency=1800, cooldown=7200, drops = { { id=20518, name='Eshus' }, { id=27319, name='Obatala Subligar' }, { id=25706, name='Shango Robe' }, { id=28411, name='Yemaya Belt' } } },
        { name='Vir\'ava', gid=76, tier=3, hp=650000, currency=1800, cooldown=7200, drops = { { id=21083, name='Sucellus' }, { id=27538, name='Lempo Earring' }, { id=25704, name='Abnoba Kaftan' }, { id=27320, name='Selvans Subligar' } } },
        -- Tier 3 (Ark Angels, retail 140) ------------------------------
        { name='Ark Angel EV', label='AA EV', gid=90, tier=3, hp=800000, currency=2200, cooldown=7200, drops = { { id=20704, name='Deacon Sword' }, { id=22265, name='Elis Tome' } } },
        { name='Ark Angel GK', label='AA GK', gid=91, tier=3, hp=800000, currency=2200, cooldown=7200, drops = { { id=21028, name='Deacon Blade' }, { id=6415, name='Seki Shuriken Pouch' } } },
        { name='Ark Angel HM', label='AA HM', gid=85, tier=3, hp=800000, currency=2200, cooldown=7200, drops = { { id=20703, name='Deacon Saber' }, { id=26322, name='Kerygma Belt' }, { id=27744, name='Lithelimb Cap' } } },
        { name='Ark Angel MR', label='AA MR', gid=87, tier=3, hp=800000, currency=2200, cooldown=7200, drops = { { id=20798, name='Deacon Tabar' }, { id=27617, name='Enuma Mantle' } } },
        { name='Ark Angel TT', label='AA TT', gid=86, tier=3, hp=800000, currency=2200, cooldown=7200, drops = { { id=20894, name='Deacon Scythe' }, { id=26162, name='Rahab Ring' }, { id=28616, name='Fravashi Mantle' } } },
        -- Tier 3 (Heavenly Beasts, retail 140/150) ---------------------
        { name='Byakko-Escha', label='Byakko', gid=78, tier=3, hp=700000, currency=2000, cooldown=7200, drops = { { id=22256, name='Jokushunoibuki' }, { id=20846, name='Jokushuono' }, { id=27318, name='Jokushu Haidate' }, { id=27525, name='Jokushu Chain' } } },
        { name='Genbu-Escha', label='Genbu', gid=79, tier=3, hp=700000, currency=2000, cooldown=7200, drops = { { id=22257, name='Genmeinoibuki' }, { id=27645, name='Genmei Shield' }, { id=25629, name='Genmei Kabuto' }, { id=27539, name='Genmei Earring' } } },
        { name='Seiryu-Escha', label='Seiryu', gid=80, tier=3, hp=700000, currency=2000, cooldown=7200, drops = { { id=22259, name='Kobonoibuki' }, { id=20699, name='Koboto' }, { id=27133, name='Kobo Kote' }, { id=26320, name='Kobo Obi' } } },
        { name='Suzaku-Escha', label='Suzaku', gid=81, tier=3, hp=700000, currency=2000, cooldown=7200, drops = { { id=22258, name='Shukuyunoibuki' }, { id=20893, name='Shukuyu\'s Scythe' }, { id=27489, name='Shukuyu Sune-Ate' }, { id=26161, name='Shukuyu Ring' } } },
        { name='Kirin', gid=82, tier=3, hp=1200000, currency=3500, cooldown=7200 },
        { name='Kouryu', gid=84, tier=3, hp=1000000, currency=3500, cooldown=7200, drops = { { id=27615, name='Reiki Cloak' }, { id=20842, name='Reikiono' }, { id=21152, name='Reikikon' }, { id=20690, name='Reikiko' }, { id=26321, name='Reiki Yotai' }, { id=25702, name='Reiki Osode' } } },
        -- Boss ---------------------------------------------------------
        { name='Warder of Courage', label='Courage', gid=93, tier=4, hp=2000000, currency=8000, cooldown=86400, drops = { { id=22196, name='Alber Strap' }, { id=20887, name='Dacnomania' }, { id=20932, name='Habile Mazrak' }, { id=19209, name='Molybdosis' }, { id=27545, name='Telos Earring' }, { id=25728, name='Zendik Robe' } } },
    },
}

-- ===================================================================
-- CURRENCY HELPERS
-- ===================================================================
-- UNIFIED (2026-07-09): every Escha kill (Zi'Tah AND Ru'Aun) awards ONE currency
-- -- the real 'escha_beads' (char_points, Currencies II tab) -- so a single pool
-- funds BOTH Warding Circle exchanges, the Temprix Aeonic vendor, and the Aeonic
-- WeaponForge. escha_beads is a REAL currency (visible/spendable anywhere), NOT a
-- charVar. Both zones map to it.
local BEADS          = 'escha_beads'
local CURRENCY_KEY   = { [ZITAH] = BEADS, [RUAUN] = BEADS }
local CURRENCY_LABEL = { [ZITAH] = 'Escha Beads', [RUAUN] = 'Escha Beads' }

-- Fold the DEAD legacy charVars (Escha_Beads / Escha_Silt, from before the
-- real-currency refactor) into the unified escha_beads currency on access, so
-- pre-refactor balances aren't stranded. Idempotent -- each var is zeroed once.
-- NOTE: the real 'escha_silt' CURRENCY is intentionally NOT folded -- it is still
-- the Eschan portal travel cost (scripts/globals/teleports/eschan_portals.lua)
-- and Domain Invasion fuel, a separate currency from content beads.
local function migrateLegacy(player)
    for _, var in ipairs({ 'Escha_Beads', 'Escha_Silt' }) do
        local old = player:getCharVar(var) or 0
        if old > 0 then
            player:addCurrency(BEADS, old)
            player:setCharVar(var, 0)
        end
    end
end

local function getCurrency(player, zoneId)
    migrateLegacy(player)
    return player:getCurrency(CURRENCY_KEY[zoneId]) or 0
end

local function addCurrency(player, zoneId, amount)
    migrateLegacy(player)
    player:addCurrency(CURRENCY_KEY[zoneId], amount)
end

local function takeCurrency(player, zoneId, amount)
    migrateLegacy(player)
    local k = CURRENCY_KEY[zoneId]
    if (player:getCurrency(k) or 0) < amount then return false end
    player:delCurrency(k, amount)
    return true
end

-- ===================================================================
-- COOLDOWN HELPERS
-- ===================================================================
local function cooldownKey(zoneId, gid)
    return string.format('GF_%d_%d', zoneId, gid)
end

local function getCooldown(player, zoneId, gid)
    local expires = player:getCharVar(cooldownKey(zoneId, gid)) or 0
    local now     = os.time()
    return (expires > now) and (expires - now) or 0
end

local function setCooldown(player, zoneId, gid, seconds)
    player:setCharVar(cooldownKey(zoneId, gid), os.time() + seconds)
end

local function fmtCD(secs)
    if secs <= 0 then return '>>' end
    if secs < 3600 then return string.format('%dm', math.ceil(secs / 60)) end
    return string.format('%dh', math.ceil(secs / 3600))
end

-- ===================================================================
-- DROP HELPER (awarded to killer on mob death)
-- ===================================================================
local function awardDrops(player, zoneId, def)
    local t = def.tier
    -- Beitetsu
    local bei = math.random(t, t * 2)
    -- Riftcinder: T2+ only
    local rc = (t >= 2) and math.random(1, t) or 0
    -- Riftborn Boulder: T3+ guaranteed, T2 30% chance
    local rb
    if t >= 3 then
        rb = math.random(1, t - 1)
    elseif t == 2 then
        rb = (math.random() < 0.30) and 1 or 0
    else
        rb = 0
    end
    -- Eschalixir +2: boss only, always
    local lix = (t == 4) and 1 or 0

    if bei > 0 then player:addItem({ id = BEITETSU,         quantity = bei }) end
    if rc  > 0 then player:addItem({ id = RIFTCINDER,       quantity = rc  }) end
    if rb  > 0 then player:addItem({ id = RIFTBORN_BOULDER, quantity = rb  }) end
    if lix > 0 then player:addItem({ id = ESCHALIXIR_2,     quantity = lix }) end

    -- Boss only: 1 random Attestation (Aeonic path material).
    -- 40% chance of a second random Attestation.
    if t == 4 then
        player:addItem({ id = ATTESTATIONS[math.random(#ATTESTATIONS)], quantity = 1 })
        if math.random() < 0.40 then
            player:addItem({ id = ATTESTATIONS[math.random(#ATTESTATIONS)], quantity = 1 })
        end
    end

    -- Retail signature drops: each NM's own drop list (see NM_CATALOG),
    -- every listed item rolled independently. Bosses are more generous.
    if def.drops then
        local rate = (t == 4) and FETE_BOSS_DROP_RATE or FETE_DROP_RATE
        for _, dr in ipairs(def.drops) do
            if math.random() < rate then
                if player:addItem({ id = dr.id, quantity = 1 }) then
                    player:printToPlayer(string.format('[Geas Fete] %s drops: %s!',
                        def.name, dr.name), S)
                end
            end
        end
    end

    -- Reisenjima-crafted armor (Adhemar/Argosy/Carmine/Rao/Ryuo/Souveran/Naga):
    -- T2 rolls an NQ piece, T3/boss roll NQ and the +1. Random piece from the
    -- whole pool -- the hunt is the gate, not a job lock.
    local nqChance = ({ [2] = 0.20, [3] = 0.35, [4] = 0.50 })[t] or 0
    local hqChance = ({ [3] = 0.10, [4] = 0.25 })[t] or 0
    if math.random() < nqChance then
        local id = GEAR_NQ[math.random(#GEAR_NQ)]
        if player:addItem({ id = id, quantity = 1 }) then
            player:printToPlayer('[Geas Fete] The vanquished NM yields a piece of Reisenjima armor!', S)
        end
    end
    if math.random() < hqChance then
        local id = GEAR_HQ[math.random(#GEAR_HQ)]
        if player:addItem({ id = id, quantity = 1 }) then
            player:printToPlayer('[Geas Fete] A pristine (+1) piece of Reisenjima armor drops!', S)
        end
    end
end

-- ===================================================================
-- NM SPAWN
-- ===================================================================
local function spawnNM(player, zone, zoneId, def)
    local px, py, pz = player:getXPos(), player:getYPos(), player:getZPos()
    local angle = math.random() * math.pi * 2
    local dist  = 12 + math.random(0, 8)
    local mx    = px + math.cos(angle) * dist
    local mz    = pz + math.sin(angle) * dist

    local rot        = math.random(0, 255)
    local defCapture = def

    local mob = zone:insertDynamicEntity({
        objtype              = xi.objType.MOB,
        name                 = defCapture.name:gsub(' ', '_'),
        groupId              = defCapture.gid,
        groupZoneId          = zoneId,
        x                    = mx,
        y                    = py,
        z                    = mz,
        rotation             = rot,
        minLevel             = 149,
        maxLevel             = 149,
        detection            = xi.detects.SIGHT_AND_HEARING,
        isAggroable          = true,
        releaseIdOnDisappear = true,

        onMobDeath = function(mob, killer, isKiller, noKillTly)
            if not isKiller then return end
            local cur = defCapture.currency or 0
            if cur > 0 then
                addCurrency(killer, zoneId, cur)
            end
            awardDrops(killer, zoneId, defCapture)
            local clbl = CURRENCY_LABEL[zoneId] or 'pts'
            killer:printToPlayer(string.format('[Geas Fete] %s defeated! +%d %s',
                defCapture.name, cur, clbl), S)
        end,
    })

    if mob then
        -- A dynamically-inserted MOB is created but INACTIVE until spawned.
        -- Without setSpawn()+spawn() the entity exists (so the caller's
        -- "emerges from the darkness!" message fires) but never appears in the
        -- world -- which is exactly the "it said it spawned but didn't" bug.
        mob:setSpawn(mx, py, mz, rot)
        mob:spawn()
        -- Some Escha Warder pools ship with FLAG_UNTARGETABLE (0x800) baked into
        -- mob_pools.entityFlags -- retail spawns them sealed/untargetable and the
        -- Geas Fete encounter unseals them. Warder of Hope (pool 5659) and Warder
        -- of Love (pool 5661) are entityFlags=2183 (=0x887, has 0x800); the other
        -- four Warders are 135 and work. Since this is a pop-on-demand system where
        -- every NM should be immediately fightable, clear the flag unconditionally
        -- after spawn (no-op for pools that never had it). Without this the mob is
        -- visible but can't be attacked/shot/cast on -- the reported bug.
        mob:setUntargetable(false)
        if def.hp and def.hp > 0 then
            mob:setMaxHP(def.hp)
            mob:setHP(def.hp)
        end
        mob:updateClaim(player)
    end
    return mob
end

-- ===================================================================
-- MENU SYSTEM
-- ===================================================================
-- Tier menu: lists NMs of a specific tier with cooldown status.
-- Returns the options table for the shared menu.
-- Full-roster tiers hold up to 18 NMs, well past the customMenu byte/entry
-- budget -- paginate like the shops (NM_PER_PAGE entries + More >> / Back).
local NM_PER_PAGE = 6

local function tierOptions(player, zone, zoneId, tierNum, mainFn, menu, page, reshowFn)
    page = page or 0
    local defs = {}
    for _, def in ipairs(NM_CATALOG[zoneId] or {}) do
        if def.tier == tierNum then
            defs[#defs + 1] = def
        end
    end
    local pages = math.max(1, math.ceil(#defs / NM_PER_PAGE))
    page = page % pages

    local opts = {}
    for i = page * NM_PER_PAGE + 1, math.min((page + 1) * NM_PER_PAGE, #defs) do
        local d   = defs[i]
        local cd  = getCooldown(player, zoneId, d.gid)
        local lbl = string.format('%s [%s]', d.label or d.name, fmtCD(cd))
        opts[#opts + 1] = { lbl, function(p)
            local cd2 = getCooldown(p, zoneId, d.gid)
            if cd2 > 0 then
                p:printToPlayer(string.format('[Geas Fete] %s: %s remaining.',
                    d.name, fmtCD(cd2)), S)
                return
            end
            local spawned = spawnNM(p, zone, zoneId, d)
            if spawned then
                setCooldown(p, zoneId, d.gid, d.cooldown)
                p:printToPlayer(string.format('[Geas Fete] %s emerges from the darkness!',
                    d.name), S)
            else
                p:printToPlayer('[Geas Fete] The seal will not yield. Try again.', S)
            end
        end }
    end
    if pages > 1 then
        opts[#opts + 1] = { string.format('More >> (%d/%d)', page + 1, pages),
            function(p) reshowFn(p, page + 1) end }
    end
    opts[#opts + 1] = { 'Back', function(p) mainFn(p) end }
    return opts
end

-- Exchange shop: spend currency on materials. Each material opens a quantity
-- submenu (x1 / x10 / x<stack> / Max) -- the Aeonic/Mythic forge steps need
-- materials by the thousands (Mythic II+III alone is 10,300 Beitetsu), so
-- one-per-click is not viable. Max buys as many as beads AND bag space allow.
local function buildShop(player, zone, zoneId, mainFn, menu)
    local clbl   = CURRENCY_LABEL[zoneId] or 'pts'
    local shopFn -- forward decl

    -- Keep one entry per line: the site's geas_fete docgen parses label=/cost=.
    local SHOP = {
        { label='Beitetsu',         id=BEITETSU,         stack=99, cost=200  },
        { label='Riftcinder',       id=RIFTCINDER,       stack=99, cost=150  },
        { label='Riftborn Boulder', id=RIFTBORN_BOULDER, stack=99, cost=500  },
        { label='Eschalixir+2',     id=ESCHALIXIR_2,     stack=12, cost=2000 },
    }

    -- Grant items FIRST (batched per stack, stopping when the bag fills), then
    -- charge only for what actually landed -- a full inventory can never eat
    -- beads. Affordability is pre-checked and nothing yields in between, so
    -- the final takeCurrency cannot come up short.
    local function buy(pp, it, want)
        local afford = math.floor(getCurrency(pp, zoneId) / it.cost)
        if afford < 1 then
            pp:printToPlayer(string.format('[Geas Fete] Need %d %s.', it.cost, clbl), S)
            return
        end
        local n     = math.min(want, afford)
        local added = 0
        while added < n do
            local batch = math.min(it.stack, n - added)
            if not pp:addItem({ id = it.id, quantity = batch }) then break end
            added = added + batch
        end
        if added == 0 then
            pp:printToPlayer('[Geas Fete] Your inventory is full.', S)
            return
        end
        takeCurrency(pp, zoneId, added * it.cost)
        pp:printToPlayer(string.format('[Geas Fete] %s x%d for %d %s.', it.label, added, added * it.cost, clbl), S)
        if added < n then
            pp:printToPlayer('[Geas Fete] Inventory filled -- exchanged what fit.', S)
        end
    end

    local function qtyMenu(pp, it)
        menu.title = string.format('%s [%s: %d]', it.label, clbl, getCurrency(pp, zoneId))
        local function opt(n)
            return {
                string.format('x%d (%d)', n, n * it.cost),
                function(p2)
                    buy(p2, it, n)
                    p2:timer(30, function(p3) qtyMenu(p3, it) end)
                end,
            }
        end
        menu.options = {
            opt(1),
            opt(10),
            opt(it.stack),
            { 'Max', function(p2)
                buy(p2, it, math.floor(getCurrency(p2, zoneId) / it.cost))
                p2:timer(30, function(p3) qtyMenu(p3, it) end)
            end },
            { 'Back', function(p2) shopFn(p2) end },
        }
        pp:timer(30, function(p2) p2:customMenu(menu) end)
    end

    shopFn = function(p)
        local cur = getCurrency(p, zoneId)
        menu.title = string.format('%s Exchange [%d]', clbl, cur)
        menu.options = {}
        for _, item in ipairs(SHOP) do
            local it = item
            menu.options[#menu.options + 1] = {
                string.format('%s (%d)', it.label, it.cost),
                function(pp) qtyMenu(pp, it) end,
            }
        end
        menu.options[#menu.options + 1] = { 'Back', function(pp) mainFn(pp) end }
        p:timer(30, function(p2) p2:customMenu(menu) end)
    end

    return shopFn
end

-- Main Warding Circle menu for one zone.
local function wardingCircleMenu(player, zone, zoneId)
    local clbl  = CURRENCY_LABEL[zoneId] or 'pts'
    local menu  = { title = '', options = {} }
    local mainFn, shopFn

    local function show(p)
        p:timer(30, function(p2) p2:customMenu(menu) end)
    end

    local function tierScreen(p, tierNum, tierTitle, page)
        menu.title   = tierTitle
        menu.options = tierOptions(p, zone, zoneId, tierNum, mainFn, menu, page,
            function(p2, nextPage) tierScreen(p2, tierNum, tierTitle, nextPage) end)
        show(p)
    end

    shopFn = buildShop(player, zone, zoneId, function(p) mainFn(p) end, menu)

    mainFn = function(p)
        local cur = getCurrency(p, zoneId)
        menu.title   = string.format('Warding Circle [%s: %d]', clbl, cur)
        menu.options = {
            { 'Tier I NMs',   function(pp) tierScreen(pp, 1, '-- Tier I NMs --')   end },
            { 'Tier II NMs',  function(pp) tierScreen(pp, 2, '-- Tier II NMs --')  end },
            { 'Tier III NMs', function(pp) tierScreen(pp, 3, '-- Tier III NMs --') end },
            { 'Zone Boss',    function(pp) tierScreen(pp, 4, '-- Zone Boss --')     end },
            { string.format('Exchange %s', clbl), function(pp) shopFn(pp) end },
            { 'Leave', function(pp) end },
        }
        show(p)
    end

    mainFn(player)
end

-- ===================================================================
-- ZONE HOOKS
-- ===================================================================
local function spawnWardingCircle(zone, zoneId, x, y, z, rot)
    local capturedZone   = zone
    local capturedZoneId = zoneId
    local wc = zone:insertDynamicEntity({
        objtype    = xi.objType.NPC,
        name       = string.format('GF_WardingCircle_%d', zoneId),
        packetName = string.format('%sWarding Circle', xi.icon.STAR_LARGE),
        look       = 171,
        x          = x,
        y          = y,
        z          = z,
        rotation   = rot,
        widescan   = 1,

        onTrigger = function(player, npc)
            wardingCircleMenu(player, capturedZone, capturedZoneId)
        end,
    })
    utils.unused(wc)
end

-- Escha - Zi'Tah (288)
-- Placed near the HL zone guide (x≈3, z≈-30) but offset slightly.
m:addOverride('xi.zones.Escha_ZiTah.Zone.onInitialize', function(zone)
    super(zone)
    spawnWardingCircle(zone, ZITAH, 3.0, -0.5, -20.0, 128)
end)

-- Escha - Ru'Aun (289)
-- Placed near the zone entry point, clear of the GM wave NPC area.
m:addOverride('xi.zones.Escha_RuAun.Zone.onInitialize', function(zone)
    super(zone)
    spawnWardingCircle(zone, RUAUN, 5.0, -34.277, -455.0, 64)
end)

-- Reisenjima (291) redirect signpost. Players come here for Temprix (the Aeonic
-- vendor) and, out of retail habit, hunt for a Geas Fete Warding Circle in the
-- old spot -- but on relaunch the Geas Fete NMs live in Escha. This signpost
-- sits right at the zone-in point (arrival is -500.0, -19.1, -487.7) so anyone
-- looking for the circle gets pointed to the right zone.
local function spawnReisenSignpost(zone)
    local sp = zone:insertDynamicEntity({
        objtype    = xi.objType.NPC,
        name       = 'GF_Reisen_Signpost',
        packetName = string.format('%sGeas Fete Notice', xi.icon.STAR_LARGE),
        look       = 171,
        x          = -497.0,
        y          = -19.07,
        z          = -484.0,
        rotation   = 190,
        widescan   = 1,

        onTrigger = function(player, npc)
            player:printToPlayer('[Geas Fete] The Warding Circles are in ESCHA now. Fight the Geas Fete NMs (Escha Beads/Silt + Attestations) at the Warding Circle in Escha - Zi\'Tah and Escha - Ru\'Aun -- type !hunt to warp to the Zi\'Tah hub.', S)
            player:printToPlayer('[Geas Fete] Reisenjima still hosts Temprix, the Aeonic weapon vendor (Malformed base weapons for 50,000 Escha Beads), further into the zone.', S)
        end,
    })
    utils.unused(sp)
end

m:addOverride('xi.zones.Reisenjima.Zone.onInitialize', function(zone)
    super(zone)
    spawnReisenSignpost(zone)
end)

return m
