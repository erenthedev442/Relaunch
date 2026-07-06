---
title: Content Unlock Tree
---

# Content Unlock Tree

<!-- DOCGEN:BEGIN id="unlock-tree" -->
Every piece of content on the Relaunch server depends on something else. This diagram maps those dependencies: click any node to highlight what gates it (orange) and what it enables (teal).

Scroll the diagram left–right to see the full progression from Day 1 through Vertical Progression.

<div style="position:relative;margin:1.2rem 0">
<div id="utree-wrap" style="overflow:auto;border:1px solid #2a2d4a;border-radius:6px;background:#090B14">
<canvas id="utc" width="1380" height="910" style="display:block;cursor:default"></canvas>
</div>
<div id="utip" style="position:absolute;display:none;background:#1a1e38f0;border:1px solid #3a3e5a;border-radius:5px;padding:7px 11px;font-size:12px;color:#c8c8e8;pointer-events:none;max-width:230px;line-height:1.55;z-index:50;box-shadow:0 4px 16px #00000080"></div>
</div>

<script>
(function(){
const CW=1380,CH=910,NW=140,NH=26;
const cv=document.getElementById('utc');
const wrap=document.getElementById('utree-wrap');
if(!cv)return;
const ctx=cv.getContext('2d');

const CC={
  start:   {bg:'#5A3A0A',bd:'#DDA84A',tx:'#FFE090'},
  mile:    {bg:'#0D2A50',bd:'#4482C4',tx:'#A0C8FF'},
  rank:    {bg:'#3A0D0D',bd:'#C85848',tx:'#FFB0A0'},
  curr:    {bg:'#3A330A',bd:'#BBA020',tx:'#FFE090'},
  always:  {bg:'#0D3020',bd:'#5EA872',tx:'#88FF88'},
  content: {bg:'#20133A',bd:'#8B72D4',tx:'#C0A8FF'},
  reward:  {bg:'#0D2830',bd:'#41BFB0',tx:'#80FFE0'},
  vert:    {bg:'#2A1A08',bd:'#E8956A',tx:'#FFCC88'},
};

const nodes=[{"id": "start", "x": 70, "y": 45, "lbl": "New Character", "t": "start", "desc": "<strong>New Character</strong>Starter setup + <strong>25 Hunt Marks</strong>. Everything on this map branches from here."}, {"id": "boards", "x": 70, "y": 140, "lbl": "Daily & Weekly Boards", "t": "always", "desc": "<strong>Daily & Weekly Boards</strong>Daily: Hunt Marks + Gil objectives. Weekly: sweep all objectives → +5,000 mark meta-bonus."}, {"id": "augmog", "x": 70, "y": 215, "lbl": "Augment Moogle", "t": "always", "desc": "<strong>Augment Moogle</strong>Random stat augments on any gear. No gate. A registered affinity makes every matching roll happen twice and keep the better result."}, {"id": "coloss", "x": 70, "y": 290, "lbl": "Colosseum", "t": "always", "desc": "<strong>Colosseum</strong>Async duels vs player replicas. 10 Hunt Marks per win, 15 wins/day cap."}, {"id": "gauntlet", "x": 70, "y": 365, "lbl": "Gauntlet (10 levels)", "t": "always", "desc": "<strong>The Gauntlet</strong>Solo NM climb, HP doubles per level. Level 10 clear: 250,000 gil + 25 Infamy + 25 PP + Prime Armory flag."}, {"id": "apex", "x": 70, "y": 440, "lbl": "Apex Trials", "t": "always", "desc": "<strong>Apex Trials</strong>Infinite scaling post-cap NMs. Infamy + Paragon Points per kill."}, {"id": "etower", "x": 70, "y": 515, "lbl": "Endless Tower", "t": "always", "desc": "<strong>Endless Tower</strong>50 floors solo, trusts disabled. Floor 50 clear sets the Prime Armory unlock flag."}, {"id": "voidwatch", "x": 70, "y": 590, "lbl": "Voidwatch", "t": "always", "desc": "<strong>Voidwatch</strong>5 free Voidstones on first visit, 1/hr regen, cap 10. Open Planar Rifts → Voidwalker NM → Pyxis loot."}, {"id": "dungeons", "x": 70, "y": 665, "lbl": "Dungeons (10)", "t": "always", "desc": "<strong>Dungeons</strong>10 custom instanced zones, no rank gate, curated boss drops."}, {"id": "affnm", "x": 70, "y": 740, "lbl": "Affinity NMs (24)", "t": "always", "desc": "<strong>Affinity NMs</strong>24 classic HNMs permanently spawned, 30s respawn. Trophy drops to the kill-blow player."}, {"id": "sigils", "x": 70, "y": 815, "lbl": "Mastery Sigils", "t": "curr", "desc": "<strong>Mastery Sigils</strong>Granted by !buff (the zone's regional buff). Spent at the Mastery Sage for Spell & Skill Mastery."}, {"id": "lv99", "x": 245, "y": 45, "lbl": "Level 99", "t": "mile", "desc": "<strong>Level 99</strong>Reach level 99 to unlock Hunting League Rank I."}, {"id": "mastery", "x": 245, "y": 815, "lbl": "Spell & Skill Mastery", "t": "vert", "desc": "<strong>Spell & Skill Mastery</strong>Mastery Sage at !leaf. Spend Mastery Sigils to empower weapon skills and spells beyond their normal caps."}, {"id": "rank1", "x": 420, "y": 45, "lbl": "HL Rank I — Initiate", "t": "rank", "desc": "<strong>Rank I - Initiate</strong>Starting HL rank. Pop NMs from Hunt: Spawner. 5 Hunt Marks per kill."}, {"id": "marks", "x": 420, "y": 150, "lbl": "Hunt Marks", "t": "curr", "desc": "<strong>Hunt Marks</strong>Primary currency. 5→65 per kill by rank. Buy seals, register affinities, unlock ranks."}, {"id": "seals", "x": 420, "y": 255, "lbl": "Seals (Bronze/Sv/Gd)", "t": "curr", "desc": "<strong>Seals</strong>Bought with Hunt Marks at the Seals Vendor. Bronze/Silver/Gold tier determines the gear tier available."}, {"id": "gear", "x": 420, "y": 360, "lbl": "Seal Vendors (Gear)", "t": "reward", "desc": "<strong>Seal Vendors</strong>Armor, Weapons, and Accessories vendors in Escha - Zi'Tah. Seal tier gates the gear tier."}, {"id": "rank2", "x": 600, "y": 45, "lbl": "HL Rank II — Hunter", "t": "rank", "desc": "<strong>Rank II - Hunter</strong>Unlock: 150 total marks spent. 12 marks/kill."}, {"id": "rank3", "x": 780, "y": 45, "lbl": "HL Rank III — Elite", "t": "rank", "desc": "<strong>Rank III - Elite</strong>Unlock: 650 total marks spent. 22 marks/kill. Gates: Abyssea, Unity, Augment Sage R2, Affinity Registration."}, {"id": "abyssea", "x": 780, "y": 155, "lbl": "Abyssea NMs", "t": "content", "desc": "<strong>Abyssea NMs</strong>3 tiers (Visions/Scars/Heroes). Pop cost: 200/350/500 Hunt Marks. Drops AF/Relic/Empy Marks + Infamy (25–60/kill)."}, {"id": "unity", "x": 780, "y": 250, "lbl": "Unity Concord", "t": "content", "desc": "<strong>Unity Concord</strong>Wanted NMs across tiers. Produces Accolades for the Unity Shop."}, {"id": "augsage1", "x": 780, "y": 345, "lbl": "Augment Sage R1–2", "t": "reward", "desc": "<strong>Augment Sage R1–2</strong>HL Rank 3 unlocks Sage Rank 2 (Augment Adept). Higher roll floors on all gear."}, {"id": "affreg", "x": 780, "y": 440, "lbl": "Affinity Registration", "t": "reward", "desc": "<strong>Affinity Registration</strong>Trophy + HL Rank 3 + 1,000 marks. Registers one of 24 stat affinities permanently."}, {"id": "affmult", "x": 780, "y": 535, "lbl": "Affinity Reroll", "t": "reward", "desc": "<strong>Affinity Reroll</strong>Per registered affinity: every augment roll in that stat category is rolled twice, keeping the better result."}, {"id": "rank4", "x": 960, "y": 45, "lbl": "HL Rank IV — Champion", "t": "rank", "desc": "<strong>Rank IV - Champion</strong>Unlock: 1,500 total marks spent. 38 marks/kill. Opens group boss content."}, {"id": "hnm", "x": 960, "y": 155, "lbl": "HNM Kings / Sky Gods", "t": "content", "desc": "<strong>HNM Kings / Sky Gods</strong>Land kings and Sky Gods. Produce AF/Relic/Empy Marks for the Reforge system."}, {"id": "htbf", "x": 960, "y": 250, "lbl": "HTBF (Phantom Gem)", "t": "content", "desc": "<strong>HTBF</strong>3 tiers, Phantom Gem entry (50,000–200,000 gil). No rank gate — buy a gem, enter anytime."}, {"id": "dynamis", "x": 960, "y": 345, "lbl": "Dynamis – Divergence", "t": "content", "desc": "<strong>Dynamis – Divergence</strong>4 cities × wave battles. Drops the +4 Forge materials — Rusted/Black ID Cards, and a main-job Paragon Card off the Mega-Boss."}, {"id": "nyzul", "x": 960, "y": 440, "lbl": "Nyzul Isle", "t": "content", "desc": "<strong>Nyzul Isle</strong>Floor-climb runs. Enter via the Sorrowful Sage at Mhaura (no Assault rank needed). Nyzul armor rewards."}, {"id": "invasions", "x": 960, "y": 630, "lbl": "Scheduled Invasions", "t": "content", "desc": "<strong>Scheduled Invasions</strong>Server-wide wave events — watch for the announcement. Produces Infamy per event."}, {"id": "rfmarks", "x": 960, "y": 725, "lbl": "AF/Relic/Empy Marks", "t": "curr", "desc": "<strong>AF/Relic/Empy Marks</strong>Produced by Abyssea NMs and HNM Kings. Spent at the Reforge Vendor for +1/+2/+3 armor."}, {"id": "reforge", "x": 960, "y": 820, "lbl": "Reforge (+1/+2/+3)", "t": "reward", "desc": "<strong>Reforge Vendor</strong>Upgrades AF, Relic, and Empy armor from base to +1, +2, +3. Spend marks at the Reforge Vendor at !leaf. (+4 is the separate Dynamis-D Forge.)"}, {"id": "plus4forge", "x": 1140, "y": 635, "lbl": "Divergence +4 Forge", "t": "reward", "desc": "<strong>Divergence +4 Forge</strong>Trade a reforged +3 AF/Relic piece + your job's Paragon Card + Rusted/Black ID Cards → the +4. AF & Relic only (Empy caps at +3)."}, {"id": "rank5", "x": 1140, "y": 45, "lbl": "HL Rank V — Legend", "t": "rank", "desc": "<strong>Rank V - Legend</strong>Unlock: 3,000 total marks spent. 65 marks/kill (top NM 110). Gates the Prestige system."}, {"id": "infamy", "x": 1140, "y": 155, "lbl": "Infamy", "t": "curr", "desc": "<strong>Infamy</strong>Produced by Invasions, Apex Trials, the Gauntlet (25 on full clear), and Abyssea (25–60/kill)."}, {"id": "infamyv", "x": 1140, "y": 250, "lbl": "Infamy Vendor (BiS)", "t": "reward", "desc": "<strong>Infamy Vendor</strong>Best-in-slot gear, relic weapons, instruments. Spend Infamy directly. No rank gate."}, {"id": "pp", "x": 1140, "y": 350, "lbl": "Paragon Points", "t": "curr", "desc": "<strong>Paragon Points</strong>Produced by Apex Trials and the Gauntlet (25 PP on full clear). Spent on the Paragon Board."}, {"id": "parboard", "x": 1140, "y": 445, "lbl": "Paragon Board", "t": "reward", "desc": "<strong>Paragon Board</strong>Permanent account-wide stat bonuses. Never resets. Bought with Paragon Points."}, {"id": "accolades", "x": 1140, "y": 540, "lbl": "Accolades → Unity Shop", "t": "reward", "desc": "<strong>Accolades</strong>Produced by Unity Concord kills. Spent in the Unity Shop for gear and rewards."}, {"id": "prestige", "x": 1300, "y": 45, "lbl": "Prestige / Ascension", "t": "vert", "desc": "<strong>Prestige / Ascension</strong>Requires HL Rank 5 on a job → reset it for a permanent per-job bonus. Cost: 500–3,000 marks, escalating. Stackable across all 22 jobs."}, {"id": "rebirth", "x": 1300, "y": 190, "lbl": "Job Rebirth", "t": "vert", "desc": "<strong>Job Rebirth</strong>After Prestige: any job with 2,100 spent Job Points can rebirth — re-grind RP for larger permanent per-job stat bonuses."}, {"id": "augsage2", "x": 1300, "y": 360, "lbl": "Augment Sage R3–5", "t": "reward", "desc": "<strong>Augment Sage R3–5</strong>R3: HL Rank 5 + Prestige 5 + 1 rebirth. R4: Prestige 15 + 10 rebirths. R5: Prestige 30 + 20 rebirths + Gauntlet clear."}, {"id": "prime", "x": 1300, "y": 530, "lbl": "Prime Armory", "t": "vert", "desc": "<strong>Prime Armory</strong>Unlock: Gauntlet full clear OR Endless Tower top-floor clear. Complete 5 trials, then forge 1 of 12 named Prime forms (750M gil each)."}];

const edges=[{"f": "start", "t": "lv99"}, {"f": "lv99", "t": "rank1"}, {"f": "rank1", "t": "rank2", "lb": "150 marks"}, {"f": "rank2", "t": "rank3", "lb": "650 marks"}, {"f": "rank3", "t": "rank4", "lb": "1,500 marks"}, {"f": "rank4", "t": "rank5", "lb": "3,000 marks"}, {"f": "rank5", "t": "prestige"}, {"f": "start", "t": "boards"}, {"f": "start", "t": "augmog"}, {"f": "start", "t": "coloss"}, {"f": "start", "t": "gauntlet"}, {"f": "start", "t": "apex"}, {"f": "start", "t": "etower"}, {"f": "start", "t": "voidwatch", "lb": "5 free stones"}, {"f": "start", "t": "dungeons"}, {"f": "start", "t": "affnm"}, {"f": "start", "t": "sigils", "lb": "!buff"}, {"f": "rank1", "t": "marks", "lb": "5/kill"}, {"f": "marks", "t": "seals", "lb": "buy"}, {"f": "seals", "t": "gear"}, {"f": "boards", "t": "marks", "lb": "daily bonus"}, {"f": "coloss", "t": "marks", "lb": "10/win"}, {"f": "htbf", "t": "marks"}, {"f": "rank3", "t": "abyssea", "lb": "200–500 marks/pop"}, {"f": "rank3", "t": "unity"}, {"f": "rank3", "t": "augsage1"}, {"f": "rank3", "t": "affreg", "lb": "HL 3 req."}, {"f": "affnm", "t": "affreg", "lb": "trophy + 1,000"}, {"f": "marks", "t": "affreg", "lb": "1,000 marks"}, {"f": "affreg", "t": "affmult"}, {"f": "affmult", "t": "augmog", "lb": "reroll on match"}, {"f": "abyssea", "t": "rfmarks", "lb": "AF/Rel/Emp"}, {"f": "hnm", "t": "rfmarks"}, {"f": "rfmarks", "t": "reforge"}, {"f": "dynamis", "t": "plus4forge", "lb": "ID cards + P.Card"}, {"f": "reforge", "t": "plus4forge", "lb": "+3 piece"}, {"f": "rank4", "t": "hnm"}, {"f": "rank4", "t": "htbf", "lb": "gem/gil only"}, {"f": "rank4", "t": "dynamis"}, {"f": "rank4", "t": "nyzul"}, {"f": "rank4", "t": "invasions"}, {"f": "abyssea", "t": "infamy", "lb": "25–60/kill"}, {"f": "gauntlet", "t": "infamy", "lb": "25 on L10"}, {"f": "apex", "t": "infamy"}, {"f": "invasions", "t": "infamy"}, {"f": "infamy", "t": "infamyv"}, {"f": "gauntlet", "t": "pp", "lb": "25 on L10"}, {"f": "apex", "t": "pp"}, {"f": "pp", "t": "parboard"}, {"f": "unity", "t": "accolades"}, {"f": "prestige", "t": "rebirth"}, {"f": "rank5", "t": "augsage2", "lb": "HL 5 gate"}, {"f": "prestige", "t": "augsage2", "lb": "Prestige ≥5"}, {"f": "rebirth", "t": "augsage2", "lb": "Rebirth ≥1"}, {"f": "gauntlet", "t": "prime", "lb": "L10 clears flag"}, {"f": "etower", "t": "prime", "lb": "Fl.50 clears flag"}, {"f": "sigils", "t": "mastery"}];

const nmap={};nodes.forEach(n=>nmap[n.id]=n);
function nr(n){return{x:n.x-NW/2,y:n.y-NH/2,w:NW,h:NH};}
let sel=null;
function getConn(id){
  const out=new Set(),inp=new Set();
  edges.forEach(e=>{if(e.f===id)out.add(e.t);if(e.t===id)inp.add(e.f);});
  return{out,inp};
}
function drawNode(n,st){
  const r=nr(n);const col=CC[n.t]||CC.content;
  const alpha=st==='dim'?0.18:1;
  ctx.save();ctx.globalAlpha=alpha;
  if(st==='sel'){ctx.shadowColor=col.bd;ctx.shadowBlur=16;}
  else if(st==='out'||st==='inp'){ctx.shadowColor=col.bd;ctx.shadowBlur=9;}
  ctx.beginPath();ctx.roundRect(r.x,r.y,r.w,r.h,4);
  ctx.fillStyle=col.bg;ctx.fill();
  ctx.lineWidth=st==='sel'?2.2:1.4;
  ctx.strokeStyle=st==='sel'?'#ffffff':col.bd;ctx.stroke();
  ctx.shadowBlur=0;
  ctx.font=(st==='sel'?'600 ':'400 ')+'10.5px system-ui';
  ctx.fillStyle=st==='dim'?'#444466':col.tx;
  ctx.textAlign='center';ctx.textBaseline='middle';
  const t=n.lbl;ctx.fillText(t.length>21?t.slice(0,20)+'…':t,r.x+r.w/2,r.y+r.h/2);
  ctx.restore();
}
function ep(src,dst){
  const sr=nr(src),dr=nr(dst);
  const dx=dst.x-src.x,dy=dst.y-src.y;
  let x1,y1,x2,y2,c1x,c1y,c2x,c2y;
  if(Math.abs(dx)>=Math.abs(dy)){
    if(dx>0){x1=sr.x+sr.w;y1=src.y;x2=dr.x;y2=dst.y;}
    else{x1=sr.x;y1=src.y;x2=dr.x+dr.w;y2=dst.y;}
    const mx=(x1+x2)/2;c1x=mx;c1y=y1;c2x=mx;c2y=y2;
  } else {
    if(dy>0){x1=src.x;y1=sr.y+sr.h;x2=dst.x;y2=dr.y;}
    else{x1=src.x;y1=sr.y;x2=dst.x;y2=dr.y+dr.h;}
    const my=(y1+y2)/2;c1x=x1;c1y=my;c2x=x2;c2y=my;
  }
  return{x1,y1,x2,y2,c1x,c1y,c2x,c2y};
}
function drawEdge(e,dim,col){
  const src=nmap[e.f],dst=nmap[e.t];if(!src||!dst)return;
  const p=ep(src,dst);
  ctx.save();ctx.globalAlpha=dim?0.09:0.72;
  ctx.strokeStyle=dim?'#2a2d50':col;ctx.lineWidth=dim?1:1.4;
  ctx.beginPath();ctx.moveTo(p.x1,p.y1);
  ctx.bezierCurveTo(p.c1x,p.c1y,p.c2x,p.c2y,p.x2,p.y2);ctx.stroke();
  if(!dim){
    const ang=Math.atan2(p.y2-p.c2y,p.x2-p.c2x);
    ctx.fillStyle=col;ctx.beginPath();ctx.moveTo(p.x2,p.y2);
    ctx.lineTo(p.x2-8*Math.cos(ang-.38),p.y2-8*Math.sin(ang-.38));
    ctx.lineTo(p.x2-8*Math.cos(ang+.38),p.y2-8*Math.sin(ang+.38));
    ctx.closePath();ctx.fill();
    if(e.lb){
      ctx.globalAlpha=0.8;ctx.font='8.5px system-ui';ctx.fillStyle='#9090b8';
      ctx.textAlign='center';
      ctx.fillText(e.lb,(p.x1+p.x2)/2,(p.y1+p.y2)/2-5);
    }
  }
  ctx.restore();
}
function draw(){
  ctx.clearRect(0,0,CW,CH);ctx.fillStyle='#090B14';ctx.fillRect(0,0,CW,CH);
  const bands=[
    {x:10,  w:148,label:'Day 1 Open',  col:'#5EA87212'},
    {x:158, w:160,label:'Lv99',        col:'#4482C412'},
    {x:318, w:320,label:'Rank I–II',   col:'#BBA02008'},
    {x:638, w:325,label:'Rank III',    col:'#8B72D412'},
    {x:963, w:365,label:'Rank IV–V',   col:'#C8584812'},
    {x:1228,w:145,label:'Vertical',    col:'#E8956A12'},
  ];
  bands.forEach(b=>{
    ctx.save();ctx.fillStyle=b.col;
    ctx.beginPath();ctx.roundRect(b.x,5,b.w,CH-10,6);ctx.fill();
    ctx.font='9px system-ui';ctx.fillStyle='#ffffff18';
    ctx.textAlign='center';ctx.fillText(b.label,b.x+b.w/2,CH-10);
    ctx.restore();
  });
  let ns={},edim={};
  nodes.forEach(n=>ns[n.id]=sel?'dim':'normal');
  if(sel){
    ns[sel]='sel';
    const{out,inp}=getConn(sel);
    out.forEach(id=>{if(nmap[id])ns[id]='out';});
    inp.forEach(id=>{if(nmap[id])ns[id]='inp';});
    edges.forEach((e,i)=>{edim[i]=!(e.f===sel||e.t===sel);});
  }
  edges.forEach((e,i)=>{
    const dim=!!edim[i];
    let col='#5060a0';
    if(!dim&&sel){if(e.f===sel)col='#41BFB0';else if(e.t===sel)col='#E8956A';}
    drawEdge(e,dim,col);
  });
  nodes.forEach(n=>drawNode(n,ns[n.id]||'normal'));
  const ltypes=[
    {t:'rank',   lb:'HL Rank gate'},
    {t:'always', lb:'Always available'},
    {t:'curr',   lb:'Currency'},
    {t:'content',lb:'Content / Boss'},
    {t:'reward', lb:'Reward / Service'},
    {t:'vert',   lb:'Vertical progression'},
  ];
  const lx=CW-150,ly=CH-ltypes.length*19-18;
  ctx.save();ctx.globalAlpha=.88;ctx.fillStyle='#10142B';
  ctx.beginPath();ctx.roundRect(lx-8,ly-6,144,ltypes.length*19+16,5);
  ctx.fill();ctx.strokeStyle='#2a2d4a';ctx.lineWidth=1;ctx.stroke();
  ctx.font='9px system-ui';ctx.fillStyle='#6666a0';ctx.textAlign='left';ctx.textBaseline='middle';
  ctx.fillText('LEGEND',lx,ly+4);
  ltypes.forEach((lt,i)=>{
    const ty=ly+18+i*19;const col=CC[lt.t]||CC.content;
    ctx.fillStyle=col.bd;ctx.beginPath();ctx.roundRect(lx,ty-5,10,10,2);ctx.fill();
    ctx.fillStyle='#aaaacc';ctx.font='9.5px system-ui';ctx.fillText(lt.lb,lx+14,ty);
  });
  ctx.restore();
}
const tip=document.getElementById('utip');
cv.addEventListener('click',e=>{
  const r=wrap.getBoundingClientRect();
  const sx=wrap.scrollLeft,sy=wrap.scrollTop;
  const mx=(e.clientX-r.left+sx)*(CW/cv.offsetWidth||1);
  const my=(e.clientY-r.top+sy)*(CH/cv.offsetHeight||1);
  let hit=null;
  nodes.forEach(n=>{const rc=nr(n);if(mx>=rc.x&&mx<=rc.x+rc.w&&my>=rc.y&&my<=rc.y+rc.h)hit=n.id;});
  sel=(hit===sel)?null:hit;draw();
});
cv.addEventListener('mousemove',e=>{
  const wr=wrap.getBoundingClientRect();
  const sx=wrap.scrollLeft,sy=wrap.scrollTop;
  const mx=(e.clientX-wr.left+sx)*(CW/cv.offsetWidth||1);
  const my=(e.clientY-wr.top+sy)*(CH/cv.offsetHeight||1);
  let found=false;
  nodes.forEach(n=>{
    const rc=nr(n);
    if(mx>=rc.x&&mx<=rc.x+rc.w&&my>=rc.y&&my<=rc.y+rc.h){
      const pr=wrap.parentElement.getBoundingClientRect();
      tip.style.display='block';
      tip.style.left=(e.clientX-pr.left+10)+'px';
      tip.style.top=Math.max(0,e.clientY-pr.top-30)+'px';
      tip.innerHTML=n.desc;found=true;
      cv.style.cursor='pointer';
    }
  });
  if(!found){tip.style.display='none';cv.style.cursor='default';}
});
cv.addEventListener('mouseleave',()=>{tip.style.display='none';});
draw();
})();
</script>

---

## Reading the diagram

- **Teal arrows** leaving a selected node: systems it **enables**
- **Orange arrows** entering a selected node: systems that **gate** it
- Phase bands (column background shading) show which unlock tier each system sits in
- Nodes with no incoming arrows are available from **Day 1**

## Key unlock paths

| If you want… | You need… |
|---|---|
| Augment Sage R3–5 | HL Rank 5 + Prestige 5 + 1 rebirth (R3), escalating to Prestige 30 + 20 rebirths + Gauntlet clear (R5) |
| Prime Armory | Gauntlet full clear **or** Endless Tower top-floor clear |
| Affinity Registration | Affinity NM trophy + HL Rank 3 + 1,000 Hunt Marks |
| Reforge +3 gear | Abyssea NMs / HNM Kings → AF/Relic/Empy marks |
| +4 AF/Relic gear | A reforged **+3** piece + Dynamis-D materials (Rusted/Black ID Cards + Paragon Card) at the Divergence Forge |
| Infamy Vendor (BiS) | Accumulate Infamy (Invasions, Apex, Gauntlet) |
| Paragon Board | Paragon Points from Apex Trials or Gauntlet full clear |

*Every node, edge, and number in this diagram is regenerated from the live server catalogs on each site publish — if it disagrees with the game, the next hourly publish reconciles it.*
<!-- DOCGEN:END id="unlock-tree" -->

---

<!-- DOCGEN:BEGIN id="last-updated" -->
<!-- content-hash: 65404cbc05f0 -->
_Last updated: 2026-07-06 06:28 PDT_
<!-- DOCGEN:END id="last-updated" -->
