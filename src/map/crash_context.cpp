#include "crash_context.h"

#include "common/crash_snapshot.h"
#include "common/earth_time.h"

#include "entities/charentity.h"
#include "instance.h"
#include "utils/zoneutils.h"
#include "zone.h"
#include "zone_instance.h"

#include <deque>
#include <fmt/format.h>
#include <mutex>
#include <string>
#include <vector>

namespace
{
    std::mutex             eventMutex;
    std::deque<std::string> recentEvents;

    void joinNames(std::string& out, const std::vector<std::string>& names)
    {
        for (size_t i = 0; i < names.size(); ++i)
        {
            if (i != 0)
            {
                out += ", ";
            }
            out += names[i];
        }
    }
}

namespace crash_context
{
    void Note(std::string_view event)
    {
        const auto line = fmt::format("{:%Y/%m/%d %H:%M:%S}  {}", earth_time::to_local_tm(), event);
        std::lock_guard lock(eventMutex);
        recentEvents.push_back(line);
        while (recentEvents.size() > 8)
        {
            recentEvents.pop_front();
        }
    }

    void Refresh()
    {
        try
        {
            std::string out;
            out += fmt::format("Snapshot: {:%Y/%m/%d %H:%M:%S}\n", earth_time::to_local_tm());
            out += "Players / instances:\n";

            const auto before = out.size();
            zoneutils::ForEachZone(
                [&](CZone* PZone)
                {
                    if (PZone != nullptr)
                    {
                        PZone->AppendCrashOccupancy(out);
                    }
                });

            if (out.size() == before)
            {
                out += "  (no players online)\n";
            }

            out += "Recent instance events:\n";
            {
                std::lock_guard lock(eventMutex);
                if (recentEvents.empty())
                {
                    out += "  (none)\n";
                }
                else
                {
                    for (const auto& line : recentEvents)
                    {
                        out += "  ";
                        out += line;
                        out += '\n';
                    }
                }
            }

            crash_snapshot::Store(std::move(out));
        }
        catch (const std::exception& e)
        {
            crash_snapshot::Store(fmt::format("Flight recorder refresh failed: {}\n", e.what()));
        }
        catch (...)
        {
            crash_snapshot::Store("Flight recorder refresh failed (unknown).\n");
        }
    }
}

void CZone::AppendCrashOccupancy(std::string& out)
{
    std::vector<std::string> names;
    ForEachChar(
        [&](CCharEntity* PChar)
        {
            if (PChar != nullptr)
            {
                names.push_back(fmt::format("{} ({})", PChar->getName(), PChar->id));
            }
        });

    if (names.empty())
    {
        return;
    }

    out += fmt::format("  Zone {} [{}]: ", getName(), static_cast<uint16>(GetID()));
    joinNames(out, names);
    out += '\n';
}

void CZoneInstance::AppendCrashOccupancy(std::string& out)
{
    if (IsHybrid())
    {
        CZone::AppendCrashOccupancy(out);
    }

    size_t copies = 0;
    for (const auto& inst : m_InstanceList)
    {
        if (inst)
        {
            ++copies;
        }
    }

    if (copies == 0)
    {
        return;
    }

    out += fmt::format("  Zone {} [{}] — {} instance copy/copies\n", getName(), static_cast<uint16>(GetID()), copies);

    size_t index = 0;
    for (const auto& inst : m_InstanceList)
    {
        if (!inst)
        {
            continue;
        }

        std::vector<std::string> names;
        inst->ForEachChar(
            [&](CCharEntity* PChar)
            {
                if (PChar != nullptr)
                {
                    names.push_back(fmt::format("{} ({})", PChar->getName(), PChar->id));
                }
            });

        const char* status = "";
        if (inst->Failed())
        {
            status = " FAILED";
        }
        else if (inst->Completed())
        {
            status = " COMPLETE";
        }

        out += fmt::format("    [{}] instance {} {}{}: ", index, inst->GetID(), inst->GetName(), status);
        if (names.empty())
        {
            out += "(empty)";
        }
        else
        {
            joinNames(out, names);
        }
        out += '\n';
        ++index;
    }
}
