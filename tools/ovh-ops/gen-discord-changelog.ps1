# =====================================================================
# gen-discord-changelog.ps1  --  turn recent relaunch commits into a
# player-friendly, Discord-ready changelog (copy/paste blocks < 2000 chars).
# Buckets into New / Balance / Fixes, prefixes each line with the game system,
# and hard-filters internal scopes + dev jargon. ASCII-only (PowerShell 5.1).
#
#   powershell -ExecutionPolicy Bypass -File gen-discord-changelog.ps1
#   ... -Since '3 days ago'        (default: '3 days ago'; also accepts a date)
#
# 2026-07-19: collaborator commits ("fix capacity respawns...", "Added the
# foundations...") were silently dropped because they don't use conventional
# type(scope): subjects. A leading-verb FALLBACK classifier now catches them;
# system labels for those lines are keyword-sniffed from the subject.
# CANONICAL COPY: tools/ovh-ops/gen-discord-changelog.ps1 in the Relaunch
# repo; the running copy is C:\relaunch-ops\gen-discord-changelog.ps1 (NOT in
# the OPS-SELFSYNC whitelist -- update both when editing).
# =====================================================================
param(
    [string]$Since    = '3 days ago',
    [string]$Out      = 'C:\relaunch-ops\discord-changelog.txt',
    [int]   $MaxChars = 1900
)
$ErrorActionPreference = 'Stop'
$root = 'C:\server'

# scope -> friendly system name shown to players.
$cat = @{
    'augment'='Augments'; 'augments'='Augments'
    'dungeons'='Augmentation Dungeons'; 'dungeon'='Augmentation Dungeons'
    'htbf'='High-Tier Battlefields'
    'trusts'='Trusts'; 'trust'='Trusts'
    'hub'='Home Hub'
    'affinity-nm'='Affinity NMs'; 'affinity'='Affinity NMs'
    'unity'='Unity Concord'
    'fellow'='Adventuring Fellow'
    'geas-fete'='Geas Fete'; 'geas_fete'='Geas Fete'
    'vendor'='Vendors'; 'shop'='Shop'
    'nyzul'='Nyzul Isle'; 'voidwatch'='Voidwatch'; 'voidspire'='Voidspire'
    'divergence'='Dynamis - Divergence'; 'dynamis'='Dynamis - Divergence'; 'dynamis-d'='Dynamis - Divergence'
    'prime'='Prime Weapons'; 'forge'='Weapon Forge'; 'aeonic'='Aeonic Weapons'; 'reforge'='Reforge'
    'jobpoints'='Job Points'; 'jp'='Job Points'; 'job'='Job Points'
    'gauntlet'='Gauntlet'; 'apex'='Apex Trials'
    'nm'='Notorious Monsters'; 'blu'='Blue Magic'; 'bst'='Beastmaster'
    'pup'='Puppetmaster'; 'smn'='Summoner'; 'drk'='Dark Knight'
    'gear'='Gear'; 'farm'='Capacity Farm'; 'reroll'='Augment Reroll'
    'hl'='Hunting League'; 'infamy'='Infamy Vendor'; 'cor'='Corsair'; 'moogle'='Augment Moogle'
    'commands'='Commands'; 'mystats'='!mystats'; 'gamemaster'='Wave Arena'; 'game_master'='Wave Arena'
    'hunters-guild'='Hunters Guild'; 'huntwarp'='Commands'; 'legendary-ring'='Legendary Ring'
}
# TYPE -> player bucket. Types not listed here fall through to the verb
# fallback below, then drop.
$bucketOf = @{ 'feat'='New & Improved'; 'add'='New & Improved';
               'balance'='Balance & Tuning'; 'tune'='Balance & Tuning'; 'perf'='Balance & Tuning';
               'fix'='Bug Fixes' }
$bucketOrder = @('New & Improved','Balance & Tuning','Bug Fixes')

# scopes that are internal/infra/website -- never shown to players
$excludeScopes = @('vps','ops','deploy','deploy-everything','changelog','ci','build','docs','doc',
                   'scorer','scoring','modules','crash','shutdown','auginfo','drop_finder','gear-finder',
                   'npcs','npc','moghouse','rebirth')
# lines whose text is clearly dev-speak -> dropped even if the type/scope pass
$jargonRe = 'int16|\bUAF\b|gitlink|submodule|docgen|SyntaxError|f-string|onEvent|::|\.lua|\.py|customMenu|localvar|nested|\bbyte\b|override SQL|groupId|mob_groups|\bSQL\b|onGameIn|charVar|exdata|stat block|closure|roster slot'

$subjects = & git -C $root log --since=$Since --pretty=format:'%s'
if (-not $subjects) { Write-Output "No commits since $Since."; return }

$groups = @{}
foreach ($b in $bucketOrder) { $groups[$b] = New-Object System.Collections.ArrayList }

foreach ($s in $subjects) {
    if (-not $s) { continue }
    if ($s -like 'Merge *') { continue }
    $type = ''; $scope = ''; $desc = $s
    if ($s -match '^(\w+)(?:\(([^)]*)\))?(!)?:\s*(.+)$') {
        $type = $matches[1].ToLower()
        if ($matches[2]) { $scope = $matches[2] }
        $desc = $matches[4]
    }

    $bucket = ''
    if ($bucketOf.ContainsKey($type)) {
        $bucket = $bucketOf[$type]
    } else {
        # FALLBACK: collaborators write plain subjects, not conventional
        # commits ("fix capacity respawns...", "Added high Enmity to August").
        # Classify by the leading verb so their work is not silently dropped.
        # Unlisted conventional types (docs/chore/ops/refactor) begin with
        # those words, never these verbs, so they still fall through and drop.
        if     ($s -match '^(?:hot)?fix(?:ed|es)?\b') { $bucket = 'Bug Fixes' }
        elseif ($s -match '^(?:add(?:ed|s)?\b|new\b|implement|creat(?:e|ed|es)\b|introduc)') { $bucket = 'New & Improved' }
        elseif ($s -match '^(?:tun(?:e|ed|es)\b|balanc|buff(?:ed|s)?\b|nerf(?:ed|s)?\b|adjust|rework|increas|reduc|lower(?:ed|s)?\b|rais(?:e|ed|es)\b)') { $bucket = 'Balance & Tuning' }
        if ($bucket -eq '') { continue }                       # drop everything else
        # Plain subjects are often multi-sentence with a trailing dev-note
        # ("... Added some SQL for mob_skill_lists"). Keep only the first
        # sentence so the tail can't jargon-kill an otherwise clean line.
        $desc = ($desc -split '\.\s+')[0]
    }

    $sc = $scope -replace '^relaunch/',''
    $sc = (($sc -split '/')[0]).ToLower()
    if ($excludeScopes -contains $sc) { continue }             # drop internal scopes
    if ($desc -match $jargonRe) { continue }                   # drop dev-jargon lines

    if ($sc -and $cat.ContainsKey($sc)) {
        $sys = $cat[$sc]
    } elseif ($sc) {
        $sys = (Get-Culture).TextInfo.ToTitleCase($sc.Replace('-',' '))
    } else {
        # No scope (typical for fallback lines): sniff a system keyword from
        # the subject itself. Longest key first so 'affinity-nm' beats 'nm'.
        $sys = ''
        foreach ($k in ($cat.Keys | Sort-Object { $_.Length } -Descending)) {
            if ($s -match ('\b' + [regex]::Escape($k) + '\b')) { $sys = $cat[$k]; break }
        }
    }

    $desc = $desc -replace '\s*\((?:[^()]*(?:[a-z][A-Z]|->|>>)[^()]*)\)\s*$',''    # strip trailing tech parenthetical
    $desc = ($desc -replace '\s*--\s*.*$','')                                        # drop "-- dev aside"
    $desc = $desc.Trim().TrimEnd('.')
    if ($desc.Length -lt 3) { continue }
    $desc = $desc.Substring(0,1).ToUpper() + $desc.Substring(1)

    if ($sys) { $line = "- **$sys** " + [char]0x2014 + " $desc" } else { $line = "- $desc" }
    if (-not $groups[$bucket].Contains($line)) { [void]$groups[$bucket].Add($line) }
}

# ---- build the post body (Discord markdown) ----
$today = Get-Date -Format 'MMMM d, yyyy'
$lines = New-Object System.Collections.ArrayList
[void]$lines.Add("# Relaunch " + [char]0x2014 + " Server Update")
[void]$lines.Add("_" + $today + "_")
[void]$lines.Add("")
$emptyAll = $true
foreach ($b in $bucketOrder) {
    if ($groups[$b].Count -eq 0) { continue }
    $emptyAll = $false
    [void]$lines.Add("## $b")
    foreach ($l in $groups[$b]) { [void]$lines.Add($l) }
    [void]$lines.Add("")
}
if ($emptyAll) { Write-Output "No player-facing changes since $Since."; return }

# ---- pack into <MaxChars Discord messages at line boundaries ----
$sep = "`r`n============  copy above as one Discord message  ============`r`n"
$chunks = New-Object System.Collections.ArrayList
$buf = ""
foreach ($ln in $lines) {
    if ($buf -eq "") { $candidate = $ln } else { $candidate = $buf + "`r`n" + $ln }
    if ($candidate.Length -gt $MaxChars -and $buf -ne "") {
        [void]$chunks.Add($buf); $buf = $ln
    } else {
        $buf = $candidate
    }
}
if ($buf -ne "") { [void]$chunks.Add($buf) }

Set-Content -Path $Out -Value ($chunks -join $sep) -Encoding UTF8
Write-Output ("wrote {0}  ({1} message block(s), since {2})" -f $Out, $chunks.Count, $Since)
