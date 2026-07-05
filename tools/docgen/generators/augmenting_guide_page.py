"""Generate docs/progression/augmenting-guide.md — the plain-English
"start here" augmenting walkthrough — from the live Moogle config.

FULL-PAGE writer (idiom: spells.py). Narrative frame + headings are template
constants (heading text kept byte-stable for deep links); every number is
parsed from:

  modules/custom/lua/Augment_Moogle.lua           GIL_COST (flat trade cost),
                                                  MAX_CATALYST_COUNT (slots),
                                                  TIER_SLICES + TIER_GATES
                                                  (parsed via augment_sage's
                                                  _parse_tier_system)
  modules/custom/lua/augment_catalog.lua          catalyst count, per-catalyst
                                                  tier spread, and the worked
                                                  example's base/mult math
  modules/custom/lua/augment_catalyst_mobs.lua    the example catalyst's
                                                  assigned mob
  modules/custom/lua/augment_catalyst_drops.lua   DROP_RATE
  modules/custom/lua/augment_sage_catalog.lua     mastery rank count + crit
                                                  chance ladder
  modules/custom/lua/augment_affinity_catalog.lua affinity gate (HL rank +
                                                  mark cost)
  sql/item_basic.sql                              example catalyst item name

The worked example ("your first augment") is RENDERED FROM DATA: the module
finds the catalyst whose live label is exactly 'Attack', resolves its item
name, its assigned drop mob, and the live drop rate — so the example can
never name the wrong item. If that resolution fails the example degrades to
generic wording rather than inventing an item.

The `!augstats` display-quirk warning is a constant. The Moogle's hub is
emitted as the {{npc:augment_moogle}} token (npc_location_inject resolves it).

Fail-closed: missing required source -> print skip, leave the page untouched.
No last-updated footer — stamp.py owns that.
"""
from __future__ import annotations

import re
from pathlib import Path

from tools.docgen._paths import resolve_source
from tools.docgen.generators.augment_sage import (
    _parse_tier_system,
    _parse_mult_table,
    _parse_affinity_gate,
)
from tools.docgen.generators.progression_map import _parse_sage_ranks

_TAG = "[augmenting_guide_page]"


class _Skip(Exception):
    pass


def _read(repo_root: Path, rel: str, required: bool = True) -> str | None:
    src = resolve_source(repo_root, rel)
    if src is None:
        if required:
            raise _Skip(f"source not found: {rel}")
        return None
    return src.read_text(encoding="utf-8", errors="replace")


def _fmt(n: int) -> str:
    return f"{n:,}"


# ---------------------------------------------------------------- parsers


_ENTRY_RE = re.compile(r"^\s*\[(\d+)\]\s*=\s*\{(.*)\}\s*,?\s*$", re.MULTILINE)


def _parse_catalog_entries(text: str) -> dict[int, dict]:
    """augment_catalog.lua: itemId -> {augId, base, mult, cat, tier, label}.
    Entries are single-line tables; fields plucked by name so reordering is
    harmless."""
    out: dict[int, dict] = {}
    for m in _ENTRY_RE.finditer(text):
        item_id, body = int(m.group(1)), m.group(2)

        def num(field: str) -> float | None:
            fm = re.search(rf"\b{field}\s*=\s*([\d.]+)", body)
            return float(fm.group(1)) if fm else None

        label_m = re.search(r"label\s*=\s*'((?:[^'\\]|\\.)*)'", body)
        if label_m is None or num("augId") is None:
            continue
        out[item_id] = {
            "augId": int(num("augId")),
            "base":  num("base") if num("base") is not None else 1.0,
            "mult":  num("mult") if num("mult") is not None else 1.0,
            "cat":   int(num("cat")) if num("cat") is not None else 0,
            "tier":  int(num("tier")) if num("tier") is not None else 0,
            "label": label_m.group(1).replace("\\'", "'"),
        }
    return out


def _parse_mob_map(text: str) -> dict[str, tuple[int, str | None]]:
    """augment_catalyst_mobs.lua: mob internal name -> (itemId, 'L70' level
    hint from the trailing comment when present)."""
    out: dict[str, tuple[int, str | None]] = {}
    for m in re.finditer(r"\['([^']+)'\]\s*=\s*(\d+)\s*,?\s*(?:--(.*))?", text):
        mob, item_id, comment = m.group(1), int(m.group(2)), m.group(3) or ""
        lvl = re.search(r"\bL(\d+)\b", comment)
        out[mob] = (item_id, lvl.group(1) if lvl else None)
    return out


def _item_display_name(item_basic_text: str, item_id: int) -> str | None:
    m = re.search(
        rf"INSERT INTO `item_basic` VALUES \({item_id},\d+,'([^']*)'",
        item_basic_text,
    )
    if not m:
        return None
    return " ".join(w.capitalize() for w in m.group(1).split("_"))


def _resolve_example(repo_root: Path, entries: dict[int, dict]) -> dict | None:
    """Find the plain-'Attack' catalyst and its assigned mob + item name.
    Returns None (example degrades to generic wording) if anything is off."""
    attack = sorted(
        ((iid, e) for iid, e in entries.items() if e["label"] == "Attack"),
        key=lambda kv: (kv[1]["tier"], kv[0]),
    )
    if not attack:
        return None
    item_id, entry = attack[0]

    item_text = _read(repo_root, "sql/item_basic.sql", required=False)
    name = _item_display_name(item_text, item_id) if item_text else None

    mob_text = _read(repo_root, "modules/custom/lua/augment_catalyst_mobs.lua", required=False)
    mob = lvl = None
    if mob_text:
        for mob_name, (iid, mlvl) in _parse_mob_map(mob_text).items():
            if iid == item_id:
                mob, lvl = mob_name.replace("_", " "), mlvl
                break

    if not name or not mob:
        return None
    return {"item_id": item_id, "name": name, "mob": mob, "lvl": lvl, "entry": entry}


# Enrich the live gate strings with docs links. Fail-safe: an unmatched
# key simply leaves the gate text plain.
_GATE_LINKS = [
    ("Dynamis - Divergence", "[Dynamis - Divergence](../endgame/dynamis-divergence.md)"),
    ("Maat's Echo",          "[Maat's Echo](../endgame/maats-challenge.md)"),
    ("Voidspire",            "[Voidspire](../endgame/voidspire.md)"),
    ("Game Master",          "[Game Master](game-master.md)"),
    ("Hunting League",       "[Hunting League](index.md)"),
]


def _linkify_gate(text: str) -> str:
    for needle, link in _GATE_LINKS:
        if needle in text:
            text = text.replace(needle, link, 1)
    return text


def _val(entry: dict, roll: int) -> int:
    """Per-slot engine math: (base + roll) * max(mult, 1)."""
    return int((entry["base"] + roll) * max(entry["mult"], 1.0))


# ---------------------------------------------------------------- render


def _render(d: dict) -> str:
    gil       = d["gil"]
    max_cats  = d["max_cats"]
    slices    = d["slices"]           # [(min,max) x5]
    gates     = d["gates"]            # [(tier, unlock)]
    n_cats    = d["catalyst_count"]
    tier_dist = d["tier_dist"]        # catalyst tier -> count
    hi_labels = d["high_tier_labels"]
    ex        = d["example"]          # dict | None
    rate      = d["drop_rate"]        # int | None
    crit      = d["crit"]
    n_ranks   = d["n_ranks"]
    aff_rank, aff_cost = d["aff_gate"]
    reroll_gil = d["reroll_gil"]      # [gil per tier] | None

    t_last = len(slices)
    roll_top = slices[-1][1]
    crit_lo = f"{crit[0] * 100:.0f}%" if crit else "5%"
    crit_hi = f"{crit[-1] * 100:.0f}%" if crit else "30%"

    rate_txt = f"~{rate}% per kill" if rate is not None else "a strong per-kill chance"

    L: list[str] = []
    A = L.append

    A("# Augmenting: Start Here")
    A("")
    A("![Augment gem](../assets/emblems/augment.svg){ .lgnd-emblem }")
    A("")
    A(
        "New to augmenting and not sure where to begin? This is the plain-English "
        "guide. The two pages after it — [Augment Moogle](augments.md) and "
        "[Augment Sage](augment-sage.md) — are the full reference with every "
        "number; **this page is just how to start.**"
    )
    A("")
    A('!!! tip "The one-sentence version"')
    A(
        f"    Augmenting lets you **stamp custom stat bonuses onto any piece of "
        f"gear** — up to {max_cats} bonuses per piece — by trading a cheap "
        f"\"catalyst\" item to the **Augment Moogle** in {{{{npc:augment_moogle}}}}. "
        f"It's the single biggest source of character power on the Relaunch server."
    )
    A("")
    A("## What it is & what it does")
    A("")
    A(
        f"Every catalyst item maps to **one augment** (a stat bonus). Trade a "
        f"catalyst to the Augment Moogle along with a piece of gear, and that "
        f"bonus gets **written onto the gear**. Each piece has **{max_cats} "
        f"augment slots**, so you can stamp up to {max_cats} bonuses on it — and "
        f"you can stack the **same** catalyst to multiply one stat "
        f"({max_cats}× Attack catalysts = {max_cats} lines of Attack on one piece)."
    )
    A("")
    A(
        "This means **any** gear can become best-in-slot. That ring with no "
        "useful stats? Stamp it with +HP, +Attack, +Accuracy — whatever your "
        "build wants."
    )
    A("")
    A("## Your first augment")
    A("")
    A(
        "Let's add some **Attack** to a piece of gear. (Any stat works the same "
        "way — this is just an example.)"
    )
    A("")
    if ex:
        lvl_txt = f" (a level ~{ex['lvl']} mob)" if ex["lvl"] else ""
        A(
            f"1. **Farm the catalysts.** Every catalyst **drops from one specific "
            f"monster** ({rate_txt}) — catalysts are **no longer bought for gil**. "
            f"The \"Attack\" catalyst is **{ex['name']}**; its assigned mob is "
            f"**{ex['mob']}**{lvl_txt} — kill it until you have **{max_cats}×**. "
            f"Which catalysts you can trade scales with your progression — see "
            f"[Catalyst tiers](#catalyst-tiers-what-you-can-trade) below."
        )
    else:
        A(
            f"1. **Farm the catalysts.** Every catalyst **drops from one specific "
            f"monster** ({rate_txt}) — catalysts are **no longer bought for gil**. "
            f"Look the Attack catalyst up in the "
            f"[catalog](augments.md#catalyst--augment-catalog), then kill its "
            f"assigned mob until you have **{max_cats}×**. Which catalysts you "
            f"can trade scales with your progression — see "
            f"[Catalyst tiers](#catalyst-tiers-what-you-can-trade) below."
        )
    A(
        f"2. **Have {_fmt(gil)} gil** in your inventory (the Augment Moogle's "
        f"flat trade cost, no matter how many catalysts)."
    )
    A(
        "3. **Go to {{npc:augment_moogle}}** and find the **Augment Moogle** "
        "(it's in the row of moogles)."
    )
    A(
        f"4. **Trade** the gear piece **+ your {max_cats} catalysts** to the "
        f"Moogle. It shows you what's about to be applied."
    )
    A(
        f"5. **Confirm.** It takes the {_fmt(gil)} gil and hands your gear back "
        f"with **{max_cats} lines of Attack** stamped on it."
    )
    A("")
    A("That's it. You just augmented your first piece. 🎉")
    A("")
    A('!!! warning "Don\'t panic when the numbers look weird"')
    A(
        "    The in-game **item examine window will show garbled/negative "
        "values** on augmented gear — that's a known client display quirk, "
        "**the stats are really there.** To see your *true* augment values, type "
        "**`!augstats`**. (For total gear stats use `!getstats offensive` / "
        "`defensive` / `base`.)"
    )
    A("")
    A("## Every augment is a ROLL — the most important thing to understand")
    A("")
    A(
        f"Every line the Moogle writes is **rolled** inside your **Augment "
        f"Tier's band**. Your tier (1–{t_last}) is earned through **custom "
        f"content**, and each tier's band sits strictly above the one below it — "
        f"a fresh character rolls small numbers, an endgame character rolls huge "
        f"ones, **on the exact same catalyst**:"
    )
    A("")
    A(f"| Augment Tier | Roll band (of 0–{roll_top}) | How you unlock it |")
    A("|---|---|---|")
    for tier_no, unlock in gates:
        lo, hi = slices[tier_no - 1]
        A(f"| **T{tier_no}** | {lo}–{hi} | {_linkify_gate(unlock)} |")
    A("")
    A(
        f"The ladder is **consecutive** — your tier is the highest step you've "
        f"cleared in order, and a brand-new character is **Tier 0: the Moogle "
        f"won't augment at all** until the first gate is cleared."
    )
    A("")
    if ex:
        e = ex["entry"]
        v_floor = _val(e, slices[0][0])
        v_cap = _val(e, slices[-1][1])
        climb = (
            f" That +{v_floor}/slot Attack roll at Tier 1 climbs all the way to "
            f"**+{v_cap}/slot** at a max Tier-{t_last} roll (i.e. "
            f"**+{v_cap * max_cats} Attack** on a {max_cats}-slot piece)."
        )
    else:
        climb = ""
    A(
        f"(Trust summon counts climb a **separate** ladder — Unity Concord "
        f"accolades, Voidwatch rift tiers, and your Adventuring Fellow's level. "
        f"See the [Trust page](../reference/spells/trust.md).){climb} So:"
    )
    A("")
    A(
        f"> **Augment early, augment often, and re-stamp the same gear each time "
        f"you climb a tier.** Any T3 roll beats every T2 roll — re-rolling after "
        f"a tier-up is always an upgrade. Within a tier, re-trade to fish for the "
        f"top of the band."
    )
    A("")
    A("## How to roll higher (maximizing)")
    A("")
    A("Three things improve your rolls — stack all three to hit the ceiling:")
    A("")
    A("| Booster | What it does | How to get it |")
    A("|---|---|---|")
    A(
        f"| **Sage Mastery rank** | Ranks 1→{n_ranks} **raise the roll floor** "
        f"(+1 per rank within your band) and your crit chance ({crit_lo} → "
        f"{crit_hi}) | Unlocks automatically as you reach the required Hunting "
        f"League Rank / Prestige Level milestones — nothing is consumed |"
    )
    A(
        f"| **Category affinity** | **Roll twice, keep the better** for that "
        f"stat family | Reach **Hunting League Rank {aff_rank}**, then register "
        f"the affinity at the Sage with **{_fmt(aff_cost)} Hunt Marks** + that "
        f"category's **signature NM trophy** (consumed) |"
    )
    A(
        f"| **Critical augment** | A **PERFECT roll** — every line in the trade "
        f"lands at the top of your band | Happens randomly each trade (chance "
        f"rises with your rank). A **Maat's Cap** (from "
        f"[Maat's Challenge](../endgame/maats-challenge.md)) *guarantees* a crit "
        f"on your next trade. |"
    )
    A("")
    A(
        f"A max-rank, affinity-held **crit at Tier {t_last}** writes the "
        f"absolute cap: `(base + {roll_top}) × multiplier` per slot. The "
        f"[Augment Sage page](augment-sage.md) has the full formula, rank table, "
        f"and NM list."
    )
    A("")
    if reroll_gil:
        A("## Re-rolling in place with `!reroll`")
        A("")
        A(
            "Once a piece already has the augment **types** you want, you don't "
            "have to re-farm five catalysts just to chase bigger numbers. The "
            "**`!reroll`** command re-gambles the *magnitudes* of the augments "
            "already on an **equipped** item — the same roll math as the Moogle "
            "(your tier band, mastery floor, affinity double-roll, and crits all "
            "apply), but it keeps your existing lines and costs only **gil + one "
            "catalyst**."
        )
        A("")
        A("| | Augment Moogle (trade in {{npc:augment_moogle}}) | `!reroll <slot>` (equipped item) |")
        A("|---|---|---|")
        A("| **Changes** | Overwrites lines with the catalyst **types** you trade "
          "| Keeps the types, re-rolls the **numbers** |")
        A(f"| **Cost** | {_fmt(gil)} gil flat + up to {max_cats} catalysts "
          f"| Per-tier gil (below) + **1** matching catalyst |")
        A("| **Reach for it to** | Add or change *which* stats sit on the gear "
          "| Fish for higher rolls on gear you already like |")
        A("")
        A(
            "Both are **rank-floor protected** (never roll below `band min + your "
            "mastery rank`) and **capped at your tier band**, so neither can "
            "power-creep past your tier's ceiling — reroll is purely a cheaper way "
            "to re-fish the numbers you already have."
        )
        A("")
        A("**How to use it:**")
        A("")
        A("1. **Equip** the item you want to improve.")
        A(
            "2. Type **`!reroll <slot>`** (e.g. `!reroll head`) to **preview** — it "
            "lists each augment, the roll range, your floor, your crit %, and the "
            "cost. Nothing is charged."
        )
        A(
            "3. Type **`!reroll <slot> confirm`** to commit — it charges the gil + "
            "1 catalyst and re-rolls every line at once."
        )
        A("4. **Re-equip** the item to apply the fresh values.")
        A("")
        A(
            "Slots: `main sub ranged ammo head body hands legs feet neck waist "
            "ear1 ear2 ring1 ring2 back`. The catalyst it consumes must match "
            "**one of the augments already on the item** — and you have to be "
            "holding it."
        )
        A("")
        A("**Reroll cost by Augment Tier** (plus the one matching catalyst):")
        A("")
        A("| Augment Tier | Reroll cost |")
        A("|---|---:|")
        for i, cost in enumerate(reroll_gil, start=1):
            A(f"| **T{i}** | {_fmt(cost)} gil |")
        A("")
        A(
            "Because every line re-rolls together, a **crit** (or a guaranteed one "
            "from a **Maat's Cap**) turns a single reroll into a perfect roll of "
            "the *whole piece*. And since rolls are floor-protected, rerolling "
            "after a **tier-up** or a **mastery rank-up** only ever lifts your "
            "weakest lines — it's the cheap way to keep already-good gear current."
        )
        A("")
    A("## Catalyst tiers: what you can trade")
    A("")
    open_count = tier_dist.get(0, 0) + tier_dist.get(1, 0)
    hi_txt = ", ".join(hi_labels) if hi_labels else "the top universal stats"
    dist_txt = " · ".join(
        f"T{t} ×{tier_dist[t]}" for t in sorted(tier_dist) if tier_dist[t]
    )
    A(
        f"Separately from the roll band, each **catalyst** has a tier "
        f"(T0–T{max(tier_dist) if tier_dist else t_last}) — the minimum Augment "
        f"Tier required to trade it. T0/T1 catalysts ({open_count} of them) are "
        f"open to everyone; the universally-powerful stats ({hi_txt}...) sit at "
        f"T3–T5, so the strongest *stats* and the strongest *rolls* unlock "
        f"together as you clear content. The "
        f"[catalog](augments.md#catalyst--augment-catalog) groups every catalyst "
        f"by tier ({dist_txt})."
    )
    A("")
    A("## Good first moves")
    A("")
    A(
        "- **Pick stats you actually use.** DD? Stack **Attack** and "
        "**Accuracy**. Tank? **HP**, **Defense**, and the **−Phys. dmg. taken** "
        "catalysts. Caster? **Magic Accuracy** / **Magic Atk**."
    )
    A(
        f"- **Stack one stat for a big swing.** {max_cats}× the same catalyst on "
        f"one piece concentrates the bonus where you want it."
    )
    A(
        "- **Start the Augment Sage early.** Mastery ranks unlock automatically "
        "as you hit Hunting League Rank / Prestige Level milestones — each rank "
        "lifts your worst rolls and raises crit chance. Don't wait."
    )
    A(
        "- **Re-augment after every tier-up.** Same gear, same catalysts, a "
        "strictly higher band — a tier-up re-roll is never a downgrade."
    )
    A(
        f"- **Browse the full catalog** on the "
        f"[Augment Moogle page](augments.md#catalyst--augment-catalog) — "
        f"{n_cats} catalysts across a wide range of stat families, each with its "
        f"full per-trade stat values."
    )
    A("")
    A("## A few rules to remember")
    A("")
    A(f"- **{max_cats} catalysts max per trade** ({max_cats} augment slots per piece).")
    A("- **Catalysts are consumed; gear is not** — your gear comes back stamped.")
    A(
        f"- **Re-augmenting overwrites** the piece's existing augments — that's "
        f"how you upgrade them as you rank up, but it means you re-apply all "
        f"{max_cats} lines each time."
    )
    A("- **Cancel any time** during the confirm menu to get everything back.")
    A("")
    A("---")
    A("")
    A(
        "**Ready for the details?** → [Augment Moogle](augments.md) (the full "
        "catalyst catalog & exact numbers) · [Augment Sage](augment-sage.md) "
        "(ranking up & affinities)"
    )
    A("")

    return "\n".join(L)


# ---------------------------------------------------------------- entry point


def generate(repo_root: Path, docs_dir: Path) -> None:
    try:
        moogle_text = _read(repo_root, "modules/custom/lua/Augment_Moogle.lua")
        catalog_text = _read(repo_root, "modules/custom/lua/augment_catalog.lua")
        sage_text = _read(repo_root, "modules/custom/lua/augment_sage_catalog.lua")
        aff_text = _read(repo_root, "modules/custom/lua/augment_affinity_catalog.lua")
        drops_text = _read(repo_root, "modules/custom/lua/augment_catalyst_drops.lua", required=False)
        reroll_text = _read(repo_root, "modules/custom/commands/reroll.lua", required=False)

        gil_m = re.search(r"^\s*local\s+GIL_COST\s*=\s*(\d+)", moogle_text, re.MULTILINE)
        max_m = re.search(r"^\s*local\s+MAX_CATALYST_COUNT\s*=\s*(\d+)", moogle_text, re.MULTILINE)
        if not (gil_m and max_m):
            raise _Skip("Augment_Moogle.lua: GIL_COST / MAX_CATALYST_COUNT not parsed")

        try:
            slices, gates = _parse_tier_system(moogle_text)
        except ValueError as e:
            raise _Skip(f"Augment_Moogle.lua: {e}")

        entries = _parse_catalog_entries(catalog_text)
        if len(entries) < 50:
            raise _Skip(
                f"augment_catalog.lua: only {len(entries)} entries parsed — "
                "field shape probably changed"
            )

        tier_dist: dict[int, int] = {}
        for e in entries.values():
            tier_dist[e["tier"]] = tier_dist.get(e["tier"], 0) + 1

        # Deterministic, data-backed "high tier" example labels: preferred
        # marquee stats that actually sit at catalyst tier >= 3 in the live
        # catalog (so e.g. Haste, which is T1 live, can't sneak in).
        preferred = [
            "Triple Atk", "Quadruple Attack", "Damage Taken",
            "Weapon skill damage", "Crit. hit damage", "Haste",
        ]
        by_label = {e["label"]: e for e in entries.values()}
        hi_labels = [p for p in preferred if p in by_label and by_label[p]["tier"] >= 3][:3]

        drop_rate = None
        if drops_text:
            r = re.search(r"^\s*local\s+DROP_RATE\s*=\s*(\d+)", drops_text, re.MULTILINE)
            drop_rate = int(r.group(1)) if r else None

        example = _resolve_example(repo_root, entries)

        # !reroll gil cost ladder (per Augment Tier). Fail-safe: if the command
        # or its GIL_BY_TIER table is missing, the reroll section is dropped
        # rather than invented.
        reroll_gil = None
        if reroll_text:
            rm = re.search(r"GIL_BY_TIER\s*=\s*\{([^}]*)\}", reroll_text)
            if rm:
                nums = [int(x) for x in re.findall(r"\d+", rm.group(1))]
                reroll_gil = nums or None

        data = {
            "gil":              int(gil_m.group(1)),
            "max_cats":         int(max_m.group(1)),
            "slices":           slices,
            "gates":            gates,
            "catalyst_count":   len(entries),
            "tier_dist":        tier_dist,
            "high_tier_labels": hi_labels,
            "example":          example,
            "drop_rate":        drop_rate,
            "crit":             _parse_mult_table(sage_text, "critChance"),
            "n_ranks":          len(_parse_sage_ranks(sage_text)),
            "aff_gate":         _parse_affinity_gate(aff_text),
            "reroll_gil":       reroll_gil,
        }
    except (_Skip, RuntimeError, ValueError) as e:
        # RuntimeError/ValueError = a reused parser's own schema-regression
        # guard fired. Same fail-closed handling: keep the published page.
        print(f"{_TAG} skip: {e}")
        return

    content = _render(data)
    page = docs_dir / "progression" / "augmenting-guide.md"
    page.parent.mkdir(parents=True, exist_ok=True)
    page.write_text(content, encoding="utf-8")

    ex = data["example"]
    ex_txt = (
        f"example={ex['name']} <- {ex['mob']} @ {data['drop_rate']}%"
        if ex else "example=GENERIC (catalyst/mob resolution failed)"
    )
    reroll_txt = (
        f"reroll={'/'.join(_fmt(g) for g in data['reroll_gil'])}"
        if data["reroll_gil"] else "reroll=OMITTED (reroll.lua not parsed)"
    )
    print(
        f"{_TAG} wrote progression/augmenting-guide.md "
        f"(gil={_fmt(data['gil'])}, slots={data['max_cats']}, "
        f"{len(data['gates'])} tier gates, {data['catalyst_count']} catalysts, {ex_txt}, {reroll_txt})"
    )
