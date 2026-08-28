local open = false
local spectating = false
local noclip = false
local noclipSpeed = 1.0

local function nui(action, data)
    SendNUIMessage({ action = action, data = data })
end

local function setFocus(state)
    SetNuiFocus(state, state)
    SetNuiFocusKeepInput(false)
end

local function closeTablet()
    open = false
    SetNuiFocus(false, false)
    SetNuiFocusKeepInput(false)
    nui('close')
end

local function openTablet()
    if open then
        closeTablet()
        return
    end

    local meta = lib.callback.await('liveafk_admin:canOpen', false)
    if not meta then return end

    -- Jobs disponibles cote client (export qbx)
    if not meta.jobs or #meta.jobs == 0 then
        local jobsMap = exports.qbx_core:GetJobs()
        local list = {}
        for name, data in pairs(jobsMap or {}) do
            local grades = {}
            for g, info in pairs(data.grades or {}) do
                grades[#grades + 1] = { level = tonumber(g) or 0, name = info.name or tostring(g) }
            end
            table.sort(grades, function(a, b) return a.level < b.level end)
            list[#list + 1] = { name = name, label = data.label or name, grades = grades }
        end
        table.sort(list, function(a, b) return a.label < b.label end)
        meta.jobs = list
    end

    local dashboard = lib.callback.await('liveafk_admin:getDashboard', false)
    local players = lib.callback.await('liveafk_admin:getPlayers', false)
    local reports = lib.callback.await('liveafk_admin:getReports', false)

    open = true
    setFocus(true)
    nui('open', {
        meta = meta,
        dashboard = dashboard,
        players = players,
        reports = reports,
    })
end

lib.addKeybind({
    name = 'liveafk_admin_tablet',
    description = 'Tablette Admin Acardia RP V2',
    defaultKey = Config.OpenKey,
    onPressed = function()
        openTablet()
    end,
})

-- addCommand ox_lib = serveur only → RegisterCommand cote client
RegisterCommand(Config.Command, function()
    openTablet()
end, false)

TriggerEvent('chat:addSuggestion', '/' .. Config.Command, 'Ouvrir la tablette admin Acardia RP V2')

RegisterNUICallback('close', function(_, cb)
    cb(1)
    closeTablet()
end)

RegisterNUICallback('refresh', function(_, cb)
    local dashboard = lib.callback.await('liveafk_admin:getDashboard', false)
    local players = lib.callback.await('liveafk_admin:getPlayers', false)
    local reports = lib.callback.await('liveafk_admin:getReports', false)
    cb({ dashboard = dashboard, players = players, reports = reports })
end)

RegisterNUICallback('action', function(data, cb)
    local ok, extra = lib.callback.await('liveafk_admin:action', false, data.action, data.payload or {})
    cb({ ok = ok and true or false, extra = extra })
end)

RegisterNUICallback('toggleNoclip', function(_, cb)
    local meta = lib.callback.await('liveafk_admin:canOpen', false)
    if not meta or not meta.perms.noclip then
        cb({ ok = false })
        return
    end
    noclip = not noclip
    cb({ ok = true, enabled = noclip })
end)

RegisterNUICallback('copyCoords', function(_, cb)
    local ped = cache.ped
    local c = GetEntityCoords(ped)
    local h = GetEntityHeading(ped)
    cb({
        ok = true,
        text = ('vec4(%.2f, %.2f, %.2f, %.2f)'):format(c.x, c.y, c.z, h),
    })
end)

RegisterNUICallback('stopSpectate', function(_, cb)
    if spectating then
        NetworkSetInSpectatorMode(false, cache.ped)
        spectating = false
    end
    cb(1)
end)

RegisterNetEvent('liveafk_admin:teleport', function(x, y, z)
    local ped = cache.ped
    SetEntityCoords(ped, x + 0.0, y + 0.0, z + 0.0, false, false, false, false)
end)

RegisterNetEvent('liveafk_admin:heal', function()
    local ped = cache.ped
    SetEntityHealth(ped, GetEntityMaxHealth(ped))
    SetPedArmour(ped, 100)
    ClearPedBloodDamage(ped)
end)

RegisterNetEvent('liveafk_admin:revive', function()
    local ped = cache.ped
    local coords = GetEntityCoords(ped)
    NetworkResurrectLocalPlayer(coords.x, coords.y, coords.z, GetEntityHeading(ped), true, false)
    SetEntityInvincible(ped, false)
    ClearPedBloodDamage(ped)
    SetEntityHealth(ped, GetEntityMaxHealth(ped))
    SetPedArmour(ped, 100)
end)

RegisterNetEvent('liveafk_admin:spectate', function(targetId, coords)
    closeTablet()
    local targetPed = GetPlayerPed(GetPlayerFromServerId(targetId))
    if not targetPed or targetPed == 0 then
        SetEntityCoords(cache.ped, coords.x, coords.y, coords.z + 1.0, false, false, false, false)
        Wait(400)
        targetPed = GetPlayerPed(GetPlayerFromServerId(targetId))
    end
    if targetPed and targetPed ~= 0 then
        spectating = true
        NetworkSetInSpectatorMode(true, targetPed)
        lib.notify({ description = 'Spectate ON — F10 pour ouvrir la tablette, bouton Stop Spectate pour quitter.', type = 'inform' })
    end
end)

RegisterNetEvent('liveafk_admin:setWeather', function(weather)
    SetWeatherTypeOvertimePersist(weather, 15.0)
    SetWeatherTypeNowPersist(weather)
    SetWeatherTypeNow(weather)
end)

RegisterNetEvent('liveafk_admin:setTime', function(hour, minute)
    NetworkOverrideClockTime(hour, minute, 0)
end)

RegisterNetEvent('liveafk_admin:spawnVehicle', function(model)
    local hash = joaat(model)
    if not IsModelInCdimage(hash) then
        lib.notify({ description = 'Modele invalide.', type = 'error' })
        return
    end
    lib.requestModel(hash, 5000)
    local ped = cache.ped
    local coords = GetEntityCoords(ped)
    local heading = GetEntityHeading(ped)
    local veh = CreateVehicle(hash, coords.x, coords.y, coords.z, heading, true, false)
    SetVehicleOnGroundProperly(veh)
    SetPedIntoVehicle(ped, veh, -1)
    SetVehicleNumberPlateText(veh, 'LIVEAFK')
    SetModelAsNoLongerNeeded(hash)
    lib.notify({ description = ('Vehicule spawn: %s'):format(model), type = 'success' })
end)

RegisterNetEvent('liveafk_admin:fixVehicle', function()
    local veh = cache.vehicle
    if not veh then
        lib.notify({ description = 'Pas dans un vehicule.', type = 'error' })
        return
    end
    SetVehicleFixed(veh)
    SetVehicleDirtLevel(veh, 0.0)
    SetVehicleEngineHealth(veh, 1000.0)
    SetVehicleBodyHealth(veh, 1000.0)
    lib.notify({ description = 'Vehicule repare.', type = 'success' })
end)

RegisterNetEvent('liveafk_admin:deleteVehicle', function()
    local veh = cache.vehicle
    if not veh then
        veh = lib.getClosestVehicle(GetEntityCoords(cache.ped), 5.0, false)
    end
    if not veh or veh == 0 then
        lib.notify({ description = 'Aucun vehicule proche.', type = 'error' })
        return
    end
    SetEntityAsMissionEntity(veh, true, true)
    DeleteVehicle(veh)
    lib.notify({ description = 'Vehicule supprime.', type = 'success' })
end)

RegisterNetEvent('liveafk_admin:flipVehicle', function()
    local veh = cache.vehicle or lib.getClosestVehicle(GetEntityCoords(cache.ped), 5.0, false)
    if not veh or veh == 0 then
        lib.notify({ description = 'Aucun vehicule.', type = 'error' })
        return
    end
    local c = GetEntityCoords(veh)
    SetEntityCoords(veh, c.x, c.y, c.z + 0.5, false, false, false, false)
    SetEntityRotation(veh, 0.0, 0.0, GetEntityHeading(veh), 2, true)
    lib.notify({ description = 'Vehicule retourne.', type = 'success' })
end)

RegisterNetEvent('liveafk_admin:reportPing', function(report)
    if open then
        nui('reportPing', report)
    end
end)

-- Noclip loop
CreateThread(function()
    while true do
        if noclip then
            local ped = cache.ped
            local speed = noclipSpeed
            if IsControlPressed(0, 21) then speed = speed * 3.0 end -- Shift
            if IsControlPressed(0, 36) then speed = speed * 0.35 end -- Ctrl

            SetEntityCollision(ped, false, false)
            FreezeEntityPosition(ped, true)
            SetEntityInvincible(ped, true)
            SetEntityVisible(ped, false, false)

            local coords = GetEntityCoords(ped)
            local camRot = GetGameplayCamRot(2)
            local heading = math.rad(camRot.z)
            local pitch = math.rad(camRot.x)
            local dx = -math.sin(heading) * math.cos(pitch)
            local dy = math.cos(heading) * math.cos(pitch)
            local dz = math.sin(pitch)

            if IsControlPressed(0, 32) then -- W
                coords = coords + vector3(dx, dy, dz) * speed
            end
            if IsControlPressed(0, 33) then -- S
                coords = coords - vector3(dx, dy, dz) * speed
            end
            if IsControlPressed(0, 34) then -- A
                coords = coords + vector3(-dy, dx, 0.0) * speed
            end
            if IsControlPressed(0, 35) then -- D
                coords = coords + vector3(dy, -dx, 0.0) * speed
            end
            if IsControlPressed(0, 22) then -- Space
                coords = coords + vector3(0.0, 0.0, speed)
            end

            SetEntityCoordsNoOffset(ped, coords.x, coords.y, coords.z, true, true, true)
            Wait(0)
        else
            local ped = cache.ped
            if DoesEntityExist(ped) then
                SetEntityCollision(ped, true, true)
                FreezeEntityPosition(ped, false)
                SetEntityInvincible(ped, false)
                SetEntityVisible(ped, true, false)
            end
            Wait(400)
        end
    end
end)

AddEventHandler('onResourceStop', function(res)
    if res ~= GetCurrentResourceName() then return end
    if spectating then NetworkSetInSpectatorMode(false, cache.ped) end
    if noclip then
        local ped = cache.ped
        SetEntityCollision(ped, true, true)
        FreezeEntityPosition(ped, false)
        SetEntityInvincible(ped, false)
        SetEntityVisible(ped, true, false)
    end
    if open then closeTablet() end
end)
