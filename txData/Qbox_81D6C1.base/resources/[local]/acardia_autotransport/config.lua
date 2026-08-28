Config = {}

Config.JobName = 'autotransport'
Config.BossGrade = 3
Config.TabletKey = 'F6'
Config.TheftResaleHours = 48
Config.DriverCut = 0.35
Config.OrderDepositRate = 0.30

Config.BlockedGangs = { 'ballas', 'vagos', 'families', 'marabunta', 'triads', 'lostmc' }
Config.BlockedJobs = { 'police', 'bcso', 'sasp' }

Config.Blip = {
    coords = vec3(924.19, -1265.79, 25.52),
    sprite = 477,
    color = 3,
    scale = 0.85,
    label = 'Auto Import Export',
}

-- HQ LSIA Cargo (separe de Acardia Export)
Config.HQ = {
    duty = vec3(-797.52, -2380.89, 14.64),
    stash = vec3(-801.10, -2376.40, 14.64),
    garage = vec4(903.18, -1262.69, 25.81, 303.08),
    truckSpawn = vec4(912.82, -1253.60, 25.55, 35.00),
    missionPed = vec4(928.43, -1264.24, 26.95, 214.88),
}

Config.Peds = {
    mission = 's_m_m_trucker_01',
    garage = 's_m_m_autoshop_02',
}

Config.Garage = {
    pedModel = 's_m_m_autoshop_02',
    storeRadius = 65.0,
    catalog = {
        { model = 'flatbed', label = 'Flatbed', price = 35000 },
        { model = 'hauler', label = 'Hauler', price = 55000 },
        { model = 'packer', label = 'Packer', price = 75000 },
    },
}

-- Camion temporaire pour missions flatbed (si aucun camion entreprise sorti)
Config.MissionTruck = 'flatbed'

-- Navette de depart (missions drive / VIP)
Config.MissionShuttle = {
    spawn = vec4(912.82, -1253.60, 25.55, 35.00),
    models = { 'blista', 'primo', 'asea', 'faggio2', 'speedo' },
}

-- Vehicule de retour apres livraison (missions drive / VIP)
Config.MissionReturn = {
    models = { 'oracle2', 'schafter2', 'fugitive', 'premier', 'faggio2' },
    bikeModels = { 'faggio2', 'faggio', 'sanchez', 'enduro' },
}

-- Point de cloture retour mission / ramener vehicule a l'entrepot
Config.HQ.returnPoint = vec3(928.87, -1256.11, 25.48)

-- Progression chauffeur (bonus prime)
Config.MissionRanks = {
    { minMissions = 0,  label = 'Stagiaire',   bonus = 0.00 },
    { minMissions = 5,  label = 'Chauffeur',   bonus = 0.05 },
    { minMissions = 15, label = 'Experimente', bonus = 0.10 },
    { minMissions = 35, label = 'Expert',      bonus = 0.15 },
    { minMissions = 70, label = 'Veteran',     bonus = 0.20 },
}

Config.Stash = {
    id = 'at_company_stash',
    label = 'Coffre Auto Import Export',
    slots = 50,
    weight = 2000000,
}

Config.OrderCatalog = {
    { model = 'blista', label = 'Blista', price = 8500, category = 'citadine' },
    { model = 'faggio', label = 'Faggio', price = 4500, category = 'moto' },
    { model = 'sanchez', label = 'Sanchez', price = 6200, category = 'moto' },
    { model = 'oracle', label = 'Oracle', price = 14500, category = 'berline' },
    { model = 'baller', label = 'Baller', price = 28000, category = 'suv' },
    { model = 'comet2', label = 'Comet', price = 42000, category = 'sport' },
}

Config.DealerPickup = vec4(-56.80, -1096.90, 26.42, 70.0)

-- Generation aleatoire des missions tablette
Config.MissionRandom = {
    boardSize = 6,
    refreshMinutes = 12,
    driveChance = 0.38,
    vipChance = 0.10,
    minPayout = 1200,
    maxPayout = 6800,
    payoutPerKm = 165,
}

Config.MissionPickups = {
    { label = 'Sandy Shores', coords = vec4(1708.20, 3770.50, 34.75, 210.0) },
    { label = 'Paleto Bay', coords = vec4(-234.80, 6265.40, 31.50, 135.0) },
    { label = 'Port de LS', coords = vec4(1200.50, -3115.80, 5.54, 0.0) },
    { label = 'Grapeseed', coords = vec4(1690.80, 4785.20, 41.98, 90.0) },
    { label = 'Davis', coords = vec4(-707.40, -915.80, 19.22, 90.0) },
    { label = 'La Puerta', coords = vec4(-1155.40, -2007.80, 13.18, 320.0) },
    { label = 'Harmony', coords = vec4(1185.60, 2649.20, 37.82, 180.0) },
    { label = 'Chumash', coords = vec4(-3195.40, 1085.20, 20.70, 250.0) },
    { label = 'Mirror Park', coords = vec4(1124.50, -776.30, 57.62, 90.0) },
    { label = 'Route 68', coords = vec4(2558.40, 4685.10, 34.08, 45.0) },
    { label = 'Del Perro', coords = vec4(-1520.30, -440.60, 35.44, 130.0) },
    { label = 'Vinewood', coords = vec4(724.80, 1203.40, 325.82, 180.0) },
}

Config.MissionDeliveries = {
    { label = 'Depot LSIA', coords = vec4(-773.80, -2348.60, 14.64, 150.0), hub = true },
    { label = 'Cargo LSIA', coords = vec4(-820.10, -2360.40, 14.64, 150.0), hub = true },
    { label = 'Pillbox Hill', coords = vec4(-48.20, -1110.50, 26.44, 70.0) },
    { label = 'Legion Square', coords = vec4(215.50, -810.20, 30.72, 160.0) },
    { label = 'Burton', coords = vec4(-375.40, -120.80, 38.70, 70.0) },
    { label = 'Rockford Hills', coords = vec4(-842.30, -236.50, 37.20, 120.0) },
    { label = 'Vespucci', coords = vec4(-1150.20, -1520.40, 4.38, 35.0) },
    { label = 'Sandy Garage', coords = vec4(1887.40, 3760.20, 32.92, 210.0) },
    { label = 'Paleto Centre', coords = vec4(105.20, 6612.40, 31.82, 225.0) },
    { label = 'La Mesa', coords = vec4(805.60, -820.40, 26.18, 90.0) },
}

Config.MissionVehicles = {
    drive = {
        { model = 'sanchez', label = 'Sanchez' },
        { model = 'faggio', label = 'Faggio' },
        { model = 'faggio2', label = 'Faggio Sport' },
        { model = 'enduro', label = 'Enduro' },
        { model = 'blazer', label = 'Blazer' },
        { model = 'bati', label = 'Bati 801' },
    },
    flatbed = {
        { model = 'blista', label = 'Blista' },
        { model = 'oracle', label = 'Oracle' },
        { model = 'oracle2', label = 'Oracle XS' },
        { model = 'baller', label = 'Baller' },
        { model = 'stanier', label = 'Stanier' },
        { model = 'fugitive', label = 'Fugitive' },
        { model = 'washington', label = 'Washington' },
        { model = 'premier', label = 'Premier' },
        { model = 'intruder', label = 'Intruder' },
    },
    vip = {
        { model = 'comet2', label = 'Comet' },
        { model = 'elegy2', label = 'Elegy RH8' },
        { model = 'jester', label = 'Jester' },
        { model = 'massacro', label = 'Massacro' },
    },
}
