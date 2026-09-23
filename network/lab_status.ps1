# ===========================================================================
# AEDI - IONITY GLOBAL | Ionity Lab: one-look health check
# Doc ID: DOC-2026-09-IONITY-LAB | Policy 986 AED
# Household internet -> lab link -> lab services -> every registered project
# and its boards. Every line must be OK before a client demo.
# ===========================================================================
$ErrorActionPreference = 'SilentlyContinue'
$root = Split-Path $PSScriptRoot
$cfg  = Get-Content (Join-Path $root 'lab.json') -Raw | ConvertFrom-Json
$ok = 0; $bad = 0
function Check($name, [bool]$pass, $detail) {
  $script:ok += [int]$pass; $script:bad += [int](-not $pass)
  $mark = if ($pass) { 'OK  ' } else { 'FAIL' }
  $col  = if ($pass) { 'Green' } else { 'Red' }
  Write-Host ("[{0}] {1,-34} {2}" -f $mark, $name, $detail) -ForegroundColor $col
}

Write-Host "`n== Household ($($cfg.household.router)) =="
$route = Find-NetRoute -RemoteIPAddress 1.1.1.1 | Select-Object -Last 1
Check 'internet goes via household NIC' ($route.InterfaceAlias -eq $cfg.household.laptop_nic) "$($route.InterfaceAlias) -> $($route.NextHop)"
$web = try { (Invoke-WebRequest http://www.google.com/generate_204 -UseBasicParsing -TimeoutSec 6).StatusCode -eq 204 } catch { $false }
Check 'internet reachable' $web 'google generate_204'

Write-Host "`n== Lab ($($cfg.lab.router)) =="
$labIp = (Get-NetIPAddress -InterfaceAlias $cfg.lab.laptop_nic -AddressFamily IPv4 | ? PrefixOrigin -ne 'WellKnown').IPAddress
Check 'laptop has pinned lab address' ($labIp -eq $cfg.lab.server_ip) "$($cfg.lab.laptop_nic) = $labIp (want $($cfg.lab.server_ip))"
Check 'lab router reachable' (Test-Connection $cfg.lab.router_ip -Count 1 -Quiet) $cfg.lab.router_ip
$prof = (Get-NetConnectionProfile -InterfaceAlias $cfg.lab.laptop_nic).NetworkCategory
Check 'lab network is Private' ("$prof" -eq 'Private') "$prof"
Check 'lab firewall rules present' ((@(Get-NetFirewallRule -Group 'Ionity Lab' -ErrorAction SilentlyContinue)).Count -ge 4) 'group Ionity Lab (SETUP-LAB-NETWORK.cmd)'
$mq = [bool](Get-NetTCPConnection -LocalPort $cfg.ports.mqtt -State Listen)
Check 'lab MQTT broker listening' $mq ":$($cfg.ports.mqtt)"

$prefix = ($cfg.lab.subnet -split '\.')[0..2] -join '.'
foreach ($p in $cfg.projects) {
  Write-Host "`n== Project: $($p.name) =="
  if (-not (Test-Path $p.path)) { Check 'project folder' $false "$($p.path) not on this machine"; continue }
  if ($p.health_url) {
    $h = try { Invoke-RestMethod $p.health_url -TimeoutSec 5 } catch { $null }
    Check 'service up' ([bool]$h) $p.health_url
    if ($h.mqtt)      { Check 'connected to lab broker' ([bool]$h.mqtt.connected) "$($h.mqtt.host)" }
    if ($h.discovery) { Check 'mDNS advertises lab address' ($h.discovery.advertised_ip -eq $cfg.lab.server_ip) "$($h.discovery.hostname) -> $($h.discovery.advertised_ip)" }
    if ($h.dns)       { Check 'DNS logger on lab only' ($h.dns.bind -like "$($cfg.lab.server_ip)*") "bind $($h.dns.bind)" }
  }
  if ($p.devices_url) {
    $devs = try { (Invoke-RestMethod $p.devices_url -TimeoutSec 5).devices } catch { @() }
    foreach ($d in $devs) {
      $where = if ($d.transport -eq 'serial') { 'USB serial' } else { $d.ip }
      $onLab = ($d.transport -eq 'serial') -or ("$($d.ip)" -like "$prefix.*")
      Check "$($d.device_id)" (($d.health -eq 'online') -and $onLab) "$($d.health), $where, fw $($d.fw)$(if (-not $onLab) { '  <- still on household network' })"
    }
    if (-not $devs) { Check 'boards reporting' $false 'none' }
  }
}

Write-Host "`n$ok passed, $bad failed.`n"
