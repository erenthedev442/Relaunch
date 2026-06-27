-----------------------------------
-- augment_affinity_grants.lua
-- Grants augment affinities on NM kill. No trophy item required.
-- Each NM maps to one affinity cat in augment_affinity_catalog.lua.
-- Zones with multiple NMs share one addOverride hook.
--
-- Zone-path notes (verify if a zone name errors on load):
--   Behemoths_Dominion, Batallia_Downs, Kuftal_Tunnel,
--   Rolanberry_Fields, Valley_of_Sorrows, Hall_of_the_Gods,
--   Sauromugue_Champaign, The_Shrine_of_RuAvitau, Cape_Teriggan,
--   Riverne-Site_B01, The_Boyahda_Tree, Riverne-Site_A01,
--   Dragons_Aery, Ifrits_Cauldron, Uleguerand_Range,
--   Western_Altepa_Desert, King_Ranperres_Tomb, RuAun_Gardens,
--   Temenos (Proto-Omega)
-----------------------------------
require('modules/module_utils')
require('scripts/zones/Batallia_Downs/Zone')
require('scripts/zones/Behemoths_Dominion/Zone')
require('scripts/zones/Kuftal_Tunnel/Zone')
require('scripts/zones/Rolanberry_Fields/Zone')
require('scripts/zones/Valley_of_Sorrows/Zone')
require('scripts/zones/Hall_of_the_Gods/Zone')
require('scripts/zones/Sauromugue_Champaign/Zone')
require('scripts/zones/The_Shrine_of_RuAvitau/Zone')
require('scripts/zones/Cape_Teriggan/Zone')
require('scripts/zones/Riverne-Site_B01/Zone')
require('scripts/zones/The_Boyahda_Tree/Zone')
require('scripts/zones/Riverne-Site_A01/Zone')
require('scripts/zones/Dragons_Aery/Zone')
require('scripts/zones/Ifrits_Cauldron/Zone')
require('scripts/zones/Uleguerand_Range/Zone')
require('scripts/zones/Western_Altepa_Desert/Zone')
require('scripts/zones/King_Ranperres_Tomb/Zone')
require('scripts/zones/RuAun_Gardens/Zone')
require('scripts/zones/Temenos/Zone')

local m        = Module:new('augment_affinity_grants')
local affinity = require('modules/custom/lua/augment_affinity_catalog')
local SYS      = xi.msg.channel.SYSTEM_3

local function grantIfNew(player, nmName)
    local row = affinity.byNm(nmName)
    if not row then return end
    if affinity.hasAffinity(player, row.cat) then return end
    affinity.grantAffinity(player, row.cat)
    player:printToPlayer(string.format(
        '[Augment] %s affinity unlocked! Augments in this category are now %.0f%% stronger.',
        row.label, (affinity.affinityMult - 1.0) * 100), SYS)
end

-----------------------------------
-- Single-NM zones
-----------------------------------
m:addOverride('xi.zones.Batallia_Downs.Zone.onMobDeath', function(mob, player, isKiller, noKillIncrement)
    super(mob, player, isKiller, noKillIncrement)
    if player and isKiller then grantIfNew(player, mob:getName()) end
end)

m:addOverride('xi.zones.Behemoths_Dominion.Zone.onMobDeath', function(mob, player, isKiller, noKillIncrement)
    super(mob, player, isKiller, noKillIncrement)
    if player and isKiller then grantIfNew(player, mob:getName()) end
end)

m:addOverride('xi.zones.Kuftal_Tunnel.Zone.onMobDeath', function(mob, player, isKiller, noKillIncrement)
    super(mob, player, isKiller, noKillIncrement)
    if player and isKiller then grantIfNew(player, mob:getName()) end
end)

m:addOverride('xi.zones.Rolanberry_Fields.Zone.onMobDeath', function(mob, player, isKiller, noKillIncrement)
    super(mob, player, isKiller, noKillIncrement)
    if player and isKiller then grantIfNew(player, mob:getName()) end
end)

m:addOverride('xi.zones.Valley_of_Sorrows.Zone.onMobDeath', function(mob, player, isKiller, noKillIncrement)
    super(mob, player, isKiller, noKillIncrement)
    if player and isKiller then grantIfNew(player, mob:getName()) end
end)

m:addOverride('xi.zones.Sauromugue_Champaign.Zone.onMobDeath', function(mob, player, isKiller, noKillIncrement)
    super(mob, player, isKiller, noKillIncrement)
    if player and isKiller then grantIfNew(player, mob:getName()) end
end)

m:addOverride('xi.zones.The_Shrine_of_RuAvitau.Zone.onMobDeath', function(mob, player, isKiller, noKillIncrement)
    super(mob, player, isKiller, noKillIncrement)
    if player and isKiller then grantIfNew(player, mob:getName()) end
end)

m:addOverride('xi.zones.Cape_Teriggan.Zone.onMobDeath', function(mob, player, isKiller, noKillIncrement)
    super(mob, player, isKiller, noKillIncrement)
    if player and isKiller then grantIfNew(player, mob:getName()) end
end)

m:addOverride('xi.zones.Riverne-Site_B01.Zone.onMobDeath', function(mob, player, isKiller, noKillIncrement)
    super(mob, player, isKiller, noKillIncrement)
    if player and isKiller then grantIfNew(player, mob:getName()) end
end)

m:addOverride('xi.zones.The_Boyahda_Tree.Zone.onMobDeath', function(mob, player, isKiller, noKillIncrement)
    super(mob, player, isKiller, noKillIncrement)
    if player and isKiller then grantIfNew(player, mob:getName()) end
end)

m:addOverride('xi.zones.Riverne-Site_A01.Zone.onMobDeath', function(mob, player, isKiller, noKillIncrement)
    super(mob, player, isKiller, noKillIncrement)
    if player and isKiller then grantIfNew(player, mob:getName()) end
end)

m:addOverride('xi.zones.Ifrits_Cauldron.Zone.onMobDeath', function(mob, player, isKiller, noKillIncrement)
    super(mob, player, isKiller, noKillIncrement)
    if player and isKiller then grantIfNew(player, mob:getName()) end
end)

m:addOverride('xi.zones.Uleguerand_Range.Zone.onMobDeath', function(mob, player, isKiller, noKillIncrement)
    super(mob, player, isKiller, noKillIncrement)
    if player and isKiller then grantIfNew(player, mob:getName()) end
end)

m:addOverride('xi.zones.Western_Altepa_Desert.Zone.onMobDeath', function(mob, player, isKiller, noKillIncrement)
    super(mob, player, isKiller, noKillIncrement)
    if player and isKiller then grantIfNew(player, mob:getName()) end
end)

m:addOverride('xi.zones.RuAun_Gardens.Zone.onMobDeath', function(mob, player, isKiller, noKillIncrement)
    super(mob, player, isKiller, noKillIncrement)
    if player and isKiller then grantIfNew(player, mob:getName()) end
end)

m:addOverride('xi.zones.Temenos.Zone.onMobDeath', function(mob, player, isKiller, noKillIncrement)
    super(mob, player, isKiller, noKillIncrement)
    if player and isKiller then grantIfNew(player, mob:getName()) end
end)

-----------------------------------
-- Multi-NM zones (Genbu, Seiryu, Suzaku, Kirin all in Hall of the Gods)
-----------------------------------
m:addOverride('xi.zones.Hall_of_the_Gods.Zone.onMobDeath', function(mob, player, isKiller, noKillIncrement)
    super(mob, player, isKiller, noKillIncrement)
    if player and isKiller then grantIfNew(player, mob:getName()) end
end)

-----------------------------------
-- Multi-NM zone (Fafnir cat 16, Nidhogg cat 17 both in Dragon's Aery)
-----------------------------------
m:addOverride('xi.zones.Dragons_Aery.Zone.onMobDeath', function(mob, player, isKiller, noKillIncrement)
    super(mob, player, isKiller, noKillIncrement)
    if player and isKiller then grantIfNew(player, mob:getName()) end
end)

-----------------------------------
-- Multi-NM zone (Khimaira cat 21, Cerberus cat 22 both in King Ranperre's Tomb)
-----------------------------------
m:addOverride('xi.zones.King_Ranperres_Tomb.Zone.onMobDeath', function(mob, player, isKiller, noKillIncrement)
    super(mob, player, isKiller, noKillIncrement)
    if player and isKiller then grantIfNew(player, mob:getName()) end
end)

return m
