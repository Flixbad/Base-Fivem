# Acardia Export — mode d'emploi

Resource: `resources/[local]/acardia_importexport`

## Setup

1. SQL deja importe dans `qbox_81d6c1` (tables `ae_*`)
2. `ensure [local]` dans `server.cfg`
3. Restart serveur / `ensure acardia_importexport`

## Test rapide (admin)

```
/ae_setjob
/ae_giveitems
/optin
```

## Boucle joueur

1. Blip **Acardia Export** (docks)
2. Va sur le **premier marker jaune** → texte `[E] Prendre / Quitter service` → appuie sur **E**
3. Sur le **second marker** → **E** → menu (craft / mission)
4. Demarrer mission -> camion spawn
5. Valider chargement au marker craft (**E**)
6. Port → bateau → 2e camion → client (toujours **E** dans les markers)

> Ancien systeme ox_target (Alt) remplace par interaction **E** + texte a l ecran.

## Missions

### Approvisionnement
1. Service + menu entrepot → **Mission: chercher ingredients**
2. Camion spawn + GPS fournisseur (PNJ)
3. **E** chez le PNJ → acheter (argent = **compte societe**)
4. Retour HQ → **E** coffre entreprise pour deposer
5. Terminer mission chez le PNJ ou Annuler

### Export
Craft colis (ingredients = inventaire **puis** coffre) → mission export → port → bateau → client

### Coffre
Marker jaune entre duty et craft — **10000 kg** / 100 slots

### Garage entreprise
- PNJ garage au HQ (**E**)
- Acces **job uniquement** (en service)
- **Patron** : achete camions avec le compte societe (Mule, Pounder, etc.)
- Employes : sortir / ranger les vehicules
- Les missions ne spawn plus de camion : il faut en sortir un du garage d abord


