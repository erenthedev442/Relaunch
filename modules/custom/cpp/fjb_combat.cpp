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
#include "common/xirand.h"

#include "map/entities/battleentity.h"
#include "map/entities/charentity.h"
#include "map/entities/petentity.h"
#include "map/enums/chat_message_type.h"
#include "map/items.h"
#include "map/items/item_equipment.h"
#include "map/packets/s2c/0x017_chat_std.h"

#include <algorithm>
#include <cmath>
#include <string>
#include <string_view>

namespace
{
    constexpr int32 TRUST_ENDGAME_MOB_LEVEL_GATE = 120;

    bool IsEligibleEndgameTrust(CBattleEntity* PAttacker)
    {
        if (PAttacker == nullptr || PAttacker->objtype != TYPE_TRUST)
        {
            return false;
        }
        if (PAttacker->GetLocalVar("fellowApplied") == 1)
        {
            return false;
        }
        CBattleEntity* PMaster = PAttacker->PMaster;
        return PMaster != nullptr && PMaster->GetMLevel() >= 99;
    }

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
    constexpr int32 PRIME_ABSOLUTE_DAMAGE_CAP     = 1999999;
    constexpr int32 COMPANION_ABSOLUTE_DAMAGE_CAP = 1499999;
    constexpr int32 FELLOW_ABSOLUTE_DAMAGE_CAP    = 99999;

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
    // raise exceptions (Matsui-P 79999) or EncounterOutgoingDamageCapMB for
    // Shantotto II / Matsui-P magic bursts. Without a localVar, trusts must
    // never inherit the global 999999 PC ceiling.
    if (PAttacker->objtype == TYPE_TRUST)
    {
        constexpr int32 TRUST_DEFAULT_CAP = 40000;
        return globalCap > 0 ? std::min(globalCap, TRUST_DEFAULT_CAP) : TRUST_DEFAULT_CAP;
    }

    // BST/PUP/SMN Lua progression stamps the active weapon-tier ceiling on
    // player-owned pets immediately before damage is applied. This permits the
    // completed Prime tier to exceed the ordinary 999,999 global ceiling while
    // leaving unrelated pets, mobs, trusts and baseline attacks unchanged.
    if (
        PAttacker->objtype == TYPE_PET &&
        PAttacker->PMaster != nullptr &&
        PAttacker->PMaster->objtype == TYPE_PC)
    {
        const auto companionCap =
            static_cast<int32>(PAttacker->GetLocalVar("CompanionDamageCap"));
        if (companionCap > 0)
        {
            const auto boundedCap = std::min(companionCap, COMPANION_ABSOLUTE_DAMAGE_CAP);
            if (globalCap <= 0 || boundedCap <= globalCap)
            {
                return boundedCap;
            }

            auto*      PMaster                 = static_cast<CCharEntity*>(PAttacker->PMaster);
            const auto masterJob               = PMaster->GetMJob();
            const auto* PMainWeapon            = PMaster->getEquip(SLOT_MAIN);
            const auto equippedMainItemId      = PMainWeapon != nullptr ? PMainWeapon->getID() : 0;
            uint16     expectedPrimeMainItemId = 0;
            switch (masterJob)
            {
                case JOB_BST:
                    expectedPrimeMainItemId = 21730; // Spalirisos
                    break;
                case JOB_PUP:
                    expectedPrimeMainItemId = 21535; // Varga Purnikawa
                    break;
                case JOB_SMN:
                    expectedPrimeMainItemId = 22106; // Opashoro
                    break;
                default:
                    break;
            }

            if (
                companionCap == COMPANION_ABSOLUTE_DAMAGE_CAP &&
                equippedMainItemId == expectedPrimeMainItemId)
            {
                return COMPANION_ABSOLUTE_DAMAGE_CAP;
            }

            return globalCap;
        }
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
    // Per-hit roll inside the trust's tier band (% of mob max HP). Defaults to
    // medium (B: 10–15%) when spawn did not stamp a band. Disabled at 99+.
    constexpr int32 DEFAULT_PORTION_BPS_MIN = 1200; // B floor
    constexpr int32 DEFAULT_PORTION_BPS_MAX = 2000; // B ceiling
    constexpr int32 ABS_PORTION_BPS_MIN     = 800;  // C floor
    constexpr int32 ABS_PORTION_BPS_MAX     = 3000; // S ceiling (never >30% mob HP)

    if (damage <= 0 || PAttacker == nullptr || PDefender == nullptr)
    {
        return damage;
    }

    if (PAttacker->objtype != TYPE_TRUST || PDefender->objtype != TYPE_MOB)
    {
        return damage;
    }

    // Adventuring Fellow has its own progression profile.
    if (PAttacker->GetLocalVar("fellowApplied") == 1)
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

    int32 bandMin = static_cast<int32>(PAttacker->GetLocalVar("TrustLevelingPortionBpsMin"));
    int32 bandMax = static_cast<int32>(PAttacker->GetLocalVar("TrustLevelingPortionBpsMax"));
    if (bandMin < ABS_PORTION_BPS_MIN || bandMax > ABS_PORTION_BPS_MAX || bandMin > bandMax)
    {
        bandMin = DEFAULT_PORTION_BPS_MIN;
        bandMax = DEFAULT_PORTION_BPS_MAX;
    }

    int32 portionBps = static_cast<int32>(PAttacker->GetLocalVar("TrustLevelingPortionBps"));
    if (portionBps >= bandMin && portionBps <= bandMax)
    {
        // One-shot stamp from Lua (processDamage) — consume so the next hit re-rolls.
        PAttacker->SetLocalVar("TrustLevelingPortionBps", 0);
    }
    else
    {
        // Inclusive bandMin..bandMax (GetRandomNumber max is exclusive for integrals).
        portionBps = xirand::GetRandomNumber<int32>(bandMin, bandMax + 1);
    }

    const float portion    = static_cast<float>(portionBps) / 10000.0f;
    const int32 portionCap = std::max(1, static_cast<int32>(maxHp * portion));
    return std::min(damage, portionCap);
}

int32 ApplyTrustEndgameSoftClamp(CBattleEntity* PAttacker, int32 damage)
{
    // Compress overshoots: T + (hardCap - T) * (1 - exp(-(dmg - T) / scale)).
    // scale ≈ 40k keeps a raw 80k roll well below a 40k hard cap most of the time.
    constexpr float SOFTCLAMP_SCALE = 40000.0f;
    constexpr int32 DEFAULT_BAND_MIN = 22000;
    constexpr int32 DEFAULT_BAND_MAX = 28000;

    if (damage <= 0 || !IsEligibleEndgameTrust(PAttacker))
    {
        return damage;
    }

    // Auto-attacks (TakePhysicalDamage + skill-replaced HIT_DMG) must never be
    // pulled into WS/nuke soft bands — that looked like every AA hitting 33–40k.
    if (PAttacker->GetLocalVar("TrustOutgoingIsAutoAttack") == 1)
    {
        PAttacker->SetLocalVar("TrustOutgoingIsAutoAttack", 0);
        return damage;
    }

    int32 bandMin = static_cast<int32>(PAttacker->GetLocalVar("TrustSoftBandMin"));
    int32 bandMax = static_cast<int32>(PAttacker->GetLocalVar("TrustSoftBandMax"));
    if (bandMin <= 0 || bandMax < bandMin)
    {
        bandMin = DEFAULT_BAND_MIN;
        bandMax = DEFAULT_BAND_MAX;
    }

    const int32 softTarget = (bandMin == bandMax)
        ? bandMin
        : xirand::GetRandomNumber<int32>(bandMin, bandMax + 1);

    if (damage <= softTarget)
    {
        return damage;
    }

    const int32 globalHpDamageCap = settings::get<int32>("map.GLOBAL_HP_DAMAGE_CAP");
    int32       hardCap           = ResolveOutgoingHpDamageCap(PAttacker, globalHpDamageCap);
    if (hardCap <= softTarget)
    {
        hardCap = softTarget;
    }

    const float overshoot = static_cast<float>(damage - softTarget);
    const float room      = static_cast<float>(hardCap - softTarget);
    const float compressed =
        static_cast<float>(softTarget) + room * (1.0f - std::exp(-overshoot / SOFTCLAMP_SCALE));

    // Tiny jitter so soft-band-top hits are not identical every time.
    const float jitter = xirand::GetRandomNumber(0.97f, 1.03f);
    return std::max(1, static_cast<int32>(compressed * jitter));
}

int32 ApplyTrustEndgameLevelDamageMult(CBattleEntity* PAttacker, CBattleEntity* PDefender, int32 damage)
{
    if (damage <= 0 || PDefender == nullptr || !IsEligibleEndgameTrust(PAttacker))
    {
        return damage;
    }

    // Support / aura / utility trusts keep healing and utility; DD roles fall off.
    if (PAttacker->GetLocalVar("TrustDdRole") != 1)
    {
        return damage;
    }

    if (PDefender->objtype != TYPE_MOB)
    {
        return damage;
    }

    const int32 mobLvl = PDefender->GetMLevel();
    if (mobLvl <= TRUST_ENDGAME_MOB_LEVEL_GATE)
    {
        return damage;
    }

    const int32 over = mobLvl - TRUST_ENDGAME_MOB_LEVEL_GATE;
    const float mult = std::clamp(1.0f - 0.06f * static_cast<float>(over), 0.20f, 1.0f);
    return std::max(1, static_cast<int32>(damage * mult));
}

uint8 ApplyTrustEndgameHitRateAdjust(CBattleEntity* PAttacker, CBattleEntity* PDefender, uint8 hitrate)
{
    if (PDefender == nullptr || !IsEligibleEndgameTrust(PAttacker))
    {
        return hitrate;
    }

    if (PDefender->objtype != TYPE_MOB)
    {
        return hitrate;
    }

    const int32 mobLvl = PDefender->GetMLevel();
    if (mobLvl <= TRUST_ENDGAME_MOB_LEVEL_GATE)
    {
        // Reliable hits through level 120; shadows / forced misses are elsewhere.
        return static_cast<uint8>(std::max<int32>(hitrate, 95));
    }

    const int32 over = mobLvl - TRUST_ENDGAME_MOB_LEVEL_GATE;
    const float mult = std::clamp(1.0f - 0.08f * static_cast<float>(over), 0.15f, 1.0f);
    return static_cast<uint8>(std::clamp(static_cast<int32>(std::floor(hitrate * mult)), 5, 100));
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

int32 ApplyAutomatonDamageBonus(CBattleEntity* /* PAttacker */, int32 damage)
{
    // Automaton strength is supplied by its frame, attachments and maneuvers.
    // Keep this compatibility hook neutral so callers do not grant every frame
    // the same unconditional damage multiplier.
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
    // At 99: 0.55 keeps under player AA but still chips / builds TP.
    // While leveling: lower so S-tier DA/TA (Darrcuiln etc.) can't outpace hybrid
    // trusts like Matsui-P that already sit on a softer melee package.
    constexpr float TRUST_AA_MULT_ENDGAME  = 0.55f;
    constexpr float TRUST_AA_MULT_LEVELING = 0.28f;

    if (damage <= 0 || PAttacker == nullptr || PAttacker->objtype != TYPE_TRUST)
    {
        return damage;
    }

    // Custom Adventuring Fellow keeps its own tuned auto profile.
    if (PAttacker->GetLocalVar("fellowApplied") == 1)
    {
        return damage;
    }

    float mult = TRUST_AA_MULT_ENDGAME;
    CBattleEntity* PMaster = PAttacker->PMaster;
    if (PMaster != nullptr && PMaster->GetMLevel() < 99)
    {
        mult = TRUST_AA_MULT_LEVELING;
    }

    return std::max(1, static_cast<int32>(damage * mult));
}
