# Lab status log

Doc ID: DOC-2026-09-IONITY-LAB-STATUS · Policy 986 AED · © 2018-2026 Antwerp Designs | Ionity (Pty) Ltd

## 2026-10-03: lab ON, ESP32-MCP synced

- H3C factory reset; SSIDs are now `Ionity-LAB_2.4G` (boards) and `Ionity-LAB_5G` - recorded in `lab.json`.
- Laptop lab IP 192.168.124.2; boards `esp32-98a316e5d18c` (.4, fw 2.1.0) and `esp32-fc012cd8ea14` (.5, fw 2.1.1)
  online; Pico offline. Broker :1883 and fleet server :8099 up.
- ESP32-MCP at commit `7e91028` (host 2.1.2 / MCP 1.3.0): live command replies on the dashboard and a standalone
  testers package (`scripts\build_testers_package.ps1`). `lab.json` project entry updated.
- To do: `server_ip` in `lab.json` (and ESP32-MCP `.env` `IONITY_MDNS_ADVERTISE_IP`) still say .124.4, which is now a
  board's address - set both to .124.2 at the next lab restart.

## 2026-09-24: lab switched OFF (checkpoint)

**Everything is committed and pushed.** Lab repo head `6530ac9`, ESP32-MCP head `575b394`.

Stopped by hand:
- the lab MQTT broker (:1883)
- the ESP32-MCP fleet server, dashboard and DNS logger (:8099, :53)
- the serial bridge
- the MCP stdio bridge

Nothing is listening on 1883, 8099 or 53. The boards keep running on their own power and retry until the lab is back.

**Will start again automatically when:**
- you log in (Startup shortcut **Ionity Lab** → `E:\.ESP32-MCP\scripts\start_lab.ps1`)
- Claude calls an `ionity-esp32-fleet` MCP tool (the MCP bridge autostarts the lab)

**Start by hand:** `E:\.IONITY-LAB\START-LAB.cmd`. **Check:** `LAB-STATUS.cmd`.

### Where things stand
| Area | State |
|---|---|
| Lab project | This repo, `github.com/dennisGIonity/Ionity-2nd-Router-Test-Lab`. GateFlame is registered in `lab.json` (Pi 5, 192.168.124.3) |
| GateFlame | Resume window was opened on 2026-09-24 for your passphrase and sudo password. Move plan in `docs/GATEFLAME-MOVE.md`, to be carried out in the GateFlame Cowork project |
| ESP32-MCP | Firmware: ESP32 1.2.0 (DNS probe), Pico 1.1.0 (serial CMD/RES). The server runs under `python.exe`, because `pythonw` crashed uvicorn logging |
| Still yours to do | `SETUP-LAB-NETWORK.cmd` (fixes laptop DNS while the lab cable is in); TP-Link 2.4 GHz ch 1 / 20 MHz; H3C `IONITY-LAB` 5 GHz ch 149 + `IONITY-LAB-IOT` 2.4 GHz ch 11 low power; reserve 192.168.124.4; `SET-LAB-WIFI.cmd` |
| Then Claude | Reflash the boards onto `IONITY-LAB-IOT`, then `LAB-STATUS.cmd` until every line is OK |
