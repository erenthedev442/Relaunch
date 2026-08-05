# Trust Cipher Drop Proposal — Dev Review Draft

**Status:** Implemented · `trust_cipher_drops.lua` + per-system death hooks  
**Last updated:** 2026-08-03 (rank 1–5 review tables)  
**Source of truth:** [`exports/trust_cipher_drop_proposal.csv`](trust_cipher_drop_proposal.csv)  
**By-rank sheet:** [`exports/trust_cipher_drop_by_rank.csv`](trust_cipher_drop_by_rank.csv)  
**Related:** usable ciphers + drop helper (`trust_cipher_drops.lua`)

---

## Trusts by Rank (1–5) — review table

Rank mirrors drop band: **1 = D1 (15%)** · **2 = D2 (13%)** · **3 = D3 (11%)** · **4 = D4 (9%)** · **5 = D5 (8%)**.  
`Power` is the trust combat tier from `trust_power_catalog` (C/B/A/S), for feedback — not the drop rank.

### Rank 1 — D1 · 15% · 26 trusts

| Power | Trust | Method | Primary NM | Content | Drop % | Item | Spell |
|:-----:|-------|--------|------------|---------|-------:|-----:|------:|
| C | Abenzio | cipher | Prickly Pitriv | Unity Wanted T1 | 15 | 10144 | 959 |
| C | Adelheid | cipher | Aello | Reforge Abyssea [I] | 15 | 10153 | 968 |
| C | Ajido-Marujido | direct | Immanibugard | Unity Wanted T1 | 15 | — | 904 |
| C | Areuhat | cipher | Emperor Arthro | Unity Wanted T1 | 15 | 10149 | 939 |
| C | Ayame | direct | Jester Malatrix | Unity Wanted T1 | 15 | — | 900 |
| C | Babban | cipher | Hugemaw Harold | Unity Wanted T1 | 15 | 10143 | 958 |
| C | Cherukiki | direct | Bloodguzzler | Abyssea Marks T1 | 15 | — | 916 |
| C | Elivira | cipher | Abyssdiver | Unity Wanted T1 | 15 | 10130 | 941 |
| C | Ferreous Coffin | cipher | Bukhis | Reforge Unity [I] | 15 | 10133 | 944 |
| C | Halver | cipher | Keeper of Heiligtum | Unity Wanted T1 | 15 | 10158 | 972 |
| C | Karaha-Baruha | cipher | Woodland Mender | Unity Wanted T1 | 15 | 10142 | 936 |
| C | Kukki-Chebukki | cipher | Joyous Green | Unity Wanted T1 | 15 | 10146 | 961 |
| C | Lehko Habhoka | cipher | Tom Tit Tat | Hunting League Rank I | 15 | 10120 | 922 |
| C | Lhu Mhakaracca | cipher | Warblade Beak | Unity Wanted T1 | 15 | 10132 | 943 |
| C | Margret | cipher | Intuila | Unity Wanted T1 | 15 | 10147 | 962 |
| C | Mayakov | cipher | Cactrot Veloz | Unity Wanted T1 | 15 | 10151 | 966 |
| C | Mihli Aliapoh | cipher | Valkurm Emperor | Hunting League Rank I | 15 | 10115 | 909 |
| C | Mnejing | cipher | Wepwawet | Geas Fete T1 | 15 | 10122 | 926 |
| C | Moogle | cipher | Genbu | Reforge Sky [I] | 15 | 10127 | 931 |
| C | Naja Salaheem | cipher | Leaping Lizzy | Hunting League Rank I | 15 | 10118 | 912 |
| C | Naji | direct | Arimaspi | Abyssea Marks T1 | 15 | — | 897 |
| C | Ovjang | cipher | Warder of Justice | Geas Fete T1 | 15 | 10121 | 925 |
| C | Romaa Mihgo | direct | Ironhorn Baldurno | Unity Wanted T1 | 15 | — | 949 |
| C | Sakura | cipher | Tangata Manu | Geas Fete T1 | 15 | 10123 | 927 |
| C | Semih Lafihna | cipher | Warder of Faith | Geas Fete T1 | 15 | 10157 | 940 |
| C | Zazarg | direct | Tiyanak | Unity Wanted T1 | 15 | — | 924 |

### Rank 2 — D2 · 13% · 29 trusts

| Power | Trust | Method | Primary NM | Content | Drop % | Item | Spell |
|:-----:|-------|--------|------------|---------|-------:|-----:|------:|
| B | Arciela | direct | Eccentric Eve | Abyssea Marks T1 | 13 | — | 965 |
| B | Brygid | cipher | Bomb Queen | Hunting League Rank II | 13 | 10155 | 970 |
| B | D. Shantotto | cipher | Kamohoalii | Geas Fete T2 | 13 | 10129 | 934 |
| — | Excenmille S | disabled | — | — | 0 | Slot is Matsui-P (Void Keeper) | 1004 |
| B | Fablinix | cipher | Suzaku | Reforge Sky [II] | 13 | 10128 | 932 |
| B | Gadalar | direct | Garbage Gel | Unity Wanted T2 | 13 | — | 919 |
| B | Ingrid | direct | Strix | Unity Wanted T2 | 13 | — | 921 |
| B | Ingrid II | cipher | Shaula | Abyssea Marks T3 | 13 | 10174 | 1016 |
| B | Iroha | cipher | Iratham | Reforge Abyssea [II] | 13 | 10185 | 997 |
| B | Iron Eater | direct | Blazing Eruca | Abyssea Marks T2 | 13 | — | 917 |
| B | Joachim | cipher | Vrtra | Hunting League Rank III | 13 | 10117 | 911 |
| B | Klara | direct | Lord Varney | Abyssea Marks T2 | 13 | — | 948 |
| B | Koru-Moru | cipher | Khun | Reforge Unity [II] | 13 | 10140 | 952 |
| B | Leonoyne | cipher | Aquarius | The Gauntlet L1 | 13 | 10163 | 974 |
| B | Maat | direct | Sovereign Behemoth | Unity Wanted T2 | 13 | — | 933 |
| B | Maat UC | direct | Amarok | Abyssea Marks T3 | 13 | — | 1006 |
| B | Mumor | cipher | Muut | Unity Wanted T2 | 13 | 10135 | 946 |
| B | Najelith | cipher | Carabosse | Abyssea Marks T1 | 13 | 10125 | 929 |
| B | Nashmeira | direct | Arke | Unity Wanted T2 | 13 | — | 923 |
| B | Noillurie | cipher | Lumber Jill | Unity Wanted T2 | 13 | 10131 | 942 |
| B | Prishe | direct | Sirrush | Abyssea Marks T2 | 13 | — | 913 |
| B | Rahal | cipher | Roc | Hunting League Rank II | 13 | 10139 | 951 |
| B | Robel-Akbel | cipher | Durinn | Abyssea Marks T2 | 13 | 10166 | 977 |
| B | Rughadjeen | cipher | Ionos | Geas Fete T2 | 13 | 10145 | 960 |
| B | Shikaree Z | direct | Largantua | Unity Wanted T2 | 13 | — | 915 |
| B | Star Sibyl | cipher | Serket | The Gauntlet L2 | 13 | 10134 | 935 |
| B | Tenzen II | cipher | Thu'ban | Unity Wanted T2 | 13 | 10167 | 1014 |
| B | Volker | direct | Maahes | Abyssea Marks T2 | 13 | — | 903 |
| C | Gessho | direct | Simurgh | Hunting League Rank III | 13 | — | 918 |

### Rank 3 — D3 · 11% · 36 trusts

| Power | Trust | Method | Primary NM | Content | Drop % | Item | Spell |
|:-----:|-------|--------|------------|---------|-------:|-----:|------:|
| A | AA EV | cipher | Ark Angel EV | Geas Fete T3 | 11 | 10191 | 993 |
| A | AA GK | cipher | Ark Angel GK | Geas Fete T3 | 11 | 10192 | 996 |
| A | AA HM | cipher | Ark Angel HM | Geas Fete T3 | 11 | 10188 | 992 |
| A | AA MR | cipher | Ark Angel MR | Geas Fete T3 | 11 | 10190 | 994 |
| A | AA TT | cipher | Ark Angel TT | Geas Fete T3 | 11 | 10189 | 995 |
| A | Arciela II | cipher | Itzpapalotl | Abyssea Marks T2 | 11 | 10184 | 1017 |
| A | Ayame UC | direct | Wyvernhunter Bambrox | Unity Wanted T3 | 11 | — | 1005 |
| A | Balamor | cipher | Pazuzu | Geas Fete T3 | 11 | 10172 | 983 |
| A | Cid | cipher | Byakko | Reforge Sky [IV] | 11 | 10138 | 937 |
| A | Flaviria UC | direct | Mephitas | Unity Wanted T3 | 11 | — | 957 |
| A | Gilgamesh | cipher | Genbu-Escha | Geas Ru'Aun T3 | 11 | 10148 | 938 |
| A | Invincible Shield UC | direct | Vidmapire | Unity Wanted T3 | 11 | — | 954 |
| A | Iroha II | cipher | Shedu | Unity Wanted T3 | 11 | 10186 | 1018 |
| A | Jakoh UC | direct | Tolba | Unity Wanted T3 | 11 | — | 956 |
| A | Kayeel-Payeel | cipher | Ketea | Abyssea Marks T2 | 11 | 10165 | 976 |
| A | King of Hearts | cipher | Briareus | Abyssea Marks T1 | 11 | 10181 | 989 |
| A | Kuyin Hathdenna | cipher | Byakko-Escha | Geas Ru'Aun T3 | 11 | 10141 | 950 |
| A | Lilisette | cipher | Padfoot | Reforge Unity [III] | 11 | 10137 | 945 |
| A | Lilisette II | cipher | Bakunawa | Unity Wanted T3 | 11 | 10171 | 1013 |
| A | Lion | cipher | Seiryu | Reforge Sky [III] | 11 | 10113 | 907 |
| A | Luzaf | cipher | Seiryu-Escha | Geas Ru'Aun T3 | 11 | 10124 | 928 |
| A | Maximilian | cipher | Dvalinn | Abyssea Marks T2 | 11 | 10164 | 975 |
| A | Mildaurion | cipher | Kirin | Geas Ru'Aun T3 | 11 | 10156 | 971 |
| A | Mumor II | cipher | Bennu | Abyssea Marks T3 | 11 | 10177 | 1015 |
| A | Naja UC | direct | Ayapec | Unity Wanted T3 | 11 | — | 1008 |
| A | Nashmeira II | cipher | Specter Worm | Unity Wanted T3 | 11 | 10170 | 1012 |
| A | Pieuje UC | direct | Centurio XX-I | Unity Wanted T3 | 11 | — | 953 |
| A | Qultada | cipher | Glavoid | Reforge Unity [IV] | 11 | 10152 | 967 |
| A | Rainemard | cipher | King Behemoth | Hunting League Rank IV | 11 | 10119 | 920 |
| A | Rongelouts | cipher | Fleetstalker | Geas Fete T3 | 11 | 10161 | 973 |
| A | Rosulatia | cipher | Urmahlullu | Geas Fete T3 | 11 | 10176 | 985 |
| A | Ullegore | cipher | Iku-Turso | Abyssea Marks T2 | 11 | 10178 | 987 |
| A | Yoran-Oran UC | direct | Coca | Unity Wanted T3 | 11 | — | 980 |
| A | Zeid | cipher | Nidhogg | Hunting League Rank IV | 11 | 10112 | 906 |
| B | Amchuchu | cipher | Apademak | Abyssea Marks T3 | 11 | 10154 | 969 |
| S | August | cipher | Alfard | Abyssea Marks T3 | 11 | 10175 | 984 |

### Rank 4 — D4 · 9% · 19 trusts

| Power | Trust | Method | Primary NM | Content | Drop % | Item | Spell |
|:-----:|-------|--------|------------|---------|-------:|-----:|------:|
| A | Abquhbah | cipher | Teles | Geas Fete T4 | 9 | 10169 | 982 |
| A | Monberaux | cipher | Maju | Geas Fete T4 | 9 | 10193 | 999 |
| A | Selh'Teus | cipher | Albumen | Geas Fete T4 | 9 | 10173 | 979 |
| A | Valaineral | cipher | Kirin | Reforge Sky [V] | 9 | 10116 | 910 |
| B | Chacharoon | direct | Azdaja | Abyssea Marks T3 | 9 | — | 963 |
| S | Apururu UC | direct | Chloris | Abyssea Marks T1 | 9 | — | 955 |
| S | Darrcuiln | cipher | Azi Dahaka | Geas Fete T4 | 9 | 10183 | 991 |
| S | Lhe Lhangavo | cipher | Kukulkan | Abyssea Marks T1 | 9 | 10150 | 964 |
| S | Lion II | cipher | Tinnin | Reforge Unity [V] | 9 | 10159 | 1009 |
| S | Makki-Chebukki | cipher | Warder of Courage | Geas Fete T4 | 9 | 10180 | 988 |
| S | Morimar | cipher | Warder of Hope | Geas Fete T4 | 9 | 10182 | 990 |
| S | Prishe II | cipher | Lorelei | Abyssea Marks T3 | 9 | 10168 | 1011 |
| S | Shantotto II | cipher | Absolute Virtue | Hunting League Rank V | 9 | 10187 | 1019 |
| S | Sylvie UC | direct | Tumult Curator | Unity Wanted T3 capstone | 9 | — | 981 |
| S | Teodor | cipher | Titlacauan | Abyssea Marks T2 | 9 | 10179 | 986 |
| S | Uka Totlihn | cipher | Pantokrator | Abyssea Marks T3 | 9 | 10136 | 947 |
| S | Ulmia | direct | Pandemonium Warden | Hunting League Rank V | 9 | — | 914 |
| S | Ygnas | direct | Isgebind | Abyssea Marks T3 | 9 | — | 998 |
| S | Zeid II | cipher | Orthrus | Abyssea Marks T3 | 9 | 10160 | 1010 |

### Rank 5 — D5 · 8% · 1 trusts

| Power | Trust | Method | Primary NM | Content | Drop % | Item | Spell |
|:-----:|-------|--------|------------|---------|-------:|-----:|------:|
| S | Kupofried | cipher | Shinryu | Hunting League Rank V | 8 | 10162 | 978 |

### Not in Rank 1–5 (starters / Void Keeper / disabled)

| Trust | Method | Notes |
|-------|--------|-------|
| Aldo (Locke) | disabled | Temporarily removed from live roster / drops (2026-08-02) |
| Aldo UC | disabled | Temporarily removed from live roster / drops (2026-08-02) |
| Shantotto | starter | Free at login — only non-NM unlock |
| Kupipi | starter | Free at login — only non-NM unlock |
| Trion | starter | Free at login — only non-NM unlock |
| Tenzen | starter | Free at login; cipher 10114 must NOT drop |
| Meat (Excenmille) | void_keeper | 50 trusts collected + 10M gil |
| Gemma (Nanaa Mihgo) | void_keeper | 60 trusts collected + 10M gil |
| Corvus (Curilla) | void_keeper | 40 trusts collected + 10M gil |
| Cornelia | void_keeper | All 120 roster trusts + 50M gil |
| Matsui-P | void_keeper | All 120 roster trusts + 50M gil |

---

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
| **Dupe protection** | If player already knows the trust: skip roll |
| **Excluded systems** | No Prestige / Rebirth / Infamy gates for these farms; no paid cipher purchases |

### Drop rate bands (= Rank)

| Rank | Band | Example content | Drop rate |
|-----:|------|-----------------|----------:|
| **1** | D1 — Entry | HL Rank I, Reforge [I], Unity T1, Geas T1, Abyssea Marks T1 | **15%** |
| **2** | D2 — Mid | HL Rank II–III, Reforge [II–III], Unity T2, Geas T2, Abyssea Marks T2 | **13%** |
| **3** | D3 — Hard | HL Rank IV, Reforge [IV], Unity T3, Geas T3, Abyssea Marks T2–3 | **11%** |
| **4** | D4 — Apex | HL Rank V, Reforge [V], Geas T4, Abyssea Marks T3, Gauntlet high | **9%** |
| **5** | D5 — Chase | Shinryu (HL Rank V) | **8%** |

---

## 2. Cipher NM drops (80)

| Rank | Item ID | Trust | Power | Spell | Primary NM | Content | Drop % | Notes |
|-----:|--------:|-------|:-----:|------:|------------|---------|-------:|-------|
| 1 | 10122 | Mnejing | C | 926 | Wepwawet | Geas Fete T1 | 15 |  |
| 1 | 10121 | Ovjang | C | 925 | Warder of Justice | Geas Fete T1 | 15 |  |
| 1 | 10123 | Sakura | C | 927 | Tangata Manu | Geas Fete T1 | 15 |  |
| 1 | 10157 | Semih Lafihna | C | 940 | Warder of Faith | Geas Fete T1 | 15 |  |
| 1 | 10120 | Lehko Habhoka | C | 922 | Tom Tit Tat | Hunting League Rank I | 15 |  |
| 1 | 10115 | Mihli Aliapoh | C | 909 | Valkurm Emperor | Hunting League Rank I | 15 |  |
| 1 | 10118 | Naja Salaheem | C | 912 | Leaping Lizzy | Hunting League Rank I | 15 |  |
| 1 | 10153 | Adelheid | C | 968 | Aello | Reforge Abyssea [I] | 15 |  |
| 1 | 10127 | Moogle | C | 931 | Genbu | Reforge Sky [I] | 15 |  |
| 1 | 10133 | Ferreous Coffin | C | 944 | Bukhis | Reforge Unity [I] | 15 |  |
| 1 | 10144 | Abenzio | C | 959 | Prickly Pitriv | Unity Wanted T1 | 15 |  |
| 1 | 10149 | Areuhat | C | 939 | Emperor Arthro | Unity Wanted T1 | 15 |  |
| 1 | 10143 | Babban | C | 958 | Hugemaw Harold | Unity Wanted T1 | 15 |  |
| 1 | 10130 | Elivira | C | 941 | Abyssdiver | Unity Wanted T1 | 15 |  |
| 1 | 10158 | Halver | C | 972 | Keeper of Heiligtum | Unity Wanted T1 | 15 |  |
| 1 | 10142 | Karaha-Baruha | C | 936 | Woodland Mender | Unity Wanted T1 | 15 |  |
| 1 | 10146 | Kukki-Chebukki | C | 961 | Joyous Green | Unity Wanted T1 | 15 |  |
| 1 | 10132 | Lhu Mhakaracca | C | 943 | Warblade Beak | Unity Wanted T1 | 15 |  |
| 1 | 10147 | Margret | C | 962 | Intuila | Unity Wanted T1 | 15 |  |
| 1 | 10151 | Mayakov | C | 966 | Cactrot Veloz | Unity Wanted T1 | 15 |  |
| 2 | 10125 | Najelith | B | 929 | Carabosse | Abyssea Marks T1 | 13 |  |
| 2 | 10166 | Robel-Akbel | B | 977 | Durinn | Abyssea Marks T2 | 13 | Was Prestige Diabolos trial — moved to Abyssea |
| 2 | 10174 | Ingrid II | B | 1016 | Shaula | Abyssea Marks T3 | 13 | Was Prestige Medusa trial — moved to Abyssea |
| 2 | 10129 | D. Shantotto | B | 934 | Kamohoalii | Geas Fete T2 | 13 |  |
| 2 | 10145 | Rughadjeen | B | 960 | Ionos | Geas Fete T2 | 13 |  |
| 2 | 10155 | Brygid | B | 970 | Bomb Queen | Hunting League Rank II | 13 |  |
| 2 | 10139 | Rahal | B | 951 | Roc | Hunting League Rank II | 13 |  |
| 2 | 10117 | Joachim | B | 911 | Vrtra | Hunting League Rank III | 13 | NOTABLE |
| 2 | 10185 | Iroha | B | 997 | Iratham | Reforge Abyssea [II] | 13 |  |
| 2 | 10128 | Fablinix | B | 932 | Suzaku | Reforge Sky [II] | 13 |  |
| 2 | 10140 | Koru-Moru | B | 952 | Khun | Reforge Unity [II] | 13 |  |
| 2 | 10163 | Leonoyne | B | 974 | Aquarius | The Gauntlet L1 | 13 |  |
| 2 | 10134 | Star Sibyl | B | 935 | Serket | The Gauntlet L2 | 13 |  |
| 2 | 10135 | Mumor | B | 946 | Muut | Unity Wanted T2 | 13 |  |
| 2 | 10131 | Noillurie | B | 942 | Lumber Jill | Unity Wanted T2 | 13 |  |
| 2 | 10167 | Tenzen II | B | 1014 | Thu'ban | Unity Wanted T2 | 13 |  |
| 3 | 10181 | King of Hearts | A | 989 | Briareus | Abyssea Marks T1 | 11 |  |
| 3 | 10184 | Arciela II | A | 1017 | Itzpapalotl | Abyssea Marks T2 | 11 |  |
| 3 | 10165 | Kayeel-Payeel | A | 976 | Ketea | Abyssea Marks T2 | 11 |  |
| 3 | 10164 | Maximilian | A | 975 | Dvalinn | Abyssea Marks T2 | 11 |  |
| 3 | 10178 | Ullegore | A | 987 | Iku-Turso | Abyssea Marks T2 | 11 |  |
| 3 | 10154 | Amchuchu | B | 969 | Apademak | Abyssea Marks T3 | 11 | NOTABLE |
| 3 | 10175 | August | S | 984 | Alfard | Abyssea Marks T3 | 11 | CORE |
| 3 | 10177 | Mumor II | A | 1015 | Bennu | Abyssea Marks T3 | 11 |  |
| 3 | 10191 | AA EV | A | 993 | Ark Angel EV | Geas Fete T3 | 11 |  |
| 3 | 10192 | AA GK | A | 996 | Ark Angel GK | Geas Fete T3 | 11 |  |
| 3 | 10188 | AA HM | A | 992 | Ark Angel HM | Geas Fete T3 | 11 |  |
| 3 | 10190 | AA MR | A | 994 | Ark Angel MR | Geas Fete T3 | 11 |  |
| 3 | 10189 | AA TT | A | 995 | Ark Angel TT | Geas Fete T3 | 11 |  |
| 3 | 10172 | Balamor | A | 983 | Pazuzu | Geas Fete T3 | 11 |  |
| 3 | 10161 | Rongelouts | A | 973 | Fleetstalker | Geas Fete T3 | 11 |  |
| 3 | 10176 | Rosulatia | A | 985 | Urmahlullu | Geas Fete T3 | 11 |  |
| 3 | 10148 | Gilgamesh | A | 938 | Genbu-Escha | Geas Ru'Aun T3 | 11 |  |
| 3 | 10141 | Kuyin Hathdenna | A | 950 | Byakko-Escha | Geas Ru'Aun T3 | 11 |  |
| 3 | 10124 | Luzaf | A | 928 | Seiryu-Escha | Geas Ru'Aun T3 | 11 |  |
| 3 | 10156 | Mildaurion | A | 971 | Kirin | Geas Ru'Aun T3 | 11 | Geas catalog name is Kirin (not Kirin-Escha) |
| 3 | 10119 | Rainemard | A | 920 | King Behemoth | Hunting League Rank IV | 11 |  |
| 3 | 10112 | Zeid | A | 906 | Nidhogg | Hunting League Rank IV | 11 |  |
| 3 | 10113 | Lion | A | 907 | Seiryu | Reforge Sky [III] | 11 |  |
| 3 | 10138 | Cid | A | 937 | Byakko | Reforge Sky [IV] | 11 |  |
| 3 | 10137 | Lilisette | A | 945 | Padfoot | Reforge Unity [III] | 11 |  |
| 3 | 10152 | Qultada | A | 967 | Glavoid | Reforge Unity [IV] | 11 | CORE |
| 3 | 10186 | Iroha II | A | 1018 | Shedu | Unity Wanted T3 | 11 |  |
| 3 | 10171 | Lilisette II | A | 1013 | Bakunawa | Unity Wanted T3 | 11 |  |
| 3 | 10170 | Nashmeira II | A | 1012 | Specter Worm | Unity Wanted T3 | 11 |  |
| 4 | 10150 | Lhe Lhangavo | S | 964 | Kukulkan | Abyssea Marks T1 | 9 | Was Prestige Sarameya trial — moved to Abyssea |
| 4 | 10179 | Teodor | S | 986 | Titlacauan | Abyssea Marks T2 | 9 |  |
| 4 | 10168 | Prishe II | S | 1011 | Lorelei | Abyssea Marks T3 | 9 |  |
| 4 | 10136 | Uka Totlihn | S | 947 | Pantokrator | Abyssea Marks T3 | 9 | Was Prestige Omega trial — moved to Abyssea |
| 4 | 10160 | Zeid II | S | 1010 | Orthrus | Abyssea Marks T3 | 9 | CORE; was Prestige Odin trial — moved to Abyssea |
| 4 | 10169 | Abquhbah | A | 982 | Teles | Geas Fete T4 | 9 |  |
| 4 | 10183 | Darrcuiln | S | 991 | Azi Dahaka | Geas Fete T4 | 9 |  |
| 4 | 10180 | Makki-Chebukki | S | 988 | Warder of Courage | Geas Fete T4 | 9 |  |
| 4 | 10193 | Monberaux | A | 999 | Maju | Geas Fete T4 | 9 | CORE |
| 4 | 10182 | Morimar | S | 990 | Warder of Hope | Geas Fete T4 | 9 |  |
| 4 | 10173 | Selh'Teus | A | 979 | Albumen | Geas Fete T4 | 9 |  |
| 4 | 10187 | Shantotto II | S | 1019 | Absolute Virtue | Hunting League Rank V | 9 | CORE |
| 4 | 10116 | Valaineral | A | 910 | Kirin | Reforge Sky [V] | 9 | Was Prestige trial — now Reforge Sky |
| 4 | 10159 | Lion II | S | 1009 | Tinnin | Reforge Unity [V] | 9 |  |
| 5 | 10162 | Kupofried | S | 978 | Shinryu | Hunting League Rank V | 8 | CORE chase |

---

## 3. Direct spell grants (31)

| Rank | Trust | Power | Spell | Primary NM | Content | Drop % | Notes |
|-----:|-------|:-----:|------:|------------|---------|-------:|-------|
| 1 | Cherukiki | C | 916 | Bloodguzzler | Abyssea Marks T1 | 15 | No cipher item |
| 1 | Naji | C | 897 | Arimaspi | Abyssea Marks T1 | 15 | No cipher item |
| 1 | Ajido-Marujido | C | 904 | Immanibugard | Unity Wanted T1 | 15 | No cipher item |
| 1 | Ayame | C | 900 | Jester Malatrix | Unity Wanted T1 | 15 | No cipher item |
| 1 | Romaa Mihgo | C | 949 | Ironhorn Baldurno | Unity Wanted T1 | 15 | No cipher item |
| 1 | Zazarg | C | 924 | Tiyanak | Unity Wanted T1 | 15 | No cipher item |
| 2 | Arciela | B | 965 | Eccentric Eve | Abyssea Marks T1 | 13 | No cipher item |
| — | Excenmille S | — | 1004 | — | — | 0 | Slot is Matsui-P (Void Keeper); Toppling Tuber drop retired |
| 2 | Iron Eater | B | 917 | Blazing Eruca | Abyssea Marks T2 | 13 | No cipher item |
| 2 | Klara | B | 948 | Lord Varney | Abyssea Marks T2 | 13 | No cipher item; was Infamy Maat fight |
| 2 | Prishe | B | 913 | Sirrush | Abyssea Marks T2 | 13 | No cipher item |
| 2 | Volker | B | 903 | Maahes | Abyssea Marks T2 | 13 | No cipher item |
| 2 | Maat UC | B | 1006 | Amarok | Abyssea Marks T3 | 13 | No cipher item |
| 2 | Gessho | C | 918 | Simurgh | Hunting League Rank III | 13 | NOTABLE — no cipher item |
| 2 | Gadalar | B | 919 | Garbage Gel | Unity Wanted T2 | 13 | No cipher item |
| 2 | Ingrid | B | 921 | Strix | Unity Wanted T2 | 13 | No cipher item |
| 2 | Maat | B | 933 | Sovereign Behemoth | Unity Wanted T2 | 13 | No cipher item |
| 2 | Nashmeira | B | 923 | Arke | Unity Wanted T2 | 13 | No cipher item |
| 2 | Shikaree Z | B | 915 | Largantua | Unity Wanted T2 | 13 | No cipher item |
| 3 | Ayame UC | A | 1005 | Wyvernhunter Bambrox | Unity Wanted T3 | 11 | No cipher item |
| 3 | Flaviria UC | A | 957 | Mephitas | Unity Wanted T3 | 11 | No cipher item |
| 3 | Invincible Shield UC | A | 954 | Vidmapire | Unity Wanted T3 | 11 | No cipher item |
| 3 | Jakoh UC | A | 956 | Tolba | Unity Wanted T3 | 11 | No cipher item |
| 3 | Naja UC | A | 1008 | Ayapec | Unity Wanted T3 | 11 | No cipher item |
| 3 | Pieuje UC | A | 953 | Centurio XX-I | Unity Wanted T3 | 11 | No cipher item |
| 3 | Yoran-Oran UC | A | 980 | Coca | Unity Wanted T3 | 11 | No cipher item |
| 4 | Apururu UC | S | 955 | Chloris | Abyssea Marks T1 | 9 | CORE — no cipher item |
| 4 | Chacharoon | B | 963 | Azdaja | Abyssea Marks T3 | 9 | No cipher item; was Prestige Ultima trial |
| 4 | Ygnas | S | 998 | Isgebind | Abyssea Marks T3 | 9 | CORE — no cipher item |
| 4 | Ulmia | S | 914 | Pandemonium Warden | Hunting League Rank V | 9 | CORE — no cipher item |
| 4 | Sylvie UC | S | 981 | Tumult Curator | Unity Wanted T3 capstone | 9 | CORE — no cipher item |

---

## 4. File references

| Resource | Path |
|----------|------|
| **CSV source of truth** | `exports/trust_cipher_drop_proposal.csv` |
| **By-rank review CSV** | `exports/trust_cipher_drop_by_rank.csv` |
| Drop runtime | `modules/custom/lua/trust_cipher_drops.lua` |
| Drop catalog | `modules/custom/lua/trust_cipher_drop_catalog.lua` |
| Power tiers | `modules/custom/lua/trust_power_catalog.lua` |

*Edit the main CSV, then refresh this markdown / by-rank sheet.*

