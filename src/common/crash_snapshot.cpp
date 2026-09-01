#include "crash_snapshot.h"

#include <fstream>
#include <mutex>
#include <string>

namespace
{
    std::mutex  mutex;
    std::string text = "Flight recorder not yet armed.\n";
}

namespace crash_snapshot
{
    void Store(std::string next)
    {
        if (next.size() > 16 * 1024)
        {
            next.resize(16 * 1024);
            next += "\n…(truncated)\n";
        }

        std::lock_guard lock(mutex);
        text = std::move(next);
    }

    auto Copy() -> std::string
    {
        std::unique_lock lock(mutex, std::try_to_lock);
        if (!lock.owns_lock())
        {
            return "Flight recorder lock busy (tick in progress).\n";
        }

        return text;
    }

    void WriteSidecar(const char* wheatyLogPath)
    {
        if (wheatyLogPath == nullptr || wheatyLogPath[0] == '\0')
        {
            return;
        }

        std::string path(wheatyLogPath);
        const auto  dot = path.find_last_of('.');
        if (dot != std::string::npos)
        {
            path.replace(dot, std::string::npos, ".context.txt");
        }
        else
        {
            path += ".context.txt";
        }

        std::ofstream out(path, std::ios::out | std::ios::trunc);
        if (!out)
        {
            return;
        }

        out << Copy();
    }
}
