-- Ferme le loading screen apres connexion (fade NUI gere cote HTML)
CreateThread(function()
    while not NetworkIsSessionStarted() do
        Wait(100)
    end

    Wait(1500)
    SendLoadingScreenMessage(json.encode({ action = 'fadeOut' }))
    Wait(900)

    ShutdownLoadingScreen()
    ShutdownLoadingScreenNui()
end)
