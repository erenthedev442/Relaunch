"""Legendary database backup + verify-restore tool.

Protects the project's one hard guarantee — *never wipe progression*. It
mysqldumps the live ``xidb`` database to a timestamped, gzip-compressed file
on a schedule, prunes old copies, and (the part most home-grown backup setups
skip) can *prove each backup actually restores* by loading it into a throwaway
temporary database and sanity-checking row counts. A backup you've never test-
restored is a hope, not a backup.

Credentials are read from ``settings/network.lua`` (the same SQL_* parse the
Discord bots use) so they live in exactly one place. The MariaDB client tools
(``mysqldump`` / ``mysql``) are auto-located from the standard install dirs.

Commands
--------
    python db_backup.py backup            dump xidb -> backups/xidb_<ts>.sql.gz,
                                          prune old copies, write heartbeat
    python db_backup.py backup --verify   dump, then immediately test-restore it
                                          (recommended for the nightly schedule)
    python db_backup.py verify            test-restore the NEWEST backup into a
                                          temp DB, check row counts, drop it
    python db_backup.py list              show existing backups (size + age)
    python db_backup.py restore-help      print exact commands to restore for real

Exit codes
----------
    0  success
    1  configuration / credentials problem (network.lua missing or unparseable)
    2  required tools missing, or the live DB is unreachable
    3  the backup (mysqldump) failed
    4  the verify (test-restore) failed

Backups are written OUTSIDE the git working tree by default
(``<repo>/../server-backups/db`` -> ``D:\\server-backups\\db``) so a reclone or
``git clean`` can never delete them. Override with --out or $LEGENDARY_BACKUP_DIR.
"""
from __future__ import annotations

import argparse
import glob
import gzip
import os
import re
import shutil
import subprocess
import sys
import tempfile
import time
from pathlib import Path

# --- shared heartbeat helper (optional; degrade to a no-op if absent) -------
sys.path.insert(0, str(Path(__file__).resolve().parent.parent))  # tools/
try:
    from _heartbeat import write_heartbeat  # type: ignore
except Exception:  # pragma: no cover - heartbeat is best-effort
    def write_heartbeat(*_a, **_k):  # type: ignore
        return False

# ---------------------------------------------------------------------------
# Configuration (sensible defaults; override via flags / environment)
# ---------------------------------------------------------------------------
DB_NAME            = "xidb"
VERIFY_DB          = "xidb_verify_tmp"   # throwaway DB used by `verify`; dropped after
DEFAULT_KEEP       = 14                  # most-recent dumps to retain when pruning
HEARTBEAT_JOB      = "db_backup"

# Tables whose loss would mean lost player progression. `verify` requires these
# to restore non-empty; the rest of the dump is checked structurally (it loads
# without SQL errors). Counts for all of these are reported live-vs-restored.
REQUIRED_TABLES    = ["chars", "char_vars", "char_inventory"]
INFORMATIONAL_TABLES = [
    "accounts", "char_jobs", "char_points", "char_equip", "char_skills",
    "char_pet", "char_storage", "server_variables", "auction_house",
]

# Candidate directories for the MariaDB/MySQL client tools, in priority order.
_TOOL_DIR_GLOBS = [
    r"C:\Program Files\MariaDB *\bin",
    r"C:\Program Files\MariaDB*\bin",
    r"C:\Program Files\MySQL\MySQL Server *\bin",
    r"C:\Program Files\MariaDB\*\bin",
    r"C:\xampp\mysql\bin",
]


# ---------------------------------------------------------------------------
# Small utilities
# ---------------------------------------------------------------------------
def _log(msg: str) -> None:
    # ASCII-safe: the Windows console is cp1252 and chokes on fancy glyphs.
    sys.stdout.write(msg.encode("ascii", "replace").decode("ascii") + "\n")
    sys.stdout.flush()


def _repo_root() -> Path:
    # tools/db_backup/db_backup.py -> parents[2] == <repo root>
    return Path(__file__).resolve().parents[2]


def _resolve_network_lua(repo_root: Path) -> Path | None:
    live = os.environ.get("LEGENDARY_LIVE_ROOT")
    if live:
        p = Path(live) / "settings" / "network.lua"
        if p.exists():
            return p
    p = repo_root / "settings" / "network.lua"
    return p if p.exists() else None


_SETTING_RE = re.compile(
    r"^\s*(SQL_HOST|SQL_PORT|SQL_LOGIN|SQL_PASSWORD|SQL_DATABASE)"
    r"\s*=\s*(?:'([^']*)'|\"([^\"]*)\"|(\d+))",
    re.MULTILINE,
)


def _load_creds(repo_root: Path) -> dict | None:
    """Parse SQL_* credentials out of network.lua (no Lua execution)."""
    netfile = _resolve_network_lua(repo_root)
    if netfile is None:
        return None
    try:
        text = netfile.read_text(encoding="utf-8", errors="replace")
    except OSError:
        return None
    out: dict[str, str] = {}
    for m in _SETTING_RE.finditer(text):
        key = m.group(1)
        val = m.group(2) or m.group(3) or m.group(4)
        if val is not None:
            out[key] = val
    if not out:
        return None
    return {
        "host": out.get("SQL_HOST", "127.0.0.1"),
        "port": out.get("SQL_PORT", "3306"),
        "user": out.get("SQL_LOGIN", "root"),
        "password": out.get("SQL_PASSWORD", ""),
        "database": out.get("SQL_DATABASE", DB_NAME),
    }


def _first_existing(d: Path, names: list[str]) -> Path | None:
    for n in names:
        p = d / n
        if p.exists():
            return p
    return None


def _find_tools() -> tuple[Path | None, Path | None]:
    """Locate (mysqldump, mysql) executables. Returns (None, None) if missing."""
    dirs: list[Path] = []
    env = os.environ.get("LEGENDARY_DB_BIN")
    if env:
        dirs.append(Path(env))
    for pat in _TOOL_DIR_GLOBS:
        dirs.extend(Path(p) for p in glob.glob(pat))

    dump_names   = ["mysqldump.exe", "mariadb-dump.exe", "mysqldump", "mariadb-dump"]
    client_names = ["mysql.exe", "mariadb.exe", "mysql", "mariadb"]

    for d in dirs:
        if not d.is_dir():
            continue
        dump = _first_existing(d, dump_names)
        client = _first_existing(d, client_names)
        if dump and client:
            return dump, client

    # PATH fallback.
    dump_w = shutil.which("mysqldump") or shutil.which("mariadb-dump")
    client_w = shutil.which("mysql") or shutil.which("mariadb")
    if dump_w and client_w:
        return Path(dump_w), Path(client_w)
    return None, None


def _write_defaults_file(creds: dict) -> Path:
    """Write a transient [client] option file so the password never appears on
    the command line (and to silence mysqldump's password-on-argv warning).
    The caller MUST delete it. Returns the path."""
    fd, name = tempfile.mkstemp(prefix="lgnd_db_", suffix=".cnf")
    with os.fdopen(fd, "w", encoding="utf-8") as f:
        f.write("[client]\n")
        f.write(f"host={creds['host']}\n")
        f.write(f"port={creds['port']}\n")
        f.write(f"user={creds['user']}\n")
        f.write(f"password={creds['password']}\n")
    return Path(name)


def _backup_dir(args_out: str | None, repo_root: Path) -> Path:
    if args_out:
        return Path(args_out)
    env = os.environ.get("LEGENDARY_BACKUP_DIR")
    if env:
        return Path(env)
    # Default: a sibling of the repo, OUTSIDE the git tree.
    return repo_root.parent / "server-backups" / "db"


def _human_size(n: int) -> str:
    units = ["B", "KB", "MB", "GB", "TB"]
    f = float(n)
    for u in units:
        if f < 1024 or u == units[-1]:
            return f"{f:.0f} {u}" if u == "B" else f"{f:.1f} {u}"
        f /= 1024
    return f"{n} B"


def _list_backups(backup_dir: Path) -> list[Path]:
    if not backup_dir.is_dir():
        return []
    files = list(backup_dir.glob("xidb_*.sql.gz"))
    files.sort(key=lambda p: p.name, reverse=True)  # name is timestamp-sortable
    return files


# ---------------------------------------------------------------------------
# Commands
# ---------------------------------------------------------------------------
def cmd_backup(args) -> int:
    repo_root = _repo_root()
    creds = _load_creds(repo_root)
    if not creds:
        _log("ERROR: could not read SQL_* credentials from settings/network.lua")
        return 1

    dump_exe, client_exe = _find_tools()
    if not dump_exe:
        _log("ERROR: mysqldump / mariadb-dump not found. Set $LEGENDARY_DB_BIN to "
             "your MariaDB 'bin' directory.")
        return 2

    backup_dir = _backup_dir(args.out, repo_root)
    try:
        backup_dir.mkdir(parents=True, exist_ok=True)
    except OSError as e:
        _log(f"ERROR: cannot create backup directory {backup_dir}: {e}")
        return 3

    ts = time.strftime("%Y%m%d_%H%M%S", time.gmtime())
    final_gz = backup_dir / f"xidb_{ts}.sql.gz"
    tmp_sql  = backup_dir / f"xidb_{ts}.sql.partial"

    cnf = _write_defaults_file(creds)
    rc = 3
    try:
        cmd = [
            str(dump_exe),
            f"--defaults-extra-file={cnf}",
            "--single-transaction",   # consistent InnoDB snapshot, no write lock
            "--quick",                # stream rows, low memory on big tables
            "--hex-blob",             # binary-safe for blob columns (inventory, look)
            "--routines",
            "--events",
            "--triggers",
            "--add-drop-table",
            "--default-character-set=utf8mb4",
            creds["database"],
        ]
        _log(f"[backup] dumping '{creds['database']}' -> {final_gz.name} ...")
        t0 = time.time()
        with open(tmp_sql, "wb") as out_f:
            proc = subprocess.run(cmd, stdout=out_f, stderr=subprocess.PIPE)
        if proc.returncode != 0:
            err = (proc.stderr or b"").decode("utf-8", "replace").strip()
            _log(f"ERROR: mysqldump exited {proc.returncode}: {err[:500]}")
            return 3
        if tmp_sql.stat().st_size < 1024:
            _log("ERROR: dump is implausibly small (<1 KB) - aborting.")
            return 3

        # Compress the validated dump, then drop the plaintext copy.
        with open(tmp_sql, "rb") as src, gzip.open(final_gz, "wb", compresslevel=6) as dst:
            shutil.copyfileobj(src, dst, length=1024 * 1024)
        size = final_gz.stat().st_size
        dt = time.time() - t0
        _log(f"[backup] OK  {final_gz.name}  ({_human_size(size)}, {dt:.1f}s)")
        rc = 0
    finally:
        for p in (cnf, tmp_sql):
            try:
                p.unlink()
            except OSError:
                pass

    if rc != 0:
        write_heartbeat(repo_root, HEARTBEAT_JOB, ok=False, detail="backup failed")
        return rc

    # Prune old copies.
    pruned = _prune(backup_dir, args.keep)
    if pruned:
        _log(f"[backup] pruned {pruned} old backup(s), keeping newest {args.keep}")

    detail = f"backup {final_gz.name} ({_human_size(final_gz.stat().st_size)})"

    # Optional immediate verify of what we just wrote.
    if args.verify:
        vrc = _verify(repo_root, creds, client_exe, backup_dir, target=final_gz)
        if vrc != 0:
            write_heartbeat(repo_root, HEARTBEAT_JOB, ok=False,
                            detail=detail + " | VERIFY FAILED")
            return 4
        detail += " | verify OK"

    write_heartbeat(repo_root, HEARTBEAT_JOB, ok=True, detail=detail)
    return 0


def _prune(backup_dir: Path, keep: int) -> int:
    files = _list_backups(backup_dir)
    if keep <= 0 or len(files) <= keep:
        return 0
    removed = 0
    for old in files[keep:]:
        try:
            old.unlink()
            removed += 1
        except OSError:
            pass
    return removed


def cmd_verify(args) -> int:
    repo_root = _repo_root()
    creds = _load_creds(repo_root)
    if not creds:
        _log("ERROR: could not read SQL_* credentials from settings/network.lua")
        return 1
    _dump_exe, client_exe = _find_tools()
    if not client_exe:
        _log("ERROR: mysql / mariadb client not found. Set $LEGENDARY_DB_BIN.")
        return 2
    backup_dir = _backup_dir(args.out, repo_root)
    return _verify(repo_root, creds, client_exe, backup_dir, target=None)


def _run_client_sql(client_exe: Path, cnf: Path, sql: str, database: str | None = None):
    """Run a SQL string through the mysql client; return (rc, stdout, stderr).
    Output is tab-separated rows (the client's default batch format)."""
    cmd = [str(client_exe), f"--defaults-extra-file={cnf}", "--batch", "--raw"]
    if database:
        cmd.append(database)
    proc = subprocess.run(cmd, input=sql.encode("utf-8"),
                          stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    return (proc.returncode,
            (proc.stdout or b"").decode("utf-8", "replace"),
            (proc.stderr or b"").decode("utf-8", "replace"))


def _count(client_exe: Path, cnf: Path, database: str, table: str) -> int | None:
    rc, out, _err = _run_client_sql(
        client_exe, cnf,
        f"SELECT COUNT(*) FROM `{database}`.`{table}`;")
    if rc != 0:
        return None
    lines = [ln for ln in out.splitlines() if ln.strip()]
    # First line is the column header ("COUNT(*)"); value is on the next line.
    for ln in reversed(lines):
        ln = ln.strip()
        if ln.isdigit():
            return int(ln)
    return None


def _verify(repo_root: Path, creds: dict, client_exe: Path | None,
            backup_dir: Path, target: Path | None) -> int:
    """Restore `target` (or the newest backup) into a temp DB and check it.
    Returns 0 on PASS, 4 on FAIL."""
    if client_exe is None:
        _log("ERROR: mysql client not available for verify.")
        return 4

    if target is None:
        backups = _list_backups(backup_dir)
        if not backups:
            _log(f"ERROR: no backups found in {backup_dir} to verify.")
            return 4
        target = backups[0]

    if not target.exists() or target.stat().st_size < 1024:
        _log(f"ERROR: backup {target.name} is missing or implausibly small.")
        return 4

    _log(f"[verify] test-restoring {target.name} into temp DB '{VERIFY_DB}' ...")
    cnf = _write_defaults_file(creds)
    tmp_sql = backup_dir / f"_verify_{int(time.time())}.sql"
    ok = False
    try:
        # 1. Decompress to a plain .sql the client can swallow on stdin.
        try:
            with gzip.open(target, "rb") as src, open(tmp_sql, "wb") as dst:
                shutil.copyfileobj(src, dst, length=1024 * 1024)
        except (OSError, EOFError, gzip.BadGzipFile) as e:
            _log(f"ERROR: backup will not decompress ({e}). The file is corrupt.")
            return 4

        # 2. Fresh temp DB.
        rc, _o, err = _run_client_sql(
            client_exe, cnf,
            f"DROP DATABASE IF EXISTS `{VERIFY_DB}`; "
            f"CREATE DATABASE `{VERIFY_DB}` "
            f"DEFAULT CHARACTER SET utf8mb4;")
        if rc != 0:
            _log(f"ERROR: could not create temp DB: {err[:300]}")
            return 4

        # 3. Restore the dump into it.
        t0 = time.time()
        with open(tmp_sql, "rb") as f:
            cmd = [str(client_exe), f"--defaults-extra-file={cnf}", VERIFY_DB]
            proc = subprocess.run(cmd, stdin=f,
                                  stdout=subprocess.PIPE, stderr=subprocess.PIPE)
        if proc.returncode != 0:
            err = (proc.stderr or b"").decode("utf-8", "replace").strip()
            _log(f"ERROR: restore failed (mysql exit {proc.returncode}): {err[:500]}")
            return 4
        _log(f"[verify] restore completed in {time.time() - t0:.1f}s; checking tables...")

        # 4. Row-count checks: required tables must be present & non-empty;
        #    report live-vs-restored for required + informational tables.
        problems: list[str] = []
        rows: list[tuple[str, str, str, str]] = []
        for table in REQUIRED_TABLES + INFORMATIONAL_TABLES:
            live = _count(client_exe, cnf, creds["database"], table)
            restored = _count(client_exe, cnf, VERIFY_DB, table)
            required = table in REQUIRED_TABLES
            status = "ok"
            if restored is None:
                status = "MISSING"
                if required:
                    problems.append(f"{table}: not restored")
            elif required and restored == 0:
                status = "EMPTY"
                problems.append(f"{table}: restored 0 rows")
            elif live is not None and restored is not None and live > 0:
                ratio = restored / live
                if ratio < 0.5 or ratio > 1.5:
                    status = "DRIFT?"  # informational warning, not a hard fail
            rows.append((
                table,
                "-" if live is None else str(live),
                "-" if restored is None else str(restored),
                status,
            ))

        _log("")
        _log(f"    {'table':<18}{'live':>10}{'restored':>12}   status")
        _log(f"    {'-'*18}{'-'*10:>10}{'-'*12:>12}   ------")
        for name, live_s, rest_s, status in rows:
            _log(f"    {name:<18}{live_s:>10}{rest_s:>12}   {status}")
        _log("")

        if problems:
            _log("[verify] FAIL: " + "; ".join(problems))
            return 4
        _log(f"[verify] PASS: {target.name} restores cleanly and all required "
             f"tables are populated.")
        ok = True
        return 0
    finally:
        # Always drop the temp DB and remove the scratch .sql.
        try:
            _run_client_sql(client_exe, cnf, f"DROP DATABASE IF EXISTS `{VERIFY_DB}`;")
        except Exception:
            pass
        for p in (cnf, tmp_sql):
            try:
                p.unlink()
            except OSError:
                pass
        if not ok:
            # Leave a failure heartbeat only when invoked standalone; the
            # backup path manages its own heartbeat around verify.
            pass


def cmd_list(args) -> int:
    repo_root = _repo_root()
    backup_dir = _backup_dir(args.out, repo_root)
    files = _list_backups(backup_dir)
    _log(f"Backup directory: {backup_dir}")
    if not files:
        _log("  (no backups yet)")
        return 0
    now = time.time()
    total = 0
    _log("")
    _log(f"  {'file':<34}{'size':>10}   age")
    _log(f"  {'-'*34}{'-'*10:>10}   ---")
    for f in files:
        st = f.stat()
        total += st.st_size
        age_h = (now - st.st_mtime) / 3600.0
        age = f"{age_h:.1f}h ago" if age_h < 48 else f"{age_h/24:.1f}d ago"
        _log(f"  {f.name:<34}{_human_size(st.st_size):>10}   {age}")
    _log("")
    _log(f"  {len(files)} backup(s), {_human_size(total)} total")
    return 0


def cmd_restore_help(args) -> int:
    repo_root = _repo_root()
    creds = _load_creds(repo_root) or {}
    backup_dir = _backup_dir(args.out, repo_root)
    files = _list_backups(backup_dir)
    newest = files[0].name if files else "xidb_YYYYMMDD_HHMMSS.sql.gz"
    db = creds.get("database", DB_NAME)
    dump_exe, client_exe = _find_tools()
    client = str(client_exe) if client_exe else r"C:\Program Files\MariaDB 10.6\bin\mysql.exe"
    _log("To restore a backup FOR REAL (overwrites the live database):")
    _log("")
    _log("  1. Stop the game server (so nothing writes mid-restore).")
    _log("  2. From a shell, decompress and pipe the dump into the live DB:")
    _log("")
    _log(f"     gzip -dc \"{backup_dir / newest}\" | \"{client}\" -u {creds.get('user','root')} -p {db}")
    _log("")
    _log("     (PowerShell has no gzip; instead use 7-Zip or this tool's verify")
    _log("      path as a reference. On Windows you can also run:")
    _log(f"        python db_backup.py verify   # proves the newest dump restores")
    _log("")
    _log("  3. Restart the server.")
    _log("")
    _log("Note: dumps are table-level (no CREATE DATABASE). If the database was")
    _log(f"      dropped entirely, first run:  CREATE DATABASE {db} DEFAULT CHARACTER SET utf8mb4;")
    return 0


def main(argv: list[str] | None = None) -> int:
    p = argparse.ArgumentParser(
        prog="db_backup.py",
        description="Backup + test-restore the Legendary game database (xidb).")
    sub = p.add_subparsers(dest="cmd")

    pb = sub.add_parser("backup", help="dump xidb, prune old copies, write heartbeat")
    pb.add_argument("--verify", action="store_true",
                    help="immediately test-restore the new dump (recommended nightly)")
    pb.add_argument("--keep", type=int, default=DEFAULT_KEEP,
                    help=f"how many recent backups to retain (default {DEFAULT_KEEP})")
    pb.add_argument("--out", default=None, help="backup directory (overrides default)")
    pb.set_defaults(func=cmd_backup)

    pv = sub.add_parser("verify", help="test-restore the NEWEST backup into a temp DB")
    pv.add_argument("--out", default=None, help="backup directory (overrides default)")
    pv.set_defaults(func=cmd_verify)

    pl = sub.add_parser("list", help="list existing backups")
    pl.add_argument("--out", default=None, help="backup directory (overrides default)")
    pl.set_defaults(func=cmd_list)

    pr = sub.add_parser("restore-help", help="print real-restore instructions")
    pr.add_argument("--out", default=None, help="backup directory (overrides default)")
    pr.set_defaults(func=cmd_restore_help)

    args = p.parse_args(argv)
    if not getattr(args, "func", None):
        p.print_help()
        return 0
    try:
        return args.func(args)
    except KeyboardInterrupt:
        _log("interrupted")
        return 1


if __name__ == "__main__":
    raise SystemExit(main())
