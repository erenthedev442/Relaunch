# NPC Disable Audit — review list

_Generated 2026-06-13 03:17 UTC. **Disables nothing** — this is a candidate list to review. The eventual mechanism is `status=2` (DISAPPEAR): reversible, and the entity still loads so nothing nil-crashes._

## Summary

- **31,047 NPCs** total; **10,699 already hidden** (status=2); 0 in unmapped/system zones (skipped).
- Of the visible, scripted NPCs: **2,108 functional** (keep), **1,049 flavor candidates**, **483 cutscene (review)**.
- **16,392 scenery** NPCs (no script) — left alone here; hiding the ambient crowd would make zones look dead.
- **316 doors / lamps / ??? markers / furniture** — excluded from the candidate list (infrastructure & puzzle pieces, not townsfolk).

**Legend:** `[ref]` = this NPC is referenced by a `GetNPCByID(...)` call somewhere (usually harmless under status=2, but eyeball it). Cutscene NPCs are listed separately per zone because hiding one *could* block a mission step.

## Candidates by zone (most flavor-clutter first)

### Port Windurst  (240)
_33 flavor candidate(s) · 30 functional kept · 142 scenery · 58 already hidden_

| npcid | NPC | |
|---:|---|---|
| 17760320 | Alizabe  `Alizabe` |  |
| 17760312 | Aroro  `Aroro` |  |
| 17760306 | Babubu  `Babubu` |  |
| 17760305 | Degong  `Degong` |  |
| 17760405 | Drozga  `Drozga` |  |
| 17760304 | Erabu-Fumulubu  `Erabu-Fumulubu` |  |
| 17760464 | Fabricius  `Fabricius` |  |
| 17760315 | Guruna-Maguruna  `Guruna-Maguruna` |  |
| 17760313 | Hohbiba-Mubiba  `Hohbiba-Mubiba` |  |
| 17760456 | Hunt Registry  `Hunt_Registry` |  |
| 17760323 | Khel Pahlhama  `Khel_Pahlhama` |  |
| 17760438 | Kucha Malkobhi  `Kucha_Malkobhi` |  |
| 17760316 | Kumama  `Kumama` |  |
| 17760311 | Kususu  `Kususu` |  |
| 17760435 | Lebondur  `Lebondur` |  |
| 17760352 | Machichi  `Machichi` |  |
| 17760321 | Mhoji Roccoruh  `Mhoji_Roccoruh` |  |
| 17760277 | Mojo-Pojo  `Mojo-Pojo` |  |
| 17760356 | Mosusu  `Mosusu` |  |
| 17760369 | Mov Lingyoh  `Mov_Lingyoh` |  |
| 17760285 | Noragu-Meragu  `Noragu-Meragu` |  |
| 17760303 | Panja-Nanja  `Panja-Nanja` |  |
| 17760317 | Posso Ruhbini  `Posso_Ruhbini` |  |
| 17760286 | Rachuchu  `Rachuchu` |  |
| 17760361 | Reiso-Haroiso  `Reiso-Haroiso` |  |
| 17760404 | Ryan  `Ryan` |  |
| 17760436 | Sattsuh Ahkanpari  `Sattsuh_Ahkanpari` |  |
| 17760391 | Seven of Clubs  `Seven_of_Clubs` |  |
| 17760318 | Sheia Pohrichamaha  `Sheia_Pohrichamaha` |  |
| 17760411 | Symphonic Curator  `Symphonic_Curator` |  |
| 17760314 | Taniko-Maniko  `Taniko-Maniko` |  |
| 17760337 | Uli Pehkowa  `Uli_Pehkowa` |  |
| 17760319 | Zoreen  `Zoreen` |  |

<details><summary>↳ 11 cutscene NPC(s) — review (possible mission steps)</summary>

A.M.A.N. Liaison, Choyi Totlihpa, Five of Clubs, Goltata, Janshura-Rashura, Kameel, Kunchichi, Martin, Three of Clubs, Tohopka, Yaman-Hachuman

</details>

### Windurst Woods  (241)
_33 flavor candidate(s) · 46 functional kept · 252 scenery · 121 already hidden_

| npcid | NPC | |
|---:|---|---|
| 17764828 | A.M.A.N. Validator  `AMAN_Validator` |  |
| 17764395 | Anillah  `Anillah` |  |
| 17764601 | Artisan Moogle  `Artisan_Moogle` |  |
| 17764461 | Bin Stejihna  `Bin_Stejihna` |  |
| 17764496 | Dazi Nosuk  `Dazi_Nosuk` |  |
| 17764483 | Dhahah  `Dhahah` |  |
| 17764481 | Dhahih  `Dhahih` |  |
| 17764482 | Dhakih  `Dhakih` |  |
| 17764484 | Dhakoh  `Dhakoh` |  |
| 17764518 | Eight of Spades  `Eight_of_Spades` |  |
| 17764449 | Ju Kamja  `Ju_Kamja` |  |
| 17764401 | Kuzah Hpirohpon  `Kuzah_Hpirohpon` |  |
| 17764405 | Kyaa Taali  `Kyaa_Taali` |  |
| 17764403 | Lih Pituu  `Lih_Pituu` |  |
| 17764456 | Manyny  `Manyny` |  |
| 17764400 | Meriri  `Meriri` |  |
| 17764455 | Mono Nchaa  `Mono_Nchaa` |  |
| 17764396 | Nikkoko  `Nikkoko` |  |
| 17764460 | Nya Labiccio  `Nya_Labiccio` |  |
| 17764487 | Orahi-Karapahi  `Orahi-Karapahi` |  |
| 17764500 | Patsaa Maehoc  `Patsaa_Maehoc` |  |
| 17764463 | Pehki Machumaht  `Pehki_Machumaht` |  |
| 17764448 | Pew Sahbaraef  `Pew_Sahbaraef` |  |
| 17764407 | Retto-Marutto  `Retto-Marutto` |  |
| 17764404 | Ronana  `Ronana` |  |
| 17764600 | Selele  `Selele` |  |
| 17764492 | Seno Zarhin  `Seno_Zarhin` |  |
| 17764406 | Shih Tayuun  `Shih_Tayuun` |  |
| 17764549 | Symphonic Curator  `Symphonic_Curator` |  |
| 17764608 | Teldro-Kesdrodo  `Teldro-Kesdrodo` |  |
| 17764394 | Terude-Harude  `Terude-Harude` |  |
| 17764459 | Wije Tiren  `Wije_Tiren` |  |
| 17764609 | Yonolala  `Yonolala` |  |

<details><summary>↳ 18 cutscene NPC(s) — review (possible mission steps)</summary>

A.M.A.N. Liaison, Boizo-Naizo, Cayu Pensharhumi, Erpolant, Etsa Rhuyuli, Forine, Gottah Maporushanoh, Kopua-Mobua A.M.A.N., Matata, Mheca Khetashipah, Rakoh Buuma, Spare Five, Spare Four, Spare One, Spare Three, Spare Two, Sunana, Wani Casdohry

</details>

### Southern San dOria  (230)
_30 flavor candidate(s) · 55 functional kept · 395 scenery · 156 already hidden_

| npcid | NPC | |
|---:|---|---|
| 17720032 | A.M.A.N. Validator  `AMAN_Validator` |  |
| 17719618 | Alaune  `Alaune` |  |
| 17719633 | Artisan Moogle  `Artisan_Moogle` |  |
| 17719599 | Arvilauge  `Arvilauge` |  |
| 17719354 | Ashene  `Ashene` |  |
| 17719318 | Aveline  `Aveline` |  |
| 17719317 | Benaige  `Benaige` |  |
| 17719352 | Capucine  `Capucine` |  |
| 17719388 | Carautia  `Carautia` |  |
| 17719419 | Clainomille  `Clainomille` |  |
| 17719328 | Glenne  `Glenne` |  |
| 17719384 | Kueh Igunahmori  `Kueh_Igunahmori` |  |
| 17719408 | Lanqueron  `Lanqueron` |  |
| 17719350 | Lusiane  `Lusiane` | `[ref]` |
| 17719387 | Miogique  `Miogique` |  |
| 17719498 | Moozo-Koozo  `Moozo-Koozo` |  |
| 17719380 | Orechiniel  `Orechiniel` |  |
| 17719351 | Ostalie  `Ostalie` |  |
| 17719488 | Paunelie  `Paunelie` |  |
| 17719321 | Shilah  `Shilah` |  |
| 17719442 | Symphonic Curator  `Symphonic_Curator` |  |
| 17719382 | Tek Lengyon  `Tek_Lengyon` |  |
| 17719613 | Tek Lengyon  `Tek_Lengyon` |  |
| 17719616 | Tek Lengyon  `Tek_Lengyon` |  |
| 17719355 | Thadiene  `Thadiene` |  |
| 17719536 | Trail Markings  `Trail_Markings` |  |
| 17719643 | Urbiolaine  `Urbiolaine` |  |
| 17719410 | Vaquelage  `Vaquelage` |  |
| 17719389 | Victoire  `Victoire` |  |
| 17719307 | Violitte  `Violitte` |  |

<details><summary>↳ 16 cutscene NPC(s) — review (possible mission steps)</summary>

A.M.A.N. Liaison, Authere, Balasiel, Celyddon, Chanpau, Daggao, Deraquien, Diary, Femitte, Najjar, Namonutice, Poudoruchant, Rouva, Sharzalion, Ullasa

</details>

### Bastok Markets  (235)
_29 flavor candidate(s) · 28 functional kept · 121 scenery · 172 already hidden_

| npcid | NPC | |
|---:|---|---|
| 17740226 | A.M.A.N. Validator  `AMAN_Validator` |  |
| 17739947 | Artisan Moogle  `Artisan_Moogle` |  |
| 17739803 | Balthilda  `Balthilda` |  |
| 17739797 | Belizieg  `Belizieg` |  |
| 17739801 | Brunhilde  `Brunhilde` |  |
| 17739810 | Carmelide  `Carmelide` |  |
| 17739799 | Ciqala  `Ciqala` |  |
| 17739791 | Fatimah  `Fatimah` |  |
| 17739939 | Gulldago  `Gulldago` |  |
| 17739808 | Harmodios  `Harmodios` |  |
| 17739812 | Hortense  `Hortense` |  |
| 17739958 | Igsli  `Igsli` |  |
| 17739824 | Karine  `Karine` |  |
| 17739796 | Khonzon  `Khonzon` |  |
| 17739804 | Mjoll  `Mjoll` |  |
| 17739819 | Oggodett  `Oggodett` |  |
| 17739800 | Peritrage  `Peritrage` |  |
| 17739811 | Raghd  `Raghd` |  |
| 17739822 | Somn-Paemn  `Somn-Paemn` |  |
| 17739807 | Sororo  `Sororo` |  |
| 17739878 | Symphonic Curator  `Symphonic_Curator` |  |
| 17739788 | Teerth  `Teerth` |  |
| 17739793 | Ulrike  `Ulrike` |  |
| 17739789 | Visala  `Visala` |  |
| 17739792 | Wulfnoth  `Wulfnoth` |  |
| 17739823 | Yafafa  `Yafafa` |  |
| 17739806 | Zaira  `Zaira` |  |
| 17739798 | Zhikkom  `Zhikkom` |  |
| 17739841 | Zon-Fobun  `Zon-Fobun` |  |

<details><summary>↳ 5 cutscene NPC(s) — review (possible mission steps)</summary>

A.M.A.N. Liaison, Ardea, Cleades, Lamepaue, Rothais

</details>

### Aht Urhgan Whitegate  (50)
_28 flavor candidate(s) · 41 functional kept · 359 scenery · 191 already hidden_

| npcid | NPC | |
|---:|---|---|
| 16982457 | Asrahd  `Asrahd` |  |
| 16982097 | Bajahb  `Bajahb` |  |
| 16982041 | Baya Hiramayuh  `Baya_Hiramayuh` |  |
| 16982093 | Dwago  `Dwago` |  |
| 16982099 | Fayeewah  `Fayeewah` |  |
| 16982102 | Gathweeda  `Gathweeda` |  |
| 16982088 | Gavrie  `Gavrie` |  |
| 16982120 | Hadayah  `Hadayah` |  |
| 16982096 | Hagakoff  `Hagakoff` |  |
| 16982148 | Hashayra  `Hashayra` |  |
| 16982607 | Hunt Registry  `Hunt_Registry` |  |
| 16982151 | Kazween  `Kazween` |  |
| 16982095 | Khaf Jhifanm  `Khaf_Jhifanm` |  |
| 16982123 | Koyol-Futenol  `Koyol-Futenol` |  |
| 16982040 | Kuhn Tsahnpri  `Kuhn_Tsahnpri` |  |
| 16982094 | Kulh Amariyo  `Kulh_Amariyo` |  |
| 16982089 | Malfud  `Malfud` |  |
| 16982152 | Mariyaam  `Mariyaam` |  |
| 16982098 | Mazween  `Mazween` |  |
| 16982091 | Mulnith  `Mulnith` |  |
| 16982087 | Riyadahf  `Riyadahf` |  |
| 16982090 | Rubahah  `Rubahah` |  |
| 16982092 | Saluhwa  `Saluhwa` |  |
| 16982121 | Shahau  `Shahau` |  |
| 16982053 | Symphonic Curator  `Symphonic_Curator` |  |
| 16982101 | Wahnid  `Wahnid` |  |
| 16982103 | Wahraga  `Wahraga` |  |
| 16982100 | Yafaaf  `Yafaaf` |  |

<details><summary>↳ 10 cutscene NPC(s) — review (possible mission steps)</summary>

Abda-Lurabda, Abquhbah, Burnished Bones, Esoteric Hound, Furious Boulder, Ghanraam, Jarafah, Somnolent Rooster, _(unnamed)_ `_1ee`

</details>

### The Shrine of RuAvitau  (178)
_27 flavor candidate(s) · 4 functional kept · 71 scenery · 43 already hidden_

| npcid | NPC | |
|---:|---|---|
| 17506827 | Grounds Tome  `Grounds_Tome` |  |
| 17506828 | Grounds Tome  `Grounds_Tome` |  |
| 17506829 | Grounds Tome  `Grounds_Tome` |  |
| 17506830 | Grounds Tome  `Grounds_Tome` |  |
| 17506831 | Grounds Tome  `Grounds_Tome` |  |
| 17506832 | Grounds Tome  `Grounds_Tome` |  |
| 17506833 | Grounds Tome  `Grounds_Tome` |  |
| 17506742 | Monolith  `Monolith` |  |
| 17506744 | Monolith  `Monolith` |  |
| 17506746 | Monolith  `Monolith` |  |
| 17506748 | Monolith  `Monolith` |  |
| 17506750 | Monolith  `Monolith` |  |
| 17506752 | Monolith  `Monolith` |  |
| 17506754 | Monolith  `Monolith` |  |
| 17506756 | Monolith  `Monolith` |  |
| 17506758 | Monolith  `Monolith` |  |
| 17506760 | Monolith  `Monolith` |  |
| 17506762 | Monolith  `Monolith` |  |
| 17506764 | Monolith  `Monolith` |  |
| 17506766 | Monolith  `Monolith` |  |
| 17506768 | Monolith  `Monolith` |  |
| 17506770 | Monolith  `Monolith` |  |
| 17506772 | Monolith  `Monolith` |  |
| 17506774 | Monolith  `Monolith` |  |
| 17506776 | Monolith  `Monolith` |  |
| 17506778 | Monolith  `Monolith` |  |
| 17506780 | Monolith  `Monolith` |  |

### Port Bastok  (236)
_26 flavor candidate(s) · 25 functional kept · 161 scenery · 116 already hidden_

| npcid | NPC | |
|---:|---|---|
| 17744032 | Bagnobrok  `Bagnobrok` |  |
| 17743908 | Belka  `Belka` |  |
| 17744007 | Blabbivix  `Blabbivix` |  |
| 17743969 | Cheh Raihah  `Cheh_Raihah` |  |
| 17743967 | Dahjal  `Dahjal` |  |
| 17743975 | Denvihr  `Denvihr` |  |
| 17744006 | Dhen Tevryukoh  `Dhen_Tevryukoh` |  |
| 17744055 | Erich  `Erich` |  |
| 17743898 | Evelyn  `Evelyn` |  |
| 17743906 | Galvin  `Galvin` |  |
| 17744185 | Greeter Moogle  `Greeter_Moogle` |  |
| 17743936 | Hilda  `Hilda` |  |
| 17743974 | Ilita  `Ilita` |  |
| 17743888 | Melloa  `Melloa` |  |
| 17743968 | Mokop-Sankop  `Mokop-Sankop` |  |
| 17743970 | Nalta  `Nalta` |  |
| 17743907 | Numa  `Numa` |  |
| 17743899 | Rex  `Rex` |  |
| 17743933 | Rosswald  `Rosswald` |  |
| 17743887 | Sawyer  `Sawyer` |  |
| 17743994 | Styi Palneh  `Styi_Palneh` |  |
| 17743976 | Sugandhi  `Sugandhi` |  |
| 17743983 | Symphonic Curator  `Symphonic_Curator` |  |
| 17743966 | Valeriano  `Valeriano` |  |
| 17743923 | Vattian  `Vattian` |  |
| 17744005 | Zoby Quhyo  `Zoby_Quhyo` |  |

<details><summary>↳ 13 cutscene NPC(s) — review (possible mission steps)</summary>

A.M.A.N. Liaison, Argus, Benita, Bodaway, Brita, Bruno, Dalba, Ensetsu, Flaco, Gallagher, Kachada, Kagetora, _(unnamed)_ `_6kt`

</details>

### Windurst Waters  (238)
_25 flavor candidate(s) · 35 functional kept · 235 scenery · 154 already hidden_

| npcid | NPC | |
|---:|---|---|
| 17752104 | Baehu-Faehu  `Baehu-Faehu` |  |
| 17752196 | Caliburn  `Caliburn` |  |
| 17752140 | Chomo Jinjahl  `Chomo_Jinjahl` |  |
| 17752105 | Fomina  `Fomina` |  |
| 17752137 | Hakeem  `Hakeem` |  |
| 17752096 | Hilkomu-Makimu  `Hilkomu-Makimu` |  |
| 17752174 | Hororo  `Hororo` |  |
| 17752136 | Jacodaut  `Jacodaut` |  |
| 17752171 | Janta-Jonta  `Janta-Jonta` |  |
| 17752107 | Jourille  `Jourille` |  |
| 17752135 | Kipo-Opo  `Kipo-Opo` |  |
| 17752141 | Kopopo  `Kopopo` |  |
| 17752201 | Kyokyo  `Kyokyo` |  |
| 17752094 | Orez-Ebrez  `Orez-Ebrez` |  |
| 17752106 | Otete  `Otete` |  |
| 17752200 | Pia  `Pia` |  |
| 17752108 | Prestapiq  `Prestapiq` |  |
| 17752172 | Rabiri-Tabiri  `Rabiri-Tabiri` |  |
| 17752186 | Ramasese  `Ramasese` |  |
| 17752202 | Shasha  `Shasha` |  |
| 17752187 | Shataru-Potaru  `Shataru-Potaru` |  |
| 17752095 | Shohrun-Tuhrun  `Shohrun-Tuhrun` |  |
| 17752229 | Symphonic Curator  `Symphonic_Curator` |  |
| 17752100 | Taajiji  `Taajiji` |  |
| 17752169 | Yohra-Ora  `Yohra-Ora` |  |

<details><summary>↳ 17 cutscene NPC(s) — review (possible mission steps)</summary>

A.M.A.N. Liaison, Amagusa-Chigurusa, Angelica, Aramu-Paramu, Buchi Kohmrijah, Five of Hearts, Fuepepe, Funpo-Shipo, Furakku-Norakku, Lago-Charago, Mokyokyo, Moreno-Toeno, Npopo, Olaky-Yayulaky, Yuli Yaam, Yung Yaam, Zabirego-Hajigo

</details>

### Northern San dOria  (231)
_23 flavor candidate(s) · 39 functional kept · 214 scenery · 147 already hidden_

| npcid | NPC | |
|---:|---|---|
| 17723429 | Amarefice  `Amarefice` |  |
| 17723587 | Arachagnon  `Arachagnon` |  |
| 17723446 | Arlenne  `Arlenne` |  |
| 17723438 | Beadurinc  `Beadurinc` |  |
| 17723431 | Cauzeriste  `Cauzeriste` |  |
| 17723432 | Chaupire  `Chaupire` |  |
| 17723439 | Doggomehr  `Doggomehr` |  |
| 17723403 | Elesca  `Elesca` |  |
| 17723493 | Eugballion  `Eugballion` |  |
| 17723553 | Gaudylox  `Gaudylox` |  |
| 17723436 | Greubaque  `Greubaque` |  |
| 17723658 | Hunt Registry  `Hunt_Registry` |  |
| 17723485 | Justi  `Justi` |  |
| 17723440 | Lucretia  `Lucretia` |  |
| 17723498 | Millechuca  `Millechuca` |  |
| 17723491 | Palguevion  `Palguevion` |  |
| 17723437 | Pinok-Morok  `Pinok-Morok` |  |
| 17723486 | Pirvidiauce  `Pirvidiauce` |  |
| 17723430 | Ramua  `Ramua` |  |
| 17723647 | Ramua  `Ramua` |  |
| 17723535 | Symphonic Curator  `Symphonic_Curator` |  |
| 17723447 | Tavourine  `Tavourine` |  |
| 17723428 | Ulycille  `Ulycille` |  |

<details><summary>↳ 23 cutscene NPC(s) — review (possible mission steps)</summary>

A.M.A.N. Liaison, Anilla, Baraka, Beriphaule, Bertenont, Commojourt, Durogg, Emeige A.M.A.N., Giaunne, Heruze-Moruze, Lotine, Madaline, Maloquedil, Morjean, Nonterene, Phairupegiont, Pulloie, Shomo Pochachilo, Telmoda, Wooden Shutter

</details>

### Lower Jeuno  (245)
_23 flavor candidate(s) · 27 functional kept · 148 scenery · 64 already hidden_

| npcid | NPC | |
|---:|---|---|
| 17780854 | _(unnamed)_ `rarabcaged` |  |
| 17780855 | _(unnamed)_ `rarabcaged` |  |
| 17780861 | Adelflete  `Adelflete` |  |
| 17780943 | Chatnachoq  `Chatnachoq` |  |
| 17780865 | Chenokih  `Chenokih` |  |
| 17780864 | Chetak  `Chetak` |  |
| 17780859 | Creepstix  `Creepstix` |  |
| 17780742 | Ghebi Damomohe  `Ghebi_Damomohe` |  |
| 17780946 | Goldagrik  `Goldagrik` |  |
| 17780866 | Hasim  `Hasim` |  |
| 17780863 | Matoaka  `Matoaka` |  |
| 17780846 | Mesukiki  `Mesukiki` |  |
| 17780862 | Morefie  `Morefie` |  |
| 17780785 | Nakho Jawantal  `Nakho_Jawantal` |  |
| 17780794 | Navisse  `Navisse` |  |
| 17780787 | Omer  `Omer` |  |
| 17780760 | Pawkrix  `Pawkrix` |  |
| 17780860 | Promurouve  `Promurouve` |  |
| 17780841 | Stinknix  `Stinknix` |  |
| 17780845 | Subash  `Subash` |  |
| 17780867 | Susu  `Susu` |  |
| 17780907 | Symphonic Curator  `Symphonic_Curator` |  |
| 17780842 | Yoskolo  `Yoskolo` |  |

<details><summary>↳ 10 cutscene NPC(s) — review (possible mission steps)</summary>

Darcia, Mataligeat, Mendi, Mertaire, Ruslan, Sutarara, Teigero-Bangero, Tovrutaux, Vingijard, Yin Pocanakhu

</details>

### West Sarutabaruta  (115)
_22 flavor candidate(s) · 4 functional kept · 40 scenery · 69 already hidden_

| npcid | NPC | |
|---:|---|---|
| 17248857 | Field Manual  `Field_Manual` |  |
| 17248858 | Field Manual  `Field_Manual` |  |
| 17248859 | Field Manual  `Field_Manual` |  |
| 17248796 | Fuahah  `Fuahah` |  |
| 17248797 | Signpost  `Signpost` |  |
| 17248798 | Signpost  `Signpost` |  |
| 17248799 | Signpost  `Signpost` |  |
| 17248800 | Signpost  `Signpost` |  |
| 17248801 | Signpost  `Signpost` |  |
| 17248802 | Signpost  `Signpost` |  |
| 17248803 | Signpost  `Signpost` |  |
| 17248804 | Signpost  `Signpost` |  |
| 17248805 | Signpost  `Signpost` |  |
| 17248806 | Signpost  `Signpost` |  |
| 17248807 | Signpost  `Signpost` |  |
| 17248808 | Signpost  `Signpost` |  |
| 17248809 | Signpost  `Signpost` |  |
| 17248810 | Signpost  `Signpost` |  |
| 17248811 | Signpost  `Signpost` |  |
| 17248812 | Signpost  `Signpost` |  |
| 17248813 | Signpost  `Signpost` |  |
| 17248814 | Signpost  `Signpost` |  |

### East Sarutabaruta  (116)
_21 flavor candidate(s) · 0 functional kept · 24 scenery · 70 already hidden_

| npcid | NPC | |
|---:|---|---|
| 17253074 | Field Manual  `Field_Manual` |  |
| 17253075 | Field Manual  `Field_Manual` |  |
| 17253076 | Field Manual  `Field_Manual` |  |
| 17253044 | Signpost  `Signpost` |  |
| 17253045 | Signpost  `Signpost` |  |
| 17253046 | Signpost  `Signpost` |  |
| 17253047 | Signpost  `Signpost` |  |
| 17253048 | Signpost  `Signpost` |  |
| 17253049 | Signpost  `Signpost` |  |
| 17253050 | Signpost  `Signpost` |  |
| 17253051 | Signpost  `Signpost` |  |
| 17253052 | Signpost  `Signpost` |  |
| 17253053 | Signpost  `Signpost` |  |
| 17253054 | Signpost  `Signpost` |  |
| 17253055 | Signpost  `Signpost` |  |
| 17253056 | Signpost  `Signpost` |  |
| 17253057 | Signpost  `Signpost` |  |
| 17253058 | Signpost  `Signpost` |  |
| 17253059 | Signpost  `Signpost` |  |
| 17253060 | Signpost  `Signpost` |  |
| 17253061 | Signpost  `Signpost` |  |

### VeLugannon Palace  (177)
_20 flavor candidate(s) · 4 functional kept · 75 scenery · 29 already hidden_

| npcid | NPC | |
|---:|---|---|
| 17502707 | Grounds Tome  `Grounds_Tome` |  |
| 17502708 | Grounds Tome  `Grounds_Tome` |  |
| 17502709 | Grounds Tome  `Grounds_Tome` |  |
| 17502710 | Grounds Tome  `Grounds_Tome` |  |
| 17502711 | Grounds Tome  `Grounds_Tome` |  |
| 17502712 | Grounds Tome  `Grounds_Tome` |  |
| 17502713 | Grounds Tome  `Grounds_Tome` |  |
| 17502714 | Grounds Tome  `Grounds_Tome` |  |
| 17502715 | Grounds Tome  `Grounds_Tome` |  |
| 17502716 | Grounds Tome  `Grounds_Tome` |  |
| 17502625 | Monolith  `Monolith` |  |
| 17502627 | Monolith  `Monolith` |  |
| 17502629 | Monolith  `Monolith` |  |
| 17502631 | Monolith  `Monolith` |  |
| 17502633 | Monolith  `Monolith` |  |
| 17502635 | Monolith  `Monolith` |  |
| 17502637 | Monolith  `Monolith` |  |
| 17502639 | Monolith  `Monolith` |  |
| 17502641 | Monolith  `Monolith` |  |
| 17502643 | Monolith  `Monolith` |  |

### Bastok Mines  (234)
_20 flavor candidate(s) · 27 functional kept · 186 scenery · 98 already hidden_

| npcid | NPC | |
|---:|---|---|
| 17735711 | Azima  `Azima` |  |
| 17735739 | Black Mud  `Black_Mud` |  |
| 17735724 | Boytz  `Boytz` |  |
| 17735722 | Deegis  `Deegis` |  |
| 17735746 | Galdeo  `Galdeo` |  |
| 17735716 | Gawful  `Gawful` |  |
| 17735725 | Gelzerio  `Gelzerio` |  |
| 17735726 | Griselda  `Griselda` |  |
| 17735860 | Hunt Registry  `Hunt_Registry` |  |
| 17735714 | Maymunah  `Maymunah` |  |
| 17735715 | Odoba  `Odoba` |  |
| 17735743 | Rodellieux  `Rodellieux` |  |
| 17735713 | Sieglinde  `Sieglinde` |  |
| 17735717 | Sodragamm  `Sodragamm` |  |
| 17735775 | Symphonic Curator  `Symphonic_Curator` |  |
| 17735745 | Tibelda  `Tibelda` |  |
| 17735712 | Titus  `Titus` |  |
| 17735819 | Titus  `Titus` |  |
| 17735798 | Trail Markings  `Trail_Markings` |  |
| 17735723 | Zemedars  `Zemedars` |  |

<details><summary>↳ 3 cutscene NPC(s) — review (possible mission steps)</summary>

A.M.A.N. Liaison, Gerbaum, Rashid

</details>

### Port San dOria  (232)
_18 flavor candidate(s) · 32 functional kept · 90 scenery · 42 already hidden_

| npcid | NPC | |
|---:|---|---|
| 17727564 | Artinien  `Artinien` |  |
| 17727530 | Bonmaurieut  `Bonmaurieut` |  |
| 17727565 | Brifalien  `Brifalien` |  |
| 17727516 | Comittie  `Comittie` |  |
| 17727523 | Coullave  `Coullave` |  |
| 17727503 | Croumangue  `Croumangue` |  |
| 17727527 | Deguerendars  `Deguerendars` |  |
| 17727524 | Fiva  `Fiva` |  |
| 17727611 | Gallijaux  `Gallijaux` |  |
| 17727653 | Gilburt  `Gilburt` |  |
| 17727655 | Greeter Moogle  `Greeter_Moogle` |  |
| 17727612 | Joulet  `Joulet` |  |
| 17727517 | Meinemelle  `Meinemelle` |  |
| 17727525 | Milva  `Milva` |  |
| 17727528 | Nimia  `Nimia` |  |
| 17727529 | Patolle  `Patolle` |  |
| 17727584 | Symphonic Curator  `Symphonic_Curator` |  |
| 17727526 | Vendavoq  `Vendavoq` |  |

<details><summary>↳ 11 cutscene NPC(s) — review (possible mission steps)</summary>

A.M.A.N. Liaison, Ambleon, Arminibit, Cherlodeau, Leonora, Louis, Nazar, Parcarin, Perdiouvilet, Pomilla, Rugiette

</details>

### Norg  (252)
_18 flavor candidate(s) · 21 functional kept · 71 scenery · 27 already hidden_

| npcid | NPC | |
|---:|---|---|
| 17809447 | Achika  `Achika` |  |
| 17809448 | Chiyo  `Chiyo` |  |
| 17809438 | Deigoff  `Deigoff` |  |
| 17809525 | Hunt Registry  `Hunt_Registry` |  |
| 17809446 | Jirokichi  `Jirokichi` |  |
| 17809436 | Louartain  `Louartain` |  |
| 17809455 | Nomad Moogle  `Nomad_Moogle` |  |
| 17809456 | Nomad Moogle  `Nomad_Moogle` |  |
| 17809457 | Nomad Moogle  `Nomad_Moogle` |  |
| 17809439 | Oruga  `Oruga` |  |
| 17809442 | Paito-Maito  `Paito-Maito` |  |
| 17809450 | Paleille  `Paleille` |  |
| 17809440 | Parlemaille  `Parlemaille` |  |
| 17809479 | Quntsu-Nointsu  `Quntsu-Nointsu` |  |
| 17809437 | Shivivi  `Shivivi` |  |
| 17809502 | Solby-Maholby  `Solby-Maholby` |  |
| 17809449 | Spasija  `Spasija` |  |
| 17809445 | Vuliaie  `Vuliaie` |  |

<details><summary>↳ 3 cutscene NPC(s) — review (possible mission steps)</summary>

Fouvia, Gimb, Vaultimand

</details>

### Grand Palace of HuXzoi  (34)
_17 flavor candidate(s) · 12 functional kept · 68 scenery · 14 already hidden_

| npcid | NPC | |
|---:|---|---|
| 16916928 | Cermet Alcove  `Cermet_Alcove` |  |
| 16916929 | Cermet Alcove  `Cermet_Alcove` |  |
| 16916930 | Cermet Alcove  `Cermet_Alcove` |  |
| 16916931 | Cermet Alcove  `Cermet_Alcove` |  |
| 16916870 | Cermet Portal  `_iyj` |  |
| 16916871 | Cermet Portal  `_iyn` |  |
| 16916873 | Cermet Portal  `_iyp` |  |
| 16916874 | Cermet Portal  `_iyo` |  |
| 16916876 | Cermet Portal  `_iyk` |  |
| 16916878 | Cermet Portal  `_iym` |  |
| 16916879 | Cermet Portal  `_iyl` |  |
| 16916881 | Cermet Portal  `_iyd` |  |
| 16916883 | Cermet Portal  `_iyi` |  |
| 16916884 | Cermet Portal  `_iyh` |  |
| 16916885 | Cermet Portal  `_iyg` |  |
| 16916886 | Cermet Portal  `_iyf` |  |
| 16916887 | Cermet Portal  `_iye` |  |

### Windurst Walls  (239)
_17 flavor candidate(s) · 23 functional kept · 143 scenery · 99 already hidden_

| npcid | NPC | |
|---:|---|---|
| 17756196 | Bonchacha  `Bonchacha` |  |
| 17756469 | Greeter Moogle  `Greeter_Moogle` |  |
| 17756253 | Haah Chakaila  `Haah_Chakaila` |  |
| 17756250 | Juna Moshal  `Juna_Moshal` |  |
| 17756239 | Karija-Marija  `Karija-Marija` |  |
| 17756201 | Kenono  `Kenono` |  |
| 17756225 | Komomo  `Komomo` |  |
| 17756245 | Malmi-Monmi  `Malmi-Monmi` |  |
| 17756249 | Migi Centa  `Migi_Centa` |  |
| 17756227 | Pakeke  `Pakeke` |  |
| 17756229 | Polink-Moink  `Polink-Moink` |  |
| 17756240 | Purakoko  `Purakoko` |  |
| 17756304 | Scavnix  `Scavnix` |  |
| 17756200 | Selulu  `Selulu` |  |
| 17756226 | Suhie-Kaihie  `Suhie-Kaihie` |  |
| 17756273 | Symphonic Curator  `Symphonic_Curator` |  |
| 17756306 | Trail Markings  `Trail_Markings` |  |

<details><summary>↳ 14 cutscene NPC(s) — review (possible mission steps)</summary>

A.M.A.N. Liaison, Chomomo, Five of Diamonds, Kalupa-Tawalupa, Moan-Maon, Naih Arihmepp, Orudoba-Sondeba, Ran, Rutango-Botango, Shantotto, Tsuaora-Tsuora, Yoriri, Zokima-Rokima

</details>

### Selbina  (248)
_17 flavor candidate(s) · 11 functional kept · 45 scenery · 36 already hidden_

| npcid | NPC | |
|---:|---|---|
| 17793128 | Boris  `Boris` |  |
| 17793068 | Chutarmire  `Chutarmire` |  |
| 17793041 | Dohdjuma  `Dohdjuma` |  |
| 17793133 | Falgima  `Falgima` |  |
| 17793054 | Gibol  `Gibol` |  |
| 17793038 | Graegham  `Graegham` |  |
| 17793033 | Herminia  `Herminia` |  |
| 17793084 | Humilitie  `Humilitie` |  |
| 17793066 | Lombaria  `Lombaria` |  |
| 17793037 | Mendoline  `Mendoline` |  |
| 17793129 | Nomad Moogle  `Nomad_Moogle` |  |
| 17793130 | Nomad Moogle  `Nomad_Moogle` |  |
| 17793067 | Quelpia  `Quelpia` |  |
| 17793053 | Tilala  `Tilala` |  |
| 17793036 | Torapiont  `Torapiont` |  |
| 17793127 | Wenzel  `Wenzel` |  |
| 17793090 | Yulon-Polon  `Yulon-Polon` |  |

<details><summary>↳ 10 cutscene NPC(s) — review (possible mission steps)</summary>

Aleria, Bretta, Flandiace, Gabwaleid, Mathilde, Pacomart, Raging Tiger, Ramona, Sleeping Lizard, Velema

</details>

### Mhaura  (249)
_17 flavor candidate(s) · 15 functional kept · 69 scenery · 37 already hidden_

| npcid | NPC | |
|---:|---|---|
| 17797132 | Celestina  `Celestina` |  |
| 17797154 | Celestina  `Celestina` |  |
| 17797178 | Dieh Yamilsiah  `Dieh_Yamilsiah` |  |
| 17797130 | Graine  `Graine` |  |
| 17797135 | Kamilah  `Kamilah` |  |
| 17797183 | Laughing Bison  `Laughing_Bison` | `[ref]` |
| 17797160 | Ludwig  `Ludwig` |  |
| 17797249 | Mauriri  `Mauriri` |  |
| 17797134 | Mololo  `Mololo` |  |
| 17797251 | Nomad Moogle  `Nomad_Moogle` |  |
| 17797252 | Nomad Moogle  `Nomad_Moogle` |  |
| 17797250 | Panoru-Kanoru  `Panoru-Kanoru` |  |
| 17797138 | Pikini-Mikini  `Pikini-Mikini` |  |
| 17797127 | Runito-Monito  `Runito-Monito` |  |
| 17797255 | Tya Padolih  `Tya_Padolih` |  |
| 17797195 | Willah Maratahya  `Willah_Maratahya` |  |
| 17797131 | Yabby Tanmikey  `Yabby_Tanmikey` |  |

<details><summary>↳ 9 cutscene NPC(s) — review (possible mission steps)</summary>

Condor Eye, Ekokoko, Emyr, Hyria, Mauh Halaapah, Radhika, Somo Aatsula, Standing Bear, Tonasav

</details>

### Nashmau  (53)
_16 flavor candidate(s) · 11 functional kept · 61 scenery · 42 already hidden_

| npcid | NPC | |
|---:|---|---|
| 16994373 | Chichiroon  `Chichiroon` |  |
| 16994361 | Chuchuroon  `Chuchuroon` |  |
| 16994435 | Hunt Registry  `Hunt_Registry` |  |
| 16994341 | Jajaroon  `Jajaroon` |  |
| 16994346 | Mamaroon  `Mamaroon` |  |
| 16994410 | Nabihwah  `Nabihwah` |  |
| 16994377 | Nanaroon  `Nanaroon` |  |
| 16994378 | Neneroon  `Neneroon` |  |
| 16994379 | Nomad Moogle  `Nomad_Moogle` |  |
| 16994380 | Nomad Moogle  `Nomad_Moogle` |  |
| 16994348 | Pipiroon  `Pipiroon` |  |
| 16994349 | Poporoon  `Poporoon` |  |
| 16994350 | Wata Khamazom  `Wata_Khamazom` |  |
| 16994324 | Yohj Dukonlhy  `Yohj_Dukonlhy` |  |
| 16994344 | Yoyoroon  `Yoyoroon` |  |
| 16994405 | Yoyoroon  `Yoyoroon` |  |

<details><summary>↳ 3 cutscene NPC(s) — review (possible mission steps)</summary>

Belligerent Sheep, Bellowing Scout, Dnegan

</details>

### Rabao  (247)
_16 flavor candidate(s) · 16 functional kept · 38 scenery · 38 already hidden_

| npcid | NPC | |
|---:|---|---|
| 17788970 | Ashu Bolkhomo  `Ashu_Bolkhomo` |  |
| 17788939 | Bald Aurochs  `Bald_Aurochs` |  |
| 17788945 | Brave Ox  `Brave_Ox` |  |
| 17788944 | Brave Wolf  `Brave_Wolf` |  |
| 17788941 | Eflatun  `Eflatun` |  |
| 17789001 | Hunt Registry  `Hunt_Registry` |  |
| 17788940 | Iron Muscles  `Iron_Muscles` |  |
| 17788952 | Nomad Moogle  `Nomad_Moogle` |  |
| 17788953 | Nomad Moogle  `Nomad_Moogle` |  |
| 17788954 | Nomad Moogle  `Nomad_Moogle` |  |
| 17788947 | Pakhi Churhebi  `Pakhi_Churhebi` |  |
| 17788946 | Scamplix  `Scamplix` |  |
| 17788943 | Shiny Teeth  `Shiny_Teeth` |  |
| 17788972 | Shupah Mujuuk  `Shupah_Mujuuk` |  |
| 17788948 | Spirit Singer  `Spirit_Singer` |  |
| 17788942 | Yabehbeh  `Yabehbeh` |  |

<details><summary>↳ 2 cutscene NPC(s) — review (possible mission steps)</summary>

Jourdenaux, Waylea

</details>

### Tavnazian Safehold  (26)
_15 flavor candidate(s) · 14 functional kept · 118 scenery · 29 already hidden_

| npcid | NPC | |
|---:|---|---|
| 16883823 | Aligi-Kufongi  `Aligi-Kufongi` |  |
| 16883792 | Caiphimonride  `Caiphimonride` |  |
| 16883868 | Hieroglyphics  `Hieroglyphics` |  |
| 16883880 | Hunt Registry  `Hunt_Registry` |  |
| 16883791 | Komalata  `Komalata` |  |
| 16883799 | Maturiri  `Maturiri` |  |
| 16883790 | Mazuro-Oozuro  `Mazuro-Oozuro` |  |
| 16883793 | Melleupaux  `Melleupaux` |  |
| 16883795 | Migran  `Migran` |  |
| 16883794 | Misseulieu  `Misseulieu` |  |
| 16883789 | Nilerouche  `Nilerouche` |  |
| 16883786 | Nomad Moogle  `Nomad_Moogle` |  |
| 16883787 | Nomad Moogle  `Nomad_Moogle` |  |
| 16883788 | Nomad Moogle  `Nomad_Moogle` |  |
| 16883765 | Quelveuiat  `Quelveuiat` |  |

<details><summary>↳ 4 cutscene NPC(s) — review (possible mission steps)</summary>

Havillione, Nivorajean, Resauchamet, Sewer Entrance

</details>

### Al Zahbi  (48)
_15 flavor candidate(s) · 14 functional kept · 114 scenery · 38 already hidden_

| npcid | NPC | |
|---:|---|---|
| 16974291 | Allard  `Allard` |  |
| 16974296 | Bornahn  `Bornahn` |  |
| 16974290 | Chayaya  `Chayaya` |  |
| 16974298 | Dehbi Moshal  `Dehbi_Moshal` |  |
| 16974372 | Falzuuk  `Falzuuk` |  |
| 16974373 | Famatar  `Famatar` |  |
| 16974292 | Kahah Hobichai  `Kahah_Hobichai` |  |
| 16974308 | Mabebe  `Mabebe` |  |
| 16974381 | Najaaj  `Najaaj` |  |
| 16974297 | Ndego  `Ndego` |  |
| 16974309 | Opococo  `Opococo` |  |
| 16974382 | Sujyahn  `Sujyahn` |  |
| 16974288 | Symphonic Curator  `Symphonic_Curator` |  |
| 16974295 | Taten-Bilten  `Taten-Bilten` |  |
| 16974293 | Zafif  `Zafif` |  |

### Buburimu Peninsula  (118)
_15 flavor candidate(s) · 4 functional kept · 58 scenery · 73 already hidden_

| npcid | NPC | |
|---:|---|---|
| 17261203 | Field Manual  `Field_Manual` |  |
| 17261204 | Field Manual  `Field_Manual` |  |
| 17261191 | Hieroglyphics  `Hieroglyphics` |  |
| 17261035 | Jade Etui  `Jade_Etui` |  |
| 17261036 | Jade Etui  `Jade_Etui` |  |
| 17261037 | Jade Etui  `Jade_Etui` |  |
| 17261038 | Jade Etui  `Jade_Etui` |  |
| 17261039 | Jade Etui  `Jade_Etui` |  |
| 17261165 | Signpost  `Signpost` |  |
| 17261166 | Signpost  `Signpost` |  |
| 17261167 | Signpost  `Signpost` |  |
| 17261168 | Signpost  `Signpost` |  |
| 17261169 | Signpost  `Signpost` |  |
| 17261170 | Signpost  `Signpost` |  |
| 17261171 | Signpost  `Signpost` |  |

<details><summary>↳ 1 cutscene NPC(s) — review (possible mission steps)</summary>

Five of Spades

</details>

### Escha RuAun  (289)
_15 flavor candidate(s) · 1 functional kept · 36 scenery · 13 already hidden_

| npcid | NPC | |
|---:|---|---|
| 17961713 | Eschan Portal #1  `Eschan_Portal_#1` |  |
| 17961722 | Eschan Portal #10  `Eschan_Portal_#10` |  |
| 17961723 | Eschan Portal #11  `Eschan_Portal_#11` |  |
| 17961724 | Eschan Portal #12  `Eschan_Portal_#12` |  |
| 17961725 | Eschan Portal #13  `Eschan_Portal_#13` |  |
| 17961726 | Eschan Portal #14  `Eschan_Portal_#14` |  |
| 17961727 | Eschan Portal #15  `Eschan_Portal_#15` |  |
| 17961714 | Eschan Portal #2  `Eschan_Portal_#2` |  |
| 17961715 | Eschan Portal #3  `Eschan_Portal_#3` |  |
| 17961716 | Eschan Portal #4  `Eschan_Portal_#4` |  |
| 17961717 | Eschan Portal #5  `Eschan_Portal_#5` |  |
| 17961718 | Eschan Portal #6  `Eschan_Portal_#6` |  |
| 17961719 | Eschan Portal #7  `Eschan_Portal_#7` |  |
| 17961720 | Eschan Portal #8  `Eschan_Portal_#8` |  |
| 17961721 | Eschan Portal #9  `Eschan_Portal_#9` |  |

### The Eldieme Necropolis  (195)
_14 flavor candidate(s) · 16 functional kept · 58 scenery · 53 already hidden_

| npcid | NPC | |
|---:|---|---|
| 17576327 | East Plate  `_5fl` |  |
| 17576328 | East Plate  `_5fm` |  |
| 17576440 | Geomagnetic Fount  `Geomagnetic_Fount` |  |
| 17576441 | Geomantic Reservoir  `Geomantic_Reservoir` |  |
| 17576430 | Grounds Tome  `Grounds_Tome` |  |
| 17576431 | Grounds Tome  `Grounds_Tome` |  |
| 17576432 | Grounds Tome  `Grounds_Tome` |  |
| 17576433 | Grounds Tome  `Grounds_Tome` |  |
| 17576329 | North Plate  `_5fn` |  |
| 17576330 | North Plate  `_5fo` |  |
| 17576333 | South Plate  `_5fr` |  |
| 17576334 | South Plate  `_5fs` |  |
| 17576331 | West Plate  `_5fp` |  |
| 17576332 | West Plate  `_5fq` |  |

### Upper Jeuno  (244)
_14 flavor candidate(s) · 24 functional kept · 153 scenery · 59 already hidden_

| npcid | NPC | |
|---:|---|---|
| 17776715 | Antonia  `Antonia` |  |
| 17776718 | Areebah  `Areebah` |  |
| 17776717 | Champalpieu  `Champalpieu` |  |
| 17776714 | Coumuna  `Coumuna` |  |
| 17776696 | Deadly Minnow  `Deadly_Minnow` |  |
| 17776677 | Glyke  `Glyke` |  |
| 17776736 | Kasra  `Kasra` |  |
| 17776716 | Khe Chalahko  `Khe_Chalahko` |  |
| 17776737 | Koriso-Manriso  `Koriso-Manriso` |  |
| 17776721 | Leillaine  `Leillaine` |  |
| 17776720 | Rusese  `Rusese` |  |
| 17776692 | Sibila-Mobla  `Sibila-Mobla` |  |
| 17776764 | Symphonic Curator  `Symphonic_Curator` |  |
| 17776719 | Theraisie  `Theraisie` |  |

<details><summary>↳ 2 cutscene NPC(s) — review (possible mission steps)</summary>

Afdeen, Hinda

</details>

### Kazham  (250)
_14 flavor candidate(s) · 26 functional kept · 34 scenery · 28 already hidden_

| npcid | NPC | |
|---:|---|---|
| 17801285 | _(unnamed)_ `rarab_1` |  |
| 17801286 | _(unnamed)_ `rarab_2` |  |
| 17801287 | _(unnamed)_ `rarab_3` |  |
| 17801240 | Eron-Tomaron  `Eron-Tomaron` |  |
| 17801253 | Ghemi Sinterilo  `Ghemi_Sinterilo` |  |
| 17801342 | Hunt Registry  `Hunt_Registry` |  |
| 17801256 | Khifo Ryuhkowa  `Khifo_Ryuhkowa` |  |
| 17801303 | Kobhi Sarhigamya  `Kobhi_Sarhigamya` |  |
| 17801259 | Nomad Moogle  `Nomad_Moogle` |  |
| 17801260 | Nomad Moogle  `Nomad_Moogle` |  |
| 17801261 | Nuh Celodehki  `Nuh_Celodehki` |  |
| 17801279 | Pahya Lolohoiv  `Pahya_Lolohoiv` |  |
| 17801254 | Tahn Posbei  `Tahn_Posbei` |  |
| 17801278 | Toji Mumosulah  `Toji_Mumosulah` |  |

<details><summary>↳ 32 cutscene NPC(s) — review (possible mission steps)</summary>

Balih Chavizaai, Bhi Telifahgo, Bhoyu Halpatacco, Bhukka Sahbeo, Cha Tigunalhgo, Cobbi Malgharam, Dakha Topsalwan, Dheo Nbolo, Flame Walker, Ghosa Demuhzo, Haih Ahmpagako, Hozie Naharaf, Jakoh Wahcondalo, Khaffi Salponoihz, Khau Mahiyoeloh, Kocho Phunakcham, Kyun Magopiteh, Majjih Bakrhamab, Mijeh Sholpoilo, Mitti Haplihza, Ney Hiparujah, Nti Badolsoma, Pofhu Tendelicon, Qhio Plittibhi, Romaa Mihgo, Shark Teeth, Shey Wayatih, Thali Mhobrum, Toeh Leddenbah, Tsahbi Ifalombo, Tsui Golalapahn, Vah Keshura

</details>

### Bibiki Bay  (4)
_13 flavor candidate(s) · 3 functional kept · 31 scenery · 23 already hidden_

| npcid | NPC | |
|---:|---|---|
| 16793991 | Clamming Point  `Clamming_Point_1` |  |
| 16793992 | Clamming Point  `Clamming_Point_2` |  |
| 16793993 | Clamming Point  `Clamming_Point_3` |  |
| 16793994 | Clamming Point  `Clamming_Point_4` |  |
| 16793995 | Clamming Point  `Clamming_Point_5` |  |
| 16793996 | Clamming Point  `Clamming_Point_6` |  |
| 16793997 | Clamming Point  `Clamming_Point_7` |  |
| 16793998 | Clamming Point  `Clamming_Point_8` |  |
| 16793982 | Fheli Lapatzuo  `Fheli_Lapatzuo` |  |
| 16793988 | Mep Nhapopoluko  `Mep_Nhapopoluko` |  |
| 16793983 | Noih Tahparawh  `Noih_Tahparawh` |  |
| 16793987 | Pohka Chichiyowahl  `Pohka_Chichiyowahl` |  |
| 16793990 | Toh Zonikki  `Toh_Zonikki` |  |

### Tahrongi Canyon  (117)
_12 flavor candidate(s) · 7 functional kept · 63 scenery · 59 already hidden_

| npcid | NPC | |
|---:|---|---|
| 17257079 | Field Manual  `Field_Manual` |  |
| 17257080 | Field Manual  `Field_Manual` |  |
| 17257081 | Field Manual  `Field_Manual` |  |
| 17257123 | Geomantic Reservoir  `Geomantic_Reservoir` |  |
| 17257033 | Signpost  `Signpost` |  |
| 17257034 | Signpost  `Signpost` |  |
| 17257035 | Signpost  `Signpost` |  |
| 17257036 | Signpost  `Signpost` |  |
| 17257037 | Signpost  `Signpost` |  |
| 17257038 | Signpost  `Signpost` |  |
| 17257039 | Signpost  `Signpost` |  |
| 17257040 | Signpost  `Signpost` |  |

<details><summary>↳ 1 cutscene NPC(s) — review (possible mission steps)</summary>

Dimensional Portal

</details>

### Castle Oztroja  (151)
_12 flavor candidate(s) · 16 functional kept · 49 scenery · 30 already hidden_

| npcid | NPC | |
|---:|---|---|
| 17396195 | _(unnamed)_ `_47n` |  |
| 17396269 | Geomantic Reservoir  `Geomantic_Reservoir` |  |
| 17396159 | Handle  `_47e` |  |
| 17396162 | Handle  `_47p` |  |
| 17396163 | Handle  `_47f` |  |
| 17396164 | Handle  `_47g` |  |
| 17396165 | Handle  `_47h` |  |
| 17396166 | Handle  `_47i` |  |
| 17396168 | Handle  `_47v` |  |
| 17396173 | Handle  `_47w` |  |
| 17396178 | Handle  `_47u` |  |
| 17396187 | Handle  `_47x` |  |

<details><summary>↳ 2 cutscene NPC(s) — review (possible mission steps)</summary>

Handle

</details>

### Metalworks  (237)
_12 flavor candidate(s) · 8 functional kept · 138 scenery · 50 already hidden_

| npcid | NPC | |
|---:|---|---|
| 17748035 | _(unnamed)_ `@6l0` |  |
| 17748038 | _(unnamed)_ `@6l1` |  |
| 17747970 | Amulya  `Amulya` |  |
| 17748033 | Fariel  `Fariel` |  |
| 17747973 | Hugues  `Hugues` |  |
| 17747977 | Nogga  `Nogga` |  |
| 17747976 | Olaf  `Olaf` |  |
| 17747974 | Romero  `Romero` |  |
| 17748139 | Takiyah  `Takiyah` |  |
| 17748005 | Tomasa  `Tomasa` |  |
| 17747969 | Vicious Eye  `Vicious_Eye` |  |
| 17747972 | Wise Owl  `Wise_Owl` |  |

<details><summary>↳ 6 cutscene NPC(s) — review (possible mission steps)</summary>

Ferghus, Malduc, Mighty Fist, Mythily, Savae E Paleade, Udine A.M.A.N.

</details>

### RuLude Gardens  (243)
_12 flavor candidate(s) · 22 functional kept · 183 scenery · 41 already hidden_

| npcid | NPC | |
|---:|---|---|
| 17772575 | Arenuel  `Arenuel` |  |
| 17772833 | Artisan Moogle  `Artisan_Moogle` |  |
| 17772776 | Assai Nybaem  `Assai_Nybaem` |  |
| 17772579 | Dugga  `Dugga` |  |
| 17772773 | Explorer Moogle  `Explorer_Moogle` |  |
| 17772836 | Fabien  `Fabien` |  |
| 17772580 | Ghye Dachanthu  `Ghye_Dachanthu` |  |
| 17772774 | Hunt Registry  `Hunt_Registry` |  |
| 17772574 | Leis  `Leis` |  |
| 17772598 | Macchi Gazlitah  `Macchi_Gazlitah` |  |
| 17772629 | Trail Markings  `Trail_Markings` |  |
| 17772573 | Yavoraile  `Yavoraile` |  |

<details><summary>↳ 4 cutscene NPC(s) — review (possible mission steps)</summary>

Laityn, Maat

</details>

### PsoXja  (9)
_11 flavor candidate(s) · 22 functional kept · 74 scenery · 26 already hidden_

| npcid | NPC | |
|---:|---|---|
| 16814443 | TOWER_A_Lift_0  `@090` |  |
| 16814462 | TOWER_B_Lift_1  `@091` |  |
| 16814465 | TOWER_C_Lift_1  `@092` |  |
| 16814475 | TOWER_C_Lift_E  `@098` |  |
| 16814468 | TOWER_C_Lift_N  `@097` |  |
| 16814478 | TOWER_C_Lift_S  `@09a` |  |
| 16814472 | TOWER_C_Lift_W  `@099` |  |
| 16814487 | TOWER_D_Lift_1  `@093` |  |
| 16814506 | TOWER_E_Lift_1  `@094` |  |
| 16814512 | TOWER_F_Lift_E  `@095` |  |
| 16814509 | TOWER_F_Lift_W  `@096` |  |

### Western Adoulin  (256)
_10 flavor candidate(s) · 34 functional kept · 187 scenery · 143 already hidden_

| npcid | NPC | |
|---:|---|---|
| 17826076 | Ansegusele  `Ansegusele` |  |
| 17826089 | Eukalline  `Eukalline` |  |
| 17826088 | Ishvad  `Ishvad` |  |
| 17826093 | Kanil  `Kanil` |  |
| 17826087 | Ledericus  `Ledericus` |  |
| 17826179 | Nunaarl Bthtrogg  `Nunaarl_Bthtrogg` |  |
| 17826091 | Preterig  `Preterig` |  |
| 17825926 | Symphonic Curator  `Symphonic_Curator` |  |
| 17826077 | Tevigogo  `Tevigogo` |  |
| 17826094 | Theophylacte  `Theophylacte` |  |

<details><summary>↳ 15 cutscene NPC(s) — review (possible mission steps)</summary>

Andrival, Barenngo, Bilp, Dewalt, Eamonn, Gontrain, Grevan, Kipligg, Marjoirelle, Oka Qhantari, Rising Solstice, Ruth, Terwok, Volgoi, Zaoso

</details>

### Reisenjima  (291)
_10 flavor candidate(s) · 0 functional kept · 126 scenery · 16 already hidden_

| npcid | NPC | |
|---:|---|---|
| 17969979 | Ethereal Ingress #1  `Ethereal_Ingress_#1` |  |
| 17969988 | Ethereal Ingress #10  `Ethereal_Ingress_#10` |  |
| 17969980 | Ethereal Ingress #2  `Ethereal_Ingress_#2` |  |
| 17969981 | Ethereal Ingress #3  `Ethereal_Ingress_#3` |  |
| 17969982 | Ethereal Ingress #4  `Ethereal_Ingress_#4` |  |
| 17969983 | Ethereal Ingress #5  `Ethereal_Ingress_#5` |  |
| 17969984 | Ethereal Ingress #6  `Ethereal_Ingress_#6` |  |
| 17969985 | Ethereal Ingress #7  `Ethereal_Ingress_#7` |  |
| 17969986 | Ethereal Ingress #8  `Ethereal_Ingress_#8` |  |
| 17969987 | Ethereal Ingress #9  `Ethereal_Ingress_#9` |  |

### Bastok Markets [S]  (87)
_8 flavor candidate(s) · 8 functional kept · 225 scenery · 58 already hidden_

| npcid | NPC | |
|---:|---|---|
| 17134031 | Adelbrecht  `Adelbrecht` |  |
| 17134076 | Blingbrix  `Blingbrix` |  |
| 17134276 | Hunt Registry  `Hunt_Registry` |  |
| 17134084 | Karlotte  `Karlotte` |  |
| 17134131 | Millard, I.M.  `Millard_IM` |  |
| 17134153 | Silke  `Silke` |  |
| 17134104 | Symphonic Curator  `Symphonic_Curator` |  |
| 17134083 | Weldon  `Weldon` |  |

<details><summary>↳ 2 cutscene NPC(s) — review (possible mission steps)</summary>

Raginmund, Red Canyon

</details>

### Ifrits Cauldron  (205)
_8 flavor candidate(s) · 23 functional kept · 32 scenery · 48 already hidden_

| npcid | NPC | |
|---:|---|---|
| 17617268 | Grounds Tome  `Grounds_Tome` |  |
| 17617269 | Grounds Tome  `Grounds_Tome` |  |
| 17617270 | Grounds Tome  `Grounds_Tome` |  |
| 17617271 | Grounds Tome  `Grounds_Tome` |  |
| 17617272 | Grounds Tome  `Grounds_Tome` |  |
| 17617273 | Grounds Tome  `Grounds_Tome` |  |
| 17617274 | Grounds Tome  `Grounds_Tome` |  |
| 17617275 | Grounds Tome  `Grounds_Tome` |  |

### Port Jeuno  (246)
_8 flavor candidate(s) · 26 functional kept · 97 scenery · 30 already hidden_

| npcid | NPC | |
|---:|---|---|
| 17784910 | Digaga  `Digaga` |  |
| 17784881 | Gavin  `Gavin` |  |
| 17784834 | Gekko  `Gekko` |  |
| 17784979 | Joachim  `Joachim` |  |
| 17784835 | Leyla  `Leyla` |  |
| 17784900 | Red Ghost  `Red_Ghost` |  |
| 17784911 | Veujaie  `Veujaie` |  |
| 17784980 | Zuah Lepahnyu  `Zuah_Lepahnyu` |  |

<details><summary>↳ 13 cutscene NPC(s) — review (possible mission steps)</summary>

Avijit, Chaka Skitimah, Chudigrimane, Garridan, Gaura, Imasuke, Jaipal, Kindlix, Najib, Pyropox, Raging Lion, Supiroro, Zona Shodhun

</details>

### Escha ZiTah  (288)
_8 flavor candidate(s) · 1 functional kept · 28 scenery · 21 already hidden_

| npcid | NPC | |
|---:|---|---|
| 17957451 | Eschan Portal #1  `Eschan_Portal_#1` |  |
| 17957452 | Eschan Portal #2  `Eschan_Portal_#2` |  |
| 17957453 | Eschan Portal #3  `Eschan_Portal_#3` |  |
| 17957454 | Eschan Portal #4  `Eschan_Portal_#4` |  |
| 17957455 | Eschan Portal #5  `Eschan_Portal_#5` |  |
| 17957456 | Eschan Portal #6  `Eschan_Portal_#6` |  |
| 17957457 | Eschan Portal #7  `Eschan_Portal_#7` |  |
| 17957458 | Eschan Portal #8  `Eschan_Portal_#8` |  |

### Beaucedine Glacier  (111)
_7 flavor candidate(s) · 2 functional kept · 80 scenery · 54 already hidden_

| npcid | NPC | |
|---:|---|---|
| 17232291 | Field Manual  `Field_Manual` |  |
| 17232292 | Field Manual  `Field_Manual` |  |
| 17232293 | Field Manual  `Field_Manual` |  |
| 17232294 | Field Manual  `Field_Manual` |  |
| 17232321 | Geomantic Reservoir  `Geomantic_Reservoir` |  |
| 17232324 | Geomantic Reservoir  `Geomantic_Reservoir_2` |  |
| 17232242 | Trail Markings  `Trail_Markings` |  |

<details><summary>↳ 7 cutscene NPC(s) — review (possible mission steps)</summary>

Iron Grate, Torino-Samarino

</details>

### Western Altepa Desert  (125)
_7 flavor candidate(s) · 10 functional kept · 69 scenery · 46 already hidden_

| npcid | NPC | |
|---:|---|---|
| 17289754 | Emerald Column  `_3h7` |  |
| 17289801 | Field Manual  `Field_Manual` |  |
| 17289802 | Field Manual  `Field_Manual` |  |
| 17289803 | Field Manual  `Field_Manual` |  |
| 17289752 | Ruby Column  `_3h5` |  |
| 17289755 | Sapphire Column  `_3h8` |  |
| 17289753 | Topaz Column  `_3h6` |  |

### Windurst Waters [S]  (94)
_6 flavor candidate(s) · 11 functional kept · 282 scenery · 89 already hidden_

| npcid | NPC | |
|---:|---|---|
| 17162877 | Ezura-Romazura  `Ezura-Romazura` |  |
| 17163018 | Hunt Registry  `Hunt_Registry` |  |
| 17162866 | Mindala-Andola, C.C.  `Mindala-Andola_CC` |  |
| 17162832 | Pelftrix  `Pelftrix` |  |
| 17162865 | Symphonic Curator  `Symphonic_Curator` |  |
| 17162831 | Yassi-Possi  `Yassi-Possi` |  |

<details><summary>↳ 2 cutscene NPC(s) — review (possible mission steps)</summary>

Ajen-Myoojen, Rohn Ehlbalna

</details>

### RuAun Gardens  (130)
_6 flavor candidate(s) · 22 functional kept · 52 scenery · 36 already hidden_

| npcid | NPC | |
|---:|---|---|
| 17310108 | Field Manual  `Field_Manual` |  |
| 17310109 | Field Manual  `Field_Manual` |  |
| 17310110 | Field Manual  `Field_Manual` |  |
| 17310111 | Field Manual  `Field_Manual` |  |
| 17310112 | Field Manual  `Field_Manual` |  |
| 17310113 | Field Manual  `Field_Manual` |  |

### Den of Rancor  (160)
_6 flavor candidate(s) · 16 functional kept · 22 scenery · 43 already hidden_

| npcid | NPC | |
|---:|---|---|
| 17433091 | Grounds Tome  `Grounds_Tome` |  |
| 17433092 | Grounds Tome  `Grounds_Tome` |  |
| 17433093 | Grounds Tome  `Grounds_Tome` |  |
| 17433094 | Grounds Tome  `Grounds_Tome` |  |
| 17433095 | Grounds Tome  `Grounds_Tome` |  |
| 17433096 | Grounds Tome  `Grounds_Tome` |  |

### FeiYin  (204)
_6 flavor candidate(s) · 15 functional kept · 80 scenery · 46 already hidden_

| npcid | NPC | |
|---:|---|---|
| 17613269 | Geomantic Reservoir  `Geomantic_Reservoir` |  |
| 17613267 | Grounds Tome  `Grounds_Tome` |  |
| 17613268 | Grounds Tome  `Grounds_Tome` |  |
| 17613247 | Underground Pool  `Underground_Pool` |  |
| 17613248 | Underground Pool  `Underground_Pool` |  |
| 17613249 | Underground Pool  `Underground_Pool` |  |

### Quicksand Caves  (208)
_6 flavor candidate(s) · 5 functional kept · 60 scenery · 37 already hidden_

| npcid | NPC | |
|---:|---|---|
| 17629779 | Grounds Tome  `Grounds_Tome` |  |
| 17629780 | Grounds Tome  `Grounds_Tome` |  |
| 17629781 | Grounds Tome  `Grounds_Tome` |  |
| 17629782 | Grounds Tome  `Grounds_Tome` |  |
| 17629783 | Grounds Tome  `Grounds_Tome` |  |
| 17629784 | Grounds Tome  `Grounds_Tome` |  |

### Valkurm Dunes  (103)
_5 flavor candidate(s) · 4 functional kept · 64 scenery · 60 already hidden_

| npcid | NPC | |
|---:|---|---|
| 17199605 | Barnacled Box  `Barnacled_Box` | `[ref]` |
| 17199755 | Field Manual  `Field_Manual` |  |
| 17199756 | Field Manual  `Field_Manual` |  |
| 17199757 | Field Manual  `Field_Manual` |  |
| 17199743 | Hieroglyphics  `Hieroglyphics` |  |

### Qufim Island  (126)
_5 flavor candidate(s) · 6 functional kept · 57 scenery · 86 already hidden_

| npcid | NPC | |
|---:|---|---|
| 17293787 | Field Manual  `Field_Manual` |  |
| 17293788 | Field Manual  `Field_Manual` |  |
| 17293819 | Geomantic Reservoir  `Geomantic_Reservoir` |  |
| 17293763 | Hieroglyphics  `Hieroglyphics` |  |
| 17293708 | Nightflowers  `Nightflowers` |  |

### Beadeaux  (147)
_5 flavor candidate(s) · 4 functional kept · 49 scenery · 18 already hidden_

| npcid | NPC | |
|---:|---|---|
| 17379870 | Geomantic Reservoir  `Geomantic_Reservoir` |  |
| 17379808 | The Mute  `The_Mute` |  |
| 17379809 | The Mute  `The_Mute` |  |
| 17379810 | The Mute  `The_Mute` |  |
| 17379811 | The Mute  `The_Mute` |  |

### Temple of Uggalepih  (159)
_5 flavor candidate(s) · 29 functional kept · 98 scenery · 45 already hidden_

| npcid | NPC | |
|---:|---|---|
| 17429029 | Grounds Tome  `Grounds_Tome` |  |
| 17429030 | Grounds Tome  `Grounds_Tome` |  |
| 17429031 | Grounds Tome  `Grounds_Tome` |  |
| 17429032 | Grounds Tome  `Grounds_Tome` |  |
| 17429033 | Grounds Tome  `Grounds_Tome` |  |

<details><summary>↳ 3 cutscene NPC(s) — review (possible mission steps)</summary>

Tome of Magic

</details>

### Toraimarai Canal  (169)
_5 flavor candidate(s) · 4 functional kept · 36 scenery · 38 already hidden_

| npcid | NPC | |
|---:|---|---|
| 17469855 | Geomagnetic Fount  `Geomagnetic_Fount` |  |
| 17469851 | Grounds Tome  `Grounds_Tome` |  |
| 17469852 | Grounds Tome  `Grounds_Tome` |  |
| 17469853 | Grounds Tome  `Grounds_Tome` |  |
| 17469854 | Grounds Tome  `Grounds_Tome` |  |

<details><summary>↳ 5 cutscene NPC(s) — review (possible mission steps)</summary>

Tome of Magic

</details>

### Korroloka Tunnel  (173)
_5 flavor candidate(s) · 3 functional kept · 9 scenery · 41 already hidden_

| npcid | NPC | |
|---:|---|---|
| 17486271 | Geomagnetic Fount  `Geomagnetic_Fount` |  |
| 17486267 | Grounds Tome  `Grounds_Tome` |  |
| 17486268 | Grounds Tome  `Grounds_Tome` |  |
| 17486269 | Grounds Tome  `Grounds_Tome` |  |
| 17486270 | Grounds Tome  `Grounds_Tome` |  |

### Sea Serpent Grotto  (176)
_5 flavor candidate(s) · 11 functional kept · 42 scenery · 40 already hidden_

| npcid | NPC | |
|---:|---|---|
| 17498663 | Grounds Tome  `Grounds_Tome` |  |
| 17498664 | Grounds Tome  `Grounds_Tome` |  |
| 17498665 | Grounds Tome  `Grounds_Tome` |  |
| 17498666 | Grounds Tome  `Grounds_Tome` |  |
| 17498667 | Grounds Tome  `Grounds_Tome` |  |

<details><summary>↳ 1 cutscene NPC(s) — review (possible mission steps)</summary>

Bou the Righteous

</details>

### King Ranperres Tomb  (190)
_5 flavor candidate(s) · 4 functional kept · 24 scenery · 39 already hidden_

| npcid | NPC | |
|---:|---|---|
| 17556031 | Geomagnetic Fount  `Geomagnetic_Fount` |  |
| 17556027 | Grounds Tome  `Grounds_Tome` |  |
| 17556028 | Grounds Tome  `Grounds_Tome` |  |
| 17556029 | Grounds Tome  `Grounds_Tome` |  |
| 17556030 | Grounds Tome  `Grounds_Tome` |  |

### Outer Horutoto Ruins  (194)
_5 flavor candidate(s) · 2 functional kept · 51 scenery · 29 already hidden_

| npcid | NPC | |
|---:|---|---|
| 17572314 | Geomagnetic Fount  `Geomagnetic_Fount` |  |
| 17572310 | Grounds Tome  `Grounds_Tome` |  |
| 17572311 | Grounds Tome  `Grounds_Tome` |  |
| 17572312 | Grounds Tome  `Grounds_Tome` |  |
| 17572313 | Grounds Tome  `Grounds_Tome` |  |

### Gusgen Mines  (196)
_5 flavor candidate(s) · 14 functional kept · 9 scenery · 29 already hidden_

| npcid | NPC | |
|---:|---|---|
| 17580420 | Geomagnetic Fount  `Geomagnetic_Fount` |  |
| 17580421 | Geomantic Reservoir  `Geomantic_Reservoir` |  |
| 17580417 | Grounds Tome  `Grounds_Tome` |  |
| 17580418 | Grounds Tome  `Grounds_Tome` |  |
| 17580419 | Grounds Tome  `Grounds_Tome` |  |

### Maze of Shakhrami  (198)
_5 flavor candidate(s) · 9 functional kept · 31 scenery · 41 already hidden_

| npcid | NPC | |
|---:|---|---|
| 17588793 | Geomagnetic Fount  `Geomagnetic_Fount` |  |
| 17588789 | Grounds Tome  `Grounds_Tome` |  |
| 17588790 | Grounds Tome  `Grounds_Tome` |  |
| 17588791 | Grounds Tome  `Grounds_Tome` |  |
| 17588792 | Grounds Tome  `Grounds_Tome` |  |

### Garlaige Citadel  (200)
_5 flavor candidate(s) · 13 functional kept · 57 scenery · 39 already hidden_

| npcid | NPC | |
|---:|---|---|
| 17596866 | Geomagnetic Fount  `Geomagnetic_Fount` |  |
| 17596867 | Geomantic Reservoir  `Geomantic_Reservoir` |  |
| 17596857 | Grounds Tome  `Grounds_Tome` |  |
| 17596858 | Grounds Tome  `Grounds_Tome` |  |
| 17596859 | Grounds Tome  `Grounds_Tome` |  |

### Gustav Tunnel  (212)
_5 flavor candidate(s) · 1 functional kept · 11 scenery · 44 already hidden_

| npcid | NPC | |
|---:|---|---|
| 17645915 | Geomagnetic Fount  `Geomagnetic_Fount` |  |
| 17645911 | Grounds Tome  `Grounds_Tome` |  |
| 17645912 | Grounds Tome  `Grounds_Tome` |  |
| 17645913 | Grounds Tome  `Grounds_Tome` |  |
| 17645914 | Grounds Tome  `Grounds_Tome` |  |

### Carpenters Landing  (2)
_4 flavor candidate(s) · 10 functional kept · 20 scenery · 19 already hidden_

| npcid | NPC | |
|---:|---|---|
| 16785755 | Beugungel  `Beugungel` |  |
| 16785778 | Cofisephe  `Cofisephe` |  |
| 16785779 | Coupulie  `Coupulie` |  |
| 16785780 | Echanie  `Echanie` |  |

### Attohwa Chasm  (7)
_4 flavor candidate(s) · 10 functional kept · 64 scenery · 26 already hidden_

| npcid | NPC | |
|---:|---|---|
| 16806321 | _(unnamed)_ `_07h` |  |
| 16806322 | _(unnamed)_ `_07i` |  |
| 16806323 | _(unnamed)_ `_07j` |  |
| 16806324 | _(unnamed)_ `_07k` |  |

### The Garden of RuHmet  (35)
_4 flavor candidate(s) · 3 functional kept · 76 scenery · 15 already hidden_

| npcid | NPC | |
|---:|---|---|
| 16921069 | Cermet Portal  `_0zw` |  |
| 16921070 | Cermet Portal  `_0zx` |  |
| 16921071 | Cermet Portal  `_0zz` |  |
| 16921073 | Cermet Portal  `_iz0` |  |

<details><summary>↳ 1 cutscene NPC(s) — review (possible mission steps)</summary>

Cermet Portal

</details>

### Alzadaal Undersea Ruins  (72)
_4 flavor candidate(s) · 8 functional kept · 70 scenery · 29 already hidden_

| npcid | NPC | |
|---:|---|---|
| 17072323 | Gilded Gateway  `_20t` |  |
| 17072325 | Gilded Gateway  `_20u` |  |
| 17072327 | Gilded Gateway  `_20v` |  |
| 17072329 | Gilded Gateway  `_20w` |  |

<details><summary>↳ 1 cutscene NPC(s) — review (possible mission steps)</summary>

Runic Seal

</details>

### Southern San dOria [S]  (80)
_4 flavor candidate(s) · 9 functional kept · 321 scenery · 120 already hidden_

| npcid | NPC | |
|---:|---|---|
| 17105413 | Geltpix  `Geltpix` |  |
| 17105694 | Hunt Registry  `Hunt_Registry` |  |
| 17105519 | Miliart, T.K.  `Miliart_TK` |  |
| 17105381 | Nembet  `Nembet` |  |

<details><summary>↳ 2 cutscene NPC(s) — review (possible mission steps)</summary>

Eauvague, T.K., Fiaudie

</details>

### West Ronfaure  (100)
_4 flavor candidate(s) · 2 functional kept · 35 scenery · 57 already hidden_

| npcid | NPC | |
|---:|---|---|
| 17187549 | Field Manual  `Field_Manual` |  |
| 17187550 | Field Manual  `Field_Manual` |  |
| 17187491 | Palcomondau  `Palcomondau` |  |
| 17187492 | Zovriace  `Zovriace` |  |

<details><summary>↳ 5 cutscene NPC(s) — review (possible mission steps)</summary>

Signpost

</details>

### La Theine Plateau  (102)
_4 flavor candidate(s) · 8 functional kept · 128 scenery · 75 already hidden_

| npcid | NPC | |
|---:|---|---|
| 17195682 | Field Manual  `Field_Manual` |  |
| 17195683 | Field Manual  `Field_Manual` |  |
| 17195726 | Geomantic Reservoir  `Geomantic_Reservoir` |  |
| 17195729 | Geomantic Reservoir  `Geomantic_Reservoir_2` |  |

<details><summary>↳ 1 cutscene NPC(s) — review (possible mission steps)</summary>

Dimensional Portal

</details>

### Xarcabard  (112)
_4 flavor candidate(s) · 5 functional kept · 41 scenery · 69 already hidden_

| npcid | NPC | |
|---:|---|---|
| 17236354 | Field Manual  `Field_Manual` |  |
| 17236355 | Field Manual  `Field_Manual` |  |
| 17236371 | Geomantic Reservoir  `Geomantic_Reservoir` |  |
| 17236333 | Trail Markings  `Trail_Markings` |  |

<details><summary>↳ 1 cutscene NPC(s) — review (possible mission steps)</summary>

Perennial Snow

</details>

### Yuhtunga Jungle  (123)
_4 flavor candidate(s) · 14 functional kept · 68 scenery · 56 already hidden_

| npcid | NPC | |
|---:|---|---|
| 17281657 | Field Manual  `Field_Manual` |  |
| 17281658 | Field Manual  `Field_Manual` |  |
| 17281659 | Field Manual  `Field_Manual` |  |
| 17281660 | Field Manual  `Field_Manual` |  |

### The Boyahda Tree  (153)
_4 flavor candidate(s) · 3 functional kept · 18 scenery · 35 already hidden_

| npcid | NPC | |
|---:|---|---|
| 17404414 | Grounds Tome  `Grounds_Tome` |  |
| 17404415 | Grounds Tome  `Grounds_Tome` |  |
| 17404416 | Grounds Tome  `Grounds_Tome` |  |
| 17404417 | Grounds Tome  `Grounds_Tome` |  |

### Middle Delkfutts Tower  (157)
_4 flavor candidate(s) · 1 functional kept · 13 scenery · 26 already hidden_

| npcid | NPC | |
|---:|---|---|
| 17420680 | Grounds Tome  `Grounds_Tome` |  |
| 17420681 | Grounds Tome  `Grounds_Tome` |  |
| 17420682 | Grounds Tome  `Grounds_Tome` |  |
| 17420683 | Grounds Tome  `Grounds_Tome` |  |

### Upper Delkfutts Tower  (158)
_4 flavor candidate(s) · 5 functional kept · 9 scenery · 27 already hidden_

| npcid | NPC | |
|---:|---|---|
| 17424569 | Geomantic Reservoir  `Geomantic_Reservoir` |  |
| 17424566 | Grounds Tome  `Grounds_Tome` |  |
| 17424567 | Grounds Tome  `Grounds_Tome` |  |
| 17424568 | Grounds Tome  `Grounds_Tome` |  |

### Ranguemont Pass  (166)
_4 flavor candidate(s) · 3 functional kept · 22 scenery · 41 already hidden_

| npcid | NPC | |
|---:|---|---|
| 17457384 | Geomagnetic Fount  `Geomagnetic_Fount` |  |
| 17457381 | Grounds Tome  `Grounds_Tome` |  |
| 17457382 | Grounds Tome  `Grounds_Tome` |  |
| 17457383 | Grounds Tome  `Grounds_Tome` |  |

<details><summary>↳ 1 cutscene NPC(s) — review (possible mission steps)</summary>

Myffore

</details>

### Bostaunieux Oubliette  (167)
_4 flavor candidate(s) · 2 functional kept · 57 scenery · 45 already hidden_

| npcid | NPC | |
|---:|---|---|
| 17461589 | Geomantic Reservoir  `Geomantic_Reservoir` |  |
| 17461586 | Grounds Tome  `Grounds_Tome` |  |
| 17461587 | Grounds Tome  `Grounds_Tome` |  |
| 17461588 | Grounds Tome  `Grounds_Tome` |  |

<details><summary>↳ 1 cutscene NPC(s) — review (possible mission steps)</summary>

Novalmauge

</details>

### Kuftal Tunnel  (174)
_4 flavor candidate(s) · 4 functional kept · 24 scenery · 39 already hidden_

| npcid | NPC | |
|---:|---|---|
| 17490326 | Grounds Tome  `Grounds_Tome` |  |
| 17490327 | Grounds Tome  `Grounds_Tome` |  |
| 17490328 | Grounds Tome  `Grounds_Tome` |  |
| 17490329 | Grounds Tome  `Grounds_Tome` |  |

### Lower Delkfutts Tower  (184)
_4 flavor candidate(s) · 2 functional kept · 60 scenery · 35 already hidden_

| npcid | NPC | |
|---:|---|---|
| 17531236 | Geomantic Reservoir  `Geomantic_Reservoir` |  |
| 17531233 | Grounds Tome  `Grounds_Tome` |  |
| 17531234 | Grounds Tome  `Grounds_Tome` |  |
| 17531235 | Grounds Tome  `Grounds_Tome` |  |

### Inner Horutoto Ruins  (192)
_4 flavor candidate(s) · 3 functional kept · 51 scenery · 27 already hidden_

| npcid | NPC | |
|---:|---|---|
| 17563927 | Geomagnetic Fount  `Geomagnetic_Fount` |  |
| 17563924 | Grounds Tome  `Grounds_Tome` |  |
| 17563925 | Grounds Tome  `Grounds_Tome` |  |
| 17563926 | Grounds Tome  `Grounds_Tome` |  |

### Ordelles Caves  (193)
_4 flavor candidate(s) · 6 functional kept · 17 scenery · 40 already hidden_

| npcid | NPC | |
|---:|---|---|
| 17568207 | Geomagnetic Fount  `Geomagnetic_Fount` |  |
| 17568205 | Grounds Tome  `Grounds_Tome` |  |
| 17568206 | Grounds Tome  `Grounds_Tome` |  |
| 17568171 | Ruillont  `Ruillont` |  |

### Crawlers Nest  (197)
_4 flavor candidate(s) · 11 functional kept · 14 scenery · 47 already hidden_

| npcid | NPC | |
|---:|---|---|
| 17584505 | Geomagnetic Fount  `Geomagnetic_Fount` |  |
| 17584506 | Geomantic Reservoir  `Geomantic_Reservoir` |  |
| 17584497 | Grounds Tome  `Grounds_Tome` |  |
| 17584498 | Grounds Tome  `Grounds_Tome` |  |

### Labyrinth of Onzozo  (213)
_4 flavor candidate(s) · 2 functional kept · 5 scenery · 28 already hidden_

| npcid | NPC | |
|---:|---|---|
| 17649906 | Geomagnetic Fount  `Geomagnetic_Fount` |  |
| 17649903 | Grounds Tome  `Grounds_Tome` |  |
| 17649904 | Grounds Tome  `Grounds_Tome` |  |
| 17649905 | Grounds Tome  `Grounds_Tome` |  |

### Abyssea-Altepa  (218)
_4 flavor candidate(s) · 38 functional kept · 56 scenery · 86 already hidden_

| npcid | NPC | |
|---:|---|---|
| 17670620 | Conflux Surveyor  `Conflux_Surveyor` |  |
| 17670778 | Dominion Sergeant  `DSgt_Excenmille` |  |
| 17670779 | Dominion Sergeant  `DSgt_Nanaa` |  |
| 17670780 | Dominion Sergeant  `DSgt_Volker` |  |

### Abyssea-Uleguerand  (253)
_4 flavor candidate(s) · 50 functional kept · 93 scenery · 76 already hidden_

| npcid | NPC | |
|---:|---|---|
| 17813978 | Conflux Surveyor  `Conflux_Surveyor` |  |
| 17814175 | Dominion Sergeant  `DSgt_Maat` |  |
| 17814176 | Dominion Sergeant  `DSgt_Romaa` |  |
| 17814177 | Dominion Sergeant  `DSgt_Zazarg` |  |

### Abyssea-Grauberg  (254)
_4 flavor candidate(s) · 42 functional kept · 55 scenery · 52 already hidden_

| npcid | NPC | |
|---:|---|---|
| 17818110 | Conflux Surveyor  `Conflux_Surveyor` |  |
| 17818271 | Dominion Sergeant  `DSgt_Wolfgang` |  |
| 17818272 | Dominion Sergeant  `DSgt_Cornelia` |  |
| 17818273 | Dominion Sergeant  `DSgt_Tosuka` |  |

### East Ronfaure  (101)
_3 flavor candidate(s) · 10 functional kept · 20 scenery · 54 already hidden_

| npcid | NPC | |
|---:|---|---|
| 17191539 | Field Manual  `Field_Manual` |  |
| 17191540 | Field Manual  `Field_Manual` |  |
| 17191583 | Geomantic Reservoir  `Geomantic_Reservoir` |  |

### Batallia Downs  (105)
_3 flavor candidate(s) · 9 functional kept · 100 scenery · 73 already hidden_

| npcid | NPC | |
|---:|---|---|
| 17207875 | Field Manual  `Field_Manual` |  |
| 17207876 | Field Manual  `Field_Manual` |  |
| 17207970 | Geomantic Reservoir  `Geomantic_Reservoir` |  |

### North Gustaberg  (106)
_3 flavor candidate(s) · 8 functional kept · 42 scenery · 56 already hidden_

| npcid | NPC | |
|---:|---|---|
| 17212110 | Field Manual  `Field_Manual` |  |
| 17212111 | Field Manual  `Field_Manual` |  |
| 17212112 | Field Manual  `Field_Manual` |  |

### Konschtat Highlands  (108)
_3 flavor candidate(s) · 5 functional kept · 67 scenery · 53 already hidden_

| npcid | NPC | |
|---:|---|---|
| 17220170 | Field Manual  `Field_Manual` |  |
| 17220171 | Field Manual  `Field_Manual` |  |
| 17220213 | Geomantic Reservoir  `Geomantic_Reservoir` |  |

<details><summary>↳ 1 cutscene NPC(s) — review (possible mission steps)</summary>

Dimensional Portal

</details>

### Rolanberry Fields  (110)
_3 flavor candidate(s) · 7 functional kept · 28 scenery · 55 already hidden_

| npcid | NPC | |
|---:|---|---|
| 17228382 | Field Manual  `Field_Manual` |  |
| 17228383 | Field Manual  `Field_Manual` |  |
| 17228423 | Geomantic Reservoir  `Geomantic_Reservoir` |  |

### Eastern Altepa Desert  (114)
_3 flavor candidate(s) · 5 functional kept · 40 scenery · 43 already hidden_

| npcid | NPC | |
|---:|---|---|
| 17244657 | Field Manual  `Field_Manual` |  |
| 17244658 | Field Manual  `Field_Manual` |  |
| 17244659 | Field Manual  `Field_Manual` |  |

### Meriphataud Mountains  (119)
_3 flavor candidate(s) · 4 functional kept · 57 scenery · 49 already hidden_

| npcid | NPC | |
|---:|---|---|
| 17265295 | Field Manual  `Field_Manual` |  |
| 17265296 | Field Manual  `Field_Manual` |  |
| 17265297 | Field Manual  `Field_Manual` |  |

### Sauromugue Champaign  (120)
_3 flavor candidate(s) · 5 functional kept · 36 scenery · 67 already hidden_

| npcid | NPC | |
|---:|---|---|
| 17269267 | Field Manual  `Field_Manual` |  |
| 17269268 | Field Manual  `Field_Manual` |  |
| 17269304 | Geomantic Reservoir  `Geomantic_Reservoir` |  |

### Yhoator Jungle  (124)
_3 flavor candidate(s) · 15 functional kept · 42 scenery · 63 already hidden_

| npcid | NPC | |
|---:|---|---|
| 17285702 | Field Manual  `Field_Manual` |  |
| 17285703 | Field Manual  `Field_Manual` |  |
| 17285704 | Field Manual  `Field_Manual` |  |

### Davoi  (149)
_3 flavor candidate(s) · 7 functional kept · 43 scenery · 25 already hidden_

| npcid | NPC | |
|---:|---|---|
| 17387999 | _(unnamed)_ `_454` |  |
| 17388053 | Geomantic Reservoir  `Geomantic_Reservoir` |  |
| 17387991 | Quemaricond  `Quemaricond` |  |

### Dangruf Wadi  (191)
_3 flavor candidate(s) · 5 functional kept · 17 scenery · 35 already hidden_

| npcid | NPC | |
|---:|---|---|
| 17559938 | Geomagnetic Fount  `Geomagnetic_Fount` |  |
| 17559936 | Grounds Tome  `Grounds_Tome` |  |
| 17559937 | Grounds Tome  `Grounds_Tome` |  |

### Ship bound for Selbina  (220)
_3 flavor candidate(s) · 0 functional kept · 7 scenery · 10 already hidden_

| npcid | NPC | |
|---:|---|---|
| 17678361 | Bhagirath  `Bhagirath` |  |
| 17678362 | Maera  `Maera` |  |
| 17678363 | Rajmonda  `Rajmonda` |  |

### Ship bound for Mhaura  (221)
_3 flavor candidate(s) · 0 functional kept · 7 scenery · 10 already hidden_

| npcid | NPC | |
|---:|---|---|
| 17682457 | Chhaya  `Chhaya` |  |
| 17682458 | Lokhong  `Lokhong` |  |
| 17682456 | Sahn  `Sahn` |  |

### Ship bound for Selbina Pirates  (227)
_3 flavor candidate(s) · 0 functional kept · 8 scenery · 14 already hidden_

| npcid | NPC | |
|---:|---|---|
| 17707037 | Bhagirath  `Bhagirath` |  |
| 17707038 | Maera  `Maera` |  |
| 17707039 | Rajmonda  `Rajmonda` |  |

### Ship bound for Mhaura Pirates  (228)
_3 flavor candidate(s) · 0 functional kept · 8 scenery · 19 already hidden_

| npcid | NPC | |
|---:|---|---|
| 17711133 | Chhaya  `Chhaya` |  |
| 17711134 | Lokhong  `Lokhong` |  |
| 17711132 | Sahn  `Sahn` |  |

### Abyssea-Konschtat  (15)
_2 flavor candidate(s) · 69 functional kept · 68 scenery · 50 already hidden_

| npcid | NPC | |
|---:|---|---|
| 16839107 | Conflux Surveyor  `Conflux_Surveyor` |  |
| 16839108 | Cruor Prospector  `Cruor_Prospector` |  |

### Abyssea-Tahrongi  (45)
_2 flavor candidate(s) · 39 functional kept · 69 scenery · 101 already hidden_

| npcid | NPC | |
|---:|---|---|
| 16961982 | Conflux Surveyor  `Conflux_Surveyor` |  |
| 16961983 | Cruor Prospector  `Cruor_Prospector` |  |

### Open sea route to Al Zahbi  (46)
_2 flavor candidate(s) · 0 functional kept · 8 scenery · 17 already hidden_

| npcid | NPC | |
|---:|---|---|
| 16965670 | Adeben  `Adeben` |  |
| 16965678 | Cehn Teyohngo  `Cehn_Teyohngo` |  |

### Open sea route to Mhaura  (47)
_2 flavor candidate(s) · 0 functional kept · 7 scenery · 10 already hidden_

| npcid | NPC | |
|---:|---|---|
| 16969774 | Pashi Maccaleh  `Pashi_Maccaleh` |  |
| 16969766 | Sheadon  `Sheadon` |  |

### Arrapago Reef  (54)
_2 flavor candidate(s) · 9 functional kept · 128 scenery · 53 already hidden_

| npcid | NPC | |
|---:|---|---|
| 16999054 | Cutter  `Cutter` |  |
| 16998996 | Runic Seal  `_jic` |  |

### Silver Sea route to Nashmau  (58)
_2 flavor candidate(s) · 0 functional kept · 8 scenery · 10 already hidden_

| npcid | NPC | |
|---:|---|---|
| 17014832 | Jidwahn  `Jidwahn` |  |
| 17014823 | Qudamahf  `Qudamahf` |  |

### Silver Sea route to Al Zahbi  (59)
_2 flavor candidate(s) · 0 functional kept · 8 scenery · 10 already hidden_

| npcid | NPC | |
|---:|---|---|
| 17018919 | Shadeeu  `Shadeeu` |  |
| 17018928 | Yahliq  `Yahliq` |  |

### Caedarva Mire  (79)
_2 flavor candidate(s) · 20 functional kept · 44 scenery · 45 already hidden_

| npcid | NPC | |
|---:|---|---|
| 17101318 | Runic Seal  `_272` |  |
| 17101321 | Runic Seal  `_273` |  |

### Jugner Forest  (104)
_2 flavor candidate(s) · 4 functional kept · 96 scenery · 87 already hidden_

| npcid | NPC | |
|---:|---|---|
| 17203887 | Field Manual  `Field_Manual` |  |
| 17203888 | Field Manual  `Field_Manual` |  |

<details><summary>↳ 5 cutscene NPC(s) — review (possible mission steps)</summary>

Alexius, Signpost

</details>

### South Gustaberg  (107)
_2 flavor candidate(s) · 4 functional kept · 62 scenery · 65 already hidden_

| npcid | NPC | |
|---:|---|---|
| 17216186 | Field Manual  `Field_Manual` |  |
| 17216187 | Field Manual  `Field_Manual` |  |

### Pashhow Marshlands  (109)
_2 flavor candidate(s) · 3 functional kept · 61 scenery · 49 already hidden_

| npcid | NPC | |
|---:|---|---|
| 17224355 | Field Manual  `Field_Manual` |  |
| 17224356 | Field Manual  `Field_Manual` |  |

### Cape Teriggan  (113)
_2 flavor candidate(s) · 3 functional kept · 25 scenery · 60 already hidden_

| npcid | NPC | |
|---:|---|---|
| 17240521 | Field Manual  `Field_Manual` |  |
| 17240522 | Field Manual  `Field_Manual` |  |

### The Sanctuary of ZiTah  (121)
_2 flavor candidate(s) · 3 functional kept · 37 scenery · 53 already hidden_

| npcid | NPC | |
|---:|---|---|
| 17273421 | Field Manual  `Field_Manual` |  |
| 17273422 | Field Manual  `Field_Manual` |  |

### RoMaeve  (122)
_2 flavor candidate(s) · 5 functional kept · 29 scenery · 43 already hidden_

| npcid | NPC | |
|---:|---|---|
| 17277232 | Field Manual  `Field_Manual` |  |
| 17277233 | Field Manual  `Field_Manual` |  |

### Behemoths Dominion  (127)
_2 flavor candidate(s) · 2 functional kept · 9 scenery · 37 already hidden_

| npcid | NPC | |
|---:|---|---|
| 17297495 | Field Manual  `Field_Manual` |  |
| 17297508 | Geomantic Reservoir  `Geomantic_Reservoir` |  |

### Valley of Sorrows  (128)
_2 flavor candidate(s) · 3 functional kept · 22 scenery · 33 already hidden_

| npcid | NPC | |
|---:|---|---|
| 17301596 | Field Manual  `Field_Manual` |  |
| 17301597 | Field Manual  `Field_Manual` |  |

### Abyssea-La Theine  (132)
_2 flavor candidate(s) · 42 functional kept · 70 scenery · 86 already hidden_

| npcid | NPC | |
|---:|---|---|
| 17318502 | Conflux Surveyor  `Conflux_Surveyor` |  |
| 17318503 | Cruor Prospector  `Cruor_Prospector` |  |

### Palborough Mines  (143)
_2 flavor candidate(s) · 17 functional kept · 16 scenery · 13 already hidden_

| npcid | NPC | |
|---:|---|---|
| 17363347 | _(unnamed)_ `@3z0` |  |
| 17363380 | Geomagnetic Fount  `Geomagnetic_Fount` |  |

### The Eldieme Necropolis [S]  (175)
_2 flavor candidate(s) · 3 functional kept · 81 scenery · 31 already hidden_

| npcid | NPC | |
|---:|---|---|
| 17494720 | Layton  `Layton` |  |
| 17494747 | Lennart  `Lennart` |  |

### San dOria-Jeuno Airship  (223)
_2 flavor candidate(s) · 0 functional kept · 1 scenery · 19 already hidden_

| npcid | NPC | |
|---:|---|---|
| 17690625 | Nigel  `Nigel` |  |
| 17690626 | Ricaldo  `Ricaldo` |  |

### Bastok-Jeuno Airship  (224)
_2 flavor candidate(s) · 0 functional kept · 0 scenery · 19 already hidden_

| npcid | NPC | |
|---:|---|---|
| 17694721 | Dereck  `Dereck` |  |
| 17694722 | Michele  `Michele` |  |

### Windurst-Jeuno Airship  (225)
_2 flavor candidate(s) · 0 functional kept · 0 scenery · 17 already hidden_

| npcid | NPC | |
|---:|---|---|
| 17698818 | Gabriele  `Gabriele` |  |
| 17698817 | Mauricio  `Mauricio` |  |

### Kazham-Jeuno Airship  (226)
_2 flavor candidate(s) · 0 functional kept · 0 scenery · 20 already hidden_

| npcid | NPC | |
|---:|---|---|
| 17702914 | Joosef  `Joosef` |  |
| 17702915 | Oslam  `Oslam` |  |

### Heavens Tower  (242)
_2 flavor candidate(s) · 6 functional kept · 93 scenery · 14 already hidden_

| npcid | NPC | |
|---:|---|---|
| 17768504 | Chuqui-Chanqui  `Chuqui-Chanqui` |  |
| 17768567 | Jerrett  `Jerrett` |  |

<details><summary>↳ 3 cutscene NPC(s) — review (possible mission steps)</summary>

Gamimi, Jatata, Rakano-Marukano

</details>

### Morimar Basalt Fields  (265)
_2 flavor candidate(s) · 7 functional kept · 121 scenery · 47 already hidden_

| npcid | NPC | |
|---:|---|---|
| 17863463 | Geomantic Reservoir  `Geomantic_Reservoir` |  |
| 17863466 | Geomantic Reservoir  `Geomantic_Reservoir_2` |  |

### Manaclipper  (3)
_1 flavor candidate(s) · 0 functional kept · 3 scenery · 11 already hidden_

| npcid | NPC | |
|---:|---|---|
| 16789530 | Gniyah Mischatt  `Gniyah_Mischatt` |  |

### Dynamis-Valkurm  (39)
_1 flavor candidate(s) · 4 functional kept · 0 scenery · 11 already hidden_

| npcid | NPC | |
|---:|---|---|
| 16937585 | Somnial Threshold  `Somnial_Threshold` |  |

### Dynamis-Buburimu  (40)
_1 flavor candidate(s) · 5 functional kept · 0 scenery · 17 already hidden_

| npcid | NPC | |
|---:|---|---|
| 16941676 | Somnial Threshold  `Somnial_Threshold` |  |

### Dynamis-Qufim  (41)
_1 flavor candidate(s) · 4 functional kept · 0 scenery · 12 already hidden_

| npcid | NPC | |
|---:|---|---|
| 16945638 | Somnial Threshold  `Somnial_Threshold` |  |

### Dynamis-Tavnazia  (42)
_1 flavor candidate(s) · 1 functional kept · 0 scenery · 15 already hidden_

| npcid | NPC | |
|---:|---|---|
| 16949396 | Somnial Threshold  `Somnial_Threshold` |  |

### Bhaflau Thickets  (52)
_1 flavor candidate(s) · 9 functional kept · 14 scenery · 26 already hidden_

| npcid | NPC | |
|---:|---|---|
| 16990627 | Runic Seal  `_1g2` |  |

<details><summary>↳ 1 cutscene NPC(s) — review (possible mission steps)</summary>

Postern

</details>

### Mount Zhayolm  (61)
_1 flavor candidate(s) · 12 functional kept · 53 scenery · 44 already hidden_

| npcid | NPC | |
|---:|---|---|
| 17027541 | Runic Seal  `_1p3` |  |

### Zhayolm Remnants  (73)
_1 flavor candidate(s) · 0 functional kept · 1 scenery · 22 already hidden_

| npcid | NPC | |
|---:|---|---|
| 17076968 | Gilded Gateway  `_21i` |  |

<details><summary>↳ 17 cutscene NPC(s) — review (possible mission steps)</summary>

Gilded Doors

</details>

### Bhaflau Remnants  (75)
_1 flavor candidate(s) · 0 functional kept · 3 scenery · 25 already hidden_

| npcid | NPC | |
|---:|---|---|
| 17084923 | Gilded Gateway  `_23x` |  |

<details><summary>↳ 32 cutscene NPC(s) — review (possible mission steps)</summary>

Gilded Doors

</details>

### Nyzul Isle  (77)
_1 flavor candidate(s) · 2 functional kept · 118 scenery · 30 already hidden_

| npcid | NPC | |
|---:|---|---|
| 17093431 | Vending Box  `Vending_Box` |  |

### North Gustaberg [S]  (88)
_1 flavor candidate(s) · 9 functional kept · 106 scenery · 35 already hidden_

| npcid | NPC | |
|---:|---|---|
| 17138603 | Stonehoused Adit  `Stonehoused_Adit` |  |

### Dynamis-Beaucedine  (134)
_1 flavor candidate(s) · 10 functional kept · 0 scenery · 10 already hidden_

| npcid | NPC | |
|---:|---|---|
| 17326800 | Somnial Threshold  `Somnial_Threshold` |  |

### Dynamis-Xarcabard  (135)
_1 flavor candidate(s) · 21 functional kept · 2 scenery · 16 already hidden_

| npcid | NPC | |
|---:|---|---|
| 17330780 | Somnial Threshold  `Somnial_Threshold` |  |

### Fort Ghelsba  (141)
_1 flavor candidate(s) · 2 functional kept · 7 scenery · 10 already hidden_

| npcid | NPC | |
|---:|---|---|
| 17354993 | _(unnamed)_ `@3x0` |  |

### Yughott Grotto  (142)
_1 flavor candidate(s) · 8 functional kept · 26 scenery · 28 already hidden_

| npcid | NPC | |
|---:|---|---|
| 17359094 | Geomagnetic Fount  `Geomagnetic_Fount` |  |

### Qulun Dome  (148)
_1 flavor candidate(s) · 2 functional kept · 16 scenery · 20 already hidden_

| npcid | NPC | |
|---:|---|---|
| 17383473 | The Mute  `The_Mute` |  |

### Monastic Cavern  (150)
_1 flavor candidate(s) · 2 functional kept · 24 scenery · 15 already hidden_

| npcid | NPC | |
|---:|---|---|
| 17391861 | Geomagnetic Fount  `Geomagnetic_Fount` |  |

### Zeruhn Mines  (172)
_1 flavor candidate(s) · 7 functional kept · 39 scenery · 33 already hidden_

| npcid | NPC | |
|---:|---|---|
| 17481855 | Grounds Tome  `Grounds_Tome` |  |

<details><summary>↳ 1 cutscene NPC(s) — review (possible mission steps)</summary>

Lasthenes

</details>

### Dynamis-San dOria  (185)
_1 flavor candidate(s) · 5 functional kept · 0 scenery · 16 already hidden_

| npcid | NPC | |
|---:|---|---|
| 17535223 | Somnial Threshold  `Somnial_Threshold` |  |

### Dynamis-Bastok  (186)
_1 flavor candidate(s) · 5 functional kept · 0 scenery · 12 already hidden_

| npcid | NPC | |
|---:|---|---|
| 17539322 | Somnial Threshold  `Somnial_Threshold` |  |

### Dynamis-Windurst  (187)
_1 flavor candidate(s) · 5 functional kept · 0 scenery · 12 already hidden_

| npcid | NPC | |
|---:|---|---|
| 17543479 | Somnial Threshold  `Somnial_Threshold` |  |

### Dynamis-Jeuno  (188)
_1 flavor candidate(s) · 5 functional kept · 0 scenery · 16 already hidden_

| npcid | NPC | |
|---:|---|---|
| 17547509 | Somnial Threshold  `Somnial_Threshold` |  |

### Abyssea-Attohwa  (215)
_1 flavor candidate(s) · 42 functional kept · 166 scenery · 96 already hidden_

| npcid | NPC | |
|---:|---|---|
| 17658383 | Conflux Surveyor  `Conflux_Surveyor` |  |

### Abyssea-Misareaux  (216)
_1 flavor candidate(s) · 52 functional kept · 89 scenery · 97 already hidden_

| npcid | NPC | |
|---:|---|---|
| 17662588 | Conflux Surveyor  `Conflux_Surveyor` |  |

### Abyssea-Vunkerl  (217)
_1 flavor candidate(s) · 52 functional kept · 83 scenery · 68 already hidden_

| npcid | NPC | |
|---:|---|---|
| 17666608 | Conflux Surveyor  `Conflux_Surveyor` |  |

### Abyssea-Empyreal Paradox  (255)
_1 flavor candidate(s) · 2 functional kept · 7 scenery · 14 already hidden_

| npcid | NPC | |
|---:|---|---|
| 17821710 | Cruor Prospector  `Cruor_Prospector` |  |

### Eastern Adoulin  (257)
_1 flavor candidate(s) · 20 functional kept · 223 scenery · 87 already hidden_

| npcid | NPC | |
|---:|---|---|
| 17830000 | Symphonic Curator  `Symphonic_Curator` |  |

<details><summary>↳ 2 cutscene NPC(s) — review (possible mission steps)</summary>

Eppel-Treppel, Iyvah Halohm

</details>

### Yahse Hunting Grounds  (260)
_1 flavor candidate(s) · 5 functional kept · 75 scenery · 76 already hidden_

| npcid | NPC | |
|---:|---|---|
| 17842745 | Geomantic Reservoir  `Geomantic_Reservoir` |  |

### Ceizak Battlegrounds  (261)
_1 flavor candidate(s) · 10 functional kept · 81 scenery · 63 already hidden_

| npcid | NPC | |
|---:|---|---|
| 17846847 | Geomantic Reservoir  `Geomantic_Reservoir` |  |

### Foret de Hennetiel  (262)
_1 flavor candidate(s) · 6 functional kept · 100 scenery · 31 already hidden_

| npcid | NPC | |
|---:|---|---|
| 17850958 | Geomantic Reservoir  `Geomantic_Reservoir` |  |

### Marjami Ravine  (266)
_1 flavor candidate(s) · 6 functional kept · 104 scenery · 49 already hidden_

| npcid | NPC | |
|---:|---|---|
| 17867256 | Geomantic Reservoir  `Geomantic_Reservoir` |  |

### Spire of Holla  (17)
_0 flavor candidate(s) · 0 functional kept · 17 scenery · 17 already hidden_

<details><summary>↳ 1 cutscene NPC(s) — review (possible mission steps)</summary>

Radiant Aureole

</details>

### Spire of Dem  (19)
_0 flavor candidate(s) · 0 functional kept · 16 scenery · 18 already hidden_

<details><summary>↳ 1 cutscene NPC(s) — review (possible mission steps)</summary>

Radiant Aureole

</details>

### Spire of Mea  (21)
_0 flavor candidate(s) · 0 functional kept · 16 scenery · 18 already hidden_

<details><summary>↳ 1 cutscene NPC(s) — review (possible mission steps)</summary>

Radiant Aureole

</details>

### Spire of Vahzl  (23)
_0 flavor candidate(s) · 0 functional kept · 21 scenery · 14 already hidden_

<details><summary>↳ 1 cutscene NPC(s) — review (possible mission steps)</summary>

Radiant Aureole

</details>

### Misareaux Coast  (25)
_0 flavor candidate(s) · 11 functional kept · 46 scenery · 35 already hidden_

<details><summary>↳ 1 cutscene NPC(s) — review (possible mission steps)</summary>

Spatial Displacement

</details>

### Riverne-Site B01  (29)
_0 flavor candidate(s) · 5 functional kept · 16 scenery · 15 already hidden_

<details><summary>↳ 35 cutscene NPC(s) — review (possible mission steps)</summary>

Spatial Displacement

</details>

### Riverne-Site A01  (30)
_0 flavor candidate(s) · 5 functional kept · 18 scenery · 14 already hidden_

<details><summary>↳ 32 cutscene NPC(s) — review (possible mission steps)</summary>

Spatial Displacement

</details>

### Monarch Linn  (31)
_0 flavor candidate(s) · 1 functional kept · 58 scenery · 10 already hidden_

<details><summary>↳ 1 cutscene NPC(s) — review (possible mission steps)</summary>

Spatial Displacement

</details>

### AlTaieu  (33)
_0 flavor candidate(s) · 7 functional kept · 68 scenery · 18 already hidden_

<details><summary>↳ 11 cutscene NPC(s) — review (possible mission steps)</summary>

Auroral Updraft, Dimensional Portal, Swirling Vortex

</details>

### Wajaom Woodlands  (51)
_0 flavor candidate(s) · 8 functional kept · 165 scenery · 55 already hidden_

<details><summary>↳ 1 cutscene NPC(s) — review (possible mission steps)</summary>

Postern

</details>

### Mamook  (65)
_0 flavor candidate(s) · 4 functional kept · 63 scenery · 68 already hidden_

<details><summary>↳ 6 cutscene NPC(s) — review (possible mission steps)</summary>

Viscous Liquid

</details>

### Arrapago Remnants  (74)
_0 flavor candidate(s) · 0 functional kept · 4 scenery · 11 already hidden_

<details><summary>↳ 17 cutscene NPC(s) — review (possible mission steps)</summary>

Gilded Doors

</details>

### Jugner Forest [S]  (82)
_0 flavor candidate(s) · 6 functional kept · 112 scenery · 67 already hidden_

<details><summary>↳ 1 cutscene NPC(s) — review (possible mission steps)</summary>

Roiloux, R.K.

</details>

### Fort Karugo-Narugo [S]  (96)
_0 flavor candidate(s) · 4 functional kept · 146 scenery · 72 already hidden_

<details><summary>↳ 1 cutscene NPC(s) — review (possible mission steps)</summary>

Rotih Moalghett

</details>

### Meriphataud Mountains [S]  (97)
_0 flavor candidate(s) · 5 functional kept · 87 scenery · 77 already hidden_

<details><summary>↳ 1 cutscene NPC(s) — review (possible mission steps)</summary>

Iron Portcullis

</details>

### Beaucedine Glacier [S]  (136)
_0 flavor candidate(s) · 1 functional kept · 146 scenery · 67 already hidden_

<details><summary>↳ 2 cutscene NPC(s) — review (possible mission steps)</summary>

Moana, C.A., Watchful Pixie

</details>

### Xarcabard [S]  (137)
_0 flavor candidate(s) · 1 functional kept · 210 scenery · 61 already hidden_

<details><summary>↳ 1 cutscene NPC(s) — review (possible mission steps)</summary>

Zvahl Portcullis

</details>

### Garlaige Citadel [S]  (164)
_0 flavor candidate(s) · 2 functional kept · 95 scenery · 92 already hidden_

<details><summary>↳ 1 cutscene NPC(s) — review (possible mission steps)</summary>

Randecque

</details>

### Walk of Echoes  (182)
_0 flavor candidate(s) · 0 functional kept · 91 scenery · 32 already hidden_

<details><summary>↳ 2 cutscene NPC(s) — review (possible mission steps)</summary>

Veridical Conflux

</details>

### Chateau dOraguille  (233)
_0 flavor candidate(s) · 5 functional kept · 67 scenery · 22 already hidden_

<details><summary>↳ 4 cutscene NPC(s) — review (possible mission steps)</summary>

Faurie, Halver, Perfaumand

</details>

### Hall of the Gods  (251)
_0 flavor candidate(s) · 1 functional kept · 15 scenery · 27 already hidden_

<details><summary>↳ 2 cutscene NPC(s) — review (possible mission steps)</summary>

Shimmering Circle

</details>

### Kamihr Drifts  (267)
_0 flavor candidate(s) · 6 functional kept · 67 scenery · 72 already hidden_

<details><summary>↳ 1 cutscene NPC(s) — review (possible mission steps)</summary>

Blockaded Path

</details>

### Outer RaKaznar  (274)
_0 flavor candidate(s) · 0 functional kept · 83 scenery · 22 already hidden_

<details><summary>↳ 5 cutscene NPC(s) — review (possible mission steps)</summary>

Entwined Roots

</details>

### Feretory  (285)
_0 flavor candidate(s) · 4 functional kept · 3 scenery · 9 already hidden_

<details><summary>↳ 1 cutscene NPC(s) — review (possible mission steps)</summary>

Suibhne

</details>
