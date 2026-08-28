-- Ecran de mort Acardia : overlay violet, appels LSMD/BCMD, respawn après 5 min

local RESPAWN_COORDS = vector4(-449.07, -340.94, 34.50, 79.00)

local deathActive = false

local function isDowned()
    if GetResourceState('qbx_medical') ~= 'started' then return false end
    local medical = exports.qbx_medical
    return medical:IsDead() or medical:IsLaststand()
end

local function blockControls()
    DisableAllControlActions(0)
    DisableAllControlActions(1)
    DisableAllControlActions(2)
    DisablePlayerFiring(PlayerId(), true)
    SetPauseMenuActive(false)
end

local function showDeath()
    if deathActive then return end
    deathActive = true

    if GetResourceState('qbx_medical') == 'started' then
        exports.qbx_medical:DisableRespawn()
    end

    SetNuiFocus(true, true)
    SendNUIMessage({ action = 'hud', show = false })
    SendNUIMessage({ action = 'death', show = true })
end

local function hideDeath()
    if not deathActive then return end
    deathActive = false

    SetNuiFocus(false, false)
    SendNUIMessage({ action = 'death', show = false })

    if GetResourceState('qbx_medical') == 'started' then
        exports.qbx_medical:AllowRespawn()
    end
end

local function doRespawn()
    if not deathActive then return end

    local ped = PlayerPedId()

    if GetResourceState('qbx_medical') == 'started' then
        TriggerEvent('qbx_medical:client:playerRevived')
    end

    hideDeath()

    SetEntityCoordsNoOffset(ped, RESPAWN_COORDS.x, RESPAWN_COORDS.y, RESPAWN_COORDS.z, false, false, false)
    SetEntityHeading(ped, RESPAWN_COORDS.w)
    SetEntityInvincible(ped, false)
    SetEntityHealth(ped, GetEntityMaxHealth(ped))
    SetPedArmour(ped, 0)
    ClearPedBloodDamage(ped)
    NetworkResurrectLocalPlayer(RESPAWN_COORDS.x, RESPAWN_COORDS.y, RESPAWN_COORDS.z, RESPAWN_COORDS.w, true, false)
    SetPlayerInvincible(PlayerId(), false)
    ClearPedTasksImmediately(ped)
end

RegisterNUICallback('deathCall', function(data, cb)
    local service = data and data.service
    if service == 'lsmd' then
        exports.qbx_core:Notify('Appel LSMD — liaison à venir', 'inform')
    elseif service == 'bcmd' then
        exports.qbx_core:Notify('Appel BCMD — liaison à venir', 'inform')
    end
    cb('ok')
end)

RegisterNUICallback('deathRespawn', function(_, cb)
    doRespawn()
    cb('ok')
end)

AddEventHandler('qbx_medical:client:onPlayerDied', function()
    showDeath()
end)

AddEventHandler('qbx_medical:client:playerRevived', function()
    hideDeath()
end)

CreateThread(function()
    while GetResourceState('qbx_medical') ~= 'started' do
        Wait(500)
    end

    while true do
        if isDowned() then
            if not deathActive then
                showDeath()
            end
            blockControls()
            Wait(0)
        else
            if deathActive then
                hideDeath()
            end
            Wait(400)
        end
    end
end)
