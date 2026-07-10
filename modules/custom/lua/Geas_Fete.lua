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
local BEITETSU         = 4060  -- chunk of beitetsu
local RIFTBORN_BOULDER = 4061  -- riftborn boulder
local RIFTCINDER       = 3499  -- pinch of riftcinder
local ESCHALIXIR_2     = 9086  -- eschalixir +2

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
    [ZITAH] = {
        -- Tier 1 -------------------------------------------------------
        { name='Hugemaw Harold',   gid=24, tier=1, hp=150000, currency=400, cooldown=1800 },
        { name='Prickly Pitriv',   gid=25, tier=1, hp=150000, currency=400, cooldown=1800 },
        { name='Serpopard Ninlil', gid=26, tier=1, hp=120000, currency=350, cooldown=1800 },
        { name='Abyssdiver',       gid=27, tier=1, hp=100000, currency=300, cooldown=1800 },
        { name='Eschan Jewelweed', gid=36, tier=1, hp=100000, currency=300, cooldown=1800 },
        -- Tier 2 -------------------------------------------------------
        { name='Keeper of Heiligtum', gid=28, tier=2, hp=300000, currency=800,  cooldown=3600 },
        { name='Jester Malatrix',     gid=33, tier=2, hp=280000, currency=750,  cooldown=3600 },
        { name='Immanibugard',        gid=34, tier=2, hp=320000, currency=800,  cooldown=3600 },
        { name='Beist',               gid=35, tier=2, hp=350000, currency=900,  cooldown=3600 },
        { name='Wepwawet',            gid=37, tier=2, hp=300000, currency=800,  cooldown=3600 },
        -- Tier 3 -------------------------------------------------------
        { name='Voso',           gid=32, tier=3, hp=550000, currency=1500, cooldown=5400 },
        { name='Lustful Lydia',  gid=38, tier=3, hp=500000, currency=1200, cooldown=5400 },
        { name='Aglaophotis',    gid=39, tier=3, hp=550000, currency=1300, cooldown=5400 },
        { name='Ferrodon',       gid=46, tier=3, hp=600000, currency=1500, cooldown=5400 },
        { name='Blazewing',      gid=49, tier=3, hp=520000, currency=1200, cooldown=5400 },
        -- Boss ---------------------------------------------------------
        { name='Azi Dahaka', gid=64, tier=4, hp=1500000, currency=5000, cooldown=86400 },
    },
    [RUAUN] = {
        -- Tier 1 (Six Warders) — label= short menu text to stay under 150-byte menu cap
        { name='Warder of Temperance', label='Temperance', gid=29, tier=1, hp=180000, currency=500, cooldown=1800 },
        { name='Warder of Faith',      label='Faith',      gid=31, tier=1, hp=180000, currency=500, cooldown=1800 },
        { name='Warder of Justice',    label='Justice',    gid=32, tier=1, hp=180000, currency=500, cooldown=1800 },
        { name='Warder of Hope',       label='Hope',       gid=34, tier=1, hp=160000, currency=450, cooldown=1800 },
        { name='Warder of Prudence',   label='Prudence',   gid=35, tier=1, hp=160000, currency=450, cooldown=1800 },
        { name='Warder of Love',       label='Love',       gid=36, tier=1, hp=160000, currency=450, cooldown=1800 },
        -- Tier 2 -------------------------------------------------------
        { name='Ma',             gid=47, tier=2, hp=350000, currency=1000, cooldown=3600 },
        { name='Emputa',         gid=52, tier=2, hp=380000, currency=1000, cooldown=3600 },
        { name='Peirithoos',     gid=53, tier=2, hp=400000, currency=1100, cooldown=3600 },
        { name='Sava Savanovic', gid=56, tier=2, hp=420000, currency=1200, cooldown=3600 },
        { name='Hanbi',          gid=59, tier=2, hp=400000, currency=1100, cooldown=3600 },
        -- Tier 3 (Celestial Warders)
        { name='Byakko-Escha',    label='Byakko',  gid=78, tier=3, hp=700000,  currency=2000, cooldown=7200 },
        { name='Genbu-Escha',     label='Genbu',   gid=79, tier=3, hp=700000,  currency=2000, cooldown=7200 },
        { name='Seiryu-Escha',    label='Seiryu',  gid=80, tier=3, hp=700000,  currency=2000, cooldown=7200 },
        { name='Suzaku-Escha',    label='Suzaku',  gid=81, tier=3, hp=700000,  currency=2000, cooldown=7200 },
        { name='Kouryu',                           gid=84, tier=3, hp=1000000, currency=3500, cooldown=7200 },
        -- Boss ---------------------------------------------------------
        { name='Warder of Courage', label='Courage', gid=93, tier=4, hp=2000000, currency=8000, cooldown=86400 },
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
local function tierOptions(player, zone, zoneId, tierNum, mainFn, menu)
    local opts = {}
    for _, def in ipairs(NM_CATALOG[zoneId] or {}) do
        if def.tier == tierNum then
            local cd  = getCooldown(player, zoneId, def.gid)
            local lbl = string.format('%s [%s]', def.label or def.name, fmtCD(cd))
            local d   = def
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
    end
    opts[#opts + 1] = { 'Back', function(p) mainFn(p) end }
    return opts
end

-- Exchange shop: spend currency on materials.
local function buildShop(player, zone, zoneId, mainFn, menu)
    local clbl   = CURRENCY_LABEL[zoneId] or 'pts'
    local shopFn -- forward decl

    local SHOP = {
        { label='Beitetsu x1',        id=BEITETSU,         qty=1, cost=200  },
        { label='Riftcinder x1',      id=RIFTCINDER,       qty=1, cost=150  },
        { label='Riftborn Boulder x1',id=RIFTBORN_BOULDER, qty=1, cost=500  },
        { label='Eschalixir+2 x1',    id=ESCHALIXIR_2,     qty=1, cost=2000 },
    }

    shopFn = function(p)
        local cur = getCurrency(p, zoneId)
        menu.title = string.format('%s Exchange [%d]', clbl, cur)
        menu.options = {}
        for _, item in ipairs(SHOP) do
            local it = item
            menu.options[#menu.options + 1] = {
                string.format('%s (%d)', it.label, it.cost),
                function(pp)
                    if takeCurrency(pp, zoneId, it.cost) then
                        pp:addItem({ id = it.id, quantity = it.qty })
                        pp:printToPlayer('[Geas Fete] Exchanged.', S)
                    else
                        pp:printToPlayer(string.format('[Geas Fete] Need %d %s.', it.cost, clbl), S)
                    end
                    pp:timer(30, function(p2) p2:customMenu(menu) end)
                end,
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

    local function tierScreen(p, tierNum, tierTitle)
        menu.title   = tierTitle
        menu.options = tierOptions(p, zone, zoneId, tierNum, mainFn, menu)
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
