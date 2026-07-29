/************************************************************************
 * Arcane Augmenter catalyst-bank bindings.
 *
 * Exposes:
 *   player:depositAugmentCatalyst(itemId, quantity) -> new balance (0 = error)
 *   player:depositAugmentCatalysts(requests)        -> bool
 *   player:getAugmentCatalystBalances()             -> { [itemId] = quantity }
 *   player:consumeAugmentCatalysts(requests)        -> bool
 *
 * `requests` is an array of { id = itemId, qty = quantity }. Consumption is
 * one database transaction: either every requested catalyst is deducted or
 * none are. Lua validates item IDs against augment_catalog.lua; these bindings
 * provide durable storage and race-safe quantity changes.
 ************************************************************************/

#include "map/utils/moduleutils.h"

#include "common/database.h"
#include "common/logging.h"

#include "map/entities/baseentity.h"
#include "map/entities/charentity.h"
#include "map/lua/lua_baseentity.h"

#include <stdexcept>
#include <utility>
#include <vector>

namespace
{
    CCharEntity* getChar(CLuaBaseEntity& self)
    {
        auto* entity = self.GetBaseEntity();
        if (entity == nullptr || entity->objtype != TYPE_PC)
        {
            return nullptr;
        }

        return static_cast<CCharEntity*>(entity);
    }

    bool parseRequests(sol::table requests, std::vector<std::pair<uint16, uint32>>& parsed)
    {
        for (const auto& pair : requests)
        {
            const sol::object value = pair.second;
            if (!value.is<sol::table>())
            {
                return false;
            }

            const sol::table request  = value.as<sol::table>();
            const uint16     itemId   = request.get_or<uint16>("id", 0);
            const uint32     quantity = request.get_or<uint32>("qty", 0);
            if (itemId == 0 || quantity == 0)
            {
                return false;
            }

            parsed.emplace_back(itemId, quantity);
        }

        return !parsed.empty();
    }
}

class AugmentCatalystBankBindingsModule : public CPPModule
{
    void OnInit() override
    {
        lua["CBaseEntity"]["depositAugmentCatalyst"] =
            [](CLuaBaseEntity& self, uint16 itemId, uint32 quantity) -> uint32
        {
            auto* PChar = getChar(self);
            if (PChar == nullptr || itemId == 0 || quantity == 0)
            {
                return 0;
            }

            const auto update = db::preparedStmt(
                "INSERT INTO char_augment_catalysts (charid, itemid, quantity) "
                "VALUES (?, ?, ?) "
                "ON DUPLICATE KEY UPDATE quantity = LEAST(4294967295, quantity + VALUES(quantity))",
                PChar->id, itemId, quantity);
            if (!update)
            {
                return 0;
            }

            const auto balance = db::preparedStmt(
                "SELECT quantity FROM char_augment_catalysts WHERE charid = ? AND itemid = ?",
                PChar->id, itemId);
            if (!balance || !balance->next())
            {
                return 0;
            }

            return balance->get<uint32>("quantity");
        };

        lua["CBaseEntity"]["depositAugmentCatalysts"] =
            [](CLuaBaseEntity& self, sol::table requests) -> bool
        {
            auto* PChar = getChar(self);
            if (PChar == nullptr)
            {
                return false;
            }

            std::vector<std::pair<uint16, uint32>> parsed;
            if (!parseRequests(requests, parsed))
            {
                return false;
            }

            return db::transaction([&]()
            {
                for (const auto& [itemId, quantity] : parsed)
                {
                    const auto update = db::preparedStmt(
                        "INSERT INTO char_augment_catalysts (charid, itemid, quantity) "
                        "VALUES (?, ?, ?) "
                        "ON DUPLICATE KEY UPDATE quantity = LEAST(4294967295, quantity + VALUES(quantity))",
                        PChar->id, itemId, quantity);
                    if (!update)
                    {
                        throw std::runtime_error("Could not deposit Arcane Augmenter catalysts");
                    }
                }
            });
        };

        lua["CBaseEntity"]["getAugmentCatalystBalances"] =
            [](CLuaBaseEntity& self) -> sol::table
        {
            sol::table result = ::lua.create_table();
            auto*      PChar  = getChar(self);
            if (PChar == nullptr)
            {
                return result;
            }

            const auto balances = db::preparedStmt(
                "SELECT itemid, quantity FROM char_augment_catalysts "
                "WHERE charid = ? AND quantity > 0 ORDER BY itemid",
                PChar->id);
            if (balances)
            {
                while (balances->next())
                {
                    result[balances->get<uint16>("itemid")] = balances->get<uint32>("quantity");
                }
            }

            return result;
        };

        lua["CBaseEntity"]["consumeAugmentCatalysts"] =
            [](CLuaBaseEntity& self, sol::table requests) -> bool
        {
            auto* PChar = getChar(self);
            if (PChar == nullptr)
            {
                return false;
            }

            std::vector<std::pair<uint16, uint32>> parsed;
            if (!parseRequests(requests, parsed))
            {
                return false;
            }

            return db::transaction([&]()
            {
                for (const auto& [itemId, quantity] : parsed)
                {
                    const auto deduct = db::preparedStmt(
                        "UPDATE char_augment_catalysts SET quantity = quantity - ? "
                        "WHERE charid = ? AND itemid = ? AND quantity >= ?",
                        quantity, PChar->id, itemId, quantity);
                    if (!deduct || deduct->rowsAffected() != 1)
                    {
                        throw std::runtime_error("Insufficient Arcane Augmenter catalyst balance");
                    }
                }

                db::preparedStmt(
                    "DELETE FROM char_augment_catalysts WHERE charid = ? AND quantity = 0",
                    PChar->id);
            });
        };

        ShowInfo("[augment_catalyst_bank] Registered deposit/batch/balance/consume Lua bindings.");
    }
};

REGISTER_CPP_MODULE(AugmentCatalystBankBindingsModule);
