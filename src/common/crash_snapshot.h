#pragma once

#include <string>

// Last occupancy snapshot from the map tick. Wheaty only copies this buffer
// on crash — it does not walk game objects from the exception handler.
namespace crash_snapshot
{
    void Store(std::string text);
    auto Copy() -> std::string;
    void WriteSidecar(const char* wheatyLogPath);
}
