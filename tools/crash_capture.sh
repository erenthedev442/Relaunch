#!/usr/bin/env bash
# ===========================================================================
# crash_capture.sh
#
# Run by cron (as root) on the live box. For each FULLY-WRITTEN xi_map core in
# /var/crash, extract a symbolicated backtrace against the CURRENT xi_map binary
# into log/crashes/, then DELETE the multi-GB core so /var can't fill up.
#
# Why: xi_map's in-process crash handler (src/common/debug_linux.cpp) can hang
# generating its backtrace on a corrupted heap (the "corrupted double-linked
# list" SIGABRTs), so the live trace is unreliable. A real core + offline gdb is
# the robust way to get the faulting stack. Cores are 2+ GB each, so we keep only
# the small text backtrace and remove the core.
#
# Pairs with the timestamped core_pattern:
#   /var/crash/core.%e.%t.%p   (set at runtime + persisted in
#   /etc/sysctl.d/99-xi-coredump.conf)
#
# Install (on the box):
#   sudo cp /home/azureuser/server/tools/crash_capture.sh /usr/local/bin/
#   # cron in /etc/cron.d/xi-crash-capture (every 2 min, flock-guarded)
# ===========================================================================
set -u

BIN=/home/azureuser/server/xi_map
OUTDIR=/home/azureuser/server/log/crashes
mkdir -p "$OUTDIR"

shopt -s nullglob
for core in /var/crash/core.xi_map.*; do
    # Skip cores still being written by the kernel (modified in the last minute).
    if [ -z "$(find "$core" -maxdepth 0 -mmin +1 2>/dev/null)" ]; then
        continue
    fi

    name=$(basename "$core")
    out="$OUTDIR/${name}.bt.txt"

    {
        echo "=== xi_map crash backtrace: ${name} ==="
        echo "captured: $(date '+%F %T %Z')"
        echo "binary:   ${BIN}  (built $(date -r "$BIN" '+%F %T' 2>/dev/null))"
        echo "core:     ${core}  (written $(date -r "$core" '+%F %T' 2>/dev/null), $(du -h "$core" 2>/dev/null | cut -f1))"
        echo
        timeout 300 gdb -batch -nx \
            -ex 'set pagination off' \
            -ex 'set print frame-arguments none' \
            -ex 'printf "\n========== CRASHING THREAD ==========\n"' \
            -ex 'bt' \
            -ex 'printf "\n========== ALL THREADS ==========\n"' \
            -ex 'thread apply all bt' \
            "$BIN" "$core" 2>&1
    } > "$out" 2>&1

    chmod 0644 "$out"
    rm -f "$core"
    logger -t xi_crash_capture "captured backtrace for ${name} -> ${out}; core removed"
done
