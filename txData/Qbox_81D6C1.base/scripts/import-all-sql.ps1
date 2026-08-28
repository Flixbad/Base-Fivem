# Importe tous les fichiers SQL des ressources FiveM (CREATE IF NOT EXISTS / INSERT safe)
$ErrorActionPreference = 'Continue'
$Base = Split-Path $PSScriptRoot -Parent
$Resources = Join-Path $Base 'resources'
$Db = 'Qbox_81D6C1'
$User = 'root'

$MysqlCandidates = @(
    'C:\xampp\mysql\bin\mysql.exe',
    'C:\Program Files\MariaDB 12.3\bin\mysql.exe',
    'C:\Program Files\MariaDB 11.4\bin\mysql.exe',
    'C:\Program Files\MySQL\MySQL Server 8.0\bin\mysql.exe'
)

$Mysql = $MysqlCandidates | Where-Object { Test-Path $_ } | Select-Object -First 1
if (-not $Mysql) {
    Write-Error 'Client mysql introuvable (XAMPP / MariaDB / MySQL).'
    exit 1
}

Write-Host "MySQL: $Mysql"
Write-Host "Base:  $Db"
Write-Host ''

# Ordre logique (schemas avant ALTER / INSERT de donnees)
$Ordered = @(
    '[qbx]\qbx_core\qbx_core.sql',
    '[qbx]\qbx_vehicles\vehicles.sql',
    '[qbx]\qbx_vehicleshop\vehshop.sql',
    '[standalone]\illenium-appearance\sql\playerskins.sql',
    '[standalone]\illenium-appearance\sql\player_outfits.sql',
    '[standalone]\illenium-appearance\sql\player_outfit_codes.sql',
    '[standalone]\illenium-appearance\sql\management_outfits.sql',
    '[local]\acardia_importexport\sql\acardia_importexport.sql',
    '[local]\acardia_importexport\sql\ae_vehicles.sql',
    '[local]\acardia_autotransport\sql\autotransport.sql',
    '_disabled\Renewed-Banking\Renewed-Banking.sql',
    '_disabled\npwd\import.sql',
    '_disabled\ox_doorlock\sql\ox_doorlock.sql',
    '_disabled\ox_doorlock\sql\default.sql',
    '_disabled\ox_doorlock\sql\community_mrpd.sql',
    '_disabled\qbx_drugs\qbx_drugs.sql',
    '_disabled\qbx_lapraces\qbx_lapraces.sql',
    '_disabled\qbx_properties\property.sql',
    '_disabled\qbx_properties\decorations.sql',
    '_disabled\qbx_properties\property_garages.sql',
    '_disabled\qbx_vehiclesales\qbx_vehiclesales.sql',
    '_disabled\qbx_weed\sql\qbx_weed.sql'
)

# Migrations deja appliquees ou dangereuses a reexecuter
$Skip = @(
    'migrate.sql',
    'migration.sql'
)

$ok = 0
$warn = 0
$fail = 0

function Import-SqlFile {
    param([string]$RelativePath)

    $full = Join-Path $Resources $RelativePath
    if (-not (Test-Path -LiteralPath $full)) {
        Write-Host "[SKIP] Fichier absent: $RelativePath" -ForegroundColor DarkYellow
        $script:warn++
        return
    }

    $name = Split-Path $RelativePath -Leaf
    if ($Skip -contains $name) {
        Write-Host "[SKIP] Migration ignoree: $RelativePath" -ForegroundColor DarkYellow
        $script:warn++
        return
    }

    Write-Host "[RUN ] $RelativePath" -ForegroundColor Cyan
    $sql = Get-Content -LiteralPath $full -Raw -Encoding UTF8
    $out = $sql | & $Mysql -u $User --force $Db 2>&1
    $code = $LASTEXITCODE

    if ($code -eq 0 -and -not $out) {
        Write-Host "       OK" -ForegroundColor Green
        $script:ok++
        return
    }

    $lines = @($out | Where-Object { $_ -match '\S' })
    $hard = $lines | Where-Object {
        $_ -notmatch 'Duplicate entry|already exists|Duplicate column|Duplicate key name|Can''t DROP'
    }

    if ($hard.Count -eq 0) {
        Write-Host "       OK (deja present / doublons ignores)" -ForegroundColor Green
        $script:ok++
    } elseif ($code -eq 0) {
        Write-Host "       OK avec avertissements:" -ForegroundColor Yellow
        $lines | ForEach-Object { Write-Host "         $_" -ForegroundColor DarkYellow }
        $script:warn++
    } else {
        Write-Host "       ERREUR:" -ForegroundColor Red
        $lines | ForEach-Object { Write-Host "         $_" -ForegroundColor Red }
        $script:fail++
    }
}

foreach ($rel in $Ordered) {
    Import-SqlFile -RelativePath $rel
}

# Tout autre .sql non liste (sauf migrations)
$known = $Ordered | ForEach-Object { (Join-Path $Resources $_).ToLowerInvariant() }
Get-ChildItem -LiteralPath $Resources -Filter '*.sql' -Recurse | ForEach-Object {
    if ($known -contains $_.FullName.ToLowerInvariant()) { return }
    if ($Skip -contains $_.Name) { return }
    $rel = $_.FullName.Substring($Resources.Length + 1)
    Import-SqlFile -RelativePath $rel
}

Write-Host ''
Write-Host "Termine - OK: $ok | Avertissements: $warn | Erreurs: $fail"
if ($fail -gt 0) { exit 1 }
