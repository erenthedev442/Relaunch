-- ============================================================================
-- relic_vouchers.sql
--
-- Hades weekend shop: Relic vouchers only. Ambuscade weeks sell the finished
-- weapon (no extra item ids). Trade a Relic voucher to the Weapon Forger
-- after WF_Relic_Final == 1.
--
-- Relic ids 23879-23892 + 23867 Aegis + 23868 Gjallarhorn.
--
-- Flags = 62528 = NOAUCTION + CANTRADENPC + NOSALE + NODELIVERY + EX + RARE.
-- Apply, then RESTART the map (item_basic is cached at boot). Idempotent.
-- ============================================================================

DELETE FROM `item_basic` WHERE `itemid` IN (23867, 23868)
    OR `itemid` BETWEEN 23879 AND 23892
    OR `itemid` BETWEEN 24276 AND 24282
    OR `itemid` BETWEEN 24290 AND 24296;
INSERT INTO `item_basic` (`itemid`, `subid`, `name`, `sortname`, `name_jp`, `type`, `stackSize`, `flags`, `aH`, `BaseSell`) VALUES
    (23867, 0, 'aegis_voucher',          'aegis_voucher',          '', 1, 1, 62528, 0, 0),
    (23868, 0, 'gjallarhorn_voucher',    'gjallarhorn_voucher',    '', 1, 1, 62528, 0, 0),
    (23879, 0, 'spharai_voucher',        'spharai_voucher',        '', 1, 1, 62528, 0, 0),
    (23880, 0, 'mandau_voucher',         'mandau_voucher',         '', 1, 1, 62528, 0, 0),
    (23881, 0, 'excalibur_voucher',      'excalibur_voucher',      '', 1, 1, 62528, 0, 0),
    (23882, 0, 'ragnarok_voucher',       'ragnarok_voucher',       '', 1, 1, 62528, 0, 0),
    (23883, 0, 'guttler_voucher',        'guttler_voucher',        '', 1, 1, 62528, 0, 0),
    (23884, 0, 'bravura_voucher',        'bravura_voucher',        '', 1, 1, 62528, 0, 0),
    (23885, 0, 'apocalypse_voucher',     'apocalypse_voucher',     '', 1, 1, 62528, 0, 0),
    (23886, 0, 'gungnir_voucher',        'gungnir_voucher',        '', 1, 1, 62528, 0, 0),
    (23887, 0, 'kikoku_voucher',         'kikoku_voucher',         '', 1, 1, 62528, 0, 0),
    (23888, 0, 'amanomurakumo_voucher',  'amanomurakumo_voucher',  '', 1, 1, 62528, 0, 0),
    (23889, 0, 'mjollnir_voucher',       'mjollnir_voucher',       '', 1, 1, 62528, 0, 0),
    (23890, 0, 'claustrum_voucher',      'claustrum_voucher',      '', 1, 1, 62528, 0, 0),
    (23891, 0, 'yoichinoyumi_voucher',   'yoichinoyumi_voucher',   '', 1, 1, 62528, 0, 0),
    (23892, 0, 'annihilator_voucher',    'annihilator_voucher',    '', 1, 1, 62528, 0, 0);
