# ---------------------------------------------------------------------------
# azure-update.ps1  -  "rebuild + reload mods" button for the LIVE Azure server.
# Uploads your latest zz_*.sql, then on the box: backup -> git pull -> rebuild
# (cmake --build build) -> reload the mod SQL (sudo mariadb) -> restart.
# Uses the same proven methods as your other Azure bats - no dbtool, no installs.
# Launched by azure-update.bat. Reuses deploy-to-azure.config (asked once).
# ---------------------------------------------------------------------------
$ErrorActionPreference = 'Stop'
$Repo = Split-Path -Parent $MyInvocation.MyCommand.Path
$Cfg  = Join-Path $Repo 'deploy-to-azure.config'
$Ip   = '172.215.213.23'
$RemoteScript = Join-Path $Repo 'tools\_azure_update_remote.sh'

function Pause-Exit($code) { Write-Host ''; Read-Host 'Press Enter to close'; exit $code }

foreach ($t in 'ssh','scp') {
  if (-not (Get-Command $t -ErrorAction SilentlyContinue)) {
    Write-Host "ERROR: '$t' not installed. Turn on 'OpenSSH Client' in Settings > Apps > Optional Features." -ForegroundColor Red
    Pause-Exit 1
  }
}

# Reuse (or create) the shared deploy config.
if (-not (Test-Path $Cfg)) {
  $u = Read-Host 'Your server username [press Enter for azureuser]'
  if ([string]::IsNullOrWhiteSpace($u)) { $u = 'azureuser' }
  $k = Read-Host 'Key file path (or Enter for password)'
  $lines = @("user=$u")
  if (-not [string]::IsNullOrWhiteSpace($k)) { $lines += "key=$($k.Trim('"'))" }
  Set-Content -Path $Cfg -Value $lines -Encoding ASCII
}
$conf = @{}
Get-Content $Cfg | ForEach-Object { if ($_ -match '^([^=]+)=(.*)$') { $conf[$matches[1].Trim()] = $matches[2].Trim() } }
$User = $conf['user']
$Key  = $conf['key']
$opts = @('-o', 'StrictHostKeyChecking=accept-new')
if ($Key) {
  if (-not (Test-Path $Key)) { Write-Host "ERROR: key file not found: $Key (fix $Cfg)" -ForegroundColor Red; Pause-Exit 1 }
  $opts += @('-i', $Key)
}

$files = Get-ChildItem -Path (Join-Path $Repo 'sql\zz_*.sql') -File -ErrorAction SilentlyContinue

Write-Host '============================================================' -ForegroundColor Yellow
Write-Host ' FULL update of the LIVE Azure server:' -ForegroundColor Yellow
Write-Host '   0. commit + push your local changes (so the box pulls them)'
Write-Host '   1. back up the database'
Write-Host '   2. git pull latest code'
Write-Host '   3. rebuild the binaries (cmake --build build)'
Write-Host '   4. reload your mod SQL (zz_*.sql)'
Write-Host '   5. restart - players disconnect briefly'
Write-Host ' Player characters / inventory / AH are preserved.' -ForegroundColor Yellow
Write-Host '============================================================' -ForegroundColor Yellow
$go = Read-Host 'Proceed? [Y/N]'
if ($go -notmatch '^[Yy]') { Write-Host 'Cancelled - nothing changed.'; Pause-Exit 0 }

# Commit + push ALL local changes so the box's `git pull` actually sees them.
# Without this, laptop edits (Lua / C++ / scripts) silently never reach Azure.
# (zz_*.sql are also uploaded directly below; everything else rides git.)
Write-Host ''
Write-Host '[1/3] Committing + pushing your local changes...' -ForegroundColor Cyan
$pushOk = $true
Push-Location $Repo
try {
  & git add -A
  & git diff --cached --quiet
  if ($LASTEXITCODE -ne 0) {
    $stamp = Get-Date -Format 'yyyy-MM-dd_HH:mm'
    & git commit -m "Live update $stamp" | Out-Host
    Write-Host '  committed local changes.'
  } else {
    Write-Host '  working tree clean - nothing new to commit.'
  }
  $branch = (& git rev-parse --abbrev-ref HEAD).Trim()
  Write-Host "  pushing $branch -> fjb ..."
  & git push fjb $branch
  if ($LASTEXITCODE -ne 0) { $pushOk = $false }
} finally { Pop-Location }
if (-not $pushOk) {
  Write-Host 'ERROR: git push failed - resolve it (e.g. pull/merge), then re-run.' -ForegroundColor Red
  Pause-Exit 1
}

# Upload latest zz_*.sql + the remote script (relative paths => no C: colon issue).
Write-Host ''
Write-Host '[2/3] Uploading mod SQL + update script...' -ForegroundColor Cyan
Push-Location (Join-Path $Repo 'sql')
try {
  $names = @()
  if ($files) { $names = $files | ForEach-Object { $_.Name } }
  & scp @opts @names '../tools/_azure_update_remote.sh' "${User}@${Ip}:"
  $rc = $LASTEXITCODE
} finally { Pop-Location }
if ($rc -ne 0) { Write-Host 'ERROR: upload failed (check key / network).' -ForegroundColor Red; Pause-Exit 1 }

# Run it (strip CRLF, -t so sudo/git can prompt if ever needed).
Write-Host ''
Write-Host '[3/3] Rebuilding + reloading on the server (watch the steps)...' -ForegroundColor Cyan
$remoteCmd = "tr -d '\015' < ~/_azure_update_remote.sh > ~/_au.sh && bash ~/_au.sh; rm -f ~/_au.sh"
& ssh @opts '-t' "${User}@${Ip}" $remoteCmd
$rc = $LASTEXITCODE
if ($rc -ne 0) { Write-Host 'ERROR: the update reported a problem (see messages above).' -ForegroundColor Red; Pause-Exit 1 }

Write-Host ''
Write-Host '============================================================' -ForegroundColor Green
Write-Host ' DONE - Azure rebuilt, mod SQL reloaded, server restarted.' -ForegroundColor Green
Write-Host '============================================================' -ForegroundColor Green
Pause-Exit 0
