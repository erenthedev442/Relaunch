-----------------------------------
-- Dignified Awe (Arciela II) — Neutral
-- Inflicts Amnesia. No skillchain.
-----------------------------------
local arciela = require('scripts/actions/mobskills/_arciela_ii_skill')

return arciela.magical(
    xi.element.LIGHT,
    xi.damageType.LIGHT,
    3.0,
    xi.effect.AMNESIA,
    1,
    30,
    false,
    nil)
