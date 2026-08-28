# Auto Import Export (`acardia_autotransport`)

Job legal de logistique automobile — transport, livraisons, garage entreprise, tablette de gestion.

## Installation

1. SQL : `resources/[local]/acardia_autotransport/sql/autotransport.sql`
2. Ou script global : `txData/Qbox_81D6C1.base/scripts/import-all-sql.ps1`
3. `ensure [local]` dans `server.cfg` (deja present)
4. `restart acardia_autotransport`

## Prise de service

- **F6** : tablette entreprise (missions, stats, RH patron, solde societe)
- Job Qbox : `autotransport` (grades 0-3)

## Localisation entrepot (La Mesa)

| Point | Coords |
|-------|--------|
| Blip carte | `924.19, -1265.79, 25.52` |
| PNJ logistique (tablette) | `928.43, -1264.24, 26.95` h `214.88` |
| PNJ garage | `903.18, -1262.69, 25.81` h `303.08` |
| Spawn vehicules / navettes | `912.82, -1253.60, 25.55` h `35.00` |
| Retour mission / entrepot | `928.87, -1256.11, 25.48` |

## Types de missions

### Flatbed
Camion plateau → recuperation → chargement → livraison hub/client.

### Drive
Navette → pickup moto/voiture → livraison → **vehicule de retour** → cloture entrepot.

### VIP (~10%)
Sportive premium, livraison client, annonce serveur, prime x1.35.

## Garage entreprise

- PNJ garage : sortir / ranger camions (Flatbed, Hauler, Packer)
- Achat flotte : patron uniquement (compte societe)
- Flatbed temporaire si aucun camion sorti

## Vol & BOLO (RP criminel)

- Chauffeur : `/atsignaler` si vehicule mission vole
- Police : `/boloauto` — liste BOLO (plaque, chauffeur, GPS)
- Revente bloquee **48h** apres vol signale (`Config.TheftResaleHours`)
- Export : `exports.acardia_autotransport:IsResaleBlocked(plate)`

## Commandes

| Commande | Qui | Action |
|----------|-----|--------|
| F6 | Employe | Tablette |
| /atsignaler | Chauffeur en mission | Signaler vol |
| /boloauto | Police on duty | Liste BOLO |

## Progression

Grades chauffeur : Stagiaire → Veteran (+20% prime) selon missions SQL `at_missions_log`.

## MLO associe

`storage_warehouse2` — entrepot La Mesa (`ensure storage_warehouse2`).

## Liens

- Import/Export separe : `acardia_importexport` (job `importexport`)
- Banque societe : `acardia_bank`
- Tables SQL partagees : `ae_society`, `ae_vehicles`
