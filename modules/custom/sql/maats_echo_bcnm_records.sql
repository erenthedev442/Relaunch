-----------------------------------------------------------------------------
-- maats_echo_bcnm_records.sql  (relaunch)
--
-- Seeds the bcnm_records row for Maat's Echo. CBattlefieldHandler::LoadBattlefield
-- does SELECT ... FROM bcnm_records WHERE bcnmId = <battlefieldId> and returns
-- REQS_NOT_MET if the row is missing. Echo uses custom id 4230 (after HTBF
-- 4000-4220 -- see modules/custom/lua/maat_infamy_fight.lua).
--
-- Deploy applies modules/custom/sql/*.sql. Idempotent.
-----------------------------------------------------------------------------

INSERT INTO `bcnm_records` (`bcnmId`,`zoneId`,`name`,`fastestName`,`fastestPartySize`,`fastestTime`)
VALUES (4230,144,'maats_echo','Not Set!',0,1200)
ON DUPLICATE KEY UPDATE `zoneId`=VALUES(`zoneId`),`name`=VALUES(`name`);
