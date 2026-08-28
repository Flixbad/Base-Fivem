return {
    visibilityDistance = 10,
    openKey = 'HOME',
    toggle = true, -- If true, scoreboard will open/close on button press. If false, scoreboard stays open as long as button is held down.

    maxPlayers = GetConvarInt('sv_maxclients', 48), -- It returns 48 if it cant find the Convar Int

    -- Allows or disallows the viewing of Player IDs when having the scoreboard open.
    -- If set to 'admin_only', only admins can see player IDs.
    -- If set to 'admin_excluded', all players will see player IDs except for those of admins.
    -- If set to 'all', all players will see player IDs.
    idVisibility = 'admin_only',
}
