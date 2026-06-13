-- Global server linkshell "Legendary".
-- Idempotent: only inserts when no linkshell with this name exists yet, so a
-- re-run or a dbtool re-import is safe. linkshellid auto-increments (it is the
-- first/only linkshell on this server). Handed to every character by
-- modules/custom/lua/new_player_linkshell.lua via player:addLinkpearl(), which
-- looks the linkshell up by name and stamps the pearl's exdata from this row.
INSERT INTO `linkshells` (`name`, `color`, `broken`)
SELECT 'Legendary', 61440, 0
FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM `linkshells` WHERE `name` = 'Legendary');
