# Trust Cipher Drop Proposal â€” Dev Review Draft

**Status:** Design only Â· **Not implemented in code**  
**Last updated:** 2026-08-02  
**Related (implemented):** usable ciphers (`modules/custom/sql/trust_cipher_usable.sql`, `scripts/items/_trust_cipher.lua`)

This document is for team review before wiring NM drops. Each row proposes **one primary NM** per cipher. Adjustments welcome â€” flag rows in the CSV companion or inline comments.

### Design rule: every trust from a unique farmable NM

**No Rebirth / Prestige / Ascension trial gates.** Every trust except the 4 starters drops from a **dedicated NM kill** â€” one trust per NM, no shared drop tables. **Abyssea Marks** NMs are a first-class source (153 encounters in `abyssea_marks_catalog.lua`).

| Bucket | Count | Unlock |
|--------|------:|--------|
| **Cipher NM drops** | 81 | Use cipher item â†’ learn trust |
| **Direct spell grant** | 35 | `addSpell` on kill â€” no retail cipher item |
| **Starters** | 4 | Trion, Kupipi, Tenzen, Shantotto â€” free at creation |
| **â†’ Farmable total** | **116** | Unique NM per trust |
| **â†’ Roster total** | **120** | Includes Excenmille S variant + all starters |

**Moved off Prestige / gates (2026-08-02):** Meat, Corvus, Gemma (were Void Keeper % gates) Â· Valaineral, Uka, Chacharoon, Lhe, Robel-Akbel, Zeid II, Ingrid II (were Provenance trials) Â· Klara (was Infamy Maat fight) Â· Aldo UC (was paid Void Keeper) â€” all now Abyssea Marks or other farmable NMs.

---

## 1. System summary

| Layer | Rule |
|-------|------|
| **Starters (free)** | Trion, Kupipi, Tenzen, Shantotto â€” granted on first login; remove bulk `giveAllTrusts` from Character Upgrader |
| **Collectible pool** | **116** NM-farmable trusts + **4** starters = **120** roster entries |
| **One trust per NM** | Each `mob_groups_name` appears **once** in the CSV â€” no shared drops |
| **Drop model** | Ciphers: NM drops assigned cipher item. Direct grants: NM kill teaches spell directly |
| **Dupe protection** | If player already knows the trust: skip roll or convert to Hunt Marks / gil |
| **Collection display** | Target **116/116** farmable (+ 4 starters = 120/120 full roster) |
| **Excluded systems** | No Prestige trials, no Job Rebirth gates, no Infamy fights, no Void Keeper % gates, no paid cipher purchases |

### Drop rate bands

| Band | Example content | Drop rate |
|------|-----------------|-----------|
| **D1 â€” Entry** | HL Rank I, Reforge [I], Unity T1, Geas T1, Abyssea Marks T1 | **15%** |
| **D2 â€” Mid** | HL Rank IIâ€“III, Reforge [IIâ€“III], Unity T2, Geas T2, Abyssea Marks T2 | **13%** |
| **D3 â€” Hard** | HL Rank IV, Reforge [IV], Unity T3, Geas T3, Abyssea Marks T2â€“3 | **11%** |
| **D4 â€” Apex** | HL Rank V, Reforge [V], Geas T4, Abyssea Marks T3, Gauntlet high | **9%** |
| **D5 â€” Chase** | Shinryu (HL Rank V) | **8%** |

### Priority trusts (your short list)

| Trust | Tier | Proposed primary NM | Content | Drop % | Notes |
|-------|------|---------------------|---------|-------:|-------|
| **Monberaux** â˜… | Core | Briareus | Abyssea Marks T1 | 11% | |
| **August** â˜… | Core | Kirin | Reforge Sky [V] | 9% | |
| **Shantotto II** â˜… | Core | Absolute Virtue | HL Rank V | 9% | |
| **Sylvie UC** â˜… | Core | Tumult Curator | Unity T3 | 9% | Direct spell grant |
| **Apururu UC** â˜… | Core | Chloris | Abyssea Marks T1 | 9% | Direct spell grant |
| **Zeid II** â˜… | Core | Orthrus | Abyssea Marks T3 | 9% | Was Prestige Odin |
| **Ygnas** â˜… | Core | Isgebind | Abyssea Marks T3 | 9% | Direct spell grant |
| **Ulmia** â˜… | Core | Pandemonium Warden | HL Rank V | 9% | Direct spell grant |
| **Qultada** â˜… | Core | Glavoid | Reforge Unity [IV] | 11% | |
| **Kupofried** â˜… | Core chase | Shinryu | HL Rank V | **8%** | |
| **Joachim** â˜… | Notable | Vrtra | HL Rank III | 13% | |
| **Amchuchu** â˜… | Notable | Smok | Abyssea Marks T2 | 13% | |
| **Gessho** â˜… | Notable | Simurgh | HL Rank III | 13% | Direct spell grant |
| **Meat** | Custom | Void Keeper | GM Home | — | 50 trusts + 10M gil |
| **Corvus** | Custom | Void Keeper | GM Home | — | 40 trusts + 10M gil |
| **Gemma** | Custom | Void Keeper | GM Home | — | 60 trusts + 10M gil |

â˜… = called out in original design brief

---

## 2. Master cipher catalog (all 82)

Sort key: difficulty band â†’ content pool â†’ trust name.

| Item ID | Trust | Spell ID | Primary NM | `mob_groups.name` (internal) | Content / zone | Band | Drop % | Notes |
|--------:|-------|----------|------------|------------------------------|----------------|------|-------:|-------|
| 10118 | Naja Salaheem | 912 | Leaping Lizzy | `Leaping_Lizzy` | HL Rank I Â· Escha Zi'Tah | D1 | 15 | |
| 10115 | Mihli Aliapoh | 909 | Valkurm Emperor | `Valkurm_Emperor` | HL Rank I | D1 | 15 | |
| 10120 | Lehko Habhoka | 922 | Tom Tit Tat | `Tom_Tit_Tat` | HL Rank I | D1 | 15 | |
| 10143 | Babban | 958 | Hugemaw Harold | `Hugemaw_Harold` | Unity Wanted T1 | D1 | 15 | |
| 10158 | Halver | 972 | Keeper of Heiligtum | `Keeper_of_Heiligtum` | Unity T1 | D1 | 15 | |
| 10142 | Karaha-Baruha | 936 | Woodland Mender | `Woodland_Mender` | Unity T1 | D1 | 15 | |
| 10144 | Abenzio | 959 | Prickly Pitriv | `Prickly_Pitriv` | Unity T1 | D1 | 15 | |
| 10130 | Elivira | 941 | Abyssdiver | `Abyssdiver` | Unity T1 | D1 | 15 | |
| 10149 | Areuhat | 939 | Emperor Arthro | `Emperor_Arthro` | Unity T1 | D1 | 15 | |
| 10132 | Lhu Mhakaracca | 943 | Warblade Beak | `Warblade_Beak` | Unity T1 | D1 | 15 | |
| 10147 | Margret | 962 | Intuila | `Intuila` | Unity T1 | D1 | 15 | |
| 10146 | Kukki-Chebukki | 961 | Joyous Green | `Joyous_Green` | Unity T1 | D1 | 15 | |
| 10151 | Mayakov | 966 | Cactrot Veloz | `Cactrot_Veloz` | Unity T1 | D1 | 15 | |
| 10127 | Moogle | 931 | Genbu | `Genbu` | Reforge Sky [I] Â· Diorama | D1 | 15 | |
| 10133 | Ferreous Coffin | 944 | Bukhis | `Bukhis` | Reforge Unity [I] | D1 | 15 | |
| 10153 | Adelheid | 969 | Aello | `Aello` | Reforge Abyssea [I] | D1 | 15 | |
| 10122 | Mnejing | 926 | Wepwawet | `Wepwawet` | Geas Fete T1 Â· Escha Zi'Tah | D1 | 15 | |
| 10157 | Semih Lafihna | 940 | Warder of Faith | `Warder_of_Faith` | Geas Fete T1 | D1 | 15 | |
| 10123 | Sakura | 927 | Tangata Manu | `Tangata_Manu` | Geas Fete T1 | D1 | 15 | |
| 10121 | Ovjang | 925 | Warder of Justice | `Warder_of_Justice` | Geas Fete T1 | D1 | 15 | |
| 10139 | Rahal | 951 | Roc | `Roc` | HL Rank II | D2 | 13 | |
| 10155 | Brygid | 970 | Bomb Queen | `Bomb_Queen` | HL Rank II | D2 | 13 | |
| 10117 | Joachim | 911 | Vrtra | `Vrtra` | HL Rank III | D2 | 13 | â˜… Notable |
| 10154 | Amchuchu | 968 | Serket | `Serket` | HL Rank III | D2 | 13 | â˜… Notable |
| 10135 | Mumor | 946 | Muut | `Muut` | Unity Wanted T2 | D2 | 13 | |
| 10131 | Noillurie | 942 | Lumber Jill | `Lumber_Jill` | Unity T2 | D2 | 13 | |
| 10128 | Fablinix | 932 | Suzaku | `Suzaku` | Reforge Sky [II] | D2 | 13 | |
| 10140 | Koru-Moru | 952 | Khun | `Khun` | Reforge Unity [II] | D2 | 13 | |
| 10185 | Iroha | 997 | Iratham | `Iratham` | Reforge Abyssea [II] | D2 | 13 | |
| 10167 | Tenzen II | 1014 | Thu'ban | `Thuban` | Unity T2 gate | D2 | 13 | |
| 10116 | Valaineral | 910 | Jailer of Justice | `Jailer_of_Justice` | Prestige P20+ trial | D2 | 13 | Trial spawn, not farm loop |
| 10166 | Robel-Akbel | 977 | Diabolos | `Diabolos` | Prestige P0 trial | D2 | 13 | |
| 10174 | Ingrid II | 1016 | Medusa | `Medusa` | Prestige P0 trial | D2 | 13 | |
| 10145 | Rughadjeen | 960 | Ionos | `Ionos` | Geas Fete T2 Â· Ru'Aun | D2 | 13 | |
| 10129 | D. Shantotto | 934 | Kamohoalii | `Kamohoalii` | Geas Fete T2 | D2 | 13 | |
| 10163 | Leonoyne | 974 | Aquarius | `Aquarius` | The Gauntlet L1 | D2 | 13 | |
| 10134 | Star Sibyl | 935 | Serket | `Serket` | The Gauntlet L2 | D2 | 13 | |
| 10125 | Najelith | 929 | Simurgh | `Simurgh` | The Gauntlet L3 | D2 | 13 | Simurgh: also desired home for Gessho (no cipher) |
| 10112 | Zeid | 906 | Nidhogg | `Nidhogg` | HL Rank IV | D3 | 11 | |
| 10119 | Rainemard | 920 | King Behemoth | `King_Behemoth` | HL Rank IV | D3 | 11 | |
| 10175 | August | 984 | Kirin | `Kirin` | Reforge Sky [V] Â· Diorama | D4 | 9 | â˜… Core (primary source) |
| 10113 | Lion | 907 | Seiryu | `Seiryu` | Reforge Sky [III] | D3 | 11 | |
| 10137 | Lilisette | 945 | Padfoot | `Padfoot` | Reforge Unity [III] | D3 | 11 | |
| 10193 | Monberaux | 999 | Briareus | `Briareus` | Reforge Abyssea [III] | D3 | 11 | â˜… Core |
| 10152 | Qultada | 967 | Glavoid | `Glavoid` | Reforge Unity [IV] | D3 | 11 | â˜… Core |
| 10184 | Arciela II | 965 | Itzpapalotl | `Itzpapalotl` | Reforge Abyssea [IV] | D3 | 11 | |
| 10138 | Cid | 937 | Byakko | `Byakko` | Reforge Sky [IV] | D3 | 11 | |
| 10170 | Nashmeira II | 1012 | Specter Worm | `Specter_Worm` | Unity T3 | D3 | 11 | |
| 10171 | Lilisette II | 1013 | Bakunawa | `Bakunawa` | Unity T3 | D3 | 11 | |
| 10186 | Iroha II | 1018 | Shedu | `Shedu` | Unity T3 | D3 | 11 | |
| 10161 | Rongelouts | 973 | Fleetstalker | `Fleetstalker` | Geas Fete T3 | D3 | 11 | |
| 10176 | Rosulatia | 987 | Urmahlullu | `Urmahlullu` | Geas Fete T3 | D3 | 11 | |
| 10172 | Balamor | 979 | Pazuzu | `Pazuzu` | Geas Fete T3 | D3 | 11 | |
| 10148 | Gilgamesh | 938 | Genbu-Escha | `Genbu-Escha` | Geas Ru'Aun T3 | D3 | 11 | |
| 10124 | Luzaf | 928 | Seiryu-Escha | `Seiryu-Escha` | Geas Ru'Aun T3 | D3 | 11 | |
| 10141 | Kuyin Hathdenna | 950 | Byakko-Escha | `Byakko-Escha` | Geas Ru'Aun T3 | D3 | 11 | |
| 10126 | Aldo | 930 | Suzaku-Escha | `Suzaku-Escha` | Geas Ru'Aun T3 | D3 | 11 | |
| 10156 | Mildaurion | 971 | Kirin-Escha | `Kirin-Escha` | Geas Ru'Aun T3 | D3 | 11 | |
| 10188 | AA HM | 992 | Ark Angel HM | `Ark_Angel_HM` | Geas T3 | D3 | 11 | |
| 10191 | AA EV | 993 | Ark Angel EV | `Ark_Angel_EV` | Geas T3 | D3 | 11 | |
| 10189 | AA TT | 995 | Ark Angel TT | `Ark_Angel_TT` | Geas T3 | D3 | 11 | |
| 10190 | AA MR | 994 | Ark Angel MR | `Ark_Angel_MR` | Geas T3 | D3 | 11 | |
| 10192 | AA GK | 996 | Ark Angel GK | `Ark_Angel_GK` | Geas T3 | D3 | 11 | |
| 10164 | Maximilian | 976 | Nidhogg | `Nidhogg` | The Gauntlet L4 | D3 | 11 | |
| 10165 | Kayeel-Payeel | 975 | King Behemoth | `King_Behemoth` | The Gauntlet L5 | D3 | 11 | |
| 10178 | Ullegore | 989 | Vrtra | `Vrtra` | The Gauntlet L6 | D3 | 11 | |
| 10177 | Mumor II | 1015 | Kirin | `Kirin` | The Gauntlet L7 | D3 | 11 | |
| 10187 | Shantotto II | 1019 | Absolute Virtue | `Absolute_Virtue` | HL Rank V | D4 | 9 | â˜… Core |
| 10160 | Zeid II | 1010 | Odin | `Odin` | Prestige trial | D4 | 9 | â˜… Core |
| 10159 | Lion II | 1009 | Tinnin | `Tinnin` | Reforge Unity [V] | D4 | 9 | |
| 10179 | Teodor | 986 | Hadhayosh | `Hadhayosh` | Reforge Abyssea [V] | D4 | 9 | Pair w/ Apururu UC direct grant? |
| 10168 | Prishe II | 1011 | Tumult Curator | `Tumult_Curator` | Unity T3 capstone | D4 | 9 | Pair w/ Sylvie UC direct grant? |
| 10173 | Selh'Teus | 978 | Albumen | `Albumen` | Geas Fete T4 | D4 | 9 | |
| 10169 | Abquhbah | 982 | Teles | `Teles` | Geas Fete T4 | D4 | 9 | |
| 10180 | Makki-Chebukki | 988 | Warder of Courage | `Warder_of_Courage` | Geas T4 | D4 | 9 | |
| 10181 | King of Hearts | 990 | Maju | `Maju` | Geas T4 | D4 | 9 | |
| 10182 | Morimar | 991 | Warder of Hope | `Warder_of_Hope` | Geas T4 | D4 | 9 | |
| 10183 | Darrcuiln | 993 | Azi Dahaka | `Azi_Dahaka` | Geas T4 | D4 | 9 | Pair w/ Ygnas direct grant? |
| 10162 | Kupofried | 973 | Shinryu | `Shinryu` | HL Rank V | D5 | 8 | â˜… Core chase |
| 10150 | Lhe Lhangavo | 964 | Sarameya | `Sarameya` | Prestige P10+ | D4 | 9 | |
| 10136 | Uka Totlihn | 947 | Omega | `Omega` | Prestige P30+ | D4 | 9 | |
| 10114 | Tenzen | 908 | *(none)* | *(none)* | Starter grant | â€” | â€” | Free at creation â€” do not drop |

**81 farmable cipher drops + 1 starter (Tenzen) = 82 total ciphers.** HL Rank IV Kirin intentionally has no cipher (August is Reforge Sky [V] only).

---

## 3. By content pool (quick reference)

### Hunting League â€” 15 NMs Â· Escha Zi'Tah

| NM | Rank | Cipher / trust | Drop % |
|----|------|----------------|-------:|
| Leaping Lizzy | I | Naja | 15 |
| Valkurm Emperor | I | Mihli Aliapoh | 15 |
| Tom Tit Tat | I | Lehko Habhoka | 15 |
| Roc | II | Rahal | 13 |
| Bomb Queen | II | Brygid | 13 |
| Serket | III | Amchuchu | 13 |
| Vrtra | III | Joachim | 13 |
| Simurgh | III | *(Gessho — no cipher)* | — |
| Nidhogg | IV | Zeid | 11 |
| King Behemoth | IV | Rainemard | 11 |
| Kirin | IV | *(no cipher — August is Reforge Sky [V])* | — |
| Absolute Virtue | V | Shantotto II | 9 |
| Pandemonium Warden | V | *(Ulmia — no cipher)* | — |
| Shinryu | V | Kupofried | 8 |

### Reforge Arena â€” 15 NMs Â· Diorama Abdhaljs-Ghelsba

| NM | Slot | Cipher / trust | Drop % |
|----|------|----------------|-------:|
| Genbu | AF [I] | Moogle | 15 |
| Suzaku | AF [II] | Fablinix | 13 |
| Seiryu | AF [III] | Lion | 11 |
| Byakko | AF [IV] | Cid | 11 |
| Kirin | AF [V] | August ★ | 9 |
| Bukhis | Relic [I] | Ferreous Coffin | 15 |
| Khun | Relic [II] | Koru-Moru | 13 |
| Padfoot | Relic [III] | Lilisette | 11 |
| Glavoid | Relic [IV] | Qultada ★ | 11 |
| Tinnin | Relic [V] | Lion II | 9 |
| Aello | Empy [I] | Adelheid | 15 |
| Iratham | Empy [II] | Iroha | 13 |
| Briareus | Empy [III] | Monberaux ★ | 11 |
| Itzpapalotl | Empy [IV] | Arciela II | 11 |
| Hadhayosh | Empy [V] | Teodor / Apururu UC? | 9 |

### Unity Wanted â€” 20 mapped (of 56) Â· Escha Zi'Tah

See master table for T1/T2/T3 assignments. Remaining Unity NMs can share a **rotating filler pool** (11% each) for lower-priority ciphers: e.g. Iron Eater proxy â†’ assign **Ovjang** elsewhere, **Kuyin**, **Lhe**, etc.

### Geas Fete â€” sample Â· Escha Zi'Tah / Ru'Aun / Reisenjima

T1 Warders + Wepwawet Â· T2 Ionos/Kamohoalii Â· T3 Ark Angels + Escha beasts Â· T4 Azi Dahaka / Albumen / Teles / Warders

### Abyssea Marks Â· marks-popped NMs (primary rebalance pool)

**35 trusts** now source from Abyssea Marks (`modules/custom/lua/abyssea_marks_catalog.lua`). Each uses a **unique** marks NM â€” no overlap with Prestige Provenance spawns.

| Trust | NM | Abyssea tier |
|-------|-----|--------------|
| Naji | Arimaspi | T1 Visions |
| Cherukiki | Bloodguzzler | T1 Visions |
| Apururu UC â˜… | Chloris | T1 Visions |
| Arciela | Eccentric Eve | T1 Visions |
| Najelith | Carabosse | T1 Visions |
| Lhe Lhangavo | Kukulkan | T1 Visions |
| Monberaux â˜… | Briareus | T1 Visions |
| Excenmille S | Toppling Tuber | T1 Visions |
| Volker | Maahes | T2 Scars |
| Prishe | Sirrush | T2 Scars |
| Iron Eater | Blazing Eruca | T2 Scars |
| Klara | Lord Varney | T2 Scars |
| Amchuchu â˜… | Smok | T2 Scars |
| Maximilian | Dvalinn | T2 Scars |
| Kayeel-Payeel | Ketea | T2 Scars |
| Robel-Akbel | Durinn | T2 Scars |
| Teodor | Titlacauan | T2 Scars |
| Ullegore | Iku-Turso | T2 Scars |
| Arciela II | Itzpapalotl | T2 Scars |
| Chacharoon | Azdaja | T3 Heroes |
| Valaineral | Alfard | T3 Heroes |
| Uka Totlihn | Pantokrator | T3 Heroes |
| Zeid II â˜… | Orthrus | T3 Heroes |
| Prishe II | Lorelei | T3 Heroes |
| Mumor II | Bennu | T3 Heroes |
| Ingrid II | Shaula | T3 Heroes |
| Maat UC | Amarok | T3 Heroes |
| Aldo UC | Ningishzida | T3 Heroes |
| Ygnas | Isgebind | T3 Heroes |

### The Gauntlet Â· Riverne (subset)

Leonoyne (L1), Star Sibyl (L2) â€” remaining Gauntlet slots freed by moving overlapping trusts to Abyssea.

---

## 4. Custom trusts (Meat / Corvus / Gemma / Cornelia / Matsui-P)

**Void Keeper only** — collection progress + gil. Not NM drops.

| Trust | Spell | Unlock | Cost |
|-------|------:|--------|------|
| **Corvus** | 902 | 40 trusts collected | 10M gil |
| **Meat** | 899 | 50 trusts collected | 10M gil |
| **Gemma** | 901 | 60 trusts collected | 10M gil |
| **Cornelia** | 1002 | All 120 roster trusts | 50M gil |
| **Matsui-P** | 1003 | All 120 roster trusts | 50M gil |

---

## 5. Trusts with **no retail cipher item** (direct spell grant)

These **35 trusts** use **`addSpell` on NM kill** at the rate in the CSV. See the Abyssea table in Â§3 for the marks-sourced subset.

| Trust | Spell | Primary NM | Pool |
|-------|------:|------------|------|
| Naji | 897 | Arimaspi | Abyssea Marks T1 |
| Ayame | 900 | Jester Malatrix | Unity T1 |
| Volker | 903 | Maahes | Abyssea Marks T2 |
| Ajido-Marujido | 904 | Immanibugard | Unity T1 |
| Prishe | 913 | Sirrush | Abyssea Marks T2 |
| **Ulmia** â˜… | 914 | Pandemonium Warden | HL Rank V |
| Shikaree Z | 915 | Largantua | Unity T2 |
| Cherukiki | 916 | Bloodguzzler | Abyssea Marks T1 |
| Iron Eater | 917 | Blazing Eruca | Abyssea Marks T2 |
| **Gessho** â˜… | 918 | Simurgh | HL Rank III |
| Gadalar | 919 | Garbage Gel | Unity T2 |
| Ingrid | 921 | Strix | Unity T2 |
| Nashmeira | 923 | Arke | Unity T2 |
| Zazarg | 924 | Tiyanak | Unity T1 |
| Maat | 933 | Sovereign Behemoth | Unity T2 |
| Klara | 948 | Lord Varney | Abyssea Marks T2 |
| Romaa Mihgo | 949 | Ironhorn Baldurno | Unity T1 |
| Pieuje UC | 953 | Centurio XX-I | Unity T3 |
| Invincible Shield UC | 954 | Vidmapire | Unity T3 |
| **Apururu UC** â˜… | 955 | Chloris | Abyssea Marks T1 |
| Jakoh UC | 956 | Tolba | Unity T3 |
| Flaviria UC | 957 | Mephitas | Unity T3 |
| Chacharoon | 963 | Azdaja | Abyssea Marks T3 |
| Arciela | 965 | Eccentric Eve | Abyssea Marks T1 |
| Yoran-Oran UC | 980 | Coca | Unity T3 |
| **Sylvie UC** â˜… | 981 | Tumult Curator | Unity T3 |
| **Ygnas** â˜… | 998 | Isgebind | Abyssea Marks T3 |
| Excenmille S | 1004 | Toppling Tuber | Abyssea Marks T1 |
| Ayame UC | 1005 | Wyvernhunter Bambrox | Unity T3 |
| Maat UC | 1006 | Amarok | Abyssea Marks T3 |
| Aldo UC | 1007 | Ningishzida | Abyssea Marks T3 |
| Naja UC | 1008 | Ayapec | Unity T3 |

â˜… = priority trusts from original design brief

---

## 6. Open decisions for dev review

1. **Abyssea drop wiring** â€” hook `AbysseaMarks.lua` `onMobDeath` alongside HL / Unity / Geas / Reforge / Gauntlet
2. **Dupe conversion** â€” Hunt Marks vs gil vs skip silently?
3. **Collection UI** â€” `!trusts` or Void Keeper board showing X/116 farmable (+ starters)
4. **Tenzen cipher (10114)** â€” starter Tenzen is free; drop table should exclude 10114 everywhere
5. **Excenmille S** â€” count toward 120/120 or optional side collect?

---

## 7. Implementation checklist (after approval)

- [ ] `trust_cipher_drops.lua` catalog (spell/cipherId â†’ mob name â†’ rate â†’ grant type)
- [ ] Hook HL / Reforge / Unity / Geas / **Abyssea Marks** / Gauntlet `onMobDeath` paths
- [ ] Dupe protection + optional conversion
- [ ] Character Upgrader â†’ 4 starters only
- [ ] Remove Void Keeper % gates for Corvus / Meat / Gemma (if still in `trust_skoll.lua`)
- [ ] Apply `trust_cipher_usable.sql` if not already on live DB
- [ ] Player-facing `!trusts` or board showing X/82

---

## 8. File references

| Resource | Path |
|----------|------|
| Cipher item names (82) | `modules/custom/lua/trust_cipher_catalog.lua` |
| Usable cipher wiring | `modules/custom/lua/trust_cipher_usable.lua` |
| Item IDs | `scripts/enum/item.lua` (10112â€“10193) |
| HL catalog | `modules/custom/lua/hunting_league_catalog.lua` |
| Reforge catalog | `modules/custom/lua/reforge_catalog.lua` |
| Unity catalog | `modules/custom/lua/unity_wanted_catalog.lua` |
| Geas catalog | `modules/custom/lua/Geas_Fete.lua` |
| Abyssea Marks catalog | `modules/custom/lua/abyssea_marks_catalog.lua` |
| Abyssea Marks runtime | `modules/custom/lua/AbysseaMarks.lua` |
| Gauntlet catalog | `modules/custom/lua/gauntlet_catalog.lua` |
| CSV companion (full roster) | `exports/trust_cipher_drop_proposal.csv` (**120 trusts**, sorted by spell ID) |

---

*End of draft â€” please annotate changes and return for implementation pass.*
