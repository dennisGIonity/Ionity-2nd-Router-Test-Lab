# Arduino IDE bench setup

Stops the IDE showing lab boards as "Unknown" or as the wrong board.

| File | Copy to | Effect |
|---|---|---|
| `esp32.boards.local.txt` | `%LOCALAPPDATA%\Arduino15\packages\esp32\hardware\esp32\<version>\boards.local.txt` | ESP32-S3 boards on CH340 (1a86:7523) and native USB (303a:1001) show as **ESP32S3 Dev Module** |
| `rp2040.boards.local.txt` | `%LOCALAPPDATA%\Arduino15\packages\rp2040\hardware\rp2040\<version>\boards.local.txt` | Pico 2 (RP2350) no longer mis-identifies as a Pimoroni/Waveshare/WeAct board |

Restart the IDE after copying. Delete the file to undo. Changing it makes the next compile rebuild the core, which takes about 20 minutes once.
