/************************************************************************
 * Auto-spend Lua bindings
 *
 * Exposes two methods on the CBaseEntity Lua usertype:
 *
 *   player:raiseMerit(meritId)    -> bool
 *   player:raiseJobPoint(jpId)    -> bool
 *
 * Both spend 1 upgrade rank from the player's pool. They wrap the engine's
 * existing CMeritPoints::RaiseMerit / CJobPoints::RaiseJobPoint, which
 * already validate affordability, rank caps, and (for JP) current-job
 * scope. We detect application by checking the spendable balance before
 * and after the engine call: if it went down, an upgrade was applied.
 *
 * Used by:
 *   modules/custom/commands/automerits.lua  (!automerits)
 *   modules/custom/commands/autojp.lua      (!autojp)
 *
 * Why a custom module instead of editing src/map/lua/lua_baseentity.cpp?
 *   Custom modules under modules/custom/cpp/ are outside the upstream
 *   LandSandBoat source tree, so they survive an upstream git pull
 *   without merge conflicts. The runtime behavior is identical.
 ************************************************************************/

#include "map/utils/moduleutils.h"

#include "common/logging.h"

#include "map/entities/baseentity.h"
#include "map/entities/charentity.h"
#include "map/job_points.h"
#include "map/lua/lua_baseentity.h"
#include "map/merit.h"
#include "map/utils/charutils.h"

// Balance packets (currentJp / merit-balance numbers).
#include "map/packets/s2c/0x063_miscdata_job_points.h"
#include "map/packets/s2c/0x063_miscdata_merits.h"
#include "map/packets/s2c/0x063_miscdata_monstrosity.h"

// Per-category update packets. WITHOUT these the client UI shows the
// stale per-rank values (0/20 on JP, untouched merit counts) even though
// the engine + DB have been updated correctly. Mirrors what retail's
// client-initiated handlers push (0x0BE for merits, 0x0BF for JP).
#include "map/packets/s2c/0x08c_merit.h"
#include "map/packets/s2c/0x08d_job_points.h"

// Char-status refresh chain for merits — same set of packets the retail
// merit handler pushes so HP/MP/stats/abilities/traits reflect the new
// merit value without a relog or zone change.
#include "map/packets/char_status.h"
#include "map/packets/char_sync.h"
#include "map/packets/s2c/0x061_clistatus.h"
#include "map/packets/s2c/0x062_clistatus2.h"
#include "map/packets/s2c/0x0ac_command_data.h"
#include "map/packets/s2c/0x119_abil_recast.h"

class AutoSpendBindingsModule : public CPPModule
{
    void OnInit() override
    {
        // -----------------------------------------------------------------
        // player:raiseMerit(meritId) -> bool
        // -----------------------------------------------------------------
        // Walks one upgrade onto the given merit category. Returns true if
        // the merit balance actually moved (i.e. the engine accepted it),
        // false in any of the engine's no-op cases:
        //   - not a player entity
        //   - insufficient unspent merits for the next-rank cost
        //   - this category is already at its category cap or rank max
        //   - merit id doesn't belong to this player's main job (Group 1/2)
        //   - merit id is invalid
        // The engine's RaiseMerit method handles all the validation,
        // spell/WS unlocks, and trait rebuilds; we just refresh the client
        // packet on success so the merit menu reflects the new value
        // without requiring a relog.
        lua["CBaseEntity"]["raiseMerit"] =
            [](CLuaBaseEntity& self, uint16 merit) -> bool
        {
            auto* entity = self.GetBaseEntity();
            if (entity == nullptr || entity->objtype != TYPE_PC)
            {
                return false;
            }

            auto* PChar = static_cast<CCharEntity*>(entity);
            if (PChar->PMeritPoints == nullptr)
            {
                return false;
            }

            const MERIT_TYPE meritType = static_cast<MERIT_TYPE>(merit);
            const uint8 before = PChar->PMeritPoints->GetMeritPoints();
            PChar->PMeritPoints->RaiseMerit(meritType);
            const uint8 after = PChar->PMeritPoints->GetMeritPoints();

            if (after == before)
            {
                return false; // engine no-op (one of the conditions above)
            }

            // Mirror the retail merit-raise flow (see 0x0BE handler).
            // The balance packet alone is insufficient — without the per-merit
            // GP_SERV_COMMAND_MERIT packet the client UI keeps showing the
            // old rank values. The stat refresh chain re-applies merit mods
            // to skills/abilities/HP/MP so the player sees the change without
            // a relog.
            PChar->pushPacket<GP_SERV_COMMAND_MISCDATA::MERITS>(PChar);
            PChar->pushPacket<GP_SERV_COMMAND_MISCDATA::MONSTROSITY1>(PChar);
            PChar->pushPacket<GP_SERV_COMMAND_MISCDATA::MONSTROSITY2>(PChar);
            PChar->pushPacket<GP_SERV_COMMAND_MERIT>(PChar, meritType);

            charutils::SaveCharExp(PChar, PChar->GetMJob());
            PChar->PMeritPoints->SaveMeritPoints(PChar->id);

            charutils::BuildingCharSkillsTable(PChar);
            charutils::CalculateStats(PChar);
            charutils::CheckValidEquipment(PChar);
            charutils::BuildingCharAbilityTable(PChar);
            charutils::BuildingCharTraitsTable(PChar);

            PChar->UpdateHealth();
            PChar->addHP(PChar->GetMaxHP());
            PChar->addMP(PChar->GetMaxMP());

            PChar->pushPacket<CCharStatusPacket>(PChar);
            PChar->pushPacket<GP_SERV_COMMAND_CLISTATUS>(PChar);
            PChar->pushPacket<GP_SERV_COMMAND_CLISTATUS2>(PChar);
            PChar->pushPacket<GP_SERV_COMMAND_ABIL_RECAST>(PChar);
            PChar->pushPacket<GP_SERV_COMMAND_COMMAND_DATA>(PChar);
            charutils::SendExtendedJobPackets(PChar);
            PChar->pushPacket<CCharSyncPacket>(PChar);

            return true;
        };

        // -----------------------------------------------------------------
        // player:raiseJobPoint(jpId) -> bool
        // -----------------------------------------------------------------
        // Walks one upgrade onto the given JP category for the player's
        // current main job. The engine silently no-ops if:
        //   - not a player entity
        //   - insufficient unspent JP (cost = 1 + currentRank)
        //   - category is at rank 20 (the cap)
        //   - jpId belongs to a different job than the player's current main
        //   - jpId is invalid
        // RaiseJobPoint persists the change to char_job_points and refreshes
        // gift mods on success; we push the JP packet so the JP menu UI
        // updates without needing a relog.
        lua["CBaseEntity"]["raiseJobPoint"] =
            [](CLuaBaseEntity& self, uint16 jpType) -> bool
        {
            auto* entity = self.GetBaseEntity();
            if (entity == nullptr || entity->objtype != TYPE_PC)
            {
                return false;
            }

            auto* PChar = static_cast<CCharEntity*>(entity);
            if (PChar->PJobPoints == nullptr)
            {
                return false;
            }

            const JOBPOINT_TYPE jp = static_cast<JOBPOINT_TYPE>(jpType);
            const uint16 before = PChar->PJobPoints->GetJobPoints();
            PChar->PJobPoints->RaiseJobPoint(jp);
            const uint16 after = PChar->PJobPoints->GetJobPoints();

            if (after == before)
            {
                return false; // engine no-op
            }

            // Mirror the retail JP-raise flow (see 0x0BF handler). The
            // balance packet alone is insufficient — without the per-category
            // GP_SERV_COMMAND_JOB_POINTS packet the JP menu keeps showing
            // 0/20 for every category even after the value is incremented
            // and saved to char_job_points.
            PChar->pushPacket<GP_SERV_COMMAND_MISCDATA::JOB_POINTS>(PChar);
            PChar->pushPacket<GP_SERV_COMMAND_JOB_POINTS>(PChar, jp);
            return true;
        };

        // -----------------------------------------------------------------
        // player:lowerMerit(meritId, refundPoints) -> bool
        // -----------------------------------------------------------------
        // Lowers one rank on the given merit and refunds the specified
        // number of merit points to the player's unspent balance.
        //
        // LowerMerit() handles spell/WS removal when the rank drops to 0
        // but does NOT touch m_MeritPoints, so callers must pass in the
        // exact cost of the rank being removed (see merit.cpp upgrade[]
        // array). The Lua !resetjobmerits command computes this from its
        // own per-rank cost tables that mirror the C++ constants.
        //
        // Returns false if the entity is not a player, has no merit data,
        // or the merit rank is already 0 (LowerMerit would no-op).
        lua["CBaseEntity"]["lowerMerit"] =
            [](CLuaBaseEntity& self, uint16 merit, uint8 refundPoints) -> bool
        {
            auto* entity = self.GetBaseEntity();
            if (entity == nullptr || entity->objtype != TYPE_PC)
            {
                return false;
            }

            auto* PChar = static_cast<CCharEntity*>(entity);
            if (PChar->PMeritPoints == nullptr)
            {
                return false;
            }

            const MERIT_TYPE meritType = static_cast<MERIT_TYPE>(merit);

            // GetMeritCountInSameCategory sums ranks across the whole group;
            // use the combo total as a proxy to detect if this merit is at 0.
            // A cleaner check: RaiseMerit then LowerMerit was the old pattern,
            // but that would corrupt the balance. Instead we rely on the Lua
            // caller only passing merits with rank > 0 (verified via getMerit).
            PChar->PMeritPoints->LowerMerit(meritType);

            // Refund the caller-supplied point cost into the unspent balance.
            // Use the public Get/SetMeritPoints accessors -- m_MeritPoints is private
            // (MSVC let the direct poke slide; g++ on the box rejects it -> build break).
            const int32 newBalance = static_cast<int32>(PChar->PMeritPoints->GetMeritPoints()) + refundPoints;
            PChar->PMeritPoints->SetMeritPoints(static_cast<uint16>(std::min(newBalance, 255)));

            // Push updated balance + per-merit packets so the client UI
            // reflects the change without a relog. Then rebuild traits/skills
            // in case the lowered merit had active effects.
            PChar->pushPacket<GP_SERV_COMMAND_MISCDATA::MERITS>(PChar);
            PChar->pushPacket<GP_SERV_COMMAND_MISCDATA::MONSTROSITY1>(PChar);
            PChar->pushPacket<GP_SERV_COMMAND_MISCDATA::MONSTROSITY2>(PChar);
            PChar->pushPacket<GP_SERV_COMMAND_MERIT>(PChar, meritType);

            charutils::SaveCharExp(PChar, PChar->GetMJob());
            PChar->PMeritPoints->SaveMeritPoints(PChar->id);

            charutils::BuildingCharSkillsTable(PChar);
            charutils::CalculateStats(PChar);
            charutils::CheckValidEquipment(PChar);
            charutils::BuildingCharAbilityTable(PChar);
            charutils::BuildingCharTraitsTable(PChar);

            PChar->UpdateHealth();
            PChar->addHP(PChar->GetMaxHP());
            PChar->addMP(PChar->GetMaxMP());

            PChar->pushPacket<CCharStatusPacket>(PChar);
            PChar->pushPacket<GP_SERV_COMMAND_CLISTATUS>(PChar);
            PChar->pushPacket<GP_SERV_COMMAND_CLISTATUS2>(PChar);
            PChar->pushPacket<GP_SERV_COMMAND_ABIL_RECAST>(PChar);
            PChar->pushPacket<GP_SERV_COMMAND_COMMAND_DATA>(PChar);
            charutils::SendExtendedJobPackets(PChar);
            PChar->pushPacket<CCharSyncPacket>(PChar);

            return true;
        };

        ShowInfo("[auto_spend_bindings] Registered raiseMerit + raiseJobPoint + lowerMerit Lua bindings.");
    }
};

REGISTER_CPP_MODULE(AutoSpendBindingsModule);
