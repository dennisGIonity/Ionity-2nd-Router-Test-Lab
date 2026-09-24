# Moving GateFlame into the 2nd-Router Test Lab

Doc ID: DOC-2026-09-IONITY-LAB-GF · Policy 986 AED · © 2018-2026 Antwerp Designs | Ionity (Pty) Ltd
For: the **GateFlame Cowork project** (repo `github.com/dennisGIonity/Gate-Flame`, local `E:\Gateflame`).
Lab repo: `github.com/dennisGIonity/Ionity-2nd-Router-Test-Lab` (local `E:\.IONITY-LAB`).

## 1. Where GateFlame is today

| Item | Value |
|---|---|
| Hardware | Raspberry Pi 5, hostname `raspberrypi`, user `wabapi` |
| Screen | ASUS monitor on HDMI (kiosk: `gateflame-kiosk`) |
| Source code | `E:\Gateflame` → `git@github.com:dennisGIonity/Gate-Flame.git` |
| SSH key | `~/.ssh/id_ed25519` (passphrase-protected), loaded with `E:\Gateflame\tools\load-key.cmd`, agent socket `C:\Users\DGMic\.ssh\agent.sock`, verify host with `HostKeyAlias=raspberrypi` |
| Keystore backup | `E:\Gateflame-KeystoreBackup` (keep offline, never commit) |
| Pi WiFi `wlan0` | MAC `88:a2:9e:27:a1:8f`, was on the **household** WiFi at `192.168.0.11` |
| Pi Ethernet `eth0` | MAC `88:a2:9e:27:a1:8d`, on the **H3C lab** at `192.168.124.3` |
| GateFlame API | port `8080` |

### GateFlame pieces on the Pi (what pause/resume touches)
| Kind | Names |
|---|---|
| systemd units | `gateflame-kiosk`, `gateflame-node-agent`, `gateflame-mdns-alias` (all `gateflame*`) |
| Docker containers | `gateflame-pihole` (DNS filter), `gateflame-unbound` (recursive DNS) |
| mDNS alias | `/etc/avahi/services/gateflame.service` → `gateflame.local` |
| cron | `/etc/cron.d/*gateflame*` and root crontab lines |
| DNS | the Pi resolves through itself (Pi-hole on `127.0.0.1`) |

The pause (2026-09-22) recorded every prior state in `/var/lib/ionity-lab/gateflame-paused.state`.
`RESUME-GATEFLAME.cmd` (in the lab repo) restores exactly that state and deletes the state file.
Nothing was ever deleted.

## 2. Rule for the move
**GateFlame must never serve DNS, DHCP or IPv6 router adverts to the household (TP-Link 192.168.0.x).**
It may do so inside the lab (192.168.124.x) only when deliberately configured. The H3C stays the
lab's DHCP server unless you decide otherwise.

## 3. Move steps

| # | Step | Where / how |
|---|---|---|
| 1 | **Resume GateFlame** so it runs as before | Double-click `E:\.IONITY-LAB\RESUME-GATEFLAME.cmd`, type your SSH passphrase + Pi sudo password. Check: status shows `STATE: running (not paused)` |
| 2 | Pi on the lab by **cable**: `eth0` → an H3C **LAN** port | physical |
| 3 | Reserve `192.168.124.3` for MAC `88:a2:9e:27:a1:8d` | H3C admin `http://192.168.124.1` → DHCP reservation |
| 4 | **Take the Pi off the household WiFi** (this is what kept GateFlame visible to the house) | On the Pi: `nmcli -f NAME,DEVICE con show` then `sudo nmcli con modify "<household SSID profile>" connection.autoconnect no` and `sudo nmcli con down "<profile>"`. Optional lab WiFi instead: `sudo nmcli dev wifi connect IONITY-LAB` (5 GHz) |
| 5 | Point GateFlame's own config at lab addresses | In `E:\Gateflame`: replace any `192.168.0.x` / `192.168.2.x` host refs with `192.168.124.3` (Pi) and `192.168.124.4` (laptop / fleet server). Keep Pi-hole bound to `eth0` / `192.168.124.0/24`; Pi-hole DHCP **off** |
| 6 | Deploy + start in the GateFlame project | Its normal deploy (`GATEFLAME-push.cmd` / `release/`), then on the Pi `sudo systemctl start 'gateflame*'` and `docker start gateflame-pihole gateflame-unbound` |
| 7 | Verify from the laptop | `ssh -o HostKeyAlias=raspberrypi wabapi@192.168.124.3`, `curl http://192.168.124.3:8080/`, and from the household side `Resolve-DnsName google.com -Server 192.168.0.1` still answers (the house is untouched) |
| 8 | **Register GateFlame in the lab** | Add to `E:\.IONITY-LAB\lab.json` → `projects` (entry below), then `LAB-STATUS.cmd` |

### lab.json entry for GateFlame
```json
{
  "name": "GateFlame",
  "repo": "https://github.com/dennisGIonity/Gate-Flame",
  "path": "E:\\Gateflame",
  "health_url": "http://192.168.124.3:8080/",
  "note": "Runs on the Pi 5 (192.168.124.3). Started on the Pi by systemd, not by lab.ps1."
}
```
No `start` script: GateFlame starts itself on the Pi at boot. `lab.ps1 status` will check its API.

## 4. Screen: GateFlame kiosk vs lab dashboard
Only one can own the ASUS. With GateFlame running, `gateflame-kiosk` owns it and the lab's
`SETUP-PI-LAB.cmd` refuses to install the dashboard kiosk (by design). To show the fleet dashboard
instead, pause GateFlame first, or add the dashboard URL (`http://192.168.124.4:8099/`) as a page in
the GateFlame kiosk.

## 5. Paste this into the GateFlame Cowork project
> GateFlame is moving onto the Ionity 2nd-Router Test Lab (H3C Magic, 192.168.124.0/24), fully off the
> household TP-Link network. Read `E:\.IONITY-LAB\docs\GATEFLAME-MOVE.md` and `E:\.IONITY-LAB\lab.json`.
> The Pi 5 is `wabapi@192.168.124.3` (eth0, reserved on the H3C); the laptop/fleet server is 192.168.124.4.
> GateFlame was paused on 2026-09-22 and has been resumed. Do steps 4-8: take the Pi off household WiFi,
> repoint GateFlame's config to lab addresses (Pi-hole bound to eth0, DHCP off), deploy, start, verify,
> then add the GateFlame entry to lab.json. Never let GateFlame serve DNS/DHCP/RA to 192.168.0.x.
> I type my own SSH passphrase and sudo password.
