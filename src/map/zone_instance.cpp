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

#include "zone_instance.h"
#include "ai/ai_container.h"
#include "common/logging.h"
#include "common/timer.h"
#include "entities/charentity.h"
#include "lua/luautils.h"
#include "status_effect_container.h"
#include "utils/charutils.h"
#include "utils/zoneutils.h"

#include <algorithm>

CZoneInstance::CZoneInstance(Scheduler& scheduler, MapConfig config, ZONEID ZoneID, REGION_TYPE RegionID, CONTINENT_TYPE ContinentID, uint8 levelRestriction)
: CZone(scheduler, config, ZoneID, RegionID, ContinentID, levelRestriction)
{
    TracyZoneScoped;
}

CZoneInstance::~CZoneInstance()
{
    TracyZoneScoped;
}

bool CZoneInstance::IsHybrid()
{
    return (GetTypeMask() & ZONE_TYPE::HYBRID_INSTANCED) != 0;
}

CCharEntity* CZoneInstance::GetCharByName(const std::string& name)
{
    TracyZoneScoped;
    CCharEntity* PEntity = IsHybrid() ? CZone::GetCharByName(name) : nullptr;
    if (PEntity)
    {
        return PEntity;
    }
    for (const auto& PInstance : m_InstanceList)
    {
        PEntity = PInstance->GetCharByName(name);
        if (PEntity)
        {
            break;
        }
    }
    return PEntity;
}

CCharEntity* CZoneInstance::GetCharByID(uint32 id)
{
    TracyZoneScoped;
    CCharEntity* PEntity = IsHybrid() ? CZone::GetCharByID(id) : nullptr;
    if (PEntity)
    {
        return PEntity;
    }
    for (const auto& PInstance : m_InstanceList)
    {
        PEntity = PInstance->GetCharByID(id);
        if (PEntity)
        {
            break;
        }
    }
    return PEntity;
}

CBaseEntity* CZoneInstance::GetEntity(uint16 targid, uint8 filter)
{
    TracyZoneScoped;
    CBaseEntity* PEntity = IsHybrid() ? CZone::GetEntity(targid, filter) : nullptr;
    if (PEntity)
    {
        return PEntity;
    }
    if (filter & TYPE_PC)
    {
        for (const auto& PInstance : m_InstanceList)
        {
            PEntity = PInstance->GetEntity(targid, filter);
            if (PEntity)
            {
                break;
            }
        }
    }
    return PEntity;
}

void CZoneInstance::InsertMOB(CBaseEntity* PMob)
{
    TracyZoneScoped;
    if (PMob->PInstance)
    {
        PMob->PInstance->InsertMOB(PMob);
    }
    else if (IsHybrid())
    {
        CZone::InsertMOB(PMob);
    }
}

void CZoneInstance::InsertNPC(CBaseEntity* PNpc)
{
    TracyZoneScoped;
    if (PNpc->PInstance)
    {
        PNpc->PInstance->InsertNPC(PNpc);
    }
    else if (IsHybrid())
    {
        CZone::InsertNPC(PNpc);
    }
}

void CZoneInstance::InsertPET(CBaseEntity* PPet)
{
    TracyZoneScoped;
    if (PPet->PInstance)
    {
        PPet->PInstance->InsertPET(PPet);
    }
    else if (IsHybrid())
    {
        CZone::InsertPET(PPet);
    }
}

void CZoneInstance::InsertTRUST(CBaseEntity* PTrust)
{
    TracyZoneScoped;
    if (PTrust->PInstance)
    {
        PTrust->PInstance->InsertTRUST(PTrust);
    }
    else if (IsHybrid())
    {
        CZone::InsertTRUST(PTrust);
    }
}

void CZoneInstance::FindPartyForMob(CBaseEntity* PEntity)
{
    TracyZoneScoped;
    if (PEntity->PInstance)
    {
        PEntity->PInstance->FindPartyForMob(PEntity);
    }
    else if (IsHybrid())
    {
        CZone::FindPartyForMob(PEntity);
    }
}

void CZoneInstance::TransportDepart(uint16 boundary, uint16 prevZoneId, uint16 transportId)
{
    TracyZoneScoped;
    if (IsHybrid())
    {
        CZone::TransportDepart(boundary, prevZoneId, transportId);
    }

    for (const auto& PInstance : m_InstanceList)
    {
        PInstance->TransportDepart(boundary, prevZoneId, transportId);
    }
}

void CZoneInstance::DecreaseZoneCounter(CCharEntity* PChar)
{
    TracyZoneScoped;
    CInstance* PInstance = PChar->PInstance;
    if (PInstance)
    {
        PInstance->DecreaseZoneCounter(PChar);
        PInstance->DespawnPC(PChar);
        CharZoneOut(PChar);
        PChar->StatusEffectContainer->DelStatusEffectSilent(EFFECT_LEVEL_RESTRICTION);
        PChar->PInstance = nullptr;

        if (PInstance->CharListEmpty())
        {
            if (!(PInstance->Failed() || PInstance->Completed()))
            {
                PInstance->SetWipeTime(PInstance->GetElapsedTime(timer::now()));
            }
        }
    }
    else if (IsHybrid())
    {
        CZone::DecreaseZoneCounter(PChar);
    }
}

void CZoneInstance::IncreaseZoneCounter(CCharEntity* PChar)
{
    TracyZoneScoped;
    if (PChar == nullptr)
    {
        ShowWarning("PChar is null.");
        return;
    }

    if (PChar->loc.zone != nullptr)
    {
        ShowWarning("Zone was not null for %s.", PChar->getName());
        return;
    }

    if (PChar->PTreasurePool != nullptr)
    {
        ShowWarning("PTreasurePool was not empty for %s.", PChar->getName());
        return;
    }

    // return char to instance (d/c or logout)
    if (!PChar->PInstance)
    {
        for (const auto& PInstance : m_InstanceList)
        {
            if (PInstance->CharRegistered(PChar))
            {
                PChar->PInstance = PInstance.get();
            }
        }
    }

    if (PChar->PInstance)
    {
        if (!zoneTimerToken_.has_value())
        {
            createZoneTimers();
        }

        PChar->targid = PChar->PInstance->GetNewCharTargID();

        if (PChar->targid >= 0x700)
        {
            ShowError("CZone::InsertChar : targid is high (03hX), update packets will be ignored", PChar->targid);
            return;
        }

        PChar->PInstance->InsertPC(PChar);
        luautils::OnInstanceZoneIn(PChar, PChar->PInstance);
        CharZoneIn(PChar);

        if (PChar->PInstance->GetLevelCap() > 0)
        {
            PChar->StatusEffectContainer->AddStatusEffect(new CStatusEffect(EFFECT_LEVEL_RESTRICTION, EFFECT_LEVEL_RESTRICTION, PChar->PInstance->GetLevelCap(), 0s, 0s));
        }

        if (PChar->PInstance->CheckFirstEntry(PChar->id))
        {
            PChar->loc.p = PChar->PInstance->GetEntryLoc();
            PChar->PAI->QueueAction(queueAction_t(400ms, false, luautils::AfterInstanceRegister));
        }
    }
    else if (IsHybrid())
    {
        CZone::IncreaseZoneCounter(PChar);
    }
    else
    {
        ShowWarning(fmt::format("Failed to place {} in {} ({}). Placing them in that zone's instance exit area.",
                                PChar->name,
                                this->getName(),
                                this->GetID())
                        .c_str());

        // instance no longer exists: put them outside (at exit)
        uint16 zoneid = luautils::OnInstanceLoadFailed(this);

        CZone* PZone = zoneutils::GetZone(zoneid);
        // At this stage, can only send the player to a zone on this map server
        // reset position in the case of a zone crash while in an instance
        PChar->loc.p.x = 0;
        PChar->loc.p.y = 0;
        PChar->loc.p.z = 0;
        if (PZone)
        {
            PZone->IncreaseZoneCounter(PChar);
        }
        else
        {
            // if we can't get the instance failed destination zone, get their previous zone
            zoneid = PChar->loc.prevzone;
            zoneutils::GetZone(zoneid)->IncreaseZoneCounter(PChar);
        }

        // They are properly sent to zone, but bypassed the onZoneIn position fixup, do that now
        PChar->loc.prevzone    = GetID();
        PChar->loc.destination = zoneid;
        luautils::OnZoneIn(PChar);
        charutils::SaveCharPosition(PChar);
    }
}

void CZoneInstance::SpawnMOBs(CCharEntity* PChar)
{
    TracyZoneScoped;
    if (PChar->PInstance)
    {
        PChar->PInstance->SpawnMOBs(PChar);
    }
    else if (IsHybrid())
    {
        CZone::SpawnMOBs(PChar);
    }
}

void CZoneInstance::SpawnPETs(CCharEntity* PChar)
{
    TracyZoneScoped;
    if (PChar->PInstance)
    {
        PChar->PInstance->SpawnPETs(PChar);
    }
    else if (IsHybrid())
    {
        CZone::SpawnPETs(PChar);
    }
}

void CZoneInstance::SpawnTRUSTs(CCharEntity* PChar)
{
    TracyZoneScoped;
    if (PChar->PInstance)
    {
        PChar->PInstance->SpawnTRUSTs(PChar);
    }
    else if (IsHybrid())
    {
        CZone::SpawnTRUSTs(PChar);
    }
}

void CZoneInstance::SpawnNPCs(CCharEntity* PChar)
{
    TracyZoneScoped;
    if (PChar->PInstance)
    {
        PChar->PInstance->SpawnNPCs(PChar);
    }
    else if (IsHybrid())
    {
        CZone::SpawnNPCs(PChar);
    }
}

void CZoneInstance::SpawnPCs(CCharEntity* PChar)
{
    TracyZoneScoped;
    if (PChar->PInstance)
    {
        PChar->PInstance->SpawnPCs(PChar);
    }
    else if (IsHybrid())
    {
        CZone::SpawnPCs(PChar);
    }
}

void CZoneInstance::SpawnConditionalNPCs(CCharEntity* PChar)
{
    TracyZoneScoped;
    if (PChar->PInstance)
    {
        PChar->PInstance->SpawnConditionalNPCs(PChar);
    }
    else if (IsHybrid())
    {
        CZone::SpawnConditionalNPCs(PChar);
    }
}

void CZoneInstance::SpawnTransport(CCharEntity* PChar)
{
    TracyZoneScoped;
    if (PChar->PInstance)
    {
        PChar->PInstance->SpawnTransport(PChar);
    }
    else if (IsHybrid())
    {
        CZone::SpawnTransport(PChar);
    }
}

void CZoneInstance::TOTDChange(vanadiel_time::TOTD TOTD)
{
    TracyZoneScoped;
    if (IsHybrid())
    {
        CZone::TOTDChange(TOTD);
    }

    for (const auto& PInstance : m_InstanceList)
    {
        PInstance->TOTDChange(TOTD);
    }
}

void CZoneInstance::PushPacket(CBaseEntity* PEntity, GLOBAL_MESSAGE_TYPE message_type, const std::unique_ptr<CBasicPacket>& packet)
{
    TracyZoneScoped;

    if (PEntity)
    {
        if (PEntity->PInstance)
        {
            PEntity->PInstance->PushPacket(PEntity, message_type, packet);
        }
        else if (IsHybrid())
        {
            CZone::PushPacket(PEntity, message_type, packet);
        }
    }
    else
    {
        if (IsHybrid())
        {
            CZone::PushPacket(nullptr, message_type, packet);
        }

        for (const auto& PInstance : m_InstanceList)
        {
            PInstance->PushPacket(PEntity, message_type, packet);
        }
    }
}

void CZoneInstance::UpdateEntityPacket(CBaseEntity* PEntity, ENTITYUPDATE type, uint8 updatemask, bool alwaysInclude)
{
    TracyZoneScoped;

    if (PEntity)
    {
        if (PEntity->PInstance)
        {
            PEntity->PInstance->UpdateEntityPacket(PEntity, type, updatemask, alwaysInclude);
        }
        else if (IsHybrid())
        {
            CZone::UpdateEntityPacket(PEntity, type, updatemask, alwaysInclude);
        }
    }
    else
    {
        if (IsHybrid())
        {
            CZone::UpdateEntityPacket(nullptr, type, updatemask, alwaysInclude);
        }

        for (const auto& PInstance : m_InstanceList)
        {
            PInstance->UpdateEntityPacket(PEntity, type, updatemask, alwaysInclude);
        }
    }
}

void CZoneInstance::WideScan(CCharEntity* PChar, uint16 radius)
{
    TracyZoneScoped;

    if (PChar->PInstance)
    {
        PChar->PInstance->WideScan(PChar, radius);
    }
    else if (IsHybrid())
    {
        CZone::WideScan(PChar, radius);
    }
}

auto CZoneInstance::ZoneServer(timer::time_point tick) -> Task<void>
{
    TracyZoneScoped;

    if (IsHybrid())
    {
        co_await CZone::ZoneServer(tick);
    }

    // Snapshot raw pointers before any await. CheckInstance -> CreateInstance
    // can emplace_back (and realloc) m_InstanceList while an instance tick is
    // yielded — CZoneEntities::ZoneServer explicitly yields so other zone /
    // time_server work can run. A range-for reference into the vector is then
    // a dangling unique_ptr (02:47 Dynamis-Bastok_[D] ACCESS_VIOLATION).
    std::vector<CInstance*> instances;
    instances.reserve(m_InstanceList.size());
    for (const auto& inst : m_InstanceList)
    {
        if (inst)
        {
            instances.push_back(inst.get());
        }
    }

    std::vector<CInstance*> instancesToRemove;
    for (CInstance* PInstance : instances)
    {
        if (!ContainsInstance(PInstance))
        {
            continue;
        }

        co_await PInstance->ZoneServer(tick);

        if (!ContainsInstance(PInstance))
        {
            continue;
        }

        PInstance->CheckTime(tick);

        if ((PInstance->Failed() || PInstance->Completed()) && PInstance->CharListEmpty())
        {
            instancesToRemove.push_back(PInstance);
        }
    }

    for (CInstance* PInstance : instancesToRemove)
    {
        auto it = std::find_if(
            m_InstanceList.begin(),
            m_InstanceList.end(),
            [PInstance](const auto& el)
            {
                return el.get() == PInstance;
            });

        if (it == m_InstanceList.end())
        {
            continue;
        }

        ShowDebug("[CZoneInstance] ZoneServer cleaned up Instance %s", PInstance->GetName());
        m_InstanceList.erase(it);
    }
}

bool CZoneInstance::IsZoneEmpty()
{
    if (IsHybrid() && !CZone::IsZoneEmpty())
    {
        return false;
    }

    for (const auto& PInstance : m_InstanceList)
    {
        if (!PInstance->CharListEmpty())
        {
            return false;
        }
    }

    return true;
}

auto CZoneInstance::CheckTriggerAreas() -> Task<void>
{
    return CZone::CheckTriggerAreas();
}

void CZoneInstance::ForEachChar(const std::function<void(CCharEntity*)>& func)
{
    TracyZoneScoped;

    if (IsHybrid())
    {
        CZone::ForEachChar(func);
    }

    for (const auto& PInstance : m_InstanceList)
    {
        PInstance->ForEachChar(func);
    }
}

void CZoneInstance::ForEachCharInstance(CBaseEntity* PEntity, const std::function<void(CCharEntity*)>& func)
{
    TracyZoneScoped;

    if (PEntity->PInstance)
    {
        PEntity->PInstance->ForEachChar(func);
    }
    else if (IsHybrid())
    {
        CZone::ForEachChar(func);
    }
}

void CZoneInstance::ForEachMob(const std::function<void(CMobEntity*)>& func)
{
    TracyZoneScoped;

    if (IsHybrid())
    {
        CZone::ForEachMob(func);
    }

    for (const auto& PInstance : m_InstanceList)
    {
        PInstance->ForEachMob(func);
    }
}

void CZoneInstance::ForEachMobInstance(CBaseEntity* PEntity, const std::function<void(CMobEntity*)>& func)
{
    TracyZoneScoped;

    if (PEntity->PInstance)
    {
        PEntity->PInstance->ForEachMob(func);
    }
    else if (IsHybrid())
    {
        CZone::ForEachMob(func);
    }
}

void CZoneInstance::ForEachNpc(const std::function<void(CNpcEntity*)>& func)
{
    TracyZoneScoped;

    if (IsHybrid())
    {
        CZone::ForEachNpc(func);
    }

    for (const auto& PInstance : m_InstanceList)
    {
        PInstance->ForEachNpc(func);
    }
}

void CZoneInstance::ForEachNpcInstance(CBaseEntity* PEntity, const std::function<void(CNpcEntity*)>& func)
{
    TracyZoneScoped;

    if (PEntity->PInstance)
    {
        PEntity->PInstance->ForEachNpc(func);
    }
    else if (IsHybrid())
    {
        CZone::ForEachNpc(func);
    }
}

void CZoneInstance::ForEachTrust(const std::function<void(CTrustEntity*)>& func)
{
    TracyZoneScoped;

    if (IsHybrid())
    {
        CZone::ForEachTrust(func);
    }

    for (const auto& PInstance : m_InstanceList)
    {
        PInstance->ForEachTrust(func);
    }
}

void CZoneInstance::ForEachTrustInstance(CBaseEntity* PEntity, const std::function<void(CTrustEntity*)>& func)
{
    TracyZoneScoped;

    if (PEntity->PInstance)
    {
        PEntity->PInstance->ForEachTrust(func);
    }
    else if (IsHybrid())
    {
        CZone::ForEachTrust(func);
    }
}

void CZoneInstance::ForEachPet(const std::function<void(CPetEntity*)>& func)
{
    TracyZoneScoped;

    if (IsHybrid())
    {
        CZone::ForEachPet(func);
    }

    for (const auto& PInstance : m_InstanceList)
    {
        PInstance->ForEachPet(func);
    }
}

void CZoneInstance::ForEachPetInstance(CBaseEntity* PEntity, const std::function<void(CPetEntity*)>& func)
{
    TracyZoneScoped;

    if (PEntity->PInstance)
    {
        PEntity->PInstance->ForEachPet(func);
    }
    else if (IsHybrid())
    {
        CZone::ForEachPet(func);
    }
}

void CZoneInstance::ForEachAlly(const std::function<void(CMobEntity*)>& func)
{
    TracyZoneScoped;

    if (IsHybrid())
    {
        CZone::ForEachAlly(func);
    }

    for (const auto& PInstance : m_InstanceList)
    {
        PInstance->ForEachAlly(func);
    }
}

void CZoneInstance::ForEachAllyInstance(CBaseEntity* PEntity, const std::function<void(CMobEntity*)>& func)
{
    TracyZoneScoped;

    if (PEntity->PInstance)
    {
        PEntity->PInstance->ForEachAlly(func);
    }
    else if (IsHybrid())
    {
        CZone::ForEachAlly(func);
    }
}

bool CZoneInstance::ContainsInstance(const CInstance* PInstance) const
{
    if (PInstance == nullptr)
    {
        return false;
    }

    return std::any_of(m_InstanceList.begin(), m_InstanceList.end(), [PInstance](const auto& inst)
                       { return inst.get() == PInstance; });
}

CInstance* CZoneInstance::CreateInstance(uint32 instanceid)
{
    TracyZoneScoped;

    // Grow before insert so a second concurrent [D] copy is less likely to
    // realloc under a yielded ZoneServer. The snapshot in ZoneServer is the
    // actual UAF fix; this just keeps the common 2–4 copy case cheap.
    if (m_InstanceList.capacity() < 8)
    {
        m_InstanceList.reserve(8);
    }

    m_InstanceList.emplace_back(std::make_unique<CInstance>(scheduler_, config_, this, instanceid));
    ShowInfoFmt("[CZoneInstance] Created instance {} in {} ({} live copies)", instanceid, getName(), m_InstanceList.size());
    return m_InstanceList.back().get();
}
