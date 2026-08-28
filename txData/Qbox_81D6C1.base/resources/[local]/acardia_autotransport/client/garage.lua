local garagePed = nil
local attachedCargo = nil

local function notify(msg, nType)
    lib.notify({ description = msg, type = nType or 'inform' })
end

local function getJob()
    return exports.qbx_core:GetPlayerData().job
end

local function isEmployee()
    return JobAccess.HasJob()
end

local function isOnDuty()
    return JobAccess.IsOnDutyClient()
end

local function normalizePlate(plate)
    return (plate or ''):gsub('%s+', ''):upper()
end

function SpawnCompanyVehicleClient(data)
    if not data or not data.model then return nil end
    local model = joaat(data.model)
    lib.requestModel(model, 8000)
    local c = data.coords
    local veh = CreateVehicle(model, c.x, c.y, c.z, c.w or 0.0, true, false)
    if not veh or veh == 0 then return nil end
    SetEntityAsMissionEntity(veh, true, true)
    SetVehicleOnGroundProperly(veh)
    SetVehicleNumberPlateText(veh, data.plate)
    SetVehicleEngineOn(veh, true, true, false)
    local netId = NetworkGetNetworkIdFromEntity(veh)
    lib.callback.await('acardia_autotransport:registerOutVehicle', false, netId, normalizePlate(GetVehicleNumberPlateText(veh)))
    TaskWarpPedIntoVehicle(cache.ped, veh, -1)
    return veh, netId
end

local function openGarageMenu()
    if not isEmployee() or not isOnDuty() then
        return notify('Prends ton service (F6).', 'error')
    end

    local data = lib.callback.await('acardia_autotransport:getGarageData', false)
    if not data then return end

    local options = {}
    if data.isBoss then
        options[#options + 1] = {
            title = 'Acheter un camion (societe)',
            description = ('Solde $%s'):format(data.balance),
            icon = 'cart-shopping',
            onSelect = function()
                local buyOpts = {}
                for _, v in ipairs(data.catalog) do
                    buyOpts[#buyOpts + 1] = {
                        title = v.label,
                        description = ('$%s'):format(v.price),
                        onSelect = function()
                            if lib.callback.await('acardia_autotransport:buyCompanyVehicle', false, v.model) then
                                openGarageMenu()
                            end
                        end,
                    }
                end
                lib.registerContext({ id = 'at_garage_buy', title = 'Catalogue', menu = 'at_garage', options = buyOpts })
                lib.showContext('at_garage_buy')
            end,
        }
    end

    for _, v in ipairs(data.vehicles) do
        if v.stored == 1 then
            options[#options + 1] = {
                title = ('Sortir %s (%s)'):format(v.label, v.plate),
                icon = 'truck',
                onSelect = function()
                    local spawnData = lib.callback.await('acardia_autotransport:takeCompanyVehicle', false, v.id)
                    if spawnData then SpawnCompanyVehicleClient(spawnData) end
                end,
            }
        end
    end

    options[#options + 1] = {
        title = 'Ranger le camion',
        icon = 'warehouse',
        onSelect = function()
            local veh = GetVehiclePedIsIn(cache.ped, false)
            if veh == 0 then return notify('Monte dans le camion entreprise.', 'error') end
            local plate = GetVehicleNumberPlateText(veh)
            local props = lib.getVehicleProperties(veh)
            local netId = NetworkGetNetworkIdFromEntity(veh)
            DeleteEntity(veh)
            lib.callback.await('acardia_autotransport:storeCompanyVehicle', false, plate, props, netId)
        end,
    }

    lib.registerContext({ id = 'at_garage', title = 'Garage Auto Import Export', options = options })
    lib.showContext('at_garage')
end

function GetAttachedCargo()
    return attachedCargo
end

function SetAttachedCargo(entity)
    attachedCargo = entity
end

function AttachCargoToFlatbed(flatbed, cargo)
    if not flatbed or not cargo then return false end
    AttachEntityToEntity(
        cargo, flatbed, GetEntityBoneIndexByName(flatbed, 'bodyshell'),
        0.0, -2.2, 0.95, 0.0, 0.0, 0.0,
        false, false, true, false, 2, true
    )
    attachedCargo = cargo
    return true
end

function DetachCargo()
    if attachedCargo and DoesEntityExist(attachedCargo) then
        FreezeEntityPosition(attachedCargo, true)
        DetachEntity(attachedCargo, true, true)
        Wait(0)
        if IsEntityAVehicle(attachedCargo) then
            SetVehicleOnGroundProperly(attachedCargo)
        end
        FreezeEntityPosition(attachedCargo, false)
    end
    attachedCargo = nil
end

function DetachCargoSafely()
    if not attachedCargo or not DoesEntityExist(attachedCargo) then
        attachedCargo = nil
        return
    end
    local cargo = attachedCargo
    FreezeEntityPosition(cargo, true)
    DetachEntity(cargo, true, true)
    for _ = 1, 10 do Wait(0) end
    if IsEntityAVehicle(cargo) then
        SetVehicleOnGroundProperly(cargo)
    end
    FreezeEntityPosition(cargo, false)
    attachedCargo = nil
end

CreateThread(function()
    if garagePed and DoesEntityExist(garagePed) then return end

    local model = joaat(Config.Peds.garage)
    if not IsModelInCdimage(model) then return end
    lib.requestModel(model, 5000)

    garagePed = CreatePed(0, model, Config.HQ.garage.x, Config.HQ.garage.y, Config.HQ.garage.z - 1.0, Config.HQ.garage.w, false, true)
    SetEntityInvincible(garagePed, true)
    FreezeEntityPosition(garagePed, true)
    SetBlockingOfNonTemporaryEvents(garagePed, true)

    exports.ox_target:addLocalEntity(garagePed, {
        {
            name = 'at_garage_ped',
            icon = 'fa-solid fa-warehouse',
            label = 'Garage entreprise',
            canInteract = function()
                return isEmployee()
            end,
            onSelect = openGarageMenu,
        },
    })
end)

AddEventHandler('onResourceStop', function(res)
    if res ~= GetCurrentResourceName() then return end
    if garagePed and DoesEntityExist(garagePed) then DeleteEntity(garagePed) end
end)
