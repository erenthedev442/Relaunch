# Portal activity sampler tick. Reads PORTAL_TICK_KEY from .env and pokes the
# local /api/internal/tick endpoint. Run every minute by the FFXIPortalTick task.
# .env lives next to app.py (one level above this deploy/ folder), wherever the
# checkout is -- no hardcoded install path.
$envf = Join-Path (Split-Path -Parent $PSScriptRoot) '.env'
$m = Select-String -Path $envf -Pattern '^\s*PORTAL_TICK_KEY=(.+)$' | Select-Object -First 1
if ($m) {
  $k = $m.Matches.Groups[1].Value.Trim()
  if ($k) {
    try {
      Invoke-WebRequest -UseBasicParsing -TimeoutSec 25 -Uri ("http://127.0.0.1:8090/api/internal/tick?key=" + $k) | Out-Null
    } catch { }
  }
}
