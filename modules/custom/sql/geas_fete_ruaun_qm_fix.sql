-- =====================================================================
-- geas_fete_ruaun_qm_fix.sql
-- Escha - Ru'Aun Geas Fete ??? camp fixes:
--   Asida           17961729 — La'Loff wall SW of portal #2
--   Warder of Love  17961734 — overhang NE of portal #7 (sky / camera jank)
--   Hanbi           17961733 — void off bridge near portal #6
--   Vir'ava         17961739 — void off map near portal #12
--   Ark Angel HM    17961742 — void off southern tip near portal #15
--   Ma camp         17961705 — ensure targetable (Ma / Peirithoos / Kouryu)
--   Ark Angel MR    17961777 — hide dead (0,0,0) twin; MR lives on 17961700
-- Relocate onto solid ground. Idempotent. Map restart for NPC moves;
-- Lua QM_POINTS remap is script-reload. Pair with CAMP_SPAWN_NO_SCATTER
-- for bridge/tip camps so the 5–7y spawn ring cannot re-void them.
-- =====================================================================

-- Asida — stock camp beside portal #2 / tribulens plaza.
UPDATE `npc_list`
SET
    pos_x = -290.229,
    pos_y = -42.587,
    pos_z = -399.348
WHERE npcid = 17961729;

-- Warder of Love — stock camp on solid ground near portal #7.
UPDATE `npc_list`
SET
    pos_x = -431.045,
    pos_y = -70.803,
    pos_z =  397.578
WHERE npcid = 17961734;

-- Hanbi — island pad beside portal #6 (was mid-bridge void).
UPDATE `npc_list`
SET
    pos_x = -275.000,
    pos_y =  -3.500,
    pos_z =  380.000
WHERE npcid = 17961733;

-- Vir'ava — island pad beside portal #12 (was off-map at Y=-24).
UPDATE `npc_list`
SET
    pos_x =  448.000,
    pos_y =   -3.600,
    pos_z = -140.000
WHERE npcid = 17961739;

-- Ark Angel HM — inland of portal #15 tip (was on the southern edge).
UPDATE `npc_list`
SET
    pos_x =   -1.000,
    pos_y =  -52.000,
    pos_z = -555.000
WHERE npcid = 17961742;

-- Ma / Peirithoos / Kouryu — keep the clickable twin targetable.
UPDATE `npc_list`
SET
    flag         = 1,
    animation    = 0,
    animationsub = 0,
    namevis      = 112,
    status       = 0,
    entityFlags  = 3,
    look         = 0x0000340000000000000000000000000000000000,
    name_prefix  = 2,
    widescan     = 1
WHERE npcid = 17961705;

-- Ark Angel MR's old ??? sat at (0,0,0) (zone-center void). Menu moved to
-- 17961700 in Geas_Fete.lua; hide this stub so warps/lookups can't hit it.
UPDATE `npc_list`
SET
    status = 2
WHERE npcid = 17961777;
