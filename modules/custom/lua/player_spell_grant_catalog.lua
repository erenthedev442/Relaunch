-----------------------------------
-- player_spell_grant_catalog.lua
--
-- Spells whose spell_list.jobs column is all-zero are mob/NM-only: mobs may
-- cast them via mob_spell_lists, but players must not see them in the spell
-- menu. Character Upgrader skips these IDs; login backfill strips them once.
--
-- Player-castable custom unlocks (Silencega, Hastega, Meteor II) are removed
-- from this set via spell_list job updates in player_castable_spells.sql.
-----------------------------------
local catalog = {}

catalog.mobOnlySpells =
{
    [26]  = true, -- dia_iv
    [27]  = true, -- dia_v
    [31]  = true, -- banish_iv
    [32]  = true, -- banish_v
    [35]  = true, -- diaga_iii
    [36]  = true, -- diaga_iv
    [37]  = true, -- diaga_v
    [40]  = true, -- banishga_iii
    [41]  = true, -- banishga_iv
    [42]  = true, -- banishga_v
    [177] = true, -- firaga_iv
    [178] = true, -- firaga_v
    [182] = true, -- blizzaga_iv
    [183] = true, -- blizzaga_v
    [187] = true, -- aeroga_iv
    [188] = true, -- aeroga_v
    [192] = true, -- stonega_iv
    [193] = true, -- stonega_v
    [197] = true, -- thundaga_iv
    [198] = true, -- thundaga_v
    [202] = true, -- waterga_iv
    [203] = true, -- waterga_v
    [222] = true, -- poison_iii
    [223] = true, -- poison_iv
    [224] = true, -- poison_v
    [227] = true, -- poisonga_iii
    [228] = true, -- poisonga_iv
    [229] = true, -- poisonga_v
    [233] = true, -- bio_iv
    [234] = true, -- bio_v
    [256] = true, -- virus
    [257] = true, -- curse
    [265] = true, -- tractor_ii
    [340] = true, -- utsusemi_san
    [342] = true, -- jubaku_ni
    [343] = true, -- jubaku_san
    [346] = true, -- hojo_san
    [349] = true, -- kurayami_san
    [351] = true, -- dokumori_ni
    [352] = true, -- dokumori_san
    [356] = true, -- paralyga
    [357] = true, -- slowga
    [361] = true, -- blindga
    [362] = true, -- bindga
    [365] = true, -- breakga
    [366] = true, -- graviga
    [367] = true, -- death
    [375] = true, -- foe_requiem_viii
    [384] = true, -- armys_paeon_vii
    [385] = true, -- armys_paeon_viii
    [407] = true, -- chocobo_hum
    [411] = true, -- jesters_operetta
    [413] = true, -- devotee_serenade
    [416] = true, -- cactuar_fugue
    [418] = true, -- protected_aria
    [423] = true, -- massacre_elegy
    [848] = true, -- reraise_iv
    [855] = true, -- enlight_ii
    [857] = true, -- sandstorm_ii
    [858] = true, -- rainstorm_ii
    [859] = true, -- windstorm_ii
    [860] = true, -- firestorm_ii
    [861] = true, -- hailstorm_ii
    [862] = true, -- thunderstorm_ii
    [863] = true, -- voidstorm_ii
    [864] = true, -- aurorastorm_ii
    [871] = true, -- fire_threnody_ii
    [872] = true, -- ice_threnody_ii
    [873] = true, -- wind_threnody_ii
    [874] = true, -- earth_threnody_ii
    [875] = true, -- ltng_threnody_ii
    [876] = true, -- water_threnody_ii
    [877] = true, -- light_threnody_ii
    [878] = true, -- dark_threnody_ii
    [879] = true, -- inundation
    [881] = true, -- aspir_iii
    [882] = true, -- distract_iii
    [883] = true, -- frazzle_iii
    [884] = true, -- addle_ii
    [893] = true, -- full_cure
    [894] = true, -- refresh_iii
}

return catalog
