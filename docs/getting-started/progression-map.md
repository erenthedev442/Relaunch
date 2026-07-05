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
  .pmap .c-infamy{color:#c96a86;border-color:#c96a86}
  .pmap .c-ap{color:#5f9fd6;border-color:#5f9fd6}
  .pmap .c-paragon{color:#d3814f;border-color:#d3814f}
  .pmap .c-gil{color:#a8b064;border-color:#a8b064}
  .pmap .c-reforge{color:#6fbfa0;border-color:#6fbfa0}
  .pmap .c-abyssea{color:#a482d8;border-color:#a482d8}
  .pmap .c-time{color:#8d96ab;border-color:#334059;text-transform:none;letter-spacing:.02em}
  .pmap .c-tbd{color:#8d96ab;border-color:#8d96ab;border-style:dashed}
  .pmap .spine{position:relative;margin:0 0 8px;padding-left:34px}
  .pmap .spine::before{content:'';position:absolute;left:12px;top:14px;bottom:0;width:2px;background:#334059}
  .pmap .node{position:relative;margin:0 0 18px;background:#1d2634;border:1px solid #334059;border-radius:4px;padding:16px 18px}
  .pmap .node::before{content:'';position:absolute;left:-28px;top:18px;width:12px;height:12px;border-radius:50%;background:#151a23;border:2px solid #8a7433}
  .pmap .node.hub{border-color:#8a7433;box-shadow:0 0 0 1px #8a7433,0 0 24px rgba(213,174,69,.08)}
  .pmap .node.hub::before{background:#d5ae45;border-color:#d5ae45}
  .pmap .stageno{font-size:11px;letter-spacing:.14em;text-transform:uppercase;color:#8d96ab;font-weight:600}
  .pmap .node h2{font-family:'Palatino Linotype','Book Antiqua',Palatino,Georgia,serif;font-size:21px;margin:2px 0 2px;font-weight:600;color:#d8dde8}
  .pmap .gate{font-size:13px;color:#d5ae45;margin:0 0 8px;font-weight:600}
  .pmap .gate .c-time{margin-left:8px}
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
  .pmap .lanes{display:grid;grid-template-columns:1fr 1fr;gap:14px;margin-bottom:30px}
  @media(max-width:900px){.pmap .lanes{grid-template-columns:1fr}}
  .pmap .lane{background:#1d2634;border:1px solid #334059;border-top:3px solid #8a7433;border-radius:4px;padding:14px 16px}
  .pmap .lane h3{font-family:'Palatino Linotype','Book Antiqua',Palatino,Georgia,serif;font-size:18px;margin:0 0 2px;font-weight:600;color:#d8dde8}
  .pmap .lane .who{font-size:12px;color:#8d96ab;margin-bottom:10px}
  .pmap .rung{display:flex;gap:10px;padding:7px 0;border-top:1px solid #334059;font-size:13.5px;align-items:baseline}
  .pmap .rung:first-of-type{border-top:none}
  .pmap .rung b{min-width:96px;color:#d5ae45;font-weight:600;font-variant-numeric:tabular-nums;flex-shrink:0}
  .pmap .rung span{color:#d8dde8}
  .pmap .rung .dim{color:#8d96ab}
  .pmap .refs{display:grid;grid-template-columns:1fr 1fr;gap:14px;margin-bottom:30px}
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
<div class="pmap">
<header>
  <div class="eyebrow">Legendary FFXI · Relaunch</div>
  <h1>Progression Flow Map</h1>
  <p class="sub">Every gate, unlock, and currency from first login to the infinite endgame. Times assume the plan's 6&nbsp;hours/day reference pace.</p>
</header>
<div class="loop"><b>Hunt NMs</b><span>→</span><b>Earn Marks</b><span>→</span><b>Rank Up</b><span>→</span><b>Harder Content</b><span>→</span><b>Prestige</b><span>→</span><b>Ascend Infinitely</b></div>
<div class="spine">
  <div class="node">
    <div class="stageno">Stage 0</div>
    <h2>First Login</h2>
    <div class="gate">No gate <span class="chip c-time">Day 1 · hunting within ~10 min</span></div>
    <div class="kit">
      <div><b>300,000</b> gil — 1–2 Bronze weapons off the AH</div>
      <div><b>50</b> Hunt Marks — full 10-piece Bronze armor set</div>
      <div>All jobs <b>Lv99</b> · RUN+GEO auto-unlocked</div>
      <div>Subjob levels itself (EXP share)</div>
    </div>
    <p class="dim">No starter gear handout — the 50 marks + 300k gil is a runway. Augment Sage <b>Tier 0</b> open immediately (utility/job mods, 8 boost/slot). Open from day one, in parallel: Hunter's Guild (4 guilds → up to +100% mark amp) · Invasions (<span class="chip c-infamy">Infamy</span>) · Treasure Hunts · Casino · Chocobo Derby · Daily Login · Daily Board · Login Streaks.</p>
  </div>
  <div class="node">
    <div class="stageno">Stage 1</div>
    <h2>The Hunt Begins</h2>
    <div class="gate">Rank 2 at 75 lifetime marks <span class="chip c-time">~Day 1</span></div>
    <p>Rank 1 NMs: solo/duo, 5 marks base — first kill +100%, weekly featured +200%, party +25–50%. Buy into <b>Silver gear</b> (iLv 201–250) as marks come in.</p>
    <ul class="open">
      <li>Opens: Rank 2 NMs (12 marks/kill) · Silver vendor · Colosseum (PvP marks, 15-win daily cap)</li>
    </ul>
  </div>
  <div class="node">
    <div class="stageno">Stage 2</div>
    <h2>Hitting Your Stride</h2>
    <div class="gate">Rank 3 at 225 lifetime marks <span class="chip c-time">~Day 3–4</span></div>
    <p>Rank 2–3 NMs are real duo/small-group fights (7–12 min). Transition into <b>Gold gear</b> (iLv 251+).</p>
    <ul class="open">
      <li>Opens: Rank 3 NMs (22 marks/kill) · Gold vendor · <b>Augment Tier 1</b> (weapon/magic skills, pet stats — 16/slot) · Voidspire (milestone dungeon → Paragon Points) · Abyssea T1 <span class="chip c-abyssea">Abyssea Marks</span></li>
    </ul>
  </div>
  <div class="node">
    <div class="stageno">Stage 3</div>
    <h2>The Hard Push</h2>
    <div class="gate">Rank 4 at 500 → Rank 5 at 1,000 marks <span class="chip c-time">Rank 4 ~Day 7–9 · Rank 5 ~Day 12–16</span></div>
    <p>The long stretch by design. Rank 4 = trio content at 38 marks/kill; Rank 5 = full party at 65 (130 first-kill, 195 featured). Reforge armor track runs in parallel from Week 2–3 <span class="chip c-reforge">Reforge Marks</span>.</p>
  </div>
  <div class="node hub">
    <div class="stageno">★ The Hub Gate</div>
    <h2>Hunting League Rank 5</h2>
    <div class="gate">1,000 lifetime marks — everything past this point fans out from here</div>
    <ul class="open">
      <li><b>Prestige entry</b> — job-specific Ascension begins</li>
      <li><b>Augment Tier 2</b> — core stats, acc/att ratings, Fast Cast, Store TP, cures (24/slot)</li>
      <li><b>Abyssea T2/T3</b> (Infamy-gated) · <b>Prime Trial 1</b> becomes actively completable</li>
    </ul>
  </div>
</div>
<div class="fanlabel">
  <h2>After Rank 5 — four parallel tracks</h2>
  <p>These run side by side. Prestige is the power spine; Prime is the trophy quest; Abyssea is the parallel gear track; Apex→Paragon is the ladder that never ends.</p>
</div>
<div class="lanes">
  <div class="lane">
    <h3>Prestige — Job Mastery <span class="chip c-ap">Ascension AP</span></h3>
    <div class="who">Nightmare Court trials (Diabolos · Medusa · Odin), party of 4 · AP spent on capped perks (20% crit, 40% WSDMG…) · Job Rebirth stacks in parallel (mob HP scales up at T3+)</div>
    <div class="rung"><b>Lv 1–14</b><span>Nightmare Court + T1 Voidwalker NMs <span class="dim">· Lv1 ~Day 16–18</span></span></div>
    <div class="rung"><b>Lv 15</b><span><b>Augment Tier 3</b> — Atk, DA, crit, pools, WS dmg, delay (28/slot) <span class="dim">· ~Week 5–6</span></span></div>
    <div class="rung"><b>Lv 15–40</b><span>Jailer-tier T2 · party 4–6, 15–22 min fights <span class="dim">· Lv40 ~Month 3</span></span></div>
    <div class="rung"><b>Lv 40–60</b><span>Voidwalker Lord / World's End T3–T4 · raid scale <span class="dim">· ~Month 4–5</span></span></div>
    <div class="rung"><b>Lv 60+</b><span>Celestial T5 · alliance content</span></div>
    <div class="rung"><b>Aug Tier 4</b><span>Haste, TA/QA, TP Bonus, crit dmg, Dmg+, PDT/MDT (31/slot) <span class="chip c-tbd">gate TBD — admin vote</span></span></div>
  </div>
  <div class="lane">
    <h3>Prime Weapon — Pinnacle Quest <span class="chip c-gil">750M gil</span></h3>
    <div class="who">One path, four trials, then the forge. A server status symbol and the economy's anchor gil sink.</div>
    <div class="rung"><b>Trial 1</b><span>Nightmare Fragments from Nightmare Court <span class="dim">· ~Week 3–4</span></span></div>
    <div class="rung"><b>Trial 2</b><span>Endless Tower Floor 50 <span class="dim">· ~Week 4–7</span></span></div>
    <div class="rung"><b>Trial 3</b><span>3× World Boss kills (Invasion finale) <span class="dim">· ~Week 2–4</span></span></div>
    <div class="rung"><b>Trial 4</b><span>Job Mastery milestone — needs deep Prestige <span class="dim">· ~Month 2–3</span></span></div>
    <div class="rung"><b>The Forge</b><span>Prime Armory unlocks · 750,000,000 gil <span class="dim">· ~Month 4–6</span></span></div>
  </div>
  <div class="lane">
    <h3>Abyssea — Parallel Gear Track <span class="chip c-abyssea">Abyssea Marks</span> <span class="chip c-infamy">Infamy</span></h3>
    <div class="who">Runs alongside Prestige; feeds the Infamy vendor and its own gear drops — a complement to HL, not a replacement.</div>
    <div class="rung"><b>Tier 1</b><span>Trio-sized · 8–12 min fights <span class="dim">· from HL Rank 3</span></span></div>
    <div class="rung"><b>Tier 2</b><span>Party of 4 · 10–15 min <span class="dim">· HL Rank 4–5 + Infamy</span></span></div>
    <div class="rung"><b>Tier 3</b><span>Party 4–6, alliance-adjacent · 1.5–2.3M HP <span class="dim">· HL Rank 5 + Infamy</span></span></div>
    <div class="rung"><b>Feeds</b><span>Infamy vendor top-tier picks · Reforge access</span></div>
  </div>
  <div class="lane">
    <h3>Apex &amp; Paragon — The Infinite <span class="chip c-paragon">Paragon Points</span></h3>
    <div class="who">Greater-Rift-style scaled boss ladder in Walk of Echoes [P2] · two leaderboards (Apex rank · Paragon Points) <span class="chip c-tbd">entry gate TBD</span></div>
    <div class="rung"><b>Apex Trials</b><span>1.4M HP at Tier 1, scaling per tier · PP per clear + personal-best bonus <span class="dim">· from ~Month 2–3</span></span></div>
    <div class="rung"><b>Paragon caps</b><span>+1,000 ATT · +1,000 ACC · +2,000 DEF · +5,000 HP <span class="dim">· ~Month 5–8</span></span></div>
    <div class="rung"><b>No ceiling</b><span>Infinite Prestige Levels via the Paragon board — a year in, still progressing</span></div>
  </div>
</div>
<div class="refs">
  <div class="ref">
    <h3>Currencies at a glance</h3>
    <div class="tablewrap"><table>
      <tr><th>Currency</th><th>Source</th><th>Buys</th></tr>
      <tr><td><span class="chip c-marks">Hunt Marks</span></td><td>HL NM kills</td><td>Gear tiers, rank gates, augment rolls, Colosseum</td></tr>
      <tr><td><span class="chip c-infamy">Infamy</span></td><td>Invasions, Abyssea</td><td>Abyssea tiers, Infamy vendor, Reforge access</td></tr>
      <tr><td><span class="chip c-ap">Ascension AP</span></td><td>Prestige NMs</td><td>Ascension stat perks</td></tr>
      <tr><td><span class="chip c-paragon">Paragon Pts</span></td><td>Apex Trials</td><td>Paragon board, infinite Prestige Levels</td></tr>
      <tr><td><span class="chip c-gil">Gil</span></td><td>AH, Casino, mobs</td><td>Prime forge (750M), AH, Casino</td></tr>
      <tr><td><span class="chip c-reforge">Reforge Marks</span></td><td>AF/Relic/Empy NMs</td><td>Reforge armor upgrades</td></tr>
      <tr><td><span class="chip c-abyssea">Abyssea Marks</span></td><td>Abyssea kills</td><td>Abyssea gear, Infamy vendor items</td></tr>
    </table></div>
  </div>
  <div class="ref">
    <h3>Power curve checkpoints</h3>
    <div class="tablewrap"><table>
      <tr><th>Stage</th><th>ATT</th><th>DEF</th><th>HP</th></tr>
      <tr><td>Fresh Lv99</td><td>~300</td><td>~1,500</td><td>~2,500</td></tr>
      <tr><td>Rank 1 · Bronze</td><td>~500</td><td>~2,000</td><td>~3,500</td></tr>
      <tr><td>Rank 2 · Silver</td><td>~700</td><td>~2,500</td><td>~4,500</td></tr>
      <tr><td>Rank 3–4 · Gold + T1 augs</td><td>~950</td><td>~3,000</td><td>~6,000</td></tr>
      <tr><td>Rank 5 · T2 augs</td><td>~1,200</td><td>~3,200</td><td>~7,000</td></tr>
      <tr><td>Prestige 20–40</td><td>~1,600</td><td>~4,000</td><td>~8,500</td></tr>
      <tr><td>Prestige 60+ · max Paragon</td><td>~2,200</td><td>~5,000</td><td>~10,000</td></tr>
    </table></div>
    <p class="dim" style="font-size:12px;margin-top:8px">Pets follow their own curve (jug overhaul + avatar boost) — competitive, not dominant.</p>
  </div>
</div>
<footer>
  Condensed from the relaunch design plan ("How Progression Works" · "Full Unlock Tree" · "Progression Timeline"). Two open decisions are flagged <span class="chip c-tbd">TBD</span> above: the Augment Tier 4 gate and the Apex entry gate. If the plan moves, update this map.
</footer>
</div>
