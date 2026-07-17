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

#include "0x017_charreq2.h"

#include "entities/charentity.h"

auto GP_CLI_COMMAND_CHARREQ2::validate(MapSession* PSession, const CCharEntity* PChar) const -> PacketValidationResult
{
    // Not implemented.
    return PacketValidator(PChar)
        .blockedBy({ BlockedState::InEvent });
}

void GP_CLI_COMMAND_CHARREQ2::process(MapSession* PSession, CCharEntity* PChar) const
{
    // Demoted 2026-07-16: client polls Voidwatch/mission NPCs with non-standard
    // type codes the engine doesn't map to a TYPE_ enum (e.g. Pursuivant with
    // Flg=27). Server ignores the mismatch and returns the NPC anyway, so this
    // is client/engine noise, not a data bug. Kept as Debug for diagnostics.
    ShowDebug("GP_CLI_COMMAND_CHARREQ2: Incorrect NPC(%u,%u) type(%u)", this->ActIndex, this->UniqueNo2, this->Flg);
}
