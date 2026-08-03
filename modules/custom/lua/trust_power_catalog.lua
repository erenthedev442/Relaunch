-----------------------------------
-- trust_power_catalog.lua
-- Role / tier / style / kit injection for every companion trust spell ID.
--
-- Power tiers track content difficulty (cipher drop bands).
-- Master-99 soft bands + hard caps (softclamp compresses overshoots):
--   C = starters / D1 entry            → soft 8–10k,  hard 10k
--   B = D2 mid content                 → soft 22–28k, hard 28k
--   A = D3 hard content                → soft 30–36k, hard 36k
--   S = D4/D5 / CORE / Void Keeper     → soft 36–40k, hard 40k
--
-- style: combat personality within a role (especially nukers) so same-tier
-- BLMs do not feel identical.
-----------------------------------
local C = {}

C.DEFAULT_CAP         = 40000
C.MATSUI_CAP          = 99999
C.SHANTOTTO_II_MB_CAP = 79999

-- Per-tier hard caps (override DEFAULT_CAP unless entry.cap is set).
C.TIER_HARD_CAP =
{
    C = 10000,
    B = 28000,
    A = 36000,
    S = 40000,
}

-- Wide spread so players feel the upgrade path from entry → endgame trusts.
-- C sits high enough that WS/nukes reach the 8–10k soft band once AI works;
-- the 10k hard cap stops Ajido-style MB spikes.
C.TIER_MULT =
{
    C = 0.70,
    B = 0.82, -- clear step above C (was 0.72 ≈ C)
    A = 0.94,
    S = 1.18,
}

-- Nuker / mage personality (multiplies mage package axes).
C.STYLE =
{
    -- Entry BLMs: slow, modest, mostly free nukes.
    apprentice = { matt = 0.88, mdmg = 0.82, mbb = 0.65, fc = 0.80, macc = 0.90 },
    -- Mid BLMs: solid pressure casters.
    pressure   = { matt = 1.00, mdmg = 1.00, mbb = 0.90, fc = 0.95, macc = 1.00 },
    -- SCH / hybrid nukers: slightly less raw, good consistency.
    scholar    = { matt = 0.95, mdmg = 0.92, mbb = 1.05, fc = 1.05, macc = 1.05 },
    -- MB specialists: live for skillchain windows.
    burst      = { matt = 0.96, mdmg = 1.05, mbb = 1.30, fc = 1.18, macc = 1.02 },
    -- Capstone nukers.
    apex       = { matt = 1.12, mdmg = 1.18, mbb = 1.40, fc = 1.22, macc = 1.10 },
    -- Default / non-nuker styles (melee personalities).
    standard   = { att = 1.00, wsd = 1.00, haste = 1.00, da = 1.00 },
    bruiser    = { att = 1.08, wsd = 0.92, haste = 1.05, da = 1.15 },
    weaponskill= { att = 0.95, wsd = 1.18, haste = 0.95, da = 0.90 },
    skirmisher = { att = 1.00, wsd = 1.05, haste = 1.12, da = 1.05 },
    support    = { matt = 0.70, mdmg = 0.55, mbb = 0.40, fc = 0.85, macc = 0.85 },
}

-- spellId -> { role, tier, style?, cap?, mbCap?, injectKit? }
local function e(role, tier, opts)
    opts = opts or {}
    return {
        role      = role,
        tier      = tier,
        style     = opts.style or 'standard',
        cap       = opts.cap,
        mbCap     = opts.mbCap,
        injectKit = opts.injectKit,
    }
end

C.trusts =
{
    ------------------------------------------------------------------
    -- Starters (deliberately modest — first party, not endgame DPS)
    ------------------------------------------------------------------
    [896] = e('nuker',     'C', { style = 'apprentice', injectKit = false }), -- Shantotto
    [898] = e('healer',    'C', { style = 'support',    injectKit = false }), -- Kupipi
    [905] = e('tank',      'C', { style = 'bruiser',    injectKit = false }), -- Trion
    [908] = e('melee_dd',  'C', { style = 'weaponskill',injectKit = false }), -- Tenzen (starter = C)

    ------------------------------------------------------------------
    -- D1 entry farms
    ------------------------------------------------------------------
    [897] = e('melee_dd',  'C', { style = 'bruiser',     injectKit = 'melee_dd' }), -- Naji
    [900] = e('melee_dd',  'C', { style = 'weaponskill', injectKit = false }), -- Ayame
    [904] = e('nuker',     'C', { style = 'apprentice',  injectKit = false, mbCap = 10000 }), -- Ajido
    [909] = e('healer',    'C', { style = 'support',     injectKit = false }), -- Mihli
    [912] = e('melee_dd',  'C', { style = 'skirmisher',  injectKit = false }), -- Naja
    [918] = e('tank',      'C', { style = 'skirmisher',  injectKit = false }), -- Gessho (off-tank)
    [916] = e('healer',    'C', { style = 'support',     injectKit = false }), -- Cherukiki
    [922] = e('ranged_dd', 'C', { style = 'skirmisher',  injectKit = false }), -- Lehko
    [924] = e('melee_dd',  'C', { style = 'bruiser',     injectKit = false }), -- Zazarg (Focus script)
    [925] = e('nuker',     'C', { style = 'apprentice',  injectKit = false, mbCap = 10000 }), -- Ovjang (custom RDM kit)
    [926] = e('tank',      'C', { style = 'bruiser',     injectKit = false }), -- Mnejing
    [927] = e('aura',      'C', { style = 'support',     injectKit = false }), -- Sakura
    [931] = e('aura',      'C', { style = 'support',     injectKit = false }), -- Moogle
    [936] = e('healer',    'C', { style = 'support',     injectKit = false }), -- Karaha
    [939] = e('melee_dd',  'C', { style = 'bruiser',     injectKit = false }), -- Areuhat
    [940] = e('ranged_dd', 'C', { style = 'skirmisher',  injectKit = false }), -- Semih
    [941] = e('ranged_dd', 'C', { style = 'skirmisher',  injectKit = false }), -- Elivira (custom RA kit)
    [943] = e('melee_dd',  'C', { style = 'bruiser',     injectKit = false }), -- Lhu (BST script)
    [944] = e('healer',    'C', { style = 'support',     injectKit = false }), -- Ferreous
    [949] = e('melee_dd',  'C', { style = 'skirmisher',  injectKit = false }), -- Romaa (THF script)
    [958] = e('melee_dd',  'C', { style = 'bruiser',     injectKit = false }), -- Babban
    [959] = e('melee_dd',  'C', { style = 'bruiser',     injectKit = false }), -- Abenzio
    [961] = e('nuker',     'C', { style = 'apprentice',  injectKit = 'nuker', mbCap = 10000 }), -- Kukki
    [962] = e('ranged_dd', 'C', { style = 'skirmisher',  injectKit = false }), -- Margret (custom RA kit)
    [966] = e('melee_dd',  'C', { style = 'skirmisher',  injectKit = false }), -- Mayakov (DNC, not BRD buffer)
    [968] = e('nuker',     'C', { style = 'scholar',     injectKit = false, mbCap = 10000 }), -- Adelheid
    [972] = e('melee_dd',  'C', { style = 'bruiser',     injectKit = false }), -- Halver (PLD script, not WAR kit)

    ------------------------------------------------------------------
    -- D2 mid content
    ------------------------------------------------------------------
    [903] = e('melee_dd',  'B', { style = 'bruiser',     injectKit = false }), -- Volker
    [911] = e('buffer',    'B', { style = 'support',     injectKit = false }), -- Joachim
    [913] = e('melee_dd',  'B', { style = 'bruiser',     injectKit = false }), -- Prishe
    [915] = e('ranged_dd', 'B', { style = 'skirmisher',  injectKit = false }), -- Shikaree Z
    [917] = e('melee_dd',  'B', { style = 'bruiser',     injectKit = false }), -- Iron Eater
    [919] = e('nuker',     'B', { style = 'pressure',    injectKit = 'nuker' }), -- Gadalar
    [921] = e('healer',    'B', { style = 'support',     injectKit = false }), -- Ingrid (custom WHM/banish)
    [923] = e('healer',    'B', { style = 'support',     injectKit = false }), -- Nashmeira (custom DNC/WHM)
    [929] = e('melee_dd',  'B', { style = 'weaponskill', injectKit = 'melee_dd' }), -- Najelith
    [932] = e('hybrid',    'B', { style = 'pressure',    injectKit = false }), -- Fablinix
    [933] = e('melee_dd',  'B', { style = 'bruiser',     injectKit = false }), -- Maat
    [934] = e('nuker',     'B', { style = 'burst',       injectKit = 'nuker' }), -- D.Shantotto
    [935] = e('utility',   'B', { style = 'support',     injectKit = 'utility' }), -- Star Sibyl
    [942] = e('melee_dd',  'B', { style = 'weaponskill', injectKit = 'melee_dd' }), -- Noillurie
    [946] = e('buffer',    'B', { style = 'support',     injectKit = false }), -- Mumor
    [948] = e('melee_dd',  'B', { style = 'bruiser',     injectKit = 'melee_dd' }), -- Klara
    [951] = e('tank',      'B', { style = 'bruiser',     injectKit = false }), -- Rahal
    [952] = e('nuker',     'B', { style = 'scholar',     injectKit = false }), -- Koru-Moru
    [960] = e('tank',      'B', { style = 'bruiser',     injectKit = false }), -- Rughadjeen
    [965] = e('hybrid',    'B', { style = 'pressure',    injectKit = false }), -- Arciela (RDM: buffs + melee WS)
    [969] = e('tank',      'B', { style = 'bruiser',     injectKit = false }), -- Amchuchu
    [970] = e('utility',   'B', { style = 'support',     injectKit = 'utility' }), -- Brygid
    [974] = e('nuker',     'B', { style = 'pressure',    injectKit = 'nuker' }), -- Leonoyne
    [977] = e('nuker',     'B', { style = 'burst',       injectKit = 'nuker' }), -- Robel-Akbel
    [997] = e('melee_dd',  'B', { style = 'weaponskill', injectKit = 'melee_dd' }), -- Iroha
    [1004]= e('melee_dd',  'B', { style = 'bruiser',     injectKit = 'melee_dd' }), -- Excenmille S
    [1006]= e('melee_dd',  'B', { style = 'bruiser',     injectKit = false }), -- Maat UC
    [1014]= e('melee_dd',  'B', { style = 'weaponskill', injectKit = false }), -- Tenzen II (Unity T2)
    [1016]= e('healer',    'B', { style = 'support',     injectKit = false }), -- Ingrid II (custom Holy/banish)

    ------------------------------------------------------------------
    -- D3 hard content
    ------------------------------------------------------------------
    [906] = e('melee_dd',  'A', { style = 'weaponskill', injectKit = false }), -- Zeid
    [907] = e('melee_dd',  'A', { style = 'skirmisher',  injectKit = false }), -- Lion
    [910] = e('tank',      'A', { style = 'bruiser',     injectKit = false }), -- Valaineral
    [920] = e('nuker',     'A', { style = 'burst',       injectKit = false }), -- Rainemard
    [928] = e('ranged_dd', 'A', { style = 'weaponskill', injectKit = 'ranged_dd' }), -- Luzaf
    [937] = e('melee_dd',  'A', { style = 'bruiser',     injectKit = 'melee_dd' }), -- Cid
    [938] = e('melee_dd',  'A', { style = 'weaponskill', injectKit = 'melee_dd' }), -- Gilgamesh
    [945] = e('melee_dd',  'A', { style = 'skirmisher',  injectKit = 'melee_dd' }), -- Lilisette
    [950] = e('utility',   'A', { style = 'support',     injectKit = 'utility' }), -- Kuyin
    [953] = e('healer',    'A', { style = 'support',     injectKit = 'healer' }), -- Pieuje UC
    [954] = e('tank',      'A', { style = 'bruiser',     injectKit = false }), -- I.Shield UC (WAR provoke tank)
    [956] = e('melee_dd',  'A', { style = 'skirmisher',  injectKit = 'melee_dd' }), -- Jakoh UC
    [957] = e('ranged_dd', 'A', { style = 'weaponskill', injectKit = 'ranged_dd' }), -- Flaviria UC
    [967] = e('hybrid',    'A', { style = 'skirmisher',  injectKit = false }), -- Qultada CORE
    [971] = e('melee_dd',  'A', { style = 'weaponskill', injectKit = 'melee_dd' }), -- Mildaurion
    [973] = e('melee_dd',  'A', { style = 'bruiser',     injectKit = 'melee_dd' }), -- Rongelouts
    [975] = e('melee_dd',  'A', { style = 'skirmisher',  injectKit = 'melee_dd' }), -- Maximilian
    [976] = e('nuker',     'A', { style = 'burst',       injectKit = 'nuker' }), -- Kayeel-Payeel
    [980] = e('healer',    'A', { style = 'support',     injectKit = false }), -- Yoran-Oran UC
    [983] = e('hybrid',    'A', { style = 'pressure',    injectKit = false }), -- Balamor (DRK absorbs + melee)
    [985] = e('nuker',     'A', { style = 'scholar',     injectKit = 'nuker' }), -- Rosulatia
    [987] = e('nuker',     'A', { style = 'pressure',    injectKit = 'nuker' }), -- Ullegore
    [992] = e('melee_dd',  'A', { style = 'bruiser',     injectKit = false }), -- Ark HM
    [993] = e('tank',      'A', { style = 'bruiser',     injectKit = false }), -- Ark EV
    [994] = e('melee_dd',  'A', { style = 'bruiser',     injectKit = false }), -- Ark MR (axe melee; RA optional in script)
    [995] = e('nuker',     'A', { style = 'burst',       injectKit = 'nuker' }), -- Ark TT
    [996] = e('melee_dd',  'A', { style = 'weaponskill', injectKit = false }), -- Ark GK
    [999] = e('healer',    'A', { style = 'support',     injectKit = false }), -- Monberaux CORE heal
    [1005]= e('melee_dd',  'A', { style = 'weaponskill', injectKit = 'melee_dd' }), -- Ayame UC
    [1008]= e('melee_dd',  'A', { style = 'skirmisher',  injectKit = 'melee_dd' }), -- Naja UC
    [1012]= e('healer',    'A', { style = 'support',     injectKit = false }), -- Nashmeira II
    [1013]= e('melee_dd',  'A', { style = 'skirmisher',  injectKit = 'melee_dd' }), -- Lilisette II
    [1015]= e('buffer',    'A', { style = 'support',     injectKit = false }), -- Mumor II
    [1017]= e('nuker',     'A', { style = 'burst',       injectKit = 'nuker' }), -- Arciela II
    [1018]= e('melee_dd',  'A', { style = 'weaponskill', injectKit = false }), -- Iroha II

    ------------------------------------------------------------------
    -- D4 / D5 / CORE endgame
    ------------------------------------------------------------------
    [914] = e('buffer',    'S', { style = 'support',     injectKit = false }), -- Ulmia CORE
    [947] = e('melee_dd',  'S', { style = 'skirmisher',  injectKit = false }), -- Uka DNC (melee, not buffer)
    [955] = e('healer',    'S', { style = 'support',     injectKit = false }), -- Apururu UC CORE
    [963] = e('utility',   'B', { style = 'support',     injectKit = 'utility' }), -- Chacharoon (utility, not DPS)
    [964] = e('melee_dd',  'S', { style = 'bruiser',     injectKit = 'melee_dd' }), -- Lhe (Prestige move)
    [978] = e('utility',   'S', { style = 'support',     injectKit = 'utility' }), -- Kupofried CORE chase
    [979] = e('hybrid',    'A', { style = 'pressure',    injectKit = false }), -- Selh'teus (Lunar Bay MS)
    [981] = e('buffer',    'S', { style = 'support',     injectKit = false }), -- Sylvie UC CORE
    [982] = e('melee_dd',  'A', { style = 'bruiser',     injectKit = 'melee_dd' }), -- Abquhbah D4
    [984] = e('tank',      'S', { style = 'bruiser',     injectKit = false }), -- August CORE
    [986] = e('nuker',     'S', { style = 'apex',        injectKit = 'nuker' }), -- Teodor
    [988] = e('ranged_dd', 'S', { style = 'weaponskill', injectKit = 'ranged_dd' }), -- Makki
    [989] = e('buffer',    'A', { style = 'support',     injectKit = false }), -- King of Hearts (RDM, not BRD)
    [990] = e('melee_dd',  'S', { style = 'bruiser',     injectKit = 'melee_dd' }), -- Morimar
    [991] = e('melee_dd',  'S', { style = 'skirmisher',  injectKit = 'melee_dd' }), -- Darrcuiln
    [998] = e('healer',    'S', { style = 'support',     injectKit = false }), -- Ygnas CORE
    [1009]= e('melee_dd',  'S', { style = 'skirmisher',  injectKit = false }), -- Lion II
    [1010]= e('melee_dd',  'S', { style = 'weaponskill', injectKit = false }), -- Zeid II CORE
    [1011]= e('melee_dd',  'S', { style = 'bruiser',     injectKit = false }), -- Prishe II
    [1019]= e('nuker',     'S', {
        style     = 'apex',
        injectKit = false,
        mbCap     = C.SHANTOTTO_II_MB_CAP,
    }), -- Shantotto II CORE

    ------------------------------------------------------------------
    -- Void Keeper customs (chase rewards — top band)
    ------------------------------------------------------------------
    [899] = e('tank',      'S', { style = 'bruiser',     injectKit = false }), -- Meat
    [901] = e('buffer',    'S', { style = 'support',     injectKit = false }), -- Gemma
    [902] = e('ranged_dd', 'A', { style = 'weaponskill', injectKit = false }), -- Corvus
    [1002]= e('aura',      'S', { style = 'support',     injectKit = false }), -- Cornelia
    [1003]= e('hybrid',    'S', {
        style     = 'apex',
        cap       = C.MATSUI_CAP,
        injectKit = false,
    }), -- Matsui-P

    ------------------------------------------------------------------
    -- Retired (kept for lookup; stripped by grant gate)
    ------------------------------------------------------------------
    [930] = e('melee_dd',  'A', { style = 'skirmisher', injectKit = false }), -- Locke / Aldo disabled
    [1007]= e('melee_dd',  'A', { style = 'skirmisher', injectKit = 'melee_dd' }), -- Aldo UC disabled
}

function C.get(spellId)
    return C.trusts[spellId]
end

function C.styleWeights(styleName)
    return C.STYLE[styleName] or C.STYLE.standard
end

return C
