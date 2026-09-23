# ===========================================================================
# AEDI - IONITY GLOBAL | Ionity Lab control
# Doc ID: DOC-2026-09-IONITY-LAB | Policy 986 AED
# (c) 2018-2026 Antwerp Designs | Ionity (Pty) Ltd
# ---------------------------------------------------------------------------
#   lab.ps1 start      broker, then every registered project's start script
#   lab.ps1 restart    stop the broker + projects, then start
#   lab.ps1 broker     only make sure the lab MQTT broker is up (projects call this)
#   lab.ps1 stop       stop the broker (projects stop their own services)
#   lab.ps1 status     health check (network\lab_status.ps1)
#   lab.ps1 setup      create .venv and install the broker (first run on a new PC)
# Idempotent: safe to run any number of times.
# ===========================================================================
param([ValidateSet('start','restart','broker','stop','status','setup')][string]$Action = 'start',
      [switch]$Quiet)
$root = $PSScriptRoot
$cfg  = Get-Content (Join-Path $root 'lab.json') -Raw | ConvertFrom-Json
$py   = Join-Path $root "$($cfg.broker.venv)\Scripts\pythonw.exe"
$port = [int]($cfg.broker.bind -split ':')[-1]
New-Item -ItemType Directory -Force (Join-Path $root 'data') | Out-Null

function Say($m) { if (-not $Quiet) { Write-Host "[ionity-lab] $m" } }
function Listening($p) { [bool](Get-NetTCPConnection -LocalPort $p -State Listen -ErrorAction SilentlyContinue) }
function BrokerProcs {
  @(Get-CimInstance Win32_Process -Filter "Name like 'python%'" -ErrorAction SilentlyContinue |
    Where-Object { $_.CommandLine -like '*run_broker.py*' })
}

function Setup {
  $sysPy = (Get-Command python -ErrorAction SilentlyContinue).Source
  if (Test-Path 'C:\Python314\python.exe') { $sysPy = 'C:\Python314\python.exe' }
  if (-not $sysPy) { throw 'Python 3.12+ is not installed' }
  Say "creating $($cfg.broker.venv) with $sysPy"
  & $sysPy -m venv (Join-Path $root $cfg.broker.venv)
  & (Join-Path $root "$($cfg.broker.venv)\Scripts\python.exe") -m pip install -q -r (Join-Path $root 'broker\requirements.txt')
  Say 'broker installed'
}

function Broker {
  if (Listening $port) { Say "broker        already up on :$port"; return }
  if (-not (Test-Path $py)) { Setup }
  Say "broker        starting on $($cfg.broker.bind)"
  Start-Process -FilePath $py -ArgumentList "`"$root\broker\run_broker.py`" $($cfg.broker.bind)" `
    -WorkingDirectory $root -RedirectStandardError "$root\data\broker_err.txt" -WindowStyle Hidden
  for ($i = 0; $i -lt 15 -and -not (Listening $port); $i++) { Start-Sleep 1 }
  if (Listening $port) { Say "broker        up on :$port" } else { Say "broker FAILED - see data\broker_err.txt" }
}

function StopBroker { BrokerProcs | % { Stop-Process -Id $_.ProcessId -Force -ErrorAction SilentlyContinue }; Say 'broker        stopped' }

function Projects([switch]$Restart) {
  foreach ($p in $cfg.projects) {
    $s = if ($p.start) { Join-Path $p.path $p.start } else { $null }
    if (-not $s -or -not (Test-Path $s)) { Say "$($p.name): no start script - skipped"; continue }
    Say "$($p.name): $($p.start)$(if ($Restart) { ' -Restart' })"
    if ($Restart) { & $s -Restart -Quiet:$Quiet } else { & $s -Quiet:$Quiet }
  }
}

switch ($Action) {
  'setup'   { Setup }
  'broker'  { Broker }
  'stop'    { StopBroker }
  'status'  { & (Join-Path $root 'network\lab_status.ps1') }
  'start'   { Broker; Projects }
  'restart' { StopBroker; Start-Sleep 2; Broker; Projects -Restart }
}
