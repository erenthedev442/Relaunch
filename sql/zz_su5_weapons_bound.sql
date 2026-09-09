-- ============================================================================
-- Bind every Su5 (Superior Lv5) weapon so it cannot leave the character.
--
-- These are the named weapons in scripts/globals/dynamis_divergence.lua
-- (SU5_WEAPONS). They used to roll from Abyssea NMs; they now drop from
-- Dynamis Divergence Mega-Bosses. Same IDs either way.
--
-- Flags added (applies to every copy, including ones already owned):
--   NOAUCTION  0x0040 -- cannot be listed on the Auction House
--   NOSALE     0x1000 -- cannot be sold to NPC vendors
--   NODELIVERY 0x2000 -- cannot be sent through the Delivery Box
--   EXCLUSIVE  0x4000 -- cannot be traded or bazaared; displays Ex
--
-- CanSendAccount (0x0010) is cleared so a mule on the same account cannot
-- receive them via delivery. AugSendable (0x0001) is cleared with it.
-- RARE is not added -- a character may hold more than one.
--
-- Apply SQL, then restart xi_map (item_basic is cached at boot). Idempotent.
-- ============================================================================

UPDATE `item_basic`
SET
    `flags` = (`flags` | 28736) & ~17,
    `aH`    = 0
WHERE `itemid` IN
(
    21523, -- Sagitta
    21526, -- Xiucoatl
    21575, -- Gandring
    21578, -- Barfawc
    21581, -- Rostam
    21584, -- Setan Kober
    21627, -- Crocea Mors
    21630, -- Moralltach
    21633, -- Zomorrodnegar
    21669, -- Morgelai
    21717, -- Pangu
    21774, -- Labraunda
    21825, -- Father Time
    21878, -- Aram
    21917, -- Fudo Masamune
    21970, -- Fusenaikyo
    22035, -- Asclepius
    22038, -- Bhima
    22093, -- Kaumodaki
    22096, -- Draumstafir
    22099, -- Musa
    22149  -- Sharanga
);
