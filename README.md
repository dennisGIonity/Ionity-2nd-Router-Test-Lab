# Ionity Lab

**Isolated IoT test lab next to household internet: one setup shared by every Ionity hardware project.**

Doc ID: DOC-2026-09-IONITY-LAB · Policy 986 AED · License AED 900 · © 2018-2026 Antwerp Designs | Ionity (Pty) Ltd
Author: Johan Wilhelm van Antwerp · www.ionity.today · ref www.ionity.co.za · *Building Tomorrow, Today.*

The lab owns the network, the laptop's dual-network setup, the shared MQTT broker, the Pi 5 tools
and the bench health check. Projects (firmware, servers, dashboards) plug into it through
[`lab.json`](lab.json) → `projects`.

## Layout

```
 Afrihost fibre
      │
 TP-Link EX511  192.168.0.1   ← HOUSEHOLD. Internet only. Owns 2.4 GHz.
  2.4 GHz ch 1 / 20 MHz / High power (phones) · 5 GHz ch 36 (laptop, S10e)
      │ WiFi (metric 10 = all internet + DNS)
 ┌────┴──────────────── LAPTOP ─────────────────┐
 │ Ionity Lab: MQTT broker :1883                 │
 │ projects: e.g. ESP32-MCP server :8099 + MCP   │
 └────┬─────────────────────────────────────────┘
      │ Ethernet → H3C **LAN** port (metric 200 = lab only, never internet)
 H3C Magic  192.168.124.1                      ← LAB. Isolated.
  IONITY-LAB      5 GHz ch 149   main lab network (Pi 5, laptops, demo phones, ESP32-C5)
  IONITY-LAB-IOT  2.4 GHz ch 11 / 20 MHz / LOW power   2.4-only boards on the bench
      │
 ESP32 boards · Pico W · Pi 5 (GateFlame, paused)   all on 192.168.124.x
 laptop pinned at 192.168.124.4 (DHCP reservation on the H3C)
```

## Rules
1. **Nothing lab-related on the household network**: no boards, no lab DNS, no GateFlame.
2. The laptop cable goes into an H3C **LAN** port. Never the WAN port.
3. Band split: the **household owns 2.4 GHz** (TP-Link), the **lab lives on 5 GHz** (`IONITY-LAB`, ch 149).
4. Exception: ESP32-S3 / Pico 2 W radios are **2.4 GHz only**. They get one low-power lab network,
   `IONITY-LAB-IOT` on ch 11, which never overlaps the household's ch 1. Dual-band ESP32-C5 boards use 5 GHz.
5. WiFi passwords are typed into `SET-LAB-WIFI.cmd` only, and land in each project's git-ignored `secrets.h`.
   Never in chat, never in this repo.

## What's in here

| Path | What it does |
|---|---|
| `lab.json` | The lab, defined once: routers, bands, addresses, ports, Pi, registered projects. No secrets. |
| `lab.ps1` / `START-LAB.cmd` | `start` · `restart` · `broker` · `stop` · `status` · `setup`. Brings up the broker, then each project's start script. |
| `SETUP-LAB-NETWORK.cmd` → `network\setup_lab_network.ps1` | Laptop: WiFi carries internet (metric 10), cable is lab-only (metric 200), lab network Private, lab ports open to `192.168.124.0/24` only. `-Undo` reverts. Needs admin. |
| `SET-LAB-WIFI.cmd` → `network\set_lab_wifi.ps1` | Hidden password prompt. Writes the lab WiFi into every registered project's `secrets.h`, points firmware fallback + project env at the lab server IP. |
| `LAB-STATUS.cmd` → `network\lab_status.ps1` | One-look health check: household internet, lab link, broker, each project's service and boards. |
| `broker\` | Shared MQTT 3.1.1 broker (amqtt), own venv (`.venv`, created by `lab.ps1 setup`). |
| `pi\` + `SETUP-PI-LAB.cmd`, `PAUSE-GATEFLAME.cmd`, `RESUME-GATEFLAME.cmd` | Pi 5: reversible GateFlame pause/resume, dashboard kiosk on its screen. You type your own SSH passphrase and sudo password. |
| `arduino\` | Arduino IDE `boards.local.txt` files so lab boards identify correctly. |
| `docs\lab-template.html` | Source of the pinned **Ionity Lab Template** page. |

## Set up the lab (new PC or rebuild)

| # | Step | Who |
|---|------|-----|
| 1 | Laptop cable → H3C LAN port | you |
| 2 | H3C (http://192.168.124.1): 5 GHz `IONITY-LAB` ch 149; 2.4 GHz `IONITY-LAB-IOT` ch 11, 20 MHz, low power; band steering **off**; reserve **192.168.124.4** for MAC `40:C2:BA:F5:B9:5F` | you (router password) |
| 3 | TP-Link (http://192.168.0.1): 2.4 GHz ch 1, 20 MHz, power High; 5 GHz ch 36 | you |
| 4 | `SETUP-LAB-NETWORK.cmd`, then approve the admin prompt | you |
| 5 | `SET-LAB-WIFI.cmd`: accept `IONITY-LAB-IOT`, type its password | you |
| 6 | `lab.ps1 setup` (first time only), then `START-LAB.cmd` | Claude |
| 7 | Reflash each board with its project's flasher (ESP32-MCP: `scripts\add_device.ps1 -Port COMx`) | Claude |
| 8 | `LAB-STATUS.cmd`: every line **OK** | Claude |

## Adding a project to the lab
Add an entry to `lab.json` → `projects`:
```json
{ "name": "My-Project", "path": "E:\\.MY-PROJECT", "firmware_dir": "firmware-arduino",
  "env_file": ".env", "env": { "MY_SERVER_IP": "{server_ip}" },
  "start": "scripts\\start.ps1",
  "health_url": "http://127.0.0.1:9000/health", "devices_url": "http://127.0.0.1:9000/devices" }
```
- The project's firmware must read `WIFI_SSID` / `WIFI_PASSWORD` from a git-ignored `secrets.h`.
- It must use MQTT at the lab broker (`192.168.124.4:1883`, or `127.0.0.1:1883` on the laptop).
- Its start script must accept `-Restart` and `-Quiet`, and call `E:\.IONITY-LAB\lab.ps1 broker` first.

## Registered projects
| Project | Repo |
|---|---|
| ESP32-MCP (fleet server, MCP, dashboard, ESP32/Pico firmware) | https://github.com/dennisGIonity/Esp32-MCP |
