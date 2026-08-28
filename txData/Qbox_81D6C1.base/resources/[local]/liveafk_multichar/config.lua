Config = {}

Config.Brand = {
    live = 'ACARDIA',
    afk = 'RP V2',
    server = 'Acardia RP V2',
    tagline = 'Bienvenue dans l histoire',
}

Config.MandatorySpawn = vec4(327.56, -205.08, 53.08, 163.5)

Config.UseLastLocation = true
Config.AllowDelete = true

--[[
  Maison de Michael (salon) — interieur story toujours present, vrai canape.
  On spawn aussi un prop canape au cas ou, et on assoit les persos dessus.
]]
Config.Apartment = {
    load = vec4(-802.99, 174.95, 72.84, 190.0),
    hidden = vec4(-798.50, 176.80, 72.84, 0.0),
    sofa = {
        model = `v_res_mp_sofa`,
        -- Devant le canape natif / salon
        coords = vec4(-803.55, 173.05, 71.84, 210.0),
    },
    seatOffsets = {
        vec3(-0.90, 0.12, 0.42),
        vec3(0.00, 0.12, 0.42),
        vec3(0.90, 0.12, 0.42),
    },
    seatHeading = 210.0,
    camOverview = vec4(-801.10, 175.85, 73.35, 0.0),
    camFocusDistance = 2.20,
    camFocusHeight = 0.50,
    camFov = 45.0,
    camFovFocus = 34.0,
}

Config.Nationalities = {
    'Francaise', 'Belge', 'Suisse', 'Canadienne', 'Americaine',
    'Britannique', 'Espagnole', 'Italienne', 'Allemande', 'Portugaise',
    'Marocaine', 'Algerienne', 'Tunisienne', 'Senegalaise', 'Ivoirienne',
    'Bresilienne', 'Mexicaine', 'Japonaise', 'Chinoise', 'Russe',
}

Config.DateMin = '1900-01-01'
Config.DateMax = '2006-12-31'
