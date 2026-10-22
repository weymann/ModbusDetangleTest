#requires -Version 5.1
<#
.SYNOPSIS
  Creates an openHAB 5.3 snapshot instance that uses the split Modbus add-ons from this package.

.PARAMETER Mode
  Fresh   = blank 5.3 instance.
  Upgrade = 5.3 instance that takes over conf and userdata of an existing 5.2 instance (-From).

.EXAMPLE
  .\Setup-OpenHabTest.ps1 -Mode Fresh -Target C:\oh\oh53-fresh
  .\Setup-OpenHabTest.ps1 -Mode Upgrade -From C:\oh\oh52 -Target C:\oh\oh53-upgrade
#>
param(
    [Parameter(Mandatory = $true)][ValidateSet('Fresh', 'Upgrade')][string]$Mode,
    [Parameter(Mandatory = $true)][string]$Target,
    [string]$From,
    [string]$DistroUrl = 'https://openhab.jfrog.io/artifactory/libs-snapshot/org/openhab/distro/openhab/5.3.0-SNAPSHOT/openhab-5.3.0-20261020.160808-146.zip'
)

$ErrorActionPreference = 'Stop'
$pkg = $PSScriptRoot

function ToUri([string]$p) { return 'file:///' + ((Resolve-Path $p).Path -replace '\\', '/') }

# --- checks
$javaOut = & cmd /c "java -version 2>&1"
if (($javaOut | Select-Object -First 1) -notmatch '"(2[1-9]|[3-9]\d)\.') {
    throw "Java 21 or newer is required. Found: $($javaOut | Select-Object -First 1)"
}
if (Test-Path $Target) { throw "Target '$Target' already exists. Choose a new folder." }
if ($Mode -eq 'Upgrade') {
    if (-not $From) { throw 'Mode Upgrade needs -From <path of the stopped 5.2 instance>.' }
    if (-not (Test-Path (Join-Path $From 'conf')) -or -not (Test-Path (Join-Path $From 'userdata'))) {
        throw "'$From' does not look like an openHAB folder (conf or userdata missing)."
    }
    if (Test-Path (Join-Path $From 'userdata\tmp\instances\instance.properties')) {
        Write-Warning 'Found Karaf instance data in the 5.2 folder. Make sure openHAB 5.2 is stopped before you continue.'
    }
}

# --- download and extract
$zip = Join-Path $env:TEMP 'openhab-5.3-snapshot.zip'
if (-not (Test-Path $zip)) {
    Write-Host "Downloading $DistroUrl"
    Invoke-WebRequest -Uri $DistroUrl -OutFile $zip
}
Write-Host "Extracting to $Target"
Expand-Archive -Path $zip -DestinationPath $Target

# --- upgrade: take over conf and userdata (without cache, tmp, logs), keep the fresh userdata\etc
if ($Mode -eq 'Upgrade') {
    $freshEtc = Join-Path $env:TEMP ('oh53-etc-' + [guid]::NewGuid())
    Copy-Item (Join-Path $Target 'userdata\etc') $freshEtc -Recurse
    Remove-Item (Join-Path $Target 'conf') -Recurse -Force
    Remove-Item (Join-Path $Target 'userdata') -Recurse -Force
    & robocopy (Join-Path $From 'conf') (Join-Path $Target 'conf') /E /NFL /NDL /NJH /NJS | Out-Null
    & robocopy (Join-Path $From 'userdata') (Join-Path $Target 'userdata') /E /XD cache tmp logs /NFL /NDL /NJH /NJS | Out-Null
    Remove-Item (Join-Path $Target 'userdata\etc') -Recurse -Force -ErrorAction SilentlyContinue
    Copy-Item $freshEtc (Join-Path $Target 'userdata\etc') -Recurse
    Remove-Item $freshEtc -Recurse -Force
}

# --- point the instance to the local Modbus features and the local Maven repository
$featuresUri = ToUri (Join-Path $pkg 'modbus-features.xml')
$repoUri = ToUri (Join-Path $pkg 'repo')

$featuresCfg = Join-Path $Target 'userdata\etc\org.apache.karaf.features.cfg'
$txt = Get-Content $featuresCfg -Raw
$new = [regex]::Replace($txt, 'mvn:org\.openhab\.distro/openhab-addons/[^\s,\\]+', $featuresUri)
if ($new -eq $txt) { throw 'openhab-addons feature repository not found in org.apache.karaf.features.cfg.' }
Set-Content $featuresCfg $new -NoNewline

$paxCfg = Join-Path $Target 'userdata\etc\org.ops4j.pax.url.mvn.cfg'
$txt = Get-Content $paxCfg -Raw
$marker = 'org.ops4j.pax.url.mvn.defaultRepositories=\'
$idx = $txt.IndexOf($marker)
if ($idx -lt 0) { throw 'defaultRepositories not found in org.ops4j.pax.url.mvn.cfg.' }
$nl = if ($txt.Contains("`r`n")) { "`r`n" } else { "`n" }
$eol = $txt.IndexOf("`n", $idx)
$txt = $txt.Insert($eol + 1, "    $repoUri@id=local.repository@snapshots, \" + $nl)
Set-Content $paxCfg $txt -NoNewline

Write-Host ''
Write-Host "Done. Start with: $Target\start.bat" -ForegroundColor Green
Write-Host 'UI: http://localhost:8080  (Settings > Add-ons)'
Write-Host "Log: $Target\userdata\logs\openhab.log"
