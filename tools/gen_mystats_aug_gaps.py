"""Regenerate the GAP_AUG table for modules/custom/commands/mystats.lua.

GAP_AUG lists every obtainable-augment stat that no other !mystats section
already shows, so a player can confirm EVERY augment they can get. This tool
derives it from the RELAUNCH sources (ported from Legendary's version, which
read a JSON catalog export this repo doesn't have):

  * modules/custom/lua/augment_catalog.lua   -> the obtainable augIds
  * sql/augments.sql + modules/custom/sql/*  -> augId -> (modId, isPet) rows
  * modules/custom/commands/mystats.lua      -> the SHOWN set, extracted from
    the source itself (xi.mod.NAME names resolved via scripts/enum/mod.lua,
    plus numeric getMod(NN) reads), with the GAP_AUG block stripped first so
    the table never excludes itself.

Run from the repo root:  python tools/gen_mystats_aug_gaps.py
Paste the emitted rows over the GAP_AUG body in mystats.lua. Rerun whenever
the augment catalog gains new mods.
"""
import collections
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]

# Concise labels (Legendary's curated map, kept verbatim; unlabeled gap mods
# are emitted as a review comment instead of table rows).
LBL = {173:'Martial Arts',306:'Zanshin',911:'Daken',292:'Kick Atk',138:'Barrage',359:'Rapid Shot',
 880:'Save TP',944:'Conserve TP',836:'Rev.Flourish',166:'EnemyCrit-',287:'MeleeDmg+',376:'RangedDmg+',
 48:'WS Acc',706:'BladeKu Dmg', 485:'ShieldMastery',518:'BlockRate',963:'ParryRate',1182:'PhalanxRcvd',296:'ConserveMP',
 487:'MBurst Dmg',311:'Magic Dmg',315:'Drain/Aspir',902:'OccultAcumen',909:'OccQuickCast',94:'MeditateDur',
 477:'HelixDur',890:'EnhMagDur',960:'IndiDur',519:'CureCast-',455:'SongCast-',452:'AllSongs+',
 240:'Res.Sleep',241:'Res.Poison',242:'Res.Paralyze',243:'Res.Blind',244:'Res.Silence',245:'Res.Virus',
 246:'Res.Petrify',247:'Res.Bind',248:'Res.Curse',249:'Res.Gravity',250:'Res.Slow',251:'Res.Stun',252:'Res.Charm',958:'Occ.ResStatus',
 71:'MPrecov.heal',72:'HPrecov.heal',989:'RegenPot',854:'RepairPot',897:'Gilfinder',391:'Charm+',308:'NinjaTool',
 273:'CallBeast-',357:'BloodPact-',1052:'Sic/Ready-',1060:'QuickDraw-',1076:'PhRoll-',497:'Waltz-',833:'SongRecast-',
 139:'WaltzTP-',491:'WaltzPot',365:'Snapshot',305:'Recycle',1146:'ElemRecast-',1183:'CureRecast-',1184:'EnfbRecast-',
 1185:'EnhaRecast-',171:'MeleeDelay-',172:'RngDelay-',380:'MeleeDelay2-',
 80:'H2H skl',81:'Dagger skl',82:'Sword skl',83:'GSword skl',84:'Axe skl',85:'GAxe skl',86:'Scythe skl',
 87:'Polearm skl',88:'Katana skl',89:'GKatana skl',90:'Club skl',91:'Staff skl',104:'Archery skl',105:'Marks skl',
 106:'Throw skl',107:'Guarding skl',109:'Shield skl',110:'Parry skl',111:'Divine skl',112:'Heal skl',113:'Enha skl',114:'Enfb skl',
 115:'Elem skl',116:'Dark skl',117:'Summon skl',118:'Ninjutsu skl',119:'Sing skl',120:'String skl',121:'Wind skl',
 122:'Blue skl',123:'Geo skl',124:'Handbell skl', 126:'AvatarBP Dmg',346:'AvatarPerp-',540:'ElemSiphon',913:'BloodBoon',
 101:'AutoMelee skl',102:'AutoRanged skl',103:'AutoMagic skl',
 881:'PhRoll Pot',1073:'DarkSeal+',1137:'Absorb Pot',1197:'Immunobreak',1200:'BeastAffinity',1626:'ElemDebuffPot'}


def obtainable_aug_ids() -> set[int]:
    text = (ROOT / "modules/custom/lua/augment_catalog.lua").read_text(
        encoding="utf-8", errors="replace")
    return {int(m) for m in re.findall(r"augId\s*=\s*(\d+)", text)}


def aug_mods() -> dict[int, set[tuple[int, int]]]:
    out: collections.defaultdict = collections.defaultdict(set)
    srcs = [ROOT / "sql/augments.sql"] + sorted((ROOT / "modules/custom/sql").glob("*.sql"))
    for src in srcs:
        for ln in src.read_text(encoding="utf-8", errors="replace").splitlines():
            m = re.match(r"INSERT INTO `augments` VALUES \((\d+),(-?\d+),(-?\d+),(-?\d+),(\d+),(\d+)\)", ln)
            if m:
                aid, _mult, mod, _val, is_pet, _pt = map(int, m.groups())
                if mod != 0:
                    out[aid].add((mod, is_pet))
    return out


def shown_mods() -> set[int]:
    """Every mod !mystats already displays, read from the command source."""
    text = (ROOT / "modules/custom/commands/mystats.lua").read_text(
        encoding="utf-8", errors="replace")
    # Strip the GAP_AUG table so it never excludes its own entries.
    text = re.sub(r"local GAP_AUG\s*=\s*\{.*?\n\}", "", text, flags=re.DOTALL)

    mod_ids = {name: int(mid) for name, mid in re.findall(
        r"^\s*([A-Z][A-Z0-9_]*)\s*=\s*(\d+)", (ROOT / "scripts/enum/mod.lua")
        .read_text(encoding="utf-8", errors="replace"), flags=re.MULTILINE)}

    shown: set[int] = set()
    for name in re.findall(r"xi\.mod\.([A-Z][A-Z0-9_]*)", text):
        if name in mod_ids:
            shown.add(mod_ids[name])
    # vcap(player, 'NAME') reads xi.mod[NAME] dynamically -- catch those too.
    for name in re.findall(r"vcap\(player,\s*'([A-Z0-9_]+)'\)", text):
        if name in mod_ids:
            shown.add(mod_ids[name])
    for nn in re.findall(r"get(?:Mod|Stat)\((\d+)\)", text):
        shown.add(int(nn))
    # Flat HP/MP (mods 2/5) are visible as the header's max HP/MP totals.
    shown |= {2, 5}
    return shown


def main() -> None:
    meta = obtainable_aug_ids()
    mods = aug_mods()
    shown = shown_mods()

    gaps: dict[int, str | None] = {}
    for aid in meta:
        for mod, is_pet in mods.get(aid, set()):
            if is_pet or mod in shown:
                continue
            gaps.setdefault(mod, LBL.get(mod))

    labeled = [m for m in sorted(gaps) if gaps[m]]
    print(f"-- {len(labeled)} labeled gap mods (of {len(gaps)} total; "
          f"{len(shown)} already shown elsewhere)")
    for mod in labeled:
        print(f"    {{ {mod}, '{gaps[mod]}' }},")
    unlabeled = sorted(m for m in gaps if not gaps[m])
    if unlabeled:
        print("-- UNLABELED (niche, review):", unlabeled)


if __name__ == "__main__":
    main()
