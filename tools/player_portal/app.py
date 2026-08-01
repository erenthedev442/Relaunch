"""
Legendary FFXI -- Player Portal API (FastAPI)
=============================================
Authenticates players against the live LandSandBoat `accounts` table (bcrypt)
and returns account/character data. READ-ONLY against xidb.

Public (no login):
  GET  /api/status                 -> who's online now + population
  GET  /api/profile/{name}         -> a character's public trophy page data
  GET  /c/{name}                   -> the public profile page (HTML)
  GET  /status.html                -> the live server status page

Authenticated (session cookie):
  POST /api/login   { login, password }   -> sets session cookie
  GET  /api/me                             -> account + characters (+ progression)
  GET  /api/inventory/{charid}             -> your character's inventory (own account only)
  POST /api/logout                         -> clears the cookie

Run (dev):   uvicorn app:app --host 127.0.0.1 --port 8080 --reload
Config:      copy .env.example -> .env and fill it in.

SECURITY NOTES
  * Passwords verified against the existing bcrypt hash -- plaintext never stored/logged.
  * Use the dedicated READ-ONLY DB user from README.md (NOT xiuser).
  * Bind to 127.0.0.1; expose ONLY through the tunnel. Inventory is scoped to the
    logged-in account; public endpoints deliberately omit gil/inventory/location-history.
"""
from __future__ import annotations

import datetime
import html
import json
import os
import re
import time
import urllib.parse
import urllib.request
from collections import defaultdict, deque
from pathlib import Path

import bcrypt
import jwt  # PyJWT
import pymysql
from dotenv import load_dotenv
from fastapi import FastAPI, HTTPException, Request, Response
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import FileResponse, HTMLResponse, JSONResponse, Response
from fastapi.staticfiles import StaticFiles
from pydantic import BaseModel
from pymysql.cursors import DictCursor

load_dotenv(os.path.join(os.path.dirname(os.path.abspath(__file__)), ".env"))  # cwd-independent

# ------------------------------------------------------------------ config ----
DB_HOST = os.getenv("PORTAL_DB_HOST", "127.0.0.1")
DB_PORT = int(os.getenv("PORTAL_DB_PORT", "3306"))
DB_USER = os.getenv("PORTAL_DB_USER", "portal_ro")   # dedicated READ-ONLY user
DB_PASS = os.getenv("PORTAL_DB_PASS", "")
DB_NAME = os.getenv("PORTAL_DB_NAME", "xidb")
# Writes (offline item move/discard) use a SEPARATE, tightly-scoped user so the
# read paths stay read-only. Defaults to the read user for local dev.
DB_WRITE_USER = os.getenv("PORTAL_DB_WRITE_USER", DB_USER)
DB_WRITE_PASS = os.getenv("PORTAL_DB_WRITE_PASS", DB_PASS)

JWT_SECRET      = os.getenv("PORTAL_JWT_SECRET", "")
JWT_TTL_HOURS   = int(os.getenv("PORTAL_JWT_TTL_HOURS", "12"))
COOKIE_NAME     = os.getenv("PORTAL_COOKIE_NAME", "portal_session")
COOKIE_SECURE   = os.getenv("PORTAL_COOKIE_SECURE", "true").lower() == "true"
COOKIE_SAMESITE = os.getenv("PORTAL_COOKIE_SAMESITE", "lax")
CORS_ORIGINS    = [o.strip() for o in os.getenv("PORTAL_CORS_ORIGINS", "").split(",") if o.strip()]

# Public base URL (absolute links in share-card OpenGraph tags). No trailing slash.
PUBLIC_URL      = os.getenv("PORTAL_PUBLIC_URL", "https://portal.ffxi-legendary.com").rstrip("/")
# Shared secret the sampler cron passes to /api/internal/tick (feed + push).
TICK_KEY        = os.getenv("PORTAL_TICK_KEY", "")
# Optional Discord webhook -- notable events (rank-ups, big kills) are relayed here.
DISCORD_WEBHOOK = os.getenv("PORTAL_DISCORD_WEBHOOK", "")
# Web Push (VAPID). Optional: push degrades to in-app + Discord if unset/lib absent.
VAPID_PUBLIC    = os.getenv("PORTAL_VAPID_PUBLIC", "")
VAPID_PRIVATE   = os.getenv("PORTAL_VAPID_PRIVATE", "")
VAPID_SUBJECT   = os.getenv("PORTAL_VAPID_SUBJECT", "mailto:admin@ffxi-legendary.com")

if len(JWT_SECRET) < 32:
    raise RuntimeError(
        "PORTAL_JWT_SECRET must be >=32 random chars. Generate one:\n"
        '  python -c "import secrets; print(secrets.token_urlsafe(48))"'
    )
if not DB_PASS:
    raise RuntimeError("PORTAL_DB_PASS is required (the read-only portal DB user's password).")

# job id -> abbreviation (xi.job order); char_jobs column order is jobs 1..22.
JOBS = {
    0: "NON", 1: "WAR", 2: "MNK", 3: "WHM", 4: "BLM", 5: "RDM", 6: "THF", 7: "PLD",
    8: "DRK", 9: "BST", 10: "BRD", 11: "RNG", 12: "SAM", 13: "NIN", 14: "DRG",
    15: "SMN", 16: "BLU", 17: "COR", 18: "PUP", 19: "DNC", 20: "SCH", 21: "GEO", 22: "RUN",
}
JOB_COLS = ["war", "mnk", "whm", "blm", "rdm", "thf", "pld", "drk", "bst", "brd", "rng",
            "sam", "nin", "drg", "smn", "blu", "cor", "pup", "dnc", "sch", "geo", "run"]
NATIONS = {0: "San d'Oria", 1: "Bastok", 2: "Windurst"}

# char_inventory.location -> container name.
CONTAINERS = {
    0: "Inventory", 1: "Mog Safe", 2: "Storage", 3: "Temp Items", 4: "Mog Locker",
    5: "Mog Satchel", 6: "Mog Sack", 7: "Mog Case", 8: "Wardrobe", 9: "Mog Safe 2",
    10: "Wardrobe 2", 11: "Wardrobe 3", 12: "Wardrobe 4", 13: "Wardrobe 5",
    14: "Wardrobe 6", 15: "Wardrobe 7", 16: "Wardrobe 8", 17: "Recycle Bin",
}
GIL_ITEM = 65535  # the currency sentinel in char_inventory

# char_storage column holding each container's capacity. Containers NOT listed
# here (storage=2, temp=3, mogsafe2=9, recyclebin=17) are never move targets.
STORAGE_COL = {
    0: "inventory", 1: "safe", 4: "locker", 5: "satchel", 6: "sack", 7: "case",
    8: "wardrobe", 10: "wardrobe2", 11: "wardrobe3", 12: "wardrobe4",
    13: "wardrobe5", 14: "wardrobe6", 15: "wardrobe7", 16: "wardrobe8",
}
WARDROBE_LOCS = {8, 10, 11, 12, 13, 14, 15, 16}  # equipment-only containers
VAULT_CAP = int(os.getenv("PORTAL_VAULT_CAP", "500"))  # per-character offline-vault item limit
RESCUE_ZONE = int(os.getenv("PORTAL_RESCUE_ZONE", "210"))  # GM Home -- /api/char/rescue target (matches rescue_bot)

# Warp destinations for /api/char/warp -- safe home-point coords per city/hub.
# ("home" is a special dest that uses the character's own chars.home_* point.)
WARP_DESTS = {
    "sandoria":  {"name": "San d'Oria", "zone": 230, "x": -85.554,  "y": 1.0,  "z": -64.554,  "rot": 45},
    "bastok":    {"name": "Bastok",     "zone": 234, "x": 39.0,     "y": 0.0,  "z": -43.0,    "rot": 0},
    "windurst":  {"name": "Windurst",   "zone": 241, "x": 106.239,  "y": -5.0, "z": -55.0,    "rot": 40},
    "jeuno":     {"name": "Jeuno",      "zone": 245, "x": -100.792, "y": 0.0,  "z": -181.577, "rot": 17},
    "whitegate": {"name": "Whitegate",  "zone": 50,  "x": -96.686,  "y": 0.0,  "z": -67.688,  "rot": 110},
    "gmhome":    {"name": "GM Home",    "zone": 210, "x": 0.0,      "y": 0.0,  "z": 0.0,      "rot": 0},
}

# Custom-system progression for the per-character quest-log (/api/progress).
#   cap       -> var value out of a fixed max
#   trials    -> count of <prefix>N_Done flags out of count
#   perks     -> sum of Paragon_Perk_<name> out of len*each
#   milestone -> open-ended; target = next round number (step), optional hard cap
PROGRESSION = [
    {"key": "hl", "name": "Hunting League", "type": "cap", "var": "HL_Tier", "max": 5,
     "extra": ("HL_Points", "points"),
     "hint": "Hunt Notorious Monsters at the Hunters' Guild (Escha - Zi'Tah) to rank up."},
    {"key": "prime", "name": "Prime Weapon", "type": "trials", "prefix": "PW_Trial", "count": 5,
     "hint": "Finish the 5 Prime trials to forge your Prime weapon (!tower, !mastery)."},
    {"key": "ascension", "name": "Ascensions", "type": "milestone", "var": "Prestige_Ascensions_Total", "step": 25,
     "hint": "Ascend your job through the Prestige system to grow past 99."},
    {"key": "rebirth", "name": "Rebirths (main job)", "type": "milestone", "varfmt": "Rebirth_Count_{mjob}", "step": 5,
     "hint": "Rebirth your job for permanent bonuses (a re-grind penalty applies)."},
    {"key": "apex", "name": "Apex Climb", "type": "milestone", "var": "Apex_HighestTier", "step": 25,
     "hint": "Climb through the Apex Arbiter NPC — every tier is harder than the last."},
    {"key": "paragon", "name": "Paragon Board", "type": "perks",
     "perks": ["might", "vigor", "precision", "warding", "arcana", "dominion"], "each": 10,
     "extra": ("Paragon_Level", "board level"), "hint": "Spend Paragon points across the 6-perk board."},
    {"key": "augment", "name": "Augment Mastery", "type": "cap", "var": "Augment_Mastery", "max": 5,
     "hint": "Raise Augment Mastery to strengthen your augments."},
    {"key": "tower", "name": "Endless Tower", "type": "milestone", "var": "Tower_Best_Floor", "step": 10,
     "hint": "Climb the Endless Tower — beat your best floor (!tower)."},
    {"key": "voidspire", "name": "Voidspire", "type": "milestone", "var": "Voidspire_Best_Floor", "step": 25,
     "hint": "Descend deeper into the Voidspire each run."},
    {"key": "nm", "name": "NM Hunter", "type": "milestone", "var": "Custom_NM_Kills", "step": 1000, "cap": 9999,
     "hint": "Slay Notorious Monsters — climb toward the 9,999 cap."},
    {"key": "unity", "name": "Unity Concord", "type": "milestone", "var": "Unity_NMs_Conquered", "step": 25,
     "hint": "Slay Unity Wanted NMs from the board at Purgonorgo Isle."},
    {"key": "fellow", "name": "Adventuring Fellow", "type": "milestone", "var": "Fellow_Level", "step": 20, "cap": 120,
     "hint": "Level your Adventuring Fellow companion (!fellow)."},
    {"key": "mastery", "name": "Spell & Skill Mastery", "type": "milestone", "var": "MasterySigils", "step": 1000,
     "hint": "Earn Mastery Sigils to empower your weapon skills and spells."},
    {"key": "colosseum", "name": "Colosseum", "type": "milestone", "var": "Col_Best_Rating", "step": 200,
     "hint": "Raise your best Colosseum rating in the arena."},
    {"key": "invasion", "name": "Invasions", "type": "milestone", "var": "Inv_Kills", "step": 25,
     "hint": "Defend Al Zahbi — rack up Invasion kills."},
    {"key": "domain", "name": "Domain Invasion", "type": "milestone", "var": "DI_Kills", "step": 50,
     "hint": "Rack up kills in Domain Invasion."},
    {"key": "reforge", "name": "Reforge Sets", "type": "flagcount", "prefix": "ReforgeClaimed_", "step": 3,
     "hint": "Claim Reforged AF/Relic/Empyrean armor at the Reforge hub (Diorama)."},
    {"key": "forgegates", "name": "Weapon Forge Gates", "type": "forge_gates",
     "hint": "The 11 stage prerequisites for Empyrean / Mythic / Aeonic / Prime forging."},
]


# ---- Weapon Forge gate targets ------------------------------------------
# Mirror the runtime counts exposed at Lua load-time via
# xi.geasFete.uniqueNmCount / xi.voidwatch.uniqueNmCount /
# xi.dungeonInstances.uniqueDungeonCount. Parsed here from the same catalogs
# so the Portal dashboard tallies the same numerator the in-game NPC does.
# Failure-tolerant: any parse miss becomes a math.huge-style guard (target=0
# reads as "no gate") -- so a temporarily-broken catalog degrades gracefully
# instead of dropping the whole page.
def _count_forge_gate_targets() -> dict[str, int]:
    root = Path(__file__).resolve().parents[2]
    # gf_empy_total = T1-T2 only (Empyrean Stage I). gf_aeonic_total = T3-T4 (Aeonic Stage II).
    out = {"gf_total": 0, "gf_empy_total": 0, "gf_aeonic_total": 0, "vw_total": 0, "dungeon_total": 0}
    try:
        text = (root / "modules/custom/lua/Geas_Fete.lua").read_text(encoding="utf-8", errors="replace")
        m = re.search(r"^local NM_CATALOG = \{(.*?)\n\}\n", text, re.MULTILINE | re.DOTALL)
        if m:
            for block in re.findall(r"\{[^{}]*gid\s*=\s*\d+[^{}]*\}", m.group(1)):
                out["gf_total"] += 1
                tm = re.search(r"tier\s*=\s*(\d+)", block)
                if tm and int(tm.group(1)) <= 2:
                    out["gf_empy_total"] += 1
                if tm and int(tm.group(1)) >= 3:
                    out["gf_aeonic_total"] += 1
    except OSError:
        pass
    try:
        text = (root / "modules/custom/lua/voidwatch_catalog.lua").read_text(encoding="utf-8", errors="replace")
        strata = re.search(r"C\.STRATA\s*=\s*\{(.*?)\n\}", text, re.DOTALL)
        if strata:
            names = set()
            for r in re.findall(r"roster\s*=\s*\{(.*?)\}\s*\}", strata.group(1), re.DOTALL):
                for n in re.findall(r"name\s*=\s*'([^']+)'", r):
                    names.add(n)
            out["vw_total"] = len(names)
    except OSError:
        pass
    try:
        text = (root / "modules/custom/lua/dungeon_catalog.lua").read_text(encoding="utf-8", errors="replace")
        out["dungeon_total"] = len(re.findall(r"^\s+instanceId\s*=\s*\d", text, re.MULTILINE))
    except OSError:
        pass
    return out


FORGE_GATE_TARGETS = _count_forge_gate_targets()


# Static spec for the 11 Weapon Forge gates, keyed by dashboard order. Each
# entry is (label, check(charvars, targets) -> bool). Matches the Lua
# STAGE_GATES table in modules/custom/lua/weapon_forge_gates.lua verbatim so
# the Portal card, the in-game !forgegates command, and the actual forge
# preflight all read from equivalent sources.
def _cv(charvars: dict, name: str) -> int:
    try:
        return int(charvars.get(name, 0) or 0)
    except (TypeError, ValueError):
        return 0

def _any_rebirth_50(cv, _):
    return any(_cv(cv, f"Rebirth_Count_{j}") >= 50 for j in range(1, 23))

def _any_ascension_100(cv, _):
    return any(_cv(cv, f"Prestige_Level_{j}") >= 100 for j in range(1, 23))

def _all_trials_and_apex(cv, _):
    return all(_cv(cv, f"PW_Trial{i}_Done") == 1 for i in range(1, 6)) \
        and _cv(cv, "Title_Apex_Hunter") == 1

def _first_empy_roster(cv, _):
    return _cv(cv, "WF_Empyrean_Final") == 1 or all(
        _cv(cv, f"AbyNM_{i:03d}") != 0 for i in range(1, 137)
    )

FORGE_GATES: list[dict] = [
    {"cat": "Relic",     "stage": "III", "label": "Wave Master Nightmare cleared",
     "check": lambda cv, _: (_cv(cv, "GM_Wave_Clears") & 16) != 0},
    {"cat": "Empyrean", "stage": "I",   "label": "All Geas Fete T1-T2 NMs killed at least once",
     "check": lambda cv, t: _cv(cv, "GF_Empyrean_Kills") >= (t["gf_empy_total"] or 10**9)},
    {"cat": "Empyrean", "stage": "II",  "label": "Voidspire Floor 100 reached",
     "check": lambda cv, _: _cv(cv, "Voidspire_Best_Floor") >= 100},
    {"cat": "Empyrean", "stage": "III",
     "label": "First-Empyrean Abyssea roster + Wave Master Apocalypse",
     "check": lambda cv, t: _first_empy_roster(cv, t)
                            and (_cv(cv, "GM_Wave_Clears") & 32) != 0},
    {"cat": "Mythic",   "stage": "I",   "label": "Floor 100 recorded on your Runic Disc",
     "check": lambda cv, _: _cv(cv, "Nyzul_F100_Cleared") == 1},
    {"cat": "Mythic",   "stage": "II",  "label": "All Voidwatch NMs killed",
     "check": lambda cv, t: _cv(cv, "VW_Unique_Kills") >= (t["vw_total"] or 10**9)},
    {"cat": "Mythic",   "stage": "III", "label": "1 Gauntlet win + Wave Master Apocalypse",
     "check": lambda cv, _: _cv(cv, "Gauntlet_Clears") >= 1
                        and (_cv(cv, "GM_Wave_Clears") & 32) != 0},
    {"cat": "Aeonic",   "stage": "I",   "label": "50 rebirths on a single job (not combined)",
     "check": _any_rebirth_50},
    {"cat": "Aeonic",   "stage": "II",
     "label": "100 Ascensions on a single job + all Geas Fete T3-T4 NMs killed once",
     "check": lambda cv, t: _any_ascension_100(cv, t)
                        and _cv(cv, "GF_Aeonic_Kills") >= (t["gf_aeonic_total"] or 10**9)},
    {"cat": "Aeonic",   "stage": "III", "label": "All Dungeons + 10 Maat's Echo wins + Wave Master Oblivion",
     "check": lambda cv, t: _cv(cv, "Dungeon_Unique_Clears") >= (t["dungeon_total"] or 10**9)
                        and _cv(cv, "Maat_Kills") >= 10
                        and (_cv(cv, "GM_Wave_Clears") & 64) != 0},
    {"cat": "Prime",    "stage": "I",   "label": "Built a final Aeonic weapon",
     "check": lambda cv, _: _cv(cv, "WF_Aeonic_Final") == 1},
    {"cat": "Prime",    "stage": "II",  "label": "All 5 Prime Armory Trials + Apex Hunter in the Hunter's Guild",
     "check": _all_trials_and_apex},
    {"cat": "Prime",    "stage": "III", "label": "Wave Master Ragnarok cleared",
     "check": lambda cv, _: (_cv(cv, "GM_Wave_Clears") & 128) != 0},
]


# One-time migration reward for Legendary community members transitioning to Relaunch.
# Each option sets specific char_vars (never overwriting a higher existing value).
# Claimed state tracked in char_vars as `Legacy_Reward_Claimed` = 1-based option index.
#
# STRICTLY COSMETIC: each pick is a keepsake with zero functional advantage over a
# new player. A Relaunch login hook reads the Legacy_Cosmetic_* var to grant the
# matching title/aura/glamour/emote. No stats, currency, or progression.
LEGACY_REWARD_OPTIONS = [
    {
        "id": "legendary_ring",
        "label": "Legendary Ring  (functional heirloom)",
        "description": "The one reward with real teeth: a Rare/Ex ring — EXP +50%, Capacity Points +50%, and Auto-Reraise, usable by all jobs at Lv.1. Granted on your first Relaunch login. Everything else here is cosmetic; choose the ring to carry a working piece of Legendary with you.",
        "vars": {"Legacy_Ring_Grant": 1},
    },
    {
        "id": "free_job_99",
        "label": "Free Job to 99  (functional heirloom)",
        "description": "Pick any one job — it arrives at level 99 on your first Relaunch login (you'll be switched to that job). A real head-start to carry your Legendary progress forward.",
        "needs_job": True,          # the player picks WHICH job; stored in `var`
        "var": "Legacy_FreeJob99",
    },
    {
        "id": "tracksuit",
        "label": "Legendary Track Suit",
        "description": "An exclusive 4-piece cosmetic set — custom-painted blue track jacket, pants, and shoes, plus a crimson sweater with scarf. Zero stats, all jobs, Lv.1. Granted on your first Relaunch login. Install the Relaunch Custom DATs pack to see the custom colors and names.",
        "vars": {"Legacy_TrackSuit_Grant": 1},
    },
    {
        "id": "founder_title",
        "label": "Founder's Title",
        "description": "Display the exclusive “Legendary Founder” title — a permanent nod to being here from the start.",
        "vars": {"Legacy_Cosmetic_Title": 1},
    },
    # Removed 2026-07-13 (owner call): Veteran's Aura / Founder's Mantle /
    # Commemorative Fireworks were listed but never had implementations on the
    # server side (no aura VFX, no back-slot cosmetic override, no emote wired
    # up). Anyone who already claimed one still has their Legacy_Cosmetic_Aura
    # / _Glamour / _Emote charVar -- harmless to leave set -- but the reward
    # picker no longer offers them to future migrators.
]
_REWARD_BY_ID = {o["id"]: o for o in LEGACY_REWARD_OPTIONS}
# Legacy single-slot indicator. Kept for backwards-compat with any code that
# reads "did this character claim ANYTHING" as a boolean. Still stamped when a
# player claims any reward. Individual claims live under _reward_claim_var().
LEGACY_REWARD_CLAIMED_VAR = "Legacy_Reward_Claimed"

def _reward_claim_var(option_id: str) -> str:
    """Per-option claim charVar (2026-07-13 owner call: rewards are no longer
    mutually exclusive -- players claim each one independently)."""
    return f"Legacy_Reward_Claim_{option_id}"


def compute_progress(charvars: dict, mjob: int) -> list:
    def iv(name):
        try:
            return int(charvars.get(name, 0) or 0)
        except (TypeError, ValueError):
            return 0

    systems = []
    for p in PROGRESSION:
        t = p["type"]
        cap = p.get("cap")
        if t == "cap":
            cur, tgt = iv(p["var"]), p["max"]
        elif t == "trials":
            cur = sum(1 for i in range(1, p["count"] + 1) if iv(f"{p['prefix']}{i}_Done"))
            tgt = p["count"]
        elif t == "perks":
            cur = sum(iv(f"Paragon_Perk_{k}") for k in p["perks"])
            tgt = len(p["perks"]) * p["each"]
        elif t == "milestone":
            var = p["varfmt"].format(mjob=mjob) if "varfmt" in p else p["var"]
            cur = iv(var)
            tgt = cap if (cap and cur >= cap) else ((cur // p["step"]) + 1) * p["step"]
            if cap:
                tgt = min(tgt, cap)
        elif t == "flagcount":
            # count of set flags matching a prefix (e.g. ReforgeClaimed_<jobid>),
            # rendered like a milestone (next round number).
            cur = sum(1 for k in charvars if k.startswith(p["prefix"]) and iv(k) > 0)
            tgt = ((cur // p["step"]) + 1) * p["step"]
        elif t == "forge_gates":
            # 11 binary Weapon Forge stage prerequisites -- count how many the
            # character has satisfied. gates[] gives the per-row breakdown so
            # the frontend can render each label + met/not-met marker.
            met = 0
            rows = []
            for g in FORGE_GATES:
                ok = bool(g["check"](charvars, FORGE_GATE_TARGETS))
                if ok:
                    met += 1
                rows.append({"cat": g["cat"], "stage": g["stage"],
                             "label": g["label"], "met": ok})
            cur, tgt = met, len(FORGE_GATES)
        else:
            continue

        if t in ("milestone", "flagcount"):
            done = bool(cap and cur >= cap)
            prev = tgt - p["step"]
            pct = 100 if done else (round((cur - prev) * 100 / p["step"]) if p["step"] else 0)
        else:
            done = cur >= tgt
            pct = round(cur * 100 / tgt) if tgt else 0

        item = {"key": p["key"], "name": p["name"], "type": t, "hint": p["hint"],
                "cur": cur, "target": tgt, "pct": max(0, min(100, pct)), "done": done}
        if "extra" in p:
            item["extra"] = iv(p["extra"][0])
            item["extraLabel"] = p["extra"][1]
        if t == "forge_gates":
            item["gates"] = rows  # per-row met/not-met detail for the drill-down
        systems.append(item)
    return systems

# -------------------------------------------------- profile customization ----
# Player-chosen cosmetics for their public /c/{name} page. Stored in the
# portal_profile table (char_vars is INT-only, so a title string needs its own
# home). Everything here is validated server-side against a fixed allow-list.
ACCENTS = {  # id -> hex accent used to theme the profile card
    "gold":    "#ecc25f", "crimson": "#e5534b", "azure": "#6ea8fe",
    "verdant": "#57c98a", "void":    "#b98cff", "silver": "#c7d0da",
}
DEFAULT_ACCENT = "gold"
MAX_TITLE = 40
MAX_SHOWCASE = 3

def sanitize_title(s) -> str:
    # Plain text only: strip tags/controls, collapse whitespace, hard length cap.
    t = re.sub(r"[<>\x00-\x1f\x7f]", "", str(s or ""))
    t = re.sub(r"\s+", " ", t).strip()
    return t[:MAX_TITLE]

def earned_badges(mjob: int, kills: int, jobs: list, pv: dict) -> list:
    """The ID'd accomplishments a character has actually earned. Drives both the
    auto-tags on the profile and the 'feature one' picker in the editor."""
    def iv(k):
        try: return int(pv.get(k, 0) or 0)
        except (TypeError, ValueError): return 0
    hl, asc, nmk, aug = iv("HL_Tier"), iv("Prestige_Ascensions_Total"), iv("Custom_NM_Kills"), iv("Augment_Mastery")
    maxed = sum(1 for j in jobs if j["lvl"] >= 99)
    prime = sum(1 for i in range(1, 6) if iv(f"PW_Trial_{i}_Done")) == 5
    b = []
    if   hl >= 5:  b.append(("hl", "Apex Hunter"))
    elif hl >= 1:  b.append(("hl", f"Hunting League Tier {hl}"))
    if   asc >= 200: b.append(("ascension", "Transcendent"))
    elif asc >= 100: b.append(("ascension", "Ascended"))
    elif asc >= 1:   b.append(("ascension", f"{asc} Ascensions"))
    if   nmk >= 9000: b.append(("nm", "NM Apex"))
    elif nmk >= 5000: b.append(("nm", "Monster Slayer"))
    elif nmk >= 1000: b.append(("nm", f"{nmk:,} NM Kills"))
    if   maxed >= 22: b.append(("jobs", "Jack of All Trades"))
    elif maxed >= 5:  b.append(("jobs", f"{maxed}× Lv99"))
    if prime:            b.append(("prime", "Prime Wielder"))
    if aug >= 5:         b.append(("augment", "Augment Master"))
    if kills >= 30000:   b.append(("warmonger", "Warmonger"))
    return [{"id": i, "label": l} for (i, l) in b]

# A real bcrypt hash we verify against when the login doesn't exist, so response
# timing is the same whether or not the account exists (blocks user enumeration).
DUMMY_HASH = bcrypt.hashpw(b"portal-nonexistent-account", bcrypt.gensalt(rounds=12)).decode()

_zone_cache: dict[int, str] | None = None


def db():
    return pymysql.connect(
        host=DB_HOST, port=DB_PORT, user=DB_USER, password=DB_PASS, database=DB_NAME,
        cursorclass=DictCursor, autocommit=True, connect_timeout=5, read_timeout=5,
    )


def db_write():
    # autocommit OFF: every mutation runs in one transaction we commit/rollback.
    return pymysql.connect(
        host=DB_HOST, port=DB_PORT, user=DB_WRITE_USER, password=DB_WRITE_PASS, database=DB_NAME,
        cursorclass=DictCursor, autocommit=False, connect_timeout=5, read_timeout=5,
    )


def is_bcrypt_hash(h: str) -> bool:
    return len(h) == 60 and h.startswith("$2") and h[3] == "$"


def prettify(s) -> str:
    return " ".join(w.capitalize() for w in str(s or "").replace("_", " ").split())


# Item name + BG-Wiki hover image keyed by item id. Generated from the docs
# site's bgwiki_images.json (data/item_thumbs.json) so the portal shows the SAME
# names/thumbnails as the site -- and resolves items missing from item_basic.
try:
    with open(os.path.join(os.path.dirname(__file__), "data", "item_thumbs.json"), encoding="utf-8") as _f:
        ITEM_THUMBS = {int(k): v for k, v in json.load(_f).items()}
except (OSError, ValueError):
    ITEM_THUMBS = {}

_DATA_DIR = os.path.join(os.path.dirname(__file__), "data")

def _load_json(fname, default):
    try:
        with open(os.path.join(_DATA_DIR, fname), encoding="utf-8") as f:
            return json.load(f)
    except (OSError, ValueError):
        return default

# modId -> readable stat label (gear set builder). Parsed from sql/item_mods.sql.
MOD_NAMES = {int(k): v for k, v in _load_json("mod_names.json", {}).items()}
# Snapshot of the relaunch augment catalog (planner). Regenerate with the helper
# in this dir when augment_catalog.lua changes.
AUGMENT_CATALOG = _load_json("augment_catalog.json", {"augments": [], "cats": {}})
# itemId -> augment description it grants, so the inventory view can flag
# catalysts a player is holding (trade them to the Augment Moogle) and show
# WHAT they give on hover: "AGI +1–32 · Base Stats" (label + min–max roll range
# + category, all from the catalog snapshot).
def _catalyst_desc(a: dict) -> str:
    label = a.get("label", "")
    lo, hi = a.get("min"), a.get("max")
    rng = ""
    if isinstance(lo, (int, float)) and isinstance(hi, (int, float)):
        rng = f" +{lo:g}–{hi:g}" if lo != hi else f" +{lo:g}"
    cat = a.get("catName", "")
    return f"{label}{rng}" + (f" · {cat}" if cat else "")

CATALYST_ITEMS = {int(a["itemId"]): _catalyst_desc(a) for a in AUGMENT_CATALOG.get("augments", [])}


def item_display(iid: int, basic_name) -> tuple:
    """(name, hover_image_url|None, link) for an item id -- matches the docs site."""
    thumb = ITEM_THUMBS.get(iid)
    if basic_name:
        name = prettify(basic_name)
    elif thumb:
        name = thumb["n"]
    else:
        name = f"item #{iid}"
    # Hover image: BG-Wiki stat box when resolved, else the always-available
    # FFXIAH icon. Link: FFXIAH by id (reliable) -- matches the docs site.
    img = thumb["img"] if thumb else f"https://static.ffxiah.com/images/icon/{iid}.png"
    wiki = f"https://www.ffxiah.com/item/{iid}"
    return name, img, wiki


def zone_name(cur, zid) -> str:
    global _zone_cache
    if _zone_cache is None:
        cur.execute("SELECT zoneid, name FROM zone_settings")
        _zone_cache = {r["zoneid"]: prettify(r["name"]) for r in cur.fetchall()}
    return _zone_cache.get(zid, "Unknown")


def load_progression(cur, charids: list[int]) -> dict[int, dict[str, int]]:
    """HL_Tier / Ascensions / NM kills / per-job Prestige+Rebirth for the given chars."""
    prog: dict[int, dict[str, int]] = {}
    if not charids:
        return prog
    ph = ", ".join(["%s"] * len(charids))
    cur.execute(
        f"SELECT charid, varname, value FROM char_vars "
        f"WHERE charid IN ({ph}) AND ("
        f"  varname IN ('HL_Tier','Prestige_Ascensions_Total','Custom_NM_Kills','{LEGACY_REWARD_CLAIMED_VAR}') "
        f"  OR varname LIKE 'Prestige_Level_%%' OR varname LIKE 'Rebirth_Count_%%')",
        tuple(charids),
    )
    for r in cur.fetchall():
        try:
            prog.setdefault(r["charid"], {})[r["varname"]] = int(r["value"])
        except (TypeError, ValueError):
            pass
    return prog


# ---- offline inventory-mutation helpers (write path) -------------------------
def is_offline(cur, charid: int) -> bool:
    cur.execute("SELECT 1 FROM accounts_sessions WHERE charid = %s LIMIT 1", (charid,))
    return cur.fetchone() is None


def owned_char(cur, acct_id: int, charid: int) -> dict:
    cur.execute("SELECT accid, charname FROM chars WHERE charid = %s", (charid,))
    row = cur.fetchone()
    if not row or row["accid"] != acct_id:
        raise HTTPException(status_code=404, detail="Character not found on this account.")
    return row


def is_equipped(cur, charid: int, loc: int, slot: int) -> bool:
    cur.execute("SELECT 1 FROM char_equip WHERE charid = %s AND containerid = %s AND slotid = %s LIMIT 1",
                (charid, loc, slot))
    return cur.fetchone() is not None


def is_equippable(cur, itemid: int) -> bool:
    cur.execute("SELECT 1 FROM item_equipment WHERE itemId = %s LIMIT 1", (itemid,))
    if cur.fetchone():
        return True
    cur.execute("SELECT 1 FROM item_weapon WHERE itemId = %s LIMIT 1", (itemid,))
    return cur.fetchone() is not None


def _get_charvar(cur, charid: int, varname: str) -> int:
    cur.execute("SELECT value FROM char_vars WHERE charid=%s AND varname=%s", (charid, varname))
    row = cur.fetchone()
    try:
        return int(row["value"]) if row else 0
    except (TypeError, ValueError):
        return 0


def _upsert_charvar(cur, charid: int, varname: str, value: int):
    cur.execute(
        "INSERT INTO char_vars (charid, varname, value) VALUES (%s, %s, %s) "
        "ON DUPLICATE KEY UPDATE value=%s",
        (charid, varname, value, value),
    )


def container_cap(cur, charid: int, loc: int) -> int:
    """Effective capacity = max(configured size, highest slot in use). 0 = unusable."""
    col = STORAGE_COL.get(loc)
    if not col:
        return 0
    cur.execute(f"SELECT `{col}` AS sz FROM char_storage WHERE charid = %s", (charid,))
    row = cur.fetchone()
    nominal = int(row["sz"]) if row and row["sz"] is not None else 0
    cur.execute("SELECT COALESCE(MAX(slot), 0) AS mx FROM char_inventory WHERE charid = %s AND location = %s",
                (charid, loc))
    return max(nominal, int(cur.fetchone()["mx"]))


def free_slot(cur, charid: int, loc: int, cap: int) -> "int | None":
    cur.execute("SELECT slot FROM char_inventory WHERE charid = %s AND location = %s", (charid, loc))
    used = {r["slot"] for r in cur.fetchall()}
    for s in range(1, cap + 1):   # slot 0 is reserved (gil / none)
        if s not in used:
            return s
    return None


# ---- naive per-IP rate limiter (scaffold guard; use slowapi/redis at scale) --
_attempts: dict[str, deque] = defaultdict(deque)
RL_WINDOW = 300   # seconds
RL_MAX    = 10    # attempts per window per IP


def client_ip(request: Request) -> str:
    cf = request.headers.get("cf-connecting-ip")
    if cf:
        return cf.strip()
    xff = request.headers.get("x-forwarded-for")
    if xff:
        return xff.split(",")[0].strip()
    return request.client.host if request.client else "unknown"


def rate_limit(ip: str):
    now = time.time()
    dq = _attempts[ip]
    while dq and dq[0] < now - RL_WINDOW:
        dq.popleft()
    if len(dq) >= RL_MAX:
        raise HTTPException(status_code=429, detail="Too many attempts -- wait a few minutes.")
    dq.append(now)


# --------------------------------------------------------------------- app ----
app = FastAPI(title="Legendary FFXI Player Portal", docs_url=None, redoc_url=None)

if CORS_ORIGINS:
    app.add_middleware(
        CORSMiddleware, allow_origins=CORS_ORIGINS, allow_credentials=True,
        allow_methods=["GET", "POST"], allow_headers=["Content-Type"],
    )


@app.middleware("http")
async def _cache_control(request: Request, call_next):
    """Stop Cloudflare + browsers from caching the service worker and HTML.

    Static .js was being edge-cached (Cf-Cache HIT, max-age=14400), so an updated
    sw.js never reached clients and the old cache-first worker kept serving a
    stale index.html. sw.js = never store; HTML/manifest = always revalidate.
    """
    response = await call_next(request)
    path = request.url.path
    if path == "/sw.js":
        response.headers["Cache-Control"] = "no-store, no-cache, must-revalidate, max-age=0"
    elif path == "/" or path.endswith(".html") or path == "/manifest.webmanifest":
        response.headers["Cache-Control"] = "no-cache, must-revalidate, max-age=0"
    return response


class LoginBody(BaseModel):
    login: str
    password: str


def make_token(account_id: int, login: str) -> str:
    now = datetime.datetime.now(datetime.timezone.utc)
    return jwt.encode(
        {"sub": str(account_id), "login": login, "iat": now,
         "exp": now + datetime.timedelta(hours=JWT_TTL_HOURS)},
        JWT_SECRET, algorithm="HS256",
    )


def require_account(request: Request) -> dict:
    token = request.cookies.get(COOKIE_NAME)
    if not token:
        raise HTTPException(status_code=401, detail="Not logged in.")
    try:
        payload = jwt.decode(token, JWT_SECRET, algorithms=["HS256"])
    except jwt.PyJWTError:
        raise HTTPException(status_code=401, detail="Session expired -- log in again.")
    return {"id": int(payload["sub"]), "login": payload["login"]}


# --------------------------------------------------------------- auth routes --
@app.post("/api/login")
def login(body: LoginBody, request: Request, response: Response):
    rate_limit(client_ip(request))

    login_name = body.login.strip()
    if not login_name or not body.password:
        raise HTTPException(status_code=400, detail="Login and password are required.")

    conn = db()
    try:
        with conn.cursor() as cur:
            cur.execute("SELECT id, password FROM accounts WHERE login = %s", (login_name,))
            row = cur.fetchone()
    finally:
        conn.close()

    stored = row["password"] if (row and is_bcrypt_hash(row["password"])) else DUMMY_HASH
    try:
        ok = bcrypt.checkpw(body.password.encode("utf-8"), stored.encode("utf-8"))
    except ValueError:
        ok = False

    if not row or not ok:
        raise HTTPException(status_code=401, detail="Invalid login or password.")

    response.set_cookie(
        COOKIE_NAME, make_token(row["id"], login_name),
        httponly=True, secure=COOKIE_SECURE, samesite=COOKIE_SAMESITE,
        max_age=JWT_TTL_HOURS * 3600, path="/",
    )
    return {"ok": True, "login": login_name}


@app.post("/api/logout")
def logout(response: Response):
    response.delete_cookie(COOKIE_NAME, path="/")
    return {"ok": True}


@app.get("/api/me")
def me(request: Request):
    acct = require_account(request)
    conn = db()
    try:
        with conn.cursor() as cur:
            cur.execute("SELECT current_email, timecreate, priv FROM accounts WHERE id = %s", (acct["id"],))
            arow = cur.fetchone() or {}
            cur.execute(
                "SELECT c.charid, c.charname, c.nation, c.playtime, "
                "       COALESCE(s.mjob,0) AS mjob, COALESCE(s.sjob,0) AS sjob, "
                "       COALESCE(s.mlvl,1) AS mlvl, COALESCE(s.slvl,1) AS slvl, "
                "       COALESCE(s.hp,0)   AS hp,   COALESCE(s.mp,0)   AS mp, "
                "       COALESCE(g.quantity,0)          AS gil, "
                "       COALESCE(h.enemies_defeated,0)  AS kills, "
                "       COALESCE(h.times_knocked_out,0) AS deaths, "
                "       COALESCE(h.battles_fought,0)    AS battles "
                "FROM chars c "
                "LEFT JOIN char_stats s     ON s.charid = c.charid "
                "LEFT JOIN char_history h   ON h.charid = c.charid "
                "LEFT JOIN char_inventory g ON g.charid = c.charid AND g.itemId = %s AND g.location = 0 "
                "WHERE c.accid = %s ORDER BY c.charname",
                (GIL_ITEM, acct["id"]),
            )
            chars = cur.fetchall()
            prog = load_progression(cur, [c["charid"] for c in chars])
    finally:
        conn.close()

    characters = []
    for c in chars:
        pv   = prog.get(c["charid"], {})
        mjob = c["mjob"]
        characters.append({
            "charid":       c["charid"],
            "name":         c["charname"],
            "nation":       NATIONS.get(c["nation"], "?"),
            "mainJob":      JOBS.get(mjob, "?"),
            "mainLvl":      c["mlvl"],
            "subJob":       JOBS.get(c["sjob"], "NON"),
            "subLvl":       c["slvl"],
            "hp":           c["hp"],
            "mp":           c["mp"],
            "gil":          int(c["gil"]),
            "playtimeH":    (c["playtime"] or 0) // 3600,
            "kills":        int(c["kills"]),
            "deaths":       int(c["deaths"]),
            "battles":      int(c["battles"]),
            "hlTier":              pv.get("HL_Tier", 0),
            "ascensions":          pv.get("Prestige_Ascensions_Total", 0),
            "nmKills":             pv.get("Custom_NM_Kills", 0),
            "prestigeLvl":         pv.get(f"Prestige_Level_{mjob}", 0),
            "rebirthCount":        pv.get(f"Rebirth_Count_{mjob}", 0),
            "legacyRewardClaimed": bool(pv.get(LEGACY_REWARD_CLAIMED_VAR, 0)),
        })
    return {
        "login":      acct["login"],
        "email":      arow.get("current_email", ""),
        "since":      str(arow.get("timecreate", "")),
        "isGm":       int(arow.get("priv", 0) or 0) >= GM_PRIV_MIN,
        "characters": characters,
    }


@app.get("/api/inventory/{charid}")
def inventory(charid: int, request: Request):
    """A character's inventory across every container. Own-account only."""
    acct = require_account(request)
    conn = db()
    try:
        with conn.cursor() as cur:
            owner = owned_char(cur, acct["id"], charid)
            online = not is_offline(cur, charid)
            cur.execute("SELECT * FROM char_storage WHERE charid = %s", (charid,))
            storage = cur.fetchone() or {}
            cur.execute(
                "SELECT i.location, i.slot, i.itemId, i.quantity, i.bazaar, b.name "
                "FROM char_inventory i LEFT JOIN item_basic b ON b.itemid = i.itemId "
                "WHERE i.charid = %s AND i.itemId <> %s "
                "ORDER BY i.location, i.slot",
                (charid, GIL_ITEM),
            )
            rows = cur.fetchall()
            cur.execute("SELECT containerid, slotid FROM char_equip WHERE charid = %s", (charid,))
            equipped = {(r["containerid"], r["slotid"]) for r in cur.fetchall()}
            cur.execute(
                "SELECT v.id, v.itemId, v.quantity, b.name "
                "FROM portal_vault v LEFT JOIN item_basic b ON b.itemid = v.itemId "
                "WHERE v.charid = %s ORDER BY v.id",
                (charid,),
            )
            vrows = cur.fetchall()
    finally:
        conn.close()

    buckets: dict[int, list] = defaultdict(list)
    maxslot: dict[int, int] = defaultdict(int)
    for r in rows:
        loc = r["location"]
        maxslot[loc] = max(maxslot[loc], r["slot"])
        name, img, wiki = item_display(r["itemId"], r["name"])
        buckets[loc].append({
            "id":     r["itemId"],
            "slot":   r["slot"],
            "name":   name,
            "qty":    int(r["quantity"]),
            "img":    img,
            "wiki":   wiki,
            "locked": bool(r["bazaar"]) or ((loc, r["slot"]) in equipped),
            "catalyst":    r["itemId"] in CATALYST_ITEMS,
            "catalystAug": CATALYST_ITEMS.get(r["itemId"], ""),
        })

    def cap_of(loc: int) -> int:
        col = STORAGE_COL.get(loc)
        if not col:
            return 0
        return max(int(storage.get(col) or 0), maxslot.get(loc, 0))

    containers = [
        {"id": loc, "name": CONTAINERS.get(loc, f"Container {loc}"),
         "count": len(items), "cap": cap_of(loc), "items": items}
        for loc, items in sorted(buckets.items())
    ]
    destinations = [
        {"id": loc, "name": CONTAINERS[loc], "cap": cap_of(loc), "count": len(buckets.get(loc, []))}
        for loc in STORAGE_COL if cap_of(loc) > 0
    ]
    vault_items = []
    for v in vrows:
        vname, vimg, vwiki = item_display(v["itemId"], v["name"])
        vault_items.append({"vaultId": v["id"], "id": v["itemId"], "name": vname,
                            "qty": int(v["quantity"]), "img": vimg, "wiki": vwiki,
                            "catalyst": v["itemId"] in CATALYST_ITEMS,
                            "catalystAug": CATALYST_ITEMS.get(v["itemId"], "")})
    return {"charid": charid, "name": owner["charname"], "online": online,
            "total": len(rows), "containers": containers, "destinations": destinations,
            "vault": {"count": len(vault_items), "cap": VAULT_CAP, "items": vault_items}}


class MoveBody(BaseModel):
    charid: int
    fromLoc: int
    fromSlot: int
    toLoc: int


class DiscardBody(BaseModel):
    charid: int
    fromLoc: int
    fromSlot: int


def _lock_source_item(cur, charid: int, loc: int, slot: int) -> dict:
    """Row-lock the source item and refuse if it's equipped or in a bazaar."""
    cur.execute(
        "SELECT itemId, quantity, bazaar, signature, extra "
        "FROM char_inventory WHERE charid = %s AND location = %s AND slot = %s FOR UPDATE",
        (charid, loc, slot),
    )
    item = cur.fetchone()
    if not item:
        raise HTTPException(status_code=404, detail="No item in that slot.")
    if item["bazaar"]:
        raise HTTPException(status_code=409, detail="That item is in a bazaar -- take it down in-game first.")
    if is_equipped(cur, charid, loc, slot):
        raise HTTPException(status_code=409, detail="That item is equipped -- unequip it in-game first.")
    return item


@app.post("/api/inventory/move")
def inv_move(body: MoveBody, request: Request):
    """Move one item to a free slot in another container. Offline + own-account only."""
    acct = require_account(request)
    if body.toLoc not in STORAGE_COL:
        raise HTTPException(status_code=400, detail="That container can't be a destination.")
    if body.toLoc == body.fromLoc:
        raise HTTPException(status_code=400, detail="Pick a different container.")
    conn = db_write()
    try:
        with conn.cursor() as cur:
            owned_char(cur, acct["id"], body.charid)
            if not is_offline(cur, body.charid):
                raise HTTPException(status_code=409, detail="That character is online -- log out of the game first.")
            item = _lock_source_item(cur, body.charid, body.fromLoc, body.fromSlot)
            if body.toLoc in WARDROBE_LOCS and not is_equippable(cur, item["itemId"]):
                raise HTTPException(status_code=409, detail="Only equipment can go in a wardrobe.")
            cap  = container_cap(cur, body.charid, body.toLoc)
            slot = free_slot(cur, body.charid, body.toLoc, cap)
            if slot is None:
                raise HTTPException(status_code=409, detail="That container is full.")
            cur.execute(
                "UPDATE char_inventory SET location = %s, slot = %s "
                "WHERE charid = %s AND location = %s AND slot = %s",
                (body.toLoc, slot, body.charid, body.fromLoc, body.fromSlot),
            )
        conn.commit()
        return {"ok": True, "toLoc": body.toLoc, "toSlot": slot}
    except HTTPException:
        conn.rollback()
        raise
    except Exception:
        conn.rollback()
        raise HTTPException(status_code=500, detail="Move failed -- nothing was changed.")
    finally:
        conn.close()


@app.post("/api/inventory/discard")
def inv_discard(body: DiscardBody, request: Request):
    """Discard one item (logged to portal_item_log so it's recoverable). Offline + own-account only."""
    acct = require_account(request)
    conn = db_write()
    try:
        with conn.cursor() as cur:
            owned_char(cur, acct["id"], body.charid)
            if not is_offline(cur, body.charid):
                raise HTTPException(status_code=409, detail="That character is online -- log out of the game first.")
            item = _lock_source_item(cur, body.charid, body.fromLoc, body.fromSlot)
            cur.execute(
                "INSERT INTO portal_item_log "
                "(charid, accid, itemId, quantity, fromLoc, fromSlot, signature, extra) "
                "VALUES (%s, %s, %s, %s, %s, %s, %s, %s)",
                (body.charid, acct["id"], item["itemId"], item["quantity"],
                 body.fromLoc, body.fromSlot, item["signature"], item["extra"]),
            )
            cur.execute(
                "DELETE FROM char_inventory WHERE charid = %s AND location = %s AND slot = %s",
                (body.charid, body.fromLoc, body.fromSlot),
            )
        conn.commit()
        return {"ok": True}
    except HTTPException:
        conn.rollback()
        raise
    except Exception:
        conn.rollback()
        raise HTTPException(status_code=500, detail="Discard failed -- nothing was changed.")
    finally:
        conn.close()


class DepositBody(BaseModel):
    charid: int
    fromLoc: int
    fromSlot: int


class WithdrawBody(BaseModel):
    charid: int
    vaultId: int
    toLoc: int


@app.post("/api/vault/deposit")
def vault_deposit(body: DepositBody, request: Request):
    """Move one item from a container into the offline vault, freeing the in-game slot.
    The vault lives OUTSIDE the game's containers, so it doesn't count against any
    in-game limit. Offline + own-account only."""
    acct = require_account(request)
    conn = db_write()
    try:
        with conn.cursor() as cur:
            owned_char(cur, acct["id"], body.charid)
            if not is_offline(cur, body.charid):
                raise HTTPException(status_code=409, detail="That character is online -- log out of the game first.")
            item = _lock_source_item(cur, body.charid, body.fromLoc, body.fromSlot)
            cur.execute("SELECT COUNT(*) AS n FROM portal_vault WHERE charid = %s", (body.charid,))
            if int(cur.fetchone()["n"]) >= VAULT_CAP:
                raise HTTPException(status_code=409, detail=f"Vault is full ({VAULT_CAP} items).")
            cur.execute(
                "INSERT INTO portal_vault (charid, accid, itemId, quantity, signature, extra) "
                "VALUES (%s, %s, %s, %s, %s, %s)",
                (body.charid, acct["id"], item["itemId"], item["quantity"], item["signature"], item["extra"]),
            )
            cur.execute(
                "DELETE FROM char_inventory WHERE charid = %s AND location = %s AND slot = %s",
                (body.charid, body.fromLoc, body.fromSlot),
            )
        conn.commit()
        return {"ok": True}
    except HTTPException:
        conn.rollback()
        raise
    except Exception:
        conn.rollback()
        raise HTTPException(status_code=500, detail="Deposit failed -- nothing was changed.")
    finally:
        conn.close()


@app.post("/api/vault/withdraw")
def vault_withdraw(body: WithdrawBody, request: Request):
    """Move one item from the offline vault back into an in-game container (needs a free
    slot). Offline + own-account only."""
    acct = require_account(request)
    if body.toLoc not in STORAGE_COL:
        raise HTTPException(status_code=400, detail="That container can't be a destination.")
    conn = db_write()
    try:
        with conn.cursor() as cur:
            owned_char(cur, acct["id"], body.charid)
            if not is_offline(cur, body.charid):
                raise HTTPException(status_code=409, detail="That character is online -- log out of the game first.")
            cur.execute(
                "SELECT id, itemId, quantity, signature, extra FROM portal_vault "
                "WHERE id = %s AND charid = %s FOR UPDATE",
                (body.vaultId, body.charid),
            )
            item = cur.fetchone()
            if not item:
                raise HTTPException(status_code=404, detail="That item isn't in this character's vault.")
            if body.toLoc in WARDROBE_LOCS and not is_equippable(cur, item["itemId"]):
                raise HTTPException(status_code=409, detail="Only equipment can go in a wardrobe.")
            cap  = container_cap(cur, body.charid, body.toLoc)
            slot = free_slot(cur, body.charid, body.toLoc, cap)
            if slot is None:
                raise HTTPException(status_code=409, detail="That container is full.")
            cur.execute(
                "INSERT INTO char_inventory (charid, location, slot, itemId, quantity, bazaar, signature, extra) "
                "VALUES (%s, %s, %s, %s, %s, 0, %s, %s)",
                (body.charid, body.toLoc, slot, item["itemId"], item["quantity"], item["signature"], item["extra"]),
            )
            cur.execute("DELETE FROM portal_vault WHERE id = %s", (body.vaultId,))
        conn.commit()
        return {"ok": True, "toLoc": body.toLoc, "toSlot": slot}
    except HTTPException:
        conn.rollback()
        raise
    except Exception:
        conn.rollback()
        raise HTTPException(status_code=500, detail="Withdraw failed -- nothing was changed.")
    finally:
        conn.close()


@app.get("/api/progress/{charid}")
def progress(charid: int, request: Request):
    """Per-character quest-log: progress + next milestone through each custom system.
    Own-account only."""
    acct = require_account(request)
    conn = db()
    try:
        with conn.cursor() as cur:
            owner = owned_char(cur, acct["id"], charid)
            cur.execute("SELECT COALESCE(mjob, 0) AS mjob FROM char_stats WHERE charid = %s", (charid,))
            mjob = (cur.fetchone() or {}).get("mjob", 0)
            cur.execute(
                "SELECT varname, value FROM char_vars WHERE charid = %s AND ("
                "  varname IN ('HL_Tier','HL_Points','Prestige_Ascensions_Total','Apex_HighestTier',"
                "  'Augment_Mastery','Tower_Best_Floor','Voidspire_Best_Floor','Custom_NM_Kills','Paragon_Level',"
                "  'Unity_NMs_Conquered','Fellow_Level','MasterySigils','Col_Best_Rating','Inv_Kills','DI_Kills',"
                "  'GF_Unique_Kills','GF_Empyrean_Kills','GF_Aeonic_Kills','VW_Unique_Kills','Dungeon_Unique_Clears','Maat_Kills','Gauntlet_Clears',"
                "  'Nyzul_F100_Cleared','Title_Apex_Hunter','WF_Relic_Final','WF_Mythic_Final',"
                "  'WF_Empyrean_Final','WF_Aeonic_Final') "
                "  OR varname LIKE 'PW_Trial%%' OR varname LIKE 'Paragon_Perk_%%' OR varname LIKE 'Rebirth_Count_%%'"
                "  OR varname LIKE 'Prestige_Level_%%' OR varname LIKE 'AbyNM_%%'"
                "  OR varname LIKE 'ReforgeClaimed_%%')",
                (charid,),
            )
            cvars = {r["varname"]: r["value"] for r in cur.fetchall()}
    finally:
        conn.close()
    return {"charid": charid, "name": owner["charname"], "job": JOBS.get(mjob, "?"),
            "systems": compute_progress(cvars, mjob)}


# --- Adventuring Fellow (companion) label tables, mirrored from
# modules/custom/lua/fellow_companion.lua CONFIG. char_vars is INT-only, so the
# Fellow's role/name/appearance are stored as 1-based indices into these lists.
# Keep in sync if that CONFIG changes.
FELLOW_ROLES = [
    "Vanguard", "Berserker", "Bulwark", "Oracle", "Magus", "Hunter", "Mastered",
]  # index = Fellow_Role (1-based); 0/unset -> Vanguard
FELLOW_CATEGORIES = [
    "STR", "DEX", "VIT", "AGI", "INT", "MND",
    "Ferocity", "Critical", "Frenzy", "Onslaught", "Sorcery", "Celerity", "Warding", "Vigor",
]
FELLOW_NAMES = [
    "Siegward", "Theobald", "Gunnar", "Ferdinand", "Beatrice", "Henrietta",
    "Karyn", "Nanako", "Gauldeval", "Romidiant", "Liabelle", "Radille",
    "Nokum-Akkum", "Yawawa", "Cupapa", "Raka Maimhov", "Voldai", "Zoldof",
]
FELLOW_MODELS = [
    "Moogle", "Mandragora", "Coeurl", "Sabotender", "Cardian", "Goblin",
    "Yagudo", "Tonberry", "Antican", "Boggart", "Goobbue", "Adventurer",
]
FELLOW_OUTFITS = [
    "Thief", "Monk", "Red Mage", "Ranger", "Dark Knight", "Paladin",
    "Warrior", "Black Mage", "Scholar", "Bard",
]
FELLOW_STAT_CAP = 1400
FELLOW_MAX_LEVEL = 120


@app.get("/api/fellow/{charid}")
def fellow(charid: int, request: Request):
    """Adventuring Fellow build: level/XP, role, appearance, the 14-category
    allocation and mastery progress. Read-only, own-account only."""
    acct = require_account(request)
    conn = db()
    try:
        with conn.cursor() as cur:
            owner = owned_char(cur, acct["id"], charid)
            cur.execute(
                "SELECT varname, value FROM char_vars WHERE charid=%s AND varname LIKE 'Fellow_%%'",
                (charid,),
            )
            cv = {}
            for r in cur.fetchall():
                try:
                    cv[r["varname"]] = int(r["value"])
                except (TypeError, ValueError):
                    pass
    finally:
        conn.close()

    if cv.get("Fellow_Born", 0) != 1:
        return {"charid": charid, "name": owner["charname"], "born": False}

    level = max(1, cv.get("Fellow_Level", 1))
    role_idx = cv.get("Fellow_Role", 0)
    role = FELLOW_ROLES[role_idx - 1] if 1 <= role_idx <= len(FELLOW_ROLES) else "Vanguard"

    name_idx = cv.get("Fellow_NameIdx", 0)
    fellow_name = FELLOW_NAMES[name_idx - 1] if 1 <= name_idx <= len(FELLOW_NAMES) else None

    outfit_idx = cv.get("Fellow_Outfit", 0)
    model_idx = cv.get("Fellow_ModelPet", 0)
    if 1 <= outfit_idx <= len(FELLOW_OUTFITS):
        appearance = FELLOW_OUTFITS[outfit_idx - 1] + " (outfit)"
    elif 1 <= model_idx <= len(FELLOW_MODELS):
        appearance = FELLOW_MODELS[model_idx - 1]
    else:
        appearance = "Lynx"

    allocation, capped = [], 0
    for stat in FELLOW_CATEGORIES:
        pts = cv.get("Fellow_" + stat, 0)
        is_capped = pts >= FELLOW_STAT_CAP
        if is_capped:
            capped += 1
        allocation.append({"stat": stat, "points": pts, "capped": is_capped})

    return {
        "charid": charid,
        "name": owner["charname"],
        "born": True,
        "fellowName": fellow_name,
        "level": level,
        "maxLevel": FELLOW_MAX_LEVEL,
        "xp": cv.get("Fellow_XP", 0),
        "xpToNext": (80 * level) if level < FELLOW_MAX_LEVEL else 0,
        "points": cv.get("Fellow_Points", 0),
        "role": role,
        "appearance": appearance,
        "active": cv.get("Fellow_Active", 0) == 1,
        "mastered": (capped >= len(FELLOW_CATEGORIES)),
        "cappedCount": capped,
        "categoryTotal": len(FELLOW_CATEGORIES),
        "statCap": FELLOW_STAT_CAP,
        "allocation": allocation,
    }


# --------------------------------------------------- self-service char tools --
class CharBody(BaseModel):
    charid: int


class AppearanceBody(BaseModel):
    charid: int
    race: int
    face: int


@app.get("/api/char/{charid}")
def char_tools(charid: int, request: Request):
    """Status / location / jobs / appearance for the self-service tools panel. Own-account only."""
    acct = require_account(request)
    conn = db()
    try:
        with conn.cursor() as cur:
            owner = owned_char(cur, acct["id"], charid)
            online = not is_offline(cur, charid)
            cur.execute("SELECT pos_zone, home_zone FROM chars WHERE charid = %s", (charid,))
            c = cur.fetchone() or {}
            cur.execute("SELECT face, race FROM char_look WHERE charid = %s", (charid,))
            look = cur.fetchone() or {}
            cur.execute("SELECT COALESCE(mjob,0) AS mjob, COALESCE(sjob,0) AS sjob FROM char_stats WHERE charid = %s", (charid,))
            st = cur.fetchone() or {}
            cur.execute("SELECT * FROM char_jobs WHERE charid = %s", (charid,))
            jr = cur.fetchone() or {}
            hz = c.get("home_zone") or 0
            zone = zone_name(cur, c.get("pos_zone", 0))
            home = zone_name(cur, hz) if hz else None
    finally:
        conn.close()
    jobs = [{"id": i + 1, "abbr": JOBS[i + 1], "lvl": int(jr.get(JOB_COLS[i], 0) or 0)}
            for i in range(len(JOB_COLS)) if int(jr.get(JOB_COLS[i], 0) or 0) >= 1]
    dests = ([{"key": "home", "name": "Home Point"}] if hz else []) + \
            [{"key": k, "name": v["name"]} for k, v in WARP_DESTS.items()]
    return {
        "charid": charid, "name": owner["charname"], "online": online,
        "zone": zone, "homeZone": home,
        "race": int(look.get("race", 0)), "face": int(look.get("face", 0)),
        "mainJob": int(st.get("mjob", 0)), "subJob": int(st.get("sjob", 0)),
        "jobs": jobs, "warpDests": dests,
    }


@app.post("/api/char/rescue")
def char_rescue(body: CharBody, request: Request):
    """Move a stuck OFFLINE character to GM Home (safe zone), like !rescue. Own-account only."""
    acct = require_account(request)
    conn = db_write()
    try:
        with conn.cursor() as cur:
            owned_char(cur, acct["id"], body.charid)
            if not is_offline(cur, body.charid):
                raise HTTPException(status_code=409, detail="That character is online -- log out of the game first.")
            cur.execute(
                "UPDATE chars SET pos_zone=%s, pos_prevzone=%s, pos_x=0, pos_y=0, pos_z=0, pos_rot=0, moghouse=0 "
                "WHERE charid=%s",
                (RESCUE_ZONE, RESCUE_ZONE, body.charid),
            )
        conn.commit()
        return {"ok": True}
    except HTTPException:
        conn.rollback()
        raise
    except Exception:
        conn.rollback()
        raise HTTPException(status_code=500, detail="Rescue failed -- nothing was changed.")
    finally:
        conn.close()


class WarpBody(BaseModel):
    charid: int
    dest: str = "home"


class JobBody(BaseModel):
    charid: int
    mainJob: int
    subJob: int


@app.post("/api/char/warp")
def char_warp(body: WarpBody, request: Request):
    """Send an OFFLINE character to a chosen city/hub, or its own home point. Own-account only."""
    acct = require_account(request)
    conn = db_write()
    try:
        with conn.cursor() as cur:
            owned_char(cur, acct["id"], body.charid)
            if not is_offline(cur, body.charid):
                raise HTTPException(status_code=409, detail="That character is online -- log out of the game first.")
            if body.dest == "home":
                cur.execute("SELECT home_zone AS zone, home_x AS x, home_y AS y, home_z AS z, home_rot AS rot "
                            "FROM chars WHERE charid=%s", (body.charid,))
                d = cur.fetchone() or {}
                if not d.get("zone"):
                    raise HTTPException(status_code=409, detail="This character has no home point set.")
            else:
                d = WARP_DESTS.get(body.dest)
                if not d:
                    raise HTTPException(status_code=400, detail="Unknown destination.")
            cur.execute(
                "UPDATE chars SET pos_zone=%s, pos_prevzone=%s, pos_x=%s, pos_y=%s, pos_z=%s, pos_rot=%s, moghouse=0 "
                "WHERE charid=%s",
                (d["zone"], d["zone"], d["x"], d["y"], d["z"], d["rot"], body.charid),
            )
        conn.commit()
        return {"ok": True}
    except HTTPException:
        conn.rollback()
        raise
    except Exception:
        conn.rollback()
        raise HTTPException(status_code=500, detail="Warp failed -- nothing was changed.")
    finally:
        conn.close()


@app.post("/api/char/job")
def char_job(body: JobBody, request: Request):
    """Change an OFFLINE character's main/sub job (to any unlocked job). Own-account only."""
    acct = require_account(request)
    if not (1 <= body.mainJob <= 22):
        raise HTTPException(status_code=400, detail="Invalid main job.")
    if not (0 <= body.subJob <= 22):
        raise HTTPException(status_code=400, detail="Invalid sub job.")
    if body.subJob and body.subJob == body.mainJob:
        raise HTTPException(status_code=400, detail="Sub job can't be the same as main.")
    conn = db_write()
    try:
        with conn.cursor() as cur:
            owned_char(cur, acct["id"], body.charid)
            if not is_offline(cur, body.charid):
                raise HTTPException(status_code=409, detail="That character is online -- log out of the game first.")
            cur.execute("SELECT * FROM char_jobs WHERE charid=%s", (body.charid,))
            jr = cur.fetchone() or {}
            mlvl = int(jr.get(JOB_COLS[body.mainJob - 1], 0) or 0)
            if mlvl < 1:
                raise HTTPException(status_code=409, detail=f"{JOBS[body.mainJob]} isn't unlocked on this character.")
            slvl = 0
            if body.subJob:
                sj = int(jr.get(JOB_COLS[body.subJob - 1], 0) or 0)
                if sj < 1:
                    raise HTTPException(status_code=409, detail=f"{JOBS[body.subJob]} isn't unlocked on this character.")
                slvl = min(sj, mlvl // 2)  # sub capped at half main level
            cur.execute("UPDATE char_stats SET mjob=%s, sjob=%s, mlvl=%s, slvl=%s WHERE charid=%s",
                        (body.mainJob, body.subJob, mlvl, slvl, body.charid))
            if cur.rowcount == 0:
                raise HTTPException(status_code=404, detail="No stats record for this character.")
        conn.commit()
        return {"ok": True}
    except HTTPException:
        conn.rollback()
        raise
    except Exception:
        conn.rollback()
        raise HTTPException(status_code=500, detail="Job change failed -- nothing was changed.")
    finally:
        conn.close()


@app.post("/api/char/appearance")
def char_appearance(body: AppearanceBody, request: Request):
    """Change an OFFLINE character's race/face (cosmetic). Own-account only."""
    acct = require_account(request)
    if not (1 <= body.race <= 8):
        raise HTTPException(status_code=400, detail="Race must be 1-8.")
    if not (0 <= body.face <= 15):
        raise HTTPException(status_code=400, detail="Face must be 0-15.")
    size = 0 if body.race in (5, 6) else (2 if body.race in (3, 4, 8) else 1)  # Taru small, Elvaan/Galka large
    conn = db_write()
    try:
        with conn.cursor() as cur:
            owned_char(cur, acct["id"], body.charid)
            if not is_offline(cur, body.charid):
                raise HTTPException(status_code=409, detail="That character is online -- log out of the game first.")
            cur.execute("UPDATE char_look SET race=%s, face=%s, size=%s WHERE charid=%s",
                        (body.race, body.face, size, body.charid))
            if cur.rowcount == 0:
                raise HTTPException(status_code=404, detail="No appearance record for this character.")
        conn.commit()
        return {"ok": True, "race": body.race, "face": body.face}
    except HTTPException:
        conn.rollback()
        raise
    except Exception:
        conn.rollback()
        raise HTTPException(status_code=500, detail="Appearance change failed -- nothing was changed.")
    finally:
        conn.close()


# ---- legacy migration reward -------------------------------------------------
class LegacyRewardBody(BaseModel):
    charid: int
    option_id: str
    job: int | None = None   # required only for options with needs_job (Free Job to 99): jobId 1-22


@app.get("/api/legacy-reward/{charid}")
def legacy_reward_get(charid: int, request: Request):
    """Per-option claim status for the Legendary migration rewards. Own-account only.
    Rewards are independently claimable (2026-07-13 owner call) -- one entry per
    option, each with its own `claimed` boolean."""
    acct = require_account(request)
    conn = db()
    try:
        with conn.cursor() as cur:
            owner = owned_char(cur, acct["id"], charid)
            option_claims = {
                o["id"]: bool(_get_charvar(cur, charid, _reward_claim_var(o["id"])))
                for o in LEGACY_REWARD_OPTIONS
            }
    finally:
        conn.close()

    return {
        "charid":    charid,
        "name":      owner["charname"],
        # allClaimed = true only when every reward is claimed; drives the ✓
        # indicator in the character-selector.
        "allClaimed": all(option_claims.values()) if option_claims else False,
        "options":   [
            {
                "id":          o["id"],
                "label":       o["label"],
                "description": o["description"],
                "needsJob":    o.get("needs_job", False),
                "claimed":     option_claims[o["id"]],
            }
            for o in LEGACY_REWARD_OPTIONS
        ],
    }


@app.post("/api/legacy-reward")
def legacy_reward_claim(body: LegacyRewardBody, request: Request):
    """Claim the one-time Legendary migration reward for an OFFLINE character. Own-account only."""
    acct = require_account(request)
    option = _REWARD_BY_ID.get(body.option_id)
    if not option:
        raise HTTPException(status_code=400, detail="Unknown reward option.")

    conn = db_write()
    try:
        with conn.cursor() as cur:
            owned_char(cur, acct["id"], body.charid)
            if not is_offline(cur, body.charid):
                raise HTTPException(status_code=409, detail="That character is online -- log out of the game first.")
            # Per-option claim lock (2026-07-13 owner call: each reward is
            # independently claimable). Row-lock the specific option's var to
            # prevent a double-click race on that option, while leaving the
            # other rewards freely available on the same character.
            claim_var = _reward_claim_var(body.option_id)
            cur.execute(
                "SELECT value FROM char_vars WHERE charid=%s AND varname=%s FOR UPDATE",
                (body.charid, claim_var),
            )
            existing = cur.fetchone()
            if existing and int(existing.get("value") or 0):
                raise HTTPException(status_code=409, detail=f"'{option['label']}' already claimed on this character.")

            # Write reward vars.
            if option.get("needs_job"):
                # Free Job to 99: the player picks WHICH job; store the jobId. The
                # Relaunch login hook (legacy_freejob_grant.lua) unlocks it, switches
                # to it, and sets it to 99 on first login.
                job = body.job or 0
                if not (1 <= job <= 22):
                    raise HTTPException(status_code=400, detail="Choose a valid job for the Free Job to 99 reward.")
                _upsert_charvar(cur, body.charid, option["var"], job)
            else:
                # Fixed grant -- never overwrite a higher value the player already has.
                for varname, value in option["vars"].items():
                    if value > _get_charvar(cur, body.charid, varname):
                        _upsert_charvar(cur, body.charid, varname, value)

            # Stamp both the per-option claim var and the legacy indicator (so
            # any code that reads "has claimed anything" still works).
            _upsert_charvar(cur, body.charid, claim_var, 1)
            _upsert_charvar(cur, body.charid, LEGACY_REWARD_CLAIMED_VAR, 1)

        conn.commit()
        return {"ok": True, "option": option["id"], "label": option["label"]}
    except HTTPException:
        conn.rollback()
        raise
    except Exception:
        conn.rollback()
        raise HTTPException(status_code=500, detail="Claim failed -- nothing was changed.")
    finally:
        conn.close()


# ------------------------------------------------------------- public routes --
@app.get("/api/status")
def status():
    """Who's online right now, plus population history if the sampler table exists."""
    conn = db()
    try:
        with conn.cursor() as cur:
            cur.execute(
                "SELECT c.charname, c.pos_zone, "
                "       COALESCE(s.mjob,0) AS mjob, COALESCE(s.mlvl,1) AS mlvl, "
                "       COALESCE(s.sjob,0) AS sjob, COALESCE(s.slvl,1) AS slvl "
                "FROM accounts_sessions ses "
                "JOIN chars c ON c.charid = ses.charid "
                "LEFT JOIN char_stats s ON s.charid = c.charid "
                "ORDER BY c.charname"
            )
            sess = cur.fetchall()
            players = [{
                "name": r["charname"],
                "job":  JOBS.get(r["mjob"], "?"),
                "lvl":  r["mlvl"],
                "sub":  JOBS.get(r["sjob"], "NON"),
                "subLvl": r["slvl"],
                "zone": zone_name(cur, r["pos_zone"]),
            } for r in sess]

            history = []
            try:
                cur.execute(
                    "SELECT UNIX_TIMESTAMP(ts) AS t, online FROM portal_pop_history "
                    "ORDER BY ts DESC LIMIT 288"
                )
                history = [{"t": int(r["t"]), "n": int(r["online"])} for r in reversed(cur.fetchall())]
            except (pymysql.err.ProgrammingError, pymysql.err.OperationalError):
                # sampler table not created (or not granted) -> graph shows "collecting".
                # A no-grant read returns 1142 (OperationalError), not 1146, so catch both.
                pass
    finally:
        conn.close()

    return {"online": len(players), "players": players, "history": history}


@app.get("/api/profile/{name}")
def profile(name: str):
    """Public trophy page for one character. No gil / inventory / location on purpose."""
    conn = db()
    try:
        with conn.cursor() as cur:
            cur.execute(
                "SELECT c.charid, c.charname, c.nation, c.playtime, "
                "       COALESCE(s.mjob,0) AS mjob, COALESCE(s.sjob,0) AS sjob, "
                "       COALESCE(s.mlvl,1) AS mlvl, COALESCE(s.slvl,1) AS slvl, "
                "       COALESCE(s.hp,0)   AS hp,   COALESCE(s.mp,0)   AS mp, "
                "       COALESCE(h.enemies_defeated,0)  AS kills, "
                "       COALESCE(h.times_knocked_out,0) AS deaths, "
                "       COALESCE(h.battles_fought,0)    AS battles "
                "FROM chars c "
                "LEFT JOIN char_stats s   ON s.charid = c.charid "
                "LEFT JOIN char_history h ON h.charid = c.charid "
                "WHERE c.charname = %s",
                (name,),
            )
            c = cur.fetchone()
            if not c:
                raise HTTPException(status_code=404, detail="No such character.")
            cid = c["charid"]

            cur.execute("SELECT * FROM char_jobs WHERE charid = %s", (cid,))
            jrow = cur.fetchone() or {}
            jobs = sorted(
                ({"job": col.upper(), "lvl": int(jrow.get(col, 0) or 0)} for col in JOB_COLS),
                key=lambda j: j["lvl"], reverse=True,
            )
            maxed = sum(1 for j in jobs if j["lvl"] >= 99)

            pv = load_progression(cur, [cid]).get(cid, {})

            cur.execute("SELECT title, accent, featured, showcase FROM portal_profile WHERE charid = %s", (cid,))
            prof = cur.fetchone() or {}
    finally:
        conn.close()

    mjob = c["mjob"]
    hl   = pv.get("HL_Tier", 0)
    asc  = pv.get("Prestige_Ascensions_Total", 0)
    nmk  = pv.get("Custom_NM_Kills", 0)
    rb   = pv.get(f"Rebirth_Count_{mjob}", 0)

    badges = earned_badges(mjob, int(c["kills"]), jobs, pv)
    tags   = [b["label"] for b in badges]

    # Player customizations (all validated against what they've actually earned).
    earned_ids = {b["id"] for b in badges}
    owned_jobs = {j["job"] for j in jobs if j["lvl"] > 1}
    accent   = prof.get("accent") if prof.get("accent") in ACCENTS else DEFAULT_ACCENT
    title    = sanitize_title(prof.get("title"))
    featured = prof.get("featured") if prof.get("featured") in earned_ids else None
    showcase = [j for j in (prof.get("showcase") or "").split(",") if j in owned_jobs][:MAX_SHOWCASE]

    return {
        "name":      c["charname"],
        "nation":    NATIONS.get(c["nation"], "?"),
        "mainJob":   JOBS.get(mjob, "?"),
        "mainLvl":   c["mlvl"],
        "subJob":    JOBS.get(c["sjob"], "NON"),
        "subLvl":    c["slvl"],
        "hp":        c["hp"],
        "mp":        c["mp"],
        "playtimeH": (c["playtime"] or 0) // 3600,
        "kills":     int(c["kills"]),
        "deaths":    int(c["deaths"]),
        "battles":   int(c["battles"]),
        "maxedJobs": maxed,
        "jobs":      [j for j in jobs if j["lvl"] > 1],
        "hlTier":    hl,
        "ascensions": asc,
        "nmKills":   nmk,
        "rebirthCount": rb,
        "tags":      tags,
        "badges":    badges,
        "title":     title,
        "accent":    accent,
        "accentHex": ACCENTS[accent],
        "featured":  featured,
        "featuredLabel": next((b["label"] for b in badges if b["id"] == featured), None),
        "showcase":  showcase,
    }


class ProfileCustomBody(BaseModel):
    charid:   int
    title:    str = ""
    accent:   str = DEFAULT_ACCENT
    featured: str = ""
    showcase: list[str] = []


def _char_cosmetic_context(cur, charid):
    """(mjob, kills, jobs, pv) used by both the customize GET and POST."""
    cur.execute("SELECT COALESCE(mjob,0) AS mjob FROM char_stats WHERE charid=%s", (charid,))
    mjob = (cur.fetchone() or {}).get("mjob", 0)
    cur.execute("SELECT COALESCE(enemies_defeated,0) AS kills FROM char_history WHERE charid=%s", (charid,))
    kills = int((cur.fetchone() or {}).get("kills", 0) or 0)
    cur.execute("SELECT * FROM char_jobs WHERE charid=%s", (charid,))
    jrow = cur.fetchone() or {}
    jobs = sorted(({"job": col.upper(), "lvl": int(jrow.get(col, 0) or 0)} for col in JOB_COLS),
                  key=lambda j: j["lvl"], reverse=True)
    pv = load_progression(cur, [charid]).get(charid, {})
    return mjob, kills, jobs, pv


@app.get("/api/profile-custom/{charid}")
def profile_custom_get(charid: int, request: Request):
    """Current cosmetics + the options this character may choose from. Own-account only."""
    acct = require_account(request)
    conn = db()
    try:
        with conn.cursor() as cur:
            owned_char(cur, acct["id"], charid)
            mjob, kills, jobs, pv = _char_cosmetic_context(cur, charid)
            cur.execute("SELECT title, accent, featured, showcase FROM portal_profile WHERE charid=%s", (charid,))
            prof = cur.fetchone() or {}
    finally:
        conn.close()
    return {
        "charid": charid,
        "current": {
            "title":    sanitize_title(prof.get("title")),
            "accent":   prof.get("accent") if prof.get("accent") in ACCENTS else DEFAULT_ACCENT,
            "featured": prof.get("featured") or "",
            "showcase": [j for j in (prof.get("showcase") or "").split(",") if j][:MAX_SHOWCASE],
        },
        "options": {
            "accents":     [{"id": k, "hex": v} for k, v in ACCENTS.items()],
            "badges":      earned_badges(mjob, kills, jobs, pv),
            "jobs":        [j for j in jobs if j["lvl"] > 1],
            "maxTitle":    MAX_TITLE,
            "maxShowcase": MAX_SHOWCASE,
        },
    }


@app.post("/api/profile-custom")
def profile_custom_save(body: ProfileCustomBody, request: Request):
    """Save profile cosmetics. Own-account only; validated to earned/allowed values."""
    acct = require_account(request)
    conn = db_write()
    try:
        with conn.cursor() as cur:
            owned_char(cur, acct["id"], body.charid)
            mjob, kills, jobs, pv = _char_cosmetic_context(cur, body.charid)
            earned = {b["id"] for b in earned_badges(mjob, kills, jobs, pv)}
            owned  = {j["job"] for j in jobs if j["lvl"] > 1}
            title    = sanitize_title(body.title)
            accent   = body.accent if body.accent in ACCENTS else DEFAULT_ACCENT
            featured = body.featured if body.featured in earned else ""
            showcase = ",".join([j for j in (body.showcase or []) if j in owned][:MAX_SHOWCASE])
            cur.execute(
                "INSERT INTO portal_profile (charid, title, accent, featured, showcase) "
                "VALUES (%s,%s,%s,%s,%s) "
                "ON DUPLICATE KEY UPDATE title=VALUES(title), accent=VALUES(accent), "
                "  featured=VALUES(featured), showcase=VALUES(showcase)",
                (body.charid, title, accent, featured, showcase),
            )
        conn.commit()
    except HTTPException:
        conn.rollback(); raise
    except Exception as e:
        conn.rollback()
        # Surface the real cause to the server log (the generic message once hid a
        # DB "Access denied ... char_history" grant gap for portal_rw, 2026-07).
        print(f"[profile_custom_save] charid={body.charid} failed: {type(e).__name__}: {e}", flush=True)
        raise HTTPException(status_code=500, detail="Save failed -- nothing was changed.")
    finally:
        conn.close()
    return {"ok": True, "title": title, "accent": accent, "featured": featured,
            "showcase": showcase.split(",") if showcase else []}


# ------------------------------------------------------------- live events ----
# Read straight from the game's own schedule/state so the board can never drift.
INVASION_HOURS      = [0, 3, 6, 9, 12, 15, 18, 21]   # Al Zahbi, UTC (invasion_catalog.windows)
INVASION_WARN_MIN   = 5     # server-wide warning this many min before (catalog.warnMinutes)
INVASION_ACTIVE_MIN = 10    # the armed grace window (catalog.graceMinutes) -- window is "open"
WORLD_BOSSES = [            # world_boss.lua BOSSES, in rotation order
    "Ancient Behemoth", "Absolute Virtue Reborn", "Grand Pandemonium", "Eternal Shinryu",
    "Lord Kirin Ascendant", "Vrtra the Unbound", "Nidhogg Unchained", "Simurgh Eternal",
]
# Domain Invasion (domain_invasion_catalog.lua windows: every 3h, zones alternate)
DOMAIN_ZONES = ["Escha - Zi'Tah", "Escha - Ru'Aun"]              # zoneIdx 1 / 2
DOMAIN_HOURS = [(0, 0), (3, 1), (6, 0), (9, 1), (12, 0), (15, 1), (18, 0), (21, 1)]
# Happy Hour (happy_hour.lua WINDOWS -- keep in sync): (startHourUTC, startMin, durationMin)
HH_WINDOWS = [(20, 0, 60)]
# Dynamis [D] City of the Day (dynamis_divergence.lua featuredZoneToday: 294 + epochday % 4)
DYNA_CITIES = ["San d'Oria [D]", "Bastok [D]", "Windurst [D]", "Jeuno [D]"]
# Unity Wanted weekly featured NM (unity_wanted.lua weeklyFeaturedId():
# (time // 604800) % #nms + 1 -- double accolades). Labels in catalog id order 1..56.
UNITY_WANTED_NMS = [
    "Hugemaw Harold", "Prickly Pitriv", "Serpopard Ninlil", "Abyssdiver",
    "Keeper of Heiligtum", "Jester Malatrix", "Immanibugard", "Orcfeltrap",
    "Ironhorn Baldurno", "Sleepy Mabel", "Sybaritic Samantha", "Bounding Belinda",
    "Valkurm Imperator", "Joyous Green", "Warblade Beak", "Cactrot Veloz",
    "Woodland Mender", "Emperor Arthro", "Tiyanak", "Vermillion Fishfly",
    "Intuila", "Muut", "Voso", "Beist",
    "Lumber Jill", "Largantua", "Garbage Gel", "King Uropygid",
    "Vedrfolnir", "Glazemane", "Volatile Cluster", "Strix",
    "Sovereign Behemoth", "Arke", "Douma Weapon", "Kubool Jas Mhuufya",
    "Thu'ban", "Tumult Curator", "Specter Worm", "Bakunawa",
    "Mephitas", "Vidmapire", "Shedu", "Azure-toothed Clawberry",
    "Centurio XX-I", "Wyvernhunter Bambrox", "Tolba", "Ayapec",
    "Hidhaegg", "Coca", "Grand Grenade", "Sarama",
    "Azrael", "Carousing Celine", "Camahueto", "Borealis Shadow",
]

@app.get("/api/events")
def events():
    """Live event board: next Al Zahbi invasion + the weekly World Boss. Public.
    Countdowns compute from the fixed schedule; live state reads server_variables."""
    now   = int(time.time())
    today = now // 86400                       # epoch-day (matches the game's clock)
    day0  = today * 86400

    windows = [day0 + d * 86400 + h * 3600 for d in (0, 1) for h in INVASION_HOURS]
    prev_w  = max((t for t in windows if t <= now), default=None)
    next_w  = min(t for t in windows if t > now)

    conn = db()
    try:
        with conn.cursor() as cur:
            cur.execute("SELECT name, value FROM server_variables "
                        "WHERE name LIKE '[WB]%' OR name LIKE '[Inv]Done_%'")
            sv = {r["name"]: int(r["value"] or 0) for r in cur.fetchall()}
    except Exception:
        sv = {}
    finally:
        conn.close()

    inv_active = False
    if prev_w is not None:
        idx  = INVASION_HOURS.index((prev_w // 3600) % 24) + 1
        done = sv.get(f"[Inv]Done_{idx}", 0)
        inv_active = (now - prev_w < INVASION_ACTIVE_MIN * 60) and (done != today)
    inv_warn = (next_w - now) <= INVASION_WARN_MIN * 60

    invasion = {
        "id": "invasion", "name": "Al Zahbi Invasion", "zone": "Al Zahbi", "icon": "⚔",
        "cadence": "Every 3 hours",
        "desc": "The Voidsent storm Al Zahbi. Everyone online is called to defend the city — waves scale with the defenders present.",
        "next": next_w, "active": inv_active, "warning": inv_warn and not inv_active,
    }

    active = sv.get("[WB]Active", 0)
    bidx   = sv.get("[WB]BossIdx", 1) or 1
    boss   = WORLD_BOSSES[(bidx - 1) % len(WORLD_BOSSES)]
    hp, maxhp = sv.get("[WB]HP", 0), sv.get("[WB]MaxHP", 0)
    off      = (3 - today % 7) % 7             # game defines Sunday as epoch-day % 7 == 3
    next_sun = (today + off) * 86400
    if next_sun <= now:
        next_sun += 7 * 86400

    wb = {
        "id": "worldboss", "name": "Weekly World Boss", "zone": "West Ronfaure", "icon": "\U0001F409",
        "cadence": "Sundays 00:00 UTC", "boss": boss,
        "desc": "A colossal foe descends every week — eight legends rotate through the calendar.",
    }
    if active == 1:
        wb.update({"state": "alive", "hp": hp, "maxHp": maxhp,
                   "hpPct": round(hp * 100 / maxhp) if maxhp else 0, "active": True})
    elif active == 2:
        wb.update({"state": "defeated", "next": next_sun, "active": False})
    else:
        wb.update({"state": "idle", "next": next_sun, "active": False})

    # ---- Domain Invasion (schedule-only; zones alternate every 3h) ----------
    dwindows = [(day0 + d * 86400 + h * 3600, z) for d in (0, 1) for (h, z) in DOMAIN_HOURS]
    dnext, dzone = min((t, z) for (t, z) in dwindows if t > now)
    domain = {
        "id": "domain", "name": "Domain Invasion", "zone": "Escha", "icon": "\U0001F300",
        "cadence": "Every 3 hours",
        "desc": "Dahaka and Lamia legions flood an Escha domain in waves. Silt, beads and Domain Points for the defenders.",
        "featured": f"Next battleground: {DOMAIN_ZONES[dzone]}",
        "next": dnext, "nextLabel": "until the rift tears open",
        "warning": (dnext - now) <= 5 * 60, "active": False,
    }

    # ---- Happy Hour ---------------------------------------------------------
    hh_now, hh_next = None, None
    for d in (-1, 0, 1):
        for (h, mnt, dur) in HH_WINDOWS:
            s = day0 + d * 86400 + h * 3600 + mnt * 60
            if s <= now < s + dur * 60:
                hh_now = (s, s + dur * 60)
            elif s > now and (hh_next is None or s < hh_next):
                hh_next = s
    happy = {
        "id": "happyhour", "name": "Happy Hour", "zone": "Vana'diel-wide", "icon": "\U0001F37B",
        "cadence": "Daily 20:00-21:00 UTC",
        "desc": "The tavern opens: +50% EXP and +50% Capacity Points for everyone online, the whole hour.",
    }
    if hh_now:
        happy.update({"active": True, "stateText": "Happy Hour is ON — drink up!",
                      "next": hh_now[1], "nextLabel": "until last call"})
    else:
        happy.update({"active": False, "next": hh_next, "nextLabel": "until the tavern opens"})

    # ---- Unity Wanted: weekly featured NM (double accolades) ----------------
    week = now // 604800
    wanted = {
        "id": "wanted", "name": "Wanted: Featured Hunt", "zone": "Unity Concord", "icon": "\U0001F3AF",
        "cadence": "Rotates Thursdays 00:00 UTC",
        "desc": "One Wanted NM pays DOUBLE accolades all week. Take the contract at the Unity board in the Library.",
        "featured": f"This week: {UNITY_WANTED_NMS[week % len(UNITY_WANTED_NMS)]}",
        "next": (week + 1) * 604800, "nextLabel": "until the next mark",
        "active": False,
    }

    # ---- Dynamis [D]: City of the Day ---------------------------------------
    dyna = {
        "id": "dynacity", "name": "Divergence: City of the Day", "zone": "Dynamis [D]", "icon": "\U0001F3F0",
        "cadence": "Rotates daily 00:00 UTC",
        "desc": "Clear today's featured city for bonus spoils: 1 Demon's Medal + 2 Kindred's Medals per member.",
        "featured": f"Today: {DYNA_CITIES[today % len(DYNA_CITIES)]}",
        "next": (today + 1) * 86400, "nextLabel": "until the rift shifts",
        "active": False,
    }

    # ---- Resets board (daily / weekly / monthly) ----------------------------
    next_midnight = (today + 1) * 86400
    next_monday   = (today + (((4 - today % 7) % 7) or 7)) * 86400   # epoch day 0 = Thursday; Monday = day%7==4
    ymd = datetime.datetime.fromtimestamp(now, datetime.timezone.utc)
    nm_y, nm_m = (ymd.year + 1, 1) if ymd.month == 12 else (ymd.year, ymd.month + 1)
    next_month1 = int(datetime.datetime(nm_y, nm_m, 1, tzinfo=datetime.timezone.utc).timestamp())
    resets = {
        "id": "resets", "name": "Resets", "zone": "Vana'diel-wide", "icon": "⏳",
        "cadence": "Daily / weekly / monthly",
        "desc": "When the boards refresh.",
        "rows": [
            {"label": "Daily Board objectives",     "next": next_midnight},
            {"label": "Weekly Hunts (5 new marks)", "next": next_monday},
            {"label": "Ambuscade Hallmark cap",     "next": next_month1},
        ],
        "active": False,
    }

    return {"now": now, "events": [invasion, happy, domain, wanted, dyna, wb, resets]}


# ================================================================ market ======
@app.get("/api/bazaars")
def bazaars(q: str = ""):
    """Server-wide player bazaars (items priced > 0). Public."""
    conn = db()
    try:
        with conn.cursor() as cur:
            cur.execute(
                "SELECT i.itemId, i.quantity, i.bazaar AS price, c.charname, c.pos_zone "
                "FROM char_inventory i JOIN chars c ON c.charid = i.charid "
                "WHERE i.bazaar > 0 ORDER BY i.bazaar ASC LIMIT 800")
            rows = cur.fetchall()
            items = []
            for r in rows:
                name, img, wiki = item_display(r["itemId"], None)
                items.append({"itemId": r["itemId"], "name": name, "img": img, "wiki": wiki,
                              "price": int(r["price"]), "qty": int(r["quantity"]),
                              "seller": r["charname"], "zone": zone_name(cur, r["pos_zone"])})
    finally:
        conn.close()
    if q:
        ql = q.lower()
        items = [it for it in items if ql in it["name"].lower()]
    return {"count": len(items), "items": items}


@app.get("/api/ah")
def ah_prices(q: str = ""):
    """Auction House: match items by name, return recent sales + cheapest listings. Public."""
    ql = q.strip().lower()
    if len(ql) < 2:
        return {"matches": []}
    ids = [iid for iid, t in ITEM_THUMBS.items() if ql in t["n"].lower()][:8]
    if not ids:
        return {"matches": []}
    conn = db()
    out = []
    try:
        with conn.cursor() as cur:
            for iid in ids:
                name, img, wiki = item_display(iid, None)
                cur.execute("SELECT price, sell_date, stack FROM auction_house "
                            "WHERE itemid=%s AND sale > 0 ORDER BY sell_date DESC LIMIT 8", (iid,))
                sales = [{"price": int(s["price"]), "date": int(s["sell_date"] or 0),
                          "stack": int(s["stack"] or 0)} for s in cur.fetchall()]
                cur.execute("SELECT price, stack, seller_name FROM auction_house "
                            "WHERE itemid=%s AND sale = 0 ORDER BY price ASC LIMIT 6", (iid,))
                listings = [{"price": int(l["price"]), "stack": int(l["stack"] or 0),
                             "seller": l["seller_name"]} for l in cur.fetchall()]
                avg = round(sum(s["price"] for s in sales) / len(sales)) if sales else None
                out.append({"itemId": iid, "name": name, "img": img, "wiki": wiki,
                            "avg": avg, "sales": sales, "listings": listings})
    finally:
        conn.close()
    out.sort(key=lambda m: (0 if m["name"].lower() == ql else 1, len(m["name"])))
    return {"matches": out}


# ================================================================ gear =========
EQUIP_SLOTS = ["Main", "Sub", "Ranged", "Ammo", "Head", "Body", "Hands", "Legs",
               "Feet", "Neck", "Waist", "Ear 1", "Ear 2", "Ring 1", "Ring 2", "Back"]

@app.get("/api/gear/{charid}")
def gear(charid: int, request: Request):
    """Equipped gear by slot + augment presence + an augment advisor. Own-account only."""
    acct = require_account(request)
    conn = db()
    try:
        with conn.cursor() as cur:
            owner = owned_char(cur, acct["id"], charid)
            cur.execute(
                "SELECT e.slotid, i.itemId, i.extra FROM char_equip e "
                "LEFT JOIN char_inventory i ON i.charid = e.charid "
                "  AND i.location = e.containerid AND i.slot = e.slotid "
                "WHERE e.charid = %s", (charid,))
            rows = {r["slotid"]: r for r in cur.fetchall()}
    finally:
        conn.close()

    slots, augged, bare, empty = [], 0, [], []
    for sid in range(16):
        r = rows.get(sid)
        entry = {"slot": EQUIP_SLOTS[sid], "slotId": sid, "equipped": False}
        if r and r.get("itemId"):
            name, img, wiki = item_display(r["itemId"], None)
            ex = r.get("extra")
            has_aug = bool(ex) and len(ex) > 0 and ex[0] != 0   # AugmentKind byte (0 = none)
            entry.update({"equipped": True, "itemId": r["itemId"], "name": name,
                          "img": img, "wiki": wiki, "augmented": has_aug})
            if has_aug: augged += 1
            else:       bare.append(EQUIP_SLOTS[sid])
        else:
            empty.append(EQUIP_SLOTS[sid])
        slots.append(entry)
    return {"charid": charid, "name": owner["charname"], "slots": slots,
            "equippedCount": sum(1 for s in slots if s["equipped"]),
            "augmentedCount": augged, "bareSlots": bare, "emptySlots": empty}


# ============================================================ achievements ====
ACHIEVEMENTS = [   # id (-> char_var ACH_<id>), display name, flavor
    ("FIRST_HUNT", "First Hunt", "Your first Hunting League kill -- the legend begins."),
    ("TENTH_HUNT", "Ten Hunts", "Veteran of ten hunts. You know the drill."),
    ("CENTURY", "Century", "100 Hunting League kills. No signs of stopping."),
    ("THOUSAND", "Thousand Slayer", "1,000 NM kills. You have earned the title."),
    ("TIER2_FIRST", "Tier II Slayer", "First kill from the Tier II roster."),
    ("TIER3_FIRST", "Tier III Slayer", "First kill from the Tier III roster."),
    ("TIER4_FIRST", "Tier IV Slayer", "First kill from the Tier IV roster."),
    ("APEX_HUNTER", "Apex Hunter", "First Tier V kill -- the hardest NMs on the server."),
    ("MARKS_1K", "Marked Hunter", "1,000 lifetime Hunt Marks."),
    ("MARKS_10K", "Devotee", "10,000 lifetime Hunt Marks."),
    ("MARKS_100K", "Legend of the Hunt", "100,000 lifetime Hunt Marks."),
    ("FIRST_WAVE", "Wave Survivor", "Survived your first wave fight."),
    ("WAVE_FIGHTER", "Wave Fighter", "10 lifetime wave fights cleared."),
    ("WAVE_LEGEND", "Wave Legend", "50 lifetime wave fights."),
    ("FIRST_ASCENSION", "Ascendant", "Your first Prestige ascension."),
    ("TEN_ASCENSIONS", "Tenfold Ascendant", "10 lifetime Prestige ascensions."),
    ("FIFTY_ASCENSIONS", "Beyond Mortal Limits", "50 lifetime ascensions."),
    ("DERBY_FIRST_WIN", "Derby Winner", "Your first Chocobo Derby win."),
    ("DERBY_10_WINS", "Derby Champion", "10 Derby wins."),
    ("DERBY_OWN_WIN", "Homegrown Champion", "Won the Derby on your OWN raised chocobo."),
    ("TH_FIRST_CHEST", "Treasure Hunter", "Unearthed your first buried strongbox."),
    ("TH_10_CHESTS", "Strongbox Raider", "10 strongboxes unearthed across Vana'diel."),
    ("LEAGUE_FIRST_TURNIN", "Provisioner", "Your first catch on the League scales."),
    ("LEAGUE_RANK3", "Master Provisioner", "Reached rank 3 of the Provisioners' League."),
    ("LEAGUE_RANK5", "League Summit", "The Provisioners' League's summit."),
    ("RAID_FIRST_KILL", "Star-Slayer", "Felled the Star-Devourer for the first time."),
    ("RAID_10_KILLS", "Devourer's Bane", "10 Star-Devourer kills. It fears YOU now."),
    ("INV_FIRST_DEFENSE", "City Defender", "Defended against your first invasion."),
]
_ACH_KNOWN = {f"ACH_{i}" for (i, _, _) in ACHIEVEMENTS}
# The achievements endpoint (with "new since acknowledged" detection) lives in
# the community-feel block further down, alongside the sampler that unlocks them.


# ================================================================ recap ========
@app.get("/api/recap/{charid}")
def recap(charid: int, request: Request):
    """This-week streaks & momentum. Own-account only."""
    acct = require_account(request)
    conn = db()
    try:
        with conn.cursor() as cur:
            owner = owned_char(cur, acct["id"], charid)
            cur.execute("SELECT varname, value FROM char_vars WHERE charid=%s AND varname IN "
                        "('DailyReward_Streak','DailyReward_BestStreak','HL_Streak_Count','WH_KillStreak')", (charid,))
            v = {r["varname"]: int(r["value"] or 0) for r in cur.fetchall()}
    finally:
        conn.close()
    streaks = []
    if v.get("DailyReward_Streak"):     streaks.append({"label": "Daily login streak", "value": v["DailyReward_Streak"], "unit": "days"})
    if v.get("DailyReward_BestStreak"): streaks.append({"label": "Best login streak", "value": v["DailyReward_BestStreak"], "unit": "days"})
    if v.get("HL_Streak_Count"):        streaks.append({"label": "Hunting League streak", "value": v["HL_Streak_Count"], "unit": "kills"})
    if v.get("WH_KillStreak"):          streaks.append({"label": "Weekly hunt streak", "value": v["WH_KillStreak"], "unit": "kills"})
    return {"charid": charid, "name": owner["charname"], "streaks": streaks}


# ================================================================ admin ========
GM_PRIV_MIN = 1   # accounts.priv >= this counts as staff

def require_gm(request: Request) -> dict:
    acct = require_account(request)
    conn = db()
    try:
        with conn.cursor() as cur:
            cur.execute("SELECT priv FROM accounts WHERE id=%s", (acct["id"],))
            row = cur.fetchone() or {}
    finally:
        conn.close()
    if int(row.get("priv", 0) or 0) < GM_PRIV_MIN:
        raise HTTPException(status_code=403, detail="Staff access required.")
    return acct

@app.get("/api/admin/overview")
def admin_overview(request: Request):
    """Staff dashboard: who's online, population, recent signups. GM only."""
    require_gm(request)
    conn = db()
    try:
        with conn.cursor() as cur:
            cur.execute("SELECT c.charname, c.pos_zone, a.login, COALESCE(s.mjob,0) AS mjob, "
                        "COALESCE(s.mlvl,1) AS mlvl FROM accounts_sessions ses "
                        "JOIN chars c ON c.charid = ses.charid "
                        "LEFT JOIN char_stats s ON s.charid = c.charid "
                        "LEFT JOIN accounts a ON a.id = c.accid ORDER BY c.charname")
            online = [{"name": r["charname"], "login": r["login"], "job": JOBS.get(r["mjob"], "?"),
                       "lvl": r["mlvl"], "zone": zone_name(cur, r["pos_zone"])} for r in cur.fetchall()]
            cur.execute("SELECT COUNT(*) AS n FROM accounts"); acct_ct = (cur.fetchone() or {}).get("n", 0)
            cur.execute("SELECT COUNT(*) AS n FROM chars");    char_ct = (cur.fetchone() or {}).get("n", 0)
            cur.execute("SELECT login, timecreate FROM accounts ORDER BY timecreate DESC LIMIT 12")
            recent = [{"login": r["login"], "created": str(r["timecreate"])} for r in cur.fetchall()]
    finally:
        conn.close()
    return {"online": len(online), "players": online, "accounts": acct_ct,
            "characters": char_ct, "recentAccounts": recent}


# --- Legacy Migration Reward: staff review of who lands in each reward bucket --
# (id, label, description, gate(row)->bool, detail(row)->str). Reward philosophy:
# TWO opt-in FUNCTIONAL rewards (Legendary Ring, Free Job to 99) carry over a real
# head-start; everything else is STRICTLY COSMETIC / RECOGNITION (title, glamour,
# reskin) with ZERO functional advantage. Reads xi_relaunch.legacy_snapshot
# (built by tools/legacy).
LEGACY_REWARD_CATS = [
    # -- FUNCTIONAL rewards: opt-in claim, not auto-granted --
    ("legendary_ring", "Legendary Ring (functional)", "Any Legacy account may CLAIM this instead of a cosmetic keepsake -- EXP +50%, Capacity +50%, Auto-Reraise, all jobs Lv.1.",
        lambda r: True,
        lambda r: f"eligible to claim ({r['playtime_h']}h played)"),
    ("free_job_99", "Free Job to 99 (functional)", "Any Legacy account may claim a head-start on Relaunch: one job of your choice raised to level 99.",
        lambda r: True,
        lambda r: f"eligible to claim ({r['playtime_h']}h played)"),
    # -- Cosmetic / recognition --
    ("veteran",   "Veteran's Mantle",             "Recognizes hours logged on Legendary -- a cosmetic cape whose tint deepens with playtime.",
        lambda r: r["playtime_h"] >= 50,
        lambda r: f"{r['playtime_h']}h played" + (" (deep tint)" if r["playtime_h"] >= 150 else "")),
    ("tracksuit", "Legacy Tracksuit",             "A cosmetic Legacy Tracksuit glamour for every Legendary account. (Work in progress -- built in a separate thread.)",
        lambda r: True,
        lambda r: "Legacy Tracksuit glamour (WIP)"),
]

@app.get("/api/admin/legacy")
def admin_legacy(request: Request):
    """Which accounts land in each Legacy Migration Reward bucket. GM only.

    Reads the point-in-time legacy_snapshot (Legendary progression, built by
    tools/legacy/build_legacy_snapshot.py) and buckets every account into each
    reward category so staff can review the population before finalizing.
    """
    require_gm(request)
    conn = db()
    try:
        with conn.cursor() as cur:
            try:
                cur.execute("SELECT * FROM legacy_snapshot ORDER BY tier DESC, playtime_h DESC, login")
                rows = cur.fetchall()
            except (pymysql.err.ProgrammingError, pymysql.err.OperationalError):
                return {"total_accounts": 0, "snapshotted_at": "", "categories": [],
                        "note": "No legacy_snapshot yet -- run tools/legacy/build_legacy_snapshot.py."}
    finally:
        conn.close()

    cats = []
    for cid, label, desc, gate, detail in LEGACY_REWARD_CATS:
        acs = [{"login": r["login"], "characters": r["characters"], "detail": detail(r)}
               for r in rows if gate(r)]
        cats.append({"id": cid, "label": label, "desc": desc, "count": len(acs), "accounts": acs})
    tier_names = {4: "The Unbroken", 3: "League Legend", 2: "Proven Hunter", 1: "Veteran"}
    tiers = [{"tier": t, "name": tier_names[t], "count": sum(1 for r in rows if r["tier"] == t)}
             for t in (4, 3, 2, 1)]
    snap = str(rows[0]["snapshotted_at"]) if rows else ""
    return {"total_accounts": len(rows), "snapshotted_at": snap, "tiers": tiers, "categories": cats}


@app.get("/api/health")
def health():
    return {"ok": True}


# ========================================================= community feel =====
# Optional web-push (VAPID). Absent lib -> push endpoints degrade to 501; the
# rest of notifications (in-app + Discord relay) keep working.
try:
    from pywebpush import webpush, WebPushException  # type: ignore
    _HAS_WEBPUSH = True
except Exception:
    _HAS_WEBPUSH = False


def _discord_relay(text: str):
    """Best-effort mirror of a notable event to the configured Discord webhook."""
    if not DISCORD_WEBHOOK:
        return
    try:
        data = json.dumps({"content": text[:1900]}).encode("utf-8")
        req = urllib.request.Request(DISCORD_WEBHOOK, data=data,
                                     headers={"Content-Type": "application/json"})
        urllib.request.urlopen(req, timeout=4).read()
    except Exception as e:
        print(f"[discord_relay] {type(e).__name__}: {e}", flush=True)


def _send_push(sub: dict, payload: dict) -> bool:
    """Deliver one web-push. Returns False if the subscription is dead (410/404)."""
    if not (_HAS_WEBPUSH and VAPID_PRIVATE):
        return True
    try:
        webpush(
            subscription_info={"endpoint": sub["endpoint"],
                               "keys": {"p256dh": sub["p256dh"], "auth": sub["auth"]}},
            data=json.dumps(payload),
            vapid_private_key=VAPID_PRIVATE,
            vapid_claims={"sub": VAPID_SUBJECT},
        )
        return True
    except WebPushException as e:
        code = getattr(getattr(e, "response", None), "status_code", None)
        return code not in (404, 410)   # dead endpoint -> caller prunes it
    except Exception as e:
        print(f"[send_push] {type(e).__name__}: {e}", flush=True)
        return True


# ---- leaderboards -----------------------------------------------------------
# Each: (key, title, unit, source). Source is (table, expr) resolved below.
LEADERBOARDS = [
    {"key": "kills",      "title": "Most Battles Won", "unit": "kills"},
    {"key": "nmkills",    "title": "NM Slayers",       "unit": "NM kills"},
    {"key": "hltier",     "title": "Hunting League",   "unit": "rank"},
    {"key": "ascensions", "title": "Ascendants",       "unit": "ascensions"},
    {"key": "maxedjobs",  "title": "Job Masters",      "unit": "jobs at 99"},
    {"key": "playtime",   "title": "Most Devoted",     "unit": "hours"},
]

@app.get("/api/leaderboards")
def leaderboards(board: str = "", limit: int = 10):
    """Top players across several ladders. Public; GM accounts excluded."""
    limit = max(1, min(int(limit or 10), 25))
    conn = db()
    out = {}
    try:
        with conn.cursor() as cur:
            # Exclude staff by in-game GM level (gmlevel 0 == a normal player).
            # NOTE: accounts.priv == 1 is the *normal* player value here, so it
            # cannot be used to exclude GMs -- gmlevel is the right field.
            def top_from_history():
                cur.execute(
                    "SELECT c.charname, h.enemies_defeated AS v FROM chars c "
                    "JOIN char_history h ON h.charid=c.charid "
                    "WHERE COALESCE(c.gmlevel,0)=0 AND h.enemies_defeated > 0 "
                    "ORDER BY h.enemies_defeated DESC LIMIT %s", (limit,))
                return [{"name": r["charname"], "value": int(r["v"])} for r in cur.fetchall()]

            def top_from_playtime():
                cur.execute(
                    "SELECT c.charname, c.playtime AS v FROM chars c "
                    "WHERE COALESCE(c.gmlevel,0)=0 AND c.playtime > 0 "
                    "ORDER BY c.playtime DESC LIMIT %s", (limit,))
                return [{"name": r["charname"], "value": int(r["v"]) // 3600} for r in cur.fetchall()]

            def top_from_var(varname):
                cur.execute(
                    "SELECT c.charname, v.value AS v FROM char_vars v "
                    "JOIN chars c ON c.charid=v.charid "
                    "WHERE v.varname=%s AND v.value > 0 AND COALESCE(c.gmlevel,0)=0 "
                    "ORDER BY v.value DESC LIMIT %s", (varname, limit))
                return [{"name": r["charname"], "value": int(r["v"])} for r in cur.fetchall()]

            def top_maxed():
                cols = "+".join(f"(j.{c}>=99)" for c in JOB_COLS)
                cur.execute(
                    f"SELECT c.charname, ({cols}) AS v FROM char_jobs j "
                    "JOIN chars c ON c.charid=j.charid "
                    f"WHERE COALESCE(c.gmlevel,0)=0 HAVING v > 0 ORDER BY v DESC LIMIT %s", (limit,))
                return [{"name": r["charname"], "value": int(r["v"])} for r in cur.fetchall()]

            wanted = [b for b in LEADERBOARDS if not board or b["key"] == board]
            for b in wanted:
                try:
                    if   b["key"] == "kills":      rows = top_from_history()
                    elif b["key"] == "playtime":   rows = top_from_playtime()
                    elif b["key"] == "maxedjobs":  rows = top_maxed()
                    elif b["key"] == "nmkills":    rows = top_from_var("Custom_NM_Kills")
                    elif b["key"] == "hltier":     rows = top_from_var("HL_Tier")
                    elif b["key"] == "ascensions": rows = top_from_var("Prestige_Ascensions_Total")
                    else:                          rows = []
                except Exception as e:
                    print(f"[leaderboards] {b['key']} failed: {e}", flush=True); rows = []
                out[b["key"]] = {"title": b["title"], "unit": b["unit"], "rows": rows}
    finally:
        conn.close()
    return {"boards": out, "order": [b["key"] for b in LEADERBOARDS]}


# ---- live activity feed -----------------------------------------------------
@app.get("/api/activity")
def activity(limit: int = 40):
    """Recent notable happenings: sampler events + AH sales + new adventurers."""
    limit = max(1, min(int(limit or 40), 80))
    now = int(time.time())
    feed = []
    conn = db()
    try:
        with conn.cursor() as cur:
            # (1) sampler-emitted events (level-ups, rank-ups, achievements)
            try:
                cur.execute("SELECT ts, charname, kind, detail FROM portal_activity "
                            "ORDER BY ts DESC LIMIT %s", (limit,))
                for r in cur.fetchall():
                    feed.append({"ts": int(r["ts"]), "icon": _ACT_ICON.get(r["kind"], "✦"),
                                 "who": r["charname"], "kind": r["kind"], "text": r["detail"]})
            except (pymysql.err.ProgrammingError, pymysql.err.OperationalError):
                pass
            # (2) recent big Auction House sales
            try:
                cur.execute("SELECT itemid, price, seller_name, buyer_name, sell_date "
                            "FROM auction_house WHERE sale > 0 AND price >= 50000 "
                            "ORDER BY sell_date DESC LIMIT 12")
                for r in cur.fetchall():
                    nm, _, _ = item_display(r["itemid"], None)
                    feed.append({"ts": int(r["sell_date"] or 0), "icon": "💰", "who": r["buyer_name"] or "",
                                 "kind": "sale", "text": f"bought {nm} for {int(r['price']):,} gil"})
            except Exception:
                pass
            # (3) newest adventurers (accounts.timecreate) with a character
            try:
                cur.execute("SELECT a.login, a.timecreate, c.charname FROM accounts a "
                            "LEFT JOIN chars c ON c.accid=a.id "
                            "WHERE a.timecreate IS NOT NULL ORDER BY a.timecreate DESC LIMIT 8")
                for r in cur.fetchall():
                    try: ts = int(datetime.datetime.fromisoformat(str(r["timecreate"])).timestamp())
                    except Exception: ts = 0
                    who = r["charname"] or r["login"]
                    if who:
                        feed.append({"ts": ts, "icon": "🌱", "who": who, "kind": "join",
                                     "text": "joined the adventure"})
            except Exception:
                pass
    finally:
        conn.close()
    feed = [f for f in feed if f["ts"] > 0]
    feed.sort(key=lambda f: f["ts"], reverse=True)
    return {"now": now, "events": feed[:limit]}

_ACT_ICON = {"levelup": "⬆", "hltier": "🏹", "ascension": "✨", "achievement": "🏆",
             "nmkill": "⚔", "maxjob": "⭐", "sale": "💰", "join": "🌱"}


# ---- gear set builder: real item stats --------------------------------------
# A handful of gear mods are stored scaled; divide for human display.
_MOD_DIV = {}   # modId -> divisor (kept empty: item_mods gear values are already display-scale)

@app.get("/api/items/search")
def items_search(q: str = "", limit: int = 20):
    """Item name -> id/name/img lookup for the gear set builder. Public."""
    ql = q.strip().lower()
    if len(ql) < 2:
        return {"items": []}
    limit = max(1, min(int(limit or 20), 40))
    hits = []
    for iid, t in ITEM_THUMBS.items():
        nm = t.get("n") or ""
        if ql in nm.lower():
            hits.append((0 if nm.lower() == ql else (1 if nm.lower().startswith(ql) else 2), len(nm), iid, nm, t.get("img")))
    hits.sort()
    return {"items": [{"itemId": h[2], "name": h[3], "img": h[4]} for h in hits[:limit]]}


@app.get("/api/item-mods")
def item_mods(ids: str = ""):
    """Real item_mods for a set of item ids -> readable stat lines. Public."""
    try:
        want = [int(x) for x in ids.split(",") if x.strip()][:20]
    except ValueError:
        raise HTTPException(status_code=400, detail="ids must be comma-separated integers")
    if not want:
        return {"items": {}}
    conn = db()
    out = {}
    try:
        with conn.cursor() as cur:
            fmt = ",".join(["%s"] * len(want))
            cur.execute(f"SELECT itemId, modId, value FROM item_mods WHERE itemId IN ({fmt})", want)
            per = defaultdict(list)
            for r in cur.fetchall():
                mid = int(r["modId"]); val = int(r["value"])
                label = MOD_NAMES.get(mid, f"mod {mid}")
                per[int(r["itemId"])].append({"mod": mid, "label": label, "value": val})
    finally:
        conn.close()
    for iid in want:
        nm, img, wiki = item_display(iid, None)
        out[iid] = {"name": nm, "img": img, "wiki": wiki,
                    "mods": sorted(per.get(iid, []), key=lambda m: m["label"])}
    return {"items": out}


# ---- augment planner --------------------------------------------------------
@app.get("/api/augments")
def augments_catalog(cat: int = 0, q: str = ""):
    """The relaunch augment catalog (catalyst -> augment, value ranges). Public."""
    rows = AUGMENT_CATALOG.get("augments", [])
    if cat:
        rows = [r for r in rows if r.get("cat") == cat]
    if q:
        ql = q.lower()
        rows = [r for r in rows if ql in r.get("label", "").lower() or ql in r.get("item", "").lower()]
    return {"cats": AUGMENT_CATALOG.get("cats", {}), "formula": AUGMENT_CATALOG.get("formula", ""),
            "count": len(rows), "augments": rows}


# ---- AH price trends --------------------------------------------------------
@app.get("/api/ah/trend")
def ah_trend(item: int = 0, days: int = 60):
    """Daily sale price series for one item id (single + stack). Public."""
    if not item:
        raise HTTPException(status_code=400, detail="item id required")
    days = max(7, min(int(days or 60), 180))
    since = int(time.time()) - days * 86400
    conn = db()
    try:
        with conn.cursor() as cur:
            cur.execute("SELECT stack, price, sell_date FROM auction_house "
                        "WHERE itemid=%s AND sale > 0 AND sell_date >= %s "
                        "ORDER BY sell_date ASC", (item, since))
            sales = cur.fetchall()
    finally:
        conn.close()
    def series(rows):
        by_day = defaultdict(list)
        for r in rows:
            by_day[int(r["sell_date"]) // 86400].append(int(r["price"]))
        pts = []
        for day in sorted(by_day):
            ps = by_day[day]
            pts.append({"t": day * 86400, "avg": round(sum(ps) / len(ps)),
                        "min": min(ps), "max": max(ps), "n": len(ps)})
        return pts
    single = series([r for r in sales if not r["stack"]])
    stack  = series([r for r in sales if r["stack"]])
    nm, img, wiki = item_display(item, None)
    allp = [int(r["price"]) for r in sales if not r["stack"]]
    return {"itemId": item, "name": nm, "img": img, "wiki": wiki, "days": days,
            "single": single, "stack": stack,
            "summary": {"sales": len(allp),
                        "avg": round(sum(allp) / len(allp)) if allp else None,
                        "min": min(allp) if allp else None, "max": max(allp) if allp else None}}


# ---- Wrapped: a seasonal "your legend so far" recap -------------------------
def _wrapped_for(cur, charid: int) -> dict:
    cur.execute("SELECT charname, nation, playtime FROM chars WHERE charid=%s", (charid,))
    c = cur.fetchone() or {}
    cur.execute("SELECT COALESCE(mjob,0) AS mjob, COALESCE(mlvl,1) AS mlvl FROM char_stats WHERE charid=%s", (charid,))
    st = cur.fetchone() or {}
    cur.execute("SELECT enemies_defeated, times_knocked_out, battles_fought, spells_cast, "
                "abilities_used, ws_used, items_used, distance_travelled FROM char_history WHERE charid=%s", (charid,))
    h = cur.fetchone() or {}
    cur.execute("SELECT * FROM char_jobs WHERE charid=%s", (charid,))
    jrow = cur.fetchone() or {}
    jobs = sorted(({"job": col.upper(), "lvl": int(jrow.get(col, 0) or 0)} for col in JOB_COLS),
                  key=lambda j: j["lvl"], reverse=True)
    pv = load_progression(cur, [charid]).get(charid, {})
    maxed = [j["job"] for j in jobs if j["lvl"] >= 99]
    kills = int(h.get("enemies_defeated", 0) or 0)
    deaths = int(h.get("times_knocked_out", 0) or 0)
    hours = int(c.get("playtime", 0) or 0) // 3600
    top = jobs[0] if jobs and jobs[0]["lvl"] > 1 else None
    cards = []
    cards.append({"k": "playtime", "label": "Hours adventured", "value": hours, "unit": "h",
                  "note": "That's real dedication." if hours >= 100 else "The journey's just begun."})
    cards.append({"k": "kills", "label": "Foes vanquished", "value": kills, "unit": "",
                  "note": f"~{round(kills / hours):,}/hr" if hours else ""})
    if top:
        cards.append({"k": "job", "label": "Signature job", "value": top["job"], "unit": "",
                      "note": f"Level {top['lvl']}" + (" — mastered" if top["lvl"] >= 99 else "")})
    cards.append({"k": "maxed", "label": "Jobs at 99", "value": len(maxed), "unit": "",
                  "note": ", ".join(maxed[:6]) + ("…" if len(maxed) > 6 else "") if maxed else "Keep climbing."})
    if pv.get("Custom_NM_Kills"):
        cards.append({"k": "nm", "label": "Notorious Monsters felled", "value": int(pv["Custom_NM_Kills"]), "unit": ""})
    if pv.get("HL_Tier"):
        cards.append({"k": "hl", "label": "Hunting League rank", "value": int(pv["HL_Tier"]), "unit": "/5"})
    if pv.get("Prestige_Ascensions_Total"):
        cards.append({"k": "asc", "label": "Ascensions", "value": int(pv["Prestige_Ascensions_Total"]), "unit": ""})
    kd = round(kills / deaths, 1) if deaths else None
    if kd is not None:
        cards.append({"k": "kd", "label": "Kill / KO ratio", "value": kd, "unit": ""})
    dist = int(h.get("distance_travelled", 0) or 0)
    if dist:
        cards.append({"k": "dist", "label": "Distance travelled", "value": round(dist / 1000), "unit": "k yalms"})
    ws = int(h.get("ws_used", 0) or 0)
    if ws:
        cards.append({"k": "ws", "label": "Weapon skills unleashed", "value": ws, "unit": ""})
    return {"name": c.get("charname", "?"), "mainJob": JOBS.get(st.get("mjob", 0), "?"),
            "mainLvl": st.get("mlvl", 1), "nation": NATIONS.get(c.get("nation", 0), "?"),
            "hours": hours, "kills": kills, "maxedJobs": len(maxed), "cards": cards}

@app.get("/api/wrapped/{charid}")
def wrapped(charid: int, request: Request):
    """The full seasonal recap for one character. Own-account only."""
    acct = require_account(request)
    conn = db()
    try:
        with conn.cursor() as cur:
            owned_char(cur, acct["id"], charid)
            data = _wrapped_for(cur, charid)
    finally:
        conn.close()
    data["charid"] = charid
    return data


# ---- achievement "moments": new-since-acknowledged --------------------------
@app.get("/api/achievements/{charid}")
def achievements(charid: int, request: Request):
    """Earned vs locked achievements, with per-item `isNew` (unlocked since last ack)."""
    acct = require_account(request)
    conn = db()
    try:
        with conn.cursor() as cur:
            owner = owned_char(cur, acct["id"], charid)
            cur.execute("SELECT varname, value FROM char_vars WHERE charid=%s AND varname LIKE 'ACH_%%'", (charid,))
            earned = {r["varname"] for r in cur.fetchall() if int(r["value"] or 0) != 0}
            seen = set()
            try:
                cur.execute("SELECT seen FROM portal_ach_seen WHERE charid=%s", (charid,))
                row = cur.fetchone()
                if row and row.get("seen"):
                    seen = set(row["seen"].split(","))
            except (pymysql.err.ProgrammingError, pymysql.err.OperationalError):
                pass
    finally:
        conn.close()
    # "new" = earned but not yet acknowledged. Only celebrate once the player has
    # an ack row (has visited before) so a first-ever visit isn't all confetti.
    has_ack = bool(seen)
    def is_new(var: str) -> bool:
        return has_ack and var not in seen

    out, got, fresh = [], 0, []
    for (i, n, d) in ACHIEVEMENTS:
        var = f"ACH_{i}"; e = var in earned
        if e: got += 1
        newf = e and is_new(var)
        if newf: fresh.append(i)
        out.append({"id": i, "name": n, "desc": d, "earned": e, "isNew": newf})
    for v in earned:
        if v not in _ACH_KNOWN:
            newf = is_new(v)
            if newf: fresh.append(v[4:])
            out.append({"id": v[4:], "name": prettify(v[4:]), "desc": "", "earned": True, "isNew": newf})
            got += 1
    return {"charid": charid, "name": owner["charname"], "earned": got,
            "total": len(ACHIEVEMENTS), "newCount": len(fresh), "achievements": out}


class SeenBody(BaseModel):
    charid: int

@app.post("/api/achievements/seen")
def achievements_seen(body: SeenBody, request: Request):
    """Acknowledge all currently-earned achievements (clears the 'new' badges)."""
    acct = require_account(request)
    conn = db_write()
    try:
        with conn.cursor() as cur:
            owned_char(cur, acct["id"], body.charid)
            cur.execute("SELECT varname FROM char_vars WHERE charid=%s AND varname LIKE 'ACH_%%' AND value<>0",
                        (body.charid,))
            csv = ",".join(sorted(r["varname"] for r in cur.fetchall()))
            cur.execute("INSERT INTO portal_ach_seen (charid, seen) VALUES (%s,%s) "
                        "ON DUPLICATE KEY UPDATE seen=VALUES(seen)", (body.charid, csv))
        conn.commit()
    except HTTPException:
        conn.rollback(); raise
    except Exception as e:
        conn.rollback(); print(f"[ach_seen] {type(e).__name__}: {e}", flush=True)
        raise HTTPException(status_code=500, detail="Could not save.")
    finally:
        conn.close()
    return {"ok": True}


# ---- web push subscriptions -------------------------------------------------
@app.get("/api/push/vapid")
def push_vapid():
    """The public VAPID key the browser needs to subscribe (empty if push off)."""
    return {"key": VAPID_PUBLIC, "enabled": bool(VAPID_PUBLIC and _HAS_WEBPUSH)}

class PushSubBody(BaseModel):
    endpoint: str
    p256dh: str = ""
    auth: str = ""

@app.post("/api/push/subscribe")
def push_subscribe(body: PushSubBody, request: Request):
    """Store this browser's push subscription against the logged-in account."""
    acct = require_account(request)
    if not body.endpoint:
        raise HTTPException(status_code=400, detail="endpoint required")
    conn = db_write()
    try:
        with conn.cursor() as cur:
            cur.execute("INSERT INTO portal_push_sub (accid, endpoint, p256dh, auth) "
                        "VALUES (%s,%s,%s,%s) ON DUPLICATE KEY UPDATE "
                        "accid=VALUES(accid), p256dh=VALUES(p256dh), auth=VALUES(auth)",
                        (acct["id"], body.endpoint, body.p256dh, body.auth))
        conn.commit()
    except Exception as e:
        conn.rollback(); print(f"[push_subscribe] {type(e).__name__}: {e}", flush=True)
        raise HTTPException(status_code=500, detail="Could not subscribe.")
    finally:
        conn.close()
    return {"ok": True}


# ---- sampler: diff live char state -> activity feed + notifications ---------
def _push_to_account(cur, accid: int, title: str, body: str, url: str = "/"):
    try:
        cur.execute("SELECT endpoint, p256dh, auth FROM portal_push_sub WHERE accid=%s", (accid,))
        subs = cur.fetchall()
    except Exception:
        return
    for s in subs:
        if not _send_push(s, {"title": title, "body": body, "url": url}):
            try: cur.execute("DELETE FROM portal_push_sub WHERE endpoint=%s", (s["endpoint"],))
            except Exception: pass

@app.get("/api/internal/tick")
def internal_tick(request: Request, key: str = ""):
    """Cron-hit sampler: snapshot online chars, emit feed events + push. Secret-gated."""
    if not TICK_KEY or key != TICK_KEY:
        raise HTTPException(status_code=403, detail="bad key")
    now = int(time.time())
    emitted = 0
    conn = db_write()
    try:
        with conn.cursor() as cur:
            cur.execute("SELECT DISTINCT charid FROM accounts_sessions")
            ids = [r["charid"] for r in cur.fetchall()]
            for cid in ids:
                cur.execute("SELECT c.charname, c.accid, COALESCE(s.mlvl,1) AS mlvl "
                            "FROM chars c LEFT JOIN char_stats s ON s.charid=c.charid WHERE c.charid=%s", (cid,))
                base = cur.fetchone()
                if not base:
                    continue
                name = base["charname"]; accid = base["accid"]; mlvl = int(base["mlvl"] or 1)
                cur.execute("SELECT COALESCE(enemies_defeated,0) AS k FROM char_history WHERE charid=%s", (cid,))
                kills = int((cur.fetchone() or {}).get("k", 0) or 0)
                pv = load_progression(cur, [cid]).get(cid, {})
                hltier = int(pv.get("HL_Tier", 0)); asc = int(pv.get("Prestige_Ascensions_Total", 0))
                nmk = int(pv.get("Custom_NM_Kills", 0))
                cur.execute("SELECT * FROM char_jobs WHERE charid=%s", (cid,))
                jrow = cur.fetchone() or {}
                maxed = sum(1 for c in JOB_COLS if int(jrow.get(c, 0) or 0) >= 99)
                cur.execute("SELECT varname FROM char_vars WHERE charid=%s AND varname LIKE 'ACH_%%' AND value<>0", (cid,))
                ach = {r["varname"] for r in cur.fetchall()}
                ach_csv = ",".join(sorted(ach))

                cur.execute("SELECT mlvl,kills,hltier,ascensions,nmkills,maxedjobs,ach_csv "
                            "FROM portal_snapshot WHERE charid=%s", (cid,))
                prev = cur.fetchone()
                events = []   # (kind, detail, notable)
                if prev is not None:
                    if mlvl > int(prev["mlvl"]) and mlvl in (50, 60, 70, 75, 80, 90, 99):
                        events.append(("levelup", f"reached level {mlvl}", mlvl >= 90))
                    if hltier > int(prev["hltier"]):
                        events.append(("hltier", f"advanced to Hunting League rank {hltier}", True))
                    if asc > int(prev["ascensions"]):
                        events.append(("ascension", f"completed ascension #{asc}", asc % 10 == 0))
                    if maxed > int(prev["maxedjobs"]):
                        events.append(("maxjob", f"mastered a job ({maxed} at 99)", True))
                    for tgt in (100, 500, 1000, 5000, 10000):
                        if nmk >= tgt > int(prev["nmkills"]):
                            events.append(("nmkill", f"passed {tgt:,} NM kills", tgt >= 1000))
                    newach = ach - set((prev["ach_csv"] or "").split(","))
                    for a in newach:
                        pretty = next((n for (i, n, d) in ACHIEVEMENTS if f"ACH_{i}" == a), prettify(a[4:]))
                        events.append(("achievement", f"earned “{pretty}”", True))
                for kind, detail, notable in events:
                    cur.execute("INSERT INTO portal_activity (ts, charid, charname, kind, detail) "
                                "VALUES (%s,%s,%s,%s,%s)", (now, cid, name, kind, detail))
                    emitted += 1
                    if notable:
                        _push_to_account(cur, accid, "Legendary FFXI", f"{name} {detail}", "/")
                        _discord_relay(f"🎉 **{name}** {detail}")

                cur.execute(
                    "INSERT INTO portal_snapshot (charid,mlvl,kills,hltier,ascensions,nmkills,maxedjobs,ach_csv) "
                    "VALUES (%s,%s,%s,%s,%s,%s,%s,%s) ON DUPLICATE KEY UPDATE "
                    "mlvl=VALUES(mlvl),kills=VALUES(kills),hltier=VALUES(hltier),ascensions=VALUES(ascensions),"
                    "nmkills=VALUES(nmkills),maxedjobs=VALUES(maxedjobs),ach_csv=VALUES(ach_csv)",
                    (cid, mlvl, kills, hltier, asc, nmk, maxed, ach_csv))
            # prune feed older than 14 days
            cur.execute("DELETE FROM portal_activity WHERE ts < %s", (now - 14 * 86400,))
        conn.commit()
    except Exception as e:
        conn.rollback(); print(f"[tick] {type(e).__name__}: {e}", flush=True)
        raise HTTPException(status_code=500, detail="tick failed")
    finally:
        conn.close()
    return {"ok": True, "sampled": len(ids), "emitted": emitted}


# ---- share cards (OpenGraph + inline SVG) -----------------------------------
def _profile_min(name: str) -> "dict | None":
    """Small public summary used to build share-card text/SVG. None if no char."""
    conn = db()
    try:
        with conn.cursor() as cur:
            cur.execute("SELECT c.charid, c.charname, c.nation, COALESCE(s.mjob,0) AS mjob, "
                        "COALESCE(s.mlvl,1) AS mlvl, COALESCE(h.enemies_defeated,0) AS kills "
                        "FROM chars c LEFT JOIN char_stats s ON s.charid=c.charid "
                        "LEFT JOIN char_history h ON h.charid=c.charid WHERE c.charname=%s", (name,))
            c = cur.fetchone()
            if not c:
                return None
            cid = c["charid"]
            cur.execute("SELECT * FROM char_jobs WHERE charid=%s", (cid,))
            jrow = cur.fetchone() or {}
            maxed = sum(1 for col in JOB_COLS if int(jrow.get(col, 0) or 0) >= 99)
            pv = load_progression(cur, [cid]).get(cid, {})
            cur.execute("SELECT title, accent FROM portal_profile WHERE charid=%s", (cid,))
            prof = cur.fetchone() or {}
    finally:
        conn.close()
    accent = prof.get("accent") if prof.get("accent") in ACCENTS else DEFAULT_ACCENT
    return {"name": c["charname"], "job": JOBS.get(c["mjob"], "?"), "lvl": c["mlvl"],
            "nation": NATIONS.get(c["nation"], "?"), "kills": int(c["kills"]),
            "maxed": maxed, "hl": int(pv.get("HL_Tier", 0)), "nm": int(pv.get("Custom_NM_Kills", 0)),
            "title": sanitize_title(prof.get("title")), "accentHex": ACCENTS[accent]}

def _card_svg(p: dict) -> str:
    ac = p["accentHex"]
    stats = [("Lv", str(p["lvl"])), ("Jobs @99", str(p["maxed"])),
             ("NM Kills", f"{p['nm']:,}" if p["nm"] else f"{p['kills']:,}"),
             ("HL Rank", str(p["hl"]) if p["hl"] else "—")]
    cells = ""
    for i, (k, v) in enumerate(stats):
        x = 60 + i * 278
        cells += (f'<text x="{x}" y="480" fill="{ac}" font-size="62" font-weight="700" '
                  f'font-family="Georgia,serif">{html.escape(v)}</text>'
                  f'<text x="{x}" y="520" fill="#9aa4b2" font-size="24" '
                  f'font-family="Segoe UI,sans-serif" letter-spacing="2">{html.escape(k.upper())}</text>')
    title = html.escape(p["title"] or f"{p['job']} {p['lvl']} · {p['nation']}")
    return f'''<svg xmlns="http://www.w3.org/2000/svg" width="1200" height="630" viewBox="0 0 1200 630">
  <defs><linearGradient id="bg" x1="0" y1="0" x2="0" y2="1">
    <stop offset="0" stop-color="#1b212c"/><stop offset="1" stop-color="#12151b"/></linearGradient></defs>
  <rect width="1200" height="630" fill="url(#bg)"/>
  <rect x="0" y="0" width="1200" height="8" fill="{ac}"/>
  <text x="60" y="130" fill="{ac}" font-size="34" font-family="Georgia,serif">★ LEGENDARY FFXI</text>
  <text x="60" y="270" fill="#e6edf3" font-size="120" font-weight="700" font-family="Georgia,serif">{html.escape(p["name"])}</text>
  <text x="60" y="330" fill="#9aa4b2" font-size="40" font-family="Segoe UI,sans-serif">{title}</text>
  <line x1="60" y1="380" x2="1140" y2="380" stroke="#2b323d" stroke-width="2"/>
  {cells}
  <text x="1140" y="600" text-anchor="end" fill="#6b7480" font-size="24" font-family="Segoe UI,sans-serif">portal.ffxi-legendary.com</text>
</svg>'''

@app.get("/api/card/{name}.svg")
def card_svg(name: str):
    p = _profile_min(name)
    if not p:
        raise HTTPException(status_code=404, detail="No such character.")
    return Response(_card_svg(p), media_type="image/svg+xml",
                    headers={"Cache-Control": "public, max-age=300"})


def _og_html(name: str) -> str:
    """profile.html with per-character OpenGraph meta injected into <head>."""
    path = os.path.join(_static_dir, "profile.html")
    with open(path, encoding="utf-8") as f:
        doc = f.read()
    p = _profile_min(name)
    if p:
        desc_bits = [f"{p['job']} {p['lvl']}", f"{p['maxed']} jobs at 99"]
        if p["nm"]:  desc_bits.append(f"{p['nm']:,} NM kills")
        elif p["kills"]: desc_bits.append(f"{p['kills']:,} kills")
        if p["hl"]:  desc_bits.append(f"Hunting League rank {p['hl']}")
        desc = " · ".join(desc_bits)
        titletag = f"★ {p['name']}" + (f" — {p['title']}" if p["title"] else "")
        img = f"{PUBLIC_URL}/api/card/{urllib.parse.quote(name)}.svg"
        url = f"{PUBLIC_URL}/c/{urllib.parse.quote(name)}"
        og = (f'<meta property="og:title" content="{html.escape(titletag)}">'
              f'<meta property="og:description" content="{html.escape(desc)}">'
              f'<meta property="og:type" content="profile">'
              f'<meta property="og:url" content="{html.escape(url)}">'
              f'<meta property="og:image" content="{html.escape(img)}">'
              f'<meta name="twitter:card" content="summary_large_image">'
              f'<meta name="twitter:title" content="{html.escape(titletag)}">'
              f'<meta name="twitter:description" content="{html.escape(desc)}">'
              f'<meta name="twitter:image" content="{html.escape(img)}">'
              f'<meta name="theme-color" content="#12151b">')
        doc = doc.replace("</head>", og + "</head>", 1)
    return doc


# ------------------------------------------------------------- page routes ----
_static_dir = os.path.join(os.path.dirname(__file__), "static")


@app.get("/sw.js")
def service_worker():
    # The service worker MUST NOT be edge/browser-cached, or SW updates never
    # reach clients (Cloudflare was pinning an old /sw.js -> stale app shell).
    return FileResponse(
        os.path.join(_static_dir, "sw.js"), media_type="application/javascript",
        headers={"Cache-Control": "no-cache, no-store, must-revalidate"})


@app.get("/legacy-reward")
def legacy_reward_page():
    return FileResponse(os.path.join(_static_dir, "legacy-reward.html"))


@app.get("/c/{name}")
def profile_page(name: str):
    # Public trophy page. Inject per-character OpenGraph meta so pasted links
    # unfurl richly on Discord/social; JS still reads the name from the URL path.
    try:
        return HTMLResponse(_og_html(name))
    except Exception:
        return FileResponse(os.path.join(_static_dir, "profile.html"))


@app.get("/card/{name}")
def card_page(name: str):
    # A dedicated, screenshot-ready share card (also carries the OG meta).
    try:
        return HTMLResponse(_og_html(name))
    except Exception:
        return FileResponse(os.path.join(_static_dir, "profile.html"))


# Serve the login page + assets. Registered LAST so the /api/* + /c routes win.
app.mount("/", StaticFiles(directory=_static_dir, html=True), name="static")
