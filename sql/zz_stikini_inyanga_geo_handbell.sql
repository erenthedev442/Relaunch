-- Fix: "All Magic Skills" items were missing the GEO-era skills Geomancy (mod 123)
-- and Handbell (mod 124), so they only buffed 12 of the 14 magic skills.
-- Reported by Ruin (Stikini Ring). Affected: Stikini Ring/+1, Inyanga Dastanas/+1.
-- Values match each item's existing magic-skill bonus. Takes effect on map restart
-- (item_mods is loaded into item data at boot).
INSERT IGNORE INTO item_mods VALUES
    (26183, 123, 5),  (26183, 124, 5),   -- Stikini Ring        : +5 Geomancy/Handbell
    (26184, 123, 8),  (26184, 124, 8),   -- Stikini Ring +1     : +8
    (25806, 123, 15), (25806, 124, 15),  -- Inyanga Dastanas    : +15
    (25807, 123, 18), (25807, 124, 18);  -- Inyanga Dastanas +1 : +18
