"""dpscalc command-line entry.  Run from the repo root:

    python -m tools.dpscalc gear <charid|charname>
        Dump the char's equipped gear + per-slot mods + set totals.

    python -m tools.dpscalc mods
        Sanity check: parse scripts/enum/mod.lua and print key mod ids.

    python -m tools.dpscalc targets
        List the Hunting League NM targets (DEF / EVA / points / level band).

    python -m tools.dpscalc ws <charid|charname>
        List the weaponskills usable with the char's equipped weapon + job
        (the names you can pass to --ws).

    python -m tools.dpscalc eval <char> <mystats.txt> [--target NM] [--ws NAME] [--tp N]
        Estimate auto-attack DPS and weaponskill damage for the char's CURRENTLY
        equipped set against an NM. <mystats.txt> is a pasted `!mystats` dump,
        captured UNBUFFED and WITHOUT FOOD in that same equipped set.

    python -m tools.dpscalc optimize <char> <mystats.txt> [--target NM]
            [--slot SLOT] [--metric auto|ws|rotation] [--ws NAME] [--tp N]
            [--top N] [--csv out.csv]
        For each armor/accessory slot, rank the items the char owns by the gain
        they give over the equipped piece, then assemble a greedy best set.

    python -m tools.dpscalc whatif <char> <mystats.txt> [--target NM]
            [--ws NAME] [--tp N] [--out FILE.xlsx]
        Generate an Excel what-if workbook: a live Sensitivity sheet (value of
        +1 of each mod, type amounts to estimate a hypothetical package) and a
        Scenarios sheet to fill with hypothetical items/augments.

    python -m tools.dpscalc score <char> <mystats.txt> <FILE.xlsx>
            [--target NM] [--ws NAME] [--tp N]
        Run every filled row of the workbook's Scenarios sheet through the real
        engine and write back exact Auto/WS/Rotation numbers + deltas.

    python -m tools.dpscalc buildbook <char> <mystats.txt> [--out FILE.xlsx]
        Generate a fully self-contained Excel optimizer: every damage formula is
        baked into cell formulas and every curated endgame item + augment ships
        as a per-slot dropdown. Pick gear/augments/target/WS and the Auto/WS/
        Rotation numbers recompute live with no Python in the loop.

The weapon (main+sub) is fixed across candidates: a weapon swap needs a fresh
`!mystats` anchor with that weapon equipped.
"""
from __future__ import annotations

import csv
import sys

from . import anchor as anchormod
from . import buildbook, db, engine, gear, state, targets, whatif, wsdata
from .mods import mname, name_to_id

# Armor + accessory slots the optimizer is allowed to swap (weapon/ranged fixed).
ARMOR_SLOTS = {4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15}


# ---------------------------------------------------------------------------
# small arg helpers
# ---------------------------------------------------------------------------
def _pop_opt(args: list[str], name: str, default: str | None = None) -> str | None:
    """Pull `--name value` out of args (mutating it); return value or default."""
    if name in args:
        i = args.index(name)
        if i + 1 >= len(args):
            sys.exit(f"{name} needs a value")
        val = args[i + 1]
        del args[i:i + 2]
        return val
    return default


def _resolve_char(conn, who: str) -> tuple[int, str]:
    cur = conn.cursor()
    if who.isdigit():
        cur.execute("SELECT charid, charname FROM chars WHERE charid=%s", (int(who),))
    else:
        cur.execute("SELECT charid, charname FROM chars WHERE charname=%s", (who,))
    row = cur.fetchone()
    if not row:
        sys.exit(f"No character matching {who!r}")
    return row["charid"], row["charname"]


def _char_jobs(conn, charid: int) -> dict:
    cur = conn.cursor()
    cur.execute("SELECT mjob, sjob, mlvl, slvl FROM char_stats WHERE charid=%s",
                (charid,))
    return cur.fetchone() or {}


def _ws_label(name: str) -> str:
    return name.replace("_", " ").title()


def _pick_target(name: str | None):
    if name:
        t = targets.find_target(name)
        if not t:
            sys.exit(f"No NM matching {name!r}; run `targets` to list them.")
        return t
    tlist = targets.load_targets()
    if not tlist:
        sys.exit("No NM targets parsed from the Hunting League catalog.")
    return tlist[0]


# ---------------------------------------------------------------------------
# gear / mods (unchanged)
# ---------------------------------------------------------------------------
def cmd_gear(args: list[str]) -> None:
    if not args:
        sys.exit("usage: gear <charid|charname>")
    conn = db.connect()
    charid, charname = _resolve_char(conn, args[0])
    cs = _char_jobs(conn, charid)
    print(f"== {charname} (charid {charid})  job {cs.get('mjob')}/{cs.get('sjob')}"
          f"  lvl {cs.get('mlvl')}/{cs.get('slvl')} ==\n")

    slots = gear.equipped_items(conn, charid)
    if not slots:
        print("  (nothing equipped)")
        return

    for slot_id in sorted(slots):
        slot = slots[slot_id]
        info = gear.item_info(conn, slot.item_id)
        slot_name = gear.SLOT_NAMES.get(slot_id, f"slot{slot_id}")
        nm = info.name if info else f"item#{slot.item_id}"
        extra_bits = ""
        if info and info.is_weapon:
            extra_bits = f"  [{gear.WEAPON_SKILL.get(info.skill, info.skill)} DMG{info.dmg}/Dly{info.delay}" \
                         + (f"/hit{info.hit}" if info.hit else "") + "]"
        print(f"{slot_name:>6}: {nm}{extra_bits}")

        augs = gear.decode_augments(slot.extra)
        if augs:
            print("        augments(raw): " + ", ".join(f"id{a}:v{v}" for a, v in augs))
        mods = gear.item_total_mods(conn, slot.item_id, slot.extra)
        if mods:
            shown = ", ".join(f"{mname(m)}{'+' if v >= 0 else ''}{v}"
                              for m, v in sorted(mods.items()))
            print(f"        mods: {shown}")
    print()

    total = gear.gear_set_mods(conn, slots)
    print("== TOTAL gear mods (base + augments) ==")
    for m, v in sorted(total.items()):
        print(f"  {mname(m):<28} {'+' if v >= 0 else ''}{v}")


def cmd_mods(_args: list[str]) -> None:
    n = name_to_id()
    print(f"Parsed {len(n)} modifiers from scripts/enum/mod.lua")
    for k in ("STR", "ATT", "ACC", "STORETP", "DOUBLE_ATTACK", "TRIPLE_ATTACK",
              "QUAD_ATTACK", "CRITHITRATE", "CRIT_DMG_INCREASE", "ALL_WSDMG_ALL_HITS",
              "HASTE_GEAR", "DUAL_WIELD", "MAIN_DMG_RATING", "DMG_RATING"):
        print(f"  {k:<22} = {n.get(k)}")


# ---------------------------------------------------------------------------
# targets
# ---------------------------------------------------------------------------
def cmd_targets(_args: list[str]) -> None:
    tlist = targets.load_targets()
    if not tlist:
        sys.exit("No NM targets parsed from the Hunting League catalog.")
    print(f"== Hunting League NM targets ({len(tlist)}) ==")
    cur_tier = None
    for t in sorted(tlist, key=lambda x: (x.tier, x.points, x.label)):
        if t.tier != cur_tier:
            cur_tier = t.tier
            print(f"\n-- Tier {t.tier}: {t.tier_name} --")
        print(f"  {t.label:<30} DEF {t.defense():>4}  EVA {t.evasion():>4}  "
              f"pts {t.points:>4}  lv {t.min_lv}-{t.max_lv}")


# ---------------------------------------------------------------------------
# ws (list weaponskills usable with the char's equipped weapon + job)
# ---------------------------------------------------------------------------
def cmd_ws(args: list[str]) -> None:
    if not args:
        sys.exit("usage: ws <charid|charname>")
    conn = db.connect()
    charid, charname = _resolve_char(conn, args[0])
    jobs = _char_jobs(conn, charid)
    slots = gear.equipped_items(conn, charid)
    if gear.SLOT_IDS["main"] not in slots:
        sys.exit("Char has no main weapon equipped.")
    wctx = state.resolve_weapon_ctx(conn, charid, slots)
    wcat = gear.WEAPON_SKILL.get(wctx.main_skill, wctx.main_skill)
    ws_list = wsdata.ws_for_weapon(conn, wctx.main_skill,
                                   jobs.get("mjob"), jobs.get("sjob"))
    print(f"== Weaponskills for {charname}  "
          f"({wcat}, job {jobs.get('mjob')}/{jobs.get('sjob')}) ==")
    if not ws_list:
        print("  (none usable for this weapon/job)")
        return
    for ws in sorted(ws_list, key=lambda w: w.name):
        wsc = ", ".join(f"{int(v * 100)}% {k}"
                        for k, v in sorted(ws.wsc.items(), key=lambda kv: -kv[1]))
        print(f"  {_ws_label(ws.name):<24} {ws.num_hits} hit(s)   "
              f"WSC: {wsc or '-'}")
    print('\n  Pass any of these to --ws (e.g. --ws "Savage Blade").')


# ---------------------------------------------------------------------------
# shared setup for eval / optimize
# ---------------------------------------------------------------------------
def _setup(conn, who: str, anchor_path: str):
    charid, charname = _resolve_char(conn, who)
    jobs = _char_jobs(conn, charid)
    slots = gear.equipped_items(conn, charid)
    if gear.SLOT_IDS["main"] not in slots:
        sys.exit("Char has no main weapon equipped; cannot build a melee anchor.")
    wctx = state.resolve_weapon_ctx(conn, charid, slots)
    equipped_mods = gear.gear_set_mods(conn, slots)
    a = anchormod.parse_anchor_file(anchor_path)
    warns = anchormod.anchor_is_complete(a)
    if warns:
        print("!! anchor warnings: " + "; ".join(warns), file=sys.stderr)
    return charid, charname, jobs, slots, wctx, equipped_mods, a


def _resolve_ws_list(conn, wctx, jobs, ws_name: str | None):
    if ws_name:
        ws = wsdata.get_ws(conn, ws_name)
        if not ws:
            sys.exit(f"No weaponskill matching {ws_name!r}.")
        return [ws]
    return wsdata.ws_for_weapon(conn, wctx.main_skill,
                                jobs.get("mjob"), jobs.get("sjob"))


# ---------------------------------------------------------------------------
# eval
# ---------------------------------------------------------------------------
def cmd_eval(args: list[str]) -> None:
    target_name = _pop_opt(args, "--target")
    ws_name = _pop_opt(args, "--ws")
    tp_s = _pop_opt(args, "--tp")
    if len(args) < 2:
        sys.exit("usage: eval <char> <mystats.txt> [--target NM] [--ws NAME] [--tp N]")

    conn = db.connect()
    charid, charname, jobs, slots, wctx, equipped_mods, a = _setup(conn, args[0], args[1])
    tgt = _pick_target(target_name)

    cs = state.build_combat_stats(a, equipped_mods, equipped_mods, wctx)  # self-test

    wcat = gear.WEAPON_SKILL.get(wctx.main_skill, wctx.main_skill)
    print(f"== {charname}  {a.main_job}{a.main_lvl}/{a.sub_job}{a.sub_lvl}  [{wcat}] "
          f"vs {tgt.label} (T{tgt.tier}) ==")
    print(f"   self-test: ATT {cs.att} (anchor {a.att}), ACC {cs.acc} (anchor {a.acc})"
          + ("  OK" if cs.att == a.att and cs.acc == a.acc else "  <-- MISMATCH"))
    print(f"   target: DEF {tgt.defense()}  EVA {tgt.evasion()}  "
          f"VIT {tgt.vit()}  AGI {tgt.agi()}\n")

    auto = engine.auto_attack_dps(cs, tgt)
    print("-- Auto-attack --")
    print(f"   DPS {auto.dps:8.1f}   round {auto.interval_ms:6.0f} ms   "
          f"crit {auto.crit_rate*100:4.1f}%")
    print(f"   main: {auto.main_hits_per_round:.2f} hits/round x "
          f"{auto.main_hit_rate*100:.0f}% acc x {auto.main_hit_dmg:6.1f} dmg")
    if wctx.has_offhand:
        print(f"   off : {auto.off_hits_per_round:.2f} hits/round x "
              f"{auto.off_hit_rate*100:.0f}% acc x {auto.off_hit_dmg:6.1f} dmg")
    print(f"   dmg/round {auto.dmg_per_round:7.1f}   TP/round {auto.tp_per_round:5.1f}\n")

    ws_list = _resolve_ws_list(conn, wctx, jobs, ws_name)
    if not ws_list:
        print("-- Weaponskills: none usable for this weapon/job --")
        return
    tps = [int(tp_s)] if tp_s else [1000, 2000, 3000]
    print(f"-- Weaponskills (TP {', '.join(map(str, tps))}) --")
    rows = []
    for ws in ws_list:
        dmgs = [engine.ws_damage(cs, tgt, ws, tp).damage for tp in tps]
        rows.append((_ws_label(ws.name), ws.num_hits, dmgs))
    rows.sort(key=lambda r: r[2][-1], reverse=True)
    head = "   " + f"{'weaponskill':<22}{'hits':>5}  " + "".join(f"{f'TP{t}':>10}" for t in tps)
    print(head)
    for label, nhits, dmgs in rows:
        print("   " + f"{label:<22}{nhits:>5}  " + "".join(f"{d:>10.0f}" for d in dmgs))


# ---------------------------------------------------------------------------
# optimize
# ---------------------------------------------------------------------------
def _metric_fn(metric: str, tgt, ws, tp: int):
    """Return a function CombatStats -> float for the chosen ranking metric."""
    if metric == "auto":
        return lambda cs: engine.auto_attack_dps(cs, tgt).dps
    if metric == "ws":
        if ws is None:
            sys.exit("--metric ws needs --ws NAME")
        return lambda cs: engine.ws_damage(cs, tgt, ws, tp).damage
    if metric == "rotation":
        if ws is None:
            sys.exit("--metric rotation needs --ws NAME")
        return lambda cs: engine.rotation_dps(cs, tgt, ws, tp).total_dps
    sys.exit(f"unknown metric {metric!r}; choose auto|ws|rotation")


def cmd_optimize(args: list[str]) -> None:
    target_name = _pop_opt(args, "--target")
    ws_name = _pop_opt(args, "--ws")
    metric = _pop_opt(args, "--metric", "auto")
    tp = int(_pop_opt(args, "--tp", "1000"))
    top = int(_pop_opt(args, "--top", "5"))
    csv_path = _pop_opt(args, "--csv")
    slot_filter = _pop_opt(args, "--slot")
    if len(args) < 2:
        sys.exit("usage: optimize <char> <mystats.txt> [--target NM] "
                 "[--slot SLOT] [--metric auto|ws|rotation] [--ws NAME] "
                 "[--tp N] [--top N] [--csv out.csv]")

    conn = db.connect()
    charid, charname, jobs, slots, wctx, equipped_mods, a = _setup(conn, args[0], args[1])
    tgt = _pick_target(target_name)

    ws = wsdata.get_ws(conn, ws_name) if ws_name else None
    if ws_name and not ws:
        sys.exit(f"No weaponskill matching {ws_name!r}.")
    score = _metric_fn(metric, tgt, ws, tp)

    base_cs = state.build_combat_stats(a, equipped_mods, equipped_mods, wctx)
    base_score = score(base_cs)

    want_slots = ARMOR_SLOTS
    if slot_filter:
        sid = gear.SLOT_IDS.get(slot_filter.lower())
        if sid is None:
            sys.exit(f"unknown slot {slot_filter!r}; "
                     f"choose from {', '.join(s for s in gear.SLOT_IDS if gear.SLOT_IDS[s] in ARMOR_SLOTS)}")
        want_slots = {sid}

    candidates = gear.inventory_candidates(conn, charid, jobs.get("mjob"), want_slots)

    label = {"auto": "auto DPS", "ws": f"{_ws_label(ws.name)} dmg" if ws else "WS",
             "rotation": f"rotation DPS (+{_ws_label(ws.name)})" if ws else "rotation"}[metric]
    print(f"== optimize {charname}  metric={label}  vs {tgt.label} (T{tgt.tier}) ==")
    print(f"   equipped baseline: {base_score:.1f}\n")

    all_rows = []          # for CSV
    best_per_slot = {}     # slot_id -> (score, EquippedSlot, name)
    for slot_id in sorted(want_slots):
        cand_list = candidates.get(slot_id, [])
        if not cand_list:
            continue
        equipped_here = slots.get(slot_id)
        equipped_id = equipped_here.item_id if equipped_here else None
        scored = []
        for c in cand_list:
            trial = dict(slots)
            trial[slot_id] = c
            cand_mods = gear.gear_set_mods(conn, trial)
            cs = state.build_combat_stats(a, equipped_mods, cand_mods, wctx)
            s = score(cs)
            info = gear.item_info(conn, c.item_id)
            nm = info.name if info else f"item#{c.item_id}"
            if gear.decode_augments(c.extra):
                nm += " (aug)"
            scored.append((s, c, nm, c.item_id == equipped_id))
            all_rows.append((gear.SLOT_NAMES[slot_id], nm, c.item_id,
                             round(s, 2), round(s - base_score, 2)))
        scored.sort(key=lambda r: r[0], reverse=True)
        best_per_slot[slot_id] = scored[0][:3]

        sname = gear.SLOT_NAMES[slot_id]
        print(f"-- {sname} --")
        for s, c, nm, is_equipped in scored[:top]:
            tag = " (equipped)" if is_equipped else ""
            print(f"   {s:9.1f}  {s - base_score:+8.1f}  {nm}{tag}")
        print()

    # Greedy best set: take every slot's winner at once and re-evaluate exactly.
    if not slot_filter and best_per_slot:
        best_slots = dict(slots)
        for slot_id, (_s, c, _nm) in best_per_slot.items():
            best_slots[slot_id] = c
        best_mods = gear.gear_set_mods(conn, best_slots)
        best_cs = state.build_combat_stats(a, equipped_mods, best_mods, wctx)
        best_score = score(best_cs)
        print("== greedy best set ==")
        for slot_id in sorted(best_per_slot):
            _s, c, nm = best_per_slot[slot_id]
            cur_nm = ""
            cur = slots.get(slot_id)
            if cur:
                ci = gear.item_info(conn, cur.item_id)
                cur_nm = ci.name if ci else f"item#{cur.item_id}"
            change = "" if (cur and cur.item_id == c.item_id) else f"   (was: {cur_nm})"
            print(f"   {gear.SLOT_NAMES[slot_id]:>5}: {nm}{change}")
        print(f"\n   set {label}: {best_score:.1f}   "
              f"({best_score - base_score:+.1f} vs equipped, "
              f"{(best_score / base_score - 1) * 100:+.1f}%)")
        _warn_paired_dupes(best_per_slot)

    if csv_path:
        with open(csv_path, "w", newline="", encoding="utf-8") as fh:
            w = csv.writer(fh)
            w.writerow(["slot", "item", "item_id", metric, "delta_vs_equipped"])
            w.writerows(sorted(all_rows, key=lambda r: (r[0], -r[4])))
        print(f"\nwrote {len(all_rows)} rows to {csv_path}")


def _warn_paired_dupes(best_per_slot: dict) -> None:
    """Flag if the same item won both ring (or ear) slots -- only valid if the
    player actually owns two copies."""
    for a_name, b_name in (("ring1", "ring2"), ("ear1", "ear2")):
        ai, bi = gear.SLOT_IDS[a_name], gear.SLOT_IDS[b_name]
        if ai in best_per_slot and bi in best_per_slot:
            if best_per_slot[ai][1].item_id == best_per_slot[bi][1].item_id:
                print(f"   note: {best_per_slot[ai][2]} won both {a_name} & {b_name}; "
                      "verify you own two.")


# ---------------------------------------------------------------------------
# whatif (generate Excel workbook) / score (evaluate its Scenarios sheet)
# ---------------------------------------------------------------------------
def _whatif_ctx(conn, charname, jobs, wctx, a, equipped_mods,
                target_name, ws_name, tp):
    """Resolve the shared WhatIfCtx (target, WS, TP) for whatif/score."""
    tgt = _pick_target(target_name)
    base_cs = state.build_combat_stats(a, equipped_mods, equipped_mods, wctx)
    if ws_name:
        ws = wsdata.get_ws(conn, ws_name)
        if not ws:
            sys.exit(f"No weaponskill matching {ws_name!r}.")
    else:
        _all, ws = whatif.pick_default_ws(conn, base_cs, wctx, jobs, tgt, tp)
    return whatif.WhatIfCtx(charname=charname, target=tgt, ws=ws, tp=tp,
                            main_skill=wctx.main_skill)


def cmd_whatif(args: list[str]) -> None:
    target_name = _pop_opt(args, "--target")
    ws_name = _pop_opt(args, "--ws")
    tp = int(_pop_opt(args, "--tp", "1000"))
    out = _pop_opt(args, "--out")
    if len(args) < 2:
        sys.exit("usage: whatif <char> <mystats.txt> [--target NM] [--ws NAME] "
                 "[--tp N] [--out FILE.xlsx]")

    conn = db.connect()
    charid, charname, jobs, slots, wctx, equipped_mods, a = _setup(conn, args[0], args[1])
    ctx = _whatif_ctx(conn, charname, jobs, wctx, a, equipped_mods,
                      target_name, ws_name, tp)
    out = out or f"{charname}_whatif.xlsx"
    whatif.build_workbook(out, conn, charname, a, equipped_mods, slots,
                          wctx, jobs, ctx)
    wsname = whatif._label(ctx.ws.name) if ctx.ws else "(none)"
    print(f"Wrote {out}")
    print(f"  char {charname}  vs {ctx.target.label} (T{ctx.target.tier})  "
          f"WS column: {wsname} @ TP {ctx.tp}  (auto-picked -- see Weaponskills sheet)")
    print("  Sheets: How to use | Baseline | Weaponskills | Targets | "
          "Sensitivity (live) | Scenarios")
    print(f"  Fill the Scenarios sheet, then:  python -m tools.dpscalc score "
          f"{charname} {args[1]} {out}")


def cmd_score(args: list[str]) -> None:
    target_name = _pop_opt(args, "--target")
    ws_name = _pop_opt(args, "--ws")
    tp_s = _pop_opt(args, "--tp")
    if len(args) < 3:
        sys.exit("usage: score <char> <mystats.txt> <FILE.xlsx> "
                 "[--target NM] [--ws NAME] [--tp N]")

    conn = db.connect()
    charid, charname, jobs, slots, wctx, equipped_mods, a = _setup(conn, args[0], args[1])
    xlsx = args[2]

    # CLI flags win; otherwise reuse the context embedded when the file was made.
    saved = whatif.read_ctx(xlsx)
    target_name = target_name or (saved.get("target") if saved else None)
    ws_name = ws_name or (saved.get("ws") if saved else None)
    tp = int(tp_s) if tp_s else int(saved.get("tp", 1000) or 1000)
    ctx = _whatif_ctx(conn, charname, jobs, wctx, a, equipped_mods,
                      target_name, ws_name or None, tp)

    n = whatif.score_workbook(xlsx, conn, a, equipped_mods, slots, wctx, ctx)
    wsname = whatif._label(ctx.ws.name) if ctx.ws else "(none)"
    print(f"Scored {n} scenario(s) in {xlsx}")
    print(f"  vs {ctx.target.label} (T{ctx.target.tier})  "
          f"WS: {wsname} @ TP {ctx.tp}  -- open the Scenarios sheet for results.")


# ---------------------------------------------------------------------------
# buildbook (generate the fully self-contained Excel optimizer)
# ---------------------------------------------------------------------------
def cmd_buildbook(args: list[str]) -> None:
    out = _pop_opt(args, "--out")
    if len(args) < 2:
        sys.exit("usage: buildbook <char> <mystats.txt> [--out FILE.xlsx]")

    conn = db.connect()
    charid, charname = _resolve_char(conn, args[0])
    a = anchormod.parse_anchor_file(args[1])
    warns = anchormod.anchor_is_complete(a)
    if warns:
        print("!! anchor warnings: " + "; ".join(warns), file=sys.stderr)

    out = out or f"{charname}_optimizer.xlsx"
    stats = buildbook.build_book(conn, charid, a, out)

    eb = stats["engine_baseline"]
    print(f"Wrote {out}")
    print(f"  char {charname}  {a.main_job}{a.main_lvl}/{a.sub_job}{a.sub_lvl}")
    print(f"  curated: {stats['gear']} items, {stats['aug']} augments, "
          f"{stats['ws']} weaponskills, {stats['targets']} targets")
    print(f"  default target: {stats['default_target']}   "
          f"default WS: {stats['default_ws']}")
    print(f"  engine baseline (all 'keep equipped'):  auto {eb['auto']:.1f}   "
          f"WS {eb['ws']:.1f}   rotation {eb['rotation']:.1f}")
    print("  Open the Build sheet and start swapping gear/augments.")


# ---------------------------------------------------------------------------
def main() -> None:
    if len(sys.argv) < 2:
        print(__doc__)
        return
    cmd, rest = sys.argv[1], sys.argv[2:]
    handlers = {
        "gear": cmd_gear, "mods": cmd_mods, "targets": cmd_targets,
        "ws": cmd_ws, "eval": cmd_eval, "optimize": cmd_optimize,
        "whatif": cmd_whatif, "score": cmd_score, "buildbook": cmd_buildbook,
    }
    h = handlers.get(cmd)
    if not h:
        sys.exit(f"unknown command {cmd!r}; known: {', '.join(handlers)}")
    h(rest)


if __name__ == "__main__":
    main()
