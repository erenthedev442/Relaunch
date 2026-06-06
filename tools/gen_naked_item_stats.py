#!/usr/bin/env python3
"""Generate INSERT INTO item_mods statements for the 290 "naked" gear items
identified by gear_stat_audit.json.

How it works
------------
1. Reads gear_stat_audit.json to get the list of items and their itemId/shortName.
2. Reads scripts/enum/mod.lua to build a mod-name -> mod-id lookup.
3. Reads a stat cache file (tools/bgwiki_stats_cache.json) that contains the
   stat text extracted from BG-Wiki for each item.  The cache is populated by
   running web fetches via Claude Code or manually.  Each cache entry has:

       {
         "<itemId>": {
           "url":   "https://www.bg-wiki.com/ffxi/...",
           "name":  "Boii Mask +3",
           "stats": "DEF:144 HP+73 STR+43 ..."     # exact text from page
         },
         ...
       }

   Items that are not in the cache (or are flagged as unresolved in the cache)
   end up in tools/naked_items_unresolved.json.

4. Parses each stat string into (modId, value) tuples using regexes anchored
   on the canonical BG-Wiki stat names.  Any token we don't understand is
   recorded as a TODO comment and the item is flagged for manual review.

5. Emits sql/custom_naked_item_mods.sql with LOCK TABLES / UNLOCK TABLES and
   `INSERT INTO item_mods` lines that mirror the format used by item_mods.sql.

Run:
    python tools/gen_naked_item_stats.py

Re-run the script any time the cache changes.  The cache itself is hand
populated (or filled by ad-hoc fetches); the parser is deterministic so the
script never invents stat values that aren't in the cache.
"""

from __future__ import annotations

import json
import os
import re
import sys
from typing import Dict, List, Optional, Tuple

REPO = os.path.normpath(os.path.join(os.path.dirname(__file__), ".."))

GEAR_AUDIT_JSON       = os.path.join(REPO, "tools",   "gear_stat_audit.json")
MOD_LUA               = os.path.join(REPO, "scripts", "enum", "mod.lua")
STATS_CACHE_JSON      = os.path.join(REPO, "tools",   "bgwiki_stats_cache.json")
# Prefix the filename with `zz_` so it loads alphabetically AFTER
# item_mods.sql in dbtool's full update. Without the prefix, item_mods.sql's
# `DROP TABLE IF EXISTS item_mods` (line 16 of that upstream file) wipes
# every BG-Wiki row this generator emits, because 'c' < 'i'. With `zz_`,
# this file lands after item_mods.sql and its ON DUPLICATE KEY UPDATE
# inserts layer cleanly on top of upstream data.
OUTPUT_SQL            = os.path.join(REPO, "sql",     "zz_custom_naked_item_mods.sql")
UNRESOLVED_JSON       = os.path.join(REPO, "tools",   "naked_items_unresolved.json")


# ---------------------------------------------------------------------------
# Mod lookup
# ---------------------------------------------------------------------------
MOD_LINE_RE = re.compile(
    r"^\s*([A-Z][A-Z0-9_]*)\s*=\s*(\d+)\s*,?\s*(?:--.*)?$",
    re.MULTILINE,
)


def load_mod_enum(path: str) -> Dict[str, int]:
    """Read mod.lua and return { CONSTANT -> id }."""
    with open(path, "r", encoding="utf-8") as f:
        text = f.read()
    out: Dict[str, int] = {}
    for m in MOD_LINE_RE.finditer(text):
        out[m.group(1)] = int(m.group(2))
    return out


# ---------------------------------------------------------------------------
# Stat parsing
# ---------------------------------------------------------------------------
# Every entry maps a regex against the BG-Wiki stat text to a function returning
# a (mod_name, value) tuple.  The regex is run against the FULL text rather
# than tokenized, so order of patterns matters: more specific patterns first.
#
# The "scale" in the comment is what BG-Wiki shows; the value stored in
# item_mods is the LSB representation (e.g., haste % is stored as 1024ths of
# 1% -> 1% = 10).  Treat values exactly as they appear in similar retail
# entries in sql/item_mods.sql.

ParseRule = Tuple[re.Pattern, str, "Optional[callable]"]  # (regex, mod_name, value_xform)


def _ident(v: int) -> int:
    return v


def _haste(v: int) -> int:
    # BG-Wiki shows e.g. "Haste+7%" → store as 700 in item_mods (1024ths)
    return v * 100


def _dmg_taken(v: int) -> int:
    # "Damage taken -11%" → DMG mod 160, value stored as -1100 (base 10000)
    return v * 100


def _percent_dmg(v: int) -> int:
    # "Magic Damage Taken -%" similar to DMG mod handling
    return v * 100


def _quarter(v: int) -> int:
    # not currently used
    return v


# Order matters!  Put longer / more specific patterns first.
PARSE_RULES: List[ParseRule] = [
    # Damage taken modifiers (specific must come before generic)
    (re.compile(r"Physical damage taken\s*([+-]?\d+)%?", re.IGNORECASE), "DMGPHYS", _percent_dmg),
    (re.compile(r"Magic damage taken\s*([+-]?\d+)%?", re.IGNORECASE),    "DMGMAGIC", _percent_dmg),
    (re.compile(r"Ranged damage taken\s*([+-]?\d+)%?", re.IGNORECASE),   "DMGRANGE", _percent_dmg),
    (re.compile(r"Breath damage taken\s*([+-]?\d+)%?", re.IGNORECASE),   "DMGBREATH", _percent_dmg),
    (re.compile(r"Damage taken\s*([+-]?\d+)%?", re.IGNORECASE),         "DMG", _dmg_taken),

    # Haste (gear)
    (re.compile(r"\bHaste\s*\+?(\d+)%", re.IGNORECASE), "HASTE_GEAR", _haste),

    # Multi-attack chances (percent)
    (re.compile(r'"?Double Attack"?\s*\+?(\d+)%', re.IGNORECASE),  "DOUBLE_ATTACK", _ident),
    (re.compile(r'"?Triple Attack"?\s*\+?(\d+)%', re.IGNORECASE),  "TRIPLE_ATTACK", _ident),
    (re.compile(r'"?Quadruple Attack"?\s*\+?(\d+)%', re.IGNORECASE), "QUAD_ATTACK", _ident),
    (re.compile(r'"?Counter"?\s*\+?(\d+)%?', re.IGNORECASE),       "COUNTER", _ident),
    (re.compile(r'"?Kick[ -]Attacks?"?\s*\+?(\d+)%?', re.IGNORECASE), "KICK_ATTACK_RATE", _ident),
    (re.compile(r'"?Zanshin"?\s*\+?(\d+)%?', re.IGNORECASE),       "ZANSHIN", _ident),
    (re.compile(r'"?Subtle Blow"?\s*\+?(\d+)', re.IGNORECASE),     "SUBTLE_BLOW", _ident),
    (re.compile(r'"?Snapshot"?\s*\+?(\d+)%?', re.IGNORECASE),      "SNAPSHOT", _ident),
    (re.compile(r'"?Dual Wield"?\s*\+?(\d+)%?', re.IGNORECASE),    "DUAL_WIELD", _ident),
    (re.compile(r'"?Rapid Shot"?\s*\+?(\d+)%?', re.IGNORECASE),    "RAPID_SHOT", _ident),
    (re.compile(r'"?Double Shot"?\s*Rate\s*\+?(\d+)%?', re.IGNORECASE), "DOUBLE_SHOT_RATE", _ident),
    (re.compile(r'"?Store TP"?\s*\+?(\d+)', re.IGNORECASE),        "STORETP", _ident),
    (re.compile(r'"?Critical hit rate"?\s*\+?(\d+)%?', re.IGNORECASE), "CRITHITRATE", _ident),
    (re.compile(r'"?Critical hit damage"?\s*\+?(\d+)%?', re.IGNORECASE), "CRIT_DMG_INCREASE", _ident),
    (re.compile(r'"?Magic Crit\.? hit rate"?\s*\+?(\d+)%?', re.IGNORECASE), "MAGIC_CRITHITRATE", _ident),

    # Magic-related
    (re.compile(r'"?Magic Def\.? Bonus"?\s*\+?(\d+)', re.IGNORECASE), "MDEF", _ident),
    (re.compile(r'"?Magic Atk\.? Bonus"?\s*\+?(\d+)', re.IGNORECASE), "MATT", _ident),
    (re.compile(r'\bMagic Accuracy\s*\+?(\d+)', re.IGNORECASE),       "MACC", _ident),
    (re.compile(r'\bMagic Evasion\s*\+?(\d+)', re.IGNORECASE),        "MEVA", _ident),
    (re.compile(r'\bMagic Damage\s*\+?(\d+)\b', re.IGNORECASE),       "MAGIC_DAMAGE", _ident),
    (re.compile(r'"?Fast Cast"?\s*\+?(\d+)%?', re.IGNORECASE),        "FASTCAST", _ident),
    (re.compile(r'\bSpell interruption rate\s*-?(\d+)%?', re.IGNORECASE), "SPELLINTERRUPT", _ident),
    (re.compile(r'\bConserve MP\s*\+?(\d+)', re.IGNORECASE),          "CONSERVE_MP", _ident),
    (re.compile(r'"?Cure"? potency\s*\+?(\d+)%', re.IGNORECASE),      "CURE_POTENCY", _ident),

    # Ranged
    (re.compile(r'\bRanged Accuracy\s*\+?(\d+)', re.IGNORECASE),      "RACC", _ident),
    (re.compile(r'\bRanged Attack\s*\+?(\d+)', re.IGNORECASE),        "RATT", _ident),

    # Common combat
    (re.compile(r'\bAccuracy\s*\+?(\d+)', re.IGNORECASE),             "ACC", _ident),
    (re.compile(r'\bAttack\s*\+?(\d+)', re.IGNORECASE),               "ATT", _ident),
    (re.compile(r'\bEvasion\s*\+?(\d+)', re.IGNORECASE),              "EVA", _ident),
    (re.compile(r'\bEnmity\s*([+-]\d+)', re.IGNORECASE),              "ENMITY", _ident),
    (re.compile(r'\bResist Sleep\s*\+?(\d+)', re.IGNORECASE),         "SLEEPRES", _ident),

    # Weapon skill ratings (for earrings/jewelry that grant skill bonuses)
    (re.compile(r'\bHand[- ]to[- ]Hand\s+skill\s*\+?(\d+)', re.IGNORECASE), "HTH", _ident),
    (re.compile(r'\bDagger\s+skill\s*\+?(\d+)', re.IGNORECASE),        "DAGGER", _ident),
    (re.compile(r'\bSword\s+skill\s*\+?(\d+)', re.IGNORECASE),         "SWORD", _ident),
    (re.compile(r'\bGreat Sword\s+skill\s*\+?(\d+)', re.IGNORECASE),   "GSWORD", _ident),
    (re.compile(r'\bAxe\s+skill\s*\+?(\d+)', re.IGNORECASE),           "AXE", _ident),
    (re.compile(r'\bGreat Axe\s+skill\s*\+?(\d+)', re.IGNORECASE),     "GAXE", _ident),
    (re.compile(r'\bScythe\s+skill\s*\+?(\d+)', re.IGNORECASE),        "SCYTHE", _ident),
    (re.compile(r'\bPolearm\s+skill\s*\+?(\d+)', re.IGNORECASE),       "POLEARM", _ident),
    (re.compile(r'\bKatana\s+skill\s*\+?(\d+)', re.IGNORECASE),        "KATANA", _ident),
    (re.compile(r'\bGreat Katana\s+skill\s*\+?(\d+)', re.IGNORECASE),  "GKATANA", _ident),
    (re.compile(r'\bClub\s+skill\s*\+?(\d+)', re.IGNORECASE),          "CLUB", _ident),
    (re.compile(r'\bStaff\s+skill\s*\+?(\d+)', re.IGNORECASE),         "STAFF", _ident),
    (re.compile(r'\bArchery\s+skill\s*\+?(\d+)', re.IGNORECASE),       "ARCHERY", _ident),
    (re.compile(r'\bMarksmanship\s+skill\s*\+?(\d+)', re.IGNORECASE),  "MARKSMAN", _ident),
    (re.compile(r'\bThrowing\s+skill\s*\+?(\d+)', re.IGNORECASE),      "THROW", _ident),
    (re.compile(r'\bShield\s+skill\s*\+?(\d+)', re.IGNORECASE),        "SHIELD", _ident),
    (re.compile(r'\bParrying\s+skill\s*\+?(\d+)', re.IGNORECASE),      "PARRY", _ident),
    (re.compile(r'\bGuarding\s+skill\s*\+?(\d+)', re.IGNORECASE),      "GUARD", _ident),
    (re.compile(r'\bEvasion\s+skill\s*\+?(\d+)', re.IGNORECASE),       "EVASION", _ident),
    (re.compile(r'\bDivine magic\s+skill\s*\+?(\d+)', re.IGNORECASE),  "DIVINE", _ident),
    (re.compile(r'\bHealing magic\s+skill\s*\+?(\d+)', re.IGNORECASE), "HEALING", _ident),
    (re.compile(r'\bEnhancing magic\s+skill\s*\+?(\d+)', re.IGNORECASE), "ENHANCE", _ident),
    (re.compile(r'\bEnfeebling magic\s+skill\s*\+?(\d+)', re.IGNORECASE), "ENFEEBLE", _ident),
    (re.compile(r'\bElemental magic\s+skill\s*\+?(\d+)', re.IGNORECASE), "ELEM", _ident),
    (re.compile(r'\bDark magic\s+skill\s*\+?(\d+)', re.IGNORECASE),    "DARK", _ident),
    (re.compile(r'\bSummoning magic\s+skill\s*\+?(\d+)', re.IGNORECASE), "SUMMONING", _ident),
    (re.compile(r'\bNinjutsu\s+skill\s*\+?(\d+)', re.IGNORECASE),      "NINJUTSU", _ident),
    (re.compile(r'\bSinging\s+skill\s*\+?(\d+)', re.IGNORECASE),       "SINGING", _ident),
    (re.compile(r'\bString instrument\s+skill\s*\+?(\d+)', re.IGNORECASE), "STRING", _ident),
    (re.compile(r'\bWind instrument\s+skill\s*\+?(\d+)', re.IGNORECASE), "WIND", _ident),
    (re.compile(r'\bBlue magic\s+skill\s*\+?(\d+)', re.IGNORECASE),    "BLUE", _ident),
    (re.compile(r'\bGeomancy\s+skill\s*\+?(\d+)', re.IGNORECASE),      "GEOMANCY_SKILL", _ident),
    (re.compile(r'\bHandbell\s+skill\s*\+?(\d+)', re.IGNORECASE),      "HANDBELL_SKILL", _ident),

    # Resource pools / stats
    (re.compile(r'\bDEF\s*[:+]?\s*(\d+)', re.IGNORECASE),             "DEF", _ident),
    (re.compile(r'\bHP\s*[+:]\s*(\d+)', re.IGNORECASE),               "HP", _ident),
    (re.compile(r'\bMP\s*[+:]\s*(\d+)', re.IGNORECASE),               "MP", _ident),
    (re.compile(r'\bSTR\s*\+?(\d+)', re.IGNORECASE),                  "STR", _ident),
    (re.compile(r'\bDEX\s*\+?(\d+)', re.IGNORECASE),                  "DEX", _ident),
    (re.compile(r'\bVIT\s*\+?(\d+)', re.IGNORECASE),                  "VIT", _ident),
    (re.compile(r'\bAGI\s*\+?(\d+)', re.IGNORECASE),                  "AGI", _ident),
    (re.compile(r'\bINT\s*\+?(\d+)', re.IGNORECASE),                  "INT", _ident),
    (re.compile(r'\bMND\s*\+?(\d+)', re.IGNORECASE),                  "MND", _ident),
    (re.compile(r'\bCHR\s*\+?(\d+)', re.IGNORECASE),                  "CHR", _ident),

    # TP bonus / regain / refresh / regen
    (re.compile(r'"?TP Bonus"?\s*\+?(\d+)', re.IGNORECASE),            "TP_BONUS", _ident),
    (re.compile(r'"?Regain"?\s*\+?(\d+)', re.IGNORECASE),              "REGAIN", _ident),
    (re.compile(r'"?Refresh"?\s*\+?(\d+)\b(?!\s*potency)', re.IGNORECASE), "REFRESH", _ident),
    (re.compile(r'"?Refresh"? potency\s*\+?(\d+)', re.IGNORECASE),    "REFRESH", _ident),
    (re.compile(r'"?Regen"?\s*\+?(\d+)\b(?!\s*potency)', re.IGNORECASE), "REGEN", _ident),

    # Magic Burst
    (re.compile(r'\bMagic Burst\s*\+?(\d+)', re.IGNORECASE),           "MAGIC_BURST_BONUS_CAPPED", _ident),
    (re.compile(r'\bWeapon Skill Damage\s*\+?(\d+)%?', re.IGNORECASE), "ALL_WSDMG_ALL_HITS", _ident),
    (re.compile(r'"?Skillchain Bonus"?\s*\+?(\d+)', re.IGNORECASE),    "SKILLCHAINBONUS", _ident),

    # Pet stats (bundled) - retail "Pet: <X> +N" lines map to bundled mods that
    # cover multiple stats.  We do NOT individually handle these; if a token
    # like "Pet: Accuracy" appears we still emit a TODO comment via leftover.
    # Pet-only items end up in unresolved for manual placement in item_mods_pet.sql.

    # Less-common
    (re.compile(r'"?Treasure Hunter"?\s*\+?(\d+)', re.IGNORECASE),     "TREASURE_HUNTER", _ident),
    (re.compile(r'"?Mug"?\s*\+?(\d+)', re.IGNORECASE),                 "MUG_EFFECT", _ident),
    (re.compile(r'"?Steal"?\s*\+?(\d+)', re.IGNORECASE),               "STEAL", _ident),
    (re.compile(r'"?Despoil"?\s*\+?(\d+)', re.IGNORECASE),             "DESPOIL", _ident),
    (re.compile(r'\bFinishing Moves\s*\+?(\d+)', re.IGNORECASE),       "FINISHING_MOVES", _ident),
]


# Tokens to ignore entirely (not stat lines)
IGNORE_TOKENS = [
    re.compile(r'"Set:[^"]+"', re.IGNORECASE),
    re.compile(r'Lv\.?\s*\d+', re.IGNORECASE),
    re.compile(r'Item Level\s*\d+', re.IGNORECASE),
    re.compile(r'Augment'),
    re.compile(r'Latent'),
    re.compile(r'Enhances'),
    re.compile(r'Augments'),
    re.compile(r'All Races'),
    re.compile(r'\bAura\b'),
]


def parse_stats(text: str, modmap: Dict[str, int]) -> Tuple[List[Tuple[int, int, str]], List[str]]:
    """Return (rows, unknown_tokens).  rows = [(modId, value, label), ...]"""
    text = text or ""

    # Apply rules in order, blanking out matched segments to prevent re-matching.
    matches: List[Tuple[int, int, str]] = []
    work = text

    for regex, mod_name, xform in PARSE_RULES:
        # find all matches first so multiple instances would be flagged, but
        # normal gear has exactly one per stat
        new_segments = []
        last = 0
        for m in regex.finditer(work):
            try:
                raw = int(m.group(1))
            except (ValueError, IndexError):
                continue
            mod_id = modmap.get(mod_name)
            if mod_id is None:
                # Skip if the mod doesn't exist in the enum
                continue
            value = xform(raw)
            matches.append((mod_id, value, f"{mod_name}: {raw}"))
            new_segments.append(work[last:m.start()])
            # replace match with spaces of same length so positions don't shift
            new_segments.append(" " * (m.end() - m.start()))
            last = m.end()
        new_segments.append(work[last:])
        work = "".join(new_segments)

    # Anything that remains and isn't whitespace/ignored is unknown text.
    for ig in IGNORE_TOKENS:
        work = ig.sub(" ", work)

    # Remove common punctuation
    leftover = re.sub(r"[\s\n\r:,;.\-+\"'%\(\)\[\]\{\}/]+", " ", work).strip()
    unknown = [tok for tok in leftover.split() if not tok.isdigit() and len(tok) > 1]

    # Dedup matches by modId — keep the first occurrence (higher specificity).
    seen = set()
    uniq: List[Tuple[int, int, str]] = []
    for row in matches:
        if row[0] in seen:
            continue
        seen.add(row[0])
        uniq.append(row)
    return uniq, unknown


# ---------------------------------------------------------------------------
# Cache + audit input
# ---------------------------------------------------------------------------
def load_audit(path: str) -> List[Dict]:
    with open(path, "r", encoding="utf-8") as f:
        data = json.load(f)
    return data["naked_items"]


def load_cache(path: str) -> Dict[int, Dict]:
    if not os.path.exists(path):
        return {}
    with open(path, "r", encoding="utf-8") as f:
        raw = json.load(f)
    return {int(k): v for k, v in raw.items()}


def save_cache(path: str, cache: Dict[int, Dict]) -> None:
    with open(path, "w", encoding="utf-8") as f:
        json.dump({str(k): v for k, v in cache.items()}, f, indent=2,
                  ensure_ascii=False, sort_keys=True)


# ---------------------------------------------------------------------------
# Output writers
# ---------------------------------------------------------------------------
SQL_HEADER = """\
-- ---------------------------------------------------------------------------
-- Naked item stats sourced from BG-Wiki for items not in item_mods.sql.
-- Generated by tools/gen_naked_item_stats.py.  DO NOT HAND EDIT — re-run the
-- generator after updating tools/bgwiki_stats_cache.json.
--
-- Coverage: {resolved} of {total} naked items resolved; {unresolved} flagged
-- for manual review in tools/naked_items_unresolved.json.
-- ---------------------------------------------------------------------------

LOCK TABLES `item_mods` WRITE;

"""

SQL_FOOTER = """\

UNLOCK TABLES;
"""


def render_block(item_id: int, short_name: str, url: str,
                 wiki_name: str,
                 rows: List[Tuple[int, int, str]],
                 raw_stats: str) -> str:
    out: List[str] = []
    out.append(f"-- {item_id}: {short_name} -- BG-Wiki: {url}")
    if wiki_name and wiki_name != short_name:
        out.append(f"-- Wiki name: {wiki_name}")
    out.append(f"-- Raw: {raw_stats.strip()[:240]}")
    for mod_id, value, label in rows:
        # Use ON DUPLICATE KEY UPDATE so re-imports are idempotent. Without
        # this, dbtool's full DB refresh ERRORs out the moment any other
        # source (modules/custom/sql/, hand-applied patch, etc.) has
        # populated the same (itemId, modId) — exactly the failure we hit
        # on 2026-05-27 when reforge_plus3_mods.sql collided with this file.
        out.append(
            f"INSERT INTO `item_mods` VALUES ({item_id},{mod_id},{value}) "
            f"ON DUPLICATE KEY UPDATE `value` = VALUES(`value`);"
            f"    -- {label}"
        )
    out.append("")
    return "\n".join(out)


def main(argv: List[str]) -> int:
    audit = load_audit(GEAR_AUDIT_JSON)
    modmap = load_mod_enum(MOD_LUA)
    cache = load_cache(STATS_CACHE_JSON)

    resolved_blocks: List[str] = []
    unresolved: List[Dict] = []
    n_resolved = 0
    n_total = len(audit)

    for entry in audit:
        item_id    = entry["itemId"]
        short_name = entry["shortName"]
        context    = entry["context"]
        cached     = cache.get(item_id)

        if not cached or not cached.get("stats"):
            unresolved.append({
                "itemId":  item_id,
                "shortName": short_name,
                "context":  context,
                "reason":  (cached or {}).get("reason", "no BG-Wiki stats in cache"),
                "bgwiki":  (cached or {}).get("url", ""),
            })
            continue

        url        = cached.get("url", "")
        wiki_name  = cached.get("name", "")
        stats_text = cached.get("stats", "")

        rows, unknown = parse_stats(stats_text, modmap)
        if not rows:
            unresolved.append({
                "itemId":  item_id,
                "shortName": short_name,
                "context":  context,
                "reason":  "BG-Wiki text present but no recognized stat tokens",
                "bgwiki":  url,
                "raw":     stats_text,
                "unknown_tokens": unknown,
            })
            continue

        resolved_blocks.append(render_block(item_id, short_name, url, wiki_name, rows, stats_text))
        n_resolved += 1

        if unknown:
            # Surface for review, but DON'T block the item — we still emit
            # rows for the stats we DID recognize.
            unresolved.append({
                "itemId":  item_id,
                "shortName": short_name,
                "context":  context,
                "reason":  "partial parse — unknown tokens left over (item still emitted)",
                "bgwiki":  url,
                "raw":     stats_text,
                "unknown_tokens": unknown,
                "partial": True,
            })

    n_unresolved = sum(1 for u in unresolved if not u.get("partial"))

    # Write SQL
    os.makedirs(os.path.dirname(OUTPUT_SQL), exist_ok=True)
    with open(OUTPUT_SQL, "w", encoding="utf-8") as f:
        f.write(SQL_HEADER.format(resolved=n_resolved, total=n_total,
                                   unresolved=n_unresolved))
        f.write("\n".join(resolved_blocks))
        f.write(SQL_FOOTER)

    # Write unresolved JSON
    with open(UNRESOLVED_JSON, "w", encoding="utf-8") as f:
        json.dump(unresolved, f, indent=2, ensure_ascii=False)

    print(f"resolved      : {n_resolved} / {n_total}")
    print(f"unresolved    : {n_unresolved}")
    print(f"partial       : {sum(1 for u in unresolved if u.get('partial'))}")
    print(f"sql           : {OUTPUT_SQL}")
    print(f"unresolved.js : {UNRESOLVED_JSON}")
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
