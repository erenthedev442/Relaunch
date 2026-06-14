-----------------------------------
-- cross_job_trait_catalog.lua
--
-- The curated set of JOB TRAITS sold by the Cross-Job Trait Trainer (GM Home),
-- sibling to the Cross-Job Ability Trainer. Unlike abilities, traits are passive
-- MODIFIERS, so a purchase just applies the mod(s) and CrossJob_TraitTrainer.lua
-- re-applies them on every onGameIn (a zone-in wipes in-memory mods).
--
-- Each trait: id (charVar key suffix), name (menu label), desc, and `mods` =
-- a list of { xi.mod.X, value } pairs applied additively (stacks with gear).
-- Values are the raw mod scale verified against sql/traits.sql (e.g. accuracy
-- bonus = mods 25 ACC + 26 RACC, value 20 ~ rank 2).
--
-- TUNE: change a value, add a row, or re-price GIL_COST -- one place.
-----------------------------------
local catalog = {}

catalog.GIL_COST = 10000000  -- 10,000,000 gil each, matching the Ability Trainer
catalog.cvPrefix = 'CJTrait_' -- per-trait ownership charVar: CJTrait_<id> = 1
catalog.npcPos   = { x = 9.000, y = 0.000, z = -7.000, rot = 128 }  -- GM Home trainer row, east of the Ability Trainer (x=6)

catalog.traits =
{
    { id = 'dwield',   name = 'Dual Wield',     desc = 'Wield two weapons on ANY job (+15% dual wield).',
      mods = { { xi.mod.DUAL_WIELD, 15 } }, trait = xi.trait.DUAL_WIELD },
    { id = 'counter',  name = 'Counter',        desc = 'Chance to counter melee attacks (+5%).',
      mods = { { xi.mod.COUNTER, 5 } } },
    { id = 'fcast',    name = 'Fast Cast',      desc = 'Reduce spell casting time (+15%).',
      mods = { { xi.mod.FASTCAST, 15 } } },
    { id = 'attbonus', name = 'Attack Bonus',   desc = 'Boost melee attack (+10%).',
      mods = { { xi.mod.ATTP, 10 } } },
    { id = 'accbonus', name = 'Accuracy Bonus', desc = 'Boost accuracy and ranged accuracy (+20).',
      mods = { { xi.mod.ACC, 20 }, { xi.mod.RACC, 20 } } },
    { id = 'maxhp',    name = 'Max HP Boost',   desc = 'Increase maximum HP (+150).',
      mods = { { xi.mod.HP, 150 } } },
}

return catalog
