-- Allow portal Rescue to clear a stuck / black-screen session.
-- portal_rw already UPDATEs chars to GM Home; this adds DELETE on
-- accounts_sessions so the player can log back in without Discord !rescue.
--
-- Idempotent. Run once on the live box as a DB admin:
--   mysql -h 127.0.0.1 -u root -p xi_relaunch < portal_rescue_session.sql

GRANT SELECT, DELETE ON xi_relaunch.accounts_sessions TO 'portal_rw'@'localhost';
FLUSH PRIVILEGES;
