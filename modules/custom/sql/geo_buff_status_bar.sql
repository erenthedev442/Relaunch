-- Pin GEO ally buffs + Colure near the top of the status bar (sort_key 90,
-- just before Haste at 100). Default 0 maps to 10000 and they were last,
-- so a full buff bar hid Indi-Fury / Entrust.
UPDATE `status_effects`
SET `sort_key` = 90
WHERE `id` IN (539, 541, 542, 543, 544, 545, 546, 547, 548, 549, 550, 551, 552, 553, 554, 555, 556, 580, 612);
