Write-Host '--- powershell command lines ---'
Get-CimInstance Win32_Process -Filter "Name='powershell.exe'" |
    Select-Object ProcessId, CreationDate, CommandLine |
    Format-List
Write-Host '--- git processes ---'
Get-CimInstance Win32_Process -Filter "Name='git.exe'" |
    Select-Object ProcessId, CommandLine |
    Format-List
Write-Host '--- origin/relaunch vs HEAD ---'
git -C C:\server rev-parse HEAD
git -C C:\server rev-parse origin/relaunch
Write-Host '--- deploy-now file sizes ---'
Get-Item C:\relaunch-ops\logs\deploy-now.* -ErrorAction SilentlyContinue |
    Format-Table Name, Length, LastWriteTime -AutoSize
