# Switch the LLM API key (and optionally base URL / model), then restart the backend.
# Usage:
#   powershell -ExecutionPolicy Bypass -File .\switch-llm-key.ps1 -ApiKey "sk-xxxx"
#   powershell -ExecutionPolicy Bypass -File .\switch-llm-key.ps1 -ApiKey "sk-xxxx" -BaseUrl "https://api.deepseek.com" -Model "deepseek-chat"
param(
    [Parameter(Mandatory = $true)][string]$ApiKey,
    [string]$BaseUrl = "",
    [string]$Model = ""
)

$ErrorActionPreference = "Stop"
$root = $PSScriptRoot
$envPath = Join-Path $root ".env"

if (-not (Test-Path $envPath)) { throw ".env not found: $envPath" }

# 1. backup
$stamp = Get-Date -Format "yyyyMMdd-HHmmss"
Copy-Item $envPath "$envPath.bak-$stamp" -Force
Write-Host "[1/4] backup -> .env.bak-$stamp"

# 2. update values
$lines = @(Get-Content $envPath)
$keyFound = $false
for ($i = 0; $i -lt $lines.Count; $i++) {
    if ($lines[$i] -match '^SCG_LLM_API_KEY=') {
        $lines[$i] = "SCG_LLM_API_KEY=$ApiKey"
        $keyFound = $true
    } elseif ($BaseUrl -and $lines[$i] -match '^SCG_LLM_BASE_URL=') {
        $lines[$i] = "SCG_LLM_BASE_URL=$BaseUrl"
    } elseif ($Model -and $lines[$i] -match '^SCG_LLM_MODEL=') {
        $lines[$i] = "SCG_LLM_MODEL=$Model"
    }
}
if (-not $keyFound) { $lines += "SCG_LLM_API_KEY=$ApiKey" }
Set-Content -Path $envPath -Value $lines -Encoding UTF8
Write-Host "[2/4] .env updated (key length=$($ApiKey.Length))"

# 3. restart backend on port 8000
$conn = netstat -ano -p tcp | Select-String "LISTENING" | Select-String ":8000\s"
if ($conn) {
    $procId = ($conn.Line -split '\s+')[-1]
    Stop-Process -Id $procId -Force -ErrorAction SilentlyContinue
    Write-Host "[3/4] stopped old backend (PID=$procId)"
} else {
    Write-Host "[3/4] backend was not running"
}
Start-Sleep -Seconds 2

$pyenv = Join-Path $root ".conda\envs\backend"
$env:PATH = (Join-Path $pyenv "Library\bin") + ";" + $pyenv + ";" + (Join-Path $pyenv "Scripts") + ";" + $env:PATH
$env:PYTHONUNBUFFERED = "1"
$runtime = Join-Path $root ".runtime"
New-Item -ItemType Directory -Force -Path $runtime | Out-Null
Start-Process -FilePath (Join-Path $pyenv "python.exe") `
    -ArgumentList "-m", "uvicorn", "backend.api.app:app", "--host", "127.0.0.1", "--port", "8000" `
    -WorkingDirectory $root `
    -RedirectStandardOutput (Join-Path $runtime "backend.out.log") `
    -RedirectStandardError  (Join-Path $runtime "backend.err.log") `
    -WindowStyle Hidden | Out-Null

$ok = $false
for ($i = 0; $i -lt 60; $i++) {
    Start-Sleep -Milliseconds 800
    try {
        $h = Invoke-RestMethod -Uri "http://127.0.0.1:8000/api/v1/health" -TimeoutSec 3
        if ($h.status -eq "ok") { $ok = $true; break }
    } catch { }
}
if (-not $ok) { throw "backend failed to start, see .runtime\backend.err.log" }
Write-Host "[4/4] backend is up"

# 4. probe LLM
Write-Host "probing LLM ..."
try {
    $s = Invoke-RestMethod -Uri "http://127.0.0.1:8000/api/v1/llm/status?probe=true" -TimeoutSec 90
    Write-Host ("reachable={0}" -f $s.reachable)
    if ($s.message) { Write-Host ("message=" + $s.message) }
} catch {
    Write-Host ("probe failed: " + $_.Exception.Message)
}
