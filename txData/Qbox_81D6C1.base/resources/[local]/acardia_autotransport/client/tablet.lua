local tabletOpen = false



local function closeTablet()

    if not tabletOpen then return end

    tabletOpen = false

    SetNuiFocus(false, false)

    SendNUIMessage({ action = 'close' })

end



local function openTablet()
    local data = lib.callback.await('acardia_autotransport:getTabletData', false)
    if not data then
        local job = exports.qbx_core:GetPlayerData().job
        local hasJob = JobAccess and JobAccess.HasJob and JobAccess.HasJob()
            or exports.qbx_core:HasGroup(Config.JobName)
        if hasJob then
            return lib.notify({ description = Locales.tablet_error, type = 'error' })
        end

        local label = job and job.label or 'inconnu'

        return lib.notify({

            description = ('Tu es "%s". Recrutement requis chez Auto Import Export.'):format(label),

            type = 'error',

        })

    end

    tabletOpen = true

    SetNuiFocus(true, true)

    SendNUIMessage({ action = 'open', payload = data })

end



RegisterNetEvent('acardia_autotransport:openTablet', openTablet)



lib.addKeybind({

    name = 'at_tablet',

    description = 'Tablette Auto Import Export',

    defaultKey = Config.TabletKey,

    onPressed = function()

        if tabletOpen then closeTablet() else openTablet() end

    end,

})



RegisterNUICallback('close', function(_, cb)

    closeTablet()

    cb(1)

end)



RegisterNUICallback('toggleDuty', function(_, cb)

    lib.callback.await('acardia_autotransport:toggleDuty', false)

    local payload = lib.callback.await('acardia_autotransport:getTabletData', false)

    cb({ ok = true, payload = payload })

end)



RegisterNUICallback('refresh', function(_, cb)

    cb({ ok = true, payload = lib.callback.await('acardia_autotransport:getTabletData', false, true) })

end)



RegisterNUICallback('acceptMission', function(data, cb)

    lib.callback.await('acardia_autotransport:acceptMission', false, data.payload)

    closeTablet()

    cb({ ok = true })

end)



RegisterNUICallback('cancelMission', function(_, cb)

    lib.callback.await('acardia_autotransport:cancelMission', false)

    cb({ ok = true, payload = lib.callback.await('acardia_autotransport:getTabletData', false) })

end)



RegisterNUICallback('reportTheft', function(_, cb)

    local coords = GetEntityCoords(cache.ped)

    lib.callback.await('acardia_autotransport:reportTheft', false, { x = coords.x, y = coords.y, z = coords.z })

    cb({ ok = true })

end)



RegisterNUICallback('hireClosest', function(_, cb)

    local closest = lib.getClosestPlayer(GetEntityCoords(cache.ped), 3.0, false)

    if not closest then

        lib.notify({ description = Locales.no_player, type = 'error' })

        return cb({ ok = false })

    end

    TriggerServerEvent('acardia_autotransport:hireClosest', GetPlayerServerId(closest))

    Wait(200)

    cb({ ok = true, payload = lib.callback.await('acardia_autotransport:getTabletData', false) })

end)



RegisterNUICallback('setGrade', function(data, cb)

    TriggerServerEvent('acardia_autotransport:setGrade', data.citizenid, data.grade)

    Wait(200)

    cb({ ok = true, payload = lib.callback.await('acardia_autotransport:getTabletData', false) })

end)



RegisterNUICallback('fire', function(data, cb)

    TriggerServerEvent('acardia_autotransport:fire', data.citizenid)

    Wait(200)

    cb({ ok = true, payload = lib.callback.await('acardia_autotransport:getTabletData', false) })

end)


