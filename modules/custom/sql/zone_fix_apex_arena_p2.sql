-- Walk_of_Echoes_[P2] (zone 279): Apex Trials dedicated arena
-- Set misc = MISC_PET(0x80=128) so pets (BST/SMN/GEO) work; MISC_TRUST stays
-- off to enforce the solo-only rule.  Was 2048 (MISC_TRUST only) by default.
UPDATE zone_settings SET misc = 128 WHERE zoneid = 279;
