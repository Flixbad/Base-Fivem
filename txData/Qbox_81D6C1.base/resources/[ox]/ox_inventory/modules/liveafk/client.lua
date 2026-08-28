--[[
  Acardia RP V2 — camera inventaire + slots equipement (strip / preview clothing)
]]

local LiveAFK = {}

local cam
local open = false
local baseline = {} -- [id] = { kind, index, drawable, texture }
local stripped = {} -- [id] = true when currently off
local previewBackup = nil

local GEAR = {
    hat = { kind = 'prop', index = 0 },
    mask = { kind = 'component', index = 1 },
    glasses = { kind = 'prop', index = 1 },
    ears = { kind = 'prop', index = 2 },
    chain = { kind = 'component', index = 7 },
    jacket = { kind = 'component', index = 11 },
    vest = { kind = 'component', index = 9 },
    bag = { kind = 'component', index = 5 },
    gloves = { kind = 'component', index = 3 },
    pants = { kind = 'component', index = 4 },
    shoes = { kind = 'component', index = 6 },
    watch = { kind = 'prop', index = 6 },
    bracelet = { kind = 'prop', index = 7 },
}

--- Drawables "nus" approximatifs freemode (homme / femme)
local function bareComponent(ped, component)
    local female = GetEntityModel(ped) == `mp_f_freemode_01`
    local mapMale = {
        [1] = 0, [3] = 15, [4] = 21, [5] = 0, [6] = 34,
        [7] = 0, [8] = 15, [9] = 0, [11] = 15,
    }
    local mapFemale = {
        [1] = 0, [3] = 15, [4] = 15, [5] = 0, [6] = 35,
        [7] = 0, [8] = 15, [9] = 0, [11] = 15,
    }
    local map = female and mapFemale or mapMale
    return map[component] or 0
end

local function readPiece(ped, kind, index)
    if kind == 'prop' then
        return {
            kind = 'prop',
            index = index,
            drawable = GetPedPropIndex(ped, index),
            texture = GetPedPropTextureIndex(ped, index),
        }
    end
    return {
        kind = 'component',
        index = index,
        drawable = GetPedDrawableVariation(ped, index),
        texture = GetPedTextureVariation(ped, index),
    }
end

local function applyPiece(ped, piece)
    if not piece then return end
    if piece.kind == 'prop' then
        if piece.drawable == nil or piece.drawable < 0 then
            ClearPedProp(ped, piece.index)
        else
            SetPedPropIndex(ped, piece.index, piece.drawable, piece.texture or 0, true)
        end
    else
        SetPedComponentVariation(ped, piece.index, piece.drawable or 0, piece.texture or 0, 0)
    end
end

local function captureBaseline(ped)
    baseline = {}
    stripped = {}
    for id, def in pairs(GEAR) do
        baseline[id] = readPiece(ped, def.kind, def.index)
    end
end

local function destroyCam()
    if cam then
        RenderScriptCams(false, true, 350, true, true)
        DestroyCam(cam, false)
        cam = nil
    end
    ClearFocus()
end

local function createCam(ped)
    destroyCam()
    local coords = GetEntityCoords(ped)
    local heading = GetEntityHeading(ped)
    local rad = math.rad(heading)
    local dist = 1.85
    local camX = coords.x - math.sin(rad) * dist
    local camY = coords.y + math.cos(rad) * dist
    local camZ = coords.z + 0.45

    cam = CreateCamWithParams('DEFAULT_SCRIPTED_CAMERA', camX, camY, camZ, 0.0, 0.0, 0.0, 42.0, false, 0)
    PointCamAtEntity(cam, ped, 0.0, 0.0, 0.15, true)
    SetCamActive(cam, true)
    RenderScriptCams(true, true, 400, true, true)
    SetFocusEntity(ped)
end

function LiveAFK.open()
    if open then return end
    open = true

    local ped = PlayerPedId()
    captureBaseline(ped)
    previewBackup = nil

    FreezeEntityPosition(ped, true)
    SetEntityInvincible(ped, true)
    createCam(ped)

    -- petite pose idle
    if not IsPedInAnyVehicle(ped, false) then
        lib.requestAnimDict('amb@world_human_hang_out_street@female_arms_crossed@idle_a')
        TaskPlayAnim(ped, 'amb@world_human_hang_out_street@female_arms_crossed@idle_a', 'idle_a', 4.0, -4.0, -1, 1, 0.0, false, false, false)
    end
end

function LiveAFK.close()
    if not open then return end
    open = false

    local ped = PlayerPedId()
    LiveAFK.clearPreview()

    -- restore any stripped pieces to baseline
    for id, piece in pairs(baseline) do
        if stripped[id] then
            applyPiece(ped, piece)
            stripped[id] = nil
        end
    end

    ClearPedTasks(ped)
    FreezeEntityPosition(ped, false)
    SetEntityInvincible(ped, false)
    destroyCam()
    baseline = {}
end

function LiveAFK.toggle(id, kind, index)
    local ped = PlayerPedId()
    local def = GEAR[id] or { kind = kind, index = index }
    kind = def.kind
    index = def.index

    if not baseline[id] then
        baseline[id] = readPiece(ped, kind, index)
    end

    if stripped[id] then
        applyPiece(ped, baseline[id])
        stripped[id] = nil
        return false
    end

    -- strip
    if kind == 'prop' then
        ClearPedProp(ped, index)
    else
        local bare = bareComponent(ped, index)
        SetPedComponentVariation(ped, index, bare, 0, 0)
        -- torse: aussi undershirt
        if index == 11 then
            SetPedComponentVariation(ped, 8, bareComponent(ped, 8), 0, 0)
        end
    end
    stripped[id] = true
    return true
end

function LiveAFK.preview(metadata)
    if type(metadata) ~= 'table' then return end
    local ped = PlayerPedId()

    if not previewBackup then
        if metadata.prop ~= nil then
            previewBackup = readPiece(ped, 'prop', metadata.prop)
        elseif metadata.component ~= nil then
            previewBackup = readPiece(ped, 'component', metadata.component)
        else
            return
        end
    end

    if metadata.prop ~= nil then
        SetPedPropIndex(ped, metadata.prop, metadata.drawable or 0, metadata.texture or 0, true)
    elseif metadata.component ~= nil then
        SetPedComponentVariation(ped, metadata.component, metadata.drawable or 0, metadata.texture or 0, 0)
    end
end

function LiveAFK.clearPreview()
    if not previewBackup then return end
    applyPiece(PlayerPedId(), previewBackup)
    previewBackup = nil
end

RegisterNUICallback('toggleClothing', function(data, cb)
    LiveAFK.toggle(data and data.id, data and data.kind, data and data.index)
    cb(1)
end)

RegisterNUICallback('previewClothing', function(data, cb)
    LiveAFK.preview(data and data.metadata)
    cb(1)
end)

RegisterNUICallback('clearPreview', function(_, cb)
    LiveAFK.clearPreview()
    cb(1)
end)

RegisterNUICallback('invReady', function(_, cb)
    cb(1)
end)

AddEventHandler('onResourceStop', function(res)
    if res ~= GetCurrentResourceName() then return end
    LiveAFK.close()
end)

return LiveAFK
