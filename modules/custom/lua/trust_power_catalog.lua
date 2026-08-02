-----------------------------------
-- trust_power_catalog.lua
-- Role / tier / cap / kit injection for every companion trust spell ID.
--
-- tier: C≈20-25k | B≈25-32k | A≈32-38k | S≈36-40k typical hits at master 99
-- injectKit: role template applied after spawn for shell scripts
--            (false = script already owns its gambits)
-----------------------------------
local C = {}

C.DEFAULT_CAP         = 40000
C.MATSUI_CAP          = 99999
C.SHANTOTTO_II_MB_CAP = 79999

-- Tier multipliers on the shared power package (1.0 = mid A-ish).
C.TIER_MULT =
{
    C = 0.72,
    B = 0.88,
    A = 1.00,
    S = 1.12,
}

-- spellId -> { role, tier, cap?, mbCap?, injectKit? }
-- Roles: melee_dd, ranged_dd, tank, healer, buffer, nuker, hybrid, utility, aura
local function e(role, tier, opts)
    opts = opts or {}
    return {
        role      = role,
        tier      = tier,
        cap       = opts.cap,
        mbCap     = opts.mbCap,
        injectKit = opts.injectKit, -- nil/false = no injection
    }
end

C.trusts =
{
    -- Starters / early
    [896] = e('nuker',     'A', { injectKit = false }), -- Shantotto
    [897] = e('melee_dd',  'C', { injectKit = false }), -- Naji
    [898] = e('healer',    'B', { injectKit = false }), -- Kupipi
    [899] = e('tank',      'S', { injectKit = false }), -- Meat
    [900] = e('melee_dd',  'B', { injectKit = false }), -- Ayame
    [901] = e('buffer',    'S', { injectKit = false }), -- Gemma (skoll.lua)
    [902] = e('ranged_dd', 'A', { injectKit = false }), -- Corvus
    [903] = e('melee_dd',  'B', { injectKit = false }), -- Volker
    [904] = e('nuker',     'A', { injectKit = false }), -- Ajido-Marujido
    [905] = e('tank',      'B', { injectKit = false }), -- Trion
    [906] = e('melee_dd',  'B', { injectKit = false }), -- Zeid
    [907] = e('melee_dd',  'B', { injectKit = false }), -- Lion
    [908] = e('melee_dd',  'A', { injectKit = false }), -- Tenzen
    [909] = e('healer',    'B', { injectKit = false }), -- Mihli
    [910] = e('tank',      'A', { injectKit = false }), -- Valaineral
    [911] = e('buffer',    'A', { injectKit = false }), -- Joachim
    [912] = e('melee_dd',  'B', { injectKit = false }), -- Naja
    [913] = e('melee_dd',  'A', { injectKit = false }), -- Prishe
    [914] = e('buffer',    'B', { injectKit = false }), -- Ulmia
    [915] = e('ranged_dd', 'B', { injectKit = false }), -- Shikaree Z
    [916] = e('healer',    'B', { injectKit = false }), -- Cherukiki
    [917] = e('melee_dd',  'B', { injectKit = false }), -- Iron Eater
    [918] = e('melee_dd',  'A', { injectKit = false }), -- Gessho
    [919] = e('nuker',     'B', { injectKit = 'nuker' }), -- Gadalar (shell)
    [920] = e('nuker',     'B', { injectKit = false }), -- Rainemard
    [921] = e('healer',    'B', { injectKit = 'healer' }), -- Ingrid (shell)
    [922] = e('ranged_dd', 'A', { injectKit = false }), -- Lehko
    [923] = e('healer',    'B', { injectKit = 'healer' }), -- Nashmeira (shell)
    [924] = e('melee_dd',  'B', { injectKit = 'melee_dd' }), -- Zazarg (shell)
    [925] = e('nuker',     'B', { injectKit = 'nuker' }), -- Ovjang (shell)
    [926] = e('tank',      'B', { injectKit = false }), -- Mnejing
    [927] = e('aura',      'B', { injectKit = false }), -- Sakura
    [928] = e('ranged_dd', 'A', { injectKit = 'ranged_dd' }), -- Luzaf (shell)
    [929] = e('melee_dd',  'B', { injectKit = 'melee_dd' }), -- Najelith (shell)
    [930] = e('melee_dd',  'A', { injectKit = false }), -- Locke
    [931] = e('aura',      'B', { injectKit = false }), -- Moogle
    [932] = e('hybrid',    'B', { injectKit = false }), -- Fablinix
    [933] = e('melee_dd',  'A', { injectKit = false }), -- Maat
    [934] = e('nuker',     'A', { injectKit = 'nuker' }), -- D.Shantotto (shell)
    [935] = e('utility',   'B', { injectKit = 'utility' }), -- Star Sibyl (shell)
    [936] = e('healer',    'A', { injectKit = false }), -- Karaha-Baruha
    [937] = e('melee_dd',  'B', { injectKit = 'melee_dd' }), -- Cid (shell)
    [938] = e('melee_dd',  'A', { injectKit = 'melee_dd' }), -- Gilgamesh (shell)
    [939] = e('melee_dd',  'B', { injectKit = false }), -- Areuhat
    [940] = e('ranged_dd', 'A', { injectKit = false }), -- Semih
    [941] = e('ranged_dd', 'B', { injectKit = 'ranged_dd' }), -- Elivira (shell)
    [942] = e('melee_dd',  'B', { injectKit = 'melee_dd' }), -- Noillurie (shell)
    [943] = e('hybrid',    'B', { injectKit = 'hybrid' }), -- Lhu (shell)
    [944] = e('healer',    'B', { injectKit = false }), -- Ferreous Coffin
    [945] = e('melee_dd',  'B', { injectKit = 'melee_dd' }), -- Lilisette (shell)
    [946] = e('buffer',    'B', { injectKit = false }), -- Mumor
    [947] = e('buffer',    'B', { injectKit = false }), -- Uka
    [948] = e('melee_dd',  'B', { injectKit = 'melee_dd' }), -- Klara (shell)
    [949] = e('melee_dd',  'B', { injectKit = 'melee_dd' }), -- Romaa (shell)
    [950] = e('utility',   'C', { injectKit = 'utility' }), -- Kuyin (shell)
    [951] = e('tank',      'B', { injectKit = false }), -- Rahal
    [952] = e('nuker',     'A', { injectKit = false }), -- Koru-Moru
    [953] = e('healer',    'A', { injectKit = 'healer' }), -- Pieuje UC (shell)
    [954] = e('tank',      'A', { injectKit = 'tank' }), -- I.Shield UC (shell)
    [955] = e('healer',    'S', { injectKit = false }), -- Apururu UC
    [956] = e('melee_dd',  'B', { injectKit = 'melee_dd' }), -- Jakoh UC (shell)
    [957] = e('ranged_dd', 'A', { injectKit = 'ranged_dd' }), -- Flaviria UC (shell)
    [958] = e('melee_dd',  'B', { injectKit = 'melee_dd' }), -- Babban (shell)
    [959] = e('melee_dd',  'B', { injectKit = 'melee_dd' }), -- Abenzio (shell)
    [960] = e('tank',      'B', { injectKit = false }), -- Rughadjeen
    [961] = e('nuker',     'B', { injectKit = 'nuker' }), -- Kukki (shell)
    [962] = e('ranged_dd', 'B', { injectKit = 'ranged_dd' }), -- Margret (shell)
    [963] = e('utility',   'C', { injectKit = 'utility' }), -- Chacharoon (shell)
    [964] = e('melee_dd',  'B', { injectKit = 'melee_dd' }), -- Lhe (shell)
    [965] = e('nuker',     'A', { injectKit = 'nuker' }), -- Arciela (shell)
    [966] = e('buffer',    'B', { injectKit = 'buffer' }), -- Mayakov (shell)
    [967] = e('hybrid',    'A', { injectKit = false }), -- Qultada
    [968] = e('nuker',     'A', { injectKit = false }), -- Adelheid
    [969] = e('tank',      'A', { injectKit = false }), -- Amchuchu
    [970] = e('utility',   'B', { injectKit = 'utility' }), -- Brygid (shell)
    [971] = e('melee_dd',  'A', { injectKit = 'melee_dd' }), -- Mildaurion (shell)
    [972] = e('melee_dd',  'B', { injectKit = 'melee_dd' }), -- Halver (shell)
    [973] = e('melee_dd',  'B', { injectKit = 'melee_dd' }), -- Rongelouts (shell)
    [974] = e('nuker',     'B', { injectKit = 'nuker' }), -- Leonoyne (shell)
    [975] = e('melee_dd',  'B', { injectKit = 'melee_dd' }), -- Maximilian (shell)
    [976] = e('nuker',     'A', { injectKit = 'nuker' }), -- Kayeel-Payeel (shell)
    [977] = e('nuker',     'A', { injectKit = 'nuker' }), -- Robel-Akbel (shell)
    [978] = e('utility',   'A', { injectKit = 'utility' }), -- Kupofried (shell)
    [979] = e('utility',   'B', { injectKit = 'utility' }), -- Selh'teus (shell)
    [980] = e('healer',    'A', { injectKit = false }), -- Yoran-Oran UC
    [981] = e('buffer',    'S', { injectKit = false }), -- Sylvie UC
    [982] = e('melee_dd',  'B', { injectKit = false }), -- Abquhbah
    [983] = e('nuker',     'A', { injectKit = 'nuker' }), -- Balamor (shell)
    [984] = e('melee_dd',  'S', { injectKit = false }), -- August
    [985] = e('nuker',     'B', { injectKit = 'nuker' }), -- Rosulatia (shell)
    [986] = e('nuker',     'B', { injectKit = 'nuker' }), -- Teodor (shell)
    [987] = e('nuker',     'B', { injectKit = 'nuker' }), -- Ullegore (shell)
    [988] = e('ranged_dd', 'B', { injectKit = 'ranged_dd' }), -- Makki (shell)
    [989] = e('buffer',    'B', { injectKit = 'buffer' }), -- King of Hearts (shell)
    [990] = e('melee_dd',  'A', { injectKit = 'melee_dd' }), -- Morimar (shell)
    [991] = e('melee_dd',  'A', { injectKit = 'melee_dd' }), -- Darrcuiln (shell)
    [992] = e('melee_dd',  'A', { injectKit = false }), -- Ark HM
    [993] = e('healer',    'A', { injectKit = false }), -- Ark EV
    [994] = e('ranged_dd', 'A', { injectKit = 'ranged_dd' }), -- Ark MR (shell)
    [995] = e('nuker',     'A', { injectKit = 'nuker' }), -- Ark TT (shell)
    [996] = e('melee_dd',  'A', { injectKit = false }), -- Ark GK
    [997] = e('melee_dd',  'A', { injectKit = 'melee_dd' }), -- Iroha (shell)
    [998] = e('healer',    'A', { injectKit = false }), -- Ygnas
    [999] = e('healer',    'S', { injectKit = false }), -- Monberaux

    -- Void Keeper capstones (client IDs)
    [1002] = e('aura',   'S', { injectKit = false }), -- Cornelia
    [1003] = e('hybrid', 'S', { cap = C.MATSUI_CAP, injectKit = false }), -- Matsui-P

    [1004] = e('melee_dd', 'B', { injectKit = 'melee_dd' }), -- Excenmille [S] (shell)
    [1005] = e('melee_dd', 'A', { injectKit = 'melee_dd' }), -- Ayame UC (shell)
    [1006] = e('melee_dd', 'A', { injectKit = false }), -- Maat UC
    [1007] = e('melee_dd', 'A', { injectKit = 'melee_dd' }), -- Aldo UC (shell)
    [1008] = e('melee_dd', 'A', { injectKit = 'melee_dd' }), -- Naja UC (shell)
    [1009] = e('melee_dd', 'S', { injectKit = false }), -- Lion II
    [1010] = e('melee_dd', 'S', { injectKit = false }), -- Zeid II
    [1011] = e('melee_dd', 'S', { injectKit = false }), -- Prishe II
    [1012] = e('healer',   'A', { injectKit = false }), -- Nashmeira II
    [1013] = e('melee_dd', 'A', { injectKit = 'melee_dd' }), -- Lilisette II (shell)
    [1014] = e('melee_dd', 'S', { injectKit = false }), -- Tenzen II
    [1015] = e('buffer',   'A', { injectKit = false }), -- Mumor II
    [1016] = e('healer',   'A', { injectKit = 'healer' }), -- Ingrid II (shell)
    [1017] = e('nuker',    'S', { injectKit = 'nuker' }), -- Arciela II (shell)
    [1018] = e('melee_dd', 'S', { injectKit = false }), -- Iroha II
    [1019] = e('nuker',    'S', {
        injectKit = false,
        mbCap     = C.SHANTOTTO_II_MB_CAP,
    }), -- Shantotto II
}

function C.get(spellId)
    return C.trusts[spellId]
end

return C
