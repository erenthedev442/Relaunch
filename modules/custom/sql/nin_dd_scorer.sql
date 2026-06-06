-- ============================================================================
-- NIN Lv99 Melee DD gear scorer  (v1 — adapted from rdm_dd_scorer)
--
-- Reads:
--   item_equipment   base equip metadata
--   item_mods        always-on stat bonuses
--   item_latents     conditional mods (engaged / TP / subjob / etc.)
--   item_weapon      DMG, delay, hit count, ilvl combat skill
--
-- Skipped on purpose:
--   augments         catalog of augment definitions, NOT which items have them.
--                    Real augments live per-character in inventory (exdata).
--   item_basic.flags affects obtainability (RARE/EX), not stats.
--
-- USAGE:  Paste a section into HeidiSQL / mysql / mariadb / DBeaver, edit the
--         @slot_bit value (or the weights), run.
-- ============================================================================
--
-- Constants
-- ----------------------------------------------------------------------------
-- NIN job bit:  1 << (13-1) = 4096
--
-- Slot bits in item_equipment.slot (bitfield):
--   Main=1     Sub=2     Ranged=4    Ammo=8
--   Head=16    Body=32   Hands=64    Legs=128
--   Feet=256   Neck=512  Waist=1024
--   Ear=2048|4096   (most earrings have both bits set)
--   Ring=8192|16384 (most rings have both bits set)
--   Back=32768
--
-- Mod IDs used (see scripts/enum/mod.lua for the full list):
--    8 STR       9 DEX      11 AGI     23 ATT       25 ACC
--   62 ATT%     73 STORE_TP  259 DUAL_WIELD
--  288 DOUBLE_ATTACK  302 TRIPLE_ATTACK
--  384 HASTE_GEAR (raw; 1024 ≈ full 25% cap; ~60 raw ≈ 1%)
--  289 SUBTLE_BLOW
--
-- Latent IDs treated as "DD-relevant always-on" (full weight):
--    7  TP_OVER (cheap to keep TP > threshold while fighting)
--   10  WEAPON_DRAWN (engaged)
--   41  DURING_WS (only swap-in pieces matter, but counts toward WS score)
-- Other latents (HP_UNDER, SUBJOB-specific, etc.) get HALF weight — they are
-- situational and won't be active 100% of the time.
--
-- Score weights (tweak to taste):
--   STR ×2, DEX ×3, AGI ×2, ATT ×1, ACC ×2, ATT% ×5, StoreTP ×1,
--   DW ×10, DA ×5, TA ×7, Haste ×0.05, SubBlow ×2
--   Weapon DPS ×3, Weapon ilvl_skill ×0.3, Weapon `hit-1` ×40 (per extra hit)
--
-- NIN notes:
--   * DEX is the primary WS stat (Blade: Hi DEX+AGI, Blade: Ryu DEX+STR×0.5,
--     Blade: Shun AGI, etc.) — weighted highest.
--   * AGI added vs. RDM scorer — secondary WS mod and evasion contribution.
--   * SubBlow doubled (×1 → ×2 vs. RDM) — NIN controls enemy TP gain to
--     limit dangerous TP moves; Subtle Blow is significantly more impactful.
--   * DW remains ×10 — NIN's trademark dual-wield playstyle.
--   * Weapon skill filter: Katana(9) and G.Katana(10).
-- ============================================================================


-- ============================================================================
-- Query A: Top-30 gear for a single slot (NON-weapon)
--   Change @slot_bit to inspect a different slot.
-- ============================================================================
SET @slot_bit := 32;  -- 32 = Body. Try: 16=Head, 64=Hands, 128=Legs, 256=Feet,
                      -- 512=Neck, 1024=Waist, 2048=Ear, 8192=Ring, 32768=Back

WITH
-- Always-on mods (from item_mods)
mods_always AS (
    SELECT
        itemId,
        SUM(CASE WHEN modId =   8 THEN value *  2    ELSE 0 END) +
        SUM(CASE WHEN modId =   9 THEN value *  3    ELSE 0 END) +
        SUM(CASE WHEN modId =  11 THEN value *  2    ELSE 0 END) +
        SUM(CASE WHEN modId =  23 THEN value *  1    ELSE 0 END) +
        SUM(CASE WHEN modId =  25 THEN value *  2    ELSE 0 END) +
        SUM(CASE WHEN modId =  62 THEN value *  5    ELSE 0 END) +
        SUM(CASE WHEN modId =  73 THEN value *  1    ELSE 0 END) +
        SUM(CASE WHEN modId = 259 THEN value * 10    ELSE 0 END) +
        SUM(CASE WHEN modId = 288 THEN value *  5    ELSE 0 END) +
        SUM(CASE WHEN modId = 302 THEN value *  7    ELSE 0 END) +
        SUM(CASE WHEN modId = 384 THEN value *  0.05 ELSE 0 END) +
        SUM(CASE WHEN modId = 289 THEN value *  2    ELSE 0 END) AS score,
        SUM(CASE WHEN modId =   8 THEN value ELSE 0 END) AS STR,
        SUM(CASE WHEN modId =   9 THEN value ELSE 0 END) AS DEX,
        SUM(CASE WHEN modId =  11 THEN value ELSE 0 END) AS AGI,
        SUM(CASE WHEN modId =  23 THEN value ELSE 0 END) AS ATT,
        SUM(CASE WHEN modId =  25 THEN value ELSE 0 END) AS ACC,
        SUM(CASE WHEN modId = 259 THEN value ELSE 0 END) AS DW,
        SUM(CASE WHEN modId = 288 THEN value ELSE 0 END) AS DA,
        SUM(CASE WHEN modId = 302 THEN value ELSE 0 END) AS TA,
        SUM(CASE WHEN modId = 384 THEN value ELSE 0 END) AS Haste_raw
    FROM   item_mods
    GROUP BY itemId
),
-- Conditional mods (from item_latents)
-- WEAPON_DRAWN (10), TP_OVER (7), DURING_WS (41) treated as always-on for a DD.
-- Anything else gets half weight.
mods_latent AS (
    SELECT
        itemId,
        SUM(
            CASE
                WHEN latentId IN (7, 10, 41) THEN 1.0
                ELSE                              0.5
            END *
            CASE
                WHEN modId =   8 THEN value *  2
                WHEN modId =   9 THEN value *  3
                WHEN modId =  11 THEN value *  2
                WHEN modId =  23 THEN value *  1
                WHEN modId =  25 THEN value *  2
                WHEN modId =  62 THEN value *  5
                WHEN modId =  73 THEN value *  1
                WHEN modId = 259 THEN value * 10
                WHEN modId = 288 THEN value *  5
                WHEN modId = 302 THEN value *  7
                WHEN modId = 384 THEN value *  0.05
                WHEN modId = 289 THEN value *  2
                ELSE 0
            END
        ) AS score
    FROM   item_latents
    GROUP BY itemId
)
SELECT
    e.itemId,
    e.name,
    e.level                                       AS lv,
    e.ilevel                                      AS ilv,
    COALESCE(ma.STR,       0)                     AS STR,
    COALESCE(ma.DEX,       0)                     AS DEX,
    COALESCE(ma.AGI,       0)                     AS AGI,
    COALESCE(ma.ATT,       0)                     AS ATT,
    COALESCE(ma.ACC,       0)                     AS ACC,
    COALESCE(ma.DW,        0)                     AS DW,
    COALESCE(ma.DA,        0)                     AS DA,
    COALESCE(ma.TA,        0)                     AS TA,
    COALESCE(ma.Haste_raw, 0)                     AS Haste,
    ROUND(COALESCE(ma.score, 0), 2)               AS always_score,
    ROUND(COALESCE(ml.score, 0), 2)               AS latent_score,
    ROUND(COALESCE(ma.score, 0) +
          COALESCE(ml.score, 0), 2)               AS total_score
FROM       item_equipment e
LEFT JOIN  mods_always    ma ON ma.itemId = e.itemId
LEFT JOIN  mods_latent    ml ON ml.itemId = e.itemId
WHERE      (e.jobs & 4096)      > 0
       AND (e.level <= 99 OR e.ilevel > 0)
       AND (e.slot  & @slot_bit) > 0
HAVING     total_score > 0
ORDER BY   total_score DESC, e.ilevel DESC
LIMIT 30;


-- ============================================================================
-- Query B: Top-30 main-hand WEAPONS (joins item_weapon for DMG, hit, ilvl_skill)
--
--   Weapon-specific contributors layered on top of mod score:
--     * base_dps = dmg * 60 / delay              (×3 weight)
--     * ilvl_skill                                (×0.3 — each skill ≈ acc+att)
--     * (hit - 1)                                (×40 — extra base hits)
--
--   w.skill values:
--     1 H2H   2 Dagger   3 Sword   4 Great Sword
--     5 Axe   6 Greataxe 7 Scythe  8 Polearm
--     9 Katana 10 G.Katana 11 Club 12 Staff
--   NIN normally swings Katana(9), occasionally G.Katana(10).
-- ============================================================================
WITH
mods_always AS (
    SELECT
        itemId,
        SUM(CASE WHEN modId =   8 THEN value *  2    ELSE 0 END) +
        SUM(CASE WHEN modId =   9 THEN value *  3    ELSE 0 END) +
        SUM(CASE WHEN modId =  11 THEN value *  2    ELSE 0 END) +
        SUM(CASE WHEN modId =  23 THEN value *  1    ELSE 0 END) +
        SUM(CASE WHEN modId =  25 THEN value *  2    ELSE 0 END) +
        SUM(CASE WHEN modId =  62 THEN value *  5    ELSE 0 END) +
        SUM(CASE WHEN modId =  73 THEN value *  1    ELSE 0 END) +
        SUM(CASE WHEN modId = 259 THEN value * 10    ELSE 0 END) +
        SUM(CASE WHEN modId = 288 THEN value *  5    ELSE 0 END) +
        SUM(CASE WHEN modId = 302 THEN value *  7    ELSE 0 END) +
        SUM(CASE WHEN modId = 384 THEN value *  0.05 ELSE 0 END) +
        SUM(CASE WHEN modId = 289 THEN value *  2    ELSE 0 END) AS score
    FROM item_mods
    GROUP BY itemId
),
mods_latent AS (
    SELECT
        itemId,
        SUM(
            CASE WHEN latentId IN (7, 10, 41) THEN 1.0 ELSE 0.5 END *
            CASE
                WHEN modId =   8 THEN value *  2
                WHEN modId =   9 THEN value *  3
                WHEN modId =  11 THEN value *  2
                WHEN modId =  23 THEN value *  1
                WHEN modId =  25 THEN value *  2
                WHEN modId =  62 THEN value *  5
                WHEN modId =  73 THEN value *  1
                WHEN modId = 259 THEN value * 10
                WHEN modId = 288 THEN value *  5
                WHEN modId = 302 THEN value *  7
                WHEN modId = 384 THEN value *  0.05
                WHEN modId = 289 THEN value *  2
                ELSE 0
            END
        ) AS score
    FROM item_latents
    GROUP BY itemId
)
SELECT
    e.itemId,
    e.name,
    e.level                                                    AS lv,
    e.ilevel                                                   AS ilv,
    w.skill,
    w.dmg,
    w.delay,
    w.hit,
    w.ilvl_skill,
    ROUND(w.dmg * 60.0 / NULLIF(w.delay, 0), 2)                AS base_dps,
    ROUND(COALESCE(ma.score, 0), 2)                            AS mod_score,
    ROUND(COALESCE(ml.score, 0), 2)                            AS latent_score,
    ROUND(
        COALESCE(ma.score, 0)
      + COALESCE(ml.score, 0)
      + (w.dmg * 60.0 / NULLIF(w.delay, 0)) * 3
      +  w.ilvl_skill * 0.3
      + (w.hit - 1)   * 40,
    2)                                                         AS total_score
FROM      item_equipment e
JOIN      item_weapon    w   ON w.itemId  = e.itemId
LEFT JOIN mods_always    ma  ON ma.itemId = e.itemId
LEFT JOIN mods_latent    ml  ON ml.itemId = e.itemId
WHERE     (e.jobs & 4096) > 0
      AND (e.level <= 99 OR e.ilevel > 0)
      AND (e.slot  & 1) > 0          -- Main hand
      -- AND w.skill IN (9, 10)      -- uncomment to filter to NIN weapon types (Katana, G.Katana)
GROUP BY  e.itemId
ORDER BY  total_score DESC, e.ilevel DESC
LIMIT 30;


-- ============================================================================
-- Query C: Top 5 per slot in one shot (mods + latents)
--   Change @top_n if you want a different cutoff.
-- ============================================================================
SET @top_n := 5;
WITH
mods_always AS (
    SELECT
        itemId,
        SUM(CASE WHEN modId =   8 THEN value *  2    ELSE 0 END) +
        SUM(CASE WHEN modId =   9 THEN value *  3    ELSE 0 END) +
        SUM(CASE WHEN modId =  11 THEN value *  2    ELSE 0 END) +
        SUM(CASE WHEN modId =  23 THEN value *  1    ELSE 0 END) +
        SUM(CASE WHEN modId =  25 THEN value *  2    ELSE 0 END) +
        SUM(CASE WHEN modId =  62 THEN value *  5    ELSE 0 END) +
        SUM(CASE WHEN modId =  73 THEN value *  1    ELSE 0 END) +
        SUM(CASE WHEN modId = 259 THEN value * 10    ELSE 0 END) +
        SUM(CASE WHEN modId = 288 THEN value *  5    ELSE 0 END) +
        SUM(CASE WHEN modId = 302 THEN value *  7    ELSE 0 END) +
        SUM(CASE WHEN modId = 384 THEN value *  0.05 ELSE 0 END) +
        SUM(CASE WHEN modId = 289 THEN value *  2    ELSE 0 END) AS score,
        SUM(CASE WHEN modId =   8 THEN value ELSE 0 END)         AS STR,
        SUM(CASE WHEN modId =   9 THEN value ELSE 0 END)         AS DEX,
        SUM(CASE WHEN modId =  11 THEN value ELSE 0 END)         AS AGI,
        SUM(CASE WHEN modId =  23 THEN value ELSE 0 END)         AS ATT,
        SUM(CASE WHEN modId =  25 THEN value ELSE 0 END)         AS ACC,
        SUM(CASE WHEN modId =  62 THEN value ELSE 0 END)         AS ATTp,
        SUM(CASE WHEN modId =  73 THEN value ELSE 0 END)         AS STP,
        SUM(CASE WHEN modId = 259 THEN value ELSE 0 END)         AS DW,
        SUM(CASE WHEN modId = 288 THEN value ELSE 0 END)         AS DA,
        SUM(CASE WHEN modId = 302 THEN value ELSE 0 END)         AS TA,
        SUM(CASE WHEN modId = 384 THEN value ELSE 0 END)         AS Haste_raw,
        SUM(CASE WHEN modId = 289 THEN value ELSE 0 END)         AS SubBlow
    FROM item_mods
    GROUP BY itemId
),
mods_latent AS (
    SELECT
        itemId,
        SUM(
            CASE WHEN latentId IN (7, 10, 41) THEN 1.0 ELSE 0.5 END *
            CASE
                WHEN modId =   8 THEN value *  2
                WHEN modId =   9 THEN value *  3
                WHEN modId =  11 THEN value *  2
                WHEN modId =  23 THEN value *  1
                WHEN modId =  25 THEN value *  2
                WHEN modId =  62 THEN value *  5
                WHEN modId =  73 THEN value *  1
                WHEN modId = 259 THEN value * 10
                WHEN modId = 288 THEN value *  5
                WHEN modId = 302 THEN value *  7
                WHEN modId = 384 THEN value *  0.05
                WHEN modId = 289 THEN value *  2
                ELSE 0
            END
        ) AS score
    FROM item_latents
    GROUP BY itemId
),
scored AS (
    SELECT
        e.itemId,
        e.name,
        e.slot,
        e.ilevel,
        COALESCE(ma.STR,       0)                                  AS STR,
        COALESCE(ma.DEX,       0)                                  AS DEX,
        COALESCE(ma.AGI,       0)                                  AS AGI,
        COALESCE(ma.ATT,       0)                                  AS ATT,
        COALESCE(ma.ACC,       0)                                  AS ACC,
        COALESCE(ma.ATTp,      0)                                  AS ATTp,
        COALESCE(ma.STP,       0)                                  AS STP,
        COALESCE(ma.DW,        0)                                  AS DW,
        COALESCE(ma.DA,        0)                                  AS DA,
        COALESCE(ma.TA,        0)                                  AS TA,
        COALESCE(ma.Haste_raw, 0)                                  AS Haste,
        COALESCE(ma.SubBlow,   0)                                  AS SubBlow,
        COALESCE(w.dmg,        0)                                  AS dmg,
        COALESCE(w.delay,      0)                                  AS delay,
        COALESCE(w.hit,        0)                                  AS hit,
        COALESCE(w.ilvl_skill, 0)                                  AS wSkill,
        ROUND(COALESCE(ma.score, 0), 2)                            AS mod_score,
        ROUND(COALESCE(ml.score, 0), 2)                            AS latent_score,
        ROUND(
            COALESCE(ma.score, 0)
          + COALESCE(ml.score, 0)
          + COALESCE((w.dmg * 60.0 / NULLIF(w.delay, 0)) * 3, 0)
          + COALESCE(w.ilvl_skill * 0.3, 0)
          + COALESCE((w.hit - 1)   * 40, 0),
        2) AS score
    FROM      item_equipment e
    LEFT JOIN item_weapon  w  ON w.itemId  = e.itemId
    LEFT JOIN mods_always  ma ON ma.itemId = e.itemId
    LEFT JOIN mods_latent  ml ON ml.itemId = e.itemId
    WHERE     (e.jobs & 4096) > 0
          AND (e.level <= 99 OR e.ilevel > 0)
),
slot_lookup AS (
    SELECT     1 AS bit, 'Main'  AS slot UNION ALL
    SELECT     2       , 'Sub'           UNION ALL
    SELECT    16       , 'Head'          UNION ALL
    SELECT    32       , 'Body'          UNION ALL
    SELECT    64       , 'Hands'         UNION ALL
    SELECT   128       , 'Legs'          UNION ALL
    SELECT   256       , 'Feet'          UNION ALL
    SELECT   512       , 'Neck'          UNION ALL
    SELECT  1024       , 'Waist'         UNION ALL
    SELECT  2048       , 'Ear'           UNION ALL
    SELECT  8192       , 'Ring'          UNION ALL
    SELECT 32768       , 'Back'
),
ranked AS (
    SELECT
        sl.slot                                                    AS slot,
        s.itemId,
        s.name,
        s.ilevel                                                   AS ilv,
        s.STR, s.DEX, s.AGI, s.ATT, s.ACC, s.ATTp, s.STP,
        s.DW, s.DA, s.TA, s.Haste, s.SubBlow,
        s.dmg, s.delay, s.hit, s.wSkill,
        s.mod_score, s.latent_score, s.score,
        ROW_NUMBER() OVER (
            PARTITION BY sl.slot
            ORDER BY     s.score DESC, s.ilevel DESC, s.itemId
        )                                                          AS rn
    FROM       slot_lookup sl
    INNER JOIN scored      s  ON (s.slot & sl.bit) > 0
    WHERE      s.score > 0
)
SELECT
    slot,
    rn AS rank,
    itemId,
    name,
    ilv,
    STR, DEX, AGI, ATT, ACC, ATTp, STP,
    DW, DA, TA, Haste, SubBlow,
    dmg, delay, hit, wSkill,
    mod_score, latent_score, score
FROM       ranked
WHERE      rn <= @top_n
ORDER BY   FIELD(slot, 'Main','Sub','Head','Body','Hands','Legs','Feet',
                       'Neck','Waist','Ear','Ring','Back'),
           rn;


-- ============================================================================
-- Tuning notes
-- ----------------------------------------------------------------------------
-- LATENT WEIGHTS
--   The "always-on" set { 7, 10, 41 } covers TP_OVER, WEAPON_DRAWN, DURING_WS.
--   For an active melee NIN these are effectively always satisfied while
--   fighting.  Everything else (HP_UNDER, SUBJOB-specific, weather, etc.) is
--   counted at 50% — you can change the 0.5 in mods_latent to 0 to ignore
--   them entirely, or 1.0 to count them in full.
--
--   If you want to honor subjob-specific latents (e.g. /WAR, /DNC), modify
--   mods_latent to use 1.0 when latentId = 8 AND latentParam = your-subjob.
--
-- WEAPON SCORING
--   * base_dps × 3       — raw DPS contribution
--   * ilvl_skill × 0.3   — each combat-skill point ≈ +0.9 acc and ~+0.9 att
--                          at lv99, so a 228-skill weapon gives ~68 score
--                          from skill alone.  Tune if you want this lower.
--   * (hit-1) × 40       — a 2-hit weapon is worth ~one weapon's worth of
--                          score on top of its single-swing DPS.
--   NIN weapon filter:   uncomment `AND w.skill IN (9, 10)` in Query B to
--                        restrict to Katana / G.Katana only.
--
-- NIN STAT RATIONALE
--   DEX ×3  — Primary WS modifier on most Blade WSs (Hi, Ryu, Shun, Chi, etc.)
--              Also boosts accuracy and critical hit rate.
--   AGI ×2  — Secondary WS mod (Blade: Hi uses DEX+AGI, Blade: Shun is AGI).
--              Also the primary evasion stat.  Lower weight than DEX but
--              meaningfully non-zero for a serious NIN DD.
--   STR ×2  — General melee damage and some WS mods (Blade: Ryu STR×0.5).
--   DW  ×10 — Dual Wield is the core of NIN's DD capability.  Each point
--              reduces the TP-per-swing hit delay penalty of dual-wielding.
--   SubBlow ×2 — Doubled vs. the RDM scorer.  Subtle Blow reduces the TP
--              enemies gain per hit, directly reducing how often dangerous
--              TP moves occur.  Critical for NIN which hits very frequently.
--
-- OTHER ROLES — same query structure, swap the CASE expressions in BOTH
-- mods_always AND mods_latent to:
--
--   Nuking:        12 INT (×3), 28 MATT (×2), 30 MACC (×2), 170 FASTCAST (×3),
--                  311 MAGIC_DAMAGE (×4)
--   Enfeebling:    13 MND (×3), 30 MACC (×3), 170 FASTCAST (×2), 79 ENF_SKILL (×3)
--   Healing:       13 MND (×3), 5 MP (×0.05), 369 REFRESH (×30), 170 FASTCAST (×2)
--   To score as RDM instead: change job bit back to 16, remove AGI, set SubBlow ×1.
-- ============================================================================
