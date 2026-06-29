# Player Commands

These chat commands are available to every player on Legendary (no GM rank required). Type them in any chat channel with the `!` prefix.

**Total player-accessible commands:** 82

!!! info "Who can use these"
    Every command listed here is available to all players. Some other commands exist but are reserved for GMs; those aren't shown.

!!! note "Custom commands"
    56 of the commands below are **unique to Legendary** and won't be found on a standard FFXI server. They're tagged **:material-puzzle: custom** in the table and their detail section, and every player can use them.

## Quick reference

| Command | Parameters | Description | Custom? |
|---|---|---|---|
| `!abyssea` | — | _(no description)_ | :material-puzzle: **custom** |
| `!achievements` | — | Shows all personal milestone achievements - earned and unearned - with their reward amounts and descriptions. | :material-puzzle: **custom** |
| `!affinitynm` | string | _(no description)_ | :material-puzzle: **custom** |
| `!affinitypop` | — | _(no description)_ | :material-puzzle: **custom** |
| `!ah` | — | opens the Auction House menu anywhere in the world |  |
| `!ambuscade` | string | _(no description)_ | :material-puzzle: **custom** |
| `!aoews` | string | Permanently binds a weapon skill as your AoE WS. Requires the AoE unlock from the Rupture Sage (Leafallia, !leaf). Cannot be changed after setting. |  |
| `!apex` | string | Apex Trials helper -- check your record / Paragon Points, start a climb, or bail out of one. | :material-puzzle: **custom** |
| `!augstats` | — | Shows the true augment contributions on your equipped gear. |  |
| `!augwarp` | string | Warp to a zone that drops a catalyst for a given augment stat. Usage: !augwarp <stat or catalyst name> (e.g. !augwarp Haste). | :material-puzzle: **custom** |
| `!autojp` | string | Auto-spends all unspent job points on whichever categories of the player's CURRENT MAIN JOB can still be upgraded, distributing breadth-first so every category grows evenly. | :material-puzzle: **custom** |
| `!automerits` | string | Auto-spends all unspent merit points on whichever categories can still be upgraded, distributing breadth-first so every category grows evenly rather than one rank stack getting maxed first. | :material-puzzle: **custom** |
| `!buff` | string | Grants the zone-appropriate regional buff (Signet / Sanction / Sigil / Ionis) plus Refresh, Regen, Regain, and Composure to the player. Refresh = 10% of max MP per tick Regen   = 10% of max HP per tick Regain  = scales with player level (1 per 10 levels, min 1) |  |
| `!checkexpbonus` | — | Prints your current EXP_BONUS mod (gear/augments that boost EXP gain) and the per-kill effect it has. Useful for verifying that an EXP augment is actually attached to the player after equipping the piece. |  |
| `!dig` | — | Treasure Hunting - dig for the strongbox your treasure map points at. Maps drop from Hunting League kills. | :material-puzzle: **custom** |
| `!empower` | string, string | View your Spell & Skill Mastery -- Mastery Sigil balance, weapon-skill and spell potency tiers, and owned trait riders. Upgrades are bought at the Mastery Sage NPC in Leafallia (see SpellSkillMastery.lua). | :material-puzzle: **custom** |
| `!events` | — | Lists upcoming and active seasonal bonus mark events from the catalog.  Shows event name, multiplier, start/end dates, and status (active / upcoming / expired). | :material-puzzle: **custom** |
| `!expcamp` | string | _(no description)_ | :material-puzzle: **custom** |
| `!featured` | — | Shows which NM is the Weekly Featured Hunt for each Hunting League tier.  Featured NMs award 2x base marks on the first kill of the week - the bonus stacks with the First-Kill bonus. | :material-puzzle: **custom** |
| `!fellow` | string, int | Opens the Adventuring Fellow menu (summon/dismiss, allocate stat points, choose role, view status). Your Fellow is a personal companion ANY job can summon; it levels from your kills and you build it as you like. | :material-puzzle: **custom** |
| `!fellowstats` | — | Dumps live mod values straight off the spawned Fellow pet. Fellow must be summoned. Spend a point, re-run, watch the number move. | :material-puzzle: **custom** |
| `!gauntlet` | string | _(no description)_ |  |
| `!getstats` | string | prints stats of cursor target into chatlog, for debugging. |  |
| `!gmhome` | — | Sends you to zone 210 (GM_HOME), if you are a GM |  |
| `!help` | — | Lists all custom commands with a one-line description. | :material-puzzle: **custom** |
| `!henge` | — | _(no description)_ | :material-puzzle: **custom** |
| `!home` | string | Sends the target to their homepoint. |  |
| `!hovershot` | — | _(no description)_ | :material-puzzle: **custom** |
| `!hunt` | — | Warps you to the Hunting League hub in Escha - Zi'Tah. The hub has three NPCs in a row: Seals (leftmost)  — tier info, rank-up, seal shop Zone Guide        — one-click teleport to any tier cluster area Accessories       — neck / earring / ring / back / waist shop From the Zone Guide, pick your tier to warp straight to that cluster's spawner NPC without crossing the zone on foot. Landing spot stays in sync with sealsPos in hunting_league_catalog. |  |
| `!hunt1` | — | Warps you to the Tier 1 (Rank I - Initiate) hunt spawner in Escha - Zi'Tah. NMs: Leaping Lizzy, Valkurm Emperor, Tom Tit Tat. |  |
| `!hunt2` | — | Warps you to the Tier 2 (Rank II - Hunter) hunt spawner in Escha - Zi'Tah. NMs: Roc, Bomb Queen, Aquarius. |  |
| `!hunt3` | — | Warps you to the Tier 3 (Rank III - Elite) hunt spawner in Escha - Zi'Tah. NMs: Serket, Vrtra, Simurgh. |  |
| `!hunt4` | — | Warps you to the Tier 4 (Rank IV - Champion) hunt spawner in Escha - Zi'Tah. NMs: Nidhogg, King Behemoth, Kirin. |  |
| `!hunt5` | — | Warps you to the Tier 5 (Rank V - Legend) hunt spawner in Escha - Zi'Tah. NMs: Absolute Virtue, Pandemonium Warden, Shinryu. |  |
| `!huntrank` | string | Displays the player's Hunter's Guild status across all four guilds — current rank, rep, amplifier %, and progress to the next rank. Also shows Trinity / Apex capstone status, and the v2 Vana'diel hunt-target list per guild so the player knows what to go kill. |  |
| `!iwarp` | — | _(no description)_ | :material-puzzle: **custom** |
| `!leaf` | — | _(no description)_ | :material-puzzle: **custom** |
| `!lfg` | string | Broadcasts a Looking-For-Group announcement server-wide so other players know you're looking for someone to play with. | :material-puzzle: **custom** |
| `!lib` | — | _(no description)_ | :material-puzzle: **custom** |
| `!maat` | — | _(no description)_ | :material-puzzle: **custom** |
| `!marks` | — | Quick Hunt Marks balance - current spendable balance plus an at-a-glance kill-streak summary. | :material-puzzle: **custom** |
| `!mastery` | string, string, string | _(no description)_ | :material-puzzle: **custom** |
| `!mobs` | string | Lists the LIVE (spawned, HP > 0) mobs in your current zone, nearest first, with HP%, rough distance, and (X, Y, Z) world position (same coords as !pos / Windower). Optional name filter: !mobs            -> everything alive nearby !mobs lizard     -> only names containing "lizard" | :material-puzzle: **custom** |
| `!mobstats` | — | _(no description)_ |  |
| `!mystats` | — | Self-targeted dump of EVERY stat the player has, with equipment and buff contributions baked into the totals. Single command, no arguments, no cursor-target needed. | :material-puzzle: **custom** |
| `!nms` | — | Shows the player's NM Encyclopedia progress - which Hunting League NMs they have killed at least once, and which ones remain.  Lists up to 10 missing NMs to avoid flooding chat. | :material-puzzle: **custom** |
| `!offhand` | string | _(no description)_ | :material-puzzle: **custom** |
| `!optin` | — | Opts the player INTO leaderboards and Discord tracking. This is the default state for new characters. | :material-puzzle: **custom** |
| `!optout` | — | Opts the player OUT of leaderboards and Discord tracking. This character is excluded from every leaderboard entirely. | :material-puzzle: **custom** |
| `!pos` | string | Sets the players position. If none is given, prints out the position instead. |  |
| `!primevoucher` | string, int | [GM] Grant Prime Voucher(s) (the Maze Monger Crown, item 3038) to a player. They trade one at the Prime Armory NPC in Leafallia (!leaf) to claim a Prime weapon of their choice. The voucher is EX (bound), so a GM cannot trade it over by hand -- this command is how you grant it. | :material-puzzle: **custom** |
| `!profile` | string | Displays a competitive stat summary for a player.  With no argument shows your own stats; with a name shows that player's (they must be online - offline players can't be queried via Lua). | :material-puzzle: **custom** |
| `!progress` | string | Prints a cross-system progression summary: Hunting League rank, Hunt Marks, Reforge Marks, weekly-hunt completion, Hunter's Guild standings, and Daily Board - all in one quick readout. | :material-puzzle: **custom** |
| `!prov1` | — | _(no description)_ | :material-puzzle: **custom** |
| `!prov2` | — | _(no description)_ | :material-puzzle: **custom** |
| `!prov3` | — | _(no description)_ | :material-puzzle: **custom** |
| `!provenance` | — | Overrides scripts/commands/provenance.lua to DISABLE the !provenance warp. Lives in modules/custom/commands/ so it HOT-RELOADS (no restart) and takes precedence over the stock command (same pattern as !shop). The stock command (warp to zone 222) is left intact; this just shadows it. | :material-puzzle: **custom** |
| `!pup` | string, string | Puppetmaster automaton quick-loadout manager. Save the full setup (frame + head + all 12 attachments) of your deployed automaton to a named slot, then swap to it instantly from anywhere -- no Automaton Trunk trip, no menu drag-and-drop. | :material-puzzle: **custom** |
| `!reallevel` | string | Computes a player's "real level" -- a single fun number that reflects how far PAST the level-99 cap a character has actually progressed, by folding in every endgame power axis FFXI offers: gear (item level), Ascension (Prestige), Job Points, and merits. | :material-puzzle: **custom** |
| `!rebirth` | — | _(no description)_ |  |
| `!reforge` | — | Shows the player's Reforge AF, Relic, and Empy mark balances. | :material-puzzle: **custom** |
| `!reforged` | — | Warps you to the Reforge Armor system NPCs in Gwora-Corridor. |  |
| `!release` | string | Releases the player from current events. |  |
| `!releaseme` | string, string | Force-clears stuck event / NPC-sequence state on a player. |  |
| `!shop` | string, string | _(no description)_ | :material-puzzle: **custom** |
| `!streak` | — | Shows the current kill streak count, active bonus tier, and seconds remaining in the 5-minute window before reset. | :material-puzzle: **custom** |
| `!tier` | — | Shows the player's current Hunting League tier, the NMs available at that tier, and exactly what is needed to unlock the next rank. | :material-puzzle: **custom** |
| `!time` | — | Shows server time (UTC), hours until daily reset, days until weekly reset (Monday 00:00 UTC), and any active seasonal event. | :material-puzzle: **custom** |
| `!top` | string | Shows the top 5 currently online players ranked by a stat. Opted-out players are excluded.  For full server-wide rankings see the website at legendary-ffxi.pages.dev | :material-puzzle: **custom** |
| `!tournament` | string, string, string | Legendary Tournament — last-person-standing PvE wave event. | :material-puzzle: **custom** |
| `!tower` | string, string | _(no description)_ | :material-puzzle: **custom** |
| `!trustattack` | — | Run once to turn ON: while on, you AUTO-ENGAGE whatever mob you have targeted (cursor target), so you and your trusts attack it hands-free -- point at the next mob and you all switch to it. Run again to turn OFF. Macro:  /console !trustattack | :material-puzzle: **custom** |
| `!unstick` | — | Self-rescue from stuck event/sequence state. |  |
| `!visitant` | — | _(no description)_ | :material-puzzle: **custom** |
| `!voidwatch` | string, int | Voidwatch-flavored rift battles. Open the menu, or tear a rift in the field. | :material-puzzle: **custom** |
| `!warpty` | — | _(no description)_ |  |
| `!wavemaster` | — | Warps you to Escha - Ru'Aun where the Wave Master NPC is located. The Wave Master runs themed enemy wave fights (Easy -> Nightmare) that reward Hunt Marks on full clear. | :material-puzzle: **custom** |
| `!waypoint` | string, string | Personal, per-character warp points. Each player can save up to 10 positions (slots 1-10) wherever they stand and warp back later. Slots are overwritable -- saving over a slot just replaces it. | :material-puzzle: **custom** |
| `!week` | — | Shows the player's current weekly objectives at a glance: Weekly Hunt Board progress and featured NMs killed. Resets each Monday 00:00 UTC. | :material-puzzle: **custom** |
| `!weekly` | — | Displays the player's current Weekly Hunt Board progress — the 5 rolled objectives, per-objective progress, and the lifetime "Weekly Hunter" sweep counter. |  |
| `!who` | — | Lists players who have logged in during this server session, sorted by Hunting League tier (highest first), with their tier name shown.  Stale entries (crashed clients) are pruned lazily via GetPlayerByName at query time. | :material-puzzle: **custom** |
| `!zone` | bool/raw | Teleports a player to the given zone. |  |

## Movement & Teleport

### `!gmhome`

Sends you to zone 210 (GM_HOME), if you are a GM

**Usage:** `gmhome`

### `!home`

Sends the target to their homepoint.

**Usage:** `homepoint`

**Parameter types:** string

### `!pos`

Sets the players position. If none is given, prints out the position instead.

**Usage:** `pos <x> <y> <z> <optional zone> <optional target>`

**Parameter types:** string

### `!zone`

Teleports a player to the given zone.

**Usage:** `zone`

**Parameter types:** bool/raw

## Items & Inventory

### `!ah`

opens the Auction House menu anywhere in the world

**Usage:** `ah`

### `!shop`  _(custom)_

**Usage:** `shop`

**Parameter types:** string, string

## Buffs & Power

### `!autojp`  _(custom)_

Auto-spends all unspent job points on whichever categories of the player's CURRENT MAIN JOB can still be upgraded, distributing breadth-first so every category grows evenly.

**Usage:** `autojp <player>`

**Parameter types:** string

### `!automerits`  _(custom)_

Auto-spends all unspent merit points on whichever categories can still be upgraded, distributing breadth-first so every category grows evenly rather than one rank stack getting maxed first.

**Usage:** `automerits <player>`

**Parameter types:** string

### `!buff`

Grants the zone-appropriate regional buff (Signet / Sanction / Sigil / Ionis) plus Refresh, Regen, Regain, and Composure to the player. Refresh = 10% of max MP per tick Regen   = 10% of max HP per tick Regain  = scales with player level (1 per 10 levels, min 1)

**Usage:** `buff`

**Parameter types:** string

## Information & Debug

### `!getstats`

prints stats of cursor target into chatlog, for debugging.

**Usage:** `getstats`

**Parameter types:** string

### `!mystats`  _(custom)_

Self-targeted dump of EVERY stat the player has, with equipment and buff contributions baked into the totals. Single command, no arguments, no cursor-target needed.

**Usage:** `mystats`

## Misc

### `!abyssea`  _(custom)_

**Usage:** `abyssea`

### `!achievements`  _(custom)_

Shows all personal milestone achievements - earned and unearned - with their reward amounts and descriptions.

**Usage:** `achievements`

### `!affinitynm`  _(custom)_

**Usage:** `affinitynm`

**Parameter types:** string

### `!affinitypop`  _(custom)_

**Usage:** `affinitypop`

### `!ambuscade`  _(custom)_

**Usage:** `ambuscade`

**Parameter types:** string

### `!aoews`

Permanently binds a weapon skill as your AoE WS. Requires the AoE unlock from the Rupture Sage (Leafallia, !leaf). Cannot be changed after setting.

**Usage:** `aoews`

**Parameter types:** string

### `!apex`  _(custom)_

Apex Trials helper -- check your record / Paragon Points, start a climb, or bail out of one.

**Usage:** `apex`

**Parameter types:** string

### `!augstats`

Shows the true augment contributions on your equipped gear.

**Usage:** `augstats`

### `!augwarp`  _(custom)_

Warp to a zone that drops a catalyst for a given augment stat. Usage: !augwarp <stat or catalyst name> (e.g. !augwarp Haste).

**Usage:** `augwarp`

**Parameter types:** string

### `!checkexpbonus`

Prints your current EXP_BONUS mod (gear/augments that boost EXP gain) and the per-kill effect it has. Useful for verifying that an EXP augment is actually attached to the player after equipping the piece.

**Usage:** `checkexpbonus`

### `!dig`  _(custom)_

Treasure Hunting - dig for the strongbox your treasure map points at. Maps drop from Hunting League kills.

**Usage:** `dig`

### `!empower`  _(custom)_

View your Spell & Skill Mastery -- Mastery Sigil balance, weapon-skill and spell potency tiers, and owned trait riders. Upgrades are bought at the Mastery Sage NPC in Leafallia (see SpellSkillMastery.lua).

**Usage:** `empower`

**Parameter types:** string, string

### `!events`  _(custom)_

Lists upcoming and active seasonal bonus mark events from the catalog.  Shows event name, multiplier, start/end dates, and status (active / upcoming / expired).

**Usage:** `events`

### `!expcamp`  _(custom)_

**Usage:** `expcamp`

**Parameter types:** string

### `!featured`  _(custom)_

Shows which NM is the Weekly Featured Hunt for each Hunting League tier.  Featured NMs award 2x base marks on the first kill of the week - the bonus stacks with the First-Kill bonus.

**Usage:** `featured`

### `!fellow`  _(custom)_

Opens the Adventuring Fellow menu (summon/dismiss, allocate stat points, choose role, view status). Your Fellow is a personal companion ANY job can summon; it levels from your kills and you build it as you like.

**Usage:** `fellow`

**Parameter types:** string, int

### `!fellowstats`  _(custom)_

Dumps live mod values straight off the spawned Fellow pet. Fellow must be summoned. Spend a point, re-run, watch the number move.

**Usage:** `fellowstats`

### `!gauntlet`

**Usage:** `gauntlet`

**Parameter types:** string

### `!help`  _(custom)_

Lists all custom commands with a one-line description.

**Usage:** `help`

### `!henge`  _(custom)_

**Usage:** `henge`

### `!hovershot`  _(custom)_

**Usage:** `hovershot`

### `!hunt`

Warps you to the Hunting League hub in Escha - Zi'Tah. The hub has three NPCs in a row: Seals (leftmost)  — tier info, rank-up, seal shop Zone Guide        — one-click teleport to any tier cluster area Accessories       — neck / earring / ring / back / waist shop From the Zone Guide, pick your tier to warp straight to that cluster's spawner NPC without crossing the zone on foot. Landing spot stays in sync with sealsPos in hunting_league_catalog.

**Usage:** `hunt`

### `!hunt1`

Warps you to the Tier 1 (Rank I - Initiate) hunt spawner in Escha - Zi'Tah. NMs: Leaping Lizzy, Valkurm Emperor, Tom Tit Tat.

**Usage:** `hunt1`

### `!hunt2`

Warps you to the Tier 2 (Rank II - Hunter) hunt spawner in Escha - Zi'Tah. NMs: Roc, Bomb Queen, Aquarius.

**Usage:** `hunt2`

### `!hunt3`

Warps you to the Tier 3 (Rank III - Elite) hunt spawner in Escha - Zi'Tah. NMs: Serket, Vrtra, Simurgh.

**Usage:** `hunt3`

### `!hunt4`

Warps you to the Tier 4 (Rank IV - Champion) hunt spawner in Escha - Zi'Tah. NMs: Nidhogg, King Behemoth, Kirin.

**Usage:** `hunt4`

### `!hunt5`

Warps you to the Tier 5 (Rank V - Legend) hunt spawner in Escha - Zi'Tah. NMs: Absolute Virtue, Pandemonium Warden, Shinryu.

**Usage:** `hunt5`

### `!huntrank`

Displays the player's Hunter's Guild status across all four guilds — current rank, rep, amplifier %, and progress to the next rank. Also shows Trinity / Apex capstone status, and the v2 Vana'diel hunt-target list per guild so the player knows what to go kill.

**Usage:** `huntrank`

**Parameter types:** string

### `!iwarp`  _(custom)_

**Usage:** `iwarp`

### `!leaf`  _(custom)_

**Usage:** `leaf`

### `!lfg`  _(custom)_

Broadcasts a Looking-For-Group announcement server-wide so other players know you're looking for someone to play with.

**Usage:** `lfg`

**Parameter types:** string

### `!lib`  _(custom)_

**Usage:** `lib`

### `!maat`  _(custom)_

**Usage:** `maat`

### `!marks`  _(custom)_

Quick Hunt Marks balance - current spendable balance plus an at-a-glance kill-streak summary.

**Usage:** `marks`

### `!mastery`  _(custom)_

**Usage:** `mastery`

**Parameter types:** string, string, string

### `!mobs`  _(custom)_

Lists the LIVE (spawned, HP > 0) mobs in your current zone, nearest first, with HP%, rough distance, and (X, Y, Z) world position (same coords as !pos / Windower). Optional name filter: !mobs            -> everything alive nearby !mobs lizard     -> only names containing "lizard"

**Usage:** `mobs`

**Parameter types:** string

### `!mobstats`

**Usage:** `mobstats`

### `!nms`  _(custom)_

Shows the player's NM Encyclopedia progress - which Hunting League NMs they have killed at least once, and which ones remain.  Lists up to 10 missing NMs to avoid flooding chat.

**Usage:** `nms`

### `!offhand`  _(custom)_

**Usage:** `offhand`

**Parameter types:** string

### `!optin`  _(custom)_

Opts the player INTO leaderboards and Discord tracking. This is the default state for new characters.

**Usage:** `optin`

### `!optout`  _(custom)_

Opts the player OUT of leaderboards and Discord tracking. This character is excluded from every leaderboard entirely.

**Usage:** `optout`

### `!primevoucher`  _(custom)_

[GM] Grant Prime Voucher(s) (the Maze Monger Crown, item 3038) to a player. They trade one at the Prime Armory NPC in Leafallia (!leaf) to claim a Prime weapon of their choice. The voucher is EX (bound), so a GM cannot trade it over by hand -- this command is how you grant it.

**Usage:** `primevoucher`

**Parameter types:** string, int

### `!profile`  _(custom)_

Displays a competitive stat summary for a player.  With no argument shows your own stats; with a name shows that player's (they must be online - offline players can't be queried via Lua).

**Usage:** `profile`

**Parameter types:** string

### `!progress`  _(custom)_

Prints a cross-system progression summary: Hunting League rank, Hunt Marks, Reforge Marks, weekly-hunt completion, Hunter's Guild standings, and Daily Board - all in one quick readout.

**Usage:** `progress`

**Parameter types:** string

### `!prov1`  _(custom)_

**Usage:** `prov1`

### `!prov2`  _(custom)_

**Usage:** `prov2`

### `!prov3`  _(custom)_

**Usage:** `prov3`

### `!provenance`  _(custom)_

Overrides scripts/commands/provenance.lua to DISABLE the !provenance warp. Lives in modules/custom/commands/ so it HOT-RELOADS (no restart) and takes precedence over the stock command (same pattern as !shop). The stock command (warp to zone 222) is left intact; this just shadows it.

**Usage:** `provenance  (DISABLED)`

### `!pup`  _(custom)_

Puppetmaster automaton quick-loadout manager. Save the full setup (frame + head + all 12 attachments) of your deployed automaton to a named slot, then swap to it instantly from anywhere -- no Automaton Trunk trip, no menu drag-and-drop.

**Usage:** `pup`

**Parameter types:** string, string

### `!reallevel`  _(custom)_

Computes a player's "real level" -- a single fun number that reflects how far PAST the level-99 cap a character has actually progressed, by folding in every endgame power axis FFXI offers: gear (item level), Ascension (Prestige), Job Points, and merits.

**Usage:** `reallevel`

**Parameter types:** string

### `!rebirth`

**Usage:** `rebirth`

### `!reforge`  _(custom)_

Shows the player's Reforge AF, Relic, and Empy mark balances.

**Usage:** `reforge`

### `!reforged`

Warps you to the Reforge Armor system NPCs in Gwora-Corridor.

**Usage:** `reforged`

### `!release`

Releases the player from current events.

**Usage:** `release`

**Parameter types:** string

### `!releaseme`

Force-clears stuck event / NPC-sequence state on a player.

**Usage:** `releaseme [target] [mode]`

**Parameter types:** string, string

### `!streak`  _(custom)_

Shows the current kill streak count, active bonus tier, and seconds remaining in the 5-minute window before reset.

**Usage:** `streak`

### `!tier`  _(custom)_

Shows the player's current Hunting League tier, the NMs available at that tier, and exactly what is needed to unlock the next rank.

**Usage:** `tier`

### `!time`  _(custom)_

Shows server time (UTC), hours until daily reset, days until weekly reset (Monday 00:00 UTC), and any active seasonal event.

**Usage:** `time`

### `!top`  _(custom)_

Shows the top 5 currently online players ranked by a stat. Opted-out players are excluded.  For full server-wide rankings see the website at legendary-ffxi.pages.dev

**Usage:** `top`

**Parameter types:** string

### `!tournament`  _(custom)_

Legendary Tournament — last-person-standing PvE wave event.

**Usage:** `tournament`

**Parameter types:** string, string, string

### `!tower`  _(custom)_

**Usage:** `tower`

**Parameter types:** string, string

### `!trustattack`  _(custom)_

Run once to turn ON: while on, you AUTO-ENGAGE whatever mob you have targeted (cursor target), so you and your trusts attack it hands-free -- point at the next mob and you all switch to it. Run again to turn OFF. Macro:  /console !trustattack

**Usage:** `trustattack  (TOGGLE)`

### `!unstick`

Self-rescue from stuck event/sequence state.

**Usage:** `unstick`

### `!visitant`  _(custom)_

**Usage:** `visitant`

### `!voidwatch`  _(custom)_

Voidwatch-flavored rift battles. Open the menu, or tear a rift in the field.

**Usage:** `voidwatch`

**Parameter types:** string, int

### `!warpty`

**Usage:** `warpty`

### `!wavemaster`  _(custom)_

Warps you to Escha - Ru'Aun where the Wave Master NPC is located. The Wave Master runs themed enemy wave fights (Easy -> Nightmare) that reward Hunt Marks on full clear.

**Usage:** `wavemaster`

### `!waypoint`  _(custom)_

Personal, per-character warp points. Each player can save up to 10 positions (slots 1-10) wherever they stand and warp back later. Slots are overwritable -- saving over a slot just replaces it.

**Usage:** `waypoint`

**Parameter types:** string, string

### `!week`  _(custom)_

Shows the player's current weekly objectives at a glance: Weekly Hunt Board progress and featured NMs killed. Resets each Monday 00:00 UTC.

**Usage:** `week`

### `!weekly`

Displays the player's current Weekly Hunt Board progress — the 5 rolled objectives, per-objective progress, and the lifetime "Weekly Hunter" sweep counter.

**Usage:** `weekly`

### `!who`  _(custom)_

Lists players who have logged in during this server session, sorted by Hunting League tier (highest first), with their tier name shown.  Stale entries (crashed clients) are pruned lazily via GetPlayerByName at query time.

**Usage:** `who`

---

_This list reflects the commands currently live on the server._

---

<!-- DOCGEN:BEGIN id="last-updated" -->
<!-- content-hash: 3cf1669d8133 -->
_Last updated: 2026-06-29 04:19 UTC_
<!-- DOCGEN:END id="last-updated" -->
