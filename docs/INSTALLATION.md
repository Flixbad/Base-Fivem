# Installation complète — serveur local Qbox

## 1. MariaDB

1. Télécharge [MariaDB 12.3 LTS](https://mariadb.org/download/) (ou ≥ 10.9)
2. Installe avec un mot de passe root que tu retrouves facilement
3. Crée une base (si txAdmin ne le fait pas) :

```sql
CREATE DATABASE qbox CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE USER 'fivem'@'localhost' IDENTIFIED BY 'change_me';
GRANT ALL PRIVILEGES ON qbox.* TO 'fivem'@'localhost';
FLUSH PRIVILEGES;
```

**Interdit :** XAMPP / MySQL pur pour Qbox.

Vérif :

```powershell
.\scripts\check-env.ps1
```

## 2. Clé de licence Cfx.re

1. Va sur https://portal.cfx.re/servers/subscription
2. Connecte-toi avec ton compte Cfx
3. Génère une **Server License Key**
4. Copie-la dans `.env` (depuis `.env.example`) — ne la commit jamais

## 3. Artifacts FXServer

```powershell
.\scripts\download-artifacts.ps1
```

Le script télécharge le dernier `server.7z` Windows et l’extrait dans `server/`.

Manuellement : https://runtime.fivem.net/artifacts/fivem/build_server_windows/master/  
→ télécharge un build récent (pas les boutons « latest » du haut si la doc Qbox le déconseille) → extrais dans `server/`.

## 4. Premier lancement txAdmin

```powershell
.\scripts\start-server.ps1
```

1. Ouvre le lien affiché (souvent `http://localhost:40120`)
2. Lie ton compte Cfx.re
3. Nom du serveur : ex. `Base Locale Qbox`
4. Type de déploiement : **Popular Recipes** → **QBox Framework**
5. Dossier data : pointe vers  
   `c:\Users\samyd\Desktop\GTA RP\Base Fivem\server-data`
6. Remplis license key + connexion MariaDB
7. Lance la recipe (télécharge resources + SQL)

## 5. Post-install

1. Dans `server-data/server.cfg`, vérifie :
   - `locale` → `fr-FR` si tu veux
   - `qb_locale` / `ox:locale` → `fr` si dispo
2. `sv_maxclients` bas en local (ex. `8`)
3. Ajoute ton identifiant admin dans `permissions.cfg` / txAdmin

## 6. Jouer

1. Lance FiveM
2. `F8` → `connect 127.0.0.1:30120`
3. Crée ton personnage

## Dépannage

| Problème | Piste |
|----------|--------|
| oxmysql fail | MariaDB allumé ? string `mysql_connection_string` correcte ? |
| Recipe timeout | Relance ; vérifie GitHub / antivirus |
| Port 30120 occupé | Change dans txAdmin / `server.cfg` |
| Pas de perso | qbx_core + SQL importés ? logs txAdmin |

## Alternative manuelle

Si tu refuses txAdmin (déconseillé) : clone la recipe et les repos listés dans  
https://github.com/Qbox-project/txAdminRecipe/blob/main/qbox.yaml  
dans `server-data/resources/`, puis importe les `.sql` à la main.
