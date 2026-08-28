local tabletOpen = false

local function getJob()
    local pdata = exports.qbx_core:GetPlayerData()
    return pdata and pdata.job or nil
end

local function isEmployee()
    local job = getJob()
    return job and job.name == Config.JobName
end

local function closeTablet()
    if not tabletOpen then return end
    tabletOpen = false
    SetNuiFocus(false, false)
    SendNUIMessage({ action = 'close' })
end

local function openTablet()
    if not isEmployee() then return end

    local data = lib.callback.await('acardia_importexport:getTabletData', false)
    if not data then return end

    tabletOpen = true
    SetNuiFocus(true, true)
    SendNUIMessage({
        action = 'open',
        payload = data,
    })
end

lib.addKeybind({
    name = 'ae_tablet',
    description = 'Tablette Acardia Export',
    defaultKey = Config.TabletKey,
    onPressed = function()
        if tabletOpen then
            closeTablet()
        else
            openTablet()
        end
    end,
})

RegisterNUICallback('close', function(_, cb)
    closeTablet()
    cb(1)
end)

RegisterNUICallback('toggleDuty', function(_, cb)
    local onDuty = lib.callback.await('acardia_importexport:toggleDuty', false)
    local payload = lib.callback.await('acardia_importexport:getTabletData', false)
    cb({ ok = true, onDuty = onDuty, payload = payload })
end)

RegisterNUICallback('hireClosest', function(_, cb)
    local closest = lib.getClosestPlayer(GetEntityCoords(cache.ped), 3.0, false)
    if not closest then
        lib.notify({ description = Locales.no_player, type = 'error' })
        cb({ ok = false })
        return
    end
    local serverId = GetPlayerServerId(closest)
    TriggerServerEvent('acardia_importexport:hireClosest', serverId)
    Wait(200)
    local data = lib.callback.await('acardia_importexport:getTabletData', false)
    cb({ ok = true, payload = data })
end)

RegisterNUICallback('setGrade', function(data, cb)
    TriggerServerEvent('acardia_importexport:setGrade', data.citizenid, data.grade)
    Wait(200)
    local payload = lib.callback.await('acardia_importexport:getTabletData', false)
    cb({ ok = true, payload = payload })
end)

RegisterNUICallback('fire', function(data, cb)
    TriggerServerEvent('acardia_importexport:fire', data.citizenid)
    Wait(200)
    local payload = lib.callback.await('acardia_importexport:getTabletData', false)
    cb({ ok = true, payload = payload })
end)

RegisterNUICallback('refresh', function(_, cb)
    local payload = lib.callback.await('acardia_importexport:getTabletData', false)
    cb({ ok = true, payload = payload })
end)
