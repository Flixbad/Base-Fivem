-- Minimap carree : la map GTA visible, bordure NUI alignee dessus

local lastResX, lastResY = 0, 0
local loaded = false

local function applyMinimap()
    local map = AcardiaRadar.MAP
    local offset = AcardiaRadar.getLeftOffset()

    DisplayRadar(true)

    RequestStreamedTextureDict('squaremap', false)
    local timeout = GetGameTimer() + 5000
    while not HasStreamedTextureDictLoaded('squaremap') and GetGameTimer() < timeout do
        Wait(10)
    end

    if HasStreamedTextureDictLoaded('squaremap') then
        AddReplaceTexture('platform:/textures/graphics', 'radarmasksm', 'squaremap', 'radarmasksm')
        AddReplaceTexture('platform:/textures/graphics', 'radarmask1g', 'squaremap', 'radarmasksm')
    end

    SetMinimapClipType(0)
    SetMinimapComponentPosition('minimap', 'L', 'B', map.x + offset, map.y, map.w, map.h)
    SetMinimapComponentPosition('minimap_mask', 'L', 'B', map.maskX + offset, map.maskY, map.maskW, map.maskH)
    SetMinimapComponentPosition('minimap_blur', 'L', 'B', map.blurX + offset, map.blurY, map.blurW, map.blurH)

    local north = GetNorthRadarBlip()
    if north and north ~= 0 then
        SetBlipAlpha(north, 0)
    end

    SetMinimapClipType(0)
    SetBigmapActive(true, false)
    Wait(50)
    SetBigmapActive(false, false)

    loaded = true
end

CreateThread(function()
    Wait(800)
    applyMinimap()
    local _, resX, resY = AcardiaRadar.getLeftOffset()
    lastResX, lastResY = resX, resY
end)

RegisterNetEvent('QBCore:Client:OnPlayerLoaded', function()
    Wait(500)
    applyMinimap()
end)

RegisterNetEvent('qbx_core:client:playerLoaded', function()
    Wait(500)
    applyMinimap()
end)

AddEventHandler('onResourceStop', function(res)
    if res ~= GetCurrentResourceName() then return end
    pcall(RemoveReplaceTexture, 'platform:/textures/graphics', 'radarmasksm')
    pcall(RemoveReplaceTexture, 'platform:/textures/graphics', 'radarmask1g')
end)

CreateThread(function()
    while true do
        Wait(2000)
        if loaded then
            local _, resX, resY = AcardiaRadar.getLeftOffset()
            if resX ~= lastResX or resY ~= lastResY then
                lastResX, lastResY = resX, resY
                applyMinimap()
            end
        end
    end
end)
