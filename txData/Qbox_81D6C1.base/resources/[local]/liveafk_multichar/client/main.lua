local previewCam
local selecting = false
local previewPeds = {} -- { citizenid, ped, seatIndex }
local sofaEntity
local selectedCitizenId = nil
local refreshing = false

local function notify(msg, nType)
    lib.notify({ description = msg, type = nType or 'inform' })
end

local function nui(action, data)
    SendNUIMessage({ action = action, data = data })
end

local function setFocus(state)
    SetNuiFocus(state, state)
    SetNuiFocusKeepInput(false)
end

local function hidePlayerPed()
    local ped = PlayerPedId()
    local h = Config.Apartment.hidden
    SetEntityCoordsNoOffset(ped, h.x, h.y, h.z, false, false, false)
    SetEntityHeading(ped, h.w)
    FreezeEntityPosition(ped, true)
    SetEntityVisible(ped, false, false)
    SetEntityAlpha(ped, 0, false)
    SetEntityCollision(ped, false, false)
    SetEntityInvincible(ped, true)
    SetPlayerControl(cache.playerId, false, 0)
end

local function restorePlayerPed()
    local ped = PlayerPedId()
    ResetEntityAlpha(ped)
    SetEntityVisible(ped, true, false)
    SetEntityCollision(ped, true, true)
    SetEntityInvincible(ped, false)
    FreezeEntityPosition(ped, false)
    SetPlayerControl(cache.playerId, true, 0)
end

local function destroySofa()
    if sofaEntity and DoesEntityExist(sofaEntity) then
        SetEntityAsMissionEntity(sofaEntity, true, true)
        DeleteEntity(sofaEntity)
    end
    sofaEntity = nil
end

local function destroyPreviewPeds()
    for i = 1, #previewPeds do
        local entry = previewPeds[i]
        if entry and entry.ped and DoesEntityExist(entry.ped) then
            SetEntityAsMissionEntity(entry.ped, true, true)
            DeleteEntity(entry.ped)
        end
    end
    previewPeds = {}
end

local function destroyCam()
    if previewCam then
        SetCamActive(previewCam, false)
        DestroyCam(previewCam, true)
        previewCam = nil
    end
    RenderScriptCams(false, false, 500, true, true)
    ClearTimecycleModifier()
    ClearFocus()
    DisplayRadar(true)
end

local function spawnSofa()
    destroySofa()
    local s = Config.Apartment.sofa
    lib.requestModel(s.model, 10000)
    sofaEntity = CreateObject(s.model, s.coords.x, s.coords.y, s.coords.z, false, false, false)
    SetModelAsNoLongerNeeded(s.model)
    if not sofaEntity or sofaEntity == 0 then
        sofaEntity = nil
        return false
    end
    SetEntityHeading(sofaEntity, s.coords.w)
    FreezeEntityPosition(sofaEntity, true)
    SetEntityCollision(sofaEntity, true, true)
    SetEntityAsMissionEntity(sofaEntity, true, true)
    return true
end

local function seatWorldCoords(index)
    local offsets = Config.Apartment.seatOffsets
    local i = math.min(math.max(index, 1), #offsets)
    local off = offsets[i]
    local heading = Config.Apartment.seatHeading

    if sofaEntity and DoesEntityExist(sofaEntity) then
        local pos = GetOffsetFromEntityInWorldCoords(sofaEntity, off.x, off.y, off.z)
        return vec4(pos.x, pos.y, pos.z, heading)
    end

    local s = Config.Apartment.sofa.coords
    return vec4(s.x + off.x, s.y + off.y, s.z + off.z + 1.0, heading)
end

local function applySitPose(ped, seat)
    ClearPedTasksImmediately(ped)
    SetEntityCoordsNoOffset(ped, seat.x, seat.y, seat.z, false, false, false)
    SetEntityHeading(ped, seat.w)
    SetEntityCollision(ped, false, false)
    SetBlockingOfNonTemporaryEvents(ped, true)
    SetPedCanRagdoll(ped, false)
    SetPedFleeAttributes(ped, 0, false)
    SetEntityInvincible(ped, true)
    FreezeEntityPosition(ped, true)

    local dict = 'timetable@ron@ig_3_couch'
    if lib.requestAnimDict(dict) then
        TaskPlayAnim(ped, dict, 'base', 8.0, -8.0, -1, 1, 0.0, false, false, false)
    end
end

local function spawnPreviewPed(citizenId, modelHash, clothing, seatIndex)
    local seat = seatWorldCoords(seatIndex)
    local model = modelHash or `mp_m_freemode_01`
    if type(model) == 'string' then
        model = joaat(model)
    end

    if not IsModelInCdimage(model) or not IsModelValid(model) then
        model = `mp_m_freemode_01`
    end

    lib.requestModel(model, 10000)
    local ped = CreatePed(0, model, seat.x, seat.y, seat.z, seat.w, false, true)
    SetModelAsNoLongerNeeded(model)

    if not ped or ped == 0 or not DoesEntityExist(ped) then
        return nil
    end

    SetEntityAsMissionEntity(ped, true, true)
    SetPedDefaultComponentVariation(ped)
    SetEntityVisible(ped, true, false)
    ResetEntityAlpha(ped)

    if clothing then
        pcall(function()
            local appearance = type(clothing) == 'string' and json.decode(clothing) or clothing
            exports['illenium-appearance']:setPedAppearance(ped, appearance)
        end)
    end

    applySitPose(ped, seat)

    previewPeds[#previewPeds + 1] = {
        citizenid = citizenId,
        ped = ped,
        seatIndex = seatIndex,
    }

    return ped
end

local function findPreviewEntry(citizenId)
    for i = 1, #previewPeds do
        if previewPeds[i].citizenid == citizenId then
            return previewPeds[i]
        end
    end
end

local function pointCamAtSeat(seatIndex, focused)
    local apt = Config.Apartment
    local seat = seatWorldCoords(seatIndex or 2)
    local overview = apt.camOverview

    if not previewCam then
        previewCam = CreateCam('DEFAULT_SCRIPTED_CAMERA', true)
    end

    local camX, camY, camZ
    if focused then
        local dist = apt.camFocusDistance
        local rad = math.rad(seat.w)
        camX = seat.x - math.sin(rad) * dist
        camY = seat.y + math.cos(rad) * dist
        camZ = seat.z + apt.camFocusHeight
    else
        camX, camY, camZ = overview.x, overview.y, overview.z
    end

    SetCamCoord(previewCam, camX, camY, camZ)
    PointCamAtCoord(previewCam, seat.x, seat.y, seat.z + 0.35)
    SetCamFov(previewCam, focused and apt.camFovFocus or apt.camFov)
    SetCamActive(previewCam, true)
    RenderScriptCams(true, true, 600, true, true)
end

local function focusCitizen(citizenId)
    selectedCitizenId = citizenId
    if not citizenId then
        pointCamAtSeat(2, false)
        return
    end
    local entry = findPreviewEntry(citizenId)
    if entry then
        pointCamAtSeat(entry.seatIndex, true)
    else
        pointCamAtSeat(2, false)
    end
end

--- Charge vraiment l'appart : TELEPORTE le joueur dedans (sinon void)
local function loadApartmentScene()
    local apt = Config.Apartment
    local loadAt = apt.load
    local ped = PlayerPedId()

    DisplayRadar(false)
    pcall(function()
        ShutdownLoadingScreen()
        ShutdownLoadingScreenNui()
    end)

    SetEntityVisible(ped, true, false)
    ResetEntityAlpha(ped)
    SetEntityCollision(ped, true, true)
    SetEntityCoordsNoOffset(ped, loadAt.x, loadAt.y, loadAt.z, false, false, false)
    SetEntityHeading(ped, loadAt.w)
    FreezeEntityPosition(ped, true)

    SetFocusPosAndVel(loadAt.x, loadAt.y, loadAt.z, 0.0, 0.0, 0.0)
    RequestCollisionAtCoord(loadAt.x, loadAt.y, loadAt.z)

    local interior = GetInteriorAtCoords(loadAt.x, loadAt.y, loadAt.z)
    if interior and interior ~= 0 then
        PinInteriorInMemory(interior)
        local guard = 0
        while not IsInteriorReady(interior) and guard < 120 do
            Wait(50)
            guard = guard + 1
        end
    end

    local timeout = GetGameTimer() + 6000
    while GetGameTimer() < timeout do
        RequestCollisionAtCoord(loadAt.x, loadAt.y, loadAt.z)
        if HasCollisionLoadedAroundEntity(ped) then
            break
        end
        Wait(50)
    end

    Wait(800)

    spawnSofa()
    Wait(150)
    hidePlayerPed()
end

local function buildCharacterList(characters)
    local list = {}
    for i = 1, #(characters or {}) do
        local ch = characters[i]
        local info = ch.charinfo or {}
        list[#list + 1] = {
            citizenid = ch.citizenid,
            cid = info.cid or i,
            firstname = info.firstname or 'Inconnu',
            lastname = info.lastname or '',
            birthdate = info.birthdate or '',
            gender = tonumber(info.gender) or 0,
            nationality = info.nationality or '',
            job = (ch.job and (ch.job.label or ch.job.name)) or 'Civil',
            cash = ch.money and ch.money.cash or 0,
            bank = ch.money and ch.money.bank or 0,
        }
    end
    return list
end

local function spawnAllPreviews(list)
    destroyPreviewPeds()
    if not sofaEntity or not DoesEntityExist(sofaEntity) then
        spawnSofa()
    end

    local maxSeats = #Config.Apartment.seatOffsets
    for i = 1, math.min(#list, maxSeats) do
        local ch = list[i]
        local clothing, model = nil, nil
        local ok, a, b = pcall(function()
            return lib.callback.await('qbx_core:server:getPreviewPedData', false, ch.citizenid)
        end)
        if ok then
            clothing, model = a, b
        end
        if not model then
            model = (tonumber(ch.gender) == 1) and `mp_f_freemode_01` or `mp_m_freemode_01`
        end
        spawnPreviewPed(ch.citizenid, model, clothing, i)
        Wait(30)
    end

    if list[1] then
        focusCitizen(list[1].citizenid)
    else
        focusCitizen(nil)
    end
end

local function spawnGenderPreview(gender)
    destroyPreviewPeds()
    if not sofaEntity then spawnSofa() end
    local model = gender == 1 and `mp_f_freemode_01` or `mp_m_freemode_01`
    spawnPreviewPed('__create__', model, nil, 2)
    focusCitizen('__create__')
end

local function finishSpawn(coords, firstCharacter)
    DoScreenFadeOut(400)
    while not IsScreenFadedOut() do Wait(0) end

    destroyPreviewPeds()
    destroySofa()
    destroyCam()
    setFocus(false)
    nui('close')
    selecting = false
    selectedCitizenId = nil

    restorePlayerPed()

    SetEntityCoords(cache.ped, coords.x, coords.y, coords.z, false, false, false, false)
    SetEntityHeading(cache.ped, coords.w or 0.0)
    RequestCollisionAtCoord(coords.x, coords.y, coords.z)
    local t = 0
    while not HasCollisionLoadedAroundEntity(cache.ped) and t < 100 do
        Wait(50)
        t = t + 1
    end

    DisplayRadar(true)

    TriggerServerEvent('QBCore:Server:OnPlayerLoaded')
    TriggerEvent('QBCore:Client:OnPlayerLoaded')
    TriggerServerEvent('qb-houses:server:SetInsideMeta', 0, false)
    TriggerServerEvent('qb-apartments:server:SetInsideMeta', 0, 0, false)
    TriggerEvent('qb-weathersync:client:EnableSync')

    Wait(300)
    DoScreenFadeIn(700)

    if firstCharacter then
        Wait(500)
        TriggerEvent('qb-clothes:client:CreateFirstCharacter')
    end

    if NetworkIsInTutorialSession() then
        NetworkEndTutorialSession()
    end
end

local function refreshCharacterUi()
    if refreshing then return end
    refreshing = true

    local characters, amount = lib.callback.await('qbx_core:server:getCharacters', false)
    characters = characters or {}
    amount = amount or 1
    local list = buildCharacterList(characters)

    spawnAllPreviews(list)

    nui('refresh', {
        brand = Config.Brand,
        characters = list,
        maxSlots = amount,
        allowDelete = Config.AllowDelete,
        nationalities = Config.Nationalities,
        dateMin = Config.DateMin,
        dateMax = Config.DateMax,
    })

    refreshing = false
end

local function openSelector()
    if selecting then return end
    selecting = true

    if not NetworkIsInTutorialSession() then
        NetworkStartSoloTutorialSession()
    end

    pcall(function() exports.spawnmanager:setAutoSpawn(false) end)

    DoScreenFadeOut(200)
    while not IsScreenFadedOut() do Wait(0) end

    loadApartmentScene()

    local characters, amount = lib.callback.await('qbx_core:server:getCharacters', false)
    characters = characters or {}
    amount = amount or 1
    local list = buildCharacterList(characters)

    spawnAllPreviews(list)

    setFocus(true)
    nui('open', {
        brand = Config.Brand,
        characters = list,
        maxSlots = amount,
        allowDelete = Config.AllowDelete,
        nationalities = Config.Nationalities,
        dateMin = Config.DateMin,
        dateMax = Config.DateMax,
    })

    Wait(250)
    DoScreenFadeIn(700)
end

RegisterNUICallback('close', function(_, cb)
    cb(1)
end)

RegisterNUICallback('preview', function(data, cb)
    focusCitizen(data and data.citizenid or nil)
    cb(1)
end)

RegisterNUICallback('previewGender', function(data, cb)
    cb(1)
    CreateThread(function()
        spawnGenderPreview(tonumber(data and data.gender) or 0)
    end)
end)

RegisterNUICallback('backToSelect', function(data, cb)
    cb(1)
    CreateThread(function()
        refreshCharacterUi()
        if data and data.citizenid then
            focusCitizen(data.citizenid)
        end
    end)
end)

RegisterNUICallback('play', function(data, cb)
    cb(1)
    CreateThread(function()
        local citizenid = data and data.citizenid
        if not citizenid then return end

        DoScreenFadeOut(400)
        lib.callback.await('qbx_core:server:loadCharacter', false, citizenid)
        Wait(750)

        local coords = Config.MandatorySpawn
        if Config.UseLastLocation then
            local pdata = exports.qbx_core:GetPlayerData()
            if pdata and pdata.position and pdata.position.x then
                local pos = pdata.position
                coords = vec4(pos.x + 0.0, pos.y + 0.0, pos.z + 0.0, (pos.w or pos.a or 0.0) + 0.0)
            end
        end

        finishSpawn(coords, false)
    end)
end)

RegisterNUICallback('create', function(data, cb)
    data = data or {}
    local firstname = tostring(data.firstname or ''):gsub('^%s+', ''):gsub('%s+$', '')
    local lastname = tostring(data.lastname or ''):gsub('^%s+', ''):gsub('%s+$', '')
    local nationality = tostring(data.nationality or 'Francaise')
    local birthdate = tostring(data.birthdate or '')
    local gender = tonumber(data.gender) or 0

    if firstname == '' or lastname == '' or birthdate == '' then
        cb({ ok = false, error = 'Remplis tous les champs.' })
        return
    end

    cb({ ok = true })

    CreateThread(function()
        DoScreenFadeOut(400)
        local newData = lib.callback.await('qbx_core:server:createCharacter', false, {
            firstname = firstname,
            lastname = lastname,
            nationality = nationality,
            gender = gender,
            birthdate = birthdate,
            cid = 1,
        })

        if not newData then
            DoScreenFadeIn(400)
            notify('Creation impossible (slots pleins ou donnees invalides).', 'error')
            return
        end

        finishSpawn(Config.MandatorySpawn, true)
    end)
end)

-- Suppression: attendre le resultat puis repondre au NUI (plus de confirm natif cote JS)
RegisterNUICallback('delete', function(data, cb)
    local citizenid = data and data.citizenid
    if not citizenid or not Config.AllowDelete then
        cb({ ok = false, error = 'Suppression refusee.' })
        return
    end

    local ok = lib.callback.await('liveafk_multichar:deleteCharacter', false, citizenid)
    if not ok then
        ok = lib.callback.await('qbx_core:server:deleteCharacter', false, citizenid)
    end

    if not ok then
        cb({ ok = false, error = 'Impossible de supprimer ce personnage.' })
        return
    end

    local characters, amount = lib.callback.await('qbx_core:server:getCharacters', false)
    characters = characters or {}
    amount = amount or 1
    local list = buildCharacterList(characters)

    destroyPreviewPeds()
    spawnAllPreviews(list)

    local payload = {
        brand = Config.Brand,
        characters = list,
        maxSlots = amount,
        allowDelete = Config.AllowDelete,
        nationalities = Config.Nationalities,
        dateMin = Config.DateMin,
        dateMax = Config.DateMax,
    }
    nui('refresh', payload)

    cb({ ok = true, characters = list, maxSlots = amount })
end)

RegisterNetEvent('qbx_core:client:playerLoggedOut', function()
    if GetInvokingResource() then return end
    selecting = false
    openSelector()
end)

CreateThread(function()
    while true do
        Wait(0)
        if NetworkIsSessionStarted() then
            Wait(500)
            if GetResourceState('liveafk_loadingscreen') == 'started' then
                Wait(1200)
            end
            openSelector()
            break
        end
    end

    while NetworkIsInTutorialSession() do
        SetEntityInvincible(PlayerPedId(), true)
        Wait(250)
    end
end)

AddEventHandler('onResourceStop', function(res)
    if res ~= GetCurrentResourceName() then return end
    destroyPreviewPeds()
    destroySofa()
    destroyCam()
    restorePlayerPed()
    setFocus(false)
end)
