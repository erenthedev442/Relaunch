#!/usr/bin/env python3
"""NPC disable audit -- find 'extra' NPCs that clutter a zone with no function.

Classifies every NPC in sql/npc_list.sql by what its zone script DOES, cross-
references GetNPCByID usage for safety, and writes a per-zone REVIEW list of
candidates that are safe-ish to hide. It DISABLES NOTHING -- pure report.

Buckets (biased toward KEEP -- a false "keep" is harmless, a false "disable"
breaks content):
  FUNCTIONAL  shop / moogle / chocobo / storage / AH / guild / teleport /
              homepoint / gate / outpost, or gives a reward / key item / title /
              quest / mission / job / fame, or accepts a trade  -> KEEP
  FLAVOR      has a script but the trigger only prints a line (messageSpecial /
              showText, no startEvent, no trade, no reward) -> PRIME candidate;
              genuinely inert ("townsperson says one line")
  CUTSCENE    has startEvent but no reward markers -> REVIEW SEPARATELY: may be a
              mission cutscene step; hiding it could block a mission for anyone
              not skipping via the Mission Moogle
  SCENERY     no npcs/<name>.lua at all (placeholder bodies) -> ambient crowd;
              COUNTED per zone but NOT listed (hiding all of these = dead-looking
              cities, which is worse than cluttered)

Safety notes baked into the plan (not this script):
  * The disable mechanism will be status=2 (DISAPPEAR): the entity still LOADS,
    just hidden/untargetable, so GetNPCByID(...) references don't nil-crash and
    event scripts can still reveal it. Fully reversible (status back to 0).
  * A candidate whose name is referenced by a GetNPCByID(...) call elsewhere is
    flagged [ref] so it gets eyeballed first.

Outputs (review artifacts, nothing applied):
  tools/npc_audit/npc_disable_candidates.md    human review list, worst-clutter
                                               zones first
  tools/npc_audit/npc_disable_candidates.json  {folder: [npcid,...]} default-safe
                                               set (FLAVOR, not referenced, not
                                               already hidden) for a later
                                               status=2 SQL generator -- gated on
                                               your review.
"""
from __future__ import annotations

import json
import re
from collections import defaultdict
from datetime import datetime, timezone
from pathlib import Path

ROOT          = Path(r"D:/server")
ZONES_DIR     = ROOT / "scripts" / "zones"
NPC_LIST      = ROOT / "sql" / "npc_list.sql"
ZONE_SETTINGS = ROOT / "sql" / "zone_settings.sql"
OUT_MD        = ROOT / "tools" / "npc_audit" / "npc_disable_candidates.md"
OUT_JSON      = ROOT / "tools" / "npc_audit" / "npc_disable_candidates.json"
OUT_HTML      = ROOT / "tools" / "npc_audit" / "npc_disable_candidates.html"


def split_fields(s: str) -> list[str]:
    out, buf, in_q = [], [], False
    for c in s:
        if c == "'":
            in_q = not in_q
            buf.append(c)
        elif c == "," and not in_q:
            out.append("".join(buf).strip())
            buf = []
        else:
            buf.append(c)
    out.append("".join(buf).strip())
    return out


# --- zone id -> folder name (zone_settings field 5) -------------------------
zone_folder: dict[int, str] = {}
_zs = re.compile(r"INSERT INTO `zone_settings` VALUES \((\d+),\d+,'[^']*',\d+,'([^']+)'")
for line in ZONE_SETTINGS.read_text(encoding="utf-8", errors="replace").splitlines():
    m = _zs.search(line)
    if m:
        zone_folder[int(m.group(1))] = m.group(2)


# --- collect GetNPCByID reference tokens across ALL scripts -----------------
# Catches GetNPCByID(ID.npc.SOME_NAME) and GetNPCByID(<number>); variable args
# (GetNPCByID(npc)) can't be resolved and are skipped. Used only to FLAG, not to
# decide -- status=2 is safe even for referenced NPCs.
ref_names: set[str] = set()
ref_ids: set[int] = set()
_getnpc = re.compile(r"[gG]etNPCByID\(\s*([^),]+)")
for p in (ROOT / "scripts").rglob("*.lua"):
    try:
        txt = p.read_text(encoding="utf-8", errors="replace")
    except OSError:
        continue
    if "etNPCByID(" not in txt:
        continue
    for m in _getnpc.finditer(txt):
        tok = m.group(1).strip()
        if re.fullmatch(r"\d+", tok):
            ref_ids.add(int(tok))
        else:
            ref_names.add(tok.split(".")[-1].strip().upper())


# --- classify one npc's script ----------------------------------------------
_FUNC = re.compile(
    r"showShop|tradeShop|GuildShop|standardMerchant|StandardMerchant|MoogleShop|"
    r"customMenu|chocobo|Chocobo|porter|Porter|storage|Storage|auction|Auction|"
    r"runHomePoint|HomePoint|homepoint|Teleport|teleport|Warp|gateGuard|GateGuard|"
    r"outpost|Outpost|Survival|"
    r"addKeyItem|delKeyItem|hasKeyItem|addTitle|completeMission|completeQuest|"
    r"setMissionStatus|addItem|addGil|addCurrency|addBayldGil|unlockJob|addSpell|"
    r"addLearnedAbility|addFame|giveKeyItem|giveItem|startReward|onTrade|tradeHas",
    re.I)
_EVENT = re.compile(r"startEvent|startOptionalCutscene|startCutscene")
_MSG   = re.compile(r"messageSpecial|showText|messageText|messagePublic")


# Environmental objects / markers that the FLAVOR bucket keeps catching: doors,
# gates, ladders, lamps, furniture, and ??? quest/loot markers. These are NOT
# "townsperson says a line" NPCs -- many are zone transitions or puzzle pieces,
# so they must stay. Excluded from the candidate list (kept). Bias is toward
# exclusion: a real NPC wrongly named like an object just stays visible.
_OBJECT_WORDS = re.compile(
    r"\b(gate|door|ladder|lamp|lantern|torch|candle|sconce|brazier|lever|switch|"
    r"elevator|lift|bookshelf|bookcase|shelf|drawer|drawers|cupboard|coffer|chest|"
    r"banner|curtain|painting|console|mechanism|device|machine|valve|pipe|hatch|"
    r"trapdoor|stairs|well|fountain|statue|monument|gravestone|tombstone|pedestal|"
    r"altar|bell|cage|throne|mirror|loom|anvil|forge|furnace|cauldron|chandelier|"
    r"vase|urn|barrel|crate|wall|fence|sign|orb|crystal|cluster|pot|bed|table|chair|"
    r"stool|rug|tapestry|bookstand|globe)\b", re.I)


def is_object(name: str, polutils: str) -> bool:
    """True for ??? markers and environmental objects (doors/lamps/furniture)."""
    if name[:2].lower() == "qm":            # quest / loot ??? markers
        return True
    p = polutils.strip()
    if p == "???":
        return True
    return bool(_OBJECT_WORDS.search(p))


def classify(folder: str, name: str) -> str:
    f = ZONES_DIR / folder / "npcs" / (name + ".lua")
    if not f.exists():
        return "SCENERY"
    try:
        txt = f.read_text(encoding="utf-8", errors="replace")
    except OSError:
        return "SCENERY"
    if _FUNC.search(txt):
        return "FUNCTIONAL"
    if _EVENT.search(txt):
        return "CUTSCENE"
    if _MSG.search(txt):
        return "FLAVOR"
    return "FLAVOR"   # has a script, no functional payload -> inert


# --- parse npc_list and bucket ----------------------------------------------
_npc = re.compile(r"^INSERT INTO `npc_list` VALUES \((.*)\);")
# per zone: {folder: {bucket: [(npcid, polutils, name, referenced_bool)]}}
zones: dict[str, dict] = defaultdict(lambda: {
    "FUNCTIONAL": [], "FLAVOR": [], "CUTSCENE": [], "SCENERY": [], "OBJECT": [],
    "hidden": 0, "zoneId": 0, "total": 0,
})
grand = {"FUNCTIONAL": 0, "FLAVOR": 0, "CUTSCENE": 0, "SCENERY": 0, "OBJECT": 0,
         "hidden": 0, "total": 0, "no_folder": 0}

for line in NPC_LIST.read_text(encoding="utf-8", errors="replace").splitlines():
    m = _npc.match(line)
    if not m:
        continue
    f = split_fields(m.group(1))
    if len(f) < 14:
        continue
    npcid    = int(f[0])
    name     = f[1].strip("'")
    polutils = f[2].strip("'")
    status   = int(f[13])
    zone_id  = (npcid >> 12) & 0xFFF
    folder   = zone_folder.get(zone_id)

    grand["total"] += 1
    if status == 2:
        grand["hidden"] += 1
    if folder is None:
        grand["no_folder"] += 1
        continue

    z = zones[folder]
    z["zoneId"] = zone_id
    z["total"] += 1
    if status == 2:
        z["hidden"] += 1
        continue   # already hidden -- not clutter, skip classification

    bucket = classify(folder, name)
    if bucket in ("FLAVOR", "CUTSCENE") and is_object(name, polutils):
        bucket = "OBJECT"   # door / lamp / ??? marker -- keep, don't list
    grand[bucket] += 1
    referenced = (name.upper() in ref_names) or (npcid in ref_ids)
    z[bucket].append((npcid, polutils, name, referenced))


# --- emit report ------------------------------------------------------------
def disp(polutils: str, name: str) -> str:
    p = polutils.strip()
    if not p or p.upper() == "NPC":
        return f"_(unnamed)_ `{name}`"
    return f"{p}  `{name}`"


# default-safe proposal: FLAVOR, not referenced (JSON for the later SQL step)
proposal: dict[str, list[int]] = {}
lines: list[str] = []
ts = datetime.now(timezone.utc).strftime("%Y-%m-%d %H:%M UTC")
lines.append("# NPC Disable Audit — review list")
lines.append("")
lines.append(f"_Generated {ts}. **Disables nothing** — this is a candidate list to review. "
             "The eventual mechanism is `status=2` (DISAPPEAR): reversible, and the entity still "
             "loads so nothing nil-crashes._")
lines.append("")
lines.append("## Summary")
lines.append("")
lines.append(f"- **{grand['total']:,} NPCs** total; **{grand['hidden']:,} already hidden** "
             f"(status=2); {grand['no_folder']:,} in unmapped/system zones (skipped).")
lines.append(f"- Of the visible, scripted NPCs: **{grand['FUNCTIONAL']:,} functional** (keep), "
             f"**{grand['FLAVOR']:,} flavor candidates**, **{grand['CUTSCENE']:,} cutscene "
             f"(review)**.")
lines.append(f"- **{grand['SCENERY']:,} scenery** NPCs (no script) — left alone here; hiding the "
             "ambient crowd would make zones look dead.")
lines.append(f"- **{grand['OBJECT']:,} doors / lamps / ??? markers / furniture** — excluded from "
             "the candidate list (infrastructure & puzzle pieces, not townsfolk).")
lines.append("")
lines.append("**Legend:** `[ref]` = this NPC is referenced by a `GetNPCByID(...)` call somewhere "
             "(usually harmless under status=2, but eyeball it). Cutscene NPCs are listed "
             "separately per zone because hiding one *could* block a mission step.")
lines.append("")

# zones sorted by flavor-candidate count desc (worst clutter first)
ranked = sorted(zones.items(), key=lambda kv: -len(kv[1]["FLAVOR"]))
lines.append("## Candidates by zone (most flavor-clutter first)")
for folder, z in ranked:
    flavor = z["FLAVOR"]
    cut    = z["CUTSCENE"]
    if not flavor and not cut:
        continue
    pretty = folder.replace("_", " ")
    lines.append("")
    lines.append(f"### {pretty}  ({z['zoneId']})")
    lines.append(f"_{len(flavor)} flavor candidate(s) · {len(z['FUNCTIONAL'])} functional kept · "
                 f"{len(z['SCENERY'])} scenery · {z['hidden']} already hidden_")
    if flavor:
        lines.append("")
        lines.append("| npcid | NPC | |")
        lines.append("|---:|---|---|")
        keep_ids = []
        for npcid, polutils, name, ref in sorted(flavor, key=lambda t: t[1].lower()):
            flag = "`[ref]`" if ref else ""
            lines.append(f"| {npcid} | {disp(polutils, name)} | {flag} |")
            if not ref:
                keep_ids.append(npcid)
        if keep_ids:
            proposal[folder] = keep_ids
    if cut:
        names = ", ".join(sorted({disp(p, n).split("  ")[0] for _i, p, n, _r in cut}))[:1500]
        lines.append("")
        lines.append(f"<details><summary>↳ {len(cut)} cutscene NPC(s) — review (possible mission "
                     f"steps)</summary>\n\n{names}\n\n</details>")

OUT_MD.parent.mkdir(parents=True, exist_ok=True)
OUT_MD.write_text("\n".join(lines) + "\n", encoding="utf-8")
OUT_JSON.write_text(json.dumps(proposal, indent=1), encoding="utf-8")


# --- self-contained searchable HTML view ------------------------------------
def esc(s: str) -> str:
    return s.replace("&", "&amp;").replace("<", "&lt;").replace(">", "&gt;")


def disp_html(polutils: str, name: str) -> str:
    p = polutils.strip()
    label = "<i>(unnamed)</i>" if (not p or p.upper() == "NPC") else esc(p)
    return f"{label} <code>{esc(name)}</code>"


_CSS = """
:root{color-scheme:dark}
body{font:14px/1.5 system-ui,Segoe UI,sans-serif;margin:0;background:#14161a;color:#e6e6e6}
header{position:sticky;top:0;background:#1b1e24;border-bottom:1px solid #333;padding:14px 18px;z-index:5}
h1{margin:0 0 6px;font-size:18px}
.sub{color:#9aa4b2;font-size:13px;margin:2px 0}
#q{width:min(420px,68%);padding:7px 10px;margin-top:8px;border:1px solid #3a4150;border-radius:6px;background:#0f1115;color:#e6e6e6}
label.cut{margin-left:14px;color:#9aa4b2;font-size:13px;user-select:none}
main{padding:8px 18px 60px}
details.zone{border:1px solid #2a2f38;border-radius:8px;margin:8px 0;background:#181b21}
summary{cursor:pointer;padding:10px 12px;font-weight:600;list-style:none}
summary .z{color:#7fd1ff}
summary small{font-weight:400;color:#8b94a3;margin-left:8px}
table{width:100%;border-collapse:collapse;font-size:13px}
td{padding:3px 12px;border-top:1px solid #23272f}
td.id{color:#8b94a3;text-align:right;width:96px;font-variant-numeric:tabular-nums}
code{color:#8b94a3;font-size:12px}
.ref{color:#e0a04a;font-size:11px;border:1px solid #5a4a2a;border-radius:4px;padding:0 4px;margin-left:6px}
.cutbox{padding:7px 12px 11px;color:#9aa4b2;font-size:12px;border-top:1px dashed #2a2f38}
.hidden{display:none}
"""

_JS = """
const q=document.getElementById('q'),cut=document.getElementById('cut');
q.addEventListener('input',()=>{const t=q.value.trim().toLowerCase();
 document.querySelectorAll('details.zone').forEach(d=>{
  let any=false; const zoneMatch=d.dataset.name.includes(t);
  d.querySelectorAll('tr').forEach(tr=>{const m=!t||zoneMatch||tr.dataset.name.includes(t);
   tr.classList.toggle('hidden',!m); if(m)any=true;});
  d.classList.toggle('hidden', !!t && !any && !zoneMatch);
  if(t&&(any||zoneMatch))d.open=true; if(!t)d.open=false;
 });});
cut.addEventListener('change',()=>document.querySelectorAll('.cutbox')
  .forEach(c=>c.classList.toggle('hidden',!cut.checked)));
"""

h: list[str] = []
h.append("<!doctype html><html lang=en><head><meta charset=utf-8>")
h.append("<meta name=viewport content='width=device-width,initial-scale=1'>")
h.append("<title>NPC Disable Audit</title><style>" + _CSS + "</style></head><body>")
h.append("<header><h1>NPC Disable Audit — review list</h1>")
h.append(f"<p class=sub>{grand['total']:,} NPCs · {grand['hidden']:,} already hidden · "
         f"<b>{grand['FLAVOR']:,} flavor candidates</b> · {grand['FUNCTIONAL']:,} functional kept · "
         f"{grand['CUTSCENE']:,} cutscene (review) · {grand['SCENERY']:,} scenery · "
         f"{grand['OBJECT']:,} doors/markers filtered out. <b>Disables nothing.</b></p>")
h.append("<input id=q placeholder='filter by NPC or zone name…' autocomplete=off>")
h.append("<label class=cut><input type=checkbox id=cut> show cutscene NPCs</label></header>")
h.append("<main id=zones>")
for folder, z in ranked:
    flavor, cut_ = z["FLAVOR"], z["CUTSCENE"]
    if not flavor and not cut_:
        continue
    pretty = esc(folder.replace("_", " "))
    h.append(f"<details class=zone data-name='{pretty.lower()}'><summary>"
             f"<span class=z>{pretty}</span> <small>({z['zoneId']}) · {len(flavor)} flavor · "
             f"{len(z['FUNCTIONAL'])} functional · {len(z['SCENERY'])} scenery · "
             f"{z['hidden']} hidden</small></summary>")
    if flavor:
        h.append("<table>")
        for npcid, polutils, name, ref in sorted(flavor, key=lambda t: t[1].lower()):
            badge = "<span class=ref>ref</span>" if ref else ""
            key = f"{(polutils.strip() or name)} {name}".lower()
            h.append(f"<tr data-name='{esc(key)}'><td class=id>{npcid}</td>"
                     f"<td>{disp_html(polutils, name)}{badge}</td></tr>")
        h.append("</table>")
    if cut_:
        names = ", ".join(sorted({esc(p.strip() or n) for _i, p, n, _r in cut_}))
        h.append(f"<div class='cutbox hidden'>↳ {len(cut_)} cutscene NPC(s) — review (possible "
                 f"mission steps): {names}</div>")
    h.append("</details>")
h.append("</main><script>" + _JS + "</script></body></html>")
OUT_HTML.write_text("\n".join(h), encoding="utf-8")

prop_total = sum(len(v) for v in proposal.values())
print(f"NPCs total {grand['total']:,} | already hidden {grand['hidden']:,}")
print(f"FUNCTIONAL {grand['FUNCTIONAL']:,} | FLAVOR {grand['FLAVOR']:,} | "
      f"CUTSCENE {grand['CUTSCENE']:,} | SCENERY {grand['SCENERY']:,}")
print(f"Default-safe proposal (FLAVOR, not [ref], not hidden): {prop_total:,} NPCs "
      f"across {len(proposal)} zones")
print(f"Wrote {OUT_MD}")
print(f"Wrote {OUT_JSON}")
print(f"Wrote {OUT_HTML}")
