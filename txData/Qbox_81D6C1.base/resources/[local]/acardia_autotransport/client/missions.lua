local mission = nil

local blips = {}

local cargoNetId = nil

local cargoEntity = nil

local textUiOpen = false

local completing = false

local truckRouteReady = false

local shuttleRouteReady = false



local function notify(msg, nType)

    lib.notify({ description = msg, type = nType or 'inform' })

end



local function hideInteractUi()

    if textUiOpen then

        lib.hideTextUI()

        textUiOpen = false

    end

end



local function showInteractUi(text)

    if not textUiOpen then

        lib.showTextUI(text)

        textUiOpen = true

    end

end



local function clearBlips()

    for _, b in ipairs(blips) do

        if DoesBlipExist(b) then RemoveBlip(b) end

    end

    blips = {}

end



local function addRouteBlip(coords, label, sprite, colour)

    local c = type(coords) == 'vector3' and coords or vec3(coords.x, coords.y, coords.z)

    local b = AddBlipForCoord(c.x, c.y, c.z)

    SetBlipSprite(b, sprite or 1)

    SetBlipColour(b, colour or 3)

    SetBlipRoute(b, true)

    BeginTextCommandSetBlipName('STRING')

    AddTextComponentSubstringPlayerName(label)

    EndTextCommandSetBlipName(b)

    blips[#blips + 1] = b

end



local function distTo(vec)

    return #(GetEntityCoords(cache.ped) - vec3(vec.x, vec.y, vec.z))

end



local function distToPoint(vec3coords)

    return #(GetEntityCoords(cache.ped) - vec3coords)

end



local function isTransportTruck(veh)

    if not veh or veh == 0 then return false end

    local model = GetEntityModel(veh)

    return model == joaat('flatbed') or model == joaat('hauler') or model == joaat('packer')

end



local function isMissionVehicle(netId)

    if not netId then return false end

    local ent = NetworkGetEntityFromNetworkId(netId)

    if not ent or ent == 0 or not DoesEntityExist(ent) then return false end

    return GetVehiclePedIsIn(cache.ped, false) == ent

end



local function getShuttleSpawn()

    return Config.MissionShuttle and Config.MissionShuttle.spawn or Config.HQ.truckSpawn

end



local function refreshMissionRoute()

    if not mission then return end

    clearBlips()

    local stage = mission.stage or 'pickup'



    if mission.mode == 'flatbed' and mission.truckNetId and stage == 'pickup' then

        if not isTransportTruck(GetVehiclePedIsIn(cache.ped, false)) then

            addRouteBlip(getShuttleSpawn(), 'Flatbed de mission', 477, 5)

            return

        end

    end



    if mission.mode == 'drive' and mission.shuttleNetId and stage == 'pickup' then

        if not isMissionVehicle(mission.shuttleNetId) then

            addRouteBlip(getShuttleSpawn(), 'Navette entreprise', 280, 2)

            return

        end

    end



    if stage == 'pickup' then

        addRouteBlip(mission.pickup, 'Point de recuperation', 478, 3)

    elseif stage == 'transport' then

        local label = mission.special and 'Livraison VIP client' or 'Point de livraison'

        addRouteBlip(mission.delivery, label, 525, mission.special and 27 or 3)

    elseif stage == 'return' then

        local hq = Config.HQ.returnPoint or Config.HQ.duty

        addRouteBlip(hq, 'Retour entrepot', 477, 2)

    end

end



local function getCargoEntity()

    if cargoEntity and DoesEntityExist(cargoEntity) then return cargoEntity end

    if cargoNetId then

        local ent = NetworkGetEntityFromNetworkId(cargoNetId)

        if ent and ent ~= 0 and DoesEntityExist(ent) then

            cargoEntity = ent

            return ent

        end

    end

    return nil

end



local function despawnMissionVehicle(netId)

    if not netId then return end

    CreateThread(function()

        local veh

        for _ = 1, 40 do

            veh = NetworkGetEntityFromNetworkId(netId)

            if veh and veh ~= 0 and DoesEntityExist(veh) then break end

            Wait(100)

        end

        if not veh or veh == 0 or not DoesEntityExist(veh) then return end



        while GetVehiclePedIsIn(cache.ped, false) == veh do

            Wait(500)

        end

        Wait(500)



        if not DoesEntityExist(veh) then return end

        NetworkRequestControlOfEntity(veh)

        for _ = 1, 20 do

            if NetworkHasControlOfEntity(veh) then break end

            NetworkRequestControlOfEntity(veh)

            Wait(50)

        end

        if DoesEntityExist(veh) then

            SetEntityAsMissionEntity(veh, true, true)

            DeleteEntity(veh)

        end

    end)

end



local function fadeOutAndDeleteCargo()

    local cargo = getCargoEntity()

    if not cargo then return end



    if GetAttachedCargo() == cargo then

        DetachCargoSafely()

        Wait(300)

    end



    if not DoesEntityExist(cargo) then return end



    NetworkRequestControlOfEntity(cargo)

    for _ = 1, 20 do

        if NetworkHasControlOfEntity(cargo) then break end

        NetworkRequestControlOfEntity(cargo)

        Wait(50)

    end



    if DoesEntityExist(cargo) then

        SetEntityAsMissionEntity(cargo, true, true)

        SetEntityVisible(cargo, false, false)

        SetEntityCollision(cargo, false, false)

        FreezeEntityPosition(cargo, true)

        DeleteEntity(cargo)

    end



    cargoEntity = nil

    cargoNetId = nil

end



local function completeDelivery()

    if completing or not mission then return end

    completing = true

    hideInteractUi()



    CreateThread(function()

        if mission.mode == 'flatbed' and GetAttachedCargo() then

            DetachCargoSafely()

            Wait(400)

        end



        if mission.special and mission.stage == 'transport' then

            fadeOutAndDeleteCargo()

            Wait(200)

        elseif not mission.special then

            fadeOutAndDeleteCargo()

            Wait(200)

        end



        local ok, phase, err = lib.callback.await('acardia_autotransport:completeMission', false)

        if not ok then

            notify(err or phase or 'Livraison invalide.', 'error')

        elseif phase == 'return' then

            mission.stage = 'return'

            mission.shuttleNetId = nil

            cargoNetId = nil

            cargoEntity = nil

            refreshMissionRoute()

        end

        completing = false

    end)

end



local function finishReturnAtDepot()

    if completing or not mission or mission.stage ~= 'return' then return end

    completing = true

    hideInteractUi()



    CreateThread(function()

        local ok, _, err = lib.callback.await('acardia_autotransport:completeMission', false)

        if not ok then notify(err or 'Cloture impossible.', 'error') end

        completing = false

    end)

end



local function getStageLabel()

    if not mission then return '' end

    local stage = mission.stage or 'pickup'

    if stage == 'pickup' then

        if mission.mode == 'drive' and mission.shuttleNetId then return 'Navette -> recuperation' end

        if mission.mode == 'flatbed' and mission.truckNetId then return 'Flatbed -> recuperation' end

        return 'Recuperation vehicule'

    end

    if stage == 'transport' then

        return mission.special and 'Livraison VIP client' or 'Transport en cours'

    end

    if stage == 'return' then return 'Retour entrepot' end

    return stage

end



RegisterNetEvent('acardia_autotransport:missionStarted', function(data)

    mission = data

    completing = false

    truckRouteReady = false

    shuttleRouteReady = false

    cargoNetId = nil

    cargoEntity = nil



    if data.mode == 'flatbed' and data.truckNetId then

        notify(Locales.mission_truck_ready, 'inform')

    elseif data.mode == 'flatbed' then

        notify(Locales.need_truck, 'inform')

    elseif data.mode == 'drive' and data.shuttleNetId then

        notify(Locales.shuttle_ready, 'inform')

    end



    if data.special then

        notify(Locales.vip_briefing, 'inform')

    end



    refreshMissionRoute()

    notify(('Mission: %s'):format(data.label), 'success')

end)



RegisterNetEvent('acardia_autotransport:missionStageUpdated', function(data)

    if not mission then return end

    mission.stage = data.stage

    mission.returnNetId = data.returnNetId

    mission.shuttleNetId = data.shuttleNetId

    cargoNetId = nil

    cargoEntity = nil

    refreshMissionRoute()

end)



RegisterNetEvent('acardia_autotransport:missionEnded', function(payload)

    mission = nil

    cargoNetId = nil

    cargoEntity = nil

    completing = false

    truckRouteReady = false

    shuttleRouteReady = false

    SetAttachedCargo(nil)

    hideInteractUi()

    clearBlips()



    if not payload then return end

    if payload.truckNetId then despawnMissionVehicle(payload.truckNetId) end

    if payload.shuttleNetId then despawnMissionVehicle(payload.shuttleNetId) end

    if payload.returnNetId then despawnMissionVehicle(payload.returnNetId) end

end)



CreateThread(function()

    while true do

        local sleep = 1000



        if mission and not completing then

            local stage = mission.stage or 'pickup'

            local pickup = mission.pickup

            local delivery = mission.delivery

            local hq = Config.HQ.returnPoint or Config.HQ.duty



            if stage == 'pickup' then

                if mission.mode == 'flatbed' and mission.truckNetId and not isTransportTruck(GetVehiclePedIsIn(cache.ped, false)) then

                    sleep = 500

                elseif mission.mode == 'drive' and mission.shuttleNetId and not isMissionVehicle(mission.shuttleNetId) then

                    sleep = 500

                elseif distTo(pickup) < 40.0 then

                    sleep = 0

                    showInteractUi('[E] Recuperer le vehicule')

                    if IsControlJustReleased(0, 38) then

                        hideInteractUi()

                        local spawned = lib.callback.await('acardia_autotransport:spawnCargo', false)

                        if spawned then

                            cargoNetId = spawned.netId

                            mission.stage = 'transport'

                            mission.plate = spawned.plate
                            local oldShuttle = mission.shuttleNetId
                            mission.shuttleNetId = nil
                            if spawned.despawnShuttle and oldShuttle then
                                despawnMissionVehicle(oldShuttle)
                            end
                            refreshMissionRoute()

                            if mission.special then

                                notify(Locales.vip_pickup_done, 'success')

                            else

                                notify(Locales.cargo_ready, 'inform')

                            end

                        end

                    end

                else

                    hideInteractUi()

                end

            elseif stage == 'transport' then

                local cargo = getCargoEntity()



                if mission.mode == 'flatbed' and cargo and not GetAttachedCargo() then

                    local truck = GetVehiclePedIsIn(cache.ped, false)

                    if truck ~= 0 and #(GetEntityCoords(truck) - GetEntityCoords(cargo)) < 12.0 then

                        sleep = 0

                        showInteractUi('[E] Charger sur le flatbed')

                        if IsControlJustReleased(0, 38) then

                            hideInteractUi()

                            AttachCargoToFlatbed(truck, cargo)

                            notify(Locales.load_vehicle, 'success')

                        end

                    else

                        hideInteractUi()

                    end

                elseif distTo(delivery) < 25.0 then

                    sleep = 0

                    local text = mission.special and '[E] Remettre le vehicule VIP' or '[E] Terminer la livraison'

                    showInteractUi(text)

                    if IsControlJustReleased(0, 38) then

                        completeDelivery()

                    end

                else

                    hideInteractUi()

                end

            elseif stage == 'return' then

                if distToPoint(hq) < 25.0 then

                    sleep = 0

                    showInteractUi('[E] Cloturer a l entrepot')

                    if IsControlJustReleased(0, 38) then

                        finishReturnAtDepot()

                    end

                else

                    hideInteractUi()

                end

            else

                hideInteractUi()

            end

        else

            hideInteractUi()

        end



        if mission and not completing and (mission.stage or 'pickup') == 'pickup' then

            if mission.mode == 'flatbed' and mission.truckNetId and not truckRouteReady then

                if isTransportTruck(GetVehiclePedIsIn(cache.ped, false)) then

                    truckRouteReady = true

                    refreshMissionRoute()

                end

            elseif mission.mode == 'drive' and mission.shuttleNetId and not shuttleRouteReady then

                if isMissionVehicle(mission.shuttleNetId) then

                    shuttleRouteReady = true

                    refreshMissionRoute()

                end

            end

        end



        Wait(sleep)

    end

end)



RegisterCommand('atsignaler', function()

    if not mission then return notify('Pas de mission active.', 'error') end

    local coords = GetEntityCoords(cache.ped)

    local ok = lib.callback.await('acardia_autotransport:reportTheft', false, { x = coords.x, y = coords.y, z = coords.z })

    if ok then notify(Locales.report_theft, 'success') else notify('Signalement impossible.', 'error') end

end, false)



exports('GetCurrentMission', function()

    return mission

end)



exports('GetMissionStageLabel', getStageLabel)


