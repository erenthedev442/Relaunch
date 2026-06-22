-- Widen char_stats.pet_hp from smallint(4) UNSIGNED (max 65535) to
-- INT UNSIGNED (max ~4.3B) so BST jug pets with HP > 65535 don't
-- silently corrupt saved HP values with an "Out of range" DB error.
ALTER TABLE `char_stats` MODIFY `pet_hp` int(10) unsigned NOT NULL DEFAULT '0';
