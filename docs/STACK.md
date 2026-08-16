# Stack & choix techniques

## Verdict 2026

Pour un **serveur neuf** (apprentissage / fun / découverte) :

**Qbox + ox** > QBCore classique > ESX Legacy

### Qbox (retenu)

- Fork moderne de QBCore, maintenu activement
- ox_lib / ox_inventory / ox_target / oxmysql par défaut
- Meilleure perf et architecture plus propre
- Bridge QBCore : beaucoup de scripts `qb-*` fonctionnent avec peu ou pas de changements
- Recipe txAdmin officielle → install en quelques clics

### QBCore

- Plus gros écosystème tutos YouTube / scripts marketplace
- `qb-inventory` plus lourd ; beaucoup de serveurs migrent quand même vers ox
- Bon choix si tu veux coller à 100 % aux tutos QBCore

### ESX Legacy

- Catalogue historique immense
- Plus lourd et plus « legacy » pour un nouveau projet
- À moderniser avec ox si tu restes dessus — pas le meilleur départ en 2026

## Architecture cible

```
Client FiveM
    ↓
FXServer + OneSync
    ↓
txAdmin (gestion / démarrage)
    ↓
qbx_core  ←→  ox_lib / ox_inventory / ox_target
    ↓
oxmysql → MariaDB
```

## Ordre de démarrage des resources (rappel)

1. mapmanager, chat, spawnmanager, sessionmanager, hardcap, baseevents
2. `ox_lib`
3. `qbx_core`
4. `ox_target`
5. dossier `[ox]`, `[qbx]`, `[standalone]`, `[voice]`, `[assets]`
6. NPWD (téléphone) si activé

## Prochaines étapes après la base

1. Apparence personnage (illenium-appearance — déjà dans la recipe)
2. Jobs de base (police, EMS, mécanique) via resources qbx_*
3. Housing / véhicules / crafting selon ton RP
4. Scripts custom dans `server-data/resources/[local]/`

## Liens

- Docs Qbox : https://docs.qbox.re
- Recipe : https://github.com/Qbox-project/txAdminRecipe
- ox_lib : https://overextended.dev/ox_lib
- Artifacts : https://runtime.fivem.net/artifacts/fivem/build_server_windows/master/
- Clé licence : https://portal.cfx.re/servers/subscription
