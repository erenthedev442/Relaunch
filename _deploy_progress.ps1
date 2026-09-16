Write-Host '--- compile processes ---'
Get-Process ninja, cl, link, cmake, msbuild -ErrorAction SilentlyContinue |
    Format-Table Name, Id, CPU, StartTime -AutoSize
Write-Host '--- xi ---'
Get-Process xi_map, xi_connect, xi_world, xi_search -ErrorAction SilentlyContinue |
    Format-Table Name, Id, StartTime -AutoSize
Write-Host '--- vps-rebuild.log tail ---'
Get-Content C:\server\vps-rebuild.log -Tail 15
