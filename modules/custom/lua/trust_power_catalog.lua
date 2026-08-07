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
C.MATSUI_CAP          = 79999 -- Void Keeper capstone: frequent 40–50k, spikes to 79,999
C.SHANTOTTO_II_MB_CAP = 79999
C.MATSUI_SOFT_BAND    = { 40000, 50000 }

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

-- spellId -> { role, tier, style?, cap?, mbCap?, softBand?, injectKit?, meleeChip? }
-- meleeChip: fraction of tier melee package for healers/buffers who still AA/WS
-- (e.g. Ferreous Randgrith). Does not change cure/support package.
local function e(role, tier, opts)
    opts = opts or {}
    return {
        role      = role,
        tier      = tier,
        style     = opts.style or 'standard',
        cap       = opts.cap,
        mbCap     = opts.mbCap,
        softBand  = opts.softBand,
        injectKit = opts.injectKit,
        meleeChip = opts.meleeChip,
    }
end

C.trusts =
{
    ------------------------------------------------------------------
    -- Starters (deliberately modest — first party, not endgame DPS)
    ------------------------------------------------------------------
    [896] = e('nuker',     'C', { style = 'apprentice', injectKit = false }), -- Shantotto (ST I–V; hate mute; MP conserve)
    [898] = e('healer',    'C', { style = 'support',    injectKit = false }), -- Kupipi (status-first; hold@20'/15')
    [905] = e('tank',      'C', { style = 'bruiser',    injectKit = false }), -- Trion
    [908] = e('melee_dd',  'C', { style = 'weaponskill',injectKit = false }), -- Tenzen (starter C; Amatsu; CLOSER@1500; Light solo SC)

    ------------------------------------------------------------------
    -- D1 entry farms
    ------------------------------------------------------------------
    [897] = e('melee_dd',  'C', { style = 'bruiser',     injectKit = 'melee_dd' }), -- Naji
    [900] = e('melee_dd',  'C', { style = 'weaponskill', injectKit = false }), -- Ayame
    [904] = e('nuker',     'C', { style = 'apprentice',  injectKit = false, mbCap = 10000 }), -- Ajido (Dispel-first; hate→AA; palm blast; no TP)
    [909] = e('healer',    'C', { style = 'support',     injectKit = false, meleeChip = 0.45 }), -- Mihli (Scouring Bubbles / club)
    [912] = e('melee_dd',  'C', { style = 'skirmisher',  injectKit = false }), -- Naja (Peacebreaker util; STORE_TP; ASAP@1000)
    [918] = e('tank',      'C', { style = 'skirmisher',  injectKit = false }), -- Gessho (off-tank)
    [916] = e('healer',    'C', { style = 'support',     injectKit = false }), -- Cherukiki (Regen-first; no engage; ~15')
    [922] = e('hybrid',    'C', { style = 'skirmisher',  injectKit = false }), -- Lehko (dagger + throw + T1/T2 nukes)
    [924] = e('melee_dd',  'C', { style = 'bruiser',     injectKit = false }), -- Zazarg (Focus@soft ACC; ASAP@1000; Meteoric)
    [925] = e('nuker',     'C', { style = 'apprentice',  injectKit = false, mbCap = 10000 }), -- Ovjang (Stormwaker; Sixth Element; CLOSER@1500)
    [926] = e('tank',      'C', { style = 'bruiser',     injectKit = false }), -- Mnejing
    [927] = e('aura',      'C', { style = 'support',     injectKit = false }), -- Sakura
    [931] = e('aura',      'C', { style = 'support',     injectKit = false }), -- Moogle
    [936] = e('healer',    'C', { style = 'support',     injectKit = false, meleeChip = 0.45 }), -- Karaha (staff WS / Howling Moon)
    [939] = e('melee_dd',  'C', { style = 'bruiser',     injectKit = false }), -- Areuhat
    [940] = e('ranged_dd', 'C', { style = 'skirmisher',  injectKit = false }), -- Semih (CLOSER@2000; Sidewinder dump; Stellar/Lux T3)
    [941] = e('ranged_dd', 'C', { style = 'skirmisher',  injectKit = false }), -- Elivira (NO_MOVE hybrid; Barrage@TP<1000; CLOSER@1000)
    [943] = e('melee_dd',  'C', { style = 'bruiser',     injectKit = false }), -- Lhu (Spinning Axe bias; ASAP)
    [944] = e('healer',    'C', { style = 'support',     injectKit = false, meleeChip = 0.45 }), -- Ferreous (Randgrith ASAP chip)
    [949] = e('melee_dd',  'C', { style = 'skirmisher',  injectKit = false }), -- Romaa (Cobra Clamp; SA/TA positioned; ASAP@1000)
    [958] = e('melee_dd',  'C', { style = 'bruiser',     injectKit = false }), -- Babban
    [959] = e('melee_dd',  'C', { style = 'bruiser',     injectKit = false }), -- Abenzio
    [961] = e('nuker',     'C', { style = 'apprentice',  injectKit = false, mbCap = 10000 }), -- Kukki (day-element; Lightsday idle; no WS)
    [962] = e('ranged_dd', 'C', { style = 'skirmisher',  injectKit = false }), -- Margret (WS@2000; TH3; low-HP AA hold)
    [966] = e('melee_dd',  'C', { style = 'skirmisher',  injectKit = false }), -- Mayakov (Feather Step / Climactic; hold@2000)
    [968] = e('nuker',     'C', { style = 'scholar',     injectKit = false, mbCap = 10000 }), -- Adelheid (storm/helix/MB; microtubes; ASAP@1000)
    [972] = e('melee_dd',  'C', { style = 'bruiser',     injectKit = false }), -- Halver (PLD script, not WAR kit)

    ------------------------------------------------------------------
    -- D2 mid content
    ------------------------------------------------------------------
    [903] = e('melee_dd',  'B', { style = 'bruiser',     injectKit = false }), -- Volker (DD/tank stance; WS@2000+WC; Berserk-Ruf)
    [911] = e('buffer',    'B', { style = 'support',     injectKit = false }), -- Joachim (BRD/WHM songs; throw RA; no WS)
    [913] = e('melee_dd',  'B', { style = 'bruiser',     injectKit = false }), -- Prishe (unique H2H; Cure@25%; ASAP@1000)
    [915] = e('melee_dd',  'B', { style = 'skirmisher',  injectKit = false }), -- Shikaree Z (DRG/WHM polearm; Jump TP; CLOSER@2000)
    [917] = e('melee_dd',  'B', { style = 'bruiser',     injectKit = false }), -- Iron Eater
    [919] = e('nuker',     'B', { style = 'pressure',    injectKit = false }), -- Gadalar (Firaga; Salamander; ASAP@1000)
    [921] = e('hybrid',    'B', { style = 'weaponskill', injectKit = false }), -- Ingrid (CLOSER@1500; Banish; Cursna; melee)
    [923] = e('utility',   'B', { style = 'support',     injectKit = false }), -- Nashmeira (PUP/WHM; Cure@33%; Imperial Authority)
    [929] = e('ranged_dd', 'B', { style = 'weaponskill', injectKit = false }), -- Najelith (NO_MOVE hybrid; CLOSER@1500; Cyclone opener)
    [932] = e('hybrid',    'B', { style = 'pressure',    injectKit = false }), -- Fablinix
    [933] = e('melee_dd',  'B', { style = 'bruiser',     injectKit = false }), -- Maat (ASAP@1000; Bear Killer; Mantra HP+Haste)
    [934] = e('hybrid',    'B', { style = 'weaponskill', injectKit = false }), -- Domina (darkness nukes; ASAP@1000; Salvation)
    [935] = e('aura',      'B', { style = 'support',     injectKit = false }), -- Star Sibyl (incorporeal Indi-Acumen / MACC)
    [942] = e('melee_dd',  'B', { style = 'weaponskill', injectKit = false }), -- Noillurie (GK Kaiten/Light SC; Sekkanoki 4-step)
    [946] = e('melee_dd',  'B', { style = 'skirmisher',  injectKit = false }), -- Mumor (DNC/WAR Skullbreaker; Saber Dance)
    [948] = e('melee_dd',  'B', { style = 'bruiser',     injectKit = false }), -- Klara (ASAP@1000; Provoke on master)
    [951] = e('tank',      'B', { style = 'bruiser',     injectKit = false }), -- Rahal
    [952] = e('buffer',    'B', { style = 'support',     injectKit = false }), -- Koru-Moru (RDM/WHM; no engage / no WS)
    [960] = e('tank',      'B', { style = 'bruiser',     injectKit = false }), -- Rughadjeen
    [965] = e('buffer',    'B', { style = 'support',     injectKit = false, meleeChip = 0.55 }), -- Arciela (support RDM/PLD; light AA + unique WS)
    [969] = e('tank',      'B', { style = 'bruiser',     injectKit = false }), -- Amchuchu
    [970] = e('aura',      'B', { style = 'support',     injectKit = false }), -- Brygid (incorporeal Indi-CHR / Barrier / Fend)
    [974] = e('nuker',     'B', { style = 'pressure',    injectKit = false }), -- Leonoyne (Blizzaga; GS + Enblizzard; ASAP@1000)
    [977] = e('nuker',     'B', { style = 'burst',       injectKit = false }), -- Robel-Akbel (MB -aja; Null Blast; NO_MOVE)
    [997] = e('melee_dd',  'B', { style = 'weaponskill', injectKit = false }), -- Iroha (Amatsu solo SC; ASAP kit fights CLOSER@2500)
    -- 1004 = Matsui-P (Exc_S overlay) — see Void Keeper block below
    [1006]= e('melee_dd',  'B', { style = 'bruiser',     injectKit = false }), -- Maat UC (Hollow Smite SC open/close/dump@3000)
    [1014]= e('ranged_dd', 'B', { style = 'weaponskill', injectKit = false }), -- Tenzen II (Oisoya opener; hold@3000)
    [1016]= e('hybrid',    'B', { style = 'weaponskill', injectKit = false }), -- Ingrid II (Club Light SC / Banish MB)

    ------------------------------------------------------------------
    -- D3 hard content
    ------------------------------------------------------------------
    [906] = e('melee_dd',  'A', { style = 'weaponskill', injectKit = false }), -- Zeid (ASAP@1000; Abyssal interrupt; Souleater@healer)
    [907] = e('melee_dd',  'A', { style = 'skirmisher',  injectKit = false }), -- Lion (pirate WS; ASAP@1000)
    [910] = e('tank',      'A', { style = 'bruiser',     injectKit = false }), -- Valaineral
    [920] = e('hybrid',    'A', { style = 'pressure',    injectKit = false }), -- Rainemard (RDM/PLD sword + weakness enspell)
    [928] = e('ranged_dd', 'A', { style = 'weaponskill', injectKit = false }), -- Luzaf (preferred WS + CLOSER@2500; no Barrage kit)
    [937] = e('melee_dd',  'A', { style = 'bruiser',     injectKit = false }), -- Cid (club/gun; custom Berserk timing)
    [938] = e('melee_dd',  'A', { style = 'weaponskill', injectKit = false }), -- Gilgamesh (Sekkanoki self-SC; ASAP kit would fight CLOSER@2000)
    [945] = e('melee_dd',  'A', { style = 'skirmisher',  injectKit = false }), -- Lilisette (unique DNC TP AI)
    [950] = e('aura',      'A', { style = 'support',     injectKit = false }), -- Kuyin Hathdenna (incorporeal Indi-Precision)
    [953] = e('healer',    'A', { style = 'support',     injectKit = false, meleeChip = 0.50 }), -- Pieuje UC (NO_MOVE club AA; Nott)
    [954] = e('melee_dd',  'A', { style = 'weaponskill', injectKit = false }), -- I.Shield UC (WAR/COR provoke DD)
    [956] = e('melee_dd',  'A', { style = 'skirmisher',  injectKit = false }), -- Jakoh UC (THF/WAR SA/TA knife; Lua WS)
    [957] = e('melee_dd',  'A', { style = 'weaponskill', injectKit = false }), -- Flaviria UC (DRG polearm / Celidon)
    [967] = e('ranged_dd', 'A', { style = 'skirmisher',  injectKit = false }), -- Qultada CORE (COR/RNG gun + sword WS)
    [971] = e('melee_dd',  'A', { style = 'weaponskill', injectKit = false }), -- Mildaurion (master OPENER@1500; CLOSER/dump@3000)
    [973] = e('melee_dd',  'A', { style = 'bruiser',     injectKit = false }), -- Rongelouts (Tongue Lash; Warcry 50s; ASAP@1000)
    [975] = e('melee_dd',  'A', { style = 'skirmisher',  injectKit = false }), -- Maximilian (master OPENER@1500; CLOSER/dump@2500)
    [976] = e('nuker',     'A', { style = 'burst',       injectKit = false }), -- Kayeel-Payeel (Ice/Lit MB; Gate AM; NO_MOVE AA)
    [980] = e('healer',    'A', { style = 'support',     injectKit = false }), -- Yoran-Oran UC (standback Solace; Nott; no AA)
    [983] = e('hybrid',    'A', { style = 'pressure',    injectKit = false }), -- Balamor (DRK/BLM absorbs + dark magical AA/WS)
    [985] = e('nuker',     'A', { style = 'pressure',    injectKit = false }), -- Rosulatia (Stone only; special AA; no MB)
    [987] = e('nuker',     'A', { style = 'pressure',    injectKit = false }), -- Ullegore (Comet+Memento; Corse WS; no kit)
    [992] = e('melee_dd',  'A', { style = 'bruiser',     injectKit = false }), -- Ark HM
    [993] = e('tank',      'A', { style = 'bruiser',     injectKit = false }), -- Ark EV
    [994] = e('melee_dd',  'A', { style = 'bruiser',     injectKit = false }), -- Ark MR (axe SA/TA; Cloudsplitter MATT in script)
    [995] = e('nuker',     'A', { style = 'burst',       injectKit = false }), -- Ark TT (MB-only; Sleepga@Amon; ASAP@2000)
    [996] = e('melee_dd',  'A', { style = 'weaponskill', injectKit = false }), -- Ark GK
    [999] = e('healer',    'A', { style = 'support',     injectKit = false }), -- Monberaux (Chemist Mix; MP-90%; no AA — leave CDs alone)
    [1005]= e('melee_dd',  'A', { style = 'weaponskill', injectKit = false }), -- Ayame UC (player/pet SC closer)
    [1008]= e('melee_dd',  'A', { style = 'skirmisher',  injectKit = false }), -- Naja UC (exclusive WS OPENER; high multi)
    [1012]= e('healer',    'A', { style = 'support',     injectKit = false }), -- Nashmeira II (Curaga 3+/sleep; Imperial Authority@1000)
    [1013]= e('melee_dd',  'A', { style = 'skirmisher',  injectKit = false }), -- Lilisette II (CLOSER@2000; Rousing JA)
    [1015]= e('nuker',     'A', { style = 'burst',       injectKit = false }), -- Mumor II (MB -ja; Fever dance seq; wand AA)
    [1017]= e('hybrid',    'A', { style = 'burst',       injectKit = false }), -- Arciela II (RDM/BLM; 90s Light/Dark; MB+unique WS)
    [1018]= e('melee_dd',  'A', { style = 'weaponskill', injectKit = false }), -- Iroha II

    ------------------------------------------------------------------
    -- D4 / D5 / CORE endgame
    ------------------------------------------------------------------
    [914] = e('buffer',    'S', { style = 'support',     injectKit = false }), -- Ulmia CORE
    [947] = e('melee_dd',  'S', { style = 'skirmisher',  injectKit = false }), -- Uka Totlihn (Judgment@2000; Quickstep/RF; Waltz@66%)
    [955] = e('healer',    'S', { style = 'support',     injectKit = false }), -- Apururu UC CORE (Regain/Nott healer; no AA)
    [963] = e('utility',   'B', { style = 'support',     injectKit = false }), -- Chacharoon (status utility; no spell kit)
    [964] = e('melee_dd',  'S', { style = 'bruiser',     injectKit = false }), -- Lhe (CLOSER@2000; MNK AI)
    [978] = e('aura',      'S', { style = 'support',     injectKit = false }), -- Kupofried passive EXP (no combat kit)
    [979] = e('hybrid',    'A', { style = 'pressure',    injectKit = false }), -- Selh'teus (Lance/Revelation; Rejuv@30s; hold@3000)
    [981] = e('buffer',    'S', { style = 'support',     injectKit = false }), -- Sylvie UC CORE (Indi/Entrust; Nott; no AA)
    -- Abquhbah: A bruiser power path; no melee_dd kit (that kit forces ASAP + WAR JAs
    -- and would overwrite retail CLOSER_UNTIL_TP / Berserk+Warcry+Restraint).
    [982] = e('melee_dd',  'A', { style = 'bruiser',     injectKit = false }), -- Abquhbah
    [984] = e('tank',      'S', { style = 'bruiser',     injectKit = false }), -- August CORE
    [986] = e('hybrid',    'S', { style = 'apex',        injectKit = false }), -- Teodor (special AA/WS; MB-only -ga/-ja; Scratch→Hemo)
    [988] = e('ranged_dd', 'S', { style = 'weaponskill', injectKit = false }), -- Makki (WS@2000; Barrage/Flashy; Lightsday idle)
    [989] = e('buffer',    'A', { style = 'support',     injectKit = false, meleeChip = 0.55 }), -- King of Hearts (RDM/WHM Arcana; Cardian WS)
    [990] = e('melee_dd',  'S', { style = 'bruiser',     injectKit = false }), -- Morimar (Vehement / CLOSER@2000; special AA)
    [991] = e('melee_dd',  'S', { style = 'skirmisher',  injectKit = false }), -- Darrcuiln (special AA/WS; no JA kit)
    [998] = e('healer',    'S', { style = 'support',     injectKit = false, meleeChip = 0.40 }), -- Ygnas (unique WS chip; no AA)
    [1009]= e('melee_dd',  'S', { style = 'skirmisher',  injectKit = false }), -- Lion II (ST pirate WS; CLOSER@3000)
    [1010]= e('melee_dd',  'S', { style = 'weaponskill', injectKit = false }), -- Zeid II CORE (GS only; CLOSER@3000; Souleater@healer)
    [1011]= e('melee_dd',  'S', { style = 'bruiser',     injectKit = false }), -- Prishe II (unique H2H; anima once; ASAP@1000)
    [1019]= e('nuker',     'S', {
        style     = 'apex',
        injectKit = false,
        mbCap     = C.SHANTOTTO_II_MB_CAP, -- only S nuke that may exceed 40k on MB
    }), -- Shantotto II CORE (custom T2–V + FC; unique MS; magical AA)

    ------------------------------------------------------------------
    -- Void Keeper customs (chase rewards — top band)
    ------------------------------------------------------------------
    [899] = e('tank',      'C', { style = 'bruiser',     injectKit = false }), -- Excenmille (starter PLD; Meat overlay must not reclaim 899)
    [901] = e('buffer',    'S', { style = 'support',     injectKit = false }), -- Gemma
    [902] = e('ranged_dd', 'A', { style = 'weaponskill', injectKit = false }), -- Corvus
    [1002]= e('aura',      'S', { style = 'support',     injectKit = false }), -- Cornelia (incorporeal Haste/Acc/RAcc/MAcc)
    [1004]= e('hybrid',    'S', {
        style     = 'apex',
        cap       = C.MATSUI_CAP,
        mbCap     = C.MATSUI_CAP,
        softBand  = C.MATSUI_SOFT_BAND,
        injectKit = false,
    }), -- Matsui-P on Exc_S slot (Void Keeper: soft 40–50k, hard 79,999)

    ------------------------------------------------------------------
    -- Implemented but not grantable yet (DISABLED_SPELL)
    ------------------------------------------------------------------
    [1020]= e('melee_dd',  'S', { style = 'bruiser',     injectKit = false }), -- Fujito-PD (locked)

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
