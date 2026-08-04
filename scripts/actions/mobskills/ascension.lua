-----------------------------------
-- Ascension (Arciela II)
-- Light-mode pulse: Light magical damage. Script-invoked on 90s swap.
-----------------------------------
local arciela = require('scripts/actions/mobskills/_arciela_ii_skill')

return arciela.magical(xi.element.LIGHT, xi.damageType.LIGHT, 2.5)
