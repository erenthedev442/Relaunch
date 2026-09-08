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

#include "0x119_abil_recast.h"

#include "common/timer.h"

#include <cstring>
#include <mutex>
#include <unordered_set>

#include "ability.h"
#include "entities/charentity.h"
#include "recast_container.h"

GP_SERV_COMMAND_ABIL_RECAST::GP_SERV_COMMAND_ABIL_RECAST(CCharEntity* PChar)
{
    auto& packet = this->data();

    uint8               count      = 1;
    const RecastList_t* RecastList = PChar->PRecastContainer->GetRecastList(RECAST_ABILITY);
    for (auto&& recast : *RecastList)
    {
        const auto remaining     = recast.RecastTime == 0s ? 0s : std::chrono::ceil<std::chrono::seconds>(recast.TimeStamp - timer::now() + recast.RecastTime);
        const auto recastSeconds = static_cast<uint32>(std::max<int64>(timer::count_seconds(remaining), 0));

        if (recast.ID == Recast::Mount) // borrowing this id for mount recast
        {
            packet.MountRecast   = recastSeconds;
            packet.MountRecastId = static_cast<uint32_t>(recast.ID);
        }
        else if (recast.ID != Recast::Special)
        {
            packet.Timers[count].Timer   = recastSeconds;
            packet.Timers[count].TimerId = static_cast<uint8_t>(recast.ID);

            if (recast.maxCharges != 0)
            {
                if (const auto* charge = ability::GetCharge(PChar, static_cast<uint16>(recast.ID)))
                {
                    const uint16_t actualChargeTime = timer::count_seconds(recast.chargeTime);
                    const uint16_t baseChargeTime   = timer::count_seconds(charge->chargeTime);

                    if (baseChargeTime > actualChargeTime)
                    {
                        packet.Timers[count].Calc1 = 0; // Not used in Ready, QD, Stratagems... Is this never used?
                        packet.Timers[count].Calc2 = 65536 - (baseChargeTime - actualChargeTime) * recast.maxCharges;
                    }
                }
            }
            count++;
        }
        else // 2hr edge case // TODO: retail uses Calc2 on 2hr for some reason...
        {
            packet.Timers[0].Timer   = recastSeconds;
            packet.Timers[0].TimerId = 0;
        }

        // Retail currently only allows 31 distinct recasts to be sent in the packet
        // Reject 32 abilities and higher (zero-indexed)
        // This may change with Master Levels, as there is some padding that appears to be not used for each recast that could be removed to add more abilities.
        if (count > 30)
        {
            // Warn ONCE per character, not once per packet build. This is a hard
            // client limit, not a server fault: the 0x119 format carries 31 recast
            // slots and we correctly send the first 31. On a server that unlocks
            // every job, a geared player exceeds 31 recasts routinely and this
            // packet is rebuilt constantly -- it produced ~4,800 warnings a day
            // from two characters, which is pure noise around a condition nobody
            // can act on, and it buries warnings that do matter.
            static std::mutex              s_warnedMutex;
            static std::unordered_set<uint32> s_warnedChars;
            {
                std::lock_guard<std::mutex> lock(s_warnedMutex);
                if (s_warnedChars.insert(PChar->id).second)
                {
                    ShowWarning("GP_SERV_COMMAND_ABIL_RECAST: '%s' has more than 31 abilities on recast; "
                                "only the first 31 fit the packet. Client format limit -- expected on this "
                                "server, logged once per character.", PChar->getName());
                }
            }
            break;
        }
    }
}
