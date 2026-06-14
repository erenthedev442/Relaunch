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

#include "0x08e_alter_ego_points.h"

#include "enums/alter_ego_points.h"
#include "utils/charutils.h"

GP_SERV_PACKET_ALTER_EGO_POINTS::GP_SERV_PACKET_ALTER_EGO_POINTS(CCharEntity* PChar)
{
    auto& packet = this->data();

    packet.Points    = static_cast<uint16_t>(charutils::GetPoints(PChar, "alter_ego_points"));
    packet.padding00 = 0;

    for (auto& upgrade : packet.Upgrades) { upgrade = 0; }
    for (auto& cost    : packet.Costs)    { cost    = 0; }

    // Populate SPARSE indices 8..16 (HP..CHR). Confirmed by re-decoding the retail
    // 0x08E capture from 2026-05-04: ones land at byte offsets corresponding to
    // Costs[8..16], not Costs[0..8]. Indices 0..7 and 17..31 stay zero.
    // Cache lookup still uses dense (category - 8) since m_alterEgoUpgrades is uint8[9].
    for (uint8 category = 8; category <= 16; ++category)
    {
        const auto rank = charutils::GetAlterEgoUpgrade(PChar, category);
        packet.Upgrades[category] = rank;
        packet.Costs[category]    = AlterEgoUpgradeCost(rank);
    }
}
