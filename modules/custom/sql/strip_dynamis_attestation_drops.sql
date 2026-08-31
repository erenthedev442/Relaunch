-- =====================================================================
-- strip_dynamis_attestation_drops.sql
-- Dynamis-Beaucedine Hydra Corps NMs must NOT drop Aeonic Attestations.
-- Those items are Geas Fete T3/T4 materials (plus Absolute Virtue -> Virtue
-- for Augment Sage). The five era NMs (Dagourmarche / Goublefaupe /
-- Mildaunegeux / Quiebitiel / Velosareon) are trivial vs Geas T4, so this
-- was an Aeonic difficulty bypass.
--
-- Replaces restore_dynamis_attestation_pops.sql (2026-07-10 Burtgang
-- request: in-Dynamis alternate farm). That guard re-inserted these rows
-- every deploy; this file deletes them instead and does not put them back.
--
-- Fortune parchments (3359-3363) are left alone -- they pop the NMs for
-- Magian, they do not drop attestations. Hydra trash still has
-- setDropID(0) via dynamis_beastmen, so parchments do not drop in play.
--
-- mob_droplist has NO primary key and is not reimported on a normal
-- deploy, so this DELETE must run every deploy. dynamis_no_gear_drops.sql
-- does not match attestations (not equipment / not '%-1'). A full dbtool
-- reimport of sql/mob_droplist.sql would restore stock rows AFTER custom
-- SQL -- re-run this after one, then restart xi_map (droplists are
-- boot-cached).
--
-- Idempotent: DELETE only, scoped to the five NM dropIds + attestation
-- itemIds. Safe to re-run.
-- Consolation 100-piece rolls live in hydra_corps_beaucedine_currency.sql
-- (this file does not touch those itemIds).
-- =====================================================================

-- 559 Dagourmarche / 1211 Goublefaupe / 1672 Mildaunegeux /
-- 2066 Quiebitiel / 2577 Velosareon
-- 1556-1569 Aeonic set, 1570 Accuracy, 1821 Invulnerability
DELETE FROM `mob_droplist`
WHERE `dropId` IN (559,1211,1672,2066,2577)
  AND `itemId` IN (1556,1557,1558,1559,1560,1561,1562,1563,1564,
                   1565,1566,1567,1568,1569,1570,1821);
