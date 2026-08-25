-----------------------------------
-- Legendary Weapon Pilgrimage catalog
--
-- Data-only definitions for the 78 three-chapter weapon pilgrimages.  Targets
-- are existing server content; no objective depends on a fictional encounter.
-----------------------------------
local forge = require('modules/custom/lua/weapon_forge_catalog')
local rema  = require('modules/custom/lua/rema_ws_tier_catalog')
local prime = require('modules/custom/lua/prime_ws_tuning_catalog')

local C = {}

C.MAX_ACTIVE       = 2
C.LOWER_WS_CAP     = 149999
C.GRANTED_MAIN_WS_VAR   = 'LWP_GrantedMainWS'
C.GRANTED_RANGED_WS_VAR = 'LWP_GrantedRangedWS'
C.PRIME_ENTRY_VAR       = 'WF_Aeonic_Final'
C.NYZUL_SPECIFIED_ENEMY = 4 -- xi.nyzul.objective.ELIMINATE_SPECIFIED_ENEMY
C.FAMILY_COUNTS    = { relic = 14, empyrean = 14, mythic = 22, aeonic = 14, prime = 14 }
C.FINAL_MARKS      = { relic = 1000, empyrean = 1500, mythic = 2000, aeonic = 2000, prime = 5000 }
C.UTILITY_WS       = { [xi.weaponskill.DAGAN] = 'dagan', [xi.weaponskill.MYRKR] = 'myrkr', [xi.weaponskill.ATONEMENT] = 'atonement' }
C.ARCHETYPES =
{
    ['Hand-to-Hand'] = 'h2h_hit_chain', ['Dagger'] = 'dagger_positional',
    ['Sword'] = 'sword_tactical', ['Great Sword'] = 'great_sword_burst_survival',
    ['Axe'] = 'axe_companion', ['Great Axe'] = 'great_axe_armor',
    ['Scythe'] = 'scythe_resource', ['Polearm'] = 'polearm_aerial',
    ['Katana'] = 'katana_shadows', ['Great Katana'] = 'great_katana_skillchain',
    ['Club'] = 'club_support', ['Staff'] = 'staff_magic',
    ['Archery'] = 'bow_distance', ['Marksmanship'] = 'gun_tactical',
}
C.ECOLOGIES =
{
    xi.ecosystem.AMORPH, xi.ecosystem.AQUAN, xi.ecosystem.ARCANA,
    xi.ecosystem.BEAST, xi.ecosystem.BEASTMEN, xi.ecosystem.BIRD,
    xi.ecosystem.DEMON, xi.ecosystem.DRAGON, xi.ecosystem.ELEMENTAL,
    xi.ecosystem.HUMANOID, xi.ecosystem.LIZARD, xi.ecosystem.PLANTOID,
    xi.ecosystem.UNDEAD, xi.ecosystem.VERMIN,
}
C.ECOLOGY_NAMES =
{
    [xi.ecosystem.AMORPH] = 'Amorph', [xi.ecosystem.AQUAN] = 'Aquan',
    [xi.ecosystem.ARCANA] = 'Arcana', [xi.ecosystem.BEAST] = 'Beast',
    [xi.ecosystem.BEASTMEN] = 'Beastmen', [xi.ecosystem.BIRD] = 'Bird',
    [xi.ecosystem.DEMON] = 'Demon', [xi.ecosystem.DRAGON] = 'Dragon',
    [xi.ecosystem.ELEMENTAL] = 'Elemental', [xi.ecosystem.HUMANOID] = 'Humanoid',
    [xi.ecosystem.LIZARD] = 'Lizard', [xi.ecosystem.PLANTOID] = 'Plantoid',
    [xi.ecosystem.UNDEAD] = 'Undead', [xi.ecosystem.VERMIN] = 'Vermin',
}

-- Real, currently implemented named-content bands.
C.TARGETS =
{
    divergence =
    {
        'Disjoined Elvaan', 'Disjoined Galka', 'Disjoined Tarutaru', 'Disjoined Mithra',
    },
    unity =
    {
        'Muut', 'Voso', 'Beist', 'Lumber Jill', 'Largantua', 'Garbage Gel',
        'King Uropygid', 'Vedrfolnir', 'Glazemane', 'Volatile Cluster', 'Strix',
        'Sovereign Behemoth', 'Arke', 'Douma Weapon', 'Kubool Jas Mhuufya',
        'Thuban', 'Specter Worm', 'Bakunawa', 'Mephitas', 'Vidmapire', 'Shedu',
        'Tumult Curator', 'Azure-toothed Clawberry', 'Centurio XX-I',
        'Wyvernhunter Bambrox', 'Tolba',
    },
    abyssea =
    {
        'Glavoid', 'Lacovie', 'Chloris', 'Carabosse', 'Briareus', 'Hadhayosh',
        'Ulhuadshi', 'Titlacauan', 'Itzpapalotl', 'Amhuluk', 'Cirein-croin', 'Sobek',
        'Sedna', 'Durinn', 'Bukhis', 'Orthrus', 'Dragua', 'Bennu', 'Rani', 'Alfard',
        'Azdaja', 'Raja', 'Pantokrator', 'Isgebind', 'Apademak', 'Resheph',
    },
    voidwatch =
    {
        'Krabkatoa', 'Yacumama', 'Raker Bee', 'Farruca Fly', 'Skuld', 'Gorehound',
        'Blobdingnag', 'Shoggoth', 'Capricornus', 'Lamprey Lord', 'Jyeshtha', 'Dawon',
        'Gjenganger', 'Feuerunke', 'Tammuz', 'Aglaophotis', 'Erebus', 'Yilbegan',
        'Lord Ruthven',
    },
    geasT3 =
    {
        'Fleetstalker', 'Shockmaw', 'Urmahlullu', 'Alpluachra', 'Bucca', 'Puca',
        'Blazewing', 'Pazuzu', 'Wrathare', 'Voso', 'Pakecet', 'Duke Vepar',
        "Vir'ava", 'Ark Angel EV', 'Ark Angel GK', 'Ark Angel HM', 'Ark Angel MR',
        'Ark Angel TT', 'Byakko-Escha', 'Genbu-Escha', 'Seiryu-Escha',
        'Suzaku-Escha', 'Kirin', 'Kouryu', 'Maju', 'Yakshi', 'Neak',
    },
    geasT4 =
    {
        'Azi Dahaka', 'Warder of Courage', 'Teles', 'Zerde', 'Vinipata', 'Schah',
        'Albumen', 'Onychophora', 'Erinys',
    },
    elite =
    {
        'Kirin', 'Tinnin', 'Hadhayosh', 'Maat', 'Azi Dahaka', 'Warder of Courage',
        'Teles', 'Zerde', 'Vinipata', 'Schah', 'Albumen', 'Onychophora', 'Erinys',
    },
}

C.TARGETS.primeElite = {}
for _, source in ipairs({ C.TARGETS.geasT3, C.TARGETS.geasT4 }) do
    for _, name in ipairs(source) do C.TARGETS.primeElite[#C.TARGETS.primeElite + 1] = name end
end
for index = 13, #C.TARGETS.voidwatch do
    C.TARGETS.primeElite[#C.TARGETS.primeElite + 1] = C.TARGETS.voidwatch[index]
end

C.TARGETS.primeEndgame = {}
for _, name in ipairs(C.TARGETS.geasT4) do
    C.TARGETS.primeEndgame[#C.TARGETS.primeEndgame + 1] = name
end

local function normalize(name)
    return (name or ''):lower():gsub('[^a-z0-9]', '')
end
C.normalizeName = normalize

local function rotated(source, first, count)
    local out = {}
    for offset = 0, count - 1 do
        out[#out + 1] = source[((first + offset - 2) % #source) + 1]
    end
    return out
end

local remaByFinal = rema.BY_ITEM_ID
local primeByFinal = {}
for wsId, entry in pairs(prime.PRIME_WS_TUNING) do
    primeByFinal[entry.itemId] = { wsId = wsId, name = entry.name, slot = entry.slot }
end

local signatureByMaterial =
{
    [3287] = 'Orthrus', [3288] = 'Dragua', [3289] = 'Apademak',
    [3290] = 'Isgebind', [3291] = 'Alfard', [3292] = 'Azdaja',
}

C.chains, C.byIndex, C.byFinalId = {}, {}, {}

local function objective(kind, count, targets, distinct, extra)
    local value = { kind = kind, count = count, targets = targets, distinct = distinct == true }
    for key, setting in pairs(extra or {}) do value[key] = setting end
    return value
end

local function archetypeRule(weaponType, index)
    local key = C.ARCHETYPES[weaponType]
    local rules =
    {
        h2h_hit_chain               = { minTp = 1200 + ((index - 1) % 3) * 200 },
        dagger_positional           = { behind = true },
        sword_tactical              = { minTp = 1600 + ((index - 1) % 3) * 200 },
        great_sword_burst_survival  = {},
        axe_companion               = { petOrBerserk = true },
        great_axe_armor             = {},
        scythe_resource             = { maxHpp = 60 - ((index - 1) % 3) * 5 },
        polearm_aerial              = { petAlive = true, minTp = 1200 + ((index - 1) % 3) * 200 },
        -- Katana pilgrimage credit is the exact native-WS killing blow. The
        -- previous copy-image requirement proved unreliable at death-event
        -- time even when the player visibly retained an Utsusemi shadow.
        katana_shadows              = {},
        great_katana_skillchain     = { minTp = 1800 + ((index - 1) % 3) * 200 },
        club_support                = { maxHpp = 80 - ((index - 1) % 3) * 5 },
        staff_magic                 = { maxMpp = 60 - ((index - 1) % 3) * 5 },
        bow_distance                = { minDistance = 14 + ((index - 1) % 3) * 2 },
        gun_tactical                = { minDistance = 10 + ((index - 1) % 3) * 2, minTp = 1200 + ((index - 1) % 3) * 200 },
    }
    local rule = rules[key]
    rule.key = key
    return rule
end

function C.archetypePass(attacker, target, rule, tp)
    local function livingPet()
        local pet = attacker:getPet()
        return pet ~= nil and pet:getHP() > 0
    end
    if rule.minTp and tp < rule.minTp then return false end
    if rule.behind and not attacker:isBehind(target, 48) then return false end
    if rule.maxHpp and attacker:getHPP() > rule.maxHpp then return false end
    if rule.maxMpp and attacker:getMPP() > rule.maxMpp then return false end
    if rule.minDistance and attacker:checkDistance(target) < rule.minDistance then return false end
    if rule.petAlive and not livingPet() then return false end
    if rule.petOrBerserk and not livingPet() and not attacker:hasStatusEffect(xi.effect.BERSERK) then
        return false
    end
    return true
end

local function add(family, source, index, stages, finalId)
    local ws = family == 'prime' and primeByFinal[finalId] or remaByFinal[finalId]
    assert(ws, string.format('Pilgrimage missing native WS for final item %d', finalId))
    local entry =
    {
        index       = #C.chains + 1,
        family      = family,
        familyIndex = index,
        name        = source.name,
        jobs        = source.jobs,
        weaponType  = source.type,
        archetype   = C.ARCHETYPES[source.type],
        archetypeRule = archetypeRule(source.type, index),
        wsId        = ws.wsId,
        wsName      = ws.name,
        slot        = ws.slot,
        stages      = stages,
        finalId     = finalId,
        singleStep  = source.singleStep == true,
    }

    if family == 'relic' then
        entry.chapters =
        {
            objective('ws_kills', 60 + ((index - 1) % 3) * 10, nil, false,
                {
                    tag = 'magian_family',
                    ecosystems = rotated(C.ECOLOGIES, index, 3),
                    minLevel = 99,
                }),
            objective('named_ws_kills', 6 + ((index - 1) % 5), rotated(C.TARGETS.unity, index, 10), true, { tag = 'unity_nm' }),
            objective('named_ws_kills', 4, C.TARGETS.divergence, true, { tag = 'divergence_disjoined' }),
        }
    elseif family == 'empyrean' then
        local utility = C.UTILITY_WS[entry.wsId]
        local function supportObjective(count, targets, distinct, tag)
            local values = utility == 'dagan'
                and { utility = utility, hpBelow = 35, restore = 1500, tag = tag }
                or { utility = utility, mpBelow = 10, restore = 900, tag = tag }
            return objective('support_ws', count, targets, distinct, values)
        end
        entry.chapters =
        {
            utility and supportObjective(8, rotated(C.TARGETS.abyssea, index, 12), true, 'abyssea_support')
                or objective('ws_kills', 70 + ((index - 1) % 3) * 10, nil, false,
                    { tag = 'abyssea_ecology', ecosystems = rotated(C.ECOLOGIES, index + 4, 3) }),
            utility and supportObjective(8 + ((index - 1) % 5),
                rotated(C.TARGETS.abyssea, index, 12), true, 'abyssea_nm')
                or objective('named_ws_kills', 8 + ((index - 1) % 5),
                    rotated(C.TARGETS.abyssea, index, 12), true, { tag = 'abyssea_nm' }),
            utility and supportObjective(3, { signatureByMaterial[source.mat] }, false, 'signature_material_nm')
                or objective('named_ws_kills', 3, { signatureByMaterial[source.mat] }, false,
                    { tag = 'signature_material_nm' }),
        }
    elseif family == 'mythic' then
        local utility = C.UTILITY_WS[entry.wsId]
        entry.chapters =
        {
            utility == 'atonement'
                and objective('support_ws', 8, rotated(C.TARGETS.voidwatch, index, 8), true,
                    { utility = utility, positiveDamage = true })
                or objective('ws_kills', 25 + ((index - 1) % 4) * 5, nil, false,
                    { tag = 'job_mastery', mainJobRequired = true }),
            objective('nyzul_objectives', 5, nil, false,
                { tag = 'nyzul_specified_enemy', objectiveKind = C.NYZUL_SPECIFIED_ENEMY }),
            objective('named_ws_kills', 3, rotated(C.TARGETS.voidwatch, index + 10, 3), true, { tag = 'imperial_final_targets' }),
        }
    elseif family == 'aeonic' then
        entry.chapters =
        {
            objective('named_ws_kills', 8, rotated(C.TARGETS.geasT3, index, 8), true, { tag = 'geas_t3' }),
            objective('named_ws_kills', 2, rotated(C.TARGETS.geasT4, index, 2), true, { tag = 'geas_t4' }),
            objective('named_ws_kills', 2, rotated(C.TARGETS.geasT4, index + 2, 2), true, { tag = 'geas_t4' }),
        }
    else
        entry.chapters =
        {
            objective('named_ws_kills', 20 + ((index - 1) % 3) * 5,
                rotated(C.TARGETS.primeElite, index, 30), true, { tag = 'elite' }),
            objective('named_ws_kills', 3, rotated(C.TARGETS.primeEndgame, index, 3), true, { tag = 'geas_t4' }),
            objective('named_ws_kills', 2, rotated(C.TARGETS.primeEndgame, index + 3, 2), true, { tag = 'geas_t4' }),
        }
    end

    for _, chapter in ipairs(entry.chapters) do
        if chapter.kind == 'ws_kills' or chapter.kind == 'named_ws_kills' then
            chapter.archetypeRule = entry.archetypeRule
        end
    end

    C.chains[#C.chains + 1] = entry
    C.byIndex[entry.index] = entry
    C.byFinalId[finalId] = entry
end

for index, chain in ipairs(forge.relicChains) do
    add('relic', chain, index, { chain.base, chain.s1, chain.s2 }, chain.s3)
end
for index, chain in ipairs(forge.empyreanChains) do
    add('empyrean', chain, index, { chain.base, chain.s1, chain.s2 }, chain.s3)
end
for index, chain in ipairs(forge.mythicChains) do
    add('mythic', chain, index,
        chain.singleStep and { chain.base, chain.base, chain.base } or { chain.base, chain.s1, chain.s2 },
        chain.s3)
end
for index, chain in ipairs(forge.chains) do
    add('aeonic',
        { name = chain.aeonic.s3.name, jobs = chain.jobs, type = chain.type },
        -- Aeonic pilgrimage is state-driven. The former 297xx intermediary
        -- tokens have no client DAT/equipment records and must never be issued.
        index, { 0, 0, 0 }, chain.aeonic.s3.id)
end
for index, chain in ipairs(forge.chains) do
    -- The live Prime route begins at Ajja (119 I), so Chapters I and II are
    -- sequential on that exact stage; Chapter III is bound to 119 II.
    add('prime',
        { name = chain.s3.name, jobs = chain.jobs, type = chain.type },
        index, { chain.s1.id, chain.s1.id, chain.s2.id }, chain.s3.id)
end

function C.progressVar(index, chapter)
    return string.format('LWP_%02d_C%d', index, chapter)
end

function C.maskVar(index, chapter)
    return string.format('LWP_%02d_M%d', index, chapter)
end

function C.entryUnlocked(player, entry)
    return entry.family ~= 'prime'
        or (player:getCharVar(C.PRIME_ENTRY_VAR) or 0) == 1
end

function C.done(player, entry, chapter)
    return (player:getCharVar(C.progressVar(entry.index, chapter)) or 0) >= entry.chapters[chapter].count
end

function C.chapter(player, entry)
    for chapter = 1, 3 do
        if not C.done(player, entry, chapter) then return chapter end
    end
    return 4
end

function C.isComplete(player, finalId)
    local entry = C.byFinalId[finalId]
    return entry ~= nil and C.chapter(player, entry) == 4
end

function C.targetIndex(requirement, name)
    local wanted = normalize(name)
    for index, target in ipairs(requirement.targets or {}) do
        if normalize(target) == wanted then return index end
    end

    -- Instanced Divergence mobs have no packetName and expose internal names
    -- such as Disjoined_Elvaan_D. The client-visible catalog name omits the
    -- instance suffix, so canonicalize it only for this objective family.
    if requirement.tag == 'divergence_disjoined' then
        wanted = normalize((name or ''):gsub('_[dD]$', ''))
        for index, target in ipairs(requirement.targets or {}) do
            if normalize(target) == wanted then return index end
        end
    end

    return nil
end

return C
