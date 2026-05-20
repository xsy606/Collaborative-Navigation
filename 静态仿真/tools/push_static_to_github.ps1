param(
    [string]$Message = "Update static simulation project"
)

$ErrorActionPreference = "Stop"

$projectRoot = Resolve-Path (Join-Path $PSScriptRoot "..")
$matlabRoot = Split-Path $projectRoot -Parent
$git = Join-Path $matlabRoot ".codex-tools\MinGit\cmd\git.exe"
$keyPath = Join-Path $matlabRoot ".codex-tools\github-keys\collaborative_navigation_deploy_ed25519"
$uploadRoot = Get-ChildItem -Path $matlabRoot -Directory -Filter ".github-upload-static-*" |
    Sort-Object LastWriteTime -Descending |
    Select-Object -First 1 -ExpandProperty FullName

if (!(Test-Path -LiteralPath $git)) {
    throw "Portable Git was not found: $git"
}

if (!(Test-Path -LiteralPath $keyPath)) {
    throw "GitHub deploy key was not found: $keyPath"
}

if (!(Test-Path -LiteralPath $uploadRoot)) {
    throw "Upload worktree was not found under: $matlabRoot"
}

$staticDir = Join-Path $uploadRoot "静态仿真"
New-Item -ItemType Directory -Force -Path $staticDir | Out-Null

$files = & $git -C $projectRoot -c safe.directory=$projectRoot ls-files
foreach ($rel in $files) {
    $from = Join-Path $projectRoot $rel
    $to = Join-Path $staticDir $rel
    $toDir = Split-Path -Parent $to
    if (!(Test-Path -LiteralPath $toDir)) {
        New-Item -ItemType Directory -Force -Path $toDir | Out-Null
    }
    Copy-Item -LiteralPath $from -Destination $to -Force
}

& $git -C $projectRoot -c safe.directory=$projectRoot add .
$localStatus = & $git -C $projectRoot -c safe.directory=$projectRoot status --short
if ($localStatus) {
    & $git -C $projectRoot -c safe.directory=$projectRoot commit -m $Message
}

& $git -C $uploadRoot add "静态仿真"
$uploadStatus = & $git -C $uploadRoot status --short
if ($uploadStatus) {
    & $git -C $uploadRoot commit -m $Message
}

$keyForSsh = $keyPath.Replace("\", "/")
$env:GIT_SSH_COMMAND = "C:/Windows/System32/OpenSSH/ssh.exe -i `"$keyForSsh`" -o IdentitiesOnly=yes -o StrictHostKeyChecking=accept-new"
& $git -C $uploadRoot push origin main

Write-Output "Static simulation project pushed to GitHub."
Write-Output (& $git -C $uploadRoot rev-parse HEAD)
