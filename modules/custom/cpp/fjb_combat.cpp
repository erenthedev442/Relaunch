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

    // Encounter-owned NPCs / trusts can impose a lower per-event ceiling across
    // every ordinary damage path: melee, spells, TP moves, and additional effects.
    // Magic bursts may use a raised ceiling (e.g. Shantotto II MB → 79,999) when
    // OutgoingDamageIsMagicBurst is set for the takeDamage call.
    const auto encounterCap =
        static_cast<int32>(PAttacker->GetLocalVar("EncounterOutgoingDamageCap"));
    const auto encounterMbCap =
        static_cast<int32>(PAttacker->GetLocalVar("EncounterOutgoingDamageCapMB"));
    const bool isMagicBurst =
        PAttacker->GetLocalVar("OutgoingDamageIsMagicBurst") == 1;

    if (isMagicBurst && encounterMbCap > 0)
    {
        return globalCap > 0 ? std::min(globalCap, encounterMbCap) : encounterMbCap;
    }

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

    // Hard default for all alter egos. Lua sets EncounterOutgoingDamageCap to
    // raise exceptions (Matsui-P 99999) or EncounterOutgoingDamageCapMB for
    // Shantotto II magic bursts. Without a localVar, trusts must never inherit
    // the global 999999 PC ceiling.
    if (PAttacker->objtype == TYPE_TRUST)
    {
        constexpr int32 TRUST_DEFAULT_CAP = 40000;
        return globalCap > 0 ? std::min(globalCap, TRUST_DEFAULT_CAP) : TRUST_DEFAULT_CAP;
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

int32 ApplyTrustLevelingHpPortionCap(CBattleEntity* PAttacker, CBattleEntity* PDefender, int32 damage)
{
    constexpr float TRUST_LEVELING_MAX_HP_PORTION = 0.30f;

    if (damage <= 0 || PAttacker == nullptr || PDefender == nullptr)
    {
        return damage;
    }

    if (PAttacker->objtype != TYPE_TRUST || PDefender->objtype != TYPE_MOB)
    {
        return damage;
    }

    CBattleEntity* PMaster = PAttacker->PMaster;
    if (PMaster == nullptr || PMaster->GetMLevel() >= 99)
    {
        return damage;
    }

    const int32 maxHp = PDefender->GetMaxHP();
    if (maxHp <= 0)
    {
        return damage;
    }

    const int32 portionCap = std::max(1, static_cast<int32>(maxHp * TRUST_LEVELING_MAX_HP_PORTION));
    return std::min(damage, portionCap);
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
        // Preserve the active standard-WS ceiling. The post-Lua 0.80 adjustment
        // must not reduce a capped 40,000/79,999/premium-AoE result.
        const auto standardWsCap = static_cast<int32>(PAttacker->GetLocalVar("StandardWsDamageCap"));
        if (standardWsCap > 0 && damage >= standardWsCap)
        {
            return standardWsCap;
        }

        return static_cast<int32>(damage * RANGER_RANGED_DMG_MULTIPLIER);
    }
    return damage;
}

int32 ApplyTrustAutoAttackDamageAdjust(CBattleEntity* PAttacker, int32 damage)
{
    // Auto-swings only — wired exclusively from TakePhysicalDamage, not WS/magic.
    constexpr float TRUST_AUTO_ATTACK_MULTIPLIER = 0.25f;

    if (damage <= 0 || PAttacker == nullptr || PAttacker->objtype != TYPE_TRUST)
    {
        return damage;
    }

    // Custom Adventuring Fellow keeps its own tuned auto profile.
    if (PAttacker->GetLocalVar("fellowApplied") == 1)
    {
        return damage;
    }

    return std::max(1, static_cast<int32>(damage * TRUST_AUTO_ATTACK_MULTIPLIER));
}
