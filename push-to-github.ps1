# Push this repository to GitHub.
# Run this in a NORMAL PowerShell window (not inside a sandboxed shell).
#
# Usage:
#   powershell -ExecutionPolicy Bypass -File .\push-to-github.ps1 `
#       -RepoUrl "https://github.com/<user>/<repo>.git" `
#       -UserName "Your Name" -UserEmail "you@example.com"
#
param(
    [Parameter(Mandatory = $true)][string]$RepoUrl,
    [string]$UserName = "",
    [string]$UserEmail = ""
)

$ErrorActionPreference = "Stop"
$root = $PSScriptRoot
Set-Location $root

if (-not (Test-Path (Join-Path $root ".git"))) { throw "Not a git repository: $root" }
if ($RepoUrl -notmatch '^https://github\.com/.+/.+') {
    Write-Host "WARN: URL does not look like https://github.com/<user>/<repo>.git" -ForegroundColor Yellow
}

# 1. author
if ($UserName)  { git config user.name  $UserName }
if ($UserEmail) { git config user.email $UserEmail }
if ($UserName -or $UserEmail) {
    git commit --amend --reset-author --no-edit | Out-Null
    Write-Host ("[1/4] author = " + (git log -1 --format="%an <%ae>"))
} else {
    Write-Host ("[1/4] keeping author = " + (git log -1 --format="%an <%ae>"))
}

# 2. remote
$remotes = @(git remote)
if ($remotes -contains "origin") {
    git remote set-url origin $RepoUrl
} else {
    git remote add origin $RepoUrl
}
Write-Host "[2/4] origin -> $RepoUrl"

# 3. push
Write-Host "[3/4] pushing to origin/main ..."
git push -u origin main
$code = $LASTEXITCODE

# 4. result
if ($code -eq 0) {
    Write-Host "[4/4] done. Open: $($RepoUrl -replace '\.git$','')" -ForegroundColor Green
    exit 0
}

Write-Host "[4/4] push failed (exit $code)." -ForegroundColor Red
Write-Host ""
Write-Host "Common fixes:"
Write-Host "  Authentication failed:"
Write-Host "    - Use a Personal Access Token as the password (GitHub no longer accepts account passwords)"
Write-Host "    - or sign in through Git Credential Manager when the browser opens"
Write-Host ""
Write-Host "  rejected / fetch first (repo already has commits):"
Write-Host "    git pull --rebase origin main"
Write-Host "    git push -u origin main"
Write-Host "    # if unrelated histories:"
Write-Host "    git pull origin main --allow-unrelated-histories"
Write-Host ""
Write-Host "  remote has a different default branch (e.g. master):"
Write-Host "    git push -u origin main    # then change the default branch in repo Settings"
exit 1
