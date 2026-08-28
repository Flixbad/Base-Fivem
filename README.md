# Acardia RP V2 — Base FiveM Qbox

Base serveur **FiveM** locale et evolutive, orientee **RP francais**, construite sur **Qbox** + stack **Overextended (ox)**.

> Projet en developpement actif — de la base Qbox minimale a un ecosysteme RP custom (jobs, banque, UI, MLO, logistique automobile).

[![License: MIT](https://img.shields.io/badge/License-MIT-teal.svg)](LICENSE)
[![FiveM](https://img.shields.io/badge/FiveM-Qbox-purple)](https://docs.qbox.re)
[![Stack](https://img.shields.io/badge/Stack-ox__lib%20|%20ox__inventory%20|%20ox__target-blue)](#stack-technique)

---

## Sommaire

- [Apercu](#apercu)
- [Stack technique](#stack-technique)
- [Resources custom](#resources-custom)
- [Jobs developpes](#jobs-developpes)
- [Auto Import Export — fonctionnalites](#auto-import-export--fonctionnalites)
- [Installation](#installation)
- [Base de donnees](#base-de-donnees)
- [Structure du depot](#structure-du-depot)
- [Documentation](#documentation)
- [Securite & secrets](#securite--secrets)
- [Roadmap](#roadmap)
- [Licence](#licence)

---

## Apercu

Ce depot contient :

- Les **scripts PowerShell** pour installer et lancer FXServer / txAdmin
- Le profil serveur complet **`txData/Qbox_81D6C1.base/`** (config, resources, SQL)
- Des **resources locales** developpees pour Acardia RP V2 / Oren RP :
  - Jobs logistiques (**Auto Import Export**, **Acardia Export**)
  - Banque entreprise, HUD, multichar, pause menu, admin, clothing
- Un serveur **Qbox lean** : framework + essentials, ~67 resources desactivees dans `_disabled/`

**Nom serveur actuel :** Acardia RP V2  
**Locale :** fr-FR · **Slots :** 48 · **Game build :** 3258

---

## Stack technique

| Composant | Detail |
|-----------|--------|
| Runtime | FXServer + **txAdmin** v8 |
| Framework | [qbx_core](https://github.com/Qbox-project/qbx_core) (bridge QBCore) |
| Libs | ox_lib, ox_inventory, ox_target, oxmysql |
| Apparence | illenium-appearance |
| Voix | pma-voice (voice.cfg) |
| DB | MariaDB / MySQL — base `Qbox_81D6C1` |
| OneSync | Obligatoire |

Resources Qbox actives : core, spawn, vehicles, medical, ambulance, garages, vehiclekeys, vehicleshop, police, prison, smallresources.

---

## Resources custom

Dossier : `txData/Qbox_81D6C1.base/resources/[local]/`

| Resource | Description |
|----------|-------------|
| **acardia_autotransport** | Job Auto Import Export — missions, tablette F6, garage, BOLO |
| **acardia_importexport** | Job Acardia Export — craft, export, missions fournisseur |
| **acardia_bank** | Banque + comptes societe |
| **acardia_base** | HUD, minimap, wanted level |
| **acardia_clothing** | Boutique vetements + thumbnails |
| **acardia_discord** | Rich presence Discord |
| **liveafk_loadingscreen** | Ecran de chargement Acardia |
| **liveafk_multichar** | Multicharacter custom |
| **liveafk_pausemenu** | Menu pause cinematique |
| **liveafk_admin** | Tablette admin |
| **storage_warehouse2** | MLO entrepot La Mesa |
| **uz_AutoShot** | Screenshots vetements |
| **screencapture** | Capture ecran (dependance) |

---

## Jobs developpes

### Auto Import Export (`autotransport`)

Job legal de **logistique automobile** — voir [docs/AUTO-TRANSPORT.md](docs/AUTO-TRANSPORT.md).

### Acardia Export (`importexport`)

Job separe — craft, missions approvisionnement/export. Voir [docs/ACARDIA-EXPORT.md](docs/ACARDIA-EXPORT.md).

---

## Auto Import Export — fonctionnalites

Developpement recent (2026) :

### Gameplay

- **Tablette F6** : missions, stats, service, gestion patron (RH, grades, solde)
- **Board missions** : 6 missions aleatoires, refresh 12 min
- **3 modes** : Flatbed · Drive · VIP
- **Missions Drive** : navette → pickup → livraison → vehicule de retour → cloture entrepot
- **Missions VIP** : sportives, annonce serveur, prime majorée
- **Garage entreprise** : Flatbed / Hauler / Packer, flotte SQL
- **Progression** : 5 rangs chauffeur (+20% prime Veteran)

### Entrepot La Mesa (MLO `storage_warehouse2`)

| Point | Role |
|-------|------|
| Blip carte | Point visible sur la map |
| PNJ logistique | Ouvre la tablette / missions |
| PNJ garage | Sortie & rangement camions |
| Zone spawn | Vehicules mission & navettes |
| Point retour | Fin de mission drive/VIP |

### RP criminel & police

- `/atsignaler` — chauffeur signale vol vehicule mission
- `/boloauto` — police consulte BOLO (plaque, chauffeur, GPS)
- Revente bloquee **48h** apres vol (`at_thefts` SQL)
- Integration future : receleur, marche noir, revente differee

### Fixes techniques appliques

- Acces job via groupes Qbox secondaires (`jobaccess.lua`)
- Ordre declarations Lua (forward reference `getPlayer`, `payMission`)
- Natives client/serveur separes (`SetEntityAsMissionEntity`)
- Import SQL automatise (`scripts/import-all-sql.ps1`)
- Conflit F6 importexport/autotransport resolu

---

## Installation

### Prerequis

1. [GTA V](https://fivem.net/) + client FiveM
2. MariaDB ≥ 10.9 (ou XAMPP MySQL local)
3. [7-Zip](https://www.7-zip.org/)
4. Cle [Cfx.re](https://portal.cfx.re/)

### Demarrage rapide

```powershell
# 1. Cloner le repo
git clone https://github.com/Flixbad/Base-Fivem.git
cd Base-Fivem

# 2. Copier les variables d'environnement
copy .env.example .env
# Editer .env avec votre cle Cfx.re

# 3. MariaDB + base (admin UAC)
.\scripts\setup-mariadb.ps1

# 4. Verifier l'environnement
.\scripts\check-env.ps1

# 5. Artifacts FXServer (si absent)
.\scripts\download-artifacts.ps1

# 6. Config serveur
copy txData\Qbox_81D6C1.base\server.cfg.example txData\Qbox_81D6C1.base\server.cfg
# Renseigner sv_licenseKey et mysql_connection_string

# 7. Importer SQL
powershell -ExecutionPolicy Bypass -File txData\Qbox_81D6C1.base\scripts\import-all-sql.ps1

# 8. Lancer txAdmin
.\scripts\start-server.ps1
```

Dans **txAdmin** : lier Cfx.re → pointer data path vers `txData/Qbox_81D6C1.base/` → demarrer.

Guide detaille : [docs/INSTALLATION.md](docs/INSTALLATION.md)

### Connexion

```
connect 127.0.0.1:30120
```

Commandes test job :

```
/setjob [id] autotransport 0
/restart acardia_autotransport
```

---

## Base de donnees

Base : **`Qbox_81D6C1`**

Tables custom principales :

| Prefixe | Usage |
|---------|-------|
| `at_*` | Auto Transport (orders, thefts, missions_log) |
| `ae_*` | Societes / vehicules entreprise (partage importexport + autotransport) |
| `acardia_bank_*` | Banque |
| `ox_*` | ox_inventory, doorlock |

Script import : `txData/Qbox_81D6C1.base/scripts/import-all-sql.ps1`

---

## Structure du depot

```
Base Fivem/
├── server/                          # FXServer artifacts (non versionne)
├── server-data/                     # Legacy txAdmin data
├── scripts/                         # Helpers PowerShell racine
│   ├── start-server.ps1
│   ├── setup-mariadb.ps1
│   ├── check-env.ps1
│   └── download-artifacts.ps1
├── txData/
│   └── Qbox_81D6C1.base/            # Profil serveur actif
│       ├── server.cfg.example       # Template (copier → server.cfg)
│       ├── resources/
│       │   ├── [local]/             # Scripts custom Acardia
│       │   ├── [qbx]/               # Qbox actif
│       │   ├── [ox]/                # Overextended
│       │   ├── [standalone]/
│       │   └── _disabled/           # ~67 resources desactives
│       └── scripts/
│           └── import-all-sql.ps1
├── docs/
│   ├── INSTALLATION.md
│   ├── AUTO-TRANSPORT.md
│   ├── ACARDIA-EXPORT.md
│   └── QBOX-LEAN.md
├── assets/
├── .env.example
└── README.md
```

---

## Documentation

| Fichier | Contenu |
|---------|---------|
| [docs/INSTALLATION.md](docs/INSTALLATION.md) | Installation pas a pas |
| [docs/AUTO-TRANSPORT.md](docs/AUTO-TRANSPORT.md) | Job Auto Import Export |
| [docs/ACARDIA-EXPORT.md](docs/ACARDIA-EXPORT.md) | Job Acardia Export |
| [docs/QBOX-LEAN.md](docs/QBOX-LEAN.md) | Resources actives vs desactivees |
| [docs/STACK.md](docs/STACK.md) | Architecture & stack |

---

## Securite & secrets

**Ne jamais committer :**

- `.env` (cle Cfx.re, mots de passe DB)
- `txData/Qbox_81D6C1.base/server.cfg` (contient `sv_licenseKey`)
- `txData/admins.json` (hash mot de passe txAdmin)

Utilisez `server.cfg.example` comme template.

Fichiers exclus via `.gitignore` : cache, logs txAdmin, secrets.

---

## Roadmap

- [x] Base Qbox lean + txAdmin
- [x] UI Acardia (loadingscreen, multichar, pausemenu, admin)
- [x] Jobs logistiques (importexport + autotransport)
- [x] MLO entrepot La Mesa
- [x] Missions drive / flatbed / VIP + tablette F6
- [x] Systeme vol / BOLO / blocage revente 48h
- [ ] Commandes clients v2 (catalogue public)
- [ ] Concession luxe + livraison domicile
- [ ] Livraisons inter-concessions (B2B)
- [ ] Missions PNJ + marche noir revente

> Le fonctionnement decrit correspond a la version developpee. Evolutif si reprise par une equipe serveur.

---

## Licence

MIT — voir [LICENSE](LICENSE).

Resources tierces (Qbox, ox, MLO, FiveM) : licences respectives de leurs auteurs.

---

**Auteur / Dev :** [Flixbad](https://github.com/Flixbad)  
**Serveur cible :** Acardia RP V2 / Oren RP
