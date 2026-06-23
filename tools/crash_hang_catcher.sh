#!/usr/bin/env bash
# ===========================================================================
# crash_hang_catcher.sh   (run as root by crash-hang-catcher.service)
#
# The recurring SIGABRT heap-corruption crashes ("corrupted double-linked
# list") make xi_map's IN-PROCESS crash handler HANG (it allocates while
# generating a backtrace, on an already-corrupted heap) -> it never reaches
# raise(SIGQUIT), so NO core is dumped, and systemd SIGKILLs it ~90s later.
# That leaves nothing to diagnose.
#
# This watcher tails the journal for the handler's "Crash detected" line and
# immediately gcore's the FROZEN process -- well inside the ~90s window -- so
# even those crashes leave a usable core. It writes the core as
# /var/crash/core.xi_map.hang.<ts>.<pid>, which the existing crash_capture.sh
# cron then gdb's into log/crashes/ and deletes.
#
# REDUNDANT (harmless) once the debug_linux.cpp "dump core first" fix is rebuilt
# -- after that the process dumps its own core in ~1s. Disable then:
#   sudo systemctl disable --now crash-hang-catcher.service
# ===========================================================================
set -u

UNIT=xi_map.service
last=0

# -n 0: only NEW lines. -o cat: raw text. Survives xi_map restarts (follows the unit).
journalctl -u "$UNIT" -f -n 0 -o cat 2>/dev/null | while IFS= read -r line; do
    case "$line" in
        *"Crash detected"*)
            now=$(date +%s)
            # Debounce: the handler prints "Crash detected" 2x (two threads),
            # and a crash+restart cycle is ~95s. One gcore per crash.
            if [ $(( now - last )) -lt 120 ]; then
                continue
            fi
            last=$now

            pid=$(systemctl show "$UNIT" -p MainPID --value 2>/dev/null)
            if [ -z "$pid" ] || [ "$pid" = "0" ]; then
                continue
            fi

            out="/var/crash/core.xi_map.hang.${now}"
            logger -t xi_hang_catcher "Crash detected on pid ${pid}; gcore -> ${out}.${pid}"
            # Background it so we keep reading; 80s < the ~90s SIGKILL deadline.
            timeout 80 gcore -o "$out" "$pid" >/dev/null 2>&1 &
            ;;
    esac
done
