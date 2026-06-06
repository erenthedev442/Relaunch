"""Rescue a player whose chars.pos_zone is a broken / instance-only zone.

When a player gets stuck in a zone they can't log into, the only way
out is to manually rewrite their saved position. This script:

  1. Finds the character by name.
  2. Shows their CURRENT saved zone + position.
  3. Updates them to a safe zone (GM Home, zone 210) at a known-good coord.

Use only when the player is offline / stuck out of game (logging in
keeps failing). Player should be able to log in immediately after.
"""
import sys
from pathlib import Path

WORKTREE = Path(r'D:\server\.claude\worktrees\busy-johnson-c59e6e')
sys.path.insert(0, str(WORKTREE))
from tools.docgen._db import connect

if len(sys.argv) != 2:
    print("Usage: python tools/_rescue_jbae.py <charname>")
    sys.exit(1)

charname = sys.argv[1]
c = connect(WORKTREE)
cur = c.cursor()

cur.execute(
    "SELECT charid, accid, pos_zone, pos_prevzone, pos_x, pos_y, pos_z, pos_rot "
    "FROM chars WHERE charname = %s", (charname,))
row = cur.fetchone()
if not row:
    print(f"No character named '{charname}' found.")
    sys.exit(1)

charid, accid, pz, ppz, x, y, z, rot = row
print(f"Character:  {charname}  charid={charid}  accid={accid}")
print(f"Saved pos:  zone={pz}  prev_zone={ppz}  ({x:.2f}, {y:.2f}, {z:.2f}) rot={rot}")

# Also clear accounts_sessions just in case there's a stale row.
cur.execute("DELETE FROM accounts_sessions WHERE charid = %s", (charid,))
deleted = cur.rowcount

# Rewrite to GM Home (zone 210). Picking (0, 0, 0) lets the zone's
# onZoneIn or default entry coordinate auto-place the player; GM_Home
# has plenty of valid floor at the origin.
SAFE_ZONE = 210      # GM Home
SAFE_X, SAFE_Y, SAFE_Z, SAFE_ROT = 0.0, 0.0, 0.0, 128

cur.execute(
    "UPDATE chars SET pos_zone = %s, pos_prevzone = %s, "
    "pos_x = %s, pos_y = %s, pos_z = %s, pos_rot = %s "
    "WHERE charid = %s",
    (SAFE_ZONE, SAFE_ZONE, SAFE_X, SAFE_Y, SAFE_Z, SAFE_ROT, charid))
c.commit()
print(f"Cleared {deleted} stale accounts_sessions row(s).")
print(f"Updated {charname} to zone {SAFE_ZONE} ({SAFE_X}, {SAFE_Y}, {SAFE_Z}).")
print(f"{charname} can log in now.")
