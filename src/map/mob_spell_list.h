/*
===========================================================================

  Copyright (c) 2010-2015 Darkstar Dev Teams

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

#include <vector>

#include "common/cbasetypes.h"

#include "spell.h"

// Upper bound for spell_list_id rows LoadMobSpellList() will read. Custom content on
// this server numbers a trust's spell/skill lists to match its mob_pools poolid (6xxx),
// so the old 5000 bound silently dropped those lists at boot and left the mob with a
// null m_SpellListContainer (crashed the map via spell::CanUseSpell -- Matsui-P, 2026-09-01).
#define MAX_MOBSPELLLIST_ID 65535

typedef struct
{
    SpellID spellId;
    uint16  min_level;
    uint16  max_level;
} MobSpell_t;

class CMobSpellList
{
public:
    CMobSpellList(uint16 listId);

    auto getId() const -> uint16;

    void AddSpell(SpellID spellId, uint16 minLvl, uint16 maxLvl);
    auto GetSpellMinLevel(SpellID spellId) const -> uint16;

    // main spell list
    std::vector<MobSpell_t> m_spellList;

private:
    uint16 m_listId{};
};

namespace mobSpellList
{

void LoadMobSpellList();

auto GetMobSpellList(uint16 mobSpellListId) -> CMobSpellList*;

}; // namespace mobSpellList
