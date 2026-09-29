$ErrorActionPreference = 'Stop'
$root = Split-Path $PSScriptRoot -Parent
$artifacts = Join-Path $root 'artifacts-test'

& (Join-Path $PSScriptRoot 'Invoke-Dbvc.ps1') -Action Validate
if ($LASTEXITCODE -ne 0) { throw 'Validate action failed.' }

& (Join-Path $PSScriptRoot 'Invoke-Dbvc.ps1') -Action Plan -ArtifactsPath $artifacts
if ($LASTEXITCODE -ne 0) { throw 'Plan action failed.' }

$manifest = Get-Content -LiteralPath (Join-Path $artifacts 'migration-plan.json') -Raw | ConvertFrom-Json
if ($manifest.migrationCount -ne 3) { throw 'Expected three generic migrations.' }
if ($manifest.rollbackCoveragePercent -ne 100) { throw 'Rollback coverage must remain 100 percent.' }
if (@($manifest.migrations | Where-Object { $_.sha256 -notmatch '^[a-f0-9]{64}$' }).Count -gt 0) {
    throw 'Every migration must have a SHA-256 checksum.'
}
Write-Host 'OK: DBVC engine validation and manifest tests passed.'
