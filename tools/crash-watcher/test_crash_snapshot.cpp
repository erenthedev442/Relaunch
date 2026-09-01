// Standalone check for crash_snapshot Store / Copy / WriteSidecar.
// Does not link the game. Build: cl /EHsc /std:c++20 test_crash_snapshot.cpp ..\..\src\common\crash_snapshot.cpp
#include "../../src/common/crash_snapshot.h"

#include <cstdlib>
#include <filesystem>
#include <fstream>
#include <iostream>
#include <string>

namespace fs = std::filesystem;

static int fail(const char* what)
{
    std::cerr << "FAIL: " << what << "\n";
    return 1;
}

int main()
{
    crash_snapshot::Store("Players / instances:\n  Zone Dynamis-Bastok_[D] [295]: Alice (123)\n");
    const auto copy = crash_snapshot::Copy();
    if (copy.find("Alice (123)") == std::string::npos)
    {
        return fail("Copy() lost player name");
    }

    const auto dir = fs::temp_directory_path() / "relaunch_crash_snapshot_test";
    fs::create_directories(dir);
    const auto wheaty = dir / "xi_map.exe_1-9_2-47-8.log";
    {
        std::ofstream out(wheaty);
        out << "placeholder\n";
    }

    crash_snapshot::WriteSidecar(wheaty.string().c_str());
    const auto sidecar = dir / "xi_map.exe_1-9_2-47-8.context.txt";
    if (!fs::exists(sidecar))
    {
        return fail("sidecar not written next to Wheaty log");
    }

    std::ifstream in(sidecar);
    std::string   body((std::istreambuf_iterator<char>(in)), std::istreambuf_iterator<char>());
    if (body.find("Alice (123)") == std::string::npos)
    {
        return fail("sidecar missing player name");
    }

    std::string huge(20 * 1024, 'A');
    huge += " Carol (789)";
    crash_snapshot::Store(huge);
    const auto truncated = crash_snapshot::Copy();
    if (truncated.size() > 20 * 1024)
    {
        return fail("Store() did not cap size");
    }
    if (truncated.find("truncated") == std::string::npos)
    {
        return fail("Store() missing truncate marker");
    }

    std::error_code ec;
    fs::remove_all(dir, ec);
    std::cout << "OK crash_snapshot Store/Copy/WriteSidecar\n";
    return 0;
}
