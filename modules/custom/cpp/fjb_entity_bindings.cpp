/************************************************************************
 * FJB entity Lua bindings
 *
 * Custom player:* bindings that were originally added in-place to
 * src/map/lua/lua_baseentity.cpp. Moved here so the stock file stays
 * closer to upstream and survives a LandSandBoat pull without conflicts
 * (same rationale + pattern as auto_spend_bindings.cpp). Runtime behavior
 * is identical — each lambda reproduces the original member-method body,
 * using the public GetBaseEntity() accessor instead of m_PBaseEntity.
 *
 * Bindings (all no-op on non-PC, matching the originals):
 *   player:setShopCurrency(itemID)        -- shop charges an inventory item
 *   player:setShopCurrencyVar(varName)    -- shop charges a CharVar (e.g. Infamy)
 *   player:setShopCurrencyName(curName)   -- shop charges a named char_points currency
 *   player:resetJobPoints()               -- wipe JP, refresh JP menu packet
 *   player:resetAlterEgoUpgrades()        -- clear Alter Ego Point ranks
 *   player:addTrait(traitID) / delTrait(traitID)
 *   player:sendCommandData()              -- push the COMMAND_DATA (0xAC) packet
 *
 * See CORE_PATCH_TRIAGE.md (extraction #2).
 ************************************************************************/

#include "map/utils/moduleutils.h"

#include "common/logging.h"

#include "map/entities/baseentity.h"
#include "map/entities/charentity.h"
#include "map/lua/lua_baseentity.h"
#include "map/job_points.h"
#include "map/trade_container.h"
#include "map/utils/charutils.h"

#include "map/packets/s2c/0x063_miscdata_job_points.h"
#include "map/packets/s2c/0x0ac_command_data.h"

class FJBEntityBindingsModule : public CPPModule
{
    void OnInit() override
    {
        // player:setShopCurrency(itemID) -- make the currently-built shop
        // charge this inventory item instead of gil (reset by shop Clean()).
        lua["CBaseEntity"]["setShopCurrency"] =
            [](CLuaBaseEntity& self, uint16 itemID) -> void
        {
            auto* entity = self.GetBaseEntity();
            if (entity == nullptr || entity->objtype != TYPE_PC)
            {
                return;
            }
            static_cast<CCharEntity*>(entity)->Container->setShopCurrency(itemID);
        };

        // player:setShopCurrencyVar(varName) -- shop charges a CharVar (e.g.
        // the dungeon "Infamy" currency). "" restores gil/item.
        lua["CBaseEntity"]["setShopCurrencyVar"] =
            [](CLuaBaseEntity& self, std::string varName) -> void
        {
            auto* entity = self.GetBaseEntity();
            if (entity == nullptr || entity->objtype != TYPE_PC)
            {
                return;
            }
            static_cast<CCharEntity*>(entity)->Container->setShopCurrencyVar(varName);
        };

        // player:setShopCurrencyName(curName) -- shop charges a named
        // char_points currency. "" restores gil/item.
        lua["CBaseEntity"]["setShopCurrencyName"] =
            [](CLuaBaseEntity& self, std::string curName) -> void
        {
            auto* entity = self.GetBaseEntity();
            if (entity == nullptr || entity->objtype != TYPE_PC)
            {
                return;
            }
            static_cast<CCharEntity*>(entity)->Container->setShopCurrencyName(curName);
        };

        // player:resetJobPoints() -- wipe all JP and refresh the JP menu.
        lua["CBaseEntity"]["resetJobPoints"] =
            [](CLuaBaseEntity& self) -> void
        {
            auto* entity = self.GetBaseEntity();
            if (entity == nullptr || entity->objtype != TYPE_PC)
            {
                return;
            }
            auto* PChar = static_cast<CCharEntity*>(entity);
            PChar->PJobPoints->ResetJobPoints();
            PChar->pushPacket<GP_SERV_COMMAND_MISCDATA::JOB_POINTS>(PChar);
        };

        // player:resetAlterEgoUpgrades() -- clear the Alter Ego Point ranks.
        lua["CBaseEntity"]["resetAlterEgoUpgrades"] =
            [](CLuaBaseEntity& self) -> void
        {
            auto* PChar = dynamic_cast<CCharEntity*>(self.GetBaseEntity());
            if (PChar == nullptr)
            {
                return;
            }
            charutils::ResetAlterEgoUpgrades(PChar);
        };

        // player:addTrait(traitID) / player:delTrait(traitID)
        lua["CBaseEntity"]["addTrait"] =
            [](CLuaBaseEntity& self, uint16 traitID) -> void
        {
            auto* entity = self.GetBaseEntity();
            if (entity == nullptr || entity->objtype != TYPE_PC)
            {
                ShowWarning("Invalid entity type calling addTrait.");
                return;
            }
            charutils::addTrait(static_cast<CCharEntity*>(entity), traitID);
        };

        lua["CBaseEntity"]["delTrait"] =
            [](CLuaBaseEntity& self, uint16 traitID) -> void
        {
            auto* entity = self.GetBaseEntity();
            if (entity == nullptr || entity->objtype != TYPE_PC)
            {
                ShowWarning("Invalid entity type calling delTrait.");
                return;
            }
            charutils::delTrait(static_cast<CCharEntity*>(entity), traitID);
        };

        // player:sendCommandData() -- push the COMMAND_DATA (0xAC) packet.
        lua["CBaseEntity"]["sendCommandData"] =
            [](CLuaBaseEntity& self) -> void
        {
            auto* entity = self.GetBaseEntity();
            if (entity == nullptr || entity->objtype != TYPE_PC)
            {
                ShowWarning("Invalid entity type calling sendCommandData.");
                return;
            }
            auto* PChar = static_cast<CCharEntity*>(entity);
            PChar->pushPacket<GP_SERV_COMMAND_COMMAND_DATA>(PChar);
        };

        ShowInfo("[fjb_entity_bindings] Registered 8 custom entity Lua bindings.");
    }
};

REGISTER_CPP_MODULE(FJBEntityBindingsModule);
