local open = false
local cooldownUntil = 0

local function nui(action, data)
    SendNUIMessage({ action = action, data = data or {} })
end

local function setFocus(state)
    SetNuiFocus(state, state)
    SetNuiFocusKeepInput(false)
end

local function getPlayerPayload()
    local pdata = {}
    pcall(function()
        pdata = exports.qbx_core:GetPlayerData() or {}
    end)

    local info = pdata.charinfo or {}
    local job = pdata.job or {}
    local money = pdata.money or {}

    local first = info.firstname or ''
    local last = info.lastname or ''
    local name = (first .. ' ' .. last):gsub('^%s+', ''):gsub('%s+$', '')
    if name == '' then name = GetPlayerName(PlayerId()) or 'Citoyen' end

    return {
        name = name,
        citizenid = pdata.citizenid or '—',
        job = job.label or job.name or 'Civil',
        grade = (job.grade and (job.grade.name or job.grade.level)) or '',
        cash = money.cash or 0,
        bank = money.bank or 0,
        serverId = GetPlayerServerId(PlayerId()),
    }
end

local function closePause()
    if not open then
        setFocus(false)
        nui('close')
        return
    end
    open = false
    setFocus(false)
    nui('close')
    SetTimecycleModifierStrength(0.0)
    ClearTimecycleModifier()
    DisplayRadar(true)
    cooldownUntil = GetGameTimer() + 400
end

local function openPause()
    if open then return end
    if GetGameTimer() < cooldownUntil then return end
    if IsNuiFocused() then return end
    if IsPauseMenuActive() then return end

    if GetResourceState('liveafk_multichar') == 'started' then
        if NetworkIsInTutorialSession and NetworkIsInTutorialSession() then return end
    end

    open = true
    DisplayRadar(false)
    SetTimecycleModifier('hud_def_blur')
    SetTimecycleModifierStrength(0.45)

    local online = 0
    local ok, result = pcall(function()
        return lib.callback.await('liveafk_pausemenu:getOnline', false)
    end)
    if ok and result then online = result end

    setFocus(true)
    nui('open', {
        brand = Config.Brand,
        actions = Config.Actions,
        player = getPlayerPayload(),
        online = online,
        discord = Config.Discord,
        time = {
            hour = GetClockHours(),
            minute = GetClockMinutes(),
        },
    })
end

local function runAction(id)
    if not id then return end

    closePause()
    cooldownUntil = GetGameTimer() + 800

    CreateThread(function()
        Wait(250)

        if id == 'map' then
            ActivateFrontendMenu(`FE_MENU_VERSION_MP_PAUSE`, false, -1)
        elseif id == 'inventory' then
            if GetResourceState('ox_inventory') == 'started' then
                -- sans argument = tes poches (pas l inventaire d un autre joueur)
                exports.ox_inventory:openInventory()
            else
                lib.notify({ description = 'Inventaire indisponible.', type = 'error' })
            end
        elseif id == 'appearance' then
            if GetResourceState('illenium-appearance') == 'started' then
                TriggerEvent('illenium-appearance:client:openClothingShopMenu', true)
            else
                lib.notify({ description = 'Apparence indisponible.', type = 'error' })
            end
        elseif id == 'settings' then
            ActivateFrontendMenu(`FE_MENU_VERSION_LANDING_MENU`, false, -1)
        elseif id == 'discord' then
            if Config.Discord and Config.Discord ~= '' and Config.Discord ~= 'https://discord.gg/' then
                lib.notify({ description = 'Lien Discord ouvert / copie.', type = 'inform' })
            else
                lib.notify({ description = 'Ajoute ton lien Discord dans config.lua', type = 'error' })
            end
        elseif id == 'disconnect' then
            TriggerServerEvent('liveafk_pausemenu:disconnect')
        end
    end)
end

CreateThread(function()
    while true do
        if open then
            DisableControlAction(0, 199, true)
            DisableControlAction(0, 200, true)
            DisableControlAction(0, 202, true)
            DisableControlAction(0, 177, true)
            SetPauseMenuActive(false)
            Wait(0)
        elseif IsNuiFocused() or IsPauseMenuActive() then
            Wait(200)
        else
            DisableControlAction(0, 200, true)
            DisableControlAction(0, 199, true)

            if GetGameTimer() >= cooldownUntil then
                if IsDisabledControlJustReleased(0, 200) or IsDisabledControlJustReleased(0, 199) then
                    openPause()
                end
            end
            Wait(0)
        end
    end
end)

RegisterNUICallback('close', function(_, cb)
    cb(1)
    closePause()
end)

RegisterNUICallback('action', function(data, cb)
    cb(1)
    runAction(data and data.id)
end)

RegisterCommand('pausemenu', function()
    if open then
        closePause()
    else
        openPause()
    end
end, false)

AddEventHandler('onResourceStop', function(res)
    if res ~= GetCurrentResourceName() then return end
    closePause()
end)
