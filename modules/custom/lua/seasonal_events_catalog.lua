-----------------------------------
-- seasonal_events_catalog.lua
-- Defines seasonal event windows during which Hunting League kills earn
-- a bonus mark multiplier.  Only one event bonus applies at a time
-- (highest priority wins if two windows overlap).
--
-- To activate a new event:
--   1. Uncomment (or add) an entry below.
--   2. Set start/finish to Unix timestamps (seconds since 1970-01-01 UTC).
--      Use https://www.epochconverter.com/ or `python3 -c "import time; print(int(time.mktime(...)))"`.
--   3. Set multiplier (2.0 = double marks, 1.5 = 50% bonus, etc.).
--   4. Reload the server module (or restart).  No DB changes needed.
--
-- Each event entry:
--   name        : player-visible label (shown in the kill bonus message)
--   multiplier  : mark multiplier applied on top of Guild amplifier
--   start       : Unix timestamp when the event becomes active
--   finish      : Unix timestamp when the event ends (exclusive)
--   priority    : higher number wins if two events overlap (default 0)
-----------------------------------
local catalog = {}

catalog.events = {
    -- -- EXAMPLE - Winter Solstice Festival ---------------------
    -- Double marks Dec 20 - Jan 3 each year.  Update timestamps annually.
    -- {
    --     name       = 'Winter Solstice Festival',
    --     multiplier = 2.0,
    --     start      = 1766275200,   -- 2026-12-20 00:00 UTC
    --     finish     = 1767571200,   -- 2027-01-04 00:00 UTC
    --     priority   = 10,
    -- },

    -- -- EXAMPLE - Anniversary Celebration ----------------------
    -- 1.5x marks for a weekend (low-cost way to reward activity).
    -- {
    --     name       = 'Server Anniversary',
    --     multiplier = 1.5,
    --     start      = 1777593600,   -- 2026-05-28 00:00 UTC
    --     finish     = 1777852800,   -- 2026-05-31 00:00 UTC
    --     priority   = 5,
    -- },

    -- -- EXAMPLE - Summer Celebration ---------------------------
    -- {
    --     name       = 'Summer Celebration',
    --     multiplier = 1.5,
    --     start      = 1783468800,   -- 2026-07-04 00:00 UTC
    --     finish     = 1783728000,   -- 2026-07-07 00:00 UTC
    --     priority   = 5,
    -- },
}

return catalog
