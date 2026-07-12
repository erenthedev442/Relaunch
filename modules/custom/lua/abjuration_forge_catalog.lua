-----------------------------------
-- abjuration_forge_catalog.lua
-- Config for the AbjurationForge NPC (AbjurationForge_NPC.lua reads it).
--
-- Owner request 2026-07-13: 'these abjurations should drop from our geas-fete
-- NMs -- have our own custom NPC in the !hub that handles the trades and
-- upgrades'. This is the relaunch analogue of retail's Nolan in Norg:
--   * TRADE: Player hands over a Reisenjima abjuration -> receives the
--     matching augmented armor piece (slot- and family-locked). All 25
--     augmented pieces (Odyssean / Valorous / Chironic / Merlinic /
--     Herculean, 5 slots each) are otherwise unobtainable on relaunch
--     (they were pulled from the Domain QM in the Nolan-cleanup pass).
--   * UPGRADE: Player hands over an NQ Reisenjima-crafted piece
--     (Adhemar / Argosy / Carmine / Rao / Ryuo / Souveran) + Riftborn
--     Boulders -> receives the +1 version of the same piece. Naga has no
--     +1 so it's excluded from the upgrade menu.
--
-- Abjuration drops themselves are wired in modules/custom/lua/Geas_Fete.lua
-- (ABJURATIONS table + roll in awardDrops).
-----------------------------------
local catalog = {}

-- NPC placement in Purgonorgo Isle (!hub), on the vendor row. Nudge with
-- !pos in-game if it clips a neighbour.
catalog.npcPos =
{
    zone     = 'Abdhaljs_Isle-Purgonorgo',
    zoneId   = 44,
    x        =  548.500,
    y        =   -3.3322,
    z        =  475.600,
    rotation =   96,
}

-- ===================================================================
-- ABJURATION -> AUGMENTED ARMOR
-- Each abjuration id maps to a specific augmented-armor id. Slot-locked
-- (head-abjuration -> head-armor) and family-locked (each abjuration
-- family produces one armor family: Bushin->Valorous, Cyllenian->Odyssean,
-- Foreboding->Chironic, Grove->Merlinic, Hadean->Herculean). All 25 pieces
-- of augmented armor are NQ-only in this build; no +1 tier exists.
-- ===================================================================
catalog.abjToArmor =
{
    -- Bushin -> Valorous
    [8762] = { id = 25641, name = 'Valorous Mask'     },  -- head
    [8763] = { id = 25717, name = 'Valorous Mail'     },  -- body
    [8764] = { id = 27139, name = 'Valorous Mitts'    },  -- hands
    [8765] = { id = 25841, name = 'Valorous Hose'     },  -- legs
    [8766] = { id = 27495, name = 'Valorous Greaves'  },  -- feet
    -- Cyllenian -> Odyssean
    [9125] = { id = 25640, name = 'Odyssean Helm'       }, -- head
    [9126] = { id = 25716, name = 'Odyssean Chestplate' }, -- body
    [9127] = { id = 27138, name = 'Odyssean Gauntlets'  }, -- hands
    [9128] = { id = 25840, name = 'Odyssean Cuisses'    }, -- legs
    [9129] = { id = 27494, name = 'Odyssean Greaves'    }, -- feet
    -- Foreboding -> Chironic
    [3574] = { id = 25644, name = 'Chironic Hat'       }, -- head
    [3575] = { id = 25720, name = 'Chironic Doublet'   }, -- body
    [3576] = { id = 27142, name = 'Chironic Gloves'    }, -- hands
    [3577] = { id = 25844, name = 'Chironic Hose'      }, -- legs
    [3578] = { id = 27498, name = 'Chironic Slippers'  }, -- feet
    -- Grove -> Merlinic
    [8772] = { id = 25643, name = 'Merlinic Hood'      }, -- head
    [8773] = { id = 25719, name = 'Merlinic Jubbah'    }, -- body
    [8774] = { id = 27141, name = 'Merlinic Dastanas'  }, -- hands
    [8775] = { id = 25843, name = 'Merlinic Shalwar'   }, -- legs
    [8776] = { id = 27497, name = 'Merlinic Crackows'  }, -- feet
    -- Hadean -> Herculean
    [2434] = { id = 25642, name = 'Herculean Helm'     }, -- head
    [2435] = { id = 25718, name = 'Herculean Vest'     }, -- body
    [2436] = { id = 27140, name = 'Herculean Gloves'   }, -- hands
    [2437] = { id = 25842, name = 'Herculean Trousers' }, -- legs
    [2438] = { id = 27496, name = 'Herculean Boots'    }, -- feet
}

-- ===================================================================
-- CRAFTED-FAMILY NQ -> +1 UPGRADES
-- Six Reisenjima-crafted families that DO have +1 tiers in the item data
-- (Naga is intentionally excluded -- no +1 exists). Player trades the NQ
-- piece + N Riftborn Boulders, receives the +1 piece.
-- ===================================================================
catalog.upgradeMat      = 4061  -- Riftborn Boulder
catalog.upgradeMatName  = 'Riftborn Boulder'
catalog.upgradeMatQty   = 3     -- per piece; tunable

catalog.nqToHq =
{
    -- Adhemar +1 (head/body/hands/legs/feet)
    [25613] = { id = 25614, name = 'Adhemar Bonnet +1'     },
    [25686] = { id = 25687, name = 'Adhemar Jacket +1'     },
    [27117] = { id = 27118, name = 'Adhemar Wristbands +1' },
    [27302] = { id = 27303, name = 'Adhemar Kecks +1'      },
    [27473] = { id = 27474, name = 'Adhemar Gamashes +1'   },
    -- Argosy +1
    [26672] = { id = 26673, name = 'Argosy Celata +1'    },
    [26848] = { id = 26849, name = 'Argosy Hauberk +1'   },
    [27024] = { id = 27025, name = 'Argosy Mufflers +1'  },
    [27200] = { id = 27201, name = 'Argosy Breeches +1'  },
    [27376] = { id = 27377, name = 'Argosy Sollerets +1' },
    -- Carmine +1
    [26678] = { id = 26679, name = 'Carmine Mask +1'             },
    [26854] = { id = 26855, name = 'Carmine Scale Mail +1'       },
    [27030] = { id = 27031, name = 'Carmine Finger Gauntlets +1' },
    [27206] = { id = 27207, name = 'Carmine Cuisses +1'          },
    [27382] = { id = 27383, name = 'Carmine Greaves +1'          },
    -- Rao +1
    [26674] = { id = 26675, name = 'Rao Kabuto +1'   },
    [26850] = { id = 26851, name = 'Rao Togi +1'     },
    [27026] = { id = 27027, name = 'Rao Kote +1'     },
    [27202] = { id = 27203, name = 'Rao Haidate +1'  },
    [27378] = { id = 27379, name = 'Rao Sune-Ate +1' },
    -- Ryuo +1
    [25611] = { id = 25612, name = 'Ryuo Somen +1'    },
    [25684] = { id = 25685, name = 'Ryuo Domaru +1'   },
    [27115] = { id = 27116, name = 'Ryuo Tekko +1'    },
    [27300] = { id = 27301, name = 'Ryuo Hakama +1'   },
    [27471] = { id = 27472, name = 'Ryuo Sune-Ate +1' },
    -- Souveran +1
    [26670] = { id = 26671, name = 'Souveran Schaller +1'    },
    [26846] = { id = 26847, name = 'Souveran Cuirass +1'     },
    [27022] = { id = 27023, name = 'Souveran Handschuhs +1'  },
    [27198] = { id = 27199, name = 'Souveran Diechlings +1'  },
    [27374] = { id = 27375, name = 'Souveran Schuhs +1'      },
}

return catalog
