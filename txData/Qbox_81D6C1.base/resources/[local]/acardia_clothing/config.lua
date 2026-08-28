Config = {}

Config.ItemPrice = 100
Config.HangerPrice = 5
Config.OutfitSavePrice = 0

Config.Categories = {
    { id = 'mask',      type = 'component', componentId = 1,  label = 'Masque',      icon = 'mask' },
    { id = 'hat',       type = 'prop',      propId = 0,      label = 'Chapeau',     icon = 'hat' },
    { id = 'glasses',   type = 'prop',      propId = 1,      label = 'Lunettes',    icon = 'glasses' },
    { id = 'ear',       type = 'prop',      propId = 2,      label = 'Oreilles',    icon = 'ear' },
    { id = 'shirt',     type = 'component', componentId = 11, label = 'T-Shirt',     icon = 'shirt' },
    { id = 'torso',     type = 'component', componentId = 3,  label = 'Bras',        icon = 'torso' },
    { id = 'pants',     type = 'component', componentId = 4,  label = 'Pantalon',    icon = 'pants' },
    { id = 'shoes',     type = 'component', componentId = 6,  label = 'Chaussures',  icon = 'shoes' },
    { id = 'bag',       type = 'component', componentId = 5,  label = 'Sac',         icon = 'bag' },
    { id = 'vest',      type = 'component', componentId = 9,  label = 'Gilet',       icon = 'vest' },
    { id = 'accessory', type = 'component', componentId = 7,  label = 'Accessoire',  icon = 'accessory' },
    { id = 'decals',    type = 'component', componentId = 10, label = 'Decals',      icon = 'decals' },
    { id = 'watch',     type = 'prop',      propId = 6,      label = 'Montre',      icon = 'watch' },
    { id = 'bracelet',  type = 'prop',      propId = 7,      label = 'Bracelet',    icon = 'bracelet' },
}

Config.Shops = {
    {
        id = 'ponsonbys',
        label = 'Ponsonbys',
        coords = vec3(-168.73, -301.41, 39.73),
        size = vec3(4, 4, 4),
        rotation = 0.0,
    },
    {
        id = 'suburban_hawick',
        label = 'Suburban',
        coords = vec3(124.82, -224.36, 54.56),
        size = vec3(4, 4, 4),
        rotation = 0.0,
    },
    {
        id = 'binco_strawberry',
        label = 'Binco',
        coords = vec3(75.39, -1398.28, 29.38),
        size = vec3(4, 4, 4),
        rotation = 0.0,
    },
    {
        id = 'discount_delperro',
        label = 'Discount Store',
        coords = vec3(-1192.61, -768.4, 17.32),
        size = vec3(4, 4, 4),
        rotation = 0.0,
    },
    {
        id = 'rockford',
        label = 'Rockford Hills',
        coords = vec3(-705.5, -149.22, 37.42),
        size = vec3(4, 4, 4),
        rotation = 0.0,
    },
    {
        id = 'mission_row',
        label = 'Mission Row',
        coords = vec3(425.91, -801.03, 29.49),
        size = vec3(4, 4, 4),
        rotation = 0.0,
    },
    {
        id = 'vespucci',
        label = 'Vespucci',
        coords = vec3(-1119.24, -1440.6, 5.23),
        size = vec3(4, 4, 4),
        rotation = 0.0,
    },
    {
        id = 'grapeseed',
        label = 'Grapeseed',
        coords = vec3(1693.2, 4828.11, 42.07),
        size = vec3(4, 4, 4),
        rotation = 0.0,
    },
    {
        id = 'paleto',
        label = 'Paleto Bay',
        coords = vec3(9.22, 6515.74, 31.88),
        size = vec3(4, 4, 4),
        rotation = 0.0,
    },
    {
        id = 'harmony',
        label = 'Harmony',
        coords = vec3(615.35, 2762.72, 42.09),
        size = vec3(4, 4, 4),
        rotation = 0.0,
    },
    {
        id = 'sandy',
        label = 'Sandy Shores',
        coords = vec3(1191.61, 2710.91, 38.22),
        size = vec3(4, 4, 4),
        rotation = 0.0,
    },
}

Config.Blip = {
    sprite = 73,
    color = 47,
    scale = 0.75,
    label = 'Magasin de vetements',
}

Config.ItemMap = {
    mask      = 'clothing_mask',
    hat       = 'clothing_hat',
    glasses   = 'clothing_glasses',
    ear       = 'clothing_ear',
    shirt     = 'clothing_shirt',
    torso     = 'clothing_torso',
    pants     = 'clothing_pants',
    shoes     = 'clothing_shoes',
    bag       = 'clothing_bag',
    vest      = 'clothing_vest',
    accessory = 'clothing_accessory',
    decals    = 'clothing_decals',
    watch     = 'clothing_watch',
    bracelet  = 'clothing_bracelet',
}

Config.CategoryLabels = {
    mask = 'Masque', hat = 'Chapeau', glasses = 'Lunettes', ear = 'Boucles',
    shirt = 'T-Shirt', torso = 'Veste', pants = 'Pantalon', shoes = 'Chaussures',
    bag = 'Sac', vest = 'Gilet', accessory = 'Accessoire', decals = 'Decals',
    watch = 'Montre', bracelet = 'Bracelet',
}

Config.Thumbnails = {
    -- Fichiers locaux : html/thumbnails/{male|female}/{categoryId}/{drawable}_{texture}.webp
    useStaticFiles = true,
    -- Capture auto en jeu (flicker caméra) — laisser false sans uz_AutoShot
    runtimeCapture = false,
    captureSize = 128,
    captureDelay = 80,
    studioOffset = vec3(120.0, 120.0, -50.0),
}
