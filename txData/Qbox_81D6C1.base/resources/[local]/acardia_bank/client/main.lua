local tabletOpen = false
local atmOpen = false

local function closeAll()
    tabletOpen = false
    atmOpen = false
    SetNuiFocus(false, false)
    SendNUIMessage({ action = 'close' })
end

local function openTablet(canCreate, bankLabel)
    if tabletOpen or atmOpen then return end
    local data = lib.callback.await('acardia_bank:openTablet', false, canCreate)
    if not data then
        lib.notify({ description = 'Impossible d ouvrir la banque.', type = 'error' })
        return
    end
    tabletOpen = true
    SetNuiFocus(true, true)
    SendNUIMessage({
        action = 'openTablet',
        bankLabel = bankLabel,
        canCreate = canCreate,
        data = data,
    })
end

local function openAtm()
    if tabletOpen or atmOpen then return end
    local cards = lib.callback.await('acardia_bank:atmCards', false)
    if not cards or #cards == 0 then
        lib.notify({ description = 'Aucune carte bancaire dans l inventaire.', type = 'error' })
        return
    end
    atmOpen = true
    SetNuiFocus(true, true)
    SendNUIMessage({ action = 'openAtm', cards = cards })
end

RegisterNUICallback('close', function(_, cb)
    closeAll()
    cb('ok')
end)

RegisterNUICallback('createAccount', function(data, cb)
    local ok, result = lib.callback.await('acardia_bank:createAccount', false, data and data.slot, data and data.companyName)
    if ok == nil then
        cb({ ok = false, result = 'Erreur serveur' })
        return
    end
    cb({ ok = ok and true or false, result = result })
end)

RegisterNUICallback('accountDetails', function(data, cb)
    local result = lib.callback.await('acardia_bank:accountDetails', false, data and data.accountId)
    cb(result)
end)

RegisterNUICallback('createCard', function(data, cb)
    local ok, result = lib.callback.await('acardia_bank:createCard', false, data)
    cb({ ok = ok, result = result })
end)

RegisterNUICallback('updateCard', function(data, cb)
    local ok, result = lib.callback.await('acardia_bank:updateCard', false, data)
    cb({ ok = ok, result = result })
end)

RegisterNUICallback('reportStolen', function(data, cb)
    local ok, result = lib.callback.await('acardia_bank:reportStolen', false, data and data.cardId)
    cb({ ok = ok, result = result })
end)

RegisterNUICallback('deleteCard', function(data, cb)
    local ok, result = lib.callback.await('acardia_bank:deleteCard', false, data and data.cardId)
    cb({ ok = ok, result = result })
end)

RegisterNUICallback('deposit', function(data, cb)
    local ok, result = lib.callback.await('acardia_bank:deposit', false, data and data.accountId, data and data.amount)
    cb({ ok = ok, result = result })
end)

RegisterNUICallback('withdraw', function(data, cb)
    local ok, result = lib.callback.await('acardia_bank:withdraw', false, data and data.accountId, data and data.amount)
    cb({ ok = ok, result = result })
end)

RegisterNUICallback('transfer', function(data, cb)
    local ok, result = lib.callback.await('acardia_bank:transfer', false, data)
    cb({ ok = ok, result = result })
end)

RegisterNUICallback('atmPin', function(data, cb)
    local ok, result = lib.callback.await('acardia_bank:atmPin', false, data and data.cardId, data and data.pin)
    cb({ ok = ok, result = result })
end)

RegisterNUICallback('atmDeposit', function(data, cb)
    local ok, result = lib.callback.await('acardia_bank:atmDeposit', false, data and data.cardId, data and data.amount)
    cb({ ok = ok, result = result })
end)

RegisterNUICallback('atmWithdraw', function(data, cb)
    local ok, result = lib.callback.await('acardia_bank:atmWithdraw', false, data and data.cardId, data and data.amount)
    cb({ ok = ok, result = result })
end)

CreateThread(function()
    local blip = AddBlipForCoord(241.73, 220.71, 106.29)
    SetBlipSprite(blip, 108)
    SetBlipColour(blip, 27)
    SetBlipScale(blip, 0.85)
    SetBlipAsShortRange(blip, true)
    BeginTextCommandSetBlipName('STRING')
    AddTextComponentSubstringPlayerName('Pacific Standard Bank')
    EndTextCommandSetBlipName(blip)
end)

CreateThread(function()
    while GetResourceState('ox_target') ~= 'started' do
        Wait(200)
    end

    for i = 1, #Config.Banks do
        local bank = Config.Banks[i]
        for z = 1, #bank.zones do
            local zone = bank.zones[z]
            exports.ox_target:addBoxZone({
                name = ('acardia_bank_%s_%s'):format(bank.id, z),
                coords = zone.coords,
                size = zone.size,
                rotation = zone.rotation,
                debug = false,
                options = {
                    {
                        name = 'acardia_bank_open',
                        icon = 'fa-solid fa-building-columns',
                        label = bank.canCreate and 'Ouvrir la tablette Acardia Bank' or 'Guichet Acardia Bank',
                        distance = 2.2,
                        onSelect = function()
                            openTablet(bank.canCreate == true, bank.label)
                        end,
                    },
                },
            })
        end
    end

    exports.ox_target:addModel(Config.AtmModels, {
        {
            name = 'acardia_atm',
            icon = 'fa-solid fa-credit-card',
            label = 'Inserer une carte bancaire',
            distance = 1.6,
            onSelect = function()
                openAtm()
            end,
        },
    })
end)

AddEventHandler('onResourceStop', function(res)
    if res ~= GetCurrentResourceName() then return end
    closeAll()
end)
