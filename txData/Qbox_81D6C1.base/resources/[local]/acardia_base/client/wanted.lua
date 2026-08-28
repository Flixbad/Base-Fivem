-- Bloque les etoiles GTA + dispatch flics / hopital / SWAT natifs

local function disableWanted()
    local playerId = PlayerId()

    SetMaxWantedLevel(0)
    SetWantedLevelMultiplier(0.0)
    SetPoliceIgnorePlayer(playerId, true)
    SetDispatchCopsForPlayer(playerId, false)
    SetPlayerWantedLevel(playerId, 0, false)
    SetPlayerWantedLevelNow(playerId, false)
    ClearPlayerWantedLevel(playerId)
    SetAudioFlag('WantedMusicDisabled', true)

    if GetPlayerWantedLevel(playerId) > 0 then
        ClearPlayerWantedLevel(playerId)
    end
end

CreateThread(function()
    for i = 1, 15 do
        EnableDispatchService(i, false)
    end

    disableWanted()

    while true do
        disableWanted()
        Wait(500)
    end
end)
