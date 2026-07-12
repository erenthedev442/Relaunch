"""Full-page owner for docs/admin/review.html — the Legacy Reward breakdown.

This page was a hand-built HTML snapshot and drifted badly (it advertised the
June-24 planned tier-matrix rewards for a week after the shipped program
replaced them — owner escalation 2026-07-11). It is now generator-owned like
every other published page. NEVER hand-edit docs/admin/review.html.

Live sources (rewards section — a retune/rename updates the page):
    modules/custom/lua/legacy_ring_grant.lua       (ring item id)
    modules/custom/sql/legendary_ring.sql          (ring item_mods -> stat text)
    modules/custom/lua/legacy_tracksuit_grant.lua  (PIECES ids + names)
    modules/custom/lua/legacy_freejob_grant.lua    (target level)

Frozen source (tier standings — historical, the wipe-day eligibility record):
    tools/docgen/data/legacy_tiers_snapshot.json   (extracted 2026-07-06 from
        the Azure xidb Legacy Reward query; the DB is gone, this is the record)

Fail-closed: if any live source is missing or parses empty, the page is left
untouched (last-good stays published) and a FAIL line is printed.
"""
from __future__ import annotations

import json
import re
from pathlib import Path

PORTAL_URL = 'https://portal.ffxi-legendary.com'  # mkdocs nav "Player Portal"

# item_mods modId -> human stat line for the ring table.
_MOD_TEXT = {
    382: lambda v: f'EXP +{v}%',
    915: lambda v: f'Capacity Points +{v}%',
    456: lambda v: 'Auto-Reraise',
    458: lambda v: 'Auto-Reraise III',
     76: lambda v: f'Movement Speed +{v}%',
    914: lambda v: f'EXP retained on death {v}%',
}

# Extra ring features that are NOT item_mods (driven by the item script + a
# charentity.cpp guard), appended to the parsed stat line so the page stays
# complete when the ring is retuned.
_RING_EXTRAS = ('No Weakness after Reraise', 'USE: toggle Vanish (Sneak+Invisible) / '
                'Transform (costume)', 'permanent legendary aura glow while worn')

_TIER_ORDER = ('4', '3', '2', '1')
_CARD_CLASS = {'4': 't4', '3': 't3', '2': 't2', '1': 't1'}

_CSS = """\
:root { --bg:#0f1216; --panel:#161b22; --line:#26303b; --txt:#d7dee7; --dim:#8a93a0; --accent:#7aa2ff; }
* { box-sizing:border-box; }
body { margin:0; background:var(--bg); color:var(--txt); font:14px/1.5 -apple-system,Segoe UI,Roboto,sans-serif; }
.wrap { max-width:1180px; margin:0 auto; padding:28px 20px 80px; }
h1 { font-size:26px; margin:0 0 4px; }
.sub { color:var(--dim); margin:0 0 22px; }
.cards { display:flex; gap:12px; flex-wrap:wrap; margin-bottom:26px; }
.card { flex:1; min-width:150px; background:var(--panel); border:1px solid var(--line); border-left-width:4px; border-radius:10px; padding:14px 16px; }
.card.t4 { border-left-color:#e6b800; } .card.t3 { border-left-color:#7aa2ff; }
.card.t2 { border-left-color:#5fd0a0; } .card.t1 { border-left-color:#9aa4b2; }
.cn { font-size:28px; font-weight:700; } .cl { color:var(--dim); font-size:12.5px; }
h2 { font-size:16px; margin:28px 0 10px; border-bottom:1px solid var(--line); padding-bottom:6px; }
table { width:100%; border-collapse:collapse; }
th,td { text-align:left; padding:7px 10px; border-bottom:1px solid var(--line); }
th { color:var(--dim); font-weight:600; font-size:12.5px; position:sticky; top:0; background:var(--bg); }
.reward .rk { text-align:left; color:var(--dim); }
.rt { font-weight:400; font-size:11px; color:var(--dim); }
.controls { display:flex; gap:10px; flex-wrap:wrap; align-items:center; margin:14px 0; }
#q { flex:1; min-width:220px; background:var(--panel); border:1px solid var(--line); color:var(--txt); padding:9px 12px; border-radius:8px; font-size:14px; }
.tf { background:var(--panel); border:1px solid var(--line); color:var(--dim); padding:8px 13px; border-radius:8px; cursor:pointer; }
.tf.on { color:#fff; border-color:var(--accent); }
.badge { display:inline-block; padding:1px 8px; border-radius:20px; font-size:12px; font-weight:600; }
.b4 { background:#5a4600; color:#ffdf6b; } .b3 { background:#233463; color:#bcd0ff; }
.b2 { background:#123a2c; color:#8ff0c9; } .b1 { background:#242b34; color:#c3ccd8; }
.chars { font-weight:600; } .acct { color:var(--dim); } .num { color:var(--dim); text-align:right; font-variant-numeric:tabular-nums; }
#count { color:var(--dim); font-size:12.5px; }
tr.hide { display:none; }
.foot { color:var(--dim); font-size:12px; margin-top:24px; }
"""

_JS = """\
let TF = 'all';
function setT(b){ document.querySelectorAll('.tf').forEach(x=>x.classList.remove('on')); b.classList.add('on'); TF=b.dataset.t; render(); }
function render(){
  const q = document.getElementById('q').value.trim().toLowerCase();
  const tb = document.getElementById('tb'); let out=''; let n=0;
  for(const r of DATA){
    if(TF!=='all' && String(r.tier)!==TF) continue;
    if(q && !(r.chars.toLowerCase().includes(q) || r.account.toLowerCase().includes(q))) continue;
    n++;
    out += `<tr><td><span class="badge b${r.tier}">T${r.tier} ${r.title}</span></td>`
        +  `<td class="chars">${r.chars}</td><td class="acct">${r.account}</td>`
        +  `<td class="num">${r.hl||''}</td><td class="num">${r.marks||''}</td><td class="num">${r.prestige||''}</td>`
        +  `<td class="num">${r.gauntlet||''}</td><td class="num">${r.prime?'✓':''}</td></tr>`;
  }
  tb.innerHTML = out;
  document.getElementById('count').textContent = n + ' shown';
}
render();
"""


def _read(repo_root: Path, rel: str) -> str | None:
    p = repo_root / rel
    if not p.is_file():
        print(f'[legacy_review_page] FAIL: missing source {rel} — page left untouched')
        return None
    return p.read_text(encoding='utf-8', errors='replace')


def _ring_stats(sql: str) -> list[str]:
    stats = []
    for m in re.finditer(r'\(26169,\s*(\d+),\s*(\d+)\)', sql):
        mod, val = int(m.group(1)), int(m.group(2))
        fmt = _MOD_TEXT.get(mod)
        stats.append(fmt(val) if fmt else f'mod {mod} = {val}')
    return stats


def generate(repo_root: Path, docs_dir: Path) -> None:
    ring_lua  = _read(repo_root, 'modules/custom/lua/legacy_ring_grant.lua')
    ring_sql  = _read(repo_root, 'modules/custom/sql/legendary_ring.sql')
    suit_lua  = _read(repo_root, 'modules/custom/lua/legacy_tracksuit_grant.lua')
    job_lua   = _read(repo_root, 'modules/custom/lua/legacy_freejob_grant.lua')
    snap_path = repo_root / 'tools/docgen/data/legacy_tiers_snapshot.json'
    if None in (ring_lua, ring_sql, suit_lua, job_lua):
        return
    if not snap_path.is_file():
        print('[legacy_review_page] FAIL: missing legacy_tiers_snapshot.json — page left untouched')
        return

    ring_id_m = re.search(r'\bLEGENDARY_RING\s*=\s*(\d+)', ring_lua)
    ring_stats = _ring_stats(ring_sql)
    pieces = re.findall(r"\{\s*id\s*=\s*(\d+),\s*name\s*=\s*'([^']+)'", suit_lua)
    lvl_m = re.search(r'setLevel\((\d+)\)', job_lua)
    if not (ring_id_m and ring_stats and pieces):
        print('[legacy_review_page] FAIL: live-source parse came up empty — page left untouched')
        return
    ring_id = ring_id_m.group(1)
    level   = lvl_m.group(1) if lvl_m else '99'

    snap = json.loads(snap_path.read_text(encoding='utf-8'))
    rows = snap['rows']
    tier_names = snap['tier_names']
    n_accounts = len({r['account'] for r in rows})
    n_chars = sum(len(r['chars'].split(',')) for r in rows)
    counts = {t: sum(1 for r in rows if str(r['tier']) == t) for t in _TIER_ORDER}

    piece_names = ' / '.join(n for _i, n in pieces)
    piece_ids = ', '.join(i for i, _n in pieces)
    ring_txt = ', '.join(ring_stats + list(_RING_EXTRAS))

    cards = ''.join(
        f"<div class='card {_CARD_CLASS[t]}'><div class='cn'>{counts[t]}</div>"
        f"<div class='cl'>Tier {t} · {tier_names[t]}</div></div>"
        for t in _TIER_ORDER)

    data_js = json.dumps(rows, ensure_ascii=False, separators=(', ', ': '))

    html = f"""<!doctype html>
<html lang="en"><head><meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>Legacy Reward Program — Breakdown by Character</title>
<style>
{_CSS}</style></head>
<body><div class="wrap">
<h1>Legacy Reward Program — Breakdown by Character</h1>
<p class="sub">Pre-wipe recognition for the Legendary community. GMs excluded. {n_accounts} accounts · {n_chars} characters.</p>

<div class="cards">{cards}</div>

<h2>Rewards — shipped program (claimed on the Player Portal)</h2>
<p class="sub">Eligible accounts claim on the <a href="{PORTAL_URL}">Player Portal</a>; each claim is written to the chosen character and delivered on their next login. (The tier-matrix rewards from the original plan — gil / marks / catalysts / Death's Pardons — were superseded 2026-07-09 and never shipped.)</p>
<div style="overflow-x:auto"><table class="reward"><thead><tr><th class="rk">Reward</th><th>What it is</th><th>Delivery</th></tr></thead><tbody>
<tr><td class="rk">Legendary Ring</td><td>The one <b>functional</b> Legacy reward — Rare/Ex Lv.1 ring, all jobs: {ring_txt} (item {ring_id})</td><td><code>legacy_ring_grant.lua</code> — next login after the portal claim</td></tr>
<tr><td class="rk">Legendary Track Suit</td><td>{len(pieces)}-piece pure-cosmetic set — {piece_names} (items {piece_ids}). Custom textures show with the <a href="../getting-started/downloads/">Custom DAT pack</a>; without it the set equips fine with retail colors</td><td><code>legacy_tracksuit_grant.lua</code> — next login, piece-by-piece retry if bags fill</td></tr>
<tr><td class="rk">Free Job to {level}</td><td>Player picks any job at claim time — it is unlocked, switched to, and raised to level {level}</td><td><code>legacy_freejob_grant.lua</code> — next login</td></tr>
</tbody></table></div>

<h2>Accounts &amp; characters by tier</h2>
<p class="sub">Wipe-day tier standings ({snap['generated']} snapshot) — the eligibility record for the Legacy program. Gate logic: {snap['gate_logic']}.</p>
<div class="controls">
  <input id="q" placeholder="Search character or account name…" oninput="render()">
  <button class="tf on" data-t="all" onclick="setT(this)">All</button>
  <button class="tf" data-t="4" onclick="setT(this)">Tier 4</button>
  <button class="tf" data-t="3" onclick="setT(this)">Tier 3</button>
  <button class="tf" data-t="2" onclick="setT(this)">Tier 2</button>
  <button class="tf" data-t="1" onclick="setT(this)">Tier 1</button>
  <span id="count"></span>
</div>
<div style="overflow-x:auto"><table><thead><tr>
  <th>Tier</th><th>Characters</th><th>Account</th>
  <th class="num">HL</th><th class="num">Marks</th><th class="num">Prestige</th><th class="num">Gauntlet</th><th class="num">Prime</th>
</tr></thead><tbody id="tb"></tbody></table></div>

<p class="foot">Character snapshot: {snap['source']} ({snap['generated']}). Rewards section is generated from the live legacy_*_grant.lua modules + legendary_ring.sql on every docgen run — see tools/docgen/generators/legacy_review_page.py.</p>
</div>
<script>
const DATA = {data_js};
{_JS}</script>
</body></html>
"""

    page = docs_dir / 'admin' / 'review.html'
    page.parent.mkdir(parents=True, exist_ok=True)
    page.write_text(html, encoding='utf-8', newline='\n')
    print(f'[legacy_review_page] wrote admin/review.html '
          f'(ring={ring_id} stats={len(ring_stats)}, pieces={len(pieces)}, '
          f'level={level}, snapshot rows={len(rows)})')
