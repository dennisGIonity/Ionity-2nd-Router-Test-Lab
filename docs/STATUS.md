# Lab status log

Doc ID: DOC-2026-09-IONITY-LAB-STATUS · Policy 986 AED · © 2018-2026 Antwerp Designs | Ionity (Pty) Ltd

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
