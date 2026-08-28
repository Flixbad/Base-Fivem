Config = {}

Config.ItemName = 'bank_card'
Config.PinLength = 4
Config.PinMaxAttempts = 3
Config.PinLockSeconds = 60

Config.AccountTypes = {
    {
        slot = 1,
        type = 'personal',
        label = 'Compte Essentiel',
        subtitle = 'Votre premier compte Acardia',
        ceiling = 100000,
        maxCards = 1,
        requiresCompany = false,
    },
    {
        slot = 2,
        type = 'personal',
        label = 'Compte Premium',
        subtitle = 'Plafond et cartes etendus',
        ceiling = 500000,
        maxCards = 2,
        requiresCompany = false,
        requiresSlot = 1,
    },
    {
        slot = 3,
        type = 'personal',
        label = 'Compte Prestige',
        subtitle = 'Le haut de gamme particulier',
        ceiling = 1000000,
        maxCards = 3,
        requiresCompany = false,
        requiresSlot = 2,
    },
    {
        slot = 4,
        type = 'business',
        label = 'Compte Entreprise',
        subtitle = 'Micro-entreprise - 20 cartes employes',
        ceiling = 3000000,
        maxCards = 20,
        requiresCompany = true,
        requiresSlot = 1,
    },
}

Config.AtmModels = {
    `prop_atm_01`,
    `prop_atm_02`,
    `prop_atm_03`,
    `prop_fleeca_atm`,
}

-- canCreate = ouverture de compte + fabrication de cartes (Pacific Bank Vinewood)
Config.Banks = {
    {
        id = 'pacific',
        label = 'Pacific Standard Bank',
        canCreate = true,
        zones = {
            { coords = vec3(247.43, 223.72, 106.29), size = vec3(1.4, 1.6, 1.3), rotation = 160.0 },
            { coords = vec3(252.80, 225.72, 106.29), size = vec3(1.4, 1.6, 1.3), rotation = 160.0 },
        },
    },
    {
        id = 'legion',
        label = 'Fleeca Bank - Legion Square',
        canCreate = false,
        zones = {
            { coords = vec3(149.92, -1040.74, 29.37), size = vec3(1.6, 1.2, 1.2), rotation = 340.0 },
        },
    },
    {
        id = 'hawick',
        label = 'Fleeca Bank - Hawick',
        canCreate = false,
        zones = {
            { coords = vec3(314.23, -278.83, 54.17), size = vec3(1.6, 1.2, 1.2), rotation = 340.0 },
        },
    },
    {
        id = 'burton',
        label = 'Fleeca Bank - Burton',
        canCreate = false,
        zones = {
            { coords = vec3(-351.13, -49.67, 49.04), size = vec3(1.6, 1.2, 1.2), rotation = 341.0 },
        },
    },
    {
        id = 'rockford',
        label = 'Fleeca Bank - Rockford Hills',
        canCreate = false,
        zones = {
            { coords = vec3(-1213.00, -330.39, 37.79), size = vec3(1.6, 1.2, 1.2), rotation = 27.0 },
        },
    },
    {
        id = 'greatocean',
        label = 'Fleeca Bank - Great Ocean',
        canCreate = false,
        zones = {
            { coords = vec3(-2962.71, 482.96, 15.70), size = vec3(1.6, 1.2, 1.2), rotation = 88.0 },
        },
    },
    {
        id = 'route68',
        label = 'Fleeca Bank - Route 68',
        canCreate = false,
        zones = {
            { coords = vec3(1175.07, 2706.41, 38.09), size = vec3(1.6, 1.2, 1.2), rotation = 178.0 },
        },
    },
    {
        id = 'paleto',
        label = 'Blaine County Savings - Paleto',
        canCreate = false,
        zones = {
            { coords = vec3(-112.22, 6469.91, 31.63), size = vec3(1.6, 1.2, 1.2), rotation = 134.0 },
        },
    },
}
