# Run from Windows with the official Godot Standard console executable.
[CmdletBinding()]
param([Parameter(Mandatory = $true)][string]$Godot)

$ErrorActionPreference = 'Stop'
$Godot = (Resolve-Path -LiteralPath $Godot).Path
$Root = (Resolve-Path -LiteralPath (Join-Path $PSScriptRoot '..')).Path
$BuildRoot = Join-Path $Root 'build'
$Out = Join-Path $BuildRoot 'windows-acceptance'
$Exe = Join-Path $Out 'TheLastHaven.exe'
$Pck = Join-Path $Out 'TheLastHaven.pck'
$Archive = Join-Path $BuildRoot 'TheLastHaven-Windows-x64-acceptance.zip'

$Version = (& $Godot --version | Out-String).Trim()
if ($LASTEXITCODE -ne 0 -or $Version -notmatch '^4\.7\.2\.stable\.official\.' -or $Version -match 'mono') {
    throw "Use the official Godot 4.7.2 Stable Standard console executable. Found '$Version'."
}

New-Item -ItemType Directory -Path $Out -Force | Out-Null
New-Item -ItemType File -Path (Join-Path $BuildRoot '.gdignore') -Force | Out-Null
foreach ($Old in @($Exe, $Pck, $Archive)) {
    if (Test-Path -LiteralPath $Old) { Remove-Item -LiteralPath $Old }
}

& $Godot --headless --path $Root --editor --import
if ($LASTEXITCODE -ne 0) { throw 'Godot import failed.' }
& $Godot --headless --path $Root --export-release 'Windows x64' $Exe
if ($LASTEXITCODE -ne 0 -or !(Test-Path -LiteralPath $Exe) -or !(Test-Path -LiteralPath $Pck)) {
    throw 'Export failed. Install the official 4.7.2 Standard export templates in Editor > Manage Export Templates.'
}

Copy-Item -LiteralPath (Join-Path $Root 'assets/fonts/OFL.txt') -Destination (Join-Path $Out 'Vazirmatn-OFL.txt') -Force
Copy-Item -LiteralPath (Join-Path $Root 'docs/ASSET_LICENSES.md') -Destination $Out -Force
Copy-Item -LiteralPath (Join-Path $Root 'docs/WINDOWS_ACCEPTANCE.md') -Destination $Out -Force
$Manifest = @($Exe, $Pck, (Join-Path $Out 'Vazirmatn-OFL.txt'), (Join-Path $Out 'ASSET_LICENSES.md'), (Join-Path $Out 'WINDOWS_ACCEPTANCE.md'))
Compress-Archive -LiteralPath $Manifest -DestinationPath $Archive
Get-FileHash -LiteralPath $Archive -Algorithm SHA256
Write-Host "Windows acceptance package: $Archive (not yet runtime tested)"
