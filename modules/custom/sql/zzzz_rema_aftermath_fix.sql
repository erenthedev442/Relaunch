-- ============================================================================
-- Canonical final REMA + Prime aftermath wiring
--
-- This file sorts after the older family-specific patches and repairs stale,
-- missing, or conflicting AFTERMATH (mod 256) values in one idempotent pass.
-- Item mods are cached by xi_map, so restart the map server after deployment.
-- ============================================================================

INSERT INTO `item_mods` (`itemId`, `modId`, `value`) VALUES
    -- Relic 119 III: tier-2 family-specific aftermaths.
    (20509, 256, 15), (20583, 256, 16), (20685, 256, 17), (21683, 256, 18),
    (21750, 256, 19), (21756, 256, 20), (21808, 256, 21), (21857, 256, 22),
    (21906, 256, 23), (21954, 256, 24), (21077, 256, 25), (22060, 256, 26),
    (22129, 256, 27), (22140, 256, 28),

    -- Mythic 119 III: tier-3 aftermaths by weapon profile.
    (20510, 256, 39), (20511, 256, 39), (20584, 256, 39), (20585, 256, 39),
    (20687, 256, 39), (21751, 256, 39), (21757, 256, 39), (21809, 256, 39),
    (21858, 256, 39), (21907, 256, 39), (21955, 256, 39), (22063, 256, 39),
    (20586, 256, 40), (21078, 256, 40),
    (20686, 256, 41), (22061, 256, 41), (22062, 256, 41),
    (20688, 256, 42),
    (22139, 256, 43), (22141, 256, 43),

    -- Empyrean 119 III: tier-2 ODD/OTD aftermath (melee/ranged selected in Lua).
    (20512, 256, 45), (20587, 256, 45), (20689, 256, 45), (21079, 256, 45),
    (21684, 256, 45), (21752, 256, 45), (21758, 256, 45), (21810, 256, 45),
    (21859, 256, 45), (21908, 256, 45), (21956, 256, 45), (22064, 256, 45),
    (22130, 256, 45), (22142, 256, 45),

    -- Aeonic: 49 melee, 50 ranged. Any WS activates this family centrally.
    (20515, 256, 49), (20594, 256, 49), (20695, 256, 49), (20843, 256, 49),
    (20890, 256, 49), (20935, 256, 49), (20977, 256, 49), (21025, 256, 49),
    (21082, 256, 49), (21147, 256, 49), (21694, 256, 49), (21753, 256, 49),
    (21485, 256, 50), (22117, 256, 50),

    -- Prime physical weapons, including server-supported base/intermediate forms.
    (21531, 256, 46), (21534, 256, 46), (21535, 256, 46),
    (21586, 256, 46), (21589, 256, 46), (21590, 256, 46),
    (21642, 256, 46), (21646, 256, 46), (21653, 256, 46),
    (21726, 256, 46), (21730, 256, 46), (21781, 256, 46), (21785, 256, 46),
    (21833, 256, 46), (21834, 256, 46), (21835, 256, 46),
    (21836, 256, 46), (21837, 256, 46),
    (21887, 256, 46), (21891, 256, 46),
    (21932, 256, 46), (21986, 256, 46),
    (22155, 256, 46), (22159, 256, 46), (22163, 256, 46), (22164, 256, 46),

    -- Prime club and staff use their dedicated magic/support aftermath profiles.
    (22002, 256, 47),
    (22102, 256, 48), (22106, 256, 48)
ON DUPLICATE KEY UPDATE `value` = VALUES(`value`);

-- Gungnir's relic WS row is weapon-granted (all-zero job mask), so the final
-- weapon must explicitly expose Geirskogul through ADDS_WEAPONSKILL.
INSERT INTO `item_mods` (`itemId`, `modId`, `value`) VALUES
    (21857, 355, 121)
ON DUPLICATE KEY UPDATE `value` = VALUES(`value`);
