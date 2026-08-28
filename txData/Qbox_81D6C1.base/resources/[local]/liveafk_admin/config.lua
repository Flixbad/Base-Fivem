Config = {}

Config.OpenKey = 'F10'
Config.Command = 'admintablet'
Config.ReportCommand = 'report'

-- ACE requis (permissions.cfg): admin > mod > support
Config.Permission = {
    open = 'support',
    players = 'support',
    spectate = 'support',
    gotoPlayer = 'mod',
    bring = 'mod',
    freeze = 'mod',
    heal = 'mod',
    revive = 'mod',
    kick = 'mod',
    warn = 'support',
    ban = 'admin',
    money = 'admin',
    item = 'admin',
    job = 'admin',
    vehicles = 'mod',
    world = 'mod',
    announce = 'mod',
    reports = 'support',
    noclip = 'mod',
    names = 'support',
}

Config.BanDurations = {
    { label = '1 heure', hours = 1 },
    { label = '6 heures', hours = 6 },
    { label = '1 jour', hours = 24 },
    { label = '3 jours', hours = 72 },
    { label = '7 jours', hours = 168 },
    { label = '30 jours', hours = 720 },
    { label = 'Permanent', hours = 0 },
}

Config.QuickVehicles = {
    { model = 'sultan', label = 'Sultan' },
    { model = 'buffalo2', label = 'Buffalo' },
    { model = 'police', label = 'Police Cruiser' },
    { model = 'ambulance', label = 'Ambulance' },
    { model = 'buzzard2', label = 'Buzzard' },
    { model = 'bati', label = 'Bati' },
}

Config.Weathers = {
    'EXTRASUNNY', 'CLEAR', 'CLOUDS', 'OVERCAST', 'RAIN', 'THUNDER', 'CLEARING', 'NEUTRAL', 'SNOW', 'BLIZZARD', 'SNOWLIGHT', 'XMAS', 'FOGGY',
}

Config.MoneyTypes = { 'cash', 'bank' }

Config.Brand = {
    title = 'Acardia RP V2',
    subtitle = 'Admin Tablet',
    server = 'Acardia RP V2',
}
