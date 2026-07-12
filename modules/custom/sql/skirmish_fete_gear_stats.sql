-- skirmish_fete_gear_stats.sql
-- item_mods for the 69 reward items that shipped with NO stats in the
-- stock data: the Escha Zi'Tah T1 fete armor lines (Naga/Psycloth/Rawhide/
-- Pursuer's/Despair/Eschite/Vanya), assorted fete accessories, and Svalinn.
-- Stats parsed from BG-Wiki item pages (fetched 2026-07-12) with
-- tools/gen_naked_item_stats.py's parser -- the same pipeline as
-- zz_custom_naked_item_mods.sql. IDEMPOTENT: safe to re-run every deploy.

DELETE FROM `item_mods` WHERE `itemId` IN (25703,25706,25728,26161,26162,26322,26791,26792,26793,26794,26795,26796,26797,26947,26948,26949,26950,26951,26952,26953,26958,26959,26961,26962,27097,27098,27099,27100,27101,27102,27103,27104,27134,27282,27283,27284,27285,27286,27287,27288,27319,27320,27457,27458,27459,27460,27461,27462,27464,27511,27512,27513,27514,27521,27522,27523,27536,27538,27545,27552,27554,27606,27607,27612,27613,27614,27617,27627,27642);

-- Uac Jerkin (uac_jerkin)  https://www.bg-wiki.com/ffxi/Uac_Jerkin
INSERT INTO `item_mods` VALUES (25703,384,300); -- HASTE_GEAR: 3
INSERT INTO `item_mods` VALUES (25703,288,3); -- DOUBLE_ATTACK: 3
INSERT INTO `item_mods` VALUES (25703,165,3); -- CRITHITRATE: 3
INSERT INTO `item_mods` VALUES (25703,29,4); -- MDEF: 4
INSERT INTO `item_mods` VALUES (25703,31,48); -- MEVA: 48
INSERT INTO `item_mods` VALUES (25703,23,20); -- ATT: 20
INSERT INTO `item_mods` VALUES (25703,68,41); -- EVA: 41
INSERT INTO `item_mods` VALUES (25703,1,142); -- DEF: 142
INSERT INTO `item_mods` VALUES (25703,2,63); -- HP: 63
INSERT INTO `item_mods` VALUES (25703,5,35); -- MP: 35
INSERT INTO `item_mods` VALUES (25703,8,29); -- STR: 29
INSERT INTO `item_mods` VALUES (25703,9,19); -- DEX: 19
INSERT INTO `item_mods` VALUES (25703,10,29); -- VIT: 29
INSERT INTO `item_mods` VALUES (25703,11,19); -- AGI: 19
INSERT INTO `item_mods` VALUES (25703,12,19); -- INT: 19
INSERT INTO `item_mods` VALUES (25703,13,19); -- MND: 19
INSERT INTO `item_mods` VALUES (25703,14,19); -- CHR: 19
INSERT INTO `item_mods` VALUES (25703,174,5); -- SKILLCHAINBONUS: 5

-- Shango Robe (shango_robe)  https://www.bg-wiki.com/ffxi/Shango_Robe
INSERT INTO `item_mods` VALUES (25706,384,300); -- HASTE_GEAR: 3
INSERT INTO `item_mods` VALUES (25706,29,6); -- MDEF: 6
INSERT INTO `item_mods` VALUES (25706,30,23); -- MACC: 23
INSERT INTO `item_mods` VALUES (25706,31,80); -- MEVA: 80
INSERT INTO `item_mods` VALUES (25706,170,8); -- FASTCAST: 8
INSERT INTO `item_mods` VALUES (25706,68,41); -- EVA: 41
INSERT INTO `item_mods` VALUES (25706,114,15); -- ENFEEBLE: 15
INSERT INTO `item_mods` VALUES (25706,116,15); -- DARK: 15
INSERT INTO `item_mods` VALUES (25706,1,124); -- DEF: 124
INSERT INTO `item_mods` VALUES (25706,2,54); -- HP: 54
INSERT INTO `item_mods` VALUES (25706,5,59); -- MP: 59
INSERT INTO `item_mods` VALUES (25706,8,21); -- STR: 21
INSERT INTO `item_mods` VALUES (25706,9,21); -- DEX: 21
INSERT INTO `item_mods` VALUES (25706,10,21); -- VIT: 21
INSERT INTO `item_mods` VALUES (25706,11,21); -- AGI: 21
INSERT INTO `item_mods` VALUES (25706,12,29); -- INT: 29
INSERT INTO `item_mods` VALUES (25706,13,29); -- MND: 29
INSERT INTO `item_mods` VALUES (25706,14,29); -- CHR: 29

-- Zendik Robe (zendik_robe)  https://www.bg-wiki.com/ffxi/Zendik_Robe
--   unparsed tokens (verify by hand): Sphere
INSERT INTO `item_mods` VALUES (25728,384,400); -- HASTE_GEAR: 4
INSERT INTO `item_mods` VALUES (25728,29,7); -- MDEF: 7
INSERT INTO `item_mods` VALUES (25728,28,10); -- MATT: 10
INSERT INTO `item_mods` VALUES (25728,30,45); -- MACC: 45
INSERT INTO `item_mods` VALUES (25728,31,86); -- MEVA: 86
INSERT INTO `item_mods` VALUES (25728,170,13); -- FASTCAST: 13
INSERT INTO `item_mods` VALUES (25728,68,41); -- EVA: 41
INSERT INTO `item_mods` VALUES (25728,27,-13); -- ENMITY: -13
INSERT INTO `item_mods` VALUES (25728,1,136); -- DEF: 136
INSERT INTO `item_mods` VALUES (25728,2,57); -- HP: 57
INSERT INTO `item_mods` VALUES (25728,5,61); -- MP: 61
INSERT INTO `item_mods` VALUES (25728,8,24); -- STR: 24
INSERT INTO `item_mods` VALUES (25728,9,20); -- DEX: 20
INSERT INTO `item_mods` VALUES (25728,10,20); -- VIT: 20
INSERT INTO `item_mods` VALUES (25728,11,20); -- AGI: 20
INSERT INTO `item_mods` VALUES (25728,12,38); -- INT: 38
INSERT INTO `item_mods` VALUES (25728,13,38); -- MND: 38
INSERT INTO `item_mods` VALUES (25728,14,32); -- CHR: 32

-- Shukuyu Ring (shukuyu_ring)  https://www.bg-wiki.com/ffxi/Shukuyu_Ring
INSERT INTO `item_mods` VALUES (26161,31,5); -- MEVA: 5
INSERT INTO `item_mods` VALUES (26161,23,15); -- ATT: 15
INSERT INTO `item_mods` VALUES (26161,8,7); -- STR: 7

-- Rahab Ring (rahab_ring)  https://www.bg-wiki.com/ffxi/Rahab_Ring
INSERT INTO `item_mods` VALUES (26162,30,5); -- MACC: 5
INSERT INTO `item_mods` VALUES (26162,170,2); -- FASTCAST: 2
INSERT INTO `item_mods` VALUES (26162,5,30); -- MP: 30

-- Kerygma Belt (kerygma_belt)  https://www.bg-wiki.com/ffxi/Kerygma_Belt
INSERT INTO `item_mods` VALUES (26322,288,3); -- DOUBLE_ATTACK: 3
INSERT INTO `item_mods` VALUES (26322,73,5); -- STORETP: 5
INSERT INTO `item_mods` VALUES (26322,25,5); -- ACC: 5

-- Eschite Helm (eschite_helm)  https://www.bg-wiki.com/ffxi/Eschite_Helm
--   unparsed tokens (verify by hand): Great
INSERT INTO `item_mods` VALUES (26791,384,700); -- HASTE_GEAR: 7
INSERT INTO `item_mods` VALUES (26791,29,2); -- MDEF: 2
INSERT INTO `item_mods` VALUES (26791,30,20); -- MACC: 20
INSERT INTO `item_mods` VALUES (26791,31,32); -- MEVA: 32
INSERT INTO `item_mods` VALUES (26791,25,15); -- ACC: 15
INSERT INTO `item_mods` VALUES (26791,23,15); -- ATT: 15
INSERT INTO `item_mods` VALUES (26791,68,33); -- EVA: 33
INSERT INTO `item_mods` VALUES (26791,85,15); -- GAXE: 15 (retail 'Great Axe skill +15'; parser dropped the 'Great')
INSERT INTO `item_mods` VALUES (26791,1,116); -- DEF: 116
INSERT INTO `item_mods` VALUES (26791,2,41); -- HP: 41
INSERT INTO `item_mods` VALUES (26791,5,23); -- MP: 23
INSERT INTO `item_mods` VALUES (26791,8,25); -- STR: 25
INSERT INTO `item_mods` VALUES (26791,9,17); -- DEX: 17
INSERT INTO `item_mods` VALUES (26791,10,25); -- VIT: 25
INSERT INTO `item_mods` VALUES (26791,11,17); -- AGI: 17
INSERT INTO `item_mods` VALUES (26791,12,15); -- INT: 15
INSERT INTO `item_mods` VALUES (26791,13,15); -- MND: 15
INSERT INTO `item_mods` VALUES (26791,14,15); -- CHR: 15

-- Despair Helm (despair_helm)  https://www.bg-wiki.com/ffxi/Despair_Helm
--   unparsed tokens (verify by hand): Pet
INSERT INTO `item_mods` VALUES (26792,384,800); -- HASTE_GEAR: 8
INSERT INTO `item_mods` VALUES (26792,29,2); -- MDEF: 2
INSERT INTO `item_mods` VALUES (26792,31,53); -- MEVA: 53
INSERT INTO `item_mods` VALUES (26792,26,20); -- RACC: 20
INSERT INTO `item_mods` VALUES (26792,24,20); -- RATT: 20
INSERT INTO `item_mods` VALUES (26792,25,20); -- ACC: 20
INSERT INTO `item_mods` VALUES (26792,23,20); -- ATT: 20
INSERT INTO `item_mods` VALUES (26792,68,36); -- EVA: 36
INSERT INTO `item_mods` VALUES (26792,1,113); -- DEF: 113
INSERT INTO `item_mods` VALUES (26792,2,38); -- HP: 38
INSERT INTO `item_mods` VALUES (26792,8,21); -- STR: 21
INSERT INTO `item_mods` VALUES (26792,9,21); -- DEX: 21
INSERT INTO `item_mods` VALUES (26792,10,20); -- VIT: 20
INSERT INTO `item_mods` VALUES (26792,11,20); -- AGI: 20
INSERT INTO `item_mods` VALUES (26792,12,20); -- INT: 20
INSERT INTO `item_mods` VALUES (26792,13,20); -- MND: 20
INSERT INTO `item_mods` VALUES (26792,14,20); -- CHR: 20

-- Naga Somen (naga_somen)  https://www.bg-wiki.com/ffxi/Naga_Somen
INSERT INTO `item_mods` VALUES (26793,163,-300); -- DMGMAGIC: -3
INSERT INTO `item_mods` VALUES (26793,384,800); -- HASTE_GEAR: 8
INSERT INTO `item_mods` VALUES (26793,29,4); -- MDEF: 4
INSERT INTO `item_mods` VALUES (26793,31,43); -- MEVA: 43
INSERT INTO `item_mods` VALUES (26793,25,18); -- ACC: 18
INSERT INTO `item_mods` VALUES (26793,68,38); -- EVA: 38
INSERT INTO `item_mods` VALUES (26793,1,98); -- DEF: 98
INSERT INTO `item_mods` VALUES (26793,2,86); -- HP: 86
INSERT INTO `item_mods` VALUES (26793,8,17); -- STR: 17
INSERT INTO `item_mods` VALUES (26793,9,24); -- DEX: 24
INSERT INTO `item_mods` VALUES (26793,10,19); -- VIT: 19
INSERT INTO `item_mods` VALUES (26793,11,19); -- AGI: 19
INSERT INTO `item_mods` VALUES (26793,12,18); -- INT: 18
INSERT INTO `item_mods` VALUES (26793,13,18); -- MND: 18
INSERT INTO `item_mods` VALUES (26793,14,18); -- CHR: 18

-- Rawhide Mask (rawhide_mask)  https://www.bg-wiki.com/ffxi/Rawhide_Mask
INSERT INTO `item_mods` VALUES (26794,384,800); -- HASTE_GEAR: 8
INSERT INTO `item_mods` VALUES (26794,29,2); -- MDEF: 2
INSERT INTO `item_mods` VALUES (26794,31,53); -- MEVA: 53
INSERT INTO `item_mods` VALUES (26794,23,18); -- ATT: 18
INSERT INTO `item_mods` VALUES (26794,68,44); -- EVA: 44
INSERT INTO `item_mods` VALUES (26794,1,100); -- DEF: 100
INSERT INTO `item_mods` VALUES (26794,2,36); -- HP: 36
INSERT INTO `item_mods` VALUES (26794,5,23); -- MP: 23
INSERT INTO `item_mods` VALUES (26794,8,18); -- STR: 18
INSERT INTO `item_mods` VALUES (26794,9,26); -- DEX: 26
INSERT INTO `item_mods` VALUES (26794,10,18); -- VIT: 18
INSERT INTO `item_mods` VALUES (26794,11,26); -- AGI: 26
INSERT INTO `item_mods` VALUES (26794,12,18); -- INT: 18
INSERT INTO `item_mods` VALUES (26794,13,18); -- MND: 18
INSERT INTO `item_mods` VALUES (26794,14,19); -- CHR: 19
INSERT INTO `item_mods` VALUES (26794,369,1); -- REFRESH: 1

-- Pursuer's Beret (pursuers_beret)  https://www.bg-wiki.com/ffxi/Pursuer's_Beret
INSERT INTO `item_mods` VALUES (26795,384,800); -- HASTE_GEAR: 8
INSERT INTO `item_mods` VALUES (26795,73,5); -- STORETP: 5
INSERT INTO `item_mods` VALUES (26795,29,2); -- MDEF: 2
INSERT INTO `item_mods` VALUES (26795,31,53); -- MEVA: 53
INSERT INTO `item_mods` VALUES (26795,24,23); -- RATT: 23
INSERT INTO `item_mods` VALUES (26795,68,44); -- EVA: 44
INSERT INTO `item_mods` VALUES (26795,105,15); -- MARKSMAN: 15
INSERT INTO `item_mods` VALUES (26795,1,97); -- DEF: 97
INSERT INTO `item_mods` VALUES (26795,2,36); -- HP: 36
INSERT INTO `item_mods` VALUES (26795,8,22); -- STR: 22
INSERT INTO `item_mods` VALUES (26795,9,23); -- DEX: 23
INSERT INTO `item_mods` VALUES (26795,10,16); -- VIT: 16
INSERT INTO `item_mods` VALUES (26795,11,28); -- AGI: 28
INSERT INTO `item_mods` VALUES (26795,12,19); -- INT: 19
INSERT INTO `item_mods` VALUES (26795,13,19); -- MND: 19
INSERT INTO `item_mods` VALUES (26795,14,20); -- CHR: 20

-- Psycloth Tiara (psycloth_tiara)  https://www.bg-wiki.com/ffxi/Psycloth_Tiara
--   unparsed tokens (verify by hand): Avatar
INSERT INTO `item_mods` VALUES (26796,384,600); -- HASTE_GEAR: 6
INSERT INTO `item_mods` VALUES (26796,29,5); -- MDEF: 5
INSERT INTO `item_mods` VALUES (26796,28,20); -- MATT: 20
INSERT INTO `item_mods` VALUES (26796,31,75); -- MEVA: 75
INSERT INTO `item_mods` VALUES (26796,68,36); -- EVA: 36
INSERT INTO `item_mods` VALUES (26796,27,-6); -- ENMITY: -6
INSERT INTO `item_mods` VALUES (26796,117,15); -- SUMMONING: 15
INSERT INTO `item_mods` VALUES (26796,1,94); -- DEF: 94
INSERT INTO `item_mods` VALUES (26796,2,36); -- HP: 36
INSERT INTO `item_mods` VALUES (26796,5,32); -- MP: 32
INSERT INTO `item_mods` VALUES (26796,8,18); -- STR: 18
INSERT INTO `item_mods` VALUES (26796,9,18); -- DEX: 18
INSERT INTO `item_mods` VALUES (26796,10,18); -- VIT: 18
INSERT INTO `item_mods` VALUES (26796,11,18); -- AGI: 18
INSERT INTO `item_mods` VALUES (26796,12,26); -- INT: 26
INSERT INTO `item_mods` VALUES (26796,13,26); -- MND: 26
INSERT INTO `item_mods` VALUES (26796,14,23); -- CHR: 23

-- Vanya Hood (vanya_hood)  https://www.bg-wiki.com/ffxi/Vanya_Hood
--   unparsed tokens (verify by hand): Conserve; MP
INSERT INTO `item_mods` VALUES (26797,163,-200); -- DMGMAGIC: -2
INSERT INTO `item_mods` VALUES (26797,384,600); -- HASTE_GEAR: 6
INSERT INTO `item_mods` VALUES (26797,29,5); -- MDEF: 5
INSERT INTO `item_mods` VALUES (26797,31,75); -- MEVA: 75
INSERT INTO `item_mods` VALUES (26797,374,10); -- CURE_POTENCY: 10
INSERT INTO `item_mods` VALUES (26797,68,36); -- EVA: 36
INSERT INTO `item_mods` VALUES (26797,1,99); -- DEF: 99
INSERT INTO `item_mods` VALUES (26797,2,36); -- HP: 36
INSERT INTO `item_mods` VALUES (26797,5,32); -- MP: 32
INSERT INTO `item_mods` VALUES (26797,8,18); -- STR: 18
INSERT INTO `item_mods` VALUES (26797,9,18); -- DEX: 18
INSERT INTO `item_mods` VALUES (26797,10,18); -- VIT: 18
INSERT INTO `item_mods` VALUES (26797,11,18); -- AGI: 18
INSERT INTO `item_mods` VALUES (26797,12,23); -- INT: 23
INSERT INTO `item_mods` VALUES (26797,13,27); -- MND: 27
INSERT INTO `item_mods` VALUES (26797,14,27); -- CHR: 27

-- Eschite Breastplate (eschite_breastplate)  https://www.bg-wiki.com/ffxi/Eschite_Breastplate
INSERT INTO `item_mods` VALUES (26947,384,300); -- HASTE_GEAR: 3
INSERT INTO `item_mods` VALUES (26947,29,4); -- MDEF: 4
INSERT INTO `item_mods` VALUES (26947,31,48); -- MEVA: 48
INSERT INTO `item_mods` VALUES (26947,23,20); -- ATT: 20
INSERT INTO `item_mods` VALUES (26947,68,41); -- EVA: 41
INSERT INTO `item_mods` VALUES (26947,1,148); -- DEF: 148
INSERT INTO `item_mods` VALUES (26947,2,153); -- HP: 153
INSERT INTO `item_mods` VALUES (26947,5,35); -- MP: 35
INSERT INTO `item_mods` VALUES (26947,8,34); -- STR: 34
INSERT INTO `item_mods` VALUES (26947,9,19); -- DEX: 19
INSERT INTO `item_mods` VALUES (26947,10,34); -- VIT: 34
INSERT INTO `item_mods` VALUES (26947,11,19); -- AGI: 19
INSERT INTO `item_mods` VALUES (26947,12,19); -- INT: 19
INSERT INTO `item_mods` VALUES (26947,13,19); -- MND: 19
INSERT INTO `item_mods` VALUES (26947,14,19); -- CHR: 19

-- Despair Mail (despair_mail)  https://www.bg-wiki.com/ffxi/Despair_Mail
--   unparsed tokens (verify by hand): Pet
INSERT INTO `item_mods` VALUES (26948,384,400); -- HASTE_GEAR: 4
INSERT INTO `item_mods` VALUES (26948,288,3); -- DOUBLE_ATTACK: 3
INSERT INTO `item_mods` VALUES (26948,29,5); -- MDEF: 5
INSERT INTO `item_mods` VALUES (26948,31,64); -- MEVA: 64
INSERT INTO `item_mods` VALUES (26948,25,23); -- ACC: 23
INSERT INTO `item_mods` VALUES (26948,68,44); -- EVA: 44
INSERT INTO `item_mods` VALUES (26948,1,143); -- DEF: 143
INSERT INTO `item_mods` VALUES (26948,2,121); -- HP: 121
INSERT INTO `item_mods` VALUES (26948,8,30); -- STR: 30
INSERT INTO `item_mods` VALUES (26948,9,29); -- DEX: 29
INSERT INTO `item_mods` VALUES (26948,10,30); -- VIT: 30
INSERT INTO `item_mods` VALUES (26948,11,23); -- AGI: 23
INSERT INTO `item_mods` VALUES (26948,12,23); -- INT: 23
INSERT INTO `item_mods` VALUES (26948,13,23); -- MND: 23
INSERT INTO `item_mods` VALUES (26948,14,23); -- CHR: 23

-- Naga Samue (naga_samue)  https://www.bg-wiki.com/ffxi/Naga_Samue
INSERT INTO `item_mods` VALUES (26949,384,400); -- HASTE_GEAR: 4
INSERT INTO `item_mods` VALUES (26949,73,5); -- STORETP: 5
INSERT INTO `item_mods` VALUES (26949,29,4); -- MDEF: 4
INSERT INTO `item_mods` VALUES (26949,31,53); -- MEVA: 53
INSERT INTO `item_mods` VALUES (26949,23,15); -- ATT: 15
INSERT INTO `item_mods` VALUES (26949,68,52); -- EVA: 52
INSERT INTO `item_mods` VALUES (26949,1,124); -- DEF: 124
INSERT INTO `item_mods` VALUES (26949,2,119); -- HP: 119
INSERT INTO `item_mods` VALUES (26949,8,29); -- STR: 29
INSERT INTO `item_mods` VALUES (26949,9,30); -- DEX: 30
INSERT INTO `item_mods` VALUES (26949,10,23); -- VIT: 23
INSERT INTO `item_mods` VALUES (26949,11,27); -- AGI: 27
INSERT INTO `item_mods` VALUES (26949,12,26); -- INT: 26
INSERT INTO `item_mods` VALUES (26949,13,26); -- MND: 26
INSERT INTO `item_mods` VALUES (26949,14,26); -- CHR: 26

-- Rawhide Vest (rawhide_vest)  https://www.bg-wiki.com/ffxi/Rawhide_Vest
INSERT INTO `item_mods` VALUES (26950,384,400); -- HASTE_GEAR: 4
INSERT INTO `item_mods` VALUES (26950,302,2); -- TRIPLE_ATTACK: 2
INSERT INTO `item_mods` VALUES (26950,29,6); -- MDEF: 6
INSERT INTO `item_mods` VALUES (26950,28,25); -- MATT: 25
INSERT INTO `item_mods` VALUES (26950,31,64); -- MEVA: 64
INSERT INTO `item_mods` VALUES (26950,25,15); -- ACC: 15
INSERT INTO `item_mods` VALUES (26950,23,15); -- ATT: 15
INSERT INTO `item_mods` VALUES (26950,68,49); -- EVA: 49
INSERT INTO `item_mods` VALUES (26950,1,130); -- DEF: 130
INSERT INTO `item_mods` VALUES (26950,2,59); -- HP: 59
INSERT INTO `item_mods` VALUES (26950,5,44); -- MP: 44
INSERT INTO `item_mods` VALUES (26950,8,30); -- STR: 30
INSERT INTO `item_mods` VALUES (26950,9,35); -- DEX: 35
INSERT INTO `item_mods` VALUES (26950,10,26); -- VIT: 26
INSERT INTO `item_mods` VALUES (26950,11,30); -- AGI: 30
INSERT INTO `item_mods` VALUES (26950,12,25); -- INT: 25
INSERT INTO `item_mods` VALUES (26950,13,25); -- MND: 25
INSERT INTO `item_mods` VALUES (26950,14,25); -- CHR: 25

-- Pursuer's Doublet (pursuers_doublet)  https://www.bg-wiki.com/ffxi/Pursuer's_Doublet
INSERT INTO `item_mods` VALUES (26951,384,400); -- HASTE_GEAR: 4
INSERT INTO `item_mods` VALUES (26951,73,6); -- STORETP: 6
INSERT INTO `item_mods` VALUES (26951,29,6); -- MDEF: 6
INSERT INTO `item_mods` VALUES (26951,31,64); -- MEVA: 64
INSERT INTO `item_mods` VALUES (26951,26,25); -- RACC: 25
INSERT INTO `item_mods` VALUES (26951,24,25); -- RATT: 25
INSERT INTO `item_mods` VALUES (26951,68,49); -- EVA: 49
INSERT INTO `item_mods` VALUES (26951,1,128); -- DEF: 128
INSERT INTO `item_mods` VALUES (26951,2,109); -- HP: 109
INSERT INTO `item_mods` VALUES (26951,5,44); -- MP: 44
INSERT INTO `item_mods` VALUES (26951,8,24); -- STR: 24
INSERT INTO `item_mods` VALUES (26951,9,29); -- DEX: 29
INSERT INTO `item_mods` VALUES (26951,10,21); -- VIT: 21
INSERT INTO `item_mods` VALUES (26951,11,30); -- AGI: 30
INSERT INTO `item_mods` VALUES (26951,12,23); -- INT: 23
INSERT INTO `item_mods` VALUES (26951,13,23); -- MND: 23
INSERT INTO `item_mods` VALUES (26951,14,23); -- CHR: 23

-- Psycloth Vest (psycloth_vest)  https://www.bg-wiki.com/ffxi/Psycloth_Vest
INSERT INTO `item_mods` VALUES (26952,384,300); -- HASTE_GEAR: 3
INSERT INTO `item_mods` VALUES (26952,29,6); -- MDEF: 6
INSERT INTO `item_mods` VALUES (26952,28,25); -- MATT: 25
INSERT INTO `item_mods` VALUES (26952,31,80); -- MEVA: 80
INSERT INTO `item_mods` VALUES (26952,68,41); -- EVA: 41
INSERT INTO `item_mods` VALUES (26952,27,-7); -- ENMITY: -7
INSERT INTO `item_mods` VALUES (26952,116,21); -- DARK: 21
INSERT INTO `item_mods` VALUES (26952,1,123); -- DEF: 123
INSERT INTO `item_mods` VALUES (26952,2,54); -- HP: 54
INSERT INTO `item_mods` VALUES (26952,5,59); -- MP: 59
INSERT INTO `item_mods` VALUES (26952,8,21); -- STR: 21
INSERT INTO `item_mods` VALUES (26952,9,21); -- DEX: 21
INSERT INTO `item_mods` VALUES (26952,10,21); -- VIT: 21
INSERT INTO `item_mods` VALUES (26952,11,21); -- AGI: 21
INSERT INTO `item_mods` VALUES (26952,12,32); -- INT: 32
INSERT INTO `item_mods` VALUES (26952,13,29); -- MND: 29
INSERT INTO `item_mods` VALUES (26952,14,29); -- CHR: 29

-- Vanya Robe (vanya_robe)  https://www.bg-wiki.com/ffxi/Vanya_Robe
INSERT INTO `item_mods` VALUES (26953,160,-100); -- DMG: -1
INSERT INTO `item_mods` VALUES (26953,384,300); -- HASTE_GEAR: 3
INSERT INTO `item_mods` VALUES (26953,29,6); -- MDEF: 6
INSERT INTO `item_mods` VALUES (26953,30,21); -- MACC: 21
INSERT INTO `item_mods` VALUES (26953,31,80); -- MEVA: 80
INSERT INTO `item_mods` VALUES (26953,68,41); -- EVA: 41
INSERT INTO `item_mods` VALUES (26953,111,20); -- DIVINE: 20
INSERT INTO `item_mods` VALUES (26953,114,20); -- ENFEEBLE: 20
INSERT INTO `item_mods` VALUES (26953,1,127); -- DEF: 127
INSERT INTO `item_mods` VALUES (26953,2,54); -- HP: 54
INSERT INTO `item_mods` VALUES (26953,5,59); -- MP: 59
INSERT INTO `item_mods` VALUES (26953,8,23); -- STR: 23
INSERT INTO `item_mods` VALUES (26953,9,23); -- DEX: 23
INSERT INTO `item_mods` VALUES (26953,10,23); -- VIT: 23
INSERT INTO `item_mods` VALUES (26953,11,23); -- AGI: 23
INSERT INTO `item_mods` VALUES (26953,12,31); -- INT: 31
INSERT INTO `item_mods` VALUES (26953,13,36); -- MND: 36
INSERT INTO `item_mods` VALUES (26953,14,36); -- CHR: 36

-- Sweller's Harness (swellers_harness)  https://www.bg-wiki.com/ffxi/Sweller's_Harness
INSERT INTO `item_mods` VALUES (26958,384,400); -- HASTE_GEAR: 4
INSERT INTO `item_mods` VALUES (26958,291,5); -- COUNTER: 5
INSERT INTO `item_mods` VALUES (26958,29,4); -- MDEF: 4
INSERT INTO `item_mods` VALUES (26958,31,53); -- MEVA: 53
INSERT INTO `item_mods` VALUES (26958,23,25); -- ATT: 25
INSERT INTO `item_mods` VALUES (26958,68,52); -- EVA: 52
INSERT INTO `item_mods` VALUES (26958,107,20); -- GUARD: 20
INSERT INTO `item_mods` VALUES (26958,1,129); -- DEF: 129
INSERT INTO `item_mods` VALUES (26958,2,59); -- HP: 59
INSERT INTO `item_mods` VALUES (26958,8,37); -- STR: 37
INSERT INTO `item_mods` VALUES (26958,9,25); -- DEX: 25
INSERT INTO `item_mods` VALUES (26958,10,21); -- VIT: 21
INSERT INTO `item_mods` VALUES (26958,11,25); -- AGI: 25
INSERT INTO `item_mods` VALUES (26958,12,24); -- INT: 24
INSERT INTO `item_mods` VALUES (26958,13,24); -- MND: 24
INSERT INTO `item_mods` VALUES (26958,14,24); -- CHR: 24

-- Kubira Meikogai (kubira_meikogai)  https://www.bg-wiki.com/ffxi/Kubira_Meikogai
--   unparsed tokens (verify by hand): Sphere
INSERT INTO `item_mods` VALUES (26959,161,-1000); -- DMGPHYS: -10
INSERT INTO `item_mods` VALUES (26959,384,300); -- HASTE_GEAR: 3
INSERT INTO `item_mods` VALUES (26959,288,4); -- DOUBLE_ATTACK: 4
INSERT INTO `item_mods` VALUES (26959,29,4); -- MDEF: 4
INSERT INTO `item_mods` VALUES (26959,31,69); -- MEVA: 69
INSERT INTO `item_mods` VALUES (26959,25,25); -- ACC: 25
INSERT INTO `item_mods` VALUES (26959,23,25); -- ATT: 25
INSERT INTO `item_mods` VALUES (26959,68,36); -- EVA: 36
INSERT INTO `item_mods` VALUES (26959,1,153); -- DEF: 153
INSERT INTO `item_mods` VALUES (26959,2,166); -- HP: 166
INSERT INTO `item_mods` VALUES (26959,5,59); -- MP: 59
INSERT INTO `item_mods` VALUES (26959,8,29); -- STR: 29
INSERT INTO `item_mods` VALUES (26959,9,17); -- DEX: 17
INSERT INTO `item_mods` VALUES (26959,10,32); -- VIT: 32
INSERT INTO `item_mods` VALUES (26959,11,17); -- AGI: 17
INSERT INTO `item_mods` VALUES (26959,12,16); -- INT: 16
INSERT INTO `item_mods` VALUES (26959,13,16); -- MND: 16
INSERT INTO `item_mods` VALUES (26959,14,16); -- CHR: 16

-- Makora Meikogai (makora_meikogai)  https://www.bg-wiki.com/ffxi/Makora_Meikogai
--   unparsed tokens (verify by hand): Sphere
INSERT INTO `item_mods` VALUES (26961,384,300); -- HASTE_GEAR: 3
INSERT INTO `item_mods` VALUES (26961,29,4); -- MDEF: 4
INSERT INTO `item_mods` VALUES (26961,28,10); -- MATT: 10
INSERT INTO `item_mods` VALUES (26961,31,59); -- MEVA: 59
INSERT INTO `item_mods` VALUES (26961,25,15); -- ACC: 15
INSERT INTO `item_mods` VALUES (26961,23,15); -- ATT: 15
INSERT INTO `item_mods` VALUES (26961,68,44); -- EVA: 44
INSERT INTO `item_mods` VALUES (26961,1,144); -- DEF: 144
INSERT INTO `item_mods` VALUES (26961,2,66); -- HP: 66
INSERT INTO `item_mods` VALUES (26961,8,36); -- STR: 36
INSERT INTO `item_mods` VALUES (26961,9,32); -- DEX: 32
INSERT INTO `item_mods` VALUES (26961,10,36); -- VIT: 36
INSERT INTO `item_mods` VALUES (26961,11,19); -- AGI: 19
INSERT INTO `item_mods` VALUES (26961,12,19); -- INT: 19
INSERT INTO `item_mods` VALUES (26961,13,19); -- MND: 19
INSERT INTO `item_mods` VALUES (26961,14,19); -- CHR: 19
INSERT INTO `item_mods` VALUES (26961,368,5); -- REGAIN: 5

-- Enforcer's Harness (enforcers_harness)  https://www.bg-wiki.com/ffxi/Enforcer's_Harness
--   unparsed tokens (verify by hand): Sphere
INSERT INTO `item_mods` VALUES (26962,384,400); -- HASTE_GEAR: 4
INSERT INTO `item_mods` VALUES (26962,165,4); -- CRITHITRATE: 4
INSERT INTO `item_mods` VALUES (26962,421,5); -- CRIT_DMG_INCREASE: 5
INSERT INTO `item_mods` VALUES (26962,29,6); -- MDEF: 6
INSERT INTO `item_mods` VALUES (26962,31,69); -- MEVA: 69
INSERT INTO `item_mods` VALUES (26962,68,55); -- EVA: 55
INSERT INTO `item_mods` VALUES (26962,1,135); -- DEF: 135
INSERT INTO `item_mods` VALUES (26962,2,63); -- HP: 63
INSERT INTO `item_mods` VALUES (26962,8,25); -- STR: 25
INSERT INTO `item_mods` VALUES (26962,9,42); -- DEX: 42
INSERT INTO `item_mods` VALUES (26962,10,24); -- VIT: 24
INSERT INTO `item_mods` VALUES (26962,11,28); -- AGI: 28
INSERT INTO `item_mods` VALUES (26962,12,21); -- INT: 21
INSERT INTO `item_mods` VALUES (26962,13,21); -- MND: 21
INSERT INTO `item_mods` VALUES (26962,14,21); -- CHR: 21

-- Eschite Gauntlets (eschite_gauntlets)  https://www.bg-wiki.com/ffxi/Eschite_Gauntlets
INSERT INTO `item_mods` VALUES (27097,384,400); -- HASTE_GEAR: 4
INSERT INTO `item_mods` VALUES (27097,73,3); -- STORETP: 3
INSERT INTO `item_mods` VALUES (27097,29,1); -- MDEF: 1
INSERT INTO `item_mods` VALUES (27097,31,26); -- MEVA: 26
INSERT INTO `item_mods` VALUES (27097,23,22); -- ATT: 22
INSERT INTO `item_mods` VALUES (27097,68,22); -- EVA: 22
INSERT INTO `item_mods` VALUES (27097,111,20); -- DIVINE: 20
INSERT INTO `item_mods` VALUES (27097,1,104); -- DEF: 104
INSERT INTO `item_mods` VALUES (27097,2,29); -- HP: 29
INSERT INTO `item_mods` VALUES (27097,8,12); -- STR: 12
INSERT INTO `item_mods` VALUES (27097,9,29); -- DEX: 29
INSERT INTO `item_mods` VALUES (27097,10,33); -- VIT: 33
INSERT INTO `item_mods` VALUES (27097,12,8); -- INT: 8
INSERT INTO `item_mods` VALUES (27097,13,25); -- MND: 25
INSERT INTO `item_mods` VALUES (27097,14,19); -- CHR: 19

-- Despair Finger Gauntlets (despair_finger_gauntlets)  https://www.bg-wiki.com/ffxi/Despair_Finger_Gauntlets
--   unparsed tokens (verify by hand): Wyvern
INSERT INTO `item_mods` VALUES (27098,384,500); -- HASTE_GEAR: 5
INSERT INTO `item_mods` VALUES (27098,29,2); -- MDEF: 2
INSERT INTO `item_mods` VALUES (27098,31,43); -- MEVA: 43
INSERT INTO `item_mods` VALUES (27098,25,18); -- ACC: 18
INSERT INTO `item_mods` VALUES (27098,23,18); -- ATT: 18
INSERT INTO `item_mods` VALUES (27098,68,22); -- EVA: 22
INSERT INTO `item_mods` VALUES (27098,1,99); -- DEF: 99
INSERT INTO `item_mods` VALUES (27098,2,57); -- HP: 57
INSERT INTO `item_mods` VALUES (27098,8,15); -- STR: 15
INSERT INTO `item_mods` VALUES (27098,9,34); -- DEX: 34
INSERT INTO `item_mods` VALUES (27098,10,34); -- VIT: 34
INSERT INTO `item_mods` VALUES (27098,11,8); -- AGI: 8
INSERT INTO `item_mods` VALUES (27098,12,16); -- INT: 16
INSERT INTO `item_mods` VALUES (27098,13,31); -- MND: 31
INSERT INTO `item_mods` VALUES (27098,14,21); -- CHR: 21

-- Naga Tekko (naga_tekko)  https://www.bg-wiki.com/ffxi/Naga_Tekko
--   unparsed tokens (verify by hand): Pet
INSERT INTO `item_mods` VALUES (27099,160,-200); -- DMG: -2
INSERT INTO `item_mods` VALUES (27099,384,500); -- HASTE_GEAR: 5
INSERT INTO `item_mods` VALUES (27099,29,1); -- MDEF: 1
INSERT INTO `item_mods` VALUES (27099,31,26); -- MEVA: 26
INSERT INTO `item_mods` VALUES (27099,24,20); -- RATT: 20
INSERT INTO `item_mods` VALUES (27099,23,20); -- ATT: 20
INSERT INTO `item_mods` VALUES (27099,68,22); -- EVA: 22
INSERT INTO `item_mods` VALUES (27099,1,83); -- DEF: 83
INSERT INTO `item_mods` VALUES (27099,2,65); -- HP: 65
INSERT INTO `item_mods` VALUES (27099,8,16); -- STR: 16
INSERT INTO `item_mods` VALUES (27099,9,36); -- DEX: 36
INSERT INTO `item_mods` VALUES (27099,10,34); -- VIT: 34
INSERT INTO `item_mods` VALUES (27099,11,8); -- AGI: 8
INSERT INTO `item_mods` VALUES (27099,12,12); -- INT: 12
INSERT INTO `item_mods` VALUES (27099,13,30); -- MND: 30
INSERT INTO `item_mods` VALUES (27099,14,18); -- CHR: 18

-- Rawhide Gloves (rawhide_gloves)  https://www.bg-wiki.com/ffxi/Rawhide_Gloves
--   unparsed tokens (verify by hand): Spell; interruption; rate; down
INSERT INTO `item_mods` VALUES (27100,384,500); -- HASTE_GEAR: 5
INSERT INTO `item_mods` VALUES (27100,29,2); -- MDEF: 2
INSERT INTO `item_mods` VALUES (27100,30,20); -- MACC: 20
INSERT INTO `item_mods` VALUES (27100,31,37); -- MEVA: 37
INSERT INTO `item_mods` VALUES (27100,25,20); -- ACC: 20
INSERT INTO `item_mods` VALUES (27100,68,24); -- EVA: 24
INSERT INTO `item_mods` VALUES (27100,122,10); -- BLUE: 10
INSERT INTO `item_mods` VALUES (27100,1,90); -- DEF: 90
INSERT INTO `item_mods` VALUES (27100,2,25); -- HP: 25
INSERT INTO `item_mods` VALUES (27100,8,13); -- STR: 13
INSERT INTO `item_mods` VALUES (27100,9,41); -- DEX: 41
INSERT INTO `item_mods` VALUES (27100,10,34); -- VIT: 34
INSERT INTO `item_mods` VALUES (27100,11,7); -- AGI: 7
INSERT INTO `item_mods` VALUES (27100,12,14); -- INT: 14
INSERT INTO `item_mods` VALUES (27100,13,32); -- MND: 32
INSERT INTO `item_mods` VALUES (27100,14,19); -- CHR: 19

-- Pursuer's Cuffs (pursuers_cuffs)  https://www.bg-wiki.com/ffxi/Pursuer's_Cuffs
INSERT INTO `item_mods` VALUES (27101,384,500); -- HASTE_GEAR: 5
INSERT INTO `item_mods` VALUES (27101,29,2); -- MDEF: 2
INSERT INTO `item_mods` VALUES (27101,28,20); -- MATT: 20
INSERT INTO `item_mods` VALUES (27101,31,37); -- MEVA: 37
INSERT INTO `item_mods` VALUES (27101,24,20); -- RATT: 20
INSERT INTO `item_mods` VALUES (27101,68,24); -- EVA: 24
INSERT INTO `item_mods` VALUES (27101,27,-7); -- ENMITY: -7
INSERT INTO `item_mods` VALUES (27101,1,88); -- DEF: 88
INSERT INTO `item_mods` VALUES (27101,2,25); -- HP: 25
INSERT INTO `item_mods` VALUES (27101,8,11); -- STR: 11
INSERT INTO `item_mods` VALUES (27101,9,35); -- DEX: 35
INSERT INTO `item_mods` VALUES (27101,10,29); -- VIT: 29
INSERT INTO `item_mods` VALUES (27101,11,17); -- AGI: 17
INSERT INTO `item_mods` VALUES (27101,12,12); -- INT: 12
INSERT INTO `item_mods` VALUES (27101,13,30); -- MND: 30
INSERT INTO `item_mods` VALUES (27101,14,17); -- CHR: 17

-- Psycloth Manillas (psycloth_manillas)  https://www.bg-wiki.com/ffxi/Psycloth_Manillas
--   unparsed tokens (verify by hand): Avatar
INSERT INTO `item_mods` VALUES (27102,384,300); -- HASTE_GEAR: 3
INSERT INTO `item_mods` VALUES (27102,29,3); -- MDEF: 3
INSERT INTO `item_mods` VALUES (27102,28,17); -- MATT: 17
INSERT INTO `item_mods` VALUES (27102,30,17); -- MACC: 17
INSERT INTO `item_mods` VALUES (27102,31,37); -- MEVA: 37
INSERT INTO `item_mods` VALUES (27102,68,22); -- EVA: 22
INSERT INTO `item_mods` VALUES (27102,115,20); -- ELEM: 20
INSERT INTO `item_mods` VALUES (27102,1,81); -- DEF: 81
INSERT INTO `item_mods` VALUES (27102,2,22); -- HP: 22
INSERT INTO `item_mods` VALUES (27102,5,14); -- MP: 14
INSERT INTO `item_mods` VALUES (27102,8,6); -- STR: 6
INSERT INTO `item_mods` VALUES (27102,9,28); -- DEX: 28
INSERT INTO `item_mods` VALUES (27102,10,25); -- VIT: 25
INSERT INTO `item_mods` VALUES (27102,11,5); -- AGI: 5
INSERT INTO `item_mods` VALUES (27102,12,25); -- INT: 25
INSERT INTO `item_mods` VALUES (27102,13,33); -- MND: 33
INSERT INTO `item_mods` VALUES (27102,14,19); -- CHR: 19

-- Vanya Cuffs (vanya_cuffs)  https://www.bg-wiki.com/ffxi/Vanya_Cuffs
INSERT INTO `item_mods` VALUES (27103,384,300); -- HASTE_GEAR: 3
INSERT INTO `item_mods` VALUES (27103,29,3); -- MDEF: 3
INSERT INTO `item_mods` VALUES (27103,31,37); -- MEVA: 37
INSERT INTO `item_mods` VALUES (27103,68,22); -- EVA: 22
INSERT INTO `item_mods` VALUES (27103,119,15); -- SINGING: 15
INSERT INTO `item_mods` VALUES (27103,1,86); -- DEF: 86
INSERT INTO `item_mods` VALUES (27103,2,22); -- HP: 22
INSERT INTO `item_mods` VALUES (27103,5,44); -- MP: 44
INSERT INTO `item_mods` VALUES (27103,8,6); -- STR: 6
INSERT INTO `item_mods` VALUES (27103,9,28); -- DEX: 28
INSERT INTO `item_mods` VALUES (27103,10,25); -- VIT: 25
INSERT INTO `item_mods` VALUES (27103,11,5); -- AGI: 5
INSERT INTO `item_mods` VALUES (27103,12,19); -- INT: 19
INSERT INTO `item_mods` VALUES (27103,13,33); -- MND: 33
INSERT INTO `item_mods` VALUES (27103,14,28); -- CHR: 28

-- Shrieker's Cuffs (shriekers_cuffs)  https://www.bg-wiki.com/ffxi/Shrieker's_Cuffs
--   unparsed tokens (verify by hand): Conserve; MP; Resist; Silence
INSERT INTO `item_mods` VALUES (27104,384,300); -- HASTE_GEAR: 3
INSERT INTO `item_mods` VALUES (27104,29,3); -- MDEF: 3
INSERT INTO `item_mods` VALUES (27104,31,57); -- MEVA: 57
INSERT INTO `item_mods` VALUES (27104,68,22); -- EVA: 22
INSERT INTO `item_mods` VALUES (27104,1,89); -- DEF: 89
INSERT INTO `item_mods` VALUES (27104,2,22); -- HP: 22
INSERT INTO `item_mods` VALUES (27104,5,59); -- MP: 59
INSERT INTO `item_mods` VALUES (27104,8,6); -- STR: 6
INSERT INTO `item_mods` VALUES (27104,9,28); -- DEX: 28
INSERT INTO `item_mods` VALUES (27104,10,25); -- VIT: 25
INSERT INTO `item_mods` VALUES (27104,11,5); -- AGI: 5
INSERT INTO `item_mods` VALUES (27104,12,19); -- INT: 19
INSERT INTO `item_mods` VALUES (27104,13,33); -- MND: 33
INSERT INTO `item_mods` VALUES (27104,14,19); -- CHR: 19

-- Kurys Gloves (kurys_gloves)  https://www.bg-wiki.com/ffxi/Kurys_Gloves
INSERT INTO `item_mods` VALUES (27134,160,-200); -- DMG: -2
INSERT INTO `item_mods` VALUES (27134,384,500); -- HASTE_GEAR: 5
INSERT INTO `item_mods` VALUES (27134,29,2); -- MDEF: 2
INSERT INTO `item_mods` VALUES (27134,31,57); -- MEVA: 57
INSERT INTO `item_mods` VALUES (27134,25,20); -- ACC: 20
INSERT INTO `item_mods` VALUES (27134,68,44); -- EVA: 44
INSERT INTO `item_mods` VALUES (27134,27,9); -- ENMITY: 9
INSERT INTO `item_mods` VALUES (27134,1,92); -- DEF: 92
INSERT INTO `item_mods` VALUES (27134,2,25); -- HP: 25
INSERT INTO `item_mods` VALUES (27134,8,11); -- STR: 11
INSERT INTO `item_mods` VALUES (27134,9,35); -- DEX: 35
INSERT INTO `item_mods` VALUES (27134,10,32); -- VIT: 32
INSERT INTO `item_mods` VALUES (27134,11,5); -- AGI: 5
INSERT INTO `item_mods` VALUES (27134,12,12); -- INT: 12
INSERT INTO `item_mods` VALUES (27134,13,30); -- MND: 30
INSERT INTO `item_mods` VALUES (27134,14,17); -- CHR: 17

-- Eschite Cuisses (eschite_cuisses)  https://www.bg-wiki.com/ffxi/Eschite_Cuisses
INSERT INTO `item_mods` VALUES (27282,384,500); -- HASTE_GEAR: 5
INSERT INTO `item_mods` VALUES (27282,29,3); -- MDEF: 3
INSERT INTO `item_mods` VALUES (27282,30,23); -- MACC: 23
INSERT INTO `item_mods` VALUES (27282,31,64); -- MEVA: 64
INSERT INTO `item_mods` VALUES (27282,25,23); -- ACC: 23
INSERT INTO `item_mods` VALUES (27282,68,22); -- EVA: 22
INSERT INTO `item_mods` VALUES (27282,116,20); -- DARK: 20
INSERT INTO `item_mods` VALUES (27282,1,129); -- DEF: 129
INSERT INTO `item_mods` VALUES (27282,2,52); -- HP: 52
INSERT INTO `item_mods` VALUES (27282,5,60); -- MP: 60
INSERT INTO `item_mods` VALUES (27282,8,35); -- STR: 35
INSERT INTO `item_mods` VALUES (27282,10,21); -- VIT: 21
INSERT INTO `item_mods` VALUES (27282,11,16); -- AGI: 16
INSERT INTO `item_mods` VALUES (27282,12,25); -- INT: 25
INSERT INTO `item_mods` VALUES (27282,13,12); -- MND: 12
INSERT INTO `item_mods` VALUES (27282,14,10); -- CHR: 10

-- Despair Cuisses (despair_cuisses)  https://www.bg-wiki.com/ffxi/Despair_Cuisses
--   unparsed tokens (verify by hand): Pet
INSERT INTO `item_mods` VALUES (27283,384,600); -- HASTE_GEAR: 6
INSERT INTO `item_mods` VALUES (27283,29,4); -- MDEF: 4
INSERT INTO `item_mods` VALUES (27283,31,80); -- MEVA: 80
INSERT INTO `item_mods` VALUES (27283,24,23); -- RATT: 23
INSERT INTO `item_mods` VALUES (27283,23,23); -- ATT: 23
INSERT INTO `item_mods` VALUES (27283,68,27); -- EVA: 27
INSERT INTO `item_mods` VALUES (27283,27,4); -- ENMITY: 4
INSERT INTO `item_mods` VALUES (27283,1,126); -- DEF: 126
INSERT INTO `item_mods` VALUES (27283,2,50); -- HP: 50
INSERT INTO `item_mods` VALUES (27283,8,34); -- STR: 34
INSERT INTO `item_mods` VALUES (27283,10,21); -- VIT: 21
INSERT INTO `item_mods` VALUES (27283,11,17); -- AGI: 17
INSERT INTO `item_mods` VALUES (27283,12,29); -- INT: 29
INSERT INTO `item_mods` VALUES (27283,13,16); -- MND: 16
INSERT INTO `item_mods` VALUES (27283,14,16); -- CHR: 16

-- Naga Hakama (naga_hakama)  https://www.bg-wiki.com/ffxi/Naga_Hakama
--   unparsed tokens (verify by hand): Pet
INSERT INTO `item_mods` VALUES (27284,384,600); -- HASTE_GEAR: 6
INSERT INTO `item_mods` VALUES (27284,259,4); -- DUAL_WIELD: 4
INSERT INTO `item_mods` VALUES (27284,29,3); -- MDEF: 3
INSERT INTO `item_mods` VALUES (27284,31,64); -- MEVA: 64
INSERT INTO `item_mods` VALUES (27284,26,20); -- RACC: 20
INSERT INTO `item_mods` VALUES (27284,25,20); -- ACC: 20
INSERT INTO `item_mods` VALUES (27284,68,33); -- EVA: 33
INSERT INTO `item_mods` VALUES (27284,1,110); -- DEF: 110
INSERT INTO `item_mods` VALUES (27284,2,97); -- HP: 97
INSERT INTO `item_mods` VALUES (27284,8,37); -- STR: 37
INSERT INTO `item_mods` VALUES (27284,10,19); -- VIT: 19
INSERT INTO `item_mods` VALUES (27284,11,21); -- AGI: 21
INSERT INTO `item_mods` VALUES (27284,12,32); -- INT: 32
INSERT INTO `item_mods` VALUES (27284,13,17); -- MND: 17
INSERT INTO `item_mods` VALUES (27284,14,10); -- CHR: 10

-- Rawhide Trousers (rawhide_trousers)  https://www.bg-wiki.com/ffxi/Rawhide_Trousers
--   unparsed tokens (verify by hand): Tactical; Parry
INSERT INTO `item_mods` VALUES (27285,384,600); -- HASTE_GEAR: 6
INSERT INTO `item_mods` VALUES (27285,29,5); -- MDEF: 5
INSERT INTO `item_mods` VALUES (27285,30,20); -- MACC: 20
INSERT INTO `item_mods` VALUES (27285,31,69); -- MEVA: 69
INSERT INTO `item_mods` VALUES (27285,68,38); -- EVA: 38
INSERT INTO `item_mods` VALUES (27285,113,10); -- ENHANCE: 10
INSERT INTO `item_mods` VALUES (27285,1,112); -- DEF: 112
INSERT INTO `item_mods` VALUES (27285,2,47); -- HP: 47
INSERT INTO `item_mods` VALUES (27285,8,33); -- STR: 33
INSERT INTO `item_mods` VALUES (27285,10,16); -- VIT: 16
INSERT INTO `item_mods` VALUES (27285,11,24); -- AGI: 24
INSERT INTO `item_mods` VALUES (27285,12,30); -- INT: 30
INSERT INTO `item_mods` VALUES (27285,13,17); -- MND: 17
INSERT INTO `item_mods` VALUES (27285,14,11); -- CHR: 11

-- Pursuer's Pants (pursuers_pants)  https://www.bg-wiki.com/ffxi/Pursuer's_Pants
INSERT INTO `item_mods` VALUES (27286,384,600); -- HASTE_GEAR: 6
INSERT INTO `item_mods` VALUES (27286,359,9); -- RAPID_SHOT: 9
INSERT INTO `item_mods` VALUES (27286,29,5); -- MDEF: 5
INSERT INTO `item_mods` VALUES (27286,31,69); -- MEVA: 69
INSERT INTO `item_mods` VALUES (27286,26,23); -- RACC: 23
INSERT INTO `item_mods` VALUES (27286,24,23); -- RATT: 23
INSERT INTO `item_mods` VALUES (27286,68,38); -- EVA: 38
INSERT INTO `item_mods` VALUES (27286,1,113); -- DEF: 113
INSERT INTO `item_mods` VALUES (27286,2,47); -- HP: 47
INSERT INTO `item_mods` VALUES (27286,5,23); -- MP: 23
INSERT INTO `item_mods` VALUES (27286,8,35); -- STR: 35
INSERT INTO `item_mods` VALUES (27286,9,3); -- DEX: 3
INSERT INTO `item_mods` VALUES (27286,10,17); -- VIT: 17
INSERT INTO `item_mods` VALUES (27286,11,29); -- AGI: 29
INSERT INTO `item_mods` VALUES (27286,12,33); -- INT: 33
INSERT INTO `item_mods` VALUES (27286,13,20); -- MND: 20
INSERT INTO `item_mods` VALUES (27286,14,14); -- CHR: 14

-- Psycloth Lappas (psycloth_lappas)  https://www.bg-wiki.com/ffxi/Psycloth_Lappas
--   unparsed tokens (verify by hand): Pet
INSERT INTO `item_mods` VALUES (27287,160,-400); -- DMG: -4
INSERT INTO `item_mods` VALUES (27287,384,500); -- HASTE_GEAR: 5
INSERT INTO `item_mods` VALUES (27287,29,6); -- MDEF: 6
INSERT INTO `item_mods` VALUES (27287,30,20); -- MACC: 20
INSERT INTO `item_mods` VALUES (27287,31,107); -- MEVA: 107
INSERT INTO `item_mods` VALUES (27287,68,27); -- EVA: 27
INSERT INTO `item_mods` VALUES (27287,114,18); -- ENFEEBLE: 18
INSERT INTO `item_mods` VALUES (27287,1,101); -- DEF: 101
INSERT INTO `item_mods` VALUES (27287,2,43); -- HP: 43
INSERT INTO `item_mods` VALUES (27287,5,29); -- MP: 29
INSERT INTO `item_mods` VALUES (27287,8,25); -- STR: 25
INSERT INTO `item_mods` VALUES (27287,10,12); -- VIT: 12
INSERT INTO `item_mods` VALUES (27287,11,17); -- AGI: 17
INSERT INTO `item_mods` VALUES (27287,12,40); -- INT: 40
INSERT INTO `item_mods` VALUES (27287,13,30); -- MND: 30
INSERT INTO `item_mods` VALUES (27287,14,19); -- CHR: 19

-- Vanya Slops (vanya_slops)  https://www.bg-wiki.com/ffxi/Vanya_Slops
--   unparsed tokens (verify by hand): Conserve; MP
INSERT INTO `item_mods` VALUES (27288,384,500); -- HASTE_GEAR: 5
INSERT INTO `item_mods` VALUES (27288,29,6); -- MDEF: 6
INSERT INTO `item_mods` VALUES (27288,30,20); -- MACC: 20
INSERT INTO `item_mods` VALUES (27288,31,107); -- MEVA: 107
INSERT INTO `item_mods` VALUES (27288,68,27); -- EVA: 27
INSERT INTO `item_mods` VALUES (27288,1,106); -- DEF: 106
INSERT INTO `item_mods` VALUES (27288,2,43); -- HP: 43
INSERT INTO `item_mods` VALUES (27288,5,29); -- MP: 29
INSERT INTO `item_mods` VALUES (27288,8,25); -- STR: 25
INSERT INTO `item_mods` VALUES (27288,10,12); -- VIT: 12
INSERT INTO `item_mods` VALUES (27288,11,17); -- AGI: 17
INSERT INTO `item_mods` VALUES (27288,12,44); -- INT: 44
INSERT INTO `item_mods` VALUES (27288,13,34); -- MND: 34
INSERT INTO `item_mods` VALUES (27288,14,29); -- CHR: 29

-- Obatala Subligar (obatala_subligar)  https://www.bg-wiki.com/ffxi/Obatala_Subligar
INSERT INTO `item_mods` VALUES (27319,384,800); -- HASTE_GEAR: 8
INSERT INTO `item_mods` VALUES (27319,29,5); -- MDEF: 5
INSERT INTO `item_mods` VALUES (27319,31,69); -- MEVA: 69
INSERT INTO `item_mods` VALUES (27319,26,15); -- RACC: 15
INSERT INTO `item_mods` VALUES (27319,24,20); -- RATT: 20
INSERT INTO `item_mods` VALUES (27319,25,15); -- ACC: 15
INSERT INTO `item_mods` VALUES (27319,23,20); -- ATT: 20
INSERT INTO `item_mods` VALUES (27319,68,38); -- EVA: 38
INSERT INTO `item_mods` VALUES (27319,27,5); -- ENMITY: 5
INSERT INTO `item_mods` VALUES (27319,1,118); -- DEF: 118
INSERT INTO `item_mods` VALUES (27319,2,47); -- HP: 47
INSERT INTO `item_mods` VALUES (27319,8,29); -- STR: 29
INSERT INTO `item_mods` VALUES (27319,10,16); -- VIT: 16
INSERT INTO `item_mods` VALUES (27319,11,20); -- AGI: 20
INSERT INTO `item_mods` VALUES (27319,12,30); -- INT: 30
INSERT INTO `item_mods` VALUES (27319,13,17); -- MND: 17
INSERT INTO `item_mods` VALUES (27319,14,11); -- CHR: 11

-- Selvans Subligar (selvans_subligar)  https://www.bg-wiki.com/ffxi/Selvans_Subligar
INSERT INTO `item_mods` VALUES (27320,163,-300); -- DMGMAGIC: -3
INSERT INTO `item_mods` VALUES (27320,384,500); -- HASTE_GEAR: 5
INSERT INTO `item_mods` VALUES (27320,288,4); -- DOUBLE_ATTACK: 4
INSERT INTO `item_mods` VALUES (27320,29,3); -- MDEF: 3
INSERT INTO `item_mods` VALUES (27320,31,75); -- MEVA: 75
INSERT INTO `item_mods` VALUES (27320,23,23); -- ATT: 23
INSERT INTO `item_mods` VALUES (27320,68,22); -- EVA: 22
INSERT INTO `item_mods` VALUES (27320,1,118); -- DEF: 118
INSERT INTO `item_mods` VALUES (27320,2,50); -- HP: 50
INSERT INTO `item_mods` VALUES (27320,8,38); -- STR: 38
INSERT INTO `item_mods` VALUES (27320,10,19); -- VIT: 19
INSERT INTO `item_mods` VALUES (27320,11,15); -- AGI: 15
INSERT INTO `item_mods` VALUES (27320,12,26); -- INT: 26
INSERT INTO `item_mods` VALUES (27320,13,16); -- MND: 16
INSERT INTO `item_mods` VALUES (27320,14,12); -- CHR: 12

-- Eschite Greaves (eschite_greaves)  https://www.bg-wiki.com/ffxi/Eschite_Greaves
INSERT INTO `item_mods` VALUES (27457,163,-300); -- DMGMAGIC: -3
INSERT INTO `item_mods` VALUES (27457,384,300); -- HASTE_GEAR: 3
INSERT INTO `item_mods` VALUES (27457,29,2); -- MDEF: 2
INSERT INTO `item_mods` VALUES (27457,31,64); -- MEVA: 64
INSERT INTO `item_mods` VALUES (27457,68,49); -- EVA: 49
INSERT INTO `item_mods` VALUES (27457,27,8); -- ENMITY: 8
INSERT INTO `item_mods` VALUES (27457,1,91); -- DEF: 91
INSERT INTO `item_mods` VALUES (27457,2,18); -- HP: 18
INSERT INTO `item_mods` VALUES (27457,8,21); -- STR: 21
INSERT INTO `item_mods` VALUES (27457,9,12); -- DEX: 12
INSERT INTO `item_mods` VALUES (27457,10,22); -- VIT: 22
INSERT INTO `item_mods` VALUES (27457,11,29); -- AGI: 29
INSERT INTO `item_mods` VALUES (27457,13,10); -- MND: 10
INSERT INTO `item_mods` VALUES (27457,14,26); -- CHR: 26

-- Despair Greaves (despair_greaves)  https://www.bg-wiki.com/ffxi/Despair_Greaves
--   unparsed tokens (verify by hand): Pet
INSERT INTO `item_mods` VALUES (27458,384,400); -- HASTE_GEAR: 4
INSERT INTO `item_mods` VALUES (27458,288,2); -- DOUBLE_ATTACK: 2
INSERT INTO `item_mods` VALUES (27458,29,3); -- MDEF: 3
INSERT INTO `item_mods` VALUES (27458,31,80); -- MEVA: 80
INSERT INTO `item_mods` VALUES (27458,26,17); -- RACC: 17
INSERT INTO `item_mods` VALUES (27458,25,17); -- ACC: 17
INSERT INTO `item_mods` VALUES (27458,68,52); -- EVA: 52
INSERT INTO `item_mods` VALUES (27458,1,82); -- DEF: 82
INSERT INTO `item_mods` VALUES (27458,2,15); -- HP: 15
INSERT INTO `item_mods` VALUES (27458,8,19); -- STR: 19
INSERT INTO `item_mods` VALUES (27458,9,16); -- DEX: 16
INSERT INTO `item_mods` VALUES (27458,10,15); -- VIT: 15
INSERT INTO `item_mods` VALUES (27458,11,33); -- AGI: 33
INSERT INTO `item_mods` VALUES (27458,13,11); -- MND: 11
INSERT INTO `item_mods` VALUES (27458,14,28); -- CHR: 28

-- Naga Kyahan (naga_kyahan)  https://www.bg-wiki.com/ffxi/Naga_Kyahan
--   unparsed tokens (verify by hand): Automaton; All; skills
INSERT INTO `item_mods` VALUES (27459,384,400); -- HASTE_GEAR: 4
INSERT INTO `item_mods` VALUES (27459,288,3); -- DOUBLE_ATTACK: 3
INSERT INTO `item_mods` VALUES (27459,29,3); -- MDEF: 3
INSERT INTO `item_mods` VALUES (27459,31,64); -- MEVA: 64
INSERT INTO `item_mods` VALUES (27459,25,18); -- ACC: 18
INSERT INTO `item_mods` VALUES (27459,23,18); -- ATT: 18
INSERT INTO `item_mods` VALUES (27459,68,69); -- EVA: 69
INSERT INTO `item_mods` VALUES (27459,1,67); -- DEF: 67
INSERT INTO `item_mods` VALUES (27459,2,63); -- HP: 63
INSERT INTO `item_mods` VALUES (27459,8,14); -- STR: 14
INSERT INTO `item_mods` VALUES (27459,9,15); -- DEX: 15
INSERT INTO `item_mods` VALUES (27459,10,11); -- VIT: 11
INSERT INTO `item_mods` VALUES (27459,11,34); -- AGI: 34
INSERT INTO `item_mods` VALUES (27459,13,12); -- MND: 12
INSERT INTO `item_mods` VALUES (27459,14,29); -- CHR: 29

-- Rawhide Boots (rawhide_boots)  https://www.bg-wiki.com/ffxi/Rawhide_Boots
--   unparsed tokens (verify by hand): Waltz; potency
INSERT INTO `item_mods` VALUES (27460,384,400); -- HASTE_GEAR: 4
INSERT INTO `item_mods` VALUES (27460,259,3); -- DUAL_WIELD: 3
INSERT INTO `item_mods` VALUES (27460,29,5); -- MDEF: 5
INSERT INTO `item_mods` VALUES (27460,31,69); -- MEVA: 69
INSERT INTO `item_mods` VALUES (27460,25,23); -- ACC: 23
INSERT INTO `item_mods` VALUES (27460,68,72); -- EVA: 72
INSERT INTO `item_mods` VALUES (27460,1,73); -- DEF: 73
INSERT INTO `item_mods` VALUES (27460,2,13); -- HP: 13
INSERT INTO `item_mods` VALUES (27460,8,18); -- STR: 18
INSERT INTO `item_mods` VALUES (27460,9,24); -- DEX: 24
INSERT INTO `item_mods` VALUES (27460,10,12); -- VIT: 12
INSERT INTO `item_mods` VALUES (27460,11,37); -- AGI: 37
INSERT INTO `item_mods` VALUES (27460,13,18); -- MND: 18
INSERT INTO `item_mods` VALUES (27460,14,30); -- CHR: 30

-- Pursuer's Gaiters (pursuers_gaiters)  https://www.bg-wiki.com/ffxi/Pursuer's_Gaiters
INSERT INTO `item_mods` VALUES (27461,384,400); -- HASTE_GEAR: 4
INSERT INTO `item_mods` VALUES (27461,29,5); -- MDEF: 5
INSERT INTO `item_mods` VALUES (27461,30,15); -- MACC: 15
INSERT INTO `item_mods` VALUES (27461,31,69); -- MEVA: 69
INSERT INTO `item_mods` VALUES (27461,26,20); -- RACC: 20
INSERT INTO `item_mods` VALUES (27461,68,72); -- EVA: 72
INSERT INTO `item_mods` VALUES (27461,27,-7); -- ENMITY: -7
INSERT INTO `item_mods` VALUES (27461,1,69); -- DEF: 69
INSERT INTO `item_mods` VALUES (27461,2,13); -- HP: 13
INSERT INTO `item_mods` VALUES (27461,8,12); -- STR: 12
INSERT INTO `item_mods` VALUES (27461,9,29); -- DEX: 29
INSERT INTO `item_mods` VALUES (27461,10,10); -- VIT: 10
INSERT INTO `item_mods` VALUES (27461,11,44); -- AGI: 44
INSERT INTO `item_mods` VALUES (27461,13,12); -- MND: 12
INSERT INTO `item_mods` VALUES (27461,14,30); -- CHR: 30

-- Psycloth Boots (psycloth_boots)  https://www.bg-wiki.com/ffxi/Psycloth_Boots
--   unparsed tokens (verify by hand): Avatar
INSERT INTO `item_mods` VALUES (27462,384,300); -- HASTE_GEAR: 3
INSERT INTO `item_mods` VALUES (27462,288,3); -- DOUBLE_ATTACK: 3
INSERT INTO `item_mods` VALUES (27462,29,5); -- MDEF: 5
INSERT INTO `item_mods` VALUES (27462,31,107); -- MEVA: 107
INSERT INTO `item_mods` VALUES (27462,25,20); -- ACC: 20
INSERT INTO `item_mods` VALUES (27462,23,20); -- ATT: 20
INSERT INTO `item_mods` VALUES (27462,68,55); -- EVA: 55
INSERT INTO `item_mods` VALUES (27462,1,66); -- DEF: 66
INSERT INTO `item_mods` VALUES (27462,2,13); -- HP: 13
INSERT INTO `item_mods` VALUES (27462,5,74); -- MP: 74
INSERT INTO `item_mods` VALUES (27462,8,10); -- STR: 10
INSERT INTO `item_mods` VALUES (27462,9,11); -- DEX: 11
INSERT INTO `item_mods` VALUES (27462,10,10); -- VIT: 10
INSERT INTO `item_mods` VALUES (27462,11,33); -- AGI: 33
INSERT INTO `item_mods` VALUES (27462,12,17); -- INT: 17
INSERT INTO `item_mods` VALUES (27462,13,19); -- MND: 19
INSERT INTO `item_mods` VALUES (27462,14,34); -- CHR: 34

-- Inspirited Boots (inspirited_boots)  https://www.bg-wiki.com/ffxi/Inspirited_Boots
--   unparsed tokens (verify by hand): Duration; of; Refresh; effects; received
INSERT INTO `item_mods` VALUES (27464,384,300); -- HASTE_GEAR: 3
INSERT INTO `item_mods` VALUES (27464,29,6); -- MDEF: 6
INSERT INTO `item_mods` VALUES (27464,28,20); -- MATT: 20
INSERT INTO `item_mods` VALUES (27464,31,118); -- MEVA: 118
INSERT INTO `item_mods` VALUES (27464,311,10); -- MAGIC_DAMAGE: 10
INSERT INTO `item_mods` VALUES (27464,68,60); -- EVA: 60
INSERT INTO `item_mods` VALUES (27464,1,70); -- DEF: 70
INSERT INTO `item_mods` VALUES (27464,2,9); -- HP: 9
INSERT INTO `item_mods` VALUES (27464,5,20); -- MP: 20
INSERT INTO `item_mods` VALUES (27464,8,8); -- STR: 8
INSERT INTO `item_mods` VALUES (27464,9,8); -- DEX: 8
INSERT INTO `item_mods` VALUES (27464,10,8); -- VIT: 8
INSERT INTO `item_mods` VALUES (27464,11,29); -- AGI: 29
INSERT INTO `item_mods` VALUES (27464,12,25); -- INT: 25
INSERT INTO `item_mods` VALUES (27464,13,17); -- MND: 17
INSERT INTO `item_mods` VALUES (27464,14,32); -- CHR: 32

-- Dampener's Torque (dampeners_torque)  https://www.bg-wiki.com/ffxi/Dampener's_Torque
INSERT INTO `item_mods` VALUES (27511,163,-400); -- DMGMAGIC: -4
INSERT INTO `item_mods` VALUES (27511,25,5); -- ACC: 5
INSERT INTO `item_mods` VALUES (27511,23,5); -- ATT: 5
INSERT INTO `item_mods` VALUES (27511,2,25); -- HP: 25

-- Marked Gorget (marked_gorget)  https://www.bg-wiki.com/ffxi/Marked_Gorget
INSERT INTO `item_mods` VALUES (27512,73,2); -- STORETP: 2
INSERT INTO `item_mods` VALUES (27512,26,15); -- RACC: 15
INSERT INTO `item_mods` VALUES (27512,24,15); -- RATT: 15
INSERT INTO `item_mods` VALUES (27512,27,-3); -- ENMITY: -3
INSERT INTO `item_mods` VALUES (27512,11,3); -- AGI: 3

-- Subtlety Spectacles (subtlety_spectacles)  https://www.bg-wiki.com/ffxi/Subtlety_Spectacles
INSERT INTO `item_mods` VALUES (27513,289,4); -- SUBTLE_BLOW: 4
INSERT INTO `item_mods` VALUES (27513,25,15); -- ACC: 15
INSERT INTO `item_mods` VALUES (27513,1,9); -- DEF: 9
INSERT INTO `item_mods` VALUES (27513,2,20); -- HP: 20

-- Empath Necklace (empath_necklace)  https://www.bg-wiki.com/ffxi/Empath_Necklace
--   unparsed tokens (verify by hand): Pet
INSERT INTO `item_mods` VALUES (27514,26,10); -- RACC: 10
INSERT INTO `item_mods` VALUES (27514,24,10); -- RATT: 10
INSERT INTO `item_mods` VALUES (27514,25,10); -- ACC: 10
INSERT INTO `item_mods` VALUES (27514,23,5); -- ATT: 5
INSERT INTO `item_mods` VALUES (27514,370,1); -- REGEN: 1

-- Reti Pendant (reti_pendant)  https://www.bg-wiki.com/ffxi/Reti_Pendant
--   unparsed tokens (verify by hand): Conserve; MP
INSERT INTO `item_mods` VALUES (27521,120,9); -- STRING: 9
INSERT INTO `item_mods` VALUES (27521,124,5); -- HANDBELL_SKILL: 5
INSERT INTO `item_mods` VALUES (27521,14,7); -- CHR: 7

-- Diemer Gorget (diemer_gorget)  https://www.bg-wiki.com/ffxi/Diemer_Gorget
--   unparsed tokens (verify by hand): Cure; spellcasting; time
INSERT INTO `item_mods` VALUES (27522,161,-600); -- DMGPHYS: -6
INSERT INTO `item_mods` VALUES (27522,109,7); -- SHIELD: 7
INSERT INTO `item_mods` VALUES (27522,1,11); -- DEF: 11

-- Caro Necklace (caro_necklace)  https://www.bg-wiki.com/ffxi/Caro_Necklace
INSERT INTO `item_mods` VALUES (27523,23,10); -- ATT: 10
INSERT INTO `item_mods` VALUES (27523,8,6); -- STR: 6
INSERT INTO `item_mods` VALUES (27523,9,6); -- DEX: 6

-- Assuage Earring (assuage_earring)  https://www.bg-wiki.com/ffxi/Assuage_Earring
INSERT INTO `item_mods` VALUES (27536,289,3); -- SUBTLE_BLOW: 3
INSERT INTO `item_mods` VALUES (27536,25,7); -- ACC: 7
INSERT INTO `item_mods` VALUES (27536,23,7); -- ATT: 7
INSERT INTO `item_mods` VALUES (27536,68,7); -- EVA: 7
INSERT INTO `item_mods` VALUES (27536,2,20); -- HP: 20

-- Lempo Earring (lempo_earring)  https://www.bg-wiki.com/ffxi/Lempo_Earring
--   unparsed tokens (verify by hand): Conserve; MP
INSERT INTO `item_mods` VALUES (27538,30,5); -- MACC: 5
INSERT INTO `item_mods` VALUES (27538,25,5); -- ACC: 5
INSERT INTO `item_mods` VALUES (27538,27,-3); -- ENMITY: -3

-- Telos Earring (telos_earring)  https://www.bg-wiki.com/ffxi/Telos_Earring
INSERT INTO `item_mods` VALUES (27545,288,1); -- DOUBLE_ATTACK: 1
INSERT INTO `item_mods` VALUES (27545,73,5); -- STORETP: 5
INSERT INTO `item_mods` VALUES (27545,26,10); -- RACC: 10
INSERT INTO `item_mods` VALUES (27545,24,10); -- RATT: 10
INSERT INTO `item_mods` VALUES (27545,25,10); -- ACC: 10
INSERT INTO `item_mods` VALUES (27545,23,10); -- ATT: 10

-- Overbearing Ring (overbearing_ring)  https://www.bg-wiki.com/ffxi/Overbearing_Ring
--   unparsed tokens (verify by hand): Automaton
INSERT INTO `item_mods` VALUES (27552,23,15); -- ATT: 15
INSERT INTO `item_mods` VALUES (27552,2,45); -- HP: 45

-- Purity Ring (purity_ring)  https://www.bg-wiki.com/ffxi/Purity_Ring
--   unparsed tokens (verify by hand): Potency; of; Cursna; effects; received; Holy; Water
INSERT INTO `item_mods` VALUES (27554,163,-400); -- DMGMAGIC: -4
INSERT INTO `item_mods` VALUES (27554,31,10); -- MEVA: 10

-- Disperser's Cape (dispersers_cape)  https://www.bg-wiki.com/ffxi/Disperser's_Cape
--   unparsed tokens (verify by hand): Potency; of; Banish; vs; undead; Resist; Paralyze; Healing; magic; casting; time
INSERT INTO `item_mods` VALUES (27606,1,10); -- DEF: 10

-- Thaumaturge's Cape (thaumaturges_cape)  https://www.bg-wiki.com/ffxi/Thaumaturge's_Cape
--   unparsed tokens (verify by hand): Conserve; MP
INSERT INTO `item_mods` VALUES (27607,27,-10); -- ENMITY: -10
INSERT INTO `item_mods` VALUES (27607,5,25); -- MP: 25

-- Sokolski Mantle (sokolski_mantle)  https://www.bg-wiki.com/ffxi/Sokolski_Mantle
INSERT INTO `item_mods` VALUES (27612,289,5); -- SUBTLE_BLOW: 5
INSERT INTO `item_mods` VALUES (27612,26,15); -- RACC: 15
INSERT INTO `item_mods` VALUES (27612,25,15); -- ACC: 15
INSERT INTO `item_mods` VALUES (27612,27,-3); -- ENMITY: -3
INSERT INTO `item_mods` VALUES (27612,1,15); -- DEF: 15
INSERT INTO `item_mods` VALUES (27612,2,70); -- HP: 70

-- Quarrel Mantle (quarrel_mantle)  https://www.bg-wiki.com/ffxi/Quarrel_Mantle
--   unparsed tokens (verify by hand): Recycle
INSERT INTO `item_mods` VALUES (27613,26,18); -- RACC: 18
INSERT INTO `item_mods` VALUES (27613,27,-3); -- ENMITY: -3
INSERT INTO `item_mods` VALUES (27613,1,14); -- DEF: 14
INSERT INTO `item_mods` VALUES (27613,11,4); -- AGI: 4

-- Xucau Mantle (xucau_mantle)  https://www.bg-wiki.com/ffxi/Xucau_Mantle
INSERT INTO `item_mods` VALUES (27614,160,-300); -- DMG: -3
INSERT INTO `item_mods` VALUES (27614,25,5); -- ACC: 5
INSERT INTO `item_mods` VALUES (27614,1,20); -- DEF: 20
INSERT INTO `item_mods` VALUES (27614,2,100); -- HP: 100
INSERT INTO `item_mods` VALUES (27614,5,100); -- MP: 100

-- Enuma Mantle (enuma_mantle)  https://www.bg-wiki.com/ffxi/Enuma_Mantle
INSERT INTO `item_mods` VALUES (27617,73,3); -- STORETP: 3
INSERT INTO `item_mods` VALUES (27617,25,20); -- ACC: 20
INSERT INTO `item_mods` VALUES (27617,27,6); -- ENMITY: 6
INSERT INTO `item_mods` VALUES (27617,1,17); -- DEF: 17

-- Svalinn (svalinn)  https://www.bg-wiki.com/ffxi/Svalinn
INSERT INTO `item_mods` VALUES (27627,27,7); -- ENMITY: 7
INSERT INTO `item_mods` VALUES (27627,109,112); -- SHIELD: 112
INSERT INTO `item_mods` VALUES (27627,1,130); -- DEF: 130

-- Nibiru Shield (nibiru_shield)  https://www.bg-wiki.com/ffxi/Nibiru_Shield
INSERT INTO `item_mods` VALUES (27642,160,-600); -- DMG: -6
INSERT INTO `item_mods` VALUES (27642,25,7); -- ACC: 7
INSERT INTO `item_mods` VALUES (27642,109,112); -- SHIELD: 112
INSERT INTO `item_mods` VALUES (27642,1,130); -- DEF: 130
INSERT INTO `item_mods` VALUES (27642,8,5); -- STR: 5
INSERT INTO `item_mods` VALUES (27642,10,5); -- VIT: 5

-- ---------------------------------------------------------------------------
-- Hand-mapped leftovers the generic parser could not resolve (values from the
-- same BG-Wiki fetches). Pet:/Avatar:/Automaton: lines use the combined pet
-- mods 990-993. Un-implementable lines (Sphere: auras, pet HP, automaton
-- skill+, refresh-duration-received, Holy Water potency) are omitted.
-- ---------------------------------------------------------------------------
INSERT INTO `item_mods` VALUES (26792,991,20); -- PET_ACC_EVA: Pet: Acc/R.Acc+20
INSERT INTO `item_mods` VALUES (26796,992,20); -- PET_MAB_MDB: Avatar: MAB+20
INSERT INTO `item_mods` VALUES (26797,296,6);  -- CONSERVE_MP: 6
INSERT INTO `item_mods` VALUES (27099,990,20); -- PET_ATK_DEF: Pet: Att/R.Att+20
INSERT INTO `item_mods` VALUES (27100,168,15); -- SPELLINTERRUPT: down 15%
INSERT INTO `item_mods` VALUES (27102,993,20); -- PET_MACC_MEVA: Avatar: M.Acc+20
INSERT INTO `item_mods` VALUES (27104,296,7);  -- CONSERVE_MP: 7
INSERT INTO `item_mods` VALUES (27104,244,25); -- SILENCERES: Resist Silence+25
INSERT INTO `item_mods` VALUES (27283,990,23); -- PET_ATK_DEF: Pet: Att/R.Att+23
INSERT INTO `item_mods` VALUES (27284,991,20); -- PET_ACC_EVA: Pet: Acc/R.Acc+20
INSERT INTO `item_mods` VALUES (27285,486,15); -- TACTICAL_PARRY: 15
INSERT INTO `item_mods` VALUES (27288,296,6);  -- CONSERVE_MP: 6
INSERT INTO `item_mods` VALUES (27458,991,17); -- PET_ACC_EVA: Pet: Acc/R.Acc+17
INSERT INTO `item_mods` VALUES (27460,491,8);  -- WALTZ_POTENCY: 8
INSERT INTO `item_mods` VALUES (27462,991,20); -- PET_ACC_EVA: Avatar: Acc+20
INSERT INTO `item_mods` VALUES (27462,990,20); -- PET_ATK_DEF: Avatar: Att+20
INSERT INTO `item_mods` VALUES (27514,991,10); -- PET_ACC_EVA: Pet: Acc/R.Acc+10
INSERT INTO `item_mods` VALUES (27514,990,10); -- PET_ATK_DEF: Pet: Att+5/R.Att+10
INSERT INTO `item_mods` VALUES (27521,296,4);  -- CONSERVE_MP: 4
INSERT INTO `item_mods` VALUES (27522,519,4);  -- CURE_CAST_TIME: -4%
INSERT INTO `item_mods` VALUES (27538,296,2);  -- CONSERVE_MP: 2
INSERT INTO `item_mods` VALUES (27552,990,15); -- PET_ATK_DEF: Automaton: Attack+15
INSERT INTO `item_mods` VALUES (27554,67,7);   -- ENHANCES_CURSNA_RCVD: +7
INSERT INTO `item_mods` VALUES (27606,242,20); -- PARALYZERES: Resist Paralyze+20
INSERT INTO `item_mods` VALUES (27606,519,5);  -- CURE_CAST_TIME: healing cast -5%
INSERT INTO `item_mods` VALUES (27607,296,4);  -- CONSERVE_MP: 4
INSERT INTO `item_mods` VALUES (27613,305,10); -- RECYCLE: 10
