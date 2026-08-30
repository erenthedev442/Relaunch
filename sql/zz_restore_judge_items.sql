-- Restore stock Judge item definitions (helm 12523, etc.).
--
-- The old purge deleted these from the live DB. The restore lived in
-- modules/custom/sql/zz_remove_judge_items.sql, which light deploy does
-- not apply (only sql\zz_*.sql). !additem then fails silently because
-- the map item cache has no row for 12523.
--
-- Idempotent: INSERT IGNORE. Does not touch char_inventory.
-- Map restart required after import.

INSERT IGNORE INTO `item_basic`
    (`itemid`, `subid`, `name`, `sortname`, `name_jp`, `type`, `stackSize`, `flags`, `aH`, `BaseSell`)
VALUES
    (12332, 0, 'judges_shield',    'judges_shield',    'ジャッジシールド',   6,  1,  2050, 0,  72),
    (12523, 0, 'judges_helm',      'judges_helm',      'ジャッジヘルム',     6,  1,  2050, 0,  58),
    (12551, 0, 'judges_cuirass',   'judges_cuirass',   'ジャッジキュイラス', 6,  1,  2050, 0, 165),
    (12679, 0, 'judges_gauntlets', 'judges_gauntlets', 'ジャッジガントレ',   6,  1,  2050, 0,  68),
    (12807, 0, 'judges_cuisses',   'judges_cuisses',   'ジャッジクウィス',   6,  1,  2050, 0,  97),
    (12935, 0, 'judges_greaves',   'judges_greaves',   'ジャッジグリーヴ',   6,  1,  2050, 0,  65),
    (13074, 0, 'judges_gorget',    'judges_gorget',    'ジャッジゴルゲット', 6,  1,  2050, 0,  58),
    (13215, 0, 'judges_belt',      'judges_belt',      'ジャッジベルト',     6,  1,  2050, 0,  64),
    (13358, 0, 'judges_earring',   'judges_earring',   'ジャッジピアス',     6,  1,  2050, 0,  40),
    (13505, 0, 'judges_ring',      'judges_ring',      'ジャッジリング',     6,  1,  2050, 0,  61),
    (13606, 0, 'judges_cape',      'judges_cape',      'ジャッジケープ',     6,  1,  2050, 0, 131),
    (16622, 0, 'judges_sword',     'judges_sword',     'ジャッジソード',     7,  1, 63554, 0,   0),
    (17004, 0, 'judge_minnow',     'judge_minnow',     'ジャッジミノー',     7,  1,  2050, 0,  60),
    (17012, 0, 'judges_rod',       'judges_rod',       'ジャッジロッド',     7,  1,  2050, 0,  64),
    (17174, 0, 'judges_bow',       'judges_bow',       'ジャッジボウ',       7,  1, 63586, 0,   0),
    (17326, 0, 'judges_arrow',     'judges_arrow',     'ジャッジアロー',     7, 99, 30786, 0,   0),
    (17406, 0, 'judges_lure',      'judges_lure',      'ジャッジルアー',     7,  1,  2050, 0,  50),
    (17644, 0, 'judges_sword',     'judges_sword',     'ジャッジソード',     7,  1, 63554, 0,   0),
    (19325, 0, 'judge_fly',        'judge_fly',        'ジャッジフライ',     7,  1, 63554, 0,   0);

INSERT IGNORE INTO `item_equipment` VALUES
    (12332, 'judges_shield',    1, 0, 4194303,  22, 3, 0,     2, 0, 0, 0),
    (12523, 'judges_helm',      1, 0, 4194303,  30, 0, 0,    16, 0, 0, 0),
    (12551, 'judges_cuirass',   1, 0, 4194303,  30, 0, 0,    32, 0, 0, 0),
    (12679, 'judges_gauntlets', 1, 0, 4194303,  30, 0, 0,    64, 0, 0, 0),
    (12807, 'judges_cuisses',   1, 0, 4194303,  30, 0, 0,   128, 0, 0, 0),
    (12935, 'judges_greaves',   1, 0, 4194303,  30, 0, 0,   256, 0, 0, 0),
    (13074, 'judges_gorget',    1, 0, 4194303,   0, 0, 0,   512, 0, 0, 0),
    (13215, 'judges_belt',      1, 0, 4194303,   0, 0, 0,  1024, 0, 0, 0),
    (13358, 'judges_earring',   1, 0, 4194303,   0, 0, 0,  6144, 0, 0, 0),
    (13505, 'judges_ring',      1, 0, 4194303,   0, 0, 0, 24576, 0, 0, 0),
    (13606, 'judges_cape',      1, 0, 4194303,   0, 0, 0, 32768, 0, 0, 0),
    (16622, 'judges_sword',     1, 0, 4194303, 308, 0, 0,     1, 0, 0, 0),
    (17004, 'judge_minnow',     1, 0, 4194303,   0, 0, 0,     8, 0, 0, 0),
    (17012, 'judges_rod',       1, 0, 4194303,  11, 0, 0,     4, 0, 0, 0),
    (17174, 'judges_bow',       1, 0, 4194303,  40, 0, 0,     4, 0, 0, 0),
    (17326, 'judges_arrow',     1, 0, 4194303,   0, 0, 0,     8, 0, 0, 0),
    (17406, 'judges_lure',      1, 0, 4194303,   0, 0, 0,     8, 0, 0, 0),
    (17644, 'judges_sword',     1, 0, 4194303, 390, 0, 0,     3, 0, 0, 0),
    (19325, 'judge_fly',        1, 0, 4194303,   0, 0, 0,     8, 0, 0, 0);

INSERT IGNORE INTO `item_weapon` VALUES
    (16622, 'judges_sword',  4, 0, 0, 0, 0, 2, 1, 999,  99, 0),
    (17004, 'judge_minnow', 48, 0, 0, 0, 0, 0, 1, 240,   0, 0),
    (17012, 'judges_rod',    48, 0, 0, 0, 0, 0, 1, 240,   0, 0),
    (17174, 'judges_bow',    25, 4, 0, 0, 0, 1, 1, 540, 100, 0),
    (17326, 'judges_arrow',  25, 0, 0, 0, 0, 1, 1, 120, 100, 0),
    (17406, 'judges_lure',   48, 0, 0, 0, 0, 0, 1, 240,   0, 0),
    (17644, 'judges_sword',   3, 0, 0, 0, 0, 2, 1, 240,   0, 0),
    (19325, 'judge_fly',     48, 0, 0, 0, 0, 0, 1, 240,   0, 0);

INSERT IGNORE INTO `item_mods` VALUES
    (12332, 1, 50),
    (12523, 1, 50),
    (12551, 1, 70),
    (12679, 1, 50),
    (12807, 1, 60),
    (12935, 1, 50),
    (13074, 1, 30),
    (13215, 1, 40),
    (13358, 1, 20),
    (13505, 1, 20),
    (13505, 387, -10000),
    (13505, 388, -10000),
    (13505, 389, -10000),
    (13505, 390, -10000),
    (13606, 1, 30),
    (13606, 8, 9999),
    (13606, 9, 9999),
    (13606, 10, 9999),
    (13606, 11, 9999),
    (13606, 12, 9999),
    (13606, 13, 9999),
    (13606, 14, 9999);
