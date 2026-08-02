# Trust Cipher Drop Proposal — Dev Review Draft

**Status:** Implemented · `trust_cipher_drops.lua` + per-system death hooks  
**Last updated:** 2026-08-02 (drops wired from CSV)  
**Source of truth:** [`exports/trust_cipher_drop_proposal.csv`](trust_cipher_drop_proposal.csv)  
**Related:** usable ciphers (`trust_cipher_usable.sql` / `_trust_cipher.lua`); drop helper (`trust_cipher_drops.lua`)

This document is generated from the CSV companion. Edit the CSV, then regenerate this file.

### Design rule: every trust from a unique farmable NM

**No Rebirth / Prestige / Ascension trial gates** for farmable trusts. Starters are free at creation. Void Keeper customs remain separate collection gates. **Abyssea Marks** NMs are a first-class source.

| Bucket | Count | Unlock |
|--------|------:|--------|
| **Cipher NM drops** | 80 | Use cipher item → learn trust |
| **Direct spell grant** | 31 | `addSpell` on kill — no retail cipher item |
| **Starters** | 4 | Trion, Kupipi, Tenzen, Shantotto — free at creation |
| **Void Keeper** | 5 | Meat / Gemma / Corvus / Cornelia / Matsui-P collection gates |
| **Disabled / retired** | 2 | Aldo (Locke), Aldo UC |
| **→ NM-farmable** | **111** | Cipher drops + direct grants |
| **→ Full CSV rows** | **122** | Includes starters, Void Keeper, disabled |

---

## 1. System summary

| Layer | Rule |
|-------|------|
| **Starters (free)** | Trion, Kupipi, Tenzen, Shantotto — granted on first login |
| **One trust per NM** | Each `mob_groups_name` appears once among farmable rows |
| **Drop model** | Ciphers: NM drops item. Direct grants: NM kill teaches spell |
| **Dupe protection** | If player already knows the trust: skip roll or convert to Hunt Marks / gil |
| **Excluded systems** | No Prestige / Rebirth / Infamy gates for these farms; no paid cipher purchases |

### Drop rate bands

| Band | Example content | Drop rate |
|------|-----------------|----------:|
| **D1 — Entry** | HL Rank I, Reforge [I], Unity T1, Geas T1, Abyssea Marks T1 | **15%** |
| **D2 — Mid** | HL Rank II–III, Reforge [II–III], Unity T2, Geas T2, Abyssea Marks T2 | **13%** |
| **D3 — Hard** | HL Rank IV, Reforge [IV], Unity T3, Geas T3, Abyssea Marks T2–3 | **11%** |
| **D4 — Apex** | HL Rank V, Reforge [V], Geas T4, Abyssea Marks T3, Gauntlet high | **9%** |
| **D5 — Chase** | Shinryu (HL Rank V) | **8%** |

### Priority trusts

| Trust | Method | Primary NM | Content | Drop % | Notes |
|-------|--------|------------|---------|-------:|-------|
| **Monberaux** | cipher_drop | Maju | Geas Fete T4 | 9 | CORE |
| **August** | cipher_drop | Alfard | Abyssea Marks T3 | 11 | CORE |
| **Shantotto II** | cipher_drop | Absolute Virtue | Hunting League Rank V | 9 | CORE |
| **Sylvie UC** | direct_spell_grant | Tumult Curator | Unity Wanted T3 capstone | 9 | CORE — no cipher item |
| **Apururu UC** | direct_spell_grant | Chloris | Abyssea Marks T1 | 9 | CORE — no cipher item |
| **Zeid II** | cipher_drop | Orthrus | Abyssea Marks T3 | 9 | CORE; was Prestige Odin trial — moved to Abyssea |
| **Ygnas** | direct_spell_grant | Isgebind | Abyssea Marks T3 | 9 | CORE — no cipher item |
| **Ulmia** | direct_spell_grant | Pandemonium Warden | Hunting League Rank V | 9 | CORE — no cipher item |
| **Qultada** | cipher_drop | Glavoid | Reforge Unity [IV] | 11 | CORE |
| **Kupofried** | cipher_drop | Shinryu | Hunting League Rank V | 8 | CORE chase |
| **Joachim** | cipher_drop | Vrtra | Hunting League Rank III | 13 | NOTABLE |
| **Amchuchu** | cipher_drop | Apademak | Abyssea Marks T3 | 11 | NOTABLE |
| **Gessho** | direct_spell_grant | Simurgh | Hunting League Rank III | 13 | NOTABLE — no cipher item |

---

## 2. Cipher NM drops (80)

Sort: band → content pool → trust name.

| Item ID | Trust | Spell ID | Primary NM | `mob_groups.name` | Content | Band | Drop % | Notes |
|--------:|-------|---------:|------------|-------------------|---------|------|-------:|-------|
| 10122 | Mnejing | 926 | Wepwawet | `Wepwawet` | Geas Fete T1 | D1 | 15 |  |
| 10121 | Ovjang | 925 | Warder of Justice | `Warder_of_Justice` | Geas Fete T1 | D1 | 15 |  |
| 10123 | Sakura | 927 | Tangata Manu | `Tangata_Manu` | Geas Fete T1 | D1 | 15 |  |
| 10157 | Semih Lafihna | 940 | Warder of Faith | `Warder_of_Faith` | Geas Fete T1 | D1 | 15 |  |
| 10120 | Lehko Habhoka | 922 | Tom Tit Tat | `Tom_Tit_Tat` | Hunting League Rank I | D1 | 15 |  |
| 10115 | Mihli Aliapoh | 909 | Valkurm Emperor | `Valkurm_Emperor` | Hunting League Rank I | D1 | 15 |  |
| 10118 | Naja Salaheem | 912 | Leaping Lizzy | `Leaping_Lizzy` | Hunting League Rank I | D1 | 15 |  |
| 10153 | Adelheid | 968 | Aello | `Aello` | Reforge Abyssea [I] | D1 | 15 |  |
| 10127 | Moogle | 931 | Genbu | `Genbu` | Reforge Sky [I] | D1 | 15 |  |
| 10133 | Ferreous Coffin | 944 | Bukhis | `Bukhis` | Reforge Unity [I] | D1 | 15 |  |
| 10144 | Abenzio | 959 | Prickly Pitriv | `Prickly_Pitriv` | Unity Wanted T1 | D1 | 15 |  |
| 10149 | Areuhat | 939 | Emperor Arthro | `Emperor_Arthro` | Unity Wanted T1 | D1 | 15 |  |
| 10143 | Babban | 958 | Hugemaw Harold | `Hugemaw_Harold` | Unity Wanted T1 | D1 | 15 |  |
| 10130 | Elivira | 941 | Abyssdiver | `Abyssdiver` | Unity Wanted T1 | D1 | 15 |  |
| 10158 | Halver | 972 | Keeper of Heiligtum | `Keeper_of_Heiligtum` | Unity Wanted T1 | D1 | 15 |  |
| 10142 | Karaha-Baruha | 936 | Woodland Mender | `Woodland_Mender` | Unity Wanted T1 | D1 | 15 |  |
| 10146 | Kukki-Chebukki | 961 | Joyous Green | `Joyous_Green` | Unity Wanted T1 | D1 | 15 |  |
| 10132 | Lhu Mhakaracca | 943 | Warblade Beak | `Warblade_Beak` | Unity Wanted T1 | D1 | 15 |  |
| 10147 | Margret | 962 | Intuila | `Intuila` | Unity Wanted T1 | D1 | 15 |  |
| 10151 | Mayakov | 966 | Cactrot Veloz | `Cactrot_Veloz` | Unity Wanted T1 | D1 | 15 |  |
| 10125 | Najelith | 929 | Carabosse | `Carabosse` | Abyssea Marks T1 | D2 | 13 |  |
| 10166 | Robel-Akbel | 977 | Durinn | `Durinn` | Abyssea Marks T2 | D2 | 13 | Was Prestige Diabolos trial — moved to Abyssea |
| 10174 | Ingrid II | 1016 | Shaula | `Shaula` | Abyssea Marks T3 | D2 | 13 | Was Prestige Medusa trial — moved to Abyssea |
| 10129 | D. Shantotto | 934 | Kamohoalii | `Kamohoalii` | Geas Fete T2 | D2 | 13 |  |
| 10145 | Rughadjeen | 960 | Ionos | `Ionos` | Geas Fete T2 | D2 | 13 |  |
| 10155 | Brygid | 970 | Bomb Queen | `Bomb_Queen` | Hunting League Rank II | D2 | 13 |  |
| 10139 | Rahal | 951 | Roc | `Roc` | Hunting League Rank II | D2 | 13 |  |
| 10117 | Joachim | 911 | Vrtra | `Vrtra` | Hunting League Rank III | D2 | 13 | NOTABLE |
| 10185 | Iroha | 997 | Iratham | `Iratham` | Reforge Abyssea [II] | D2 | 13 |  |
| 10128 | Fablinix | 932 | Suzaku | `Suzaku` | Reforge Sky [II] | D2 | 13 |  |
| 10140 | Koru-Moru | 952 | Khun | `Khun` | Reforge Unity [II] | D2 | 13 |  |
| 10163 | Leonoyne | 974 | Aquarius | `Aquarius` | The Gauntlet L1 | D2 | 13 |  |
| 10134 | Star Sibyl | 935 | Serket | `Serket` | The Gauntlet L2 | D2 | 13 |  |
| 10135 | Mumor | 946 | Muut | `Muut` | Unity Wanted T2 | D2 | 13 |  |
| 10131 | Noillurie | 942 | Lumber Jill | `Lumber_Jill` | Unity Wanted T2 | D2 | 13 |  |
| 10167 | Tenzen II | 1014 | Thu'ban | `Thuban` | Unity Wanted T2 | D2 | 13 |  |
| 10181 | King of Hearts | 989 | Briareus | `Briareus` | Abyssea Marks T1 | D3 | 11 |  |
| 10184 | Arciela II | 1017 | Itzpapalotl | `Itzpapalotl` | Abyssea Marks T2 | D3 | 11 |  |
| 10165 | Kayeel-Payeel | 976 | Ketea | `Ketea` | Abyssea Marks T2 | D3 | 11 |  |
| 10164 | Maximilian | 975 | Dvalinn | `Dvalinn` | Abyssea Marks T2 | D3 | 11 |  |
| 10178 | Ullegore | 987 | Iku-Turso | `Iku-Turso` | Abyssea Marks T2 | D3 | 11 |  |
| 10154 | Amchuchu | 969 | Apademak | `Apademak` | Abyssea Marks T3 | D3 | 11 | NOTABLE |
| 10175 | August | 984 | Alfard | `Alfard` | Abyssea Marks T3 | D3 | 11 | CORE |
| 10177 | Mumor II | 1015 | Bennu | `Bennu` | Abyssea Marks T3 | D3 | 11 |  |
| 10191 | AA EV | 993 | Ark Angel EV | `Ark_Angel_EV` | Geas Fete T3 | D3 | 11 |  |
| 10192 | AA GK | 996 | Ark Angel GK | `Ark_Angel_GK` | Geas Fete T3 | D3 | 11 |  |
| 10188 | AA HM | 992 | Ark Angel HM | `Ark_Angel_HM` | Geas Fete T3 | D3 | 11 |  |
| 10190 | AA MR | 994 | Ark Angel MR | `Ark_Angel_MR` | Geas Fete T3 | D3 | 11 |  |
| 10189 | AA TT | 995 | Ark Angel TT | `Ark_Angel_TT` | Geas Fete T3 | D3 | 11 |  |
| 10172 | Balamor | 983 | Pazuzu | `Pazuzu` | Geas Fete T3 | D3 | 11 |  |
| 10161 | Rongelouts | 973 | Fleetstalker | `Fleetstalker` | Geas Fete T3 | D3 | 11 |  |
| 10176 | Rosulatia | 985 | Urmahlullu | `Urmahlullu` | Geas Fete T3 | D3 | 11 |  |
| 10148 | Gilgamesh | 938 | Genbu-Escha | `Genbu-Escha` | Geas Ru'Aun T3 | D3 | 11 |  |
| 10141 | Kuyin Hathdenna | 950 | Byakko-Escha | `Byakko-Escha` | Geas Ru'Aun T3 | D3 | 11 |  |
| 10124 | Luzaf | 928 | Seiryu-Escha | `Seiryu-Escha` | Geas Ru'Aun T3 | D3 | 11 |  |
| 10156 | Mildaurion | 971 | Kirin-Escha | `Kirin-Escha` | Geas Ru'Aun T3 | D3 | 11 |  |
| 10119 | Rainemard | 920 | King Behemoth | `King_Behemoth` | Hunting League Rank IV | D3 | 11 |  |
| 10112 | Zeid | 906 | Nidhogg | `Nidhogg` | Hunting League Rank IV | D3 | 11 |  |
| 10113 | Lion | 907 | Seiryu | `Seiryu` | Reforge Sky [III] | D3 | 11 |  |
| 10138 | Cid | 937 | Byakko | `Byakko` | Reforge Sky [IV] | D3 | 11 |  |
| 10137 | Lilisette | 945 | Padfoot | `Padfoot` | Reforge Unity [III] | D3 | 11 |  |
| 10152 | Qultada | 967 | Glavoid | `Glavoid` | Reforge Unity [IV] | D3 | 11 | CORE |
| 10186 | Iroha II | 1018 | Shedu | `Shedu` | Unity Wanted T3 | D3 | 11 |  |
| 10171 | Lilisette II | 1013 | Bakunawa | `Bakunawa` | Unity Wanted T3 | D3 | 11 |  |
| 10170 | Nashmeira II | 1012 | Specter Worm | `Specter_Worm` | Unity Wanted T3 | D3 | 11 |  |
| 10150 | Lhe Lhangavo | 964 | Kukulkan | `Kukulkan` | Abyssea Marks T1 | D4 | 9 | Was Prestige Sarameya trial — moved to Abyssea |
| 10179 | Teodor | 986 | Titlacauan | `Titlacauan` | Abyssea Marks T2 | D4 | 9 |  |
| 10168 | Prishe II | 1011 | Lorelei | `Lorelei` | Abyssea Marks T3 | D4 | 9 |  |
| 10136 | Uka Totlihn | 947 | Pantokrator | `Pantokrator` | Abyssea Marks T3 | D4 | 9 | Was Prestige Omega trial — moved to Abyssea |
| 10160 | Zeid II | 1010 | Orthrus | `Orthrus` | Abyssea Marks T3 | D4 | 9 | CORE; was Prestige Odin trial — moved to Abyssea |
| 10169 | Abquhbah | 982 | Teles | `Teles` | Geas Fete T4 | D4 | 9 |  |
| 10183 | Darrcuiln | 991 | Azi Dahaka | `Azi_Dahaka` | Geas Fete T4 | D4 | 9 |  |
| 10180 | Makki-Chebukki | 988 | Warder of Courage | `Warder_of_Courage` | Geas Fete T4 | D4 | 9 |  |
| 10193 | Monberaux | 999 | Maju | `Maju` | Geas Fete T4 | D4 | 9 | CORE |
| 10182 | Morimar | 990 | Warder of Hope | `Warder_of_Hope` | Geas Fete T4 | D4 | 9 |  |
| 10173 | Selh'Teus | 979 | Albumen | `Albumen` | Geas Fete T4 | D4 | 9 |  |
| 10187 | Shantotto II | 1019 | Absolute Virtue | `Absolute_Virtue` | Hunting League Rank V | D4 | 9 | CORE |
| 10116 | Valaineral | 910 | Kirin | `Kirin` | Reforge Sky [V] | D4 | 9 | Was Prestige trial — now Reforge Sky |
| 10159 | Lion II | 1009 | Tinnin | `Tinnin` | Reforge Unity [V] | D4 | 9 |  |
| 10162 | Kupofried | 978 | Shinryu | `Shinryu` | Hunting League Rank V | D5 | 8 | CORE chase |

---

## 3. Direct spell grants (31) — no cipher item

| Trust | Spell ID | Primary NM | `mob_groups.name` | Content | Band | Drop % | Notes |
|-------|---------:|------------|-------------------|---------|------|-------:|-------|
| Cherukiki | 916 | Bloodguzzler | `Bloodguzzler` | Abyssea Marks T1 | D1 | 15 | No cipher item |
| Naji | 897 | Arimaspi | `Arimaspi` | Abyssea Marks T1 | D1 | 15 | No cipher item |
| Ajido-Marujido | 904 | Immanibugard | `Immanibugard` | Unity Wanted T1 | D1 | 15 | No cipher item |
| Ayame | 900 | Jester Malatrix | `Jester_Malatrix` | Unity Wanted T1 | D1 | 15 | No cipher item |
| Romaa Mihgo | 949 | Ironhorn Baldurno | `Ironhorn_Baldurno` | Unity Wanted T1 | D1 | 15 | No cipher item |
| Zazarg | 924 | Tiyanak | `Tiyanak` | Unity Wanted T1 | D1 | 15 | No cipher item |
| Arciela | 965 | Eccentric Eve | `Eccentric_Eve` | Abyssea Marks T1 | D2 | 13 | No cipher item |
| Excenmille S | 1004 | Toppling Tuber | `Toppling_Tuber` | Abyssea Marks T1 | D2 | 13 | Variant trust; optional collection row |
| Iron Eater | 917 | Blazing Eruca | `Blazing_Eruca` | Abyssea Marks T2 | D2 | 13 | No cipher item |
| Klara | 948 | Lord Varney | `Lord_Varney` | Abyssea Marks T2 | D2 | 13 | No cipher item; was Infamy Maat fight |
| Prishe | 913 | Sirrush | `Sirrush` | Abyssea Marks T2 | D2 | 13 | No cipher item |
| Volker | 903 | Maahes | `Maahes` | Abyssea Marks T2 | D2 | 13 | No cipher item |
| Maat UC | 1006 | Amarok | `Amarok` | Abyssea Marks T3 | D2 | 13 | No cipher item |
| Gessho | 918 | Simurgh | `Simurgh` | Hunting League Rank III | D2 | 13 | NOTABLE — no cipher item |
| Gadalar | 919 | Garbage Gel | `Garbage_Gel` | Unity Wanted T2 | D2 | 13 | No cipher item |
| Ingrid | 921 | Strix | `Strix` | Unity Wanted T2 | D2 | 13 | No cipher item |
| Maat | 933 | Sovereign Behemoth | `Sovereign_Behemoth` | Unity Wanted T2 | D2 | 13 | No cipher item |
| Nashmeira | 923 | Arke | `Arke` | Unity Wanted T2 | D2 | 13 | No cipher item |
| Shikaree Z | 915 | Largantua | `Largantua` | Unity Wanted T2 | D2 | 13 | No cipher item |
| Ayame UC | 1005 | Wyvernhunter Bambrox | `Wyvernhunter_Bambrox` | Unity Wanted T3 | D3 | 11 | No cipher item |
| Flaviria UC | 957 | Mephitas | `Mephitas` | Unity Wanted T3 | D3 | 11 | No cipher item |
| Invincible Shield UC | 954 | Vidmapire | `Vidmapire` | Unity Wanted T3 | D3 | 11 | No cipher item |
| Jakoh UC | 956 | Tolba | `Tolba` | Unity Wanted T3 | D3 | 11 | No cipher item |
| Naja UC | 1008 | Ayapec | `Ayapec` | Unity Wanted T3 | D3 | 11 | No cipher item |
| Pieuje UC | 953 | Centurio XX-I | `Centurio_XX-I` | Unity Wanted T3 | D3 | 11 | No cipher item |
| Yoran-Oran UC | 980 | Coca | `Coca` | Unity Wanted T3 | D3 | 11 | No cipher item |
| Apururu UC | 955 | Chloris | `Chloris` | Abyssea Marks T1 | D4 | 9 | CORE — no cipher item |
| Chacharoon | 963 | Azdaja | `Azdaja` | Abyssea Marks T3 | D4 | 9 | No cipher item; was Prestige Ultima trial |
| Ygnas | 998 | Isgebind | `Isgebind` | Abyssea Marks T3 | D4 | 9 | CORE — no cipher item |
| Ulmia | 914 | Pandemonium Warden | `Pandemonium_Warden` | Hunting League Rank V | D4 | 9 | CORE — no cipher item |
| Sylvie UC | 981 | Tumult Curator | `Tumult_Curator` | Unity Wanted T3 capstone | D4 | 9 | CORE — no cipher item |

---

## 4. Starters / Void Keeper / Disabled

### Starters (free at login)

| Trust | Spell ID | Notes |
|-------|---------:|-------|
| Shantotto | 896 | Free at login — only non-NM unlock |
| Kupipi | 898 | Free at login — only non-NM unlock |
| Trion | 905 | Free at login — only non-NM unlock |
| Tenzen | 908 | Free at login; cipher 10114 must NOT drop |

### Void Keeper customs

| Trust | Spell ID | Cost / gate | Notes |
|-------|---------:|-------------|-------|
| Meat (Excenmille) | 899 | 10M | 50 trusts collected + 10M gil |
| Gemma (Nanaa Mihgo) | 901 | 10M | 60 trusts collected + 10M gil |
| Corvus (Curilla) | 902 | 10M | 40 trusts collected + 10M gil |
| Cornelia | 1002 | 50M | All 120 roster trusts + 50M gil |
| Matsui-P | 1003 | 50M | All 120 roster trusts + 50M gil |

### Disabled

| Item ID | Trust | Spell ID | Notes |
|--------:|-------|---------:|-------|
| 10126 | Aldo (Locke) | 930 | Temporarily removed from live roster / drops (2026-08-02) |
| — | Aldo UC | 1007 | Temporarily removed from live roster / drops (2026-08-02) |

---

## 5. By content pool (cipher drops only)

### Abyssea Marks T1 — 3 cipher(s)

| NM | Trust | Item | Band | Drop % |
|----|-------|-----:|------|-------:|
| Briareus | King of Hearts | 10181 | D3 | 11 |
| Kukulkan | Lhe Lhangavo | 10150 | D4 | 9 |
| Carabosse | Najelith | 10125 | D2 | 13 |

### Abyssea Marks T2 — 6 cipher(s)

| NM | Trust | Item | Band | Drop % |
|----|-------|-----:|------|-------:|
| Itzpapalotl | Arciela II | 10184 | D3 | 11 |
| Ketea | Kayeel-Payeel | 10165 | D3 | 11 |
| Dvalinn | Maximilian | 10164 | D3 | 11 |
| Durinn | Robel-Akbel | 10166 | D2 | 13 |
| Titlacauan | Teodor | 10179 | D4 | 9 |
| Iku-Turso | Ullegore | 10178 | D3 | 11 |

### Abyssea Marks T3 — 7 cipher(s)

| NM | Trust | Item | Band | Drop % |
|----|-------|-----:|------|-------:|
| Apademak | Amchuchu | 10154 | D3 | 11 |
| Alfard | August | 10175 | D3 | 11 |
| Shaula | Ingrid II | 10174 | D2 | 13 |
| Bennu | Mumor II | 10177 | D3 | 11 |
| Lorelei | Prishe II | 10168 | D4 | 9 |
| Pantokrator | Uka Totlihn | 10136 | D4 | 9 |
| Orthrus | Zeid II | 10160 | D4 | 9 |

### Geas Fete T1 — 4 cipher(s)

| NM | Trust | Item | Band | Drop % |
|----|-------|-----:|------|-------:|
| Wepwawet | Mnejing | 10122 | D1 | 15 |
| Warder of Justice | Ovjang | 10121 | D1 | 15 |
| Tangata Manu | Sakura | 10123 | D1 | 15 |
| Warder of Faith | Semih Lafihna | 10157 | D1 | 15 |

### Geas Fete T2 — 2 cipher(s)

| NM | Trust | Item | Band | Drop % |
|----|-------|-----:|------|-------:|
| Kamohoalii | D. Shantotto | 10129 | D2 | 13 |
| Ionos | Rughadjeen | 10145 | D2 | 13 |

### Geas Fete T3 — 8 cipher(s)

| NM | Trust | Item | Band | Drop % |
|----|-------|-----:|------|-------:|
| Ark Angel EV | AA EV | 10191 | D3 | 11 |
| Ark Angel GK | AA GK | 10192 | D3 | 11 |
| Ark Angel HM | AA HM | 10188 | D3 | 11 |
| Ark Angel MR | AA MR | 10190 | D3 | 11 |
| Ark Angel TT | AA TT | 10189 | D3 | 11 |
| Pazuzu | Balamor | 10172 | D3 | 11 |
| Fleetstalker | Rongelouts | 10161 | D3 | 11 |
| Urmahlullu | Rosulatia | 10176 | D3 | 11 |

### Geas Fete T4 — 6 cipher(s)

| NM | Trust | Item | Band | Drop % |
|----|-------|-----:|------|-------:|
| Teles | Abquhbah | 10169 | D4 | 9 |
| Azi Dahaka | Darrcuiln | 10183 | D4 | 9 |
| Warder of Courage | Makki-Chebukki | 10180 | D4 | 9 |
| Maju | Monberaux | 10193 | D4 | 9 |
| Warder of Hope | Morimar | 10182 | D4 | 9 |
| Albumen | Selh'Teus | 10173 | D4 | 9 |

### Geas Ru'Aun T3 — 4 cipher(s)

| NM | Trust | Item | Band | Drop % |
|----|-------|-----:|------|-------:|
| Genbu-Escha | Gilgamesh | 10148 | D3 | 11 |
| Byakko-Escha | Kuyin Hathdenna | 10141 | D3 | 11 |
| Seiryu-Escha | Luzaf | 10124 | D3 | 11 |
| Kirin-Escha | Mildaurion | 10156 | D3 | 11 |

### Hunting League Rank I — 3 cipher(s)

| NM | Trust | Item | Band | Drop % |
|----|-------|-----:|------|-------:|
| Tom Tit Tat | Lehko Habhoka | 10120 | D1 | 15 |
| Valkurm Emperor | Mihli Aliapoh | 10115 | D1 | 15 |
| Leaping Lizzy | Naja Salaheem | 10118 | D1 | 15 |

### Hunting League Rank II — 2 cipher(s)

| NM | Trust | Item | Band | Drop % |
|----|-------|-----:|------|-------:|
| Bomb Queen | Brygid | 10155 | D2 | 13 |
| Roc | Rahal | 10139 | D2 | 13 |

### Hunting League Rank III — 1 cipher(s)

| NM | Trust | Item | Band | Drop % |
|----|-------|-----:|------|-------:|
| Vrtra | Joachim | 10117 | D2 | 13 |

### Hunting League Rank IV — 2 cipher(s)

| NM | Trust | Item | Band | Drop % |
|----|-------|-----:|------|-------:|
| King Behemoth | Rainemard | 10119 | D3 | 11 |
| Nidhogg | Zeid | 10112 | D3 | 11 |

### Hunting League Rank V — 2 cipher(s)

| NM | Trust | Item | Band | Drop % |
|----|-------|-----:|------|-------:|
| Shinryu | Kupofried | 10162 | D5 | 8 |
| Absolute Virtue | Shantotto II | 10187 | D4 | 9 |

### Reforge Abyssea [I] — 1 cipher(s)

| NM | Trust | Item | Band | Drop % |
|----|-------|-----:|------|-------:|
| Aello | Adelheid | 10153 | D1 | 15 |

### Reforge Abyssea [II] — 1 cipher(s)

| NM | Trust | Item | Band | Drop % |
|----|-------|-----:|------|-------:|
| Iratham | Iroha | 10185 | D2 | 13 |

### Reforge Sky [I] — 1 cipher(s)

| NM | Trust | Item | Band | Drop % |
|----|-------|-----:|------|-------:|
| Genbu | Moogle | 10127 | D1 | 15 |

### Reforge Sky [II] — 1 cipher(s)

| NM | Trust | Item | Band | Drop % |
|----|-------|-----:|------|-------:|
| Suzaku | Fablinix | 10128 | D2 | 13 |

### Reforge Sky [III] — 1 cipher(s)

| NM | Trust | Item | Band | Drop % |
|----|-------|-----:|------|-------:|
| Seiryu | Lion | 10113 | D3 | 11 |

### Reforge Sky [IV] — 1 cipher(s)

| NM | Trust | Item | Band | Drop % |
|----|-------|-----:|------|-------:|
| Byakko | Cid | 10138 | D3 | 11 |

### Reforge Sky [V] — 1 cipher(s)

| NM | Trust | Item | Band | Drop % |
|----|-------|-----:|------|-------:|
| Kirin | Valaineral | 10116 | D4 | 9 |

### Reforge Unity [I] — 1 cipher(s)

| NM | Trust | Item | Band | Drop % |
|----|-------|-----:|------|-------:|
| Bukhis | Ferreous Coffin | 10133 | D1 | 15 |

### Reforge Unity [II] — 1 cipher(s)

| NM | Trust | Item | Band | Drop % |
|----|-------|-----:|------|-------:|
| Khun | Koru-Moru | 10140 | D2 | 13 |

### Reforge Unity [III] — 1 cipher(s)

| NM | Trust | Item | Band | Drop % |
|----|-------|-----:|------|-------:|
| Padfoot | Lilisette | 10137 | D3 | 11 |

### Reforge Unity [IV] — 1 cipher(s)

| NM | Trust | Item | Band | Drop % |
|----|-------|-----:|------|-------:|
| Glavoid | Qultada | 10152 | D3 | 11 |

### Reforge Unity [V] — 1 cipher(s)

| NM | Trust | Item | Band | Drop % |
|----|-------|-----:|------|-------:|
| Tinnin | Lion II | 10159 | D4 | 9 |

### The Gauntlet L1 — 1 cipher(s)

| NM | Trust | Item | Band | Drop % |
|----|-------|-----:|------|-------:|
| Aquarius | Leonoyne | 10163 | D2 | 13 |

### The Gauntlet L2 — 1 cipher(s)

| NM | Trust | Item | Band | Drop % |
|----|-------|-----:|------|-------:|
| Serket | Star Sibyl | 10134 | D2 | 13 |

### Unity Wanted T1 — 10 cipher(s)

| NM | Trust | Item | Band | Drop % |
|----|-------|-----:|------|-------:|
| Prickly Pitriv | Abenzio | 10144 | D1 | 15 |
| Emperor Arthro | Areuhat | 10149 | D1 | 15 |
| Hugemaw Harold | Babban | 10143 | D1 | 15 |
| Abyssdiver | Elivira | 10130 | D1 | 15 |
| Keeper of Heiligtum | Halver | 10158 | D1 | 15 |
| Woodland Mender | Karaha-Baruha | 10142 | D1 | 15 |
| Joyous Green | Kukki-Chebukki | 10146 | D1 | 15 |
| Warblade Beak | Lhu Mhakaracca | 10132 | D1 | 15 |
| Intuila | Margret | 10147 | D1 | 15 |
| Cactrot Veloz | Mayakov | 10151 | D1 | 15 |

### Unity Wanted T2 — 3 cipher(s)

| NM | Trust | Item | Band | Drop % |
|----|-------|-----:|------|-------:|
| Muut | Mumor | 10135 | D2 | 13 |
| Lumber Jill | Noillurie | 10131 | D2 | 13 |
| Thu'ban | Tenzen II | 10167 | D2 | 13 |

### Unity Wanted T3 — 3 cipher(s)

| NM | Trust | Item | Band | Drop % |
|----|-------|-----:|------|-------:|
| Shedu | Iroha II | 10186 | D3 | 11 |
| Bakunawa | Lilisette II | 10171 | D3 | 11 |
| Specter Worm | Nashmeira II | 10170 | D3 | 11 |

---

## 6. Open decisions for implementation

1. Hook `onMobDeath` for HL / Unity / Geas / Reforge / Abyssea Marks / Gauntlet
2. Dupe conversion — Hunt Marks vs gil vs skip silently
3. Collection UI — `!trusts` / Void Keeper board showing farmable progress
4. Tenzen cipher **10114** must not drop (starter is free)
5. Excenmille S — count toward full collection or optional side collect?

---

## 7. File references

| Resource | Path |
|----------|------|
| **CSV source of truth** | `exports/trust_cipher_drop_proposal.csv` |
| Cipher item names | `modules/custom/lua/trust_cipher_catalog.lua` |
| Usable cipher wiring | `modules/custom/lua/trust_cipher_usable.lua` |
| Item IDs | `scripts/enum/item.lua` (10112–10193) |
| HL catalog | `modules/custom/lua/hunting_league_catalog.lua` |
| Reforge catalog | `modules/custom/lua/reforge_catalog.lua` |
| Unity catalog | `modules/custom/lua/unity_wanted_catalog.lua` |
| Geas | `modules/custom/lua/Geas_Fete.lua` |
| Abyssea Marks | `modules/custom/lua/abyssea_marks_catalog.lua` / `AbysseaMarks.lua` |
| Gauntlet | `modules/custom/lua/gauntlet_catalog.lua` |

*Regenerated from CSV — edit the CSV, then refresh this markdown.*

