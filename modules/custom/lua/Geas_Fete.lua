-----------------------------------
-- Geas_Fete.lua
--
-- Escha Geas Fete for the relaunch server.
--
-- Pop mechanic (retail-style, owner request 2026-07-12): the stock retail
-- ??? points scattered across Escha - Zi'Tah (12), Escha - Ru'Aun (30), and
-- Reisenjima (23) each host specific NMs (QM_POINTS below). Inspect a ???
-- to pop one of ITS NMs -- no trinkets/Tribulens (relaunch-friendly), just
-- the per-player per-NM cooldown (charVar GF_<zoneId>_<groupId>). NMs with
-- real retail camps in the stock spawn data got their retail ???; NMs whose
-- stock spawns are placeholder clusters were spread across the remaining
-- ???s so every point hosts 1-5 NMs.
-- The Warding Circle NPCs remain as the Escha Beads material EXCHANGE only
-- (one per zone; Reisenjima's replaces the old redirect signpost).
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
-- Raised 2026-07-13 (owner: NMs felt like they never dropped -- at 0.15 a
-- 2-drop NM whiffed ~72% of kills). Plus FETE_DROP_GUARANTEE: if the
-- independent rolls all miss, one random signature item is forced, so EVERY
-- kill yields at least one piece of the NM's gear.
local FETE_DROP_RATE      = 0.35
local FETE_BOSS_DROP_RATE = 0.60
local FETE_DROP_GUARANTEE = true

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

-- Reisenjima abjurations (owner request 2026-07-13: 'these should drop from
-- our geas-fete NMs'). 5 augmented-armor families x 5 slots = 25 items.
-- T3+ NMs roll for one; the AbjurationForge NPC in the hub trades an
-- abjuration for its matching augmented armor piece (slot- and family-locked).
--   Bushin      -> Valorous       Cyllenian  -> Odyssean
--   Foreboding  -> Chironic       Grove      -> Merlinic
--   Hadean      -> Herculean
local ABJURATIONS = {
    -- Bushin (-> Valorous)
    8762, 8763, 8764, 8765, 8766,  -- head/body/hands/legs/feet
    -- Cyllenian (-> Odyssean)
    9125, 9126, 9127, 9128, 9129,
    -- Foreboding (-> Chironic)
    3574, 3575, 3576, 3577, 3578,
    -- Grove (-> Merlinic)
    8772, 8773, 8774, 8775, 8776,
    -- Hadean (-> Herculean)
    2434, 2435, 2436, 2437, 2438,
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
local ZITAH  = xi.zone.ESCHA_ZITAH  -- 288
local RUAUN  = xi.zone.ESCHA_RUAUN  -- 289
local REISEN = xi.zone.REISENJIMA   -- 291

local NM_CATALOG = {
    -- Full retail Geas Fete roster (BG-wiki, 2026-07-12) + the relaunch
    -- originals. gids are stock mob_groups rows for zones 288/289. Each
    -- retail NM carries its retail signature drops (drops = {...}); the
    -- roll happens in awardDrops (FETE_DROP_RATE / FETE_BOSS_DROP_RATE).
    -- Kirin has no retail gear table -- he pays beads + the T3 material
    -- spread. Retail tiering: 119->T1, 125->T2, 135/HELM/AA/gods->T3.
    [ZITAH] = {
        -- Tier 1 (retail 119) ------------------------------------------
        { name='Wepwawet', gid=37, tier=1, hp=260000, currency=350, cooldown=1800, delay=280, drops = { { id=27099, name='Naga Tekko' }, { id=27461, name='Pursuer\'s Gaiters' }, { id=21413, name='Clemency Grip' }, { id=26791, name='Eschite Helm' } } },
        { name='Lustful Lydia', gid=38, tier=1, hp=260000, currency=350, cooldown=1800, drops = { { id=26947, name='Eschite Breastplate' }, { id=27284, name='Naga Hakama' }, { id=26796, name='Psycloth Tiara' }, { id=22250, name='Seraphic Ampulla' } } },
        { name='Aglaophotis', gid=39, tier=1, hp=260000, currency=350, cooldown=1800, drops = { { id=27097, name='Eschite Gauntlets' }, { id=26952, name='Psycloth Vest' }, { id=27459, name='Naga Kyahan' }, { id=27512, name='Marked Gorget' } } },
        { name='Tangata Manu', gid=40, tier=1, hp=260000, currency=350, cooldown=1800, drops = { { id=27282, name='Eschite Cuisses' }, { id=27102, name='Psycloth Manillas' }, { id=28474, name='Mendicant\'s Earring' }, { id=26794, name='Rawhide Mask' } } },
        { name='Vidala', gid=41, tier=1, hp=260000, currency=350, cooldown=1800, drops = { { id=27552, name='Overbearing Ring' }, { id=27287, name='Psycloth Lappas' }, { id=26950, name='Rawhide Vest' }, { id=27457, name='Eschite Greaves' } } },
        { name='Gestalt', gid=42, tier=1, hp=260000, currency=350, cooldown=1800, drops = { { id=27462, name='Psycloth Boots' }, { id=26792, name='Despair Helm' }, { id=27606, name='Disperser\'s Cape' }, { id=27100, name='Rawhide Gloves' } } },
        { name='Angrboda', gid=43, tier=1, hp=260000, currency=350, cooldown=1800, delay=280, drops = { { id=28416, name='Lucidity Sash' }, { id=26948, name='Despair Mail' }, { id=26797, name='Vanya Hood' }, { id=27285, name='Rawhide Trousers' } } },
        { name='Cunnast', gid=44, tier=1, hp=260000, currency=350, cooldown=1800, drops = { { id=26953, name='Vanya Robe' }, { id=27098, name='Despair Finger Gauntlets' }, { id=27460, name='Rawhide Boots' }, { id=21414, name='Willpower Grip' } } },
        { name='Revetaur', gid=45, tier=1, hp=260000, currency=350, cooldown=1800, drops = { { id=26795, name='Pursuer\'s Beret' }, { id=27103, name='Vanya Cuffs' }, { id=27283, name='Despair Cuisses' }, { id=22251, name='Grenade Core' } } },
        { name='Ferrodon', gid=46, tier=1, hp=260000, currency=350, cooldown=1800, drops = { { id=27458, name='Despair Greaves' }, { id=27513, name='Subtlety Spectacles' }, { id=26951, name='Pursuer\'s Doublet' }, { id=27288, name='Vanya Slops' } } },
        { name='Gulltop', gid=47, tier=1, hp=260000, currency=350, cooldown=1800, drops = { { id=27101, name='Pursuer\'s Cuffs' }, { id=26793, name='Naga Somen' }, { id=27463, name='Vanya Clogs' }, { id=28475, name='Infused Earring' } } },
        { name='Vyala', gid=48, tier=1, hp=260000, currency=350, cooldown=1800, drops = { { id=27553, name='Resonance Ring' }, { id=27286, name='Pursuer\'s Pants' }, { id=26949, name='Naga Samue' } } },
        -- Tier 1 (relaunch originals) ----------------------------------
        { name='Hugemaw Harold', gid=24, tier=1, hp=260000, currency=350, cooldown=1800 },
        { name='Prickly Pitriv', gid=25, tier=1, hp=260000, currency=350, cooldown=1800 },
        { name='Serpopard Ninlil', gid=26, tier=1, hp=260000, currency=350, cooldown=1800 },
        { name='Abyssdiver', gid=27, tier=1, hp=260000, currency=350, cooldown=1800 },
        { name='Eschan Jewelweed', gid=36, tier=1, hp=260000, currency=350, cooldown=1800 },
        -- Tier 2 (retail 125) ------------------------------------------
        { name='Ionos', gid=55, tier=2, hp=640000, currency=800, cooldown=1800, drops = { { id=20524, name='Nibiru Sainti' }, { id=21216, name='Nibiru Bow' }, { id=20895, name='Nibiru Sickle' }, { id=27607, name='Thaumaturge\'s Cape' } } },
        { name='Sensual Sandy', gid=56, tier=2, hp=640000, currency=800, cooldown=1800, drops = { { id=20600, name='Nibiru Knife' }, { id=20939, name='Nibiru Lance' }, { id=21273, name='Nibiru Gun' }, { id=28417, name='Sinew Belt' } } },
        { name='Nosoi', gid=57, tier=2, hp=640000, currency=800, cooldown=1800, drops = { { id=20710, name='Nibiru Blade' }, { id=28476, name='Calamitous Earring' }, { id=20983, name='Mijin' }, { id=27642, name='Nibiru Shield' } } },
        { name='Brittlis', gid=58, tier=2, hp=640000, currency=800, cooldown=1800, drops = { { id=27554, name='Purity Ring' }, { id=21699, name='Nibiru Faussar' }, { id=21399, name='Nibiru Harp' }, { id=21031, name='Sensui' } } },
        { name='Kamohoalii', gid=59, tier=2, hp=640000, currency=800, cooldown=1800, drops = { { id=20801, name='Nibiru Tabar' }, { id=21092, name='Nibiru Cudgel' }, { id=21415, name='Forefathers\' Grip' } } },
        { name='Umdhlebi', gid=60, tier=2, hp=640000, currency=800, cooldown=1800, drops = { { id=20848, name='Nibiru Chopper' }, { id=21156, name='Nibiru Staff' }, { id=22252, name='Sapience Orb' } } },
        -- Tier 2 (relaunch originals) ----------------------------------
        { name='Keeper of Heiligtum', gid=28, tier=2, hp=640000, currency=800, cooldown=1800, delay=260 },
        { name='Jester Malatrix', gid=33, tier=2, hp=640000, currency=800, cooldown=1800 },
        { name='Immanibugard', gid=34, tier=2, hp=640000, currency=800, cooldown=1800 },
        { name='Beist', gid=35, tier=2, hp=640000, currency=800, cooldown=1800 },
        -- Tier 3 (retail 135 + HELM NMs) -------------------------------
        { name='Fleetstalker', gid=61, tier=3, hp=1100000, currency=1300, cooldown=1800, drops = { { id=27605, name='Penetrating Cape' }, { id=26958, name='Sweller\'s Harness' }, { id=20847, name='Router' }, { id=27104, name='Shrieker\'s Cuffs' } } },
        { name='Shockmaw', gid=62, tier=3, hp=1100000, currency=1300, cooldown=1800, drops = { { id=27464, name='Inspirited Boots' }, { id=27289, name='Doyen Pants' }, { id=27511, name='Dampener\'s Torque' }, { id=20938, name='Annealed Lance' } } },
        { name='Urmahlullu', gid=63, tier=3, hp=1100000, currency=1300, cooldown=1800, delay=240, spellList=5, mp=9999, drops = { { id=26963, name='Onca Suit' }, { id=28415, name='Eschan Stone' }, { id=27783, name='Skormoth Mask' }, { id=20523, name='Chastisers' } } },
        { name='Alpluachra', gid=52, tier=3, hp=1100000, currency=1300, cooldown=1800, drops = { { id=28477, name='Hermetic Earring' }, { id=26960, name='Annointed Kalasiris' } } },
        { name='Bucca', gid=50, tier=3, hp=1100000, currency=1300, cooldown=1800, drops = { { id=28477, name='Hermetic Earring' }, { id=26960, name='Annointed Kalasiris' } } },
        { name='Puca', gid=51, tier=3, hp=1100000, currency=1300, cooldown=1800, drops = { { id=28477, name='Hermetic Earring' }, { id=26960, name='Annointed Kalasiris' } } },
        { name='Blazewing', gid=49, tier=3, hp=1100000, currency=1300, cooldown=1800, drops = { { id=22253, name='Falcon Eye' }, { id=26959, name='Kubira Meikogai' } } },
        { name='Pazuzu', gid=53, tier=3, hp=1100000, currency=1300, cooldown=1800, drops = { { id=27514, name='Empath Necklace' }, { id=26961, name='Makora Meikogai' } } },
        { name='Wrathare', gid=54, tier=3, hp=1100000, currency=1300, cooldown=1800, drops = { { id=27555, name='Warden\'s Ring' }, { id=26962, name='Enforcer\'s Harness' } } },
        { name='Voso', gid=32, tier=3, hp=1100000, currency=1500, cooldown=1800 },
        -- Boss ---------------------------------------------------------
        { name='Azi Dahaka', gid=64, tier=4, hp=3000000, currency=5000, cooldown=1800 },
    },
    [RUAUN] = {
        -- Tier 1 (Six Warders) — label= short menu text (150-byte menu cap)
        { name='Warder of Temperance', label='Temperance', gid=29, tier=1, hp=340000, currency=475, cooldown=1800 },
        { name='Warder of Faith', label='Faith', gid=31, tier=1, hp=340000, currency=475, cooldown=1800 },
        { name='Warder of Justice', label='Justice', gid=32, tier=1, hp=340000, currency=475, cooldown=1800 },
        { name='Warder of Hope', label='Hope', gid=34, tier=1, hp=340000, currency=475, cooldown=1800 },
        { name='Warder of Prudence', label='Prudence', gid=35, tier=1, hp=340000, currency=475, cooldown=1800 },
        { name='Warder of Love', label='Love', gid=36, tier=1, hp=340000, currency=475, cooldown=1800 },
        -- Tier 1 (retail 119) ------------------------------------------
        { name='Bia', gid=45, tier=1, hp=340000, currency=475, cooldown=1800, drops = { { id=21390, name='Albin Bane' }, { id=27521, name='Reti Pendant' } } },
        { name='Ruea', gid=46, tier=1, hp=340000, currency=475, cooldown=1800, drops = { { id=10772, name='Petrov Ring' }, { id=27522, name='Diemer Gorget' } } },
        { name='Ma', gid=47, tier=1, hp=340000, currency=475, cooldown=1800, drops = { { id=21410, name='Giuoco Grip' }, { id=27611, name='Philidor Mantle' } } },
        { name='Khon', gid=48, tier=1, hp=340000, currency=475, cooldown=1800, drops = { { id=27612, name='Sokolski Mantle' }, { id=27523, name='Caro Necklace' } } },
        { name='Met', gid=49, tier=1, hp=340000, currency=475, cooldown=1800, drops = { { id=22262, name='Amar Cluster' }, { id=27534, name='Evans Earring' } } },
        { name='Khun', gid=50, tier=1, hp=340000, currency=475, cooldown=1800, drops = { { id=28408, name='Grunfeld Rope' }, { id=27535, name='Halasz Earring' } } },
        { name='Wasserspeier', gid=51, tier=1, hp=340000, currency=475, cooldown=1800, drops = { { id=28409, name='Porous Rope' }, { id=27613, name='Quarrel Mantle' } } },
        { name='Emputa', gid=52, tier=1, hp=340000, currency=475, cooldown=1800, drops = { { id=10773, name='Fortified Ring' }, { id=27536, name='Assuage Earring' } } },
        { name='Peirithoos', gid=53, tier=1, hp=340000, currency=475, cooldown=1800, drops = { { id=27537, name='Ishvara Earring' }, { id=22263, name='Hydrocera' } } },
        { name='Asida', gid=54, tier=1, hp=340000, currency=475, cooldown=1800, drops = { { id=21411, name='Balarama Grip' }, { id=10774, name='Vertigo Ring' } } },
        { name='Tenodera', gid=55, tier=1, hp=340000, currency=475, cooldown=1800, drops = { { id=28410, name='Sulla Belt' }, { id=22264, name='Mantoptera Eye' } } },
        { name='Sava Savanovic', gid=56, tier=1, hp=340000, currency=475, cooldown=1800, drops = { { id=27524, name='Nodens Gorget' }, { id=26160, name='Evanescence Ring' } } },
        -- Tier 2 (retail 125) ------------------------------------------
        { name='Palila', gid=57, tier=2, hp=760000, currency=1050, cooldown=1800, drops = { { id=20700, name='Nixxer' }, { id=20979, name='Aizushintogo' }, { id=20519, name='Hammerfists' }, { id=20845, name='Instigator' } } },
        { name='Hanbi', gid=59, tier=2, hp=760000, currency=1050, cooldown=1800, drops = { { id=20597, name='Enchufla' }, { id=21149, name='Espiritus' }, { id=21150, name='Akademos' }, { id=20937, name='Rhomphaia' } } },
        { name='Yilan', gid=61, tier=2, hp=760000, currency=1050, cooldown=1800, delay=260, drops = { { id=20701, name='Iris' }, { id=21151, name='Lathi' }, { id=20702, name='Emissary' }, { id=21084, name='Queller Rod' } } },
        { name='Amymone', gid=63, tier=2, hp=760000, currency=1050, cooldown=1800, drops = { { id=21482, name='Compensator' }, { id=20892, name='Deathbane' }, { id=20598, name='Shijo' }, { id=21698, name='Bidenhander' } } },
        { name='Naphula', gid=65, tier=2, hp=760000, currency=1050, cooldown=1800, drops = { { id=21085, name='Solstice' }, { id=20797, name='Skullrender' }, { id=21215, name='Vijaya Bow' } } },
        { name='Kammavaca', gid=67, tier=2, hp=760000, currency=1050, cooldown=1800, drops = { { id=20599, name='Kali' }, { id=21027, name='Ichigohitofuri' }, { id=20520, name='Midnights' } } },
        -- Tier 3 (retail 135) ------------------------------------------
        { name='Pakecet', gid=72, tier=3, hp=1300000, currency=1800, cooldown=1800, drops = { { id=27614, name='Xucau Mantle' }, { id=27490, name='Tutyr Sabots' }, { id=25703, name='Uac Jerkin' }, { id=27134, name='Kurys Gloves' } } },
        { name='Duke Vepar', gid=74, tier=3, hp=1300000, currency=1800, cooldown=1800, drops = { { id=20518, name='Eshus' }, { id=27319, name='Obatala Subligar' }, { id=25706, name='Shango Robe' }, { id=28411, name='Yemaya Belt' } } },
        { name='Vir\'ava', gid=76, tier=3, hp=1300000, currency=1800, cooldown=1800, drops = { { id=21083, name='Sucellus' }, { id=27538, name='Lempo Earring' }, { id=25704, name='Abnoba Kaftan' }, { id=27320, name='Selvans Subligar' } } },
        -- Tier 3 (Ark Angels, retail 140) ------------------------------
        { name='Ark Angel EV', label='AA EV', gid=90, tier=3, hp=1600000, currency=2200, cooldown=1800, drops = { { id=20704, name='Deacon Sword' }, { id=22265, name='Elis Tome' } } },
        { name='Ark Angel GK', label='AA GK', gid=91, tier=3, hp=1600000, currency=2200, cooldown=1800, drops = { { id=21028, name='Deacon Blade' }, { id=6415, name='Seki Shuriken Pouch' } } },
        { name='Ark Angel HM', label='AA HM', gid=85, tier=3, hp=1600000, currency=2200, cooldown=1800, drops = { { id=20703, name='Deacon Saber' }, { id=26322, name='Kerygma Belt' }, { id=27744, name='Lithelimb Cap' } } },
        { name='Ark Angel MR', label='AA MR', gid=87, tier=3, hp=1600000, currency=2200, cooldown=1800, drops = { { id=20798, name='Deacon Tabar' }, { id=27617, name='Enuma Mantle' } } },
        { name='Ark Angel TT', label='AA TT', gid=86, tier=3, hp=1600000, currency=2200, cooldown=1800, drops = { { id=20894, name='Deacon Scythe' }, { id=26162, name='Rahab Ring' }, { id=28616, name='Fravashi Mantle' } } },
        -- Tier 3 (Heavenly Beasts, retail 140/150) ---------------------
        { name='Byakko-Escha', label='Byakko', gid=78, tier=3, hp=1400000, currency=2000, cooldown=1800, drops = { { id=22256, name='Jokushunoibuki' }, { id=20846, name='Jokushuono' }, { id=27318, name='Jokushu Haidate' }, { id=27525, name='Jokushu Chain' } } },
        { name='Genbu-Escha', label='Genbu', gid=79, tier=3, hp=1400000, currency=2000, cooldown=1800, delay=240, drops = { { id=22257, name='Genmeinoibuki' }, { id=27645, name='Genmei Shield' }, { id=25629, name='Genmei Kabuto' }, { id=27539, name='Genmei Earring' } } },
        { name='Seiryu-Escha', label='Seiryu', gid=80, tier=3, hp=1400000, currency=2000, cooldown=1800, delay=240, drops = { { id=22259, name='Kobonoibuki' }, { id=20699, name='Koboto' }, { id=27133, name='Kobo Kote' }, { id=26320, name='Kobo Obi' } } },
        { name='Suzaku-Escha', label='Suzaku', gid=81, tier=3, hp=1400000, currency=2000, cooldown=1800, drops = { { id=22258, name='Shukuyunoibuki' }, { id=20893, name='Shukuyu\'s Scythe' }, { id=27489, name='Shukuyu Sune-Ate' }, { id=26161, name='Shukuyu Ring' } } },
        { name='Kirin', gid=82, tier=3, hp=2400000, currency=3500, cooldown=1800, delay=240 },
        { name='Kouryu', gid=84, tier=3, hp=2000000, currency=3500, cooldown=1800, drops = { { id=27615, name='Reiki Cloak' }, { id=20842, name='Reikiono' }, { id=21152, name='Reikikon' }, { id=20690, name='Reikiko' }, { id=26321, name='Reiki Yotai' }, { id=25702, name='Reiki Osode' } } },
        -- Boss ---------------------------------------------------------
        { name='Warder of Courage', label='Courage', gid=93, tier=4, hp=4000000, currency=8000, cooldown=1800, drops = { { id=22196, name='Alber Strap' }, { id=20887, name='Dacnomania' }, { id=20932, name='Habile Mazrak' }, { id=19209, name='Molybdosis' }, { id=27545, name='Telos Earring' }, { id=25728, name='Zendik Robe' } } },
    },
    [REISEN] = {
        -- Tier 1 (retail 119) ------------------------------------
        { name='Crom Dubh', gid=45, tier=1, hp=400000, currency=600, cooldown=1800, drops = { { id=26326, name='Channeler\'s Stone' }, { id=25843, name='Merlinic Shalwar' }, { id=27138, name='Odyssean Gauntlets' } } },
        { name='Golden Kist', gid=46, tier=1, hp=400000, currency=600, cooldown=1800, drops = { { id=26240, name='Tantalic Cape' }, { id=27495, name='Valorous Greaves' } } },
        { name='Mauve-Wristed Gomberry', label='Gomberry', gid=47, tier=1, hp=400000, currency=600, cooldown=1800, drops = { { id=25644, name='Chironic Hat' }, { id=27139, name='Valorous Mitts' }, { id=26172, name='Begrudging Ring' } } },
        { name='Dazzling Dolores', label='Dolores', gid=48, tier=1, hp=400000, currency=600, cooldown=1800, drops = { { id=25643, name='Merlinic Hood' }, { id=22197, name='Niobid Strap' }, { id=27494, name='Odyssean Greaves' } } },
        { name='Taelmoth the Diremaw', label='Taelmoth', gid=49, tier=1, hp=400000, currency=600, cooldown=1800, drops = { { id=26017, name='Clotharius Torque' }, { id=27140, name='Herculean Gloves' }, { id=25841, name='Valorous Hose' } } },
        { name='Belphegor', gid=50, tier=1, hp=400000, currency=600, cooldown=1800, drops = { { id=26327, name='Asklepian Belt' }, { id=25840, name='Odyssean Cuisses' }, { id=27496, name='Herculean Boots' } } },
        { name='Kabandha', gid=51, tier=1, hp=400000, currency=600, cooldown=1800, drops = { { id=27141, name='Merlinic Dastanas' }, { id=26241, name='Scintillating Cape' } } },
        { name='Selkit', gid=52, tier=1, hp=400000, currency=600, cooldown=1800, drops = { { id=26173, name='Apate Ring' }, { id=25842, name='Herculean Trousers' }, { id=27497, name='Merlinic Crackows' } } },
        { name='Sang Buaya', gid=53, tier=1, hp=400000, currency=600, cooldown=1800, drops = { { id=27142, name='Chironic Gloves' }, { id=27546, name='Thureous Earring' }, { id=25641, name='Valorous Mask' } } },
        { name='Sabotender Royal', label='Sab. Royal', gid=54, tier=1, hp=400000, currency=600, cooldown=1800, drops = { { id=27498, name='Chironic Slippers' }, { id=26018, name='Deino Collar' }, { id=25640, name='Odyssean Helm' } } },
        { name='Zduhac', gid=55, tier=1, hp=400000, currency=600, cooldown=1800, drops = { { id=25844, name='Chironic Hose' }, { id=22270, name='Expeditious Pinion' } } },
        { name='Oryx', gid=56, tier=1, hp=400000, currency=600, cooldown=1800, drops = { { id=22198, name='Potent Grip' }, { id=25642, name='Herculean Helm' } } },
        -- Tier 2 (retail 129) ------------------------------------
        { name='Strophadia', gid=57, tier=2, hp=900000, currency=1200, cooldown=1800, drops = { { id=21854, name='Reienkyo' }, { id=20579, name='Skinflayer' }, { id=27547, name='Dignitary\'s Earring' } } },
        { name='Gajasimha', gid=58, tier=2, hp=900000, currency=1200, cooldown=1800, drops = { { id=20505, name='Condemners' }, { id=21804, name='Obschine' }, { id=26174, name='Persis Ring' }, { id=22113, name='Teller' } } },
        { name='Ironside', gid=59, tier=2, hp=900000, currency=1200, cooldown=1800, drops = { { id=20677, name='Colada' }, { id=26019, name='Homeric Gorget' }, { id=21904, name='Kanaria' } } },
        { name='Sarsaok', gid=60, tier=2, hp=900000, currency=1200, cooldown=1800, drops = { { id=22271, name='Pemphredo Tathlum' }, { id=21021, name='Umaru' }, { id=21686, name='Zulfiqar' } } },
        { name='Old Shuck', gid=61, tier=2, hp=900000, currency=1200, cooldown=1800, drops = { { id=21746, name='Digirbalag' }, { id=21072, name='Gada' }, { id=26242, name='Phalangite Mantle' } } },
        { name='Bashmu', gid=62, tier=2, hp=900000, currency=1200, cooldown=1800, drops = { { id=21754, name='Aganoshe' }, { id=22054, name='Grioavolr' }, { id=26328, name='Sarissaphoroi Belt' } } },
        -- Tier 3 (retail 135) ------------------------------------
        { name='Maju', gid=63, tier=3, hp=1400000, currency=2000, cooldown=1800, drops = { { id=26175, name='Hetairoi Ring' }, { id=25719, name='Merlinic Jubbah' }, { id=25716, name='Odyssean Chestplate' }, { id=26243, name='Perimede Cape' } } },
        { name='Yakshi', gid=64, tier=3, hp=1400000, currency=2000, cooldown=1800, drops = { { id=26020, name='Ainia Collar' }, { id=25720, name='Chironic Doublet' }, { id=22199, name='Thrace Strap' }, { id=25717, name='Valorous Mail' } } },
        { name='Neak', gid=65, tier=3, hp=1400000, currency=2000, cooldown=1800, drops = { { id=26244, name='Agema Cape' }, { id=25718, name='Herculean Vest' }, { id=26329, name='Luminary Sash' } } },
        -- Apex / HELM bosses (Aeonic-tier) -----------------------
        { name='Teles', gid=66, tier=4, hp=2800000, currency=4500, cooldown=1800, drops = { { id=27143, name='Composer\'s Mitts' }, { id=27499, name='Composer\'s Sabots' }, { id=20889, name='Misanthropy' }, { id=20592, name='Sangoma' } } },
        { name='Zerde', gid=67, tier=4, hp=2800000, currency=4500, cooldown=1800, drops = { { id=25854, name='Arjuna Breeches' }, { id=25760, name='Mrigavyadha Gloves' }, { id=20506, name='Suwaiyas' }, { id=25721, name='Vedic Coat' } } },
        { name='Vinipata', gid=71, tier=4, hp=2800000, currency=4500, cooldown=1800, drops = { { id=21022, name='Shishio' }, { id=21905, name='Taka' }, { id=21073, name='Izcalli' }, { id=25655, name='Ipoca Beret' } } },
        { name='Schah', gid=74, tier=4, hp=2800000, currency=4500, cooldown=1800, drops = { { id=21687, name='Takoba' }, { id=22055, name='Oranyan' }, { id=25730, name='Nzingha Cuirass' }, { id=25920, name='Ahosi Leggings' } } },
        { name='Albumen', gid=80, tier=4, hp=2800000, currency=4500, cooldown=1800, delay=240, drops = { { id=25921, name='Skaoi Boots' }, { id=25656, name='Ynglinga Sallet' }, { id=21747, name='Freydis' }, { id=22114, name='Steinthor' } } },
        { name='Onychophora', gid=85, tier=4, hp=2800000, currency=4500, cooldown=1800, drops = { { id=20678, name='Firangi' }, { id=22056, name='Gozuki Mezuki' }, { id=21855, name='Lembing' }, { id=25922, name='Navon Crackows' } } },
        { name='Erinys', gid=87, tier=4, hp=2800000, currency=4500, cooldown=1800, drops = { { id=21755, name='Hodadenon' }, { id=25761, name='Iktomi Dastanas' }, { id=22119, name='Wochowsen' }, { id=25731, name='Sayadio\'s Kaftan' } } },
    },
}

-- ===================================================================
-- ??? POP POINTS (stock npc_list 'qm' NPCs at retail positions)
-- zone -> ??? npcid -> { NM gids poppable at that point }.
-- Generated 2026-07-12 from stock mob_spawn_points camps (nearest ???
-- within 80y = the NM's retail camp); placeholder-cluster NMs were
-- spread across remaining ???s (1-5 NMs per point).
-- ===================================================================
local QM_POINTS = {
    [ZITAH] = {
        [17957437] = { 37, 43, 60 },  -- Wepwawet, Angrboda, Umdhlebi
        [17957438] = { 35, 44, 28 },  -- Beist, Cunnast, Keeper of Heiligtum
        [17957439] = { 27, 36, 58, 59, 63 },  -- Abyssdiver, Eschan Jewelweed, Brittlis, Kamohoalii, Urmahlullu
        [17957440] = { 38, 46, 33 },  -- Lustful Lydia, Ferrodon, Jester Malatrix
        [17957441] = { 39, 47, 61 },  -- Aglaophotis, Gulltop, Fleetstalker
        [17957442] = { 51, 48, 62 },  -- Puca, Vyala, Shockmaw
        [17957443] = { 34, 24, 52 },  -- Immanibugard, Hugemaw Harold, Alpluachra
        [17957444] = { 53, 25, 50 },  -- Pazuzu, Prickly Pitriv, Bucca
        [17957445] = { 40, 26, 49 },  -- Tangata Manu, Serpopard Ninlil, Blazewing
        [17957446] = { 45, 55, 54 },  -- Revetaur, Ionos, Wrathare
        [17957447] = { 41, 56, 32 },  -- Vidala, Sensual Sandy, Voso
        [17957448] = { 42, 57, 64 },  -- Gestalt, Nosoi, Azi Dahaka
    },
    [RUAUN] = {
        [17961682] = { 31, 86 },  -- Warder of Faith, Ark Angel TT
        [17961683] = { 34, 78 },  -- Warder of Hope, Byakko-Escha
        [17961699] = { 46, 48 },  -- Ruea, Khon
        [17961700] = { 35, 80 },  -- Warder of Prudence, Seiryu-Escha
        [17961701] = { 45, 81 },  -- Bia, Suzaku-Escha
        [17961702] = { 61, 82 },  -- Yilan, Kirin
        [17961703] = { 53, 84 },  -- Peirithoos, Kouryu
        [17961704] = { 32, 93 },  -- Warder of Justice, Warder of Courage
        [17961705] = { 47 },  -- Ma
        [17961706] = { 49 },  -- Met
        [17961707] = { 65 },  -- Naphula
        [17961708] = { 51 },  -- Wasserspeier
        [17961709] = { 52 },  -- Emputa
        [17961710] = { 50, 79 },  -- Khun, Genbu-Escha
        [17961728] = { 29 },  -- Warder of Temperance
        [17961729] = { 54 },  -- Asida
        [17961730] = { 55 },  -- Tenodera
        [17961731] = { 56 },  -- Sava Savanovic
        [17961732] = { 57 },  -- Palila
        [17961733] = { 59 },  -- Hanbi
        [17961734] = { 36 },  -- Warder of Love
        [17961735] = { 63 },  -- Amymone
        [17961736] = { 67 },  -- Kammavaca
        [17961737] = { 72 },  -- Pakecet
        [17961738] = { 74 },  -- Duke Vepar
        [17961739] = { 76 },  -- Vir'ava
        [17961740] = { 90 },  -- Ark Angel EV
        [17961741] = { 91 },  -- Ark Angel GK
        [17961742] = { 85 },  -- Ark Angel HM
        [17961777] = { 87 },  -- Ark Angel MR
    },
    [REISEN] = {
        [17969915] = { 45 },  -- Crom Dubh
        [17969919] = { 46 },  -- Golden Kist
        [17969923] = { 48 },  -- Dazzling Dolores
        [17969924] = { 49 },  -- Taelmoth the Diremaw
        [17969926] = { 50 },  -- Belphegor
        [17969965] = { 47, 54 },  -- Mauve-Wristed Gomberry, Sabotender Royal
        [17969966] = { 67, 74, 80 },  -- Zerde, Schah, Albumen
        [17969967] = { 51 },  -- Kabandha
        [17969968] = { 52 },  -- Selkit
        [17969969] = { 53 },  -- Sang Buaya
        [17969970] = { 55 },  -- Zduhac
        [17969971] = { 57 },  -- Strophadia
        [17969972] = { 58 },  -- Gajasimha
        [17969973] = { 59 },  -- Ironside
        [17969974] = { 60 },  -- Sarsaok
        [17969975] = { 62 },  -- Bashmu
        [17969976] = { 66, 71 },  -- Teles, Vinipata
        [17969989] = { 63 },  -- Maju
        [17969990] = { 64 },  -- Yakshi
        [17969991] = { 65 },  -- Neak
        [17969992] = { 56, 61 },  -- Oryx, Old Shuck
        [17969993] = { 85 },  -- Onychophora
        [17969994] = { 87 },  -- Erinys
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
    -- every listed item rolled independently. Bosses are more generous. If
    -- FETE_DROP_GUARANTEE and nothing dropped, one random item is forced so
    -- every kill yields at least one signature piece.
    if def.drops and #def.drops > 0 then
        local rate = (t == 4) and FETE_BOSS_DROP_RATE or FETE_DROP_RATE
        local got = 0
        for _, dr in ipairs(def.drops) do
            if math.random() < rate then
                if player:addItem({ id = dr.id, quantity = 1 }) then
                    got = got + 1
                    player:printToPlayer(string.format('[Geas Fete] %s drops: %s!',
                        def.name, dr.name), S)
                end
            end
        end
        if got == 0 and FETE_DROP_GUARANTEE then
            local dr = def.drops[math.random(#def.drops)]
            if player:addItem({ id = dr.id, quantity = 1 }) then
                player:printToPlayer(string.format('[Geas Fete] %s drops: %s!',
                    def.name, dr.name), S)
            else
                player:printToPlayer('[Geas Fete] A drop was lost -- make bag room, kupo!', S)
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

    -- Reisenjima abjurations (owner call 2026-07-13): T3 rolls a single
    -- random abjuration; bosses roll one guaranteed + a chance at a second.
    -- Trade at the AbjurationForge NPC in Purgonorgo Isle (!hub) for the
    -- matching augmented armor piece (Odyssean/Valorous/Chironic/etc.).
    local abjRolls = (t == 4) and 1 or 0
    if t == 3 and math.random() < 0.15 then abjRolls = 1 end
    if t == 4 and math.random() < 0.30 then abjRolls = 2 end
    for _ = 1, abjRolls do
        local id = ABJURATIONS[math.random(#ABJURATIONS)]
        if player:addItem({ id = id, quantity = 1 }) then
            player:printToPlayer('[Geas Fete] A Reisenjima abjuration falls -- trade it at the forge in !hub!', S)
        end
    end
end

-- ===================================================================
-- DIFFICULTY LAYER (owner request 2026-07-12: 'all these geas fetes need
-- to be significantly harder'). Stock pools at level 149 were sponges --
-- formula stats, slow swings, little TP pressure -- so every spawned NM
-- now gets a tier-scaled OFFENSE profile on top of its pool. Defense is
-- deliberately untouched (harder should mean 'kills you', not 'unhittable').
-- Retune here, not in the catalog. Reference points: Absolute Virtue runs
-- REGAIN 200, Nepionic Soulflayer 50.
--   attP     : +% physical attack        acc/macc : flat accuracy boosts
--   matt     : flat magic attack bonus   regain   : passive TP/tick (more TP moves)
--   da / ta  : double / triple attack %
-- Per-NM catalog overrides (all optional):
--   delay=N     : auto-attack delay (240-scale; for slow stock pools)
--   spellList=N : grant/replace the mob's spell list (pair with mp=)
--   mp=N        : max MP (casters need a pool; stock WAR/WAR mobs have 0)
--   mods={ [xi.mod.X]=v, ... } : any extra modifier
-- ===================================================================
local TIER_TUNING = {
    [1] = { attP =  75, acc = 225, macc = 225, matt =  60, regain =  90, da =  45, ta = 0  },
    [2] = { attP = 120, acc = 300, macc = 300, matt = 105, regain = 150, da =  75, ta = 15 },
    [3] = { attP = 165, acc = 375, macc = 375, matt = 150, regain = 240, da =  90, ta = 30 },
    [4] = { attP = 210, acc = 450, macc = 450, matt = 210, regain = 360, da = 105, ta = 45 },
}

local function applyDifficulty(mob, def)
    local t = TIER_TUNING[def.tier] or TIER_TUNING[1]
    mob:addMod(xi.mod.ATTP,          t.attP)
    mob:addMod(xi.mod.ACC,           t.acc)
    mob:addMod(xi.mod.MACC,          t.macc)
    mob:addMod(xi.mod.MATT,          t.matt)
    mob:addMod(xi.mod.REGAIN,        t.regain)
    mob:addMod(xi.mod.DOUBLE_ATTACK, t.da)
    if t.ta > 0 then
        mob:addMod(xi.mod.TRIPLE_ATTACK, t.ta)
    end

    if def.delay then
        mob:setDelay(def.delay)
    end
    if def.spellList then
        mob:setSpellList(def.spellList)
    end
    if def.mp then
        mob:setMaxMP(def.mp)
        mob:setMP(def.mp)
    end
    if def.mods then
        for modId, v in pairs(def.mods) do
            mob:addMod(modId, v)
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

        -- LSB new signature: onMobDeath(mob, player, optParams). The 3rd arg is
        -- a table (optParams), NOT a bool -- the old `if not isKiller` guard was
        -- dead code. Reward every credited alliance member (this fires once per
        -- member); guard only against a nil player.
        onMobDeath = function(mob, killer, optParams)
            if killer == nil then return end
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
        applyDifficulty(mob, def)
        mob:updateClaim(player)
    end
    return mob
end

-- ===================================================================
-- MENU SYSTEM
-- ===================================================================
-- Fast def lookup for the ??? pop points: zone -> gid -> catalog def.
local DEF_BY_GID = {}
for zoneId, defs in pairs(NM_CATALOG) do
    DEF_BY_GID[zoneId] = {}
    for _, def in ipairs(defs) do
        DEF_BY_GID[zoneId][def.gid] = def
    end
end

-- ??? pop menu: lists ONLY the NMs camped at this point (retail-style),
-- with cooldown status. Busy points paginate past NM_PER_PAGE.
local NM_PER_PAGE = 6

local function qmPopMenu(player, npc, zoneId, gids, page)
    page = page or 0
    local zone = npc:getZone()
    local defs = {}
    for _, gid in ipairs(gids) do
        local d = DEF_BY_GID[zoneId] and DEF_BY_GID[zoneId][gid]
        if d then
            defs[#defs + 1] = d
        end
    end
    if #defs == 0 then
        player:printToPlayer('You sense nothing out of the ordinary.', S)
        return
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
            function(p) qmPopMenu(p, npc, zoneId, gids, page + 1) end }
    end
    opts[#opts + 1] = { 'Leave', function(p) end }

    local menu = { title = 'Planar Rift', options = opts }
    player:timer(30, function(p) p:customMenu(menu) end)
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

-- Main Warding Circle menu for one zone. EXCHANGE ONLY since the retail-???
-- rework (2026-07-12): NMs pop at the ??? points, not here.
local function wardingCircleMenu(player, zone, zoneId)
    local clbl  = CURRENCY_LABEL[zoneId] or 'pts'
    local menu  = { title = '', options = {} }
    local mainFn, shopFn

    local function show(p)
        p:timer(30, function(p2) p2:customMenu(menu) end)
    end

    shopFn = buildShop(player, zone, zoneId, function(p) mainFn(p) end, menu)

    mainFn = function(p)
        local cur = getCurrency(p, zoneId)
        menu.title   = string.format('Warding Circle [%s: %d]', clbl, cur)
        menu.options = {
            { string.format('Exchange %s', clbl), function(pp) shopFn(pp) end },
            { 'Where are the NMs?', function(pp)
                pp:printToPlayer('[Geas Fete] The NMs answer at the ??? points scattered across Escha - Zi\'Tah, Escha - Ru\'Aun, and Reisenjima -- inspect one to pop the NMs camped there. Check the website\'s Geas Fete page for every camp.', S)
            end },
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

-- Attach the pop menu to every stock ??? point this zone owns (QM_POINTS).
-- The qm NPCs are plain npc_list rows with no script of their own -- verified
-- unreferenced by any quest/mission -- so an ON_TRIGGER listener is the whole
-- wiring (same pattern as battlefield armoury crates).
local function bindQmPoints(zoneId)
    local bound = 0
    for npcId, gids in pairs(QM_POINTS[zoneId] or {}) do
        local npc = GetNPCByID(npcId)
        if npc then
            local g = gids
            npc:addListener('ON_TRIGGER', 'GEAS_FETE_QM', function(player, trigNpc)
                qmPopMenu(player, trigNpc, zoneId, g)
            end)
            bound = bound + 1
        else
            printf('[geas_fete] ??? npc %i missing in zone %i', npcId, zoneId)
        end
    end
    printf('[geas_fete] zone %i: %i ??? pop points bound', zoneId, bound)
end

-- Escha - Zi'Tah (288)
-- Circle near the HL zone guide (x≈3, z≈-30); NMs pop at the 12 ??? points.
m:addOverride('xi.zones.Escha_ZiTah.Zone.onInitialize', function(zone)
    super(zone)
    spawnWardingCircle(zone, ZITAH, 3.0, -0.5, -20.0, 128)
    bindQmPoints(ZITAH)
end)

-- Escha - Ru'Aun (289)
-- Circle near the zone entry point; NMs pop at the 30 ??? points.
m:addOverride('xi.zones.Escha_RuAun.Zone.onInitialize', function(zone)
    super(zone)
    spawnWardingCircle(zone, RUAUN, 5.0, -34.277, -455.0, 64)
    bindQmPoints(RUAUN)
end)

-- Reisenjima (291)
-- The old redirect signpost at the zone-in point is now a full Warding Circle
-- (exchange) -- Reisenjima hosts its own retail Geas Fete roster at 23 ???
-- points since the 2026-07-12 rework. Temprix (Aeonic vendor) is unchanged.
m:addOverride('xi.zones.Reisenjima.Zone.onInitialize', function(zone)
    super(zone)
    spawnWardingCircle(zone, REISEN, -497.0, -19.07, -484.0, 190)
    bindQmPoints(REISEN)
end)

return m
