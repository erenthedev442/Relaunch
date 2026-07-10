/************************************************************************
 * FJB combat helpers
 *
 * True-damage (over-cap) + automaton-DPS helpers extracted verbatim from
 * src/map/utils/battleutils.cpp so the high-churn stock file stays closer to
 * upstream (see CORE_PATCH_TRIAGE.md, extraction #3). Behavior is identical;
 * battleutils #includes fjb_combat.h and calls these at the same sites.
 *
 * This is a plain helper TU (not a CPPModule) — listed in modules/init.txt so
 * CMake compiles it into xi_map.
 ************************************************************************/

#include "modules/custom/cpp/fjb_combat.h"

#include "common/cbasetypes.h"

#include "map/entities/battleentity.h"
#include "map/entities/charentity.h"
#include "map/entities/petentity.h"
#include "map/enums/chat_message_type.h"
#include "map/packets/s2c/0x017_chat_std.h"

#include <string>
#include <string_view>

namespace
{
    // The PC who should receive the over-cap readout: the attacker itself if it
    // is a PC, otherwise the PC master of a player-owned pet/trust. nullptr when
    // the source isn't player-controlled (mobs get no message).
    CCharEntity* OverCapReporter(CBattleEntity* PAttacker)
    {
        if (PAttacker == nullptr)
        {
            return nullptr;
        }
        if (PAttacker->objtype == TYPE_PC)
        {
            return static_cast<CCharEntity*>(PAttacker);
        }
        if (PAttacker->PMaster != nullptr && PAttacker->PMaster->objtype == TYPE_PC)
        {
            return static_cast<CCharEntity*>(PAttacker->PMaster);
        }
        return nullptr;
    }

    // Automaton physical-damage multiplier (melee + ranged auto-attacks AND
    // weaponskills, which all funnel through TakePhysical/TakeWeaponskillDamage).
    // Does NOT touch magic-frame nukes or any non-automaton entity.
    // 2026-07-06: turned down 20 -> 5 (relaunch PUP power reduction).
    constexpr float AUTOMATON_DMG_MULTIPLIER = 5.0f;

    // Main-job-RNG player ranged-damage multiplier (auto-shots, Barrage,
    // ranged weaponskills, Eagle Eye Shot — everything funnels through
    // TakePhysical/TakeWeaponskillDamage with a ranged slot). Melee swings,
    // COR, and /RNG subs are untouched. Silent server-side trim per the
    // no-visible-multiplier balance policy.
    // 2026-07-10: RNG outpacing other DDs on relaunch — 0.80 (pending tune;
    // edit here + rebuild to adjust).
    constexpr float RANGER_RANGED_DMG_MULTIPLIER = 0.80f;
} // namespace

bool IsPlayerControlled(CBattleEntity* PAttacker)
{
    return PAttacker != nullptr &&
           (PAttacker->objtype == TYPE_PC ||
            (PAttacker->PMaster != nullptr && PAttacker->PMaster->objtype == TYPE_PC));
}

void NotifyOverCapDamage(CBattleEntity* PAttacker, int32 damage, std::string_view type)
{
    if (damage <= 131071)
    {
        return;
    }
    CCharEntity* PChar = OverCapReporter(PAttacker);
    if (PChar == nullptr)
    {
        return;
    }
    std::string label = (PAttacker->objtype == TYPE_PC)
        ? std::string(type)
        : fmt::format("{} {}", PAttacker->getName(), type);
    PChar->pushPacket<GP_SERV_COMMAND_CHAT_STD>(
        PChar, CHAT_MESSAGE_TYPE::MESSAGE_SYSTEM_1,
        fmt::format("[{}] {}", label, damage));
}

int32 ApplyAutomatonDamageBonus(CBattleEntity* PAttacker, int32 damage)
{
    if (damage > 0 && PAttacker != nullptr && PAttacker->objtype == TYPE_PET &&
        static_cast<CPetEntity*>(PAttacker)->getPetType() == PET_TYPE::AUTOMATON)
    {
        return static_cast<int32>(damage * AUTOMATON_DMG_MULTIPLIER);
    }
    return damage;
}

int32 ApplyRangerDamageAdjust(CBattleEntity* PAttacker, int32 damage, bool isRanged)
{
    if (damage > 0 && isRanged && PAttacker != nullptr && PAttacker->objtype == TYPE_PC &&
        PAttacker->GetMJob() == JOB_RNG)
    {
        return static_cast<int32>(damage * RANGER_RANGED_DMG_MULTIPLIER);
    }
    return damage;
}
