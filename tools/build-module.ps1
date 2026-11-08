<#
.SYNOPSIS
Packages the KernelSU module files into an installable ZIP.

.DESCRIPTION
The ZIP places module.prop and the install scripts at the archive root, as
required by KernelSU. The default output is dist/adb-over-tcp-at-boot-<version>.zip.

.PARAMETER OutputPath
Optional path for the generated ZIP. Relative paths use the current directory.

.EXAMPLE
pwsh -File tools/build-module.ps1

.EXAMPLE
pwsh -File tools/build-module.ps1 -OutputPath C:\Temp\adb-module.zip
#>
[CmdletBinding()]
param(
    [string]$OutputPath
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

$repoRoot = Split-Path -Parent $PSScriptRoot
$moduleRoot = Join-Path $repoRoot 'modules\adb_tcpip_boot'
$modulePropPath = Join-Path $moduleRoot 'module.prop'
$requiredFiles = @(
    'module.prop',
    'customize.sh',
    'service.sh',
    'action.sh',
    'uninstall.sh',
    'adb_tcpip_common.sh'
)

if (-not (Test-Path -LiteralPath $modulePropPath -PathType Leaf)) {
    throw "KernelSU module metadata not found: $modulePropPath"
}

$moduleProp = Get-Content -LiteralPath $modulePropPath -Raw
if ($moduleProp -notmatch '(?m)^version=(\S+)$') {
    throw "The module version is missing from $modulePropPath"
}
$version = $Matches[1]

$missingFiles = @(
    $requiredFiles | Where-Object {
        -not (Test-Path -LiteralPath (Join-Path $moduleRoot $_) -PathType Leaf)
    }
)
if ($missingFiles.Count -gt 0) {
    throw "Module payload files are missing: $($missingFiles -join ', ')"
}

if ([string]::IsNullOrWhiteSpace($OutputPath)) {
    $OutputPath = Join-Path $repoRoot "dist\adb-over-tcp-at-boot-$version.zip"
}
$outputFile = [IO.Path]::GetFullPath($OutputPath)
$outputDirectory = Split-Path -Parent $outputFile
New-Item -ItemType Directory -Path $outputDirectory -Force | Out-Null

$temporaryZip = Join-Path $outputDirectory "$([IO.Path]::GetFileName($outputFile)).$([guid]::NewGuid().ToString('N')).tmp.zip"
try {
    Compress-Archive -Path (Join-Path $moduleRoot '*') -DestinationPath $temporaryZip -CompressionLevel Optimal

    Add-Type -AssemblyName System.IO.Compression.FileSystem
    $archive = [IO.Compression.ZipFile]::OpenRead($temporaryZip)
    try {
        $archiveFiles = @($archive.Entries | ForEach-Object { $_.FullName })
        $missingEntries = @($requiredFiles | Where-Object { $_ -notin $archiveFiles })
        $unexpectedEntries = @($archiveFiles | Where-Object { $_ -notin $requiredFiles })
        if ($missingEntries.Count -gt 0 -or $unexpectedEntries.Count -gt 0) {
            throw "ZIP layout is invalid. Missing: $($missingEntries -join ', '); unexpected: $($unexpectedEntries -join ', ')"
        }
    }
    finally {
        $archive.Dispose()
    }

    Move-Item -LiteralPath $temporaryZip -Destination $outputFile -Force
    Write-Output "Created $outputFile"
}
finally {
    if (Test-Path -LiteralPath $temporaryZip -PathType Leaf) {
        Remove-Item -LiteralPath $temporaryZip -Force
    }
}
