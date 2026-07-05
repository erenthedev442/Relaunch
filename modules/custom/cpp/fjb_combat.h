#pragma once

// True-damage / over-cap readout + automaton-DPS helpers extracted from
// src/map/utils/battleutils.cpp (see CORE_PATCH_TRIAGE.md, extraction #3).
//
// Kept in the global namespace with their ORIGINAL names so the battleutils
// call sites are unchanged. Definitions live in fjb_combat.cpp, compiled into
// xi_map via modules/init.txt; battleutils (in xi_map_lib) calls them across the
// static-lib boundary, resolved at the final xi_map link.

#include "common/cbasetypes.h"

#include <string_view>

class CBattleEntity;

// True when the damage source is player-controlled (PC, or a pet/trust/charmed
// mob whose master is a PC). These bypass the damage cap.
bool IsPlayerControlled(CBattleEntity* PAttacker);

// Whisper the true (over-cap) damage to the controlling player so it's readable
// in chat. No-op for <=131071 or non-player-controlled sources.
void NotifyOverCapDamage(CBattleEntity* PAttacker, int32 damage, std::string_view type);

// Scale an automaton's outgoing PHYSICAL damage by AUTOMATON_DMG_MULTIPLIER.
// Returns damage unchanged for non-automaton attackers or damage <= 0.
int32 ApplyAutomatonDamageBonus(CBattleEntity* PAttacker, int32 damage);
