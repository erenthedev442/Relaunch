/*
===========================================================================

  Copyright (c) 2026 LandSandBoat Dev Teams

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

#include "0x0c1_alter_ego_points.h"

#include "entities/charentity.h"
#include "enums/alter_ego_points.h"
#include "packets/s2c/0x029_battle_message.h"
#include "packets/s2c/0x08e_alter_ego_points.h"
#include "utils/charutils.h"

auto GP_CLI_COMMAND_ALTER_EGO_POINTS::validate(MapSession* PSession, const CCharEntity* PChar) const
    -> PacketValidationResult
{
    return PacketValidator(PChar)
        .blockedBy({ BlockedState::InEvent, BlockedState::AbnormalStatus })
        .oneOf<AlterEgoCategory>(this->CategoryIndex)
        .isInMogHouse()
        .hasKeyItem(KeyItem::CIPHER_BRACELET)
        .custom([&](PacketValidator& v)
                {
                    if (PChar->GetMLevel() < 99)
                    {
                        v.mustEqual(true, false, "Main job must be Level 99");
                    }
                });
}

void GP_CLI_COMMAND_ALTER_EGO_POINTS::process(MapSession* PSession, CCharEntity* PChar) const
{
    const auto category = static_cast<uint8>(this->CategoryIndex);

    const auto currentRank = charutils::GetAlterEgoUpgrade(PChar, category);
    if (currentRank >= 50)
    {
        // At cap — silently re-sync client and bail.
        PChar->pushPacket<GP_SERV_PACKET_ALTER_EGO_POINTS>(PChar);
        return;
    }

    const auto cost          = AlterEgoUpgradeCost(currentRank);
    const auto currentPoints = charutils::GetPoints(PChar, "alter_ego_points");
    if (currentPoints < cost)
    {
        // Insufficient funds — silently re-sync.
        PChar->pushPacket<GP_SERV_PACKET_ALTER_EGO_POINTS>(PChar);
        return;
    }

    const auto newRank = static_cast<uint8>(currentRank + 1);
    charutils::AddPoints(PChar, "alter_ego_points", -static_cast<int32>(cost));
    charutils::SetAlterEgoUpgrade(PChar, category, newRank);

    ShowInfoFmt("AEP upgrade: {} category={} {}->{} cost={}",
                PChar->getName(), category, currentRank, newRank, cost);

    PChar->pushPacket<GP_SERV_COMMAND_BATTLE_MESSAGE>(
        PChar, PChar, this->CategoryIndex, newRank, MsgBasic::AlterEgoUpgrade);
    PChar->pushPacket<GP_SERV_PACKET_ALTER_EGO_POINTS>(PChar);
}
