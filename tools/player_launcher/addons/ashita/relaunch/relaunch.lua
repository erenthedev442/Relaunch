--[[
* Relaunch -- Ashita v4 welcome addon
* Shipped by the Relaunch launcher. Safe to load on a stock Ashita install.
--]]

addon.name    = 'relaunch'
addon.author  = 'Relaunch'
addon.version = '1.0.0'
addon.desc    = 'Relaunch welcome and command hints.'
addon.commands = { '/relaunch' }

require('common')
local chat = require('chat')

local function say(msg)
    print(chat.header('relaunch'):append(chat.message(msg)))
end

ashita.events.register('load', 'relaunch_load', function()
    say('Welcome to Relaunch. Try !hunt  !apex  !tower  !buff  !shop')
    say('Toggle this hint anytime with /relaunch')
end)

ashita.events.register('command', 'relaunch_cmd', function(e)
    local args = e.command:args()
    if (#args == 0 or args[1] ~= '/relaunch') then
        return
    end
    e.blocked = true
    say('Relaunch tips: !hunt (Hunting League)  !apex  !tower  !buff  !shop')
    say('Resolution and addons are controlled from the Relaunch launcher.')
end)
