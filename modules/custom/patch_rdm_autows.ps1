# patch_rdm_autows.ps1
# Run as Administrator to add user_job_tick() to RDM.lua for Hunting League auto-WS fix.

$file = 'C:\Program Files (x86)\PlayOnline\SquareEnix\PlayOnlineViewer\Windower from NS\addons\GearSwap\data\RDM.lua'

if (-not (Test-Path $file)) {
    Write-Host "ERROR: RDM.lua not found at: $file" -ForegroundColor Red
    pause
    exit 1
}

$content = [System.IO.File]::ReadAllText($file, [System.Text.Encoding]::UTF8)

if ($content -match 'function user_job_tick') {
    Write-Host "user_job_tick() already present — nothing to do." -ForegroundColor Yellow
    pause
    exit 0
}

$insert = @'
-------------------------------------------------------------------------------------------------------------------
-- user_job_tick fires before job_tick in the tick chain.
-- Handles WS for dynamically spawned mobs (e.g. Hunting League NMs) whose
-- Windower spawn_type doesn't map to "MONSTER", which would otherwise block
-- check_ws() in Sel-Utility.lua from firing.
-- Falls through to check_ws() for normal mobs (type == "MONSTER") so that the
-- full Sel-Utility logic (emergency Sanguine Blade, MaintainAftermath, etc.) still runs.
-------------------------------------------------------------------------------------------------------------------
function user_job_tick()
	if not state.AutoWSMode.value then return false end
	if player.status ~= 'Engaged' then return false end
	if not player.target then return false end
	-- Normal mobs: let check_ws() in default_tick() handle it (full logic intact).
	if player.target.type == "MONSTER" then return false end
	-- Dynamic/custom entity: type check would silently block auto WS, so fire it here.
	local model_size = player.target.model_size or 1
	if model_size < 1 then model_size = 1 end
	if player.tp >= autowstp and autows ~= ''
	and not silent_check_amnesia()
	and player.target.distance <= (3.2 + model_size) then
		windower.chat.input('/ws "' .. autows .. '" <t>')
		tickdelay = os.clock() + 2.8
		return true
	end
	return false
end

'@

$newContent = $content -replace '(?m)^function job_tick\(\)', ($insert + 'function job_tick()')

# Back up the original first
Copy-Item $file ($file + '.bak') -Force
Write-Host "Backup saved: $file.bak" -ForegroundColor Cyan

[System.IO.File]::WriteAllText($file, $newContent, [System.Text.Encoding]::UTF8)
Write-Host "Done! user_job_tick() added to RDM.lua." -ForegroundColor Green
Write-Host "Reload GearSwap in-game with: //gs reload" -ForegroundColor Cyan
pause
