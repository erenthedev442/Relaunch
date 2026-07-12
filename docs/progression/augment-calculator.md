# Augment Value Calculator

Plug in an augment, pick your **Augment Tier** (content-gated — see the [Sage page](augment-sage.md) ladder), how many catalyst slots you're filling, your Sage rank, and toggle affinity / crit to see your **roll band** — worst case, expected, best case — and how it compares to the absolute ceiling.

!!! tip "Crystalize is a separate layer"
    These numbers are the roll *magnitudes*. When a line hits its **max** value it can **crystalize** (lock) — a chance that scales with your Sage rank — so you can protect a perfect roll while re-rolling the rest. See [Crystalize: lock in your best rolls](augmenting-guide.md#crystalize-lock-in-your-best-rolls).

<div id="aug-calc-root">

<style>
#aug-calc-root{font-family:inherit;max-width:860px}
.aug-label{display:block;font-size:.72rem;font-weight:700;letter-spacing:.08em;text-transform:uppercase;color:var(--md-default-fg-color--light,#555);margin-bottom:.45rem}
.aug-select{width:100%;padding:.55rem .7rem;border:1px solid var(--md-default-fg-color--lightest,#ddd);border-radius:6px;font-size:.95rem;background:var(--md-default-bg-color,#fff);color:var(--md-default-fg-color,#222);margin-bottom:1.4rem;cursor:pointer}
.aug-select:focus{outline:2px solid #5c6bc0;outline-offset:2px}
.aug-btn-row{display:flex;flex-wrap:wrap;gap:.45rem;margin-bottom:1.4rem}
.aug-btn{padding:.42rem .9rem;border-radius:6px;border:1px solid var(--md-default-fg-color--lightest,#ddd);font-size:.88rem;cursor:pointer;background:var(--md-default-bg-color,#fff);color:var(--md-default-fg-color,#222);transition:background .12s,color .12s,border-color .12s}
.aug-btn.active{background:#5c6bc0;color:#fff;border-color:#5c6bc0}
.aug-btn:hover:not(.active){background:var(--md-accent-fg-color--transparent,#e8eaf6)}
.aug-toggle-row{display:flex;gap:2.5rem;margin-bottom:1.6rem;flex-wrap:wrap}
.aug-toggle-group{display:flex;flex-direction:column;gap:.35rem}
.aug-toggle-label{font-size:.72rem;font-weight:700;letter-spacing:.08em;text-transform:uppercase;color:var(--md-default-fg-color--light,#555)}
.aug-toggle-inner{display:flex;align-items:center;gap:.6rem}
.aug-toggle-switch{position:relative;width:42px;height:24px;flex-shrink:0}
.aug-toggle-switch input{opacity:0;width:0;height:0;position:absolute}
.aug-toggle-track{position:absolute;inset:0;border-radius:12px;background:#ccc;cursor:pointer;transition:background .18s}
.aug-toggle-switch input:checked+.aug-toggle-track{background:#5c6bc0}
.aug-toggle-track::after{content:'';position:absolute;top:3px;left:3px;width:18px;height:18px;border-radius:50%;background:#fff;transition:transform .18s;box-shadow:0 1px 3px rgba(0,0,0,.3)}
.aug-toggle-switch input:checked+.aug-toggle-track::after{transform:translateX(18px)}
.aug-toggle-text{font-size:.92rem;color:var(--md-default-fg-color,#222)}
.aug-toggle-hint{font-size:.8rem;color:var(--md-default-fg-color--light,#777);margin-top:.1rem}
.aug-result{background:var(--md-default-fg-color--lightest,#f5f5f5);border-radius:10px;padding:1.4rem 1.6rem;margin-top:.4rem}
.aug-big{font-size:2.5rem;font-weight:700;color:var(--md-default-fg-color,#222);line-height:1}
.aug-sub{font-size:.9rem;color:var(--md-default-fg-color--light,#777);margin-top:.25rem}
.aug-bar-wrap{height:4px;background:var(--md-default-fg-color--lightest,#ddd);border-radius:2px;margin:.85rem 0}
.aug-bar{height:100%;background:#5c6bc0;border-radius:2px;transition:width .2s}
.aug-stats{display:flex;gap:2rem;flex-wrap:wrap;margin-top:.2rem}
.aug-stat{display:flex;flex-direction:column;gap:.2rem}
.aug-stat-lbl{font-size:.7rem;font-weight:700;letter-spacing:.07em;text-transform:uppercase;color:var(--md-default-fg-color--light,#999)}
.aug-stat-val{font-size:.95rem;font-weight:600;color:var(--md-default-fg-color,#222)}
</style>

<div style="margin-bottom:1.4rem">
  <label class="aug-label" for="aug-select">Augment</label>
  <select id="aug-select" class="aug-select"></select>
</div>

<div>
  <span class="aug-label">Augment Tier (content-gated roll band)</span>
  <div class="aug-btn-row" id="tier-row"></div>
  <span id="tier-hint" class="aug-toggle-hint" style="display:block;margin:-1rem 0 1.4rem"></span>
</div>

<div>
  <span class="aug-label">Catalysts traded (slots filled)</span>
  <div class="aug-btn-row" id="slots-row"></div>
</div>

<div>
  <span class="aug-label">Sage Rank (raises the roll floor)</span>
  <div class="aug-btn-row" id="rank-row"></div>
</div>

<div class="aug-toggle-row">
  <div class="aug-toggle-group">
    <span class="aug-toggle-label">Affinity unlocked</span>
    <div class="aug-toggle-inner">
      <label class="aug-toggle-switch">
        <input type="checkbox" id="tog-affinity">
        <span class="aug-toggle-track"></span>
      </label>
      <span id="tog-affinity-text" class="aug-toggle-text">No</span>
    </div>
    <span class="aug-toggle-hint">Defeat the category NM + trade trophy to Augment Sage</span>
  </div>
  <div class="aug-toggle-group">
    <span class="aug-toggle-label">Critical Roll</span>
    <div class="aug-toggle-inner">
      <label class="aug-toggle-switch">
        <input type="checkbox" id="tog-crit">
        <span class="aug-toggle-track"></span>
      </label>
      <span id="tog-crit-text" class="aug-toggle-text">No</span>
    </div>
    <span id="crit-hint" class="aug-toggle-hint">5% chance at rank 0</span>
  </div>
</div>

<div class="aug-result">
  <div id="out-big" class="aug-big">—</div>
  <div id="out-sub" class="aug-sub"></div>
  <div class="aug-bar-wrap"><div id="out-bar" class="aug-bar" style="width:0%"></div></div>
  <div class="aug-stats">
    <div class="aug-stat"><span class="aug-stat-lbl">Per Slot (min–max)</span><span id="out-per-slot" class="aug-stat-val">—</span></div>
    <div class="aug-stat"><span class="aug-stat-lbl">Roll Band</span><span id="out-boost" class="aug-stat-val">—</span></div>
    <div class="aug-stat"><span class="aug-stat-lbl">% of Max (expected)</span><span id="out-pct" class="aug-stat-val">—</span></div>
    <div class="aug-stat"><span id="out-max-lbl" class="aug-stat-lbl">Max Possible (×5)</span><span id="out-max" class="aug-stat-val">—</span></div>
  </div>
</div>

</div>

<!-- DOCGEN:BEGIN id="augment-calc-data" -->
<script>window._augCalcData=[{"label":"AGI","base":1,"mult":1,"tier":0},{"label":"Accuracy","base":1,"mult":2,"tier":0},{"label":"Accuracy Attack","base":1,"mult":1,"tier":0},{"label":"Accuracy Rng.Acc","base":1,"mult":1,"tier":0},{"label":"All elemental resists","base":10,"mult":1,"tier":0},{"label":"All songs","base":1,"mult":1,"tier":0,"mb":1,"tv":2},{"label":"Attack","base":1,"mult":2,"tier":0},{"label":"Attack Rng.Atk","base":1,"mult":1,"tier":0},{"label":"Avatar Blood Pact Dmg","base":1,"mult":1,"tier":0,"mb":11},{"label":"Avatar perpetuation cost","base":1,"mult":1,"tier":0},{"label":"Barrage","base":1,"mult":1,"tier":0},{"label":"Beast Affinity","base":5,"mult":1,"tier":0},{"label":"Blood Boon","base":1,"mult":1,"tier":0},{"label":"Blood Pact ability delay","base":1,"mult":1,"tier":0},{"label":"Breath dmg. taken","base":3,"mult":30,"tier":0,"d":100},{"label":"CHR","base":1,"mult":1,"tier":0},{"label":"Call Beast ability delay","base":1,"mult":1,"tier":0},{"label":"Cap. Point +33%","base":33,"mult":1,"tier":0},{"label":"Chance of successful block","base":1,"mult":1,"tier":0,"mb":9},{"label":"Charm","base":1,"mult":1,"tier":0},{"label":"Conserve MP","base":1,"mult":1,"tier":0},{"label":"Conserve TP","base":1,"mult":1,"tier":0},{"label":"Counter","base":1,"mult":2,"tier":0},{"label":"Crit. hit damage","base":1,"mult":1,"tier":0,"mb":9},{"label":"Crit.hit rate","base":1,"mult":1,"tier":0,"mb":9},{"label":"Cure potency","base":1,"mult":1,"tier":0,"mb":14},{"label":"Cure spellcasting time","base":1,"mult":1,"tier":0},{"label":"DEF","base":1,"mult":10,"tier":0},{"label":"DEX","base":1,"mult":1,"tier":0},{"label":"Daken","base":1,"mult":1,"tier":0},{"label":"Damage Taken","base":3,"mult":30,"tier":0,"d":100},{"label":"Dbl.Atk","base":1,"mult":1,"tier":0,"mb":7},{"label":"Dbl.Atk. Crit.hit rate","base":1,"mult":1,"tier":0,"mb":7},{"label":"Drain/Aspir Potency","base":1,"mult":1,"tier":0},{"label":"Elemental Magic Recast Delay","base":1,"mult":1,"tier":0},{"label":"Elemental Siphon","base":1,"mult":5,"tier":0},{"label":"Enemy crit. hit rate","base":1,"mult":1,"tier":0},{"label":"Enfeebling Magic Recast Delay","base":1,"mult":1,"tier":0},{"label":"Enhances","base":1,"mult":10,"tier":0,"mb":7},{"label":"Enhancing Magic Effect Duration","base":1,"mult":1,"tier":0},{"label":"Enhancing Magic Recast Delay","base":1,"mult":1,"tier":0},{"label":"Enmity","base":1,"mult":1,"tier":0},{"label":"Enspell Dmg","base":1,"mult":1,"tier":0},{"label":"Evasion","base":3,"mult":1,"tier":0},{"label":"Exp. Point +33%","base":33,"mult":1,"tier":0},{"label":"Fast Cast","base":1,"mult":1,"tier":0,"mb":9},{"label":"Gilfinder","base":1,"mult":1,"tier":0},{"label":"HP","base":1,"mult":4,"tier":0},{"label":"HP MP","base":1,"mult":2,"tier":0},{"label":"HP recovered while healing","base":1,"mult":4,"tier":0,"mb":15},{"label":"Haste","base":1,"mult":2,"tier":0,"d":10},{"label":"Healing Magic Recast Delay","base":1,"mult":1,"tier":0},{"label":"Helix Damage","base":1,"mult":15,"tier":0,"mb":7},{"label":"Helix Effect Duration","base":1,"mult":1,"tier":0},{"label":"INT","base":1,"mult":1,"tier":0},{"label":"Immunobreak Chance+","base":1,"mult":1,"tier":0},{"label":"Indi Effect Duration","base":1,"mult":1,"tier":0},{"label":"Kick Attacks Rate or Damage","base":1,"mult":1,"tier":0},{"label":"MND","base":1,"mult":1,"tier":0},{"label":"MP","base":1,"mult":4,"tier":0},{"label":"MP recovered while healing","base":1,"mult":4,"tier":0,"mb":15},{"label":"Mag. Acc","base":1,"mult":2,"tier":0},{"label":"Mag. Acc. Mag.Atk.Bns","base":1,"mult":2,"tier":0},{"label":"Mag. Acc./Mag. Dmg","base":1,"mult":1,"tier":0},{"label":"Mag. Evasion","base":3,"mult":1,"tier":0},{"label":"Mag. crit. hit dmg","base":1,"mult":1,"tier":0},{"label":"Mag.Atk.Bns","base":1,"mult":1,"tier":0,"mb":14},{"label":"Mag.Def.Bns","base":1,"mult":1,"tier":0},{"label":"Magic Damage","base":1,"mult":1,"tier":0},{"label":"Magic Damage Taken","base":3,"mult":30,"tier":0,"d":100},{"label":"Magic burst dmg","base":1,"mult":1,"tier":0,"mb":9},{"label":"Magic crit. hit rate","base":1,"mult":1,"tier":0},{"label":"Magic dmg. taken","base":3,"mult":30,"tier":0,"d":100},{"label":"Magic skill","base":1,"mult":1,"tier":0},{"label":"Martial Arts","base":1,"mult":1,"tier":0},{"label":"Meditate Effect Duration","base":1,"mult":1,"tier":0},{"label":"Melee skill","base":1,"mult":1,"tier":0},{"label":"Ninja tool expertise","base":1,"mult":1,"tier":0},{"label":"Occ. inc. resist to stat ailments","base":1,"mult":1,"tier":0},{"label":"Occ. quickens spellcasting","base":1,"mult":1,"tier":0,"mb":9},{"label":"Occult Acumen","base":1,"mult":1,"tier":0},{"label":"Parrying Skill","base":1,"mult":1,"tier":0},{"label":"Parrying rate","base":1,"mult":1,"tier":0},{"label":"Pet Acc R.Acc Atk. R.Atk","base":1,"mult":1,"tier":0},{"label":"Pet DEF","base":1,"mult":1,"tier":0},{"label":"Pet Dbl.Atk. Crit.hit rate","base":1,"mult":1,"tier":0},{"label":"Pet Enemy crit. hit rate","base":1,"mult":1,"tier":0},{"label":"Pet Enmity","base":1,"mult":1,"tier":0},{"label":"Pet Evasion","base":1,"mult":1,"tier":0},{"label":"Pet Haste","base":1,"mult":2,"tier":0,"d":10},{"label":"Pet Mag. Evasion","base":1,"mult":1,"tier":0},{"label":"Pet Mag.Acc. Mag.Atk.Bns","base":1,"mult":1,"tier":0},{"label":"Pet Mag.Def.Bns","base":1,"mult":1,"tier":0},{"label":"Pet Magic Damage","base":1,"mult":1,"tier":0},{"label":"Pet Magic Dmg. Taken","base":3,"mult":30,"tier":0,"d":100},{"label":"Pet Phy. Dmg. Taken","base":3,"mult":30,"tier":0,"d":100},{"label":"Pet Regen","base":1,"mult":4,"tier":0},{"label":"Pet STR DEX VIT","base":1,"mult":1,"tier":0},{"label":"Pet Store TP","base":1,"mult":1,"tier":0},{"label":"Pet Subtle Blow","base":1,"mult":1,"tier":0},{"label":"Pet TP Bonus","base":20,"mult":1,"tier":0},{"label":"Phalanx Received","base":1,"mult":1,"tier":0},{"label":"Phantom Roll ability delay","base":1,"mult":1,"tier":0},{"label":"Phantom Roll effect","base":1,"mult":1,"tier":0,"mb":5},{"label":"Phys. dmg. taken","base":3,"mult":30,"tier":0,"d":100},{"label":"Physical Damage Taken","base":3,"mult":30,"tier":0,"d":100},{"label":"Potency of Cure received","base":1,"mult":1,"tier":0},{"label":"Quadruple Attack","base":1,"mult":1,"tier":0,"mb":5},{"label":"Quick Draw ability delay","base":1,"mult":1,"tier":0},{"label":"Ranged skill","base":1,"mult":1,"tier":0},{"label":"Rapid Shot","base":1,"mult":1,"tier":0},{"label":"Recycle","base":1,"mult":1,"tier":0},{"label":"Refresh","base":1,"mult":2,"tier":0,"mb":5},{"label":"Regen","base":1,"mult":4,"tier":0,"mb":5},{"label":"Regen Potency","base":1,"mult":1,"tier":0},{"label":"Repair potency","base":1,"mult":1,"tier":0},{"label":"Resist Charm","base":1,"mult":1,"tier":0},{"label":"Resist Slow","base":1,"mult":1,"tier":0},{"label":"Reverse Flourish","base":1,"mult":1,"tier":0},{"label":"Rng.Acc. Rng.Atk","base":1,"mult":1,"tier":0},{"label":"Rng.Accuracy","base":1,"mult":2,"tier":0},{"label":"Rng.Attack","base":1,"mult":2,"tier":0},{"label":"STR","base":1,"mult":1,"tier":0},{"label":"Save TP","base":10,"mult":1,"tier":0},{"label":"Shield Mastery","base":1,"mult":1,"tier":0},{"label":"Shield skill","base":1,"mult":1,"tier":0},{"label":"Sic and Ready ability delay","base":1,"mult":1,"tier":0},{"label":"Sklchn.dmg","base":1,"mult":100,"tier":0,"d":100,"mb":9},{"label":"Snapshot","base":1,"mult":1,"tier":0},{"label":"Song recast delay","base":1,"mult":1,"tier":0},{"label":"Song spellcasting time","base":1,"mult":1,"tier":0},{"label":"Spell Interruption Rate Down","base":2,"mult":1,"tier":0},{"label":"Spikes Dmg","base":1,"mult":1,"tier":0},{"label":"Store TP","base":1,"mult":1,"tier":0,"mb":14},{"label":"Store TP Subtle Blow","base":1,"mult":1,"tier":0,"mb":14},{"label":"Subtle Blow","base":1,"mult":1,"tier":0,"mb":14},{"label":"TP Bonus","base":1,"mult":4,"tier":0},{"label":"Treasure Hunter","base":1,"mult":1,"tier":0,"mb":0,"tv":1},{"label":"Triple Atk","base":1,"mult":1,"tier":0,"mb":5},{"label":"VIT","base":1,"mult":1,"tier":0},{"label":"Waltz TP cost","base":1,"mult":1,"tier":0},{"label":"Waltz ability delay","base":1,"mult":1,"tier":0},{"label":"Waltz potency","base":1,"mult":1,"tier":0},{"label":"Weapon Skill Acc","base":1,"mult":1,"tier":0},{"label":"Weapon skill damage","base":1,"mult":1,"tier":0,"mb":9},{"label":"Zanshin","base":1,"mult":1,"tier":0}];</script>
<!-- DOCGEN:END id="augment-calc-data" -->

<script>
(function(){
const AUGMENTS=window._augCalcData||[];
// 2026-06-30 TIER REVAMP: mirror TIER_SLICES / TIER_GATES / critChance from
// modules/custom/lua/Augment_Moogle.lua + augment_sage_catalog.lua.
const TIER_SLICES=[[0,5],[6,11],[12,17],[18,24],[25,31]];
const TIER_UNLOCKS=[
  'slay your first 10 custom NMs',
  'Hunting League Rank 5',
  'Voidspire floor 10 + all Game Master waves',
  'Dynamis - Divergence city clear',
  "Maat's Echo (!maat)"
];
const CRIT_CHANCE=[0.05,0.10,0.15,0.20,0.25,0.30];
const RANK_NAMES=['0 — Unranked','1 — Initiate','2 — Adept','3 — Magus','4 — Sage','5 — Archon'];
const MAX_SLOTS=5;

let selAug=AUGMENTS.find(a=>a.label==='HP')||AUGMENTS[0];
let tier=1,slots=5,rank=0,affinity=false,crit=false;

// Roll model per slot: floor = band.min + rank (capped at band.max);
// uniform roll floor..max; affinity = roll twice keep better; crit = band max.
function rollStats(t,r,aff,cr){
  const band=TIER_SLICES[t-1];
  const lo=Math.min(band[0]+r,band[1]);
  const hi=band[1];
  if(cr)return{min:hi,avg:hi,max:hi,lo:lo,hi:hi};
  const n=hi-lo+1;
  let avg=0;
  for(let v=lo;v<=hi;v++){
    const k=v-lo+1;
    const p=aff?((k*k-(k-1)*(k-1))/(n*n)):(1/n);  // advantage = max of two uniforms
    avg+=v*p;
  }
  return{min:lo,avg:avg,max:hi,lo:lo,hi:hi};
}
// Mirror Augment_Moogle.lua: the raw 0-31 roll is SCALED into the augment's
// [0, maxBoost] range (mb, default 31 = uncapped) so each tier is a distinct
// step, then value = floor((base + scaled) * mult / disp + 0.5).
function perSlotVal(aug,roll){
  if(aug.tv)return aug.tv*tier; // tier-fixed (Treasure Hunter, All songs): value = tv x your Augment Tier, no roll
  const mb=(aug.mb==null?31:aug.mb);
  const scaled=Math.floor(roll*mb/31+0.5);
  const m=(aug.mult&&aug.mult>1)?aug.mult:1;
  const d=(aug.d&&aug.d>1)?aug.d:1;
  return Math.floor((aug.base+scaled)*m/d+0.5);
}

function render(){
  const rs=rollStats(tier,rank,affinity,crit);
  const effSlots=selAug.tv?1:slots; // tier-fixed augments take a single catalyst
  const pMin=perSlotVal(selAug,rs.min);
  const pAvg=perSlotVal(selAug,rs.avg);
  const pMax=perSlotVal(selAug,rs.max);
  const tMin=pMin*effSlots,tAvg=Math.round(pAvg*effSlots),tMax=pMax*effSlots;
  const maxTotal=selAug.tv?(selAug.tv*TIER_SLICES.length):perSlotVal(selAug,31)*MAX_SLOTS;
  const pct=maxTotal>0?Math.round((pAvg*effSlots/maxTotal)*100):0;

  document.getElementById('out-big').textContent='+'+tMin+' – +'+tMax;
  document.getElementById('out-sub').textContent=
    selAug.label+' — '+(selAug.tv
      ?'single catalyst (tier-fixed), Tier '+tier
      :effSlots+' slot'+(effSlots>1?'s':'')+', Tier '+tier+', rank '+rank+
       (affinity?', affinity (best of 2 rolls)':'')+(crit?', CRIT (perfect)':''))+
    ' — expected +'+tAvg;
  document.getElementById('out-bar').style.width=Math.min(100,pct)+'%';
  document.getElementById('out-per-slot').textContent='+'+pMin+' – +'+pMax;
  document.getElementById('out-boost').textContent=selAug.tv?('tier-fixed: +'+pMax):(rs.lo+'–'+rs.hi+' of 31');
  document.getElementById('out-pct').textContent=pct+'%';
  document.getElementById('out-max-lbl').textContent=selAug.tv?'Max Possible (T5)':'Max Possible (\xd7'+MAX_SLOTS+')';
  document.getElementById('out-max').textContent='+'+maxTotal;

  document.getElementById('tier-hint').textContent=
    'T'+tier+' unlock: '+TIER_UNLOCKS[tier-1];
  document.getElementById('crit-hint').textContent=
    Math.round(CRIT_CHANCE[rank]*100)+'% chance at rank '+rank+" — Maat's Cap guarantees";
}

// Build augment dropdown
(function(){
  const sel=document.getElementById('aug-select');
  // dedupe labels
  const seen=new Set();
  AUGMENTS.forEach((a,i)=>{
    if(seen.has(a.label))return;
    seen.add(a.label);
    const opt=document.createElement('option');
    opt.value=i;
    opt.textContent=a.label;
    if(a.label===selAug.label)opt.selected=true;
    sel.appendChild(opt);
  });
  sel.addEventListener('change',()=>{
    selAug=AUGMENTS[parseInt(sel.value,10)];
    render();
  });
})();

// Build tier buttons
(function(){
  const row=document.getElementById('tier-row');
  for(let t=1;t<=5;t++){
    const btn=document.createElement('button');
    btn.className='aug-btn'+(t===tier?' active':'');
    btn.textContent='T'+t+' ('+TIER_SLICES[t-1][0]+'–'+TIER_SLICES[t-1][1]+')';
    btn.addEventListener('click',()=>{
      tier=t;
      row.querySelectorAll('.aug-btn').forEach((b,i)=>b.classList.toggle('active',i+1===t));
      render();
    });
    row.appendChild(btn);
  }
})();

// Build slot buttons
(function(){
  const row=document.getElementById('slots-row');
  for(let s=1;s<=MAX_SLOTS;s++){
    const btn=document.createElement('button');
    btn.className='aug-btn'+(s===slots?' active':'');
    btn.textContent='\xd7'+s;
    btn.addEventListener('click',()=>{
      slots=s;
      row.querySelectorAll('.aug-btn').forEach((b,i)=>b.classList.toggle('active',i+1===s));
      render();
    });
    row.appendChild(btn);
  }
})();

// Build rank buttons
(function(){
  const row=document.getElementById('rank-row');
  RANK_NAMES.forEach((name,r)=>{
    const btn=document.createElement('button');
    btn.className='aug-btn'+(r===rank?' active':'');
    btn.textContent=name;
    btn.addEventListener('click',()=>{
      rank=r;
      row.querySelectorAll('.aug-btn').forEach((b,i)=>b.classList.toggle('active',i===r));
      render();
    });
    row.appendChild(btn);
  });
})();

// Toggles
document.getElementById('tog-affinity').addEventListener('change',function(){
  affinity=this.checked;
  document.getElementById('tog-affinity-text').textContent=affinity?'Yes':'No';
  render();
});
document.getElementById('tog-crit').addEventListener('change',function(){
  crit=this.checked;
  document.getElementById('tog-crit-text').textContent=crit?'Yes':'No';
  render();
});

render();
})();
</script>

---

<!-- DOCGEN:BEGIN id="last-updated" -->
<!-- content-hash: 9342efef1527 -->
_Last updated: 2026-07-11 21:20 PDT_
<!-- DOCGEN:END id="last-updated" -->
