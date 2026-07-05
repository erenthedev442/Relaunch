---
title: Progression Map
---

<style>
  .pmap{background:#151a23;color:#d8dde8;font-family:'Segoe UI',system-ui,-apple-system,sans-serif;line-height:1.5;font-size:15px;border-radius:6px;padding:34px 26px 30px;margin:6px 0 24px}
  .pmap,.pmap *{box-sizing:border-box}
  .pmap .eyebrow{font-size:11px;letter-spacing:.14em;text-transform:uppercase;color:#d5ae45;font-weight:600}
  .pmap h1{font-family:'Palatino Linotype','Book Antiqua',Palatino,Georgia,serif;font-size:34px;margin:6px 0 4px;font-weight:600;letter-spacing:.01em;color:#d8dde8}
  .pmap .sub{color:#8d96ab;max-width:64ch;margin:0}
  .pmap .loop{margin:22px 0 34px;padding:14px 18px;background:#1d2634;border:1px solid #334059;border-radius:4px;font-family:'Palatino Linotype','Book Antiqua',Palatino,Georgia,serif;font-size:17px;letter-spacing:.02em;overflow-x:auto;white-space:nowrap}
  .pmap .loop b{color:#d5ae45;font-weight:600}
  .pmap .loop span{color:#8d96ab;padding:0 6px}
  .pmap .chip{display:inline-block;font-size:11px;font-weight:600;letter-spacing:.06em;text-transform:uppercase;padding:2px 8px;border-radius:3px;border:1px solid;background:rgba(0,0,0,.18);vertical-align:middle}
  .pmap .c-marks{color:#d5ae45;border-color:#d5ae45}
  .pmap .c-sigil{color:#c96a86;border-color:#c96a86}
  .pmap .c-ap{color:#5f9fd6;border-color:#5f9fd6}
  .pmap .c-paragon{color:#d3814f;border-color:#d3814f}
  .pmap .c-gil{color:#a8b064;border-color:#a8b064}
  .pmap .c-div{color:#6fbfa0;border-color:#6fbfa0}
  .pmap .c-aug{color:#a482d8;border-color:#a482d8}
  .pmap .c-time{color:#8d96ab;border-color:#334059;text-transform:none;letter-spacing:.02em}
  .pmap .spine{position:relative;margin:0 0 8px;padding-left:34px}
  .pmap .spine::before{content:'';position:absolute;left:12px;top:14px;bottom:0;width:2px;background:#334059}
  .pmap .node{position:relative;margin:0 0 18px;background:#1d2634;border:1px solid #334059;border-radius:4px;padding:16px 18px}
  .pmap .node::before{content:'';position:absolute;left:-28px;top:18px;width:12px;height:12px;border-radius:50%;background:#151a23;border:2px solid #8a7433}
  .pmap .node.hub{border-color:#8a7433;box-shadow:0 0 0 1px #8a7433,0 0 24px rgba(213,174,69,.08)}
  .pmap .node.hub::before{background:#d5ae45;border-color:#d5ae45}
  .pmap .stageno{font-size:11px;letter-spacing:.14em;text-transform:uppercase;color:#8d96ab;font-weight:600}
  .pmap .node h2{font-family:'Palatino Linotype','Book Antiqua',Palatino,Georgia,serif;font-size:21px;margin:2px 0 2px;font-weight:600;color:#d8dde8}
  .pmap .gate{font-size:13px;color:#d5ae45;margin:0 0 8px;font-weight:600}
  .pmap .node p{margin:6px 0;color:#d8dde8}
  .pmap .dim{color:#8d96ab;font-size:13.5px}
  .pmap ul.open{margin:8px 0 2px;padding-left:18px}
  .pmap ul.open li{margin:3px 0;color:#d8dde8}
  .pmap ul.open li::marker{color:#8a7433}
  .pmap .kit{display:flex;flex-wrap:wrap;gap:8px;margin-top:8px}
  .pmap .kit div{background:#232e40;border:1px solid #334059;border-radius:3px;padding:6px 10px;font-size:13px}
  .pmap .kit b{font-variant-numeric:tabular-nums}
  .pmap .fanlabel{position:relative;margin:26px 0 14px;padding-left:34px}
  .pmap .fanlabel h2{font-family:'Palatino Linotype','Book Antiqua',Palatino,Georgia,serif;font-size:24px;margin:0;color:#d5ae45;font-weight:600}
  .pmap .fanlabel p{margin:2px 0 0;color:#8d96ab;max-width:70ch}
  .pmap .lanes{display:grid;grid-template-columns:1fr 1fr;gap:14px;margin-bottom:14px}
  @media(max-width:900px){.pmap .lanes{grid-template-columns:1fr}}
  .pmap .lane{background:#1d2634;border:1px solid #334059;border-top:3px solid #8a7433;border-radius:4px;padding:14px 16px}
  .pmap .lane.wide{grid-column:1/-1}
  .pmap .lane h3{font-family:'Palatino Linotype','Book Antiqua',Palatino,Georgia,serif;font-size:18px;margin:0 0 2px;font-weight:600;color:#d8dde8}
  .pmap .lane .who{font-size:12px;color:#8d96ab;margin-bottom:10px}
  .pmap .rung{display:flex;gap:10px;padding:7px 0;border-top:1px solid #334059;font-size:13.5px;align-items:baseline}
  .pmap .rung:first-of-type{border-top:none}
  .pmap .rung b{min-width:104px;color:#d5ae45;font-weight:600;font-variant-numeric:tabular-nums;flex-shrink:0}
  .pmap .rung span{color:#d8dde8}
  .pmap .rung .dim{color:#8d96ab}
  .pmap .wgrid{display:grid;grid-template-columns:repeat(3,1fr);gap:10px}
  @media(max-width:900px){.pmap .wgrid{grid-template-columns:1fr}}
  .pmap .wcell{background:#232e40;border:1px solid #334059;border-radius:3px;padding:10px 12px;font-size:13px}
  .pmap .wcell b{display:block;color:#d5ae45;font-weight:600;margin-bottom:2px;font-size:13.5px}
  .pmap .wcell span{color:#8d96ab}
  .pmap .refs{display:grid;grid-template-columns:1fr 1fr;gap:14px;margin:14px 0 30px}
  @media(max-width:900px){.pmap .refs{grid-template-columns:1fr}}
  .pmap .ref{background:#1d2634;border:1px solid #334059;border-radius:4px;padding:14px 16px}
  .pmap .ref h3{font-family:'Palatino Linotype','Book Antiqua',Palatino,Georgia,serif;font-size:17px;margin:0 0 10px;font-weight:600;color:#d8dde8}
  .pmap table{border-collapse:collapse;width:100%;font-size:13px;font-variant-numeric:tabular-nums;background:transparent;margin:0}
  .pmap th{text-align:left;font-size:11px;letter-spacing:.08em;text-transform:uppercase;color:#8d96ab;font-weight:600;padding:4px 10px 6px 0;border-bottom:1px solid #334059;background:transparent}
  .pmap td{padding:5px 10px 5px 0;border-bottom:1px solid rgba(51,64,89,.45);vertical-align:top;background:transparent;color:#d8dde8}
  .pmap tr:last-child td{border-bottom:none}
  .pmap .tablewrap{overflow-x:auto}
  .pmap td b{color:#d5ae45;font-weight:600}
  .pmap footer{color:#8d96ab;font-size:12px;border-top:1px solid #334059;padding-top:14px;margin-top:8px}
  .pmap footer code{background:#1d2634;padding:1px 5px;border-radius:3px;font-size:11.5px;color:#d8dde8}
</style>
<!-- DOCGEN:BEGIN id="progression-map" -->
<div class="pmap">
<header>
  <div class="eyebrow">Legendary FFXI · Relaunch</div>
  <h1>Progression Flow Map</h1>
  <p class="sub">Every gate, unlock, and currency from first login to the infinite endgame — regenerated from the live catalogs on every site publish.</p>
</header>
<div class="loop"><b>Hunt NMs</b><span>→</span><b>Earn Marks</b><span>→</span><b>Rank Up</b><span>→</span><b>Unlock Augment Tiers</b><span>→</span><b>Prestige &amp; Rebirth</b><span>→</span><b>Ascend Infinitely</b></div>
<div class="spine">
  <div class="node">
    <div class="stageno">Stage 0</div>
    <h2>First Login</h2>
    <div class="gate">No gate — hunting within minutes</div>
    <div class="kit">
      <div><b>25</b> Hunt Marks starter stipend</div>
      <div><b>+50</b> marks first login each UTC day</div>
      <div>Login streaks: 7d <b>+75</b> · 14d <b>+200</b> · 21d <b>+400</b> · 30d <b>+750</b></div>
      <div>All jobs ready — no leveling wall</div>
    </div>
    <p class="dim">Open from day one, in parallel: HL Rank 1 camps · <b>Adventuring Fellow</b> · Hunter's Guild (rep amps your marks) · Affinity NM hunts · Casino · Chocobo Derby · Colosseum PvP · Daily Board. <b>The Augment Moogle refuses fresh characters</b> — slay your first 10 custom NMs (Hunting League, Wave Mode, Voidspire...) to open Augment Tier 1.</p>
  </div>
  <div class="node">
    <div class="stageno">Stage 1</div>
    <h2>The Hunt Begins</h2>
    <div class="gate">Rank 2 at 150 lifetime marks</div>
    <p>Rank 1 NMs pay 5 marks base. <b>First-ever kill of each NM pays double</b>; the weekly <b>Featured Hunt pays 2× base</b> on your first kill (stacks with first-kill); kill streaks inside 5 minutes add <b>+10% at 3, +20% at 5, +50% at 10</b>; partied kills add +25% with 2+ in party / +50% with 4+ in party.</p>
    <ul class="open">
      <li>Opens: Rank 2 NMs (12 marks/kill) · <b>Sage Mastery rank 1</b> (Augment Initiate — lifts your roll floor)</li>
      <li>Augment Tier 1 rolls live in the 0–5 band once the gate is cleared</li>
    </ul>
  </div>
  <div class="node">
    <div class="stageno">Stage 2</div>
    <h2>Hitting Your Stride</h2>
    <div class="gate">Rank 3 at 650 lifetime marks</div>
    <p>Rank 2–3 NMs are duo/small-group fights. Gear climbs through the vendor tiers as marks accumulate.</p>
    <ul class="open">
      <li>Opens: Rank 3 NMs (22 marks/kill) · <b>Sage Mastery rank 2</b> (Augment Adept)</li>
      <li>Start chipping the later augment-tier keys: clear Voidspire floor 10 + every Game Master wave difficulty</li>
    </ul>
  </div>
  <div class="node">
    <div class="stageno">Stage 3</div>
    <h2>The Hard Push</h2>
    <div class="gate">Rank 4 at 1,500 → Rank 5 at 3,000 lifetime marks</div>
    <p>The long stretch by design. Rank 4 NMs pay 38 marks; Rank 5 pays 65 — and Shinryu <b>110</b> as the Rank 5 server boss. Featured weeks and kill streaks matter most here.</p>
  </div>
  <div class="node hub">
    <div class="stageno">★ The Hub Gate</div>
    <h2>Hunting League Rank 5</h2>
    <div class="gate">3,000 lifetime marks — everything past this point fans out from here</div>
    <ul class="open">
      <li><b>Prestige entry</b> — the Ascension Altar accepts you; Nightmare Court trials begin</li>
      <li><b>Augment Tier 2</b> — rolls move up to the 6–11 band (reach Hunting League Rank 5)</li>
      <li>Deeper Sage Mastery ranks come into reach as Prestige and Rebirth progress</li>
    </ul>
  </div>
</div>
<div class="fanlabel">
  <h2>After Rank 5 — the endgame fan</h2>
  <p>Prestige is the power spine, the augment ladder is the thread through everything, Prime is the trophy quest, and Apex→Paragon never ends. The world-content band below feeds all of them.</p>
</div>
<div class="lanes">
  <div class="lane">
    <h3>Prestige &amp; Rebirth <span class="chip c-ap">Ascension AP</span></h3>
    <div class="who">Nightmare Court boss trials at the Ascension Altar · AP per kill scales with depth</div>
    <div class="rung"><b>P.Lv 1–50</b><span>10 AP per Court kill</span></div>
    <div class="rung"><b>P.Lv 51–80</b><span>15 AP per Court kill</span></div>
    <div class="rung"><b>P.Lv 81+</b><span>20 AP per Court kill</span></div>
    <div class="rung"><b>Rebirth</b><span>Any job with <b>2,100 spent Job Points</b> can rebirth — permanent stacking category boosts; rebirth counts also gate the deeper Sage Mastery ranks</span></div>
  </div>
  <div class="lane">
    <h3>Prime Weapon — 5 Trials <span class="chip c-gil">750,000,000 gil</span></h3>
    <div class="who">All trials in any order, then the forge opens</div>
    <div class="rung"><b>Trial 1</b><span>12 each of all 20 Abyssea collectibles (turn in here)</span></div>
    <div class="rung"><b>Trial 2</b><span>Endless Tower floor 50</span></div>
    <div class="rung"><b>Trial 3</b><span>Prime Voucher (Maze Monger Crown) - rare Hunting League NM drop (turn in here)</span></div>
    <div class="rung"><b>Trial 4</b><span>Weapon Guardian defeated (Job Mastery)</span></div>
    <div class="rung"><b>Trial 5</b><span>99 each of Jadeshell, Silverpiece &amp; 100 Byne Bill (turn in here)</span></div>
    <div class="rung"><b>The Forge</b><span>Prime Armory · 750,000,000 gil per weapon</span></div>
  </div>
  <div class="lane">
    <h3>The Gauntlet &amp; Apex <span class="chip c-paragon">Paragon Points</span></h3>
    <div class="who">Solo boss ladders — the Gauntlet's champion climb and the Apex arena in Walk of Echoes [P2]</div>
    <div class="rung"><b>Apex Trials</b><span>Scaled boss tiers · Paragon Points per clear</span></div>
    <div class="rung"><b>Paragon board</b><span>Caps: <b>+5,000</b> HP · <b>+1,000</b> ATT, RATT · <b>+1,000</b> ACC, RACC · <b>+2,000</b> DEF</span></div>
    <div class="rung"><b>No ceiling</b><span>The Apex ladder itself keeps scaling — the leaderboard war never ends</span></div>
  </div>
  <div class="lane">
    <h3>The Augment Ladder <span class="chip c-aug">Tiers 1–5</span></h3>
    <div class="who">Your roll band is gated by CONTENT; your Sage Mastery rank lifts the floor inside the band, and a crit = a perfect roll</div>
    <div class="rung"><b>Tier 1 · 0–5</b><span>slay your first 10 custom NMs (Hunting League, Wave Mode, Voidspire...)</span></div>
    <div class="rung"><b>Tier 2 · 6–11</b><span>reach Hunting League Rank 5</span></div>
    <div class="rung"><b>Tier 3 · 12–17</b><span>clear Voidspire floor 10 + every Game Master wave difficulty</span></div>
    <div class="rung"><b>Tier 4 · 18–24</b><span>clear a Dynamis - Divergence city</span></div>
    <div class="rung"><b>Tier 5 · 25–31</b><span>defeat Maat's Echo (Ru'Lude Gardens, !maat)</span></div>
    <div class="rung"><b>Mastery</b><span>Initiate@HL R2 · Adept@HL R3 · Magus@HL R5+P5+1 rebirth · Sage@P15+10 rebirths · Archon@P30+20 rebirths+Gauntlet clear</span></div>
  </div>
  <div class="lane wide">
    <h3>The World-Content Band — feeds everything above</h3>
    <div class="who">Independent tracks with their own currencies and loot; several are augment-tier keys. A system only appears here while it exists in the live code.</div>
    <div class="wgrid">
      <div class="wcell"><b>Dynamis — Divergence</b><span>Portals at the four city Dynamis entrances · wave battles · currency feeds the Divergence Reforger (armor +1 → +3) · a city clear is an Augment Tier key</span></div>
      <div class="wcell"><b>Voidwatch</b><span>Rift battles — pop a Planar Rift, burn the Voidwalker, stack lights for the Pyxis loot roll</span></div>
      <div class="wcell"><b>High-Tier Battlefields</b><span>Retail HTBF fights via phantom gems, tiered difficulty, dedicated vendor</span></div>
      <div class="wcell"><b>Nyzul Isle</b><span>The Sorrowful Sage in Mhaura opens retail Nyzul runs — floor-climb loot</span></div>
      <div class="wcell"><b>Spell &amp; Skill Mastery</b><span>Spend <span class="chip c-sigil">Mastery Sigils</span> at the Mastery Sage in Leafallia to permanently empower weapon skills and spells</span></div>
      <div class="wcell"><b>Voidspire &amp; GM Waves</b><span>Weekly milestone dungeon + five wave difficulties — together an Augment Tier key</span></div>
      <div class="wcell"><b>Affinity NM Hunts</b><span>Always-up affinity NMs · register Augment Sage affinities for better rolls in their category</span></div>
      <div class="wcell"><b>Maat's Echo</b><span><code>!maat</code> — the solo super-fight · first kill is an Augment Tier key</span></div>
      <div class="wcell"><b>Adventuring Fellow</b><span>Your persistent companion — levels from your kills, build it toward the role you need</span></div>
    </div>
  </div>
</div>
<div class="refs">
  <div class="ref">
    <h3>Hunting League economics</h3>
    <div class="tablewrap"><table>
      <tr><th>Rank</th><th>Gate (lifetime marks)</th><th>Pay per kill</th></tr>
      <tr><td>Rank 1</td><td>—</td><td>5</td></tr>
      <tr><td>Rank 2</td><td>150</td><td>12</td></tr>
      <tr><td>Rank 3</td><td>650</td><td>22</td></tr>
      <tr><td>Rank 4</td><td>1,500</td><td>38</td></tr>
      <tr><td>Rank 5</td><td>3,000</td><td>65 · Shinryu <b>110</b></td></tr>
    </table></div>
    <p class="dim" style="font-size:12px;margin-top:8px">Multipliers stack on base: first-kill ×2 · featured week ×2 · streak +10% at 3, +20% at 5, +50% at 10 · +25% with 2+ in party / +50% with 4+ in party · Hunter's Guild rank amp.</p>
  </div>
  <div class="ref">
    <h3>Currencies at a glance</h3>
    <div class="tablewrap"><table>
      <tr><th>Currency</th><th>Source</th><th>Buys</th></tr>
      <tr><td><span class="chip c-marks">Hunt Marks</span></td><td>HL NM kills, daily/streak/boards</td><td>Gear tiers, rank gates, augment trades</td></tr>
      <tr><td><span class="chip c-ap">Ascension AP</span></td><td>Nightmare Court kills</td><td>Prestige board perks</td></tr>
      <tr><td><span class="chip c-paragon">Paragon Pts</span></td><td>Apex Trials</td><td>Paragon board (capped stats + Daily Might)</td></tr>
      <tr><td><span class="chip c-sigil">Mastery Sigils</span></td><td>Mastery content</td><td>Permanent WS/spell empowerment</td></tr>
      <tr><td><span class="chip c-div">Divergence currency</span></td><td>Dynamis — Divergence waves</td><td>Armor reforge +1 → +3</td></tr>
      <tr><td><span class="chip c-gil">Gil</span></td><td>AH, Casino, Derby, mobs</td><td>Prime forge (750,000,000), AH, Casino</td></tr>
    </table></div>
  </div>
</div>
<footer>
  Generated on every site publish from the live relaunch catalogs (hunting_league_catalog · Augment_Moogle TIER_SLICES/TIER_GATES · augment_sage_catalog · prestige_catalog · job_rebirth_catalog · PrimeArmory_NPC · paragon_catalog · daily_login_bonus · login_streak · HuntingLeague). If a number here disagrees with the game, the next hourly publish reconciles it.
</footer>
</div>
<!-- DOCGEN:END id="progression-map" -->
