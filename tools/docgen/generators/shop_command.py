"""Generate docs/reference/shop-command.md from scripts/commands/shop.lua.

Parses every stock category and the petStock block, then renders a
searchable tabbed HTML catalog. Item names come from inline Lua comments
(primary) and item_basic DB lookup (fallback for unnamed raw IDs). The
reforge category is described textually since it's job-dynamic.

Marker: shop-catalog
"""
from __future__ import annotations

import json
import re
from pathlib import Path

from tools.docgen._paths import resolve_source
from tools.docgen._markers import write_between_markers
from tools.docgen._db import connect


# ---------------------------------------------------------------------------
# Lua parsing
# ---------------------------------------------------------------------------

# Matches one stock entry:  { xi.item.CONST, 1234 }  or  { 17175, 15000 }
# followed by an optional inline comment  -- Item Name (extra notes)
_ENTRY_RE = re.compile(
    r'\{\s*(xi\.item\.\w+|\d+)\s*,\s*(\d+)\s*\}'
    r'[^\n]*?--+\s*([^\n]*)?'
)
_ENTRY_BARE_RE = re.compile(
    r'\{\s*(xi\.item\.\w+|\d+)\s*,\s*(\d+)\s*\}'
)

_ENUM_RE = re.compile(r'^\s*(\w+)\s*=\s*(\d+)\s*,', re.MULTILINE)

_CATS_MAIN = ("general", "consumables", "weapons", "armor", "food",
               "dice", "ammo", "ninja")
_CATS_PET  = {"jugs": "pets_jugs", "food": "pets_food"}


def _parse_enum(repo_root: Path) -> dict[str, int]:
    src = resolve_source(repo_root, "scripts/enum/item.lua")
    if src is None:
        return {}
    return {m.group(1): int(m.group(2))
            for m in _ENUM_RE.finditer(
                src.read_text(encoding="utf-8", errors="replace"))}


def _const_name(const: str) -> str:
    """xi.item.FLASK_OF_ECHO_DROPS  ->  'Echo Drops'."""
    for pfx in ("FLASK_OF_", "BOTTLE_OF_", "STRIP_OF_", "TOOLBAG_"):
        if const.startswith(pfx):
            const = const[len(pfx):]
    const = re.sub(r'_P(\d+)$', lambda m: f" +{m.group(1)}", const)
    return const.replace("_", " ").title()


def _balanced_inner(text: str, open_brace_pos: int) -> str:
    """Return the text *inside* the brace starting at open_brace_pos."""
    depth, i = 0, open_brace_pos
    while i < len(text):
        if text[i] == '{':
            depth += 1
        elif text[i] == '}':
            depth -= 1
            if depth == 0:
                return text[open_brace_pos + 1: i]
        i += 1
    return text[open_brace_pos + 1:]


def _clean_comment(raw: str) -> str:
    raw = raw.strip()
    # Drop trailing parenthetical (Lv7), (RNG), (waist, MACC35), etc.
    raw = re.sub(r'\s*\([^)]*\)\s*$', '', raw)
    # Drop everything after a second "--"
    raw = raw.split('--')[0].strip()
    # Drop trailing " - note" or " / note"
    raw = re.sub(r'\s*[-/]\s*\w.*$', '', raw.strip()) if len(raw) > 30 else raw
    return raw.strip()


def _parse_entries(block: str, enum: dict[str, int]) -> list[dict]:
    results = []
    # Try to match entries with comments first; fall back to bare entries.
    matched_spans: set[int] = set()

    for m in _ENTRY_RE.finditer(block):
        expr, price = m.group(1), int(m.group(2))
        comment = _clean_comment(m.group(3) or "")
        if expr.startswith("xi.item."):
            const = expr[len("xi.item."):]
            item_id = enum.get(const)
            name = comment or _const_name(const)
        else:
            item_id = int(expr)
            name = comment
        results.append({"id": item_id, "name": name, "price": price})
        matched_spans.add(m.start())

    # Catch entries that had no comment at all
    for m in _ENTRY_BARE_RE.finditer(block):
        if m.start() in matched_spans:
            continue
        expr, price = m.group(1), int(m.group(2))
        if expr.startswith("xi.item."):
            const = expr[len("xi.item."):]
            item_id = enum.get(const)
            name = _const_name(const)
        else:
            item_id = int(expr)
            name = ""
        results.append({"id": item_id, "name": name, "price": price})

    return results


def _find_and_parse(text: str, label: str, enum: dict[str, int]) -> list[dict]:
    m = re.search(rf'\b{re.escape(label)}\s*=\s*\{{', text)
    if not m:
        return []
    inner = _balanced_inner(text, m.end() - 1)
    return _parse_entries(inner, enum)


def _fill_from_db(cats: dict[str, list[dict]], conn) -> None:
    if conn is None:
        return
    unnamed = [(cat, item) for cat, items in cats.items()
               for item in items if item["id"] and not item["name"]]
    if not unnamed:
        return
    ids = list({item["id"] for _, item in unnamed})
    ph = ",".join(["%s"] * len(ids))
    try:
        cur = conn.cursor()
        cur.execute(
            f"SELECT id, name FROM item_basic WHERE id IN ({ph})", ids)
        id_to_name: dict[int, str] = {}
        for row in cur.fetchall():
            raw = row[1] if isinstance(row[1], str) else row[1].decode("utf-8", "replace")
            id_to_name[int(row[0])] = raw.replace("_", " ").strip().title()
        for _, item in unnamed:
            if item["id"] in id_to_name:
                item["name"] = id_to_name[item["id"]]
    except Exception:
        pass


# ---------------------------------------------------------------------------
# Category metadata (order, labels, notes)
# ---------------------------------------------------------------------------

_META = [
    ("general",     "General",
     "Rings, potions, and everyday convenience items."),
    ("consumables", "Consumables",
     "Full consumable stack — potions, ethers, Elixirs, and utility items."),
    ("weapons",     "Weapons",
     "Leveling and endgame weapons across all weapon types, including GEO handbells and PUP Animators."),
    ("armor",       "Armor",
     "Earrings, belts, capes, and utility armor pieces."),
    ("food",        "Food",
     "Best-in-slot endgame food for every role. All items are 5,000 gil."),
    ("dice",        "COR Dice",
     "All 32 Phantom Roll dice at 1 gil each. Using a die on a Corsair of the right level teaches that roll permanently."),
    ("ammo",        "Ammo",
     "Arrows, bolts, bullets, waist bullet pouches (infinite-ammo / RECYCLE 100), throwing weapons, and shuriken. Leveling ladder plus Lv99 endgame options."),
    ("ninja",       "Ninja Tools",
     "All ninja toolbags at 1 gil each. One purchase gives 99 charges of that tool. Toolbags stack to 12 (≈1,188 charges per slot). The three card toolbags (Ino/Shika/Cho) can substitute for ANY elemental ninjutsu on a main-job NIN."),
    ("pets_jugs",   "BST Pets",
     "Jug broths for Beastmaster. Buy a broth, then use Call Beast or Bestial Loyalty to summon the pet. Pet food is on a separate sub-page (!shop pets food)."),
    ("pets_food",   "BST Pet Food",
     "Pet food biscuits (Alpha through Theta) to heal and feed your jug pet."),
    ("reforge",     "Reforge Claim",
     "Free one-time claim of your current main job's ilvl-109 Artifact, Relic, and Empyrean armor sets. One claim per job per set — switch jobs and re-run for another job's gear."),
]

_ORDER  = [m[0] for m in _META]
_LABEL  = {m[0]: m[1] for m in _META}
_NOTE   = {m[0]: m[2] for m in _META}


# ---------------------------------------------------------------------------
# HTML widget renderer
# ---------------------------------------------------------------------------

def _render(cats: dict[str, list[dict]]) -> str:
    data: dict[str, list] = {}
    for key in _ORDER:
        data[key] = [
            {"id": it["id"], "name": it["name"] or f"Item #{it['id']}", "price": it["price"]}
            for it in cats.get(key, [])
        ]

    payload  = json.dumps(data,  ensure_ascii=False, separators=(",", ":"))
    labels   = json.dumps(_LABEL, ensure_ascii=False, separators=(",", ":"))
    notes    = json.dumps(_NOTE,  ensure_ascii=False, separators=(",", ":"))
    order    = json.dumps(_ORDER, ensure_ascii=False, separators=(",", ":"))

    tab_btns = "\n".join(
        f'  <button class="st-tab{" active" if i == 0 else ""}" '
        f'data-cat="{k}">{_LABEL[k]}</button>'
        for i, k in enumerate(_ORDER)
    )

    return f"""<div class="st-wrap">
<div class="st-bar"><input id="st-q" type="text" placeholder="Search all items…" oninput="stFilter()"></div>
<div class="st-tabs">{tab_btns}
</div>
<div id="st-body"></div>
</div>
<script>
(function(){{
const D={payload};
const L={labels};
const N={notes};
const O={order};
let cur=O[0];

function gil(p){{
  if(p===0)return'Free';
  if(p===1)return'1 gil';
  return p.toLocaleString()+'&thinsp;gil';
}}
function link(id,name){{
  if(!id)return name;
  return`<a href="https://www.ffxiah.com/item/${{id}}" target="_blank" rel="noopener">${{name}}</a>`;
}}
function table(rows){{
  if(!rows.length)return'<p class="st-empty">No items.</p>';
  return'<table class="st-tbl"><thead><tr><th>Item</th><th>Price</th></tr></thead><tbody>'
    +rows.map(r=>`<tr><td>${{link(r.id,r.name)}}</td><td class="st-price">${{gil(r.price)}}</td></tr>`).join('')
    +'</tbody></table>';
}}
function noteBox(cat){{
  return N[cat]?`<div class="st-note">${{N[cat]}}</div>`:'';
}}
function reforgePanel(){{
  return`<div class="st-reforge">
    <p>Claim your current main-job ilvl-109 armor sets for free — one set per job, per category:</p>
    <table class="st-tbl" style="width:auto;max-width:500px"><thead><tr><th>Command</th><th>What you get</th></tr></thead><tbody>
    <tr><td><code>!shop reforge af</code></td><td>Artifact set (5 pieces)</td></tr>
    <tr><td><code>!shop reforge relic</code></td><td>Relic set (5 pieces)</td></tr>
    <tr><td><code>!shop reforge empy</code></td><td>Empyrean set (5 pieces)</td></tr>
    <tr><td><code>!shop reforge all</code></td><td>All three sets (15 pieces)</td></tr>
    </tbody></table>
    <p style="margin-top:10px;font-size:13px;color:#7878a0">Switch to a different main job and re-run to claim that job's set.</p>
  </div>`;
}}
function render(cat,q){{
  const items=(D[cat]||[]).filter(r=>!q||r.name.toLowerCase().includes(q));
  let html=noteBox(cat);
  html+=cat==='reforge'?reforgePanel():table(items);
  document.getElementById('st-body').innerHTML=html;
}}
function stFilter(){{
  const q=document.getElementById('st-q').value.trim().toLowerCase();
  if(!q){{render(cur,'');return;}}
  let html='';
  for(const cat of O){{
    const rows=(D[cat]||[]).filter(r=>r.name.toLowerCase().includes(q));
    if(!rows.length)continue;
    html+=`<div class="st-section"><div class="st-section-hdr">${{L[cat]}}</div>${{table(rows)}}</div>`;
  }}
  document.getElementById('st-body').innerHTML=html||'<p class="st-empty">No items match.</p>';
}}
document.querySelectorAll('.st-tab').forEach(b=>b.addEventListener('click',()=>{{
  cur=b.dataset.cat;
  document.querySelectorAll('.st-tab').forEach(t=>t.classList.toggle('active',t===b));
  document.getElementById('st-q').value='';
  render(cur,'');
}}));
render(cur,'');
}})();
</script>
<style>
.st-wrap{{font-family:inherit;}}
.st-bar{{margin-bottom:10px;}}
.st-bar input{{width:100%;max-width:320px;padding:7px 12px;background:#0b0d1a;border:1px solid #252840;border-radius:20px;color:#d2d2dc;font-size:13px;outline:none;}}
.st-bar input:focus{{border-color:#6e37d2;}}
.st-tabs{{display:flex;flex-wrap:wrap;gap:5px;margin-bottom:14px;}}
.st-tab{{padding:5px 13px;border-radius:20px;border:1px solid #252840;background:#14162a;color:#7878a0;font-size:12px;cursor:pointer;transition:all .15s;}}
.st-tab.active,.st-tab:hover{{background:#6e37d2;border-color:#6e37d2;color:#fff;}}
.st-note{{background:#14162a;border-left:3px solid #6e37d2;padding:8px 14px;border-radius:0 4px 4px 0;margin-bottom:12px;font-size:13px;color:#9090b8;line-height:1.5;}}
.st-tbl{{width:100%;border-collapse:collapse;font-size:13px;}}
.st-tbl thead th{{text-align:left;padding:5px 10px;border-bottom:1px solid #252840;color:#6e37d2;font-size:11px;text-transform:uppercase;letter-spacing:.07em;}}
.st-tbl tbody tr{{border-bottom:1px solid #161830;}}
.st-tbl tbody tr:hover{{background:#14162a;}}
.st-tbl td{{padding:6px 10px;}}
.st-tbl td a{{color:#c8aaff;text-decoration:none;}}
.st-tbl td a:hover{{text-decoration:underline;}}
.st-price{{text-align:right;color:#f0c84a;font-variant-numeric:tabular-nums;white-space:nowrap;}}
.st-section{{margin-bottom:20px;}}
.st-section-hdr{{font-size:11px;color:#6e37d2;text-transform:uppercase;letter-spacing:.07em;font-weight:600;margin-bottom:6px;padding-bottom:4px;border-bottom:1px solid #252840;}}
.st-empty{{color:#50507a;font-style:italic;padding:16px 0;}}
.st-reforge{{background:#14162a;border-radius:6px;padding:16px 20px;color:#9090b8;line-height:1.6;}}
.st-reforge code{{background:#0b0d1a;padding:2px 7px;border-radius:3px;font-size:12px;color:#d2d2dc;}}
</style>"""


# ---------------------------------------------------------------------------
# Generator entry point
# ---------------------------------------------------------------------------

def generate(repo_root: Path, docs_dir: Path) -> None:
    src = resolve_source(repo_root, "scripts/commands/shop.lua")
    if src is None:
        print("[shop_command] skip: shop.lua not found")
        return

    text = src.read_text(encoding="utf-8", errors="replace")
    enum = _parse_enum(repo_root)

    cats: dict[str, list[dict]] = {}

    # Main stock block
    stock_m = re.search(r'\blocal stock\s*=\s*\{', text)
    if stock_m:
        stock_block = _balanced_inner(text, stock_m.end() - 1)
        for cat in _CATS_MAIN:
            cats[cat] = _find_and_parse(stock_block, cat, enum)

    # petStock block
    pet_m = re.search(r'\blocal petStock\s*=\s*\{', text)
    if pet_m:
        pet_text = text[pet_m.start():]
        for lua_key, cat_key in _CATS_PET.items():
            cats[cat_key] = _find_and_parse(pet_text, lua_key, enum)

    # Reforge is dynamic — no static item list
    cats["reforge"] = []

    # Fill unnamed items from DB
    conn = connect(repo_root)
    try:
        _fill_from_db(cats, conn)
    finally:
        if conn:
            try:
                conn.close()
            except Exception:
                pass

    page = docs_dir / "reference" / "shop-command.md"
    ok = write_between_markers(page, "shop-catalog", _render(cats))

    total = sum(len(v) for v in cats.items() if isinstance(v, list))
    counts = ", ".join(
        f"{k}={len(cats.get(k, []))}" for k in _ORDER if k != "reforge")
    print(f"[shop_command] {'written' if ok else 'marker not found'} — {counts}")
