#include "modules/custom/cpp/kraken_club.h"

#include "common/database.h"
#include "common/ipc_structs.h"
#include "common/logging.h"
#include "map/entities/charentity.h"
#include "map/ipc_client.h"
#include "map/items/item.h"

#include <format>

namespace krakenclub
{
auto stampNewItem(CCharEntity* PChar, CItem* PItem) -> uint32
{
    if (PChar == nullptr || PItem == nullptr || !isKrakenClub(PItem->getID()) || !PItem->getSignature().empty())
    {
        return 0;
    }

    uint32 serial = 0;
    db::transaction([&]()
                    {
                        if (!db::preparedStmt(
                                "INSERT INTO kraken_club_serials (charid, charname) VALUES (?, ?)",
                                PChar->id,
                                PChar->getName()))
                        {
                            return;
                        }

                        if (const auto rset = db::preparedStmt("SELECT LAST_INSERT_ID() AS serial"); rset && rset->next())
                        {
                            serial = rset->get<uint32>("serial");
                        }
                    });

    if (serial == 0)
    {
        ShowErrorFmt("Kraken Club: failed to allocate a serial for {} (item {})", PChar->getName(), PItem->getID());
        return 0;
    }

    PItem->setSignature(std::format("LEG{:04d}", serial));
    return serial;
}

void releaseSerial(const uint32 serial)
{
    if (serial != 0)
    {
        db::preparedStmt("DELETE FROM kraken_club_serials WHERE serial = ?", serial);
    }
}

void announce(CCharEntity* PChar, const std::string& signature, uint16 itemId)
{
    if (PChar == nullptr || signature.empty())
    {
        return;
    }

    const char* name = (itemId == PlusOneItemId) ? "Kraken Club +1" : "Kraken Club";
    message::send(ipc::ChatMessageServerMessage{
        .senderId    = PChar->id,
        .senderName  = "Relaunch",
        .message     = std::format("Congratulations to {} on obtaining {} {}!", PChar->getName(), name, signature),
        .messageType = MESSAGE_SYSTEM_3,
    });
}
} // namespace krakenclub
