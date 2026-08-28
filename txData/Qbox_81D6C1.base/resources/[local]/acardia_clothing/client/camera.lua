ClothingCam = {}

local shopCam = nil
local shopOpen = false
local initialHeading = 0.0
local camBaseXY = nil
local currentCategory = 'shirt'

local function getCamOffset(categoryId)
    local offsets = {
        mask = { dist = 2.0, height = 0.65, look = 0.65 },
        hat = { dist = 2.0, height = 0.75, look = 0.70 },
        glasses = { dist = 1.9, height = 0.68, look = 0.65 },
        ear = { dist = 1.9, height = 0.68, look = 0.65 },
        shirt = { dist = 2.2, height = 0.35, look = 0.30 },
        torso = { dist = 2.2, height = 0.35, look = 0.30 },
        pants = { dist = 2.4, height = -0.10, look = -0.20 },
        shoes = { dist = 2.5, height = -0.45, look = -0.55 },
        bag = { dist = 2.3, height = 0.25, look = 0.20 },
        vest = { dist = 2.2, height = 0.35, look = 0.30 },
        accessory = { dist = 2.1, height = 0.45, look = 0.40 },
        decals = { dist = 2.2, height = 0.35, look = 0.30 },
        watch = { dist = 2.0, height = 0.05, look = 0.0 },
        bracelet = { dist = 2.0, height = 0.05, look = 0.0 },
    }
    return offsets[categoryId] or { dist = 2.2, height = 0.25, look = 0.20 }
end

local function applyCameraPosition(ped, categoryId)
    if not shopCam then return end
    local off = getCamOffset(categoryId or currentCategory)
    local coords = GetEntityCoords(ped)

    if not camBaseXY then
        local rad = math.rad(initialHeading)
        camBaseXY = {
            x = coords.x - math.sin(rad) * off.dist,
            y = coords.y + math.cos(rad) * off.dist,
        }
    end

    SetCamCoord(shopCam, camBaseXY.x, camBaseXY.y, coords.z + off.height)
    PointCamAtCoord(shopCam, coords.x, coords.y, coords.z + off.look)
end

function ClothingCam.start(ped)
    shopOpen = true
    initialHeading = GetEntityHeading(ped)
    camBaseXY = nil
    currentCategory = 'shirt'

    shopCam = CreateCam('DEFAULT_SCRIPTED_CAMERA', true)
    applyCameraPosition(ped, currentCategory)
    SetCamActive(shopCam, true)
    RenderScriptCams(true, true, 500, true, true)
end

function ClothingCam.focus(ped, categoryId)
    if categoryId then currentCategory = categoryId end
    applyCameraPosition(ped, currentCategory)
end

function ClothingCam.rotate(ped, delta)
    SetEntityHeading(ped, GetEntityHeading(ped) + (delta or 0))
end

function ClothingCam.setView(ped, view)
    local views = {
        front = initialHeading,
        back = initialHeading + 180.0,
        left = initialHeading + 90.0,
        right = initialHeading - 90.0,
    }
    local heading = views[view]
    if heading then
        SetEntityHeading(ped, heading % 360.0)
    end
end

function ClothingCam.getInitialHeading()
    return initialHeading
end

function ClothingCam.stop()
    shopOpen = false
    camBaseXY = nil
    if shopCam then
        RenderScriptCams(false, true, 500, true, true)
        DestroyCam(shopCam, false)
        shopCam = nil
    end
end

function ClothingCam.isOpen()
    return shopOpen
end

function ClothingCam.reactivate()
    if shopCam then
        SetCamActive(shopCam, true)
        RenderScriptCams(true, false, 0, true, true)
    end
end
