-----------------------------------------------------------------------------
-- htbf_bcnm_records.sql  (relaunch)
--
-- Seeds bcnm_records rows for every custom High-Tier Mission Battlefield.
-- The C++ battlefield loader (CBattlefieldHandler::LoadBattlefield) does
--   SELECT ... FROM bcnm_records WHERE bcnmId = <battlefieldId>
-- and returns REQS_NOT_MET ('access denied') if the row is missing. HTBF
-- fights use custom ids 4000-4220 (see modules/custom/lua/htbf_catalog.lua:
-- baseBattlefieldId + tier 0/1/2, plus Final Proving), which retail
-- bcnm_info.sql never seeds.
--
-- *** LOCATION MATTERS ON RELAUNCH ***  The OVH deploy (vps-rebuild.ps1 step 3)
-- applies ONLY modules/custom/sql/*.sql -- it does NOT apply sql/zz_*.sql or
-- sql/bcnm_info.sql. This file was originally sql/zz_htbf_bcnm_records.sql and
-- therefore NEVER applied on deploy -> every HTBF trial returned 'access denied'
-- (bug 2026-07-09). Moved here so the deploy actually seeds it. Because the
-- relaunch deploy does not re-run sql/bcnm_info.sql, nothing wipes these rows on
-- a normal deploy. (A FULL dbtool reimport DOES run sql/bcnm_info.sql after
-- modules/custom/sql -> would wipe these; re-run this file after any full reimport.)
-- Idempotent (ON DUPLICATE KEY UPDATE); read live per registration -> no restart.
-----------------------------------------------------------------------------

INSERT INTO `bcnm_records` (`bcnmId`,`zoneId`,`name`,`fastestName`,`fastestPartySize`,`fastestTime`) VALUES (4000,207,'htbf_trial_by_fire_1','Not Set!',0,1800) ON DUPLICATE KEY UPDATE `zoneId`=VALUES(`zoneId`),`name`=VALUES(`name`);
INSERT INTO `bcnm_records` (`bcnmId`,`zoneId`,`name`,`fastestName`,`fastestPartySize`,`fastestTime`) VALUES (4001,207,'htbf_trial_by_fire_2','Not Set!',0,1800) ON DUPLICATE KEY UPDATE `zoneId`=VALUES(`zoneId`),`name`=VALUES(`name`);
INSERT INTO `bcnm_records` (`bcnmId`,`zoneId`,`name`,`fastestName`,`fastestPartySize`,`fastestTime`) VALUES (4002,207,'htbf_trial_by_fire_3','Not Set!',0,1800) ON DUPLICATE KEY UPDATE `zoneId`=VALUES(`zoneId`),`name`=VALUES(`name`);

INSERT INTO `bcnm_records` (`bcnmId`,`zoneId`,`name`,`fastestName`,`fastestPartySize`,`fastestTime`) VALUES (4010,203,'htbf_trial_by_ice_1','Not Set!',0,1800) ON DUPLICATE KEY UPDATE `zoneId`=VALUES(`zoneId`),`name`=VALUES(`name`);
INSERT INTO `bcnm_records` (`bcnmId`,`zoneId`,`name`,`fastestName`,`fastestPartySize`,`fastestTime`) VALUES (4011,203,'htbf_trial_by_ice_2','Not Set!',0,1800) ON DUPLICATE KEY UPDATE `zoneId`=VALUES(`zoneId`),`name`=VALUES(`name`);
INSERT INTO `bcnm_records` (`bcnmId`,`zoneId`,`name`,`fastestName`,`fastestPartySize`,`fastestTime`) VALUES (4012,203,'htbf_trial_by_ice_3','Not Set!',0,1800) ON DUPLICATE KEY UPDATE `zoneId`=VALUES(`zoneId`),`name`=VALUES(`name`);

INSERT INTO `bcnm_records` (`bcnmId`,`zoneId`,`name`,`fastestName`,`fastestPartySize`,`fastestTime`) VALUES (4020,201,'htbf_trial_by_wind_1','Not Set!',0,1800) ON DUPLICATE KEY UPDATE `zoneId`=VALUES(`zoneId`),`name`=VALUES(`name`);
INSERT INTO `bcnm_records` (`bcnmId`,`zoneId`,`name`,`fastestName`,`fastestPartySize`,`fastestTime`) VALUES (4021,201,'htbf_trial_by_wind_2','Not Set!',0,1800) ON DUPLICATE KEY UPDATE `zoneId`=VALUES(`zoneId`),`name`=VALUES(`name`);
INSERT INTO `bcnm_records` (`bcnmId`,`zoneId`,`name`,`fastestName`,`fastestPartySize`,`fastestTime`) VALUES (4022,201,'htbf_trial_by_wind_3','Not Set!',0,1800) ON DUPLICATE KEY UPDATE `zoneId`=VALUES(`zoneId`),`name`=VALUES(`name`);

INSERT INTO `bcnm_records` (`bcnmId`,`zoneId`,`name`,`fastestName`,`fastestPartySize`,`fastestTime`) VALUES (4030,209,'htbf_trial_by_earth_1','Not Set!',0,1800) ON DUPLICATE KEY UPDATE `zoneId`=VALUES(`zoneId`),`name`=VALUES(`name`);
INSERT INTO `bcnm_records` (`bcnmId`,`zoneId`,`name`,`fastestName`,`fastestPartySize`,`fastestTime`) VALUES (4031,209,'htbf_trial_by_earth_2','Not Set!',0,1800) ON DUPLICATE KEY UPDATE `zoneId`=VALUES(`zoneId`),`name`=VALUES(`name`);
INSERT INTO `bcnm_records` (`bcnmId`,`zoneId`,`name`,`fastestName`,`fastestPartySize`,`fastestTime`) VALUES (4032,209,'htbf_trial_by_earth_3','Not Set!',0,1800) ON DUPLICATE KEY UPDATE `zoneId`=VALUES(`zoneId`),`name`=VALUES(`name`);

INSERT INTO `bcnm_records` (`bcnmId`,`zoneId`,`name`,`fastestName`,`fastestPartySize`,`fastestTime`) VALUES (4040,202,'htbf_trial_by_lightning_1','Not Set!',0,1800) ON DUPLICATE KEY UPDATE `zoneId`=VALUES(`zoneId`),`name`=VALUES(`name`);
INSERT INTO `bcnm_records` (`bcnmId`,`zoneId`,`name`,`fastestName`,`fastestPartySize`,`fastestTime`) VALUES (4041,202,'htbf_trial_by_lightning_2','Not Set!',0,1800) ON DUPLICATE KEY UPDATE `zoneId`=VALUES(`zoneId`),`name`=VALUES(`name`);
INSERT INTO `bcnm_records` (`bcnmId`,`zoneId`,`name`,`fastestName`,`fastestPartySize`,`fastestTime`) VALUES (4042,202,'htbf_trial_by_lightning_3','Not Set!',0,1800) ON DUPLICATE KEY UPDATE `zoneId`=VALUES(`zoneId`),`name`=VALUES(`name`);

INSERT INTO `bcnm_records` (`bcnmId`,`zoneId`,`name`,`fastestName`,`fastestPartySize`,`fastestTime`) VALUES (4050,211,'htbf_trial_by_water_1','Not Set!',0,1800) ON DUPLICATE KEY UPDATE `zoneId`=VALUES(`zoneId`),`name`=VALUES(`name`);
INSERT INTO `bcnm_records` (`bcnmId`,`zoneId`,`name`,`fastestName`,`fastestPartySize`,`fastestTime`) VALUES (4051,211,'htbf_trial_by_water_2','Not Set!',0,1800) ON DUPLICATE KEY UPDATE `zoneId`=VALUES(`zoneId`),`name`=VALUES(`name`);
INSERT INTO `bcnm_records` (`bcnmId`,`zoneId`,`name`,`fastestName`,`fastestPartySize`,`fastestTime`) VALUES (4052,211,'htbf_trial_by_water_3','Not Set!',0,1800) ON DUPLICATE KEY UPDATE `zoneId`=VALUES(`zoneId`),`name`=VALUES(`name`);

INSERT INTO `bcnm_records` (`bcnmId`,`zoneId`,`name`,`fastestName`,`fastestPartySize`,`fastestTime`) VALUES (4060,31,'htbf_the_savage_1','Not Set!',0,1800) ON DUPLICATE KEY UPDATE `zoneId`=VALUES(`zoneId`),`name`=VALUES(`name`);
INSERT INTO `bcnm_records` (`bcnmId`,`zoneId`,`name`,`fastestName`,`fastestPartySize`,`fastestTime`) VALUES (4061,31,'htbf_the_savage_2','Not Set!',0,1800) ON DUPLICATE KEY UPDATE `zoneId`=VALUES(`zoneId`),`name`=VALUES(`name`);
INSERT INTO `bcnm_records` (`bcnmId`,`zoneId`,`name`,`fastestName`,`fastestPartySize`,`fastestTime`) VALUES (4062,31,'htbf_the_savage_3','Not Set!',0,1800) ON DUPLICATE KEY UPDATE `zoneId`=VALUES(`zoneId`),`name`=VALUES(`name`);

INSERT INTO `bcnm_records` (`bcnmId`,`zoneId`,`name`,`fastestName`,`fastestPartySize`,`fastestTime`) VALUES (4070,32,'htbf_warriors_path_1','Not Set!',0,1800) ON DUPLICATE KEY UPDATE `zoneId`=VALUES(`zoneId`),`name`=VALUES(`name`);
INSERT INTO `bcnm_records` (`bcnmId`,`zoneId`,`name`,`fastestName`,`fastestPartySize`,`fastestTime`) VALUES (4071,32,'htbf_warriors_path_2','Not Set!',0,1800) ON DUPLICATE KEY UPDATE `zoneId`=VALUES(`zoneId`),`name`=VALUES(`name`);
INSERT INTO `bcnm_records` (`bcnmId`,`zoneId`,`name`,`fastestName`,`fastestPartySize`,`fastestTime`) VALUES (4072,32,'htbf_warriors_path_3','Not Set!',0,1800) ON DUPLICATE KEY UPDATE `zoneId`=VALUES(`zoneId`),`name`=VALUES(`name`);

INSERT INTO `bcnm_records` (`bcnmId`,`zoneId`,`name`,`fastestName`,`fastestPartySize`,`fastestTime`) VALUES (4080,32,'htbf_one_to_be_feared_1','Not Set!',0,1800) ON DUPLICATE KEY UPDATE `zoneId`=VALUES(`zoneId`),`name`=VALUES(`name`);
INSERT INTO `bcnm_records` (`bcnmId`,`zoneId`,`name`,`fastestName`,`fastestPartySize`,`fastestTime`) VALUES (4081,32,'htbf_one_to_be_feared_2','Not Set!',0,1800) ON DUPLICATE KEY UPDATE `zoneId`=VALUES(`zoneId`),`name`=VALUES(`name`);
INSERT INTO `bcnm_records` (`bcnmId`,`zoneId`,`name`,`fastestName`,`fastestPartySize`,`fastestTime`) VALUES (4082,32,'htbf_one_to_be_feared_3','Not Set!',0,1800) ON DUPLICATE KEY UPDATE `zoneId`=VALUES(`zoneId`),`name`=VALUES(`name`);

INSERT INTO `bcnm_records` (`bcnmId`,`zoneId`,`name`,`fastestName`,`fastestPartySize`,`fastestTime`) VALUES (4090,8,'htbf_head_wind_1','Not Set!',0,1800) ON DUPLICATE KEY UPDATE `zoneId`=VALUES(`zoneId`),`name`=VALUES(`name`);
INSERT INTO `bcnm_records` (`bcnmId`,`zoneId`,`name`,`fastestName`,`fastestPartySize`,`fastestTime`) VALUES (4091,8,'htbf_head_wind_2','Not Set!',0,1800) ON DUPLICATE KEY UPDATE `zoneId`=VALUES(`zoneId`),`name`=VALUES(`name`);
INSERT INTO `bcnm_records` (`bcnmId`,`zoneId`,`name`,`fastestName`,`fastestPartySize`,`fastestTime`) VALUES (4092,8,'htbf_head_wind_3','Not Set!',0,1800) ON DUPLICATE KEY UPDATE `zoneId`=VALUES(`zoneId`),`name`=VALUES(`name`);

INSERT INTO `bcnm_records` (`bcnmId`,`zoneId`,`name`,`fastestName`,`fastestPartySize`,`fastestTime`) VALUES (4100,67,'htbf_puppet_in_peril_1','Not Set!',0,1800) ON DUPLICATE KEY UPDATE `zoneId`=VALUES(`zoneId`),`name`=VALUES(`name`);
INSERT INTO `bcnm_records` (`bcnmId`,`zoneId`,`name`,`fastestName`,`fastestPartySize`,`fastestTime`) VALUES (4101,67,'htbf_puppet_in_peril_2','Not Set!',0,1800) ON DUPLICATE KEY UPDATE `zoneId`=VALUES(`zoneId`),`name`=VALUES(`name`);
INSERT INTO `bcnm_records` (`bcnmId`,`zoneId`,`name`,`fastestName`,`fastestPartySize`,`fastestTime`) VALUES (4102,67,'htbf_puppet_in_peril_3','Not Set!',0,1800) ON DUPLICATE KEY UPDATE `zoneId`=VALUES(`zoneId`),`name`=VALUES(`name`);

INSERT INTO `bcnm_records` (`bcnmId`,`zoneId`,`name`,`fastestName`,`fastestPartySize`,`fastestTime`) VALUES (4110,57,'htbf_legacy_of_the_lost_1','Not Set!',0,1800) ON DUPLICATE KEY UPDATE `zoneId`=VALUES(`zoneId`),`name`=VALUES(`name`);
INSERT INTO `bcnm_records` (`bcnmId`,`zoneId`,`name`,`fastestName`,`fastestPartySize`,`fastestTime`) VALUES (4111,57,'htbf_legacy_of_the_lost_2','Not Set!',0,1800) ON DUPLICATE KEY UPDATE `zoneId`=VALUES(`zoneId`),`name`=VALUES(`name`);
INSERT INTO `bcnm_records` (`bcnmId`,`zoneId`,`name`,`fastestName`,`fastestPartySize`,`fastestTime`) VALUES (4112,57,'htbf_legacy_of_the_lost_3','Not Set!',0,1800) ON DUPLICATE KEY UPDATE `zoneId`=VALUES(`zoneId`),`name`=VALUES(`name`);

INSERT INTO `bcnm_records` (`bcnmId`,`zoneId`,`name`,`fastestName`,`fastestPartySize`,`fastestTime`) VALUES (4120,165,'htbf_shadow_lord_1','Not Set!',0,1800) ON DUPLICATE KEY UPDATE `zoneId`=VALUES(`zoneId`),`name`=VALUES(`name`);
INSERT INTO `bcnm_records` (`bcnmId`,`zoneId`,`name`,`fastestName`,`fastestPartySize`,`fastestTime`) VALUES (4121,165,'htbf_shadow_lord_2','Not Set!',0,1800) ON DUPLICATE KEY UPDATE `zoneId`=VALUES(`zoneId`),`name`=VALUES(`name`);
INSERT INTO `bcnm_records` (`bcnmId`,`zoneId`,`name`,`fastestName`,`fastestPartySize`,`fastestTime`) VALUES (4122,165,'htbf_shadow_lord_3','Not Set!',0,1800) ON DUPLICATE KEY UPDATE `zoneId`=VALUES(`zoneId`),`name`=VALUES(`name`);

INSERT INTO `bcnm_records` (`bcnmId`,`zoneId`,`name`,`fastestName`,`fastestPartySize`,`fastestTime`) VALUES (4130,179,'htbf_stellar_fulcrum_1','Not Set!',0,1800) ON DUPLICATE KEY UPDATE `zoneId`=VALUES(`zoneId`),`name`=VALUES(`name`);
INSERT INTO `bcnm_records` (`bcnmId`,`zoneId`,`name`,`fastestName`,`fastestPartySize`,`fastestTime`) VALUES (4131,179,'htbf_stellar_fulcrum_2','Not Set!',0,1800) ON DUPLICATE KEY UPDATE `zoneId`=VALUES(`zoneId`),`name`=VALUES(`name`);
INSERT INTO `bcnm_records` (`bcnmId`,`zoneId`,`name`,`fastestName`,`fastestPartySize`,`fastestTime`) VALUES (4132,179,'htbf_stellar_fulcrum_3','Not Set!',0,1800) ON DUPLICATE KEY UPDATE `zoneId`=VALUES(`zoneId`),`name`=VALUES(`name`);

INSERT INTO `bcnm_records` (`bcnmId`,`zoneId`,`name`,`fastestName`,`fastestPartySize`,`fastestTime`) VALUES (4140,181,'htbf_celestial_nexus_1','Not Set!',0,1800) ON DUPLICATE KEY UPDATE `zoneId`=VALUES(`zoneId`),`name`=VALUES(`name`);
INSERT INTO `bcnm_records` (`bcnmId`,`zoneId`,`name`,`fastestName`,`fastestPartySize`,`fastestTime`) VALUES (4141,181,'htbf_celestial_nexus_2','Not Set!',0,1800) ON DUPLICATE KEY UPDATE `zoneId`=VALUES(`zoneId`),`name`=VALUES(`name`);
INSERT INTO `bcnm_records` (`bcnmId`,`zoneId`,`name`,`fastestName`,`fastestPartySize`,`fastestTime`) VALUES (4142,181,'htbf_celestial_nexus_3','Not Set!',0,1800) ON DUPLICATE KEY UPDATE `zoneId`=VALUES(`zoneId`),`name`=VALUES(`name`);

INSERT INTO `bcnm_records` (`bcnmId`,`zoneId`,`name`,`fastestName`,`fastestPartySize`,`fastestTime`) VALUES (4150,180,'htbf_divine_might_1','Not Set!',0,1800) ON DUPLICATE KEY UPDATE `zoneId`=VALUES(`zoneId`),`name`=VALUES(`name`);
INSERT INTO `bcnm_records` (`bcnmId`,`zoneId`,`name`,`fastestName`,`fastestPartySize`,`fastestTime`) VALUES (4151,180,'htbf_divine_might_2','Not Set!',0,1800) ON DUPLICATE KEY UPDATE `zoneId`=VALUES(`zoneId`),`name`=VALUES(`name`);
INSERT INTO `bcnm_records` (`bcnmId`,`zoneId`,`name`,`fastestName`,`fastestPartySize`,`fastestTime`) VALUES (4152,180,'htbf_divine_might_3','Not Set!',0,1800) ON DUPLICATE KEY UPDATE `zoneId`=VALUES(`zoneId`),`name`=VALUES(`name`);

INSERT INTO `bcnm_records` (`bcnmId`,`zoneId`,`name`,`fastestName`,`fastestPartySize`,`fastestTime`) VALUES (4160,180,'htbf_ark_angels_1_1','Not Set!',0,1800) ON DUPLICATE KEY UPDATE `zoneId`=VALUES(`zoneId`),`name`=VALUES(`name`);
INSERT INTO `bcnm_records` (`bcnmId`,`zoneId`,`name`,`fastestName`,`fastestPartySize`,`fastestTime`) VALUES (4161,180,'htbf_ark_angels_1_2','Not Set!',0,1800) ON DUPLICATE KEY UPDATE `zoneId`=VALUES(`zoneId`),`name`=VALUES(`name`);
INSERT INTO `bcnm_records` (`bcnmId`,`zoneId`,`name`,`fastestName`,`fastestPartySize`,`fastestTime`) VALUES (4162,180,'htbf_ark_angels_1_3','Not Set!',0,1800) ON DUPLICATE KEY UPDATE `zoneId`=VALUES(`zoneId`),`name`=VALUES(`name`);

INSERT INTO `bcnm_records` (`bcnmId`,`zoneId`,`name`,`fastestName`,`fastestPartySize`,`fastestTime`) VALUES (4170,180,'htbf_ark_angels_2_1','Not Set!',0,1800) ON DUPLICATE KEY UPDATE `zoneId`=VALUES(`zoneId`),`name`=VALUES(`name`);
INSERT INTO `bcnm_records` (`bcnmId`,`zoneId`,`name`,`fastestName`,`fastestPartySize`,`fastestTime`) VALUES (4171,180,'htbf_ark_angels_2_2','Not Set!',0,1800) ON DUPLICATE KEY UPDATE `zoneId`=VALUES(`zoneId`),`name`=VALUES(`name`);
INSERT INTO `bcnm_records` (`bcnmId`,`zoneId`,`name`,`fastestName`,`fastestPartySize`,`fastestTime`) VALUES (4172,180,'htbf_ark_angels_2_3','Not Set!',0,1800) ON DUPLICATE KEY UPDATE `zoneId`=VALUES(`zoneId`),`name`=VALUES(`name`);

INSERT INTO `bcnm_records` (`bcnmId`,`zoneId`,`name`,`fastestName`,`fastestPartySize`,`fastestTime`) VALUES (4180,180,'htbf_ark_angels_3_1','Not Set!',0,1800) ON DUPLICATE KEY UPDATE `zoneId`=VALUES(`zoneId`),`name`=VALUES(`name`);
INSERT INTO `bcnm_records` (`bcnmId`,`zoneId`,`name`,`fastestName`,`fastestPartySize`,`fastestTime`) VALUES (4181,180,'htbf_ark_angels_3_2','Not Set!',0,1800) ON DUPLICATE KEY UPDATE `zoneId`=VALUES(`zoneId`),`name`=VALUES(`name`);
INSERT INTO `bcnm_records` (`bcnmId`,`zoneId`,`name`,`fastestName`,`fastestPartySize`,`fastestTime`) VALUES (4182,180,'htbf_ark_angels_3_3','Not Set!',0,1800) ON DUPLICATE KEY UPDATE `zoneId`=VALUES(`zoneId`),`name`=VALUES(`name`);

INSERT INTO `bcnm_records` (`bcnmId`,`zoneId`,`name`,`fastestName`,`fastestPartySize`,`fastestTime`) VALUES (4190,180,'htbf_ark_angels_4_1','Not Set!',0,1800) ON DUPLICATE KEY UPDATE `zoneId`=VALUES(`zoneId`),`name`=VALUES(`name`);
INSERT INTO `bcnm_records` (`bcnmId`,`zoneId`,`name`,`fastestName`,`fastestPartySize`,`fastestTime`) VALUES (4191,180,'htbf_ark_angels_4_2','Not Set!',0,1800) ON DUPLICATE KEY UPDATE `zoneId`=VALUES(`zoneId`),`name`=VALUES(`name`);
INSERT INTO `bcnm_records` (`bcnmId`,`zoneId`,`name`,`fastestName`,`fastestPartySize`,`fastestTime`) VALUES (4192,180,'htbf_ark_angels_4_3','Not Set!',0,1800) ON DUPLICATE KEY UPDATE `zoneId`=VALUES(`zoneId`),`name`=VALUES(`name`);

INSERT INTO `bcnm_records` (`bcnmId`,`zoneId`,`name`,`fastestName`,`fastestPartySize`,`fastestTime`) VALUES (4200,180,'htbf_ark_angels_5_1','Not Set!',0,1800) ON DUPLICATE KEY UPDATE `zoneId`=VALUES(`zoneId`),`name`=VALUES(`name`);
INSERT INTO `bcnm_records` (`bcnmId`,`zoneId`,`name`,`fastestName`,`fastestPartySize`,`fastestTime`) VALUES (4201,180,'htbf_ark_angels_5_2','Not Set!',0,1800) ON DUPLICATE KEY UPDATE `zoneId`=VALUES(`zoneId`),`name`=VALUES(`name`);
INSERT INTO `bcnm_records` (`bcnmId`,`zoneId`,`name`,`fastestName`,`fastestPartySize`,`fastestTime`) VALUES (4202,180,'htbf_ark_angels_5_3','Not Set!',0,1800) ON DUPLICATE KEY UPDATE `zoneId`=VALUES(`zoneId`),`name`=VALUES(`name`);

INSERT INTO `bcnm_records` (`bcnmId`,`zoneId`,`name`,`fastestName`,`fastestPartySize`,`fastestTime`) VALUES (4210,36,'htbf_dawn_1','Not Set!',0,1800) ON DUPLICATE KEY UPDATE `zoneId`=VALUES(`zoneId`),`name`=VALUES(`name`);
INSERT INTO `bcnm_records` (`bcnmId`,`zoneId`,`name`,`fastestName`,`fastestPartySize`,`fastestTime`) VALUES (4211,36,'htbf_dawn_2','Not Set!',0,1800) ON DUPLICATE KEY UPDATE `zoneId`=VALUES(`zoneId`),`name`=VALUES(`name`);
INSERT INTO `bcnm_records` (`bcnmId`,`zoneId`,`name`,`fastestName`,`fastestPartySize`,`fastestTime`) VALUES (4212,36,'htbf_dawn_3','Not Set!',0,1800) ON DUPLICATE KEY UPDATE `zoneId`=VALUES(`zoneId`),`name`=VALUES(`name`);

INSERT INTO `bcnm_records` (`bcnmId`,`zoneId`,`name`,`fastestName`,`fastestPartySize`,`fastestTime`) VALUES (4220,201,'htbf_final_proving','Not Set!',0,1800) ON DUPLICATE KEY UPDATE `zoneId`=VALUES(`zoneId`),`name`=VALUES(`name`);
