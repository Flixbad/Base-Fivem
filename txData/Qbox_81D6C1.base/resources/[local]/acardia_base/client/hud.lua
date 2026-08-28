-- HUD + barre info sous la minimap carree

local last = {
    hunger = -1, thirst = -1, energy = -1, armor = -1, health = -1,
    time = '', street = '', zone = '',
    hidden = nil,
}

local function clamp(value)
    value = tonumber(value) or 0
    if value < 0 then return 0 end
    if value > 100 then return 100 end
    return math.floor(value + 0.5)
end

local function getHealth()
    local ped = PlayerPedId()
    local max = GetEntityMaxHealth(ped) - 100
    if max < 1 then return 100 end
    return clamp((GetEntityHealth(ped) - 100) / max * 100)
end

local function getEnergy()
    local ok, stamina = pcall(GetPlayerSprintStaminaRemaining, PlayerId())
    if ok and type(stamina) == 'number' then
        return clamp(stamina)
    end
    return 100
end

local function getLocation()
    local ped = PlayerPedId()
    local coords = GetEntityCoords(ped)
    local streetHash, crossingHash = GetStreetNameAtCoord(coords.x, coords.y, coords.z)
    local streetName = GetStreetNameFromHashKey(streetHash)
    local crossingName = GetStreetNameFromHashKey(crossingHash)

    if crossingName and crossingName ~= '' then
        streetName = streetName .. ' / ' .. crossingName
    end
    if not streetName or streetName == '' then
        streetName = 'Los Santos'
    end

    local zoneHash = GetNameOfZone(coords.x, coords.y, coords.z)
    local zoneName = GetLabelText(zoneHash)
    if not zoneName or zoneName == 'NULL' or zoneName == '' then
        zoneName = zoneHash or 'SAN ANDREAS'
    end

    return streetName, zoneName
end

local function getTime()
    local h = GetClockHours()
    local m = GetClockMinutes()
    return ('%02d:%02d'):format(h, m)
end

local function pushHud(force)
    if IsPauseMenuActive() then
        if last.hidden ~= true then
            SendNUIMessage({ action = 'hud', show = false })
            last.hidden = true
        end
        return
    end

    local hunger = clamp(LocalPlayer.state.hunger or 100)
    local thirst = clamp(LocalPlayer.state.thirst or 100)
    local energy = getEnergy()
    local armor = clamp(GetPedArmour(PlayerPedId()))
    local health = getHealth()
    local time = getTime()
    local streetName, zoneName = getLocation()

    if not force
        and last.hidden == false
        and last.hunger == hunger
        and last.thirst == thirst
        and last.energy == energy
        and last.armor == armor
        and last.health == health
        and last.time == time
        and last.street == streetName
        and last.zone == zoneName
    then
        return
    end

    last.hunger, last.thirst, last.energy, last.armor, last.health = hunger, thirst, energy, armor, health
    last.time, last.street, last.zone = time, streetName, zoneName
    last.hidden = false

    SendNUIMessage({
        action = 'hud',
        show = true,
        time = time,
        street = streetName,
        zone = zoneName,
        hunger = hunger,
        thirst = thirst,
        energy = energy,
        armor = armor,
        health = health,
    })
end

AddEventHandler('hud:client:UpdateNeeds', function()
    pushHud(true)
end)

CreateThread(function()
    Wait(500)
    pushHud(true)
    while true do
        Wait(250)
        pushHud(false)
    end
end)

CreateThread(function()
    Wait(2000)
    local minimap = RequestScaleformMovie('minimap')
    local timeout = GetGameTimer() + 8000
    while not HasScaleformMovieLoaded(minimap) and GetGameTimer() < timeout do
        Wait(100)
    end
    while true do
        if not IsPauseMenuActive() then
            BeginScaleformMovieMethod(minimap, 'SETUP_HEALTH_ARMOUR')
            ScaleformMovieMethodAddParamInt(3)
            EndScaleformMovieMethod()
        end
        Wait(100)
    end
end)
