-----------------------------------
-- hades_trust_catalog.lua
--
-- Weekend Trusts stall. One alter ego per UTC week, same name for every
-- player. Farmable roster minus starters (Shantotto, Kupipi, Trion,
-- Tenzen), gil/completion names (Meat, Gemma, Corvus, Cornelia,
-- Matsui-P), and dead slots (Aldo / Aldo UC / Fujito-P / seasonal
-- Matsui). Grant goes through xi.trustGrant.grantSpell so the login
-- stripper keeps it.
-----------------------------------
local CATALOG_KEY = 'modules/custom/lua/hades_trust_catalog'
local C = package.loaded[CATALOG_KEY]
if type(C) ~= 'table' then
    C = {}
end
package.loaded[CATALOG_KEY] = C

C.WEEK_SALT    = 43
C.PRICE_NORMAL = 399
C.PRICE_RARE   = 699

-- Starters, gil/completion names, and ungrantable slots.
C.EXCLUDED =
{
    [896]  = true, -- Shantotto (starter)
    [898]  = true, -- Kupipi (starter)
    [899]  = true, -- Meat / Excenmille
    [901]  = true, -- Gemma / Nanaa Mihgo
    [902]  = true, -- Corvus / Curilla
    [905]  = true, -- Trion (starter)
    [908]  = true, -- Tenzen (starter)
    [930]  = true, -- Aldo (disabled)
    [1002] = true, -- Cornelia
    [1003] = true, -- seasonal Matsui (client crash)
    [1004] = true, -- Matsui-P
    [1007] = true, -- Aldo UC (disabled)
    [1020] = true, -- Fujito-P (no unlock yet)
}

C.RARE =
{
    [953]  = true, -- Pieuje UC
    [954]  = true, -- Invincible Shield UC
    [955]  = true, -- Apururu UC
    [956]  = true, -- Jakoh UC
    [957]  = true, -- Flaviria UC
    [978]  = true, -- Kupofried
    [980]  = true, -- Yoran-Oran UC
    [981]  = true, -- Sylvie UC
    [991]  = true, -- Darrcuiln
    [1005] = true, -- Ayame UC
    [1006] = true, -- Maat UC
    [1008] = true, -- Naja UC
    [1013] = true, -- Lilisette II
    [1018] = true, -- Iroha II
    [1019] = true, -- Shantotto II
}

-- collectionRoster minus the four starters. Shop-length names.
C.items =
{
    { spellId =  897, name = 'Naji' },
    { spellId =  900, name = 'Ayame' },
    { spellId =  903, name = 'Volker' },
    { spellId =  904, name = 'Ajido-Marujido' },
    { spellId =  906, name = 'Zeid' },
    { spellId =  907, name = 'Lion' },
    { spellId =  909, name = 'Mihli Aliapoh' },
    { spellId =  910, name = 'Valaineral' },
    { spellId =  911, name = 'Joachim' },
    { spellId =  912, name = 'Naja Salaheem' },
    { spellId =  913, name = 'Prishe' },
    { spellId =  914, name = 'Ulmia' },
    { spellId =  915, name = 'Shikaree Z' },
    { spellId =  916, name = 'Cherukiki' },
    { spellId =  917, name = 'Iron Eater' },
    { spellId =  918, name = 'Gessho' },
    { spellId =  919, name = 'Gadalar' },
    { spellId =  920, name = 'Rainemard' },
    { spellId =  921, name = 'Ingrid' },
    { spellId =  922, name = 'Lehko Habhoka' },
    { spellId =  923, name = 'Nashmeira' },
    { spellId =  924, name = 'Zazarg' },
    { spellId =  925, name = 'Ovjang' },
    { spellId =  926, name = 'Mnejing' },
    { spellId =  927, name = 'Sakura' },
    { spellId =  928, name = 'Luzaf' },
    { spellId =  929, name = 'Najelith' },
    { spellId =  931, name = 'Moogle' },
    { spellId =  932, name = 'Fablinix' },
    { spellId =  933, name = 'Maat' },
    { spellId =  934, name = 'Domina Shantotto' },
    { spellId =  935, name = 'Star Sibyl' },
    { spellId =  936, name = 'Karaha-Baruha' },
    { spellId =  937, name = 'Cid' },
    { spellId =  938, name = 'Gilgamesh' },
    { spellId =  939, name = 'Areuhat' },
    { spellId =  940, name = 'Semih Lafihna' },
    { spellId =  941, name = 'Elvira' },
    { spellId =  942, name = 'Noillurie' },
    { spellId =  943, name = 'Lhu Mhakaracca' },
    { spellId =  944, name = 'Ferreous Coffin' },
    { spellId =  945, name = 'Lilisette' },
    { spellId =  946, name = 'Mumor' },
    { spellId =  947, name = 'Uka Totlihn' },
    { spellId =  948, name = 'Klara' },
    { spellId =  949, name = 'Romaa Mihgo' },
    { spellId =  950, name = 'Kuyin Hathdenna' },
    { spellId =  951, name = 'Rahal' },
    { spellId =  952, name = 'Koru-Moru' },
    { spellId =  953, name = 'Pieuje UC' },
    { spellId =  954, name = 'Inv. Shield UC' },
    { spellId =  955, name = 'Apururu UC' },
    { spellId =  956, name = 'Jakoh UC' },
    { spellId =  957, name = 'Flaviria UC' },
    { spellId =  958, name = 'Babban' },
    { spellId =  959, name = 'Abenzio' },
    { spellId =  960, name = 'Rughadjeen' },
    { spellId =  961, name = 'Kukki-Chebukki' },
    { spellId =  962, name = 'Margret' },
    { spellId =  963, name = 'Chacharoon' },
    { spellId =  964, name = 'Lhe Lhangavo' },
    { spellId =  965, name = 'Arciela' },
    { spellId =  966, name = 'Mayakov' },
    { spellId =  967, name = 'Qultada' },
    { spellId =  968, name = 'Adelheid' },
    { spellId =  969, name = 'Amchuchu' },
    { spellId =  970, name = 'Brygid' },
    { spellId =  971, name = 'Mildaurion' },
    { spellId =  972, name = 'Halver' },
    { spellId =  973, name = 'Rongelouts' },
    { spellId =  974, name = 'Leonoyne' },
    { spellId =  975, name = 'Maximilian' },
    { spellId =  976, name = 'Kayeel-Payeel' },
    { spellId =  977, name = 'Robel-Akbel' },
    { spellId =  978, name = 'Kupofried' },
    { spellId =  979, name = 'Selh\'teus' },
    { spellId =  980, name = 'Yoran-Oran UC' },
    { spellId =  981, name = 'Sylvie UC' },
    { spellId =  982, name = 'Abquhbah' },
    { spellId =  983, name = 'Balamor' },
    { spellId =  984, name = 'August' },
    { spellId =  985, name = 'Rosulatia' },
    { spellId =  986, name = 'Teodor' },
    { spellId =  987, name = 'Ullegore' },
    { spellId =  988, name = 'Makki-Chebukki' },
    { spellId =  989, name = 'King of Hearts' },
    { spellId =  990, name = 'Morimar' },
    { spellId =  991, name = 'Darrcuiln' },
    { spellId =  992, name = 'AAHM' },
    { spellId =  993, name = 'AAEV' },
    { spellId =  994, name = 'AAMR' },
    { spellId =  995, name = 'AATT' },
    { spellId =  996, name = 'AAGK' },
    { spellId =  997, name = 'Iroha' },
    { spellId =  998, name = 'Ygnas' },
    { spellId =  999, name = 'Monberaux' },
    { spellId = 1005, name = 'Ayame UC' },
    { spellId = 1006, name = 'Maat UC' },
    { spellId = 1008, name = 'Naja UC' },
    { spellId = 1009, name = 'Lion II' },
    { spellId = 1010, name = 'Zeid II' },
    { spellId = 1011, name = 'Prishe II' },
    { spellId = 1012, name = 'Nashmeira II' },
    { spellId = 1013, name = 'Lilisette II' },
    { spellId = 1014, name = 'Tenzen II' },
    { spellId = 1015, name = 'Mumor II' },
    { spellId = 1016, name = 'Ingrid II' },
    { spellId = 1017, name = 'Arciela II' },
    { spellId = 1018, name = 'Iroha II' },
    { spellId = 1019, name = 'Shantotto II' },
}

C.bySpellId = {}
for _, row in ipairs(C.items) do
    row.rare  = C.RARE[row.spellId] == true
    row.price = row.rare and C.PRICE_RARE or C.PRICE_NORMAL
    C.bySpellId[row.spellId] = row
end

function C.weeklyTrust(weekId, pinSpellId)
    if pinSpellId and C.bySpellId[pinSpellId] then
        return C.bySpellId[pinSpellId]
    end
    local n = #C.items
    if n == 0 then
        return nil
    end
    weekId = weekId or tonumber(os.date('!%Y%W'))
    return C.items[(((weekId or 0) * C.WEEK_SALT) % n) + 1]
end

function C.owns(player, row)
    if not player or not row or not row.spellId then
        return false
    end
    local ok, has = pcall(function()
        return player:hasSpell(row.spellId)
    end)
    return ok and has == true
end

function C.award(player, row)
    if not player or not row or not row.spellId then
        return false
    end
    if C.owns(player, row) then
        return false
    end
    if not xi.trustGrant or not xi.trustGrant.grantSpell then
        return false
    end
    return xi.trustGrant.grantSpell(player, row.spellId) == true
end

return C
