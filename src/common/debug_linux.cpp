/*
===========================================================================

  Copyright (c) 2024 LandSandBoat Dev Teams

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

#ifdef __linux__
#include <csignal>
#include <sys/ptrace.h>
#include <sys/resource.h>
#include <sys/types.h>

#include "debug.h"
#include "logging.h"

#define BACKWARD_HAS_BFD 1
#include "ext/backward/backward.hpp"

// https://man7.org/linux/man-pages/man7/signal-safety.7.html
void safe_print(const char* str)
{
    // https://man7.org/linux/man-pages/man2/write.2.html
    // https://man7.org/linux/man-pages/man3/strlen.3.html
    std::ignore = write(1, str, strlen(str));
}

void dumpBacktrace(int signal)
{
    // FJB: go STRAIGHT to a core dump and let the out-of-process watcher
    // (tools/crash_capture.sh) symbolicate it offline with gdb. The in-process
    // backward-cpp traceback we used to run here ALLOCATES, so it HUNG whenever
    // the crash was heap corruption (the recurring "corrupted double-linked list"
    // SIGABRTs) -- systemd's 90s stop timeout then SIGKILLed the process, leaving
    // NO core and a ~90s outage. Dumping the core immediately fixes both: every
    // crash (SIGSEGV and SIGABRT) leaves a usable, symbol-matching core AND
    // recovery is back to ~5s. The crashing thread's stack is captured in the
    // core, so nothing is lost vs the old (ANSI-garbled, often-truncated) live
    // trace -- gdb on the core gives a better, full, all-threads backtrace.
    safe_print("Crash detected -- dumping core (analyzed offline by tools/crash_capture.sh)\n");
    std::signal(SIGQUIT, SIG_DFL);
    raise(SIGQUIT); // Let the OS dump the core file
}

void debug::init()
{
    rlimit core_limits{};
    core_limits.rlim_cur = core_limits.rlim_max = RLIM_INFINITY;
    setrlimit(RLIMIT_CORE, &core_limits);

    // things we want to handle
    std::signal(SIGABRT, dumpBacktrace);
    std::signal(SIGSEGV, dumpBacktrace);
    std::signal(SIGFPE, dumpBacktrace);
    std::signal(SIGXFSZ, dumpBacktrace);

    // pass these onto default handler
    std::signal(SIGILL, SIG_DFL);
    std::signal(SIGBUS, SIG_DFL);
    std::signal(SIGTRAP, SIG_DFL);
}

bool debug::isRunningUnderDebugger()
{
    static bool isCheckedAlready = false;

    bool underDebugger = false;

    if (!isCheckedAlready)
    {
        if (ptrace(PTRACE_TRACEME, 0, 1, 0) < 0)
        {
            underDebugger = true;
        }
        else
        {
            ptrace(PTRACE_DETACH, 0, 1, 0);
        }

        isCheckedAlready = true;
    }
    return underDebugger;
}

bool debug::isUserRoot()
{
    return getuid() == 0 && getgid() == 0;
}

#endif // __linux__
