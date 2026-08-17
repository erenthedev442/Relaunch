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

#include "automaton_controller.h"

#include "ai/ai_container.h"
#include "ai/states/ability_state.h"
#include "ai/states/magic_state.h"
#include "ai/states/weaponskill_state.h"
#include "common/database.h"
#include "common/utils.h"
#include "enmity_container.h"
#include "entities/trustentity.h"
#include "enums/automaton.h"
#include "lua/luautils.h"
#include "mob_spell_container.h"
#include "mobskill.h"
#include "recast_container.h"
#include "status_effect_container.h"
#include "utils/battleutils.h"
#include "utils/itemutils.h"
#include "utils/petutils.h"
#include "utils/puppetutils.h"

namespace
{
    constexpr timer::duration AUTOMATON_SKILLCHAIN_HOLD_MAX = 12s;
    constexpr timer::duration AUTOMATON_MAGIC_COOLDOWN_FLOOR = 1s;
    constexpr auto            AUTOMATON_ATTACHMENT_ACTIVATED  = "AutomatonAttachmentActivated";
    constexpr auto            AUTOMATON_ATTACHMENT_CHECKING   = "AutomatonAttachmentChecking";

    timer::duration GetAdjustedMagicCooldown(timer::duration cooldown, int16 delay)
    {
        return std::max(AUTOMATON_MAGIC_COOLDOWN_FLOOR, cooldown - std::chrono::seconds(delay));
    }

    uint16 GetAutomatonBaseWs(AutomatonFrame frame)
    {
        switch (frame)
        {
            case AutomatonFrame::Harlequin:  return 1943; // Slapstick
            case AutomatonFrame::Valoredge:  return 1940; // Chimera Ripper
            case AutomatonFrame::Sharpshot:  return 1942; // Arcuballista
            case AutomatonFrame::Stormwaker: return 1943; // Slapstick
            default:                         return 0;
        }
    }

    // Explicit retail-style priority for tied maneuver counts. Unknown future
    // moves retain their required-skill ordering as a safe fallback.
    int16 GetAutomatonWsPriority(uint16 skillId, int16 fallback)
    {
        switch (skillId)
        {
            case 2744: return 500; // Armor Shatterer
            case 2743: return 500; // String Shredder
            case 2301: return 400; // Magic Mortar
            case 2300: return 400; // Armor Piercer
            case 2299: return 400; // Bone Crusher
            case 2067: return 300; // Knockout
            case 2066: return 300; // Daze
            case 2065: return 300; // Cannibal Blade
            case 1942: return 200; // Arcuballista
            case 1941: return 200; // String Clipper
            case 1940: return 100; // Chimera Ripper
            case 1943: return 100; // Slapstick
            default:   return fallback;
        }
    }
}

CAutomatonController::CAutomatonController(CAutomatonEntity* PPet)
: CPetController(PPet)
, PAutomaton(PPet)
{
    setCooldowns();
    if (shouldStandBack())
    {
        PAutomaton->m_Behavior |= BEHAVIOR_STANDBACK;
    }
}

void CAutomatonController::setCooldowns()
{
    switch (PAutomaton->getFrame())
    {
        case AutomatonFrame::Sharpshot:
        {
            switch (PAutomaton->getHead())
            {
                case AutomatonHead::Sharpshot:
                    m_rangedCooldown = 20s;
                    break;
                case AutomatonHead::Harlequin:
                    m_rangedCooldown = 25s;
                    break;
                default:
                    m_rangedCooldown = 36s;
            }
        }
        break;
        case AutomatonFrame::Harlequin:
        {
            setMagicCooldowns();
        }
        break;
        case AutomatonFrame::Stormwaker:
        {
            setMagicCooldowns();
        }
        break;
        case AutomatonFrame::Valoredge:
        {
            m_shieldbashCooldown = 3min;
        }
    }
}

// New retail Automaton magic AI (Needs more information to accurately recreate)
void CAutomatonController::setMagicCooldowns()
{
    switch (PAutomaton->getHead())
    {
        case AutomatonHead::Harlequin:
        {
            m_magicCooldown    = 10s;
            m_enfeebleCooldown = 10s;
            m_healCooldown     = 15s;
        }
        break;
        case AutomatonHead::Valoredge:
        {
            m_magicCooldown = 20s;
            m_healCooldown  = 20s;
        }
        break;
        case AutomatonHead::Sharpshot:
        {
            m_magicCooldown    = 12s;
            m_enfeebleCooldown = 12s;
            m_healCooldown     = 18s; // Guess
        }
        break;
        case AutomatonHead::Stormwaker:
        {
            m_magicCooldown     = 10s;
            m_enfeebleCooldown  = 12s;
            m_healCooldown      = 15s; // Guess
            m_elementalCooldown = 33s; // Guess
            m_enhanceCooldown   = 10s; // Guess
        }
        break;
        case AutomatonHead::Soulsoother:
        {
            m_magicCooldown    = 4s;
            m_enfeebleCooldown = 4s;
            m_healCooldown     = 15s;
            m_enhanceCooldown  = 15s;
            m_statusCooldown   = 15s;
        }
        break;
        case AutomatonHead::Spiritreaver:
        {
            m_magicCooldown     = 10s;
            m_enfeebleCooldown  = 10s;
            m_elementalCooldown = 33s;
            m_enhanceCooldown   = 135s;
        }
    }
}

// Determines standback behavior for the Automaton.
// Animators override all behavior, Valor Edge frame will always enter melee, followed
// by ranged head types defaulting to ranged behavior.
auto CAutomatonController::shouldStandBack() const -> bool
{
    const CBattleEntity* PMaster = PAutomaton->PMaster;

    if (PMaster)
    {
        CItemWeapon* animator = dynamic_cast<CItemWeapon*>(PMaster->m_Weapons[SLOT_RANGED]);

        if (animator &&
            (animator->getSubSkillType() == SUBSKILLTYPE::SUBSKILL_ANIMATOR ||
             animator->getSubSkillType() == SUBSKILLTYPE::SUBSKILL_ANIMATOR_II))
        {
            return true;
        }
    }

    if (PAutomaton->getFrame() == AutomatonFrame::Valoredge)
    {
        return false;
    }

    switch (PAutomaton->getHead())
    {
        case AutomatonHead::Sharpshot:
        case AutomatonHead::Stormwaker:
        case AutomatonHead::Soulsoother:
        case AutomatonHead::Spiritreaver:
            return true;
        default:
            return false;
    }
}

auto CAutomatonController::GetCurrentManeuvers() const -> CurrentManeuvers
{
    const auto& statuses = PAutomaton->PMaster->StatusEffectContainer;
    return {
        statuses->GetEffectsCount(EFFECT_FIRE_MANEUVER),
        statuses->GetEffectsCount(EFFECT_ICE_MANEUVER),
        statuses->GetEffectsCount(EFFECT_WIND_MANEUVER),
        statuses->GetEffectsCount(EFFECT_EARTH_MANEUVER),
        statuses->GetEffectsCount(EFFECT_THUNDER_MANEUVER),
        statuses->GetEffectsCount(EFFECT_WATER_MANEUVER),
        statuses->GetEffectsCount(EFFECT_LIGHT_MANEUVER),
        statuses->GetEffectsCount(EFFECT_DARK_MANEUVER),
    };
}

auto CAutomatonController::DoCombatTick(timer::time_point tick) -> Task<void>
{
    if (PAutomaton->PMaster == nullptr)
    {
        if (PAutomaton->isAlive())
        {
            PAutomaton->Die();
        }

        co_return;
    }

    PTarget = static_cast<CBattleEntity*>(PAutomaton->GetEntity(PAutomaton->GetBattleTargetID()));

    if (TryDeaggro())
    {
        Disengage();
        co_return;
    }

    // Automatons only attempt actions in 3 second intervals (Reduced by the Tactical Processor)
    if (TryAction())
    {
        auto maneuvers = GetCurrentManeuvers();

        if (TryAttachment())
        {
            co_return;
        }
        else if (TryShieldBash())
        {
            m_LastShieldBashTime = m_Tick;
            co_return;
        }
        else if (TrySpellcast(maneuvers))
        {
            m_LastMagicTime = m_Tick;
            co_return;
        }
        else if (TryTPMove())
        {
            co_return;
        }
        else if (TryRangedAttack())
        {
            m_LastRangedTime = m_Tick;
            co_return;
        }
    }

    Move();
}

void CAutomatonController::Move()
{
    if ((shouldStandBack() && !isWithinDistance(PAutomaton->loc.p, PTarget->loc.p, 15.0f)) ||
        (PAutomaton->health.mp < 8 && PAutomaton->health.maxmp > 8))
    {
        PAutomaton->m_Behavior &= ~BEHAVIOR_STANDBACK;
    }

    CPetController::Move();
}

auto CAutomatonController::TryAction() -> bool
{
    if (m_Tick > m_LastActionTime + (m_actionCooldown - std::chrono::milliseconds(PAutomaton->getMod(Mod::AUTO_DECISION_DELAY) * 10)))
    {
        m_LastActionTime = m_Tick;
        PAutomaton->PAI->EventHandler.triggerListener("AUTOMATON_AI_TICK", PAutomaton, PTarget);

        return true;
    }

    return false;
}

auto CAutomatonController::TryShieldBash() -> bool
{
    CState* PState = PTarget->PAI->GetCurrentState();

    if (m_shieldbashCooldown > 0s && PState && PState->CanInterrupt() &&
        m_Tick > m_LastShieldBashTime + (m_shieldbashCooldown - std::chrono::seconds(PAutomaton->getMod(Mod::AUTO_SHIELD_BASH_DELAY))))
    {
        return MobSkill(PTarget->targid, m_ShieldBashAbility, std::nullopt);
    }

    return false;
}

auto CAutomatonController::TrySpellcast(const CurrentManeuvers& maneuvers) -> bool
{
    // Apparently the automaton has nothing in its spell list, so CanCastSpells must ignore spell lists and recasts?
    const auto magicCooldown = GetAdjustedMagicCooldown(m_magicCooldown, PAutomaton->getMod(Mod::AUTO_MAGIC_DELAY));
    if (!PAutomaton->PMaster || m_magicCooldown == 0s ||
        m_Tick <= m_LastMagicTime + magicCooldown || !CanCastSpells(IgnoreRecastsAndCosts::Yes))
    {
        return false;
    }

    switch (PAutomaton->getHead())
    {
        case AutomatonHead::Valoredge:
        {
            if (TryHeal(maneuvers))
            {
                m_LastHealTime = m_Tick;
                return true;
            }
        }
        break;
        case AutomatonHead::Sharpshot:
        {
            if (maneuvers.light && TryHeal(maneuvers)) // Light -> Heal
            {
                m_LastHealTime = m_Tick;
                return true;
            }

            if (TryEnfeeble(maneuvers))
            {
                m_LastEnfeebleTime = m_Tick;
                return true;
            }
            else if (!maneuvers.light && TryHeal(maneuvers))
            {
                m_LastHealTime = m_Tick;
                return true;
            }
        }
        break;
        case AutomatonHead::Harlequin:
        {
            if (maneuvers.light && TryHeal(maneuvers)) // Light -> Heal
            {
                m_LastHealTime = m_Tick;
                return true;
            }

            if (TryEnfeeble(maneuvers))
            {
                m_LastEnfeebleTime = m_Tick;
                return true;
            }
            else if (!maneuvers.light && TryHeal(maneuvers))
            {
                m_LastHealTime = m_Tick;
                return true;
            }
        }
        break;
        case AutomatonHead::Stormwaker:
        {
            bool lowHP = PTarget->GetHPP() <= 30 && PTarget->health.hp <= 300;
            if (lowHP && TryElemental(maneuvers)) // Mob low HP -> Nuke
            {
                m_LastElementalTime = m_Tick;
                return true;
            }

            if (maneuvers.light && TryHeal(maneuvers)) // Light -> Heal
            {
                m_LastHealTime = m_Tick;
                return true;
            }
            else if (!lowHP && maneuvers.ice && TryElemental(maneuvers)) // Ice -> Nuke
            {
                m_LastElementalTime = m_Tick;
                return true;
            }

            if (TryEnfeeble(maneuvers))
            {
                m_LastEnfeebleTime = m_Tick;
                return true;
            }
            else if (!maneuvers.light && TryHeal(maneuvers))
            {
                m_LastHealTime = m_Tick;
                return true;
            }
            else if (!lowHP && !maneuvers.ice && TryElemental(maneuvers))
            {
                m_LastElementalTime = m_Tick;
                return true;
            }
            else if (TryEnhance())
            {
                m_LastEnhanceTime = m_Tick;
                return true;
            }
        }
        break;
        case AutomatonHead::Soulsoother:
        {
            if (maneuvers.light && TryHeal(maneuvers)) // Light -> Heal
            {
                m_LastHealTime = m_Tick;
                return true;
            }

            if (TryStatusRemoval(maneuvers))
            {
                m_LastStatusTime = m_Tick;
                return true;
            }
            else if (!maneuvers.light && TryHeal(maneuvers))
            {
                m_LastHealTime = m_Tick;
                return true;
            }
            else if (TryEnhance())
            {
                m_LastEnhanceTime = m_Tick;
                return true;
            }
            else if (TryEnfeeble(maneuvers))
            {
                m_LastEnfeebleTime = m_Tick;
                return true;
            }
        }
        break;
        case AutomatonHead::Spiritreaver:
        {
            if (maneuvers.ice && TryElemental(maneuvers)) // Ice -> Nuke
            {
                m_LastElementalTime = m_Tick;
                return true;
            }
            else if (maneuvers.dark && TryEnhance())
            {
                m_LastEnhanceTime = m_Tick;
                return true;
            }
            else if ((maneuvers.dark || PAutomaton->GetHPP() < 75 || PAutomaton->GetMPP() < 75) &&
                     TryEnfeeble(maneuvers)) // Dark or self HPP/MPP < 75 -> Enfeeble
            {
                m_LastEnfeebleTime = m_Tick;
                return true;
            }

            if (!maneuvers.ice && TryElemental(maneuvers))
            {
                m_LastElementalTime = m_Tick;
                return true;
            }
        }
    }
    return false;
}

auto CAutomatonController::TryHeal(const CurrentManeuvers& maneuvers) -> bool
{
    const auto healDelay = PAutomaton->getMod(Mod::AUTO_HEALING_DELAY) + PAutomaton->getMod(Mod::AUTO_MAGIC_DELAY);
    if (!PAutomaton->PMaster || m_healCooldown == 0s ||
        m_Tick <= m_LastHealTime + GetAdjustedMagicCooldown(m_healCooldown, healDelay))
    {
        return false;
    }

    float threshold = 0;
    switch (maneuvers.light) // Light -> Higher healing threshold
    {
        case 1:
            threshold = 40;
            break;
        case 2:
            threshold = 50;
            break;
        case 3:
            threshold = 75;
            break;
        default:
            threshold = 30;
            break;
    }

    threshold                  = std::clamp<float>(threshold + PAutomaton->getMod(Mod::AUTO_HEALING_THRESHOLD), 30.0f, 90.0f);
    CBattleEntity* PCastTarget = nullptr;
    uint8          lowestHpp   = 101;

    const auto considerTarget = [&](CBattleEntity* PCandidate, float candidateThreshold)
    {
        if (PCandidate && PCandidate->isAlive() && PCandidate->GetHPP() <= candidateThreshold &&
            distance(PAutomaton->loc.p, PCandidate->loc.p) < 20.0f &&
            (PCandidate->GetHPP() < lowestHpp || (PCandidate->GetHPP() == lowestHpp && (!PCastTarget || PCandidate->id < PCastTarget->id))))
        {
            PCastTarget = PCandidate;
            lowestHpp   = PCandidate->GetHPP();
        }
    };

    considerTarget(PAutomaton, 50.0f);
    considerTarget(PAutomaton->PMaster, threshold);

    // Light + Soulsoother head extends healing selection to party members and trusts.
    if (maneuvers.light && PAutomaton->getHead() == AutomatonHead::Soulsoother)
    {
        if (auto* PMaster = dynamic_cast<CCharEntity*>(PAutomaton->PMaster))
        {
            PMaster->ForPartyWithTrusts([&](CBattleEntity* PMember)
            {
                considerTarget(PMember, threshold);
            });
        }
    }

    // This might be wrong
    if (PCastTarget)
    {
        auto missinghp = PCastTarget->GetMaxHP() - PCastTarget->health.hp;
        if (missinghp > 850 && Cast(PCastTarget->targid, SpellID::Cure_VI))
        {
            return true;
        }
        else if (missinghp > 600 && Cast(PCastTarget->targid, SpellID::Cure_V))
        {
            return true;
        }
        else if (missinghp > 350 && Cast(PCastTarget->targid, SpellID::Cure_IV))
        {
            return true;
        }
        else if (missinghp > 190 && Cast(PCastTarget->targid, SpellID::Cure_III))
        {
            return true;
        }
        else if (missinghp > 120 && Cast(PCastTarget->targid, SpellID::Cure_II))
        {
            return true;
        }
        else if (Cast(PCastTarget->targid, SpellID::Cure))
        {
            return true;
        }
    }

    return false;
}

inline auto resistanceComparator(const std::pair<SpellID, int16>& firstElem, const std::pair<SpellID, int16>& secondElem) -> bool
{
    return firstElem.second < secondElem.second;
}

auto CAutomatonController::TryElemental(const CurrentManeuvers& maneuvers) -> bool
{
    if (!PAutomaton->PMaster || m_elementalCooldown == 0s ||
        m_Tick <= m_LastElementalTime + GetAdjustedMagicCooldown(m_elementalCooldown, PAutomaton->getMod(Mod::AUTO_MAGIC_DELAY)))
    {
        return false;
    }

    std::vector<SpellID> castPriority;
    std::vector<SpellID> defaultPriority;

    int8        tier   = 4;
    const int32 hp     = PTarget->health.hp;
    const int32 selfmp = PAutomaton->health.mp; // Shortcut for wasting less time
    if (selfmp < 4)
    {
        return false;
    }
    else if (hp <= 50 || selfmp < 16)
    {
        tier = 0;
    }
    else if (hp <= 150 || selfmp < 40)
    {
        tier = 1;
    }
    else if (hp <= 200 || selfmp < 88)
    {
        tier = 2;
    }
    else if (hp <= 600 || selfmp < 156)
    {
        tier = 3;
    }

    if (PAutomaton->getMod(Mod::AUTO_SCAN_RESISTS))
    {
        std::vector<std::pair<SpellID, int16>> reslist{
            std::make_pair(SpellID::Fire, PTarget->getMod(Mod::FIRE_RES_RANK)),
            std::make_pair(SpellID::Blizzard, PTarget->getMod(Mod::ICE_RES_RANK)),
            std::make_pair(SpellID::Aero, PTarget->getMod(Mod::WIND_RES_RANK)),
            std::make_pair(SpellID::Stone, PTarget->getMod(Mod::EARTH_RES_RANK)),
            std::make_pair(SpellID::Thunder, PTarget->getMod(Mod::THUNDER_RES_RANK)),
            std::make_pair(SpellID::Water, PTarget->getMod(Mod::WATER_RES_RANK)),
        };
        std::stable_sort(reslist.begin(), reslist.end(), resistanceComparator);
        for (std::pair<SpellID, int16>& res : reslist)
        {
            castPriority.emplace_back(res.first);
        }
    }
    else if (PAutomaton->getHead() == AutomatonHead::Spiritreaver)
    {
        if (maneuvers.thunder)
        { // Thunder -> Thunder spells
            castPriority.emplace_back(SpellID::Thunder);
        }
        else
        {
            defaultPriority.emplace_back(SpellID::Thunder);
        }

        if (maneuvers.ice)
        { // Ice -> Blizzard spells
            castPriority.emplace_back(SpellID::Blizzard);
        }
        else
        {
            defaultPriority.emplace_back(SpellID::Blizzard);
        }

        if (maneuvers.fire)
        { // Fire -> Fire spells
            castPriority.emplace_back(SpellID::Fire);
        }
        else
        {
            defaultPriority.emplace_back(SpellID::Fire);
        }

        if (maneuvers.wind)
        { // Wind -> Aero spells
            castPriority.emplace_back(SpellID::Aero);
        }
        else
        {
            defaultPriority.emplace_back(SpellID::Aero);
        }

        if (maneuvers.water)
        { // Water -> Water spells
            castPriority.emplace_back(SpellID::Water);
        }
        else
        {
            defaultPriority.emplace_back(SpellID::Water);
        }

        if (maneuvers.earth)
        { // Earth -> Stone spells
            castPriority.emplace_back(SpellID::Stone);
        }
        else
        {
            defaultPriority.emplace_back(SpellID::Stone);
        }
    }
    else
    {
        defaultPriority = { SpellID::Thunder, SpellID::Blizzard, SpellID::Fire, SpellID::Aero, SpellID::Water, SpellID::Stone };
    }

    for (int8 i = tier; i >= 0; --i)
    {
        for (SpellID& id : castPriority)
        {
            if (Cast(PTarget->targid, static_cast<SpellID>(static_cast<uint16>(id) + i)))
            {
                return true;
            }
        }

        for (SpellID& id : defaultPriority)
        {
            if (Cast(PTarget->targid, static_cast<SpellID>(static_cast<uint16>(id) + i)))
            {
                return true;
            }
        }
    }

    return false;
}

auto CAutomatonController::TryEnfeeble(const CurrentManeuvers& maneuvers) -> bool
{
    if (!PAutomaton->PMaster || m_enfeebleCooldown == 0s ||
        m_Tick <= m_LastEnfeebleTime + GetAdjustedMagicCooldown(m_enfeebleCooldown, PAutomaton->getMod(Mod::AUTO_MAGIC_DELAY)))
    {
        return false;
    }

    std::vector<SpellID> castPriority;
    std::vector<SpellID> defaultPriority;

    switch (PAutomaton->getHead())
    {
        case AutomatonHead::Stormwaker:
        {
            bool dispel = false;
            // clang-format off
            PTarget->StatusEffectContainer->ForEachEffect([&dispel](CStatusEffect* PStatus)
            {
                if (!dispel && PStatus->GetDuration() > 0s)
                {
                    if (PStatus->HasEffectFlag(EFFECTFLAG_DISPELABLE))
                    {
                        dispel = true;
                        return;
                    }
                }
            });
            // clang-format on
            if (dispel)
            {
                castPriority.emplace_back(SpellID::Dispel);
            }
            break;
        }
        default:
        {
            if (!PTarget->StatusEffectContainer->HasStatusEffect(EFFECT_DIA))
            {
                if (maneuvers.dark) // Dark -> Bio
                {
                    castPriority.emplace_back(SpellID::Bio_II);
                }
                else
                {
                    defaultPriority.emplace_back(SpellID::Bio_II);
                }
            }

            if (!PTarget->StatusEffectContainer->HasStatusEffect(EFFECT_BIO))
            {
                if (maneuvers.light)
                {
                    castPriority.emplace_back(SpellID::Dia_II);
                }
                else
                {
                    defaultPriority.emplace_back(SpellID::Dia_II);
                }
            }

            if (!PTarget->StatusEffectContainer->HasStatusEffect(EFFECT_DIA))
            {
                if (maneuvers.dark) // Dark -> Bio
                {
                    castPriority.emplace_back(SpellID::Bio);
                }
                else
                {
                    defaultPriority.emplace_back(SpellID::Bio);
                }
            }

            if (!PTarget->StatusEffectContainer->HasStatusEffect(EFFECT_BIO))
            {
                if (maneuvers.light)
                {
                    castPriority.emplace_back(SpellID::Dia);
                }
                else
                {
                    defaultPriority.emplace_back(SpellID::Dia);
                }
            }

            if (maneuvers.water) // Water -> Poison
            {
                castPriority.emplace_back(SpellID::Poison_II);
                castPriority.emplace_back(SpellID::Poison);
            }
            else
            {
                defaultPriority.emplace_back(SpellID::Poison_II);
                defaultPriority.emplace_back(SpellID::Poison);
            }

            if (maneuvers.wind)
            { // Wind -> Silence
                castPriority.emplace_back(SpellID::Silence);
            }
            else
            {
                defaultPriority.emplace_back(SpellID::Silence);
            }

            if (maneuvers.earth)
            { // Earth -> Slow
                castPriority.emplace_back(SpellID::Slow);
            }
            else
            {
                defaultPriority.emplace_back(SpellID::Slow);
            }

            if (maneuvers.dark)
            { // Dark -> Blind
                castPriority.emplace_back(SpellID::Blind);
            }
            else
            {
                defaultPriority.emplace_back(SpellID::Blind);
            }

            if (maneuvers.ice)
            { // Ice -> Paralyze
                castPriority.emplace_back(SpellID::Paralyze);
            }
            else
            {
                defaultPriority.emplace_back(SpellID::Paralyze);
            }

            if (maneuvers.fire)
            { // Fire -> Addle
                castPriority.emplace_back(SpellID::Addle);
            }
            else
            {
                defaultPriority.emplace_back(SpellID::Addle);
            }
            break;
        }
        case AutomatonHead::Spiritreaver:
        {
            if (PAutomaton->GetMPP() < 75 && PTarget->health.mp > 0) // MPP < 75 -> Aspir
            {
                castPriority.emplace_back(SpellID::Aspir_II);
                castPriority.emplace_back(SpellID::Aspir);
            }

            if (PAutomaton->GetHPP() < 75 && PTarget->m_EcoSystem != ECOSYSTEM::UNDEAD)
            { // HPP <= 75 -> Drain
                castPriority.emplace_back(SpellID::Drain);
            }

            if (maneuvers.dark) // Dark -> Access to Enfeebles
            {
                if (!PAutomaton->StatusEffectContainer->HasStatusEffect(EFFECT_INT_BOOST))
                { // Use it ASAP
                    defaultPriority.emplace_back(SpellID::Absorb_INT);
                }

                // Not prioritizable since it requires 1 Dark to access Enfeebles and requires 2 of another element to prioritize another
                defaultPriority.emplace_back(SpellID::Blind);
                if (!PTarget->StatusEffectContainer->HasStatusEffect(EFFECT_DIA))
                {
                    defaultPriority.emplace_back(SpellID::Bio_II);
                }

                if (!PTarget->StatusEffectContainer->HasStatusEffect(EFFECT_BIO))
                {
                    if (maneuvers.light >= 2) // 2 Light -> Dia
                    {
                        castPriority.emplace_back(SpellID::Dia_II);
                    }
                    else
                    {
                        defaultPriority.emplace_back(SpellID::Dia_II);
                    }
                }
                if (!PTarget->StatusEffectContainer->HasStatusEffect(EFFECT_DIA))
                {
                    defaultPriority.emplace_back(SpellID::Bio);
                }

                if (!PTarget->StatusEffectContainer->HasStatusEffect(EFFECT_BIO))
                {
                    if (maneuvers.light >= 2) // 2 Light -> Dia
                    {
                        castPriority.emplace_back(SpellID::Dia);
                    }
                    else
                    {
                        defaultPriority.emplace_back(SpellID::Dia);
                    }
                }

                if (maneuvers.water >= 2) // 2 Water -> Poison
                {
                    castPriority.emplace_back(SpellID::Poison_II);
                    castPriority.emplace_back(SpellID::Poison);
                }
                else
                {
                    defaultPriority.emplace_back(SpellID::Poison_II);
                    defaultPriority.emplace_back(SpellID::Poison);
                }

                if (maneuvers.wind >= 2)
                { // 2 Wind -> Silence
                    castPriority.emplace_back(SpellID::Silence);
                }
                else
                {
                    defaultPriority.emplace_back(SpellID::Silence);
                }

                if (maneuvers.earth >= 2)
                { // 2 Earth -> Slow
                    castPriority.emplace_back(SpellID::Slow);
                }
                else
                {
                    defaultPriority.emplace_back(SpellID::Slow);
                }

                if (maneuvers.ice >= 2)
                { // 2 Ice -> Paralyze
                    castPriority.emplace_back(SpellID::Paralyze);
                }
                else
                {
                    defaultPriority.emplace_back(SpellID::Paralyze);
                }

                if (maneuvers.fire >= 2)
                { // 2 Fire -> Addle
                    castPriority.emplace_back(SpellID::Addle);
                }
                else
                {
                    defaultPriority.emplace_back(SpellID::Addle);
                }
            }
            break;
        }
        case AutomatonHead::Soulsoother:
        {
            if (maneuvers.earth)
            { // Earth -> Slow
                castPriority.emplace_back(SpellID::Slow);
            }
            else
            {
                defaultPriority.emplace_back(SpellID::Slow);
            }

            if (maneuvers.water) // 2 Water -> Poison
            {
                castPriority.emplace_back(SpellID::Poison_II);
                castPriority.emplace_back(SpellID::Poison);
            }
            else
            {
                defaultPriority.emplace_back(SpellID::Poison_II);
                defaultPriority.emplace_back(SpellID::Poison);
            }

            if (maneuvers.dark) // Dark -> Blind > Bio
            {
                castPriority.emplace_back(SpellID::Blind);
                if (!PTarget->StatusEffectContainer->HasStatusEffect(EFFECT_DIA))
                {
                    castPriority.emplace_back(SpellID::Bio_II);
                }
            }
            else
            {
                defaultPriority.emplace_back(SpellID::Blind);
                if (!PTarget->StatusEffectContainer->HasStatusEffect(EFFECT_DIA))
                {
                    defaultPriority.emplace_back(SpellID::Bio_II);
                }
            }

            if (!PTarget->StatusEffectContainer->HasStatusEffect(EFFECT_BIO))
            {
                if (maneuvers.light) // Light -> Dia
                {
                    castPriority.emplace_back(SpellID::Dia_II);
                }
                else
                {
                    defaultPriority.emplace_back(SpellID::Dia_II);
                }
            }

            if (!PTarget->StatusEffectContainer->HasStatusEffect(EFFECT_DIA))
            {
                if (maneuvers.dark) // Dark -> Blind > Bio
                {
                    castPriority.emplace_back(SpellID::Bio);
                }
                else
                {
                    defaultPriority.emplace_back(SpellID::Bio);
                }
            }

            if (!PTarget->StatusEffectContainer->HasStatusEffect(EFFECT_BIO))
            {
                if (maneuvers.light) // Light -> Dia
                {
                    castPriority.emplace_back(SpellID::Dia);
                }
                else
                {
                    defaultPriority.emplace_back(SpellID::Dia);
                }
            }

            if (maneuvers.wind)
            { // Wind -> Silence
                castPriority.emplace_back(SpellID::Silence);
            }
            else
            {
                defaultPriority.emplace_back(SpellID::Silence);
            }

            if (maneuvers.ice)
            { // Ice -> Paralyze
                castPriority.emplace_back(SpellID::Paralyze);
            }
            else
            {
                defaultPriority.emplace_back(SpellID::Paralyze);
            }

            if (maneuvers.fire)
            { // Fire -> Addle
                castPriority.emplace_back(SpellID::Addle);
            }
            else
            {
                defaultPriority.emplace_back(SpellID::Addle);
            }
            break;
        }
    }

    for (SpellID& id : castPriority)
    {
        if (automaton::CanUseEnfeeble(PTarget, id) && Cast(PTarget->targid, id))
        {
            return true;
        }
    }

    for (SpellID& id : defaultPriority)
    {
        if (automaton::CanUseEnfeeble(PTarget, id) && Cast(PTarget->targid, id))
        {
            return true;
        }
    }

    return false;
}

auto CAutomatonController::TryStatusRemoval(const CurrentManeuvers& maneuvers) -> bool
{
    if (!PAutomaton->PMaster || m_statusCooldown == 0s ||
        m_Tick <= m_LastStatusTime + GetAdjustedMagicCooldown(m_statusCooldown, PAutomaton->getMod(Mod::AUTO_MAGIC_DELAY)))
    {
        return false;
    }

    const auto tryRemoval = [&](CBattleEntity* PEntity) -> bool
    {
        std::vector<SpellID> removals;
        PEntity->StatusEffectContainer->ForEachEffect(
            [&removals](CStatusEffect* PStatus)
            {
                if (PStatus->GetDuration() > 0s)
                {
                    if (auto removal = automaton::FindNaSpell(PStatus); removal.has_value())
                    {
                        removals.emplace_back(removal.value());
                    }
                }
            });

        for (const auto removal : removals)
        {
            if (Cast(PEntity->targid, removal))
            {
                return true;
            }
        }

        return false;
    };

    if (distance(PAutomaton->loc.p, PAutomaton->PMaster->loc.p) < 20.0f && tryRemoval(PAutomaton->PMaster))
    {
        return true;
    }

    if (tryRemoval(PAutomaton))
    {
        return true;
    }

    if (maneuvers.water && PAutomaton->getHead() == AutomatonHead::Soulsoother)
    {
        bool castStarted = false;

        if (auto* PMaster = dynamic_cast<CCharEntity*>(PAutomaton->PMaster))
        {
            PMaster->ForPartyWithTrusts([&](CBattleEntity* PMember)
            {
                if (!castStarted && PMember->id != PAutomaton->PMaster->id &&
                    distance(PAutomaton->loc.p, PMember->loc.p) < 20.0f)
                {
                    castStarted = tryRemoval(PMember);
                }
            });
        }

        if (castStarted)
        {
            return true;
        }
    }

    return false;
}

auto CAutomatonController::TryEnhance() -> bool
{
    if (!PAutomaton->PMaster || m_enhanceCooldown == 0s ||
        m_Tick <= m_LastEnhanceTime + GetAdjustedMagicCooldown(m_enhanceCooldown, PAutomaton->getMod(Mod::AUTO_MAGIC_DELAY)))
    {
        return false;
    }

    if (PAutomaton->getHead() == AutomatonHead::Spiritreaver)
    {
        return Cast(PAutomaton->targid, SpellID::Dread_Spikes);
    }

    uint16 highestEnmity = 0;

    CBattleEntity* PRegenTarget     = nullptr;
    CBattleEntity* PProtectTarget   = nullptr;
    CBattleEntity* PShellTarget     = nullptr;
    CBattleEntity* PHasteTarget     = nullptr;
    CBattleEntity* PStoneSkinTarget = nullptr;
    CBattleEntity* PPhalanxTarget   = nullptr;

    bool  protect      = false;
    uint8 protectcount = 0;
    bool  shell        = false;
    uint8 shellcount   = 0;
    bool  haste        = false;
    bool  stoneskin    = false;
    bool  phalanx      = false;

    bool isEngaged = false;

    if (distance(PAutomaton->loc.p, PAutomaton->PMaster->loc.p) < 20)
    {
        if (auto* PMob = dynamic_cast<CMobEntity*>(PTarget))
        {
            auto enmityList = PMob->PEnmityContainer->GetEnmityList();
            if (auto enmity_obj = enmityList->find(PAutomaton->PMaster->id);
                enmity_obj != enmityList->end())
            {
                isEngaged = true;
                if (highestEnmity < enmity_obj->second.CE + enmity_obj->second.VE)
                {
                    highestEnmity = enmity_obj->second.CE + enmity_obj->second.VE;
                    PRegenTarget  = PAutomaton->PMaster;
                }
            }
            else
            {
                isEngaged = true; // Assume everyone is engaged if the target isn't a mob
            }
        }

        PAutomaton->PMaster->StatusEffectContainer->ForEachEffect(
            [&protect, &protectcount, &shell, &shellcount, &haste, &stoneskin, &phalanx](CStatusEffect* PStatus)
            {
                if (PStatus->GetDuration() > 0s)
                {
                    if (PStatus->GetStatusID() == EFFECT_PROTECT)
                    {
                        protect = true;
                        ++protectcount;
                    }

                    if (PStatus->GetStatusID() == EFFECT_SHELL)
                    {
                        shell = true;
                        ++shellcount;
                    }

                    if (PStatus->GetStatusID() == EFFECT_HASTE || PStatus->GetStatusID() == EFFECT_GEO_HASTE)
                    {
                        haste = true;
                    }

                    if (PStatus->GetStatusID() == EFFECT_STONESKIN)
                    {
                        stoneskin = true;
                    }

                    if (PStatus->GetStatusID() == EFFECT_PHALANX)
                    {
                        phalanx = true;
                    }
                }
            });

        if (isEngaged)
        {
            if (!protect)
            {
                PProtectTarget = PAutomaton->PMaster;
            }

            if (!shell)
            {
                PShellTarget = PAutomaton->PMaster;
            }

            if (!haste)
            {
                PHasteTarget = PAutomaton->PMaster;
            }

            if (!stoneskin)
            {
                PStoneSkinTarget = PAutomaton->PMaster;
            }

            if (!phalanx)
            {
                PPhalanxTarget = PAutomaton->PMaster;
            }
        }
    }

    protect   = false;
    shell     = false;
    haste     = false;
    stoneskin = false;
    phalanx   = false;

    if (auto* PMob = dynamic_cast<CMobEntity*>(PTarget))
    {
        auto enmityList = PMob->PEnmityContainer->GetEnmityList();
        auto enmity_obj = enmityList->find(PAutomaton->id);
        if (enmity_obj != enmityList->end() && highestEnmity < enmity_obj->second.CE + enmity_obj->second.VE)
        {
            highestEnmity = enmity_obj->second.CE + enmity_obj->second.VE;
            PRegenTarget  = PAutomaton;
        }
    }

    PAutomaton->StatusEffectContainer->ForEachEffect(
        [&protect, &shell, &haste](CStatusEffect* PStatus)
        {
            if (PStatus->GetDuration() > 0s)
            {
                if (PStatus->GetStatusID() == EFFECT_PROTECT)
                {
                    protect = true;
                }

                if (PStatus->GetStatusID() == EFFECT_SHELL)
                {
                    shell = true;
                }

                if (PStatus->GetStatusID() == EFFECT_HASTE || PStatus->GetStatusID() == EFFECT_GEO_HASTE)
                {
                    haste = true;
                }
            }
        });

    if (!PProtectTarget && !protect)
    {
        PProtectTarget = PAutomaton;
    }

    if (!PShellTarget && !shell)
    {
        PShellTarget = PAutomaton;
    }

    if (!PHasteTarget && !haste)
    {
        PHasteTarget = PAutomaton;
    }

    size_t members = 0;

    // Unknown whether it only applies buffs to other members if they have hate or if the Soulsoother head is needed
    if (PAutomaton->PMaster->PParty)
    {
        members = PAutomaton->PMaster->PParty->members.size();
        // clang-format off
        static_cast<CCharEntity*>(PAutomaton->PMaster)->ForPartyWithTrusts([&](CBattleEntity* PMember)
        {
            if (PMember->id != PAutomaton->PMaster->id && distance(PAutomaton->loc.p, PMember->loc.p) < 20)
            {
                protect = false;
                shell   = false;
                haste   = false;

                isEngaged = false;

                if (auto* PMob = dynamic_cast<CMobEntity*>(PTarget))
                {
                    auto enmityList = PMob->PEnmityContainer->GetEnmityList();
                    auto enmity_obj = enmityList->find(PMember->id);
                    if (enmity_obj != enmityList->end())
                    {
                        isEngaged = true;
                        if (highestEnmity < enmity_obj->second.CE + enmity_obj->second.VE)
                        {
                            highestEnmity = enmity_obj->second.CE + enmity_obj->second.VE;
                            PRegenTarget  = PMember;
                        }
                    }
                }
                else
                {
                    isEngaged = true; // Assume everyone is engaged if the target isn't a mob
                }

                PMember->StatusEffectContainer->ForEachEffect([&protect, &protectcount, &shell, &shellcount, &haste](CStatusEffect* PStatus)
                {
                    if (PStatus->GetDuration() > 0s)
                    {
                        if (PStatus->GetStatusID() == EFFECT_PROTECT)
                        {
                            protect = true;
                            ++protectcount;
                        }

                        if (PStatus->GetStatusID() == EFFECT_SHELL)
                        {
                            shell = true;
                            ++shellcount;
                        }

                        if (PStatus->GetStatusID() == EFFECT_HASTE || PStatus->GetStatusID() == EFFECT_GEO_HASTE)
                        {
                            haste = true;
                        }
                    }
                });

                if (isEngaged)
                {
                    if (!PProtectTarget && !protect)
                    {
                        PProtectTarget = PMember;
                    }

                    if (!PShellTarget && !shell)
                    {
                        PShellTarget = PMember;
                    }

                    if (!PHasteTarget && !haste)
                    {
                        PHasteTarget = PMember;
                    }
                }
            }
        });
        // clang-format on
    }

    // No info on how this spell worked
    if ((members - protectcount) >= 4)
    {
        if (Cast(PAutomaton->targid, SpellID::Protectra_V))
        {
            return true;
        }
    }

    // No info on how this spell worked
    if ((members - shellcount) >= 4)
    {
        if (Cast(PAutomaton->targid, SpellID::Shellra_V))
        {
            return true;
        }
    }

    if (PRegenTarget &&
        !(PRegenTarget->StatusEffectContainer->HasStatusEffect(EFFECT_REGEN) || PRegenTarget->StatusEffectContainer->HasStatusEffect(EFFECT_GEO_REGEN)))
    {
        if (Cast(PRegenTarget->targid, SpellID::Regen_III) || Cast(PRegenTarget->targid, SpellID::Regen_II) || Cast(PRegenTarget->targid, SpellID::Regen))
        {
            return true;
        }
    }

    if (PProtectTarget)
    {
        if (Cast(PProtectTarget->targid, SpellID::Protect_V) || Cast(PProtectTarget->targid, SpellID::Protect_IV) ||
            Cast(PProtectTarget->targid, SpellID::Protect_III) || Cast(PProtectTarget->targid, SpellID::Protect_II) ||
            Cast(PProtectTarget->targid, SpellID::Protect))
        {
            return true;
        }
    }

    if (PShellTarget)
    {
        if (Cast(PShellTarget->targid, SpellID::Shell_V) || Cast(PShellTarget->targid, SpellID::Shell_IV) || Cast(PShellTarget->targid, SpellID::Shell_III) ||
            Cast(PShellTarget->targid, SpellID::Shell_II) || Cast(PShellTarget->targid, SpellID::Shell))
        {
            return true;
        }
    }

    if (PHasteTarget)
    {
        if (Cast(PHasteTarget->targid, SpellID::Haste_II) || Cast(PHasteTarget->targid, SpellID::Haste))
        {
            return true;
        }
    }

    if (PStoneSkinTarget)
    {
        if (Cast(PStoneSkinTarget->targid, SpellID::Stoneskin))
        {
            return true;
        }
    }

    if (PPhalanxTarget)
    {
        if (Cast(PPhalanxTarget->targid, SpellID::Phalanx))
        {
            return true;
        }
    }

    return false;
}

auto CAutomatonController::TryTPMove() -> bool
{
    if (PAutomaton->health.tp >= 1000)
    {
        const auto& FrameSkills = battleutils::GetMobSkillList(PAutomaton->m_MobSkillList);

        std::vector<CMobSkill*> validSkills;

        // load the skills that the automaton has access to with it's skill
        SKILLTYPE skilltype = SKILL_AUTOMATON_MELEE;

        if (PAutomaton->getFrame() == AutomatonFrame::Sharpshot)
        {
            skilltype = SKILL_AUTOMATON_RANGED;
        }

        for (auto skillid : FrameSkills)
        {
            auto* PSkill = battleutils::GetMobSkill(skillid);
            if (PSkill && PAutomaton->GetSkill(skilltype) > PSkill->getParam() && PSkill->getParam() != -1 &&
                distance(PAutomaton->loc.p, PTarget->loc.p) < PSkill->getRadius())
            {
                validSkills.emplace_back(PSkill);
            }
        }

        int16      currentPriority  = -1;
        CMobSkill* PWSkill          = nullptr;
        int8       currentManeuvers = -1;
        uint16     currentSkillId   = 0;
        CMobSkill* PBaseSkill       = nullptr;
        const auto baseSkillId      = GetAutomatonBaseWs(PAutomaton->getFrame());

        for (auto* PSkill : validSkills)
        {
            if (PSkill->getID() == baseSkillId)
            {
                PBaseSkill = PSkill;
                break;
            }
        }

        bool attemptChain = (PAutomaton->getMod(Mod::AUTO_TP_EFFICIENCY) != 0);

        if (attemptChain)
        {
            CStatusEffect* PSCEffect = PTarget->StatusEffectContainer->GetStatusEffect(EFFECT_SKILLCHAIN, 0);
            if (PSCEffect && PSCEffect->GetStartTime() + 3s < timer::now())
            {
                std::list<SKILLCHAIN_ELEMENT> resonanceProperties;

                if (uint16 power = PSCEffect->GetPower())
                {
                    resonanceProperties.emplace_back((SKILLCHAIN_ELEMENT)(power & 0xF));
                    resonanceProperties.emplace_back((SKILLCHAIN_ELEMENT)((power >> 4) & 0xF));
                    resonanceProperties.emplace_back((SKILLCHAIN_ELEMENT)(power >> 8));
                }

                for (auto* PSkill : validSkills)
                {
                    const int8 maneuvers = luautils::OnAutomatonAbilityCheck(PTarget, PAutomaton, PSkill);
                    if (maneuvers <= 0)
                    {
                        continue;
                    }

                    const int16 priority = GetAutomatonWsPriority(PSkill->getID(), PSkill->getParam());
                    if (priority > currentPriority || (priority == currentPriority && PSkill->getID() > currentSkillId))
                    {
                        std::list<SKILLCHAIN_ELEMENT> skillProperties;
                        skillProperties.emplace_back((SKILLCHAIN_ELEMENT)PSkill->getPrimarySkillchain());
                        skillProperties.emplace_back((SKILLCHAIN_ELEMENT)PSkill->getSecondarySkillchain());
                        skillProperties.emplace_back((SKILLCHAIN_ELEMENT)PSkill->getTertiarySkillchain());
                        if (battleutils::FormSkillchain(resonanceProperties, skillProperties) != SC_NONE)
                        {
                            currentManeuvers = 1;
                            currentPriority  = priority;
                            currentSkillId   = PSkill->getID();
                            PWSkill          = PSkill;
                        }
                    }
                }
            }
        }

        const bool masterIsReady = attemptChain && PAutomaton->PMaster != nullptr &&
            PAutomaton->PMaster->health.tp >= PAutomaton->getMod(Mod::AUTO_TP_EFFICIENCY);
        if (currentManeuvers == -1 && masterIsReady)
        {
            if (m_TpHoldStarted == timer::time_point{})
            {
                m_TpHoldStarted = m_Tick;
            }

            // Inhibitor/Speedloader should hold for a player skillchain, but
            // never suppress every WS forever when the master remains at TP.
            if (m_Tick < m_TpHoldStarted + AUTOMATON_SKILLCHAIN_HOLD_MAX)
            {
                return false;
            }
        }
        else
        {
            m_TpHoldStarted = {};
        }

        if (!attemptChain || currentManeuvers == -1)
        {
            for (auto* PSkill : validSkills)
            {
                int8 maneuvers = luautils::OnAutomatonAbilityCheck(PTarget, PAutomaton, PSkill);
                int16 priority = GetAutomatonWsPriority(PSkill->getID(), PSkill->getParam());
                if (maneuvers > 0 &&
                    (maneuvers > currentManeuvers ||
                     (maneuvers == currentManeuvers &&
                      (priority > currentPriority || (priority == currentPriority && PSkill->getID() > currentSkillId)))))
                {
                    currentManeuvers = maneuvers;
                    currentPriority  = priority;
                    currentSkillId   = PSkill->getID();
                    PWSkill          = PSkill;
                }
            }

            // Every weaponskill is maneuver-specialized. If none are enabled,
            // retain one deterministic starter move for the equipped frame.
            if (currentManeuvers == -1 && PBaseSkill)
            {
                currentManeuvers = 0;
                currentPriority  = GetAutomatonWsPriority(PBaseSkill->getID(), PBaseSkill->getParam());
                currentSkillId   = PBaseSkill->getID();
                PWSkill          = PBaseSkill;
            }
        }

        // No WS was chosen (waiting on master's TP to skillchain probably)
        if (currentManeuvers == -1)
        {
            return false;
        }

        if (PWSkill)
        {
            const bool releasedWeaponskill = MobSkill(PTarget->targid, PWSkill->getID(), std::nullopt);
            if (releasedWeaponskill)
            {
                // A new TP cycle gets its own hold window even if the master
                // remains above the inhibitor threshold.
                m_TpHoldStarted = {};
            }

            return releasedWeaponskill;
        }
    }
    m_TpHoldStarted = {};
    return false;
}

auto CAutomatonController::TryRangedAttack() -> bool // TODO: Find the animation for its ranged attack
{
    if (PAutomaton->getFrame() == AutomatonFrame::Sharpshot)
    {
        timer::duration minDelay   = PAutomaton->getHead() == AutomatonHead::Sharpshot ? 5s : 10s;
        timer::duration attackTime = m_rangedCooldown - std::chrono::seconds(PAutomaton->getMod(Mod::AUTO_RANGED_DELAY));

        if (m_rangedCooldown > 0s && m_Tick > m_LastRangedTime + std::max(attackTime, minDelay))
        {
            return MobSkill(PTarget->targid, m_RangedAbility, std::nullopt);
        }
    }

    return false;
}

auto CAutomatonController::TryAttachment() -> bool
{
    if (!PAutomaton->PAI->CanChangeState())
    {
        return false;
    }

    PAutomaton->SetLocalVar(AUTOMATON_ATTACHMENT_ACTIVATED, 0);
    PAutomaton->SetLocalVar(AUTOMATON_ATTACHMENT_CHECKING, 1);
    PAutomaton->PAI->EventHandler.triggerListener("AUTOMATON_ATTACHMENT_CHECK", PAutomaton, PTarget);
    PAutomaton->SetLocalVar(AUTOMATON_ATTACHMENT_CHECKING, 0);

    return PAutomaton->GetLocalVar(AUTOMATON_ATTACHMENT_ACTIVATED) != 0;
}

auto CAutomatonController::CanCastSpells(IgnoreRecastsAndCosts ignoreRecastsAndCosts) -> bool
{
    // Check for spell blockers e.g. silence
    if (PAutomaton->StatusEffectContainer->HasStatusEffect({ EFFECT_SILENCE, EFFECT_MUTE }))
    {
        return false;
    }

    if (!ignoreRecastsAndCosts && !PAutomaton->SpellContainer->IsAnySpellAvailable())
    {
        return false;
    }

    // Check if we can change states!
    return PAutomaton->PAI->CanChangeState();
}

auto CAutomatonController::Cast(uint16 targid, SpellID spellid) -> bool
{
    if (!automaton::CanUseSpell(PAutomaton, spellid) || PAutomaton->PRecastContainer->HasRecast(RECAST_MAGIC, static_cast<Recast>(spellid), 0s))
    {
        return false;
    }

    return CPetController::Cast(targid, spellid);
}

auto CAutomatonController::MobSkill(uint16 targid, uint16 wsid, Maybe<timer::duration> castTimeOverride) -> bool
{
    if (PAutomaton->PRecastContainer->HasRecast(RECAST_ABILITY, static_cast<Recast>(wsid), 0s))
    {
        return false;
    }
    return CPetController::MobSkill(targid, wsid, castTimeOverride);
}

auto CAutomatonController::Disengage() -> bool
{
    PTarget = nullptr;
    if (shouldStandBack())
    {
        PAutomaton->m_Behavior |= BEHAVIOR_STANDBACK;
    }
    return CMobController::Disengage();
}

namespace automaton
{

std::unordered_map<SpellID, AutomatonSpell, EnumClassHash> autoSpellList;
std::vector<SpellID>                                       naSpells;
std::unordered_map<uint16, AutomatonAbility>               autoAbilityList;

void LoadAutomatonSpellList()
{
    const auto rset = db::preparedStmt("SELECT spellid, skilllevel, heads, enfeeble, immunity, removes FROM automaton_spells");
    if (rset && rset->rowsCount())
    {
        while (rset->next())
        {
            SpellID id = rset->get<SpellID>("spellid");

            AutomatonSpell PSpell{
                .skilllevel = rset->get<uint16>("skilllevel"),
                .heads      = rset->get<uint8>("heads"),
                .enfeeble   = rset->get<EFFECT>("enfeeble"),
                .immunity   = rset->get<IMMUNITY>("immunity"),
                .removes    = {}, // Will handle in a moment
            };

            uint32 removes = rset->get<uint32>("removes");
            while (removes > 0)
            {
                PSpell.removes.emplace_back(static_cast<EFFECT>(removes & 0xFF));
                removes = removes >> 8;
            }

            if (!PSpell.removes.empty())
            {
                naSpells.emplace_back(id);
            }

            autoSpellList[id] = std::move(PSpell);
        }
    }
}

bool CanUseSpell(CAutomatonEntity* PCaster, SpellID spellid)
{
    const AutomatonSpell& PSpell = autoSpellList[spellid];
    return ((PCaster->GetSkill(SKILL_AUTOMATON_MAGIC) >= PSpell.skilllevel) && (PSpell.heads & (1 << ((uint8)PCaster->getHead() - 1))));
}

bool CanUseEnfeeble(CBattleEntity* PTarget, SpellID spell)
{
    const AutomatonSpell& PSpell   = autoSpellList[spell];
    auto&                 statuses = PTarget->StatusEffectContainer;
    return (!statuses->HasStatusEffect(PSpell.enfeeble) && !PTarget->hasImmunity(PSpell.immunity));
}

Maybe<SpellID> FindNaSpell(CStatusEffect* PStatus)
{
    for (auto spell : naSpells)
    {
        const AutomatonSpell& PSpell = autoSpellList[spell];
        if (std::find(PSpell.removes.begin(), PSpell.removes.end(), PStatus->GetStatusID()) != PSpell.removes.end())
        {
            return spell;
        }
    }

    if (PStatus->HasEffectFlag(EFFECTFLAG_ERASABLE))
    {
        return SpellID::Erase;
    }
    else
    {
        // TODO: -Wno-maybe-uninitialized - possible false positive (anonymous may be used)
        return {};
    }
}

void LoadAutomatonAbilities()
{
    const auto rset = db::preparedStmt("SELECT abilityid, abilityname, reqframe, skilllevel FROM automaton_abilities");

    if (rset && rset->rowsCount())
    {
        while (rset->next())
        {
            uint16 id = rset->get<uint16>("abilityid");

            AutomatonAbility PAbility{
                .requiredFrame = rset->get<uint8>("reqframe"),
                .skillLevel    = rset->get<uint16>("skilllevel"),
            };

            autoAbilityList[id] = PAbility;

            const auto abilityName = rset->get<std::string>("abilityname");

            const auto filename = fmt::format("./scripts/actions/abilities/pets/automaton/{}.lua", abilityName);
            luautils::CacheLuaObjectFromFile(filename);
        }
    }
}

} // namespace automaton
