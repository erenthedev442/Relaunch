-----------------------------------
-- Relic Forge final-form catalog
-----------------------------------

local C = {}

C.repeatCurrencyCost = 750
C.repeatPlutonCost   = 500
C.plutonId           = 4059

C.weapons =
{
    { id = 20509, name = 'Spharai',        currency = 1456, currencyName = '100 Byne Bill',         highCurrency = 1457, highCurrencyName = '10,000 Byne Bill',       info = 'H2H relic. Native WS: Final Heaven.' },
    { id = 20583, name = 'Mandau',         currency = 1456, currencyName = '100 Byne Bill',         highCurrency = 1457, highCurrencyName = '10,000 Byne Bill',       info = 'Dagger relic. Native WS: Mercy Stroke.' },
    { id = 20685, name = 'Excalibur',      currency = 1453, currencyName = 'Montiont Silverpiece',  highCurrency = 1454, highCurrencyName = 'Ranperre Goldpiece',     info = 'Sword relic. Native WS: Knights of Round.' },
    { id = 21683, name = 'Ragnarok',       currency = 1453, currencyName = 'Montiont Silverpiece',  highCurrency = 1454, highCurrencyName = 'Ranperre Goldpiece',     info = 'Great Sword relic. Native WS: Scourge.' },
    { id = 21750, name = 'Guttler',        currency = 1450, currencyName = 'Lungo-Nango Jadeshell', highCurrency = 1451, highCurrencyName = 'Rimilala Stripeshell',    info = 'Axe relic. Native WS: Onslaught.' },
    { id = 21756, name = 'Bravura',        currency = 1456, currencyName = '100 Byne Bill',         highCurrency = 1457, highCurrencyName = '10,000 Byne Bill',       info = 'Great Axe relic. Native WS: Metatron Torment.' },
    { id = 21808, name = 'Apocalypse',     currency = 1450, currencyName = 'Lungo-Nango Jadeshell', highCurrency = 1451, highCurrencyName = 'Rimilala Stripeshell',    info = 'Scythe relic. Native WS: Catastrophe.' },
    { id = 21857, name = 'Gungnir',        currency = 1450, currencyName = 'Lungo-Nango Jadeshell', highCurrency = 1451, highCurrencyName = 'Rimilala Stripeshell',    info = 'Polearm relic. Native WS: Geirskogul.' },
    { id = 21906, name = 'Kikoku',         currency = 1456, currencyName = '100 Byne Bill',         highCurrency = 1457, highCurrencyName = '10,000 Byne Bill',       info = 'Katana relic. Native WS: Blade: Metsu.' },
    { id = 21954, name = 'Amanomurakumo',  currency = 1453, currencyName = 'Montiont Silverpiece',  highCurrency = 1454, highCurrencyName = 'Ranperre Goldpiece',     info = 'Great Katana relic. Native WS: Tachi: Kaiten.' },
    { id = 21077, name = 'Mjollnir',       currency = 1453, currencyName = 'Montiont Silverpiece',  highCurrency = 1454, highCurrencyName = 'Ranperre Goldpiece',     info = 'Club relic. Native WS: Randgrith.' },
    { id = 22060, name = 'Claustrum',      currency = 1450, currencyName = 'Lungo-Nango Jadeshell', highCurrency = 1451, highCurrencyName = 'Rimilala Stripeshell',    info = 'Staff relic. Native WS: Gate of Tartarus.' },
    { id = 22129, name = 'Yoichinoyumi',   currency = 1453, currencyName = 'Montiont Silverpiece',  highCurrency = 1454, highCurrencyName = 'Ranperre Goldpiece',     info = 'Bow relic. Native WS: Namas Arrow. Forging also grants Yoichi\'s Quiver.', companions = { 26343 } },
    { id = 22140, name = 'Annihilator',    currency = 1456, currencyName = '100 Byne Bill',         highCurrency = 1457, highCurrencyName = '10,000 Byne Bill',       info = 'Gun relic. Native WS: Coronach.' },
    { id = 11927, name = 'Aegis',          currency = 1453, currencyName = 'Montiont Silverpiece',  highCurrency = 1454, highCurrencyName = 'Ranperre Goldpiece',     info = 'Shield relic. Defensive support relic.' },
    { id = 18840, name = 'Gjallarhorn',    currency = 1450, currencyName = 'Lungo-Nango Jadeshell', highCurrency = 1451, highCurrencyName = 'Rimilala Stripeshell',    info = 'Horn relic. All Songs support relic. (BRD)' },
}

function C.companionsFor(itemId)
    for _, weapon in ipairs(C.weapons) do
        if weapon.id == itemId then
            return weapon.companions or {}
        end
    end

    return {}
end

function C.companionSlotNeed(player, itemId)
    local need = 0
    for _, extraId in ipairs(C.companionsFor(itemId)) do
        if player:getItemCount(extraId) < 1 then
            need = need + 1
        end
    end

    return need
end

-- swappingWeapon: the forge consumes one weapon and hands another (net-zero slots).
function C.grantSlotNeed(player, itemId, swappingWeapon)
    local extras = C.companionSlotNeed(player, itemId)
    if swappingWeapon then
        return math.max(1, extras)
    end

    return 1 + extras
end

function C.grantCompanions(player, itemId, channelTag)
    local granted = 0
    for _, extraId in ipairs(C.companionsFor(itemId)) do
        if player:getItemCount(extraId) < 1 then
            if not player:addItem({ id = extraId, quantity = 1 }) then
                player:printToPlayer(
                    string.format('[%s] Free a slot for the companion item and talk to me again.', channelTag),
                    xi.msg.channel.SYSTEM_3)
                return granted, false
            end

            granted = granted + 1
            if extraId == 26343 then
                player:printToPlayer(
                    string.format('[%s] Yoichi\'s Quiver is included -- use it for Yoichi Arrows.', channelTag),
                    xi.msg.channel.SYSTEM_3)
            end
        end
    end

    return granted, true
end

return C
