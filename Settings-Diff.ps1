# ================================================
# LEGENDARY Server - Clean Grouped Change Log
# With Commas + No Decimals
# ================================================

$ServerPath = "D:\server"
$DefaultPath = "$ServerPath\settings\default"
$LivePath = "$ServerPath\settings"

$Timestamp = Get-Date -Format "yyyy-MM-dd_HH-mm-ss"
$OutputFile = "$ServerPath\LEGENDARY_Changes_$Timestamp.txt"

function Format-Number ($value) {
    if ($value -match '^\d+\.0+$') {
        $value = $value -replace '\.0+$', ''
    }
    if ($value -match '^\d+$') {
        return [int]$value | ForEach-Object { '{0:N0}' -f $_ }
    }
    return $value
}

$Report = @()
$Report += "=== LEGENDARY Server Settings Changes ==="
$Report += "Date: $(Get-Date -Format 'MM/dd/yyyy HH:mm:ss')"
$Report += ""

$Categories = @{
    "Server Info"      = @("SERVER_NAME","SERVER_MESSAGE")
    "Progression"      = @("MAX_LEVEL","INITIAL_LEVEL_CAP")
    "Experience Rates" = @("EXP_RATE","CAPACITY_RATE","BOOK_EXP_RATE","ROE_EXP_RATE","SPARKS_RATE")
    "Gil & Economy"    = @("GIL_RATE","START_GIL")
    "Combat Power"     = @("CURE_POWER","ELEMENTAL_POWER","DIVINE_POWER","BLUE_POWER","WEAPON_SKILL_POWER")
    "Drops & Loot"     = @("DROP_RATE_MULTIPLIER","MOB_GIL_MULTIPLIER","CASKET_DROP_RATE")
    "Movement & QoL"   = @("BASE_SPEED","SPEED_LIMIT","ALL_MAPS")
    "Trusts"           = @("ALTER_EGO_HP_MULTIPLIER","ALTER_EGO_STAT_MULTIPLIER","ENABLE_TRUST_CASTING")
    "Other"            = @()
}

$ChangesByCategory = @{}

$Files = @("main.lua","map.lua","login.lua","network.lua")

foreach ($file in $Files) {
    $defaultFile = "$DefaultPath\$file"
    $liveFile = "$LivePath\$file"
    if (-not (Test-Path $liveFile)) { continue }

    $defaultContent = Get-Content $defaultFile
    $liveContent = Get-Content $liveFile

    $diff = Compare-Object $defaultContent $liveContent

    foreach ($line in $diff) {
        if ($line.SideIndicator -eq "=>") {
            $newLine = $line.InputObject.Trim()
            if ($newLine -match '^\s*(\w+)\s*=\s*(.+?)(,|\s*$)') {
                $key = $matches[1].Trim()
                $newValue = Format-Number $matches[2].Trim()

                $oldLine = $defaultContent | Where-Object { $_ -match "^\s*$key\s*=" }
                $oldValue = if ($oldLine -match '=\s*(.+?)(,|\s*$)') { Format-Number $matches[1].Trim() } else { "???" }

                $category = "Other"
                foreach ($cat in $Categories.Keys) {
                    if ($Categories[$cat] -contains $key) { $category = $cat; break }
                }

                if (-not $ChangesByCategory.ContainsKey($category)) {
                    $ChangesByCategory[$category] = @()
                }
                $ChangesByCategory[$category] += "$key Before = $oldValue, Now = $newValue"
            }
        }
    }
}

foreach ($cat in $Categories.Keys) {
    if ($ChangesByCategory.ContainsKey($cat) -and $ChangesByCategory[$cat].Count -gt 0) {
        $Report += "**$cat**"
        $Report += $ChangesByCategory[$cat]
        $Report += ""
    }
}

if ($ChangesByCategory.Count -eq 0) {
    $Report += "No changes detected."
}

$Report += "============================================"

$FullText = $Report -join "`n"

# Split into chunks with clear markers
$MaxLength = 1900
$Chunks = @()
for ($i = 0; $i -lt $FullText.Length; $i += $MaxLength) {
    $Chunks += $FullText.Substring($i, [Math]::Min($MaxLength, $FullText.Length - $i))
}

for ($i = 0; $i -lt $Chunks.Count; $i++) {
    $part = $i + 1
    $total = $Chunks.Count
    Write-Host "`n--- START COPY PART $part OF $total ---" -ForegroundColor Magenta
    Write-Host $Chunks[$i]
    Write-Host "--- END COPY PART $part OF $total ---`n" -ForegroundColor Magenta
}

$FullText | Out-File $OutputFile -Encoding UTF8

Write-Host "Success! File saved as: $OutputFile" -ForegroundColor Green