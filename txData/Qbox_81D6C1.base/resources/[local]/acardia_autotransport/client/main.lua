local blip = nil
local missionPed = nil

local function notify(msg, nType)
    lib.notify({ description = msg, type = nType or 'inform' })
end

local function isEmployee()
    return JobAccess.HasJob()
end

local function createBlip()
    if blip then return end
    local c = Config.Blip.coords or Config.HQ.duty
    blip = AddBlipForCoord(c.x, c.y, c.z)
    SetBlipSprite(blip, Config.Blip.sprite)
    SetBlipColour(blip, Config.Blip.color)
    SetBlipScale(blip, Config.Blip.scale)
    SetBlipAsShortRange(blip, true)
    BeginTextCommandSetBlipName('STRING')
    AddTextComponentSubstringPlayerName(Config.Blip.label)
    EndTextCommandSetBlipName(blip)
end

local function spawnPed(modelName, coords, scenario)
    local model = joaat(modelName)
    if not IsModelInCdimage(model) then
        print(('[acardia_autotransport] Modele PNJ invalide: %s'):format(modelName))
        return nil
    end
    lib.requestModel(model, 5000)
    local ped = CreatePed(0, model, coords.x, coords.y, coords.z - 1.0, coords.w, false, true)
    SetEntityInvincible(ped, true)
    SetBlockingOfNonTemporaryEvents(ped, true)
    FreezeEntityPosition(ped, true)
    if scenario then TaskStartScenarioInPlace(ped, scenario, 0, true) end
    SetModelAsNoLongerNeeded(model)
    return ped
end

CreateThread(function()
    createBlip()

    missionPed = spawnPed(Config.Peds.mission, Config.HQ.missionPed, 'WORLD_HUMAN_CLIPBOARD')

    if missionPed then
        exports.ox_target:addLocalEntity(missionPed, {
        {
            name = 'at_mission_ped',
            icon = 'fa-solid fa-truck-ramp-box',
            label = 'Parler au responsable logistique',
            distance = 2.5,
            canInteract = function()
                return isEmployee()
            end,
            onSelect = function()
                TriggerEvent('acardia_autotransport:openTablet')
            end,
        },
        })
    end

    exports.ox_target:addBoxZone({
        coords = Config.HQ.stash,
        size = vec3(1.5, 1.5, 2.0),
        rotation = 0,
        options = {
            {
                name = 'at_stash',
                icon = 'fa-solid fa-box',
                label = 'Coffre entreprise',
                canInteract = function()
                    return isEmployee()
                end,
                onSelect = function()
                    exports.ox_inventory:openInventory('stash', Config.Stash.id)
                end,
            },
        },
    })

    exports.ox_target:addBoxZone({
        coords = vec3(Config.DealerPickup.x, Config.DealerPickup.y, Config.DealerPickup.z),
        size = vec3(3.0, 3.0, 2.0),
        rotation = Config.DealerPickup.w,
        options = {
            {
                name = 'at_dealer_transfer',
                icon = 'fa-solid fa-truck',
                label = 'Demander un transfert Auto Import',
                canInteract = function()
                    local job = exports.qbx_core:GetPlayerData().job
                    return job and job.name == 'cardealer' and job.onduty
                end,
                onSelect = function()
                    local input = lib.inputDialog('Transfert concession', {
                        { type = 'input', label = 'Modele (spawn name)', required = true },
                        { type = 'input', label = 'Label', default = 'Vehicule' },
                    })
                    if not input then return end
                    lib.callback.await('acardia_autotransport:createDealerTransfer', false, input[1], input[2], 3500)
                end,
            },
        },
    })
end)

RegisterNetEvent('acardia_autotransport:setupMissionVehicle', function(netId, warpIn)
    CreateThread(function()
        local veh
        for _ = 1, 80 do
            veh = NetworkGetEntityFromNetworkId(netId)
            if veh and veh ~= 0 and DoesEntityExist(veh) then break end
            Wait(50)
        end
        if not veh or veh == 0 then return end

        SetVehicleOnGroundProperly(veh)
        SetVehicleDoorsLocked(veh, 1)
        SetVehicleDoorsLockedForAllPlayers(veh, false)
        SetVehicleDoorsLockedForPlayer(veh, PlayerId(), false)
        SetVehicleNeedsToBeHotwired(veh, false)

        if GetResourceState('qbx_vehiclekeys') == 'started' then
            lib.callback.await('qbx_vehiclekeys:server:giveKeys', false, netId)
        end

        if warpIn then
            Wait(150)
            TaskWarpPedIntoVehicle(cache.ped, veh, -1)
            SetVehicleEngineOn(veh, true, true, false)
        end
    end)
end)

RegisterNetEvent('acardia_autotransport:despawnCompanyVehicle', function(plate, netId)
    if netId then
        local veh = NetworkGetEntityFromNetworkId(netId)
        if veh and veh ~= 0 and DoesEntityExist(veh) then
            DeleteEntity(veh)
        end
    end
end)

AddEventHandler('onResourceStop', function(res)
    if res ~= GetCurrentResourceName() then return end
    if blip then RemoveBlip(blip) end
    if missionPed then DeleteEntity(missionPed) end
end)
