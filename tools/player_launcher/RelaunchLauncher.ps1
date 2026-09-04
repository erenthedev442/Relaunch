#requires -Version 5.1
<#
.SYNOPSIS
    Relaunch player launcher -- fetch official Ashita or Windower, write a
    Relaunch profile, manage resolution / addons, launch into the live server.

    Clients are downloaded from their official URLs into %LOCALAPPDATA%\Relaunch.
    Your existing Windower/Ashita folders are never touched.
#>
[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

if ([Threading.Thread]::CurrentThread.GetApartmentState() -ne 'STA') {
    $args = @('-NoProfile', '-ExecutionPolicy', 'Bypass', '-STA', '-File', $PSCommandPath)
    Start-Process -FilePath 'powershell.exe' -ArgumentList $args -Wait
    exit $LASTEXITCODE
}

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
[System.Windows.Forms.Application]::EnableVisualStyles()

# ---------------------------------------------------------------------------
# Constants
# ---------------------------------------------------------------------------
$ServerHost   = '15.204.112.102'
$AshitaZipUrl = 'https://github.com/AshitaXI/Ashita-v4beta/archive/refs/heads/main.zip'
$WindowerUrl  = 'https://files.windower.net/4/live/Windower.exe'
$XiloaderApi  = 'https://api.github.com/repos/LandSandBoat/xiloader/releases/latest'
$VcRedistUrl  = 'https://aka.ms/vs/17/release/vc_redist.x86.exe'
$HttpHeaders  = @{ 'User-Agent' = 'RelaunchLauncher' }

$Root         = $PSScriptRoot
$RepoRoot     = (Resolve-Path (Join-Path $Root '..\..')).Path
$AppDir       = Join-Path $env:LOCALAPPDATA 'Relaunch'
$SettingsPath = Join-Path $AppDir 'launcher.json'
$AshitaDir    = Join-Path $AppDir 'Ashita'
$WindowerDir  = Join-Path $AppDir 'Windower'
$XiloaderPath = Join-Path $AppDir 'xiloader.exe'

$Resolutions = @(
    '1280 x 720'
    '1600 x 900'
    '1920 x 1080'
    '2560 x 1440'
    'Native'
)

$AddonCatalog = @(
    @{ Id = 'fps';            Label = 'FPS display';              Ashita = $true;  Windower = $true;  StockAshita = $true;  StockWindower = $true }
    @{ Id = 'timestamp';      Label = 'Timestamps';               Ashita = $true;  Windower = $true;  StockAshita = $true;  StockWindower = $true }
    @{ Id = 'distance';       Label = 'Target distance';          Ashita = $true;  Windower = $true;  StockAshita = $true;  StockWindower = $true }
    @{ Id = 'tparty';         Label = 'Party HP / TP';            Ashita = $true;  Windower = $false; StockAshita = $true;  StockWindower = $false }
    @{ Id = 'relaunch';       Label = 'Relaunch helper';          Ashita = $true;  Windower = $true;  StockAshita = $false; StockWindower = $false }
    @{ Id = 'augment_browser';Label = 'Augment Browser (Windower)'; Ashita = $false; Windower = $true; StockAshita = $false; StockWindower = $false }
    @{ Id = 'augment_trade';  Label = 'Augment Trade (Windower)'; Ashita = $false; Windower = $true;  StockAshita = $false; StockWindower = $false }
)

# ---------------------------------------------------------------------------
# Settings
# ---------------------------------------------------------------------------
function Default-Settings {
    [pscustomobject]@{
        ffxiPath   = ''
        client     = 'Ashita'
        resolution = '1920 x 1080'
        windowMode = 'Borderless'
        addons     = @{
            fps             = $true
            timestamp       = $true
            distance        = $true
            tparty          = $true
            relaunch        = $true
            augment_browser = $true
            augment_trade   = $true
        }
        installDats = $false
    }
}

function Load-Settings {
    if (Test-Path $SettingsPath) {
        try {
            $raw = Get-Content $SettingsPath -Raw | ConvertFrom-Json
            $d = Default-Settings
            foreach ($p in $d.PSObject.Properties.Name) {
                if ($null -ne $raw.$p) { $d.$p = $raw.$p }
            }
            if (-not $d.addons) { $d.addons = (Default-Settings).addons }
            return $d
        } catch {}
    }
    return Default-Settings
}

function Save-Settings($s) {
    New-Item -ItemType Directory -Force -Path $AppDir | Out-Null
    $s | ConvertTo-Json -Depth 6 | Set-Content -Path $SettingsPath -Encoding UTF8
}

$State = Load-Settings

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------
function Write-Log($msg, $color = 'LightGray') {
    if ($script:LogBox -and -not $script:LogBox.IsDisposed) {
        $script:LogBox.SelectionColor = [System.Drawing.Color]::FromName($color)
        $script:LogBox.AppendText(("[{0}] {1}`r`n" -f (Get-Date -Format 'HH:mm:ss'), $msg))
        $script:LogBox.ScrollToCaret()
        [System.Windows.Forms.Application]::DoEvents()
    }
}

function Get-FfxiInstalls {
    $cands = New-Object System.Collections.Generic.List[string]
    foreach ($key in @(
        'HKLM:\SOFTWARE\WOW6432Node\PlayOnlineUS\InstallFolder',
        'HKLM:\SOFTWARE\PlayOnlineUS\InstallFolder',
        'HKLM:\SOFTWARE\WOW6432Node\PlayOnline\InstallFolder',
        'HKLM:\SOFTWARE\WOW6432Node\PlayOnlineEU\InstallFolder'
    )) {
        try {
            (Get-ItemProperty $key -ErrorAction Stop).PSObject.Properties | ForEach-Object {
                if ($_.Value -is [string] -and (Test-Path (Join-Path $_.Value 'FFXiMain.dll'))) {
                    $cands.Add($_.Value.TrimEnd('\'))
                }
            }
        } catch {}
    }
    foreach ($c in @(
        'C:\Program Files (x86)\PlayOnline\SquareEnix\FINAL FANTASY XI',
        'C:\Program Files\PlayOnline\SquareEnix\FINAL FANTASY XI',
        'C:\PlayOnline\SquareEnix\FINAL FANTASY XI',
        'C:\Program Files (x86)\Steam\steamapps\common\PlayOnline\SquareEnix\FINAL FANTASY XI'
    )) {
        if (Test-Path (Join-Path $c 'FFXiMain.dll')) { $cands.Add($c.TrimEnd('\')) }
    }
    return @($cands | Select-Object -Unique)
}

function Resolve-Resolution($label) {
    if ($label -eq 'Native') {
        $b = [System.Windows.Forms.Screen]::PrimaryScreen.Bounds
        return @{ W = $b.Width; H = $b.Height }
    }
    $parts = $label -split '\s*x\s*'
    return @{ W = [int]$parts[0]; H = [int]$parts[1] }
}

function Window-ModeValue($mode) {
    switch ($mode) {
        'Fullscreen' { 0 }
        'Windowed'   { 1 }
        default      { 3 }  # Borderless
    }
}

function Test-AshitaInstalled { Test-Path (Join-Path $AshitaDir 'ashita-cli.exe') }
function Test-WindowerInstalled { Test-Path (Join-Path $WindowerDir 'Windower.exe') }

function Download-File($url, $dest, $label) {
    Write-Log "Downloading $label..."
    New-Item -ItemType Directory -Force -Path (Split-Path $dest) | Out-Null
    Invoke-WebRequest -Uri $url -OutFile $dest -Headers $HttpHeaders -UseBasicParsing
    if (-not (Test-Path $dest) -or ((Get-Item $dest).Length -lt 1024)) {
        throw "Download failed or file too small: $label"
    }
    Write-Log ("Saved {0} ({1:N1} MB)" -f $label, ((Get-Item $dest).Length / 1MB))
}

function Install-Xiloader {
    Write-Log 'Fetching latest xiloader release metadata...'
    $rel = Invoke-RestMethod -Uri $XiloaderApi -Headers $HttpHeaders
    $asset = $rel.assets | Where-Object { $_.name -eq 'xiloader.exe' } | Select-Object -First 1
    if (-not $asset) { throw 'xiloader.exe asset not found on the latest LSB release.' }
    Download-File $asset.browser_download_url $XiloaderPath ("xiloader {0}" -f $rel.tag_name)
}

function Install-Ashita {
    New-Item -ItemType Directory -Force -Path $AppDir | Out-Null
    $zip = Join-Path $env:TEMP 'relaunch-ashita.zip'
    $extract = Join-Path $env:TEMP 'relaunch-ashita-extract'
    Download-File $AshitaZipUrl $zip 'Ashita v4 (official GitHub snapshot)'
    if (Test-Path $extract) { Remove-Item $extract -Recurse -Force }
    Write-Log 'Extracting Ashita...'
    Expand-Archive -Path $zip -DestinationPath $extract -Force
    $inner = Get-ChildItem $extract -Directory | Select-Object -First 1
    if (-not $inner) { throw 'Ashita zip did not contain a folder.' }
    New-Item -ItemType Directory -Force -Path $AshitaDir | Out-Null
    Copy-Item -Path (Join-Path $inner.FullName '*') -Destination $AshitaDir -Recurse -Force
    Remove-Item $zip -Force -ErrorAction SilentlyContinue
    Remove-Item $extract -Recurse -Force -ErrorAction SilentlyContinue
    if (-not (Test-AshitaInstalled)) { throw 'ashita-cli.exe missing after extract.' }
    Write-Log 'Ashita installed. Source: github.com/AshitaXI/Ashita-v4beta (GPLv3).' 'LimeGreen'
}

function Install-Windower {
    New-Item -ItemType Directory -Force -Path $WindowerDir | Out-Null
    $dest = Join-Path $WindowerDir 'Windower.exe'
    Download-File $WindowerUrl $dest 'Windower 4 (official)'
    Write-Log 'Windower.exe saved. First Play will let it self-update from windower.net.' 'LimeGreen'
}

function Copy-DirContents($src, $dst) {
    if (-not (Test-Path $src)) { return $false }
    New-Item -ItemType Directory -Force -Path $dst | Out-Null
    Copy-Item -Path (Join-Path $src '*') -Destination $dst -Recurse -Force
    return $true
}

function Install-RelaunchAddons($client) {
    if ($client -eq 'Ashita') {
        $src = Join-Path $Root 'addons\ashita\relaunch'
        $dst = Join-Path $AshitaDir 'addons\relaunch'
        if (Copy-DirContents $src $dst) { Write-Log 'Installed Relaunch Ashita addon.' }
        return
    }

    $addonRoot = Join-Path $WindowerDir 'addons'
    New-Item -ItemType Directory -Force -Path $addonRoot | Out-Null

    $pairs = @(
        @{ Src = Join-Path $Root 'addons\ashita\relaunch'; Dst = $null } # skip, Windower has its own
        @{ Src = Join-Path $RepoRoot 'tools\windower\augment_browser'; Dst = Join-Path $addonRoot 'augment_browser' }
        @{ Src = Join-Path $RepoRoot 'tools\windower\augment_trade';   Dst = Join-Path $addonRoot 'augment_trade' }
        @{ Src = Join-Path $RepoRoot 'Custom DATs\Relaunch Custom DATs\Windower\addons\relaunch'; Dst = Join-Path $addonRoot 'relaunch' }
    )
    foreach ($p in $pairs) {
        if (-not $p.Dst) { continue }
        if (Copy-DirContents $p.Src $p.Dst) {
            Write-Log ("Copied addon {0}" -f (Split-Path $p.Dst -Leaf))
        }
    }
}

function Write-AshitaConfig {
    $res = Resolve-Resolution $State.resolution
    $mode = Window-ModeValue $State.windowMode
    $ffxi = $State.ffxiPath -replace '\\', '\\'
    $xilo = $XiloaderPath -replace '\\', '\\'

    $bootDir = Join-Path $AshitaDir 'config\boot'
    $scriptDir = Join-Path $AshitaDir 'scripts'
    New-Item -ItemType Directory -Force -Path $bootDir, $scriptDir | Out-Null

    $enabled = @()
    foreach ($a in $AddonCatalog) {
        if (-not $a.Ashita) { continue }
        $on = $true
        if ($State.addons.PSObject.Properties.Name -contains $a.Id) {
            $on = [bool]$State.addons.($a.Id)
        } elseif ($State.addons -is [hashtable]) {
            $on = [bool]$State.addons[$a.Id]
        }
        if ($on) { $enabled += $a.Id }
    }

    $loadLines = foreach ($id in $enabled) { "/addon load $id" }

    $script = @"
##########################################################################
# Relaunch -- Ashita startup script (managed by the Relaunch launcher)
# Do not edit Ashita's stock default.txt; this copy is ours.
##########################################################################
/load thirdparty
/load addons
/load screenshot

$($loadLines -join "`r`n")

/bind insert /ashita
/wait 3
"@
    Set-Content -Path (Join-Path $scriptDir 'relaunch.txt') -Value $script -Encoding ASCII

    $ini = @"
; Relaunch boot config. Managed by the Relaunch launcher -- safe to overwrite.
; Ashita: https://github.com/AshitaXI/Ashita-v4beta  (GPLv3)
[ashita.launcher]
autoclose = 1
name = Relaunch

[ashita.boot]
file        = $xilo
command     = --server $ServerHost
gamemodule  = ffximain.dll
script      = relaunch.txt
args        =

[ashita.fonts]
d3d8.disable_scaling = 0
d3d8.family = Arial
d3d8.height = 10

[ashita.input]
gamepad.allowbackground = 0
keyboard.blockbindsduringinput = 1
mouse.unhook = 1

[ashita.language]
playonline = 2
ashita = 2

[ashita.logging]
level = 5
crashdumps = 1

[ashita.polplugins]
sandbox = 1

[ffxi.registry]
0001 = $($res.W)
0002 = $($res.H)
0003 = 4096
0004 = 4096
0011 = 2
0017 = 0
0018 = 2
0019 = 1
0021 = 1
0034 = $mode
0037 = $($res.W)
0038 = $($res.H)
0042 = $ffxi
"@
    Set-Content -Path (Join-Path $bootDir 'relaunch.ini') -Value $ini -Encoding ASCII
    Write-Log ("Ashita profile written ({0}x{1}, {2})." -f $res.W, $res.H, $State.windowMode)
}

function Write-WindowerConfig {
    $res = Resolve-Resolution $State.resolution
    $windowed = if ($State.windowMode -eq 'Fullscreen') { 'false' } else { 'true' }
    $borderless = if ($State.windowMode -eq 'Borderless') { 'true' } else { 'false' }

    New-Item -ItemType Directory -Force -Path (Join-Path $WindowerDir 'scripts') | Out-Null

    $loads = New-Object System.Collections.Generic.List[string]
    $addonRoot = Join-Path $WindowerDir 'addons'
    foreach ($a in $AddonCatalog) {
        if (-not $a.Windower) { continue }
        $on = $true
        if ($State.addons -is [hashtable]) { $on = [bool]$State.addons[$a.Id] }
        elseif ($State.addons.PSObject.Properties.Name -contains $a.Id) { $on = [bool]$State.addons.($a.Id) }
        if (-not $on) { continue }
        $addonDir = Join-Path $addonRoot $a.Id
        if (-not (Test-Path $addonDir)) { continue }
        $loads.Add("lua load $($a.Id)")
    }

    $init = @"
-- Relaunch -- Windower init (managed by the Relaunch launcher)
$($loads -join "`r`n")
"@
    Set-Content -Path (Join-Path $WindowerDir 'scripts\init.txt') -Value $init -Encoding ASCII

    $xml = @"
<?xml version="1.0" encoding="utf-8"?>
<settings>
  <global>
    <consolekey>Insert</consolekey>
  </global>
  <profile name="Relaunch">
    <consolekey>Insert</consolekey>
    <width>$($res.W)</width>
    <height>$($res.H)</height>
    <windowed>$windowed</windowed>
    <borderless>$borderless</borderless>
    <mipmaplevel>6</mipmaplevel>
    <args>--server $ServerHost</args>
    <executable>$([System.Security.SecurityElement]::Escape($XiloaderPath))</executable>
  </profile>
</settings>
"@
    Set-Content -Path (Join-Path $WindowerDir 'settings.xml') -Value $xml -Encoding UTF8
    Write-Log ("Windower profile written ({0}x{1}, {2})." -f $res.W, $res.H, $State.windowMode)
}

function Apply-ClientConfig {
    if ($State.client -eq 'Ashita') {
        Install-RelaunchAddons 'Ashita'
        Write-AshitaConfig
    } else {
        Install-RelaunchAddons 'Windower'
        Write-WindowerConfig
    }
}

function Install-SelectedClient {
    if (-not $State.ffxiPath -or -not (Test-Path (Join-Path $State.ffxiPath 'FFXiMain.dll'))) {
        throw 'Set your FINAL FANTASY XI folder first (FFXiMain.dll must be there).'
    }
    if (-not (Test-Path $XiloaderPath)) { Install-Xiloader }
    else { Write-Log 'xiloader.exe already present.' }

    if ($State.client -eq 'Ashita') {
        Install-Ashita
    } else {
        Install-Windower
    }
    Apply-ClientConfig
}

function Launch-Game {
    if (-not $State.ffxiPath -or -not (Test-Path (Join-Path $State.ffxiPath 'FFXiMain.dll'))) {
        throw 'FINAL FANTASY XI folder is not set.'
    }
    if (-not (Test-Path $XiloaderPath)) { throw 'xiloader.exe is missing. Click Install first.' }

    Apply-ClientConfig

    if ($State.client -eq 'Ashita') {
        if (-not (Test-AshitaInstalled)) { throw 'Ashita is not installed. Click Install.' }
        $cli = Join-Path $AshitaDir 'ashita-cli.exe'
        Write-Log 'Launching Ashita -> xiloader -> Relaunch...'
        Start-Process -FilePath $cli -ArgumentList 'relaunch.ini' -WorkingDirectory $AshitaDir
        Write-Log 'xiloader will ask you to log in or create an account (option 2).' 'Khaki'
    } else {
        if (-not (Test-WindowerInstalled)) { throw 'Windower is not installed. Click Install.' }
        Write-Log 'Launching Windower. Pick the Relaunch profile, then Play.'
        Start-Process -FilePath (Join-Path $WindowerDir 'Windower.exe') -WorkingDirectory $WindowerDir
    }
}

function Install-CustomDats {
    $bat = Join-Path $RepoRoot 'Custom DATs\Relaunch Custom DATs\Install Relaunch DATs.bat'
    if (-not (Test-Path $bat)) {
        Write-Log 'DAT installer not found in this checkout. Skip or copy the Custom DATs pack.' 'Khaki'
        return
    }
    Write-Log 'Starting DAT installer (may ask for admin)...'
    Start-Process -FilePath $bat -WorkingDirectory (Split-Path $bat)
}

# ---------------------------------------------------------------------------
# GUI
# ---------------------------------------------------------------------------
$form = New-Object System.Windows.Forms.Form
$form.Text = 'Relaunch Launcher'
$form.Size = New-Object System.Drawing.Size(760, 700)
$form.MinimumSize = New-Object System.Drawing.Size(720, 640)
$form.StartPosition = 'CenterScreen'
$form.BackColor = [System.Drawing.Color]::FromArgb(28, 30, 36)
$form.ForeColor = [System.Drawing.Color]::WhiteSmoke
$form.Font = New-Object System.Drawing.Font('Segoe UI', 9)

function New-Label($text, $x, $y, $w = 200) {
    $l = New-Object System.Windows.Forms.Label
    $l.Text = $text
    $l.Location = New-Object System.Drawing.Point($x, $y)
    $l.Size = New-Object System.Drawing.Size($w, 20)
    $l.ForeColor = [System.Drawing.Color]::Gainsboro
    $form.Controls.Add($l)
    return $l
}

function Style-Btn($b, $bg) {
    $b.FlatStyle = 'Flat'
    $b.BackColor = $bg
    $b.ForeColor = [System.Drawing.Color]::White
    $b.FlatAppearance.BorderSize = 0
    $b.Cursor = [System.Windows.Forms.Cursors]::Hand
}

New-Label 'Relaunch  --  install Ashita or Windower, then Play' 16 14 700 | Out-Null
$sub = New-Label 'Fetches official builds. Does not ship FFXI or overwrite your current Windower folder.' 16 34 720
$sub.ForeColor = [System.Drawing.Color]::DarkGray

New-Label 'FINAL FANTASY XI folder' 16 70 300 | Out-Null
$ffxiBox = New-Object System.Windows.Forms.TextBox
$ffxiBox.Location = New-Object System.Drawing.Point(16, 92)
$ffxiBox.Size = New-Object System.Drawing.Size(500, 24)
$ffxiBox.Text = $State.ffxiPath
$form.Controls.Add($ffxiBox)

$browseBtn = New-Object System.Windows.Forms.Button
$browseBtn.Text = 'Browse'
$browseBtn.Location = New-Object System.Drawing.Point(526, 90)
$browseBtn.Size = New-Object System.Drawing.Size(90, 26)
Style-Btn $browseBtn ([System.Drawing.Color]::FromArgb(60, 64, 74))
$form.Controls.Add($browseBtn)

$detectBtn = New-Object System.Windows.Forms.Button
$detectBtn.Text = 'Detect'
$detectBtn.Location = New-Object System.Drawing.Point(624, 90)
$detectBtn.Size = New-Object System.Drawing.Size(90, 26)
Style-Btn $detectBtn ([System.Drawing.Color]::FromArgb(60, 64, 74))
$form.Controls.Add($detectBtn)

New-Label 'Client' 16 132 80 | Out-Null
$ashitaRadio = New-Object System.Windows.Forms.RadioButton
$ashitaRadio.Text = 'Ashita v4'
$ashitaRadio.Location = New-Object System.Drawing.Point(16, 154)
$ashitaRadio.Size = New-Object System.Drawing.Size(110, 22)
$ashitaRadio.ForeColor = [System.Drawing.Color]::WhiteSmoke
$ashitaRadio.Checked = ($State.client -ne 'Windower')
$form.Controls.Add($ashitaRadio)

$windowerRadio = New-Object System.Windows.Forms.RadioButton
$windowerRadio.Text = 'Windower 4'
$windowerRadio.Location = New-Object System.Drawing.Point(130, 154)
$windowerRadio.Size = New-Object System.Drawing.Size(120, 22)
$windowerRadio.ForeColor = [System.Drawing.Color]::WhiteSmoke
$windowerRadio.Checked = ($State.client -eq 'Windower')
$form.Controls.Add($windowerRadio)

$statusLabel = New-Label '' 260 156 300
$statusLabel.ForeColor = [System.Drawing.Color]::Khaki

$installBtn = New-Object System.Windows.Forms.Button
$installBtn.Text = 'Install / Update'
$installBtn.Location = New-Object System.Drawing.Point(16, 186)
$installBtn.Size = New-Object System.Drawing.Size(140, 30)
Style-Btn $installBtn ([System.Drawing.Color]::FromArgb(46, 108, 168))
$form.Controls.Add($installBtn)

$folderBtn = New-Object System.Windows.Forms.Button
$folderBtn.Text = 'Open folder'
$folderBtn.Location = New-Object System.Drawing.Point(164, 186)
$folderBtn.Size = New-Object System.Drawing.Size(110, 30)
Style-Btn $folderBtn ([System.Drawing.Color]::FromArgb(60, 64, 74))
$form.Controls.Add($folderBtn)

New-Label 'Resolution' 16 230 100 | Out-Null
$resCombo = New-Object System.Windows.Forms.ComboBox
$resCombo.DropDownStyle = 'DropDownList'
$resCombo.Location = New-Object System.Drawing.Point(16, 252)
$resCombo.Size = New-Object System.Drawing.Size(160, 24)
$Resolutions | ForEach-Object { [void]$resCombo.Items.Add($_) }
if ($resCombo.Items.Contains($State.resolution)) { $resCombo.SelectedItem = $State.resolution }
else { $resCombo.SelectedIndex = 2 }
$form.Controls.Add($resCombo)

New-Label 'Window' 190 230 80 | Out-Null
$modeCombo = New-Object System.Windows.Forms.ComboBox
$modeCombo.DropDownStyle = 'DropDownList'
$modeCombo.Location = New-Object System.Drawing.Point(190, 252)
$modeCombo.Size = New-Object System.Drawing.Size(130, 24)
@('Borderless', 'Windowed', 'Fullscreen') | ForEach-Object { [void]$modeCombo.Items.Add($_) }
if ($modeCombo.Items.Contains($State.windowMode)) { $modeCombo.SelectedItem = $State.windowMode }
else { $modeCombo.SelectedIndex = 0 }
$form.Controls.Add($modeCombo)

New-Label 'Addons / plugins (applied on Play)' 16 290 400 | Out-Null
$addonChecks = @{}
$ax = 16; $ay = 314
foreach ($a in $AddonCatalog) {
    $cb = New-Object System.Windows.Forms.CheckBox
    $cb.Text = $a.Label
    $cb.Location = New-Object System.Drawing.Point($ax, $ay)
    $cb.Size = New-Object System.Drawing.Size(230, 22)
    $cb.ForeColor = [System.Drawing.Color]::WhiteSmoke
    $on = $true
    if ($State.addons -is [hashtable] -and $State.addons.ContainsKey($a.Id)) { $on = [bool]$State.addons[$a.Id] }
    elseif ($State.addons.PSObject.Properties.Name -contains $a.Id) { $on = [bool]$State.addons.($a.Id) }
    $cb.Checked = $on
    $cb.Tag = $a
    $form.Controls.Add($cb)
    $addonChecks[$a.Id] = $cb
    $ax += 240
    if ($ax -gt 500) { $ax = 16; $ay += 24 }
}

$datCheck = New-Object System.Windows.Forms.CheckBox
$datCheck.Text = 'Also run Custom DAT installer (names / track suit; needs admin)'
$datCheck.Location = New-Object System.Drawing.Point(16, 390)
$datCheck.Size = New-Object System.Drawing.Size(520, 22)
$datCheck.ForeColor = [System.Drawing.Color]::Silver
$datCheck.Checked = [bool]$State.installDats
$form.Controls.Add($datCheck)

$playBtn = New-Object System.Windows.Forms.Button
$playBtn.Text = 'Play'
$playBtn.Location = New-Object System.Drawing.Point(16, 424)
$playBtn.Size = New-Object System.Drawing.Size(160, 40)
$playBtn.Font = New-Object System.Drawing.Font('Segoe UI', 11, [System.Drawing.FontStyle]::Bold)
Style-Btn $playBtn ([System.Drawing.Color]::FromArgb(46, 140, 80))
$form.Controls.Add($playBtn)

$redistBtn = New-Object System.Windows.Forms.Button
$redistBtn.Text = 'VC++ x86 redist'
$redistBtn.Location = New-Object System.Drawing.Point(188, 430)
$redistBtn.Size = New-Object System.Drawing.Size(140, 30)
Style-Btn $redistBtn ([System.Drawing.Color]::FromArgb(60, 64, 74))
$form.Controls.Add($redistBtn)

$script:LogBox = New-Object System.Windows.Forms.RichTextBox
$script:LogBox.Location = New-Object System.Drawing.Point(16, 478)
$script:LogBox.Size = New-Object System.Drawing.Size(700, 160)
$script:LogBox.ReadOnly = $true
$script:LogBox.BackColor = [System.Drawing.Color]::FromArgb(18, 20, 24)
$script:LogBox.ForeColor = [System.Drawing.Color]::Gainsboro
$script:LogBox.Font = New-Object System.Drawing.Font('Consolas', 8.5)
$script:LogBox.Anchor = 'Top,Bottom,Left,Right'
$form.Controls.Add($script:LogBox)

function Sync-StateFromUi {
    $State.ffxiPath   = $ffxiBox.Text.Trim().TrimEnd('\')
    $State.client     = if ($windowerRadio.Checked) { 'Windower' } else { 'Ashita' }
    $State.resolution = [string]$resCombo.SelectedItem
    $State.windowMode = [string]$modeCombo.SelectedItem
    $map = @{}
    foreach ($id in $addonChecks.Keys) { $map[$id] = [bool]$addonChecks[$id].Checked }
    $State.addons = $map
    $State.installDats = [bool]$datCheck.Checked
}

function Refresh-Status {
    $c = if ($windowerRadio.Checked) { 'Windower' } else { 'Ashita' }
    $ready = if ($c -eq 'Ashita') { Test-AshitaInstalled } else { Test-WindowerInstalled }
    $xilo = Test-Path $XiloaderPath
    if ($ready -and $xilo) {
        $statusLabel.Text = "$c ready in LocalAppData"
        $statusLabel.ForeColor = [System.Drawing.Color]::LightGreen
    } elseif ($ready) {
        $statusLabel.Text = "$c present, xiloader missing"
        $statusLabel.ForeColor = [System.Drawing.Color]::Khaki
    } else {
        $statusLabel.Text = "$c not installed yet"
        $statusLabel.ForeColor = [System.Drawing.Color]::Silver
    }
}

function Run-Safe([scriptblock]$work) {
    $form.UseWaitCursor = $true
    $installBtn.Enabled = $false
    $playBtn.Enabled = $false
    try {
        Sync-StateFromUi
        Save-Settings $State
        & $work
    } catch {
        Write-Log $_.Exception.Message 'Salmon'
        [System.Windows.Forms.MessageBox]::Show($_.Exception.Message, 'Relaunch', 'OK', 'Warning') | Out-Null
    } finally {
        $form.UseWaitCursor = $false
        $installBtn.Enabled = $true
        $playBtn.Enabled = $true
        Refresh-Status
    }
}

$browseBtn.Add_Click({
    $d = New-Object System.Windows.Forms.FolderBrowserDialog
    $d.Description = 'Select your FINAL FANTASY XI folder (the one with FFXiMain.dll)'
    if ($d.ShowDialog() -eq 'OK') { $ffxiBox.Text = $d.SelectedPath }
})

$detectBtn.Add_Click({
    $found = Get-FfxiInstalls
    if ($found.Count -eq 0) {
        Write-Log 'No FFXI install found in the usual places. Browse to FFXiMain.dll.' 'Khaki'
        return
    }
    $ffxiBox.Text = $found[0]
    if ($found.Count -gt 1) {
        Write-Log ("Found {0} installs; using the first. Browse if that is wrong." -f $found.Count) 'Khaki'
        $found | ForEach-Object { Write-Log "  $_" }
    } else {
        Write-Log "Detected FFXI: $($found[0])" 'LimeGreen'
    }
})

$installBtn.Add_Click({
    Run-Safe {
        Install-SelectedClient
        if ($State.installDats) { Install-CustomDats }
        Write-Log 'Install finished. Click Play.' 'LimeGreen'
    }
})

$folderBtn.Add_Click({
    New-Item -ItemType Directory -Force -Path $AppDir | Out-Null
    Start-Process explorer.exe $AppDir
})

$playBtn.Add_Click({
    Run-Safe { Launch-Game }
})

$redistBtn.Add_Click({
    Run-Safe {
        $dest = Join-Path $env:TEMP 'relaunch-vc_redist.x86.exe'
        Download-File $VcRedistUrl $dest 'Visual C++ 2015-2022 x86 redistributable'
        Start-Process -FilePath $dest -Wait
    }
})

$ashitaRadio.Add_CheckedChanged({ Refresh-Status })
$windowerRadio.Add_CheckedChanged({ Refresh-Status })

$form.Add_Shown({
    Write-Log "Install folder: $AppDir"
    Write-Log "Server: $ServerHost   (xiloader --server)"
    Write-Log 'Ashita = official GitHub snapshot. Windower = files.windower.net. xiloader = LSB GitHub.'
    if (-not $ffxiBox.Text) {
        $found = Get-FfxiInstalls
        if ($found.Count -ge 1) {
            $ffxiBox.Text = $found[0]
            Write-Log "Auto-detected FFXI: $($found[0])" 'LimeGreen'
        } else {
            Write-Log 'Could not find FFXI. Click Detect or Browse.' 'Khaki'
        }
    }
    Refresh-Status
})

$form.Add_FormClosing({
    Sync-StateFromUi
    Save-Settings $State
})

[void]$form.ShowDialog()
