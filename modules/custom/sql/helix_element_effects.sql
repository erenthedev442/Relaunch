-- Element-specific Helix status effect slots (807-814)
-- Enables multi-element Helix stacking: each element occupies its own slot so
-- Fire + Ice + Lightning helixes all tick independently on the same target.
-- overwrite=3 (ALWAYS) means re-casting the same element refreshes rather than stacks.
-- flags: FLAG_DEATH(0x20) | FLAG_NO_CANCEL(0x200) = same as base helix (186)
--
-- C++ MAX_EFFECTID must be > 814. At 807, AddStatusEffect rejected every
-- element helix: nuke landed, DoT never applied.

INSERT IGNORE INTO `status_effects` VALUES (807,'helix_fire',       0x220,0,0,3,0,0,0,0,0,NULL);
INSERT IGNORE INTO `status_effects` VALUES (808,'helix_ice',        0x220,0,0,3,0,0,0,0,0,NULL);
INSERT IGNORE INTO `status_effects` VALUES (809,'helix_wind',       0x220,0,0,3,0,0,0,0,0,NULL);
INSERT IGNORE INTO `status_effects` VALUES (810,'helix_earth',      0x220,0,0,3,0,0,0,0,0,NULL);
INSERT IGNORE INTO `status_effects` VALUES (811,'helix_water',      0x220,0,0,3,0,0,0,0,0,NULL);
INSERT IGNORE INTO `status_effects` VALUES (812,'helix_lightning',  0x220,0,0,3,0,0,0,0,0,NULL);
INSERT IGNORE INTO `status_effects` VALUES (813,'helix_light',      0x220,0,0,3,0,0,0,0,0,NULL);
INSERT IGNORE INTO `status_effects` VALUES (814,'helix_dark',       0x220,0,0,3,0,0,0,0,0,NULL);
