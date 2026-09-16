Write-Host '--- deploy-now.out ---'
if (Test-Path C:\relaunch-ops\logs\deploy-now.out) {
    Get-Content C:\relaunch-ops\logs\deploy-now.out -Tail 50
} else { Write-Host 'MISSING' }
Write-Host '--- deploy-now.err ---'
if (Test-Path C:\relaunch-ops\logs\deploy-now.err) {
    Get-Content C:\relaunch-ops\logs\deploy-now.err -Tail 50
} else { Write-Host 'MISSING' }
Write-Host '--- powershell ---'
Get-Process powershell -ErrorAction SilentlyContinue |
    Select-Object Id, StartTime, CPU |
    Format-Table -AutoSize
Write-Host '--- deploy-relaunch.log tail ---'
if (Test-Path C:\server\deploy-relaunch.log) {
    Get-Content C:\server\deploy-relaunch.log -Tail 30
}
Write-Host '--- C:\server HEAD ---'
git -C C:\server log -1 --oneline
git -C C:\server status -sb
