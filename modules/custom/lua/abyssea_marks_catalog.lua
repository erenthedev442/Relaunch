-----------------------------------
-- Bespoke marks-popped Abyssea encounter catalog
--
-- Keys are normalized logical NM names. Alternate OFFSET copies therefore
-- share one encounter definition while every distinct NM keeps its own
-- named tell, counter, failure, and payoff.
-----------------------------------

local C = {}

local entries = {}
local ordered = {}

local tierDefaults =
{
    -- Pressure starts inside the expected clear-time band instead of after it.
    -- It remains a soft ramp: mechanics and normal combat are the primary test.
    [1] = { repeatSec = 52, firstSignatureSec = 24, pressureSec = 240, pressureStepSec = 30 },
    [2] = { repeatSec = 44, firstSignatureSec = 20, pressureSec = 360, pressureStepSec = 25 },
    [3] = { repeatSec = 36, firstSignatureSec = 16, pressureSec = 480, pressureStepSec = 20 },
}

local effectCycle =
{
    xi.effect.POISON,
    xi.effect.PARALYSIS,
    xi.effect.BLINDNESS,
    xi.effect.SLOW,
    xi.effect.SILENCE,
    xi.effect.PLAGUE,
    xi.effect.AMNESIA,
}

-- Every failed challenge forces one active, non-lethal TP move that fits the
-- NM's family or retail skill list. Moves deal damage where the family supports
-- it; status-only families use their strongest visible enfeeble. Keeping this
-- separate from the signature prose covers all 136 encounters while avoiding
-- random selection of heals, buffs, Doom, or unimplemented skills.
local punishmentSkills =
{
    -- Visions
    arimaspi = 549, bloodguzzler = 415, clingyclare = 319, hexenpilz = 311,
    bombadeel = 584, ashtaerhthegallvexed = 1963, alkonost = 1330,
    keratyrannos = 2104, feargorta = 1340, siranpakamuy = 549, lentor = 2185,
    sarcophilus = 519, kukulkan = 2153, eccentriceve = 726,
    bloodeyevileberry = 788, lachrymater = 1228, hedetet = 353, muscaliet = 800,
    cannerednoz = 437, ophanim = 437, tefenet = 483, gancanagh = 305, abas = 519,
    vetehinen = 2564, alectryon = 406, halimede = 2562, treblenoctules = 395,
    glavoid = 2189, lacovie = 806, chloris = 305, latheineliege = 658,
    poroggodomjuan = 1959, lugarhoo = 2170, dozingdorian = 262,
    topplingtuber = 308, grandgousier = 1636, adamastor = 665, nguruvilu = 1723,
    pantagruel = 663, babayaga = 2193, megantereon = 273,
    trudgingthomas = 266, carabosse = 2193, briareus = 2578, hadhayosh = 628,

    -- Scars
    svarbhanu = 646, maahes = 483, mielikki = 331, gaizkin = 492,
    pallidpercy = 427, berstuk = 2185, wherwetrice = 406, drekavac = 472,
    kharon = 485, kampe = 353, nightshade = 305, blazingeruca = 1791,
    graniteborer = 1818, smok = 1279, ulhuadshi = 2189, titlacauan = 1326,
    itzpapalotl = 1951, minaxbugard = 383, sirrush = 367, funerealapkallu = 1717,
    manohra = 1580, cepkamuy = 1696, ironcladobserver = 665, nehebkau = 378,
    avalerion = 2178, karkatakam = 444, nonno = 300, tuskertrap = 719,
    npfundlwa = 258, amhuluk = 2433, cireincroin = 1693, sobek = 383,
    ironcladpulverizer = 665, khalkotaur = 500, quasimodo = 2426, ikuturso = 462,
    kadraeththehatespawn = 1963, dvalinn = 2118, rakshas = 271, seps = 1723,
    xan = 2178, chhirbatti = 591, pascerpot = 345, gnawtoothgary = 259,
    armillaria = 311, sedna = 2437, durinn = 2118, bukhis = 500,
    karkadann = 2335,

    -- Heroes
    sharabha = 799, chickcharney = 406, emperadordealtepa = 1625, waugyl = 1723,
    shaula = 353, tablilla = 539, vadleany = 2181, amarok = 1787, bugulnoz = 305,
    ironcladsmiter = 665, orthrus = 1787, dragua = 1301, bennu = 401,
    rani = 2566, bomblixflamefinger = 591, ikaroa = 452, minaruja = 814,
    lorelei = 2194, xibalba = 485, teugghia = 2193, ningishzida = 1835,
    burstroxpowderpate = 591, teekesselchen = 521, ironcladsunderer = 665,
    alfard = 1835, azdaja = 1311, raja = 2567, amphitrite = 507,
    ironcladtriturator = 665, dhormekhimaira = 2023, blanga = 2426,
    yaguarogui = 273, koghatu = 3975, upaskamuy = 1645, veriselen = 814,
    chillwinghwitti = 2003, anemicaloysius = 425, audumbla = 494,
    pantokrator = 1527, isgebind = 1289, apademak = 2023, resheph = 365,
}

local function normalize(name)
    return (name or ''):lower():gsub('[^a-z0-9]', '')
end

local function clone(source)
    local result = {}
    for key, value in pairs(source or {}) do
        if type(value) == 'table' then
            result[key] = clone(value)
        else
            result[key] = value
        end
    end
    return result
end

local function signature(title, kind, tell, success, fail, options)
    options = options or {}
    return
    {
        title     = title,
        kind      = kind,
        tell      = string.format('%s — %s', title, tell),
        success   = success,
        fail      = fail,
        delaySec  = options.delaySec or 10,
        distance  = options.distance,
        angle     = options.angle,
        damagePct = options.damagePct,
        hpp       = options.hpp,
        failure   =
        {
            skill      = options.punishSkill,
            tp         = options.punishTp,
            castTimeMs = options.punishCastTimeMs,
            effect     = options.effect,
            duration   = options.effectDuration,
            power      = options.effectPower,
            tick       = options.effectTick,
        },
        reward =
        {
            sec  = 15,
            def  = options.rewardDef,
            eva  = options.rewardEva,
            mdef = options.rewardMdef,
        },
    }
end

local reversal =
{
    turn        = { kind = 'move',        tell = 'the pattern reverses; move at least 9 yalms!' },
    face        = { kind = 'hold',        tell = 'the pattern mirrors aggression; cease attacks!' },
    rear        = { kind = 'far',         tell = 'the rear erupts; retreat beyond 13 yalms!' },
    near        = { kind = 'move',        tell = 'the safe center shifts; move at least 9 yalms!' },
    far         = { kind = 'near',        tell = 'the outer ring closes; move within 6 yalms!' },
    move        = { kind = 'rear',        tell = 'the marked path turns forward; reach the rear!' },
    hold        = { kind = 'burst',       tell = 'the restraint breaks; deal 4% HP before it reforms!' },
    burst       = { kind = 'far',         tell = 'the broken ward erupts outward; retreat beyond 13 yalms!' },
    weaponskill = { kind = 'far',         tell = 'the answer detonates outward; retreat beyond 13 yalms!' },
    highhp      = { kind = 'move',        tell = 'vitality is marked; move at least 9 yalms!' },
    lowhp       = { kind = 'face',        tell = 'the pattern demands resolve; face the enemy!' },
    proc        = { kind = 'weaponskill', tell = 'the weakness destabilizes; use a weapon skill!' },
    physical    = { kind = 'hold',        tell = 'the damage aspect reverses; cease attacks!' },
    magic       = { kind = 'move',        tell = 'the magic aspect marks the ground; move 9 yalms!' },
}

local function makeReversal(source, step)
    local result = clone(source)
    local rule = reversal[result.kind] or reversal.move
    result.title = string.format('%s — Reversal %d', source.title, step)
    result.kind = rule.kind
    result.tell = string.format('%s — %s', result.title, rule.tell)
    result.distance = nil
    result.damagePct = result.kind == 'burst' and 4 or nil
    if result.kind == 'move' then result.distance = 9 end
    if result.kind == 'far' then result.distance = 13 end
    if result.kind == 'near' then result.distance = 6 end
    return result
end

local function add(name, tier, sig, climax, options)
    options = options or {}
    local key = normalize(name)
    assert(entries[key] == nil, string.format('Duplicate Abyssea encounter: %s', name))
    local punishmentSkill = punishmentSkills[key]
    if punishmentSkill then
        sig.failure.skill = sig.failure.skill or punishmentSkill
        if climax then
            climax.failure.skill = climax.failure.skill or punishmentSkill
        end
    end

    local defaults = tierDefaults[tier]
    local phaseOne = clone(sig)
    if not climax and tier == 3 then
        phaseOne = makeReversal(sig, 1)
    end
    phaseOne.tell = string.format('At 70%%, %s', phaseOne.tell)

    local final
    if climax then
        final = clone(climax)
    elseif tier >= 2 then
        final = makeReversal(tier == 3 and phaseOne or sig, tier == 3 and 2 or 1)
    else
        final = clone(sig)
    end
    final.tell = string.format('Final test at 30%%: %s', final.tell)
    final.delaySec = final.delaySec or 10
    final.reward.sec = 15

    local entry =
    {
        key               = key,
        index             = #ordered + 1,
        signatureId       = 'aby_' .. key,
        label             = name,
        tier              = tier,
        signature         = sig,
        phases            =
        {
            { hp = 70, title = phaseOne.title, kind = phaseOne.kind, tell = phaseOne.tell, success = phaseOne.success, fail = phaseOne.fail, delaySec = phaseOne.delaySec, distance = phaseOne.distance, angle = phaseOne.angle, damagePct = phaseOne.damagePct, hpp = phaseOne.hpp, failure = phaseOne.failure, reward = phaseOne.reward },
            { hp = 30, title = final.title, kind = final.kind, tell = final.tell, success = final.success, fail = final.fail, delaySec = final.delaySec, distance = final.distance, angle = final.angle, damagePct = final.damagePct, hpp = final.hpp, failure = final.failure, reward = final.reward },
        },
        repeatSec         = options.repeatSec or defaults.repeatSec,
        firstSignatureSec = options.firstSignatureSec or defaults.firstSignatureSec,
        pressureSec       = options.pressureSec or defaults.pressureSec,
        pressureStepSec   = options.pressureStepSec or defaults.pressureStepSec,
        pressureMessage   = options.pressureMessage,
    }

    entries[key] = entry
    ordered[#ordered + 1] = entry
end

local function e(index)
    return effectCycle[((index - 1) % #effectCycle) + 1]
end

-- ========================================================================
-- T1: Visions of Abyssea (45)
-- ========================================================================

-- Konschtat
add('Arimaspi', 1, signature('Clouded Lens', 'turn', 'its eye clouds over; turn away!', 'The lens cracks and Arimaspi reels.', 'The lens sears your sight.', { effect = e(1) }))
add('Bloodguzzler', 1, signature('Crimson Thirst', 'highhp', 'it scents weakness; recover above 70% HP!', 'Your vitality denies the feeding frenzy.', 'Bloodguzzler drinks deeply.', { hpp = 70, effect = e(2) }))
add('Clingy Clare', 1, signature('Grasping Vines', 'move', 'roots seize the earth; move at least 8 yalms!', 'The vines tear loose.', 'The vines constrict around you.', { distance = 8, effect = e(3) }))
add('Hexenpilz', 1, signature('Oblivispore Bloom', 'far', 'the cap swells; retreat beyond 12 yalms!', 'The spores disperse harmlessly.', 'You inhale the oblivious spores.', { distance = 12, effect = e(4) }))
add('Bombadeel', 1, signature('Volatile Moss', 'hold', 'the moss sparks; cease attacks!', 'The moss burns itself out.', 'Your strike detonates the moss.', { effect = e(5) }))
add('Ashtaerh the Gallvexed', 1, signature('Murmuring Globule', 'weaponskill', 'the globule hums; answer with a weapon skill!', 'The resonance bursts inward.', 'The murmur becomes a maddening shriek.', { effect = e(6) }))
add('Alkonost', 1, signature('Gale Dive', 'rear', 'its wings lock forward; take the rear!', 'The dive overshoots.', 'The gale catches you head-on.', { effect = e(7) }))
add('Keratyrannos', 1, signature('Armored Rush', 'near', 'it lowers its horn; close inside 6 yalms!', 'You slip beneath the charge.', 'The full charge tramples you.', { distance = 6, effect = e(8) }))
add('Fear Gorta', 1, signature('Moonglow Lament', 'face', 'its lament seeks the fearful; face it!', 'You stare down the apparition.', 'Fear takes root.', { effect = e(9) }))
add('Siranpa-Kamuy', 1, signature('Rotting Gaze', 'turn', 'the eyeball opens; look away!', 'The gaze passes over you.', 'The dead eye marks you.', { effect = e(10) }))
add('Lentor', 1, signature('Mucid Bulwark', 'burst', 'mucus hardens; break 3% of its HP before it sets!', 'The bulwark sloughs away.', 'The shell hardens around Lentor.', { damagePct = 3, effect = e(11) }))
add('Sarcophilus', 1, signature('Ripped-Skin Feint', 'hold', 'it presents a false opening; hold your fire!', 'The feint collapses.', 'The counter tears through you.', { effect = e(12) }))
add('Kukulkan', 1,
    signature('Grim Glower', 'turn', 'yellow eyes blaze; turn away from petrification!', 'Kukulkan loses sight of its prey.', 'The yellow gaze begins to petrify you.', { effect = xi.effect.GRADUAL_PETRIFICATION, effectDuration = 8 }),
    signature('Oppressive Gaze', 'rear', 'blue eyes blaze; reach its rear!', 'The oppressive gaze misses and its scales part.', 'Terror and poison flood your body.', { effect = xi.effect.TERROR, effectDuration = 5, rewardSec = 14 }))
add('Eccentric Eve', 1,
    signature('Extremely Bad Breath', 'rear', 'the morbol inhales; get behind it!', 'The killing breath wilts Eve instead.', 'The breath leaves you barely standing.', { effect = xi.effect.CURSE_I, effectDuration = 12 }),
    signature('Tainting Breath', 'move', 'a charming perfume gathers; break away 10 yalms!', 'The perfume disperses.', 'The perfume steals your will.', { distance = 10, effect = xi.effect.TERROR, effectDuration = 6 }))
add('Bloodeye Vileberry', 1, signature('Grudge Spiral', 'move', 'the tonberry fixes your position; move 9 yalms!', 'The grudge strikes empty ground.', 'The accumulated grudge finds you.', { distance = 9, effect = xi.effect.AMNESIA }))

-- Tahrongi
add('Lachrymater', 1, signature('Vestige of the Day', 'hold', 'the elemental vestige mirrors attacks; pause!', 'The day-aspect fades.', 'The vestige reflects your aggression.', { effect = e(16) }))
add('Hedetet', 1, signature('Acidic Pincer', 'rear', 'the claws spread forward; circle behind!', 'The pincers snap on empty air.', 'Acid floods the wound.', { effect = e(17) }))
add('Muscaliet', 1, signature('Resilient Mane', 'burst', 'its mane stiffens; deal 3% HP to break it!', 'The mane parts and exposes its neck.', 'The mane becomes an iron wall.', { damagePct = 3, effect = e(18) }))
add('Cannered Noz', 1, signature('Baleful Skull', 'face', 'the skull demands courage; face it!', 'The baleful flame gutters out.', 'The skull brands your mind.', { effect = e(19) }))
add('Ophanim', 1, signature('Threefold Offering', 'weaponskill', 'its trophies orbit; shatter them with a weapon skill!', 'The orbit collapses.', 'The offerings empower Ophanim.', { effect = e(20) }))
add('Tefenet', 1, signature('Shocking Whisker', 'far', 'its whiskers crackle; retreat 11 yalms!', 'The charge grounds out.', 'Lightning courses through you.', { distance = 11, effect = e(21) }))
add('Gancanagh', 1, signature('Alkaline Feast', 'move', 'the soil bubbles underfoot; move 7 yalms!', 'The eruption misses.', 'Caustic humus engulfs you.', { distance = 7, effect = e(22) }))
add('Abas', 1, signature('Eft-Egg Guard', 'hold', 'it curls around its clutch; cease attacks!', 'Abas leaves its clutch exposed.', 'The guarded clutch erupts.', { effect = e(23) }))
add('Vetehinen', 1, signature('Limule Clamp', 'near', 'its reach extends; close within 5 yalms!', 'You crowd inside the clamp.', 'The pincer drags you through the mire.', { distance = 5, effect = e(24) }))
add('Alectryon', 1, signature('Quivering Brood', 'turn', 'the brood flashes; turn away!', 'The hatchlings lose their mark.', 'The flash blinds and panics you.', { effect = e(25) }))
add('Halimede', 1, signature('Clionid Shear', 'rear', 'its wing-blades sweep forward; take the rear!', 'The blades bury in the earth.', 'The crossing blades catch you.', { effect = e(26) }))
add('Treble Noctules', 1, signature('Threefold Screech', 'far', 'three throats inhale; spread beyond 13 yalms!', 'The harmonics break apart.', 'The harmonics overwhelm you.', { distance = 13, effect = e(27) }))
add('Glavoid', 1,
    signature('Gorge', 'far', 'it opens its maw; retreat beyond 12 yalms!', 'Glavoid stores no stolen life.', 'Gorge steals your vitality for Disgorge.', { distance = 12, effect = xi.effect.SLOW }),
    signature('Disgorge', 'rear', 'the stored torrent aims forward; reach its rear!', 'The torrent tears open Glavoid instead.', 'Disgorge crashes through you.', { effect = xi.effect.CURSE_I, rewardSec = 15 }))
add('Lacovie', 1, signature('Chipped Bastion', 'burst', 'its shell seals; crack 4% HP before it locks!', 'The shell fractures.', 'The bastion hardens.', { damagePct = 4, effect = e(29) }))
add('Chloris', 1,
    signature('Phaeosynthesis', 'burst', 'a solar bloom opens; deal 3% HP to uproot it!', 'The bloom ruptures and Chloris wilts.', 'The bloom feeds Chloris a furious vigor.', { damagePct = 3, effect = xi.effect.SLOW }),
    signature('Fatal Scream', 'weaponskill', 'Doom gathers in its throat; answer with a weapon skill!', 'The scream breaks into a stagger.', 'A brief Doom shadow falls over you.', { effect = xi.effect.DOOM, effectDuration = 8, rewardSec = 14 }))

-- La Theine
add('La Theine Liege', 1, signature('Transparent Wing', 'turn', 'the wing catches the light; turn away!', 'The false image dissolves.', 'The mirage steals your sight.', { effect = e(31) }))
add('Poroggo Dom Juan', 1, signature('Bug-Eaten Hex', 'move', 'the hat marks your ground; move 8 yalms!', 'The hex lands on empty earth.', 'The hex binds your thoughts.', { distance = 8, effect = e(32) }))
add('Lugarhoo', 1, signature('Filthy-Claw Pounce', 'near', 'it springs from afar; close inside 6 yalms!', 'You spoil the pounce.', 'The pounce tears through you.', { distance = 6, effect = e(33) }))
add('Dozing Dorian', 1, signature('Drowsing Stomp', 'face', 'it tries to lull you; face the threat!', 'Your focus breaks the lull.', 'Drowsiness slows every response.', { effect = e(34) }))
add('Toppling Tuber', 1, signature('Agaricus Roll', 'far', 'the giant cap topples; retreat 10 yalms!', 'The cap crashes short.', 'The cap crushes and spores you.', { distance = 10, effect = e(35) }))
add('Grandgousier', 1, signature('Massive Armband', 'rear', 'its arms sweep forward; circle behind!', 'The armbands drag it off balance.', 'The sweeping blow catches you.', { effect = e(36) }))
add('Adamastor', 1, signature('Trophy Shield', 'hold', 'the shield waits to counter; hold attacks!', 'The shield lowers.', 'The shield returns your force.', { effect = e(37) }))
add('Nguruvilu', 1, signature('Winter Egg', 'burst', 'an icy shell forms; break 3% HP!', 'The shell showers it in shards.', 'The shell seals its wounds.', { damagePct = 3, effect = e(38) }))
add('Pantagruel', 1, signature('Oversized Step', 'move', 'a giant foot shadows you; move 9 yalms!', 'The stomp misses.', 'The stomp pins you down.', { distance = 9, effect = e(39) }))
add('Baba Yaga', 1, signature('Piceous Veil', 'turn', 'black scales flash; turn away!', 'The veil loses its reflection.', 'The veil clouds your senses.', { effect = e(40) }))
add('Megantereon', 1, signature('Saber-Tooth Rush', 'near', 'it lines up a long rush; close within 5 yalms!', 'The tiger cannot build momentum.', 'The full rush mauls you.', { distance = 5, effect = e(41) }))
add('Trudging Thomas', 1, signature('Marbled Stampede', 'rear', 'the ram lowers its horns; take the rear!', 'Thomas stumbles past.', 'The horns launch you.', { effect = e(42) }))
add('Carabosse', 1,
    signature('Autumn Breeze', 'hold', 'Autumn absorbs aggression; cease attacks!', 'The season turns and Carabosse is exposed.', 'Autumn feeds on your attack.', { effect = xi.effect.SLOW }),
    signature('Winter to Summer', 'far', 'Winter gathers a cyclone; retreat 13 yalms!', 'The season exhausts itself.', 'The seasonal storm overwhelms you.', { distance = 13, effect = xi.effect.SILENCE, rewardSec = 15 }))
add('Briareus', 1,
    signature('Mercurial Omen', 'face', 'read the repeating number and face the giant!', 'You stand through the omen and expose its stance.', 'The omen breaks your formation.', { effect = xi.effect.CURSE_II, effectDuration = 8 }),
    signature('Meikyo Sequence', 'far', 'three Colossal Slams are coming; retreat 14 yalms!', 'Briareus exhausts its hundred arms.', 'The Slam sequence catches you.', { distance = 14, effect = xi.effect.CURSE_II, effectDuration = 10, rewardSec = 16 }))
add('Hadhayosh', 1,
    signature('Accursed Armor', 'hold', 'black armor reflects violence; cease attacks!', 'The armor gutters out.', 'The curse returns your aggression.', { effect = xi.effect.CURSE_I }),
    signature('Ecliptic Meteor', 'far', 'Meteor fixes your position; escape beyond 15 yalms!', 'The meteor misses and Hadhayosh falters.', 'Meteor consumes the marked ground.', { distance = 15, effect = xi.effect.AMNESIA, rewardSec = 16 }))

-- ========================================================================
-- T2: Scars of Abyssea (49)
-- ========================================================================

-- Attohwa
add('Svarbhanu', 2, signature('Cracked Scale', 'burst', 'a dragon scale seals its chest; break 4% HP!', 'The scale shatters inward.', 'The scale hardens its hide.', { damagePct = 4, effect = e(46) }))
add('Maahes', 2, signature('Coeurl Circuit', 'move', 'lightning maps your ground; move 10 yalms!', 'The circuit discharges harmlessly.', 'The circuit closes through you.', { distance = 10, effect = e(47) }))
add('Mielikki', 2, signature('Great Root', 'far', 'roots erupt in a widening ring; retreat 13 yalms!', 'The roots fail to reach.', 'The roots drag away your strength.', { distance = 13, effect = e(48) }))
add('Gaizkin', 2, signature('Undying Ooze', 'hold', 'the ooze copies incoming force; cease attacks!', 'The ooze decays.', 'The copied force erupts back.', { effect = e(49) }))
add('Pallid Percy', 2, signature('Pallid Division', 'burst', 'the slime begins to divide; deal 4% HP!', 'The division collapses.', 'The new mass reinforces Percy.', { damagePct = 4, effect = e(50) }))
add('Berstuk', 2, signature('Extended Eyestalk', 'turn', 'the eyestalk unfolds; look away!', 'The eye loses focus.', 'The gaze robs your memory.', { effect = e(51) }))
add('Wherwetrice', 2, signature('Mangled Pinion', 'rear', 'its wings scissor forward; take the rear!', 'The pinions tangle.', 'The scissor tears through you.', { effect = e(52) }))
add('Drekavac', 2, signature('Wailing Rags', 'face', 'the dead demand a witness; face them!', 'The wail loses its hold.', 'The rags smother your will.', { effect = e(53) }))
add('Kharon', 2, signature('Bone Toll', 'weaponskill', 'the ferryman demands force; pay with a weapon skill!', 'The toll cracks Kharon.', 'The unpaid toll drains your resolve.', { effect = e(54) }))
add('Kampe', 2, signature('Gory Pincer', 'near', 'the pincer reaches outward; crowd within 5 yalms!', 'You slip inside its reach.', 'The claw impales you.', { distance = 5, effect = e(55) }))
add('Nightshade', 2, signature('Withered Bloom', 'move', 'the bloom stains the ground; move 9 yalms!', 'The stain blooms alone.', 'The stain flowers beneath you.', { distance = 9, effect = e(56) }))
add('Blazing Eruca', 2, signature('Brood Furnace', 'far', 'the egg becomes a furnace; retreat 13 yalms!', 'The furnace vents away.', 'The broodfire scorches you.', { distance = 13, effect = e(57) }))
add('Granite Borer', 2, signature('Withered Cocoon', 'hold', 'the cocoon reflects disturbance; stop attacks!', 'The cocoon splits naturally.', 'The cocoon bursts in retaliation.', { effect = e(58) }))
add('Smok', 2,
    signature('Tebbad Wing', 'rear', 'its burning wings sweep forward; take the rear!', 'The wingfire feeds back into Smok.', 'Plague and heat take hold.', { effect = xi.effect.PLAGUE }),
    signature('Smoldering Sky', 'burst', 'embers crown Smok; deal 5% HP to cool it!', 'The heat meter collapses.', 'Smok enters a hotter rage.', { damagePct = 5, effect = xi.effect.TERROR, effectDuration = 5, rewardSec = 14 }))
add('Ulhuadshi', 2,
    signature('Damage Cocoon', 'hold', 'its hide absorbs all force; cease attacks!', 'The absorption ends empty.', 'Stored force heals its frenzy.', { effect = xi.effect.SLOW }),
    signature('Psyche Suction', 'far', 'the worm drinks every attribute nearby; retreat 14 yalms!', 'The suction starves.', 'Your attributes are crushed.', { distance = 14, effect = xi.effect.CURSE_I, rewardSec = 14 }))
add('Titlacauan', 2,
    signature('Memento Mori', 'weaponskill', 'the death-rite primes a nuke; break it with a weapon skill!', 'The rite shatters.', 'The rite empowers the coming spell.', { effect = xi.effect.SILENCE }),
    signature('Soul Tether', 'move', 'a charm tether fixes your soul; move 11 yalms!', 'The tether snaps.', 'The tether steals your will.', { distance = 11, effect = xi.effect.TERROR, effectDuration = 7 }))
add('Itzpapalotl', 2,
    signature('Exuviation', 'hold', 'it consumes aggression and ailments; cease attacks!', 'Exuviation finds nothing to feed on.', 'The molt feeds its blaze.', { effect = xi.effect.PLAGUE }),
    signature('Blazing Flutter', 'far', 'Blaze Spikes erupt around it; retreat 14 yalms!', 'The flames gutter out.', 'The flutter brands you.', { distance = 14, effect = xi.effect.PARALYSIS, rewardSec = 14 }))

-- Misareaux
add('Minax Bugard', 2, signature('Bugard Breakline', 'rear', 'its horns rake forward; reach the rear!', 'The hornline misses.', 'The horns tear away your guard.', { effect = e(63) }))
add('Sirrush', 2, signature('Scale Reversal', 'hold', 'its scales reverse incoming force; stop attacks!', 'The scales settle.', 'The reversal strikes back.', { effect = e(64) }))
add('Funereal Apkallu', 2, signature('Funereal March', 'move', 'the march marks your ground; move 8 yalms!', 'The procession passes by.', 'The march tramples your focus.', { distance = 8, effect = e(65) }))
add('Manohra', 2, signature('Razor Plume', 'turn', 'plumes flash like mirrors; turn away!', 'The plume loses its mark.', 'The flash blinds you.', { effect = e(66) }))
add('Cep-Kamuy', 2, signature('Kamuy Coil', 'near', 'the coil strikes at range; close within 5 yalms!', 'You crowd the striking arc.', 'The coil lashes through you.', { distance = 5, effect = e(67) }))
add('Ironclad Observer', 2, signature('Observer Lock', 'move', 'a targeting lattice fixes your position; move 10 yalms!', 'The lattice loses lock.', 'The observer cannon finds you.', { distance = 10, effect = e(68) }))
add('Nehebkau', 2, signature('Serpent Compass', 'rear', 'its neck fixes forward; circle behind!', 'The serpent overextends.', 'The fangs find their line.', { effect = e(69) }))
add('Avalerion', 2, signature('Avalanche Wing', 'far', 'the wings drive a pressure front; retreat 12 yalms!', 'The front breaks short.', 'The pressure buries you.', { distance = 12, effect = e(70) }))
add('Karkatakam', 2, signature('Carapace Vice', 'burst', 'the shell closes; deal 4% HP to jam it!', 'The carapace remains open.', 'The shell seals its weakness.', { damagePct = 4, effect = e(71) }))
add('Nonno', 2, signature('False Slumber', 'hold', 'it feigns sleep and waits to counter; pause!', 'The feint expires.', 'The waking counter catches you.', { effect = e(72) }))
add('Tuskertrap', 2, signature('Tusker Snare', 'move', 'the trap roots beneath you; move 9 yalms!', 'The snare closes empty.', 'The tusks lock around you.', { distance = 9, effect = e(73) }))
add('Npfundlwa', 2, signature('Hareline Feint', 'face', 'it darts for your blind side; keep facing it!', 'You catch the feint.', 'The feint tears through your flank.', { effect = e(74) }))
add('Amhuluk', 2,
    signature('Calamitous Wind', 'near', 'the wind expands outward; close within 6 yalms!', 'You stand inside the pressure edge.', 'The gale strips your momentum.', { distance = 6, effect = xi.effect.SILENCE }),
    signature('Vermillion Chain', 'move', 'a second wind marks your ground; move 11 yalms!', 'The repeated gust misses.', 'Two winds collide on you.', { distance = 11, effect = xi.effect.TERROR, effectDuration = 5 }))
add('Cirein-croin', 2,
    signature('Mayhem Lantern', 'burst', 'the lantern swells; deal 4% HP to dim it!', 'The lantern dims and exposes the body.', 'Mayhem floods your senses.', { damagePct = 4, effect = xi.effect.TERROR, effectDuration = 5 }),
    signature('Lantern Shock', 'turn', 'the lantern strobes; turn away!', 'The strobe passes harmlessly.', 'Shock and confusion seize you.', { effect = xi.effect.PARALYSIS }))
add('Sobek', 2,
    signature('Tyrant Tusk', 'highhp', 'the tusk executes the wounded; recover above 60% HP!', 'Your vitality blunts the execution.', 'The tusk finds you weakened.', { hpp = 60, effect = xi.effect.CURSE_I }),
    signature('Awful Eye', 'turn', 'the eye opens; turn away from petrification!', 'The gaze misses and Sobek loses hate.', 'The eye petrifies you.', { effect = xi.effect.PETRIFICATION, effectDuration = 6 }))
add('Ironclad Pulverizer', 2,
    signature('Pulverizing Lock', 'move', 'the cannon fixes your coordinates; move 10 yalms!', 'The shot pulverizes empty ground.', 'The cannon crushes your guard.', { distance = 10, effect = xi.effect.AMNESIA }),
    signature('Ironclad Overheat', 'hold', 'its armor glows white; cease attacks!', 'The heat vents through cracked plates.', 'Your attack detonates the plates.', { effect = xi.effect.PLAGUE }))

-- Vunkerl
add('Khalkotaur', 2, signature('Bull-Head Feint', 'rear', 'the horns commit forward; reach the rear!', 'The bull crashes past.', 'The horns catch you.', { effect = e(79) }))
add('Quasimodo', 2, signature('Crooked Toll', 'face', 'the bell demands your gaze; face it!', 'The crooked rhythm breaks.', 'The toll bends your senses.', { effect = e(80) }))
add('Iku-Turso', 2, signature('Turso Undertow', 'far', 'an undertow gathers; retreat 13 yalms!', 'The current falls short.', 'The undertow drags at your life.', { distance = 13, effect = e(81) }))
add('Kadraeth the Hatespawn', 2, signature('Hate Mirror', 'hold', 'it mirrors hostility; cease attacks!', 'The mirror clouds over.', 'Your hostility returns amplified.', { effect = e(82) }))
add('Dvalinn', 2, signature('Dvergr Measure', 'weaponskill', 'the rune demands a decisive weapon skill!', 'The measured rune fractures.', 'The rune completes its curse.', { effect = e(83) }))
add('Rakshas', 2, signature('Rakshas Pounce', 'near', 'it coils for a distant pounce; close within 5 yalms!', 'The pounce has no room.', 'The pounce mauls you.', { distance = 5, effect = e(84) }))
add('Seps', 2, signature('Venom Line', 'move', 'venom traces your position; move 9 yalms!', 'The venom erupts behind you.', 'The venom line bursts beneath you.', { distance = 9, effect = e(85) }))
add('Xan', 2, signature('Vanishing Point', 'turn', 'its outline flashes; turn away!', 'The false point fades.', 'The flash steals your bearing.', { effect = e(86) }))
add('Chhir Batti', 2, signature('Batti Winglock', 'rear', 'its pinions lock forward; circle behind!', 'The winglock tears itself apart.', 'The pinions catch you.', { effect = e(87) }))
add('Pascerpot', 2, signature('Potent Carapace', 'burst', 'its shell seals; deal 4% HP!', 'The shell fractures.', 'The shell completes its ward.', { damagePct = 4, effect = e(88) }))
add('Gnawtooth Gary', 2, signature('Gnawing Circle', 'far', 'teeth churn in a wide circle; retreat 12 yalms!', 'The bite closes short.', 'The circle gnaws through you.', { distance = 12, effect = e(89) }))
add('Armillaria', 2, signature('Armillary Spores', 'face', 'the cap tries to turn your mind; face it!', 'You resist the hypnotic rhythm.', 'The spores muddle your will.', { effect = e(90) }))
add('Sedna', 2,
    signature('Hydro Blast', 'burst', 'a magic shield swells; deal 4% HP to crack it!', 'The hydro shield collapses.', 'The shield releases a Silence aura.', { damagePct = 4, effect = xi.effect.SILENCE }),
    signature('Hydro Wave', 'hold', 'water absorption begins; cease attacks!', 'The tide reverses and Sedna is exposed.', 'The wave strips your momentum.', { effect = xi.effect.AMNESIA }))
add('Durinn', 2,
    signature('Hellsnap', 'weaponskill', 'an AoE spell is primed; interrupt the rite with a weapon skill!', 'The spell matrix shatters.', 'The matrix completes around you.', { effect = xi.effect.SILENCE }),
    signature('Thundris Shriek', 'far', 'lightning terror expands; retreat 14 yalms!', 'The shriek grounds itself.', 'The shriek terrorizes you.', { distance = 14, effect = xi.effect.TERROR, effectDuration = 6 }))
add('Bukhis', 2,
    signature('Ruinous Scythe', 'move', 'the scythe marks your life-force; move 10 yalms!', 'The ruinous mark is severed.', 'Your maximum vitality buckles.', { distance = 10, effect = xi.effect.CURSE_I, effectDuration = 12 }),
    signature('Apocalyptic Ray', 'turn', 'Doom burns in its eye; turn away!', 'The ray passes and the horn ward breaks.', 'A short Doom falls over you.', { effect = xi.effect.DOOM, effectDuration = 9 }))
add('Karkadann', 2,
    signature('Horned Benediction', 'burst', 'the horn channels a ward; deal 5% HP!', 'The horn’s blessing shatters.', 'The completed ward empowers Karkadann.', { damagePct = 5, effect = xi.effect.PLAGUE }),
    signature('Celestial Charge', 'rear', 'the horn fixes forward; reach its rear!', 'The charge leaves it exposed.', 'The celestial horn impales you.', { effect = xi.effect.TERROR, effectDuration = 5 }))

-- ========================================================================
-- T3: Heroes of Abyssea (42)
-- ========================================================================

-- Altepa
add('Sharabha', 3, signature('Sand-Caked Ambush', 'move', 'the dunes mark your footing; move 11 yalms!', 'The ambush erupts behind you.', 'The sand jaws close on you.', { distance = 11, effect = e(95) }))
add('Chickcharney', 3, signature('Cockatrice Mirror', 'turn', 'its scales mirror your gaze; look away!', 'The mirror cracks.', 'Your own gaze petrifies you.', { effect = xi.effect.PETRIFICATION, effectDuration = 5 }))
add('Emperador de Altepa', 3, signature('Oasis Dominion', 'far', 'the oasis surges outward; retreat 14 yalms!', 'The false oasis evaporates.', 'The oasis drowns your strength.', { distance = 14, effect = e(97) }))
add('Waugyl', 3, signature('Puppet-Blood Feint', 'hold', 'it feigns collapse; cease attacks!', 'The puppet string goes slack.', 'The hidden string returns your attack.', { effect = e(98) }))
add('Shaula', 3, signature('Scorpion Meridian', 'rear', 'the claws and tail cover the front; take the rear!', 'Shaula knots its own tail.', 'The meridian strike finds you.', { effect = e(99), effectTick = 3, punishSkill = 353 }))
add('Tablilla', 3, signature('Mercury Lattice', 'move', 'liquid metal fixes your position; move 10 yalms!', 'The lattice hardens empty.', 'Mercury cages you.', { distance = 10, effect = e(100) }))
add('Vadleany', 3, signature('Ladybird Vortex', 'near', 'the vortex widens; close within 5 yalms!', 'You stand in its calm eye.', 'The vortex strips your footing.', { distance = 5, effect = e(101) }))
add('Amarok', 3, signature('Three-Hide Trial', 'weaponskill', 'three hides overlap; split them with a weapon skill!', 'The layered hides part.', 'The hides fuse into armor.', { effect = e(102) }))
add('Bugul Noz', 3, signature('Sabulous Burial', 'move', 'clay rises beneath you; move 12 yalms!', 'The clay tomb closes empty.', 'The clay buries your actions.', { distance = 12, effect = e(103) }))
add('Ironclad Smiter', 3, signature('Smiter Calibration', 'hold', 'the giant calibrates against attacks; hold fire!', 'Calibration fails.', 'Your attack perfects its aim.', { effect = e(104) }))
add('Orthrus', 3,
    signature('Magma Hoplon', 'burst', 'Blaze Spikes feed its fire magic; deal 5% HP to crack them!', 'The magma shield shatters.', 'Orthrus drinks the fire and heals its fury.', { damagePct = 5, effect = xi.effect.PLAGUE }),
    signature('Howl', 'face', 'Howl resets hate; face Orthrus and brace!', 'You hold its attention through the howl.', 'The reset leaves you exposed.', { effect = xi.effect.TERROR, effectDuration = 5 }))
add('Dragua', 3,
    signature('Terra Wing', 'turn', 'petrifying dust fills its forward arc; turn away!', 'The dust settles without a victim.', 'Stone crawls over your limbs.', { effect = xi.effect.GRADUAL_PETRIFICATION, effectDuration = 8 }),
    signature('Absolute Terror', 'move', 'Dragua fixes you in place; move 11 yalms before the roar!', 'The terror mark breaks.', 'Absolute Terror seizes you.', { distance = 11, effect = xi.effect.TERROR, effectDuration = 7 }))
add('Bennu', 3,
    signature('Dread Wind', 'far', 'a Terror storm gathers; retreat 15 yalms!', 'The storm breaks before reaching you.', 'Dread Wind leaves you open to critical blows.', { distance = 15, effect = xi.effect.TERROR, effectDuration = 5 }),
    signature('Predator Landing', 'rear', 'Bennu dives forward; reach its rear!', 'The landing exhausts Bennu.', 'The dive tears through you.', { effect = xi.effect.AMNESIA, rewardSec = 16 }))
add('Rani', 3,
    signature('Action Absorption', 'hold', 'Rani begins an action and absorbs damage; cease attacks!', 'The absorption window starves.', 'Rani converts your attack into power.', { effect = xi.effect.PLAGUE }),
    signature('Enthrall', 'turn', 'Rani’s eyes glow; turn away from Charm!', 'The enthralling gaze fails.', 'The gaze steals your will.', { effect = xi.effect.TERROR, effectDuration = 8, rewardSec = 16 }))

-- Grauberg
add('Bomblix Flamefinger', 3, signature('Powderfinger Fuse', 'far', 'gunpowder ignites; retreat 14 yalms!', 'The blast falls short.', 'The powder blast engulfs you.', { distance = 14, effect = e(109) }))
add('Ika-Roa', 3, signature('Pugil Undertow', 'near', 'the current lashes outward; close within 5 yalms!', 'You enter the still center.', 'The undertow batters you.', { distance = 5, effect = e(110) }))
add('Minaruja', 3, signature('Pursuer Wing', 'move', 'a hunting shadow fixes your ground; move 11 yalms!', 'The pursuer strikes empty ground.', 'The wing pins you.', { distance = 11, effect = e(111) }))
add('Lorelei', 3, signature('Fay Refrain', 'face', 'the song seeks an unwary mind; face Lorelei!', 'You break the refrain.', 'The refrain silences your thoughts.', { effect = e(112) }))
add('Xibalba', 3, signature('Decaying Molar', 'rear', 'the jaws commit forward; circle behind!', 'The bite snaps empty.', 'The molars crush you.', { effect = e(113) }))
add('Teugghia', 3, signature('Unseelie Bargain', 'weaponskill', 'the bargain demands decisive force; use a weapon skill!', 'The bargain is rejected.', 'The unseelie price is taken.', { effect = e(114) }))
add('Ningishzida', 3, signature('Three-Trophy Ward', 'burst', 'three trophies form a ward; deal 5% HP!', 'The trophies shatter.', 'The completed ward hardens the wyrm.', { damagePct = 5, effect = e(115) }))
add('Burstrox Powderpate', 3, signature('Goblin Rope Fuse', 'move', 'a powder keg is lashed to your position; move 12 yalms!', 'The keg detonates behind you.', 'The rope holds you in the blast.', { distance = 12, effect = e(116) }))
add('Teekesselchen', 3, signature('Bubbling Pressure', 'hold', 'the kettle seals under pressure; cease attacks!', 'The pressure vents safely.', 'Your strike ruptures the kettle.', { effect = e(117) }))
add('Ironclad Sunderer', 3, signature('Darkflame Sunder', 'far', 'darkflame expands from the arm; retreat 15 yalms!', 'The flame gutters out.', 'The sundered flame consumes your guard.', { distance = 15, effect = e(118) }))
add('Alfard', 3,
    signature('Serpentine Front', 'rear', 'poison and curse flood its front; take the rear!', 'You find the narrow safe angle.', 'The frontal aura corrupts you.', { effect = xi.effect.CURSE_I }),
    signature('Tail Reversal', 'face', 'the tail punishes the rear; return to its face!', 'The tail sweeps empty ground.', 'The reversal paralyzes you.', { effect = xi.effect.PARALYSIS }))
add('Azdaja', 3,
    signature('Rotating Breath Aura', 'rear', 'the current breath aura gathers forward; take the rear!', 'The aura misses and the wings sag.', 'The breath aura brands you.', { effect = xi.effect.PLAGUE }),
    signature('Spike Flail', 'near', 'the tail rises; close within 6 yalms and face the wyrm!', 'You crowd inside the flail arc.', 'Spike Flail hurls you aside.', { distance = 6, effect = xi.effect.TERROR, effectDuration = 5 }))
add('Raja', 3,
    signature('Royal Decree', 'weaponskill', 'support is being sealed; break the decree with a weapon skill!', 'The decree fractures.', 'Your arts are briefly sealed.', { effect = xi.effect.AMNESIA, effectDuration = 10 }),
    signature('Stygian Sphere', 'burst', 'matching stoneskin forms; deal 5% HP to crack it!', 'The sphere bursts and Raja is exposed.', 'The sphere completes its protection.', { damagePct = 5, effect = xi.effect.SILENCE, rewardSec = 16 }))
add('Amphitrite', 3,
    signature('Physical Absorption', 'hold', 'the shell prepares to absorb force; cease attacks!', 'The shell opens unfed.', 'Your force is swallowed.', { effect = xi.effect.SLOW }),
    signature('Delayed Reversal', 'weaponskill', 'the shell changes mode; wait for the tell, then weapon skill!', 'The delayed opening is struck.', 'The reversal catches your timing.', { effect = xi.effect.PARALYSIS, rewardSec = 16 }))

-- Uleguerand
add('Ironclad Triturator', 3, signature('Triturating Beam', 'move', 'a beam grid fixes your ground; move 12 yalms!', 'The beam grinds empty ice.', 'The grid pulverizes you.', { distance = 12, effect = e(123) }))
add('Dhorme Khimaira', 3, signature('Torn-Wing Fulmination', 'far', 'the torn wing crackles; retreat 15 yalms!', 'The charge grounds out.', 'Fulmination catches you.', { distance = 15, effect = e(124) }))
add('Blanga', 3, signature('Rimed Sentry', 'turn', 'the sentry horn flashes; turn away!', 'The signal loses its target.', 'The rime freezes your reactions.', { effect = e(125) }))
add('Yaguarogui', 3, signature('Black-Tiger Vector', 'rear', 'the tiger commits to a forward vector; reach the rear!', 'The vector carries it past.', 'The rush mauls you.', { effect = e(126) }))
add('Koghatu', 3, signature('Bevel-Gear Lock', 'burst', 'gears mesh into armor; deal 5% HP!', 'The gear train jams.', 'The lock completes.', { damagePct = 5, effect = e(127) }))
add('Upas-Kamuy', 3, signature('Snow-God Core', 'near', 'the blizzard expands outward; close within 5 yalms!', 'You enter the eye of the storm.', 'The blizzard freezes your will.', { distance = 5, effect = e(128) }))
add('Veri Selen', 3, signature('Ice-Scale Refraction', 'hold', 'the scales refract attacks; cease fire!', 'The refraction fades.', 'Your attack returns as ice.', { effect = e(129) }))
add('Chillwing Hwitti', 3, signature('Rimed Wingbeat', 'far', 'rimed wings drive a freezing front; retreat 14 yalms!', 'The front shatters short.', 'The rime locks your actions.', { distance = 14, effect = e(130) }))
add('Anemic Aloysius', 3, signature('Anemic Exchange', 'highhp', 'it seeks weakened blood; recover above 70% HP!', 'Your vitality rejects the exchange.', 'Aloysius siphons your weakness.', { hpp = 70, effect = e(131) }))
add('Audumbla', 3, signature('Frozen Stampede', 'move', 'the herd-line marks your position; move 11 yalms!', 'The stampede passes behind.', 'The frozen herd tramples you.', { distance = 11, effect = e(132) }))
add('Pantokrator', 3,
    signature('Action Absorption', 'hold', 'Omega absorbs damage while acting; cease attacks!', 'The absorption starves and its frame opens.', 'Your attack repairs the frame.', { effect = xi.effect.PLAGUE }),
    signature('Stance Exhaustion', 'far', 'Chainspell and Hundred Fists peak; retreat 15 yalms!', 'Pantokrator exhausts its stance.', 'The stance burst overwhelms you.', { distance = 15, effect = xi.effect.TERROR, effectDuration = 6, rewardSec = 18 }))
add('Isgebind', 3,
    signature('Gregale Wing', 'burst', 'an ice plume sustains a Paralyze aura; deal 5% HP!', 'The plume shatters.', 'The aura freezes your nerves.', { damagePct = 5, effect = xi.effect.PARALYSIS }),
    signature('Glacial Breath', 'rear', 'the breath fixes forward; take the rear!', 'The breath misses and the wyrm pants.', 'Glacial Breath entombs you.', { effect = xi.effect.PETRIFICATION, effectDuration = 5 }))
add('Apademak', 3,
    signature('Lightning Level', 'hold', 'lightning would level it up; cease attacks during the charge!', 'The charge grounds without feeding.', 'Apademak gains a Fulmination level.', { effect = xi.effect.PARALYSIS }),
    signature('Fulmination Rod', 'burst', 'a lightning rod overloads; deal 5% HP to discharge it!', 'The stored level discharges safely.', 'Fulmination detonates around you.', { damagePct = 5, effect = xi.effect.TERROR, effectDuration = 6 }))
add('Resheph', 3,
    signature('Meikyo Chain', 'far', 'a three-move chain begins; retreat 15 yalms!', 'The chain spends itself at range.', 'The chained techniques tear through you.', { distance = 15, effect = xi.effect.AMNESIA }),
    signature('Tarsal Slam', 'highhp', 'the Slam will leave you at death’s edge; recover above 75% HP!', 'You endure the slam and its follow-up falters.', 'The follow-up finds you broken.', { hpp = 75, effect = xi.effect.TERROR, effectDuration = 5, rewardSec = 18 }))

-- ========================================================================
-- 2026-07-19 HP-audit additions (16): these logical NMs have marks-zone ???s
-- but were never catalogued, so spawnViaMark errored on the nil encounter and
-- the pcall fallback silently routed them to the STOCK free pop at DB HP
-- (4.8k-9.7k -- one weapon skill). Catalogue them so the marks pop applies
-- the real tier profile like their peers.
-- APPEND ONLY: entry order defines encounter.index, which keys the AbyNM_%03d
-- first-clear stamps -- inserting above this line would corrupt player records.
-- ========================================================================

-- Konschtat (T1)
add('Meanderer', 1, signature('Vagrant Ooze', 'move', 'the ooze pools beneath you; move at least 8 yalms!', 'The pool congeals on empty ground.', 'The ooze swallows your footing.', { distance = 8, effect = e(137) }))
add('Pavan', 1, signature('Restless Gale', 'far', 'the winds spiral inward; retreat beyond 12 yalms!', 'The gale collapses on itself.', 'The vortex flays you.', { distance = 12, effect = e(138) }))
add('Hadal Satiator', 1, signature('Abyssal Appetite', 'highhp', 'it hungers for the weak; recover above 70% HP!', 'Your vigor spoils its meal.', 'The satiator feeds well.', { hpp = 70, effect = e(139) }))
add('Hadal Mirror', 1, signature('Mirrored Skin', 'hold', 'its skin turns reflective; cease attacks!', 'The mirror clouds over.', 'Your own blow returns twofold.', { effect = e(140) }))
add('Lesser Arimaspi', 1, signature('Lesser Lens', 'turn', 'its eye clouds over; turn away!', 'The lens fractures.', 'The lens sears your sight.', { effect = e(141) }))

-- Tahrongi (T1)
add('Hungerer', 1, signature('Devouring Maw', 'near', 'the maw inhales; close inside 6 yalms to dodge the pull!', 'You slip beneath the intake.', 'The maw drags you in.', { distance = 6, effect = e(142) }))
add('Myrmecoleon', 1, signature('Gravitic Horn', 'move', 'gravity fixes your position; move at least 8 yalms!', 'The horn tears through empty ground.', 'The gravitic charge catches you.', { distance = 8, effect = xi.effect.WEIGHT, punishSkill = 2516 }))

-- La Theine (T1)
add('Brooder', 1, signature('Hatching Swarm', 'burst', 'the brood stirs; deal 3% of its HP before it hatches!', 'The clutch dies unhatched.', 'The swarm erupts across you.', { damagePct = 3, effect = e(143) }))

-- Attohwa (T2)
add('Tunga', 2, signature('Sporomycosis', 'far', 'the cap swells with spores; retreat beyond 12 yalms!', 'The cloud settles on barren ground.', 'You breathe the blooming rot.', { distance = 12, effect = e(144) }))
add('Amun', 2, signature('Petrifying Gaze', 'face', 'its gaze hardens; face it and hold fast!', 'You outstare the cockatrice.', 'Your limbs begin to stone.', { effect = e(145) }))

-- Misareaux (T2)
add('Heqet', 2, signature('Toxic Croak', 'hold', 'the croak feeds on violence; cease attacks!', 'The croak dies in its throat.', 'The croak crescendos through you.', { effect = e(146) }))
add('Abyssic Cluster', 2, signature('Triple Detonation', 'far', 'all three bombs ignite; retreat beyond 13 yalms!', 'The blast spends itself on nothing.', 'The detonation engulfs you.', { distance = 13, effect = e(147) }))

-- Vunkerl (T2)
add('Fulmotondro', 2, signature('Ground Current', 'move', 'lightning grounds where you stand; move at least 9 yalms!', 'The current dies in the dirt.', 'The current climbs your spine.', { distance = 9, effect = e(148) }))
add('Ketea', 2, signature('Tail Breach', 'rear', 'it rears to breach; take the rear!', 'The breach crashes down ahead of you.', 'The tail hammers you flat.', { effect = e(149) }))
add('Lord Varney', 2, signature('Sanguine Invitation', 'weaponskill', 'the invitation beckons; refuse it with a weapon skill!', 'Steel answers the invitation.', 'You drift toward the outstretched hand.', { effect = e(150) }))
add('Hanuman', 2, signature('Mocking Caper', 'turn', 'it mimics your stance; turn away!', 'The mimicry finds no model.', 'Your own form is turned against you.', { effect = e(151) }))

-- Uleguerand (T3)
add('Ogopogo', 3, signature('Abyssal Undertow', 'far', 'the water coils to drag you under; retreat 15 yalms!', 'The undertow breaks on the shallows.', 'The deep claims you.', { distance = 15, effect = e(152) }))

C.entries = entries
C.ordered = ordered
C.normalize = normalize

function C.get(name)
    return entries[normalize(name)]
end

function C.count(tier)
    local total = 0
    for _, entry in ipairs(ordered) do
        if not tier or entry.tier == tier then
            total = total + 1
        end
    end
    return total
end

-- Fail module load loudly if a roster edit accidentally drops a logical NM.
-- The original planning audit reported 135 (45/48/42), but the live QM files
-- contain a seventeenth Attohwa NM, Pallid Percy: 136 (45/49/42).
-- 2026-07-19 HP audit added 16 uncatalogued marks-zone NMs (7/8/1).
-- Myrmecoleon's missing Tahrongi spawn was restored afterward: 153 (53/57/43).
assert(C.count(1) == 53, string.format('Visions encounter count drifted: %d', C.count(1)))
assert(C.count(2) == 57, string.format('Scars encounter count drifted: %d', C.count(2)))
assert(C.count(3) == 43, string.format('Heroes encounter count drifted: %d', C.count(3)))
assert(C.count() == 153, string.format('Abyssea encounter count drifted: %d', C.count()))

return C
