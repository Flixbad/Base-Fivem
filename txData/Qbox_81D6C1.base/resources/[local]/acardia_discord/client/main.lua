local maxPlayers = GlobalState.MaxPlayers or 48

---@return string
local function getCharName()
    local data = QBX and QBX.PlayerData
    if data and data.charinfo then
        return ('%s %s'):format(data.charinfo.firstname or '', data.charinfo.lastname or '')
    end
    return 'Citoyen de Los Santos'
end

---@return string
local function getJobLabel()
    local data = QBX and QBX.PlayerData
    if data and data.job and data.job.label then
        return data.job.label
    end
    return 'Sans emploi'
end

---@return string
local function getStreetName()
    local coords = GetEntityCoords(cache.ped)
    local street = GetStreetNameFromHashKey(GetStreetNameAtCoord(coords.x, coords.y, coords.z))
    local zone = GetLabelText(GetNameOfZone(coords.x, coords.y, coords.z))
    if zone and zone ~= 'NULL' and zone ~= '' then
        return ('%s, %s'):format(street, zone)
    end
    return street
end

---@param template string
---@return string
local function render(template)
    local players = GlobalState.PlayerCount or 0
    return (template:gsub('{(%w+)}', {
        charName = getCharName(),
        job = getJobLabel(),
        street = getStreetName(),
        players = tostring(players),
        maxPlayers = tostring(maxPlayers),
        id = tostring(GetPlayerServerId(PlayerId())),
    }))
end

local function setupPresence()
    if not Config.AppId or Config.AppId == '' then
        lib.print.warn('[acardia_discord] Config.AppId manquant — voir config.lua et README')
        return false
    end

    SetDiscordAppId(Config.AppId)

    if Config.Assets.large then
        SetDiscordRichPresenceAsset(Config.Assets.large.key)
        SetDiscordRichPresenceAssetText(
            (Config.Assets.large.text or Config.ServerName):gsub('{(%w+)}', {
                players = tostring(GlobalState.PlayerCount or 0),
                maxPlayers = tostring(maxPlayers),
            })
        )
    end

    if Config.Assets.small then
        SetDiscordRichPresenceAssetSmall(Config.Assets.small.key)
        SetDiscordRichPresenceAssetSmallText(
            render(Config.Assets.small.text or '{players}/{maxPlayers} joueurs')
        )
    end

    for i = 1, math.min(#Config.Buttons, 2) do
        local btn = Config.Buttons[i]
        if btn.label and btn.url and btn.url ~= '' then
            SetDiscordRichPresenceAction(i - 1, btn.label, btn.url)
        end
    end

    return true
end

CreateThread(function()
    if not setupPresence() then return end

    local last = ''
    while true do
        local line = render(Config.RichPresence)
        if line:find('{charName}') and getCharName() == 'Citoyen de Los Santos' then
            line = render(Config.RichPresenceFallback)
        end

        if line ~= last then
            last = line
            SetRichPresence(line)
        end

        if Config.Assets.small then
            SetDiscordRichPresenceAssetSmallText(
                render(Config.Assets.small.text or '{players}/{maxPlayers} joueurs')
            )
        end

        Wait(math.max(Config.UpdateInterval or 12000, 5000))
    end
end)

RegisterNetEvent('QBCore:Client:OnPlayerLoaded', function()
    Wait(2000)
    SetRichPresence(render(Config.RichPresence))
end)

RegisterNetEvent('QBCore:Client:OnJobUpdate', function()
    SetRichPresence(render(Config.RichPresence))
end)
