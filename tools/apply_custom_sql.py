#!/usr/bin/env python3
"""Apply the custom sql/zz_*.sql layer to the game DB in one command.

No more hand-typing `mysql < file.sql` per file per server.

Credentials come from settings/network.lua (the same keys dbtool uses:
SQL_HOST / SQL_PORT / SQL_LOGIN / SQL_PASSWORD / SQL_DATABASE) and are
overridable via XI_NETWORK_SQL_* environment variables -- so you can point at
another server (e.g. the Azure box) without editing any file. The password is
handed to mysql via the MYSQL_PWD env var, so it never appears on the command
line, in the process list, or in this script's output.

Usage:
    # local DB (reads settings/network.lua), applies ALL sql/zz_*.sql:
    python tools/apply_custom_sql.py

    # see what WOULD run, touch nothing:
    python tools/apply_custom_sql.py --dry-run

    # only specific files:
    python tools/apply_custom_sql.py sql/zz_relic_119iii_mods.sql sql/zz_infamy_extra_mods.sql

    # target a remote DB whose MySQL port is reachable from here:
    set XI_NETWORK_SQL_HOST=172.215.213.23
    set XI_NETWORK_SQL_PASSWORD=...    & python tools/apply_custom_sql.py
    (on the Azure box itself, just run it there -- network.lua already points at localhost.)

The zz_ files are INSERT IGNORE / ON DUPLICATE KEY UPDATE, so re-running is safe
and idempotent. item_mods / item_latents are cached at map-server boot, so
restart the map server after applying for the new stats to take effect.
"""
from __future__ import annotations
import os
import re
import sys
import glob
import shutil
import subprocess

REPO = os.path.normpath(os.path.join(os.path.dirname(__file__), ".."))


def _setting(key: str):
    """Resolve a SQL_* setting: env override, then settings/network.lua,
    then settings/default/network.lua. Returns str or None."""
    env = os.getenv("XI_NETWORK_" + key)
    if env is not None:
        return env
    for rel in ("settings/network.lua", "settings/default/network.lua"):
        path = os.path.join(REPO, rel)
        if not os.path.exists(path):
            continue
        txt = open(path, encoding="utf-8", errors="ignore").read()
        m = re.search(
            r"\b" + re.escape(key) + r"\b\s*=\s*(?:\"([^\"]*)\"|'([^']*)'|([0-9]+))",
            txt,
        )
        if m:
            return m.group(1) or m.group(2) or m.group(3)
    return None


def creds():
    c = {k: _setting(k) for k in
         ("SQL_HOST", "SQL_PORT", "SQL_LOGIN", "SQL_PASSWORD", "SQL_DATABASE")}
    missing = [k for k in ("SQL_HOST", "SQL_LOGIN", "SQL_DATABASE") if not c.get(k)]
    if missing:
        sys.exit("ERROR: missing DB settings: " + ", ".join(missing) +
                 "  (set in settings/network.lua or via XI_NETWORK_* env vars)")
    c["SQL_PORT"] = c.get("SQL_PORT") or "3306"
    return c


def resolve_mysql():
    """Locate the mysql client the same way dbtool does: explicit override,
    then tools/config.yaml's mysql_bin dir, then PATH."""
    exe = ".exe" if os.name == "nt" else ""
    override = os.getenv("XI_MYSQL_BIN")
    if override:
        return override
    cfg = os.path.join(REPO, "tools", "config.yaml")
    if os.path.exists(cfg):
        m = re.search(r"^\s*-?\s*mysql_bin:\s*(.+?)\s*$",
                      open(cfg, encoding="utf-8", errors="ignore").read(), re.MULTILINE)
        if m:
            d = m.group(1).strip().strip('"').strip("'")
            if d:
                if not d.endswith(("/", "\\")):
                    d += "/"
                cand = d + "mysql" + exe
                if os.path.exists(cand):
                    return cand
    return shutil.which("mysql")


def main(argv):
    dry = ("--dry-run" in argv) or ("-n" in argv)
    args = [a for a in argv if not a.startswith("-")]

    if args:
        files = [a if os.path.isabs(a) else os.path.join(REPO, a) for a in args]
    else:
        files = sorted(glob.glob(os.path.join(REPO, "sql", "zz_*.sql")))
    files = [f for f in files if f.endswith(".sql") and os.path.exists(f)]
    if not files:
        sys.exit("No matching sql/zz_*.sql files found.")

    c = creds()
    mysql = resolve_mysql()
    if not mysql:
        sys.exit("ERROR: mysql client not found. Set XI_MYSQL_BIN, fix tools/config.yaml "
                 "mysql_bin, or add mysql to PATH.")

    print(f"Target : {c['SQL_LOGIN']}@{c['SQL_HOST']}:{c['SQL_PORT']}/{c['SQL_DATABASE']}")
    print(f"Client : {mysql}")
    print(f"Files  : {len(files)}")
    for f in files:
        print("   - " + os.path.relpath(f, REPO).replace("\\", "/"))
    if dry:
        print("\n--dry-run: connected to nothing, applied nothing.")
        return 0

    env = dict(os.environ)
    env["MYSQL_PWD"] = c.get("SQL_PASSWORD") or ""   # keep the password out of argv
    base = [mysql, f"-h{c['SQL_HOST']}", f"-P{c['SQL_PORT']}",
            f"-u{c['SQL_LOGIN']}", c["SQL_DATABASE"]]

    ok = 0
    for f in files:
        with open(f, "rb") as fh:
            r = subprocess.run(base, stdin=fh, capture_output=True, text=True, env=env)
        errs = [ln for ln in r.stderr.splitlines()
                if ln.strip()
                and "Using a password on the command line" not in ln
                and "insecure" not in ln.lower()]
        rel = os.path.relpath(f, REPO).replace("\\", "/")
        if r.returncode == 0 and not any(ln.startswith("ERROR") for ln in errs):
            print(f"  OK    {rel}")
            ok += 1
        else:
            print(f"  FAIL  {rel}")
            for ln in errs:
                print("        " + ln)

    print(f"\nApplied {ok}/{len(files)}. Restart the map server so item_mods/latents reload.")
    return 0 if ok == len(files) else 1


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
