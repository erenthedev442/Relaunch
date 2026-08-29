#pragma once

#include "common/cbasetypes.h"

#include <string>

class CCharEntity;
class CItem;

namespace krakenclub
{
inline constexpr uint16 ItemId = 17440;

// Assigns the next persistent LEG serial to a newly-created Kraken Club.
// Returns zero if the serial could not be allocated; callers must fail closed.
auto stampNewItem(CCharEntity* PChar, CItem* PItem) -> uint32;

// Removes an unused serial after an item insertion failure.
void releaseSerial(uint32 serial);

// Congratulates the recipient across every map server.
void announce(CCharEntity* PChar, const std::string& signature);
} // namespace krakenclub
