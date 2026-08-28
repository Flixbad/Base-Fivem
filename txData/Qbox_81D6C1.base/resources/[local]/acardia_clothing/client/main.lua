local shopOpen = false
local originalAppearance = nil
local currentCategory = nil
local currentSelection = nil
--- Pieces modifiees en session (pas encore achetees en tenue)
--- [categoryId] = { categoryId, drawable, texture, component?, prop? }
local pendingChanges = {}

local function getCategoryById(id)
    for i = 1, #Config.Categories do
        if Config.Categories[i].id == id then
            return Config.Categories[i]
        end
    end
end

local function countPending()
    local n = 0
    for _ in pairs(pendingChanges) do
        n = n + 1
    end
    return n
end

local function getPendingList()
    local list = {}
    for _, piece in pairs(pendingChanges) do
        list[#list + 1] = piece
    end
    return list
end

local function registerPending(category, drawable, texture)
    if not category then return end
    texture = texture or 0

    local piece = {
        categoryId = category.id,
        drawable = drawable,
        texture = texture,
    }

    if category.type == 'component' then
        piece.component = category.componentId
        -- Comparer a l'original pour savoir si c'est vraiment un changement
        if originalAppearance and originalAppearance.components then
            for i = 1, #originalAppearance.components do
                local c = originalAppearance.components[i]
                if c.component_id == category.componentId then
                    if c.drawable == drawable and (c.texture or 0) == texture then
                        pendingChanges[category.id] = nil
                        return countPending()
                    end
                    break
                end
            end
        end
    else
        piece.prop = category.propId
        if originalAppearance and originalAppearance.props then
            for i = 1, #originalAppearance.props do
                local p = originalAppearance.props[i]
                if p.prop_id == category.propId then
                    if p.drawable == drawable and (p.texture or 0) == texture then
                        pendingChanges[category.id] = nil
                        return countPending()
                    end
                    break
                end
            end
        end
    end

    pendingChanges[category.id] = piece
    return countPending()
end

local function clearPending()
    pendingChanges = {}
end

local function buildCatalog(category)
    local ped = cache.ped
    local items = {}
    local price = Config.ItemPrice

    if category.type == 'component' then
        local max = GetNumberOfPedDrawableVariations(ped, category.componentId) - 1
        for drawable = 0, max do
            items[#items + 1] = {
                drawable = drawable,
                texture = 0,
                textureCount = GetNumberOfPedTextureVariations(ped, category.componentId, drawable),
                price = price,
                id = drawable,
            }
        end
    else
        local max = GetNumberOfPedPropDrawableVariations(ped, category.propId) - 1
        for drawable = 0, max do
            items[#items + 1] = {
                drawable = drawable,
                texture = 0,
                textureCount = GetNumberOfPedPropTextureVariations(ped, category.propId, drawable),
                price = price,
                id = drawable,
            }
        end
    end

    return Thumbnails.enrichCatalog(category, items)
end

local function applyPreview(category, drawable, texture)
    local ped = cache.ped
    texture = texture or 0

    if category.type == 'component' then
        exports['illenium-appearance']:setPedComponent(ped, {
            component_id = category.componentId,
            drawable = drawable,
            texture = texture,
        })
    else
        if drawable == -1 then
            ClearPedProp(ped, category.propId)
        else
            exports['illenium-appearance']:setPedProp(ped, {
                prop_id = category.propId,
                drawable = drawable,
                texture = texture,
            })
        end
    end
end

local function restoreAppearance()
    if originalAppearance then
        exports['illenium-appearance']:setPedAppearance(cache.ped, originalAppearance)
    end
end

local function getCurrentAppearance()
    return exports['illenium-appearance']:getPedAppearance(cache.ped)
end

local function persistAppearance(appearance)
    TriggerServerEvent('illenium-appearance:server:saveAppearance', appearance)
end

local function closeShop(restore)
    if not shopOpen then return end
    shopOpen = false
    currentCategory = nil
    currentSelection = nil
    clearPending()

    if restore then
        restoreAppearance()
    end

    ClothingCam.stop()
    Thumbnails.destroy()
    FreezeEntityPosition(cache.ped, false)
    ClearPedTasksImmediately(cache.ped)
    SetEntityInvincible(cache.ped, false)
    DisplayRadar(true)
    SetNuiFocus(false, false)
    SendNUIMessage({ action = 'close' })
end

local function openShop(label)
    if shopOpen then return end

    shopOpen = true
    clearPending()
    originalAppearance = getCurrentAppearance()

    local ped = cache.ped
    SetEntityInvincible(ped, true)
    FreezeEntityPosition(ped, true)
    TaskStandStill(ped, -1)
    DisplayRadar(false)

    ClothingCam.start(ped)

    local defaultCategory = Config.Categories[5] or Config.Categories[1]
    currentCategory = defaultCategory
    local catalog = buildCatalog(defaultCategory)
    ClothingCam.focus(ped, defaultCategory.id)

    SetNuiFocus(true, true)
    SendNUIMessage({
        action = 'open',
        shopLabel = label,
        categories = Config.Categories,
        category = defaultCategory,
        items = catalog,
        gender = GetEntityModel(ped) == `mp_f_freemode_01` and 'female' or 'male',
        prices = {
            item = Config.ItemPrice,
            hanger = Config.HangerPrice,
        },
        outfit = { changes = 0, price = 0 },
    })
end

RegisterNUICallback('close', function(_, cb)
    closeShop(true)
    cb('ok')
end)

RegisterNUICallback('selectCategory', function(data, cb)
    local category = getCategoryById(data.categoryId)
    if not category then cb({ ok = false }) return end

    currentCategory = category
    currentSelection = nil
    local catalog = buildCatalog(category)
    ClothingCam.focus(cache.ped, category.id)

    cb({
        ok = true,
        category = category,
        items = catalog,
        gender = GetEntityModel(cache.ped) == `mp_f_freemode_01` and 'female' or 'male',
    })
end)

RegisterNUICallback('resetLook', function(_, cb)
    restoreAppearance()
    clearPending()
    currentSelection = nil
    cb({ ok = true, changes = 0, price = 0 })
end)

RegisterNUICallback('previewItem', function(data, cb)
    local category = getCategoryById(data.categoryId) or currentCategory
    if not category then cb({ ok = false, changes = 0, price = 0 }) return end

    currentSelection = {
        categoryId = category.id,
        drawable = data.drawable,
        texture = data.texture or 0,
    }

    applyPreview(category, data.drawable, data.texture or 0)
    local changes = registerPending(category, data.drawable, data.texture or 0) or 0
    cb({
        ok = true,
        changes = changes,
        price = changes * Config.ItemPrice,
    })
end)

RegisterNUICallback('rotate', function(data, cb)
    local ped = cache.ped
    if data.view then
        ClothingCam.setView(ped, data.view)
    else
        ClothingCam.rotate(ped, data.delta or 5.0)
    end
    cb('ok')
end)

RegisterNUICallback('buySingle', function(data, cb)
    if not currentSelection then
        cb({ ok = false, msg = 'Selectionnez un article' })
        return
    end

    local ok, msg = lib.callback.await('acardia_clothing:buySingle', false, {
        categoryId = currentSelection.categoryId,
        drawable = currentSelection.drawable,
        texture = currentSelection.texture,
        paymentMethod = data.paymentMethod or 'cash',
        cardId = data.cardId,
        cardPin = data.cardPin,
    })

    if ok then
        persistAppearance(getCurrentAppearance())
        originalAppearance = getCurrentAppearance()
        pendingChanges[currentSelection.categoryId] = nil
        local changes = countPending()
        cb({ ok = true, cash = msg and msg.cash, changes = changes, price = changes * Config.ItemPrice })
    else
        cb({ ok = false, msg = msg or 'Paiement refuse' })
    end
end)

RegisterNUICallback('buyHanger', function(data, cb)
    if not currentSelection then
        cb({ ok = false, msg = 'Selectionnez un article' })
        return
    end

    local ok, msg = lib.callback.await('acardia_clothing:buyHanger', false, {
        categoryId = currentSelection.categoryId,
        drawable = currentSelection.drawable,
        texture = currentSelection.texture,
        paymentMethod = data.paymentMethod or 'cash',
        cardId = data.cardId,
        cardPin = data.cardPin,
    })

    cb({ ok = ok, msg = msg })
end)

RegisterNUICallback('requestThumbnails', function(data, cb)
    Thumbnails.requestBatch(data.items or {})
    cb('ok')
end)

RegisterNUICallback('getPayCards', function(_, cb)
    local cards = {}
    local hasBank = false
    if GetResourceState('acardia_bank') == 'started' then
        cards = lib.callback.await('acardia_bank:atmCards', false) or {}
        hasBank = lib.callback.await('acardia_bank:hasAccount', false) or false
    end
    cb({ cards = cards, hasBank = hasBank })
end)

RegisterNUICallback('getOutfitPrice', function(_, cb)
    local changes = countPending()
    cb({ changes = changes, price = changes * Config.ItemPrice })
end)

RegisterNUICallback('buyOutfit', function(data, cb)
    local pieces = getPendingList()
    if #pieces < 1 then
        cb({ ok = false, msg = 'Aucune modification a acheter' })
        return
    end

    local appearance = getCurrentAppearance()
    local ok, msg = lib.callback.await('acardia_clothing:buyOutfit', false, {
        appearance = appearance,
        original = originalAppearance,
        pieces = pieces,
        outfitName = data.outfitName,
        paymentMethod = data.paymentMethod or 'cash',
        cardId = data.cardId,
        cardPin = data.cardPin,
    })

    if ok then
        persistAppearance(appearance)
        originalAppearance = appearance
        clearPending()
        cb({
            ok = true,
            price = msg and msg.price,
            changes = msg and msg.changes,
            cash = msg and msg.cash,
        })
    else
        cb({ ok = false, msg = msg or 'Paiement refuse' })
    end
end)

RegisterNUICallback('saveOutfit', function(data, cb)
    local appearance = getCurrentAppearance()
    local ok, msg = lib.callback.await('acardia_clothing:saveOutfit', false, {
        name = data.name,
        appearance = appearance,
    })

    if ok then
        persistAppearance(appearance)
        originalAppearance = appearance
        cb({ ok = true, msg = msg })
    else
        cb({ ok = false, msg = msg })
    end
end)

RegisterNUICallback('getOutfits', function(_, cb)
    local outfits = lib.callback.await('illenium-appearance:server:getOutfits', false) or {}
    cb(outfits)
end)

RegisterNetEvent('acardia_clothing:client:triggerSaveOutfit', function(name, appearance)
    TriggerServerEvent('illenium-appearance:server:saveOutfit', name, appearance.model, appearance.components, appearance.props)
    persistAppearance(appearance)
end)

CreateThread(function()
    while GetResourceState('ox_target') ~= 'started' do Wait(200) end

    for i = 1, #Config.Shops do
        local shop = Config.Shops[i]
        exports.ox_target:addBoxZone({
            name = ('acardia_clothing_%s'):format(shop.id),
            coords = shop.coords,
            size = shop.size,
            rotation = shop.rotation,
            debug = false,
            options = {
                {
                    name = ('acardia_clothing_open_%s'):format(shop.id),
                    icon = 'fa-solid fa-shirt',
                    label = ('%s — Parcourir les vetements'):format(shop.label),
                    distance = 2.5,
                    onSelect = function()
                        openShop(shop.label)
                    end,
                },
            },
        })

        local blip = AddBlipForCoord(shop.coords.x, shop.coords.y, shop.coords.z)
        SetBlipSprite(blip, Config.Blip.sprite)
        SetBlipColour(blip, Config.Blip.color)
        SetBlipScale(blip, Config.Blip.scale)
        SetBlipAsShortRange(blip, true)
        BeginTextCommandSetBlipName('STRING')
        AddTextComponentSubstringPlayerName(('%s — %s'):format(Config.Blip.label, shop.label))
        EndTextCommandSetBlipName(blip)
    end
end)

CreateThread(function()
    while true do
        if shopOpen then
            DisableControlAction(0, 1, true)
            DisableControlAction(0, 2, true)
            DisableControlAction(0, 24, true)
            DisableControlAction(0, 25, true)
            Wait(0)
        else
            Wait(500)
        end
    end
end)

AddEventHandler('onResourceStop', function(res)
    if res ~= GetCurrentResourceName() then return end
    closeShop(true)
end)
