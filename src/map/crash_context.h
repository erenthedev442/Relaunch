#pragma once

#include <string_view>

namespace crash_context
{
    void Note(std::string_view event);
    void Refresh();
}
