# ===========================================================================
# AEDI - IONITY GLOBAL | Ionity Lab: point every project's boards at the lab
# Doc ID: DOC-2026-09-IONITY-LAB | Policy 986 AED
# (c) 2018-2026 Antwerp Designs | Ionity (Pty) Ltd
# ---------------------------------------------------------------------------
# Asks for the lab WiFi name + password (password typed hidden, never logged,
# never committed). For every project in lab.json "projects" it:
#   - writes WIFI_SSID / WIFI_PASSWORD into each sketch's git-ignored secrets.h
#   - points SERVER_HOST_FALLBACK in each sketch's config.h at the lab server
#   - writes the project's "env" keys into its git-ignored env file
# Then reflash the boards with that project's own flashing script.
#   network\set_lab_wifi.ps1                 all projects
#   network\set_lab_wifi.ps1 -Project ESP32-MCP
# ===========================================================================
param([string]$Ssid, [string]$Project)
$ErrorActionPreference = 'Stop'
$root = Split-Path $PSScriptRoot
$cfgPath = Join-Path $root 'lab.json'
$cfg = Get-Content $cfgPath -Raw | ConvertFrom-Json
$labIp = $cfg.lab.server_ip

$projects = @($cfg.projects | ? { -not $Project -or $_.name -eq $Project })
if (-not $projects) { throw "No project '$Project' in lab.json" }
$projects = @($projects | ? { Test-Path $_.path })
if (-not $projects) { throw "None of the registered project folders exist on this machine." }

if (-not $Ssid) {
  $def = $cfg.lab.wifi_ssid
  Write-Host "Boards join the lab's 2.4 GHz network (ESP32-S3 / Pico 2 W cannot use 5 GHz)."
  $Ssid = Read-Host "Lab WiFi name (2.4 GHz) [$def]"
  if (-not $Ssid) { $Ssid = $def }
}
$sec = Read-Host "Password for '$Ssid' (hidden)" -AsSecureString
$pw  = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($sec))
if ($pw.Length -lt 8) { throw "WPA2 passwords are at least 8 characters - nothing changed." }

function CStr([string]$s) { '"' + ($s -replace '\\','\\' -replace '"','\"') + '"' }
function Set-Define([string]$file, [string]$name, [string]$value) {
  $txt = Get-Content $file -Raw
  $pat = "(?m)^(\s*#define\s+$name\s+).*$"
  if ($txt -match $pat) { $txt = [regex]::Replace($txt, $pat, { param($m) $m.Groups[1].Value + $value }) }
  else { $txt = $txt.TrimEnd() + "`r`n#define $name $value`r`n" }
  [IO.File]::WriteAllText($file, $txt)
}

foreach ($p in $projects) {
  Write-Host "`n== $($p.name)  ($($p.path))"
  $fw = Join-Path $p.path $p.firmware_dir

  # 1. secrets.h in every sketch (git-ignored in the project)
  $sketches = @(Get-ChildItem $fw -Directory -ErrorAction SilentlyContinue | ? { Test-Path (Join-Path $_.FullName 'secrets.h') })
  foreach ($s in $sketches) {
    $f = Join-Path $s.FullName 'secrets.h'
    Set-Define $f 'WIFI_SSID'     (CStr $Ssid)
    Set-Define $f 'WIFI_PASSWORD' (CStr $pw)
    Write-Host "[lab-wifi] $($s.Name)\secrets.h -> SSID '$Ssid'"
  }
  if (-not $sketches) { Write-Host "[lab-wifi] no sketch with a secrets.h under $fw" }

  # 2. server fallback baked into the firmware (not secret)
  foreach ($s in Get-ChildItem $fw -Directory -ErrorAction SilentlyContinue) {
    $c = Join-Path $s.FullName 'config.h'
    if ((Test-Path $c) -and ((Get-Content $c -Raw) -match '(?m)^\s*#define\s+SERVER_HOST_FALLBACK')) {
      Set-Define $c 'SERVER_HOST_FALLBACK' (CStr $labIp)
      Write-Host "[lab-wifi] $($s.Name)\config.h fallback -> $labIp"
    }
  }

  # 3. project env keys ({server_ip} is filled in), env file is git-ignored in the project
  if ($p.env_file -and $p.env) {
    $envFile = Join-Path $p.path $p.env_file
    $lines = if (Test-Path $envFile) { @(Get-Content $envFile) } else { @('# Local overrides - git-ignored.') }
    foreach ($prop in $p.env.PSObject.Properties) {
      $val = $prop.Value -replace '\{server_ip\}', $labIp
      $lines = @($lines | ? { $_ -notmatch "^$($prop.Name)=" }) + "$($prop.Name)=$val"
      Write-Host "[lab-wifi] $($p.env_file): $($prop.Name)=$val"
    }
    Set-Content $envFile $lines -Encoding UTF8
  }
}
$pw = $null

# 4. remember a changed SSID in lab.json (text edit keeps the file readable; never the password)
if ($Ssid -ne $cfg.lab.wifi_ssid) {
  $txt = Get-Content $cfgPath -Raw
  $txt = [regex]::Replace($txt, '("wifi_ssid"\s*:\s*")[^"]*(")', { param($m) $m.Groups[1].Value + $Ssid + $m.Groups[2].Value })
  [IO.File]::WriteAllText($cfgPath, $txt)
  Write-Host "`n[lab-wifi] lab.json -> wifi_ssid '$Ssid'"
}
Write-Host "`nNext: START-LAB.cmd (restarts lab services), then reflash each board with the project's flasher."
