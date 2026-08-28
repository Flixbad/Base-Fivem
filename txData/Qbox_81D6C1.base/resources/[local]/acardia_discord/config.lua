Config = {}

-- ═══════════════════════════════════════════════════════════════
-- 1. Crée une application sur https://discord.com/developers
-- 2. Nom de l'app : "Acardia RP V2" (c'est ce qui s'affiche dans Discord)
-- 3. Rich Presence > Art Assets > upload assets/acardia_logo.png
--    → nom de l'asset : acardia_logo (512x512 min recommandé)
-- 4. Copie l'Application ID ici :
-- ═══════════════════════════════════════════════════════════════

Config.AppId = '1539714339525759068' -- ⚠️ OBLIGATOIRE : ton Application ID Discord

Config.ServerName = 'Acardia RP V2'
Config.ServerTagline = 'RP immersif · Los Santos'

-- Texte affiché sous le nom du jeu
-- Placeholders : {charName} {job} {street} {players} {maxPlayers} {id}
Config.RichPresence = '{charName} · {job} · {street}'
Config.RichPresenceFallback = 'Exploration de Los Santos · {players}/{maxPlayers}'

Config.UpdateInterval = 12000

Config.Assets = {
    large = {
        key = 'acardia_logo',
        text = 'Acardia RP V2 — Los Santos',
    },
    small = {
        key = 'acardia_logo',
        text = '{players}/{maxPlayers} joueurs',
    },
}

Config.Buttons = {
    {
        label = 'Rejoindre le Discord',
        url = 'https://discord.gg/UE2U2agDxS', -- remplace par ton vrai lien
    },
    {
        label = 'FiveM Connect',
        url = 'https://cfx.re/join/xxxxx', -- remplace par ton lien cfx.re
    },
}
