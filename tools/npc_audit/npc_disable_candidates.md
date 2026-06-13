# NPC Disable Audit — review list

_Generated 2026-06-13 05:07 UTC. **Disables nothing** — this is a candidate list to review. The eventual mechanism is `status=2` (DISAPPEAR): reversible, and the entity still loads so nothing nil-crashes._

## Summary

- **31,047 NPCs** total; **19,266 not normal-visible** (status≠0 — already hidden, invisible, or cutscene-only); 0 in unmapped/system zones (skipped).
- Of the visible, scripted NPCs: **2,400 functional** (keep), **590 flavor candidates**, **459 cutscene (review)**.
- **8,114 scenery** NPCs (no script) — left alone here; hiding the ambient crowd would make zones look dead.
- **218 doors / lamps / ??? markers / furniture** — excluded from the candidate list (infrastructure & puzzle pieces, not townsfolk).

**Legend:** `[ref]` = this NPC is referenced by a `GetNPCByID(...)` call somewhere (usually harmless under status=2, but eyeball it). Cutscene NPCs are listed separately per zone because hiding one *could* block a mission step.

## Candidates by zone (most flavor-clutter first)

### Port Windurst  (240)
_26 flavor candidate(s) · 34 functional kept · 101 scenery · 103 already hidden_

| npcid | NPC | |
|---:|---|---|
| 17760320 | Alizabe  `Alizabe` |  |
| 17760312 | Aroro  `Aroro` |  |
| 17760306 | Babubu  `Babubu` |  |
| 17760405 | Drozga  `Drozga` |  |
| 17760315 | Guruna-Maguruna  `Guruna-Maguruna` |  |
| 17760313 | Hohbiba-Mubiba  `Hohbiba-Mubiba` |  |
| 17760323 | Khel Pahlhama  `Khel_Pahlhama` |  |
| 17760438 | Kucha Malkobhi  `Kucha_Malkobhi` |  |
| 17760316 | Kumama  `Kumama` |  |
| 17760311 | Kususu  `Kususu` |  |
| 17760435 | Lebondur  `Lebondur` |  |
| 17760352 | Machichi  `Machichi` |  |
| 17760277 | Mojo-Pojo  `Mojo-Pojo` |  |
| 17760356 | Mosusu  `Mosusu` |  |
| 17760369 | Mov Lingyoh  `Mov_Lingyoh` |  |
| 17760285 | Noragu-Meragu  `Noragu-Meragu` |  |
| 17760317 | Posso Ruhbini  `Posso_Ruhbini` |  |
| 17760286 | Rachuchu  `Rachuchu` |  |
| 17760361 | Reiso-Haroiso  `Reiso-Haroiso` |  |
| 17760404 | Ryan  `Ryan` |  |
| 17760436 | Sattsuh Ahkanpari  `Sattsuh_Ahkanpari` |  |
| 17760391 | Seven of Clubs  `Seven_of_Clubs` |  |
| 17760318 | Sheia Pohrichamaha  `Sheia_Pohrichamaha` |  |
| 17760314 | Taniko-Maniko  `Taniko-Maniko` |  |
| 17760337 | Uli Pehkowa  `Uli_Pehkowa` |  |
| 17760319 | Zoreen  `Zoreen` |  |

<details><summary>↳ 10 cutscene NPC(s) — review (possible mission steps)</summary>

Choyi Totlihpa, Five of Clubs, Goltata, Janshura-Rashura, Kameel, Kunchichi, Martin, Three of Clubs, Tohopka, Yaman-Hachuman

</details>

### Aht Urhgan Whitegate  (50)
_21 flavor candidate(s) · 46 functional kept · 120 scenery · 433 already hidden_

| npcid | NPC | |
|---:|---|---|
| 16982097 | Bajahb  `Bajahb` |  |
| 16982041 | Baya Hiramayuh  `Baya_Hiramayuh` |  |
| 16982093 | Dwago  `Dwago` |  |
| 16982099 | Fayeewah  `Fayeewah` |  |
| 16982102 | Gathweeda  `Gathweeda` |  |
| 16982088 | Gavrie  `Gavrie` |  |
| 16982096 | Hagakoff  `Hagakoff` |  |
| 16982148 | Hashayra  `Hashayra` |  |
| 16982151 | Kazween  `Kazween` |  |
| 16982095 | Khaf Jhifanm  `Khaf_Jhifanm` |  |
| 16982040 | Kuhn Tsahnpri  `Kuhn_Tsahnpri` |  |
| 16982094 | Kulh Amariyo  `Kulh_Amariyo` |  |
| 16982089 | Malfud  `Malfud` |  |
| 16982152 | Mariyaam  `Mariyaam` |  |
| 16982098 | Mazween  `Mazween` |  |
| 16982091 | Mulnith  `Mulnith` |  |
| 16982090 | Rubahah  `Rubahah` |  |
| 16982092 | Saluhwa  `Saluhwa` |  |
| 16982101 | Wahnid  `Wahnid` |  |
| 16982103 | Wahraga  `Wahraga` |  |
| 16982100 | Yafaaf  `Yafaaf` |  |

<details><summary>↳ 9 cutscene NPC(s) — review (possible mission steps)</summary>

Abda-Lurabda, Abquhbah, Burnished Bones, Esoteric Hound, Furious Boulder, Ghanraam, Jarafah, Somnolent Rooster, _(unnamed)_ `_1ee`

</details>

### Port Bastok  (236)
_21 flavor candidate(s) · 29 functional kept · 85 scenery · 195 already hidden_

| npcid | NPC | |
|---:|---|---|
| 17744032 | Bagnobrok  `Bagnobrok` |  |
| 17743908 | Belka  `Belka` |  |
| 17744007 | Blabbivix  `Blabbivix` |  |
| 17743969 | Cheh Raihah  `Cheh_Raihah` |  |
| 17743967 | Dahjal  `Dahjal` |  |
| 17743975 | Denvihr  `Denvihr` |  |
| 17744006 | Dhen Tevryukoh  `Dhen_Tevryukoh` |  |
| 17743898 | Evelyn  `Evelyn` |  |
| 17743906 | Galvin  `Galvin` |  |
| 17743936 | Hilda  `Hilda` |  |
| 17743974 | Ilita  `Ilita` |  |
| 17743888 | Melloa  `Melloa` |  |
| 17743968 | Mokop-Sankop  `Mokop-Sankop` |  |
| 17743970 | Nalta  `Nalta` |  |
| 17743907 | Numa  `Numa` |  |
| 17743933 | Rosswald  `Rosswald` |  |
| 17743887 | Sawyer  `Sawyer` |  |
| 17743976 | Sugandhi  `Sugandhi` |  |
| 17743966 | Valeriano  `Valeriano` |  |
| 17743923 | Vattian  `Vattian` |  |
| 17744005 | Zoby Quhyo  `Zoby_Quhyo` |  |

<details><summary>↳ 11 cutscene NPC(s) — review (possible mission steps)</summary>

Argus, Benita, Bodaway, Brita, Bruno, Ensetsu, Flaco, Gallagher, Kachada, Kagetora, _(unnamed)_ `_6kt`

</details>

### Windurst Waters  (238)
_21 flavor candidate(s) · 38 functional kept · 125 scenery · 266 already hidden_

| npcid | NPC | |
|---:|---|---|
| 17752104 | Baehu-Faehu  `Baehu-Faehu` |  |
| 17752196 | Caliburn  `Caliburn` |  |
| 17752140 | Chomo Jinjahl  `Chomo_Jinjahl` |  |
| 17752105 | Fomina  `Fomina` |  |
| 17752096 | Hilkomu-Makimu  `Hilkomu-Makimu` |  |
| 17752174 | Hororo  `Hororo` |  |
| 17752171 | Janta-Jonta  `Janta-Jonta` |  |
| 17752107 | Jourille  `Jourille` |  |
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
| 17752100 | Taajiji  `Taajiji` |  |
| 17752169 | Yohra-Ora  `Yohra-Ora` |  |

<details><summary>↳ 16 cutscene NPC(s) — review (possible mission steps)</summary>

Amagusa-Chigurusa, Angelica, Aramu-Paramu, Buchi Kohmrijah, Five of Hearts, Fuepepe, Funpo-Shipo, Furakku-Norakku, Lago-Charago, Mokyokyo, Moreno-Toeno, Npopo, Olaky-Yayulaky, Yuli Yaam, Yung Yaam, Zabirego-Hajigo

</details>

### The Shrine of RuAvitau  (178)
_20 flavor candidate(s) · 11 functional kept · 69 scenery · 45 already hidden_

| npcid | NPC | |
|---:|---|---|
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

### Bastok Markets  (235)
_20 flavor candidate(s) · 38 functional kept · 57 scenery · 237 already hidden_

| npcid | NPC | |
|---:|---|---|
| 17739803 | Balthilda  `Balthilda` |  |
| 17739797 | Belizieg  `Belizieg` |  |
| 17739801 | Brunhilde  `Brunhilde` |  |
| 17739810 | Carmelide  `Carmelide` |  |
| 17739799 | Ciqala  `Ciqala` |  |
| 17739808 | Harmodios  `Harmodios` |  |
| 17739812 | Hortense  `Hortense` |  |
| 17739796 | Khonzon  `Khonzon` |  |
| 17739804 | Mjoll  `Mjoll` |  |
| 17739819 | Oggodett  `Oggodett` |  |
| 17739800 | Peritrage  `Peritrage` |  |
| 17739811 | Raghd  `Raghd` |  |
| 17739822 | Somn-Paemn  `Somn-Paemn` |  |
| 17739807 | Sororo  `Sororo` |  |
| 17739788 | Teerth  `Teerth` |  |
| 17739789 | Visala  `Visala` |  |
| 17739823 | Yafafa  `Yafafa` |  |
| 17739806 | Zaira  `Zaira` |  |
| 17739798 | Zhikkom  `Zhikkom` |  |
| 17739841 | Zon-Fobun  `Zon-Fobun` |  |

<details><summary>↳ 3 cutscene NPC(s) — review (possible mission steps)</summary>

Ardea, Cleades, Rothais

</details>

### Windurst Woods  (241)
_20 flavor candidate(s) · 57 functional kept · 89 scenery · 287 already hidden_

| npcid | NPC | |
|---:|---|---|
| 17764461 | Bin Stejihna  `Bin_Stejihna` |  |
| 17764496 | Dazi Nosuk  `Dazi_Nosuk` |  |
| 17764483 | Dhahah  `Dhahah` |  |
| 17764481 | Dhahih  `Dhahih` |  |
| 17764482 | Dhakih  `Dhakih` |  |
| 17764484 | Dhakoh  `Dhakoh` |  |
| 17764518 | Eight of Spades  `Eight_of_Spades` |  |
| 17764449 | Ju Kamja  `Ju_Kamja` |  |
| 17764401 | Kuzah Hpirohpon  `Kuzah_Hpirohpon` |  |
| 17764456 | Manyny  `Manyny` |  |
| 17764400 | Meriri  `Meriri` |  |
| 17764455 | Mono Nchaa  `Mono_Nchaa` |  |
| 17764460 | Nya Labiccio  `Nya_Labiccio` |  |
| 17764487 | Orahi-Karapahi  `Orahi-Karapahi` |  |
| 17764500 | Patsaa Maehoc  `Patsaa_Maehoc` |  |
| 17764448 | Pew Sahbaraef  `Pew_Sahbaraef` |  |
| 17764407 | Retto-Marutto  `Retto-Marutto` |  |
| 17764492 | Seno Zarhin  `Seno_Zarhin` |  |
| 17764406 | Shih Tayuun  `Shih_Tayuun` |  |
| 17764459 | Wije Tiren  `Wije_Tiren` |  |

<details><summary>↳ 17 cutscene NPC(s) — review (possible mission steps)</summary>

Boizo-Naizo, Cayu Pensharhumi, Erpolant, Etsa Rhuyuli, Forine, Gottah Maporushanoh, Kopua-Mobua A.M.A.N., Matata, Mheca Khetashipah, Rakoh Buuma, Spare Five, Spare Four, Spare One, Spare Three, Spare Two, Sunana, Wani Casdohry

</details>

### West Sarutabaruta  (115)
_19 flavor candidate(s) · 7 functional kept · 14 scenery · 95 already hidden_

| npcid | NPC | |
|---:|---|---|
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

### Lower Jeuno  (245)
_19 flavor candidate(s) · 31 functional kept · 78 scenery · 135 already hidden_

| npcid | NPC | |
|---:|---|---|
| 17780854 | _(unnamed)_ `rarabcaged` |  |
| 17780855 | _(unnamed)_ `rarabcaged` |  |
| 17780861 | Adelflete  `Adelflete` |  |
| 17780865 | Chenokih  `Chenokih` |  |
| 17780864 | Chetak  `Chetak` |  |
| 17780859 | Creepstix  `Creepstix` |  |
| 17780742 | Ghebi Damomohe  `Ghebi_Damomohe` |  |
| 17780866 | Hasim  `Hasim` |  |
| 17780863 | Matoaka  `Matoaka` |  |
| 17780846 | Mesukiki  `Mesukiki` |  |
| 17780862 | Morefie  `Morefie` |  |
| 17780785 | Nakho Jawantal  `Nakho_Jawantal` |  |
| 17780794 | Navisse  `Navisse` |  |
| 17780787 | Omer  `Omer` |  |
| 17780760 | Pawkrix  `Pawkrix` |  |
| 17780841 | Stinknix  `Stinknix` |  |
| 17780845 | Subash  `Subash` |  |
| 17780867 | Susu  `Susu` |  |
| 17780842 | Yoskolo  `Yoskolo` |  |

<details><summary>↳ 9 cutscene NPC(s) — review (possible mission steps)</summary>

Darcia, Mataligeat, Mendi, Mertaire, Ruslan, Sutarara, Teigero-Bangero, Tovrutaux, Vingijard

</details>

### East Sarutabaruta  (116)
_18 flavor candidate(s) · 3 functional kept · 14 scenery · 80 already hidden_

| npcid | NPC | |
|---:|---|---|
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

### Southern San dOria  (230)
_18 flavor candidate(s) · 61 functional kept · 92 scenery · 467 already hidden_

| npcid | NPC | |
|---:|---|---|
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
| 17719351 | Ostalie  `Ostalie` |  |
| 17719488 | Paunelie  `Paunelie` |  |
| 17719321 | Shilah  `Shilah` |  |
| 17719355 | Thadiene  `Thadiene` |  |
| 17719410 | Vaquelage  `Vaquelage` |  |
| 17719389 | Victoire  `Victoire` |  |

<details><summary>↳ 14 cutscene NPC(s) — review (possible mission steps)</summary>

Authere, Balasiel, Celyddon, Chanpau, Daggao, Deraquien, Diary, Femitte, Najjar, Namonutice, Poudoruchant, Rouva, Sharzalion, Ullasa

</details>

### Grand Palace of HuXzoi  (34)
_17 flavor candidate(s) · 12 functional kept · 57 scenery · 25 already hidden_

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

### Norg  (252)
_16 flavor candidate(s) · 23 functional kept · 37 scenery · 61 already hidden_

| npcid | NPC | |
|---:|---|---|
| 17809447 | Achika  `Achika` |  |
| 17809448 | Chiyo  `Chiyo` |  |
| 17809438 | Deigoff  `Deigoff` |  |
| 17809446 | Jirokichi  `Jirokichi` |  |
| 17809436 | Louartain  `Louartain` |  |
| 17809455 | Nomad Moogle  `Nomad_Moogle` |  |
| 17809456 | Nomad Moogle  `Nomad_Moogle` |  |
| 17809457 | Nomad Moogle  `Nomad_Moogle` |  |
| 17809439 | Oruga  `Oruga` |  |
| 17809442 | Paito-Maito  `Paito-Maito` |  |
| 17809450 | Paleille  `Paleille` |  |
| 17809440 | Parlemaille  `Parlemaille` |  |
| 17809437 | Shivivi  `Shivivi` |  |
| 17809502 | Solby-Maholby  `Solby-Maholby` |  |
| 17809449 | Spasija  `Spasija` |  |
| 17809445 | Vuliaie  `Vuliaie` |  |

<details><summary>↳ 3 cutscene NPC(s) — review (possible mission steps)</summary>

Fouvia, Gimb, Vaultimand

</details>

### Port San dOria  (232)
_15 flavor candidate(s) · 33 functional kept · 51 scenery · 84 already hidden_

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
| 17727612 | Joulet  `Joulet` |  |
| 17727517 | Meinemelle  `Meinemelle` |  |
| 17727525 | Milva  `Milva` |  |
| 17727528 | Nimia  `Nimia` |  |
| 17727529 | Patolle  `Patolle` |  |
| 17727526 | Vendavoq  `Vendavoq` |  |

<details><summary>↳ 10 cutscene NPC(s) — review (possible mission steps)</summary>

Ambleon, Arminibit, Cherlodeau, Leonora, Louis, Nazar, Parcarin, Perdiouvilet, Pomilla, Rugiette

</details>

### Selbina  (248)
_15 flavor candidate(s) · 13 functional kept · 29 scenery · 52 already hidden_

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
| 17793037 | Mendoline  `Mendoline` |  |
| 17793129 | Nomad Moogle  `Nomad_Moogle` |  |
| 17793130 | Nomad Moogle  `Nomad_Moogle` |  |
| 17793067 | Quelpia  `Quelpia` |  |
| 17793053 | Tilala  `Tilala` |  |
| 17793036 | Torapiont  `Torapiont` |  |
| 17793127 | Wenzel  `Wenzel` |  |

<details><summary>↳ 10 cutscene NPC(s) — review (possible mission steps)</summary>

Aleria, Bretta, Flandiace, Gabwaleid, Mathilde, Pacomart, Raging Tiger, Ramona, Sleeping Lizard, Velema

</details>

### Windurst Walls  (239)
_14 flavor candidate(s) · 25 functional kept · 58 scenery · 187 already hidden_

| npcid | NPC | |
|---:|---|---|
| 17756196 | Bonchacha  `Bonchacha` |  |
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

<details><summary>↳ 12 cutscene NPC(s) — review (possible mission steps)</summary>

Chomomo, Five of Diamonds, Kalupa-Tawalupa, Moan-Maon, Naih Arihmepp, Orudoba-Sondeba, Ran, Rutango-Botango, Shantotto, Tsuaora-Tsuora, Yoriri, Zokima-Rokima

</details>

### Mhaura  (249)
_14 flavor candidate(s) · 16 functional kept · 33 scenery · 75 already hidden_

| npcid | NPC | |
|---:|---|---|
| 17797132 | Celestina  `Celestina` |  |
| 17797178 | Dieh Yamilsiah  `Dieh_Yamilsiah` |  |
| 17797130 | Graine  `Graine` |  |
| 17797135 | Kamilah  `Kamilah` |  |
| 17797183 | Laughing Bison  `Laughing_Bison` | `[ref]` |
| 17797249 | Mauriri  `Mauriri` |  |
| 17797134 | Mololo  `Mololo` |  |
| 17797251 | Nomad Moogle  `Nomad_Moogle` |  |
| 17797252 | Nomad Moogle  `Nomad_Moogle` |  |
| 17797250 | Panoru-Kanoru  `Panoru-Kanoru` |  |
| 17797138 | Pikini-Mikini  `Pikini-Mikini` |  |
| 17797127 | Runito-Monito  `Runito-Monito` |  |
| 17797255 | Tya Padolih  `Tya_Padolih` |  |
| 17797131 | Yabby Tanmikey  `Yabby_Tanmikey` |  |

<details><summary>↳ 9 cutscene NPC(s) — review (possible mission steps)</summary>

Condor Eye, Ekokoko, Emyr, Hyria, Mauh Halaapah, Radhika, Somo Aatsula, Standing Bear, Tonasav

</details>

### Nashmau  (53)
_13 flavor candidate(s) · 13 functional kept · 41 scenery · 63 already hidden_

| npcid | NPC | |
|---:|---|---|
| 16994373 | Chichiroon  `Chichiroon` |  |
| 16994361 | Chuchuroon  `Chuchuroon` |  |
| 16994341 | Jajaroon  `Jajaroon` |  |
| 16994346 | Mamaroon  `Mamaroon` |  |
| 16994377 | Nanaroon  `Nanaroon` |  |
| 16994378 | Neneroon  `Neneroon` |  |
| 16994379 | Nomad Moogle  `Nomad_Moogle` |  |
| 16994380 | Nomad Moogle  `Nomad_Moogle` |  |
| 16994348 | Pipiroon  `Pipiroon` |  |
| 16994349 | Poporoon  `Poporoon` |  |
| 16994350 | Wata Khamazom  `Wata_Khamazom` |  |
| 16994324 | Yohj Dukonlhy  `Yohj_Dukonlhy` |  |
| 16994344 | Yoyoroon  `Yoyoroon` |  |

<details><summary>↳ 3 cutscene NPC(s) — review (possible mission steps)</summary>

Belligerent Sheep, Bellowing Scout, Dnegan

</details>

### Northern San dOria  (231)
_13 flavor candidate(s) · 48 functional kept · 85 scenery · 282 already hidden_

| npcid | NPC | |
|---:|---|---|
| 17723587 | Arachagnon  `Arachagnon` |  |
| 17723446 | Arlenne  `Arlenne` |  |
| 17723431 | Cauzeriste  `Cauzeriste` |  |
| 17723432 | Chaupire  `Chaupire` |  |
| 17723439 | Doggomehr  `Doggomehr` |  |
| 17723493 | Eugballion  `Eugballion` |  |
| 17723553 | Gaudylox  `Gaudylox` |  |
| 17723485 | Justi  `Justi` |  |
| 17723440 | Lucretia  `Lucretia` |  |
| 17723498 | Millechuca  `Millechuca` |  |
| 17723491 | Palguevion  `Palguevion` |  |
| 17723486 | Pirvidiauce  `Pirvidiauce` |  |
| 17723447 | Tavourine  `Tavourine` |  |

<details><summary>↳ 18 cutscene NPC(s) — review (possible mission steps)</summary>

Anilla, Baraka, Beriphaule, Bertenont, Commojourt, Emeige A.M.A.N., Giaunne, Heruze-Moruze, Lotine, Madaline, Maloquedil, Morjean, Nonterene, Phairupegiont, Pulloie, Shomo Pochachilo, Telmoda, Wooden Shutter

</details>

### Bastok Mines  (234)
_13 flavor candidate(s) · 33 functional kept · 69 scenery · 217 already hidden_

| npcid | NPC | |
|---:|---|---|
| 17735739 | Black Mud  `Black_Mud` |  |
| 17735724 | Boytz  `Boytz` |  |
| 17735722 | Deegis  `Deegis` |  |
| 17735746 | Galdeo  `Galdeo` |  |
| 17735716 | Gawful  `Gawful` |  |
| 17735725 | Gelzerio  `Gelzerio` |  |
| 17735726 | Griselda  `Griselda` |  |
| 17735714 | Maymunah  `Maymunah` |  |
| 17735715 | Odoba  `Odoba` |  |
| 17735743 | Rodellieux  `Rodellieux` |  |
| 17735717 | Sodragamm  `Sodragamm` |  |
| 17735745 | Tibelda  `Tibelda` |  |
| 17735723 | Zemedars  `Zemedars` |  |

<details><summary>↳ 2 cutscene NPC(s) — review (possible mission steps)</summary>

Gerbaum, Rashid

</details>

### Rabao  (247)
_13 flavor candidate(s) · 19 functional kept · 23 scenery · 53 already hidden_

| npcid | NPC | |
|---:|---|---|
| 17788939 | Bald Aurochs  `Bald_Aurochs` |  |
| 17788945 | Brave Ox  `Brave_Ox` |  |
| 17788944 | Brave Wolf  `Brave_Wolf` |  |
| 17788941 | Eflatun  `Eflatun` |  |
| 17788940 | Iron Muscles  `Iron_Muscles` |  |
| 17788952 | Nomad Moogle  `Nomad_Moogle` |  |
| 17788953 | Nomad Moogle  `Nomad_Moogle` |  |
| 17788954 | Nomad Moogle  `Nomad_Moogle` |  |
| 17788947 | Pakhi Churhebi  `Pakhi_Churhebi` |  |
| 17788946 | Scamplix  `Scamplix` |  |
| 17788943 | Shiny Teeth  `Shiny_Teeth` |  |
| 17788948 | Spirit Singer  `Spirit_Singer` |  |
| 17788942 | Yabehbeh  `Yabehbeh` |  |

<details><summary>↳ 2 cutscene NPC(s) — review (possible mission steps)</summary>

Jourdenaux, Waylea

</details>

### Tavnazian Safehold  (26)
_12 flavor candidate(s) · 17 functional kept · 71 scenery · 76 already hidden_

| npcid | NPC | |
|---:|---|---|
| 16883792 | Caiphimonride  `Caiphimonride` |  |
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
_12 flavor candidate(s) · 16 functional kept · 81 scenery · 72 already hidden_

| npcid | NPC | |
|---:|---|---|
| 16974291 | Allard  `Allard` |  |
| 16974296 | Bornahn  `Bornahn` |  |
| 16974290 | Chayaya  `Chayaya` |  |
| 16974298 | Dehbi Moshal  `Dehbi_Moshal` |  |
| 16974292 | Kahah Hobichai  `Kahah_Hobichai` |  |
| 16974308 | Mabebe  `Mabebe` |  |
| 16974381 | Najaaj  `Najaaj` |  |
| 16974297 | Ndego  `Ndego` |  |
| 16974309 | Opococo  `Opococo` |  |
| 16974382 | Sujyahn  `Sujyahn` |  |
| 16974295 | Taten-Bilten  `Taten-Bilten` |  |
| 16974293 | Zafif  `Zafif` |  |

### Upper Jeuno  (244)
_12 flavor candidate(s) · 22 functional kept · 65 scenery · 151 already hidden_

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
| 17776692 | Sibila-Mobla  `Sibila-Mobla` |  |
| 17776719 | Theraisie  `Theraisie` |  |

<details><summary>↳ 2 cutscene NPC(s) — review (possible mission steps)</summary>

Afdeen, Hinda

</details>

### Kazham  (250)
_12 flavor candidate(s) · 27 functional kept · 19 scenery · 44 already hidden_

| npcid | NPC | |
|---:|---|---|
| 17801285 | _(unnamed)_ `rarab_1` |  |
| 17801286 | _(unnamed)_ `rarab_2` |  |
| 17801287 | _(unnamed)_ `rarab_3` |  |
| 17801253 | Ghemi Sinterilo  `Ghemi_Sinterilo` |  |
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

### PsoXja  (9)
_11 flavor candidate(s) · 22 functional kept · 54 scenery · 46 already hidden_

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

### Castle Oztroja  (151)
_11 flavor candidate(s) · 21 functional kept · 14 scenery · 65 already hidden_

| npcid | NPC | |
|---:|---|---|
| 17396195 | _(unnamed)_ `_47n` |  |
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

### VeLugannon Palace  (177)
_10 flavor candidate(s) · 14 functional kept · 75 scenery · 29 already hidden_

| npcid | NPC | |
|---:|---|---|
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

### The Eldieme Necropolis  (195)
_9 flavor candidate(s) · 21 functional kept · 16 scenery · 95 already hidden_

| npcid | NPC | |
|---:|---|---|
| 17576327 | East Plate  `_5fl` |  |
| 17576328 | East Plate  `_5fm` |  |
| 17576440 | Geomagnetic Fount  `Geomagnetic_Fount` |  |
| 17576329 | North Plate  `_5fn` |  |
| 17576330 | North Plate  `_5fo` |  |
| 17576333 | South Plate  `_5fr` |  |
| 17576334 | South Plate  `_5fs` |  |
| 17576331 | West Plate  `_5fp` |  |
| 17576332 | West Plate  `_5fq` |  |

### Metalworks  (237)
_9 flavor candidate(s) · 11 functional kept · 75 scenery · 113 already hidden_

| npcid | NPC | |
|---:|---|---|
| 17748035 | _(unnamed)_ `@6l0` |  |
| 17748038 | _(unnamed)_ `@6l1` |  |
| 17747970 | Amulya  `Amulya` |  |
| 17748033 | Fariel  `Fariel` |  |
| 17747977 | Nogga  `Nogga` |  |
| 17747976 | Olaf  `Olaf` |  |
| 17748139 | Takiyah  `Takiyah` |  |
| 17748005 | Tomasa  `Tomasa` |  |
| 17747969 | Vicious Eye  `Vicious_Eye` |  |

<details><summary>↳ 6 cutscene NPC(s) — review (possible mission steps)</summary>

Ferghus, Malduc, Mighty Fist, Mythily, Savae E Paleade, Udine A.M.A.N.

</details>

### Tahrongi Canyon  (117)
_8 flavor candidate(s) · 11 functional kept · 12 scenery · 110 already hidden_

| npcid | NPC | |
|---:|---|---|
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

### Western Adoulin  (256)
_8 flavor candidate(s) · 34 functional kept · 102 scenery · 230 already hidden_

| npcid | NPC | |
|---:|---|---|
| 17826076 | Ansegusele  `Ansegusele` |  |
| 17826089 | Eukalline  `Eukalline` |  |
| 17826088 | Ishvad  `Ishvad` |  |
| 17826093 | Kanil  `Kanil` |  |
| 17826087 | Ledericus  `Ledericus` |  |
| 17826091 | Preterig  `Preterig` |  |
| 17826077 | Tevigogo  `Tevigogo` |  |
| 17826094 | Theophylacte  `Theophylacte` |  |

<details><summary>↳ 15 cutscene NPC(s) — review (possible mission steps)</summary>

Andrival, Barenngo, Bilp, Dewalt, Eamonn, Gontrain, Grevan, Kipligg, Marjoirelle, Oka Qhantari, Rising Solstice, Ruth, Terwok, Volgoi, Zaoso

</details>

### Buburimu Peninsula  (118)
_7 flavor candidate(s) · 7 functional kept · 8 scenery · 128 already hidden_

| npcid | NPC | |
|---:|---|---|
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

### RuLude Gardens  (243)
_6 flavor candidate(s) · 28 functional kept · 60 scenery · 166 already hidden_

| npcid | NPC | |
|---:|---|---|
| 17772575 | Arenuel  `Arenuel` |  |
| 17772579 | Dugga  `Dugga` |  |
| 17772580 | Ghye Dachanthu  `Ghye_Dachanthu` |  |
| 17772574 | Leis  `Leis` |  |
| 17772598 | Macchi Gazlitah  `Macchi_Gazlitah` |  |
| 17772573 | Yavoraile  `Yavoraile` |  |

<details><summary>↳ 2 cutscene NPC(s) — review (possible mission steps)</summary>

Laityn, Maat

</details>

### Port Jeuno  (246)
_6 flavor candidate(s) · 28 functional kept · 82 scenery · 45 already hidden_

| npcid | NPC | |
|---:|---|---|
| 17784910 | Digaga  `Digaga` |  |
| 17784881 | Gavin  `Gavin` |  |
| 17784834 | Gekko  `Gekko` |  |
| 17784835 | Leyla  `Leyla` |  |
| 17784900 | Red Ghost  `Red_Ghost` |  |
| 17784911 | Veujaie  `Veujaie` |  |

<details><summary>↳ 13 cutscene NPC(s) — review (possible mission steps)</summary>

Avijit, Chaka Skitimah, Chudigrimane, Garridan, Gaura, Imasuke, Jaipal, Kindlix, Najib, Pyropox, Raging Lion, Supiroro, Zona Shodhun

</details>

### Bastok Markets [S]  (87)
_5 flavor candidate(s) · 10 functional kept · 74 scenery · 210 already hidden_

| npcid | NPC | |
|---:|---|---|
| 17134031 | Adelbrecht  `Adelbrecht` |  |
| 17134076 | Blingbrix  `Blingbrix` |  |
| 17134084 | Karlotte  `Karlotte` |  |
| 17134153 | Silke  `Silke` |  |
| 17134083 | Weldon  `Weldon` |  |

<details><summary>↳ 2 cutscene NPC(s) — review (possible mission steps)</summary>

Raginmund, Red Canyon

</details>

### Attohwa Chasm  (7)
_4 flavor candidate(s) · 10 functional kept · 61 scenery · 29 already hidden_

| npcid | NPC | |
|---:|---|---|
| 16806321 | _(unnamed)_ `_07h` |  |
| 16806322 | _(unnamed)_ `_07i` |  |
| 16806323 | _(unnamed)_ `_07j` |  |
| 16806324 | _(unnamed)_ `_07k` |  |

### The Garden of RuHmet  (35)
_4 flavor candidate(s) · 3 functional kept · 48 scenery · 43 already hidden_

| npcid | NPC | |
|---:|---|---|
| 16921069 | Cermet Portal  `_0zw` |  |
| 16921070 | Cermet Portal  `_0zx` |  |
| 16921071 | Cermet Portal  `_0zz` |  |
| 16921073 | Cermet Portal  `_iz0` |  |

<details><summary>↳ 1 cutscene NPC(s) — review (possible mission steps)</summary>

Cermet Portal

</details>

### Western Altepa Desert  (125)
_4 flavor candidate(s) · 13 functional kept · 17 scenery · 98 already hidden_

| npcid | NPC | |
|---:|---|---|
| 17289754 | Emerald Column  `_3h7` |  |
| 17289752 | Ruby Column  `_3h5` |  |
| 17289755 | Sapphire Column  `_3h8` |  |
| 17289753 | Topaz Column  `_3h6` |  |

### Beadeaux  (147)
_4 flavor candidate(s) · 5 functional kept · 30 scenery · 37 already hidden_

| npcid | NPC | |
|---:|---|---|
| 17379808 | The Mute  `The_Mute` |  |
| 17379809 | The Mute  `The_Mute` |  |
| 17379810 | The Mute  `The_Mute` |  |
| 17379811 | The Mute  `The_Mute` |  |

### Windurst Waters [S]  (94)
_3 flavor candidate(s) · 13 functional kept · 79 scenery · 293 already hidden_

| npcid | NPC | |
|---:|---|---|
| 17162877 | Ezura-Romazura  `Ezura-Romazura` |  |
| 17162832 | Pelftrix  `Pelftrix` |  |
| 17162831 | Yassi-Possi  `Yassi-Possi` |  |

<details><summary>↳ 2 cutscene NPC(s) — review (possible mission steps)</summary>

Ajen-Myoojen, Rohn Ehlbalna

</details>

### FeiYin  (204)
_3 flavor candidate(s) · 18 functional kept · 55 scenery · 71 already hidden_

| npcid | NPC | |
|---:|---|---|
| 17613247 | Underground Pool  `Underground_Pool` |  |
| 17613248 | Underground Pool  `Underground_Pool` |  |
| 17613249 | Underground Pool  `Underground_Pool` |  |

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

### Bibiki Bay  (4)
_2 flavor candidate(s) · 14 functional kept · 14 scenery · 40 already hidden_

| npcid | NPC | |
|---:|---|---|
| 16793988 | Mep Nhapopoluko  `Mep_Nhapopoluko` |  |
| 16793987 | Pohka Chichiyowahl  `Pohka_Chichiyowahl` |  |

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

### Southern San dOria [S]  (80)
_2 flavor candidate(s) · 11 functional kept · 94 scenery · 347 already hidden_

| npcid | NPC | |
|---:|---|---|
| 17105413 | Geltpix  `Geltpix` |  |
| 17105381 | Nembet  `Nembet` |  |

<details><summary>↳ 2 cutscene NPC(s) — review (possible mission steps)</summary>

Eauvague, T.K., Fiaudie

</details>

### West Ronfaure  (100)
_2 flavor candidate(s) · 4 functional kept · 25 scenery · 67 already hidden_

| npcid | NPC | |
|---:|---|---|
| 17187491 | Palcomondau  `Palcomondau` |  |
| 17187492 | Zovriace  `Zovriace` |  |

<details><summary>↳ 5 cutscene NPC(s) — review (possible mission steps)</summary>

Signpost

</details>

### Palborough Mines  (143)
_2 flavor candidate(s) · 17 functional kept · 13 scenery · 16 already hidden_

| npcid | NPC | |
|---:|---|---|
| 17363347 | _(unnamed)_ `@3z0` |  |
| 17363380 | Geomagnetic Fount  `Geomagnetic_Fount` |  |

### Davoi  (149)
_2 flavor candidate(s) · 8 functional kept · 31 scenery · 37 already hidden_

| npcid | NPC | |
|---:|---|---|
| 17387999 | _(unnamed)_ `_454` |  |
| 17387991 | Quemaricond  `Quemaricond` |  |

### The Eldieme Necropolis [S]  (175)
_2 flavor candidate(s) · 3 functional kept · 48 scenery · 64 already hidden_

| npcid | NPC | |
|---:|---|---|
| 17494720 | Layton  `Layton` |  |
| 17494747 | Lennart  `Lennart` |  |

### Ordelles Caves  (193)
_2 flavor candidate(s) · 8 functional kept · 13 scenery · 44 already hidden_

| npcid | NPC | |
|---:|---|---|
| 17568207 | Geomagnetic Fount  `Geomagnetic_Fount` |  |
| 17568171 | Ruillont  `Ruillont` |  |

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

### Carpenters Landing  (2)
_1 flavor candidate(s) · 13 functional kept · 14 scenery · 25 already hidden_

| npcid | NPC | |
|---:|---|---|
| 16785755 | Beugungel  `Beugungel` |  |

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

### Qufim Island  (126)
_1 flavor candidate(s) · 10 functional kept · 14 scenery · 129 already hidden_

| npcid | NPC | |
|---:|---|---|
| 17293708 | Nightflowers  `Nightflowers` |  |

### Fort Ghelsba  (141)
_1 flavor candidate(s) · 2 functional kept · 7 scenery · 10 already hidden_

| npcid | NPC | |
|---:|---|---|
| 17354993 | _(unnamed)_ `@3x0` |  |

### Yughott Grotto  (142)
_1 flavor candidate(s) · 8 functional kept · 3 scenery · 51 already hidden_

| npcid | NPC | |
|---:|---|---|
| 17359094 | Geomagnetic Fount  `Geomagnetic_Fount` |  |

### Qulun Dome  (148)
_1 flavor candidate(s) · 2 functional kept · 3 scenery · 33 already hidden_

| npcid | NPC | |
|---:|---|---|
| 17383473 | The Mute  `The_Mute` |  |

### Monastic Cavern  (150)
_1 flavor candidate(s) · 2 functional kept · 10 scenery · 29 already hidden_

| npcid | NPC | |
|---:|---|---|
| 17391861 | Geomagnetic Fount  `Geomagnetic_Fount` |  |

### Ranguemont Pass  (166)
_1 flavor candidate(s) · 5 functional kept · 11 scenery · 53 already hidden_

| npcid | NPC | |
|---:|---|---|
| 17457384 | Geomagnetic Fount  `Geomagnetic_Fount` |  |

<details><summary>↳ 1 cutscene NPC(s) — review (possible mission steps)</summary>

Myffore

</details>

### Toraimarai Canal  (169)
_1 flavor candidate(s) · 8 functional kept · 25 scenery · 49 already hidden_

| npcid | NPC | |
|---:|---|---|
| 17469855 | Geomagnetic Fount  `Geomagnetic_Fount` |  |

<details><summary>↳ 5 cutscene NPC(s) — review (possible mission steps)</summary>

Tome of Magic

</details>

### Korroloka Tunnel  (173)
_1 flavor candidate(s) · 7 functional kept · 7 scenery · 43 already hidden_

| npcid | NPC | |
|---:|---|---|
| 17486271 | Geomagnetic Fount  `Geomagnetic_Fount` |  |

### King Ranperres Tomb  (190)
_1 flavor candidate(s) · 8 functional kept · 10 scenery · 53 already hidden_

| npcid | NPC | |
|---:|---|---|
| 17556031 | Geomagnetic Fount  `Geomagnetic_Fount` |  |

### Dangruf Wadi  (191)
_1 flavor candidate(s) · 7 functional kept · 13 scenery · 39 already hidden_

| npcid | NPC | |
|---:|---|---|
| 17559938 | Geomagnetic Fount  `Geomagnetic_Fount` |  |

### Inner Horutoto Ruins  (192)
_1 flavor candidate(s) · 6 functional kept · 36 scenery · 42 already hidden_

| npcid | NPC | |
|---:|---|---|
| 17563927 | Geomagnetic Fount  `Geomagnetic_Fount` |  |

### Outer Horutoto Ruins  (194)
_1 flavor candidate(s) · 6 functional kept · 40 scenery · 40 already hidden_

| npcid | NPC | |
|---:|---|---|
| 17572314 | Geomagnetic Fount  `Geomagnetic_Fount` |  |

### Gusgen Mines  (196)
_1 flavor candidate(s) · 18 functional kept · 7 scenery · 31 already hidden_

| npcid | NPC | |
|---:|---|---|
| 17580420 | Geomagnetic Fount  `Geomagnetic_Fount` |  |

### Crawlers Nest  (197)
_1 flavor candidate(s) · 14 functional kept · 9 scenery · 52 already hidden_

| npcid | NPC | |
|---:|---|---|
| 17584505 | Geomagnetic Fount  `Geomagnetic_Fount` |  |

### Maze of Shakhrami  (198)
_1 flavor candidate(s) · 13 functional kept · 26 scenery · 46 already hidden_

| npcid | NPC | |
|---:|---|---|
| 17588793 | Geomagnetic Fount  `Geomagnetic_Fount` |  |

### Garlaige Citadel  (200)
_1 flavor candidate(s) · 17 functional kept · 50 scenery · 46 already hidden_

| npcid | NPC | |
|---:|---|---|
| 17596866 | Geomagnetic Fount  `Geomagnetic_Fount` |  |

### Gustav Tunnel  (212)
_1 flavor candidate(s) · 5 functional kept · 4 scenery · 51 already hidden_

| npcid | NPC | |
|---:|---|---|
| 17645915 | Geomagnetic Fount  `Geomagnetic_Fount` |  |

### Labyrinth of Onzozo  (213)
_1 flavor candidate(s) · 5 functional kept · 5 scenery · 28 already hidden_

| npcid | NPC | |
|---:|---|---|
| 17649906 | Geomagnetic Fount  `Geomagnetic_Fount` |  |

### Heavens Tower  (242)
_1 flavor candidate(s) · 6 functional kept · 47 scenery · 63 already hidden_

| npcid | NPC | |
|---:|---|---|
| 17768504 | Chuqui-Chanqui  `Chuqui-Chanqui` |  |

<details><summary>↳ 3 cutscene NPC(s) — review (possible mission steps)</summary>

Gamimi, Jatata, Rakano-Marukano

</details>

### Spire of Holla  (17)
_0 flavor candidate(s) · 0 functional kept · 6 scenery · 28 already hidden_

<details><summary>↳ 1 cutscene NPC(s) — review (possible mission steps)</summary>

Radiant Aureole

</details>

### Spire of Dem  (19)
_0 flavor candidate(s) · 0 functional kept · 5 scenery · 29 already hidden_

<details><summary>↳ 1 cutscene NPC(s) — review (possible mission steps)</summary>

Radiant Aureole

</details>

### Spire of Mea  (21)
_0 flavor candidate(s) · 0 functional kept · 5 scenery · 29 already hidden_

<details><summary>↳ 1 cutscene NPC(s) — review (possible mission steps)</summary>

Radiant Aureole

</details>

### Spire of Vahzl  (23)
_0 flavor candidate(s) · 0 functional kept · 6 scenery · 29 already hidden_

<details><summary>↳ 1 cutscene NPC(s) — review (possible mission steps)</summary>

Radiant Aureole

</details>

### Misareaux Coast  (25)
_0 flavor candidate(s) · 11 functional kept · 20 scenery · 61 already hidden_

<details><summary>↳ 1 cutscene NPC(s) — review (possible mission steps)</summary>

Spatial Displacement

</details>

### Riverne-Site B01  (29)
_0 flavor candidate(s) · 5 functional kept · 6 scenery · 25 already hidden_

<details><summary>↳ 35 cutscene NPC(s) — review (possible mission steps)</summary>

Spatial Displacement

</details>

### Riverne-Site A01  (30)
_0 flavor candidate(s) · 5 functional kept · 7 scenery · 25 already hidden_

<details><summary>↳ 32 cutscene NPC(s) — review (possible mission steps)</summary>

Spatial Displacement

</details>

### Monarch Linn  (31)
_0 flavor candidate(s) · 1 functional kept · 6 scenery · 62 already hidden_

<details><summary>↳ 1 cutscene NPC(s) — review (possible mission steps)</summary>

Spatial Displacement

</details>

### AlTaieu  (33)
_0 flavor candidate(s) · 7 functional kept · 29 scenery · 57 already hidden_

<details><summary>↳ 11 cutscene NPC(s) — review (possible mission steps)</summary>

Auroral Updraft, Dimensional Portal, Swirling Vortex

</details>

### Wajaom Woodlands  (51)
_0 flavor candidate(s) · 8 functional kept · 32 scenery · 188 already hidden_

<details><summary>↳ 1 cutscene NPC(s) — review (possible mission steps)</summary>

Postern

</details>

### Bhaflau Thickets  (52)
_0 flavor candidate(s) · 10 functional kept · 9 scenery · 31 already hidden_

<details><summary>↳ 1 cutscene NPC(s) — review (possible mission steps)</summary>

Postern

</details>

### Mamook  (65)
_0 flavor candidate(s) · 4 functional kept · 40 scenery · 91 already hidden_

<details><summary>↳ 6 cutscene NPC(s) — review (possible mission steps)</summary>

Viscous Liquid

</details>

### Arrapago Remnants  (74)
_0 flavor candidate(s) · 0 functional kept · 4 scenery · 11 already hidden_

<details><summary>↳ 17 cutscene NPC(s) — review (possible mission steps)</summary>

Gilded Doors

</details>

### Jugner Forest [S]  (82)
_0 flavor candidate(s) · 6 functional kept · 37 scenery · 142 already hidden_

<details><summary>↳ 1 cutscene NPC(s) — review (possible mission steps)</summary>

Roiloux, R.K.

</details>

### Fort Karugo-Narugo [S]  (96)
_0 flavor candidate(s) · 4 functional kept · 71 scenery · 147 already hidden_

<details><summary>↳ 1 cutscene NPC(s) — review (possible mission steps)</summary>

Rotih Moalghett

</details>

### Meriphataud Mountains [S]  (97)
_0 flavor candidate(s) · 5 functional kept · 19 scenery · 145 already hidden_

<details><summary>↳ 1 cutscene NPC(s) — review (possible mission steps)</summary>

Iron Portcullis

</details>

### La Theine Plateau  (102)
_0 flavor candidate(s) · 12 functional kept · 26 scenery · 177 already hidden_

<details><summary>↳ 1 cutscene NPC(s) — review (possible mission steps)</summary>

Dimensional Portal

</details>

### Jugner Forest  (104)
_0 flavor candidate(s) · 6 functional kept · 15 scenery · 168 already hidden_

<details><summary>↳ 5 cutscene NPC(s) — review (possible mission steps)</summary>

Alexius, Signpost

</details>

### Konschtat Highlands  (108)
_0 flavor candidate(s) · 8 functional kept · 17 scenery · 103 already hidden_

<details><summary>↳ 1 cutscene NPC(s) — review (possible mission steps)</summary>

Dimensional Portal

</details>

### Beaucedine Glacier  (111)
_0 flavor candidate(s) · 9 functional kept · 21 scenery · 113 already hidden_

<details><summary>↳ 7 cutscene NPC(s) — review (possible mission steps)</summary>

Iron Grate, Torino-Samarino

</details>

### Xarcabard  (112)
_0 flavor candidate(s) · 9 functional kept · 16 scenery · 94 already hidden_

<details><summary>↳ 1 cutscene NPC(s) — review (possible mission steps)</summary>

Perennial Snow

</details>

### Beaucedine Glacier [S]  (136)
_0 flavor candidate(s) · 1 functional kept · 22 scenery · 191 already hidden_

<details><summary>↳ 2 cutscene NPC(s) — review (possible mission steps)</summary>

Moana, C.A., Watchful Pixie

</details>

### Xarcabard [S]  (137)
_0 flavor candidate(s) · 1 functional kept · 22 scenery · 249 already hidden_

<details><summary>↳ 1 cutscene NPC(s) — review (possible mission steps)</summary>

Zvahl Portcullis

</details>

### Temple of Uggalepih  (159)
_0 flavor candidate(s) · 34 functional kept · 62 scenery · 81 already hidden_

<details><summary>↳ 3 cutscene NPC(s) — review (possible mission steps)</summary>

Tome of Magic

</details>

### Garlaige Citadel [S]  (164)
_0 flavor candidate(s) · 2 functional kept · 84 scenery · 103 already hidden_

<details><summary>↳ 1 cutscene NPC(s) — review (possible mission steps)</summary>

Randecque

</details>

### Bostaunieux Oubliette  (167)
_0 flavor candidate(s) · 6 functional kept · 51 scenery · 51 already hidden_

<details><summary>↳ 1 cutscene NPC(s) — review (possible mission steps)</summary>

Novalmauge

</details>

### Zeruhn Mines  (172)
_0 flavor candidate(s) · 8 functional kept · 18 scenery · 54 already hidden_

<details><summary>↳ 1 cutscene NPC(s) — review (possible mission steps)</summary>

Lasthenes

</details>

### Sea Serpent Grotto  (176)
_0 flavor candidate(s) · 16 functional kept · 14 scenery · 68 already hidden_

<details><summary>↳ 1 cutscene NPC(s) — review (possible mission steps)</summary>

Bou the Righteous

</details>

### Walk of Echoes  (182)
_0 flavor candidate(s) · 0 functional kept · 39 scenery · 84 already hidden_

<details><summary>↳ 2 cutscene NPC(s) — review (possible mission steps)</summary>

Veridical Conflux

</details>

### Chateau dOraguille  (233)
_0 flavor candidate(s) · 3 functional kept · 29 scenery · 63 already hidden_

<details><summary>↳ 3 cutscene NPC(s) — review (possible mission steps)</summary>

Faurie, Halver, Perfaumand

</details>

### Hall of the Gods  (251)
_0 flavor candidate(s) · 1 functional kept · 1 scenery · 41 already hidden_

<details><summary>↳ 2 cutscene NPC(s) — review (possible mission steps)</summary>

Shimmering Circle

</details>

### Eastern Adoulin  (257)
_0 flavor candidate(s) · 20 functional kept · 109 scenery · 202 already hidden_

<details><summary>↳ 2 cutscene NPC(s) — review (possible mission steps)</summary>

Eppel-Treppel, Iyvah Halohm

</details>

### Kamihr Drifts  (267)
_0 flavor candidate(s) · 6 functional kept · 52 scenery · 87 already hidden_

<details><summary>↳ 1 cutscene NPC(s) — review (possible mission steps)</summary>

Blockaded Path

</details>

### Outer RaKaznar  (274)
_0 flavor candidate(s) · 0 functional kept · 79 scenery · 26 already hidden_

<details><summary>↳ 5 cutscene NPC(s) — review (possible mission steps)</summary>

Entwined Roots

</details>

### Feretory  (285)
_0 flavor candidate(s) · 4 functional kept · 1 scenery · 11 already hidden_

<details><summary>↳ 1 cutscene NPC(s) — review (possible mission steps)</summary>

Suibhne

</details>
