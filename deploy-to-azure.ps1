# ---------------------------------------------------------------------------
# deploy-to-azure.ps1  -  pushes your local sql\zz_*.sql changes to the LIVE
# Azure server and restarts the game. Launched by deploy-to-azure.bat (double-
# click that, not this). First run asks your server username once and saves it.
# ---------------------------------------------------------------------------
$ErrorActionPreference = 'Stop'
$Repo = Split-Path -Parent $MyInvocation.MyCommand.Path
$Cfg  = Join-Path $Repo 'deploy-to-azure.config'
$Ip   = '172.215.213.23'                       # your Azure server IP
$RemoteScript = Join-Path $Repo 'tools\_deploy_remote.sh'

function Pause-Exit($code) { Write-Host ''; Read-Host 'Press Enter to close'; exit $code }

# --- need Windows' built-in ssh/scp ---------------------------------------
foreach ($t in 'ssh','scp') {
  if (-not (Get-Command $t -ErrorAction SilentlyContinue)) {
    Write-Host "ERROR: '$t' is not installed." -ForegroundColor Red
    Write-Host "Turn on 'OpenSSH Client' in Settings > Apps > Optional Features, then retry."
    Pause-Exit 1
  }
}

# --- first-run setup (saved to deploy-to-azure.config) --------------------
if (-not (Test-Path $Cfg)) {
  Write-Host '=== First-time setup (asked only once) ===' -ForegroundColor Cyan
  $u = Read-Host 'Your server username [press Enter for azureuser]'
  if ([string]::IsNullOrWhiteSpace($u)) { $u = 'azureuser' }
  Write-Host ''
  Write-Host 'If you sign in with a KEY FILE (.pem), paste its full path now.'
  Write-Host 'If you sign in with a PASSWORD, just press Enter.'
  $k = Read-Host 'Key file path (or Enter for password)'
  $lines = @("user=$u")
  if (-not [string]::IsNullOrWhiteSpace($k)) { $lines += "key=$($k.Trim('"'))" }
  Set-Content -Path $Cfg -Value $lines -Encoding ASCII
  Write-Host 'Saved. (A key file means no password typing each time.)' -ForegroundColor Green
  Write-Host ''
}

# --- load config ----------------------------------------------------------
$conf = @{}
Get-Content $Cfg | ForEach-Object { if ($_ -match '^([^=]+)=(.*)$') { $conf[$matches[1].Trim()] = $matches[2].Trim() } }
$User = $conf['user']
$Key  = $conf['key']
# Auto-accept the first-connection host key (avoids a confusing y/n prompt the
# very first time), then add -i <key> if a key file was configured.
$opts = @('-o', 'StrictHostKeyChecking=accept-new')
if ($Key) {
  if (-not (Test-Path $Key)) { Write-Host "ERROR: key file not found: $Key" -ForegroundColor Red; Write-Host "Fix it in $Cfg (or delete that file to set up again)."; Pause-Exit 1 }
  $opts += @('-i', $Key)
}

# --- gather the SQL files to send -----------------------------------------
$files = Get-ChildItem -Path (Join-Path $Repo 'sql\zz_*.sql') -File -ErrorAction SilentlyContinue
if (-not $files) { Write-Host 'No sql\zz_*.sql files found to deploy.'; Pause-Exit 0 }

Write-Host "About to deploy to $User@$Ip :" -ForegroundColor Cyan
$files | ForEach-Object { Write-Host "   $($_.Name)" }
Write-Host ''
Write-Host 'Then the LIVE game restarts - any online players disconnect for a few seconds.' -ForegroundColor Yellow
$go = Read-Host 'Proceed? [Y/N]'
if ($go -notmatch '^[Yy]') { Write-Host 'Cancelled - nothing changed.'; Pause-Exit 0 }

# --- upload (run scp from the sql folder so paths have no C: drive colon) --
Write-Host ''
Write-Host '[1/2] Uploading files...  (type your server password if it asks)' -ForegroundColor Cyan
Push-Location (Join-Path $Repo 'sql')
try {
  $names = $files | ForEach-Object { $_.Name }
  & scp @opts @names '../tools/_deploy_remote.sh' "${User}@${Ip}:"
  $rc = $LASTEXITCODE
} finally { Pop-Location }
if ($rc -ne 0) { Write-Host 'ERROR: upload failed (check username / key / network).' -ForegroundColor Red; Pause-Exit 1 }

# --- import + restart on the server ---------------------------------------
Write-Host ''
Write-Host '[2/2] Importing and restarting on the server...' -ForegroundColor Cyan
$remoteCmd = "tr -d '\015' < ~/_deploy_remote.sh > ~/_dr.sh && bash ~/_dr.sh; rm -f ~/_dr.sh"
& ssh @opts '-t' "${User}@${Ip}" $remoteCmd
$rc = $LASTEXITCODE
if ($rc -ne 0) { Write-Host 'ERROR: the server step reported a problem (see messages above).' -ForegroundColor Red; Pause-Exit 1 }

Write-Host ''
Write-Host '============================================================' -ForegroundColor Green
Write-Host ' DONE - your SQL changes are LIVE on the Azure server.' -ForegroundColor Green
Write-Host '============================================================' -ForegroundColor Green
Pause-Exit 0
