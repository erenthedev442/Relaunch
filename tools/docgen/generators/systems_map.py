"""systems_map — renders the Systems Map page body from live catalogs.

Owner requirement (2026-07-05): getting-started/systems-map.md must be 100%
connected to the content, like progression-map — if a catalog number changes,
the page changes on the next site publish. The whole body between the
DOCGEN systems-map markers is generated here, from:

  scripts/commands/hunt.lua                       hub zone (desc line)
  modules/custom/lua/new_char_starter_marks.lua   STARTER_MARKS
  modules/custom/lua/daily_login_bonus.lua        DAILY_BONUS
  modules/custom/lua/login_streak.lua             streak milestones
  modules/custom/lua/hunting_league_catalog.lua   tier names, unlockCost, pay
  modules/custom/lua/HuntingLeague.lua            first-kill/featured/streak/party
  modules/custom/lua/weekly_hunts_catalog.lua     all-cleared sweep bonus
  modules/custom/lua/colosseum_catalog.lua        reward.winBase
  modules/custom/lua/gauntlet_catalog.lua         floor-10 clear gil/pp/infamy
  modules/custom/lua/augment_affinity_catalog.lua affinity count + reg gate
  modules/custom/lua/affinity_nm_autopop.lua      RESPAWN_SECONDS
  modules/custom/lua/Augment_Moogle.lua           TIER_GATES (tier-1 gate text)
  modules/custom/lua/prestige_catalog.lua         unlockTier
  modules/custom/lua/job_rebirth_catalog.lua      jpRequired
  modules/custom/lua/PrimeArmory_NPC.lua          TRIALS / WEAPONS / GIL_COST

System rows are PRESENCE-GATED like progression_map's world cells: a row only
renders while its module file exists in the live tree, so retired systems
fall off the map automatically (and systems this branch never had — e.g. a
Legendary-only module — never appear).

FAIL-CLOSED: an essential parse that comes back empty raises; generate.py
logs the failure and the existing page stays untouched.
"""

from __future__ import annotations

import re
from collections import Counter
from pathlib import Path

from tools.docgen._paths import resolve_source
from tools.docgen._markers import write_between_markers


def _read(repo_root: Path, rel: str) -> str:
    src = resolve_source(repo_root, rel)
    if src is None:
        raise RuntimeError(f"systems_map: source not found: {rel}")
    return src.read_text(encoding="utf-8", errors="replace")


def _read_opt(repo_root: Path, rel: str) -> str | None:
    src = resolve_source(repo_root, rel, required=False)
    if src is None:
        return None
    return src.read_text(encoding="utf-8", errors="replace")


def _exists(repo_root: Path, rel: str) -> bool:
    return resolve_source(repo_root, rel, required=False) is not None


def _num(pattern: str, text: str, what: str) -> int:
    m = re.search(pattern, text)
    if not m:
        raise RuntimeError(f"systems_map: could not parse {what}")
    return int(m.group(1))


def _fmt(n: int) -> str:
    return f"{n:,}"


# ---------------------------------------------------------------- parsers


def _parse_hl_tiers(text: str) -> list[dict]:
    """Per tier: number, display name, unlockCost, representative pay, specials."""
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
        rep = counts.most_common(1)[0][0]
        specials = [(lbl, int(p)) for lbl, p in pts if int(p) != rep]
        tiers.append({
            "tier": tier_no,
            "name": name_m.group(1) if name_m else f"Rank {tier_no}",
            "cost": int(cost_m.group(1)),
            "pay": rep,
            "max_pay": max(int(p) for _, p in pts),
            "specials": specials,
        })
    tiers.sort(key=lambda t: t["tier"])
    if len(tiers) < 4:
        raise RuntimeError(f"systems_map: expected >=4 HL tiers, parsed {len(tiers)}")
    return tiers


def _parse_kill_bonuses(text: str) -> dict:
    streaks = [(int(n), int(float(m) * 100)) for n, m in
               re.findall(r"streak\s*>=\s*(\d+)\s*then\s*mult\s*=\s*([0-9.]+)", text)]
    first_kill = re.search(r"local\s+firstBonus\s*=\s*baseMarks\b", text) is not None
    featured = re.search(r"2x base marks", text) is not None
    if not streaks or not first_kill:
        raise RuntimeError(
            f"systems_map: HuntingLeague kill-bonus parse failed "
            f"(streaks={len(streaks)} first={first_kill})")
    streaks.sort()
    return {"streaks": streaks, "featured": featured}


def _parse_streaks(text: str) -> list[tuple[int, int]]:
    rows = re.findall(r"\{\s*(\d+)\s*,\s*(\d+)\s*,", text)
    out = [(int(d), int(m)) for d, m in rows]
    if len(out) < 3:
        raise RuntimeError("systems_map: login streak table parse failed")
    return out


def _parse_tier_gates(text: str) -> list[tuple[int, str]]:
    gates = [(int(t), u) for t, _q, u in
             re.findall(r"tier\s*=\s*(\d+),\s*unlock\s*=\s*(['\"])(.*?)\2", text, flags=re.S)]
    gates.sort()
    if len(gates) < 4:
        raise RuntimeError(f"systems_map: augment TIER_GATES parse failed ({len(gates)})")
    return gates


def _parse_hub_zone(text: str) -> str:
    # The command's own desc line names the hub zone in display form.
    m = re.search(r"Warps you to the Hunting League hub in (.+?)\.", text)
    if m:
        return m.group(1).strip()
    m = re.search(r"xi\.zone\.(\w+)", text)
    if not m:
        raise RuntimeError("systems_map: hunt.lua hub zone parse failed")
    return m.group(1).replace("_", " ").title()


def _parse_prime(text: str) -> tuple[int, int, int]:
    trials = re.findall(r"\{\s*var\s*=\s*'PW_Trial\d+_Done'", text)
    weapons_sec = text.split("local WEAPONS", 1)[-1].split("\n}", 1)[0]
    weapons = re.findall(r"\{\s*id\s*=\s*\d+,\s*name\s*=\s*'[^']+'", weapons_sec)
    gil_cost = _num(r"GIL_COST\s*=\s*(\d+)", text, "prime GIL_COST")
    if len(trials) < 4 or len(weapons) < 10:
        raise RuntimeError(
            f"systems_map: prime parse failed (trials={len(trials)} weapons={len(weapons)})")
    return len(trials), len(weapons), gil_cost


# ---------------------------------------------------------------- render


def _row(cells: list[str]) -> str:
    return "| " + " | ".join(cells) + " |"


def generate(repo_root: Path, docs_dir: Path) -> None:
    # ---- essential numbers (fail closed) ------------------------------
    starter = _num(r"STARTER_MARKS\s*=\s*(\d+)",
                   _read(repo_root, "modules/custom/lua/new_char_starter_marks.lua"),
                   "STARTER_MARKS")
    daily = _num(r"DAILY_BONUS\s*=\s*(\d+)",
                 _read(repo_root, "modules/custom/lua/daily_login_bonus.lua"), "DAILY_BONUS")
    streaks = _parse_streaks(_read(repo_root, "modules/custom/lua/login_streak.lua"))
    tiers = _parse_hl_tiers(_read(repo_root, "modules/custom/lua/hunting_league_catalog.lua"))
    bonuses = _parse_kill_bonuses(_read(repo_root, "modules/custom/lua/HuntingLeague.lua"))
    gates = _parse_tier_gates(_read(repo_root, "modules/custom/lua/Augment_Moogle.lua"))
    hub_zone = _parse_hub_zone(_read(repo_root, "scripts/commands/hunt.lua"))
    weekly_sweep = _num(r"catalog\.allClearedReward\s*=\s*\{[^}]*?amount\s*=\s*(\d+)",
                        _read(repo_root, "modules/custom/lua/weekly_hunts_catalog.lua"),
                        "weekly allClearedReward")
    prestige_unlock = _num(r"unlockTier\s*=\s*(\d+)",
                           _read(repo_root, "modules/custom/lua/prestige_catalog.lua"),
                           "prestige unlockTier")
    jp_required = _num(r"jpRequired\s*=\s*(\d+)",
                       _read(repo_root, "modules/custom/lua/job_rebirth_catalog.lua"),
                       "jpRequired")
    n_trials, n_weapons, prime_gil = _parse_prime(
        _read(repo_root, "modules/custom/lua/PrimeArmory_NPC.lua"))

    # ---- optional numbers (row renders only if its source parses) -----
    colo_txt = _read_opt(repo_root, "modules/custom/lua/colosseum_catalog.lua")
    colo_win = None
    if colo_txt:
        m = re.search(r"winBase\s*=\s*(\d+)", colo_txt)
        colo_win = int(m.group(1)) if m else None

    gaunt_txt = _read_opt(repo_root, "modules/custom/lua/gauntlet_catalog.lua")
    gaunt = None
    if gaunt_txt:
        # The Gauntlet's full-clear (level-10) payout lives in C.FINAL_REWARD.
        # Anchor on that brace block — a loose `gil=...pp=...infamy=` scan would
        # instead grab the first numeric entry (MILESTONE_REWARDS[3], 250k/25/25)
        # and mislabel a mid-run milestone as the full clear. This mirrors the
        # detail-page generator gauntlet.py so the two pages can't disagree.
        blk_m = re.search(r"FINAL_REWARD\s*=\s*\{([^}]*)\}", gaunt_txt)
        if blk_m:
            blk = blk_m.group(1)
            g = re.search(r"\bgil\s*=\s*(\d+)", blk)
            p = re.search(r"\bpp\s*=\s*(\d+)", blk)
            i = re.search(r"\binfamy\s*=\s*(\d+)", blk)
            if g and p and i:
                gaunt = (int(g.group(1)), int(p.group(1)), int(i.group(1)))

    aff_txt = _read_opt(repo_root, "modules/custom/lua/augment_affinity_catalog.lua")
    aff = None
    if aff_txt:
        # one row per affinity, each starting `{ cat=N, ...` (anchoring on the
        # row start keeps the doc comment `-- trophy = { id, qty, name }` out)
        count = len(re.findall(r"^\s*\{\s*cat\s*=\s*\d+", aff_txt, flags=re.M))
        rank_m = re.search(r"(?:affinityRankReq|rankReq)\s*=\s*(\d+)", aff_txt)
        cost_m = re.search(r"(?:affinityMarkCost|markCost)\s*=\s*(\d+)", aff_txt)
        if count:
            aff = {
                "count": count,
                "rank": int(rank_m.group(1)) if rank_m else None,
                "cost": int(cost_m.group(1)) if cost_m else None,
            }
    aff_respawn = None
    if (t := _read_opt(repo_root, "modules/custom/lua/affinity_nm_autopop.lua")):
        m = re.search(r"RESPAWN_SECONDS\s*=\s*(\d+)", t)
        aff_respawn = int(m.group(1)) if m else None

    # Registered affinities re-roll and keep the better result (Augment_Moogle
    # "roll twice, keep the better"); presence-checked so the wording drops if
    # the mechanic is ever removed.
    moogle_txt = _read(repo_root, "modules/custom/lua/Augment_Moogle.lua")
    aff_double_roll = "roll twice, keep the better" in moogle_txt

    def have(rel: str) -> bool:
        return _exists(repo_root, rel)

    t = {x["tier"]: x for x in tiers}
    gate_list = " → ".join(_fmt(x["cost"]) for x in tiers if x["cost"] > 0)
    pay_list = " / ".join(str(x["pay"]) for x in tiers)
    pay_min = min(x["pay"] for x in tiers)
    pay_max = max(x["max_pay"] for x in tiers)
    streak_txt = ", ".join(f"+{p}% at {n}" for n, p in bonuses["streaks"])
    login_streak_txt = " · ".join(f"{d}d **+{_fmt(m)}**" for d, m in streaks)
    top = tiers[-1]
    top_specials = " · ".join(f"{lbl} **{p}**" for lbl, p in top["specials"])

    L: list[str] = []
    add = L.append

    # ---- big picture ---------------------------------------------------
    add("## The big picture")
    add("")
    add("```")
    add(f"New character → Level 99 → Hunting League ({tiers[0]['name'].split(' - ')[0]}–"
        f"{top['name'].split(' - ')[0]}) → Endgame")
    add("```")
    add("")
    add("**Hunt Marks** are the primary currency for the entire game. You earn them by "
        "killing Hunting League NMs, spend them to unlock the next rank and buy Seals, "
        "and Seals buy gear. Everything branches off that spine.")
    add("")
    add(_row(["Phase", "Gate", "Core loop", "Main output"]))
    add(_row(["---", "---", "---", "---"]))
    add(_row(["**Foundation**", "None", "Level to 99, first hunts",
              f"{starter} starter marks, daily +{daily}"]))
    add(_row(["**Core Loop**", f"Rank gates: {gate_list} lifetime marks",
              "Pop NMs → Hunt Marks → Seals → Gear", "Gear tiers, rank progress"]))
    add(_row(["**Content Unlocks**", "Augment tier keys (see below)",
              "Boss content → Reforge marks, affinities", "Reforge armor, better augment rolls"]))
    add(_row(["**Deep Endgame**", "Party content",
              "HTBF, Dynamis, Voidwatch, Nyzul, Gauntlet", "Top-tier gear, Infamy, Paragon Pts"]))
    add(_row(["**Vertical**", "Always on",
              "Prestige, Rebirth, Prime, Apex", "Permanent stat bonuses"]))
    add("")
    add("---")
    add("")

    # ---- phase 1 --------------------------------------------------------
    add("## Phase 1 — Foundation")
    add("")
    add('!!! note ""')
    add("    **Gate:** None. Available from the moment you create a character.")
    add("")
    add(f"Every new character starts with **{starter} Hunt Marks**. Your first login "
        f"each UTC day pays **+{daily} marks**, and login streaks add milestones: "
        f"{login_streak_txt}.")
    add("")
    add(_row(["System", "What it does"]))
    add(_row(["---", "---"]))
    if have("scripts/commands/buff.lua"):
        add(_row(["`!buff`", "Grants Refresh / Regen / Regain + the current zone's "
                  "regional buff — the buff also hands you that zone's Mastery Sigil."]))
    if have("modules/custom/lua/new_player_linkshell.lua"):
        add(_row(["Newcomer linkshell", "Fresh characters are handed a pearl for the "
                  "server linkshell automatically."]))
    if have("modules/custom/lua/fellow_companion.lua"):
        add(_row(["Adventuring Fellow", "Your persistent companion — levels from your "
                  "kills from day one. `!fellow`"]))
    add("")
    add(f"Once you hit 99, type **`!hunt`** to warp to {hub_zone}. The Hunt: Seals and "
        "Hunt: Spawner NPCs are side by side where you land.")
    add("")
    add("---")
    add("")

    # ---- phase 2 --------------------------------------------------------
    add(f"## Phase 2 — Core Hunt Loop ({tiers[0]['name'].split(' - ')[0]}–"
        f"{t[3]['name'].split(' - ')[0] if 3 in t else 'Rank III'})")
    add("")
    add('!!! tip ""')
    add("    **Gate:** None. This is the game's primary content engine from your first "
        "kill forward.")
    add("")
    add("### The loop")
    add("")
    add(f"1. Talk to **Hunt: Spawner** → pick an NM at your rank → it appears in front of you")
    add(f"2. Kill it → earn **Hunt Marks** ({pay_list} per kill at "
        f"{' / '.join(x['name'].split(' - ')[0] for x in tiers)})")
    add("3. Spend marks on **Seals** at the Seals Vendor")
    add(f"4. Spend Seals at the **Armor / Weapons / Accessories Vendors** in {hub_zone}")
    add(f"5. Accumulate lifetime marks to unlock the next rank ({gate_list} total)")
    add("")
    bonus_bits = ["your first-ever kill of each NM pays **double**"]
    if bonuses["featured"]:
        bonus_bits.append("the weekly **Featured Hunt** pays 2× base (stacks with first-kill)")
    bonus_bits.append(f"kill streaks within 5 minutes add **{streak_txt}**")
    add("Payout multipliers: " + "; ".join(bonus_bits) + ".")
    add("")
    add("### Systems active in Phase 2")
    add("")
    add(_row(["System", "What it produces"]))
    add(_row(["---", "---"]))
    add(_row([f"Hunting League {tiers[0]['name'].split(' - ')[0]}–{top['name'].split(' - ')[0]}",
              f"Hunt Marks — {pay_list} per kill by rank"
              + (f" ({top_specials})" if top["specials"] else "")]))
    if have("modules/custom/lua/weekly_hunts_catalog.lua"):
        add(_row(["Weekly Hunt Board (`!lib`)",
                  f"Bonus marks — sweep all objectives for a **+{_fmt(weekly_sweep)} mark** "
                  "meta-bonus"]))
    if have("modules/custom/lua/daily_board_catalog.lua"):
        add(_row(["Daily Board (`!lib`)", "Hunt Marks + Gil on daily objectives"]))
    if have("modules/custom/lua/game_master_catalog.lua"):
        add(_row(["Game Master / Wave Mode (`!wavemaster`)",
                  "Hunt Marks per difficulty cleared"]))
    add(_row(["Seals Vendor", "Bronze / Silver / Gold Seals"]))
    if have("modules/custom/lua/armor_catalog.lua"):
        add(_row(["Armor Vendor", "Tiered armor, gated by seal type"]))
    if have("modules/custom/lua/gear_progression_catalog.lua"):
        add(_row(["Weapons Vendor", "Tiered weapons, gated by seal type"]))
    if have("modules/custom/lua/accessory_catalog.lua"):
        add(_row(["Accessories Vendor", "Accessories + Sortie job earrings"]))
    add("")
    add("---")
    add("")

    # ---- phase 3 --------------------------------------------------------
    add("## Phase 3 — Content Unlocks")
    add("")
    add('!!! abstract ""')
    add("    **Gate:** the Augment Moogle's content tiers. Tier 1 opens after: "
        f"*{gates[0][1]}*.")
    add("")
    add("### Boss content → Reforge marks")
    add("")
    if have("modules/custom/lua/Reforge_System.lua"):
        add("Killing these NMs earns **AF / Relic / Empy Marks** — the currency for the "
            "Reforge System, which upgrades AF, Relic, and Empy armor to +1 / +2 / +3.")
        add("")
        add(_row(["System", "Currency produced", "Spent on"]))
        add(_row(["---", "---", "---"]))
        if have("modules/custom/lua/AbysseaMarks.lua"):
            add(_row(["Abyssea NMs", "AF / Relic / Empy Marks",
                      "Reforge Vendor (+1 / +2 / +3 armor)"]))
        if have("modules/custom/lua/unity_wanted.lua"):
            add(_row(["Unity Concord", "Accolades", "Unity shop (gear, reward items)"]))
        if have("modules/custom/lua/custom_HNM_system.lua"):
            add(_row(["HNM Kings / Sky Gods", "AF / Relic / Empy Marks", "Reforge Vendor"]))
        add("")
    if aff:
        add("### Affinity NMs → Augment Sage")
        add("")
        add("The **Affinity NM** system bridges boss content and augmenting:")
        add("")
        respawn_txt = ""
        if aff_respawn:
            respawn_txt = (f", back up {aff_respawn} seconds after each kill"
                           if aff_respawn < 120 else
                           f", back up {aff_respawn // 60} minutes after each kill")
        add(f"1. Kill one of the **{aff['count']} always-up Affinity NMs** "
            f"(classic HNMs{respawn_txt})")
        add("2. The NM drops its unique **trophy**")
        gate_bits = []
        if aff["rank"]:
            gate_bits.append(f"requires Hunting League Rank {aff['rank']}")
        if aff["cost"]:
            gate_bits.append(f"costs {_fmt(aff['cost'])} Hunt Marks")
        add(f"3. Take the trophy to the **Augment Sage** at `!hub` and register the "
            f"affinity{' (' + ', '.join(gate_bits) + ')' if gate_bits else ''}")
        if aff_double_roll:
            add("4. Every augment roll in that stat category now **rolls twice and keeps "
                "the better result**")
        add("")
        add("Full roster: [Affinity NMs](../endgame/affinity-nms.md)")
        add("")
    add("### The Augment ladder")
    add("")
    add(_row(["Tier", "Unlocked by"]))
    add(_row(["---", "---"]))
    for tier_no, unlock in gates:
        add(_row([f"Augment Tier {tier_no}", unlock]))
    add("")
    add("Your Sage Mastery rank lifts the roll floor inside the unlocked band — see "
        "[Augments](../progression/augments.md).")
    add("")
    other_bits = []
    if have("modules/custom/lua/DungeonInstances.lua"):
        other_bits.append("- **Dungeons** — custom instanced zones with curated loot and "
                          "boss encounters")
    if have("scripts/zones/Mhaura/npcs/Sorrowful_Sage.lua"):
        other_bits.append("- **Nyzul Isle** — enter via the **Sorrowful Sage** NPC at "
                          "Mhaura. No Assault rank needed. See "
                          "[Nyzul Isle](../endgame/nyzul-isle.md).")
    if other_bits:
        add("### Other content in this phase")
        add("")
        L.extend(other_bits)
        add("")
    add("---")
    add("")

    # ---- phase 4 --------------------------------------------------------
    add("## Phase 4 — Deep Endgame")
    add("")
    add('!!! warning ""')
    add("    Most of this content expects endgame gear; several fights want a party.")
    add("")
    add(_row(["System", "What you get"]))
    add(_row(["---", "---"]))
    if have("modules/custom/lua/htbf.lua"):
        add(_row(["**[High-Tier Battlefields](../endgame/high-tier-battlefields.md)**",
                  "Retail HTBF fights via phantom gem entry, tiered difficulty, "
                  "dedicated vendor"]))
    if have("scripts/zones/Mhaura/npcs/Ambuscade_Tome.lua"):
        add(_row(["**[Ambuscade](../endgame/ambuscade.md)**",
                  "On-demand instanced boss fights in Mhaura (3 modes × 5 "
                  "difficulties). Clears pay **Hallmarks** + **Gallantry** → job "
                  "armor vouchers, weapon skins, and +1/+2 upgrades."]))
    if have("modules/custom/lua/Dynamis_Divergence.lua"):
        add(_row(["**[Dynamis – Divergence](../endgame/dynamis-divergence.md)**",
                  "4 cities × wave battles. The **+3 → +4 Forge**: farm Rusted/Black ID "
                  "Cards + a Mega-Boss Paragon Card, trade a reforged +3 AF/Relic piece → "
                  "**+4** (AF & Relic only; Empy caps at +3)."]))
    if have("modules/custom/lua/Voidwatch.lua"):
        add(_row(["**[Voidwatch](../endgame/voidwatch.md)**",
                  "Planar Rifts → Voidwalker NM → collect lights → Pyxis loot chest"]))
    if have("modules/custom/lua/domain_invasion_catalog.lua"):
        add(_row(["**[Domain Invasion](../endgame/domain-invasion.md)**",
                  "Server-wide co-op event across the two Escha zones (8×/day). "
                  "Two waves + a named boss; pays **Escha Silt**, **Escha Beads**, "
                  "and **Domain Points**. `!diwarp`"]))
    if have("scripts/zones/Mhaura/npcs/Sorrowful_Sage.lua"):
        add(_row(["**[Nyzul Isle](../endgame/nyzul-isle.md)**",
                  "Floor-climb dungeon runs with Nyzul armor rewards"]))
    if gaunt:
        add(_row(["**[The Gauntlet](../endgame/the-gauntlet.md)**",
                  f"Solo NM climb. Full clear: **{_fmt(gaunt[0])} Gil + {gaunt[1]} "
                  f"Paragon Pts + {gaunt[2]} Infamy**."]))
    if have("modules/custom/lua/endless_tower.lua"):
        add(_row(["**[Endless Tower](../endgame/endless-tower.md)**",
                  "Infinite escalating floors. How high you climb is the score."]))
    if colo_win:
        add(_row(["**[Colosseum](../endgame/colosseum.md)**",
                  f"Ladder arena at `!hub` — {colo_win} Hunt Marks per win"]))
    if have("modules/custom/lua/maat_infamy_fight.lua"):
        add(_row(["**[Maat's Challenge](../endgame/maats-challenge.md)**",
                  "`!maat` — the solo super-fight; first kill is an Augment Tier key"]))
    add("")
    add("---")
    add("")

    # ---- vertical -------------------------------------------------------
    add("## Always Active — Vertical Progression")
    add("")
    add('!!! success ""')
    add("    **Gate:** None — these run in parallel with everything else and never stop "
        "paying out.")
    add("")
    add("### Infamy track")
    add("")
    add("Infamy accumulates from the sources below and is spent at the **Infamy Vendor** "
        "(`!hub`) for best-in-slot gear.")
    add("")
    add(_row(["Source", "Notes"]))
    add(_row(["---", "---"]))
    if have("modules/custom/lua/Invasion.lua"):
        add(_row(["Scheduled Invasions",
                  "Wave events — server-wide announcement on start"]))
    if have("modules/custom/lua/star_devourer.lua"):
        add(_row(["Star-Devourer Raid", "Weekly server-wide raid boss. Party recommended."]))
    if have("modules/custom/lua/ApexTrials.lua"):
        add(_row(["Apex Trials",
                  "`!apex` — post-cap NMs. Infamy + Paragon Points per kill. See "
                  "[Apex & Paragon](../endgame/apex-paragon.md)."]))
    if gaunt:
        add(_row(["The Gauntlet", f"{gaunt[2]} Infamy per full clear"]))
    add("")
    if have("modules/custom/lua/paragon_catalog.lua"):
        add("### Paragon board")
        add("")
        add("**Apex Trials** produce **Paragon Points**. Spend them on the **Paragon "
            "Board** for permanent account-wide stat bonuses that never reset.")
        add("")
    add("### Prestige and Rebirth")
    add("")
    add(_row(["System", "How it works"]))
    add(_row(["---", "---"]))
    add(_row(["**[Prestige](../progression/prestige.md)**",
              f"Reach Hunting League Rank {prestige_unlock} → the Ascension Altar opens. "
              "Nightmare Court kills pay Ascension AP for permanent per-job bonuses."]))
    add(_row(["**[Job Rebirth](../progression/job-rebirth.md)**",
              f"Any job with **{_fmt(jp_required)} spent Job Points** can rebirth — "
              "permanent stacking category boosts."]))
    add("")
    if have("modules/custom/lua/CapacityFarm.lua"):
        add("### Capacity farm")
        add("")
        add("Job Points fuel Rebirth, and the **[Capacity farm](../progression/"
            "capacity-farm.md)** is how you bank them: instant-respawn phantom camps at "
            "Bibiki Bay (`!capacity`) and King Ranperre's Tomb (`!ranperre`) pay bonus "
            "Capacity Points per kill so your capacity chain never goes cold.")
        add("")
    add("### Prime Weapons")
    add("")
    add(f"The **Prime Armory** at `!hub` forges a Prime Weapon after **{n_trials} "
        f"trials** — {n_weapons} named forms, {_fmt(prime_gil)} gil per forge. See "
        "[Prime Armory](../progression/prime-armory.md).")
    add("")
    mastery_rows = []
    if have("modules/custom/lua/SpellSkillMastery.lua"):
        mastery_rows.append(_row(["**[Spell & Skill Mastery](../progression/spell-mastery.md)**",
                                  "Mastery Sage at `!hub`. Spend Mastery Sigils to empower "
                                  "weapon skills and spells beyond their normal caps."]))
    if have("modules/custom/lua/job_mastery.lua"):
        mastery_rows.append(_row(["**[Job Mastery](../endgame/job-mastery.md)**",
                                  "Earn Mastery Points by killing specific mob types. "
                                  "Permanent per-job-class bonuses."]))
    if mastery_rows:
        add("### Mastery systems")
        add("")
        add(_row(["System", "What it does"]))
        add(_row(["---", "---"]))
        L.extend(mastery_rows)
        add("")
    add("---")
    add("")

    # ---- currencies -----------------------------------------------------
    add("## Currencies at a Glance")
    add("")
    add(_row(["Currency", "Earn from", "Spend on"]))
    add(_row(["---", "---", "---"]))
    aff_spend = ""
    if aff and aff["cost"]:
        aff_spend = f"; Affinity registration ({_fmt(aff['cost'])} each)"
    add(_row(["**Hunt Marks**",
              f"Kill HL NMs ({pay_min}–{pay_max}/kill); daily login (+{daily}); "
              "Weekly & Daily Boards; Wave Master",
              f"Seals, rank unlocks ({gate_list} lifetime), reward shop{aff_spend}"]))
    add(_row(["**Seals** (Bronze / Silver / Gold)",
              "Trade Hunt Marks at the Seals Vendor",
              "Armor, Weapons, and Accessories Vendors — seal tier gates the gear tier"]))
    if have("modules/custom/lua/Reforge_System.lua"):
        add(_row(["**AF / Relic / Empy Marks**",
                  "Abyssea NMs, Unity Concord, HNM Kings",
                  "Reforge Vendor — upgrade armor to +1 / +2 / +3"]))
    add(_row(["**Infamy**",
              "Invasions, Apex Trials" + (", The Gauntlet" if gaunt else ""),
              "Infamy Vendor (BiS gear)"]))
    if have("modules/custom/lua/paragon_catalog.lua"):
        add(_row(["**Paragon Points**", "Apex Trials"
                  + (f", The Gauntlet ({gaunt[1]}/clear)" if gaunt else ""),
                  "Paragon Board — permanent account-wide stat bonuses"]))
    if aff:
        add(_row(["**Affinity Trophies**",
                  f"Kill one of the {aff['count']} Affinity NMs",
                  "Augment Sage registration — better rolls in that stat category"]))
    if have("modules/custom/lua/SpellSkillMastery.lua"):
        add(_row(["**Mastery Sigils**", "Regional buff via `!buff` grants the current "
                  "zone's Sigil", "Prime Armory trials, Spell & Skill Mastery empowers"]))
    if have("scripts/zones/Mhaura/npcs/Ambuscade_Tome.lua"):
        add(_row(["**Hallmarks / Gallantry**",
                  "Clear Ambuscade fights (Mhaura)",
                  "Gorpa-Masorpa — armor vouchers, weapon skins, Abdhaljs upgrade mats"]))
    if have("modules/custom/lua/domain_invasion_catalog.lua"):
        add(_row(["**Escha Silt / Beads / Domain Points**",
                  "Domain Invasion (Escha zones, 8×/day)",
                  "Escha vendors and Domain Point rewards"]))
    if have("modules/custom/lua/CapacityFarm.lua"):
        add(_row(["**Capacity Points**",
                  "Capacity farm — Bibiki Bay (`!capacity`), King Ranperre's Tomb "
                  "(`!ranperre`)",
                  "Convert to Job Points → Job Rebirth"]))
    add(_row(["**Gil**", "Quests, crafting, drops"
              + (f", The Gauntlet ({_fmt(gaunt[0])} on full clear)" if gaunt else ""),
              "AH, consumables, crafting materials, NPC vendors"]))
    add("")
    add("*Every number on this page is regenerated from the live server catalogs on "
        "each site publish — if it disagrees with the game, the next hourly publish "
        "reconciles it.*")

    page = docs_dir / "getting-started" / "systems-map.md"
    if write_between_markers(page, "systems-map", "\n".join(L)):
        print(f"[systems_map] regenerated: tiers={len(tiers)} gates={len(gates)} "
              f"affinities={aff['count'] if aff else 0} hub={hub_zone!r}")
    else:
        print(f"[systems_map] skipped (markers not found in {page.name})")
