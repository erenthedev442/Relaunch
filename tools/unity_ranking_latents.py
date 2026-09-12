#!/usr/bin/env python3
"""Generate modules/custom/sql/unity_ranking_latents.sql -- the data half of
Relaunch's "Unity Ranking: X+a~b" gear bonus.

Retail Unity Wanted gear carries a bonus that scales with the weekly ranking of
the player's Unity (e.g. Acuity Belt "Unity Ranking: INT+3~7"). LandSandBoat
stubs every one of these out (item_latents.sql only has `??` comments), so on
Relaunch the gear was silently missing its ranking line. This script emits one
LATENT::UNITY_RANKING (id 65) row per tier for every Unity Wanted reward:

    tier 1 = Unity ranked 1st            -> max value
    tier 2 / 3 / 4 = ranked 2nd / 3rd / 4th -> evenly spaced steps
    tier 5 = ranked 5th or lower         -> min value

The server picks the player's tier in charutils::GetUnityRankTier (C++) and
LATENT::UNITY_RANKING activates exactly the matching row. Not pledged to a
Unity -> no bonus. `main.UNITY_RANKING_FIXED_TIER` can pin every pledged player
to one tier (see settings/default/main.lua).

SPEC below is the retail description text of every NQ/+1 item in
modules/custom/lua/unity_wanted_catalog.lua (Windower res/item_descriptions.lua,
2026-09; Arete del Luna's element from bg-wiki). Percent mods (Double Attack,
Fast Cast, Cure potency, ...) are whole percents, matching item_mods.sql.

Nearest-available mod notes:
  * Shomonjijoe "Avatar: Magic Atk. Bonus" -> Mod::PET_MAB_MDB (992): the only
    owner-side pet MAB mod; it also raises the avatar's MDB by the same amount.

Usage (from the repo root):
    python tools/unity_ranking_latents.py            # rewrites the .sql
    python tools/unity_ranking_latents.py --check    # exit 1 if the .sql is stale

The docs generator (Relaunch-Docs tools/docgen/generators/unity_concord.py)
parses the `-- <id> <name>: <bonus>` comment lines of the emitted SQL, so keep
that comment format stable.
"""
from __future__ import annotations

import sys
from pathlib import Path

LATENT_UNITY_RANKING = 65   # src/map/latent_effect.h LATENT::UNITY_RANKING
TIERS = (1, 2, 3, 4, 5)

# (item id, item name, mod id, mod name, value at tier 5 (min), value at tier 1 (max))
SPEC = [
    (10768, 'Gelatinous Ring',            2, 'HP',              10,   35, 'HP+10~35'),
    (10769, 'Gelatinous Ring +1',         2, 'HP',              10,   35, 'HP+10~35'),
    (10770, 'Cacoethic Ring',            27, 'ENMITY',          -1,   -5, 'Enmity-1~5'),
    (10771, 'Cacoethic Ring +1',         27, 'ENMITY',          -1,   -5, 'Enmity-1~5'),
    (20507, 'Comeuppances',             288, 'DOUBLE_ATTACK',    1,    5, '"Double Attack"+1~5%'),
    (20508, 'Comeuppances +1',          288, 'DOUBLE_ATTACK',    1,    5, '"Double Attack"+1~5%'),
    (20521, 'Emeici',                    25, 'ACC',             10,   20, 'Accuracy+10~20'),
    (20522, 'Emeici +1',                 25, 'ACC',             10,   20, 'Accuracy+10~20'),
    (20527, 'Fists of Fury',             10, 'VIT',             10,   15, 'VIT+10~15'),
    (20528, 'Fists of Fury +1',          10, 'VIT',             10,   15, 'VIT+10~15'),
    (20580, 'Kustawi',                  359, 'RAPID_SHOT',       3,    7, '"Rapid Shot"+3~7'),
    (20581, 'Kustawi +1',               359, 'RAPID_SHOT',       3,    7, '"Rapid Shot"+3~7'),
    (20603, 'Ternion Dagger',            11, 'AGI',             10,   15, 'AGI+10~15'),
    (20604, 'Ternion Dagger +1',         11, 'AGI',             10,   15, 'AGI+10~15'),
    (20606, 'Anathema Harpe',            73, 'STORETP',          1,    5, '"Store TP"+1~5'),
    (20607, 'Anathema Harpe +1',         73, 'STORETP',          1,    5, '"Store TP"+1~5'),
    (20611, 'Sangarius',                  8, 'STR',              1,    7, 'STR+1~7'),
    (20612, 'Sangarius +1',               8, 'STR',              1,    7, 'STR+1~7'),
    (20613, 'Pukulatmuj',                12, 'INT',              5,   15, 'INT+5~15'),
    (20614, 'Pukulatmuj +1',             12, 'INT',              5,   15, 'INT+5~15'),
    (20679, 'Tanmogayi',                170, 'FASTCAST',         3,    6, '"Fast Cast"+3~6%'),
    (20680, 'Tanmogayi +1',             170, 'FASTCAST',         3,    6, '"Fast Cast"+3~6%'),
    (20681, 'Flyssa',                    25, 'ACC',             10,   15, 'Accuracy+10~15'),
    (20682, 'Flyssa +1',                 25, 'ACC',             10,   15, 'Accuracy+10~15'),
    (20696, 'Combuster',                 25, 'ACC',             10,   20, 'Accuracy+10~20'),
    (20697, 'Combuster +1',              25, 'ACC',             10,   20, 'Accuracy+10~20'),
    (20708, 'Demers. Degen',            170, 'FASTCAST',         1,    3, '"Fast Cast"+1~3%'),
    (20709, 'Demers. Degen +1',         170, 'FASTCAST',         1,    3, '"Fast Cast"+1~3%'),
    (20799, 'Mdomo Axe',                 27, 'ENMITY',          -3,   -7, 'Enmity-3~7'),
    (20800, 'Mdomo Axe +1',              27, 'ENMITY',          -3,   -7, 'Enmity-3~7'),
    (20804, 'Perun',                     27, 'ENMITY',          -3,   -7, 'Enmity-3~7'),
    (20805, 'Perun +1',                  27, 'ENMITY',          -3,   -7, 'Enmity-3~7'),
    (20806, 'Buramgh',                   14, 'CHR',              1,   10, 'CHR+1~10'),
    (20807, 'Buramgh +1',                14, 'CHR',              1,   10, 'CHR+1~10'),
    (20851, 'Aizkora',                  288, 'DOUBLE_ATTACK',    1,    5, '"Double Attack"+1~5%'),
    (20852, 'Aizkora +1',               288, 'DOUBLE_ATTACK',    1,    5, '"Double Attack"+1~5%'),
    (20853, 'Beheader',                   2, 'HP',              70,  120, 'HP+70~120'),
    (20854, 'Beheader +1',                2, 'HP',              70,  120, 'HP+70~120'),
    (20898, 'Triska Scythe',            288, 'DOUBLE_ATTACK',    1,    3, '"Double Attack"+1~3%'),
    (20899, 'Triska Scythe +1',         288, 'DOUBLE_ATTACK',    1,    3, '"Double Attack"+1~3%'),
    (20942, 'Gae Derg',                 165, 'CRITHITRATE',      1,    5, 'Critical hit rate +1~5%'),
    (20943, 'Gae Derg +1',              165, 'CRITHITRATE',      1,    5, 'Critical hit rate +1~5%'),
    (20980, 'Raicho',                   288, 'DOUBLE_ATTACK',    1,    3, '"Double Attack"+1~3%'),
    (20981, 'Raicho +1',                288, 'DOUBLE_ATTACK',    1,    3, '"Double Attack"+1~3%'),
    (20987, 'Tancho',                   289, 'SUBTLE_BLOW',      1,    6, '"Subtle Blow"+1~6'),
    (20988, 'Tancho +1',                289, 'SUBTLE_BLOW',      1,    6, '"Subtle Blow"+1~6'),
    (21029, 'Norifusa',                   8, 'STR',              1,    7, 'STR+1~7'),
    (21030, 'Norifusa +1',                8, 'STR',              1,    7, 'STR+1~7'),
    (21034, 'Kunimune',                   8, 'STR',             10,   20, 'STR+10~20'),
    (21035, 'Kunimune +1',                8, 'STR',             10,   20, 'STR+10~20'),
    (21075, 'Septoptic',                296, 'CONSERVE_MP',      7,   11, '"Conserve MP"+7~11'),
    (21076, 'Septoptic +1',             296, 'CONSERVE_MP',      7,   11, '"Conserve MP"+7~11'),
    (21090, 'Loxotic Mace',               9, 'DEX',              5,   10, 'DEX+5~10'),
    (21091, 'Loxotic Mace +1',            9, 'DEX',              5,   10, 'DEX+5~10'),
    (21099, 'Magesmasher',               23, 'ATT',              5,   15, 'Attack+5~15'),
    (21100, 'Magesmasher +1',            23, 'ATT',              5,   15, 'Attack+5~15'),
    (21159, 'Marin Staff',               12, 'INT',             10,   15, 'INT+10~15'),
    (21160, 'Marin Staff +1',            12, 'INT',             10,   15, 'INT+10~15'),
    (21162, 'Pouwhenua',                 25, 'ACC',             10,   20, 'Accuracy+10~20'),
    (21163, 'Pouwhenua +1',              25, 'ACC',             10,   20, 'Accuracy+10~20'),
    (21164, 'Ababinili',                374, 'CURE_POTENCY',     6,   10, '"Cure" potency +6~10%'),
    (21165, 'Ababinili +1',             374, 'CURE_POTENCY',     6,   10, '"Cure" potency +6~10%'),
    (21219, 'Paloma Bow',                26, 'RACC',            10,   20, 'Ranged Accuracy+10~20'),
    (21220, 'Paloma Bow +1',             26, 'RACC',            10,   20, 'Ranged Accuracy+10~20'),
    (21222, 'Mengado',                   26, 'RACC',            10,   20, 'Ranged Accuracy+10~20'),
    (21223, 'Mengado +1',                26, 'RACC',            10,   20, 'Ranged Accuracy+10~20'),
    (21343, 'Ghastly Tathlum',           12, 'INT',              2,    6, 'INT+2~6'),
    (21344, 'Ghastly Tathlum +1',        12, 'INT',              2,    6, 'INT+2~6'),
    (21349, 'Wingcutter',                 9, 'DEX',              1,    5, 'DEX+1~5'),
    (21350, 'Wingcutter +1',              9, 'DEX',              1,    5, 'DEX+1~5'),
    (21418, 'Rigorous Grip',             23, 'ATT',             10,   15, 'Attack+10~15'),
    (21419, 'Rigorous Grip +1',          23, 'ATT',             10,   15, 'Attack+10~15'),
    (21483, 'Malison',                   24, 'RATT',            15,   25, 'Ranged Attack+15~25'),
    (21484, 'Malison +1',                24, 'RATT',            15,   25, 'Ranged Attack+15~25'),
    (21688, 'Montante',                 302, 'TRIPLE_ATTACK',    3,    5, '"Triple Attack"+3~5%'),
    (21689, 'Montante +1',              302, 'TRIPLE_ATTACK',    3,    5, '"Triple Attack"+3~5%'),
    (21690, 'Ushenzi',                  374, 'CURE_POTENCY',     6,   10, '"Cure" potency +6~10%'),
    (21691, 'Ushenzi +1',               374, 'CURE_POTENCY',     6,   10, '"Cure" potency +6~10%'),
    (21695, 'Nullis',                     8, 'STR',             10,   20, 'STR+10~20'),
    (21696, 'Nullis +1',                  8, 'STR',             10,   20, 'STR+10~20'),
    (21702, 'Kladenets',                 12, 'INT',             10,   20, 'INT+10~20'),
    (21703, 'Kladenets +1',              12, 'INT',             10,   20, 'INT+10~20'),
    (21748, 'Habilitator',               25, 'ACC',             20,   30, 'Accuracy+20~30'),
    (21749, 'Habilitator +1',            25, 'ACC',             20,   30, 'Accuracy+20~30'),
    (21805, 'Pixquizpan',                28, 'MATT',            15,   25, '"Magic Atk. Bonus"+15~25'),
    (21806, 'Pixquizpan +1',             28, 'MATT',            15,   25, '"Magic Atk. Bonus"+15~25'),
    (22057, 'Contemplator',             369, 'REFRESH',          1,    1, '"Refresh"+1'),
    (22058, 'Contemplator +1',          369, 'REFRESH',          1,    2, '"Refresh"+1~2'),
    (22120, 'Imati',                     24, 'RATT',            20,   30, 'Ranged Attack+20~30'),
    (22121, 'Imati +1',                  24, 'RATT',            20,   30, 'Ranged Attack+20~30'),
    (22254, 'Seeth. Bomblet',             8, 'STR',              1,    5, 'STR+1~5'),
    (22255, 'Seeth. Bomblet +1',          8, 'STR',              1,    5, 'STR+1~5'),
    (22266, 'Antitail',                 288, 'DOUBLE_ATTACK',    1,    3, '"Double Attack"+1~3%'),
    (22267, 'Antitail +1',              288, 'DOUBLE_ATTACK',    1,    3, '"Double Attack"+1~3%'),
    (25601, 'Blistering Sallet',          2, 'HP',              30,   80, 'HP+30~80'),
    (25602, 'Blistering Sallet +1',       2, 'HP',              30,   80, 'HP+30~80'),
    (25635, 'Loess Barbuta',             27, 'ENMITY',           9,   14, 'Enmity+9~14'),
    (25636, 'Loess Barbuta +1',          27, 'ENMITY',           9,   14, 'Enmity+9~14'),
    (25680, 'Cohort Cloak',              30, 'MACC',            10,   20, 'Magic Accuracy+10~20'),
    (25681, 'Cohort Cloak +1',           30, 'MACC',            10,   20, 'Magic Accuracy+10~20'),
    (25709, 'Obviat. Cuirass',           27, 'ENMITY',           1,    8, 'Enmity+1~8'),
    (25710, 'Obviat. Cuirass +1',        27, 'ENMITY',           1,    8, 'Enmity+1~8'),
    (25732, 'Tatena. Harama.',           73, 'STORETP',          5,    9, '"Store TP"+5~9'),
    (25733, 'Tatena. Harama. +1',        73, 'STORETP',          5,    9, '"Store TP"+5~9'),
    (25855, 'Tatena. Haidate',           73, 'STORETP',          4,    8, '"Store TP"+4~8'),
    (25856, 'Tatena. Haidate +1',        73, 'STORETP',          4,    8, '"Store TP"+4~8'),
    (25923, 'Tatena. Sune.',             73, 'STORETP',          4,    8, '"Store TP"+4~8'),
    (25924, 'Tatena. Sune. +1',          73, 'STORETP',          4,    8, '"Store TP"+4~8'),
    (26001, 'Loricate Torque',            1, 'DEF',             10,   15, 'DEF:+10~15'),
    (26002, 'Loricate Torque +1',         1, 'DEF',             10,   15, 'DEF:+10~15'),
    (26021, 'Vim Torque',               369, 'REFRESH',          1,    2, '"Refresh"+1~2'),
    (26022, 'Vim Torque +1',            369, 'REFRESH',          1,    3, '"Refresh"+1~3'),
    (26401, 'Forfend',                   25, 'ACC',             10,   20, 'Accuracy+10~20'),
    (26402, 'Forfend +1',                25, 'ACC',             10,   20, 'Accuracy+10~20'),
    (26709, 'Imp. Wing Hair.',            9, 'DEX',              1,    7, 'DEX+1~7'),
    (26709, 'Imp. Wing Hair.',           11, 'AGI',              1,    7, 'AGI+1~7'),
    (26710, 'Imp. Wing Hair. +1',         9, 'DEX',              1,    7, 'DEX+1~7'),
    (26710, 'Imp. Wing Hair. +1',        11, 'AGI',              1,    7, 'AGI+1~7'),
    (26714, 'Adorned Helm',              23, 'ATT',              5,   15, 'Attack+5~15'),
    (26715, 'Adorned Helm +1',           23, 'ATT',              5,   15, 'Attack+5~15'),
    (26731, 'Stinger Helm',               8, 'STR',              3,    8, 'STR+3~8'),
    (26732, 'Stinger Helm +1',            8, 'STR',              3,    8, 'STR+3~8'),
    (26784, 'Hike Khat',                  5, 'MP',              10,   50, 'MP+10~50'),
    (26785, 'Hike Khat +1',               5, 'MP',              10,   50, 'MP+10~50'),
    (26786, 'Alhazen Hat',                2, 'HP',              30,   80, 'HP+30~80'),
    (26787, 'Alhazen Hat +1',             2, 'HP',              30,   80, 'HP+30~80'),
    (26868, 'Ros. Jaseran',             170, 'FASTCAST',         3,    6, '"Fast Cast"+3~6%'),
    (26869, 'Ros. Jaseran +1',          170, 'FASTCAST',         3,    6, '"Fast Cast"+3~6%'),
    (26870, 'Emet Harness',              25, 'ACC',             10,   20, 'Accuracy+10~20'),
    (26871, 'Emet Harness +1',           25, 'ACC',             10,   20, 'Accuracy+10~20'),
    (26872, 'Hime Domaru',               73, 'STORETP',          1,    5, '"Store TP"+1~5'),
    (26873, 'Hime Domaru +1',            73, 'STORETP',          1,    5, '"Store TP"+1~5'),
    (26887, 'Shomonjijoe',              992, 'PET_MAB_MDB',     25,   30, 'Avatar: "Magic Atk. Bonus"+25~30'),
    (26888, 'Shomonjijoe +1',           992, 'PET_MAB_MDB',     25,   30, 'Avatar: "Magic Atk. Bonus"+25~30'),
    (26896, 'Lugra Cloak',              170, 'FASTCAST',         3,    6, '"Fast Cast"+3~6%'),
    (26897, 'Lugra Cloak +1',           170, 'FASTCAST',         3,    6, '"Fast Cast"+3~6%'),
    (26942, 'Agony Jerkin',              25, 'ACC',             10,   15, 'Accuracy+10~15'),
    (26943, 'Agony Jerkin +1',           25, 'ACC',             10,   15, 'Accuracy+10~15'),
    (27106, 'Asteria Mitts',            369, 'REFRESH',          1,    1, '"Refresh"+1'),
    (27107, 'Asteria Mitts +1',         369, 'REFRESH',          1,    2, '"Refresh"+1~2'),
    (27108, 'Lamassu Mitts',              5, 'MP',              10,   50, 'MP+10~50'),
    (27109, 'Lamassu Mitts +1',           5, 'MP',              10,   50, 'MP+10~50'),
    (27148, 'Tatena. Gote',              73, 'STORETP',          4,    8, '"Store TP"+4~8'),
    (27149, 'Tatena. Gote +1',           73, 'STORETP',          4,    8, '"Store TP"+4~8'),
    (27150, 'Gazu Bracelets',            25, 'ACC',             10,   15, 'Accuracy+10~15'),
    (27151, 'Gazu Bracelets +1',         25, 'ACC',             10,   15, 'Accuracy+10~15'),
    (27230, 'Zoar Subligar',            288, 'DOUBLE_ATTACK',    1,    5, '"Double Attack"+1~5%'),
    (27231, 'Zoar Subligar +1',         288, 'DOUBLE_ATTACK',    1,    5, '"Double Attack"+1~5%'),
    (27407, 'Hygieia Clogs',             27, 'ENMITY',          -3,   -7, 'Enmity-3~7'),
    (27408, 'Hygieia Clogs +1',          27, 'ENMITY',          -3,   -7, 'Enmity-3~7'),
    (27409, 'Hippo. Socks',              68, 'EVA',             15,   20, 'Evasion+15~20'),
    (27410, 'Hippo. Socks +1',           68, 'EVA',             15,   20, 'Evasion+15~20'),
    (27508, 'Unmoving Collar',           25, 'ACC',              1,    5, 'Accuracy+1~5'),
    (27509, 'Unmoving Collar +1',        25, 'ACC',              1,    5, 'Accuracy+1~5'),
    (27517, 'Bathy Choker',              68, 'EVA',              5,   15, 'Evasion+5~15'),
    (27518, 'Bathy Choker +1',           68, 'EVA',              5,   15, 'Evasion+5~15'),
    (27532, 'Zwazo Earring',              8, 'STR',              1,    5, 'STR+1~5'),
    (27533, 'Zwazo Earring +1',           8, 'STR',              1,    5, 'STR+1~5'),
    (27542, 'Domin. Earring',            25, 'ACC',              1,    5, 'Accuracy+1~5'),
    (27543, 'Domin. Earring +1',         25, 'ACC',              1,    5, 'Accuracy+1~5'),
    (27548, 'Odnowa Earring',            25, 'ACC',              5,   10, 'Accuracy+5~10'),
    (27549, 'Odnowa Earring +1',         25, 'ACC',              5,   10, 'Accuracy+5~10'),
    (27560, 'Apeile Ring',               27, 'ENMITY',           5,    9, 'Enmity+5~9'),
    (27561, 'Apeile Ring +1',            27, 'ENMITY',           5,    9, 'Enmity+5~9'),
    (27562, 'Metamor. Ring',             30, 'MACC',             1,    5, 'Magic Accuracy+1~5'),
    (27563, 'Metamor. Ring +1',          30, 'MACC',             1,    5, 'Magic Accuracy+1~5'),
    (27601, 'Ground. Mantle',             9, 'DEX',              1,    7, 'DEX+1~7'),
    (27602, 'Ground. Mantle +1',          9, 'DEX',              1,    7, 'DEX+1~7'),
    (27609, 'Fi Follet Cape',            13, 'MND',              1,    5, 'MND+1~5'),
    (27610, 'Fi Follet Cape +1',         13, 'MND',              1,    5, 'MND+1~5'),
    (27636, 'Evalach',                    5, 'MP',              10,   50, 'MP+10~50'),
    (27637, 'Evalach +1',                 5, 'MP',              10,   50, 'MP+10~50'),
    (27638, 'Ajax',                       2, 'HP',              70,  120, 'HP+70~120'),
    (27639, 'Ajax +1',                    2, 'HP',              70,  120, 'HP+70~120'),
    (27640, 'Deliverance',               25, 'ACC',             10,   15, 'Accuracy+10~15'),
    (27641, 'Deliverance +1',            25, 'ACC',             10,   15, 'Accuracy+10~15'),
    (27993, 'Macabre Gaunt.',             2, 'HP',              20,   60, 'HP+20~60'),
    (27994, 'Macabre Gaunt. +1',          2, 'HP',              20,   60, 'HP+20~60'),
    (27995, 'Shigure Tekko',            289, 'SUBTLE_BLOW',      1,    7, '"Subtle Blow"+1~7'),
    (27996, 'Shigure Tekko +1',         289, 'SUBTLE_BLOW',      1,    7, '"Subtle Blow"+1~7'),
    (28134, 'Assid. Pants',             369, 'REFRESH',          1,    1, '"Refresh"+1'),
    (28135, 'Assid. Pants +1',          369, 'REFRESH',          1,    2, '"Refresh"+1~2'),
    (28136, 'Augury Cuisses',           288, 'DOUBLE_ATTACK',    1,    3, '"Double Attack"+1~3%'),
    (28137, 'Augury Cuisses +1',        288, 'DOUBLE_ATTACK',    1,    3, '"Double Attack"+1~3%'),
    (28273, 'Regal Pumps',              170, 'FASTCAST',         1,    3, '"Fast Cast"+1~3%'),
    (28274, 'Regal Pumps +1',           170, 'FASTCAST',         1,    3, '"Fast Cast"+1~3%'),
    (28275, 'Jute Boots',                68, 'EVA',              1,   10, 'Evasion+1~10'),
    (28276, 'Jute Boots +1',             68, 'EVA',              1,   10, 'Evasion+1~10'),
    (28352, 'Canto Necklace',            14, 'CHR',              5,   12, 'CHR+5~12'),
    (28353, 'Canto Necklace +1',         14, 'CHR',              5,   12, 'CHR+5~12'),
    (28412, 'Kentarch Belt',             73, 'STORETP',          1,    5, '"Store TP"+1~5'),
    (28413, 'Kentarch Belt +1',          73, 'STORETP',          1,    5, '"Store TP"+1~5'),
    (28423, 'Shinjutsu-no-Obi',          71, 'MPHEAL',           5,    7, 'MP recovered while healing +5~7'),
    (28424, 'Shinjutsu-no-Obi +1',       71, 'MPHEAL',           5,    7, 'MP recovered while healing +5~7'),
    (28427, 'Sailfi Belt',               23, 'ATT',             10,   15, 'Attack+10~15'),
    (28428, 'Sailfi Belt +1',            23, 'ATT',             10,   15, 'Attack+10~15'),
    (28429, 'Acuity Belt',               12, 'INT',              3,    7, 'INT+3~7'),
    (28430, 'Acuity Belt +1',            12, 'INT',              3,    7, 'INT+3~7'),
    (28481, 'Lugra Earring',            288, 'DOUBLE_ATTACK',    1,    3, '"Double Attack"+1~3%'),
    (28482, 'Lugra Earring +1',         288, 'DOUBLE_ATTACK',    1,    3, '"Double Attack"+1~3%'),
    (28486, 'Arete del Luna',            21, 'LIGHT_MEVA',      15,   25, 'Light+15~25'),
    (28487, 'Arete del Luna +1',         21, 'LIGHT_MEVA',      15,   25, 'Light+15~25'),
]


def tier_value(lo: int, hi: int, tier: int) -> int:
    """Value for a tier: max at tier 1, min at tier 5, evenly spaced between,
    rounded half-up on the magnitude so negative (Enmity-) bonuses mirror the
    positive ones exactly."""
    sign = -1 if (lo < 0 or hi < 0) else 1
    lo_m, hi_m = abs(lo), abs(hi)
    v = lo_m + (hi_m - lo_m) * (5 - tier) / 4.0
    return sign * int(v + 0.5)


def render() -> str:
    out = [
        "-- GENERATED by tools/unity_ranking_latents.py -- do not hand-edit; rerun the script.",
        "-- Relaunch: retail \"Unity Ranking: X+a~b\" bonuses for every Unity Wanted reward.",
        "-- Latent 65 = UNITY_RANKING; latentParam = tier (1 = Unity ranked 1st ... 5 = 5th or lower).",
        "-- Not pledged to a Unity -> no row is active.",
        "",
        "DELETE FROM `item_latents` WHERE `latentId` = %d;" % LATENT_UNITY_RANKING,
        "",
    ]
    last_item = None
    for item_id, name, mod_id, mod_name, lo, hi, text in SPEC:
        if item_id != last_item:
            out.append("")
            last_item = item_id
        out.append("-- %d %s: %s" % (item_id, name, text))
        for tier in TIERS:
            out.append("INSERT INTO `item_latents` VALUES (%d, %d, %d, %d, %d);  -- %s %+d (tier %d)"
                       % (item_id, mod_id, tier_value(lo, hi, tier), LATENT_UNITY_RANKING, tier,
                          mod_name, tier_value(lo, hi, tier), tier))
    out.append("")
    return "\n".join(out)


def main() -> int:
    repo_root = Path(__file__).resolve().parents[1]
    target = repo_root / "modules" / "custom" / "sql" / "unity_ranking_latents.sql"
    text = render()
    if "--check" in sys.argv:
        current = target.read_text(encoding="utf-8") if target.exists() else ""
        if current != text:
            print("STALE: %s differs from generator output -- rerun tools/unity_ranking_latents.py" % target)
            return 1
        print("OK: %s is up to date (%d rows)" % (target, sum(1 for l in text.splitlines() if l.startswith("INSERT"))))
        return 0
    target.write_text(text, encoding="utf-8")
    print("wrote %s: %d items, %d rows" % (target, len({s[0] for s in SPEC}),
                                            sum(1 for l in text.splitlines() if l.startswith("INSERT"))))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
