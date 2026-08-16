#Requires -Version 5.1
<#
.SYNOPSIS
    Verifie les prerequis pour un serveur FiveM / Qbox local.
#>
$ErrorActionPreference = "Continue"
$Root = Split-Path -Parent $PSScriptRoot

Write-Host ""
Write-Host "=== Check environnement Base FiveM (Qbox) ===" -ForegroundColor Cyan
Write-Host "Root: $Root"
Write-Host ""

$ok = $true

function Write-Pass {
    param([string]$Message)
    Write-Host ("  OK  " + $Message) -ForegroundColor Green
}

function Write-Warn {
    param([string]$Message)
    Write-Host ("  !!  " + $Message) -ForegroundColor Yellow
}

function Test-Tool {
    param([string]$Name, [scriptblock]$Test, [string]$Hint)
    try {
        $result = & $Test
        if ($result) {
            Write-Pass $Name
            if ($result -is [string] -and $result.Length -gt 0) {
                Write-Host ("      " + $result.Trim()) -ForegroundColor DarkGray
            }
            return $true
        }
    } catch { }
    Write-Warn $Name
    Write-Host ("      " + $Hint) -ForegroundColor DarkYellow
    return $false
}

[void](Test-Tool "PowerShell" { $PSVersionTable.PSVersion.ToString() } "Installe PowerShell 5.1+")
[void](Test-Tool "Git" { (git --version) } "https://git-scm.com/download/win")

$sevenZip = @(
    "${env:ProgramFiles}\7-Zip\7z.exe",
    "${env:ProgramFiles(x86)}\7-Zip\7z.exe"
) | Where-Object { Test-Path $_ } | Select-Object -First 1

if (-not (Test-Tool "7-Zip" { if ($sevenZip) { $sevenZip } else { $null } } "https://www.7-zip.org/")) {
    $ok = $false
}

$mysqlExe = $null
$cmd = Get-Command mysql -ErrorAction SilentlyContinue
if ($cmd) { $mysqlExe = $cmd.Source }
elseif (Test-Path "C:\Program Files\MariaDB 12.3\bin\mysql.exe") {
    $mysqlExe = "C:\Program Files\MariaDB 12.3\bin\mysql.exe"
}

$mysqlOk = Test-Tool "Client mysql (MariaDB)" {
    if ($mysqlExe) { (& $mysqlExe --version 2>&1 | Out-String) } else { $null }
} "Installe MariaDB >= 10.9 : winget install MariaDB.Server"

$svc = Get-Service -Name "MariaDB" -ErrorAction SilentlyContinue
if (-not $svc) {
    $svc = Get-Service -ErrorAction SilentlyContinue | Where-Object {
        $_.Name -match 'maria|mysql' -or $_.DisplayName -match 'Maria|MySQL'
    } | Select-Object -First 1
}
if ($svc) {
    if ($svc.Status -eq "Running") {
        Write-Pass ("Service DB: " + $svc.Name + " (" + $svc.Status + ")")
    } else {
        Write-Warn ("Service DB: " + $svc.Name + " (" + $svc.Status + ") - demarre-le")
        $ok = $false
    }
} else {
    Write-Warn "Aucun service MariaDB detecte"
    Write-Host "      Lance en admin: .\scripts\setup-mariadb.ps1" -ForegroundColor DarkYellow
    $ok = $false
}

$envFile = Join-Path $Root ".env"
if (Test-Path $envFile) {
    Write-Pass "Fichier .env present"
} else {
    Write-Warn "Pas de .env - copie .env.example vers .env"
    Copy-Item (Join-Path $Root ".env.example") $envFile -ErrorAction SilentlyContinue
    if (Test-Path $envFile) {
        Write-Host "      .env cree depuis .env.example - a remplir" -ForegroundColor DarkYellow
    }
}

$fx = Join-Path $Root "server\FXServer.exe"
if (Test-Path $fx) {
    Write-Pass "FXServer.exe trouve"
} else {
    Write-Warn "FXServer.exe manquant"
    Write-Host "      Lance: .\scripts\download-artifacts.ps1" -ForegroundColor DarkYellow
    $ok = $false
}

foreach ($port in @(30120, 40120)) {
    $inUse = Get-NetTCPConnection -LocalPort $port -ErrorAction SilentlyContinue | Select-Object -First 1
    if ($inUse) {
        Write-Warn ("Port " + $port + " deja utilise (PID " + $inUse.OwningProcess + ")")
    } else {
        Write-Pass ("Port " + $port + " libre")
    }
}

Write-Host ""
if ($ok -and $mysqlOk) {
    Write-Host "Environnement pret. Prochaine etape: .\scripts\start-server.ps1" -ForegroundColor Green
} else {
    Write-Host "Corrige les points ci-dessus puis relance ce script." -ForegroundColor Yellow
}
Write-Host ""
