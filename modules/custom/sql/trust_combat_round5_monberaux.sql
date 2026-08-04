-- Monberaux: PLD/RUN Chemist. Mix kit is driven by gambit MS SPECIFIC (not TP WS).
-- Keep skill_list EMPTY so the TP system cannot dump Mixes as weaponskills.
-- Potion heal amounts / 5s healing CD are intentional — do not retune lightly.

DELETE FROM `mob_skill_lists` WHERE `skill_list_id` = 1114;

-- PLD/RUN Chemist. No spells. No AA skills on list.
UPDATE `mob_pools` SET
    `mJob` = 7,
    `sJob` = 22,
    `cmbSkill` = 3,
    `cmbDelay` = 240,
    `cmbDmgMult` = 100,
    `skill_list_id` = 1114,
    `spellList` = 0
WHERE `poolid` = 5999;
