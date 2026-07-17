-----------------------------------
-- Common Requires
-----------------------------------
require('modules/module_utils')
require('scripts/globals/npc_util')
-----------------------------------
-- ID Requires
-----------------------------------
local dragonsAeryID      = zones[xi.zone.DRAGONS_AERY]
local valleySorrowsID    = zones[xi.zone.VALLEY_OF_SORROWS]
local behemothDomID      = zones[xi.zone.BEHEMOTHS_DOMINION]
-- Lower-tier HNMs
local sauromugueID       = zones[xi.zone.SAUROMUGUE_CHAMPAIGN]  -- Roc (zone 120)
local rolanberryID       = zones[xi.zone.ROLANBERRY_FIELDS]     -- Simurgh (zone 110)
local garlaigeCitadelID  = zones[xi.zone.GARLAIGE_CITADEL]      -- Serket (zone 200)
local jugnerForestID     = zones[xi.zone.JUGNER_FOREST]         -- King Arthro (zone 104)
local eastSarutabarutaID = zones[xi.zone.EAST_SARUTABARUTA]     -- Spiny Spipi (zone 116)

-----------------------------------
-- Module definition
-----------------------------------
-- This module attempts to mix both era and retail styles for Land Kings.
-- It allows NQ Kings to retain their era timed rotation while allowing HQ Kings to be poped from their QMs. For Uncle Teo.
-- It comes along a ToD perpetuation/retainment system, for server crashes, since this NMs were usually contested by endgame LSs.
local hnmSystem = Module:new('custom_HNM_System')

-----------------------------------
-- Module enable/disable
-----------------------------------
-- Do not use along era_HNM_System module. Choose one or the other.
hnmSystem:setEnabled(true)

-----------------------------------
-- Dragon's Aery: Fafnir, Nidhogg
-----------------------------------
hnmSystem:addOverride('xi.zones.Dragons_Aery.Zone.onInitialize', function(zone)
    super(zone)

    local hnmPopTime  = GetServerVariable('[HNM]Fafnir')   -- Time the NM will spawn at.
    local currentTime = GetSystemTime()

    -- First-time setup.
    if hnmPopTime == 0 then
        hnmPopTime = currentTime + math.random(1, 48) * 1800

        SetServerVariable('[HNM]Fafnir', hnmPopTime) -- Save pop time.
    end

    xi.mob.updateNMSpawnPoint(dragonsAeryID.mob.FAFNIR)

    -- Spawn mob or set spawn time.
    if hnmPopTime <= currentTime then
        SpawnMob(dragonsAeryID.mob.FAFNIR)
    else
        GetMobByID(dragonsAeryID.mob.FAFNIR):setRespawnTime(hnmPopTime - currentTime)
    end
end)

hnmSystem:addOverride('xi.zones.Dragons_Aery.mobs.Fafnir.onMobDespawn', function(mob)
    super(mob)

    -- Only the real HNM reschedules its own window. Affinity-NM replicas
    -- reuse this retail name/script (affinity_nm_autopop.lua); without this
    -- id check, killing a replica would stomp the real HNM's ToD/respawn.
    if mob:getID() ~= dragonsAeryID.mob.FAFNIR then
        return
    end

    -- Server Variable work.
    local randomPopTime = 75600 + math.random(0, 6) * 1800

    SetServerVariable('[HNM]Fafnir', GetSystemTime() + randomPopTime) -- Save next pop time.

    -- Set spawn time and position.
    GetMobByID(dragonsAeryID.mob.FAFNIR):setRespawnTime(randomPopTime)
    xi.mob.updateNMSpawnPoint(dragonsAeryID.mob.FAFNIR)
end)

hnmSystem:addOverride('xi.zones.Dragons_Aery.npcs.qm0.onTrade', function(player, npc, trade)
    if
        not GetMobByID(dragonsAeryID.mob.FAFNIR):isSpawned() and
        not GetMobByID(dragonsAeryID.mob.NIDHOGG):isSpawned() and
        npcUtil.tradeHasExactly(trade, xi.item.CUP_OF_SWEET_TEA) and
        npcUtil.popFromQM(player, npc, dragonsAeryID.mob.NIDHOGG)
    then
        player:confirmTrade()
    end
end)

-----------------------------------
-- Affinity-owned sites retired (2026-07-17)
-----------------------------------
-- affinity_nm_spawns.sql (2026-07-06) deleted the RETAIL spawn rows for
-- Behemoth / King Behemoth / Simurgh / Roc / Adamantoise / Aspidochelone so
-- the affinity replicas are the SOLE spawns at those camps. Consequences for
-- this module: GetFirstID('Behemoth'/'Aspidochelone') is nil (zone-init threw
-- "expected number, received nil" at every boot), and the other king names now
-- resolve to the AFFINITY mobs -- so the rotation/ToD logic here was fighting
-- affinity_nm_autopop's own respawn control over the same entities, and the
-- despawn id-guards matched the replicas they were written to exclude.
-- The four affected sites below early-return. Dragon's Aery / Garlaige /
-- Jugner / E. Sarutabaruta keep the classic rotation (retail spawns intact).
local AFFINITY_OWNED = true  -- Behemoths Dominion, Valley of Sorrows, Roc, Simurgh

-----------------------------------
-- Valley of Sorrows: Adamantoise, Aspidochelone
-----------------------------------
hnmSystem:addOverride('xi.zones.Valley_of_Sorrows.Zone.onInitialize', function(zone)
    super(zone)

    if AFFINITY_OWNED then return end

    local hnmPopTime  = GetServerVariable('[HNM]Adamantoise')   -- Time the NM will spawn at.
    local currentTime = GetSystemTime()

    -- First-time setup.
    if hnmPopTime == 0 then
        hnmPopTime = currentTime + math.random(1, 48) * 1800

        SetServerVariable('[HNM]Adamantoise', hnmPopTime) -- Save pop time.
    end

    xi.mob.updateNMSpawnPoint(valleySorrowsID.mob.ADAMANTOISE)

    -- Spawn mob or set spawn time.
    if hnmPopTime <= currentTime then
        SpawnMob(valleySorrowsID.mob.ADAMANTOISE)
    else
        GetMobByID(valleySorrowsID.mob.ADAMANTOISE):setRespawnTime(hnmPopTime - currentTime)
    end
end)

hnmSystem:addOverride('xi.zones.Valley_of_Sorrows.mobs.Adamantoise.onMobDespawn', function(mob)
    super(mob)

    if AFFINITY_OWNED then return end

    -- Only the real HNM reschedules its own window. Affinity-NM replicas
    -- reuse this retail name/script (affinity_nm_autopop.lua); without this
    -- id check, killing a replica would stomp the real HNM's ToD/respawn.
    if mob:getID() ~= valleySorrowsID.mob.ADAMANTOISE then
        return
    end

    -- Server Variable work.
    local randomPopTime = 75600 + math.random(0, 6) * 1800

    SetServerVariable('[HNM]Adamantoise', GetSystemTime() + randomPopTime) -- Save next pop time.

    -- Set spawn time and position.
    GetMobByID(valleySorrowsID.mob.ADAMANTOISE):setRespawnTime(randomPopTime)
    xi.mob.updateNMSpawnPoint(valleySorrowsID.mob.ADAMANTOISE)
end)

hnmSystem:addOverride('xi.zones.Valley_of_Sorrows.npcs.qm1.onTrade', function(player, npc, trade)
    if AFFINITY_OWNED then return end
    if
        not GetMobByID(valleySorrowsID.mob.ADAMANTOISE):isSpawned() and
        not GetMobByID(valleySorrowsID.mob.ASPIDOCHELONE):isSpawned() and
        npcUtil.tradeHasExactly(trade, xi.item.CLUMP_OF_RED_PONDWEED) and
        npcUtil.popFromQM(player, npc, valleySorrowsID.mob.ASPIDOCHELONE)
    then
        player:confirmTrade()
    end
end)

-----------------------------------
-- Behemoth's Dominion: Behemoth, King Behemoth
-----------------------------------
hnmSystem:addOverride('xi.zones.Behemoths_Dominion.Zone.onInitialize', function(zone)
    super(zone)

    if AFFINITY_OWNED then return end

    local hnmPopTime  = GetServerVariable('[HNM]Behemoth')   -- Time the NM will spawn at.
    local currentTime = GetSystemTime()

    -- First-time setup.
    if hnmPopTime == 0 then
        hnmPopTime = currentTime + math.random(1, 48) * 1800

        SetServerVariable('[HNM]Behemoth', hnmPopTime) -- Save pop time.
    end

    xi.mob.updateNMSpawnPoint(behemothDomID.mob.BEHEMOTH)

    -- Spawn mob or set spawn time.
    if hnmPopTime <= currentTime then
        SpawnMob(behemothDomID.mob.BEHEMOTH)
    else
        GetMobByID(behemothDomID.mob.BEHEMOTH):setRespawnTime(hnmPopTime - currentTime)
    end
end)

-- Behemoth.onMobDespawn override REMOVED 2026-07-13: the target path
-- xi.zones.Behemoths_Dominion.mobs.Behemoth was nil at TryApplyLuaModules time
-- (mob scripts are cached on first spawn, not at boot), so this addOverride
-- silently failed at every deploy since at least 2026-07-11 -- confirmed via
-- 8+ days of "Override not applied" log entries. The behavior (ToD server-var +
-- respawn scheduling for the real Behemoth) hasn't been active. If needed,
-- reimplement via a DEATH listener attached from Zone.onInitialize -- that
-- pattern actually fires (same as affinity_nm_autopop.lua).

hnmSystem:addOverride('xi.zones.Behemoths_Dominion.npcs.qm2.onTrade', function(player, npc, trade)
    if AFFINITY_OWNED then return end
    if
        not GetMobByID(behemothDomID.mob.BEHEMOTH):isSpawned() and
        not GetMobByID(behemothDomID.mob.KING_BEHEMOTH):isSpawned() and
        npcUtil.tradeHasExactly(trade, xi.item.SAVORY_SHANK) and
        npcUtil.popFromQM(player, npc, behemothDomID.mob.KING_BEHEMOTH)
    then
        player:confirmTrade()
    end
end)

-----------------------------------
-- Lower-tier HNMs - 6-10 hour respawn windows (accessible to mid-tier players)
--
-- Respawn formula: randomPopTime = minSeconds + math.random(0, rangeSteps) * 1800
--   Roc / Simurgh / Serket: 21600 + rand(0,4)*1800  -> 6-8 h
--   King Arthro:             28800 + rand(0,4)*1800  -> 8-10 h
--   Spiny Spipi:             14400 + rand(0,4)*1800  -> 4-6 h
--
-- Zone confirmation (IDs verified against scripts/zones/*/IDs.lua):
--   Roc         - Sauromugue_Champaign  (zone 120) - sauromugueID.mob.ROC
--   Simurgh     - Rolanberry_Fields     (zone 110) - rolanberryID.mob.SIMURGH
--   Serket      - Garlaige_Citadel      (zone 200) - garlaigeCitadelID.mob.SERKET
--   King Arthro - Jugner_Forest         (zone 104) - jugnerForestID.mob.KING_ARTHRO
--   Spiny Spipi - East_Sarutabaruta     (zone 116) - eastSarutabarutaID.mob.SPINY_SPIPI
--
-- NOTE: The prompt guessed wrong zones for several of these NMs. The zones above
-- are confirmed from the LSB IDs.lua files and are the correct vanilla locations.
-----------------------------------

-----------------------------------
-- Sauromugue Champaign: Roc
-----------------------------------
hnmSystem:addOverride('xi.zones.Sauromugue_Champaign.Zone.onInitialize', function(zone)
    super(zone)

    if AFFINITY_OWNED then return end

    local hnmPopTime  = GetServerVariable('[HNM]Roc')
    local currentTime = GetSystemTime()

    if hnmPopTime == 0 then
        hnmPopTime = currentTime + math.random(1, 20) * 1800
        SetServerVariable('[HNM]Roc', hnmPopTime)
    end

    xi.mob.updateNMSpawnPoint(sauromugueID.mob.ROC)

    if hnmPopTime <= currentTime then
        SpawnMob(sauromugueID.mob.ROC)
    else
        GetMobByID(sauromugueID.mob.ROC):setRespawnTime(hnmPopTime - currentTime)
    end
end)

hnmSystem:addOverride('xi.zones.Sauromugue_Champaign.mobs.Roc.onMobDespawn', function(mob)
    super(mob)

    if AFFINITY_OWNED then return end

    -- Only the real HNM reschedules its own window. Affinity-NM replicas
    -- reuse this retail name/script (affinity_nm_autopop.lua); without this
    -- id check, killing a replica would stomp the real HNM's ToD/respawn.
    if mob:getID() ~= sauromugueID.mob.ROC then
        return
    end

    -- 6-8 hour window: 21600s + up to 4 * 1800s
    local randomPopTime = 21600 + math.random(0, 4) * 1800

    SetServerVariable('[HNM]Roc', GetSystemTime() + randomPopTime)

    GetMobByID(sauromugueID.mob.ROC):setRespawnTime(randomPopTime)
    xi.mob.updateNMSpawnPoint(sauromugueID.mob.ROC)
end)

-----------------------------------
-- Rolanberry Fields: Simurgh
-----------------------------------
hnmSystem:addOverride('xi.zones.Rolanberry_Fields.Zone.onInitialize', function(zone)
    super(zone)

    if AFFINITY_OWNED then return end

    local hnmPopTime  = GetServerVariable('[HNM]Simurgh')
    local currentTime = GetSystemTime()

    if hnmPopTime == 0 then
        hnmPopTime = currentTime + math.random(1, 20) * 1800
        SetServerVariable('[HNM]Simurgh', hnmPopTime)
    end

    xi.mob.updateNMSpawnPoint(rolanberryID.mob.SIMURGH)

    if hnmPopTime <= currentTime then
        SpawnMob(rolanberryID.mob.SIMURGH)
    else
        GetMobByID(rolanberryID.mob.SIMURGH):setRespawnTime(hnmPopTime - currentTime)
    end
end)

hnmSystem:addOverride('xi.zones.Rolanberry_Fields.mobs.Simurgh.onMobDespawn', function(mob)
    super(mob)

    if AFFINITY_OWNED then return end

    -- Only the real HNM reschedules its own window. Affinity-NM replicas
    -- reuse this retail name/script (affinity_nm_autopop.lua); without this
    -- id check, killing a replica would stomp the real HNM's ToD/respawn.
    if mob:getID() ~= rolanberryID.mob.SIMURGH then
        return
    end

    -- 6-8 hour window: 21600s + up to 4 * 1800s
    local randomPopTime = 21600 + math.random(0, 4) * 1800

    SetServerVariable('[HNM]Simurgh', GetSystemTime() + randomPopTime)

    GetMobByID(rolanberryID.mob.SIMURGH):setRespawnTime(randomPopTime)
    xi.mob.updateNMSpawnPoint(rolanberryID.mob.SIMURGH)
end)

-----------------------------------
-- Garlaige Citadel: Serket
-----------------------------------
hnmSystem:addOverride('xi.zones.Garlaige_Citadel.Zone.onInitialize', function(zone)
    super(zone)

    local hnmPopTime  = GetServerVariable('[HNM]Serket')
    local currentTime = GetSystemTime()

    if hnmPopTime == 0 then
        hnmPopTime = currentTime + math.random(1, 20) * 1800
        SetServerVariable('[HNM]Serket', hnmPopTime)
    end

    xi.mob.updateNMSpawnPoint(garlaigeCitadelID.mob.SERKET)

    if hnmPopTime <= currentTime then
        SpawnMob(garlaigeCitadelID.mob.SERKET)
    else
        GetMobByID(garlaigeCitadelID.mob.SERKET):setRespawnTime(hnmPopTime - currentTime)
    end
end)

hnmSystem:addOverride('xi.zones.Garlaige_Citadel.mobs.Serket.onMobDespawn', function(mob)
    super(mob)

    -- Only the real HNM reschedules its own window. Affinity-NM replicas
    -- reuse this retail name/script (affinity_nm_autopop.lua); without this
    -- id check, killing a replica would stomp the real HNM's ToD/respawn.
    if mob:getID() ~= garlaigeCitadelID.mob.SERKET then
        return
    end

    -- 6-8 hour window: 21600s + up to 4 * 1800s
    local randomPopTime = 21600 + math.random(0, 4) * 1800

    SetServerVariable('[HNM]Serket', GetSystemTime() + randomPopTime)

    GetMobByID(garlaigeCitadelID.mob.SERKET):setRespawnTime(randomPopTime)
    xi.mob.updateNMSpawnPoint(garlaigeCitadelID.mob.SERKET)
end)

-----------------------------------
-- Jugner Forest: King Arthro
-----------------------------------
hnmSystem:addOverride('xi.zones.Jugner_Forest.Zone.onInitialize', function(zone)
    super(zone)

    local hnmPopTime  = GetServerVariable('[HNM]King_Arthro')
    local currentTime = GetSystemTime()

    if hnmPopTime == 0 then
        hnmPopTime = currentTime + math.random(1, 20) * 1800
        SetServerVariable('[HNM]King_Arthro', hnmPopTime)
    end

    xi.mob.updateNMSpawnPoint(jugnerForestID.mob.KING_ARTHRO)

    if hnmPopTime <= currentTime then
        SpawnMob(jugnerForestID.mob.KING_ARTHRO)
    else
        GetMobByID(jugnerForestID.mob.KING_ARTHRO):setRespawnTime(hnmPopTime - currentTime)
    end
end)

hnmSystem:addOverride('xi.zones.Jugner_Forest.mobs.King_Arthro.onMobDespawn', function(mob)
    super(mob)

    -- Only the real HNM reschedules its own window. Affinity-NM replicas
    -- reuse this retail name/script (affinity_nm_autopop.lua); without this
    -- id check, killing a replica would stomp the real HNM's ToD/respawn.
    if mob:getID() ~= jugnerForestID.mob.KING_ARTHRO then
        return
    end

    -- 8-10 hour window: 28800s + up to 4 * 1800s
    local randomPopTime = 28800 + math.random(0, 4) * 1800

    SetServerVariable('[HNM]King_Arthro', GetSystemTime() + randomPopTime)

    GetMobByID(jugnerForestID.mob.KING_ARTHRO):setRespawnTime(randomPopTime)
    xi.mob.updateNMSpawnPoint(jugnerForestID.mob.KING_ARTHRO)
end)

-----------------------------------
-- East Sarutabaruta: Spiny Spipi
-----------------------------------
hnmSystem:addOverride('xi.zones.East_Sarutabaruta.Zone.onInitialize', function(zone)
    super(zone)

    local hnmPopTime  = GetServerVariable('[HNM]Spiny_Spipi')
    local currentTime = GetSystemTime()

    if hnmPopTime == 0 then
        hnmPopTime = currentTime + math.random(1, 12) * 1800
        SetServerVariable('[HNM]Spiny_Spipi', hnmPopTime)
    end

    xi.mob.updateNMSpawnPoint(eastSarutabarutaID.mob.SPINY_SPIPI)

    if hnmPopTime <= currentTime then
        SpawnMob(eastSarutabarutaID.mob.SPINY_SPIPI)
    else
        GetMobByID(eastSarutabarutaID.mob.SPINY_SPIPI):setRespawnTime(hnmPopTime - currentTime)
    end
end)

hnmSystem:addOverride('xi.zones.East_Sarutabaruta.mobs.Spiny_Spipi.onMobDespawn', function(mob)
    super(mob)

    -- Only the real HNM reschedules its own window. Affinity-NM replicas
    -- reuse this retail name/script (affinity_nm_autopop.lua); without this
    -- id check, killing a replica would stomp the real HNM's ToD/respawn.
    if mob:getID() ~= eastSarutabarutaID.mob.SPINY_SPIPI then
        return
    end

    -- 4-6 hour window: 14400s + up to 4 * 1800s
    local randomPopTime = 14400 + math.random(0, 4) * 1800

    SetServerVariable('[HNM]Spiny_Spipi', GetSystemTime() + randomPopTime)

    GetMobByID(eastSarutabarutaID.mob.SPINY_SPIPI):setRespawnTime(randomPopTime)
    xi.mob.updateNMSpawnPoint(eastSarutabarutaID.mob.SPINY_SPIPI)
end)

-----------------------------------
-- HNM King kill-credit (per-player)
-----------------------------------
-- Bump the HNM_King_Kills charVar for every player who received EXP from a King
-- kill (the whole alliance -- not just the killing-blow player). Used as an
-- entry gate for content that requires proof of endgame combat readiness
-- (e.g. Ambuscade). The 6 IDs below are the Land Kings from docs/progression/hnm.md:
-- NQ + HQ pair per zone (Fafnir/Nidhogg, Adamantoise/Aspidochelone, Behemoth/King Behemoth).
-- Lazy-init: some zone IDs (esp. Valley_of_Sorrows.mob.ASPIDOCHELONE) can be
-- nil at module-load time if their IDs.lua hasn't run yet. Building the table
-- at kill-time guarantees the zone is fully loaded (a King is dying in it).
local _hnm_king_ids = nil
local function getHnmKingIds()
    if _hnm_king_ids then return _hnm_king_ids end
    local t = {}
    local function add(id, name) if id then t[id] = name end end
    add(dragonsAeryID.mob.FAFNIR,          'Fafnir')
    add(dragonsAeryID.mob.NIDHOGG,         'Nidhogg')
    add(valleySorrowsID.mob.ADAMANTOISE,   'Adamantoise')
    add(valleySorrowsID.mob.ASPIDOCHELONE, 'Aspidochelone')
    add(behemothDomID.mob.BEHEMOTH,        'Behemoth')
    add(behemothDomID.mob.KING_BEHEMOTH,   'King Behemoth')
    _hnm_king_ids = t
    return t
end

hnmSystem:addOverride('xi.mob.onMobDeathEx', function(mob, player, isKiller, isWeaponSkillKill)
    super(mob, player, isKiller, isWeaponSkillKill)

    -- onMobDeathEx fires once per reward-eligible player, so every alliance
    -- member who tagged the mob gets credit -- no reliance on final-hit RNG.
    local kingName = getHnmKingIds()[mob:getID()]
    if not kingName or not player then return end

    pcall(function()
        local now = (player:getCharVar('HNM_King_Kills') or 0) + 1
        player:setCharVar('HNM_King_Kills', now)
        if now == 1 then
            -- Only annouce the first credit -- avoid spamming on subsequent HNMs.
            player:printToPlayer(string.format(
                '[HNM] %s vanquished -- first HNM King kill recorded (%d total).',
                kingName, now), xi.msg.channel.SYSTEM_3)
        end
    end)
end)

return hnmSystem
