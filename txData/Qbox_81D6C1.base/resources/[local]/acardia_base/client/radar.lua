-- Position minimap carree : memes natives que qbx_hud (cadre 29vh x 18.5vh)

AcardiaRadar = AcardiaRadar or {}

AcardiaRadar.MAP = {
    x = 0.0,
    y = -0.047,
    w = 0.1638,
    h = 0.183,
    maskX = 0.0,
    maskY = 0.0,
    maskW = 0.128,
    maskH = 0.20,
    blurX = -0.01,
    blurY = 0.025,
    blurW = 0.262,
    blurH = 0.300,
}

function AcardiaRadar.getLeftOffset()
    local resX, resY = GetActiveScreenResolution()
    if resX < 1 or resY < 1 then return 0.0, resX, resY end

    local aspect = resX / resY
    local defaultAspect = 1920 / 1080
    local offset = 0.0

    if aspect > defaultAspect then
        offset = ((defaultAspect - aspect) / 3.6) - 0.008
    elseif aspect < 1.6 then
        offset = 0.012
    end

    return offset, resX, resY
end
