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
#include "common/settings.h"

#include "map/entities/battleentity.h"
#include "map/entities/charentity.h"
#include "map/entities/petentity.h"
#include "map/enums/chat_message_type.h"
#include "map/packets/s2c/0x017_chat_std.h"

#include <algorithm>
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
    // 2026-07-13: owner call to cut the boost by 80%. The "boost" is the delta above
    // baseline 1.0x, so 5.0x (boost +4.0) -> 1.8x (boost +0.8). Small headroom over
    // stock damage; stat block in petutils.cpp got the same 80% trim in the same pass.
    constexpr float AUTOMATON_DMG_MULTIPLIER = 1.8f;

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

int32 ResolveOutgoingHpDamageCap(CBattleEntity* PAttacker, int32 globalCap)
{
    constexpr int32 PRIME_ABSOLUTE_DAMAGE_CAP  = 1999999;
    constexpr int32 FELLOW_ABSOLUTE_DAMAGE_CAP = 99999;

    if (PAttacker == nullptr)
    {
        return globalCap;
    }

    // Encounter-owned NPCs can impose a lower per-event ceiling across every
    // ordinary damage path: melee, spells, TP moves, and additional effects.
    const auto encounterCap =
        static_cast<int32>(PAttacker->GetLocalVar("EncounterOutgoingDamageCap"));
    if (encounterCap > 0)
    {
        return globalCap > 0 ? std::min(globalCap, encounterCap) : encounterCap;
    }

    // The custom Adventuring Fellow is implemented as a trust and marked by
    // fellow_companion.lua. Cap every damage path at the final takeDamage()
    // choke point: melee, ranged, spells, mob skills, AoE and skillchains.
    if (PAttacker->GetLocalVar("fellowApplied") == 1)
    {
        return globalCap > 0
            ? std::min(globalCap, FELLOW_ABSOLUTE_DAMAGE_CAP)
            : FELLOW_ABSOLUTE_DAMAGE_CAP;
    }

    if (PAttacker->objtype != TYPE_PC)
    {
        return globalCap;
    }

    int32 effectiveCap = globalCap;

    const auto primeCap = static_cast<int32>(PAttacker->GetLocalVar("PrimeWsDamageCap"));
    if (effectiveCap > 0 && primeCap > effectiveCap)
    {
        effectiveCap = std::min(primeCap, PRIME_ABSOLUTE_DAMAGE_CAP);
    }

    // These synchronous WS windows are restrictive ceilings. Apply them after
    // Prime's optional raised ceiling so a capped AoE/Final-Ambuscade WS can
    // never inherit a higher cap.
    const auto aoeWsCap = static_cast<int32>(PAttacker->GetLocalVar("AoEWsDamageCap"));
    if (aoeWsCap > 0 && (effectiveCap <= 0 || aoeWsCap < effectiveCap))
    {
        effectiveCap = aoeWsCap;
    }

    const auto ambuscadeWsCap = static_cast<int32>(PAttacker->GetLocalVar("AmbuscadeWsDamageCap"));
    if (ambuscadeWsCap > 0 && (effectiveCap <= 0 || ambuscadeWsCap < effectiveCap))
    {
        effectiveCap = ambuscadeWsCap;
    }

    const auto standardWsCap = static_cast<int32>(PAttacker->GetLocalVar("StandardWsDamageCap"));
    if (standardWsCap > 0 && (effectiveCap <= 0 || standardWsCap < effectiveCap))
    {
        effectiveCap = standardWsCap;
    }

    return effectiveCap;
}

void NotifyOverCapDamage(CBattleEntity* PAttacker, int32 damage, std::string_view type)
{
    const int32 globalHpDamageCap = settings::get<int32>("map.GLOBAL_HP_DAMAGE_CAP");
    const int32 effectiveDamageCap = ResolveOutgoingHpDamageCap(PAttacker, globalHpDamageCap);
    if (damage > 0 && effectiveDamageCap > 0)
    {
        damage = std::min(damage, effectiveDamageCap);
    }

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
        // Preserve the intended 99,999 standard-WS ceiling. Previously the
        // post-Lua 0.80 adjustment turned a capped ranged WS into 79,999.
        const auto standardWsCap = static_cast<int32>(PAttacker->GetLocalVar("StandardWsDamageCap"));
        if (standardWsCap == 99999 && damage >= standardWsCap)
        {
            return standardWsCap;
        }

        return static_cast<int32>(damage * RANGER_RANGED_DMG_MULTIPLIER);
    }
    return damage;
}
