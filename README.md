# Base FiveM Locale — Qbox

Serveur FiveM local pour apprendre, tester et s’amuser. Stack recommandée **2026** : **Qbox** + écosystème **Overextended (ox)**.

## Pourquoi Qbox ?

| Framework | Pour qui | Verdict |
|-----------|----------|---------|
| **Qbox** | Nouveau serveur en 2026 | **Recommandé** — moderne, perf, ox natif, compatible QBCore |
| **QBCore** | Max tutos / scripts payants | Excellent pour débuter via YouTube, stack plus « classique » |
| **ESX Legacy** | Anciens serveurs / gros catalogue legacy | Viable si déjà ESX ; pas idéal pour repartir de zéro |

**Choix de cette base :** Qbox. Tu gardes la compatibilité QBCore (`provide 'qb-core'`) tout en partant sur ox_lib, ox_inventory, ox_target, oxmysql.

### Stack technique

- **Runtime :** FXServer (artifacts officiels) + **txAdmin**
- **Framework :** [qbx_core](https://github.com/Qbox-project/qbx_core)
- **Libs :** ox_lib, ox_inventory, ox_target, oxmysql
- **DB :** MariaDB **≥ 10.9** (recommandé **12.3 LTS**) — pas MySQL / pas XAMPP
- **Voix :** pma-voice
- **OneSync :** obligatoire (activé par la recipe)

## Prérequis

1. [GTA V légitime](https://fivem.net/) + client FiveM
2. [MariaDB](https://mariadb.org/download/) (≥ 10.9)
3. [7-Zip](https://www.7-zip.org/)
4. Compte [Cfx.re](https://portal.cfx.re/) + **clé de licence serveur**
5. Windows 10/11 (ton cas)

## Installation rapide (recommandée)

```powershell
# 1. Initialiser MariaDB (UAC admin) + DB qbox
.\scripts\setup-mariadb.ps1

# 2. Vérifier l'environnement
.\scripts\check-env.ps1

# 3. Télécharger / extraire les artifacts FXServer (déjà fait si tu suis ce repo)
.\scripts\download-artifacts.ps1

# 4. Lancer txAdmin (première config)
.\scripts\start-server.ps1
```

> Clé licence Cfx.re obligatoire dans `.env` / txAdmin : https://portal.cfx.re/servers/subscription

Dans **txAdmin** :

1. Créer l’admin (lien Cfx.re)
2. Déploiement → **Popular Recipes** → **QBox Framework**  
   (ou recipe custom : `https://raw.githubusercontent.com/Qbox-project/txAdminRecipe/main/qbox.yaml`)
3. Renseigner MariaDB + clé license
4. Lancer la recipe, puis démarrer le serveur

Guide détaillé : [docs/INSTALLATION.md](docs/INSTALLATION.md)

## Arborescence

```
Base Fivem/
├── server/                 # FXServer (artifacts) — non versionné
├── server-data/            # Données générées par txAdmin — non versionné
├── config/                 # Templates de référence (FR)
├── scripts/                # Helpers PowerShell
├── docs/                   # Documentation
├── assets/                 # Logos, etc.
├── .env.example            # Variables à copier
└── README.md
```

Après la recipe txAdmin, les resources Qbox seront dans `server-data/resources/`.

## Première connexion

1. MariaDB démarré, base créée (souvent faite par txAdmin)
2. Serveur démarré via txAdmin
3. FiveM → `F8` → `connect 127.0.0.1:30120`

## Commandes utiles

| Action | Commande |
|--------|----------|
| Vérifier env | `.\scripts\check-env.ps1` |
| Maj artifacts | `.\scripts\download-artifacts.ps1` |
| Démarrer | `.\scripts\start-server.ps1` |
| Docs Qbox | https://docs.qbox.re |

## Sécurité locale

- Ne commit **jamais** ta clé `sv_licenseKey` ni le mot de passe MariaDB
- Garde le serveur en local / privé tant que tu apprends
- Lis [docs/STACK.md](docs/STACK.md) pour l’architecture et les prochaines étapes

## Licence

MIT — voir [LICENSE](LICENSE). Les resources FiveM / Qbox / ox restent sous leurs licences respectives.
