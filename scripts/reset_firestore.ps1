param(
  [switch]$Confirm,
  [switch]$All,
  [string]$Project = "greenfestival-5320b",
  [string]$ServiceAccount = "",
  [int]$BatchSize = 250
)

$ErrorActionPreference = "Stop"

$repoRoot = Resolve-Path (Join-Path $PSScriptRoot "..")
$dartArgs = @(
  "run",
  "tool/reset_firestore.dart",
  "--project",
  $Project,
  "--batch-size",
  [string]$BatchSize
)

if ($ServiceAccount) {
  $dartArgs += @("--service-account", $ServiceAccount)
}

if ($Confirm) {
  $dartArgs += "--confirm"
}

if ($All) {
  $dartArgs += "--all"
}

Push-Location $repoRoot
try {
  dart @dartArgs
} finally {
  Pop-Location
}
