-----------------------------------
-- blu_spell_progression.lua
--
-- Automatically grants Blue Mage spells as BLU levels up, and
-- does a full catch-up on login (so new spells added to the table
-- are retroactively granted to logged-in BLUs without a GM command).
--
-- Hook points:
--   xi.player.onPlayerLevelUp  - grant spells unlocked at new level
--   xi.player.onGameIn         - catch-up all spells <= current level
--
-- No source edits required. Loaded automatically by the module system.
-----------------------------------
require('modules/module_utils')
require('scripts/globals/player')

local m = Module:new('blu_spell_progression')

-- ---- Progression table: BLU level → spell ID list --------------------
-- Source: -- Level: X comments in scripts/actions/spells/blue/<spell>.lua
-- and Calvin/blue_mage_spells/blu_spell_progression.lua
local spellsByLevel =
{
    [ 1] = { xi.magic.spell.FOOT_KICK,        xi.magic.spell.POLLEN,           xi.magic.spell.SANDSPIN          },
    [ 4] = { xi.magic.spell.POWER_ATTACK,     xi.magic.spell.SPROUT_SMACK,     xi.magic.spell.WILD_OATS         },
    [ 8] = { xi.magic.spell.COCOON,           xi.magic.spell.METALLIC_BODY,    xi.magic.spell.QUEASYSHROOM      },
    [12] = { xi.magic.spell.BATTLE_DANCE,     xi.magic.spell.FEATHER_STORM,    xi.magic.spell.HEAD_BUTT         },
    [16] = { xi.magic.spell.HEALING_BREEZE,   xi.magic.spell.HELLDIVE,         xi.magic.spell.SHEEP_SONG        },
    [18] = { xi.magic.spell.BLASTBOMB,        xi.magic.spell.BLUDGEON,         xi.magic.spell.CURSED_SPHERE     },
    [20] = { xi.magic.spell.BLOOD_DRAIN,      xi.magic.spell.CLAW_CYCLONE                                       },
    [22] = { xi.magic.spell.POISON_BREATH                                                                        },
    [24] = { xi.magic.spell.SOPORIFIC                                                                            },
    [26] = { xi.magic.spell.SCREWDRIVER                                                                          },
    [28] = { xi.magic.spell.BOMB_TOSS                                                                            },
    [30] = { xi.magic.spell.GRAND_SLAM,       xi.magic.spell.WILD_CARROT                                        },
    [32] = { xi.magic.spell.CHAOTIC_EYE,      xi.magic.spell.SOUND_BLAST                                        },
    [34] = { xi.magic.spell.DEATH_RAY,        xi.magic.spell.SMITE_OF_RAGE                                      },
    [36] = { xi.magic.spell.DIGEST,           xi.magic.spell.PINECONE_BOMB                                      },
    [38] = { xi.magic.spell.BLANK_GAZE,       xi.magic.spell.JET_STREAM,       xi.magic.spell.UPPERCUT          },
    [40] = { xi.magic.spell.MYSTERIOUS_LIGHT, xi.magic.spell.TERROR_TOUCH                                       },
    [42] = { xi.magic.spell.MP_DRAINKISS,     xi.magic.spell.VENOM_SHELL                                        },
    [44] = { xi.magic.spell.BLITZSTRAHL,      xi.magic.spell.MANDIBULAR_BITE,  xi.magic.spell.STINKING_GAS      },
    [46] = { xi.magic.spell.AWFUL_EYE,        xi.magic.spell.GEIST_WALL,       xi.magic.spell.MAGNETITE_CLOUD   },
    [48] = { xi.magic.spell.BLOOD_SABER,      xi.magic.spell.JETTATURA,        xi.magic.spell.REFUELING,
             xi.magic.spell.SICKLE_SLASH                                                                         },
    [50] = { xi.magic.spell.FRIGHTFUL_ROAR,   xi.magic.spell.ICE_BREAK,        xi.magic.spell.SELF_DESTRUCT     },
    [52] = { xi.magic.spell.COLD_WAVE,        xi.magic.spell.FILAMENTED_HOLD                                    },
    [54] = { xi.magic.spell.HECATOMB_WAVE,    xi.magic.spell.RADIANT_BREATH                                     },
    [56] = { xi.magic.spell.FEATHER_BARRIER                                                                      },
    [58] = { xi.magic.spell.FLYING_HIP_PRESS, xi.magic.spell.LIGHT_OF_PENANCE, xi.magic.spell.MAGIC_FRUIT      },
    [60] = { xi.magic.spell.DEATH_SCISSORS,   xi.magic.spell.DIMENSIONAL_DEATH, xi.magic.spell.SPIRAL_SPIN     },
    [61] = { xi.magic.spell.BAD_BREATH,       xi.magic.spell.EYES_ON_ME,       xi.magic.spell.MAELSTROM,
             xi.magic.spell.SEEDSPRAY                                                                            },
    [62] = { xi.magic.spell.BODY_SLAM,        xi.magic.spell.MEMENTO_MORI,     xi.magic.spell.THOUSAND_NEEDLES  },
    [63] = { xi.magic.spell.FRENETIC_RIP,     xi.magic.spell.FRYPAN,           xi.magic.spell.HYDRO_SHOT,
             xi.magic.spell.SPINAL_CLEAVE                                                                        },
    [64] = { xi.magic.spell.FEATHER_TICKLE,   xi.magic.spell.YAWN                                               },
    [65] = { xi.magic.spell.INFRASONICS,      xi.magic.spell.ZEPHYR_MANTLE                                      },
    [66] = { xi.magic.spell.CORROSIVE_OOZE,   xi.magic.spell.FROST_BREATH,     xi.magic.spell.SANDSPRAY        },
    [67] = { xi.magic.spell.DIAMONDHIDE,      xi.magic.spell.ENERVATION                                         },
    [68] = { xi.magic.spell.FIRESPIT,         xi.magic.spell.REGURGITATION,    xi.magic.spell.WARM_UP           },
    [69] = { xi.magic.spell.HYSTERIC_BARRAGE, xi.magic.spell.TAIL_SLAP                                          },
    [70] = { xi.magic.spell.AMPLIFICATION,    xi.magic.spell.ASURAN_CLAWS,     xi.magic.spell.CANNONBALL        },
    [71] = { xi.magic.spell.HEAT_BREATH,      xi.magic.spell.LOWING,           xi.magic.spell.TRIUMPHANT_ROAR   },
    [72] = { xi.magic.spell.DISSEVERMENT,     xi.magic.spell.SALINE_COAT,      xi.magic.spell.SUB_ZERO_SMASH,
             xi.magic.spell.VORACIOUS_TRUNK                                                                      },
    [73] = { xi.magic.spell.MIND_BLAST,       xi.magic.spell.RAM_CHARGE,       xi.magic.spell.TEMPORAL_SHIFT    },
    [74] = { xi.magic.spell.ACTINIC_BURST,    xi.magic.spell.MAGIC_HAMMER,     xi.magic.spell.REACTOR_COOL      },
    [75] = { xi.magic.spell.EXUVIATION,       xi.magic.spell.PLASMA_CHARGE,    xi.magic.spell.VERTICAL_CLEAVE   },
    [77] = { xi.magic.spell.ACRID_STREAM,     xi.magic.spell.LEAFSTORM                                          },
    [78] = { xi.magic.spell.CIMICINE_DISCHARGE, xi.magic.spell.REGENERATION                                     },
    [79] = { xi.magic.spell.ANIMATING_WAIL,   xi.magic.spell.BATTERY_CHARGE                                     },
    [80] = { xi.magic.spell.BLAZING_BOUND,    xi.magic.spell.DEMORALIZING_ROAR                                  },
    [81] = { xi.magic.spell.FINAL_STING,      xi.magic.spell.GOBLIN_RUSH                                        },
    [82] = { xi.magic.spell.MAGIC_BARRIER,    xi.magic.spell.VANITY_DIVE                                        },
    [83] = { xi.magic.spell.BENTHIC_TYPHOON,  xi.magic.spell.WHIRL_OF_RAGE                                      },
    [84] = { xi.magic.spell.AURORAL_DRAPE,    xi.magic.spell.OSMOSIS                                            },
    [85] = { xi.magic.spell.FANTOD,           xi.magic.spell.QUADRATIC_CONTINUUM                                },
    [86] = { xi.magic.spell.THERMAL_PULSE                                                                        },
    [87] = { xi.magic.spell.DREAM_FLOWER,     xi.magic.spell.EMPTY_THRASH                                       },
    [88] = { xi.magic.spell.CHARGED_WHISKER,  xi.magic.spell.OCCULTATION                                        },
    [89] = { xi.magic.spell.DELTA_THRUST,     xi.magic.spell.WINDS_OF_PROMYVION                                 },
    [90] = { xi.magic.spell.EVRYONES_GRUDGE,  xi.magic.spell.REAVING_WIND                                       },
    [91] = { xi.magic.spell.BARRIER_TUSK,     xi.magic.spell.MORTAL_RAY                                         },
    [92] = { xi.magic.spell.HEAVY_STRIKE,     xi.magic.spell.WATER_BOMB                                         },
    [93] = { xi.magic.spell.DARK_ORB                                                                             },
    [94] = { xi.magic.spell.WHITE_WIND                                                                           },
    [95] = { xi.magic.spell.HARDEN_SHELL,     xi.magic.spell.SUDDEN_LUNGE,     xi.magic.spell.THUNDERBOLT       },
    [96] = { xi.magic.spell.ABSOLUTE_TERROR,  xi.magic.spell.QUADRASTRIKE,     xi.magic.spell.VAPOR_SPRAY       },
    [97] = { xi.magic.spell.GATES_OF_HADES,   xi.magic.spell.THUNDER_BREATH,   xi.magic.spell.TOURBILLION       },
    [98] = { xi.magic.spell.AMORPHIC_SPIKES,  xi.magic.spell.ORCISH_COUNTERSTANCE, xi.magic.spell.PYRIC_BULWARK },
    [99] = { xi.magic.spell.ANVIL_LIGHTNING,  xi.magic.spell.BARBED_CRESCENT,  xi.magic.spell.BILGESTORM,
             xi.magic.spell.BLINDING_FULGOR,  xi.magic.spell.BLISTERING_ROAR,  xi.magic.spell.BLOODRAKE,
             xi.magic.spell.CARCHARIAN_VERVE, xi.magic.spell.CESSPOOL,          xi.magic.spell.CRASHING_THUNDER,
             xi.magic.spell.CRUEL_JOKE,       xi.magic.spell.DIFFUSION_RAY,    xi.magic.spell.DRONING_WHIRLWIND,
             xi.magic.spell.EMBALMING_EARTH,  xi.magic.spell.ENTOMB,           xi.magic.spell.ERRATIC_FLUTTER,
             xi.magic.spell.FOUL_WATERS,      xi.magic.spell.GLUTINOUS_DART,   xi.magic.spell.MIGHTY_GUARD,
             xi.magic.spell.MOLTING_PLUMAGE,  xi.magic.spell.NATURES_MEDITATION, xi.magic.spell.NECTAROUS_DELUGE,
             xi.magic.spell.PALLING_SALVO,    xi.magic.spell.PARALYZING_TRIAD, xi.magic.spell.POLAR_ROAR,
             xi.magic.spell.RAIL_CANNON,      xi.magic.spell.RENDING_DELUGE,   xi.magic.spell.RESTORAL,
             xi.magic.spell.RETINAL_GLARE,    xi.magic.spell.SAURIAN_SLIDE,    xi.magic.spell.SCOURING_SPATE,
             xi.magic.spell.SEARING_TEMPEST,  xi.magic.spell.SILENT_STORM,     xi.magic.spell.SINKER_DRILL,
             xi.magic.spell.SPECTRAL_FLOE,    xi.magic.spell.SUBDUCTION,       xi.magic.spell.SWEEPING_GOUGE,
             xi.magic.spell.TEARING_GUST,     xi.magic.spell.TEMPESTUOUS_UPHEAVAL, xi.magic.spell.TENEBRAL_CRUSH,
             xi.magic.spell.THRASHING_ASSAULT, xi.magic.spell.UPROOT,          xi.magic.spell.WIND_BREATH        },
}

-- ---- Helper: grant all spells unlocked at exactly `level` ----------
local function grantAtLevel(player, level)
    local list = spellsByLevel[level]
    if not list then return end
    for _, spellId in ipairs(list) do
        if not player:hasSpell(spellId) then
            player:addSpell(spellId, { silentLog = true, saveToDB = true, sendUpdate = true })
            player:printToPlayer(
                string.format('[BLU] You learn a new spell (id %d)!', spellId),
                xi.msg.channel.SYSTEM_3)
        end
    end
end

-- ---- Helper: catch-up grant all spells for levels 1..level ----------
local function grantUpToLevel(player, level)
    for lvl = 1, level do
        grantAtLevel(player, lvl)
    end
end

-- ---- Hook: level-up ------------------------------------------------
-- Fires when main-job level increases. Act for BLU main; also handle
-- /BLU sub since sub level = floor(main/2) and rises with main level.
m:addOverride('xi.player.onPlayerLevelUp', function(player)
    super(player)
    if player:getMainJob() == xi.job.BLU then
        grantAtLevel(player, player:getMainLvl())
    elseif player:getSubJob() == xi.job.BLU then
        grantAtLevel(player, player:getSubLvl())
    end
end)

-- ---- Hook: login / zone-in ----------------------------------------
-- On actual login (not zoning), do a full catch-up pass.  This makes
-- retroactively adding new spells to the table propagate automatically
-- the next time a BLU logs in, without any GM command.
-- Also covers /BLU sub so players never have to swap main just to get
-- their spell list populated before setting spells.
m:addOverride('xi.player.onGameIn', function(player, firstLogin, zoning)
    super(player, firstLogin, zoning)
    if not zoning then
        if player:getMainJob() == xi.job.BLU then
            grantUpToLevel(player, player:getMainLvl())
        elseif player:getSubJob() == xi.job.BLU then
            grantUpToLevel(player, player:getSubLvl())
        end
    end
end)

return m
