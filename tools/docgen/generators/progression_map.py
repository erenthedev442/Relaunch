"""progression_map — renders the Progression Flow Map from live catalogs.

Owner requirement (2026-07-05): the map page must stay 100% connected to the
content — if a catalog number changes, the page changes with it on the next
site publish. So the ENTIRE .pmap body on
docs/getting-started/progression-map.md is generated here, from:

  modules/custom/lua/new_char_starter_marks.lua   STARTER_MARKS
  modules/custom/lua/daily_login_bonus.lua        DAILY_BONUS
  modules/custom/lua/login_streak.lua             STREAK_MILESTONES
  modules/custom/lua/hunting_league_catalog.lua   per-tier unlockCost + points
  modules/custom/lua/HuntingLeague.lua            kill-streak %, party %, first-kill/featured
  modules/custom/lua/Augment_Moogle.lua           TIER_SLICES + TIER_GATES
  modules/custom/lua/augment_sage_catalog.lua     mastery rank gates
  modules/custom/lua/prestige_catalog.lua         unlockTier + apTiers
  modules/custom/lua/job_rebirth_catalog.lua      jpRequired
  modules/custom/lua/PrimeArmory_NPC.lua          TRIALS + GIL_COST
  modules/custom/lua/paragon_catalog.lua          perk caps + Daily Might

World-content cells are PRESENCE-GATED: each renders only if its module file
exists in the live tree, so retired systems fall off the map automatically.

FAIL-CLOSED: any essential parse that comes back empty raises, generate.py
logs it and leaves the existing page intact — we never publish a map with
holes where numbers should be. If the Hunting League ever grows past 5 tiers
this generator raises on purpose: the spine template narrates 5 stages and a
human should restage it.
"""

from __future__ import annotations

import html
import re
from collections import Counter
from pathlib import Path

from tools.docgen._paths import resolve_source
from tools.docgen._markers import write_between_markers


def _read(repo_root: Path, rel: str) -> str:
    src = resolve_source(repo_root, rel)
    if src is None:
        raise RuntimeError(f"progression_map: source not found: {rel}")
    return src.read_text(encoding="utf-8", errors="replace")


def _num(pattern: str, text: str, what: str) -> int:
    m = re.search(pattern, text)
    if not m:
        raise RuntimeError(f"progression_map: could not parse {what}")
    return int(m.group(1))


def _esc(s: str) -> str:
    return html.escape(s, quote=False)


def _fmt(n: int) -> str:
    return f"{n:,}"


# ---------------------------------------------------------------- parsers


def _parse_streaks(text: str) -> list[tuple[int, int]]:
    rows = re.findall(r"\{\s*(\d+)\s*,\s*(\d+)\s*,", text)
    out = [(int(d), int(m)) for d, m in rows]
    if len(out) < 3:
        raise RuntimeError("progression_map: login streak table parse failed")
    return out


def _parse_hl_tiers(text: str) -> list[dict]:
    """Per tier: number, unlockCost, representative pay, special payers."""
    blocks = re.split(r"\n\s*\{\s*\n?\s*tier\s*=\s*", text)[1:]
    tiers = []
    for blk in blocks:
        tier_no = int(re.match(r"(\d+)", blk).group(1))
        cost_m = re.search(r"unlockCost\s*=\s*(\d+)", blk)
        pts = re.findall(r"label\s*=\s*'([^']+)',\s*points\s*=\s*(\d+)", blk)
        if cost_m is None or not pts:
            continue
        counts = Counter(int(p) for _, p in pts)
        rep = counts.most_common(1)[0][0]
        specials = [(lbl, int(p)) for lbl, p in pts if int(p) != rep]
        tiers.append({
            "tier": tier_no,
            "cost": int(cost_m.group(1)),
            "pay": rep,
            "specials": specials,
        })
    tiers.sort(key=lambda t: t["tier"])
    if len(tiers) != 5:
        raise RuntimeError(
            f"progression_map: expected exactly 5 HL tiers, parsed {len(tiers)} — "
            "the spine template narrates 5 stages; restage it by hand if the league grew."
        )
    return tiers


def _parse_kill_bonuses(text: str) -> dict:
    streaks = [(int(n), int(float(m) * 100)) for n, m in
               re.findall(r"streak\s*>=\s*(\d+)\s*then\s*mult\s*=\s*([0-9.]+)", text)]
    party = [(int(n), int(float(m) * 100)) for n, m in
             re.findall(r"ps\s*>=\s*(\d+)\s*then\s*\n?\s*pb\s*=\s*math\.floor\(baseMarks\s*\*\s*([0-9.]+)\)", text)]
    if not party:
        party = [(int(n), int(float(m) * 100)) for n, m in
                 re.findall(r"ps\s*>=\s*(\d+).{0,60}?baseMarks\s*\*\s*([0-9.]+)", text, flags=re.S)]
    first_kill = re.search(r"local\s+firstBonus\s*=\s*baseMarks\b", text) is not None
    featured = re.search(r"2x base marks", text) is not None
    if not streaks or not party or not first_kill or not featured:
        raise RuntimeError("progression_map: HuntingLeague kill-bonus parse failed "
                           f"(streaks={len(streaks)} party={len(party)} first={first_kill} feat={featured})")
    streaks.sort()
    party.sort()
    return {"streaks": streaks, "party": party}


def _parse_aug_tiers(text: str) -> tuple[list[tuple[int, int]], list[tuple[int, str]]]:
    slice_sec = text.split("local TIER_SLICES", 1)[-1].split("local TIER_GATES", 1)[0]
    slices = [(int(a), int(b)) for a, b in
              re.findall(r"min\s*=\s*(\d+),\s*max\s*=\s*(\d+)", slice_sec)]
    gates = [(int(t), u) for t, _q, u in
             re.findall(r"tier\s*=\s*(\d+),\s*unlock\s*=\s*(['\"])(.*?)\2", text, flags=re.S)]
    gates.sort()
    if len(slices) != len(gates) or len(slices) < 4:
        raise RuntimeError(
            f"progression_map: augment tier parse failed (slices={len(slices)} gates={len(gates)})")
    return slices, gates


def _parse_sage_ranks(text: str) -> list[dict]:
    sec = text.split("catalog.ranks", 1)[-1]
    # cut at the next catalog.<field> assignment so we only see the ranks table
    sec = re.split(r"\ncatalog\.\w+\s*=", sec)[0]
    ranks = []
    for blk in re.findall(r"\{(.*?)\}", sec, flags=re.S):
        rank_m = re.search(r"rank\s*=\s*(\d+)", blk)
        title_m = re.search(r"title\s*=\s*'([^']+)'", blk)
        if not rank_m or not title_m:
            continue
        reqs = []
        if m := re.search(r"hlRank\s*=\s*(\d+)", blk):
            reqs.append(f"HL R{m.group(1)}")
        if m := re.search(r"prestigeLevel\s*=\s*(\d+)", blk):
            reqs.append(f"P{m.group(1)}")
        if m := re.search(r"rebirths\s*=\s*(\d+)", blk):
            reqs.append(f"{m.group(1)} rebirth{'s' if int(m.group(1)) != 1 else ''}")
        if m := re.search(r"gauntletClears\s*=\s*(\d+)", blk):
            reqs.append("Gauntlet clear")
        ranks.append({"rank": int(rank_m.group(1)), "title": title_m.group(1), "reqs": reqs})
    if len(ranks) < 4:
        raise RuntimeError(f"progression_map: sage rank parse failed ({len(ranks)})")
    ranks.sort(key=lambda r: r["rank"])
    return ranks


def _parse_trials(text: str) -> list[tuple[str, str]]:
    rows = re.findall(r"\{\s*var\s*=\s*'PW_Trial\d+_Done',\s*label\s*=\s*'([^']+)',\s*desc\s*=\s*'([^']+)'", text)
    if len(rows) < 4:
        raise RuntimeError(f"progression_map: prime trial parse failed ({len(rows)})")
    return rows


_PARAGON_STAT_LABEL = {
    "HP": "HP",
    "ATT": "ATT", "RATT": "RATT",
    "ACC": "ACC", "RACC": "RACC",
    "DEF": "DEF",
    "MATT": "MATT", "MACC": "MACC", "MAGIC_DAMAGE": "M.Dmg",
    "PET_ATK_DEF": "Pet ATK/DEF", "PET_ACC_EVA": "Pet ACC/EVA",
    "PET_MAB_MDB": "Pet MAB/MDB", "PET_MACC_MEVA": "Pet MACC/MEVA",
    "PET_ATTR_BONUS": "Pet Attr", "PET_TP_BONUS": "Pet TP",
}


def _parse_paragon(text: str) -> list[dict]:
    perks = []
    for m in re.finditer(
            r"label\s*=\s*'([^']+)',\s*modKeys\s*=\s*\{([^}]*)\},\s*perRank\s*=\s*(\d+),\s*maxRank\s*=\s*(\d+)",
            text):
        label, keys, per, mx = m.group(1), m.group(2), int(m.group(3)), int(m.group(4))
        raw_keys = re.findall(r"'(\w+)'", keys)
        stats = ", ".join(_PARAGON_STAT_LABEL.get(k, k) for k in raw_keys)
        perks.append({"label": label, "stats": stats, "cap": per * mx})
    if len(perks) < 2:
        raise RuntimeError(f"progression_map: paragon perk parse failed ({len(perks)})")
    return perks


# ---------------------------------------------------------------- render


def _world_cells(repo_root: Path) -> str:
    """Presence-gated world-content cells: a cell renders only while its
    module exists in the live tree."""
    cells = [
        ("modules/custom/lua/Dynamis_Divergence.lua", "Dynamis — Divergence",
         "Portals at the four city Dynamis entrances · wave battles · the +3 → +4 Forge (trade a reforged +3 AF/Relic piece + [D] materials → +4) · a city clear is an Augment Tier key"),
        ("modules/custom/lua/Voidwatch.lua", "Voidwatch",
         "Rift battles — pop a Planar Rift, burn the Voidwalker, stack lights for the Pyxis loot roll"),
        ("modules/custom/lua/htbf.lua", "High-Tier Battlefields",
         "Retail HTBF fights via phantom gems, tiered difficulty, dedicated vendor"),
        ("scripts/zones/Mhaura/npcs/Sorrowful_Sage.lua", "Nyzul Isle",
         "The Sorrowful Sage in Mhaura opens retail Nyzul runs — floor-climb loot"),
        ("modules/custom/lua/SpellSkillMastery.lua", "Spell &amp; Skill Mastery",
         'Spend <span class="chip c-sigil">Mastery Sigils</span> at the Mastery Sage in {{npc:spell_mastery}} to permanently empower weapon skills and spells'),
        ("modules/custom/lua/Voidspire.lua", "Voidspire &amp; GM Waves",
         "Weekly milestone dungeon + five wave difficulties — together an Augment Tier key"),
        ("modules/custom/lua/affinity_nm_autopop.lua", "Affinity NM Hunts",
         "Always-up affinity NMs · register Augment Sage affinities for better rolls in their category"),
        ("modules/custom/lua/maat_infamy_fight.lua", "Maat's Echo",
         "<code>!maat</code> — the solo super-fight · first kill is an Augment Tier key"),
        ("modules/custom/lua/fellow_companion.lua", "Adventuring Fellow",
         "Your persistent companion — levels from your kills, build it toward the role you need"),
    ]
    out = []
    for rel, name, desc in cells:
        # Presence probes; the aggregate guard below raises if too few resolve.
        if resolve_source(repo_root, rel, required=False) is not None:
            out.append(f'      <div class="wcell"><b>{name}</b><span>{desc}</span></div>')
    if len(out) < 3:
        raise RuntimeError("progression_map: world-content presence checks nearly all failed")
    return "\n".join(out)


def generate(repo_root: Path, docs_dir: Path) -> None:
    try:
        starter = _num(r"STARTER_MARKS\s*=\s*(\d+)",
                       _read(repo_root, "modules/custom/lua/new_char_starter_marks.lua"), "STARTER_MARKS")
        daily = _num(r"DAILY_BONUS\s*=\s*(\d+)",
                     _read(repo_root, "modules/custom/lua/daily_login_bonus.lua"), "DAILY_BONUS")
        streaks = _parse_streaks(_read(repo_root, "modules/custom/lua/login_streak.lua"))
        tiers = _parse_hl_tiers(_read(repo_root, "modules/custom/lua/hunting_league_catalog.lua"))
        bonuses = _parse_kill_bonuses(_read(repo_root, "modules/custom/lua/HuntingLeague.lua"))
        slices, gates = _parse_aug_tiers(_read(repo_root, "modules/custom/lua/Augment_Moogle.lua"))
        sage = _parse_sage_ranks(_read(repo_root, "modules/custom/lua/augment_sage_catalog.lua"))
        prestige_txt = _read(repo_root, "modules/custom/lua/prestige_catalog.lua")
        unlock_tier = _num(r"unlockTier\s*=\s*(\d+)", prestige_txt, "prestige unlockTier")
        ap_tiers = [(int(a), int(b)) for a, b in
                    re.findall(r"minLevel\s*=\s*(\d+),\s*ap\s*=\s*(\d+)", prestige_txt)]
        if not ap_tiers:
            raise RuntimeError("progression_map: apTiers parse failed")
        jp_required = _num(r"jpRequired\s*=\s*(\d+)",
                           _read(repo_root, "modules/custom/lua/job_rebirth_catalog.lua"), "jpRequired")
        prime_txt = _read(repo_root, "modules/custom/lua/PrimeArmory_NPC.lua")
        trials = _parse_trials(prime_txt)
        gil_cost = _num(r"GIL_COST\s*=\s*(\d+)", prime_txt, "prime GIL_COST")
        paragon = _parse_paragon(_read(repo_root, "modules/custom/lua/paragon_catalog.lua"))
        world = _world_cells(repo_root)
    except RuntimeError as e:
        # Fail closed: leave the existing page untouched.
        raise

    t = {x["tier"]: x for x in tiers}
    streak_txt = " · ".join(f"{d}d <b>+{_fmt(m)}</b>" for d, m in streaks)
    kill_streak_txt = ", ".join(f"+{p}% at {n}" for n, p in bonuses["streaks"])
    party_bits = sorted(bonuses["party"])
    party_txt = " / ".join(f"+{p}% with {n}+ in party" for n, p in party_bits)
    hub = t[5]
    hub_specials = " · ".join(f"{_esc(l)} <b>{p}</b>" for l, p in hub["specials"])

    slice_rows = "\n".join(
        f'    <div class="rung"><b>Tier {i + 1} · {a}–{b}</b><span>{_esc(gates[i][1])}</span></div>'
        for i, (a, b) in enumerate(slices))
    sage_txt = " · ".join(
        f"{_esc(r['title'].replace('Augment ', ''))}@{'+'.join(r['reqs']) if r['reqs'] else 'open'}"
        for r in sage)
    ap_rows = "\n".join(
        f'    <div class="rung"><b>P.Lv {lo}{"–" + str(ap_tiers[i + 1][0] - 1) if i + 1 < len(ap_tiers) else "+"}</b>'
        f'<span>{ap} AP per Court kill</span></div>'
        for i, (lo, ap) in enumerate(((max(lo, 1), ap) for lo, ap in ap_tiers)))
    trial_rows = "\n".join(
        f'    <div class="rung"><b>{_esc(lbl)}</b><span>{_esc(desc)}</span></div>'
        for lbl, desc in trials)
    paragon_caps = " · ".join(f"<b>+{_fmt(p['cap'])}</b> {_esc(p['stats'] or p['label'])}" for p in paragon)
    econ_rows = "\n".join(
        f"      <tr><td>Rank {x['tier']}</td><td>{'—' if x['cost'] == 0 else _fmt(x['cost'])}</td>"
        f"<td>{x['pay']}"
        + (" · " + " · ".join(f"{_esc(l)} <b>{p}</b>" for l, p in x["specials"]) if x["specials"] else "")
        + "</td></tr>"
        for x in tiers)

    body = f"""<div class="pmap">
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
      <div><b>{starter}</b> Hunt Marks starter stipend</div>
      <div><b>+{daily}</b> marks first login each UTC day</div>
      <div>Login streaks: {streak_txt}</div>
      <div>All jobs ready — no leveling wall</div>
    </div>
    <p class="dim">Open from day one, in parallel: HL Rank 1 camps · <b>Adventuring Fellow</b> · Hunter's Guild (rep amps your marks) · Affinity NM hunts · Casino · Chocobo Derby · Colosseum PvP · Daily Board. <b>The Augment Moogle refuses fresh characters</b> — {_esc(gates[0][1])} to open Augment Tier 1.</p>
  </div>
  <div class="node">
    <div class="stageno">Stage 1</div>
    <h2>The Hunt Begins</h2>
    <div class="gate">Rank 2 at {_fmt(t[2]["cost"])} lifetime marks</div>
    <p>Rank 1 NMs pay {t[1]["pay"]} marks base. <b>First-ever kill of each NM pays double</b>; the weekly <b>Featured Hunt pays 2× base</b> on your first kill (stacks with first-kill); kill streaks inside 5 minutes add <b>{kill_streak_txt}</b>; partied kills add {party_txt}.</p>
    <ul class="open">
      <li>Opens: Rank 2 NMs ({t[2]["pay"]} marks/kill) · <b>Sage Mastery rank 1</b> ({_esc(sage[0]["title"])} — lifts your roll floor)</li>
      <li>Augment Tier 1 rolls live in the {slices[0][0]}–{slices[0][1]} band once the gate is cleared</li>
    </ul>
  </div>
  <div class="node">
    <div class="stageno">Stage 2</div>
    <h2>Hitting Your Stride</h2>
    <div class="gate">Rank 3 at {_fmt(t[3]["cost"])} lifetime marks</div>
    <p>Rank 2–3 NMs are duo/small-group fights. Gear climbs through the vendor tiers as marks accumulate.</p>
    <ul class="open">
      <li>Opens: Rank 3 NMs ({t[3]["pay"]} marks/kill) · <b>Sage Mastery rank 2</b> ({_esc(sage[1]["title"])})</li>
      <li>Start chipping the later augment-tier keys: {_esc(gates[2][1])}</li>
    </ul>
  </div>
  <div class="node">
    <div class="stageno">Stage 3</div>
    <h2>The Hard Push</h2>
    <div class="gate">Rank 4 at {_fmt(t[4]["cost"])} → Rank 5 at {_fmt(t[5]["cost"])} lifetime marks</div>
    <p>The long stretch by design. Rank 4 NMs pay {t[4]["pay"]} marks; Rank 5 pays {t[5]["pay"]}{" — and " + hub_specials + " as the Rank 5 server boss" if hub["specials"] else ""}. Featured weeks and kill streaks matter most here.</p>
  </div>
  <div class="node hub">
    <div class="stageno">★ The Hub Gate</div>
    <h2>Hunting League Rank {unlock_tier}</h2>
    <div class="gate">{_fmt(t[unlock_tier]["cost"])} lifetime marks — everything past this point fans out from here</div>
    <ul class="open">
      <li><b>Prestige entry</b> — the Ascension Altar accepts you; Nightmare Court trials begin</li>
      <li><b>Augment Tier 2</b> — rolls move up to the {slices[1][0]}–{slices[1][1]} band ({_esc(gates[1][1])})</li>
      <li>Deeper Sage Mastery ranks come into reach as Prestige and Rebirth progress</li>
    </ul>
  </div>
</div>
<div class="fanlabel">
  <h2>After Rank {unlock_tier} — the endgame fan</h2>
  <p>Prestige is the power spine, the augment ladder is the thread through everything, Prime is the trophy quest, and Apex→Paragon never ends. The world-content band below feeds all of them.</p>
</div>
<div class="lanes">
  <div class="lane">
    <h3>Prestige &amp; Rebirth <span class="chip c-ap">Ascension AP</span></h3>
    <div class="who">Nightmare Court boss trials at the Ascension Altar · AP per kill scales with depth</div>
{ap_rows}
    <div class="rung"><b>Rebirth</b><span>Any job with <b>{_fmt(jp_required)} spent Job Points</b> can rebirth — permanent stacking category boosts; rebirth counts also gate the deeper Sage Mastery ranks</span></div>
  </div>
  <div class="lane">
    <h3>Prime Weapon — {len(trials)} Trials <span class="chip c-gil">{_fmt(gil_cost)} gil</span></h3>
    <div class="who">All trials in any order, then the forge opens</div>
{trial_rows}
    <div class="rung"><b>The Forge</b><span>Prime Armory · {_fmt(gil_cost)} gil per weapon</span></div>
  </div>
  <div class="lane">
    <h3>The Gauntlet &amp; Apex <span class="chip c-paragon">Paragon Points</span></h3>
    <div class="who">Solo boss ladders — the Gauntlet's champion climb and the Apex arena in Walk of Echoes [P2]</div>
    <div class="rung"><b>Apex Trials</b><span>Scaled boss tiers · Paragon Points per clear</span></div>
    <div class="rung"><b>Paragon board</b><span>Caps: {paragon_caps}</span></div>
    <div class="rung"><b>No ceiling</b><span>The Apex ladder itself keeps scaling — the leaderboard war never ends</span></div>
  </div>
  <div class="lane">
    <h3>The Augment Ladder <span class="chip c-aug">Tiers 1–{len(slices)}</span></h3>
    <div class="who">Your roll band is gated by CONTENT; your Sage Mastery rank lifts the floor inside the band, and a crit = a perfect roll</div>
{slice_rows}
    <div class="rung"><b>Mastery</b><span>{sage_txt}</span></div>
  </div>
  <div class="lane wide">
    <h3>The World-Content Band — feeds everything above</h3>
    <div class="who">Independent tracks with their own currencies and loot; several are augment-tier keys. A system only appears here while it exists in the live code.</div>
    <div class="wgrid">
{world}
    </div>
  </div>
</div>
<div class="refs">
  <div class="ref">
    <h3>Hunting League economics</h3>
    <div class="tablewrap"><table>
      <tr><th>Rank</th><th>Gate (lifetime marks)</th><th>Pay per kill</th></tr>
{econ_rows}
    </table></div>
    <p class="dim" style="font-size:12px;margin-top:8px">Multipliers stack on base: first-kill ×2 · featured week ×2 · streak {kill_streak_txt} · {party_txt} · Hunter's Guild rank amp.</p>
  </div>
  <div class="ref">
    <h3>Currencies at a glance</h3>
    <div class="tablewrap"><table>
      <tr><th>Currency</th><th>Source</th><th>Buys</th></tr>
      <tr><td><span class="chip c-marks">Hunt Marks</span></td><td>HL NM kills, daily/streak/boards</td><td>Gear tiers, rank gates, augment trades</td></tr>
      <tr><td><span class="chip c-ap">Ascension AP</span></td><td>Nightmare Court kills</td><td>Prestige board perks</td></tr>
      <tr><td><span class="chip c-paragon">Paragon Pts</span></td><td>Apex Trials</td><td>Paragon board (capped stats + Daily Might)</td></tr>
      <tr><td><span class="chip c-sigil">Mastery Sigils</span></td><td>Mastery content</td><td>Permanent WS/spell empowerment</td></tr>
      <tr><td><span class="chip c-div">Divergence materials</span></td><td>Dynamis — Divergence waves (Rusted/Black ID Cards + Mega-Boss Paragon Card)</td><td>The +3 → +4 Forge — upgrade a reforged +3 AF/Relic piece to +4</td></tr>
      <tr><td><span class="chip c-gil">Gil</span></td><td>AH, Casino, Derby, mobs</td><td>Prime forge ({_fmt(gil_cost)}), AH, Casino</td></tr>
    </table></div>
  </div>
</div>
<footer>
  Generated on every site publish from the live relaunch catalogs (hunting_league_catalog · Augment_Moogle TIER_SLICES/TIER_GATES · augment_sage_catalog · prestige_catalog · job_rebirth_catalog · PrimeArmory_NPC · paragon_catalog · daily_login_bonus · login_streak · HuntingLeague). If a number here disagrees with the game, the next hourly publish reconciles it.
</footer>
</div>"""

    page = docs_dir / "getting-started" / "progression-map.md"
    if write_between_markers(page, "progression-map", body):
        print(f"[progression_map] regenerated: tiers={len(tiers)} slices={len(slices)} "
              f"trials={len(trials)} paragon={len(paragon)} worldcells={world.count('wcell')}")
    else:
        print(f"[progression_map] skipped (markers not found in {page.name})")
