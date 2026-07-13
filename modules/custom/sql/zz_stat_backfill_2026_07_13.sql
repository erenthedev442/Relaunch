-- ============================================================================
-- Stat backfill for attainable-but-statless equipment (owner audit 2026-07-13)
-- ----------------------------------------------------------------------------
-- Cross-referenced 7,899 gear-finder "obtainable" items against item_mods /
-- item_weapon / item_latents to find 611 attainable pieces with NO stats
-- anywhere in the DB. Fetched retail stats from ffxiah.com for each and
-- generated INSERTs/UPDATEs.
--
-- RESULTS
--   611 items swept
--   496 items had retail stats populated on ffxiah (81%)
--   115 items came back empty (Hexed augment recipients, guild signboards,
--       costume-only pieces) -- correctly SKIPPED, no rows written.
--   1,336 item_mods rows inserted across 289 items
--   296 item_weapon rows updated (dmg/delay for basic weapons)
--
-- IDEMPOTENT
--   All INSERTs use IGNORE so re-application is safe against any mods that
--   land in item_mods later. item_weapon UPDATEs set specific columns.
--
-- ROLLBACK
--   The itemIds in this file can be extracted (`grep -oP 'itemId=\d+|VALUES \(\d+' zz_stat_backfill_2026_07_13.sql`)
--   and used to DELETE from item_mods / restore item_weapon rows if needed.
-- ============================================================================

-- SAFETY: uses INSERT IGNORE so re-running is safe against existing mods.

-- 16448  bronze_dagger  (lvl 1, ilvl 0, bucket shield)
UPDATE `item_weapon` SET dmg=3, delay=183 WHERE itemId=16448;

-- 16449  brass_dagger  (lvl 9, ilvl 0, bucket shield)
UPDATE `item_weapon` SET dmg=5, delay=183 WHERE itemId=16449;

-- 16450  dagger  (lvl 12, ilvl 0, bucket shield)
UPDATE `item_weapon` SET dmg=7, delay=183 WHERE itemId=16450;

-- 16451  mythril_dagger  (lvl 23, ilvl 0, bucket shield)
UPDATE `item_weapon` SET dmg=10, delay=183 WHERE itemId=16451;

-- 16455  baselard  (lvl 18, ilvl 0, bucket shield)
UPDATE `item_weapon` SET dmg=8, delay=186 WHERE itemId=16455;

-- 16456  mythril_baselard  (lvl 36, ilvl 0, bucket shield)
UPDATE `item_weapon` SET dmg=13, delay=186 WHERE itemId=16456;

-- 16457  darksteel_baselard  (lvl 55, ilvl 0, bucket shield)
UPDATE `item_weapon` SET dmg=20, delay=195 WHERE itemId=16457;

-- 16460  kris  (lvl 27, ilvl 0, bucket shield)
UPDATE `item_weapon` SET dmg=11, delay=192 WHERE itemId=16460;

-- 16465  bronze_knife  (lvl 1, ilvl 0, bucket shield)
UPDATE `item_weapon` SET dmg=4, delay=195 WHERE itemId=16465;

-- 16466  knife  (lvl 13, ilvl 0, bucket shield)
UPDATE `item_weapon` SET dmg=8, delay=195 WHERE itemId=16466;

-- 16467  mythril_knife  (lvl 31, ilvl 0, bucket shield)
UPDATE `item_weapon` SET dmg=12, delay=195 WHERE itemId=16467;

-- 16468  darksteel_knife  (lvl 53, ilvl 0, bucket shield)
UPDATE `item_weapon` SET dmg=19, delay=195 WHERE itemId=16468;

-- 16469  cermet_knife  (lvl 60, ilvl 0, bucket shield)
UPDATE `item_weapon` SET dmg=20, delay=186 WHERE itemId=16469;

-- 16473  kukri  (lvl 20, ilvl 0, bucket shield)
UPDATE `item_weapon` SET dmg=10, delay=200 WHERE itemId=16473;

-- 16475  mythril_kukri  (lvl 34, ilvl 0, bucket shield)
UPDATE `item_weapon` SET dmg=14, delay=200 WHERE itemId=16475;

-- 16476  darksteel_kukri  (lvl 59, ilvl 0, bucket shield)
UPDATE `item_weapon` SET dmg=22, delay=200 WHERE itemId=16476;

-- 16477  cermet_kukri  (lvl 62, ilvl 0, bucket shield)
UPDATE `item_weapon` SET dmg=22, delay=194 WHERE itemId=16477;

-- 16491  bronze_knife_+1  (lvl 1, ilvl 0, bucket shield)
UPDATE `item_weapon` SET dmg=5, delay=189 WHERE itemId=16491;

-- 16492  bronze_dagger_+1  (lvl 1, ilvl 0, bucket shield)
UPDATE `item_weapon` SET dmg=4, delay=178 WHERE itemId=16492;

-- 16512  bilbo  (lvl 13, ilvl 0, bucket shield)
UPDATE `item_weapon` SET dmg=11, delay=226 WHERE itemId=16512;

-- 16513  tuck  (lvl 23, ilvl 0, bucket shield)
UPDATE `item_weapon` SET dmg=15, delay=226 WHERE itemId=16513;

-- 16514  mailbreaker  (lvl 60, ilvl 0, bucket shield)
UPDATE `item_weapon` SET dmg=30, delay=226 WHERE itemId=16514;

-- 16517  degen  (lvl 20, ilvl 0, bucket shield)
UPDATE `item_weapon` SET dmg=14, delay=224 WHERE itemId=16517;

-- 16518  mythril_degen  (lvl 36, ilvl 0, bucket shield)
UPDATE `item_weapon` SET dmg=20, delay=224 WHERE itemId=16518;

-- 16519  schlaeger  (lvl 55, ilvl 0, bucket shield)
UPDATE `item_weapon` SET dmg=32, delay=247 WHERE itemId=16519;

-- 16524  fleuret  (lvl 30, ilvl 0, bucket shield)
UPDATE `item_weapon` SET dmg=18, delay=221 WHERE itemId=16524;

-- 16526  schwert  (lvl 66, ilvl 0, bucket shield)
UPDATE `item_weapon` SET dmg=32, delay=221 WHERE itemId=16526;

-- 16530  xiphos  (lvl 7, ilvl 0, bucket shield)
UPDATE `item_weapon` SET dmg=8, delay=228 WHERE itemId=16530;

-- 16531  brass_xiphos  (lvl 13, ilvl 0, bucket shield)
UPDATE `item_weapon` SET dmg=12, delay=228 WHERE itemId=16531;

-- 16532  gladius  (lvl 27, ilvl 0, bucket shield)
UPDATE `item_weapon` SET dmg=17, delay=228 WHERE itemId=16532;

-- 16535  bronze_sword  (lvl 1, ilvl 0, bucket shield)
UPDATE `item_weapon` SET dmg=6, delay=231 WHERE itemId=16535;

-- 16536  iron_sword  (lvl 18, ilvl 0, bucket shield)
UPDATE `item_weapon` SET dmg=14, delay=231 WHERE itemId=16536;

-- 16537  mythril_sword  (lvl 36, ilvl 0, bucket shield)
UPDATE `item_weapon` SET dmg=21, delay=231 WHERE itemId=16537;

-- 16538  darksteel_sword  (lvl 51, ilvl 0, bucket shield)
UPDATE `item_weapon` SET dmg=31, delay=254 WHERE itemId=16538;

-- 16539  cermet_sword  (lvl 59, ilvl 0, bucket shield)
UPDATE `item_weapon` SET dmg=32, delay=220 WHERE itemId=16539;

-- 16545  broadsword  (lvl 30, ilvl 0, bucket shield)
UPDATE `item_weapon` SET dmg=19, delay=233 WHERE itemId=16545;

-- 16546  katzbalger  (lvl 62, ilvl 0, bucket shield)
UPDATE `item_weapon` SET dmg=34, delay=233 WHERE itemId=16546;

-- 16551  sapara  (lvl 7, ilvl 0, bucket shield)
UPDATE `item_weapon` SET dmg=9, delay=236 WHERE itemId=16551;

-- 16552  scimitar  (lvl 13, ilvl 0, bucket shield)
UPDATE `item_weapon` SET dmg=13, delay=236 WHERE itemId=16552;

-- 16553  tulwar  (lvl 36, ilvl 0, bucket shield)
UPDATE `item_weapon` SET dmg=23, delay=236 WHERE itemId=16553;

-- 16554  hanger  (lvl 57, ilvl 0, bucket shield)
UPDATE `item_weapon` SET dmg=34, delay=225 WHERE itemId=16554;

-- 16558  falchion  (lvl 44, ilvl 0, bucket shield)
UPDATE `item_weapon` SET dmg=28, delay=236 WHERE itemId=16558;

-- 16559  darksteel_falchion  (lvl 53, ilvl 0, bucket shield)
UPDATE `item_weapon` SET dmg=36, delay=260 WHERE itemId=16559;

-- 16560  cutlass  (lvl 62, ilvl 0, bucket shield)
UPDATE `item_weapon` SET dmg=37, delay=236 WHERE itemId=16560;

-- 16565  spatha  (lvl 9, ilvl 0, bucket shield)
UPDATE `item_weapon` SET dmg=11, delay=240 WHERE itemId=16565;

-- 16566  longsword  (lvl 18, ilvl 0, bucket shield)
UPDATE `item_weapon` SET dmg=16, delay=240 WHERE itemId=16566;

-- 16567  knights_sword  (lvl 47, ilvl 0, bucket shield)
UPDATE `item_weapon` SET dmg=31, delay=240 WHERE itemId=16567;

-- 16568  saber  (lvl 56, ilvl 0, bucket shield)
UPDATE `item_weapon` SET dmg=36, delay=240 WHERE itemId=16568;

-- 16569  gold_sword  (lvl 62, ilvl 0, bucket shield)
UPDATE `item_weapon` SET dmg=38, delay=240 WHERE itemId=16569;

-- 16572  bee_spatha  (lvl 11, ilvl 0, bucket shield)
UPDATE `item_weapon` SET dmg=13, delay=233 WHERE itemId=16572;

-- 16576  hunting_sword  (lvl 34, ilvl 0, bucket shield)
UPDATE `item_weapon` SET dmg=27, delay=264 WHERE itemId=16576;

-- 16577  bastard_sword  (lvl 60, ilvl 0, bucket shield)
UPDATE `item_weapon` SET dmg=43, delay=264 WHERE itemId=16577;

-- 16600  wax_sword  (lvl 1, ilvl 0, bucket shield)
UPDATE `item_weapon` SET dmg=6, delay=225 WHERE itemId=16600;

-- 16608  gladiator  (lvl 27, ilvl 0, bucket shield)
UPDATE `item_weapon` SET dmg=18, delay=222 WHERE itemId=16608;

-- 16612  saber_+1  (lvl 56, ilvl 0, bucket shield)
UPDATE `item_weapon` SET dmg=37, delay=233 WHERE itemId=16612;

-- 16614  knife_+1  (lvl 13, ilvl 0, bucket shield)
UPDATE `item_weapon` SET dmg=9, delay=189 WHERE itemId=16614;

-- 16615  falchion_+1  (lvl 44, ilvl 0, bucket shield)
UPDATE `item_weapon` SET dmg=29, delay=229 WHERE itemId=16615;

-- 16617  tuck_+1  (lvl 23, ilvl 0, bucket shield)
UPDATE `item_weapon` SET dmg=16, delay=220 WHERE itemId=16617;

-- 16618  mailbreaker_+1  (lvl 60, ilvl 0, bucket shield)
UPDATE `item_weapon` SET dmg=31, delay=220 WHERE itemId=16618;

-- 16623  bronze_sword_+1  (lvl 1, ilvl 0, bucket shield)
UPDATE `item_weapon` SET dmg=7, delay=225 WHERE itemId=16623;

-- 16624  xiphos_+1  (lvl 7, ilvl 0, bucket shield)
UPDATE `item_weapon` SET dmg=9, delay=222 WHERE itemId=16624;

-- 16625  scimitar_+1  (lvl 13, ilvl 0, bucket shield)
UPDATE `item_weapon` SET dmg=14, delay=230 WHERE itemId=16625;

-- 16626  iron_sword_+1  (lvl 18, ilvl 0, bucket shield)
UPDATE `item_weapon` SET dmg=15, delay=225 WHERE itemId=16626;

-- 16627  spatha_+1  (lvl 9, ilvl 0, bucket shield)
UPDATE `item_weapon` SET dmg=12, delay=233 WHERE itemId=16627;

-- 16628  longsword_+1  (lvl 18, ilvl 0, bucket shield)
UPDATE `item_weapon` SET dmg=17, delay=233 WHERE itemId=16628;

-- 16632  bilbo_+1  (lvl 13, ilvl 0, bucket shield)
UPDATE `item_weapon` SET dmg=12, delay=220 WHERE itemId=16632;

-- 16633  degen_+1  (lvl 20, ilvl 0, bucket shield)
UPDATE `item_weapon` SET dmg=15, delay=218 WHERE itemId=16633;

-- 16634  broadsword_+1  (lvl 30, ilvl 0, bucket shield)
UPDATE `item_weapon` SET dmg=20, delay=227 WHERE itemId=16634;

-- 16635  mythril_sword_+1  (lvl 36, ilvl 0, bucket shield)
UPDATE `item_weapon` SET dmg=22, delay=225 WHERE itemId=16635;

-- 16636  tulwar_+1  (lvl 36, ilvl 0, bucket shield)
UPDATE `item_weapon` SET dmg=24, delay=230 WHERE itemId=16636;

-- 16640  bronze_axe  (lvl 1, ilvl 0, bucket shield)
UPDATE `item_weapon` SET dmg=8, delay=276 WHERE itemId=16640;

-- 16641  brass_axe  (lvl 8, ilvl 0, bucket shield)
UPDATE `item_weapon` SET dmg=12, delay=276 WHERE itemId=16641;

-- 16642  bone_axe  (lvl 13, ilvl 0, bucket shield)
UPDATE `item_weapon` SET dmg=16, delay=276 WHERE itemId=16642;

-- 16643  battleaxe  (lvl 20, ilvl 0, bucket shield)
UPDATE `item_weapon` SET dmg=20, delay=276 WHERE itemId=16643;

-- 16644  mythril_axe  (lvl 37, ilvl 0, bucket shield)
UPDATE `item_weapon` SET dmg=29, delay=276 WHERE itemId=16644;

-- 16645  darksteel_axe  (lvl 56, ilvl 0, bucket shield)
UPDATE `item_weapon` SET dmg=42, delay=289 WHERE itemId=16645;

-- 16646  bronze_axe_+1  (lvl 1, ilvl 0, bucket shield)
UPDATE `item_weapon` SET dmg=9, delay=268 WHERE itemId=16646;

-- 16649  bone_pick  (lvl 16, ilvl 0, bucket shield)
UPDATE `item_weapon` SET dmg=18, delay=312 WHERE itemId=16649;

-- 16650  war_pick  (lvl 31, ilvl 0, bucket shield)
UPDATE `item_weapon` SET dmg=26, delay=312 WHERE itemId=16650;

-- 16651  mythril_pick  (lvl 50, ilvl 0, bucket shield)
UPDATE `item_weapon` SET dmg=39, delay=312 WHERE itemId=16651;

-- 16652  darksteel_pick  (lvl 62, ilvl 0, bucket shield)
UPDATE `item_weapon` SET dmg=43, delay=312 WHERE itemId=16652;

-- 16657  tabar  (lvl 43, ilvl 0, bucket shield)
UPDATE `item_weapon` SET dmg=34, delay=288 WHERE itemId=16657;

-- 16658  darksteel_tabar  (lvl 65, ilvl 0, bucket shield)
UPDATE `item_weapon` SET dmg=45, delay=296 WHERE itemId=16658;

-- 16661  brass_axe_+1  (lvl 8, ilvl 0, bucket shield)
UPDATE `item_weapon` SET dmg=13, delay=268 WHERE itemId=16661;

-- 16663  battleaxe_+1  (lvl 20, ilvl 0, bucket shield)
UPDATE `item_weapon` SET dmg=21, delay=268 WHERE itemId=16663;

-- 16664  war_pick_+1  (lvl 31, ilvl 0, bucket shield)
UPDATE `item_weapon` SET dmg=27, delay=303 WHERE itemId=16664;

-- 16665  mythril_axe_+1  (lvl 37, ilvl 0, bucket shield)
UPDATE `item_weapon` SET dmg=30, delay=268 WHERE itemId=16665;

-- 16666  bone_axe_+1  (lvl 13, ilvl 0, bucket shield)
UPDATE `item_weapon` SET dmg=17, delay=268 WHERE itemId=16666;

-- 16668  bone_pick_+1  (lvl 16, ilvl 0, bucket shield)
UPDATE `item_weapon` SET dmg=19, delay=303 WHERE itemId=16668;

-- 16670  mythril_pick_+1  (lvl 50, ilvl 0, bucket shield)
UPDATE `item_weapon` SET dmg=40, delay=303 WHERE itemId=16670;

-- 16671  tabar_+1  (lvl 43, ilvl 0, bucket shield)
UPDATE `item_weapon` SET dmg=35, delay=280 WHERE itemId=16671;

-- 16677  darksteel_axe_+1  (lvl 56, ilvl 0, bucket shield)
UPDATE `item_weapon` SET dmg=43, delay=281 WHERE itemId=16677;

-- 16682  darksteel_pick_+1  (lvl 62, ilvl 0, bucket shield)
UPDATE `item_weapon` SET dmg=44, delay=303 WHERE itemId=16682;

-- 16683  darksteel_tabar_+1  (lvl 65, ilvl 0, bucket shield)
UPDATE `item_weapon` SET dmg=46, delay=288 WHERE itemId=16683;

-- 16736  dagger_+1  (lvl 12, ilvl 0, bucket shield)
UPDATE `item_weapon` SET dmg=8, delay=178 WHERE itemId=16736;

-- 16737  baselard_+1  (lvl 18, ilvl 0, bucket shield)
UPDATE `item_weapon` SET dmg=9, delay=181 WHERE itemId=16737;

-- 16738  mythril_dagger_+1  (lvl 23, ilvl 0, bucket shield)
UPDATE `item_weapon` SET dmg=11, delay=178 WHERE itemId=16738;

-- 16739  mythril_knife_+1  (lvl 31, ilvl 0, bucket shield)
UPDATE `item_weapon` SET dmg=13, delay=190 WHERE itemId=16739;

-- 16740  brass_dagger_+1  (lvl 9, ilvl 0, bucket shield)
UPDATE `item_weapon` SET dmg=6, delay=178 WHERE itemId=16740;

-- 16748  kukri_+1  (lvl 20, ilvl 0, bucket shield)
UPDATE `item_weapon` SET dmg=11, delay=194 WHERE itemId=16748;

-- 16749  kris_+1  (lvl 27, ilvl 0, bucket shield)
UPDATE `item_weapon` SET dmg=12, delay=187 WHERE itemId=16749;

-- 16750  mythril_kukri_+1  (lvl 34, ilvl 0, bucket shield)
UPDATE `item_weapon` SET dmg=15, delay=194 WHERE itemId=16750;

-- 16751  darksteel_knife_+1  (lvl 53, ilvl 0, bucket shield)
UPDATE `item_weapon` SET dmg=20, delay=190 WHERE itemId=16751;

-- 16752  fine_baselard  (lvl 36, ilvl 0, bucket shield)
UPDATE `item_weapon` SET dmg=14, delay=181 WHERE itemId=16752;

-- 16758  darksteel_baselard_+1  (lvl 55, ilvl 0, bucket shield)
UPDATE `item_weapon` SET dmg=21, delay=190 WHERE itemId=16758;

-- 16759  darksteel_kris  (lvl 57, ilvl 0, bucket shield)
UPDATE `item_weapon` SET dmg=22, delay=202 WHERE itemId=16759;

-- 16760  darksteel_kris_+1  (lvl 57, ilvl 0, bucket shield)
UPDATE `item_weapon` SET dmg=23, delay=196 WHERE itemId=16760;

-- 16763  darksteel_kukri_+1  (lvl 59, ilvl 0, bucket shield)
UPDATE `item_weapon` SET dmg=23, delay=194 WHERE itemId=16763;

-- 16800  knights_sword_+1  (lvl 47, ilvl 0, bucket shield)
UPDATE `item_weapon` SET dmg=32, delay=233 WHERE itemId=16800;

-- 16801  sapara_+1  (lvl 7, ilvl 0, bucket shield)
UPDATE `item_weapon` SET dmg=10, delay=230 WHERE itemId=16801;

-- 16802  brass_xiphos_+1  (lvl 13, ilvl 0, bucket shield)
UPDATE `item_weapon` SET dmg=13, delay=222 WHERE itemId=16802;

-- 16803  fleuret_+1  (lvl 30, ilvl 0, bucket shield)
UPDATE `item_weapon` SET dmg=19, delay=215 WHERE itemId=16803;

-- 16811  darksteel_sword_+1  (lvl 51, ilvl 0, bucket shield)
UPDATE `item_weapon` SET dmg=32, delay=242 WHERE itemId=16811;

-- 16812  war_sword  (lvl 34, ilvl 0, bucket shield)
UPDATE `item_weapon` SET dmg=28, delay=257 WHERE itemId=16812;

-- 16813  schlaeger_+1  (lvl 55, ilvl 0, bucket shield)
UPDATE `item_weapon` SET dmg=33, delay=235 WHERE itemId=16813;

-- 16814  crescent_sword  (lvl 53, ilvl 0, bucket shield)
UPDATE `item_weapon` SET dmg=37, delay=248 WHERE itemId=16814;

-- 16815  mythril_degen_+1  (lvl 36, ilvl 0, bucket shield)
UPDATE `item_weapon` SET dmg=21, delay=218 WHERE itemId=16815;

-- 16825  cermet_sword_+1  (lvl 59, ilvl 0, bucket shield)
UPDATE `item_weapon` SET dmg=33, delay=213 WHERE itemId=16825;

-- 16828  bastard_sword_+1  (lvl 60, ilvl 0, bucket shield)
UPDATE `item_weapon` SET dmg=44, delay=258 WHERE itemId=16828;

-- 16896  kunai  (lvl 1, ilvl 0, bucket shield)
UPDATE `item_weapon` SET dmg=4, delay=190 WHERE itemId=16896;

-- 16900  wakizashi  (lvl 7, ilvl 0, bucket shield)
UPDATE `item_weapon` SET dmg=8, delay=227 WHERE itemId=16900;

-- 16901  kodachi  (lvl 32, ilvl 0, bucket shield)
UPDATE `item_weapon` SET dmg=19, delay=227 WHERE itemId=16901;

-- 16902  sakurafubuki  (lvl 43, ilvl 0, bucket shield)
UPDATE `item_weapon` SET dmg=24, delay=227 WHERE itemId=16902;

-- 16903  kabutowari  (lvl 61, ilvl 0, bucket shield)
UPDATE `item_weapon` SET dmg=30, delay=227 WHERE itemId=16903;

-- 16914  kunai_+1  (lvl 1, ilvl 0, bucket shield)
UPDATE `item_weapon` SET dmg=5, delay=185 WHERE itemId=16914;

-- 16915  hien  (lvl 47, ilvl 0, bucket shield)
UPDATE `item_weapon` SET dmg=21, delay=190 WHERE itemId=16915;

-- 16916  hien_+1  (lvl 47, ilvl 0, bucket shield)
UPDATE `item_weapon` SET dmg=22, delay=185 WHERE itemId=16916;

-- 16918  wakizashi_+1  (lvl 7, ilvl 0, bucket shield)
UPDATE `item_weapon` SET dmg=9, delay=222 WHERE itemId=16918;

-- 16919  shinobi-gatana  (lvl 13, ilvl 0, bucket shield)
UPDATE `item_weapon` SET dmg=11, delay=227 WHERE itemId=16919;

-- 16920  shinobi-gatana_+1  (lvl 13, ilvl 0, bucket shield)
UPDATE `item_weapon` SET dmg=12, delay=222 WHERE itemId=16920;

-- 16921  kodachi_+1  (lvl 32, ilvl 0, bucket shield)
UPDATE `item_weapon` SET dmg=20, delay=222 WHERE itemId=16921;

-- 16922  sakurafubuki_+1  (lvl 43, ilvl 0, bucket shield)
UPDATE `item_weapon` SET dmg=25, delay=222 WHERE itemId=16922;

-- 16923  kabutowari_+1  (lvl 61, ilvl 0, bucket shield)
UPDATE `item_weapon` SET dmg=31, delay=222 WHERE itemId=16923;

-- 17024  ash_club  (lvl 1, ilvl 0, bucket shield)
UPDATE `item_weapon` SET dmg=4, delay=264 WHERE itemId=17024;

-- 17025  chestnut_club  (lvl 16, ilvl 0, bucket shield)
UPDATE `item_weapon` SET dmg=9, delay=264 WHERE itemId=17025;

-- 17026  bone_cudgel  (lvl 27, ilvl 0, bucket shield)
UPDATE `item_weapon` SET dmg=12, delay=264 WHERE itemId=17026;

-- 17027  oak_cudgel  (lvl 36, ilvl 0, bucket shield)
UPDATE `item_weapon` SET dmg=15, delay=264 WHERE itemId=17027;

-- 17030  great_club  (lvl 39, ilvl 0, bucket shield)
UPDATE `item_weapon` SET dmg=19, delay=267 WHERE itemId=17030;

-- 17033  bone_cudgel_+1  (lvl 27, ilvl 0, bucket shield)
UPDATE `item_weapon` SET dmg=13, delay=257 WHERE itemId=17033;

-- 17034  bronze_mace  (lvl 4, ilvl 0, bucket shield)
UPDATE `item_weapon` SET dmg=6, delay=300 WHERE itemId=17034;

-- 17035  mace  (lvl 19, ilvl 0, bucket shield)
UPDATE `item_weapon` SET dmg=14, delay=300 WHERE itemId=17035;

-- 17036  mythril_mace  (lvl 35, ilvl 0, bucket shield)
UPDATE `item_weapon` SET dmg=20, delay=300 WHERE itemId=17036;

-- 17037  darksteel_mace  (lvl 57, ilvl 0, bucket shield)
UPDATE `item_weapon` SET dmg=32, delay=315 WHERE itemId=17037;

-- 17040  warp_cudgel  (lvl 36, ilvl 0, bucket shield)
UPDATE `item_weapon` SET dmg=15, delay=264 WHERE itemId=17040;

-- 17042  bronze_hammer  (lvl 5, ilvl 0, bucket shield)
UPDATE `item_weapon` SET dmg=8, delay=324 WHERE itemId=17042;

-- 17043  brass_hammer  (lvl 12, ilvl 0, bucket shield)
UPDATE `item_weapon` SET dmg=13, delay=324 WHERE itemId=17043;

-- 17044  warhammer  (lvl 20, ilvl 0, bucket shield)
UPDATE `item_weapon` SET dmg=17, delay=324 WHERE itemId=17044;

-- 17045  maul  (lvl 31, ilvl 0, bucket shield)
UPDATE `item_weapon` SET dmg=22, delay=324 WHERE itemId=17045;

-- 17086  bronze_mace_+1  (lvl 4, ilvl 0, bucket shield)
UPDATE `item_weapon` SET dmg=7, delay=292 WHERE itemId=17086;

-- 17115  warhammer_+1  (lvl 20, ilvl 0, bucket shield)
UPDATE `item_weapon` SET dmg=18, delay=315 WHERE itemId=17115;

-- 17121  maul_+1  (lvl 31, ilvl 0, bucket shield)
UPDATE `item_weapon` SET dmg=23, delay=315 WHERE itemId=17121;

-- 17137  ash_club_+1  (lvl 1, ilvl 0, bucket shield)
UPDATE `item_weapon` SET dmg=5, delay=257 WHERE itemId=17137;

-- 17139  solid_club  (lvl 16, ilvl 0, bucket shield)
UPDATE `item_weapon` SET dmg=10, delay=257 WHERE itemId=17139;

-- 17142  oak_cudgel_+1  (lvl 36, ilvl 0, bucket shield)
UPDATE `item_weapon` SET dmg=16, delay=257 WHERE itemId=17142;

-- 17144  bronze_hammer_+1  (lvl 5, ilvl 0, bucket shield)
UPDATE `item_weapon` SET dmg=9, delay=315 WHERE itemId=17144;

-- 17145  mace_+1  (lvl 19, ilvl 0, bucket shield)
UPDATE `item_weapon` SET dmg=15, delay=291 WHERE itemId=17145;

-- 17147  mythril_mace_+1  (lvl 35, ilvl 0, bucket shield)
UPDATE `item_weapon` SET dmg=21, delay=291 WHERE itemId=17147;

-- 17149  brass_hammer_+1  (lvl 12, ilvl 0, bucket shield)
UPDATE `item_weapon` SET dmg=14, delay=315 WHERE itemId=17149;

-- 17408  great_club_+1  (lvl 39, ilvl 0, bucket shield)
UPDATE `item_weapon` SET dmg=20, delay=259 WHERE itemId=17408;

-- 17428  darksteel_mace_+1  (lvl 57, ilvl 0, bucket shield)
UPDATE `item_weapon` SET dmg=33, delay=306 WHERE itemId=17428;

-- 17601  demons_knife  (lvl 62, ilvl 0, bucket shield)
UPDATE `item_weapon` SET dmg=22, delay=211 WHERE itemId=17601;

-- 17602  demons_knife_+1  (lvl 62, ilvl 0, bucket shield)
UPDATE `item_weapon` SET dmg=23, delay=201 WHERE itemId=17602;

-- 17603  cermet_kukri_+1  (lvl 62, ilvl 0, bucket shield)
UPDATE `item_weapon` SET dmg=23, delay=188 WHERE itemId=17603;

-- 17609  cermet_knife_+1  (lvl 60, ilvl 0, bucket shield)
UPDATE `item_weapon` SET dmg=21, delay=180 WHERE itemId=17609;

-- 17634  wasp_fleuret  (lvl 61, ilvl 0, bucket shield)
UPDATE `item_weapon` SET dmg=35, delay=221 WHERE itemId=17634;

-- 17635  schwert_+1  (lvl 66, ilvl 0, bucket shield)
UPDATE `item_weapon` SET dmg=33, delay=215 WHERE itemId=17635;

-- 17638  katzbalger_+1  (lvl 62, ilvl 0, bucket shield)
UPDATE `item_weapon` SET dmg=35, delay=227 WHERE itemId=17638;

-- 17639  cutlass_+1  (lvl 62, ilvl 0, bucket shield)
UPDATE `item_weapon` SET dmg=38, delay=230 WHERE itemId=17639;

-- 17641  gold_sword_+1  (lvl 62, ilvl 0, bucket shield)
UPDATE `item_weapon` SET dmg=39, delay=233 WHERE itemId=17641;

-- 17642  hanger_+1  (lvl 57, ilvl 0, bucket shield)
UPDATE `item_weapon` SET dmg=35, delay=218 WHERE itemId=17642;

-- 17646  carnage_sword  (lvl 63, ilvl 0, bucket shield)
UPDATE `item_weapon` SET dmg=43, delay=264 WHERE itemId=17646;

-- 17683  sacred_degen  (lvl 45, ilvl 0, bucket shield)
UPDATE `item_weapon` SET dmg=24, delay=224 WHERE itemId=17683;

-- 17686  spark_bilbo  (lvl 13, ilvl 0, bucket shield)
UPDATE `item_weapon` SET dmg=11, delay=226 WHERE itemId=17686;

-- 17687  spark_bilbo_+1  (lvl 13, ilvl 0, bucket shield)
UPDATE `item_weapon` SET dmg=12, delay=220 WHERE itemId=17687;

-- 17688  spark_degen  (lvl 36, ilvl 0, bucket shield)
UPDATE `item_weapon` SET dmg=20, delay=224 WHERE itemId=17688;

-- 17689  spark_degen_+1  (lvl 36, ilvl 0, bucket shield)
UPDATE `item_weapon` SET dmg=21, delay=218 WHERE itemId=17689;

-- 17705  vulcan_degen  (lvl 40, ilvl 0, bucket shield)
UPDATE `item_weapon` SET dmg=22, delay=224 WHERE itemId=17705;

-- 17706  vulcan_blade  (lvl 47, ilvl 0, bucket shield)
UPDATE `item_weapon` SET dmg=30, delay=236 WHERE itemId=17706;

-- 17776  hibari  (lvl 24, ilvl 0, bucket shield)
UPDATE `item_weapon` SET dmg=13, delay=190 WHERE itemId=17776;

-- 17777  hibari_+1  (lvl 24, ilvl 0, bucket shield)
UPDATE `item_weapon` SET dmg=14, delay=185 WHERE itemId=17777;

-- 17778  muketsu  (lvl 54, ilvl 0, bucket shield)
UPDATE `item_weapon` SET dmg=26, delay=227 WHERE itemId=17778;

-- 17779  muketsu_+1  (lvl 54, ilvl 0, bucket shield)
UPDATE `item_weapon` SET dmg=27, delay=222 WHERE itemId=17779;

-- 17780  kyofu  (lvl 13, ilvl 0, bucket shield)
UPDATE `item_weapon` SET dmg=11, delay=227 WHERE itemId=17780;

-- 17781  kyofu_+1  (lvl 13, ilvl 0, bucket shield)
UPDATE `item_weapon` SET dmg=12, delay=222 WHERE itemId=17781;

-- 17782  reppu  (lvl 32, ilvl 0, bucket shield)
UPDATE `item_weapon` SET dmg=19, delay=227 WHERE itemId=17782;

-- 17783  reppu_+1  (lvl 32, ilvl 0, bucket shield)
UPDATE `item_weapon` SET dmg=20, delay=222 WHERE itemId=17783;

-- 17784  keppu  (lvl 54, ilvl 0, bucket shield)
UPDATE `item_weapon` SET dmg=26, delay=227 WHERE itemId=17784;

-- 17785  keppu_+1  (lvl 54, ilvl 0, bucket shield)
UPDATE `item_weapon` SET dmg=27, delay=222 WHERE itemId=17785;

-- 17942  tomahawk  (lvl 25, ilvl 0, bucket shield)
UPDATE `item_weapon` SET dmg=23, delay=340 WHERE itemId=17942;

-- 17943  tomahawk_+1  (lvl 25, ilvl 0, bucket shield)
UPDATE `item_weapon` SET dmg=24, delay=333 WHERE itemId=17943;

-- 17954  jolt_axe  (lvl 13, ilvl 0, bucket shield)
UPDATE `item_weapon` SET dmg=16, delay=276 WHERE itemId=17954;

-- 17955  plain_pick  (lvl 31, ilvl 0, bucket shield)
UPDATE `item_weapon` SET dmg=26, delay=312 WHERE itemId=17955;

-- 17957  navy_axe  (lvl 37, ilvl 0, bucket shield)
UPDATE `item_weapon` SET dmg=29, delay=276 WHERE itemId=17957;

-- 17984  spark_dagger  (lvl 12, ilvl 0, bucket shield)
UPDATE `item_weapon` SET dmg=7, delay=183 WHERE itemId=17984;

-- 17985  spark_dagger_+1  (lvl 12, ilvl 0, bucket shield)
UPDATE `item_weapon` SET dmg=8, delay=178 WHERE itemId=17985;

-- 17986  spark_baselard  (lvl 36, ilvl 0, bucket shield)
UPDATE `item_weapon` SET dmg=13, delay=186 WHERE itemId=17986;

-- 17987  spark_baselard_+1  (lvl 36, ilvl 0, bucket shield)
UPDATE `item_weapon` SET dmg=14, delay=181 WHERE itemId=17987;

-- 17988  spark_kris  (lvl 57, ilvl 0, bucket shield)
UPDATE `item_weapon` SET dmg=22, delay=202 WHERE itemId=17988;

-- 17989  spark_kris_+1  (lvl 57, ilvl 0, bucket shield)
UPDATE `item_weapon` SET dmg=23, delay=196 WHERE itemId=17989;

-- 18014  odorous_knife  (lvl 66, ilvl 0, bucket shield)
UPDATE `item_weapon` SET dmg=24, delay=200 WHERE itemId=18014;

-- 18016  odorous_knife_+1  (lvl 66, ilvl 0, bucket shield)
UPDATE `item_weapon` SET dmg=26, delay=190 WHERE itemId=18016;

-- 18029  piercing_dagger  (lvl 9, ilvl 0, bucket shield)
UPDATE `item_weapon` SET dmg=5, delay=183 WHERE itemId=18029;

-- 18391  sacred_mace  (lvl 43, ilvl 0, bucket shield)
UPDATE `item_weapon` SET dmg=24, delay=300 WHERE itemId=18391;

-- 18427  hanafubuki  (lvl 43, ilvl 0, bucket shield)
UPDATE `item_weapon` SET dmg=24, delay=227 WHERE itemId=18427;

-- 18868  lady_bell  (lvl 1, ilvl 0, bucket shield)
UPDATE `item_weapon` SET dmg=1, delay=216 WHERE itemId=18868;

-- 18869  lady_bell_+1  (lvl 1, ilvl 0, bucket shield)
UPDATE `item_weapon` SET dmg=2, delay=210 WHERE itemId=18869;

-- 20580  kustawi  (lvl 99, ilvl 119, bucket shield)
INSERT IGNORE INTO `item_mods` VALUES (20580, 78, 242);
INSERT IGNORE INTO `item_mods` VALUES (20580, 92, -4);
UPDATE `item_weapon` SET dmg=113, delay=195 WHERE itemId=20580;

-- 20581  kustawi_+1  (lvl 99, ilvl 119, bucket shield)
INSERT IGNORE INTO `item_mods` VALUES (20581, 78, 242);
INSERT IGNORE INTO `item_mods` VALUES (20581, 92, -5);
UPDATE `item_weapon` SET dmg=114, delay=189 WHERE itemId=20581;

-- 20592  sangoma  (lvl 99, ilvl 119, bucket shield)
INSERT IGNORE INTO `item_mods` VALUES (20592, 78, 242);
UPDATE `item_weapon` SET dmg=129, delay=200 WHERE itemId=20592;

-- 20600  nibiru_knife  (lvl 99, ilvl 119, bucket shield)
INSERT IGNORE INTO `item_mods` VALUES (20600, 9, 5);
INSERT IGNORE INTO `item_mods` VALUES (20600, 11, 5);
INSERT IGNORE INTO `item_mods` VALUES (20600, 14, 5);
INSERT IGNORE INTO `item_mods` VALUES (20600, 78, 242);
UPDATE `item_weapon` SET dmg=104, delay=183 WHERE itemId=20600;

-- 20603  ternion_dagger  (lvl 99, ilvl 119, bucket shield)
INSERT IGNORE INTO `item_mods` VALUES (20603, 2, 40);
INSERT IGNORE INTO `item_mods` VALUES (20603, 78, 228);
INSERT IGNORE INTO `item_mods` VALUES (20603, 11, 10);
UPDATE `item_weapon` SET dmg=99, delay=183 WHERE itemId=20603;

-- 20606  anathema_harpe  (lvl 99, ilvl 119, bucket shield)
INSERT IGNORE INTO `item_mods` VALUES (20606, 8, 7);
INSERT IGNORE INTO `item_mods` VALUES (20606, 78, 228);
UPDATE `item_weapon` SET dmg=113, delay=210 WHERE itemId=20606;

-- 20607  anathema_harpe_+1  (lvl 99, ilvl 119, bucket shield)
INSERT IGNORE INTO `item_mods` VALUES (20607, 8, 8);
INSERT IGNORE INTO `item_mods` VALUES (20607, 78, 228);
UPDATE `item_weapon` SET dmg=114, delay=201 WHERE itemId=20607;

-- 20633  camaraderie_dagger  (lvl 99, ilvl 109, bucket shield)
INSERT IGNORE INTO `item_mods` VALUES (20633, 78, 108);
UPDATE `item_weapon` SET dmg=75, delay=211 WHERE itemId=20633;

-- 20637  aphotic_kukri  (lvl 99, ilvl 113, bucket shield)
INSERT IGNORE INTO `item_mods` VALUES (20637, 8, 6);
INSERT IGNORE INTO `item_mods` VALUES (20637, 78, 162);
UPDATE `item_weapon` SET dmg=91, delay=200 WHERE itemId=20637;

-- 20679  tanmogayi  (lvl 99, ilvl 119, bucket shield)
INSERT IGNORE INTO `item_mods` VALUES (20679, 2, 50);
INSERT IGNORE INTO `item_mods` VALUES (20679, 4, 50);
INSERT IGNORE INTO `item_mods` VALUES (20679, 78, 242);
UPDATE `item_weapon` SET dmg=176, delay=288 WHERE itemId=20679;

-- 20680  tanmogayi_+1  (lvl 99, ilvl 119, bucket shield)
INSERT IGNORE INTO `item_mods` VALUES (20680, 2, 55);
INSERT IGNORE INTO `item_mods` VALUES (20680, 4, 55);
INSERT IGNORE INTO `item_mods` VALUES (20680, 78, 242);
UPDATE `item_weapon` SET dmg=177, delay=280 WHERE itemId=20680;

-- 20681  flyssa  (lvl 99, ilvl 119, bucket shield)
INSERT IGNORE INTO `item_mods` VALUES (20681, 78, 242);
UPDATE `item_weapon` SET dmg=146, delay=240 WHERE itemId=20681;

-- 20682  flyssa_+1  (lvl 99, ilvl 119, bucket shield)
INSERT IGNORE INTO `item_mods` VALUES (20682, 78, 242);
UPDATE `item_weapon` SET dmg=147, delay=233 WHERE itemId=20682;

-- 20696  combuster  (lvl 99, ilvl 119, bucket shield)
INSERT IGNORE INTO `item_mods` VALUES (20696, 78, 228);
UPDATE `item_weapon` SET dmg=161, delay=277 WHERE itemId=20696;

-- 20697  combuster_+1  (lvl 99, ilvl 119, bucket shield)
INSERT IGNORE INTO `item_mods` VALUES (20697, 78, 228);
UPDATE `item_weapon` SET dmg=162, delay=270 WHERE itemId=20697;

-- 20703  deacon_saber  (lvl 99, ilvl 119, bucket shield)
INSERT IGNORE INTO `item_mods` VALUES (20703, 8, 15);
INSERT IGNORE INTO `item_mods` VALUES (20703, 11, 15);
INSERT IGNORE INTO `item_mods` VALUES (20703, 78, 242);
UPDATE `item_weapon` SET dmg=145, delay=240 WHERE itemId=20703;

-- 20704  deacon_sword  (lvl 99, ilvl 119, bucket shield)
INSERT IGNORE INTO `item_mods` VALUES (20704, 78, 242);
UPDATE `item_weapon` SET dmg=158, delay=264 WHERE itemId=20704;

-- 20708  demersal_degen  (lvl 99, ilvl 119, bucket shield)
INSERT IGNORE INTO `item_mods` VALUES (20708, 78, 242);
UPDATE `item_weapon` SET dmg=109, delay=224 WHERE itemId=20708;

-- 20709  demersal_degen_+1  (lvl 99, ilvl 119, bucket shield)
INSERT IGNORE INTO `item_mods` VALUES (20709, 78, 242);
UPDATE `item_weapon` SET dmg=110, delay=218 WHERE itemId=20709;

-- 20710  nibiru_blade  (lvl 99, ilvl 119, bucket shield)
INSERT IGNORE INTO `item_mods` VALUES (20710, 8, 5);
INSERT IGNORE INTO `item_mods` VALUES (20710, 9, 5);
INSERT IGNORE INTO `item_mods` VALUES (20710, 78, 242);
UPDATE `item_weapon` SET dmg=133, delay=236 WHERE itemId=20710;

-- 20718  claidheamh_soluis  (lvl 99, ilvl 119, bucket shield)
INSERT IGNORE INTO `item_mods` VALUES (20718, 78, 242);
UPDATE `item_weapon` SET dmg=142, delay=270 WHERE itemId=20718;

-- 20725  iztaasu_+2  (lvl 99, ilvl 119, bucket shield)
INSERT IGNORE INTO `item_mods` VALUES (20725, 78, 242);
UPDATE `item_weapon` SET dmg=115, delay=236 WHERE itemId=20725;

-- 20727  tabahi_fleuret  (lvl 99, ilvl 109, bucket shield)
INSERT IGNORE INTO `item_mods` VALUES (20727, 11, 8);
INSERT IGNORE INTO `item_mods` VALUES (20727, 78, 102);
UPDATE `item_weapon` SET dmg=89, delay=221 WHERE itemId=20727;

-- 20729  vivifiante  (lvl 99, ilvl 109, bucket shield)
INSERT IGNORE INTO `item_mods` VALUES (20729, 78, 108);
UPDATE `item_weapon` SET dmg=90, delay=225 WHERE itemId=20729;

-- 20730  predatrice  (lvl 99, ilvl 109, bucket shield)
INSERT IGNORE INTO `item_mods` VALUES (20730, 4, 30);
INSERT IGNORE INTO `item_mods` VALUES (20730, 78, 108);
UPDATE `item_weapon` SET dmg=95, delay=236 WHERE itemId=20730;

-- 20731  xiutleato  (lvl 99, ilvl 115, bucket shield)
INSERT IGNORE INTO `item_mods` VALUES (20731, 8, 12);
INSERT IGNORE INTO `item_mods` VALUES (20731, 10, 12);
INSERT IGNORE INTO `item_mods` VALUES (20731, 78, 188);
UPDATE `item_weapon` SET dmg=116, delay=240 WHERE itemId=20731;

-- 20735  camaraderie_blade  (lvl 99, ilvl 109, bucket shield)
INSERT IGNORE INTO `item_mods` VALUES (20735, 78, 108);
UPDATE `item_weapon` SET dmg=86, delay=240 WHERE itemId=20735;

-- 20736  iztaasu_+1  (lvl 99, ilvl 113, bucket shield)
INSERT IGNORE INTO `item_mods` VALUES (20736, 78, 162);
UPDATE `item_weapon` SET dmg=97, delay=236 WHERE itemId=20736;

-- 20739  halachuinic_sword  (lvl 99, ilvl 113, bucket shield)
INSERT IGNORE INTO `item_mods` VALUES (20739, 78, 162);
UPDATE `item_weapon` SET dmg=104, delay=228 WHERE itemId=20739;

-- 20740  camatlatia  (lvl 99, ilvl 106, bucket shield)
INSERT IGNORE INTO `item_mods` VALUES (20740, 8, 8);
INSERT IGNORE INTO `item_mods` VALUES (20740, 78, 67);
UPDATE `item_weapon` SET dmg=76, delay=240 WHERE itemId=20740;

-- 20742  iztaasu  (lvl 99, ilvl 105, bucket shield)
INSERT IGNORE INTO `item_mods` VALUES (20742, 78, 54);
UPDATE `item_weapon` SET dmg=68, delay=236 WHERE itemId=20742;

-- 20798  deacon_tabar  (lvl 99, ilvl 119, bucket shield)
INSERT IGNORE INTO `item_mods` VALUES (20798, 2, 50);
INSERT IGNORE INTO `item_mods` VALUES (20798, 78, 242);
UPDATE `item_weapon` SET dmg=173, delay=288 WHERE itemId=20798;

-- 20799  mdomo_axe  (lvl 99, ilvl 119, bucket shield)
INSERT IGNORE INTO `item_mods` VALUES (20799, 78, 242);
INSERT IGNORE INTO `item_mods` VALUES (20799, 92, -3);
UPDATE `item_weapon` SET dmg=154, delay=276 WHERE itemId=20799;

-- 20800  mdomo_axe_+1  (lvl 99, ilvl 119, bucket shield)
INSERT IGNORE INTO `item_mods` VALUES (20800, 78, 242);
INSERT IGNORE INTO `item_mods` VALUES (20800, 92, -3);
UPDATE `item_weapon` SET dmg=155, delay=268 WHERE itemId=20800;

-- 20801  nibiru_tabar  (lvl 99, ilvl 119, bucket shield)
INSERT IGNORE INTO `item_mods` VALUES (20801, 8, 5);
INSERT IGNORE INTO `item_mods` VALUES (20801, 10, 5);
INSERT IGNORE INTO `item_mods` VALUES (20801, 78, 242);
INSERT IGNORE INTO `item_mods` VALUES (20801, 92, 5);
UPDATE `item_weapon` SET dmg=156, delay=276 WHERE itemId=20801;

-- 20804  perun  (lvl 99, ilvl 119, bucket shield)
INSERT IGNORE INTO `item_mods` VALUES (20804, 11, 7);
INSERT IGNORE INTO `item_mods` VALUES (20804, 78, 242);
INSERT IGNORE INTO `item_mods` VALUES (20804, 92, -3);
UPDATE `item_weapon` SET dmg=156, delay=288 WHERE itemId=20804;

-- 20806  buramgh  (lvl 99, ilvl 119, bucket shield)
INSERT IGNORE INTO `item_mods` VALUES (20806, 78, 242);
INSERT IGNORE INTO `item_mods` VALUES (20806, 14, 1);
UPDATE `item_weapon` SET dmg=156, delay=288 WHERE itemId=20806;

-- 20807  buramgh_+1  (lvl 99, ilvl 119, bucket shield)
INSERT IGNORE INTO `item_mods` VALUES (20807, 78, 242);
INSERT IGNORE INTO `item_mods` VALUES (20807, 14, 1);
UPDATE `item_weapon` SET dmg=157, delay=280 WHERE itemId=20807;

-- 20809  kumbhakarna  (lvl 99, ilvl 119, bucket shield)
INSERT IGNORE INTO `item_mods` VALUES (20809, 78, 242);
UPDATE `item_weapon` SET dmg=169, delay=322 WHERE itemId=20809;

-- 20814  budliqa  (lvl 99, ilvl 117, bucket shield)
INSERT IGNORE INTO `item_mods` VALUES (20814, 8, 7);
INSERT IGNORE INTO `item_mods` VALUES (20814, 78, 215);
UPDATE `item_weapon` SET dmg=160, delay=312 WHERE itemId=20814;

-- 20815  budliqa_+1  (lvl 99, ilvl 118, bucket shield)
INSERT IGNORE INTO `item_mods` VALUES (20815, 8, 8);
INSERT IGNORE INTO `item_mods` VALUES (20815, 78, 228);
UPDATE `item_weapon` SET dmg=161, delay=303 WHERE itemId=20815;

-- 20816  faizzeer_+2  (lvl 99, ilvl 119, bucket shield)
INSERT IGNORE INTO `item_mods` VALUES (20816, 78, 242);
UPDATE `item_weapon` SET dmg=141, delay=288 WHERE itemId=20816;

-- 20820  hatxiik  (lvl 99, ilvl 115, bucket shield)
INSERT IGNORE INTO `item_mods` VALUES (20820, 8, 12);
INSERT IGNORE INTO `item_mods` VALUES (20820, 10, 12);
INSERT IGNORE INTO `item_mods` VALUES (20820, 78, 188);
UPDATE `item_weapon` SET dmg=140, delay=288 WHERE itemId=20820;

-- 20823  camaraderie_axe  (lvl 99, ilvl 109, bucket shield)
INSERT IGNORE INTO `item_mods` VALUES (20823, 78, 108);
UPDATE `item_weapon` SET dmg=99, delay=276 WHERE itemId=20823;

-- 20824  faizzeer_+1  (lvl 99, ilvl 113, bucket shield)
INSERT IGNORE INTO `item_mods` VALUES (20824, 78, 162);
UPDATE `item_weapon` SET dmg=119, delay=288 WHERE itemId=20824;

-- 20826  hunahpu  (lvl 99, ilvl 115, bucket shield)
INSERT IGNORE INTO `item_mods` VALUES (20826, 8, 12);
INSERT IGNORE INTO `item_mods` VALUES (20826, 9, 12);
INSERT IGNORE INTO `item_mods` VALUES (20826, 78, 188);
INSERT IGNORE INTO `item_mods` VALUES (20826, 384, 30);
UPDATE `item_weapon` SET dmg=140, delay=288 WHERE itemId=20826;

-- 20828  brethren_axe  (lvl 99, ilvl 113, bucket shield)
INSERT IGNORE INTO `item_mods` VALUES (20828, 78, 162);
INSERT IGNORE INTO `item_mods` VALUES (20828, 92, -4);
UPDATE `item_weapon` SET dmg=132, delay=288 WHERE itemId=20828;

-- 20829  icoyoca  (lvl 99, ilvl 106, bucket shield)
INSERT IGNORE INTO `item_mods` VALUES (20829, 8, 8);
INSERT IGNORE INTO `item_mods` VALUES (20829, 78, 67);
UPDATE `item_weapon` SET dmg=92, delay=288 WHERE itemId=20829;

-- 20833  faizzeer  (lvl 99, ilvl 105, bucket shield)
INSERT IGNORE INTO `item_mods` VALUES (20833, 78, 54);
UPDATE `item_weapon` SET dmg=81, delay=288 WHERE itemId=20833;

-- 20980  raicho  (lvl 99, ilvl 119, bucket shield)
INSERT IGNORE INTO `item_mods` VALUES (20980, 8, 13);
INSERT IGNORE INTO `item_mods` VALUES (20980, 11, 13);
INSERT IGNORE INTO `item_mods` VALUES (20980, 78, 242);
UPDATE `item_weapon` SET dmg=127, delay=227 WHERE itemId=20980;

-- 20981  raicho_+1  (lvl 99, ilvl 119, bucket shield)
INSERT IGNORE INTO `item_mods` VALUES (20981, 8, 14);
INSERT IGNORE INTO `item_mods` VALUES (20981, 11, 14);
INSERT IGNORE INTO `item_mods` VALUES (20981, 78, 242);
UPDATE `item_weapon` SET dmg=128, delay=222 WHERE itemId=20981;

-- 20983  mijin  (lvl 99, ilvl 119, bucket shield)
INSERT IGNORE INTO `item_mods` VALUES (20983, 8, 5);
INSERT IGNORE INTO `item_mods` VALUES (20983, 9, 5);
INSERT IGNORE INTO `item_mods` VALUES (20983, 78, 228);
UPDATE `item_weapon` SET dmg=107, delay=190 WHERE itemId=20983;

-- 20987  tancho  (lvl 99, ilvl 119, bucket shield)
INSERT IGNORE INTO `item_mods` VALUES (20987, 9, 9);
INSERT IGNORE INTO `item_mods` VALUES (20987, 11, 9);
INSERT IGNORE INTO `item_mods` VALUES (20987, 78, 242);
UPDATE `item_weapon` SET dmg=125, delay=232 WHERE itemId=20987;

-- 20988  tancho_+1  (lvl 99, ilvl 119, bucket shield)
INSERT IGNORE INTO `item_mods` VALUES (20988, 9, 10);
INSERT IGNORE INTO `item_mods` VALUES (20988, 11, 10);
INSERT IGNORE INTO `item_mods` VALUES (20988, 78, 242);
UPDATE `item_weapon` SET dmg=126, delay=227 WHERE itemId=20988;

-- 20992  taikogane  (lvl 99, ilvl 115, bucket shield)
INSERT IGNORE INTO `item_mods` VALUES (20992, 9, 12);
INSERT IGNORE INTO `item_mods` VALUES (20992, 11, 12);
INSERT IGNORE INTO `item_mods` VALUES (20992, 78, 188);
UPDATE `item_weapon` SET dmg=110, delay=227 WHERE itemId=20992;

-- 20999  habukatana  (lvl 99, ilvl 109, bucket shield)
INSERT IGNORE INTO `item_mods` VALUES (20999, 78, 108);
UPDATE `item_weapon` SET dmg=88, delay=227 WHERE itemId=20999;

-- 21000  magorokuhocho  (lvl 99, ilvl 109, bucket shield)
INSERT IGNORE INTO `item_mods` VALUES (21000, 9, 8);
INSERT IGNORE INTO `item_mods` VALUES (21000, 11, 8);
INSERT IGNORE INTO `item_mods` VALUES (21000, 78, 108);
UPDATE `item_weapon` SET dmg=101, delay=227 WHERE itemId=21000;

-- 21003  camaraderie_katana  (lvl 99, ilvl 109, bucket shield)
INSERT IGNORE INTO `item_mods` VALUES (21003, 78, 108);
UPDATE `item_weapon` SET dmg=81, delay=227 WHERE itemId=21003;

-- 21005  kiji  (lvl 99, ilvl 113, bucket shield)
INSERT IGNORE INTO `item_mods` VALUES (21005, 78, 153);
UPDATE `item_weapon` SET dmg=87, delay=190 WHERE itemId=21005;

-- 21008  kotekirigo  (lvl 99, ilvl 100, bucket shield)
UPDATE `item_weapon` SET dmg=63, delay=227 WHERE itemId=21008;

-- 21011  enju  (lvl 99, ilvl 100, bucket shield)
INSERT IGNORE INTO `item_mods` VALUES (21011, 8, 6);
INSERT IGNORE INTO `item_mods` VALUES (21011, 9, 5);
UPDATE `item_weapon` SET dmg=55, delay=227 WHERE itemId=21011;

-- 21012  enju_+1  (lvl 99, ilvl 101, bucket shield)
INSERT IGNORE INTO `item_mods` VALUES (21012, 8, 7);
INSERT IGNORE INTO `item_mods` VALUES (21012, 9, 6);
UPDATE `item_weapon` SET dmg=56, delay=222 WHERE itemId=21012;

-- 21013  kannakiri  (lvl 99, ilvl 105, bucket shield)
INSERT IGNORE INTO `item_mods` VALUES (21013, 78, 54);
UPDATE `item_weapon` SET dmg=58, delay=227 WHERE itemId=21013;

-- 21014  ichijintanto  (lvl 99, ilvl 106, bucket shield)
INSERT IGNORE INTO `item_mods` VALUES (21014, 78, 63);
UPDATE `item_weapon` SET dmg=68, delay=190 WHERE itemId=21014;

-- 21066  trial_wand  (lvl 99, ilvl 109, bucket shield)
INSERT IGNORE INTO `item_mods` VALUES (21066, 78, 108);
UPDATE `item_weapon` SET dmg=98, delay=280 WHERE itemId=21066;

-- 21073  izcalli  (lvl 99, ilvl 119, bucket shield)
INSERT IGNORE INTO `item_mods` VALUES (21073, 78, 242);
UPDATE `item_weapon` SET dmg=209, delay=324 WHERE itemId=21073;

-- 21075  septoptic  (lvl 99, ilvl 119, bucket shield)
INSERT IGNORE INTO `item_mods` VALUES (21075, 2, 80);
INSERT IGNORE INTO `item_mods` VALUES (21075, 4, 80);
INSERT IGNORE INTO `item_mods` VALUES (21075, 12, 6);
INSERT IGNORE INTO `item_mods` VALUES (21075, 13, 6);
INSERT IGNORE INTO `item_mods` VALUES (21075, 78, 242);
UPDATE `item_weapon` SET dmg=130, delay=217 WHERE itemId=21075;

-- 21076  septoptic_+1  (lvl 99, ilvl 119, bucket shield)
INSERT IGNORE INTO `item_mods` VALUES (21076, 2, 90);
INSERT IGNORE INTO `item_mods` VALUES (21076, 4, 90);
INSERT IGNORE INTO `item_mods` VALUES (21076, 12, 6);
INSERT IGNORE INTO `item_mods` VALUES (21076, 13, 6);
INSERT IGNORE INTO `item_mods` VALUES (21076, 78, 242);
UPDATE `item_weapon` SET dmg=131, delay=210 WHERE itemId=21076;

-- 21083  sucellus  (lvl 99, ilvl 119, bucket shield)
INSERT IGNORE INTO `item_mods` VALUES (21083, 12, 6);
INSERT IGNORE INTO `item_mods` VALUES (21083, 13, 6);
INSERT IGNORE INTO `item_mods` VALUES (21083, 78, 242);
UPDATE `item_weapon` SET dmg=165, delay=288 WHERE itemId=21083;

-- 21090  loxotic_mace  (lvl 99, ilvl 119, bucket shield)
INSERT IGNORE INTO `item_mods` VALUES (21090, 78, 242);
INSERT IGNORE INTO `item_mods` VALUES (21090, 9, 5);
UPDATE `item_weapon` SET dmg=189, delay=340 WHERE itemId=21090;

-- 21091  loxotic_mace_+1  (lvl 99, ilvl 119, bucket shield)
INSERT IGNORE INTO `item_mods` VALUES (21091, 78, 242);
INSERT IGNORE INTO `item_mods` VALUES (21091, 9, 5);
UPDATE `item_weapon` SET dmg=190, delay=334 WHERE itemId=21091;

-- 21092  nibiru_cudgel  (lvl 99, ilvl 119, bucket shield)
INSERT IGNORE INTO `item_mods` VALUES (21092, 12, 11);
INSERT IGNORE INTO `item_mods` VALUES (21092, 13, 11);
INSERT IGNORE INTO `item_mods` VALUES (21092, 78, 242);
UPDATE `item_weapon` SET dmg=123, delay=216 WHERE itemId=21092;

-- 21099  magesmasher  (lvl 99, ilvl 119, bucket shield)
INSERT IGNORE INTO `item_mods` VALUES (21099, 12, 6);
INSERT IGNORE INTO `item_mods` VALUES (21099, 13, 16);
INSERT IGNORE INTO `item_mods` VALUES (21099, 78, 242);
UPDATE `item_weapon` SET dmg=174, delay=324 WHERE itemId=21099;

-- 21100  magesmasher_+1  (lvl 99, ilvl 119, bucket shield)
INSERT IGNORE INTO `item_mods` VALUES (21100, 12, 6);
INSERT IGNORE INTO `item_mods` VALUES (21100, 13, 17);
INSERT IGNORE INTO `item_mods` VALUES (21100, 78, 242);
UPDATE `item_weapon` SET dmg=175, delay=315 WHERE itemId=21100;

-- 21105  nehushtan  (lvl 99, ilvl 119, bucket shield)
INSERT IGNORE INTO `item_mods` VALUES (21105, 12, 6);
INSERT IGNORE INTO `item_mods` VALUES (21105, 13, 6);
INSERT IGNORE INTO `item_mods` VALUES (21105, 78, 228);
UPDATE `item_weapon` SET dmg=184, delay=352 WHERE itemId=21105;

-- 21120  patriarch_cane  (lvl 99, ilvl 109, bucket shield)
INSERT IGNORE INTO `item_mods` VALUES (21120, 4, 45);
INSERT IGNORE INTO `item_mods` VALUES (21120, 12, 4);
INSERT IGNORE INTO `item_mods` VALUES (21120, 13, 4);
INSERT IGNORE INTO `item_mods` VALUES (21120, 78, 108);
UPDATE `item_weapon` SET dmg=116, delay=288 WHERE itemId=21120;

-- 21123  camaraderie_wand  (lvl 99, ilvl 109, bucket shield)
INSERT IGNORE INTO `item_mods` VALUES (21123, 12, 4);
INSERT IGNORE INTO `item_mods` VALUES (21123, 13, 4);
INSERT IGNORE INTO `item_mods` VALUES (21123, 78, 108);
UPDATE `item_weapon` SET dmg=95, delay=264 WHERE itemId=21123;

-- 21124  dowsers_wand  (lvl 99, ilvl 109, bucket shield)
INSERT IGNORE INTO `item_mods` VALUES (21124, 12, 14);
INSERT IGNORE INTO `item_mods` VALUES (21124, 13, 14);
INSERT IGNORE INTO `item_mods` VALUES (21124, 78, 108);
UPDATE `item_weapon` SET dmg=87, delay=216 WHERE itemId=21124;

-- 21129  sharur  (lvl 99, ilvl 117, bucket shield)
INSERT IGNORE INTO `item_mods` VALUES (21129, 4, 30);
INSERT IGNORE INTO `item_mods` VALUES (21129, 12, 6);
INSERT IGNORE INTO `item_mods` VALUES (21129, 13, 6);
INSERT IGNORE INTO `item_mods` VALUES (21129, 78, 203);
UPDATE `item_weapon` SET dmg=174, delay=340 WHERE itemId=21129;

-- 21130  sharur_+1  (lvl 99, ilvl 118, bucket shield)
INSERT IGNORE INTO `item_mods` VALUES (21130, 4, 35);
INSERT IGNORE INTO `item_mods` VALUES (21130, 12, 7);
INSERT IGNORE INTO `item_mods` VALUES (21130, 13, 7);
INSERT IGNORE INTO `item_mods` VALUES (21130, 78, 215);
UPDATE `item_weapon` SET dmg=175, delay=334 WHERE itemId=21130;

-- 21399  nibiru_harp  (lvl 99, ilvl 0, bucket range)
INSERT IGNORE INTO `item_mods` VALUES (21399, 14, 7);

-- 21411  balarama_grip  (lvl 99, ilvl 0, bucket shield)
INSERT IGNORE INTO `item_mods` VALUES (21411, 2, 50);
INSERT IGNORE INTO `item_mods` VALUES (21411, 78, 7);
INSERT IGNORE INTO `item_mods` VALUES (21411, 92, 3);

-- 21413  clemency_grip  (lvl 99, ilvl 0, bucket shield)
INSERT IGNORE INTO `item_mods` VALUES (21413, 4, 30);

-- 21415  forefathers_grip  (lvl 99, ilvl 0, bucket shield)
INSERT IGNORE INTO `item_mods` VALUES (21415, 2, 20);
INSERT IGNORE INTO `item_mods` VALUES (21415, 4, 20);

-- 21418  rigorous_grip  (lvl 99, ilvl 0, bucket shield)
INSERT IGNORE INTO `item_mods` VALUES (21418, 8, 3);

-- 21559  raetic_kris  (lvl 99, ilvl 119, bucket shield)
INSERT IGNORE INTO `item_mods` VALUES (21559, 2, 35);
INSERT IGNORE INTO `item_mods` VALUES (21559, 4, 25);
INSERT IGNORE INTO `item_mods` VALUES (21559, 78, 242);
UPDATE `item_weapon` SET dmg=128, delay=192 WHERE itemId=21559;

-- 21560  raetic_kris_+1  (lvl 99, ilvl 119, bucket shield)
INSERT IGNORE INTO `item_mods` VALUES (21560, 2, 40);
INSERT IGNORE INTO `item_mods` VALUES (21560, 4, 30);
INSERT IGNORE INTO `item_mods` VALUES (21560, 78, 242);
UPDATE `item_weapon` SET dmg=129, delay=187 WHERE itemId=21560;

-- 21612  raetic_blade  (lvl 99, ilvl 119, bucket shield)
INSERT IGNORE INTO `item_mods` VALUES (21612, 2, 35);
INSERT IGNORE INTO `item_mods` VALUES (21612, 4, 25);
INSERT IGNORE INTO `item_mods` VALUES (21612, 78, 242);
UPDATE `item_weapon` SET dmg=157, delay=236 WHERE itemId=21612;

-- 21613  raetic_blade_+1  (lvl 99, ilvl 119, bucket shield)
INSERT IGNORE INTO `item_mods` VALUES (21613, 2, 40);
INSERT IGNORE INTO `item_mods` VALUES (21613, 4, 30);
INSERT IGNORE INTO `item_mods` VALUES (21613, 78, 242);
UPDATE `item_weapon` SET dmg=158, delay=230 WHERE itemId=21613;

-- 21710  raetic_axe  (lvl 99, ilvl 119, bucket shield)
INSERT IGNORE INTO `item_mods` VALUES (21710, 2, 35);
INSERT IGNORE INTO `item_mods` VALUES (21710, 4, 25);
INSERT IGNORE INTO `item_mods` VALUES (21710, 78, 242);
UPDATE `item_weapon` SET dmg=184, delay=276 WHERE itemId=21710;

-- 21711  raetic_axe_+1  (lvl 99, ilvl 119, bucket shield)
INSERT IGNORE INTO `item_mods` VALUES (21711, 2, 40);
INSERT IGNORE INTO `item_mods` VALUES (21711, 4, 30);
INSERT IGNORE INTO `item_mods` VALUES (21711, 78, 242);
UPDATE `item_weapon` SET dmg=185, delay=268 WHERE itemId=21711;

-- 21747  freydis  (lvl 99, ilvl 119, bucket shield)
INSERT IGNORE INTO `item_mods` VALUES (21747, 78, 242);
INSERT IGNORE INTO `item_mods` VALUES (21747, 92, 6);
UPDATE `item_weapon` SET dmg=178, delay=276 WHERE itemId=21747;

-- 21748  habilitator  (lvl 99, ilvl 119, bucket shield)
INSERT IGNORE INTO `item_mods` VALUES (21748, 8, 17);
INSERT IGNORE INTO `item_mods` VALUES (21748, 9, 17);
INSERT IGNORE INTO `item_mods` VALUES (21748, 14, 17);
INSERT IGNORE INTO `item_mods` VALUES (21748, 78, 242);
UPDATE `item_weapon` SET dmg=168, delay=288 WHERE itemId=21748;

-- 21749  habilitator_+1  (lvl 99, ilvl 119, bucket shield)
INSERT IGNORE INTO `item_mods` VALUES (21749, 8, 18);
INSERT IGNORE INTO `item_mods` VALUES (21749, 9, 18);
INSERT IGNORE INTO `item_mods` VALUES (21749, 14, 18);
INSERT IGNORE INTO `item_mods` VALUES (21749, 78, 242);
UPDATE `item_weapon` SET dmg=169, delay=280 WHERE itemId=21749;

-- 21905  taka  (lvl 99, ilvl 119, bucket shield)
INSERT IGNORE INTO `item_mods` VALUES (21905, 11, 20);
INSERT IGNORE INTO `item_mods` VALUES (21905, 78, 228);
UPDATE `item_weapon` SET dmg=123, delay=190 WHERE itemId=21905;

-- 23790  adenium_masque  (lvl 1, ilvl 0, bucket armor)
INSERT IGNORE INTO `item_mods` VALUES (23790, 1, 1);

-- 25516  chasseurs_earring  (lvl 99, ilvl 0, bucket armor)
INSERT IGNORE INTO `item_mods` VALUES (25516, 92, -7);

-- 25517  chasseurs_earring_+1  (lvl 99, ilvl 0, bucket armor)
INSERT IGNORE INTO `item_mods` VALUES (25517, 92, -8);

-- 25518  chasseurs_earring_+2  (lvl 99, ilvl 0, bucket armor)
INSERT IGNORE INTO `item_mods` VALUES (25518, 92, -9);

-- 25601  blistering_sallet  (lvl 99, ilvl 119, bucket armor)
INSERT IGNORE INTO `item_mods` VALUES (25601, 1, 110);
INSERT IGNORE INTO `item_mods` VALUES (25601, 2, 38);
INSERT IGNORE INTO `item_mods` VALUES (25601, 8, 16);
INSERT IGNORE INTO `item_mods` VALUES (25601, 9, 16);
INSERT IGNORE INTO `item_mods` VALUES (25601, 10, 16);
INSERT IGNORE INTO `item_mods` VALUES (25601, 11, 16);
INSERT IGNORE INTO `item_mods` VALUES (25601, 12, 16);
INSERT IGNORE INTO `item_mods` VALUES (25601, 13, 16);
INSERT IGNORE INTO `item_mods` VALUES (25601, 14, 16);
INSERT IGNORE INTO `item_mods` VALUES (25601, 384, 80);

-- 25635  loess_barbuta  (lvl 99, ilvl 119, bucket armor)
INSERT IGNORE INTO `item_mods` VALUES (25635, 1, 120);
INSERT IGNORE INTO `item_mods` VALUES (25635, 2, 100);
INSERT IGNORE INTO `item_mods` VALUES (25635, 4, 100);
INSERT IGNORE INTO `item_mods` VALUES (25635, 8, 20);
INSERT IGNORE INTO `item_mods` VALUES (25635, 9, 20);
INSERT IGNORE INTO `item_mods` VALUES (25635, 10, 20);
INSERT IGNORE INTO `item_mods` VALUES (25635, 11, 20);
INSERT IGNORE INTO `item_mods` VALUES (25635, 12, 20);
INSERT IGNORE INTO `item_mods` VALUES (25635, 13, -10);
INSERT IGNORE INTO `item_mods` VALUES (25635, 14, -10);
INSERT IGNORE INTO `item_mods` VALUES (25635, 92, 9);

-- 25639  korrigan_masque  (lvl 1, ilvl 0, bucket armor)
INSERT IGNORE INTO `item_mods` VALUES (25639, 1, 1);

-- 25655  ipoca_beret  (lvl 99, ilvl 119, bucket armor)
INSERT IGNORE INTO `item_mods` VALUES (25655, 1, 99);
INSERT IGNORE INTO `item_mods` VALUES (25655, 2, 34);
INSERT IGNORE INTO `item_mods` VALUES (25655, 4, 38);
INSERT IGNORE INTO `item_mods` VALUES (25655, 8, 11);
INSERT IGNORE INTO `item_mods` VALUES (25655, 9, 14);
INSERT IGNORE INTO `item_mods` VALUES (25655, 10, 14);
INSERT IGNORE INTO `item_mods` VALUES (25655, 11, 14);
INSERT IGNORE INTO `item_mods` VALUES (25655, 12, 19);
INSERT IGNORE INTO `item_mods` VALUES (25655, 13, 19);
INSERT IGNORE INTO `item_mods` VALUES (25655, 14, 19);
INSERT IGNORE INTO `item_mods` VALUES (25655, 384, 60);
INSERT IGNORE INTO `item_mods` VALUES (25655, 92, -7);

-- 25656  ynglinga_sallet  (lvl 99, ilvl 119, bucket armor)
INSERT IGNORE INTO `item_mods` VALUES (25656, 1, 118);
INSERT IGNORE INTO `item_mods` VALUES (25656, 2, 43);
INSERT IGNORE INTO `item_mods` VALUES (25656, 8, 28);
INSERT IGNORE INTO `item_mods` VALUES (25656, 9, 21);
INSERT IGNORE INTO `item_mods` VALUES (25656, 10, 27);
INSERT IGNORE INTO `item_mods` VALUES (25656, 11, 19);
INSERT IGNORE INTO `item_mods` VALUES (25656, 12, 15);
INSERT IGNORE INTO `item_mods` VALUES (25656, 13, 15);
INSERT IGNORE INTO `item_mods` VALUES (25656, 14, 15);
INSERT IGNORE INTO `item_mods` VALUES (25656, 384, 70);

-- 25659  sulevias_mask  (lvl 99, ilvl 119, bucket armor)
INSERT IGNORE INTO `item_mods` VALUES (25659, 1, 113);
INSERT IGNORE INTO `item_mods` VALUES (25659, 2, 40);
INSERT IGNORE INTO `item_mods` VALUES (25659, 4, 40);
INSERT IGNORE INTO `item_mods` VALUES (25659, 8, 25);
INSERT IGNORE INTO `item_mods` VALUES (25659, 9, 11);
INSERT IGNORE INTO `item_mods` VALUES (25659, 10, 32);
INSERT IGNORE INTO `item_mods` VALUES (25659, 11, 12);
INSERT IGNORE INTO `item_mods` VALUES (25659, 12, 11);
INSERT IGNORE INTO `item_mods` VALUES (25659, 13, 14);
INSERT IGNORE INTO `item_mods` VALUES (25659, 14, 14);
INSERT IGNORE INTO `item_mods` VALUES (25659, 384, 30);

-- 25663  hizamaru_somen  (lvl 99, ilvl 119, bucket armor)
INSERT IGNORE INTO `item_mods` VALUES (25663, 1, 105);
INSERT IGNORE INTO `item_mods` VALUES (25663, 2, 60);
INSERT IGNORE INTO `item_mods` VALUES (25663, 8, 25);
INSERT IGNORE INTO `item_mods` VALUES (25663, 9, 21);
INSERT IGNORE INTO `item_mods` VALUES (25663, 10, 19);
INSERT IGNORE INTO `item_mods` VALUES (25663, 11, 16);
INSERT IGNORE INTO `item_mods` VALUES (25663, 12, 12);
INSERT IGNORE INTO `item_mods` VALUES (25663, 13, 10);
INSERT IGNORE INTO `item_mods` VALUES (25663, 14, 12);
INSERT IGNORE INTO `item_mods` VALUES (25663, 384, 60);

-- 25680  cohort_cloak  (lvl 99, ilvl 119, bucket armor)
INSERT IGNORE INTO `item_mods` VALUES (25680, 1, 217);
INSERT IGNORE INTO `item_mods` VALUES (25680, 2, 91);
INSERT IGNORE INTO `item_mods` VALUES (25680, 4, 91);
INSERT IGNORE INTO `item_mods` VALUES (25680, 8, 35);
INSERT IGNORE INTO `item_mods` VALUES (25680, 9, 35);
INSERT IGNORE INTO `item_mods` VALUES (25680, 10, 35);
INSERT IGNORE INTO `item_mods` VALUES (25680, 11, 35);
INSERT IGNORE INTO `item_mods` VALUES (25680, 12, 55);
INSERT IGNORE INTO `item_mods` VALUES (25680, 13, 55);
INSERT IGNORE INTO `item_mods` VALUES (25680, 14, 48);
INSERT IGNORE INTO `item_mods` VALUES (25680, 384, 90);

-- 25709  obviation_cuirass  (lvl 99, ilvl 119, bucket armor)
INSERT IGNORE INTO `item_mods` VALUES (25709, 1, 165);
INSERT IGNORE INTO `item_mods` VALUES (25709, 2, 66);
INSERT IGNORE INTO `item_mods` VALUES (25709, 4, 59);
INSERT IGNORE INTO `item_mods` VALUES (25709, 8, 29);
INSERT IGNORE INTO `item_mods` VALUES (25709, 9, 17);
INSERT IGNORE INTO `item_mods` VALUES (25709, 10, 32);
INSERT IGNORE INTO `item_mods` VALUES (25709, 11, 17);
INSERT IGNORE INTO `item_mods` VALUES (25709, 12, 16);
INSERT IGNORE INTO `item_mods` VALUES (25709, 13, 16);
INSERT IGNORE INTO `item_mods` VALUES (25709, 14, 16);
INSERT IGNORE INTO `item_mods` VALUES (25709, 384, 30);
INSERT IGNORE INTO `item_mods` VALUES (25709, 92, 1);

-- 25711  botulus_suit  (lvl 1, ilvl 0, bucket armor)
INSERT IGNORE INTO `item_mods` VALUES (25711, 1, 1);

-- 25715  korrigan_suit  (lvl 1, ilvl 0, bucket armor)
INSERT IGNORE INTO `item_mods` VALUES (25715, 1, 1);

-- 25721  vedic_coat  (lvl 99, ilvl 119, bucket armor)
INSERT IGNORE INTO `item_mods` VALUES (25721, 1, 125);
INSERT IGNORE INTO `item_mods` VALUES (25721, 2, 50);
INSERT IGNORE INTO `item_mods` VALUES (25721, 4, 67);
INSERT IGNORE INTO `item_mods` VALUES (25721, 8, 19);
INSERT IGNORE INTO `item_mods` VALUES (25721, 9, 19);
INSERT IGNORE INTO `item_mods` VALUES (25721, 10, 19);
INSERT IGNORE INTO `item_mods` VALUES (25721, 11, 19);
INSERT IGNORE INTO `item_mods` VALUES (25721, 12, 35);
INSERT IGNORE INTO `item_mods` VALUES (25721, 13, 28);
INSERT IGNORE INTO `item_mods` VALUES (25721, 14, 28);
INSERT IGNORE INTO `item_mods` VALUES (25721, 384, 30);
INSERT IGNORE INTO `item_mods` VALUES (25721, 92, -4);

-- 25730  nzingha_cuirass  (lvl 99, ilvl 119, bucket armor)
INSERT IGNORE INTO `item_mods` VALUES (25730, 1, 155);
INSERT IGNORE INTO `item_mods` VALUES (25730, 2, 66);
INSERT IGNORE INTO `item_mods` VALUES (25730, 8, 33);
INSERT IGNORE INTO `item_mods` VALUES (25730, 9, 24);
INSERT IGNORE INTO `item_mods` VALUES (25730, 10, 33);
INSERT IGNORE INTO `item_mods` VALUES (25730, 11, 19);
INSERT IGNORE INTO `item_mods` VALUES (25730, 12, 19);
INSERT IGNORE INTO `item_mods` VALUES (25730, 13, 19);
INSERT IGNORE INTO `item_mods` VALUES (25730, 14, 19);
INSERT IGNORE INTO `item_mods` VALUES (25730, 384, 30);
INSERT IGNORE INTO `item_mods` VALUES (25730, 371, 3);

-- 25731  sayadios_kaftan  (lvl 99, ilvl 119, bucket armor)
INSERT IGNORE INTO `item_mods` VALUES (25731, 1, 135);
INSERT IGNORE INTO `item_mods` VALUES (25731, 2, 57);
INSERT IGNORE INTO `item_mods` VALUES (25731, 4, 59);
INSERT IGNORE INTO `item_mods` VALUES (25731, 8, 25);
INSERT IGNORE INTO `item_mods` VALUES (25731, 9, 33);
INSERT IGNORE INTO `item_mods` VALUES (25731, 10, 23);
INSERT IGNORE INTO `item_mods` VALUES (25731, 11, 39);
INSERT IGNORE INTO `item_mods` VALUES (25731, 12, 19);
INSERT IGNORE INTO `item_mods` VALUES (25731, 13, 19);
INSERT IGNORE INTO `item_mods` VALUES (25731, 14, 19);
INSERT IGNORE INTO `item_mods` VALUES (25731, 384, 40);

-- 25732  tatenashi_haramaki  (lvl 99, ilvl 119, bucket armor)
INSERT IGNORE INTO `item_mods` VALUES (25732, 1, 136);
INSERT IGNORE INTO `item_mods` VALUES (25732, 2, 66);
INSERT IGNORE INTO `item_mods` VALUES (25732, 8, 28);
INSERT IGNORE INTO `item_mods` VALUES (25732, 9, 24);
INSERT IGNORE INTO `item_mods` VALUES (25732, 10, 28);
INSERT IGNORE INTO `item_mods` VALUES (25732, 11, 19);
INSERT IGNORE INTO `item_mods` VALUES (25732, 12, 19);
INSERT IGNORE INTO `item_mods` VALUES (25732, 13, 19);
INSERT IGNORE INTO `item_mods` VALUES (25732, 14, 19);
INSERT IGNORE INTO `item_mods` VALUES (25732, 384, 30);

-- 25745  sulevias_platemail  (lvl 99, ilvl 119, bucket armor)
INSERT IGNORE INTO `item_mods` VALUES (25745, 1, 143);
INSERT IGNORE INTO `item_mods` VALUES (25745, 2, 70);
INSERT IGNORE INTO `item_mods` VALUES (25745, 4, 70);
INSERT IGNORE INTO `item_mods` VALUES (25745, 8, 33);
INSERT IGNORE INTO `item_mods` VALUES (25745, 9, 16);
INSERT IGNORE INTO `item_mods` VALUES (25745, 10, 33);
INSERT IGNORE INTO `item_mods` VALUES (25745, 11, 16);
INSERT IGNORE INTO `item_mods` VALUES (25745, 12, 16);
INSERT IGNORE INTO `item_mods` VALUES (25745, 13, 19);
INSERT IGNORE INTO `item_mods` VALUES (25745, 14, 19);
INSERT IGNORE INTO `item_mods` VALUES (25745, 384, 10);

-- 25749  hizamaru_haramaki  (lvl 99, ilvl 119, bucket armor)
INSERT IGNORE INTO `item_mods` VALUES (25749, 1, 131);
INSERT IGNORE INTO `item_mods` VALUES (25749, 2, 100);
INSERT IGNORE INTO `item_mods` VALUES (25749, 8, 32);
INSERT IGNORE INTO `item_mods` VALUES (25749, 9, 28);
INSERT IGNORE INTO `item_mods` VALUES (25749, 10, 26);
INSERT IGNORE INTO `item_mods` VALUES (25749, 11, 20);
INSERT IGNORE INTO `item_mods` VALUES (25749, 12, 20);
INSERT IGNORE INTO `item_mods` VALUES (25749, 13, 17);
INSERT IGNORE INTO `item_mods` VALUES (25749, 14, 20);
INSERT IGNORE INTO `item_mods` VALUES (25749, 384, 40);

-- 25756  wyrmking_suit  (lvl 1, ilvl 0, bucket armor)
INSERT IGNORE INTO `item_mods` VALUES (25756, 1, 1);

-- 25760  mrigavyadha_gloves  (lvl 99, ilvl 119, bucket armor)
INSERT IGNORE INTO `item_mods` VALUES (25760, 1, 99);
INSERT IGNORE INTO `item_mods` VALUES (25760, 2, 22);
INSERT IGNORE INTO `item_mods` VALUES (25760, 8, 16);
INSERT IGNORE INTO `item_mods` VALUES (25760, 9, 34);
INSERT IGNORE INTO `item_mods` VALUES (25760, 10, 28);
INSERT IGNORE INTO `item_mods` VALUES (25760, 11, 15);
INSERT IGNORE INTO `item_mods` VALUES (25760, 12, 8);
INSERT IGNORE INTO `item_mods` VALUES (25760, 13, 29);
INSERT IGNORE INTO `item_mods` VALUES (25760, 14, 16);
INSERT IGNORE INTO `item_mods` VALUES (25760, 384, 50);

-- 25761  iktomi_dastanas  (lvl 99, ilvl 119, bucket armor)
INSERT IGNORE INTO `item_mods` VALUES (25761, 1, 103);
INSERT IGNORE INTO `item_mods` VALUES (25761, 2, 27);
INSERT IGNORE INTO `item_mods` VALUES (25761, 8, 8);
INSERT IGNORE INTO `item_mods` VALUES (25761, 9, 32);
INSERT IGNORE INTO `item_mods` VALUES (25761, 10, 32);
INSERT IGNORE INTO `item_mods` VALUES (25761, 11, 7);
INSERT IGNORE INTO `item_mods` VALUES (25761, 12, 6);
INSERT IGNORE INTO `item_mods` VALUES (25761, 13, 23);
INSERT IGNORE INTO `item_mods` VALUES (25761, 14, 16);
INSERT IGNORE INTO `item_mods` VALUES (25761, 384, 60);

-- 25800  sulevias_gauntlets  (lvl 99, ilvl 119, bucket armor)
INSERT IGNORE INTO `item_mods` VALUES (25800, 1, 101);
INSERT IGNORE INTO `item_mods` VALUES (25800, 2, 30);
INSERT IGNORE INTO `item_mods` VALUES (25800, 4, 30);
INSERT IGNORE INTO `item_mods` VALUES (25800, 8, 15);
INSERT IGNORE INTO `item_mods` VALUES (25800, 9, 26);
INSERT IGNORE INTO `item_mods` VALUES (25800, 10, 37);
INSERT IGNORE INTO `item_mods` VALUES (25800, 12, 6);
INSERT IGNORE INTO `item_mods` VALUES (25800, 13, 24);
INSERT IGNORE INTO `item_mods` VALUES (25800, 14, 19);
INSERT IGNORE INTO `item_mods` VALUES (25800, 384, 30);

-- 25804  hizamaru_kote  (lvl 99, ilvl 119, bucket armor)
INSERT IGNORE INTO `item_mods` VALUES (25804, 1, 96);
INSERT IGNORE INTO `item_mods` VALUES (25804, 2, 40);
INSERT IGNORE INTO `item_mods` VALUES (25804, 8, 12);
INSERT IGNORE INTO `item_mods` VALUES (25804, 9, 35);
INSERT IGNORE INTO `item_mods` VALUES (25804, 10, 30);
INSERT IGNORE INTO `item_mods` VALUES (25804, 11, 8);
INSERT IGNORE INTO `item_mods` VALUES (25804, 12, 7);
INSERT IGNORE INTO `item_mods` VALUES (25804, 13, 21);
INSERT IGNORE INTO `item_mods` VALUES (25804, 14, 17);
INSERT IGNORE INTO `item_mods` VALUES (25804, 384, 40);

-- 25824  regal_gauntlets  (lvl 99, ilvl 119, bucket armor)
INSERT IGNORE INTO `item_mods` VALUES (25824, 1, 126);
INSERT IGNORE INTO `item_mods` VALUES (25824, 2, 205);
INSERT IGNORE INTO `item_mods` VALUES (25824, 4, 29);
INSERT IGNORE INTO `item_mods` VALUES (25824, 8, 30);
INSERT IGNORE INTO `item_mods` VALUES (25824, 9, 30);
INSERT IGNORE INTO `item_mods` VALUES (25824, 10, 40);
INSERT IGNORE INTO `item_mods` VALUES (25824, 11, 20);
INSERT IGNORE INTO `item_mods` VALUES (25824, 12, 30);
INSERT IGNORE INTO `item_mods` VALUES (25824, 13, 40);
INSERT IGNORE INTO `item_mods` VALUES (25824, 14, 30);
INSERT IGNORE INTO `item_mods` VALUES (25824, 384, 40);

-- 25825  regal_captains_gloves  (lvl 99, ilvl 119, bucket armor)
INSERT IGNORE INTO `item_mods` VALUES (25825, 1, 116);
INSERT IGNORE INTO `item_mods` VALUES (25825, 2, 182);
INSERT IGNORE INTO `item_mods` VALUES (25825, 4, 29);
INSERT IGNORE INTO `item_mods` VALUES (25825, 8, 40);
INSERT IGNORE INTO `item_mods` VALUES (25825, 9, 40);
INSERT IGNORE INTO `item_mods` VALUES (25825, 10, 30);
INSERT IGNORE INTO `item_mods` VALUES (25825, 11, 20);
INSERT IGNORE INTO `item_mods` VALUES (25825, 12, 30);
INSERT IGNORE INTO `item_mods` VALUES (25825, 13, 30);
INSERT IGNORE INTO `item_mods` VALUES (25825, 14, 30);
INSERT IGNORE INTO `item_mods` VALUES (25825, 384, 40);

-- 25826  regal_gloves  (lvl 99, ilvl 119, bucket armor)
INSERT IGNORE INTO `item_mods` VALUES (25826, 1, 106);
INSERT IGNORE INTO `item_mods` VALUES (25826, 2, 342);
INSERT IGNORE INTO `item_mods` VALUES (25826, 8, 30);
INSERT IGNORE INTO `item_mods` VALUES (25826, 9, 40);
INSERT IGNORE INTO `item_mods` VALUES (25826, 10, 30);
INSERT IGNORE INTO `item_mods` VALUES (25826, 11, 20);
INSERT IGNORE INTO `item_mods` VALUES (25826, 12, 30);
INSERT IGNORE INTO `item_mods` VALUES (25826, 13, 30);
INSERT IGNORE INTO `item_mods` VALUES (25826, 14, 40);
INSERT IGNORE INTO `item_mods` VALUES (25826, 384, 40);

-- 25854  arjuna_breeches  (lvl 99, ilvl 119, bucket armor)
INSERT IGNORE INTO `item_mods` VALUES (25854, 1, 135);
INSERT IGNORE INTO `item_mods` VALUES (25854, 2, 57);
INSERT IGNORE INTO `item_mods` VALUES (25854, 4, 41);
INSERT IGNORE INTO `item_mods` VALUES (25854, 8, 35);
INSERT IGNORE INTO `item_mods` VALUES (25854, 10, 23);
INSERT IGNORE INTO `item_mods` VALUES (25854, 11, 15);
INSERT IGNORE INTO `item_mods` VALUES (25854, 12, 26);
INSERT IGNORE INTO `item_mods` VALUES (25854, 13, 10);
INSERT IGNORE INTO `item_mods` VALUES (25854, 14, 7);
INSERT IGNORE INTO `item_mods` VALUES (25854, 384, 50);

-- 25855  tatenashi_haidate  (lvl 99, ilvl 119, bucket armor)
INSERT IGNORE INTO `item_mods` VALUES (25855, 1, 129);
INSERT IGNORE INTO `item_mods` VALUES (25855, 2, 50);
INSERT IGNORE INTO `item_mods` VALUES (25855, 8, 44);
INSERT IGNORE INTO `item_mods` VALUES (25855, 10, 25);
INSERT IGNORE INTO `item_mods` VALUES (25855, 11, 15);
INSERT IGNORE INTO `item_mods` VALUES (25855, 12, 23);
INSERT IGNORE INTO `item_mods` VALUES (25855, 13, 12);
INSERT IGNORE INTO `item_mods` VALUES (25855, 14, 10);
INSERT IGNORE INTO `item_mods` VALUES (25855, 384, 50);

-- 25858  sulevias_cuisses  (lvl 99, ilvl 119, bucket armor)
INSERT IGNORE INTO `item_mods` VALUES (25858, 1, 125);
INSERT IGNORE INTO `item_mods` VALUES (25858, 2, 50);
INSERT IGNORE INTO `item_mods` VALUES (25858, 4, 50);
INSERT IGNORE INTO `item_mods` VALUES (25858, 8, 39);
INSERT IGNORE INTO `item_mods` VALUES (25858, 10, 25);
INSERT IGNORE INTO `item_mods` VALUES (25858, 11, 14);
INSERT IGNORE INTO `item_mods` VALUES (25858, 12, 24);
INSERT IGNORE INTO `item_mods` VALUES (25858, 13, 12);
INSERT IGNORE INTO `item_mods` VALUES (25858, 14, 10);
INSERT IGNORE INTO `item_mods` VALUES (25858, 384, 20);

-- 25862  hizamaru_hizayoroi  (lvl 99, ilvl 119, bucket armor)
INSERT IGNORE INTO `item_mods` VALUES (25862, 1, 113);
INSERT IGNORE INTO `item_mods` VALUES (25862, 2, 60);
INSERT IGNORE INTO `item_mods` VALUES (25862, 8, 42);
INSERT IGNORE INTO `item_mods` VALUES (25862, 10, 24);
INSERT IGNORE INTO `item_mods` VALUES (25862, 11, 16);
INSERT IGNORE INTO `item_mods` VALUES (25862, 12, 24);
INSERT IGNORE INTO `item_mods` VALUES (25862, 13, 11);
INSERT IGNORE INTO `item_mods` VALUES (25862, 14, 11);
INSERT IGNORE INTO `item_mods` VALUES (25862, 384, 90);
INSERT IGNORE INTO `item_mods` VALUES (25862, 371, 3);

-- 25889  oshosi_trousers  (lvl 99, ilvl 119, bucket armor)
INSERT IGNORE INTO `item_mods` VALUES (25889, 1, 121);
INSERT IGNORE INTO `item_mods` VALUES (25889, 2, 84);
INSERT IGNORE INTO `item_mods` VALUES (25889, 8, 38);
INSERT IGNORE INTO `item_mods` VALUES (25889, 10, 19);
INSERT IGNORE INTO `item_mods` VALUES (25889, 11, 38);
INSERT IGNORE INTO `item_mods` VALUES (25889, 12, 29);
INSERT IGNORE INTO `item_mods` VALUES (25889, 13, 20);
INSERT IGNORE INTO `item_mods` VALUES (25889, 14, 15);

-- 25891  kendatsuba_hakama  (lvl 99, ilvl 119, bucket armor)
INSERT IGNORE INTO `item_mods` VALUES (25891, 1, 122);
INSERT IGNORE INTO `item_mods` VALUES (25891, 2, 95);
INSERT IGNORE INTO `item_mods` VALUES (25891, 8, 37);
INSERT IGNORE INTO `item_mods` VALUES (25891, 10, 25);
INSERT IGNORE INTO `item_mods` VALUES (25891, 11, 28);
INSERT IGNORE INTO `item_mods` VALUES (25891, 12, 32);
INSERT IGNORE INTO `item_mods` VALUES (25891, 13, 16);
INSERT IGNORE INTO `item_mods` VALUES (25891, 14, 12);
INSERT IGNORE INTO `item_mods` VALUES (25891, 384, 90);

-- 25893  ea_slops  (lvl 99, ilvl 119, bucket armor)
INSERT IGNORE INTO `item_mods` VALUES (25893, 1, 115);
INSERT IGNORE INTO `item_mods` VALUES (25893, 2, 61);
INSERT IGNORE INTO `item_mods` VALUES (25893, 4, 85);
INSERT IGNORE INTO `item_mods` VALUES (25893, 8, 26);
INSERT IGNORE INTO `item_mods` VALUES (25893, 10, 17);
INSERT IGNORE INTO `item_mods` VALUES (25893, 11, 24);
INSERT IGNORE INTO `item_mods` VALUES (25893, 12, 43);
INSERT IGNORE INTO `item_mods` VALUES (25893, 13, 26);
INSERT IGNORE INTO `item_mods` VALUES (25893, 14, 23);
INSERT IGNORE INTO `item_mods` VALUES (25893, 384, 50);
INSERT IGNORE INTO `item_mods` VALUES (25893, 168, 7);

-- 25897  arke_cosciales  (lvl 99, ilvl 119, bucket armor)
INSERT IGNORE INTO `item_mods` VALUES (25897, 1, 141);
INSERT IGNORE INTO `item_mods` VALUES (25897, 2, 171);
INSERT IGNORE INTO `item_mods` VALUES (25897, 8, 40);
INSERT IGNORE INTO `item_mods` VALUES (25897, 10, 30);
INSERT IGNORE INTO `item_mods` VALUES (25897, 11, 19);
INSERT IGNORE INTO `item_mods` VALUES (25897, 12, 30);
INSERT IGNORE INTO `item_mods` VALUES (25897, 13, 20);
INSERT IGNORE INTO `item_mods` VALUES (25897, 14, 15);
INSERT IGNORE INTO `item_mods` VALUES (25897, 384, 50);

-- 25899  pinga_pants  (lvl 99, ilvl 119, bucket armor)
INSERT IGNORE INTO `item_mods` VALUES (25899, 1, 117);
INSERT IGNORE INTO `item_mods` VALUES (25899, 2, 64);
INSERT IGNORE INTO `item_mods` VALUES (25899, 4, 43);
INSERT IGNORE INTO `item_mods` VALUES (25899, 8, 26);
INSERT IGNORE INTO `item_mods` VALUES (25899, 10, 17);
INSERT IGNORE INTO `item_mods` VALUES (25899, 11, 24);
INSERT IGNORE INTO `item_mods` VALUES (25899, 12, 39);
INSERT IGNORE INTO `item_mods` VALUES (25899, 13, 30);
INSERT IGNORE INTO `item_mods` VALUES (25899, 14, 23);
INSERT IGNORE INTO `item_mods` VALUES (25899, 92, -7);

-- 25901  mousai_seraweels  (lvl 99, ilvl 119, bucket armor)
INSERT IGNORE INTO `item_mods` VALUES (25901, 1, 117);
INSERT IGNORE INTO `item_mods` VALUES (25901, 2, 136);
INSERT IGNORE INTO `item_mods` VALUES (25901, 8, 25);
INSERT IGNORE INTO `item_mods` VALUES (25901, 10, 25);
INSERT IGNORE INTO `item_mods` VALUES (25901, 11, 20);
INSERT IGNORE INTO `item_mods` VALUES (25901, 12, 35);
INSERT IGNORE INTO `item_mods` VALUES (25901, 13, 23);
INSERT IGNORE INTO `item_mods` VALUES (25901, 14, 28);
INSERT IGNORE INTO `item_mods` VALUES (25901, 384, 50);

-- 25903  heyoka_subligar  (lvl 99, ilvl 119, bucket armor)
INSERT IGNORE INTO `item_mods` VALUES (25903, 1, 121);
INSERT IGNORE INTO `item_mods` VALUES (25903, 2, 84);
INSERT IGNORE INTO `item_mods` VALUES (25903, 8, 34);
INSERT IGNORE INTO `item_mods` VALUES (25903, 10, 17);
INSERT IGNORE INTO `item_mods` VALUES (25903, 11, 24);
INSERT IGNORE INTO `item_mods` VALUES (25903, 12, 29);
INSERT IGNORE INTO `item_mods` VALUES (25903, 13, 16);
INSERT IGNORE INTO `item_mods` VALUES (25903, 14, 16);
INSERT IGNORE INTO `item_mods` VALUES (25903, 384, 90);
INSERT IGNORE INTO `item_mods` VALUES (25903, 92, 9);

-- 25905  baayami_slops  (lvl 99, ilvl 119, bucket armor)
INSERT IGNORE INTO `item_mods` VALUES (25905, 1, 114);
INSERT IGNORE INTO `item_mods` VALUES (25905, 2, 61);
INSERT IGNORE INTO `item_mods` VALUES (25905, 4, 53);
INSERT IGNORE INTO `item_mods` VALUES (25905, 8, 26);
INSERT IGNORE INTO `item_mods` VALUES (25905, 10, 24);
INSERT IGNORE INTO `item_mods` VALUES (25905, 11, 23);
INSERT IGNORE INTO `item_mods` VALUES (25905, 12, 47);
INSERT IGNORE INTO `item_mods` VALUES (25905, 13, 29);
INSERT IGNORE INTO `item_mods` VALUES (25905, 14, 20);
INSERT IGNORE INTO `item_mods` VALUES (25905, 384, 50);

-- 25907  turms_subligar  (lvl 99, ilvl 119, bucket armor)
INSERT IGNORE INTO `item_mods` VALUES (25907, 1, 127);
INSERT IGNORE INTO `item_mods` VALUES (25907, 2, 107);
INSERT IGNORE INTO `item_mods` VALUES (25907, 8, 30);
INSERT IGNORE INTO `item_mods` VALUES (25907, 10, 16);
INSERT IGNORE INTO `item_mods` VALUES (25907, 11, 32);
INSERT IGNORE INTO `item_mods` VALUES (25907, 12, 30);
INSERT IGNORE INTO `item_mods` VALUES (25907, 13, 17);
INSERT IGNORE INTO `item_mods` VALUES (25907, 14, 17);
INSERT IGNORE INTO `item_mods` VALUES (25907, 384, 90);

-- 25920  ahosi_leggings  (lvl 99, ilvl 119, bucket armor)
INSERT IGNORE INTO `item_mods` VALUES (25920, 1, 84);
INSERT IGNORE INTO `item_mods` VALUES (25920, 2, 18);
INSERT IGNORE INTO `item_mods` VALUES (25920, 4, 29);
INSERT IGNORE INTO `item_mods` VALUES (25920, 8, 17);
INSERT IGNORE INTO `item_mods` VALUES (25920, 9, 26);
INSERT IGNORE INTO `item_mods` VALUES (25920, 10, 11);
INSERT IGNORE INTO `item_mods` VALUES (25920, 11, 38);
INSERT IGNORE INTO `item_mods` VALUES (25920, 13, 16);
INSERT IGNORE INTO `item_mods` VALUES (25920, 14, 32);
INSERT IGNORE INTO `item_mods` VALUES (25920, 384, 40);
INSERT IGNORE INTO `item_mods` VALUES (25920, 92, 7);

-- 25923  tatenashi_sune-ate  (lvl 99, ilvl 119, bucket armor)
INSERT IGNORE INTO `item_mods` VALUES (25923, 1, 85);
INSERT IGNORE INTO `item_mods` VALUES (25923, 2, 15);
INSERT IGNORE INTO `item_mods` VALUES (25923, 8, 16);
INSERT IGNORE INTO `item_mods` VALUES (25923, 9, 19);
INSERT IGNORE INTO `item_mods` VALUES (25923, 10, 16);
INSERT IGNORE INTO `item_mods` VALUES (25923, 11, 31);
INSERT IGNORE INTO `item_mods` VALUES (25923, 13, 5);
INSERT IGNORE INTO `item_mods` VALUES (25923, 14, 19);
INSERT IGNORE INTO `item_mods` VALUES (25923, 384, 30);

-- 25924  tatenashi_sune-ate_+1  (lvl 99, ilvl 119, bucket armor)
INSERT IGNORE INTO `item_mods` VALUES (25924, 1, 86);
INSERT IGNORE INTO `item_mods` VALUES (25924, 2, 15);
INSERT IGNORE INTO `item_mods` VALUES (25924, 8, 16);
INSERT IGNORE INTO `item_mods` VALUES (25924, 9, 19);
INSERT IGNORE INTO `item_mods` VALUES (25924, 10, 16);
INSERT IGNORE INTO `item_mods` VALUES (25924, 11, 32);
INSERT IGNORE INTO `item_mods` VALUES (25924, 13, 5);
INSERT IGNORE INTO `item_mods` VALUES (25924, 14, 19);
INSERT IGNORE INTO `item_mods` VALUES (25924, 384, 30);

-- 25925  sulevias_leggings  (lvl 99, ilvl 119, bucket armor)
INSERT IGNORE INTO `item_mods` VALUES (25925, 1, 83);
INSERT IGNORE INTO `item_mods` VALUES (25925, 2, 20);
INSERT IGNORE INTO `item_mods` VALUES (25925, 4, 20);
INSERT IGNORE INTO `item_mods` VALUES (25925, 8, 21);
INSERT IGNORE INTO `item_mods` VALUES (25925, 9, 11);
INSERT IGNORE INTO `item_mods` VALUES (25925, 10, 21);
INSERT IGNORE INTO `item_mods` VALUES (25925, 11, 26);
INSERT IGNORE INTO `item_mods` VALUES (25925, 13, 10);
INSERT IGNORE INTO `item_mods` VALUES (25925, 14, 24);
INSERT IGNORE INTO `item_mods` VALUES (25925, 384, 10);
INSERT IGNORE INTO `item_mods` VALUES (25925, 371, 5);

-- 25929  hizamaru_sune-ate  (lvl 99, ilvl 119, bucket armor)
INSERT IGNORE INTO `item_mods` VALUES (25929, 1, 75);
INSERT IGNORE INTO `item_mods` VALUES (25929, 2, 30);
INSERT IGNORE INTO `item_mods` VALUES (25929, 8, 20);
INSERT IGNORE INTO `item_mods` VALUES (25929, 9, 23);
INSERT IGNORE INTO `item_mods` VALUES (25929, 10, 15);
INSERT IGNORE INTO `item_mods` VALUES (25929, 11, 26);
INSERT IGNORE INTO `item_mods` VALUES (25929, 13, 3);
INSERT IGNORE INTO `item_mods` VALUES (25929, 14, 20);
INSERT IGNORE INTO `item_mods` VALUES (25929, 384, 30);

-- 25930  hizamaru_sune-ate_+1  (lvl 99, ilvl 119, bucket armor)
INSERT IGNORE INTO `item_mods` VALUES (25930, 1, 80);
INSERT IGNORE INTO `item_mods` VALUES (25930, 2, 30);
INSERT IGNORE INTO `item_mods` VALUES (25930, 8, 25);
INSERT IGNORE INTO `item_mods` VALUES (25930, 9, 28);
INSERT IGNORE INTO `item_mods` VALUES (25930, 10, 20);
INSERT IGNORE INTO `item_mods` VALUES (25930, 11, 31);
INSERT IGNORE INTO `item_mods` VALUES (25930, 13, 3);
INSERT IGNORE INTO `item_mods` VALUES (25930, 14, 25);
INSERT IGNORE INTO `item_mods` VALUES (25930, 384, 30);

-- 25956  oshosi_leggings  (lvl 99, ilvl 119, bucket armor)
INSERT IGNORE INTO `item_mods` VALUES (25956, 1, 79);
INSERT IGNORE INTO `item_mods` VALUES (25956, 2, 38);
INSERT IGNORE INTO `item_mods` VALUES (25956, 8, 21);
INSERT IGNORE INTO `item_mods` VALUES (25956, 9, 24);
INSERT IGNORE INTO `item_mods` VALUES (25956, 10, 15);
INSERT IGNORE INTO `item_mods` VALUES (25956, 11, 51);
INSERT IGNORE INTO `item_mods` VALUES (25956, 13, 11);
INSERT IGNORE INTO `item_mods` VALUES (25956, 14, 34);
INSERT IGNORE INTO `item_mods` VALUES (25956, 92, -10);

-- 25960  ea_pigaches  (lvl 99, ilvl 119, bucket armor)
INSERT IGNORE INTO `item_mods` VALUES (25960, 1, 73);
INSERT IGNORE INTO `item_mods` VALUES (25960, 2, 15);
INSERT IGNORE INTO `item_mods` VALUES (25960, 4, 26);
INSERT IGNORE INTO `item_mods` VALUES (25960, 8, 11);
INSERT IGNORE INTO `item_mods` VALUES (25960, 9, 14);
INSERT IGNORE INTO `item_mods` VALUES (25960, 10, 15);
INSERT IGNORE INTO `item_mods` VALUES (25960, 11, 38);
INSERT IGNORE INTO `item_mods` VALUES (25960, 13, 21);
INSERT IGNORE INTO `item_mods` VALUES (25960, 14, 39);
INSERT IGNORE INTO `item_mods` VALUES (25960, 384, 30);
INSERT IGNORE INTO `item_mods` VALUES (25960, 168, 4);

-- 25964  arke_gambieras  (lvl 99, ilvl 119, bucket armor)
INSERT IGNORE INTO `item_mods` VALUES (25964, 1, 99);
INSERT IGNORE INTO `item_mods` VALUES (25964, 2, 114);
INSERT IGNORE INTO `item_mods` VALUES (25964, 8, 21);
INSERT IGNORE INTO `item_mods` VALUES (25964, 9, 20);
INSERT IGNORE INTO `item_mods` VALUES (25964, 10, 26);
INSERT IGNORE INTO `item_mods` VALUES (25964, 11, 33);
INSERT IGNORE INTO `item_mods` VALUES (25964, 13, 19);
INSERT IGNORE INTO `item_mods` VALUES (25964, 14, 31);
INSERT IGNORE INTO `item_mods` VALUES (25964, 384, 30);

-- 25966  pinga_pumps  (lvl 99, ilvl 119, bucket armor)
INSERT IGNORE INTO `item_mods` VALUES (25966, 1, 78);
INSERT IGNORE INTO `item_mods` VALUES (25966, 2, 64);
INSERT IGNORE INTO `item_mods` VALUES (25966, 4, 66);
INSERT IGNORE INTO `item_mods` VALUES (25966, 8, 11);
INSERT IGNORE INTO `item_mods` VALUES (25966, 9, 14);
INSERT IGNORE INTO `item_mods` VALUES (25966, 10, 15);
INSERT IGNORE INTO `item_mods` VALUES (25966, 11, 38);
INSERT IGNORE INTO `item_mods` VALUES (25966, 13, 30);
INSERT IGNORE INTO `item_mods` VALUES (25966, 14, 39);
INSERT IGNORE INTO `item_mods` VALUES (25966, 92, -4);

-- 25968  mousai_crackows  (lvl 99, ilvl 119, bucket armor)
INSERT IGNORE INTO `item_mods` VALUES (25968, 1, 78);
INSERT IGNORE INTO `item_mods` VALUES (25968, 2, 79);
INSERT IGNORE INTO `item_mods` VALUES (25968, 8, 10);
INSERT IGNORE INTO `item_mods` VALUES (25968, 9, 16);
INSERT IGNORE INTO `item_mods` VALUES (25968, 10, 23);
INSERT IGNORE INTO `item_mods` VALUES (25968, 11, 38);
INSERT IGNORE INTO `item_mods` VALUES (25968, 13, 16);
INSERT IGNORE INTO `item_mods` VALUES (25968, 14, 40);
INSERT IGNORE INTO `item_mods` VALUES (25968, 384, 30);

-- 25970  heyoka_leggings  (lvl 99, ilvl 119, bucket armor)
INSERT IGNORE INTO `item_mods` VALUES (25970, 1, 79);
INSERT IGNORE INTO `item_mods` VALUES (25970, 2, 38);
INSERT IGNORE INTO `item_mods` VALUES (25970, 8, 16);
INSERT IGNORE INTO `item_mods` VALUES (25970, 9, 38);
INSERT IGNORE INTO `item_mods` VALUES (25970, 10, 14);
INSERT IGNORE INTO `item_mods` VALUES (25970, 11, 40);
INSERT IGNORE INTO `item_mods` VALUES (25970, 13, 14);
INSERT IGNORE INTO `item_mods` VALUES (25970, 14, 35);
INSERT IGNORE INTO `item_mods` VALUES (25970, 384, 30);
INSERT IGNORE INTO `item_mods` VALUES (25970, 92, 6);

-- 25972  baayami_sabots  (lvl 99, ilvl 119, bucket armor)
INSERT IGNORE INTO `item_mods` VALUES (25972, 1, 72);
INSERT IGNORE INTO `item_mods` VALUES (25972, 2, 15);
INSERT IGNORE INTO `item_mods` VALUES (25972, 4, 29);
INSERT IGNORE INTO `item_mods` VALUES (25972, 8, 12);
INSERT IGNORE INTO `item_mods` VALUES (25972, 9, 14);
INSERT IGNORE INTO `item_mods` VALUES (25972, 10, 24);
INSERT IGNORE INTO `item_mods` VALUES (25972, 11, 37);
INSERT IGNORE INTO `item_mods` VALUES (25972, 13, 25);
INSERT IGNORE INTO `item_mods` VALUES (25972, 14, 35);
INSERT IGNORE INTO `item_mods` VALUES (25972, 384, 30);

-- 25976  oshosi_gloves  (lvl 99, ilvl 119, bucket armor)
INSERT IGNORE INTO `item_mods` VALUES (25976, 1, 97);
INSERT IGNORE INTO `item_mods` VALUES (25976, 2, 29);
INSERT IGNORE INTO `item_mods` VALUES (25976, 8, 20);
INSERT IGNORE INTO `item_mods` VALUES (25976, 9, 35);
INSERT IGNORE INTO `item_mods` VALUES (25976, 10, 34);
INSERT IGNORE INTO `item_mods` VALUES (25976, 12, 11);
INSERT IGNORE INTO `item_mods` VALUES (25976, 13, 29);
INSERT IGNORE INTO `item_mods` VALUES (25976, 14, 20);

-- 25978  kendatsuba_tekko  (lvl 99, ilvl 119, bucket armor)
INSERT IGNORE INTO `item_mods` VALUES (25978, 1, 98);
INSERT IGNORE INTO `item_mods` VALUES (25978, 2, 41);
INSERT IGNORE INTO `item_mods` VALUES (25978, 8, 14);
INSERT IGNORE INTO `item_mods` VALUES (25978, 9, 57);
INSERT IGNORE INTO `item_mods` VALUES (25978, 10, 37);
INSERT IGNORE INTO `item_mods` VALUES (25978, 12, 14);
INSERT IGNORE INTO `item_mods` VALUES (25978, 13, 28);
INSERT IGNORE INTO `item_mods` VALUES (25978, 14, 21);
INSERT IGNORE INTO `item_mods` VALUES (25978, 384, 40);

-- 25980  ea_cuffs  (lvl 99, ilvl 119, bucket armor)
INSERT IGNORE INTO `item_mods` VALUES (25980, 1, 91);
INSERT IGNORE INTO `item_mods` VALUES (25980, 2, 6);
INSERT IGNORE INTO `item_mods` VALUES (25980, 4, 14);
INSERT IGNORE INTO `item_mods` VALUES (25980, 8, 7);
INSERT IGNORE INTO `item_mods` VALUES (25980, 9, 29);
INSERT IGNORE INTO `item_mods` VALUES (25980, 10, 30);
INSERT IGNORE INTO `item_mods` VALUES (25980, 12, 35);
INSERT IGNORE INTO `item_mods` VALUES (25980, 13, 35);
INSERT IGNORE INTO `item_mods` VALUES (25980, 14, 23);
INSERT IGNORE INTO `item_mods` VALUES (25980, 384, 30);
INSERT IGNORE INTO `item_mods` VALUES (25980, 168, 5);

-- 25982  ratri_gadlings  (lvl 99, ilvl 119, bucket armor)
INSERT IGNORE INTO `item_mods` VALUES (25982, 1, 114);
INSERT IGNORE INTO `item_mods` VALUES (25982, 2, 399);
INSERT IGNORE INTO `item_mods` VALUES (25982, 8, 23);
INSERT IGNORE INTO `item_mods` VALUES (25982, 9, 43);
INSERT IGNORE INTO `item_mods` VALUES (25982, 10, 34);
INSERT IGNORE INTO `item_mods` VALUES (25982, 12, 14);
INSERT IGNORE INTO `item_mods` VALUES (25982, 13, 32);
INSERT IGNORE INTO `item_mods` VALUES (25982, 14, 24);
INSERT IGNORE INTO `item_mods` VALUES (25982, 384, 40);
INSERT IGNORE INTO `item_mods` VALUES (25982, 92, -7);
INSERT IGNORE INTO `item_mods` VALUES (25982, 371, 6);

-- 25984  arke_manopolas  (lvl 99, ilvl 119, bucket armor)
INSERT IGNORE INTO `item_mods` VALUES (25984, 1, 117);
INSERT IGNORE INTO `item_mods` VALUES (25984, 2, 102);
INSERT IGNORE INTO `item_mods` VALUES (25984, 8, 15);
INSERT IGNORE INTO `item_mods` VALUES (25984, 9, 38);
INSERT IGNORE INTO `item_mods` VALUES (25984, 10, 42);
INSERT IGNORE INTO `item_mods` VALUES (25984, 12, 12);
INSERT IGNORE INTO `item_mods` VALUES (25984, 13, 33);
INSERT IGNORE INTO `item_mods` VALUES (25984, 14, 24);
INSERT IGNORE INTO `item_mods` VALUES (25984, 384, 40);

-- 25986  pinga_mittens  (lvl 99, ilvl 119, bucket armor)
INSERT IGNORE INTO `item_mods` VALUES (25986, 1, 93);
INSERT IGNORE INTO `item_mods` VALUES (25986, 2, 33);
INSERT IGNORE INTO `item_mods` VALUES (25986, 4, 73);
INSERT IGNORE INTO `item_mods` VALUES (25986, 8, 7);
INSERT IGNORE INTO `item_mods` VALUES (25986, 9, 29);
INSERT IGNORE INTO `item_mods` VALUES (25986, 10, 30);
INSERT IGNORE INTO `item_mods` VALUES (25986, 12, 24);
INSERT IGNORE INTO `item_mods` VALUES (25986, 13, 44);
INSERT IGNORE INTO `item_mods` VALUES (25986, 14, 23);
INSERT IGNORE INTO `item_mods` VALUES (25986, 92, -5);

-- 25988  mousai_gages  (lvl 99, ilvl 119, bucket armor)
INSERT IGNORE INTO `item_mods` VALUES (25988, 1, 93);
INSERT IGNORE INTO `item_mods` VALUES (25988, 2, 68);
INSERT IGNORE INTO `item_mods` VALUES (25988, 8, 8);
INSERT IGNORE INTO `item_mods` VALUES (25988, 9, 33);
INSERT IGNORE INTO `item_mods` VALUES (25988, 10, 40);
INSERT IGNORE INTO `item_mods` VALUES (25988, 12, 20);
INSERT IGNORE INTO `item_mods` VALUES (25988, 13, 32);
INSERT IGNORE INTO `item_mods` VALUES (25988, 14, 33);
INSERT IGNORE INTO `item_mods` VALUES (25988, 384, 30);

-- 25992  baayami_cuffs  (lvl 99, ilvl 119, bucket armor)
INSERT IGNORE INTO `item_mods` VALUES (25992, 1, 90);
INSERT IGNORE INTO `item_mods` VALUES (25992, 2, 6);
INSERT IGNORE INTO `item_mods` VALUES (25992, 4, 35);
INSERT IGNORE INTO `item_mods` VALUES (25992, 8, 7);
INSERT IGNORE INTO `item_mods` VALUES (25992, 9, 30);
INSERT IGNORE INTO `item_mods` VALUES (25992, 10, 37);
INSERT IGNORE INTO `item_mods` VALUES (25992, 12, 30);
INSERT IGNORE INTO `item_mods` VALUES (25992, 13, 38);
INSERT IGNORE INTO `item_mods` VALUES (25992, 14, 20);
INSERT IGNORE INTO `item_mods` VALUES (25992, 384, 30);

-- 25994  turms_mittens  (lvl 99, ilvl 119, bucket armor)
INSERT IGNORE INTO `item_mods` VALUES (25994, 1, 103);
INSERT IGNORE INTO `item_mods` VALUES (25994, 2, 75);
INSERT IGNORE INTO `item_mods` VALUES (25994, 8, 12);
INSERT IGNORE INTO `item_mods` VALUES (25994, 9, 46);
INSERT IGNORE INTO `item_mods` VALUES (25994, 10, 32);
INSERT IGNORE INTO `item_mods` VALUES (25994, 12, 15);
INSERT IGNORE INTO `item_mods` VALUES (25994, 13, 30);
INSERT IGNORE INTO `item_mods` VALUES (25994, 14, 23);
INSERT IGNORE INTO `item_mods` VALUES (25994, 384, 40);

-- 26000  consummation_torque  (lvl 99, ilvl 0, bucket armor)
INSERT IGNORE INTO `item_mods` VALUES (26000, 92, 5);

-- 26017  clotharius_torque  (lvl 99, ilvl 0, bucket armor)
INSERT IGNORE INTO `item_mods` VALUES (26017, 92, -4);

-- 26019  homeric_gorget  (lvl 99, ilvl 0, bucket armor)
INSERT IGNORE INTO `item_mods` VALUES (26019, 1, 20);
INSERT IGNORE INTO `item_mods` VALUES (26019, 92, 3);

-- 26020  ainia_collar  (lvl 99, ilvl 0, bucket armor)
INSERT IGNORE INTO `item_mods` VALUES (26020, 1, 16);

-- 26021  vim_torque  (lvl 99, ilvl 0, bucket armor)
INSERT IGNORE INTO `item_mods` VALUES (26021, 1, 14);

-- 26172  begrudging_ring  (lvl 99, ilvl 0, bucket armor)
INSERT IGNORE INTO `item_mods` VALUES (26172, 92, 5);

-- 26173  apate_ring  (lvl 99, ilvl 0, bucket armor)
INSERT IGNORE INTO `item_mods` VALUES (26173, 8, 6);
INSERT IGNORE INTO `item_mods` VALUES (26173, 9, 6);
INSERT IGNORE INTO `item_mods` VALUES (26173, 11, 6);

-- 26174  persis_ring  (lvl 99, ilvl 0, bucket armor)
INSERT IGNORE INTO `item_mods` VALUES (26174, 4, 80);
INSERT IGNORE INTO `item_mods` VALUES (26174, 12, 6);
INSERT IGNORE INTO `item_mods` VALUES (26174, 13, 6);
INSERT IGNORE INTO `item_mods` VALUES (26174, 92, -5);

-- 26204  sulevias_ring  (lvl 99, ilvl 0, bucket armor)
INSERT IGNORE INTO `item_mods` VALUES (26204, 1, 10);

-- 26205  meghanada_ring  (lvl 99, ilvl 0, bucket armor)
INSERT IGNORE INTO `item_mods` VALUES (26205, 1, 7);

-- 26206  hizamaru_ring  (lvl 99, ilvl 0, bucket armor)
INSERT IGNORE INTO `item_mods` VALUES (26206, 1, 8);

-- 26207  inyanga_ring  (lvl 99, ilvl 0, bucket armor)
INSERT IGNORE INTO `item_mods` VALUES (26207, 1, 6);

-- 26208  jhakri_ring  (lvl 99, ilvl 0, bucket armor)
INSERT IGNORE INTO `item_mods` VALUES (26208, 1, 6);
INSERT IGNORE INTO `item_mods` VALUES (26208, 168, 2);

-- 26209  ayanmo_ring  (lvl 99, ilvl 0, bucket armor)
INSERT IGNORE INTO `item_mods` VALUES (26209, 1, 7);

-- 26210  taliah_ring  (lvl 99, ilvl 0, bucket armor)
INSERT IGNORE INTO `item_mods` VALUES (26210, 1, 7);

-- 26211  flamma_ring  (lvl 99, ilvl 0, bucket armor)
INSERT IGNORE INTO `item_mods` VALUES (26211, 1, 8);

-- 26212  mummu_ring  (lvl 99, ilvl 0, bucket armor)
INSERT IGNORE INTO `item_mods` VALUES (26212, 1, 7);

-- 26213  mallquis_ring  (lvl 99, ilvl 0, bucket armor)
INSERT IGNORE INTO `item_mods` VALUES (26213, 1, 6);

-- 26240  tantalic_cape  (lvl 99, ilvl 0, bucket armor)
INSERT IGNORE INTO `item_mods` VALUES (26240, 1, 17);
INSERT IGNORE INTO `item_mods` VALUES (26240, 2, 50);
INSERT IGNORE INTO `item_mods` VALUES (26240, 4, 50);
INSERT IGNORE INTO `item_mods` VALUES (26240, 8, 4);
INSERT IGNORE INTO `item_mods` VALUES (26240, 9, 4);
INSERT IGNORE INTO `item_mods` VALUES (26240, 10, 4);
INSERT IGNORE INTO `item_mods` VALUES (26240, 11, 4);
INSERT IGNORE INTO `item_mods` VALUES (26240, 12, 4);
INSERT IGNORE INTO `item_mods` VALUES (26240, 13, 4);
INSERT IGNORE INTO `item_mods` VALUES (26240, 14, 4);

-- 26243  perimede_cape  (lvl 99, ilvl 0, bucket armor)
INSERT IGNORE INTO `item_mods` VALUES (26243, 1, 17);

-- 26244  agema_cape  (lvl 99, ilvl 0, bucket armor)
INSERT IGNORE INTO `item_mods` VALUES (26244, 1, 18);
INSERT IGNORE INTO `item_mods` VALUES (26244, 2, 40);
INSERT IGNORE INTO `item_mods` VALUES (26244, 4, 40);
INSERT IGNORE INTO `item_mods` VALUES (26244, 92, 5);

-- 26270  sacro_mantle  (lvl 99, ilvl 0, bucket armor)
INSERT IGNORE INTO `item_mods` VALUES (26270, 9, 25);
INSERT IGNORE INTO `item_mods` VALUES (26270, 11, 25);
INSERT IGNORE INTO `item_mods` VALUES (26270, 371, 6);

-- 26275  alabaster_mantle  (lvl 99, ilvl 0, bucket armor)
INSERT IGNORE INTO `item_mods` VALUES (26275, 1, 20);
INSERT IGNORE INTO `item_mods` VALUES (26275, 371, 11);

-- 26276  murky_mantle  (lvl 99, ilvl 0, bucket armor)
INSERT IGNORE INTO `item_mods` VALUES (26276, 1, 18);

-- 26325  refoccilation_stone  (lvl 99, ilvl 0, bucket armor)
INSERT IGNORE INTO `item_mods` VALUES (26325, 1, 12);
INSERT IGNORE INTO `item_mods` VALUES (26325, 4, 20);

-- 26326  channelers_stone  (lvl 99, ilvl 0, bucket armor)
INSERT IGNORE INTO `item_mods` VALUES (26326, 12, 10);
INSERT IGNORE INTO `item_mods` VALUES (26326, 92, -3);

-- 26327  asklepian_belt  (lvl 99, ilvl 0, bucket armor)
INSERT IGNORE INTO `item_mods` VALUES (26327, 1, 11);

-- 26328  sarissaphoroi_belt  (lvl 99, ilvl 0, bucket armor)
INSERT IGNORE INTO `item_mods` VALUES (26328, 1, 14);
INSERT IGNORE INTO `item_mods` VALUES (26328, 384, 30);

-- 26342  regal_belt  (lvl 99, ilvl 0, bucket armor)
INSERT IGNORE INTO `item_mods` VALUES (26342, 1, 12);
INSERT IGNORE INTO `item_mods` VALUES (26342, 2, 88);

-- 26358  ligeia_sash  (lvl 99, ilvl 0, bucket armor)
INSERT IGNORE INTO `item_mods` VALUES (26358, 1, 14);

-- 26365  cornelias_belt  (lvl 99, ilvl 0, bucket armor)
INSERT IGNORE INTO `item_mods` VALUES (26365, 1, 10);
INSERT IGNORE INTO `item_mods` VALUES (26365, 8, 10);
INSERT IGNORE INTO `item_mods` VALUES (26365, 384, 100);

-- 26366  platinum_moogle_belt  (lvl 99, ilvl 0, bucket armor)
INSERT IGNORE INTO `item_mods` VALUES (26366, 2, 10);

-- 26401  forfend  (lvl 99, ilvl 119, bucket shield)
INSERT IGNORE INTO `item_mods` VALUES (26401, 1, 140);
INSERT IGNORE INTO `item_mods` VALUES (26401, 2, 22);
INSERT IGNORE INTO `item_mods` VALUES (26401, 4, 29);

-- 26402  forfend_+1  (lvl 99, ilvl 119, bucket shield)
INSERT IGNORE INTO `item_mods` VALUES (26402, 1, 142);
INSERT IGNORE INTO `item_mods` VALUES (26402, 2, 22);
INSERT IGNORE INTO `item_mods` VALUES (26402, 4, 29);

-- 26425  joiners_scutum  (lvl 1, ilvl 0, bucket shield)
INSERT IGNORE INTO `item_mods` VALUES (26425, 1, 3);

-- 26426  joiners_shield  (lvl 1, ilvl 0, bucket shield)
INSERT IGNORE INTO `item_mods` VALUES (26426, 1, 4);

-- 26427  joiners_escutcheon  (lvl 1, ilvl 0, bucket shield)
INSERT IGNORE INTO `item_mods` VALUES (26427, 1, 5);

-- 26430  smythes_scutum  (lvl 1, ilvl 0, bucket shield)
INSERT IGNORE INTO `item_mods` VALUES (26430, 1, 3);

-- 26431  smythes_shield  (lvl 1, ilvl 0, bucket shield)
INSERT IGNORE INTO `item_mods` VALUES (26431, 1, 4);

-- 26432  smythes_escutcheon  (lvl 1, ilvl 0, bucket shield)
INSERT IGNORE INTO `item_mods` VALUES (26432, 1, 5);

-- 26435  toreutic_scutum  (lvl 1, ilvl 0, bucket shield)
INSERT IGNORE INTO `item_mods` VALUES (26435, 1, 3);

-- 26436  toreutic_shield  (lvl 1, ilvl 0, bucket shield)
INSERT IGNORE INTO `item_mods` VALUES (26436, 1, 4);

-- 26437  toreutic_escutcheon  (lvl 1, ilvl 0, bucket shield)
INSERT IGNORE INTO `item_mods` VALUES (26437, 1, 5);

-- 26440  plaiters_scutum  (lvl 1, ilvl 0, bucket shield)
INSERT IGNORE INTO `item_mods` VALUES (26440, 1, 3);

-- 26441  plaiters_shield  (lvl 1, ilvl 0, bucket shield)
INSERT IGNORE INTO `item_mods` VALUES (26441, 1, 4);

-- 26442  plaiters_escutcheon  (lvl 1, ilvl 0, bucket shield)
INSERT IGNORE INTO `item_mods` VALUES (26442, 1, 5);

-- 26445  bevelers_scutum  (lvl 1, ilvl 0, bucket shield)
INSERT IGNORE INTO `item_mods` VALUES (26445, 1, 3);

-- 26446  bevelers_shield  (lvl 1, ilvl 0, bucket shield)
INSERT IGNORE INTO `item_mods` VALUES (26446, 1, 4);

-- 26447  bevelers_escutcheon  (lvl 1, ilvl 0, bucket shield)
INSERT IGNORE INTO `item_mods` VALUES (26447, 1, 5);

-- 26450  ossifiers_scutum  (lvl 1, ilvl 0, bucket shield)
INSERT IGNORE INTO `item_mods` VALUES (26450, 1, 3);

-- 26451  ossifiers_shield  (lvl 1, ilvl 0, bucket shield)
INSERT IGNORE INTO `item_mods` VALUES (26451, 1, 4);

-- 26452  ossifiers_escutcheon  (lvl 1, ilvl 0, bucket shield)
INSERT IGNORE INTO `item_mods` VALUES (26452, 1, 5);

-- 26455  brewers_scutum  (lvl 1, ilvl 0, bucket shield)
INSERT IGNORE INTO `item_mods` VALUES (26455, 1, 3);

-- 26456  brewers_shield  (lvl 1, ilvl 0, bucket shield)
INSERT IGNORE INTO `item_mods` VALUES (26456, 1, 4);

-- 26457  brewers_escutcheon  (lvl 1, ilvl 0, bucket shield)
INSERT IGNORE INTO `item_mods` VALUES (26457, 1, 5);

-- 26460  chefs_scutum  (lvl 1, ilvl 0, bucket shield)
INSERT IGNORE INTO `item_mods` VALUES (26460, 1, 3);

-- 26461  chefs_shield  (lvl 1, ilvl 0, bucket shield)
INSERT IGNORE INTO `item_mods` VALUES (26461, 1, 4);

-- 26462  chefs_escutcheon  (lvl 1, ilvl 0, bucket shield)
INSERT IGNORE INTO `item_mods` VALUES (26462, 1, 5);

-- 26525  oshosi_vest  (lvl 99, ilvl 119, bucket armor)
INSERT IGNORE INTO `item_mods` VALUES (26525, 1, 139);
INSERT IGNORE INTO `item_mods` VALUES (26525, 2, 91);
INSERT IGNORE INTO `item_mods` VALUES (26525, 8, 33);
INSERT IGNORE INTO `item_mods` VALUES (26525, 9, 30);
INSERT IGNORE INTO `item_mods` VALUES (26525, 10, 26);
INSERT IGNORE INTO `item_mods` VALUES (26525, 11, 44);
INSERT IGNORE INTO `item_mods` VALUES (26525, 12, 21);
INSERT IGNORE INTO `item_mods` VALUES (26525, 13, 21);
INSERT IGNORE INTO `item_mods` VALUES (26525, 14, 26);

-- 26527  kendatsuba_samue  (lvl 99, ilvl 119, bucket armor)
INSERT IGNORE INTO `item_mods` VALUES (26527, 1, 140);
INSERT IGNORE INTO `item_mods` VALUES (26527, 2, 102);
INSERT IGNORE INTO `item_mods` VALUES (26527, 8, 33);
INSERT IGNORE INTO `item_mods` VALUES (26527, 9, 34);
INSERT IGNORE INTO `item_mods` VALUES (26527, 10, 21);
INSERT IGNORE INTO `item_mods` VALUES (26527, 11, 32);
INSERT IGNORE INTO `item_mods` VALUES (26527, 12, 24);
INSERT IGNORE INTO `item_mods` VALUES (26527, 13, 23);
INSERT IGNORE INTO `item_mods` VALUES (26527, 14, 21);
INSERT IGNORE INTO `item_mods` VALUES (26527, 384, 40);

-- 26529  ea_houppelande  (lvl 99, ilvl 119, bucket armor)
INSERT IGNORE INTO `item_mods` VALUES (26529, 1, 133);
INSERT IGNORE INTO `item_mods` VALUES (26529, 2, 68);
INSERT IGNORE INTO `item_mods` VALUES (26529, 4, 94);
INSERT IGNORE INTO `item_mods` VALUES (26529, 8, 23);
INSERT IGNORE INTO `item_mods` VALUES (26529, 9, 24);
INSERT IGNORE INTO `item_mods` VALUES (26529, 10, 26);
INSERT IGNORE INTO `item_mods` VALUES (26529, 11, 26);
INSERT IGNORE INTO `item_mods` VALUES (26529, 12, 43);
INSERT IGNORE INTO `item_mods` VALUES (26529, 13, 32);
INSERT IGNORE INTO `item_mods` VALUES (26529, 14, 34);
INSERT IGNORE INTO `item_mods` VALUES (26529, 384, 30);
INSERT IGNORE INTO `item_mods` VALUES (26529, 168, 8);

-- 26533  arke_corazza  (lvl 99, ilvl 119, bucket armor)
INSERT IGNORE INTO `item_mods` VALUES (26533, 1, 159);
INSERT IGNORE INTO `item_mods` VALUES (26533, 2, 205);
INSERT IGNORE INTO `item_mods` VALUES (26533, 8, 34);
INSERT IGNORE INTO `item_mods` VALUES (26533, 9, 26);
INSERT IGNORE INTO `item_mods` VALUES (26533, 10, 38);
INSERT IGNORE INTO `item_mods` VALUES (26533, 11, 21);
INSERT IGNORE INTO `item_mods` VALUES (26533, 12, 24);
INSERT IGNORE INTO `item_mods` VALUES (26533, 13, 26);
INSERT IGNORE INTO `item_mods` VALUES (26533, 14, 24);
INSERT IGNORE INTO `item_mods` VALUES (26533, 384, 30);

-- 26535  pinga_tunic  (lvl 99, ilvl 119, bucket armor)
INSERT IGNORE INTO `item_mods` VALUES (26535, 1, 135);
INSERT IGNORE INTO `item_mods` VALUES (26535, 2, 81);
INSERT IGNORE INTO `item_mods` VALUES (26535, 4, 88);
INSERT IGNORE INTO `item_mods` VALUES (26535, 8, 23);
INSERT IGNORE INTO `item_mods` VALUES (26535, 9, 24);
INSERT IGNORE INTO `item_mods` VALUES (26535, 10, 26);
INSERT IGNORE INTO `item_mods` VALUES (26535, 11, 26);
INSERT IGNORE INTO `item_mods` VALUES (26535, 12, 34);
INSERT IGNORE INTO `item_mods` VALUES (26535, 13, 35);
INSERT IGNORE INTO `item_mods` VALUES (26535, 14, 34);
INSERT IGNORE INTO `item_mods` VALUES (26535, 92, -8);

-- 26537  mousai_manteel  (lvl 99, ilvl 119, bucket armor)
INSERT IGNORE INTO `item_mods` VALUES (26537, 1, 135);
INSERT IGNORE INTO `item_mods` VALUES (26537, 2, 171);
INSERT IGNORE INTO `item_mods` VALUES (26537, 8, 21);
INSERT IGNORE INTO `item_mods` VALUES (26537, 9, 28);
INSERT IGNORE INTO `item_mods` VALUES (26537, 10, 34);
INSERT IGNORE INTO `item_mods` VALUES (26537, 11, 24);
INSERT IGNORE INTO `item_mods` VALUES (26537, 12, 30);
INSERT IGNORE INTO `item_mods` VALUES (26537, 13, 28);
INSERT IGNORE INTO `item_mods` VALUES (26537, 14, 37);
INSERT IGNORE INTO `item_mods` VALUES (26537, 384, 30);

-- 26539  heyoka_harness  (lvl 99, ilvl 119, bucket armor)
INSERT IGNORE INTO `item_mods` VALUES (26539, 1, 139);
INSERT IGNORE INTO `item_mods` VALUES (26539, 2, 91);
INSERT IGNORE INTO `item_mods` VALUES (26539, 8, 34);
INSERT IGNORE INTO `item_mods` VALUES (26539, 9, 46);
INSERT IGNORE INTO `item_mods` VALUES (26539, 10, 24);
INSERT IGNORE INTO `item_mods` VALUES (26539, 11, 32);
INSERT IGNORE INTO `item_mods` VALUES (26539, 12, 21);
INSERT IGNORE INTO `item_mods` VALUES (26539, 13, 20);
INSERT IGNORE INTO `item_mods` VALUES (26539, 14, 33);
INSERT IGNORE INTO `item_mods` VALUES (26539, 384, 40);
INSERT IGNORE INTO `item_mods` VALUES (26539, 92, 10);

-- 26541  baayami_robe  (lvl 99, ilvl 119, bucket armor)
INSERT IGNORE INTO `item_mods` VALUES (26541, 1, 132);
INSERT IGNORE INTO `item_mods` VALUES (26541, 2, 68);
INSERT IGNORE INTO `item_mods` VALUES (26541, 4, 103);
INSERT IGNORE INTO `item_mods` VALUES (26541, 8, 23);
INSERT IGNORE INTO `item_mods` VALUES (26541, 9, 24);
INSERT IGNORE INTO `item_mods` VALUES (26541, 10, 34);
INSERT IGNORE INTO `item_mods` VALUES (26541, 11, 25);
INSERT IGNORE INTO `item_mods` VALUES (26541, 12, 42);
INSERT IGNORE INTO `item_mods` VALUES (26541, 13, 34);
INSERT IGNORE INTO `item_mods` VALUES (26541, 14, 30);
INSERT IGNORE INTO `item_mods` VALUES (26541, 384, 30);

-- 26543  turms_harness  (lvl 99, ilvl 119, bucket armor)
INSERT IGNORE INTO `item_mods` VALUES (26543, 1, 145);
INSERT IGNORE INTO `item_mods` VALUES (26543, 2, 114);
INSERT IGNORE INTO `item_mods` VALUES (26543, 8, 25);
INSERT IGNORE INTO `item_mods` VALUES (26543, 9, 42);
INSERT IGNORE INTO `item_mods` VALUES (26543, 10, 24);
INSERT IGNORE INTO `item_mods` VALUES (26543, 11, 39);
INSERT IGNORE INTO `item_mods` VALUES (26543, 12, 23);
INSERT IGNORE INTO `item_mods` VALUES (26543, 13, 23);
INSERT IGNORE INTO `item_mods` VALUES (26543, 14, 29);
INSERT IGNORE INTO `item_mods` VALUES (26543, 384, 40);

-- 26546  moogle_shirt  (lvl 1, ilvl 0, bucket armor)
INSERT IGNORE INTO `item_mods` VALUES (26546, 1, 1);

-- 26703  lycopodium_masque  (lvl 1, ilvl 0, bucket armor)
INSERT IGNORE INTO `item_mods` VALUES (26703, 1, 1);

-- 26709  imperial_wing_hairpin  (lvl 99, ilvl 119, bucket armor)
INSERT IGNORE INTO `item_mods` VALUES (26709, 9, 26);
INSERT IGNORE INTO `item_mods` VALUES (26709, 11, 26);

-- 26722  gefechtschaller  (lvl 99, ilvl 119, bucket armor)
INSERT IGNORE INTO `item_mods` VALUES (26722, 1, 113);
INSERT IGNORE INTO `item_mods` VALUES (26722, 2, 38);
INSERT IGNORE INTO `item_mods` VALUES (26722, 4, 43);
INSERT IGNORE INTO `item_mods` VALUES (26722, 8, 26);
INSERT IGNORE INTO `item_mods` VALUES (26722, 9, 22);
INSERT IGNORE INTO `item_mods` VALUES (26722, 10, 24);
INSERT IGNORE INTO `item_mods` VALUES (26722, 11, 21);
INSERT IGNORE INTO `item_mods` VALUES (26722, 12, 20);
INSERT IGNORE INTO `item_mods` VALUES (26722, 13, 20);
INSERT IGNORE INTO `item_mods` VALUES (26722, 14, 20);
INSERT IGNORE INTO `item_mods` VALUES (26722, 384, 70);

-- 26723  wildheitschaller  (lvl 99, ilvl 119, bucket armor)
INSERT IGNORE INTO `item_mods` VALUES (26723, 1, 114);
INSERT IGNORE INTO `item_mods` VALUES (26723, 2, 38);
INSERT IGNORE INTO `item_mods` VALUES (26723, 4, 53);
INSERT IGNORE INTO `item_mods` VALUES (26723, 8, 27);
INSERT IGNORE INTO `item_mods` VALUES (26723, 9, 23);
INSERT IGNORE INTO `item_mods` VALUES (26723, 10, 25);
INSERT IGNORE INTO `item_mods` VALUES (26723, 11, 22);
INSERT IGNORE INTO `item_mods` VALUES (26723, 12, 21);
INSERT IGNORE INTO `item_mods` VALUES (26723, 13, 21);
INSERT IGNORE INTO `item_mods` VALUES (26723, 14, 21);
INSERT IGNORE INTO `item_mods` VALUES (26723, 384, 70);

-- 26724  sombra_tiara  (lvl 99, ilvl 119, bucket armor)
INSERT IGNORE INTO `item_mods` VALUES (26724, 1, 101);
INSERT IGNORE INTO `item_mods` VALUES (26724, 2, 56);
INSERT IGNORE INTO `item_mods` VALUES (26724, 4, 17);
INSERT IGNORE INTO `item_mods` VALUES (26724, 8, 22);
INSERT IGNORE INTO `item_mods` VALUES (26724, 9, 24);
INSERT IGNORE INTO `item_mods` VALUES (26724, 10, 21);
INSERT IGNORE INTO `item_mods` VALUES (26724, 11, 24);
INSERT IGNORE INTO `item_mods` VALUES (26724, 12, 21);
INSERT IGNORE INTO `item_mods` VALUES (26724, 13, 21);
INSERT IGNORE INTO `item_mods` VALUES (26724, 14, 21);
INSERT IGNORE INTO `item_mods` VALUES (26724, 384, 70);

-- 26726  revealers_crown  (lvl 99, ilvl 119, bucket armor)
INSERT IGNORE INTO `item_mods` VALUES (26726, 1, 95);
INSERT IGNORE INTO `item_mods` VALUES (26726, 2, 36);
INSERT IGNORE INTO `item_mods` VALUES (26726, 4, 62);
INSERT IGNORE INTO `item_mods` VALUES (26726, 8, 20);
INSERT IGNORE INTO `item_mods` VALUES (26726, 9, 20);
INSERT IGNORE INTO `item_mods` VALUES (26726, 10, 20);
INSERT IGNORE INTO `item_mods` VALUES (26726, 11, 20);
INSERT IGNORE INTO `item_mods` VALUES (26726, 12, 26);
INSERT IGNORE INTO `item_mods` VALUES (26726, 13, 26);
INSERT IGNORE INTO `item_mods` VALUES (26726, 14, 25);
INSERT IGNORE INTO `item_mods` VALUES (26726, 384, 60);

-- 26728  frosty_cap  (lvl 1, ilvl 0, bucket armor)
INSERT IGNORE INTO `item_mods` VALUES (26728, 1, 2);

-- 26731  stinger_helm  (lvl 99, ilvl 119, bucket armor)
INSERT IGNORE INTO `item_mods` VALUES (26731, 1, 110);
INSERT IGNORE INTO `item_mods` VALUES (26731, 2, 38);
INSERT IGNORE INTO `item_mods` VALUES (26731, 8, 25);
INSERT IGNORE INTO `item_mods` VALUES (26731, 9, 16);
INSERT IGNORE INTO `item_mods` VALUES (26731, 10, 16);
INSERT IGNORE INTO `item_mods` VALUES (26731, 11, 16);
INSERT IGNORE INTO `item_mods` VALUES (26731, 12, 16);
INSERT IGNORE INTO `item_mods` VALUES (26731, 13, 16);
INSERT IGNORE INTO `item_mods` VALUES (26731, 14, 16);
INSERT IGNORE INTO `item_mods` VALUES (26731, 384, 90);

-- 26784  hike_khat  (lvl 99, ilvl 119, bucket armor)
INSERT IGNORE INTO `item_mods` VALUES (26784, 1, 95);
INSERT IGNORE INTO `item_mods` VALUES (26784, 2, 36);
INSERT IGNORE INTO `item_mods` VALUES (26784, 4, 32);
INSERT IGNORE INTO `item_mods` VALUES (26784, 8, 14);
INSERT IGNORE INTO `item_mods` VALUES (26784, 9, 14);
INSERT IGNORE INTO `item_mods` VALUES (26784, 10, 14);
INSERT IGNORE INTO `item_mods` VALUES (26784, 11, 14);
INSERT IGNORE INTO `item_mods` VALUES (26784, 12, 19);
INSERT IGNORE INTO `item_mods` VALUES (26784, 13, 19);
INSERT IGNORE INTO `item_mods` VALUES (26784, 14, 19);
INSERT IGNORE INTO `item_mods` VALUES (26784, 384, 60);

-- 26786  alhazen_hat  (lvl 99, ilvl 119, bucket armor)
INSERT IGNORE INTO `item_mods` VALUES (26786, 2, 30);

-- 26872  hime_domaru  (lvl 99, ilvl 119, bucket armor)
INSERT IGNORE INTO `item_mods` VALUES (26872, 1, 140);
INSERT IGNORE INTO `item_mods` VALUES (26872, 2, 63);
INSERT IGNORE INTO `item_mods` VALUES (26872, 4, 35);
INSERT IGNORE INTO `item_mods` VALUES (26872, 8, 29);
INSERT IGNORE INTO `item_mods` VALUES (26872, 9, 19);
INSERT IGNORE INTO `item_mods` VALUES (26872, 10, 34);
INSERT IGNORE INTO `item_mods` VALUES (26872, 11, 19);
INSERT IGNORE INTO `item_mods` VALUES (26872, 12, 19);
INSERT IGNORE INTO `item_mods` VALUES (26872, 13, 19);
INSERT IGNORE INTO `item_mods` VALUES (26872, 14, 19);
INSERT IGNORE INTO `item_mods` VALUES (26872, 384, 30);

-- 26875  ravenous_breastplate  (lvl 99, ilvl 119, bucket armor)
INSERT IGNORE INTO `item_mods` VALUES (26875, 1, 145);
INSERT IGNORE INTO `item_mods` VALUES (26875, 2, 63);
INSERT IGNORE INTO `item_mods` VALUES (26875, 4, 35);
INSERT IGNORE INTO `item_mods` VALUES (26875, 8, 37);
INSERT IGNORE INTO `item_mods` VALUES (26875, 9, 24);
INSERT IGNORE INTO `item_mods` VALUES (26875, 10, 35);
INSERT IGNORE INTO `item_mods` VALUES (26875, 11, 24);
INSERT IGNORE INTO `item_mods` VALUES (26875, 12, 24);
INSERT IGNORE INTO `item_mods` VALUES (26875, 13, 24);
INSERT IGNORE INTO `item_mods` VALUES (26875, 14, 24);
INSERT IGNORE INTO `item_mods` VALUES (26875, 384, 30);

-- 26887  shomonjijoe  (lvl 99, ilvl 119, bucket armor)
INSERT IGNORE INTO `item_mods` VALUES (26887, 1, 126);
INSERT IGNORE INTO `item_mods` VALUES (26887, 2, 50);
INSERT IGNORE INTO `item_mods` VALUES (26887, 4, 85);
INSERT IGNORE INTO `item_mods` VALUES (26887, 8, 21);
INSERT IGNORE INTO `item_mods` VALUES (26887, 9, 20);
INSERT IGNORE INTO `item_mods` VALUES (26887, 10, 21);
INSERT IGNORE INTO `item_mods` VALUES (26887, 11, 21);
INSERT IGNORE INTO `item_mods` VALUES (26887, 12, 29);
INSERT IGNORE INTO `item_mods` VALUES (26887, 13, 29);
INSERT IGNORE INTO `item_mods` VALUES (26887, 14, 29);
INSERT IGNORE INTO `item_mods` VALUES (26887, 384, 30);
INSERT IGNORE INTO `item_mods` VALUES (26887, 92, 13);

-- 26942  agony_jerkin  (lvl 99, ilvl 119, bucket armor)
INSERT IGNORE INTO `item_mods` VALUES (26942, 1, 135);
INSERT IGNORE INTO `item_mods` VALUES (26942, 2, 59);
INSERT IGNORE INTO `item_mods` VALUES (26942, 4, 44);
INSERT IGNORE INTO `item_mods` VALUES (26942, 8, 24);
INSERT IGNORE INTO `item_mods` VALUES (26942, 9, 35);
INSERT IGNORE INTO `item_mods` VALUES (26942, 10, 24);
INSERT IGNORE INTO `item_mods` VALUES (26942, 11, 28);
INSERT IGNORE INTO `item_mods` VALUES (26942, 12, 23);
INSERT IGNORE INTO `item_mods` VALUES (26942, 13, 23);
INSERT IGNORE INTO `item_mods` VALUES (26942, 14, 23);
INSERT IGNORE INTO `item_mods` VALUES (26942, 384, 40);

-- 26954  behemoth_suit  (lvl 1, ilvl 0, bucket armor)
INSERT IGNORE INTO `item_mods` VALUES (26954, 1, 1);

-- 27143  composers_mitts  (lvl 99, ilvl 119, bucket armor)
INSERT IGNORE INTO `item_mods` VALUES (27143, 1, 107);
INSERT IGNORE INTO `item_mods` VALUES (27143, 2, 27);
INSERT IGNORE INTO `item_mods` VALUES (27143, 8, 8);
INSERT IGNORE INTO `item_mods` VALUES (27143, 9, 32);
INSERT IGNORE INTO `item_mods` VALUES (27143, 10, 32);
INSERT IGNORE INTO `item_mods` VALUES (27143, 11, 7);
INSERT IGNORE INTO `item_mods` VALUES (27143, 12, 6);
INSERT IGNORE INTO `item_mods` VALUES (27143, 13, 23);
INSERT IGNORE INTO `item_mods` VALUES (27143, 14, 16);
INSERT IGNORE INTO `item_mods` VALUES (27143, 384, 40);

-- 27148  tatenashi_gote  (lvl 99, ilvl 119, bucket armor)
INSERT IGNORE INTO `item_mods` VALUES (27148, 1, 103);
INSERT IGNORE INTO `item_mods` VALUES (27148, 2, 27);
INSERT IGNORE INTO `item_mods` VALUES (27148, 8, 8);
INSERT IGNORE INTO `item_mods` VALUES (27148, 9, 39);
INSERT IGNORE INTO `item_mods` VALUES (27148, 10, 32);
INSERT IGNORE INTO `item_mods` VALUES (27148, 11, 7);
INSERT IGNORE INTO `item_mods` VALUES (27148, 12, 6);
INSERT IGNORE INTO `item_mods` VALUES (27148, 13, 23);
INSERT IGNORE INTO `item_mods` VALUES (27148, 14, 16);
INSERT IGNORE INTO `item_mods` VALUES (27148, 384, 40);

-- 27150  gazu_bracelets  (lvl 99, ilvl 119, bucket armor)
INSERT IGNORE INTO `item_mods` VALUES (27150, 1, 90);
INSERT IGNORE INTO `item_mods` VALUES (27150, 2, 27);
INSERT IGNORE INTO `item_mods` VALUES (27150, 8, 10);
INSERT IGNORE INTO `item_mods` VALUES (27150, 9, 32);
INSERT IGNORE INTO `item_mods` VALUES (27150, 10, 32);
INSERT IGNORE INTO `item_mods` VALUES (27150, 11, 6);
INSERT IGNORE INTO `item_mods` VALUES (27150, 12, 14);
INSERT IGNORE INTO `item_mods` VALUES (27150, 13, 29);
INSERT IGNORE INTO `item_mods` VALUES (27150, 14, 19);
INSERT IGNORE INTO `item_mods` VALUES (27150, 384, 50);

-- 27224  gefechtdiechlings  (lvl 99, ilvl 119, bucket armor)
INSERT IGNORE INTO `item_mods` VALUES (27224, 1, 125);
INSERT IGNORE INTO `item_mods` VALUES (27224, 2, 50);
INSERT IGNORE INTO `item_mods` VALUES (27224, 4, 30);
INSERT IGNORE INTO `item_mods` VALUES (27224, 8, 33);
INSERT IGNORE INTO `item_mods` VALUES (27224, 10, 24);
INSERT IGNORE INTO `item_mods` VALUES (27224, 11, 15);
INSERT IGNORE INTO `item_mods` VALUES (27224, 12, 26);
INSERT IGNORE INTO `item_mods` VALUES (27224, 13, 16);
INSERT IGNORE INTO `item_mods` VALUES (27224, 14, 12);
INSERT IGNORE INTO `item_mods` VALUES (27224, 384, 50);

-- 27225  wildheitdiechlings  (lvl 99, ilvl 119, bucket armor)
INSERT IGNORE INTO `item_mods` VALUES (27225, 1, 126);
INSERT IGNORE INTO `item_mods` VALUES (27225, 2, 50);
INSERT IGNORE INTO `item_mods` VALUES (27225, 4, 40);
INSERT IGNORE INTO `item_mods` VALUES (27225, 8, 33);
INSERT IGNORE INTO `item_mods` VALUES (27225, 10, 25);
INSERT IGNORE INTO `item_mods` VALUES (27225, 11, 15);
INSERT IGNORE INTO `item_mods` VALUES (27225, 12, 26);
INSERT IGNORE INTO `item_mods` VALUES (27225, 13, 16);
INSERT IGNORE INTO `item_mods` VALUES (27225, 14, 12);
INSERT IGNORE INTO `item_mods` VALUES (27225, 384, 50);

-- 27226  sombra_tights  (lvl 99, ilvl 119, bucket armor)
INSERT IGNORE INTO `item_mods` VALUES (27226, 1, 113);
INSERT IGNORE INTO `item_mods` VALUES (27226, 2, 77);
INSERT IGNORE INTO `item_mods` VALUES (27226, 4, 14);
INSERT IGNORE INTO `item_mods` VALUES (27226, 8, 28);
INSERT IGNORE INTO `item_mods` VALUES (27226, 9, 5);
INSERT IGNORE INTO `item_mods` VALUES (27226, 10, 15);
INSERT IGNORE INTO `item_mods` VALUES (27226, 11, 28);
INSERT IGNORE INTO `item_mods` VALUES (27226, 12, 30);
INSERT IGNORE INTO `item_mods` VALUES (27226, 13, 17);
INSERT IGNORE INTO `item_mods` VALUES (27226, 14, 11);
INSERT IGNORE INTO `item_mods` VALUES (27226, 384, 50);

-- 27409  hippomenes_socks  (lvl 99, ilvl 119, bucket armor)
INSERT IGNORE INTO `item_mods` VALUES (27409, 1, 65);
INSERT IGNORE INTO `item_mods` VALUES (27409, 2, 13);
INSERT IGNORE INTO `item_mods` VALUES (27409, 4, 14);
INSERT IGNORE INTO `item_mods` VALUES (27409, 8, 10);
INSERT IGNORE INTO `item_mods` VALUES (27409, 9, 11);
INSERT IGNORE INTO `item_mods` VALUES (27409, 10, 10);
INSERT IGNORE INTO `item_mods` VALUES (27409, 11, 33);
INSERT IGNORE INTO `item_mods` VALUES (27409, 12, 17);
INSERT IGNORE INTO `item_mods` VALUES (27409, 13, 19);
INSERT IGNORE INTO `item_mods` VALUES (27409, 14, 34);
INSERT IGNORE INTO `item_mods` VALUES (27409, 384, 40);

-- 27499  composers_sabots  (lvl 99, ilvl 119, bucket armor)
INSERT IGNORE INTO `item_mods` VALUES (27499, 1, 89);
INSERT IGNORE INTO `item_mods` VALUES (27499, 2, 15);
INSERT IGNORE INTO `item_mods` VALUES (27499, 8, 16);
INSERT IGNORE INTO `item_mods` VALUES (27499, 9, 19);
INSERT IGNORE INTO `item_mods` VALUES (27499, 10, 16);
INSERT IGNORE INTO `item_mods` VALUES (27499, 11, 25);
INSERT IGNORE INTO `item_mods` VALUES (27499, 13, 5);
INSERT IGNORE INTO `item_mods` VALUES (27499, 14, 19);
INSERT IGNORE INTO `item_mods` VALUES (27499, 384, 30);

-- 27508  unmoving_collar  (lvl 99, ilvl 0, bucket armor)
INSERT IGNORE INTO `item_mods` VALUES (27508, 1, 10);
INSERT IGNORE INTO `item_mods` VALUES (27508, 10, 8);
INSERT IGNORE INTO `item_mods` VALUES (27508, 14, 8);
INSERT IGNORE INTO `item_mods` VALUES (27508, 92, 9);

-- 27509  unmoving_collar_+1  (lvl 99, ilvl 0, bucket armor)
INSERT IGNORE INTO `item_mods` VALUES (27509, 1, 11);
INSERT IGNORE INTO `item_mods` VALUES (27509, 10, 9);
INSERT IGNORE INTO `item_mods` VALUES (27509, 14, 9);
INSERT IGNORE INTO `item_mods` VALUES (27509, 92, 10);

-- 27517  bathy_choker  (lvl 99, ilvl 0, bucket armor)
INSERT IGNORE INTO `item_mods` VALUES (27517, 1, 9);
INSERT IGNORE INTO `item_mods` VALUES (27517, 2, 30);

-- 27532  zwazo_earring  (lvl 99, ilvl 0, bucket armor)
INSERT IGNORE INTO `item_mods` VALUES (27532, 8, 1);

-- 27533  zwazo_earring_+1  (lvl 99, ilvl 0, bucket armor)
INSERT IGNORE INTO `item_mods` VALUES (27533, 8, 1);

-- 27542  dominance_earring  (lvl 99, ilvl 0, bucket armor)
INSERT IGNORE INTO `item_mods` VALUES (27542, 9, 3);

-- 27543  dominance_earring_+1  (lvl 99, ilvl 0, bucket armor)
INSERT IGNORE INTO `item_mods` VALUES (27543, 9, 4);

-- 27548  odnowa_earring  (lvl 99, ilvl 0, bucket armor)
INSERT IGNORE INTO `item_mods` VALUES (27548, 8, 2);
INSERT IGNORE INTO `item_mods` VALUES (27548, 10, 2);

-- 27558  mephitass_ring  (lvl 99, ilvl 0, bucket armor)
INSERT IGNORE INTO `item_mods` VALUES (27558, 1, 8);
INSERT IGNORE INTO `item_mods` VALUES (27558, 92, -3);

-- 27559  mephitass_ring_+1  (lvl 99, ilvl 0, bucket armor)
INSERT IGNORE INTO `item_mods` VALUES (27559, 1, 9);
INSERT IGNORE INTO `item_mods` VALUES (27559, 92, -3);

-- 27560  apeile_ring  (lvl 99, ilvl 0, bucket armor)
INSERT IGNORE INTO `item_mods` VALUES (27560, 92, 5);

-- 27561  apeile_ring_+1  (lvl 99, ilvl 0, bucket armor)
INSERT IGNORE INTO `item_mods` VALUES (27561, 92, 5);

-- 27596  mecistopins_mantle  (lvl 99, ilvl 0, bucket armor)
INSERT IGNORE INTO `item_mods` VALUES (27596, 1, 1);

-- 27601  grounded_mantle  (lvl 99, ilvl 0, bucket armor)
INSERT IGNORE INTO `item_mods` VALUES (27601, 1, 20);
INSERT IGNORE INTO `item_mods` VALUES (27601, 384, 10);
INSERT IGNORE INTO `item_mods` VALUES (27601, 9, 1);

-- 27602  grounded_mantle_+1  (lvl 99, ilvl 0, bucket armor)
INSERT IGNORE INTO `item_mods` VALUES (27602, 1, 21);
INSERT IGNORE INTO `item_mods` VALUES (27602, 384, 20);
INSERT IGNORE INTO `item_mods` VALUES (27602, 9, 1);

-- 27609  fi_follet_cape  (lvl 99, ilvl 0, bucket armor)
INSERT IGNORE INTO `item_mods` VALUES (27609, 4, 40);
INSERT IGNORE INTO `item_mods` VALUES (27609, 13, 1);

-- 27610  fi_follet_cape_+1  (lvl 99, ilvl 0, bucket armor)
INSERT IGNORE INTO `item_mods` VALUES (27610, 4, 45);
INSERT IGNORE INTO `item_mods` VALUES (27610, 13, 1);

-- 27619  aurists_cape  (lvl 99, ilvl 0, bucket armor)
INSERT IGNORE INTO `item_mods` VALUES (27619, 1, 16);
INSERT IGNORE INTO `item_mods` VALUES (27619, 4, 40);
INSERT IGNORE INTO `item_mods` VALUES (27619, 12, 7);
INSERT IGNORE INTO `item_mods` VALUES (27619, 13, 7);

-- 27621  relucent_cape  (lvl 99, ilvl 0, bucket armor)
INSERT IGNORE INTO `item_mods` VALUES (27621, 1, 20);

-- 27636  evalach  (lvl 99, ilvl 119, bucket shield)
INSERT IGNORE INTO `item_mods` VALUES (27636, 1, 100);
INSERT IGNORE INTO `item_mods` VALUES (27636, 2, 22);
INSERT IGNORE INTO `item_mods` VALUES (27636, 4, 29);
INSERT IGNORE INTO `item_mods` VALUES (27636, 92, 5);

-- 27638  ajax  (lvl 99, ilvl 119, bucket shield)
INSERT IGNORE INTO `item_mods` VALUES (27638, 1, 120);
INSERT IGNORE INTO `item_mods` VALUES (27638, 92, 10);
INSERT IGNORE INTO `item_mods` VALUES (27638, 2, 70);

-- 27639  ajax_+1  (lvl 99, ilvl 119, bucket shield)
INSERT IGNORE INTO `item_mods` VALUES (27639, 1, 122);
INSERT IGNORE INTO `item_mods` VALUES (27639, 92, 11);
INSERT IGNORE INTO `item_mods` VALUES (27639, 2, 70);

-- 27640  deliverance  (lvl 99, ilvl 119, bucket shield)
INSERT IGNORE INTO `item_mods` VALUES (27640, 1, 114);
INSERT IGNORE INTO `item_mods` VALUES (27640, 2, 22);
INSERT IGNORE INTO `item_mods` VALUES (27640, 4, 29);

-- 27641  deliverance_+1  (lvl 99, ilvl 119, bucket shield)
INSERT IGNORE INTO `item_mods` VALUES (27641, 1, 116);
INSERT IGNORE INTO `item_mods` VALUES (27641, 2, 22);
INSERT IGNORE INTO `item_mods` VALUES (27641, 4, 29);

-- 27737  kaabnax_hat  (lvl 99, ilvl 115, bucket armor)
INSERT IGNORE INTO `item_mods` VALUES (27737, 1, 84);
INSERT IGNORE INTO `item_mods` VALUES (27737, 2, 28);
INSERT IGNORE INTO `item_mods` VALUES (27737, 4, 75);
INSERT IGNORE INTO `item_mods` VALUES (27737, 8, 16);
INSERT IGNORE INTO `item_mods` VALUES (27737, 9, 16);
INSERT IGNORE INTO `item_mods` VALUES (27737, 10, 16);
INSERT IGNORE INTO `item_mods` VALUES (27737, 11, 16);
INSERT IGNORE INTO `item_mods` VALUES (27737, 12, 26);
INSERT IGNORE INTO `item_mods` VALUES (27737, 13, 26);
INSERT IGNORE INTO `item_mods` VALUES (27737, 14, 26);
INSERT IGNORE INTO `item_mods` VALUES (27737, 384, 50);

-- 27738  ejekamal_mask  (lvl 99, ilvl 115, bucket armor)
INSERT IGNORE INTO `item_mods` VALUES (27738, 1, 90);
INSERT IGNORE INTO `item_mods` VALUES (27738, 2, 30);
INSERT IGNORE INTO `item_mods` VALUES (27738, 4, 22);
INSERT IGNORE INTO `item_mods` VALUES (27738, 8, 24);
INSERT IGNORE INTO `item_mods` VALUES (27738, 9, 18);
INSERT IGNORE INTO `item_mods` VALUES (27738, 10, 20);
INSERT IGNORE INTO `item_mods` VALUES (27738, 11, 21);
INSERT IGNORE INTO `item_mods` VALUES (27738, 12, 17);
INSERT IGNORE INTO `item_mods` VALUES (27738, 13, 20);
INSERT IGNORE INTO `item_mods` VALUES (27738, 14, 17);
INSERT IGNORE INTO `item_mods` VALUES (27738, 384, 90);

-- 27778  bokwus_circlet  (lvl 99, ilvl 110, bucket armor)
INSERT IGNORE INTO `item_mods` VALUES (27778, 1, 68);
INSERT IGNORE INTO `item_mods` VALUES (27778, 2, 19);
INSERT IGNORE INTO `item_mods` VALUES (27778, 4, 70);
INSERT IGNORE INTO `item_mods` VALUES (27778, 8, 9);
INSERT IGNORE INTO `item_mods` VALUES (27778, 9, 9);
INSERT IGNORE INTO `item_mods` VALUES (27778, 10, 9);
INSERT IGNORE INTO `item_mods` VALUES (27778, 11, 9);
INSERT IGNORE INTO `item_mods` VALUES (27778, 12, 13);
INSERT IGNORE INTO `item_mods` VALUES (27778, 13, 13);
INSERT IGNORE INTO `item_mods` VALUES (27778, 14, 13);

-- 27854  mandragora_suit  (lvl 1, ilvl 0, bucket armor)
INSERT IGNORE INTO `item_mods` VALUES (27854, 1, 1);

-- 27866  goblin_suit  (lvl 1, ilvl 0, bucket armor)
INSERT IGNORE INTO `item_mods` VALUES (27866, 1, 1);

-- 27989  sombra_mittens  (lvl 99, ilvl 119, bucket armor)
INSERT IGNORE INTO `item_mods` VALUES (27989, 1, 89);
INSERT IGNORE INTO `item_mods` VALUES (27989, 2, 25);
INSERT IGNORE INTO `item_mods` VALUES (27989, 4, 28);
INSERT IGNORE INTO `item_mods` VALUES (27989, 8, 7);
INSERT IGNORE INTO `item_mods` VALUES (27989, 9, 35);
INSERT IGNORE INTO `item_mods` VALUES (27989, 10, 26);
INSERT IGNORE INTO `item_mods` VALUES (27989, 11, 12);
INSERT IGNORE INTO `item_mods` VALUES (27989, 12, 16);
INSERT IGNORE INTO `item_mods` VALUES (27989, 13, 30);
INSERT IGNORE INTO `item_mods` VALUES (27989, 14, 17);
INSERT IGNORE INTO `item_mods` VALUES (27989, 384, 40);

-- 27993  macabre_gauntlets  (lvl 99, ilvl 119, bucket armor)
INSERT IGNORE INTO `item_mods` VALUES (27993, 1, 101);
INSERT IGNORE INTO `item_mods` VALUES (27993, 2, 29);
INSERT IGNORE INTO `item_mods` VALUES (27993, 8, 10);
INSERT IGNORE INTO `item_mods` VALUES (27993, 9, 29);
INSERT IGNORE INTO `item_mods` VALUES (27993, 10, 33);
INSERT IGNORE INTO `item_mods` VALUES (27993, 12, 8);
INSERT IGNORE INTO `item_mods` VALUES (27993, 13, 25);
INSERT IGNORE INTO `item_mods` VALUES (27993, 14, 19);
INSERT IGNORE INTO `item_mods` VALUES (27993, 384, 40);
INSERT IGNORE INTO `item_mods` VALUES (27993, 92, 6);

-- 27995  shigure_tekko  (lvl 99, ilvl 119, bucket armor)
INSERT IGNORE INTO `item_mods` VALUES (27995, 1, 88);
INSERT IGNORE INTO `item_mods` VALUES (27995, 2, 25);
INSERT IGNORE INTO `item_mods` VALUES (27995, 8, 10);
INSERT IGNORE INTO `item_mods` VALUES (27995, 9, 34);
INSERT IGNORE INTO `item_mods` VALUES (27995, 10, 28);
INSERT IGNORE INTO `item_mods` VALUES (27995, 11, 6);
INSERT IGNORE INTO `item_mods` VALUES (27995, 12, 10);
INSERT IGNORE INTO `item_mods` VALUES (27995, 13, 28);
INSERT IGNORE INTO `item_mods` VALUES (27995, 14, 16);
INSERT IGNORE INTO `item_mods` VALUES (27995, 384, 50);

-- 28026  aiwon_gauntlets  (lvl 99, ilvl 107, bucket armor)
INSERT IGNORE INTO `item_mods` VALUES (28026, 1, 66);
INSERT IGNORE INTO `item_mods` VALUES (28026, 2, 10);
INSERT IGNORE INTO `item_mods` VALUES (28026, 8, 5);
INSERT IGNORE INTO `item_mods` VALUES (28026, 9, 16);
INSERT IGNORE INTO `item_mods` VALUES (28026, 10, 18);
INSERT IGNORE INTO `item_mods` VALUES (28026, 12, 5);
INSERT IGNORE INTO `item_mods` VALUES (28026, 13, 14);
INSERT IGNORE INTO `item_mods` VALUES (28026, 14, 10);
INSERT IGNORE INTO `item_mods` VALUES (28026, 384, 30);

-- 28028  otomi_gloves  (lvl 99, ilvl 115, bucket armor)
INSERT IGNORE INTO `item_mods` VALUES (28028, 1, 58);
INSERT IGNORE INTO `item_mods` VALUES (28028, 2, 18);
INSERT IGNORE INTO `item_mods` VALUES (28028, 4, 72);
INSERT IGNORE INTO `item_mods` VALUES (28028, 8, 5);
INSERT IGNORE INTO `item_mods` VALUES (28028, 9, 24);
INSERT IGNORE INTO `item_mods` VALUES (28028, 10, 22);
INSERT IGNORE INTO `item_mods` VALUES (28028, 11, 4);
INSERT IGNORE INTO `item_mods` VALUES (28028, 12, 16);
INSERT IGNORE INTO `item_mods` VALUES (28028, 13, 28);
INSERT IGNORE INTO `item_mods` VALUES (28028, 14, 16);
INSERT IGNORE INTO `item_mods` VALUES (28028, 92, -5);
INSERT IGNORE INTO `item_mods` VALUES (28028, 384, 30);

-- 28134  assiduity_pants  (lvl 99, ilvl 119, bucket armor)
INSERT IGNORE INTO `item_mods` VALUES (28134, 1, 104);
INSERT IGNORE INTO `item_mods` VALUES (28134, 2, 43);
INSERT IGNORE INTO `item_mods` VALUES (28134, 4, 29);
INSERT IGNORE INTO `item_mods` VALUES (28134, 8, 25);
INSERT IGNORE INTO `item_mods` VALUES (28134, 10, 12);
INSERT IGNORE INTO `item_mods` VALUES (28134, 11, 17);
INSERT IGNORE INTO `item_mods` VALUES (28134, 12, 36);
INSERT IGNORE INTO `item_mods` VALUES (28134, 13, 26);
INSERT IGNORE INTO `item_mods` VALUES (28134, 14, 19);
INSERT IGNORE INTO `item_mods` VALUES (28134, 384, 50);
INSERT IGNORE INTO `item_mods` VALUES (28134, 92, -5);

-- 28136  augury_cuisses  (lvl 99, ilvl 119, bucket armor)
INSERT IGNORE INTO `item_mods` VALUES (28136, 1, 123);
INSERT IGNORE INTO `item_mods` VALUES (28136, 2, 50);
INSERT IGNORE INTO `item_mods` VALUES (28136, 8, 30);
INSERT IGNORE INTO `item_mods` VALUES (28136, 10, 17);
INSERT IGNORE INTO `item_mods` VALUES (28136, 11, 17);
INSERT IGNORE INTO `item_mods` VALUES (28136, 12, 33);
INSERT IGNORE INTO `item_mods` VALUES (28136, 13, 20);
INSERT IGNORE INTO `item_mods` VALUES (28136, 14, 16);
INSERT IGNORE INTO `item_mods` VALUES (28136, 384, 60);

-- 28167  kaabnax_trousers  (lvl 99, ilvl 115, bucket armor)
INSERT IGNORE INTO `item_mods` VALUES (28167, 1, 100);
INSERT IGNORE INTO `item_mods` VALUES (28167, 2, 37);
INSERT IGNORE INTO `item_mods` VALUES (28167, 8, 25);
INSERT IGNORE INTO `item_mods` VALUES (28167, 10, 14);
INSERT IGNORE INTO `item_mods` VALUES (28167, 11, 22);
INSERT IGNORE INTO `item_mods` VALUES (28167, 12, 26);
INSERT IGNORE INTO `item_mods` VALUES (28167, 13, 15);
INSERT IGNORE INTO `item_mods` VALUES (28167, 14, 9);
INSERT IGNORE INTO `item_mods` VALUES (28167, 384, 70);

-- 28432  ukko_sash  (lvl 99, ilvl 0, bucket armor)
INSERT IGNORE INTO `item_mods` VALUES (28432, 384, 50);

-- 28481  lugra_earring  (lvl 99, ilvl 0, bucket armor)
INSERT IGNORE INTO `item_mods` VALUES (28481, 8, 7);
INSERT IGNORE INTO `item_mods` VALUES (28481, 9, 7);
INSERT IGNORE INTO `item_mods` VALUES (28481, 10, 7);
INSERT IGNORE INTO `item_mods` VALUES (28481, 12, 7);

-- 28482  lugra_earring_+1  (lvl 99, ilvl 0, bucket armor)
INSERT IGNORE INTO `item_mods` VALUES (28482, 8, 8);
INSERT IGNORE INTO `item_mods` VALUES (28482, 9, 8);
INSERT IGNORE INTO `item_mods` VALUES (28482, 10, 8);
INSERT IGNORE INTO `item_mods` VALUES (28482, 12, 8);
