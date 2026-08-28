local config = require 'config.client'
local isScoreboardOpen, onDutyAdmins

local function shouldShowPlayerId(targetServerId)
    if config.idVisibility == 'all' then return true end
    if onDutyAdmins[cache.serverId] then return true end
    if config.idVisibility == 'admin_only' then return false end
    if config.idVisibility == 'admin_excluded' and onDutyAdmins[targetServerId] then return false end
    return true
end

local function drawPlayerNumbers()
    CreateThread(function()
        while isScoreboardOpen do
            local players = cache('nearbyPlayers', function()
                local p = lib.getNearbyPlayers(GetEntityCoords(cache.ped), config.visibilityDistance, true)

                for i = #p, 1, -1 do
                    p[i].serverId = GetPlayerServerId(p[i].id)

                    if not shouldShowPlayerId(p[i].serverId) then
                        p[i] = p[#p]
                        p[#p] = nil
                    end
                end

                return p
            end, 1000)

            for i = 1, #players do
                local player = players[i]
                local pedCoords = GetEntityCoords(player.ped)
                qbx.drawText3d({
                    text = '['..player.serverId..']',
                    coords = vec3(pedCoords.x, pedCoords.y, pedCoords.z + 1.0),
                })
            end
            Wait(0)
        end
    end)
end

-- Command

local function openScoreboard()
    local players, cops, admins = lib.callback.await('qbx_scoreboard:server:getScoreboardData')
    onDutyAdmins = admins

    SendNUIMessage({
        action = 'open',
        players = players,
        maxPlayers = config.maxPlayers,
        requiredCops = GlobalState.illegalActions,
        currentCops = cops
    })

    isScoreboardOpen = true
    drawPlayerNumbers()
end

local function closeScoreboard()
    SendNUIMessage({
        action = 'close',
    })

    isScoreboardOpen = false
end

if config.toggle then
    lib.addKeybind({
        name = 'scoreboard',
        description = 'Open Scoreboard',
        defaultKey = config.openKey,
        onPressed = function()
            if isScoreboardOpen then
                closeScoreboard()
            else
                openScoreboard()
            end
        end,
    })
else
    lib.addKeybind({
        name = 'scoreboard',
        description = 'Open Scoreboard',
        defaultKey = config.openKey,
        onPressed = openScoreboard,
        onReleased = closeScoreboard
    })
end

-- Threads

CreateThread(function()
    Wait(1000)
    local actions = {}
    for k, v in pairs(GlobalState.illegalActions) do
        actions[k] = v.label
    end
    SendNUIMessage({
        action = 'setup',
        items = actions
    })
end)
