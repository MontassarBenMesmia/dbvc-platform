[CmdletBinding()]
param(
    [ValidateSet('Validate', 'Plan', 'Verify', 'Apply')]
    [string]$Action = 'Validate',
    [string]$MigrationsPath = (Join-Path $PSScriptRoot '..\database\migrations'),
    [string]$RollbackPath = (Join-Path $PSScriptRoot '..\database\rollback'),
    [string]$ArtifactsPath = (Join-Path $PSScriptRoot '..\artifacts'),
    [string]$Server = $env:DBVC_SQLSERVER_HOST,
    [string]$Database = $env:DBVC_SQLSERVER_DATABASE,
    [string]$Username = $env:DBVC_SQLSERVER_USER,
    [string]$Password = $env:DBVC_SQLSERVER_PASSWORD,
    [string]$BackupPath = ''
)

$ErrorActionPreference = 'Stop'

function Assert-SafeIdentifier([string]$Value, [string]$Label) {
    if ([string]::IsNullOrWhiteSpace($Value) -or $Value -notmatch '^[A-Za-z0-9_.\\-]+$') {
        throw "$Label contains unsupported characters."
    }
}

function Get-MigrationCatalog {
    if (-not (Test-Path -LiteralPath $MigrationsPath -PathType Container)) {
        throw "Migration directory not found: $MigrationsPath"
    }
    if (-not (Test-Path -LiteralPath $RollbackPath -PathType Container)) {
        throw "Rollback directory not found: $RollbackPath"
    }

    $catalog = foreach ($file in Get-ChildItem -LiteralPath $MigrationsPath -File -Filter '*.up.sql' | Sort-Object Name) {
        if ($file.Name -notmatch '^(\d{3})_([A-Za-z0-9_]+)\.up\.sql$') {
            throw "Invalid migration filename: $($file.Name). Expected NNN_name.up.sql."
        }
        $version = $Matches[1]
        $name = $Matches[2]
        $rollbackFile = Join-Path $RollbackPath "$version`_$name.down.sql"
        if (-not (Test-Path -LiteralPath $rollbackFile -PathType Leaf)) {
            throw "Missing rollback companion for migration $version`: $rollbackFile"
        }

        $content = Get-Content -LiteralPath $file.FullName -Raw
        if ($content -match '(?im)^\s*USE\s+') {
            throw "Migration $($file.Name) contains USE. The target database must come from the runner."
        }

        [pscustomobject]@{
            version = $version
            name = $name.Replace('_', ' ')
            file = $file.Name
            rollbackFile = [System.IO.Path]::GetFileName($rollbackFile)
            sha256 = (Get-FileHash -LiteralPath $file.FullName -Algorithm SHA256).Hash.ToLowerInvariant()
            rollbackSha256 = (Get-FileHash -LiteralPath $rollbackFile -Algorithm SHA256).Hash.ToLowerInvariant()
            fullPath = $file.FullName
        }
    }

    if (@($catalog).Count -eq 0) { throw 'At least one migration is required.' }
    $versions = @($catalog.version)
    if (@($versions | Select-Object -Unique).Count -ne $versions.Count) { throw 'Migration versions must be unique.' }

    for ($index = 0; $index -lt $versions.Count; $index++) {
        $expected = '{0:D3}' -f ($index + 1)
        if ($versions[$index] -ne $expected) {
            throw "Migration sequence has a gap: expected $expected but found $($versions[$index])."
        }
    }
    return @($catalog)
}

function Invoke-SqlCmdFile([string]$InputFile) {
    Assert-SafeIdentifier $Server 'Server'
    Assert-SafeIdentifier $Database 'Database'
    $arguments = @('-S', $Server, '-d', $Database, '-b', '-r', '1', '-i', $InputFile)
    $previousSqlCmdPassword = $env:SQLCMDPASSWORD
    if (-not [string]::IsNullOrWhiteSpace($Username)) {
        if ([string]::IsNullOrWhiteSpace($Password)) { throw 'DBVC_SQLSERVER_PASSWORD is required when a username is provided.' }
        $arguments += @('-U', $Username)
        $env:SQLCMDPASSWORD = $Password
    } else {
        $arguments += '-E'
    }
    try {
        & sqlcmd @arguments
        if ($LASTEXITCODE -ne 0) { throw "sqlcmd failed with exit code $LASTEXITCODE." }
    } finally {
        $env:SQLCMDPASSWORD = $previousSqlCmdPassword
    }
}

function New-CombinedSql([object[]]$Catalog, [bool]$RollbackAtEnd) {
    $lines = [System.Collections.Generic.List[string]]::new()
    $lines.Add('SET NOCOUNT ON;')
    $lines.Add('SET XACT_ABORT ON;')
    $lines.Add('BEGIN TRANSACTION;')
    foreach ($migration in $Catalog) {
        $lines.Add("PRINT 'DBVC applying $($migration.version) $($migration.name)';")
        $lines.Add((Get-Content -LiteralPath $migration.fullPath -Raw))
        $escapedName = $migration.name.Replace("'", "''")
        $lines.Add("IF OBJECT_ID('dbo.dbvc_schema_version', 'U') IS NOT NULL AND NOT EXISTS (SELECT 1 FROM dbo.dbvc_schema_version WHERE version = '$($migration.version)') INSERT INTO dbo.dbvc_schema_version(version, name, checksum_sha256, applied_at_utc) VALUES ('$($migration.version)', '$escapedName', '$($migration.sha256)', SYSUTCDATETIME());")
    }
    $lines.Add($(if ($RollbackAtEnd) { "ROLLBACK TRANSACTION; PRINT 'DBVC verification rolled back successfully.';" } else { "COMMIT TRANSACTION; PRINT 'DBVC apply committed successfully.';" }))
    return $lines -join [Environment]::NewLine
}

$catalog = Get-MigrationCatalog
Write-Host "Validated $($catalog.Count) ordered migration(s) with complete rollback coverage."

if ($Action -eq 'Validate') { exit 0 }

New-Item -ItemType Directory -Path $ArtifactsPath -Force | Out-Null
$manifestPath = Join-Path $ArtifactsPath 'migration-plan.json'
$manifest = [ordered]@{
    formatVersion = 1
    generatedAtUtc = [DateTime]::UtcNow.ToString('o')
    migrationCount = $catalog.Count
    rollbackCoveragePercent = 100
    migrations = @($catalog | Select-Object version, name, file, rollbackFile, sha256, rollbackSha256)
}
$manifest | ConvertTo-Json -Depth 5 | Set-Content -LiteralPath $manifestPath -Encoding utf8
Write-Host "ARTIFACT_MANIFEST=$manifestPath"

if ($Action -eq 'Plan') { exit 0 }
if (-not (Get-Command sqlcmd -ErrorAction SilentlyContinue)) { throw 'sqlcmd is required for Verify and Apply.' }

$combinedPath = Join-Path $ArtifactsPath $(if ($Action -eq 'Verify') { 'verify.sql' } else { 'apply.sql' })
New-CombinedSql $catalog ($Action -eq 'Verify') | Set-Content -LiteralPath $combinedPath -Encoding utf8

if ($Action -eq 'Verify') {
    Invoke-SqlCmdFile $combinedPath
    Write-Host 'Verification succeeded and all changes were rolled back.'
    exit 0
}

if ($env:DBVC_ALLOW_DATABASE_WRITES -ne 'true') {
    throw 'Apply is disabled. Set DBVC_ALLOW_DATABASE_WRITES=true only in an approved environment.'
}
if ([string]::IsNullOrWhiteSpace($BackupPath)) {
    throw 'Apply requires -BackupPath so a SQL Server backup is created first.'
}
$escapedBackup = $BackupPath.Replace("'", "''")
$backupSqlPath = Join-Path $ArtifactsPath 'backup.sql'
"BACKUP DATABASE [$Database] TO DISK = N'$escapedBackup' WITH INIT, CHECKSUM;" | Set-Content -LiteralPath $backupSqlPath -Encoding utf8
Invoke-SqlCmdFile $backupSqlPath
Invoke-SqlCmdFile $combinedPath
Write-Host 'Apply succeeded after a checksum-protected backup.'
