-- Ambuscade adds: Bozzetto Urchin + Ambuscade Housemaker + Voucher Clerk NPC
-- Run this on xi_relaunch ONCE before restarting xi_map.
-- Pre-check: these IDs must be free.
--   SELECT * FROM mob_pools  WHERE poolid  IN (30003,30004);
--   SELECT * FROM mob_groups WHERE groupid IN (20024,20025);
--   SELECT * FROM mob_spawn_points WHERE mobid BETWEEN 17952868 AND 17952872;
--   SELECT * FROM npc_list WHERE npcid=17797276;

-- ─── Bozzetto Urchin ──────────────────────────────────────────────────────────
-- Small aggressive Meeble-family adds that spawn with the Breadwinner.
-- Same species/model as the Breadwinner (placeholder; swap modelid later if desired).

INSERT INTO mob_pools
    (poolid, name, packet_name, speciesid, modelid,
     mJob, sJob, cmbDelay, cmbDmgMult,
     behavior, aggro, true_detection, links, mobType, immunity,
     name_prefix, flag, entityFlags, animationsub,
     hasSpellScript, spellList, namevis, roamflag, skill_list_id, resist_id)
VALUES
    (30003, 'Bozzetto_Urchin', 'Bozzetto Urchin', 136,
     0x0000B40700000000000000000000000000000000,
     2, 0, 240, 100,
     0, 1, 0, 1, 34, 0,
     0, 0, 0, 0,
     0, 0, 1, 0, 0, 0);

-- groupid 20024 → zone 287, Urchin pool, HP=60000 (scaled by difficulty in Lua)
INSERT INTO mob_groups
    (groupid, poolid, zoneid, name, respawntime, spawntype, dropid, HP, MP, allegiance, content_tag)
VALUES
    (20024, 30003, 287, 'Bozzetto_Urchin', 0, 0, 0, 60000, 0, 0, NULL);

-- Four Urchin spawn slots (only as many as the difficulty warrants are activated)
INSERT INTO mob_spawn_points
    (mobid, spawnslotid, mobname, polutils_name, groupid, minLevel, maxLevel, pos_x, pos_y, pos_z, pos_rot)
VALUES
    (17952868, 0, 'Bozzetto_Urchin', 'Bozzetto Urchin', 20024, 119, 0, 155.0, 12.0, -155.0, 0),
    (17952869, 0, 'Bozzetto_Urchin', 'Bozzetto Urchin', 20024, 119, 0, 165.0, 12.0, -155.0, 64),
    (17952870, 0, 'Bozzetto_Urchin', 'Bozzetto Urchin', 20024, 119, 0, 155.0, 12.0, -165.0, 192),
    (17952871, 0, 'Bozzetto_Urchin', 'Bozzetto Urchin', 20024, 119, 0, 165.0, 12.0, -165.0, 128);

-- ─── Ambuscade Housemaker ────────────────────────────────────────────────────
-- Passive structure-like mob. Doesn't attack. While alive, buffs Breadwinner.
-- aggro=0, links=0, high defence (handled in Lua via resist_id / skill_list_id).

INSERT INTO mob_pools
    (poolid, name, packet_name, speciesid, modelid,
     mJob, sJob, cmbDelay, cmbDmgMult,
     behavior, aggro, true_detection, links, mobType, immunity,
     name_prefix, flag, entityFlags, animationsub,
     hasSpellScript, spellList, namevis, roamflag, skill_list_id, resist_id)
VALUES
    (30004, 'Ambuscade_Housemaker', 'Ambuscade Housemaker', 136,
     0x0000B40700000000000000000000000000000000,
     2, 0, 240, 50,
     128, 0, 0, 0, 0, 0,
     0, 0, 0, 0,
     0, 0, 1, 0, 0, 0);

-- groupid 20025 → zone 287, Housemaker pool, HP=120000
INSERT INTO mob_groups
    (groupid, poolid, zoneid, name, respawntime, spawntype, dropid, HP, MP, allegiance, content_tag)
VALUES
    (20025, 30004, 287, 'Ambuscade_Housemaker', 0, 128, 0, 120000, 0, 0, NULL);

-- One Housemaker spawn at the south end of the zone (away from Breadwinner entry)
INSERT INTO mob_spawn_points
    (mobid, spawnslotid, mobname, polutils_name, groupid, minLevel, maxLevel, pos_x, pos_y, pos_z, pos_rot)
VALUES
    (17952872, 0, 'Ambuscade_Housemaker', 'Ambuscade Housemaker', 20025, 119, 0, 140.0, 12.0, -180.0, 0);

-- ─── Ambuscade Voucher Clerk (Mhaura, zone 249) ──────────────────────────────
-- Placed next to Gorpa-Masorpa (-27.584, -15.99, 52.565).
-- polutils_name must match the NPC script filename prefix.
-- look: use Gorpa-Masorpa's look field as a placeholder (Hume male NPC).

INSERT INTO npc_list
    (npcid, name, polutils_name,
     pos_rot, pos_x, pos_y, pos_z,
     flag, speed, speedsub, animation, animationsub,
     namevis, status, entityFlags, look,
     name_prefix, content_tag, widescan)
SELECT
    17797276,
    'Ambuscade_Voucher_Clerk',
    'Ambuscade Voucher Clerk',
    104,          -- same facing as Gorpa-Masorpa
    -26.600,      -- slightly west of Gorpa
    -15.990,
    52.565,
    0, 40, 40, 0, 0,
    1, 0, 0,
    look,         -- clone Gorpa's look
    0, NULL, 1
FROM npc_list WHERE npcid = 17797274;  -- 17797274 = Gorpa-Masorpa
