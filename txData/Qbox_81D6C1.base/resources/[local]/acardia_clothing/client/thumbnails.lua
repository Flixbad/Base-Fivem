Thumbnails = {}

local thumbCache = {}
local queue = {}
local processing = false
local thumbPed = nil
local thumbCam = nil
local savedShopCamActive = false

local function getGender()
    local model = GetEntityModel(cache.ped)
    if model == `mp_f_freemode_01` then
        return 'female'
    end
    return 'male'
end

local function thumbKey(categoryId, drawable, texture)
    return ('%s:%s:%s:%s'):format(getGender(), categoryId, drawable, texture or 0)
end

local function getCategoryById(id)
    for i = 1, #Config.Categories do
        if Config.Categories[i].id == id then
            return Config.Categories[i]
        end
    end
end

local function getStaticUrl(categoryId, drawable, texture)
    return ('nui://%s/html/thumbnails/%s/%s/%s_%s.webp'):format(
        GetCurrentResourceName(),
        getGender(),
        categoryId,
        drawable,
        texture or 0
    )
end

local function staticFileExists(categoryId, drawable, texture)
    local path = ('html/thumbnails/%s/%s/%s_%s.webp'):format(
        getGender(),
        categoryId,
        drawable,
        texture or 0
    )
    return LoadResourceFile(GetCurrentResourceName(), path) ~= nil
end

local function getAutoShotUrl(category, drawable, texture)
    if GetResourceState('uz_AutoShot') ~= 'started' then
        return nil
    end
    if not category then return nil end

    local gender = getGender()
    local tex = texture or 0
    local format = 'png'

    pcall(function()
        format = exports['uz_AutoShot']:getPhotoFormat() or 'png'
    end)

    local ok, url = pcall(function()
        if category.type == 'component' then
            local id = category.componentId
            -- Capture par defaut : fichier {drawable}.png (sans _0)
            if tex == 0 then
                return ('https://cfx-nui-uz_AutoShot/shots/%s/%d/%d.%s'):format(gender, id, drawable, format)
            end
            return exports['uz_AutoShot']:getPhotoURL(gender, 'component', id, drawable, tex)
        end

        local id = category.propId
        if tex == 0 then
            return ('https://cfx-nui-uz_AutoShot/shots/%s/prop_%d/%d.%s'):format(gender, id, drawable, format)
        end
        return exports['uz_AutoShot']:getPhotoURL(gender, 'prop', id, drawable, tex)
    end)

    if ok and type(url) == 'string' and url ~= '' then
        return url
    end
    return nil
end

--- Retourne une URL uniquement si l'image existe vraiment (jamais de 404).
function Thumbnails.resolveUrl(categoryId, drawable, texture)
    local category = getCategoryById(categoryId)
    if not category then return nil end

    local key = thumbKey(categoryId, drawable, texture)
    if thumbCache[key] then
        return thumbCache[key]
    end

    local autoShot = getAutoShotUrl(category, drawable, texture)
    if autoShot then
        thumbCache[key] = autoShot
        return autoShot
    end

    if Config.Thumbnails.useStaticFiles and staticFileExists(categoryId, drawable, texture) then
        local url = getStaticUrl(categoryId, drawable, texture)
        thumbCache[key] = url
        return url
    end

    return nil
end

local function applyPiece(ped, category, drawable, texture)
    texture = texture or 0
    if category.type == 'component' then
        exports['illenium-appearance']:setPedComponent(ped, {
            component_id = category.componentId,
            drawable = drawable,
            texture = texture,
        })
    elseif drawable == -1 then
        ClearPedProp(ped, category.propId)
    else
        exports['illenium-appearance']:setPedProp(ped, {
            prop_id = category.propId,
            drawable = drawable,
            texture = texture,
        })
    end
end

local function canCapture()
    if not Config.Thumbnails.runtimeCapture then
        return false
    end
    return GetResourceState('screencapture') == 'started'
        or GetResourceState('screenshot-basic') == 'started'
end

local function requestCapture(cb)
    local opts = {
        encoding = 'webp',
        maxWidth = Config.Thumbnails.captureSize or 128,
        maxHeight = Config.Thumbnails.captureSize or 128,
    }

    if GetResourceState('screencapture') == 'started' then
        exports.screencapture:requestScreenshot(opts, cb)
        return
    end

    if GetResourceState('screenshot-basic') == 'started' then
        exports['screenshot-basic']:requestScreenshot({ encoding = 'jpg' }, cb)
        return
    end

    cb(nil)
end

local camOffsets = {
    mask = { dist = 1.2, height = 0.65, look = 0.65 },
    hat = { dist = 1.2, height = 0.75, look = 0.70 },
    glasses = { dist = 1.15, height = 0.68, look = 0.65 },
    ear = { dist = 1.15, height = 0.68, look = 0.65 },
    shirt = { dist = 1.35, height = 0.35, look = 0.30 },
    torso = { dist = 1.35, height = 0.35, look = 0.30 },
    pants = { dist = 1.45, height = -0.10, look = -0.20 },
    shoes = { dist = 1.5, height = -0.45, look = -0.55 },
    bag = { dist = 1.4, height = 0.25, look = 0.20 },
    vest = { dist = 1.35, height = 0.35, look = 0.30 },
    accessory = { dist = 1.3, height = 0.45, look = 0.40 },
    decals = { dist = 1.35, height = 0.35, look = 0.30 },
    watch = { dist = 1.2, height = 0.05, look = 0.0 },
    bracelet = { dist = 1.2, height = 0.05, look = 0.0 },
}

local function ensureStudio()
    if thumbPed and DoesEntityExist(thumbPed) then
        return true
    end

    local sourcePed = cache.ped
    local model = GetEntityModel(sourcePed)
    lib.requestModel(model)

    local coords = GetEntityCoords(sourcePed)
    local heading = GetEntityHeading(sourcePed)
    local studio = Config.Thumbnails.studioOffset

    thumbPed = CreatePed(0, model, coords.x + studio.x, coords.y + studio.y, coords.z + studio.z, heading, false, true)
    if not thumbPed or thumbPed == 0 then
        return false
    end

    SetEntityInvincible(thumbPed, true)
    FreezeEntityPosition(thumbPed, true)
    SetEntityCollision(thumbPed, false, false)
    SetBlockingOfNonTemporaryEvents(thumbPed, true)
    SetPedCanRagdoll(thumbPed, false)

    local appearance = exports['illenium-appearance']:getPedAppearance(sourcePed)
    exports['illenium-appearance']:setPedAppearance(thumbPed, appearance)

    local off = { dist = 1.35, height = 0.35, look = 0.30 }
    local rad = math.rad(heading)
    thumbCam = CreateCam('DEFAULT_SCRIPTED_CAMERA', true)
    SetCamCoord(thumbCam,
        coords.x + studio.x - math.sin(rad) * off.dist,
        coords.y + studio.y + math.cos(rad) * off.dist,
        coords.z + studio.z + off.height
    )
    PointCamAtCoord(thumbCam, coords.x + studio.x, coords.y + studio.y, coords.z + studio.z + off.look)
    SetCamFov(thumbCam, 32.0)

    return true
end

local function aimThumbCam(ped, categoryId)
    if not thumbCam then return end
    local coords = GetEntityCoords(ped)
    local heading = GetEntityHeading(ped)
    local o = camOffsets[categoryId] or { dist = 1.35, height = 0.35, look = 0.30 }
    local rad = math.rad(heading)
    SetCamCoord(thumbCam,
        coords.x - math.sin(rad) * o.dist,
        coords.y + math.cos(rad) * o.dist,
        coords.z + o.height
    )
    PointCamAtCoord(thumbCam, coords.x, coords.y, coords.z + o.look)
end

local function activateThumbCam()
    savedShopCamActive = ClothingCam.isOpen()
    if savedShopCamActive then
        RenderScriptCams(false, false, 0, true, true)
    end
    SetCamActive(thumbCam, true)
    RenderScriptCams(true, false, 0, true, true)
end

local function restoreShopCam()
    RenderScriptCams(false, false, 0, true, true)
    if thumbCam then
        SetCamActive(thumbCam, false)
    end
    if savedShopCamActive then
        ClothingCam.reactivate()
    end
end

local function pushResults(results)
    if not results or not next(results) then return end
    SendNUIMessage({
        action = 'thumbnails',
        images = results,
    })
end

local function processQueue()
    if processing or #queue == 0 or not canCapture() then
        return
    end

    processing = true

    CreateThread(function()
        if not ensureStudio() then
            processing = false
            return
        end

        activateThumbCam()

        while #queue > 0 do
            local batch = {}
            for _ = 1, math.min(2, #queue) do
                batch[#batch + 1] = table.remove(queue, 1)
            end

            local results = {}

            for i = 1, #batch do
                local job = batch[i]
                local category = getCategoryById(job.categoryId)
                if category then
                    local key = thumbKey(job.categoryId, job.drawable, job.texture)
                    if not thumbCache[key] then
                        aimThumbCam(thumbPed, job.categoryId)
                        applyPiece(thumbPed, category, job.drawable, job.texture)
                        Wait(100)

                        local captured = nil
                        local done = false
                        requestCapture(function(data)
                            captured = data
                            done = true
                        end)

                        local timeout = GetGameTimer() + 3000
                        while not done and GetGameTimer() < timeout do
                            Wait(10)
                        end

                        if captured then
                            thumbCache[key] = captured
                            results[key] = captured
                        end
                    end
                end
            end

            pushResults(results)
            Wait(Config.Thumbnails.captureDelay or 80)
        end

        restoreShopCam()
        processing = false
    end)
end

function Thumbnails.enqueue(categoryId, drawable, texture)
    local key = thumbKey(categoryId, drawable, texture)
    if thumbCache[key] then
        return thumbCache[key]
    end

    local existing = Thumbnails.resolveUrl(categoryId, drawable, texture)
    if existing then
        return existing
    end

    if not canCapture() then
        return nil
    end

    for i = 1, #queue do
        local q = queue[i]
        if q.categoryId == categoryId and q.drawable == drawable and (q.texture or 0) == (texture or 0) then
            return nil
        end
    end

    queue[#queue + 1] = {
        categoryId = categoryId,
        drawable = drawable,
        texture = texture or 0,
    }

    processQueue()
    return nil
end

function Thumbnails.requestBatch(items)
    if not items then return end

    local resolved = {}
    for i = 1, #items do
        local item = items[i]
        local url = Thumbnails.resolveUrl(item.categoryId, item.drawable, item.texture)
        if url then
            resolved[thumbKey(item.categoryId, item.drawable, item.texture)] = url
        else
            Thumbnails.enqueue(item.categoryId, item.drawable, item.texture)
        end
    end

    if next(resolved) then
        pushResults(resolved)
    end
end

function Thumbnails.destroy()
    queue = {}
    processing = false

    if thumbCam then
        DestroyCam(thumbCam, false)
        thumbCam = nil
    end

    if thumbPed and DoesEntityExist(thumbPed) then
        DeleteEntity(thumbPed)
        thumbPed = nil
    end
end

function Thumbnails.enrichCatalog(category, items)
    for i = 1, #items do
        local item = items[i]
        item.thumbKey = thumbKey(category.id, item.drawable, item.texture or 0)
        -- Uniquement une URL réelle (jamais de chemin fantôme)
        item.image = Thumbnails.resolveUrl(category.id, item.drawable, item.texture or 0)
    end
    return items
end
