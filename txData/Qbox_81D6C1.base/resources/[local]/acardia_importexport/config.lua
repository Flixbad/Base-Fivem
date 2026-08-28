Config = {}

Config.JobName = 'importexport'
Config.BossGrade = 3
Config.TabletKey = 'F6'
Config.MinCratesToStart = 1
Config.MaxCratesPerRun = 4

Config.Blip = {
    sprite = 478,
    color = 5,
    scale = 0.85,
    label = 'Acardia Export',
}

-- HQ Elysian Island / docks
Config.HQ = {
    duty = vec3(119.45, -3103.12, 6.0),
    craft = vec4(120.32, -3104.37, 6.98, 93.33),
    stash = vec3(122.10, -3101.55, 6.0),
    garage = vec4(133.02, -3113.50, 5.90, 353.71),
    truckSpawn = vec4(142.50, -3105.40, 5.90, 270.0),
    -- PNJ missions (lancer supply / export)
    missionPed = vec4(120.37, -3092.39, 6.02, 268.95),
}

-- Garage entreprise (PNJ) - acces job uniquement
Config.Garage = {
    pedModel = 's_m_y_xmech_01',
    storeRadius = 60.0, -- zone large (spawn camion inclus)
    -- Catalogue d achat (paye par le compte societe) - patron seulement
    catalog = {
        { model = 'mule', label = 'Mule', price = 25000 },
        { model = 'mule2', label = 'Mule 2', price = 28000 },
        { model = 'pounder', label = 'Pounder', price = 45000 },
        { model = 'benson', label = 'Benson', price = 35000 },
    },
}

-- Coffre entreprise (poids ox_inventory en grammes) : 10000 kg
Config.Stash = {
    id = 'ae_company_stash',
    label = 'Coffre Acardia Export',
    slots = 100,
    weight = 10000000, -- 10000 kg
}

-- Fournisseur ingredients (PNJ magasin)
Config.Supplier = {
    coords = vec4(46.55, -1749.48, 29.63, 53.0),
    pedModel = 's_m_m_autoshop_02',
    blip = { sprite = 52, color = 2, label = 'Fournisseur Acardia' },
}

-- Prix payes par le compte societe
Config.SupplierShop = {
    { item = 'goldbar', label = 'Lingot d or', price = 800, count = 1 },
    { item = 'raw_pc', label = 'Composants PC', price = 450, count = 1 },
    { item = 'raw_jewelry', label = 'Bijoux bruts', price = 350, count = 1 },
    { item = 'diamond_ring', label = 'Diamant', price = 600, count = 1 },
}

Config.Port = {
    checkIn = vec3(-52.40, -2414.85, 6.0),
    boatSpawn = vec4(-30.79, -2369.77, -0.53, 326.53),
    -- Point pour ranger le bateau apres livraison
    boatStore = vec4(-30.79, -2369.77, -0.53, 326.53),
    -- Garage camion au port (reprise apres bateau)
    truckSpawn = vec4(-45.80, -2412.50, 6.0, 325.0),
    truckGarage = vec3(-45.80, -2412.50, 6.0),
}

-- Livraisons bateau aleatoires (nord / sud)
Config.BoatDeliveries = {
    north = {
        { label = 'Livraison Nord - Paleto', coords = vec4(-1598.40, 5254.20, 0.40, 200.0) },
        { label = 'Livraison Nord - Procopio', coords = vec4(-480.20, 6488.50, 0.40, 180.0) },
        { label = 'Livraison Nord - Alamo', coords = vec4(1298.60, 4218.40, 0.40, 90.0) },
        { label = 'Livraison Nord - Chianski', coords = vec4(3855.20, 4465.80, 0.40, 270.0) },
    },
    south = {
        { label = 'Livraison Sud - Terminal', coords = vec4(-855.40, -3195.60, 0.40, 0.0) },
        { label = 'Livraison Sud - LSIA', coords = vec4(-1195.80, -3048.20, 0.40, 90.0) },
        { label = 'Livraison Sud - Elysian', coords = vec4(185.60, -3348.40, 0.40, 180.0) },
        { label = 'Livraison Sud - Port Est', coords = vec4(120.40, -2888.60, 0.40, 270.0) },
    },
}

Config.Arrival = {
    boatDest = vec4(385.60, -2748.40, 0.30, 0.0), -- legacy (non utilise)
    truckSpawn = vec4(402.15, -2736.80, 6.0, 90.0),
}

Config.ClientDrop = vec3(916.35, -1702.40, 32.20)

Config.Vehicles = {
    truck = 'mule',
    boat = 'tug',
}

Config.CraftDuration = 60000 -- 60 secondes par colis
Config.CraftAnim = {
    dict = 'mini@repair',
    clip = 'fixing_a_ped',
    flag = 1,
}

Config.CraftRecipes = {
    {
        id = 'gold',
        label = 'Caisse Or',
        result = 'export_crate_gold',
        ingredients = {
            { item = 'goldbar', count = 2 },
        },
        payout = 2500,
    },
    {
        id = 'pc',
        label = 'Caisse PC',
        result = 'export_crate_pc',
        ingredients = {
            { item = 'raw_pc', count = 1 },
        },
        payout = 1800,
    },
    {
        id = 'jewelry',
        label = 'Caisse Bijoux',
        result = 'export_crate_jewelry',
        ingredients = {
            { item = 'raw_jewelry', count = 1 },
            { item = 'diamond_ring', count = 1 },
        },
        payout = 2200,
    },
}

Config.CrateItems = {
    export_crate_gold = true,
    export_crate_pc = true,
    export_crate_jewelry = true,
}

Config.PayoutPerCrate = {
    export_crate_gold = 2500,
    export_crate_pc = 1800,
    export_crate_jewelry = 2200,
}

Config.DebugItemsCommand = true -- /ae_giveitems /ae_addmoney pour tester
