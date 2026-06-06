-- ---------------------------------------------------------------------------
-- zz_disable_dead_npcs.sql
--
-- Removes individual NPCs that exist in the world but have NO working function
-- on this server (no onTrigger handler -> "nothing happens" when clicked), so
-- they don't confuse players. Add more here as they're reported.
--
-- zz_ prefix + sql/ location: loads AFTER sql/npc_list.sql (which recreates the
-- table), so these get added then removed. Idempotent. npc_list loads at
-- map-server startup, so a RESTART is required for them to disappear in-game.
-- Reverse: delete the relevant line(s) and re-import sql/npc_list.sql.
-- ---------------------------------------------------------------------------

-- Register of Deeds (3, zones 288/289/291) + Dremi (1, zone 289): no script /
-- no onTrigger -> dead clicks. RoE is reached via the in-client menu, not these
-- NPCs, so removing them doesn't affect Records of Eminence.
DELETE FROM `npc_list` WHERE `polutils_name` IN ('Register of Deeds', 'Dremi');
