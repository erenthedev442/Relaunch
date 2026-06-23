-- PDL+ (DAMAGE_LIMITP, mod 1081) retail values for gear missing the stat.
-- Source: bg-wiki.com/ffxi/Damage_Limit%2B
-- Applied 2026-06-22. All INSERT IGNORE — safe to re-run.

-- ============================================================
-- Gletis set (legs/feet — head/body/hands already in item_mods.sql)
-- ============================================================
INSERT IGNORE INTO `item_mods` VALUES (23777, 1081, 8);  -- gletis_breeches      PDL+8
INSERT IGNORE INTO `item_mods` VALUES (23784, 1081, 5);  -- gletis_boots         PDL+5

-- ============================================================
-- Ammo
-- ============================================================
INSERT IGNORE INTO `item_mods` VALUES (22300, 1081, 3);  -- crepuscular_pebble   PDL+3

-- ============================================================
-- Job necklaces (base +6 / +1 +8 / +2 +10)
-- ============================================================
INSERT IGNORE INTO `item_mods` VALUES (25423, 1081, 6);  -- monks_nodowa
INSERT IGNORE INTO `item_mods` VALUES (25424, 1081, 8);  -- monks_nodowa_+1
INSERT IGNORE INTO `item_mods` VALUES (25425, 1081, 10); -- monks_nodowa_+2

INSERT IGNORE INTO `item_mods` VALUES (25459, 1081, 6);  -- abyssal_bead_necklace
INSERT IGNORE INTO `item_mods` VALUES (25460, 1081, 8);  -- abyssal_bead_necklace_+1
INSERT IGNORE INTO `item_mods` VALUES (25461, 1081, 10); -- abyssal_bead_necklace_+2

INSERT IGNORE INTO `item_mods` VALUES (25465, 1081, 6);  -- beastmaster_collar
INSERT IGNORE INTO `item_mods` VALUES (25466, 1081, 8);  -- beastmaster_collar_+1
INSERT IGNORE INTO `item_mods` VALUES (25467, 1081, 10); -- beastmaster_collar_+2

INSERT IGNORE INTO `item_mods` VALUES (25471, 1081, 6);  -- bards_charm
INSERT IGNORE INTO `item_mods` VALUES (25472, 1081, 8);  -- bards_charm_+1
INSERT IGNORE INTO `item_mods` VALUES (25473, 1081, 10); -- bards_charm_+2

INSERT IGNORE INTO `item_mods` VALUES (25477, 1081, 6);  -- scouts_gorget
INSERT IGNORE INTO `item_mods` VALUES (25478, 1081, 8);  -- scouts_gorget_+1
INSERT IGNORE INTO `item_mods` VALUES (25479, 1081, 10); -- scouts_gorget_+2

INSERT IGNORE INTO `item_mods` VALUES (25483, 1081, 6);  -- samurais_nodowa
INSERT IGNORE INTO `item_mods` VALUES (25484, 1081, 8);  -- samurais_nodowa_+1
INSERT IGNORE INTO `item_mods` VALUES (25485, 1081, 10); -- samurais_nodowa_+2

INSERT IGNORE INTO `item_mods` VALUES (25489, 1081, 6);  -- ninja_nodowa
INSERT IGNORE INTO `item_mods` VALUES (25490, 1081, 8);  -- ninja_nodowa_+1
INSERT IGNORE INTO `item_mods` VALUES (25491, 1081, 10); -- ninja_nodowa_+2

INSERT IGNORE INTO `item_mods` VALUES (25495, 1081, 6);  -- dragoons_collar
INSERT IGNORE INTO `item_mods` VALUES (25496, 1081, 8);  -- dragoons_collar_+1
INSERT IGNORE INTO `item_mods` VALUES (25497, 1081, 10); -- dragoons_collar_+2

INSERT IGNORE INTO `item_mods` VALUES (25519, 1081, 6);  -- puppetmasters_collar
INSERT IGNORE INTO `item_mods` VALUES (25520, 1081, 8);  -- puppetmasters_collar_+1
INSERT IGNORE INTO `item_mods` VALUES (25521, 1081, 10); -- puppetmasters_collar_+2

INSERT IGNORE INTO `item_mods` VALUES (25525, 1081, 6);  -- etoile_gorget
INSERT IGNORE INTO `item_mods` VALUES (25526, 1081, 8);  -- etoile_gorget_+1
INSERT IGNORE INTO `item_mods` VALUES (25527, 1081, 10); -- etoile_gorget_+2

-- ============================================================
-- Job earrings (base +7 / +1 +8 / +2 +9)
-- ============================================================
INSERT IGNORE INTO `item_mods` VALUES (25462, 1081, 7);  -- heathens_earring
INSERT IGNORE INTO `item_mods` VALUES (25463, 1081, 8);  -- heathens_earring_+1
INSERT IGNORE INTO `item_mods` VALUES (25464, 1081, 9);  -- heathens_earring_+2

INSERT IGNORE INTO `item_mods` VALUES (25468, 1081, 7);  -- nukumi_earring
INSERT IGNORE INTO `item_mods` VALUES (25469, 1081, 8);  -- nukumi_earring_+1
INSERT IGNORE INTO `item_mods` VALUES (25470, 1081, 9);  -- nukumi_earring_+2

INSERT IGNORE INTO `item_mods` VALUES (25480, 1081, 7);  -- amini_earring
INSERT IGNORE INTO `item_mods` VALUES (25481, 1081, 8);  -- amini_earring_+1
INSERT IGNORE INTO `item_mods` VALUES (25482, 1081, 9);  -- amini_earring_+2

INSERT IGNORE INTO `item_mods` VALUES (25492, 1081, 7);  -- hattori_earring
INSERT IGNORE INTO `item_mods` VALUES (25493, 1081, 8);  -- hattori_earring_+1
INSERT IGNORE INTO `item_mods` VALUES (25494, 1081, 9);  -- hattori_earring_+2

INSERT IGNORE INTO `item_mods` VALUES (25498, 1081, 7);  -- peltasts_earring
INSERT IGNORE INTO `item_mods` VALUES (25499, 1081, 8);  -- peltasts_earring_+1
INSERT IGNORE INTO `item_mods` VALUES (25500, 1081, 9);  -- peltasts_earring_+2

INSERT IGNORE INTO `item_mods` VALUES (25528, 1081, 7);  -- maculele_earring
INSERT IGNORE INTO `item_mods` VALUES (25529, 1081, 8);  -- maculele_earring_+1
INSERT IGNORE INTO `item_mods` VALUES (25530, 1081, 9);  -- maculele_earring_+2

-- ============================================================
-- Reforged artifact armor (+2 = PDL+7, +3 = PDL+10)
-- ============================================================
INSERT IGNORE INTO `item_mods` VALUES (23090, 1081, 7);  -- skulkers_bonnet_+2
INSERT IGNORE INTO `item_mods` VALUES (23425, 1081, 10); -- skulkers_bonnet_+3

INSERT IGNORE INTO `item_mods` VALUES (23092, 1081, 7);  -- heathens_burgeonet_+2
INSERT IGNORE INTO `item_mods` VALUES (23427, 1081, 10); -- heathens_burgeonet_+3

INSERT IGNORE INTO `item_mods` VALUES (23102, 1081, 7);  -- karagoz_cappello_+2
INSERT IGNORE INTO `item_mods` VALUES (23437, 1081, 10); -- karagoz_cappello_+3

INSERT IGNORE INTO `item_mods` VALUES (23165, 1081, 7);  -- peltasts_plackart_+2
INSERT IGNORE INTO `item_mods` VALUES (23500, 1081, 10); -- peltasts_plackart_+3

INSERT IGNORE INTO `item_mods` VALUES (23220, 1081, 7);  -- bhikku_gloves_+2
INSERT IGNORE INTO `item_mods` VALUES (23555, 1081, 10); -- bhikku_gloves_+3

INSERT IGNORE INTO `item_mods` VALUES (23286, 1081, 7);  -- boii_cuisses_+2
INSERT IGNORE INTO `item_mods` VALUES (23621, 1081, 10); -- boii_cuisses_+3

INSERT IGNORE INTO `item_mods` VALUES (23304, 1081, 7);  -- maculele_tights_+2
INSERT IGNORE INTO `item_mods` VALUES (23639, 1081, 10); -- maculele_tights_+3

INSERT IGNORE INTO `item_mods` VALUES (23361, 1081, 7);  -- nukumi_ocreae_+2
INSERT IGNORE INTO `item_mods` VALUES (23696, 1081, 10); -- nukumi_ocreae_+3

-- amini_caban_+2 (23162) already in item_mods.sql at +7
INSERT IGNORE INTO `item_mods` VALUES (23497, 1081, 10); -- amini_caban_+3

-- kasuga_sune-ate_+2 (23364) already in item_mods.sql at +7
INSERT IGNORE INTO `item_mods` VALUES (23699, 1081, 10); -- kasuga_sune-ate_+3
