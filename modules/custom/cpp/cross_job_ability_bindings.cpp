/************************************************************************
 * Cross-Job Ability bindings
 *
 * Lets a character "borrow" a job ability from another job and use it on
 * ANY job (e.g. a PLD casting Meditate). Purchased from the Cross-Job
 * Ability Trainer NPC at GM Home (modules/custom/lua/CrossJob_Trainer.lua).
 *
 * Exposes on the CBaseEntity Lua usertype:
 *   player:learnCrossJobAbility(id)   -> bool   (persist + apply live)
 *   player:unlearnCrossJobAbility(id) -> bool   (remove + rebuild)
 *   player:hasCrossJobAbility(id)     -> bool
 *   player:getCrossJobAbilities()     -> { id, id, ... }
 *
 * ---------------------------------------------------------------------------
 * Why this needs C++ (and can't be pure Lua):
 *
 * Usage of any job ability is gated in CAbilityState::CanUseAbility() by
 * charutils::hasAbility(PChar, id), which reads the per-character usable
 * bitmask m_Abilities[64]. That bitmask is wiped and rebuilt ONLY from the
 * current main/sub job by charutils::BuildingCharAbilityTable() on login,
 * zone-in, job/subjob change, level change and merit change. A borrowed
 * ability is (by definition) not in the current job's list, so the engine
 * never re-adds it. We must re-inject it after every rebuild.
 *
 * charutils::addAbility() sets the m_Abilities bit directly and is NOT
 * job-gated, which is exactly what we need. The Lua binding addLearnedAbility
 * can't be reused: it short-circuits once the native learned-bit is set, so
 * it won't re-inject after a rebuild, and there's no bare addAbility binding.
 *
 * ---------------------------------------------------------------------------
 * Re-injection strategy (two hooks, one in-memory cache):
 *
 *   OnCharZoneIn  -> (re)load this char's list from the DB into the cache,
 *                    then apply every entry. Covers login + every zone.
 *
 *   OnPushPacket  -> every BuildingCharAbilityTable rebuild is followed by a
 *                    COMMAND_DATA (0xAC) packet push to the client. Watching
 *                    for that opcode lets us re-apply after job/subjob/level/
 *                    merit changes that do NOT trigger a zone-in. Re-applying
 *                    only sets bitmask bits + registers a ready recast entry
 *                    (it pushes no packet), so there is no recursion back
 *                    through pushPacket.
 *
 * The cache (charid -> ability ids) avoids a DB hit on the hot OnPushPacket
 * path. The map server runs zone logic single-threaded, so the plain
 * unordered_map needs no locking (mirrors how other map globals are used).
 *
 * ---------------------------------------------------------------------------
 * Why a custom module instead of editing src/?
 *   Files under modules/custom/ are outside the upstream LandSandBoat tree,
 *   so they survive an upstream git pull without merge conflicts.
 ************************************************************************/

#include "map/utils/moduleutils.h"

#include "common/database.h"
#include "common/logging.h"
#include "common/timer.h"

#include "map/ability.h"
#include "map/entities/baseentity.h"
#include "map/entities/charentity.h"
#include "map/lua/lua_baseentity.h"
#include "map/packets/basic.h"
#include "map/recast_container.h"
#include "map/utils/charutils.h"

// COMMAND_DATA (0xAC): pushed after every ability-table rebuild; also the
// packet we push to refresh the client after a learn/unlearn.
#include "map/packets/s2c/0x0ac_command_data.h"

#include <algorithm>
#include <unordered_map>
#include <utility>
#include <vector>

using namespace std::chrono_literals;

namespace
{
    // charid -> borrowed ability ids. Warm after OnCharZoneIn / a learn;
    // erased on zone-out to bound memory.
    std::unordered_map<uint32, std::vector<uint16>> g_learnedCache;

    // The ability-recast packet (GP_SERV_COMMAND_ABIL_RECAST, see
    // src/map/packets/s2c/0x119_abil_recast.cpp) carries at most 30 ability
    // recast entries -- native job abilities AND borrowed ones combined. The
    // 31st makes the engine drop the overflow and log "> 31 abilities ...
    // unsupported", leaving those abilities unusable. A fully-merited/Job-Point
    // job already has ~20-25 native abilities, so only the first few borrowed
    // ones fit. We inject borrowed abilities only while the recast list has room
    // and stop at this ceiling; native abilities are placed first by
    // BuildingCharAbilityTable, so borrowed fill the remaining slots. Excess
    // borrowed abilities stay owned in char_cross_job_abilities and re-activate
    // automatically on a job whose native list leaves free slots.
    constexpr std::size_t MAX_ABILITY_RECASTS = 30;

    // Mechanical safety gate (NOT the content curation -- that lives in
    // cross_job_ability_catalog.lua). An ability is grantable cross-job if it:
    //   * exists in the global ability list,
    //   * is not a 2-hour (every 2-hour uses recastId 0), and
    //   * fits the usable-ability bitmask (m_Abilities is 64 bytes = IDs 0..511).
    bool isCrossJobLearnable(uint16 abilityId)
    {
        if (abilityId >= 512)
        {
            return false;
        }

        CAbility* PAbility = ability::GetAbility(abilityId);
        if (PAbility == nullptr)
        {
            return false;
        }

        if (PAbility->getRecastId() == Recast::Special)
        {
            return false;
        }

        return true;
    }

    // Inject one ability into the live usable table + register a ready recast,
    // mirroring charutils::BuildingCharAbilityTable. Idempotent: re-setting an
    // already-set bit is a no-op, and we only add a recast entry if one isn't
    // already present (so we never reset an active cooldown).
    void applyCrossJobAbility(CCharEntity* PChar, uint16 abilityId)
    {
        if (PChar == nullptr || !isCrossJobLearnable(abilityId))
        {
            return;
        }

        // Never push the recast list past the packet ceiling (MAX_ABILITY_RECASTS).
        // Native abilities are already present at this point, so this fills the
        // remaining slots and skips any borrowed abilities that wouldn't fit --
        // they stay owned and re-apply later when there's room.
        const RecastList_t* recasts = PChar->PRecastContainer->GetRecastList(RECAST_ABILITY);
        if (recasts != nullptr && recasts->size() >= MAX_ABILITY_RECASTS)
        {
            return;
        }

        CAbility* PAbility = ability::GetAbility(abilityId);

        charutils::addAbility(PChar, abilityId);

        const Recast recastId = PAbility->getRecastId();
        if (!PChar->PRecastContainer->Has(RECAST_ABILITY, recastId))
        {
            // Cross-job abilities never have a job charge entry, so the engine's
            // chargeTime/maxCharges are 0 here -> a normal single-use recast.
            PChar->PRecastContainer->Add(RECAST_ABILITY, recastId, 0s);
        }
    }

    void applyAllFromCache(CCharEntity* PChar)
    {
        if (PChar == nullptr)
        {
            return;
        }

        const auto it = g_learnedCache.find(PChar->id);
        if (it == g_learnedCache.end())
        {
            return;
        }

        for (const uint16 abilityId : it->second)
        {
            applyCrossJobAbility(PChar, abilityId);
        }
    }

    void loadCacheFromDB(CCharEntity* PChar)
    {
        if (PChar == nullptr)
        {
            return;
        }

        std::vector<uint16> ids;

        // If the table doesn't exist yet (SQL not applied) preparedStmt returns
        // a falsy result; we simply cache an empty list and the feature is inert.
        const auto rset = db::preparedStmt("SELECT abilityId FROM char_cross_job_abilities WHERE charid = ?", PChar->id);
        if (rset)
        {
            while (rset->next())
            {
                ids.push_back(rset->get<uint16>("abilityId"));
            }
        }

        g_learnedCache[PChar->id] = std::move(ids);
    }
} // namespace

class CrossJobAbilityBindingsModule : public CPPModule
{
    void OnInit() override
    {
        // -----------------------------------------------------------------
        // player:learnCrossJobAbility(abilityId) -> bool
        // -----------------------------------------------------------------
        // Persists the ability to char_cross_job_abilities, applies it to the
        // live usable table, and refreshes the client. Returns false only if
        // the caller isn't a player or the id fails the mechanical safety gate.
        // Idempotent: learning an already-owned ability re-applies and returns
        // true (the NPC gates gil charging on hasCrossJobAbility, so this never
        // double-charges).
        lua["CBaseEntity"]["learnCrossJobAbility"] =
            [](CLuaBaseEntity& self, uint16 abilityId) -> bool
        {
            auto* entity = self.GetBaseEntity();
            if (entity == nullptr || entity->objtype != TYPE_PC)
            {
                return false;
            }

            if (!isCrossJobLearnable(abilityId))
            {
                return false;
            }

            auto* PChar = static_cast<CCharEntity*>(entity);

            db::preparedStmt("INSERT IGNORE INTO char_cross_job_abilities (charid, abilityId) VALUES (?, ?)", PChar->id, abilityId);

            auto& vec = g_learnedCache[PChar->id];
            if (std::find(vec.begin(), vec.end(), abilityId) == vec.end())
            {
                vec.push_back(abilityId);
            }

            applyCrossJobAbility(PChar, abilityId);

            PChar->pushPacket<GP_SERV_COMMAND_COMMAND_DATA>(PChar);

            return true;
        };

        // -----------------------------------------------------------------
        // player:unlearnCrossJobAbility(abilityId) -> bool
        // -----------------------------------------------------------------
        // Removes persistence + the live bit. To strip the bit we let the
        // engine rebuild the job table from scratch, then re-apply the
        // remaining borrowed abilities. (Provided for admin/refund use; the
        // trainer NPC does not expose refunds.)
        lua["CBaseEntity"]["unlearnCrossJobAbility"] =
            [](CLuaBaseEntity& self, uint16 abilityId) -> bool
        {
            auto* entity = self.GetBaseEntity();
            if (entity == nullptr || entity->objtype != TYPE_PC)
            {
                return false;
            }

            auto* PChar = static_cast<CCharEntity*>(entity);

            db::preparedStmt("DELETE FROM char_cross_job_abilities WHERE charid = ? AND abilityId = ?", PChar->id, abilityId);

            const auto it = g_learnedCache.find(PChar->id);
            if (it != g_learnedCache.end())
            {
                auto& vec = it->second;
                vec.erase(std::remove(vec.begin(), vec.end(), abilityId), vec.end());
            }

            charutils::BuildingCharAbilityTable(PChar);
            applyAllFromCache(PChar);

            PChar->pushPacket<GP_SERV_COMMAND_COMMAND_DATA>(PChar);

            return true;
        };

        // -----------------------------------------------------------------
        // player:hasCrossJobAbility(abilityId) -> bool
        // -----------------------------------------------------------------
        lua["CBaseEntity"]["hasCrossJobAbility"] =
            [](CLuaBaseEntity& self, uint16 abilityId) -> bool
        {
            auto* entity = self.GetBaseEntity();
            if (entity == nullptr || entity->objtype != TYPE_PC)
            {
                return false;
            }

            auto* PChar = static_cast<CCharEntity*>(entity);

            const auto it = g_learnedCache.find(PChar->id);
            if (it != g_learnedCache.end())
            {
                return std::find(it->second.begin(), it->second.end(), abilityId) != it->second.end();
            }

            const auto rset = db::preparedStmt("SELECT 1 FROM char_cross_job_abilities WHERE charid = ? AND abilityId = ?", PChar->id, abilityId);
            return rset && rset->rowsCount() > 0;
        };

        // -----------------------------------------------------------------
        // player:getCrossJobAbilities() -> { abilityId, abilityId, ... }
        // -----------------------------------------------------------------
        // Built as a real Lua array (sol::table) via create_table()/:add,
        // mirroring CLuaBaseEntity::getSetBlueSpells, so the NPC can iterate
        // it with ipairs. (A bare std::vector return is pushed by sol2 as a
        // container userdata, which does NOT iterate under ipairs on every
        // Lua build -- breaking the NPC's ownedSet().) ::lua is the global
        // sol::state; we qualify it because a non-capturing lambda can't see
        // the CPPModule::lua member. One call lets the NPC build its "owned"
        // set instead of issuing N hasCrossJobAbility queries.
        lua["CBaseEntity"]["getCrossJobAbilities"] =
            [](CLuaBaseEntity& self) -> sol::table
        {
            sol::table result = ::lua.create_table();

            auto* entity = self.GetBaseEntity();
            if (entity == nullptr || entity->objtype != TYPE_PC)
            {
                return result;
            }

            auto* PChar = static_cast<CCharEntity*>(entity);

            const auto it = g_learnedCache.find(PChar->id);
            if (it != g_learnedCache.end())
            {
                for (const uint16 abilityId : it->second)
                {
                    result.add(abilityId);
                }
                return result;
            }

            const auto rset = db::preparedStmt("SELECT abilityId FROM char_cross_job_abilities WHERE charid = ?", PChar->id);
            if (rset)
            {
                while (rset->next())
                {
                    result.add(rset->get<uint16>("abilityId"));
                }
            }

            return result;
        };

        // -----------------------------------------------------------------
        // player:getAbilityRecastCount() -> int
        // -----------------------------------------------------------------
        // Current number of ability recast entries (native + borrowed). The
        // client's ability-recast packet (0x119) holds at most 30, so the
        // Cross-Job Trainer uses this to show players how many borrowed slots
        // are actually free on their current job.
        lua["CBaseEntity"]["getAbilityRecastCount"] =
            [](CLuaBaseEntity& self) -> uint16
        {
            auto* entity = self.GetBaseEntity();
            if (entity == nullptr || entity->objtype != TYPE_PC)
            {
                return 0;
            }

            auto* PChar = static_cast<CCharEntity*>(entity);

            const RecastList_t* recasts = PChar->PRecastContainer->GetRecastList(RECAST_ABILITY);
            return recasts != nullptr ? static_cast<uint16>(recasts->size()) : static_cast<uint16>(0);
        };

        ShowInfo("[cross_job_ability_bindings] Registered learn/unlearn/has/get/count CrossJobAbility Lua bindings.");
    }

    // Login + every zone-in: refresh cache from DB, then apply.
    void OnCharZoneIn(CCharEntity* PChar) override
    {
        if (PChar == nullptr)
        {
            return;
        }

        loadCacheFromDB(PChar);
        applyAllFromCache(PChar);
    }

    void OnCharZoneOut(CCharEntity* PChar) override
    {
        if (PChar != nullptr)
        {
            g_learnedCache.erase(PChar->id);
        }
    }

    // Safety net for ability-table rebuilds that don't fire a zone-in
    // (job/subjob/level/merit changes). Each is followed by a COMMAND_DATA push.
    void OnPushPacket(CCharEntity* PChar, const std::unique_ptr<CBasicPacket>& packet) override
    {
        if (PChar == nullptr || packet == nullptr)
        {
            return;
        }

        if (packet->getType() == static_cast<uint16>(PacketS2C::GP_SERV_COMMAND_COMMAND_DATA))
        {
            applyAllFromCache(PChar);
        }
    }
};

REGISTER_CPP_MODULE(CrossJobAbilityBindingsModule);
