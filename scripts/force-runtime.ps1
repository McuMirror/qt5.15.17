param(
    [Parameter(Mandatory=$true)][string]$TargetPath,
    [Parameter(Mandatory=$true)][string]$RuntimeFlag
)

$ErrorActionPreference = 'Stop'

if (-not (Test-Path -LiteralPath $TargetPath)) {
    Write-Error "Makefile not found: $TargetPath"
    exit 1
}

$content = [System.IO.File]::ReadAllText($TargetPath)
$updated = [System.Text.RegularExpressions.Regex]::Replace($content, '/M[TD]d?', $RuntimeFlag)
[System.IO.File]::WriteAllText($TargetPath, $updated, [System.Text.Encoding]::ASCII)
