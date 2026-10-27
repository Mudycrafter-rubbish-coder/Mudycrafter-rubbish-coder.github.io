$ErrorActionPreference = "Stop"

$repoRoot = Split-Path -Parent $PSScriptRoot
$toolsRoot = Join-Path $env:TEMP "luau-portfolio-tools"
$luauRoot = Join-Path $toolsRoot "luau-0.744"
$luneRoot = Join-Path $toolsRoot "lune-0.11.1"

New-Item -ItemType Directory -Force -Path $luauRoot, $luneRoot | Out-Null

$luauZip = Join-Path $luauRoot "luau-windows.zip"
$luneZip = Join-Path $luneRoot "lune-windows.zip"
$luauAnalyzer = Join-Path $luauRoot "luau-analyze.exe"
$lune = Join-Path $luneRoot "lune.exe"

$luauUrl = "https://github.com/luau-lang/luau/releases/download/0.744/luau-windows.zip"
$luneUrl = "https://github.com/lune-org/lune/releases/download/v0.11.1/lune-0.11.1-windows-x86_64.zip"
$luauSha256 = "fde3e22c557aac6afe20a34e8050b7d8c290fa42638c04274a307ed5d0ef0db8"
$luneSha256 = "83f1dc29d9e35c494907521f2ca6561f6c204fdf6f1b06525d2e9fdd1e6b4301"

if (-not (Test-Path -LiteralPath $luauAnalyzer)) {
    Invoke-WebRequest -Uri $luauUrl -OutFile $luauZip
    if ((Get-FileHash -LiteralPath $luauZip -Algorithm SHA256).Hash.ToLowerInvariant() -ne $luauSha256) {
        throw "Luau archive checksum mismatch"
    }
    Expand-Archive -LiteralPath $luauZip -DestinationPath $luauRoot -Force
}

if (-not (Test-Path -LiteralPath $lune)) {
    Invoke-WebRequest -Uri $luneUrl -OutFile $luneZip
    if ((Get-FileHash -LiteralPath $luneZip -Algorithm SHA256).Hash.ToLowerInvariant() -ne $luneSha256) {
        throw "Lune archive checksum mismatch"
    }
    Expand-Archive -LiteralPath $luneZip -DestinationPath $luneRoot -Force
}

Push-Location $repoRoot
try {
    & $luauAnalyzer `
        .\src\Pathfinding.lua `
        .\src\AI.lua `
        .\src\Spatial.lua `
        .\src\Gameplay.lua `
        .\src\Procedural.lua `
        .\tests\run.lua
    if ($LASTEXITCODE -ne 0) {
        throw "Luau static analysis failed"
    }

    & $lune run .\tests\run.lua
    if ($LASTEXITCODE -ne 0) {
        throw "Luau runtime tests failed"
    }
}
finally {
    Pop-Location
}
