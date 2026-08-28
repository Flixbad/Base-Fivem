local garagePed = nil
local openGarageMenu

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

local function normalizePlate(plate)
    return (plate or ''):gsub('%s+', ''):upper()
end

local function requestControl(entity, tries)
    tries = tries or 50
    if not entity or entity == 0 or not DoesEntityExist(entity) then return false end
    if NetworkHasControlOfEntity(entity) then return true end
    local i = 0
    while i < tries do
        NetworkRequestControlOfEntity(entity)
        if NetworkHasControlOfEntity(entity) then return true end
        Wait(0)
        i = i + 1
    end
    return NetworkHasControlOfEntity(entity)
end

local function forceDeleteVehicle(veh)
    if not veh or veh == 0 or not DoesEntityExist(veh) then return false end
    requestControl(veh, 80)
    SetEntityAsMissionEntity(veh, true, true)
    SetVehicleHasBeenOwnedByPlayer(veh, false)
    SetEntityAsNoLongerNeeded(veh)
    DeleteVehicle(veh)
    if DoesEntityExist(veh) then
        DeleteEntity(veh)
    end
    return not DoesEntityExist(veh)
end

function SpawnCompanyVehicleClient(data)
    if not data or not data.model then return nil end

    local model = joaat(data.model)
    lib.requestModel(model, 8000)

    local c = data.coords
    local veh = CreateVehicle(model, c.x, c.y, c.z, c.w or 0.0, true, false)
    if not veh or veh == 0 then
        SetModelAsNoLongerNeeded(model)
        return nil
    end

    SetEntityAsMissionEntity(veh, true, true)
    SetVehicleOnGroundProperly(veh)
    SetVehicleNumberPlateText(veh, data.plate)
    SetVehicleDoorsLocked(veh, 1)
    SetVehicleEngineOn(veh, true, true, false)
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
    end

    local actualPlate = normalizePlate(GetVehicleNumberPlateText(veh))
    lib.callback.await('acardia_importexport:registerOutVehicle', false, netId, actualPlate)
    TaskWarpPedIntoVehicle(cache.ped, veh, -1)
    return veh, netId
end

openGarageMenu = function()
    if not isEmployee() then
        notify('Reserve aux employes Acardia Export.', 'error')
        return
    end
    if not isOnDuty() then
        notify('Prends ton service via la tablette (F6).', 'error')
        return
    end

    local data = lib.callback.await('acardia_importexport:getGarageData', false)
    if not data then
        notify('Impossible d ouvrir le garage. Reessaie ou reprends ton service.', 'error')
        return
    end

    local companyPlates = {}
    for _, p in ipairs(data.plates or {}) do
        companyPlates[normalizePlate(p)] = true
    end

    local options = {}

    if data.isBoss then
        options[#options + 1] = {
            title = 'Acheter un vehicule (societe)',
            description = ('Solde: $%s'):format(data.balance),
            icon = 'cart-shopping',
            onSelect = function()
                local buyOpts = {}
                for _, v in ipairs(data.catalog) do
                    buyOpts[#buyOpts + 1] = {
                        title = v.label,
                        description = ('$%s'):format(v.price),
                        onSelect = function()
                            local ok = lib.callback.await('acardia_importexport:buyCompanyVehicle', false, v.model)
                            if ok then openGarageMenu() end
                        end,
                    }
                end
                lib.registerContext({ id = 'ae_garage_buy', title = 'Catalogue entreprise', menu = 'ae_garage', options = buyOpts })
                lib.showContext('ae_garage_buy')
            end,
        }
    end

    options[#options + 1] = {
        title = 'Ranger le vehicule entreprise',
        description = 'Monte dedans ou reste a proximite du garage',
        icon = 'warehouse',
        onSelect = function()
            local ped = cache.ped
            local coords = GetEntityCoords(ped)
            local radius = Config.Garage.storeRadius or 60.0
            local veh = GetVehiclePedIsIn(ped, false)

            if veh == 0 then
                local vehicles = GetGamePool('CVehicle')
                local best, bestDist
                for i = 1, #vehicles do
                    local v = vehicles[i]
                    local p = normalizePlate(GetVehicleNumberPlateText(v))
                    local dist = #(GetEntityCoords(v) - coords)
                    if companyPlates[p] and dist <= radius then
                        if not bestDist or dist < bestDist then
                            best, bestDist = v, dist
                        end
                    end
                end
                veh = best or 0
            end

            local plate, props, netId
            if veh and veh ~= 0 then
                plate = GetVehicleNumberPlateText(veh)
                props = lib.getVehicleProperties(veh)
                netId = NetworkGetNetworkIdFromEntity(veh)
                forceDeleteVehicle(veh)
            end

            local ok = lib.callback.await('acardia_importexport:storeCompanyVehicle', false, plate, props, netId)
            if not ok then
                notify('Impossible de ranger. Sors un camion puis reessaie a proximite.', 'error')
            end
        end,
    }

    for _, v in ipairs(data.vehicles) do
        if v.stored == 1 or v.stored == true then
            options[#options + 1] = {
                title = ('Sortir: %s'):format(v.label),
                description = ('Plaque %s'):format(v.plate),
                icon = 'truck',
                onSelect = function()
                    local spawnData = lib.callback.await('acardia_importexport:takeCompanyVehicle', false, v.id)
                    if type(spawnData) ~= 'table' then return end
                    local veh = SpawnCompanyVehicleClient(spawnData)
                    if not veh then
                        notify('Echec spawn du vehicule.', 'error')
                    end
                end,
            }
        else
            options[#options + 1] = {
                title = ('%s (dehors)'):format(v.label),
                description = ('Plaque %s - deja sorti'):format(v.plate),
                icon = 'road',
                disabled = true,
            }
        end
    end

    if #data.vehicles == 0 then
        options[#options + 1] = {
            title = 'Aucun vehicule',
            description = data.isBoss and 'Achete un camion avec le compte societe' or 'Demande au patron d acheter un camion',
            disabled = true,
        }
    end

    lib.registerContext({
        id = 'ae_garage',
        title = 'Garage Acardia Export',
        options = options,
    })
    lib.showContext('ae_garage')
end

local function attachGarageTarget()
    if not garagePed or not DoesEntityExist(garagePed) then return end

    exports.ox_target:removeLocalEntity(garagePed, 'ae_garage')
    exports.ox_target:addLocalEntity(garagePed, {
        {
            name = 'ae_garage',
            icon = 'fa-solid fa-warehouse',
            label = 'Garage entreprise',
            distance = 2.5,
            onSelect = function()
                CreateThread(function()
                    openGarageMenu()
                end)
            end,
        },
    })
end

local function spawnGaragePed()
    if garagePed and DoesEntityExist(garagePed) then
        attachGarageTarget()
        return
    end

    local c = Config.HQ.garage
    local model = joaat(Config.Garage.pedModel)
    lib.requestModel(model, 5000)
    garagePed = CreatePed(0, model, c.x, c.y, c.z - 1.0, c.w, false, false)
    SetEntityAsMissionEntity(garagePed, true, true)
    SetBlockingOfNonTemporaryEvents(garagePed, true)
    FreezeEntityPosition(garagePed, true)
    SetEntityInvincible(garagePed, true)
    SetModelAsNoLongerNeeded(model)
    attachGarageTarget()
end

function GetGarageInteractable()
    return nil
end

RegisterNetEvent('acardia_importexport:clientSpawnCompanyVehicle', function(data)
    SpawnCompanyVehicleClient(data)
end)

CreateThread(function()
    while GetResourceState('ox_target') ~= 'started' do
        Wait(200)
    end
    Wait(500)
    spawnGaragePed()
end)

AddEventHandler('onResourceStop', function(res)
    if res ~= GetCurrentResourceName() then return end
    if garagePed and DoesEntityExist(garagePed) then
        exports.ox_target:removeLocalEntity(garagePed, 'ae_garage')
        DeleteEntity(garagePed)
    end
end)
