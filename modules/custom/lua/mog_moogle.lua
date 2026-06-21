-----------------------------------
-- mog_moogle.lua
-- Moogle NPC in GM Home: Delivery Box + Job Change
-----------------------------------
require('modules/module_utils')
require('scripts/zones/GM_Home/Zone')

local m = Module:new('mog_moogle')

local PAGE_SIZE = 5

local JOBS =
{
    { id = xi.job.WAR, label = 'WAR (Warrior)'      },
    { id = xi.job.MNK, label = 'MNK (Monk)'         },
    { id = xi.job.WHM, label = 'WHM (White Mage)'   },
    { id = xi.job.BLM, label = 'BLM (Black Mage)'   },
    { id = xi.job.RDM, label = 'RDM (Red Mage)'     },
    { id = xi.job.THF, label = 'THF (Thief)'        },
    { id = xi.job.PLD, label = 'PLD (Paladin)'      },
    { id = xi.job.DRK, label = 'DRK (Dark Knight)'  },
    { id = xi.job.BST, label = 'BST (Beastmaster)'  },
    { id = xi.job.BRD, label = 'BRD (Bard)'         },
    { id = xi.job.RNG, label = 'RNG (Ranger)'       },
    { id = xi.job.SAM, label = 'SAM (Samurai)'      },
    { id = xi.job.NIN, label = 'NIN (Ninja)'        },
    { id = xi.job.DRG, label = 'DRG (Dragoon)'      },
    { id = xi.job.SMN, label = 'SMN (Summoner)'     },
    { id = xi.job.BLU, label = 'BLU (Blue Mage)'    },
    { id = xi.job.COR, label = 'COR (Corsair)'      },
    { id = xi.job.PUP, label = 'PUP (Puppetmaster)' },
    { id = xi.job.DNC, label = 'DNC (Dancer)'       },
    { id = xi.job.SCH, label = 'SCH (Scholar)'      },
    { id = xi.job.GEO, label = 'GEO (Geomancer)'    },
    { id = xi.job.RUN, label = 'RUN (Rune Fencer)'  },
}

local NUM_PAGES = math.ceil(#JOBS / PAGE_SIZE)

local showMainMenu, showJobPage

showMainMenu = function(player)
    local opts =
    {
        { 'Delivery Box',    function(p) p:sendMenu(xi.menuType.MOOGLE) end },
        { 'Change Job...',   function(p) showJobPage(p, 1)              end },
        { 'Goodbye, kupo!',  function(p) end                               },
    }
    player:timer(30, function(p)
        p:customMenu({ title = 'Kupo! How can I help?', options = opts })
    end)
end

showJobPage = function(player, page)
    local opts  = {}
    local first = (page - 1) * PAGE_SIZE + 1
    local last  = math.min(first + PAGE_SIZE - 1, #JOBS)

    for i = first, last do
        local job = JOBS[i]
        table.insert(opts, {
            job.label,
            function(p)
                p:changeJob(job.id)
                p:printToPlayer(
                    string.format('Changed to %s, kupo!', job.label),
                    xi.msg.channel.SYSTEM_3)
                showMainMenu(p)
            end,
        })
    end

    if page < NUM_PAGES then
        table.insert(opts, { 'Next ->',  function(p) showJobPage(p, page + 1) end })
    end
    if page > 1 then
        table.insert(opts, { 'Back',     function(p) showJobPage(p, page - 1) end })
    end
    table.insert(opts,     { 'Cancel',   function(p) showMainMenu(p) end })

    player:timer(30, function(p)
        p:customMenu({ title = string.format('Change Job (%d/%d)', page, NUM_PAGES), options = opts })
    end)
end

m:addOverride('xi.zones.GM_Home.Zone.onInitialize', function(zone)
    super(zone)

    zone:insertDynamicEntity({
        objtype    = xi.objType.NPC,
        name       = 'Mog_Moogle',
        packetName = string.format('%sMog Moogle', xi.icon.STAR_LARGE),
        look       = 2308,
        x          = -1.500,
        y          =  0.000,
        z          =  -5.000,
        rotation   =  128,
        widescan   = 1,

        onTrigger = function(player, npc)
            showMainMenu(player)
        end,
    })
end)

return m
