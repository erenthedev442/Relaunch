# Read-only troll watch check. Run on the VPS (C:\server).
# Does not ban, kick, or firewall anyone.
#
#   powershell -NoProfile -File C:\server\tools\troll-watch\check_trolls.ps1
#   powershell -NoProfile -File C:\server\tools\troll-watch\check_trolls.ps1 -Hours 168
#
param(
    [int]$Hours = 48,
    [string]$Mysql = 'C:\Program Files\MariaDB 10.6\bin\mysql.exe',
    [string]$Database = 'xi_relaunch',
    [string]$WatchlistPath = ''
)

$ErrorActionPreference = 'Stop'
if (-not $WatchlistPath) {
    $WatchlistPath = Join-Path $PSScriptRoot 'watchlist.json'
}
if (-not (Test-Path $WatchlistPath)) {
    throw "Missing watchlist: $WatchlistPath"
}
if (-not (Test-Path $Mysql)) {
    throw "mysql.exe not found: $Mysql"
}

$w = Get-Content -Raw -Path $WatchlistPath | ConvertFrom-Json

function Sql-Quote([string]$s) {
    return "'" + ($s -replace "'", "''") + "'"
}

function Sql-In([string[]]$items) {
    $q = @($items | Where-Object { $_ } | ForEach-Object { Sql-Quote $_ } | Select-Object -Unique)
    if ($q.Count -eq 0) { return "('')" }
    return ($q -join ',')
}

$knownLogins = New-Object System.Collections.Generic.List[string]
$knownChars  = New-Object System.Collections.Generic.List[string]
$knownIds    = New-Object System.Collections.Generic.List[int]
$exactIps    = New-Object System.Collections.Generic.List[string]
$prefixes    = New-Object System.Collections.Generic.List[object]
$watchLogins = New-Object System.Collections.Generic.List[string]
$watchChars  = New-Object System.Collections.Generic.List[string]

foreach ($c in $w.clusters) {
    foreach ($a in $c.accounts) {
        if ($a.login) { [void]$knownLogins.Add([string]$a.login) }
        if ($a.id)    { [void]$knownIds.Add([int]$a.id) }
        if ($c.status -eq 'watch' -and $a.login) { [void]$watchLogins.Add([string]$a.login) }
    }
    foreach ($name in $c.characters) {
        if ($name) { [void]$knownChars.Add([string]$name) }
        if ($c.status -eq 'watch' -and $name) { [void]$watchChars.Add([string]$name) }
    }
    foreach ($ip in $c.ips_exact) {
        if ($ip -and $ip -ne '185.124.0.99') { [void]$exactIps.Add([string]$ip) }
    }
    foreach ($p in $c.ip_prefixes) { [void]$prefixes.Add($p) }
}

$neverIds    = @($w.never_touch.account_ids)
$neverLogins = @($w.never_touch.logins)
$neverChars  = @($w.never_touch.char_names)
$neverIps    = @($w.never_touch.ips_never_firewall)

$prefixLike = ($prefixes | ForEach-Object { "ip.client_ip LIKE " + (Sql-Quote ($_.prefix + '%')) }) -join "`n   OR "

$sql = @"
SELECT '=== 1. known-bad / watch accounts (current lock state) ===' AS section;
SELECT a.id, a.login, a.status,
       CASE a.status WHEN 1 THEN 'CAN_LOGIN' WHEN 2 THEN 'BANNED' ELSE 'LOCKED' END AS lock_state,
       a.timecreate,
       GROUP_CONCAT(DISTINCT c.charname ORDER BY c.charname SEPARATOR ', ') AS chars
FROM accounts a
LEFT JOIN chars c ON c.accid = a.id OR c.original_accid = a.id
WHERE a.id IN ($(if ($knownIds.Count) { ($knownIds | Select-Object -Unique) -join ',' } else { '0' }))
   OR LOWER(a.login) IN ($(Sql-In ($knownLogins | ForEach-Object { $_.ToLower() })))
GROUP BY a.id
ORDER BY a.status, a.id;

SELECT '=== 2. never-touch (must stay unlocked / unfirewalled) ===' AS section;
SELECT a.id, a.login, a.status,
       CASE a.status WHEN 1 THEN 'OK_UNLOCKED' ELSE 'PROBLEM_LOCKED' END AS check_state
FROM accounts a
WHERE a.id IN ($(if ($neverIds.Count) { $neverIds -join ',' } else { '0' }))
   OR LOWER(a.login) IN ($(Sql-In ($neverLogins | ForEach-Object { $_.ToLower() })));

SELECT '=== 3. exact known IPs — any account still using them ===' AS section;
SELECT ip.client_ip, a.id AS accid, a.login, a.status,
       IF(c.accid=0,'DELETED','ACTIVE') AS char_state,
       c.charid, c.charname, c.playtime,
       MAX(ip.login_time) AS last_seen,
       IF(s.charid IS NULL,'OFFLINE','ONLINE') AS state
FROM account_ip_record ip
JOIN accounts a ON a.id = ip.accid
LEFT JOIN chars c ON c.accid = a.id OR c.original_accid = a.id
LEFT JOIN accounts_sessions s ON s.charid = c.charid
WHERE ip.client_ip IN ($(Sql-In $exactIps))
  AND ip.client_ip NOT IN ($(Sql-In $neverIps))
GROUP BY ip.client_ip, a.id, c.charid
ORDER BY a.status, ip.client_ip, a.id;

SELECT '=== 4. prefix neighbors in last $Hours hours (not auto-ban) ===' AS section;
SELECT ip.client_ip, a.id AS accid, a.login, a.status,
       c.charid, c.charname, c.playtime, c.timecreated,
       MAX(ip.login_time) AS last_seen,
       IF(s.charid IS NULL,'OFFLINE','ONLINE') AS state
FROM account_ip_record ip
JOIN accounts a ON a.id = ip.accid
LEFT JOIN chars c ON c.accid = a.id OR c.original_accid = a.id
LEFT JOIN accounts_sessions s ON s.charid = c.charid
WHERE ($prefixLike)
  AND ip.login_time >= NOW() - INTERVAL $Hours HOUR
  AND a.id NOT IN ($(if ($neverIds.Count) { $neverIds -join ',' } else { '0' }))
GROUP BY ip.client_ip, a.id, c.charid
ORDER BY ip.login_time DESC, a.id;

SELECT '=== 5. new chars last $Hours hours matching name/login patterns ===' AS section;
SELECT
  c.charid, c.charname,
  IF(c.accid=0,'DELETED','ACTIVE') AS char_state,
  IF(c.accid=0,c.original_accid,c.accid) AS accid,
  a.login, a.status AS acc_status,
  c.timecreated, c.playtime,
  IF(s.charid IS NULL,'OFFLINE','ONLINE') AS state,
  (SELECT ip.client_ip FROM account_ip_record ip
    WHERE ip.accid = IF(c.accid=0,c.original_accid,c.accid)
    ORDER BY ip.login_time DESC LIMIT 1) AS last_ip,
  CONCAT_WS(',',
    IF(a.login REGEXP '^[0-9]{1,3}\\.[0-9]{1,3}\\.[0-9]{1,3}\\.[0-9]{1,3}$','ip_as_login',NULL),
    IF(a.login REGEXP '^[0-9]{1,6}$','short_numeric_login',NULL),
    IF(LOWER(c.charname) REGEXP '$($w.name_regex)','name_hit',NULL),
    IF(LOWER(a.login) REGEXP '$($w.login_regex)','login_hit',NULL),
    IF(LOWER(c.charname) IN ($(Sql-In ($w.exact_login_or_char | ForEach-Object { $_.ToLower() })))
       OR LOWER(a.login) IN ($(Sql-In ($w.exact_login_or_char | ForEach-Object { $_.ToLower() }))),
       'exact_hit',NULL)
  ) AS flags
FROM chars c
LEFT JOIN accounts a ON a.id = IF(c.accid=0,c.original_accid,c.accid)
LEFT JOIN accounts_sessions s ON s.charid = c.charid
WHERE c.timecreated >= NOW() - INTERVAL $Hours HOUR
  AND IF(c.accid=0,c.original_accid,c.accid) NOT IN ($(if ($neverIds.Count) { $neverIds -join ',' } else { '0' }))
  AND LOWER(IFNULL(a.login,'')) NOT IN ($(Sql-In ($neverLogins | ForEach-Object { $_.ToLower() })))
  AND LOWER(c.charname) NOT IN ($(Sql-In ($neverChars | ForEach-Object { $_.ToLower() })))
HAVING flags IS NOT NULL AND flags <> ''
ORDER BY c.timecreated DESC;

SELECT '=== 6. new chars last $Hours hours sharing an IP with a locked or known-bad account ===' AS section;
SELECT
  newc.charname AS new_char,
  newa.login AS new_login,
  newa.status AS new_status,
  ip.client_ip,
  oldc.charname AS shared_with_char,
  olda.login AS shared_with_login,
  olda.status AS shared_acc_status
FROM chars newc
JOIN account_ip_record ip
  ON ip.accid = IF(newc.accid=0,newc.original_accid,newc.accid)
JOIN account_ip_record ip2
  ON ip2.client_ip = ip.client_ip AND ip2.accid <> ip.accid
JOIN accounts olda ON olda.id = ip2.accid
LEFT JOIN chars oldc ON oldc.accid = olda.id OR oldc.original_accid = olda.id
LEFT JOIN accounts newa ON newa.id = IF(newc.accid=0,newc.original_accid,newc.accid)
WHERE newc.timecreated >= NOW() - INTERVAL $Hours HOUR
  AND ip.client_ip NOT IN ($(Sql-In $neverIps))
  AND IF(newc.accid=0,newc.original_accid,newc.accid) NOT IN ($(if ($neverIds.Count) { $neverIds -join ',' } else { '0' }))
  AND (
        olda.status <> 1
     OR LOWER(olda.login) IN ($(Sql-In ($knownLogins | ForEach-Object { $_.ToLower() })))
     OR LOWER(IFNULL(oldc.charname,'')) IN ($(Sql-In ($knownChars | ForEach-Object { $_.ToLower() })))
  )
GROUP BY newc.charid, ip.client_ip, olda.id, oldc.charid
ORDER BY ip.client_ip, newc.charname;

SELECT '=== 7. new accounts last $Hours hours with no character (empty remake / IP-as-login) ===' AS section;
SELECT a.id, a.login, a.status, a.timecreate,
       IF(a.login REGEXP '^[0-9]{1,3}\\.[0-9]{1,3}\\.[0-9]{1,3}\\.[0-9]{1,3}$','ip_as_login',
          IF(a.login REGEXP '^[0-9]{1,10}$','numeric_login','')) AS flags
FROM accounts a
LEFT JOIN chars c ON c.accid = a.id OR c.original_accid = a.id
WHERE a.timecreate >= NOW() - INTERVAL $Hours HOUR
  AND c.charid IS NULL
  AND a.id NOT IN ($(if ($neverIds.Count) { $neverIds -join ',' } else { '0' }))
ORDER BY a.timecreate DESC;
"@

Write-Host "Troll watch check — last $Hours hours. Read-only."
Write-Host "Watchlist: $WatchlistPath  (updated $($w.updated))"
Write-Host "Never firewall: $($neverIps -join ', ')"
Write-Host "Never lock account ids: $($neverIds -join ', ')"
Write-Host ""

& $Mysql -u root --password=richard --table $Database -e $sql
if ($LASTEXITCODE -ne 0) { throw "mysql failed: $LASTEXITCODE" }

Write-Host ""
Write-Host "Read-only. Hits in tables 4-7 are suspects to review, not auto-bans."
Write-Host "Add new IPs/names to tools/troll-watch/watchlist.json after you confirm them."
