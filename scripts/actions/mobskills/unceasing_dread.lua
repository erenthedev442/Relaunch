-----------------------------------
-- Unceasing Dread (Arciela II) — Neutral
-- Inflicts Paralysis. No skillchain.
-----------------------------------
local arciela = require('scripts/actions/mobskills/_arciela_ii_skill')

return arciela.magical(
    xi.element.DARK,
    xi.damageType.DARK,
    3.0,
    xi.effect.PARALYSIS,
    30,
    60,
    false,
    nil)
