# Reticle local launcher
# Usage: powershell -ExecutionPolicy Bypass -File .\start-all.ps1
$ErrorActionPreference = "Stop"
$root = $PSScriptRoot
$runtime = Join-Path $root ".runtime"
New-Item -ItemType Directory -Force -Path $runtime | Out-Null

function Test-Port([int]$Port) {
    # netstat is used instead of Get-NetTCPConnection: the latter can return
    # empty results under restricted/sandboxed tokens even when a port listens.
    $hit = netstat -ano -p tcp | Select-String "LISTENING" | Select-String ":$Port\s"
    return [bool]$hit
}

function Wait-Http([string]$Url, [int]$TimeoutSeconds = 90) {
    $deadline = (Get-Date).AddSeconds($TimeoutSeconds)
    while ((Get-Date) -lt $deadline) {
        try {
            $r = Invoke-WebRequest -Uri $Url -TimeoutSec 3 -UseBasicParsing
            if ($r.StatusCode -eq 200) { return $true }
        } catch { }
        Start-Sleep -Milliseconds 800
    }
    return $false
}

# ---------- 1. PostgreSQL ----------
if (-not (Test-Port 5432)) {
    Write-Host "[1/3] starting PostgreSQL ..."
    $pgbin = Join-Path $root ".conda\envs\pg\Library\bin"
    $pgdata = Join-Path $root "pgdata"
    $pglog = Join-Path $runtime "pg.log"
    # Start-Process keeps postgres from inheriting this console's stdio pipes,
    # which otherwise makes the launcher hang after the server has started.
    # Do NOT use -Wait here: it would wait for the postgres process tree.
    Start-Process -FilePath (Join-Path $pgbin "pg_ctl.exe") `
        -ArgumentList "-D `"$pgdata`" -l `"$pglog`" -o `"-p 5432`" -w start" `
        -WindowStyle Hidden `
        -RedirectStandardOutput (Join-Path $runtime "pgctl.out.log") `
        -RedirectStandardError  (Join-Path $runtime "pgctl.err.log") | Out-Null
    $deadline = (Get-Date).AddSeconds(45)
    while ((Get-Date) -lt $deadline -and -not (Test-Port 5432)) { Start-Sleep -Milliseconds 500 }
    if (-not (Test-Port 5432)) { throw "PostgreSQL failed to start, see .runtime\pg.log" }
} else {
    Write-Host "[1/3] PostgreSQL already running on 5432"
}

# ---------- 2. FastAPI backend ----------
if (-not (Test-Port 8000)) {
    Write-Host "[2/3] starting FastAPI backend ..."
    $pyenv = Join-Path $root ".conda\envs\backend"
    $env:PATH = (Join-Path $pyenv "Library\bin") + ";" + $pyenv + ";" + (Join-Path $pyenv "Scripts") + ";" + $env:PATH
    $env:PYTHONUNBUFFERED = "1"
    Start-Process -FilePath (Join-Path $pyenv "python.exe") `
        -ArgumentList "-m", "uvicorn", "backend.api.app:app", "--host", "127.0.0.1", "--port", "8000" `
        -WorkingDirectory $root `
        -RedirectStandardOutput (Join-Path $runtime "backend.out.log") `
        -RedirectStandardError  (Join-Path $runtime "backend.err.log") `
        -WindowStyle Hidden | Out-Null
    if (-not (Wait-Http "http://127.0.0.1:8000/api/v1/health" 90)) {
        throw "backend failed to start, see .runtime\backend.err.log"
    }
} else {
    Write-Host "[2/3] backend already running on 8000"
}

# ---------- 3. Vite frontend ----------
if (-not (Test-Port 5173)) {
    Write-Host "[3/3] starting Vite frontend ..."
    $env:npm_config_cache = Join-Path $root ".npm-cache"
    Start-Process -FilePath "cmd.exe" `
        -ArgumentList "/c", "npm run dev > `"$runtime\frontend.log`" 2>&1" `
        -WorkingDirectory (Join-Path $root "frontend") -WindowStyle Hidden | Out-Null
    if (-not (Wait-Http "http://127.0.0.1:5173/" 90)) {
        throw "frontend failed to start, see .runtime\frontend.log"
    }
} else {
    Write-Host "[3/3] frontend already running on 5173"
}

Write-Host ""
Write-Host "ready:"
Write-Host "  frontend  http://127.0.0.1:5173"
Write-Host "  api docs  http://127.0.0.1:8000/docs"
Write-Host "  health    http://127.0.0.1:8000/api/v1/health"
Write-Host "  account   demo_auditor / demo-pass-123"
