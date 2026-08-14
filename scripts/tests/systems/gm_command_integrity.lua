local function permission(path)
    local command = require(path)
    assert(command and command.cmdprops, path .. ' did not return a command object')
    return command.cmdprops.permission
end

describe('GM command integrity', function()
    it('keeps the canonical GM1 support surface at permission one', function()
        local supportCommands =
        {
            'modules/custom/commands/gmhelp',
            'modules/custom/commands/gminspect',
            'modules/custom/commands/gmrelease',
            'modules/custom/commands/gmkick',
            'modules/custom/commands/gmjail',
            'modules/custom/commands/gmpardon',
            'modules/custom/commands/gmitem',
            'modules/custom/commands/gmkeyitem',
            'modules/custom/commands/gmrepair',
            'modules/custom/commands/gmcontent',
            'modules/custom/commands/announce',
            'modules/custom/commands/seek',
            'scripts/commands/rescue',
            'scripts/commands/bring',
            'scripts/commands/send',
            'scripts/commands/goto',
        }

        for _, path in ipairs(supportCommands) do
            assert(permission(path) == 1, path .. ' must remain GM1')
        end
    end)

    it('keeps economy progression and direct mutation commands at GM5', function()
        local ownerCommands =
        {
            'modules/custom/commands/gmadmin',
            'modules/custom/commands/givemarks',
            'modules/custom/commands/giveinfamy',
            'modules/custom/commands/givereforge',
            'modules/custom/commands/givetrust',
            'modules/custom/commands/givegfkit',
            'modules/custom/commands/primevoucher',
            'modules/custom/commands/primetrial',
            'modules/custom/commands/setbonus',
            'modules/custom/commands/worldboss',
            'modules/custom/commands/invasion',
            'modules/custom/commands/shutdown',
            'scripts/commands/giveitem',
            'scripts/commands/addkeyitem',
            'scripts/commands/delkeyitem',
            'scripts/commands/quest',
            'scripts/commands/mission',
            'scripts/commands/jail',
            'scripts/commands/pardon',
            'scripts/commands/logoff',
            'scripts/commands/givegil',
            'scripts/commands/setgil',
            'scripts/commands/setplayervar',
            'scripts/commands/setplayerlevel',
            'scripts/commands/godmode',
            'scripts/commands/spawnmob',
        }

        for _, path in ipairs(ownerCommands) do
            assert(permission(path) == 5, path .. ' must remain GM5')
        end
    end)

    it('preserves player commands that contain separately gated owner subcommands', function()
        local mixedCommands =
        {
            'modules/custom/commands/apex',
            'modules/custom/commands/empower',
            'modules/custom/commands/mastery',
            'modules/custom/commands/tower',
            'modules/custom/commands/voidwatch',
            'scripts/commands/gauntlet',
        }

        for _, path in ipairs(mixedCommands) do
            assert(permission(path) == 0, path .. ' must remain player-accessible')
        end
    end)

    it('does not load the removed hardcoded privilege backdoor', function()
        package.loaded['modules/custom/commands/gm5all'] = nil
        package.loaded['modules/custom/commands/wsdfix'] = nil
        assert(not pcall(require, 'modules/custom/commands/gm5all'))
        assert(not pcall(require, 'modules/custom/commands/wsdfix'))
    end)
end)
