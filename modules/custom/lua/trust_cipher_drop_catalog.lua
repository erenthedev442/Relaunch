-----------------------------------
-- trust_cipher_drop_catalog.lua
-- Auto-derived from exports/trust_cipher_drop_proposal.csv
-- Keyed by content system + normalized NM name (alnum lower).
-- Starters / Void Keeper / disabled rows are omitted.
-----------------------------------
local C = {}

-- system -> normalizedNm -> entry
C.bySystem = {
    hl =
    {
        ['bombqueen'] = { method = 'cipher_drop', itemId = 10155, spellId = 970, dropPct = 13, trustName = 'Brygid', nmName = 'Bomb_Queen' },
        ['simurgh'] = { method = 'direct_spell_grant', itemId = 0, spellId = 918, dropPct = 13, trustName = 'Gessho', nmName = 'Simurgh' },
        ['vrtra'] = { method = 'cipher_drop', itemId = 10117, spellId = 911, dropPct = 13, trustName = 'Joachim', nmName = 'Vrtra' },
        ['shinryu'] = { method = 'cipher_drop', itemId = 10162, spellId = 978, dropPct = 8, trustName = 'Kupofried', nmName = 'Shinryu' },
        ['tomtittat'] = { method = 'cipher_drop', itemId = 10120, spellId = 922, dropPct = 15, trustName = 'Lehko Habhoka', nmName = 'Tom_Tit_Tat' },
        ['valkurmemperor'] = { method = 'cipher_drop', itemId = 10115, spellId = 909, dropPct = 15, trustName = 'Mihli Aliapoh', nmName = 'Valkurm_Emperor' },
        ['leapinglizzy'] = { method = 'cipher_drop', itemId = 10118, spellId = 912, dropPct = 15, trustName = 'Naja Salaheem', nmName = 'Leaping_Lizzy' },
        ['roc'] = { method = 'cipher_drop', itemId = 10139, spellId = 951, dropPct = 13, trustName = 'Rahal', nmName = 'Roc' },
        ['kingbehemoth'] = { method = 'cipher_drop', itemId = 10119, spellId = 920, dropPct = 11, trustName = 'Rainemard', nmName = 'King_Behemoth' },
        ['absolutevirtue'] = { method = 'cipher_drop', itemId = 10187, spellId = 1019, dropPct = 9, trustName = 'Shantotto II', nmName = 'Absolute_Virtue' },
        ['pandemoniumwarden'] = { method = 'direct_spell_grant', itemId = 0, spellId = 914, dropPct = 9, trustName = 'Ulmia', nmName = 'Pandemonium_Warden' },
        ['nidhogg'] = { method = 'cipher_drop', itemId = 10112, spellId = 906, dropPct = 11, trustName = 'Zeid', nmName = 'Nidhogg' },
    },
    unity =
    {
        ['pricklypitriv'] = { method = 'cipher_drop', itemId = 10144, spellId = 959, dropPct = 15, trustName = 'Abenzio', nmName = 'Prickly_Pitriv' },
        ['immanibugard'] = { method = 'direct_spell_grant', itemId = 0, spellId = 904, dropPct = 15, trustName = 'Ajido-Marujido', nmName = 'Immanibugard' },
        ['emperorarthro'] = { method = 'cipher_drop', itemId = 10149, spellId = 939, dropPct = 15, trustName = 'Areuhat', nmName = 'Emperor_Arthro' },
        ['jestermalatrix'] = { method = 'direct_spell_grant', itemId = 0, spellId = 900, dropPct = 15, trustName = 'Ayame', nmName = 'Jester_Malatrix' },
        ['wyvernhunterbambrox'] = { method = 'direct_spell_grant', itemId = 0, spellId = 1005, dropPct = 11, trustName = 'Ayame UC', nmName = 'Wyvernhunter_Bambrox' },
        ['hugemawharold'] = { method = 'cipher_drop', itemId = 10143, spellId = 958, dropPct = 15, trustName = 'Babban', nmName = 'Hugemaw_Harold' },
        ['abyssdiver'] = { method = 'cipher_drop', itemId = 10130, spellId = 941, dropPct = 15, trustName = 'Elivira', nmName = 'Abyssdiver' },
        ['mephitas'] = { method = 'direct_spell_grant', itemId = 0, spellId = 957, dropPct = 11, trustName = 'Flaviria UC', nmName = 'Mephitas' },
        ['garbagegel'] = { method = 'direct_spell_grant', itemId = 0, spellId = 919, dropPct = 13, trustName = 'Gadalar', nmName = 'Garbage_Gel' },
        ['keeperofheiligtum'] = { method = 'cipher_drop', itemId = 10158, spellId = 972, dropPct = 15, trustName = 'Halver', nmName = 'Keeper_of_Heiligtum' },
        ['strix'] = { method = 'direct_spell_grant', itemId = 0, spellId = 921, dropPct = 13, trustName = 'Ingrid', nmName = 'Strix' },
        ['vidmapire'] = { method = 'direct_spell_grant', itemId = 0, spellId = 954, dropPct = 11, trustName = 'Invincible Shield UC', nmName = 'Vidmapire' },
        ['shedu'] = { method = 'cipher_drop', itemId = 10186, spellId = 1018, dropPct = 11, trustName = 'Iroha II', nmName = 'Shedu' },
        ['tolba'] = { method = 'direct_spell_grant', itemId = 0, spellId = 956, dropPct = 11, trustName = 'Jakoh UC', nmName = 'Tolba' },
        ['woodlandmender'] = { method = 'cipher_drop', itemId = 10142, spellId = 936, dropPct = 15, trustName = 'Karaha-Baruha', nmName = 'Woodland_Mender' },
        ['joyousgreen'] = { method = 'cipher_drop', itemId = 10146, spellId = 961, dropPct = 15, trustName = 'Kukki-Chebukki', nmName = 'Joyous_Green' },
        ['warbladebeak'] = { method = 'cipher_drop', itemId = 10132, spellId = 943, dropPct = 15, trustName = 'Lhu Mhakaracca', nmName = 'Warblade_Beak' },
        ['bakunawa'] = { method = 'cipher_drop', itemId = 10171, spellId = 1013, dropPct = 11, trustName = 'Lilisette II', nmName = 'Bakunawa' },
        ['sovereignbehemoth'] = { method = 'direct_spell_grant', itemId = 0, spellId = 933, dropPct = 13, trustName = 'Maat', nmName = 'Sovereign_Behemoth' },
        ['intuila'] = { method = 'cipher_drop', itemId = 10147, spellId = 962, dropPct = 15, trustName = 'Margret', nmName = 'Intuila' },
        ['cactrotveloz'] = { method = 'cipher_drop', itemId = 10151, spellId = 966, dropPct = 15, trustName = 'Mayakov', nmName = 'Cactrot_Veloz' },
        ['muut'] = { method = 'cipher_drop', itemId = 10135, spellId = 946, dropPct = 13, trustName = 'Mumor', nmName = 'Muut' },
        ['ayapec'] = { method = 'direct_spell_grant', itemId = 0, spellId = 1008, dropPct = 11, trustName = 'Naja UC', nmName = 'Ayapec' },
        ['arke'] = { method = 'direct_spell_grant', itemId = 0, spellId = 923, dropPct = 13, trustName = 'Nashmeira', nmName = 'Arke' },
        ['specterworm'] = { method = 'cipher_drop', itemId = 10170, spellId = 1012, dropPct = 11, trustName = 'Nashmeira II', nmName = 'Specter_Worm' },
        ['lumberjill'] = { method = 'cipher_drop', itemId = 10131, spellId = 942, dropPct = 13, trustName = 'Noillurie', nmName = 'Lumber_Jill' },
        ['centurioxxi'] = { method = 'direct_spell_grant', itemId = 0, spellId = 953, dropPct = 11, trustName = 'Pieuje UC', nmName = 'Centurio_XX-I' },
        ['ironhornbaldurno'] = { method = 'direct_spell_grant', itemId = 0, spellId = 949, dropPct = 15, trustName = 'Romaa Mihgo', nmName = 'Ironhorn_Baldurno' },
        ['largantua'] = { method = 'direct_spell_grant', itemId = 0, spellId = 915, dropPct = 13, trustName = 'Shikaree Z', nmName = 'Largantua' },
        ['tumultcurator'] = { method = 'direct_spell_grant', itemId = 0, spellId = 981, dropPct = 9, trustName = 'Sylvie UC', nmName = 'Tumult_Curator' },
        ['thuban'] = { method = 'cipher_drop', itemId = 10167, spellId = 1014, dropPct = 13, trustName = 'Tenzen II', nmName = 'Thuban' },
        ['coca'] = { method = 'direct_spell_grant', itemId = 0, spellId = 980, dropPct = 11, trustName = 'Yoran-Oran UC', nmName = 'Coca' },
        ['tiyanak'] = { method = 'direct_spell_grant', itemId = 0, spellId = 924, dropPct = 15, trustName = 'Zazarg', nmName = 'Tiyanak' },
    },
    geas =
    {
        ['arkangelev'] = { method = 'cipher_drop', itemId = 10191, spellId = 993, dropPct = 11, trustName = 'AA EV', nmName = 'Ark_Angel_EV' },
        ['arkangelgk'] = { method = 'cipher_drop', itemId = 10192, spellId = 996, dropPct = 11, trustName = 'AA GK', nmName = 'Ark_Angel_GK' },
        ['arkangelhm'] = { method = 'cipher_drop', itemId = 10188, spellId = 992, dropPct = 11, trustName = 'AA HM', nmName = 'Ark_Angel_HM' },
        ['arkangelmr'] = { method = 'cipher_drop', itemId = 10190, spellId = 994, dropPct = 11, trustName = 'AA MR', nmName = 'Ark_Angel_MR' },
        ['arkangeltt'] = { method = 'cipher_drop', itemId = 10189, spellId = 995, dropPct = 11, trustName = 'AA TT', nmName = 'Ark_Angel_TT' },
        ['teles'] = { method = 'cipher_drop', itemId = 10169, spellId = 982, dropPct = 9, trustName = 'Abquhbah', nmName = 'Teles' },
        ['pazuzu'] = { method = 'cipher_drop', itemId = 10172, spellId = 983, dropPct = 11, trustName = 'Balamor', nmName = 'Pazuzu' },
        ['kamohoalii'] = { method = 'cipher_drop', itemId = 10129, spellId = 934, dropPct = 13, trustName = 'D. Shantotto', nmName = 'Kamohoalii' },
        ['azidahaka'] = { method = 'cipher_drop', itemId = 10183, spellId = 991, dropPct = 9, trustName = 'Darrcuiln', nmName = 'Azi_Dahaka' },
        ['genbuescha'] = { method = 'cipher_drop', itemId = 10148, spellId = 938, dropPct = 11, trustName = 'Gilgamesh', nmName = 'Genbu-Escha' },
        ['byakkoescha'] = { method = 'cipher_drop', itemId = 10141, spellId = 950, dropPct = 11, trustName = 'Kuyin Hathdenna', nmName = 'Byakko-Escha' },
        ['seiryuescha'] = { method = 'cipher_drop', itemId = 10124, spellId = 928, dropPct = 11, trustName = 'Luzaf', nmName = 'Seiryu-Escha' },
        ['warderofcourage'] = { method = 'cipher_drop', itemId = 10180, spellId = 988, dropPct = 9, trustName = 'Makki-Chebukki', nmName = 'Warder_of_Courage' },
        -- Geas catalog name is 'Kirin' (not Kirin-Escha like the other gods).
        ['kirin'] = { method = 'cipher_drop', itemId = 10156, spellId = 971, dropPct = 11, trustName = 'Mildaurion', nmName = 'Kirin' },
        ['wepwawet'] = { method = 'cipher_drop', itemId = 10122, spellId = 926, dropPct = 15, trustName = 'Mnejing', nmName = 'Wepwawet' },
        ['maju'] = { method = 'cipher_drop', itemId = 10193, spellId = 999, dropPct = 9, trustName = 'Monberaux', nmName = 'Maju' },
        ['warderofhope'] = { method = 'cipher_drop', itemId = 10182, spellId = 990, dropPct = 9, trustName = 'Morimar', nmName = 'Warder_of_Hope' },
        ['warderofjustice'] = { method = 'cipher_drop', itemId = 10121, spellId = 925, dropPct = 15, trustName = 'Ovjang', nmName = 'Warder_of_Justice' },
        ['fleetstalker'] = { method = 'cipher_drop', itemId = 10161, spellId = 973, dropPct = 11, trustName = 'Rongelouts', nmName = 'Fleetstalker' },
        ['urmahlullu'] = { method = 'cipher_drop', itemId = 10176, spellId = 985, dropPct = 11, trustName = 'Rosulatia', nmName = 'Urmahlullu' },
        ['ionos'] = { method = 'cipher_drop', itemId = 10145, spellId = 960, dropPct = 13, trustName = 'Rughadjeen', nmName = 'Ionos' },
        ['tangatamanu'] = { method = 'cipher_drop', itemId = 10123, spellId = 927, dropPct = 15, trustName = 'Sakura', nmName = 'Tangata_Manu' },
        ['albumen'] = { method = 'cipher_drop', itemId = 10173, spellId = 979, dropPct = 9, trustName = "Selh'Teus", nmName = 'Albumen' },
        ['warderoffaith'] = { method = 'cipher_drop', itemId = 10157, spellId = 940, dropPct = 15, trustName = 'Semih Lafihna', nmName = 'Warder_of_Faith' },
    },
    reforge =
    {
        ['aello'] = { method = 'cipher_drop', itemId = 10153, spellId = 968, dropPct = 15, trustName = 'Adelheid', nmName = 'Aello' },
        ['byakko'] = { method = 'cipher_drop', itemId = 10138, spellId = 937, dropPct = 11, trustName = 'Cid', nmName = 'Byakko' },
        ['suzaku'] = { method = 'cipher_drop', itemId = 10128, spellId = 932, dropPct = 13, trustName = 'Fablinix', nmName = 'Suzaku' },
        ['bukhis'] = { method = 'cipher_drop', itemId = 10133, spellId = 944, dropPct = 15, trustName = 'Ferreous Coffin', nmName = 'Bukhis' },
        ['iratham'] = { method = 'cipher_drop', itemId = 10185, spellId = 997, dropPct = 13, trustName = 'Iroha', nmName = 'Iratham' },
        ['khun'] = { method = 'cipher_drop', itemId = 10140, spellId = 952, dropPct = 13, trustName = 'Koru-Moru', nmName = 'Khun' },
        ['padfoot'] = { method = 'cipher_drop', itemId = 10137, spellId = 945, dropPct = 11, trustName = 'Lilisette', nmName = 'Padfoot' },
        ['seiryu'] = { method = 'cipher_drop', itemId = 10113, spellId = 907, dropPct = 11, trustName = 'Lion', nmName = 'Seiryu' },
        ['tinnin'] = { method = 'cipher_drop', itemId = 10159, spellId = 1009, dropPct = 9, trustName = 'Lion II', nmName = 'Tinnin' },
        ['genbu'] = { method = 'cipher_drop', itemId = 10127, spellId = 931, dropPct = 15, trustName = 'Moogle', nmName = 'Genbu' },
        ['glavoid'] = { method = 'cipher_drop', itemId = 10152, spellId = 967, dropPct = 11, trustName = 'Qultada', nmName = 'Glavoid' },
        ['kirin'] = { method = 'cipher_drop', itemId = 10116, spellId = 910, dropPct = 9, trustName = 'Valaineral', nmName = 'Kirin' },
    },
    abyssea =
    {
        ['apademak'] = { method = 'cipher_drop', itemId = 10154, spellId = 969, dropPct = 11, trustName = 'Amchuchu', nmName = 'Apademak' },
        ['chloris'] = { method = 'direct_spell_grant', itemId = 0, spellId = 955, dropPct = 9, trustName = 'Apururu UC', nmName = 'Chloris' },
        ['eccentriceve'] = { method = 'direct_spell_grant', itemId = 0, spellId = 965, dropPct = 13, trustName = 'Arciela', nmName = 'Eccentric_Eve' },
        ['itzpapalotl'] = { method = 'cipher_drop', itemId = 10184, spellId = 1017, dropPct = 11, trustName = 'Arciela II', nmName = 'Itzpapalotl' },
        ['alfard'] = { method = 'cipher_drop', itemId = 10175, spellId = 984, dropPct = 11, trustName = 'August', nmName = 'Alfard' },
        ['azdaja'] = { method = 'direct_spell_grant', itemId = 0, spellId = 963, dropPct = 9, trustName = 'Chacharoon', nmName = 'Azdaja' },
        ['bloodguzzler'] = { method = 'direct_spell_grant', itemId = 0, spellId = 916, dropPct = 15, trustName = 'Cherukiki', nmName = 'Bloodguzzler' },
        ['topplingtuber'] = { method = 'direct_spell_grant', itemId = 0, spellId = 1004, dropPct = 13, trustName = 'Excenmille S', nmName = 'Toppling_Tuber' },
        ['shaula'] = { method = 'cipher_drop', itemId = 10174, spellId = 1016, dropPct = 13, trustName = 'Ingrid II', nmName = 'Shaula' },
        ['blazingeruca'] = { method = 'direct_spell_grant', itemId = 0, spellId = 917, dropPct = 13, trustName = 'Iron Eater', nmName = 'Blazing_Eruca' },
        ['ketea'] = { method = 'cipher_drop', itemId = 10165, spellId = 976, dropPct = 11, trustName = 'Kayeel-Payeel', nmName = 'Ketea' },
        ['briareus'] = { method = 'cipher_drop', itemId = 10181, spellId = 989, dropPct = 11, trustName = 'King of Hearts', nmName = 'Briareus' },
        ['lordvarney'] = { method = 'direct_spell_grant', itemId = 0, spellId = 948, dropPct = 13, trustName = 'Klara', nmName = 'Lord_Varney' },
        ['kukulkan'] = { method = 'cipher_drop', itemId = 10150, spellId = 964, dropPct = 9, trustName = 'Lhe Lhangavo', nmName = 'Kukulkan' },
        ['amarok'] = { method = 'direct_spell_grant', itemId = 0, spellId = 1006, dropPct = 13, trustName = 'Maat UC', nmName = 'Amarok' },
        ['dvalinn'] = { method = 'cipher_drop', itemId = 10164, spellId = 975, dropPct = 11, trustName = 'Maximilian', nmName = 'Dvalinn' },
        ['bennu'] = { method = 'cipher_drop', itemId = 10177, spellId = 1015, dropPct = 11, trustName = 'Mumor II', nmName = 'Bennu' },
        ['carabosse'] = { method = 'cipher_drop', itemId = 10125, spellId = 929, dropPct = 13, trustName = 'Najelith', nmName = 'Carabosse' },
        ['arimaspi'] = { method = 'direct_spell_grant', itemId = 0, spellId = 897, dropPct = 15, trustName = 'Naji', nmName = 'Arimaspi' },
        ['sirrush'] = { method = 'direct_spell_grant', itemId = 0, spellId = 913, dropPct = 13, trustName = 'Prishe', nmName = 'Sirrush' },
        ['lorelei'] = { method = 'cipher_drop', itemId = 10168, spellId = 1011, dropPct = 9, trustName = 'Prishe II', nmName = 'Lorelei' },
        ['durinn'] = { method = 'cipher_drop', itemId = 10166, spellId = 977, dropPct = 13, trustName = 'Robel-Akbel', nmName = 'Durinn' },
        ['titlacauan'] = { method = 'cipher_drop', itemId = 10179, spellId = 986, dropPct = 9, trustName = 'Teodor', nmName = 'Titlacauan' },
        ['pantokrator'] = { method = 'cipher_drop', itemId = 10136, spellId = 947, dropPct = 9, trustName = 'Uka Totlihn', nmName = 'Pantokrator' },
        ['ikuturso'] = { method = 'cipher_drop', itemId = 10178, spellId = 987, dropPct = 11, trustName = 'Ullegore', nmName = 'Iku-Turso' },
        ['maahes'] = { method = 'direct_spell_grant', itemId = 0, spellId = 903, dropPct = 13, trustName = 'Volker', nmName = 'Maahes' },
        ['isgebind'] = { method = 'direct_spell_grant', itemId = 0, spellId = 998, dropPct = 9, trustName = 'Ygnas', nmName = 'Isgebind' },
        ['orthrus'] = { method = 'cipher_drop', itemId = 10160, spellId = 1010, dropPct = 9, trustName = 'Zeid II', nmName = 'Orthrus' },
    },
    gauntlet =
    {
        ['aquarius'] = { method = 'cipher_drop', itemId = 10163, spellId = 974, dropPct = 13, trustName = 'Leonoyne', nmName = 'Aquarius' },
        ['serket'] = { method = 'cipher_drop', itemId = 10134, spellId = 935, dropPct = 13, trustName = 'Star Sibyl', nmName = 'Serket' },
    },
}

function C.normalize(name)
    if name == nil then
        return ''
    end

    return tostring(name):lower():gsub('[^%w]', '')
end

function C.lookup(system, nmName)
    local bucket = C.bySystem[system]
    if not bucket then
        return nil
    end

    return bucket[C.normalize(nmName)]
end

return C

