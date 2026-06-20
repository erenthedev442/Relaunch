/*
===========================================================================

  Copyright (c) 2025 LandSandBoat Dev Teams

  This program is free software: you can redistribute it and/or modify
  it under the terms of the GNU General Public License as published by
  the Free Software Foundation, either version 3 of the License, or
  (at your option) any later version.

  This program is distributed in the hope that it will be useful,
  but WITHOUT ANY WARRANTY; without even the implied warranty of
  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
  GNU General Public License for more details.

  You should have received a copy of the GNU General Public License
  along with this program.  If not, see http://www.gnu.org/licenses/

===========================================================================
*/

#include "0x083_shop_buy.h"

#include "entities/charentity.h"
#include "packets/s2c/0x01d_item_same.h"
#include "packets/s2c/0x03f_shop_buy.h"
#include "trade_container.h"
#include "utils/charutils.h"
#include "utils/itemutils.h"

auto GP_CLI_COMMAND_SHOP_BUY::validate(MapSession* PSession, const CCharEntity* PChar) const -> PacketValidationResult
{
    return PacketValidator(PChar)
        .blockedBy({ BlockedState::InEvent })
        .mustEqual(this->PropertyItemIndex, 0, "PropertyItemIndex not 0");
}

void GP_CLI_COMMAND_SHOP_BUY::process(MapSession* PSession, CCharEntity* PChar) const
{
    auto quantity = this->ItemNum;

    // Prevent users from buying from invalid container slots
    if (this->ShopItemIndex > PChar->Container->getExSize() - 1)
    {
        ShowError("User '%s' attempting to buy vendor item from an invalid slot!", PChar->getName());
        return;
    }

    const uint16 itemId = PChar->Container->getItemID(this->ShopItemIndex);
    const uint32 price  = PChar->Container->getQuantity(this->ShopItemIndex); // We used the "quantity" to store the item's sale price

    const CItem* PItem = xi::items::lookup(itemId);
    if (!PItem)
    {
        ShowWarning("User '%s' attempting to buy an invalid item from vendor!", PChar->getName());
        return;
    }

    // Prevent purchasing larger stacks than the actual stack size in database.
    if (quantity > PItem->getStackSize())
    {
        quantity = PItem->getStackSize();
    }

    // FJB: named-CURRENCY shops (a char_points currency like "allied_notes" -- the
    // cosmetic Boutique). Neither gil, an inventory item, nor a CharVar. A vendor's
    // Lua opts in via player:setShopCurrencyName("allied_notes"); createShop()/Clean()
    // resets it. Checked first so it takes precedence over everything below.
    const std::string& currencyName = PChar->Container->getShopCurrencyName();
    if (!currencyName.empty())
    {
        const uint32 totalCost = price * quantity;
        const int32  balance   = charutils::GetPoints(PChar, currencyName.c_str());
        if (balance >= 0 && static_cast<uint32>(balance) >= totalCost)
        {
            if (charutils::AddItem(PChar, LOC_INVENTORY, itemId, quantity) != ERROR_SLOTID)
            {
                charutils::AddPoints(PChar, currencyName.c_str(), -static_cast<int32>(totalCost));
                ShowInfo("User '%s' bought %u of item %u [VENDOR, currency %s]", PChar->getName(), quantity, itemId, currencyName.c_str());
                PChar->pushPacket<GP_SERV_COMMAND_SHOP_BUY>(this->ShopItemIndex, quantity);
                PChar->pushPacket<GP_SERV_COMMAND_ITEM_SAME>(PChar);
            }
        }
        return;
    }

    // FJB: CharVar-currency shops (e.g. the dungeon Infamy Vendor) charge a named
    // CharVar instead of an inventory item or gil. A vendor's Lua opts in via
    // player:setShopCurrencyVar("Infamy"); createShop()/Clean() resets it. Checked
    // first so it takes precedence over the item-currency and gil paths below.
    const std::string& currencyVar = PChar->Container->getShopCurrencyVar();
    if (!currencyVar.empty())
    {
        const uint32 totalCost = price * quantity;
        const int32  balance   = PChar->getCharVar(currencyVar);
        if (balance >= 0 && static_cast<uint32>(balance) >= totalCost)
        {
            if (charutils::AddItem(PChar, LOC_INVENTORY, itemId, quantity) != ERROR_SLOTID)
            {
                PChar->setCharVar(currencyVar, balance - static_cast<int32>(totalCost));
                ShowInfo("User '%s' bought %u of item %u [VENDOR, charvar %s]", PChar->getName(), quantity, itemId, currencyVar.c_str());
                PChar->pushPacket<GP_SERV_COMMAND_SHOP_BUY>(this->ShopItemIndex, quantity);
                PChar->pushPacket<GP_SERV_COMMAND_ITEM_SAME>(PChar);
            }
        }
        return;
    }

    // FJB: custom-currency shops (Hunting League seal/medal vendors, etc.) charge
    // a configured inventory item instead of gil. createShop()/Clean() resets the
    // currency to 0 (gil); a vendor's Lua opts in via player:setShopCurrency(id).
    const uint16 currencyItem = PChar->Container->getShopCurrency();
    if (currencyItem != 0)
    {
        const uint32 totalCost = price * quantity;
        if (charutils::getItemCount(PChar, currencyItem) >= totalCost)
        {
            if (charutils::AddItem(PChar, LOC_INVENTORY, itemId, quantity) != ERROR_SLOTID)
            {
                // Charge the currency across EVERY stack and container that the
                // getItemCount check above counts. The old code debited only the
                // first stack of main inventory -- and charutils::UpdateItem
                // debits nothing when the cost exceeds that one stack -- so a
                // buyer whose medals were in the mog safe, or split across
                // 99-stacks, was never charged while the item was handed over.
                uint32 remaining = totalCost;
                for (uint8 loc = 0; loc < CONTAINER_ID::MAX_CONTAINER_ID && remaining > 0; ++loc)
                {
                    CItemContainer* PCurrencyBag = PChar->getStorage(loc);
                    if (PCurrencyBag == nullptr)
                    {
                        continue;
                    }

                    for (const uint8 slotID : PCurrencyBag->SearchItems(currencyItem))
                    {
                        if (remaining == 0)
                        {
                            break;
                        }

                        CItem* PCurrency = PCurrencyBag->GetItem(slotID);
                        if (PCurrency == nullptr)
                        {
                            continue;
                        }

                        const uint32 available = PCurrency->getQuantity() - PCurrency->getReserve();
                        const uint32 take      = available < remaining ? available : remaining;
                        if (take > 0)
                        {
                            charutils::UpdateItem(PChar, loc, slotID, -static_cast<int32>(take));
                            remaining -= take;
                        }
                    }
                }

                ShowInfo("User '%s' bought %u of item %u [VENDOR, currency %u]", PChar->getName(), quantity, itemId, currencyItem);
                PChar->pushPacket<GP_SERV_COMMAND_SHOP_BUY>(this->ShopItemIndex, quantity);
                PChar->pushPacket<GP_SERV_COMMAND_ITEM_SAME>(PChar);
            }
        }
        return;
    }

    const CItem* gil = PChar->getStorage(LOC_INVENTORY)->GetItem(0);

    if (!gil || !gil->isType(ITEM_CURRENCY) || gil->getReserve() != 0)
    {
        ShowError("User '%s' has invalid gil", PChar->getName());
        return;
    }

    if (gil->getQuantity() >= (price * quantity))
    {
        if (charutils::AddItem(PChar, LOC_INVENTORY, itemId, quantity) != ERROR_SLOTID)
        {
            charutils::UpdateItem(PChar, LOC_INVENTORY, 0, -static_cast<int32>(price * quantity));
            ShowInfo("User '%s' purchased %u of item of ID %u [from VENDOR] ", PChar->getName(), quantity, itemId);
            PChar->pushPacket<GP_SERV_COMMAND_SHOP_BUY>(this->ShopItemIndex, quantity);
            PChar->pushPacket<GP_SERV_COMMAND_ITEM_SAME>(PChar);
        }
    }
}
