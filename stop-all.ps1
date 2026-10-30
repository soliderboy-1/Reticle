# Stop Reticle local services
# Usage: powershell -ExecutionPolicy Bypass -File .\stop-all.ps1
$ErrorActionPreference = "Continue"
$root = $PSScriptRoot

function Stop-Port([int]$Port, [string]$Name) {
    $lines = netstat -ano -p tcp | Select-String "LISTENING" | Select-String ":$Port\s"
    if (-not $lines) { Write-Host "$Name ($Port) not running"; return }
    $pids = $lines | ForEach-Object { ($_.Line -split '\s+')[-1] } | Sort-Object -Unique
    foreach ($procId in $pids) {
        try {
            Stop-Process -Id $procId -Force -ErrorAction Stop
            Write-Host "$Name ($Port) stopped, PID=$procId"
        } catch { Write-Host "$Name ($Port) stop failed: $($_.Exception.Message)" }
    }
}

Stop-Port 5173 "frontend"
Stop-Port 8000 "backend"

$pgbin = Join-Path $root ".conda\envs\pg\Library\bin"
$data = Join-Path $root "pgdata"
if (Test-Path (Join-Path $data "postmaster.pid")) {
    & (Join-Path $pgbin "pg_ctl.exe") -D $data -m fast -w stop | Out-Null
    Write-Host "PostgreSQL stopped"
} else {
    Write-Host "PostgreSQL not running"
}
