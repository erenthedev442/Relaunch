-----------------------------------
-- Descension (Arciela II)
-- Dark-mode pulse: Dark magical damage. Script-invoked on 90s swap.
-----------------------------------
local arciela = require('scripts/actions/mobskills/_arciela_ii_skill')

return arciela.magical(xi.element.DARK, xi.damageType.DARK, 2.5)
