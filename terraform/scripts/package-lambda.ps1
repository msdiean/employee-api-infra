param(
  [string]$SourcePath = (Join-Path $PSScriptRoot "..\..\..\employee-api"),
  [string]$OutputPath = (Join-Path $PSScriptRoot "..\employee-api.zip")
)

$ErrorActionPreference = "Stop"

$sourceFullPath = [System.IO.Path]::GetFullPath($SourcePath)
$outputFullPath = [System.IO.Path]::GetFullPath($OutputPath)

if (-not (Test-Path -Path $sourceFullPath -PathType Container)) {
  throw "Source path does not exist: $sourceFullPath"
}

$newItem = New-Item -ItemType Directory -Path (Split-Path -Parent $outputFullPath) -Force
if (Test-Path -Path $outputFullPath) {
  Remove-Item -Path $outputFullPath -Force
}

$stagingDir = Join-Path ([System.IO.Path]::GetTempPath()) ("lambda-package-" + [System.Guid]::NewGuid().ToString("N"))
New-Item -ItemType Directory -Path $stagingDir -Force | Out-Null

try {
  foreach ($item in @("src", "package.json", "package-lock.json")) {
    $sourceItem = Join-Path $sourceFullPath $item
    if (Test-Path -Path $sourceItem) {
      Copy-Item -Path $sourceItem -Destination $stagingDir -Recurse -Force
    }
  }

  if (Test-Path -Path (Join-Path $sourceFullPath "node_modules")) {
    Copy-Item -Path (Join-Path $sourceFullPath "node_modules") -Destination $stagingDir -Recurse -Force
  }

  Compress-Archive -Path (Join-Path $stagingDir "*") -DestinationPath $outputFullPath -Force
  Write-Host "Created Lambda package: $outputFullPath"
}
finally {
  if (Test-Path -Path $stagingDir) {
    Remove-Item -Path $stagingDir -Recurse -Force
  }
}
