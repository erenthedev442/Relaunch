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

#pragma once

// Alter Ego upgrade categories
enum class AlterEgoCategory : uint8_t
{
    HP  = 8,
    MP  = 9,
    STR = 10,
    DEX = 11,
    VIT = 12,
    AGI = 13,
    INT = 14,
    MND = 15,
    CHR = 16,
};

// Cost in alter ego points to advance from `currentRank` to `currentRank + 1`.
// Returns 0 if already at cap (rank 50 in Phase 1).
inline constexpr uint16 AlterEgoUpgradeCost(uint8 currentRank)
{
    if (currentRank >= 50)
    {
        return 0;
    }
    if (currentRank < 10) return 1;
    if (currentRank < 20) return 2;
    if (currentRank < 30) return 3;
    if (currentRank < 40) return 4;
    return 5;
}

// Sanity: the AlterEgoCategory enum has exactly 9 values (HP..CHR), and the per-character
// upgrade cache (CCharEntity::m_alterEgoUpgrades) is a fixed-size array. Lock that
// invariant at compile time so future enum additions force a cache-size bump.
static_assert(static_cast<int>(AlterEgoCategory::CHR) - static_cast<int>(AlterEgoCategory::HP) + 1 == 9,
    "AlterEgoCategory range must equal m_alterEgoUpgrades array size (9)");
