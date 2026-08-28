local blips = {}
local stage = nil
local showingUi = false
local supplierPed = nil
local missionPed = nil
local missionDest = nil
local crafting = false
local openMissionMenu
local openHqMenu
local craftProp = nil

local function notify(msg, nType)
    lib.notify({ description = msg, type = nType or 'inform' })
end

local function getJob()
    local pdata = exports.qbx_core:GetPlayerData()
    return pdata and pdata.job or nil
end

local function isEmployee()
    local job = getJob()
    return job and job.name == Config.JobName
end

local function isOnDuty()
    local job = getJob()
    return job and job.name == Config.JobName and job.onduty
end

local function clearBlips()
    for _, b in pairs(blips) do
        if DoesBlipExist(b) then RemoveBlip(b) end
    end
    blips = {}
end

local function addBlip(coords, sprite, color, label)
    local b = AddBlipForCoord(coords.x, coords.y, coords.z)
    SetBlipSprite(b, sprite or 1)
    SetBlipColour(b, color or 5)
    SetBlipScale(b, 0.85)
    SetBlipAsShortRange(b, false)
    BeginTextCommandSetBlipName('STRING')
    AddTextComponentSubstringPlayerName(label or 'Acardia')
    EndTextCommandSetBlipName(b)
    SetBlipRoute(b, true)
    blips[#blips + 1] = b
    return b
end

local function setWaypoint(coords)
    SetNewWaypoint(coords.x, coords.y)
end

local function hideInteractUi()
    if showingUi then
        lib.hideTextUI()
        showingUi = false
    end
end

local function showInteractUi(text)
    lib.showTextUI(text)
    showingUi = true
end

local function attachCraftTarget()
    if not craftProp or not DoesEntityExist(craftProp) then return end
    exports.ox_target:removeLocalEntity(craftProp, 'ae_craft')
    exports.ox_target:addLocalEntity(craftProp, {
        {
            name = 'ae_craft',
            icon = 'fa-solid fa-box',
            label = 'Preparer un colis',
            distance = 2.5,
            onSelect = function()
                CreateThread(function()
                    if not isEmployee() then return end
                    if crafting then return end
                    if not isOnDuty() then
                        notify('Prends ton service via la tablette (F6).', 'error')
                        return
                    end
                    openHqMenu()
                end)
            end,
        },
    })
end

local function spawnCraftProp()
    -- ox_target en zone sur la table (pas de prop spawné)
    local c = Config.HQ.craft
    pcall(function() exports.ox_target:removeZone('ae_craft') end)
    exports.ox_target:addBoxZone({
        name = 'ae_craft',
        coords = vec3(c.x, c.y, c.z - 0.5),
        size = vec3(1.5, 1.5, 1.5),
        rotation = c.w or 0.0,
        debug = false,
        options = {
            {
                name = 'ae_craft',
                icon = 'fa-solid fa-box',
                label = 'Preparer un colis',
                distance = 2.5,
                onSelect = function()
                    CreateThread(function()
                        if not isEmployee() then return end
                        if crafting then return end
                        if not isOnDuty() then
                            notify('Prends ton service via la tablette (F6).', 'error')
                            return
                        end
                        openHqMenu()
                    end)
                end,
            },
        },
    })
end

local function attachMissionTarget()
    if not missionPed or not DoesEntityExist(missionPed) then return end
    exports.ox_target:removeLocalEntity(missionPed, 'ae_missions')
    exports.ox_target:addLocalEntity(missionPed, {
        {
            name = 'ae_missions',
            icon = 'fa-solid fa-clipboard-list',
            label = 'Ouvrir la tablette de missions',
            distance = 2.5,
            onSelect = function()
                CreateThread(function()
                    if not isOnDuty() then
                        notify('Prends ton service via la tablette (F6).', 'error')
                        return
                    end
                    openMissionMenu()
                end)
            end,
        },
    })
end

local function spawnMissionPed()
    if missionPed and DoesEntityExist(missionPed) then
        attachMissionTarget()
        return
    end
    local c = Config.HQ.missionPed
    if not c then return end
    local model = joaat('s_m_y_dockwork_01')
    lib.requestModel(model, 5000)
    missionPed = CreatePed(0, model, c.x, c.y, c.z - 1.0, c.w, false, false)
    SetEntityAsMissionEntity(missionPed, true, true)
    SetBlockingOfNonTemporaryEvents(missionPed, true)
    FreezeEntityPosition(missionPed, true)
    SetEntityInvincible(missionPed, true)
    SetModelAsNoLongerNeeded(model)
    attachMissionTarget()
end

local function spawnSupplierPed()
    if supplierPed and DoesEntityExist(supplierPed) then return end
    local c = Config.Supplier.coords
    local model = joaat(Config.Supplier.pedModel)
    lib.requestModel(model, 5000)
    supplierPed = CreatePed(0, model, c.x, c.y, c.z - 1.0, c.w, false, false)
    SetEntityAsMissionEntity(supplierPed, true, true)
    SetBlockingOfNonTemporaryEvents(supplierPed, true)
    FreezeEntityPosition(supplierPed, true)
    SetEntityInvincible(supplierPed, true)
    SetModelAsNoLongerNeeded(model)
end

local function stopCraftAnim()
    local ped = PlayerPedId()
    ClearPedTasks(ped)
    FreezeEntityPosition(ped, false)
    SendNUIMessage({ action = 'craftProgress', show = false })
end

local function loadAnimDict(dict)
    if not dict or dict == '' then return false end
    if HasAnimDictLoaded(dict) then return true end
    RequestAnimDict(dict)
    local timeout = GetGameTimer() + 4000
    while not HasAnimDictLoaded(dict) and GetGameTimer() < timeout do
        Wait(10)
    end
    return HasAnimDictLoaded(dict)
end

local function startCraftAnim()
    local ped = PlayerPedId()
    local c = Config.HQ.craft
    if c and c.w then
        SetEntityHeading(ped, c.w)
    end

    local anim = Config.CraftAnim or {}
    if loadAnimDict(anim.dict) then
        TaskPlayAnim(ped, anim.dict, anim.clip, 8.0, -8.0, -1, anim.flag or 1, 0.0, false, false, false)
        return
    end

    -- fallback mecanicien vanilla
    TaskStartScenarioInPlace(ped, 'WORLD_HUMAN_WELDING', 0, true)
end

local function craftCrate(recipe)
    if crafting then return end
    crafting = true

    local cancelled = false
    local finished = false

    local ok, err = pcall(function()
        local can = lib.callback.await('acardia_importexport:canCraftCrate', false, recipe.id)
        if not can then
            notify('Ingredients insuffisants (inventaire ou coffre).', 'error')
            return
        end

        hideInteractUi()
        SendNUIMessage({
            action = 'craftProgress',
            show = true,
            duration = Config.CraftDuration or 60000,
            label = recipe.label or 'Fabrication du colis',
        })
        startCraftAnim()

        local duration = Config.CraftDuration or 60000
        local started = GetGameTimer()
        local anim = Config.CraftAnim or {}

        while GetGameTimer() - started < duration do
            DisableControlAction(0, 30, true)
            DisableControlAction(0, 31, true)
            DisableControlAction(0, 21, true)
            DisableControlAction(0, 22, true)
            DisableControlAction(0, 24, true)
            DisableControlAction(0, 25, true)
            DisableControlAction(0, 75, true)
            if IsControlJustReleased(0, 73) then
                cancelled = true
                break
            end
            if anim.dict and anim.clip and not IsEntityPlayingAnim(PlayerPedId(), anim.dict, anim.clip, 3) then
                if HasAnimDictLoaded(anim.dict) then
                    TaskPlayAnim(PlayerPedId(), anim.dict, anim.clip, 8.0, -8.0, -1, anim.flag or 1, 0.0, false, false, false)
                end
            end
            Wait(0)
        end

        finished = not cancelled
    end)

    stopCraftAnim()
    crafting = false

    if not ok then
        notify('Erreur fabrication. Reessaie.', 'error')
        print(('[acardia_importexport] craft error: %s'):format(err))
        return
    end

    if cancelled then
        notify('Fabrication annulee.', 'error')
        return
    end

    if finished then
        lib.callback.await('acardia_importexport:craftCrate', false, recipe.id)
    end
end

local function openCraftMenu()
    local options = {}
    for _, recipe in ipairs(Config.CraftRecipes) do
        options[#options + 1] = {
            title = recipe.label,
            description = '60 secondes · animation mecanicien',
            onSelect = function()
                CreateThread(function()
                    craftCrate(recipe)
                end)
            end,
        }
    end
    lib.registerContext({ id = 'ae_craft_menu', title = 'Preparation colis', options = options })
    lib.showContext('ae_craft_menu')
end

local function openSupplierShop()
    local options = {}
    for _, entry in ipairs(Config.SupplierShop) do
        options[#options + 1] = {
            title = entry.label,
            description = ('$%s / unite (compte societe)'):format(entry.price),
            onSelect = function()
                local input = lib.inputDialog('Acheter ' .. entry.label, {
                    { type = 'number', label = 'Quantite', default = 1, min = 1, max = 50 },
                })
                if not input or not input[1] then return end
                lib.callback.await('acardia_importexport:buySupplyItem', false, entry.item, input[1])
            end,
        }
    end
    options[#options + 1] = {
        title = 'Terminer mission approvisionnement',
        description = 'Supprime le camion de mission',
        icon = 'check',
        onSelect = function()
            lib.callback.await('acardia_importexport:finishSupplyMission', false)
        end,
    }
    lib.registerContext({ id = 'ae_supplier_shop', title = 'Fournisseur Acardia', options = options })
    lib.showContext('ae_supplier_shop')
end

openHqMenu = function()
    if not isOnDuty() then
        notify('Prends ton service via la tablette (F6).', 'error')
        return
    end
    openCraftMenu()
end

openMissionMenu = function()
    if not isOnDuty() then
        notify('Prends ton service via la tablette (F6).', 'error')
        return
    end

    local options = {
        {
            title = 'Mission: chercher ingredients',
            description = 'Conduis un camion du garage, puis lance (GPS fournisseur)',
            icon = 'store',
            disabled = stage ~= nil,
            onSelect = function()
                local veh = GetVehiclePedIsIn(cache.ped, false)
                if veh ~= 0 then
                    local plate = GetVehicleNumberPlateText(veh)
                    local netId = NetworkGetNetworkIdFromEntity(veh)
                    lib.callback.await('acardia_importexport:claimNearbyCompanyVehicle', false, plate, netId)
                end
                lib.callback.await('acardia_importexport:startSupplyMission', false)
            end,
        },
        {
            title = 'Demarrer mission export',
            description = 'Conduis un camion du garage + caisses dans l inventaire',
            icon = 'truck',
            disabled = stage ~= nil,
            onSelect = function()
                local veh = GetVehiclePedIsIn(cache.ped, false)
                if veh ~= 0 then
                    local plate = GetVehicleNumberPlateText(veh)
                    local netId = NetworkGetNetworkIdFromEntity(veh)
                    lib.callback.await('acardia_importexport:claimNearbyCompanyVehicle', false, plate, netId)
                end
                lib.callback.await('acardia_importexport:startMission', false)
            end,
        },
    }

    if stage == 'load_truck' then
        options[#options + 1] = {
            title = 'Valider chargement camion',
            icon = 'boxes-stacked',
            onSelect = function()
                lib.callback.await('acardia_importexport:confirmTruckLoaded', false)
            end,
        }
    end
    if stage ~= nil then
        options[#options + 1] = {
            title = 'Annuler mission',
            icon = 'xmark',
            onSelect = function()
                TriggerServerEvent('acardia_importexport:cancelMission')
            end,
        }
    end

    lib.registerContext({ id = 'ae_mission_menu', title = 'Missions Acardia Export', options = options })
    lib.showContext('ae_mission_menu')
end

local function openCompanyStash()
    local ok, stashId = lib.callback.await('acardia_importexport:openStash', false)
    if ok and stashId then
        exports.ox_inventory:openInventory('stash', stashId)
    end
end

local function getInteractables()
    local list = {}

    if isEmployee() then
        list[#list + 1] = {
            coords = Config.HQ.stash,
            radius = 2.2,
            label = isOnDuty() and '[E] Coffre entreprise (10000kg)' or '[E] Service via tablette F6',
            action = function()
                if not isOnDuty() then
                    notify('Prends ton service via la tablette (F6).', 'error')
                    return
                end
                openCompanyStash()
            end,
        }

        local garagePoint = GetGarageInteractable and GetGarageInteractable() or nil
        if garagePoint then
            list[#list + 1] = garagePoint
        end
    end

    if stage == 'supply_buy' then
        local s = Config.Supplier.coords
        list[#list + 1] = {
            coords = vec3(s.x, s.y, s.z),
            radius = 2.5,
            label = '[E] Parler au fournisseur',
            action = openSupplierShop,
        }
    end

    if stage == 'go_port' then
        list[#list + 1] = {
            coords = Config.Port.checkIn,
            radius = 6.0,
            label = '[E] Embarquer (port)',
            action = function()
                TriggerServerEvent('acardia_importexport:requestEmbark')
            end,
        }
    end

    if stage == 'boat_deliver' and missionDest then
        list[#list + 1] = {
            coords = missionDest,
            radius = 12.0,
            label = '[E] Livrer les caisses (bateau)',
            action = function()
                lib.callback.await('acardia_importexport:completeBoatDelivery', false)
            end,
        }
    end

    if stage == 'return_port' then
        local s = Config.Port.boatStore or Config.Port.boatSpawn
        list[#list + 1] = {
            coords = vec3(s.x, s.y, s.z),
            radius = 12.0,
            label = '[E] Ranger le bateau',
            action = function()
                lib.callback.await('acardia_importexport:storeBoat', false)
            end,
        }
    end

    if stage == 'port_truck' then
        local g = Config.Port.truckGarage or vec3(Config.Port.truckSpawn.x, Config.Port.truckSpawn.y, Config.Port.truckSpawn.z)
        list[#list + 1] = {
            coords = g,
            radius = 3.5,
            label = '[E] Prendre camion entreprise',
            action = function()
                lib.callback.await('acardia_importexport:takePortTruck', false)
            end,
        }
    end

    return list
end

RegisterNetEvent('acardia_importexport:setupVehicle', function(netId)
    CreateThread(function()
        local timeout = 0
        local veh = 0
        while timeout < 120 do
            if NetworkDoesNetworkIdExist(netId) then
                veh = NetToVeh(netId)
                if veh ~= 0 and DoesEntityExist(veh) then break end
            end
            Wait(50)
            timeout = timeout + 1
        end
        if veh == 0 or not DoesEntityExist(veh) then return end
        SetVehicleDoorsLocked(veh, 1)
        SetVehicleEngineOn(veh, true, true, false)
        SetPedIntoVehicle(cache.ped, veh, -1)
        Wait(100)
        if not IsPedInVehicle(cache.ped, veh, false) then
            TaskWarpPedIntoVehicle(cache.ped, veh, -1)
        end
    end)
end)

local function forceDeleteLocalVehicle(veh)
    if not veh or veh == 0 or not DoesEntityExist(veh) then return end
    local tries = 0
    NetworkRequestControlOfEntity(veh)
    while not NetworkHasControlOfEntity(veh) and tries < 80 do
        NetworkRequestControlOfEntity(veh)
        Wait(0)
        tries = tries + 1
    end
    SetEntityAsMissionEntity(veh, true, true)
    SetVehicleHasBeenOwnedByPlayer(veh, false)
    DeleteVehicle(veh)
    if DoesEntityExist(veh) then
        DeleteEntity(veh)
    end
end

RegisterNetEvent('acardia_importexport:despawnCompanyVehicle', function(plate, netId)
    plate = (plate or ''):gsub('%s+', ''):upper()
    if netId and NetworkDoesNetworkIdExist(netId) then
        local veh = NetToVeh(netId)
        if veh ~= 0 and DoesEntityExist(veh) then
            forceDeleteLocalVehicle(veh)
        end
    end

    local vehicles = GetGamePool('CVehicle')
    for i = 1, #vehicles do
        local veh = vehicles[i]
        local p = (GetVehicleNumberPlateText(veh) or ''):gsub('%s+', ''):upper()
        if plate ~= '' and p == plate then
            forceDeleteLocalVehicle(veh)
        end
    end
end)

RegisterNetEvent('acardia_importexport:despawnAllCompanyVehicles', function(plates)
    local set = {}
    for i = 1, #(plates or {}) do
        set[(plates[i] or ''):gsub('%s+', ''):upper()] = true
    end
    local vehicles = GetGamePool('CVehicle')
    for i = 1, #vehicles do
        local veh = vehicles[i]
        local p = (GetVehicleNumberPlateText(veh) or ''):gsub('%s+', ''):upper()
        if set[p] then
            forceDeleteLocalVehicle(veh)
        end
    end
end)

RegisterNetEvent('acardia_importexport:leaveVehicle', function()
    local ped = cache.ped
    local veh = GetVehiclePedIsIn(ped, false)
    if veh ~= 0 then
        TaskLeaveVehicle(ped, veh, 16)
    end
end)

RegisterNetEvent('acardia_importexport:despawnByNet', function(netId)
    if not netId or not NetworkDoesNetworkIdExist(netId) then return end
    local veh = NetToVeh(netId)
    if veh ~= 0 and DoesEntityExist(veh) then
        forceDeleteLocalVehicle(veh)
    end
end)

RegisterNetEvent('acardia_importexport:clearMission', function()
    stage = nil
    missionDest = nil
    clearBlips()
    hideInteractUi()
end)

RegisterNetEvent('acardia_importexport:clearMissionKeepHint', function()
    stage = nil
    missionDest = nil
end)

local function applyMissionStage(newStage, data)
    stage = newStage
    clearBlips()
    data = data or {}
    missionDest = nil

    if newStage == 'load_truck' then
        notify('Valide le chargement au marker craft (E). Les caisses restent dans ton inventaire.', 'inform')
        setWaypoint(Config.HQ.craft)
    elseif newStage == 'supply_buy' then
        spawnSupplierPed()
        local s = data.supplier or Config.Supplier.coords
        local coords = vec3(s.x, s.y, s.z)
        addBlip(coords, Config.Supplier.blip.sprite, Config.Supplier.blip.color, Config.Supplier.blip.label)
        setWaypoint(coords)
        notify('GPS place chez le fournisseur. Achats payes par la societe.', 'inform')
    elseif newStage == 'go_port' then
        addBlip(Config.Port.checkIn, 410, 3, 'Port Acardia')
        setWaypoint(Config.Port.checkIn)
        notify(Locales.go_port, 'inform')
    elseif newStage == 'boat_deliver' then
        if data.dest and data.dest.x then
            missionDest = vec3(data.dest.x + 0.0, data.dest.y + 0.0, data.dest.z + 0.0)
            local b = addBlip(missionDest, 404, 5, data.label or 'Livraison bateau')
            setWaypoint(missionDest)
            if b then SetBlipRoute(b, true) end
        else
            notify('Erreur GPS livraison — reessaie Embarquer.', 'error')
        end
        notify(
            ('Livraison bateau: %s — suis le GPS puis [E] sur place.'):format(data.label or 'Point client'),
            'success'
        )
        if data.boatNet then
            CreateThread(function()
                Wait(300)
                TriggerEvent('acardia_importexport:setupVehicle', data.boatNet)
            end)
        end
    elseif newStage == 'return_port' then
        if data.dest and data.dest.x then
            missionDest = vec3(data.dest.x + 0.0, data.dest.y + 0.0, data.dest.z + 0.0)
            addBlip(missionDest, 356, 3, 'Ranger bateau')
            setWaypoint(missionDest)
        end
        notify(Locales.return_port, 'inform')
    elseif newStage == 'port_truck' then
        if data.dest and data.dest.x then
            missionDest = vec3(data.dest.x + 0.0, data.dest.y + 0.0, data.dest.z + 0.0)
            addBlip(missionDest, 477, 5, 'Garage camion port')
            setWaypoint(missionDest)
        end
        notify(Locales.boat_stored, 'inform')
    elseif newStage == 'return_hq' then
        if data.dest and data.dest.x then
            local dest = vec3(data.dest.x + 0.0, data.dest.y + 0.0, data.dest.z + 0.0)
            addBlip(dest, Config.Blip.sprite, Config.Blip.color, 'QG Acardia')
            setWaypoint(dest)
        end
        notify(Locales.take_port_truck, 'success')
    end
end

RegisterNetEvent('acardia_importexport:setStage', function(newStage, data)
    applyMissionStage(newStage, data)
end)

RegisterNetEvent('acardia_importexport:startBoatDelivery', function(data)
    data = data or {}
    if not data.dest or not data.dest.x then
        notify('Erreur: pas de point de livraison.', 'error')
        return
    end

    -- GPS + stage d abord
    applyMissionStage('boat_deliver', {
        dest = data.dest,
        label = data.label,
        zone = data.zone,
        boatNet = nil, -- spawn gere juste apres
    })

    CreateThread(function()
        if data.resume and data.boatNet then
            Wait(200)
            TriggerEvent('acardia_importexport:setupVehicle', data.boatNet)
            return
        end

        local modelName = data.model or Config.Vehicles.boat
        local model = joaat(modelName)
        lib.requestModel(model, 8000)

        local s = data.spawn or Config.Port.boatSpawn
        local veh = CreateVehicle(model, s.x + 0.0, s.y + 0.0, s.z + 0.0, s.w or 0.0, true, false)
        if not veh or veh == 0 then
            notify('Impossible de spawn le bateau (client).', 'error')
            SetModelAsNoLongerNeeded(model)
            return
        end

        SetEntityAsMissionEntity(veh, true, true)
        SetVehicleEngineOn(veh, true, true, false)
        SetVehicleDoorsLocked(veh, 1)
        SetModelAsNoLongerNeeded(model)

        local timeout = 0
        while timeout < 40 do
            if NetworkGetEntityIsNetworked(veh) then break end
            Wait(50)
            timeout = timeout + 1
        end

        local netId = NetworkGetNetworkIdFromEntity(veh)
        if netId and netId ~= 0 then
            SetNetworkIdCanMigrate(netId, true)
            SetNetworkIdExistsOnAllMachines(netId, true)
            TriggerServerEvent('acardia_importexport:registerBoatNet', netId)
        end

        SetPedIntoVehicle(cache.ped, veh, -1)
        Wait(100)
        if not IsPedInVehicle(cache.ped, veh, false) then
            TaskWarpPedIntoVehicle(cache.ped, veh, -1)
        end

        notify('Tu es au volant — suis le GPS de livraison.', 'success')
    end)
end)

CreateThread(function()
    local hqBlip = AddBlipForCoord(Config.HQ.craft.x, Config.HQ.craft.y, Config.HQ.craft.z)
    SetBlipSprite(hqBlip, Config.Blip.sprite)
    SetBlipColour(hqBlip, Config.Blip.color)
    SetBlipScale(hqBlip, Config.Blip.scale)
    SetBlipAsShortRange(hqBlip, true)
    BeginTextCommandSetBlipName('STRING')
    AddTextComponentSubstringPlayerName(Config.Blip.label)
    EndTextCommandSetBlipName(hqBlip)

    spawnSupplierPed()
    spawnMissionPed()
    spawnCraftProp()
end)

CreateThread(function()
    while true do
        local sleep = 1000
        local ped = cache.ped
        local coords = GetEntityCoords(ped)
        local interactables = getInteractables()
        local nearest, nearestDist, nearestLabel

        for i = 1, #interactables do
            local p = interactables[i]
            local dist = #(coords - p.coords)
            if dist < 40.0 then
                sleep = 0
                DrawMarker(
                    1,
                    p.coords.x, p.coords.y, p.coords.z - 1.0,
                    0.0, 0.0, 0.0,
                    0.0, 0.0, 0.0,
                    1.6, 1.6, 0.8,
                    241, 196, 15, 160,
                    false, false, 2, false, nil, nil, false
                )
            end
            if not crafting and dist < (p.radius or 2.0) and (not nearestDist or dist < nearestDist) then
                nearest = p
                nearestDist = dist
                nearestLabel = p.label
            end
        end

        if nearest then
            sleep = 0
            showInteractUi(nearestLabel)
            if IsControlJustReleased(0, 38) then
                nearest.action()
                Wait(300)
            end
        else
            hideInteractUi()
        end

        Wait(sleep)
    end
end)

CreateThread(function()
    Wait(300)
    crafting = false
    local ped = PlayerPedId()
    FreezeEntityPosition(ped, false)
    ClearPedTasks(ped)
    SendNUIMessage({ action = 'craftProgress', show = false })
end)

AddEventHandler('onResourceStop', function(res)
    if res ~= GetCurrentResourceName() then return end
    hideInteractUi()
    crafting = false
    FreezeEntityPosition(PlayerPedId(), false)
    ClearPedTasks(PlayerPedId())
    if supplierPed and DoesEntityExist(supplierPed) then
        DeleteEntity(supplierPed)
    end
    if missionPed and DoesEntityExist(missionPed) then
        exports.ox_target:removeLocalEntity(missionPed, 'ae_missions')
        DeleteEntity(missionPed)
    end
    if craftProp and DoesEntityExist(craftProp) then
        exports.ox_target:removeLocalEntity(craftProp, 'ae_craft')
        DeleteEntity(craftProp)
    end
    exports.ox_target:removeZone('ae_craft')
end)
