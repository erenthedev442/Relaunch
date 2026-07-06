# Live C++ build progress meter for the relaunch rebuild.
# Reads the ninja [done/total] step counter from vps-rebuild-build.log while a
# rebuild is compiling, and draws a live bar. Ctrl+C to close.
$log = 'C:\server\vps-rebuild-build.log'
Write-Host 'Live C++ build progress  (Ctrl+C to close)' -ForegroundColor Cyan
Write-Host ''
while ($true) {
  $n = -1; $t = -1
  if (Test-Path $log) {
    $lines = Get-Content $log -Tail 120 -ErrorAction SilentlyContinue
    $last  = $lines | Where-Object { $_ -match '^\[\d+/\d+\]' } | Select-Object -Last 1
    if ($last -and $last -match '^\[(\d+)/(\d+)\]') { $n = [int]$Matches[1]; $t = [int]$Matches[2] }
  }
  if ($t -gt 0) {
    $p   = [int]($n * 100 / $t)
    $bar = ('#' * [int]($p / 5)).PadRight(20)
    Write-Host -NoNewline ([char]13 + ("  [{0}] {1,4}/{2} steps  {3,3}%   " -f $bar, $n, $t, $p))
    if ($n -ge $t) { Write-Host ''; Write-Host '  C++ build steps complete.' -ForegroundColor Green; break }
  } else {
    Write-Host -NoNewline ([char]13 + '  waiting for a rebuild to start compiling...        ')
  }
  Start-Sleep -Seconds 2
}
