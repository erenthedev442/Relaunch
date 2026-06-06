# LandSandBoat - Open required firewall ports
# Double-click or right-click -> "Run with PowerShell"
# The script will automatically request admin elevation via UAC.

if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Start-Process powershell -Verb RunAs -ArgumentList "-ExecutionPolicy Bypass -File `"$PSCommandPath`""
    exit
}

$rules = @(
    @{ Name = "LSB Login Data TCP"; Port = 54230; Proto = "TCP" },
    @{ Name = "LSB Login Auth TCP"; Port = 54231; Proto = "TCP" },
    @{ Name = "LSB Login View TCP"; Port = 54001; Proto = "TCP" },
    @{ Name = "LSB Login Conf TCP"; Port = 51220; Proto = "TCP" },
    @{ Name = "LSB Search TCP";     Port = 54002; Proto = "TCP" },
    @{ Name = "LSB Map UDP";        Port = 54230; Proto = "UDP" }
)

foreach ($rule in $rules) {
    $existing = Get-NetFirewallRule -DisplayName $rule.Name -ErrorAction SilentlyContinue
    if ($existing) {
        Write-Host "Already exists: $($rule.Name)" -ForegroundColor Yellow
    } else {
        New-NetFirewallRule -DisplayName $rule.Name -Direction Inbound -Protocol $rule.Proto -LocalPort $rule.Port -Action Allow | Out-Null
        Write-Host "Created: $($rule.Name) ($($rule.Proto) $($rule.Port))" -ForegroundColor Green
    }
}

Write-Host ""
Write-Host "Done. All LSB firewall rules are active." -ForegroundColor Cyan
Write-Host "Press any key to close..."
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
