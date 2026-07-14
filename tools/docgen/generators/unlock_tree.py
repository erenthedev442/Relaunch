"""unlock_tree — renders the Content Unlock Tree diagram from live catalogs.

Owner requirement (2026-07-05): getting-started/unlock-tree.md must stay 100%
connected to the content, like progression-map and systems-map. The page is an
interactive canvas dependency graph; the *layout* (node positions, ids, edge
topology, colours) is hand-authored diagram structure and lives here as data,
but every NUMBER, COUNT, COST and GATE on it is parsed live from:

  scripts/commands/hunt.lua                       hub zone
  modules/custom/lua/new_char_starter_marks.lua   STARTER_MARKS
  modules/custom/lua/weekly_hunts_catalog.lua     all-cleared sweep bonus
  modules/custom/lua/hunting_league_catalog.lua   rank names / unlockCost / pay
  modules/custom/lua/colosseum_catalog.lua        winBase + dailyWinCap
  modules/custom/lua/gauntlet_catalog.lua         final-clear gil/pp/infamy + levels
  modules/custom/lua/endless_tower.lua            MAX_FLOOR
  modules/custom/lua/voidwatch_catalog.lua        START_STONES / MAX_STONES
  modules/custom/lua/dungeon_catalog.lua          dungeon count
  modules/custom/lua/augment_affinity_catalog.lua count + reg gate
  modules/custom/lua/affinity_nm_autopop.lua      RESPAWN_SECONDS
  modules/custom/lua/AbysseaMarks.lua             per-tier pop cost + infamy
  modules/custom/lua/htbf_catalog.lua             gem price range
  modules/custom/lua/augment_sage_catalog.lua     Sage rank gates
  modules/custom/lua/prestige_catalog.lua         unlockTier + cost band
  modules/custom/lua/job_rebirth_catalog.lua      jpRequired
  modules/custom/lua/PrimeArmory_NPC.lua          trials / forms / GIL_COST
  modules/custom/lua/hunters_guild_catalog.lua    guild count / ranks / max amp
  modules/custom/lua/raid_catalog.lua             Star-Devourer weekly marks/infamy
  modules/custom/lua/Voidspire.lua                presence (endless wave gauntlet)

Content nodes are PRESENCE-GATED: a node (and any edge touching it) renders only
while its module exists in the live tree, so a system a given branch doesn't ship
— e.g. a raid or event pulled from one server but not the other — simply isn't on
the map. The rendering JS already skips edges whose endpoints are missing.

FAIL-CLOSED: essential parses that come back empty raise; generate.py logs it
and the existing page is left intact.
"""

from __future__ import annotations

import json
import re
from collections import Counter
from pathlib import Path

from tools.docgen._paths import resolve_source
from tools.docgen._markers import write_between_markers


def _read(repo_root: Path, rel: str) -> str:
    src = resolve_source(repo_root, rel)
    if src is None:
        raise RuntimeError(f"unlock_tree: source not found: {rel}")
    return src.read_text(encoding="utf-8", errors="replace")


def _read_opt(repo_root: Path, rel: str) -> str | None:
    src = resolve_source(repo_root, rel, required=False)
    return None if src is None else src.read_text(encoding="utf-8", errors="replace")


def _have(repo_root: Path, rel: str) -> bool:
    return resolve_source(repo_root, rel, required=False) is not None


def _num(pattern: str, text: str, what: str) -> int:
    m = re.search(pattern, text)
    if not m:
        raise RuntimeError(f"unlock_tree: could not parse {what}")
    return int(m.group(1))


def _fmt(n: int) -> str:
    return f"{n:,}"


def _gil(n: int) -> str:
    if n >= 1_000_000_000 and n % 1_000_000_000 == 0:
        return f"{n // 1_000_000_000}B gil"
    if n >= 1_000_000 and n % 1_000_000 == 0:
        return f"{n // 1_000_000}M gil"
    return f"{_fmt(n)} gil"


# ---------------------------------------------------------------- parsers


def _parse_hl_tiers(text: str) -> list[dict]:
    blocks = re.split(r"\n\s*\{\s*\n?\s*tier\s*=\s*", text)[1:]
    tiers = []
    for blk in blocks:
        tier_no = int(re.match(r"(\d+)", blk).group(1))
        name_m = re.search(r"name\s*=\s*'(Rank [^']+)'", blk)
        cost_m = re.search(r"unlockCost\s*=\s*(\d+)", blk)
        pts = re.findall(r"label\s*=\s*'([^']+)',\s*points\s*=\s*(\d+)", blk)
        if cost_m is None or not pts:
            continue
        counts = Counter(int(p) for _, p in pts)
        tiers.append({
            "tier": tier_no,
            "name": name_m.group(1) if name_m else f"Rank {tier_no}",
            "short": (name_m.group(1).split(" - ")[-1] if name_m else f"Rank {tier_no}"),
            "cost": int(cost_m.group(1)),
            "pay": counts.most_common(1)[0][0],
            "max_pay": max(int(p) for _, p in pts),
        })
    tiers.sort(key=lambda t: t["tier"])
    if len(tiers) != 5:
        raise RuntimeError(f"unlock_tree: expected 5 HL tiers, parsed {len(tiers)}")
    return tiers


def _parse_tier_gates(text: str) -> list[tuple[int, str]]:
    gates = [(int(t), u) for t, _q, u in
             re.findall(r"tier\s*=\s*(\d+),\s*unlock\s*=\s*(['\"])(.*?)\2", text, flags=re.S)]
    gates.sort()
    if len(gates) < 4:
        raise RuntimeError(f"unlock_tree: augment TIER_GATES parse failed ({len(gates)})")
    return gates


def _parse_hub_zone(text: str) -> str:
    m = re.search(r"Warps you to the Hunting League hub in (.+?)\.", text)
    if m:
        return m.group(1).strip()
    m = re.search(r"xi\.zone\.(\w+)", text)
    if not m:
        raise RuntimeError("unlock_tree: hunt.lua hub zone parse failed")
    return m.group(1).replace("_", " ").title()


def _parse_sage_ranks(text: str) -> dict[int, dict]:
    """rank -> {title, hlRank, prestigeLevel, rebirths, gauntletClears}."""
    out: dict[int, dict] = {}
    for blk in re.findall(r"\{(.*?)\}", text, flags=re.S):
        rank_m = re.search(r"rank\s*=\s*(\d+)", blk)
        title_m = re.search(r"title\s*=\s*'([^']+)'", blk)
        if not rank_m or not title_m:
            continue
        d = {"title": title_m.group(1)}
        for key in ("hlRank", "prestigeLevel", "rebirths", "gauntletClears"):
            km = re.search(rf"{key}\s*=\s*(\d+)", blk)
            if km:
                d[key] = int(km.group(1))
        out[int(rank_m.group(1))] = d
    if len(out) < 4:
        raise RuntimeError(f"unlock_tree: sage rank parse failed ({len(out)})")
    return out


def _parse_prime(text: str) -> tuple[int, int, int]:
    trials = re.findall(r"\{\s*var\s*=\s*'PW_Trial\d+_Done'", text)
    wsec = text.split("local WEAPONS", 1)[-1].split("\n}", 1)[0]
    forms = re.findall(r"\{\s*id\s*=\s*\d+,\s*name\s*=\s*'[^']+'", wsec)
    gil = _num(r"GIL_COST\s*=\s*(\d+)", text, "prime GIL_COST")
    if len(trials) < 4 or len(forms) < 8:
        raise RuntimeError(f"unlock_tree: prime parse failed (trials={len(trials)} forms={len(forms)})")
    return len(trials), len(forms), gil


# ---------------------------------------------------------------- render template

# The canvas rendering JS is verbatim from the hand-authored page. Only the
# `nodes` and `edges` data arrays are generated (the __NODES__ / __EDGES__
# placeholders below). Keep this a plain raw string — NOT an f-string — so the
# hundreds of literal braces in the drawing code need no escaping.
_RENDER_JS = r"""<script>
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

const nodes=__NODES__;

const edges=__EDGES__;

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
</script>"""


def _desc(title: str, body: str) -> str:
    return f"<strong>{title}</strong>{body}"


def generate(repo_root: Path, docs_dir: Path) -> None:
    # ---- essential numbers (fail closed) ------------------------------
    starter = _num(r"STARTER_MARKS\s*=\s*(\d+)",
                   _read(repo_root, "modules/custom/lua/new_char_starter_marks.lua"), "STARTER_MARKS")
    tiers = _parse_hl_tiers(_read(repo_root, "modules/custom/lua/hunting_league_catalog.lua"))
    gates = _parse_tier_gates(_read(repo_root, "modules/custom/lua/Augment_Moogle.lua"))
    hub = _parse_hub_zone(_read(repo_root, "scripts/commands/hunt.lua"))
    sage = _parse_sage_ranks(_read(repo_root, "modules/custom/lua/augment_sage_catalog.lua"))
    prestige_unlock = _num(r"unlockTier\s*=\s*(\d+)",
                           _read(repo_root, "modules/custom/lua/prestige_catalog.lua"), "prestige unlockTier")
    ptxt = _read(repo_root, "modules/custom/lua/prestige_catalog.lua")
    pcost_base = _num(r"markCostBase\s*=\s*(\d+)", ptxt, "prestige markCostBase")
    pcost_cap = _num(r"markCostCap\s*=\s*(\d+)", ptxt, "prestige markCostCap")
    jp_required = _num(r"jpRequired\s*=\s*(\d+)",
                       _read(repo_root, "modules/custom/lua/job_rebirth_catalog.lua"), "jpRequired")
    n_trials, n_forms, prime_gil = _parse_prime(_read(repo_root, "modules/custom/lua/PrimeArmory_NPC.lua"))

    # ---- optional numbers (node renders only if its module is present) --
    weekly_sweep = None
    if (t := _read_opt(repo_root, "modules/custom/lua/weekly_hunts_catalog.lua")):
        m = re.search(r"catalog\.allClearedReward\s*=\s*\{[^}]*?amount\s*=\s*(\d+)", t)
        weekly_sweep = int(m.group(1)) if m else None

    colo_win = colo_cap = None
    if (t := _read_opt(repo_root, "modules/custom/lua/colosseum_catalog.lua")):
        wm = re.search(r"winBase\s*=\s*(\d+)", t)
        cm = re.search(r"dailyWinCap\s*=\s*(\d+)", t)
        colo_win = int(wm.group(1)) if wm else None
        colo_cap = int(cm.group(1)) if cm else None

    gaunt = None
    if (t := _read_opt(repo_root, "modules/custom/lua/gauntlet_catalog.lua")):
        rm = re.search(r"gil\s*=\s*(\d+)[\s\S]{0,160}?pp\s*=\s*(\d+)[\s\S]{0,160}?infamy\s*=\s*(\d+)", t)
        lm = re.search(r"(\d+)-level", t) or re.search(r"level\s+(\d+)\s+NM kill", t)
        if rm:
            gaunt = {
                "gil": int(rm.group(1)), "pp": int(rm.group(2)), "infamy": int(rm.group(3)),
                "levels": int(lm.group(1)) if lm else 10,
            }

    tower_floors = None
    if (t := _read_opt(repo_root, "modules/custom/lua/endless_tower.lua")):
        m = re.search(r"MAX_FLOOR\s*=\s*(\d+)", t)
        tower_floors = int(m.group(1)) if m else None

    vw_start = vw_cap = None
    if (t := _read_opt(repo_root, "modules/custom/lua/voidwatch_catalog.lua")):
        sm = re.search(r"START_STONES\s*=\s*(\d+)", t)
        cm = re.search(r"MAX_STONES\s*=\s*(\d+)", t)
        vw_start = int(sm.group(1)) if sm else None
        vw_cap = int(cm.group(1)) if cm else None

    dungeon_count = None
    if (t := _read_opt(repo_root, "modules/custom/lua/dungeon_catalog.lua")):
        dungeon_count = len(re.findall(r"zoneName\s*=", t)) or None

    aff = None
    if (t := _read_opt(repo_root, "modules/custom/lua/augment_affinity_catalog.lua")):
        count = len(re.findall(r"^\s*\{\s*cat\s*=\s*\d+", t, flags=re.M))
        rank_m = re.search(r"affinityRankReq\s*=\s*(\d+)", t)
        cost_m = re.search(r"affinityMarkCost\s*=\s*(\d+)", t)
        if count:
            aff = {"count": count,
                   "rank": int(rank_m.group(1)) if rank_m else None,
                   "cost": int(cost_m.group(1)) if cost_m else None}
    aff_respawn = None
    if (t := _read_opt(repo_root, "modules/custom/lua/affinity_nm_autopop.lua")):
        m = re.search(r"RESPAWN_SECONDS\s*=\s*(\d+)", t)
        aff_respawn = int(m.group(1)) if m else None

    abyssea = None
    if (t := _read_opt(repo_root, "modules/custom/lua/AbysseaMarks.lua")):
        rows = re.findall(r"cost\s*=\s*(\d+),\s*infamy\s*=\s*(\d+)", t)
        if rows:
            costs = sorted({int(c) for c, _ in rows})
            inf = sorted({int(i) for _, i in rows})
            abyssea = {"costs": costs, "infamy": inf}

    htbf = None
    if (t := _read_opt(repo_root, "modules/custom/lua/htbf_catalog.lua")):
        gems = [int(x) for x in re.findall(r"PHANTOM_GEM\]\s*=\s*(\d+)", t)]
        if gems:
            htbf = {"min": min(gems), "max": max(gems)}

    hguild = None
    if (t := _read_opt(repo_root, "modules/custom/lua/hunters_guild_catalog.lua")):
        amps = re.findall(r"amplifier\s*=\s*([\d.]+)", t)
        guilds = re.findall(r"key\s*=\s*'(af|relic|empy|hl)'", t)
        if amps and guilds:
            hguild = {"guilds": len(set(guilds)), "ranks": len(amps),
                      "max_amp": max(float(a) for a in amps)}

    raid = None
    if (t := _read_opt(repo_root, "modules/custom/lua/raid_catalog.lua")):
        wm = re.search(r"weeklyMarks\s*=\s*(\d+)", t)
        wi = re.search(r"weeklyInfamy\s*=\s*(\d+)", t)
        if wm and wi:
            raid = {"marks": int(wm.group(1)), "infamy": int(wi.group(1))}

    # ---- shared derived text -------------------------------------------
    tmap = {x["tier"]: x for x in tiers}
    pays = [x["pay"] for x in tiers]
    r5 = tmap[5]
    cost_str = " → ".join(_fmt(x["cost"]) for x in tiers if x["cost"] > 0)

    def sage_gate(rank: int) -> str:
        d = sage.get(rank, {})
        bits = []
        if d.get("hlRank"):
            bits.append(f"HL Rank {d['hlRank']}")
        if d.get("prestigeLevel"):
            bits.append(f"Prestige {d['prestigeLevel']}")
        if d.get("rebirths"):
            bits.append(f"{d['rebirths']} rebirth{'s' if d['rebirths'] != 1 else ''}")
        if d.get("gauntletClears"):
            bits.append("Gauntlet clear")
        return " + ".join(bits) if bits else "open"

    def n(rel: str) -> bool:
        return _have(repo_root, rel)

    # ---- nodes ---------------------------------------------------------
    # Each entry: (id, x, y, lbl, type, desc, need_module_or_None). Layout
    # (x/y/type/id) is diagram structure; every number in lbl/desc is live.
    NODES = [
        ("start", 70, 45, "New Character", "start",
         _desc("New Character",
               f"Starter setup + <strong>{starter} Hunt Marks</strong>. Everything on this map branches from here."),
         None),
        ("boards", 70, 140, "Daily & Weekly Boards", "always",
         _desc("Daily & Weekly Boards",
               f"Daily: Hunt Marks + Gil objectives. Weekly: sweep all objectives → "
               f"+{_fmt(weekly_sweep)} mark meta-bonus." if weekly_sweep else
               "Daily and weekly objective boards paying Hunt Marks + Gil."),
         "modules/custom/lua/weekly_hunts_catalog.lua"),
        ("augmog", 70, 215, "Augment Moogle", "always",
         _desc("Augment Moogle",
               "Random stat augments on any gear. No gate. A registered affinity makes every "
               "matching roll happen twice and keep the better result."),
         "modules/custom/lua/Augment_Moogle.lua"),
        ("coloss", 70, 290, "Colosseum", "always",
         _desc("Colosseum",
               f"Async duels vs player replicas. {colo_win} Hunt Marks per win"
               + (f", {colo_cap} wins/day cap." if colo_cap else ".")
               if colo_win else "Async arena duels for Hunt Marks."),
         "modules/custom/lua/colosseum_catalog.lua"),
        ("gauntlet", 70, 365,
         f"Gauntlet ({gaunt['levels']} levels)" if gaunt else "The Gauntlet", "always",
         _desc("The Gauntlet",
               f"Solo NM climb, HP doubles per level. Level {gaunt['levels']} clear: "
               f"{_gil(gaunt['gil'])} + {gaunt['infamy']} Infamy + {gaunt['pp']} PP + Prime Armory flag."
               if gaunt else "Solo NM climb; the final clear flags the Prime Armory."),
         "modules/custom/lua/gauntlet_catalog.lua"),
        ("apex", 70, 440, "Apex Trials", "always",
         _desc("Apex Trials", "Infinite scaling post-cap NMs. Infamy + Paragon Points per kill."),
         "modules/custom/lua/ApexTrials.lua"),
        ("etower", 70, 515, "Endless Tower", "always",
         _desc("Endless Tower",
               f"{tower_floors} floors solo, trusts disabled. Floor {tower_floors} clear sets the "
               "Prime Armory unlock flag." if tower_floors else
               "Solo floor-climb; the top-floor clear flags the Prime Armory."),
         "modules/custom/lua/endless_tower.lua"),
        ("voidwatch", 70, 590, "Voidwatch", "always",
         _desc("Voidwatch",
               f"{vw_start} free Voidstones on first visit, 1/hr regen, cap {vw_cap}. Open Planar "
               "Rifts → Voidwalker NM → Pyxis loot." if (vw_start and vw_cap) else
               "Open Planar Rifts with Voidstones → Voidwalker NM → Pyxis loot."),
         "modules/custom/lua/voidwatch_catalog.lua"),
        ("dungeons", 70, 665,
         f"Dungeons ({dungeon_count})" if dungeon_count else "Dungeons", "always",
         _desc("Dungeons",
               f"{dungeon_count} custom instanced zones, no rank gate, curated boss drops."
               if dungeon_count else "Custom instanced zones with curated boss drops."),
         "modules/custom/lua/dungeon_catalog.lua"),
        ("affnm", 70, 740,
         f"Affinity NMs ({aff['count']})" if aff else "Affinity NMs", "always",
         _desc("Affinity NMs",
               f"{aff['count']} classic HNMs permanently spawned"
               + (f", {aff_respawn}s respawn" if aff_respawn else "")
               + ". Trophy drops to the kill-blow player." if aff else
               "Always-up HNMs; the trophy drops to the kill-blow player."),
         "modules/custom/lua/augment_affinity_catalog.lua"),
        ("sigils", 70, 815, "Mastery Sigils", "curr",
         _desc("Mastery Sigils",
               "Granted by !buff (the zone's regional buff). Spent at the Mastery Sage for Spell & "
               "Skill Mastery."),
         "modules/custom/lua/SpellSkillMastery.lua"),
        ("lv99", 245, 45, "Level 99", "mile",
         _desc("Level 99", "Reach level 99 to unlock Hunting League Rank I."),
         None),
        ("mastery", 245, 815, "Spell & Skill Mastery", "vert",
         _desc("Spell & Skill Mastery",
               "Mastery Sage at !hub. Spend Mastery Sigils to empower weapon skills and spells "
               "beyond their normal caps."),
         "modules/custom/lua/SpellSkillMastery.lua"),
        ("rank1", 420, 45, f"HL {tmap[1]['name'].replace(' - ', ' — ')}", "rank",
         _desc(tmap[1]["name"],
               f"Starting HL rank. Pop NMs from Hunt: Spawner. {pays[0]} Hunt Marks per kill."),
         None),
        ("marks", 420, 150, "Hunt Marks", "curr",
         _desc("Hunt Marks",
               f"Primary currency. {pays[0]}→{pays[4]} per kill by rank. Buy seals, register "
               "affinities, unlock ranks."),
         None),
        ("seals", 420, 255, "Seals (Bronze/Sv/Gd)", "curr",
         _desc("Seals",
               "Bought with Hunt Marks at the Seals Vendor. Bronze/Silver/Gold tier determines "
               "the gear tier available."),
         None),
        ("gear", 420, 360, "Seal Vendors (Gear)", "reward",
         _desc("Seal Vendors",
               f"Armor, Weapons, and Accessories vendors in {hub}. Seal tier gates the gear tier."),
         None),
        ("rank2", 600, 45, f"HL {tmap[2]['name'].replace(' - ', ' — ')}", "rank",
         _desc(tmap[2]["name"],
               f"Unlock: {_fmt(tmap[2]['cost'])} total marks spent. {pays[1]} marks/kill."),
         None),
        ("rank3", 780, 45, f"HL {tmap[3]['name'].replace(' - ', ' — ')}", "rank",
         _desc(tmap[3]["name"],
               f"Unlock: {_fmt(tmap[3]['cost'])} total marks spent. {pays[2]} marks/kill. "
               "Gates: Abyssea, Unity, Augment Sage R2, Affinity Registration."),
         None),
        ("abyssea", 780, 155, "Abyssea NMs", "content",
         _desc("Abyssea NMs",
               f"3 tiers (Visions/Scars/Heroes). Pop cost: {'/'.join(map(str, abyssea['costs']))} "
               f"Hunt Marks. Drops AF/Relic/Empy Marks + Infamy "
               f"({abyssea['infamy'][0]}–{abyssea['infamy'][-1]}/kill)."
               if abyssea else "Spend Hunt Marks to pop Abyssea NMs for AF/Relic/Empy Marks + Infamy."),
         "modules/custom/lua/AbysseaMarks.lua"),
        ("unity", 780, 250, "Unity Concord", "content",
         _desc("Unity Concord", "Wanted NMs across tiers. Produces Accolades for the Unity Shop."),
         "modules/custom/lua/unity_wanted.lua"),
        ("augsage1", 780, 345, "Augment Sage R1–2", "reward",
         _desc("Augment Sage R1–2",
               f"{sage_gate(2)} unlocks Sage Rank 2 ({sage.get(2, {}).get('title', 'Adept')}). "
               "Higher roll floors on all gear."),
         "modules/custom/lua/augment_sage_catalog.lua"),
        ("affreg", 780, 440, "Affinity Registration", "reward",
         _desc("Affinity Registration",
               f"Trophy + HL Rank {aff['rank']} + {_fmt(aff['cost'])} marks. Registers one of "
               f"{aff['count']} stat affinities permanently." if (aff and aff.get("rank") and aff.get("cost"))
               else "Register an NM's affinity trophy at the Augment Sage."),
         "modules/custom/lua/augment_affinity_catalog.lua"),
        ("affmult", 780, 535, "Affinity Reroll", "reward",
         _desc("Affinity Reroll",
               "Per registered affinity: every augment roll in that stat category is rolled twice, "
               "keeping the better result."),
         "modules/custom/lua/augment_affinity_catalog.lua"),
        ("rank4", 960, 45, f"HL {tmap[4]['name'].replace(' - ', ' — ')}", "rank",
         _desc(tmap[4]["name"],
               f"Unlock: {_fmt(tmap[4]['cost'])} total marks spent. {pays[3]} marks/kill. "
               "Opens group boss content."),
         None),
        ("hnm", 960, 155, "HNM Kings / Sky Gods", "content",
         _desc("HNM Kings / Sky Gods",
               "Land kings and Sky Gods. Produce AF/Relic/Empy Marks for the Reforge system."),
         "modules/custom/lua/custom_HNM_system.lua"),
        ("htbf", 960, 250, "HTBF (Phantom Gem)", "content",
         _desc("HTBF",
               (f"3 tiers, Phantom Gem entry ({_fmt(htbf['min'])}–{_fmt(htbf['max'])} gil). "
                "Access gate: **master the entering job (2,100 JP)** AND **register all 11 "
                "NM affinities** at the Augment Sage. Gem is consumed on top.") if htbf else
               ("Retail high-tier battlefields entered with Phantom Gems. Gated on "
                "job mastery + all 11 NM affinities registered.")),
         "modules/custom/lua/htbf_catalog.lua"),
        ("dynamis", 960, 345, "Dynamis – Divergence", "content",
         _desc("Dynamis – Divergence",
               "4 cities × wave battles. Entry toll: **250 Reforge Marks** (any of AF, "
               "Relic, or Empyrean). Drops the +4 Forge materials — Rusted/Black ID "
               "Cards, and a main-job Paragon Card off the Mega-Boss."),
         "modules/custom/lua/Dynamis_Divergence.lua"),
        ("nyzul", 960, 440, "Nyzul Isle", "content",
         _desc("Nyzul Isle",
               "Floor-climb runs. Enter via the Sorrowful Sage at Mhaura (no Assault rank needed). "
               "Nyzul armor rewards."),
         "scripts/zones/Mhaura/npcs/Sorrowful_Sage.lua"),
        ("invasions", 960, 630, "Scheduled Invasions", "content",
         _desc("Scheduled Invasions",
               "Server-wide wave events — watch for the announcement. Produces Infamy per event."),
         "modules/custom/lua/Invasion.lua"),
        ("rfmarks", 960, 725, "AF/Relic/Empy Marks", "curr",
         _desc("AF/Relic/Empy Marks",
               "Produced by Abyssea NMs and HNM Kings. Spent at the Reforge Vendor for "
               "+1/+2/+3 armor."),
         "modules/custom/lua/Reforge_System.lua"),
        ("reforge", 960, 820, "Reforge (+1/+2/+3)", "reward",
         _desc("Reforge Vendor",
               "Upgrades AF, Relic, and Empy armor from base to +1, +2, +3. Spend marks at the "
               "Reforge Vendor in the Reforge hall at !reforged. (+4 is the separate Dynamis-D Forge.)"),
         "modules/custom/lua/Reforge_System.lua"),
        ("plus4forge", 1140, 635, "Divergence +4 Forge", "reward",
         _desc("Divergence +4 Forge",
               "Trade a reforged +3 AF/Relic piece + your job's Paragon Card + Rusted/Black "
               "ID Cards → the +4. AF & Relic only (Empy caps at +3)."),
         "modules/custom/lua/Dynamis_Plus4_Forge.lua"),
        ("rank5", 1140, 45, f"HL {tmap[5]['name'].replace(' - ', ' — ')}", "rank",
         _desc(tmap[5]["name"],
               f"Unlock: {_fmt(r5['cost'])} total marks spent. {pays[4]} marks/kill"
               + (f" (top NM {r5['max_pay']})" if r5["max_pay"] != pays[4] else "")
               + ". Gates the Prestige system."),
         None),
        ("infamy", 1140, 155, "Infamy", "curr",
         _desc("Infamy",
               "Produced by Invasions, Apex Trials"
               + (f", the Gauntlet ({gaunt['infamy']} on full clear)" if gaunt else "")
               + (f", and Abyssea ({abyssea['infamy'][0]}–{abyssea['infamy'][-1]}/kill)." if abyssea else ".")),
         None),
        ("infamyv", 1140, 250, "Infamy Vendor (BiS)", "reward",
         _desc("Infamy Vendor",
               "Best-in-slot gear, relic weapons, instruments. Spend Infamy directly. No rank gate."),
         "modules/custom/lua/infamy_vendor_catalog.lua"),
        ("pp", 1140, 350, "Paragon Points", "curr",
         _desc("Paragon Points",
               "Produced by Apex Trials"
               + (f" and the Gauntlet ({gaunt['pp']} PP on full clear)" if gaunt else "")
               + ". Spent on the Paragon Board."),
         "modules/custom/lua/paragon_catalog.lua"),
        ("parboard", 1140, 445, "Paragon Board", "reward",
         _desc("Paragon Board",
               "Permanent account-wide stat bonuses. Never resets. Bought with Paragon Points."),
         "modules/custom/lua/paragon_catalog.lua"),
        ("accolades", 1140, 540, "Accolades → Unity Shop", "reward",
         _desc("Accolades",
               "Produced by Unity Concord kills. Spent in the Unity Shop for gear and rewards."),
         "modules/custom/lua/unity_wanted.lua"),
        ("prestige", 1300, 45, "Prestige / Ascension", "vert",
         _desc("Prestige / Ascension",
               f"At HL Rank {prestige_unlock} the Altar in Provenance opens. Clear the Nightmare "
               f"Court trial and pay {_fmt(pcost_base)}–{_fmt(pcost_cap)} escalating Hunt Marks to "
               "ascend, banking Ascension Points for permanent, uncapped per-job stat boosts."),
         "modules/custom/lua/prestige_catalog.lua"),
        ("rebirth", 1300, 190, "Job Rebirth", "vert",
         _desc("Job Rebirth",
               f"After Prestige: any job with {_fmt(jp_required)} spent Job Points can rebirth — "
               "re-grind RP for larger permanent per-job stat bonuses."),
         "modules/custom/lua/job_rebirth_catalog.lua"),
        ("augsage2", 1300, 360, "Augment Sage R3–5", "reward",
         _desc("Augment Sage R3–5",
               f"R3: {sage_gate(3)}. R4: {sage_gate(4)}. R5: {sage_gate(5)}."),
         "modules/custom/lua/augment_sage_catalog.lua"),
        ("prime", 1300, 530, "Prime Armory", "vert",
         _desc("Prime Armory",
               "Unlock: Gauntlet full clear OR Endless Tower top-floor clear. "
               f"Complete {n_trials} trials, then forge 1 of {n_forms} named Prime forms "
               f"({_gil(prime_gil)} each)."),
         "modules/custom/lua/PrimeArmory_NPC.lua"),
        # ---- presence-gated systems added 2026-07-10 (reconcile w/ live content) ----
        ("voidspire", 245, 250, "Voidspire", "always",
         _desc("The Voidspire",
               "Endless escalating wave-gauntlet, trusts enabled. A wipe ends the run and "
               "records your deepest floor on the leaderboard. No gate."),
         "modules/custom/lua/Voidspire.lua"),
        ("hguild", 600, 250, "Hunter's Guild", "content",
         _desc("Hunter's Guild",
               f"{hguild['guilds']} guilds, {hguild['ranks']} ranks each. Climb by hunting "
               "classic HNMs across Vana'diel — each rank passively amplifies that guild's "
               f"mark payout, up to +{int(round(hguild['max_amp'] * 100))}% at Grandmaster."
               if hguild else
               "Reputation guilds; ranking up amplifies each mark currency's payout."),
         "modules/custom/lua/hunters_guild_catalog.lua"),
        ("raid", 960, 535, "Star-Devourer (raid)", "content",
         _desc("The Star-Devourer",
               "Weekly multi-phase raid, popped from the Voidgate Sentinel at Escha - Ru'Aun; "
               "anyone present can join. Full weekly clear: "
               f"{_fmt(raid['marks'])} Hunt Marks + {raid['infamy']} Infamy."
               if raid else
               "Weekly multi-phase raid boss at Escha - Ru'Aun; the big payout is once per week."),
         "modules/custom/lua/RaidBoss.lua"),
    ]

    present = {nid for nid, *_rest, need in NODES if need is None or n(need)}
    nodes_out = [
        {"id": nid, "x": x, "y": y, "lbl": lbl, "t": typ, "desc": desc}
        for (nid, x, y, lbl, typ, desc, need) in NODES
        if nid in present
    ]

    # ---- edges (label numbers are live; dropped if either endpoint gone) --
    def gl() -> str:  # gauntlet clear-level label
        return f"L{gaunt['levels']}" if gaunt else "full"

    EDGES = [
        ("start", "lv99", ""),
        ("lv99", "rank1", ""),
        ("rank1", "rank2", f"{_fmt(tmap[2]['cost'])} marks"),
        ("rank2", "rank3", f"{_fmt(tmap[3]['cost'])} marks"),
        ("rank3", "rank4", f"{_fmt(tmap[4]['cost'])} marks"),
        ("rank4", "rank5", f"{_fmt(tmap[5]['cost'])} marks"),
        ("rank5", "prestige", ""),
        ("start", "boards", ""),
        ("start", "augmog", ""),
        ("start", "coloss", ""),
        ("start", "gauntlet", ""),
        ("start", "apex", ""),
        ("start", "etower", ""),
        ("start", "voidwatch", f"{vw_start} free stones" if vw_start else ""),
        ("start", "dungeons", ""),
        ("start", "affnm", ""),
        ("start", "sigils", "!buff"),
        ("rank1", "marks", f"{pays[0]}/kill"),
        ("marks", "seals", "buy"),
        ("seals", "gear", ""),
        ("boards", "marks", "daily bonus"),
        ("coloss", "marks", f"{colo_win}/win" if colo_win else ""),
        ("htbf", "marks", ""),
        ("rank3", "abyssea",
         f"{abyssea['costs'][0]}–{abyssea['costs'][-1]} marks/pop" if abyssea else ""),
        ("rank3", "unity", ""),
        ("rank3", "augsage1", ""),
        ("rank3", "affreg", f"HL {aff['rank']} req." if (aff and aff.get("rank")) else ""),
        ("affnm", "affreg", f"trophy + {_fmt(aff['cost'])}" if (aff and aff.get("cost")) else "trophy"),
        ("marks", "affreg", f"{_fmt(aff['cost'])} marks" if (aff and aff.get("cost")) else ""),
        ("affreg", "affmult", ""),
        ("affmult", "augmog", "reroll on match"),
        ("abyssea", "rfmarks", "AF/Rel/Emp"),
        ("hnm", "rfmarks", ""),
        ("rfmarks", "reforge", ""),
        ("rfmarks", "dynamis", "250 marks"),
        ("dynamis", "plus4forge", "ID cards + P.Card"),
        ("reforge", "plus4forge", "+3 piece"),
        ("rank4", "hnm", ""),
        ("mastery", "htbf", "job mastered"),
        ("affreg", "htbf", "all 11 affinities"),
        ("rank4", "nyzul", ""),
        ("rank4", "invasions", ""),
        ("abyssea", "infamy",
         f"{abyssea['infamy'][0]}–{abyssea['infamy'][-1]}/kill" if abyssea else ""),
        ("gauntlet", "infamy", f"{gaunt['infamy']} on {gl()}" if gaunt else ""),
        ("apex", "infamy", ""),
        ("invasions", "infamy", ""),
        ("infamy", "infamyv", ""),
        ("gauntlet", "pp", f"{gaunt['pp']} on {gl()}" if gaunt else ""),
        ("apex", "pp", ""),
        ("pp", "parboard", ""),
        ("unity", "accolades", ""),
        ("prestige", "rebirth", ""),
        ("rank5", "augsage2", f"HL {prestige_unlock} gate"),
        ("prestige", "augsage2", f"Prestige ≥{sage.get(3, {}).get('prestigeLevel', 5)}"),
        ("rebirth", "augsage2", f"Rebirth ≥{sage.get(3, {}).get('rebirths', 1)}"),
        ("gauntlet", "prime", f"{gl()} clears flag" if gaunt else "clears flag"),
        ("etower", "prime", f"Fl.{tower_floors} clears flag" if tower_floors else "top floor clears flag"),
        ("sigils", "mastery", ""),
        ("start", "voidspire", ""),
        ("hguild", "marks",
         f"+0–{int(round(hguild['max_amp'] * 100))}%" if hguild else "amplifies"),
        ("hguild", "rfmarks",
         f"+0–{int(round(hguild['max_amp'] * 100))}%" if hguild else "amplifies"),
        ("raid", "marks", f"{_fmt(raid['marks'])}/wk" if raid else ""),
        ("raid", "infamy", f"{raid['infamy']}/wk" if raid else ""),
    ]
    edges_out = [
        {"f": f, "t": t, **({"lb": lb} if lb else {})}
        for (f, t, lb) in EDGES
        if f in present and t in present
    ]

    nodes_json = json.dumps(nodes_out, ensure_ascii=False)
    edges_json = json.dumps(edges_out, ensure_ascii=False)
    script = _RENDER_JS.replace("__NODES__", nodes_json).replace("__EDGES__", edges_json)

    # ---- assemble page body -------------------------------------------
    L: list[str] = []
    L.append("Every piece of content on the Relaunch server depends on something else. This "
             "diagram maps those dependencies: click any node to highlight what gates it "
             "(orange) and what it enables (teal).")
    L.append("")
    L.append("Scroll the diagram left–right to see the full progression from Day 1 through "
             "Vertical Progression.")
    L.append("")
    L.append('<div style="position:relative;margin:1.2rem 0">')
    L.append('<div id="utree-wrap" style="overflow:auto;border:1px solid #2a2d4a;'
             'border-radius:6px;background:#090B14">')
    L.append('<canvas id="utc" width="1380" height="910" style="display:block;cursor:default">'
             "</canvas>")
    L.append("</div>")
    L.append('<div id="utip" style="position:absolute;display:none;background:#1a1e38f0;'
             "border:1px solid #3a3e5a;border-radius:5px;padding:7px 11px;font-size:12px;"
             "color:#c8c8e8;pointer-events:none;max-width:230px;line-height:1.55;z-index:50;"
             'box-shadow:0 4px 16px #00000080"></div>')
    L.append("</div>")
    L.append("")
    L.append(script)
    L.append("")
    L.append("---")
    L.append("")
    L.append("## Reading the diagram")
    L.append("")
    L.append("- **Teal arrows** leaving a selected node: systems it **enables**")
    L.append("- **Orange arrows** entering a selected node: systems that **gate** it")
    L.append("- Phase bands (column background shading) show which unlock tier each system sits in")
    L.append("- Nodes with no incoming arrows are available from **Day 1**")
    L.append("")
    L.append("## Key unlock paths")
    L.append("")
    L.append("| If you want… | You need… |")
    L.append("|---|---|")
    L.append(f"| Augment Sage R3–5 | {sage_gate(3)} (R3), escalating to {sage_gate(5)} (R5) |")
    L.append("| Prime Armory | Gauntlet full clear **or** Endless Tower top-floor clear |")
    if aff and aff.get("rank") and aff.get("cost"):
        L.append(f"| Affinity Registration | Affinity NM trophy + HL Rank {aff['rank']} + "
                 f"{_fmt(aff['cost'])} Hunt Marks |")
    if n("modules/custom/lua/Reforge_System.lua"):
        L.append("| Reforge +3 gear | Abyssea NMs / HNM Kings → AF/Relic/Empy marks |")
    if hguild:
        L.append(f"| Faster mark payouts | Rank up the Hunter's Guild — {hguild['guilds']} guilds, "
                 f"hunt classic HNMs, up to +{int(round(hguild['max_amp'] * 100))}% at Grandmaster |")
    if n("modules/custom/lua/Dynamis_Plus4_Forge.lua"):
        L.append("| +4 AF/Relic gear | A reforged **+3** piece + Dynamis-D materials "
                 "(Rusted/Black ID Cards + Paragon Card) at the Divergence Forge |")
    L.append("| Infamy Vendor (BiS) | Accumulate Infamy (Invasions, Apex"
             + (", Gauntlet" if gaunt else "") + ") |")
    if n("modules/custom/lua/paragon_catalog.lua"):
        L.append("| Paragon Board | Paragon Points from Apex Trials"
                 + (" or Gauntlet full clear" if gaunt else "") + " |")
    L.append("")
    L.append("*Every node, edge, and number in this diagram is regenerated from the live server "
             "catalogs on each site publish — if it disagrees with the game, the next hourly "
             "publish reconciles it.*")

    page = docs_dir / "getting-started" / "unlock-tree.md"
    if write_between_markers(page, "unlock-tree", "\n".join(L)):
        print(f"[unlock_tree] regenerated: nodes={len(nodes_out)} edges={len(edges_out)} "
              f"dropped={len(NODES) - len(nodes_out)} hub={hub!r}")
    else:
        print(f"[unlock_tree] skipped (markers not found in {page.name})")
