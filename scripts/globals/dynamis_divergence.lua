-----------------------------------
-- Dynamis - Divergence -- shared engine (relaunch custom)
--
-- One engine drives all four Dynamis [D] instances. Each zone's
-- instances/<name>.lua supplies a CONFIG table (mob IDs, unlock slot, exit point)
-- and delegates its instance callbacks here, so the wave / timer / unlock logic
-- lives in exactly one place and scales to all four cities.
--
-- Loop: enter -> Wave 1 (Squadron trash + time-extension statues + Mid-Boss)
--             -> Wave 2 (Regiment trash + Mega-Boss) -> complete -> slot unlock.
-- Statue kill = +1 min, Mid/Mega-Boss = +30 min (capped at 120). Medals drop from
-- the mobs themselves via mob_droplist (modules/custom/sql/dynamis_divergence.sql).
--
-- Entry is currency-trade + createInstance from the entry NPC (relaunch-friendly,
-- solo allowed). This engine only owns what happens once you are inside.
-----------------------------------
xi = xi or {}
xi.divergence = xi.divergence or {}

-- Boss-mechanics library (drain / aoe / cc / stance / phases / doom / enrage).
-- Attach at each SpawnMob() below, tick every second via onInstanceTimeUpdate.
-- These bosses are STATIC (SQL-backed mob_groups + instance_entities), so we
-- can't use the dynamic-entity onMobFight/onMobDeath wiring the library docs
-- describe -- attach + engine-tick + no-cleanup covers the same ground here
-- (attach re-inits state on every run, so stale mid-fight state can't survive).
local mechanics = require('modules/custom/lua/mob_mechanics_library')

local TIME_CAP_MIN  = 120
local STATUE_EXTEND = 1
local BOSS_EXTEND   = 30
local MEGA_EXTEND   = 15
local EXIT_DELAY_MS = 8000

-- Superior Lv5 (Dynamis Divergence) weapons -- their retail home. On EVERY
-- Mega-Boss kill, SU5_DROPS_PER_KILL random weapon(s) from this pool land in
-- the treasure pool for the whole run to lot. (Owner decision 2026-07-12:
-- moved here from the removed any-Abyssea-mob 5% roll in
-- abyssea_su5_drops.lua.) The docgen dynamis_divergence.py PARSES this table
-- (id/name/slot/job fields) -- keep the row shape.
local SU5_DROPS_PER_KILL = 1
local SU5_WEAPONS =
{
    { id = 21878, name = 'Aram',          slot = 'Polearm',      job = 'DRG' },
    { id = 22035, name = 'Asclepius',     slot = 'Club',         job = 'WHM' },
    { id = 21578, name = 'Barfawc',       slot = 'Dagger',       job = 'BRD' },
    { id = 22038, name = 'Bhima',         slot = 'Club',         job = 'GEO' },
    { id = 21627, name = 'Crocea Mors',   slot = 'Sword',        job = 'RDM' },
    { id = 22096, name = 'Draumstafir',   slot = 'Staff',        job = 'SMN' },
    { id = 21825, name = 'Father Time',   slot = 'Scythe',       job = 'DRK' },
    { id = 21917, name = 'Fudo Masamune', slot = 'Katana',       job = 'NIN' },
    { id = 21970, name = 'Fusenaikyo',    slot = 'Great Katana', job = 'SAM' },
    { id = 21575, name = 'Gandring',      slot = 'Dagger',       job = 'THF' },
    { id = 22093, name = 'Kaumodaki',     slot = 'Staff',        job = 'BLM' },
    { id = 21774, name = 'Labraunda',     slot = 'Great Axe',    job = 'WAR' },
    { id = 21630, name = 'Moralltach',    slot = 'Sword',        job = 'PLD' },
    { id = 21669, name = 'Morgelai',      slot = 'Great Sword',  job = 'RUN' },
    { id = 22099, name = 'Musa',          slot = 'Staff',        job = 'SCH' },
    { id = 21717, name = 'Pangu',         slot = 'Axe',          job = 'BST' },
    { id = 21581, name = 'Rostam',        slot = 'Dagger',       job = 'COR' },
    { id = 21523, name = 'Sagitta',       slot = 'Hand-to-Hand', job = 'MNK' },
    { id = 21584, name = 'Setan Kober',   slot = 'Dagger',       job = 'DNC' },
    { id = 22149, name = 'Sharanga',      slot = 'Marksmanship', job = 'RNG' },
    { id = 21526, name = 'Xiucoatl',      slot = 'Hand-to-Hand', job = 'PUP' },
    { id = 21633, name = 'Zomorrodnegar', slot = 'Sword',        job = 'BLU' },
}

-- Armor slot -> bit in the player's 'DivergenceSlots' charVar.
-- Body reforge unlocks once all four (1|2|4|8 = 15) are set.
xi.divergence.slotBit = { feet = 1, hands = 2, head = 4, legs = 8 }

local function tell(instance, msg)
    for _, p in pairs(instance:getChars()) do
        p:printToPlayer(msg, xi.msg.channel.SYSTEM_3)
    end
end

-- A pre-loaded instance entity reads as "not alive" before it is spawned.
-- This helper is therefore only for the statues, which are all spawned during
-- instance creation. Boss progression uses the armed/seen-alive guard below.
local function isDead(instance, mobid)
    local mob = GetMobByID(mobid, instance)
    return mob ~= nil and not mob:isAlive()
end

local function bossStateKey(role, state)
    return string.format('divBoss%s%s', state, role)
end

-- A boss can only count as defeated after this run has observed it alive.
-- Instance entities exist before SpawnMob() and report not-alive in that state;
-- accepting that as a kill caused deferred Mega/Disjoined slots to auto-clear.
local function isBossDefeated(instance, mobid, role)
    local mob = GetMobByID(mobid, instance)
    if mob and mob:isAlive() then
        instance:setLocalVar(bossStateKey(role, 'Seen'), 1)
    end

    return
        instance:getLocalVar(bossStateKey(role, 'Seen')) == 1 and
        instance:getLocalVar(bossStateKey(role, 'Killed')) == 1
end

-- Public for focused regression tests and instance diagnostics.
xi.divergence.isBossDefeated = isBossDefeated

-- Apply a boss's stat baseline (absolute HP + mods override). Mirrors the
-- Hunting-League NM pattern (HuntingLeague.lua ~890): setMod overrides the
-- pool-derived value, then setMaxHP + setHP resize the health bar in one shot.
-- Runs BEFORE mechanics.attach so the mechanics library records the correct
-- starting HP for phase-transition thresholds.
local function applyStats(mob, stats)
    if not stats then return end
    if stats.mods then
        for modId, value in pairs(stats.mods) do
            mob:setMod(modId, value)
        end
    end
    if stats.hp then
        mob:setMaxHP(stats.hp)
        mob:setHP(stats.hp)
    end
end

-- Attach a boss's stat baseline + mechCfg (from xi.divergence.bossMechCfgs)
-- right after its SpawnMob(). A missing cfg is a silent no-op so we can add
-- mechs incrementally.
local function attachBoss(instance, mobId)
    local cfg = xi.divergence.bossMechCfgs and xi.divergence.bossMechCfgs[mobId]
    if not cfg then return end
    local mob = GetMobByID(mobId, instance)
    if mob then
        applyStats(mob, cfg.stats)
        mechanics.attach(mob, cfg)
    end
end

local function spawnBoss(instance, mobId, role)
    instance:setLocalVar(bossStateKey(role, 'Seen'), 0)
    instance:setLocalVar(bossStateKey(role, 'Killed'), 0)

    local mob = SpawnMob(mobId, instance)
    if not mob then
        tell(instance, string.format(
            '[Divergence] ERROR: %s boss slot %d could not be loaded. The run will end without clear rewards.',
            role,
            mobId))
        instance:fail()
        return nil
    end

    attachBoss(instance, mobId)
    if not mob:isSpawned() or not mob:isAlive() then
        tell(instance, string.format(
            '[Divergence] ERROR: %s boss %d failed to spawn alive. The run will end without clear rewards.',
            role,
            mobId))
        instance:fail()
        return nil
    end

    instance:setLocalVar(bossStateKey(role, 'Seen'), 1)
    local listenerId = string.format('DIVERGENCE_%s_DEATH', role:upper())
    pcall(function() mob:removeListener(listenerId) end)
    mob:addListener('DEATH', listenerId, function()
        instance:setLocalVar(bossStateKey(role, 'Killed'), 1)
    end)
    return mob
end

-- Per-second tick for a boss slot. Safe no-op if the boss isn't spawned yet,
-- is already dead, or has no attached cfg (mechanics.tick early-returns without
-- state). Called from onInstanceTimeUpdate for each boss slot every second.
local function tickBoss(instance, mobId)
    if not mobId then return end
    local mob = GetMobByID(mobId, instance)
    if not mob or not mob:isAlive() then return end
    local target
    pcall(function() target = mob:getTarget() end)
    mechanics.tick(mob, target)
end

-- Mega-Boss Su5 payout: roll SU5_DROPS_PER_KILL random weapons into the run's
-- treasure pool (fires exactly once -- the caller's wave transition guards it).
local function dropSu5(instance, cfg)
    local chars  = instance:getChars()
    local looter = chars and chars[1]
    if not looter then
        return
    end
    local boss = GetMobByID(cfg.megaBoss, instance)
    for _ = 1, SU5_DROPS_PER_KILL do
        local w = SU5_WEAPONS[math.random(#SU5_WEAPONS)]
        looter:addTreasure(w.id, boss)
        tell(instance, string.format(
            '[Divergence] The Mega-Boss relinquishes a Superior weapon: %s (%s, %s)!',
            w.name, w.slot, w.job))
    end
end

-- Preserve per-city Mega-Boss credit as a distinct progress marker. Augment
-- Tier 4 now requires a full city clear (DivergenceSlots), but this stamp remains
-- useful for migration, diagnostics, and any future Mega-specific rewards.
local function creditMegaBoss(instance, cfg)
    local slotBit = xi.divergence.slotBit[cfg.entrySlot] or 0
    if slotBit == 0 then
        return
    end

    for _, p in pairs(instance:getChars()) do
        local slots = p:getCharVar('DivergenceMegaSlots') or 0
        if bit.band(slots, slotBit) == 0 then
            p:setCharVar('DivergenceMegaSlots', bit.bor(slots, slotBit))
            p:printToPlayer(
                '[Divergence] Mega-Boss defeated -- finish the Disjoined to record the full city clear!',
                xi.msg.channel.SYSTEM_3)
        end
    end
end

-- Extend the timer (capped) and refresh the on-screen countdown for everyone.
local function extendTime(instance, addMin, elapsed)
    local cur = instance:getTimeLimit()            -- minutes
    local new = math.min(TIME_CAP_MIN, cur + addMin)
    if new <= cur then
        return
    end
    instance:setTimeLimit(new * 60)                -- setter takes seconds
    local remaining = math.floor(new * 60 - elapsed / 1000)
    for _, p in pairs(instance:getChars()) do
        p:countdown(remaining)
    end
end

-----------------------------------
-- Lifecycle -- called from each zone's instances/<name>.lua
-----------------------------------
xi.divergence.onInstanceCreated = function(instance, cfg)
    instance:setLocalVar('divWave', 1)
    for _, mobId in ipairs(cfg.wave1Mobs) do
        SpawnMob(mobId, instance)
    end
    for _, mobId in ipairs(cfg.statues) do
        SpawnMob(mobId, instance)
    end
    spawnBoss(instance, cfg.midBoss, 'Mid')
end

xi.divergence.placePlayer = function(player, instance, cfg)
    player:setInstance(instance)
    local p = cfg.entryPos
    player:setPos(p[1], p[2], p[3], p[4], instance:getZone():getID())
end

xi.divergence.startCountdown = function(player)
    local instance = player:getInstance()
    if instance then
        player:countdown(instance:getTimeLimit() * 60)
    end
end

xi.divergence.onInstanceTimeUpdate = function(instance, elapsed, cfg)
    -- Hard time limit (rolled here so extensions are a one-liner).
    if instance:getTimeLimit() * 60 - elapsed / 1000 <= 0 then
        instance:fail()
        return
    end

    -- Boss-mechanics tick (piggybacks the 1s instance heartbeat since these
    -- static bosses don't have per-mob onMobFight scripts). All three slots
    -- get ticked -- tickBoss no-ops on un-spawned / dead / uncfg'd mobs.
    tickBoss(instance, cfg.midBoss)
    tickBoss(instance, cfg.megaBoss)
    tickBoss(instance, cfg.disjoined)

    -- Time-extension statues -- credit each exactly once.
    for _, sid in ipairs(cfg.statues) do
        local key = 'st' .. sid
        if instance:getLocalVar(key) == 0 and isDead(instance, sid) then
            instance:setLocalVar(key, 1)
            extendTime(instance, STATUE_EXTEND, elapsed)
            tell(instance, '[Divergence] A statue crumbles -- time extended (+1 min).')
        end
    end

    local wave = instance:getLocalVar('divWave')
    if wave == 1 then
        if isBossDefeated(instance, cfg.midBoss, 'Mid') then
            instance:setLocalVar('divWave', 2)
            extendTime(instance, BOSS_EXTEND, elapsed)
            for _, mobId in ipairs(cfg.wave2Mobs) do
                SpawnMob(mobId, instance)
            end
            if not spawnBoss(instance, cfg.megaBoss, 'Mega') then
                return
            end
            tell(instance, '[Divergence] The Mid-Boss falls! The Regiment and its Mega-Boss advance! (+30 min)')
        end
    elseif wave == 2 then
        if isBossDefeated(instance, cfg.megaBoss, 'Mega') then
            dropSu5(instance, cfg)
            creditMegaBoss(instance, cfg)
            extendTime(instance, MEGA_EXTEND, elapsed)
            if cfg.disjoined then
                -- Wave 3: the Disjoined NM at the elemental circle. Mega victory
                -- grants a final buffer so solo/trust teams can attempt the capstone.
                for _, mobId in ipairs(cfg.wave3Mobs or {}) do
                    SpawnMob(mobId, instance)
                end
                if not spawnBoss(instance, cfg.disjoined, 'Disjoined') then
                    return
                end
                instance:setLocalVar('divWave', 3)
                tell(instance, '[Divergence] The Mega-Boss falls! The Disjoined manifests -- defeat it to secure the full city clear and Augment progress! (+15 min)')
            else
                instance:setLocalVar('divWave', 4)
                instance:complete()
            end
        end
    elseif wave == 3 then
        if isBossDefeated(instance, cfg.disjoined, 'Disjoined') then
            instance:setLocalVar('divWave', 4)
            instance:complete()
        end
    end
end

-- City of the Day: one [D] city rotates daily (UTC) and pays bonus medals on a
-- full clear, funneling groups into the same instance each day. Deterministic
-- from the epoch day so the player portal can mirror it (app.py DYNA_CITIES --
-- keep in sync). Zone rotation: 294 SdO / 295 Bastok / 296 Windurst / 297 Jeuno.
local CITY_BONUS =
{
    { id = 9543, qty = 1 },  -- Demon's Medal
    { id = 9541, qty = 2 },  -- Kindred's Medal
}

xi.divergence.featuredZoneToday = function()
    return 294 + (math.floor(os.time() / 86400) % 4)
end

-- Count of UNIQUE Divergence cities the player has cleared, 0..4.
--
-- onInstanceComplete already sets one bit per city into the
-- DivergenceSlots charvar (feet=1 San d'Oria, hands=2 Bastok, head=4
-- Windurst, legs=8 Jeuno). Multiple runs of the same city still leave
-- one bit set, which is the "same city = 1 win" rule the Relic forge
-- gate wants. Callers just need the popcount.
--
-- Consumed by modules/custom/lua/WeaponForge_NPC.lua at the Relic-step
-- gate: relicCosts[i].divergenceWins is the threshold (1, 2, 4).
xi.divergence.uniqueWins = function(player)
    local slots = player:getCharVar('DivergenceSlots') or 0
    local n = 0
    for i = 0, 3 do                              -- 4 city bits
        if bit.band(slots, bit.lshift(1, i)) ~= 0 then
            n = n + 1
        end
    end
    return n
end

xi.divergence.onInstanceComplete = function(instance, cfg)
    local slotBit  = xi.divergence.slotBit[cfg.entrySlot] or 0
    local featured = instance:getZone():getID() == xi.divergence.featuredZoneToday()
    for _, p in pairs(instance:getChars()) do
        local slots = p:getCharVar('DivergenceSlots')
        if slotBit ~= 0 and bit.band(slots, slotBit) == 0 then
            slots = bit.bor(slots, slotBit)
            p:setCharVar('DivergenceSlots', slots)
            p:printToPlayer(string.format('[Divergence] Reforge unlocked: %s armor!', cfg.entrySlot:upper()), xi.msg.channel.SYSTEM_3)
            if bit.band(slots, 15) == 15 then
                p:printToPlayer('[Divergence] All four slots cleared -- BODY reforge unlocked!', xi.msg.channel.SYSTEM_3)
            end
        end
        if featured then
            for _, b in ipairs(CITY_BONUS) do
                pcall(function() p:addItem({ id = b.id, quantity = b.qty }) end)
            end
            p:printToPlayer("[Divergence] City of the Day! Bonus spoils: 1 Demon's Medal + 2 Kindred's Medals.", xi.msg.channel.SYSTEM_3)
        end
        p:printToPlayer('[Divergence] Victory! Returning you to San d\'Oria...', xi.msg.channel.SYSTEM_3)
        p:timer(EXIT_DELAY_MS, function(pp)
            local e = cfg.exitPos
            pp:setPos(e[1], e[2], e[3], e[4], cfg.exitZone)
        end)
    end
end

xi.divergence.onInstanceFailure = function(instance, cfg)
    for _, p in pairs(instance:getChars()) do
        p:printToPlayer('[Divergence] Time expired. Returning you to San d\'Oria...', xi.msg.channel.SYSTEM_3)
        p:timer(5000, function(pp)
            local e = cfg.exitPos
            pp:setPos(e[1], e[2], e[3], e[4], cfg.exitZone)
        end)
    end
end

-----------------------------------
-- Boss mechanics + stat baselines (owner 2026-07-12 audit + 2026-07-13
-- T3 progression rebalance: every cfg carries a `stats` block so the 12
-- Dynamis-Divergence bosses form a solo-with-trusts ladder for players wearing
-- non-REMA gear with T3 augments. Attached at the SpawnMob call
-- sites above via attachBoss() (applies stats -> then mechanics); ticked
-- every second via tickBoss().
--
-- Keyed by mobId (from the four zones' instances/<zone>.lua CONFIG blocks).
-- Every cfg sets targetPartyOnly = true (private/small-alliance instances --
-- keeps hostile pulses scoped to the aggro target's party). Enrage timers
-- are LOOSE (240-300s) since Dynamis fights run longer than dungeon fights,
-- and every cfg is added ON TOP of the retail Dynamis skill_list + spell_list
-- inherited from the donor pool -- these mechs COMPLEMENT that kit, not
-- duplicate it. Tuning tiers, from lightest to heaviest:
--   * Mid-Bosses: 200k HP and GM-Normal offense; a short warm-up.
--   * Mega-Bosses: 900k HP and HL-T3+ offense; the main run checkpoint.
--   * Disjoined: 1.4M HP and HL-T4 offense; the full-clear/T4 capstone.
-- Per-boss timing flavor (stance cycle sec, aoe %, enrage window) stays
-- UNIQUE so each city still feels distinct; the shared stat baseline just
-- pins the raw stat wall so no boss is an outlier.
-----------------------------------

-- STAT BASELINES -- keyed to the three difficulty tiers. Every boss carries
-- one of these via `stats = STATS_*`. HP is ABSOLUTE (setMaxHP overrides
-- mob_groups). Mods use setMod (override) so the pool-derived stats are
-- fully replaced -- same pattern as HuntingLeague.lua.
--
-- Baselines intentionally bracket the existing GM Normal / HL T3 / HL T4
-- progression points.  Endurance is kept low enough that trusts can sustain
-- the run; danger comes from readable mechanics rather than T5 stat walls.
local STATS_MID =
{
    hp = 200000,
    mods =
    {
        [xi.mod.DEF]           =  550,
        [xi.mod.ATT]           = 3500,
        [xi.mod.ACC]           = 1200,
        [xi.mod.EVASION]       =  400,
        [xi.mod.MEVA]          =  450,
        [xi.mod.MDEF]          =  450,
        [xi.mod.STR]           =  250,
        [xi.mod.DEX]           =  250,
        [xi.mod.HASTE_GEAR]    =  225,   -- ~22%
        [xi.mod.DOUBLE_ATTACK] =    8,
        [xi.mod.TRIPLE_ATTACK] =    0,
        [xi.mod.REGEN]         =   80,
    },
}
local STATS_MEGA =
{
    hp = 900000,
    mods =
    {
        [xi.mod.DEF]           =  950,
        [xi.mod.ATT]           = 5200,
        [xi.mod.ACC]           = 1500,
        [xi.mod.EVASION]       =  550,
        [xi.mod.MEVA]          =  650,
        [xi.mod.MDEF]          =  600,
        [xi.mod.STR]           =  350,
        [xi.mod.DEX]           =  350,
        [xi.mod.HASTE_GEAR]    =  300,
        [xi.mod.DOUBLE_ATTACK] =   12,
        [xi.mod.TRIPLE_ATTACK] =    2,
        [xi.mod.REGEN]         =  100,
    },
}
local STATS_DISJOINED =
{
    hp = 1400000,
    mods =
    {
        [xi.mod.DEF]           = 1100,
        [xi.mod.ATT]           = 6000,
        [xi.mod.ACC]           = 1700,
        [xi.mod.EVASION]       =  600,
        [xi.mod.MEVA]          =  750,
        [xi.mod.MDEF]          =  700,
        [xi.mod.STR]           =  450,
        [xi.mod.DEX]           =  450,
        [xi.mod.HASTE_GEAR]    =  330,
        [xi.mod.DOUBLE_ATTACK] =   14,
        [xi.mod.TRIPLE_ATTACK] =    3,
        [xi.mod.REGEN]         =  120,
    },
}

-- Public, immutable-by-convention contract used by focused regression tests.
xi.divergence.balance =
{
    activeWaveTrash = 20,
    activeStatues   = 6,
    megaExtendMin   = MEGA_EXTEND,
    mid             = STATS_MID,
    mega            = STATS_MEGA,
    disjoined       = STATS_DISJOINED,
}
xi.divergence.bossMechCfgs =
{
    -- ── San d'Oria [D] (zone 294) ───────────────────────────────────────────
    -- Overseer's Tombstone -- statue mid-boss. Regenerates + cracks under pressure.
    [17981770] =
    {
        name            = "Overseer's Tombstone",
        targetPartyOnly = true,
        stats  = STATS_MID,
        drain  = { periodSec = 12, healPct = 0.5 },
        enrage = { sec = 420, att = 2500, haste = 80, msg = "Overseer's Tombstone hums with unbroken vigil!" },
        phases =
        {
            { hp = 50, action = 'fury', att = 1500, haste = 80, msg = "Overseer's Tombstone splits along old fault lines -- it comes on faster!" },
        },
    },
    -- Halphas -- Fomor PLD mega-boss. Stance dance + banishga AoE + drain + dispel/fury.
    [17982112] =
    {
        name            = 'Halphas',
        targetPartyOnly = true,
        stats  = STATS_MEGA,
        stance = { startHpp = 85, periodSec = 16, stances = {
            { mods = { [xi.mod.DMGPHYS] = -3000, [xi.mod.DMGMAGIC] = 0     }, msg = 'Halphas raises his shield -- steel breaks against it!' },
            { mods = { [xi.mod.DMGPHYS] = 0,     [xi.mod.DMGMAGIC] = -3000 }, msg = 'Halphas invokes divine ward -- magic dissolves!' },
        } },
        aoe    = { periodSec = 17, dmgPct = 14, msg = 'Halphas unleashes a Banishga -- holy light burns outward!' },
        drain  = { periodSec = 10, healPct = 0.25 },
        enrage = { sec = 390, att = 2750, haste = 100, msg = 'Halphas draws deep on Fomor rage -- his blade quickens!' },
        phases =
        {
            { hp = 60, action = 'dispel', count = 2,              msg = 'Halphas roars a Fomor war-cry -- your enhancements shatter!' },
            { hp = 30, action = 'fury',   att = 2200, haste = 90, msg = 'Halphas enters his last stand -- the assault peaks!' },
        },
    },
    -- Disjoined Elvaan -- Wave 3 Fomor capstone with stance and control pressure.
    [17982238] =
    {
        name            = 'Disjoined Elvaan',
        targetPartyOnly = true,
        stats  = STATS_DISJOINED,
        stance = { startHpp = 80, periodSec = 14, stances = {
            { mods = { [xi.mod.DMGPHYS] = -3000, [xi.mod.DMGMAGIC] = 0     }, msg = 'Disjoined Elvaan\'s guard hardens -- steel is turned!' },
            { mods = { [xi.mod.DMGPHYS] = 0,     [xi.mod.DMGMAGIC] = -3000 }, msg = 'Disjoined Elvaan wards the arcane -- magic scatters!' },
        } },
        aoe    = { periodSec = 17, dmgPct = 15, msg = 'Disjoined Elvaan sweeps a holy blade -- the arc singes all!' },
        cc     = { periodSec = 24, effect = xi.effect.PARALYZE, power = 50, dur = 4, msg = 'Disjoined Elvaan\'s consecrated strike freezes your nerves!' },
        drain  = { periodSec = 10, healPct = 0.25 },
        enrage = { sec = 420, att = 3000, haste = 100, msg = 'Disjoined Elvaan burns with severed-godhood fury!' },
        phases =
        {
            { hp = 60, action = 'dispel', count = 2,              msg = 'Disjoined Elvaan calls his patron -- your blessings are recalled!' },
            { hp = 30, action = 'fury',   att = 2500, haste = 100, msg = 'Disjoined Elvaan draws his final oath -- he ascends!' },
        },
    },

    -- ── Bastok [D] (zone 295) ───────────────────────────────────────────────
    -- Mu'Sha Effigy -- giant-slayer effigy mid-boss. Echo silence + slow drain.
    -- HP50 fury added 2026-07-13 (consistency pass: every Mid has a phase now).
    [17985538] =
    {
        name            = "Mu'Sha Effigy",
        targetPartyOnly = true,
        stats  = STATS_MID,
        drain  = { periodSec = 12, healPct = 0.5 },
        cc     = { periodSec = 28, effect = xi.effect.SILENCE, power = 1, dur = 4, msg = "Mu'Sha Effigy resonates -- the echo dampens all sound!" },
        enrage = { sec = 420, att = 2500, haste = 80, msg = "Mu'Sha Effigy rings with the wrath of the twin moons!" },
        phases =
        {
            { hp = 50, action = 'fury', att = 1500, haste = 80, msg = "Mu'Sha Effigy resonates in furious echo -- assault peaks!" },
        },
    },
    -- Ka'Rho Fearsinger -- Fomor bard/mage mega-boss. Silence + fear + dispel + finale.
    [17985895] =
    {
        name            = "Ka'Rho Fearsinger",
        targetPartyOnly = true,
        stats  = STATS_MEGA,
        cc     = { periodSec = 24, effect = xi.effect.SILENCE, power = 1, dur = 4, msg = "Ka'Rho Fearsinger begins a dread lay -- your voice is stolen!" },
        aoe    = { periodSec = 17, dmgPct = 14, msg = "Ka'Rho Fearsinger unleashes a Fearscream -- the walls tremble!" },
        drain  = { periodSec = 10, healPct = 0.25 },
        enrage = { sec = 390, att = 2750, haste = 100, msg = "Ka'Rho Fearsinger's aria reaches its darkest verse!" },
        phases =
        {
            { hp = 60, action = 'dispel', count = 2,   msg = "Ka'Rho Fearsinger sings the silencing verse -- your buffs are unmade!" },
            { hp = 30, action = 'nuke',   dmgPct = 24, msg = "Ka'Rho Fearsinger unleashes the climactic finale!" },
        },
    },
    -- Disjoined Galka -- Wave 3 Fomor capstone. Slow, heavy brute + roar.
    -- CC TERROR added 2026-07-13 (consistency pass: every other Disjoined boss
    -- carries some cc; the war-bellow was thematic but toothless without a lock).
    [17986326] =
    {
        name            = 'Disjoined Galka',
        targetPartyOnly = true,
        stats  = STATS_DISJOINED,
        stance = { startHpp = 80, periodSec = 16, stances = {
            { mods = { [xi.mod.DMGPHYS] = -3000, [xi.mod.DMGMAGIC] = 0     }, msg = 'Disjoined Galka bunches his shoulders -- weapons rebound!' },
            { mods = { [xi.mod.DMGPHYS] = 0,     [xi.mod.DMGMAGIC] = -3000 }, msg = 'Disjoined Galka wards the arcane -- spells ripple off!' },
        } },
        aoe    = { periodSec = 17, dmgPct = 15, msg = 'Disjoined Galka slams the ground -- a giant shockwave rolls out!' },
        cc     = { periodSec = 28, effect = xi.effect.TERROR, power = 1, dur = 3, msg = "Disjoined Galka's war-bellow shakes your bones -- you cannot move!" },
        drain  = { periodSec = 10, healPct = 0.25 },
        enrage = { sec = 420, att = 3000, haste = 100, msg = 'Disjoined Galka lets loose a war-bellow -- Fomor blood erupts!' },
        phases =
        {
            { hp = 60, action = 'fury', att = 2300, haste = 90, msg = 'Disjoined Galka enters a killing pace!' },
            { hp = 30, action = 'nuke', dmgPct = 28,             msg = 'Disjoined Galka roars his forebears\' names -- a killing blow lands!' },
        },
    },

    -- ── Windurst [D] (zone 296) ─────────────────────────────────────────────
    -- Evincing Idol -- idol mid-boss. Buffs itself with magic (dispel-pressure).
    [17989634] =
    {
        name            = 'Evincing Idol',
        targetPartyOnly = true,
        stats  = STATS_MID,
        drain  = { periodSec = 12, healPct = 0.5 },
        enrage = { sec = 420, att = 2500, haste = 80, msg = 'Evincing Idol\'s runes blaze crimson -- it channels forbidden aid!' },
        phases =
        {
            { hp = 50, action = 'dispel', count = 2, msg = 'Evincing Idol pulses -- your blessings are banished!' },
        },
    },
    -- Fii Pexu the Eternal -- Fomor immortal mega-boss. Stance + terror + drain + phases.
    [17990606] =
    {
        name            = 'Fii Pexu the Eternal',
        targetPartyOnly = true,
        stats  = STATS_MEGA,
        stance = { startHpp = 85, periodSec = 16, stances = {
            { mods = { [xi.mod.DMGPHYS] = -3000, [xi.mod.DMGMAGIC] = 0     }, msg = 'Fii Pexu\'s form reforges as steel -- weapons cannot bite!' },
            { mods = { [xi.mod.DMGPHYS] = 0,     [xi.mod.DMGMAGIC] = -3000 }, msg = 'Fii Pexu shifts to sorcerous flesh -- magic is undone!' },
        } },
        drain  = { periodSec = 10, healPct = 0.25 },
        cc     = { periodSec = 28, effect = xi.effect.TERROR, power = 1, dur = 3, msg = 'Fii Pexu\'s eternal gaze pins you in dread!' },
        enrage = { sec = 390, att = 2750, haste = 100, msg = 'Fii Pexu the Eternal draws on the endless well of Fomor rage!' },
        phases =
        {
            { hp = 60, action = 'fury',   att = 2200, haste = 90, msg = 'Fii Pexu shrugs off the wound and comes on faster!' },
            { hp = 30, action = 'dispel', count = 2,              msg = 'Fii Pexu resurrects its own buffs -- yours are torn away!' },
        },
    },
    -- Disjoined Tarutaru -- Wave 3 endgame Fomor Tarutaru. Mage archetype.
    [17990425] =
    {
        name            = 'Disjoined Tarutaru',
        targetPartyOnly = true,
        stats  = STATS_DISJOINED,
        drain  = { periodSec = 10, healPct = 0.25 },
        aoe    = { periodSec = 17, dmgPct = 15, msg = 'Disjoined Tarutaru unleashes a spell-burst -- arcane shards fly!' },
        cc     = { periodSec = 24, effect = xi.effect.SILENCE, power = 1, dur = 4, msg = 'Disjoined Tarutaru weaves a silence trap -- your voice is snuffed!' },
        enrage = { sec = 420, att = 3000, haste = 100, msg = 'Disjoined Tarutaru overchannels -- raw magic bleeds from him!' },
        phases =
        {
            { hp = 60, action = 'dispel', count = 2,   msg = "Disjoined Tarutaru enters mage's fury -- all buffs are torn!" },
            { hp = 30, action = 'nuke',   dmgPct = 28, msg = 'Disjoined Tarutaru completes a mega-spell -- shockwave!' },
        },
    },

    -- ── Jeuno [D] (zone 297) ────────────────────────────────────────────────
    -- Impish Golem -- hybrid mid-boss. Stance + fury phase.
    [17993730] =
    {
        name            = 'Impish Golem',
        targetPartyOnly = true,
        stats  = STATS_MID,
        drain  = { periodSec = 12, healPct = 0.5 },
        stance = { startHpp = 60, periodSec = 18, stances = {
            { mods = { [xi.mod.DMGPHYS] = -3000, [xi.mod.DMGMAGIC] = 0     }, msg = 'Impish Golem plate-rotates -- weapons glance off!' },
            { mods = { [xi.mod.DMGPHYS] = 0,     [xi.mod.DMGMAGIC] = -3000 }, msg = 'Impish Golem rune-shifts -- magic is deflected!' },
        } },
        enrage = { sec = 420, att = 2500, haste = 80, msg = 'Impish Golem awakens its hidden gears -- pace quickens!' },
        phases =
        {
            { hp = 50, action = 'fury', att = 1500, haste = 80, msg = 'Impish Golem overclocks its cores -- assault escalates!' },
        },
    },
    -- Obstatrix -- Ahriman mega-boss. Fast eye stance + gaze AoE + silence.
    [17994068] =
    {
        name            = 'Obstatrix',
        targetPartyOnly = true,
        stats  = STATS_MEGA,
        stance = { startHpp = 85, periodSec = 14, stances = {
            { mods = { [xi.mod.DMGPHYS] = -3000, [xi.mod.DMGMAGIC] = 0     }, msg = 'Obstatrix blinks -- weapons find no purchase!' },
            { mods = { [xi.mod.DMGPHYS] = 0,     [xi.mod.DMGMAGIC] = -3000 }, msg = 'Obstatrix\'s pupils widen -- spells scatter!' },
        } },
        aoe    = { periodSec = 17, dmgPct = 14, msg = 'Obstatrix opens a petrifying gaze -- the room shakes!' },
        cc     = { periodSec = 24, effect = xi.effect.SILENCE, power = 1, dur = 4, msg = 'Obstatrix opens a Chaotic Eye -- your voice fails!' },
        enrage = { sec = 390, att = 2750, haste = 100, msg = 'Obstatrix\'s eyes bulge -- every pupil ignites!' },
        phases =
        {
            { hp = 60, action = 'dispel', count = 2,              msg = 'Obstatrix opens every eye -- your blessings vanish!' },
            { hp = 30, action = 'fury',   att = 2200, haste = 90, msg = 'Obstatrix roars -- pupils flare crimson!' },
        },
    },
    -- Disjoined Mithra -- Wave 3 Fomor capstone. Fast trickster pressure.
    [17994487] =
    {
        name            = 'Disjoined Mithra',
        targetPartyOnly = true,
        stats  = STATS_DISJOINED,
        stance = { startHpp = 80, periodSec = 12, stances = {
            { mods = { [xi.mod.DMGPHYS] = -3000, [xi.mod.DMGMAGIC] = 0     }, msg = 'Disjoined Mithra shifts stance -- steel bites nothing!' },
            { mods = { [xi.mod.DMGPHYS] = 0,     [xi.mod.DMGMAGIC] = -3000 }, msg = 'Disjoined Mithra wards magic -- spells fizzle!' },
        } },
        aoe    = { periodSec = 17, dmgPct = 15, msg = 'Disjoined Mithra whirls -- a spiral of steel opens outward!' },
        cc     = { periodSec = 24, effect = xi.effect.PARALYZE, power = 45, dur = 4, msg = 'Disjoined Mithra\'s poisoned blade grazes you -- paralysed!' },
        drain  = { periodSec = 10, healPct = 0.25 },
        enrage = { sec = 420, att = 3000, haste = 100, msg = 'Disjoined Mithra flickers between strikes -- an assassin unbound!' },
        phases =
        {
            { hp = 60, action = 'fury', att = 2400, haste = 100, msg = 'Disjoined Mithra breaks into a killing dance!' },
            { hp = 30, action = 'fury', att = 2800, haste = 110, msg = 'Disjoined Mithra becomes a blur -- every strike lands twice!' },
        },
    },
}

return xi.divergence
