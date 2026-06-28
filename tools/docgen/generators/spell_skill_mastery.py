"""Sync docs/progression/spell-mastery.md with spell_skill_mastery_catalog.lua.

The Mastery Sage's sigil faucet (NM rotation + trickle), the WS/Spell potency
tracks, the three WS proc effects, and the one-time trait riders all come from
the catalog. Costs, per-tier values, the rotation pool size, and effect blurbs
are read straight from the Lua, so re-tuning any of them updates the page.

Markers written:
  mastery-sigils   — how Mastery Sigils are earned (NM rotation + trickle)
  mastery-potency  — WS Potency + Spell Potency tracks, per-tier gain + 5 costs
  mastery-effects  — the 3 WS proc effects (name, effect, per-tier value, costs)
  mastery-traits   — the WS + Spell one-time trait unlocks (name + cost)
"""
from __future__ import annotations

import re
from pathlib import Path

from tools.docgen._paths import resolve_source
from tools.docgen._markers import write_between_markers
from tools.docgen._luaparse import section, ints


def _first(pattern: str, text: str, default: str) -> str:
    m = re.search(pattern, text)
    return m.group(1) if m else default


def _g(v: float) -> str:
    """Trim trailing zeros: 0.03 -> '0.03', 50.0 -> '50'."""
    return f"{v:g}"


# ---------------------------------------------------------------------------

def _parse(text: str) -> dict:
    c: dict = {}

    c["currency"] = _first(r"CURRENCY_NAME\s*=\s*'([^']+)'", text, "Mastery Sigils")

    # Sigil faucet (trickle on any NM kill) ---------------------------------
    sig = section(text, "catalog.sigils")
    c["nm_trickle"] = "true" in (_first(r"nmTrickle\s*=\s*(\w+)", sig, "false").lower())
    c["nm_base"] = int(_first(r"nmBase\s*=\s*(\d+)", sig, "0"))
    c["nm_per_level"] = float(_first(r"nmPerLevel\s*=\s*([0-9.]+)", sig, "0"))
    c["nm_max"] = int(_first(r"nmMax\s*=\s*(\d+)", sig, "0"))

    # NM rotation (primary source) ------------------------------------------
    rot = section(text, "catalog.rotation")
    c["rot_enabled"] = "true" in (_first(r"enabled\s*=\s*(\w+)", rot, "false").lower())
    c["rot_period"] = int(_first(r"periodHours\s*=\s*(\d+)", rot, "24"))
    c["rot_active"] = int(_first(r"activeCount\s*=\s*(\d+)", rot, "0"))
    c["rot_reward"] = int(_first(r"reward\s*=\s*(\d+)", rot, "0"))
    c["rot_party"] = "true" in (_first(r"partyWide\s*=\s*(\w+)", rot, "false").lower())
    pool = section(rot, "pool")
    c["pool"] = [(lbl, zone.replace("_", " "))
                 for lbl, zone in re.findall(
                     r"label\s*=\s*'([^']+)'\s*,\s*zone\s*=\s*'([^']+)'", pool)]

    # Potency tracks --------------------------------------------------------
    c["max_tier"] = int(_first(r"catalog\.MAX_TIER\s*=\s*(\d+)", text, "5"))
    c["potency_cost"] = ints(_first(r"catalog\.POTENCY_COST\s*=\s*\{([^}]*)\}", text, ""))

    wsp = section(text, "catalog.wsPotency")
    c["ws_potency_blurb"] = _first(r"blurb\s*=\s*'([^']+)'", wsp, "")
    sp = section(text, "catalog.spellPotency")
    c["spell_potency_blurb"] = _first(r"blurb\s*=\s*'([^']+)'", sp, "")

    # WS proc effects -------------------------------------------------------
    c["effect_cost"] = ints(_first(r"catalog\.EFFECT_COST\s*=\s*\{([^}]*)\}", text, ""))
    fx = section(text, "catalog.wsEffects")
    c["effects"] = [
        {"name": name, "desc": desc}
        for name, desc in re.findall(
            r"name\s*=\s*'([^']+)'.*?desc\s*=\s*'([^']+)'", fx, re.DOTALL)
    ]

    # Trait riders ----------------------------------------------------------
    c["trait_cost"] = int(_first(r"catalog\.TRAIT_COST_DEFAULT\s*=\s*(\d+)", text, "40"))
    wst = section(text, "catalog.wsTraits")
    c["ws_traits"] = re.findall(r"name\s*=\s*'([^']+)'\s*,\s*desc\s*=\s*'([^']+)'", wst)
    spt = section(text, "catalog.spellTraits")
    c["spell_traits"] = re.findall(r"name\s*=\s*'([^']+)'\s*,\s*desc\s*=\s*'([^']+)'", spt)

    return c


# ---------------------------------------------------------------------------

def _hours_phrase(h: int) -> str:
    if h == 24:
        return "daily"
    if h % 24 == 0:
        return f"every {h // 24} days"
    return f"every {h} hours"


def _render_sigils(c: dict) -> str:
    cur = c["currency"]
    period = _hours_phrase(c["rot_period"])
    lines = []

    if c["rot_enabled"]:
        party = (" Everyone in your party in the same zone shares the credit."
                 if c.get("rot_party") else "")
        lines.append(
            f"**NM Rotation (primary):** A {period} rotation keeps "
            f"**{c['rot_active']}** target NMs live at once, drawn from a pool of "
            f"**{len(c['pool'])}**. Defeating a live target awards "
            f"**{c['rot_reward']} {cur}** — once per target per rotation."
            f"{party} Use `!empower` to see which targets are currently live."
        )

    if c.get("nm_trickle"):
        if c["nm_per_level"]:
            scale = (f" (scaling slightly with the mob's level, up to "
                     f"**{c['nm_max']} {cur}** per kill)")
        else:
            scale = f" (up to **{c['nm_max']} {cur}** per kill)"
        lines.append("")
        lines.append(
            f"**NM Trickle (secondary):** Any NM kill grants a small bonus of "
            f"**{c['nm_base']} {cur}**{scale}, so you are never fully dry between "
            f"rotation windows."
        )

    lines.append("")
    lines.append("**Current rotation pool:**")
    lines.append("")
    lines.append("| NM | Zone |")
    lines.append("|---|---|")
    for label, zone in c["pool"]:
        lines.append(f"| {label} | {zone} |")

    return "\n".join(lines)


def _render_potency(c: dict) -> str:
    costs = " / ".join(str(x) for x in c["potency_cost"])
    cur = c["currency"]
    lines = [
        f"Two tiered tracks, each up to **Tier {c['max_tier']}**. Buying a tier "
        f"adds its bonus on top of the previous tiers, and the gains re-apply "
        f"automatically every time you log in.",
        "",
        "| Track | Per tier | Affects |",
        "|---|---|---|",
        f"| **Weapon Skill Potency** | {_clean_blurb(c['ws_potency_blurb'])} | Damage on all of your weapon skills |",
        f"| **Spell Potency** | {_clean_blurb(c['spell_potency_blurb'])} | Magic Attack, base magic damage, and Cure potency |",
        "",
        f"**Tier costs ({cur}):** {costs} — each tier costs more than the last.",
    ]
    return "\n".join(lines)


def _clean_blurb(s: str) -> str:
    """Make a catalog blurb a touch more player-facing without inventing data."""
    s = s.replace("M.Atk", "Magic Attack")
    s = s.replace("magic dmg", "magic damage")
    s = s.replace("WS damage", "weapon skill damage")
    s = s.replace("weapon skill damage per tier", "weapon skill damage")
    s = re.sub(r"\s*per tier\s*$", "", s)
    return s


def _render_effects(c: dict) -> str:
    cur = c["currency"]
    costs = c["effect_cost"]
    cost_line = " / ".join(str(x) for x in costs) if costs else "—"
    lines = [
        "Per-player procs that fire automatically on every weapon skill once "
        "purchased. Each effect is tiered (buy higher tiers for a stronger proc), "
        "and they take effect immediately — no re-apply needed.",
        "",
        "| Effect | What it does |",
        "|---|---|",
    ]
    for fx in c["effects"]:
        lines.append(f"| **{fx['name']}** | {_strip_var(fx['desc'])} |")
    lines.append("")
    max_tier = max((len(costs), c["max_tier"]))
    lines.append(
        f"Each effect tiers up to **Tier {max_tier}**. "
        f"**Tier costs ({cur}):** {cost_line}."
    )
    return "\n".join(lines)


def _strip_var(s: str) -> str:
    return s.replace("WS ", "weapon skill ").replace("Per tier", "Per tier")


def _render_traits(c: dict) -> str:
    cur = c["currency"]
    cost = c["trait_cost"]
    lines = [
        f"One-time passive riders that attach to your character permanently. "
        f"Each costs **{cost} {cur}**.",
        "",
        "**Weapon Skill traits:**",
        "",
        "| Trait | Effect |",
        "|---|---|",
    ]
    for name, desc in c["ws_traits"]:
        lines.append(f"| **{name}** | {desc} |")
    lines.append("")
    lines.append("**Spell traits:**")
    lines.append("")
    lines.append("| Trait | Effect |")
    lines.append("|---|---|")
    for name, desc in c["spell_traits"]:
        lines.append(f"| **{name}** | {desc} |")
    return "\n".join(lines)


# ---------------------------------------------------------------------------

def generate(repo_root: Path, docs_dir: Path) -> None:
    src = resolve_source(repo_root, "modules/custom/lua/spell_skill_mastery_catalog.lua")
    if src is None:
        print("[spell_skill_mastery] skip: spell_skill_mastery_catalog.lua not found")
        return

    text = src.read_text(encoding="utf-8", errors="replace")
    c = _parse(text)

    page = docs_dir / "progression" / "spell-mastery.md"
    blocks = [
        ("mastery-sigils", _render_sigils(c)),
        ("mastery-potency", _render_potency(c)),
        ("mastery-effects", _render_effects(c)),
        ("mastery-traits", _render_traits(c)),
    ]
    written = sum(1 for marker, content in blocks
                  if write_between_markers(page, marker, content))
    print(f"[spell_skill_mastery] {written}/{len(blocks)} marker block(s) written "
          f"(rotation={len(c['pool'])} NMs, potency tiers={c['max_tier']}, "
          f"effects={len(c['effects'])}, traits={len(c['ws_traits']) + len(c['spell_traits'])})")
