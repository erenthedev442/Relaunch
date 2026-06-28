"""Sync docs/endgame/casino.md with casino_catalog.lua.

Lady Luck's bet tiers, the four games' payouts, and the resulting house edges
all come from the catalog. The edges are *computed* from the weights/payouts
(not copied from a comment), so re-tuning a payout updates the published odds.

Markers written:
  casino-access  — NPC + zone line
  casino-bets    — bet tiers + jackpot-shout threshold
  casino-games   — the four-game table with payouts + computed house edge
"""
from __future__ import annotations

import re
from pathlib import Path

from tools.docgen._paths import resolve_source
from tools.docgen._markers import write_between_markers
from tools.docgen._luaparse import section, ints, commafy


def _parse(text: str) -> dict:
    c: dict = {}

    m = re.search(r"catalog\.npcName\s*=\s*'([^']+)'", text)
    c["npc"] = m.group(1) if m else "Lady Luck"

    m = re.search(r"catalog\.zoneId\s*=\s*xi\.zone\.(\w+)", text)
    c["zone"] = m.group(1).replace("_", " ").title() if m else "GM Home"

    m = re.search(r"catalog\.betTiers\s*=\s*\{([^}]*)\}", text)
    c["bets"] = ints(m.group(1)) if m else []

    m = re.search(r"catalog\.jackpotBroadcast\s*=\s*(\d+)", text)
    c["jackpot"] = int(m.group(1)) if m else None

    # Slots: weighted 3-reel strip + three-of-a-kind payouts.
    slots = section(text, "catalog.slots")
    reel = section(slots, "reel")
    c["reel"] = [(s, int(w)) for s, w in
                 re.findall(r"sym\s*=\s*'([^']+)'\s*,\s*weight\s*=\s*(\d+)", reel)]
    three = section(slots, "three")
    c["three"] = {s: int(p) for s, p in re.findall(r"\['([^']+)'\]\s*=\s*(\d+)", three)}

    # High-Low: odds-based, constant edge.
    hl = section(text, "catalog.highlow")
    c["hl_edge"] = float(_first(r"houseEdge\s*=\s*([0-9.]+)", hl, "0.08"))

    # Roulette: single-zero wheel.
    rl = section(text, "catalog.roulette")
    c["rl_slots"] = int(_first(r"slots\s*=\s*(\d+)", rl, "37"))
    c["rl_even"] = int(_first(r"evenPay\s*=\s*(\d+)", rl, "2"))
    c["rl_green"] = int(_first(r"greenPay\s*=\s*(\d+)", rl, "35"))

    # Dice: 2d6 band bets.
    dc = section(text, "catalog.dice")
    c["dice_hl"] = float(_first(r"highLowPay\s*=\s*([0-9.]+)", dc, "2.25"))
    c["dice_7"] = float(_first(r"sevenPay\s*=\s*([0-9.]+)", dc, "5"))
    return c


def _first(pattern: str, text: str, default: str) -> str:
    m = re.search(pattern, text)
    return m.group(1) if m else default


def _pct(edge: float) -> str:
    return f"{edge * 100:.1f}%"


# ---------------------------------------------------------------------------

def _render_access(c: dict) -> str:
    zone = c.get("zone", "GM Home")
    return (f"**{c['npc']}** holds court in **{zone}** — step up to the table, "
            f"pick a game, and place your stake.")


def _render_bets(c: dict) -> str:
    tiers = " / ".join(f"{commafy(b)}" for b in c["bets"])
    lines = [f"**Stakes:** {tiers} gil."]
    if c.get("jackpot"):
        lines.append("")
        lines.append(f"Any single win of **{commafy(c['jackpot'])} gil or more** "
                     f"is shouted server-wide — bragging rights included.")
    return "\n".join(lines)


def _render_games(c: dict) -> str:
    # --- Slots house edge: RTP = sum (weight/total)^3 * payout ---
    total_w = sum(w for _, w in c["reel"]) or 1
    rtp = sum((w / total_w) ** 3 * c["three"].get(s, 0) for s, w in c["reel"])
    slots_edge = 1.0 - rtp
    slots_pays = ", ".join(
        f"{s}×3 = {c['three'].get(s, 0)}×"
        for s, _ in sorted(c["reel"], key=lambda r: -c["three"].get(r[0], 0))
    )

    # --- Roulette edges: even-money winners = (slots-1)/2, green = 1 slot ---
    even_winners = (c["rl_slots"] - 1) // 2
    rl_even_edge = 1.0 - c["rl_even"] * even_winners / c["rl_slots"]
    rl_green_edge = 1.0 - c["rl_green"] * 1 / c["rl_slots"]

    # --- Dice edges: 2d6 probabilities are fixed (High 8-12 / Low 2-6 = 15/36; 7 = 6/36) ---
    dice_hl_edge = 1.0 - c["dice_hl"] * 15 / 36
    dice_7_edge = 1.0 - c["dice_7"] * 6 / 36

    rows = [
        "| Game | How it works | Payouts | House edge |",
        "|---|---|---|---|",
        f"| **Slots** | Spin three reels, match three symbols | {slots_pays} | ~{_pct(slots_edge)} |",
        f"| **High-Low** | A card 1–{_hl_ranks(c)} is shown; bet whether the next is higher or lower | Odds-based — safe calls pay barely over 1×, long shots pay big | ~{_pct(c['hl_edge'])} |",
        f"| **Roulette** | Single-zero wheel (0–{c['rl_slots'] - 1}); bet a colour/odd/even or a single number | Even-money **{c['rl_even']}×**, single number **{c['rl_green']}×** | ~{_pct(rl_even_edge)} even / ~{_pct(rl_green_edge)} single |",
        f"| **Dice** | Roll 2d6; bet the **High (8–12)** / **Low (2–6)** band or **Lucky 7** | High/Low **{_g(c['dice_hl'])}×**, Lucky 7 **{_g(c['dice_7'])}×** | ~{_pct(dice_hl_edge)} band / ~{_pct(dice_7_edge)} on 7 |",
    ]
    return "\n".join(rows)


def _hl_ranks(c: dict) -> int:
    return c.get("hl_ranks", 13)


def _g(v: float) -> str:
    return f"{v:g}"


# ---------------------------------------------------------------------------

def generate(repo_root: Path, docs_dir: Path) -> None:
    src = resolve_source(repo_root, "modules/custom/lua/casino_catalog.lua")
    if src is None:
        print("[casino] skip: casino_catalog.lua not found")
        return

    text = src.read_text(encoding="utf-8", errors="replace")
    # high-low rank count, for the prose
    m = re.search(r"catalog\.highlow\s*=\s*\{[^}]*ranks\s*=\s*(\d+)", text)
    c = _parse(text)
    c["hl_ranks"] = int(m.group(1)) if m else 13

    page = docs_dir / "endgame" / "casino.md"
    blocks = [
        ("casino-access", _render_access(c)),
        ("casino-bets", _render_bets(c)),
        ("casino-games", _render_games(c)),
    ]
    written = sum(1 for marker, content in blocks if write_between_markers(page, marker, content))
    print(f"[casino] {written}/{len(blocks)} marker block(s) written "
          f"(games=4, bet tiers={len(c['bets'])})")
