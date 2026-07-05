"""Shared helpers for the slot-first gear-vendor tables.

The Armor / Weapons / Accessory vendors on docs/progression/gear-vendors.md
all present the same three medal tiers (Bronze / Silver / Gold). Previously
each vendor was split into three per-tier sections; the page now reads
SLOT-FIRST — one table per gear slot (or weapon category), with the tier
shown as a colored pill column so a shopper sees every option for a slot in
one place.

These helpers render the shared Tier pill + the per-vendor tier legend so the
three generators stay visually identical. Pill styling lives in
docs/assets/gear-vendors.css.
"""
from __future__ import annotations

TIER_ORDER = ("bronze", "silver", "gold")
TIER_LABEL = {"bronze": "Bronze", "silver": "Silver", "gold": "Gold"}
# Medal emoji reinforce the pill color (and survive if the CSS ever fails to load).
TIER_EMOJI = {"bronze": "\U0001F949", "silver": "\U0001F948", "gold": "\U0001F947"}


def tier_pill(tier_key: str, currency: str | None = None) -> str:
    """Inline-HTML pill for the Tier column. `currency` (when given) becomes
    the hover title so a player can confirm which medal a tier costs without a
    separate column. Emits no pipe/newline chars, so it's table-cell safe."""
    label = TIER_LABEL.get(tier_key, tier_key.capitalize())
    emoji = TIER_EMOJI.get(tier_key, "")
    title = f' title="Paid in {currency}"' if currency else ""
    return f'<span class="tier-pill tier-{tier_key}"{title}>{emoji}&nbsp;{label}</span>'


def tier_legend(tier_currency: dict, descriptions: dict | None = None) -> str:
    """One-line legend shown under a vendor heading: each tier's pill + its
    currency + an optional short description, using the SAME pills the rows
    use. Returned as a plain markdown paragraph line (caller adds blank
    lines around it)."""
    parts = []
    for t in TIER_ORDER:
        cur = tier_currency.get(t, "")
        desc = descriptions.get(t) if descriptions else None
        tail = ""
        if cur and desc:
            tail = f" {cur} — {desc}"
        elif cur:
            tail = f" {cur}"
        elif desc:
            tail = f" — {desc}"
        parts.append(f"{tier_pill(t)}{tail}")
    return "**Tiers:** " + " · ".join(parts)


def tier_summary(per_tier: dict, noun: str = "pieces") -> str:
    """Italic one-liner: 'N pieces — 🥉 A Bronze · 🥈 B Silver · 🥇 C Gold ...'."""
    total = sum(per_tier.get(t, 0) for t in TIER_ORDER)
    bits = " · ".join(
        f"{TIER_EMOJI[t]} {per_tier.get(t, 0)} {TIER_LABEL[t]}" for t in TIER_ORDER
    )
    return (
        f"_{total} {noun} — {bits}. Each slot lists every tier together — "
        f"pick by your job and the medal you have._"
    )
