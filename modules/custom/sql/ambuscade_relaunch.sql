-- ambuscade_relaunch.sql
-- Makes Ambuscade (instance 30000, zone 287 Maquette_Abdhaljs-Legion_B) actually
-- spawn its mobs. Canonical replacement for the old sql/ambuscade_adds.sql, which
-- (a) lived outside modules/custom/sql/ so no deploy ever applied it, and
-- (b) never registered the adds in instance_entities, so even applied they could
--     not load (CInstanceLoader only loads mobs joined through instance_entities).
-- Idempotent: safe to re-apply on every deploy.
--
-- Player-visible bug this fixes: "Ambuscade has no mobs and no rewards" -- the
-- instance loaded empty (no mobs -> the all-dead check never fired -> no clear
-- -> no Hallmarks/Gallantry).
--
-- Mobs load at INSTANCE CREATION (instance_loader queries the DB per createInstance),
-- so this takes effect on the next Tome entry with NO map restart. The Mhaura
-- Voucher Clerk NPC at the bottom is the one restart-gated piece (zone-boot npc_list).

-- ─── [1] Repair the Breadwinner's orphaned group ──────────────────────────────
-- Upstream renumbered the Bozzetto_Breadwinner pool 30000 -> 30001 ("Zdei family
-- skill and behavior adjustments") but group 38 kept poolid 30000, which no longer
-- exists. The loader's INNER JOIN mob_pools therefore dropped the boss entirely.
UPDATE mob_groups SET poolid = 30001
WHERE groupid = 38 AND zoneid = 287 AND poolid = 30000;

-- ─── [2] Bozzetto Urchin (adds) + Ambuscade Housemaker (passive structure) ────
DELETE FROM mob_pools WHERE poolid IN (30003, 30004);
INSERT INTO mob_pools
    (poolid, name, packet_name, speciesid, modelid,
     mJob, sJob, cmbSkill, cmbDelay, cmbDmgMult,
     behavior, aggro, true_detection, links, mobType, immunity,
     name_prefix, flag, entityFlags, animationsub,
     hasSpellScript, spellList, namevis, roamflag, skill_list_id, resist_id)
VALUES
    -- Urchin: aggressive meeble add; uses the Bozzetto skill list (30000) so it
    -- fights like its family instead of never using TP moves.
    (30003, 'Bozzetto_Urchin', 'Bozzetto Urchin', 136,
     0x0000B40700000000000000000000000000000000,
     2, 0, 1, 240, 100,
     0, 1, 0, 1, 34, 0,
     32, 0, 3, 0,
     0, 0, 0, 0, 30000, 506),
    -- Housemaker: passive "structure" mob (aggro 0, links 0); buffs the boss
    -- while alive (handled in its mob script).
    (30004, 'Ambuscade_Housemaker', 'Ambuscade Housemaker', 136,
     0x0000B40700000000000000000000000000000000,
     2, 0, 1, 240, 50,
     128, 0, 0, 0, 0, 0,
     32, 0, 3, 0,
     0, 0, 0, 0, 0, 506);

-- Zone-scoped deletes (mob_groups groupids are only unique per zone).
DELETE FROM mob_groups WHERE groupid IN (20024, 20025) AND zoneid = 287;
INSERT INTO mob_groups
    (groupid, poolid, zoneid, name, respawntime, spawntype, dropid, HP, MP, allegiance, content_tag)
VALUES
    (20024, 30003, 287, 'Bozzetto_Urchin',      0, 0,   0,  60000, 0, 0, NULL),
    (20025, 30004, 287, 'Ambuscade_Housemaker', 0, 128, 0, 120000, 0, 0, NULL);

DELETE FROM mob_spawn_points WHERE mobid BETWEEN 17952868 AND 17952872;
INSERT INTO mob_spawn_points
    (mobid, spawnslotid, mobname, polutils_name, groupid, minLevel, maxLevel, pos_x, pos_y, pos_z, pos_rot)
VALUES
    (17952868, 0, 'Bozzetto_Urchin',      'Bozzetto Urchin',      20024, 119, 0, 155.0, 12.0, -155.0, 0),
    (17952869, 0, 'Bozzetto_Urchin',      'Bozzetto Urchin',      20024, 119, 0, 165.0, 12.0, -155.0, 64),
    (17952870, 0, 'Bozzetto_Urchin',      'Bozzetto Urchin',      20024, 119, 0, 155.0, 12.0, -165.0, 192),
    (17952871, 0, 'Bozzetto_Urchin',      'Bozzetto Urchin',      20024, 119, 0, 165.0, 12.0, -165.0, 128),
    (17952872, 0, 'Ambuscade_Housemaker', 'Ambuscade Housemaker', 20025, 119, 0, 140.0, 12.0, -180.0, 0);

-- ─── [3] Register the adds in instance 30000 (THE missing link) ───────────────
-- Stock instance_entities only lists the Breadwinner (17952867). Without these
-- rows the loader never materializes the adds, so SpawnMob() silently no-ops.
DELETE FROM instance_entities WHERE instanceid = 30000 AND id BETWEEN 17952868 AND 17952872;
INSERT INTO instance_entities (instanceid, id) VALUES
    (30000, 17952868),
    (30000, 17952869),
    (30000, 17952870),
    (30000, 17952871),
    (30000, 17952872);

-- ─── [4] Ambuscade Voucher Clerk (Mhaura 249; RESTART-GATED zone-boot NPC) ────
-- Clones Gorpa-Masorpa's look so it renders; script: Mhaura/npcs/Ambuscade_Voucher_Clerk.lua
DELETE FROM npc_list WHERE npcid = 17797276;
INSERT INTO npc_list
    (npcid, name, polutils_name, pos_rot, pos_x, pos_y, pos_z,
     flag, speed, speedsub, animation, animationsub,
     namevis, status, entityFlags, look, name_prefix, content_tag, widescan)
SELECT
    17797276, 'Ambuscade_Voucher_Clerk', 'Ambuscade Voucher Clerk',
    104, -26.600, -15.990, 52.565,
    0, 40, 40, 0, 0,
    1, 0, 0, look, 0, NULL, 1
FROM npc_list WHERE npcid = 17797274;
