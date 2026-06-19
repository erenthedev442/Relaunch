/*
===========================================================================

  Copyright (c) 2022 LandSandBoat Dev Teams

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
#include "notoriety_container.h"

#include "enmity_container.h"
#include "entities/baseentity.h"
#include "entities/battleentity.h"
#include "entities/mobentity.h"

CNotorietyContainer::CNotorietyContainer(CBattleEntity* owner)
: m_POwner(owner)
{
}

std::set<CBattleEntity*>::iterator CNotorietyContainer::begin()
{
    TracyZoneScoped;
    return m_Lookup.begin();
}

std::set<CBattleEntity*>::iterator CNotorietyContainer::end()
{
    TracyZoneScoped;
    return m_Lookup.end();
}

void CNotorietyContainer::add(CBattleEntity* entity)
{
    TracyZoneScoped;
    if (m_POwner && entity && entity->allegiance != m_POwner->allegiance)
    {
        m_Lookup.insert(entity);
    }
}

void CNotorietyContainer::remove(CBattleEntity* entity)
{
    TracyZoneScoped;
    if (m_POwner && entity)
    {
        auto entity_itr = m_Lookup.find(entity);
        if (entity_itr != m_Lookup.end())
        {
            m_Lookup.erase(*entity_itr);
        }
    }
}

bool CNotorietyContainer::hasEnmity()
{
    TracyZoneScoped;
    // Make sure the container is up to date before reporting
    if (m_POwner && !m_Lookup.empty())
    {
        std::vector<CBattleEntity*> toRemove;
        for (CBattleEntity* entry : *this)
        {
            // FJB: a despawned entity can be left in this notoriety set as a
            // dangling pointer; the dynamic_cast below would then deref freed
            // memory's vtable and SIGSEGV -- the recurring hasEnmity() UAF that
            // surfaces via a player's magic-casting check (e.g. crafted 0x01A
            // CastMagic packets). IsEntityAlive() only looks the pointer up in
            // the live-entity registry BY VALUE, so it is safe on a dangling
            // pointer -- skip and purge the stale entry instead of casting it.
            if (!CBaseEntity::IsEntityAlive(entry))
            {
                toRemove.emplace_back(entry);
                continue;
            }
            if (auto* mob = dynamic_cast<CMobEntity*>(entry))
            {
                EnmityList_t* mobEnmityList   = mob->PEnmityContainer->GetEnmityList();
                bool          notOnEnmityList = mobEnmityList->find(static_cast<uint16>(m_POwner->id)) == mobEnmityList->end();
                if ((mob->isAlive() && notOnEnmityList) || mob->isDead())
                {
                    toRemove.emplace_back(entry);
                }
            }
        }

        for (CBattleEntity* entry : toRemove)
        {
            remove(entry);
        }
    }

    return !m_Lookup.empty();
}

std::size_t CNotorietyContainer::size()
{
    TracyZoneScoped;
    return m_Lookup.size();
}
