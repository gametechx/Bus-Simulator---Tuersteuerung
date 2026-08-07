# Bus Simulator - Tuersteuerung

ESP8266-basierte Tuersteuerung fuer einen selbstgebauten Bus-Fahrpult (3D-gedruckte Taster mit LED) plus PC-Software zur Anzeige/Steuerung ueber USB.

## Projektstruktur

| Datei | Beschreibung |
|---|---|
| `Bus_Tuersteuerung.ino` | Firmware fuer den ESP8266 (Arduino IDE) |
| `BusSteuerung.lpr` | Lazarus Projektdatei (PC-Software) |
| `Unit1.pas` | Quellcode der PC-Software (Windows, Object Pascal) |

## Hardware

Zwei beleuchtete Taster (Vordere Tuer / Hintere Tuer), jeweils mit eigener LED.

| Funktion | ESP8266 Pin |
|---|---|
| Taster 1 (Vordere Tuer) | D5 (GPIO14) -> anderes Bein an GND |
| LED 1 | D1 (GPIO5) -> ueber 220 Ohm Widerstand |
| Taster 2 (Hintere Tuer) | D6 (GPIO12) -> anderes Bein an GND |
| LED 2 | D2 (GPIO4) -> ueber 220 Ohm Widerstand |

Taster nutzen den internen Pullup des ESP8266, kein externer Widerstand am Schalter noetig.

## Firmware flashen

1. `Bus_Tuersteuerung.ino` in der Arduino IDE oeffnen
2. Board: **NodeMCU 1.0 (ESP-12E Module)**
3. Passenden COM-Port waehlen, hochladen
4. Im Seriellen Monitor (115200 Baud) sollte `READY` erscheinen

## PC-Software bauen

1. [Lazarus](https://www.lazarus-ide.org/) installieren (bringt den Free Pascal Compiler mit, keine Zusatzpakete noetig)
2. `BusSteuerung.lpr` in Lazarus oeffnen
3. F9 druecken zum Kompilieren + Starten
4. Fertige `.exe` liegt danach im Projektordner und laeuft eigenstaendig auf jedem Windows-PC (keine Lazarus-Installation noetig)

## Bedienung

1. ESP8266 per USB anschliessen, COM-Port im Windows-Geraetemanager nachsehen
2. Port ins Textfeld eintragen, "Verbinden" klicken -> Kreis wird gruen
3. Taster druecken -> Tuerstatus (AUF/ZU) aktualisiert sich live, LED am Taster folgt automatisch
4. Ueber die Buttons in der Software koennen Tuerstatus und LED auch manuell/unabhaengig vom Taster gesteuert werden

## Serial-Protokoll

**ESP -> PC** (bei jedem Tastendruck):
```
TUER1:AUF
TUER1:ZU
TUER2:AUF
TUER2:ZU
```

**PC -> ESP** (Befehle, zeilenweise mit Newline):
```
LED1:AN | AUS | BLINK
LED2:AN | AUS | BLINK
TUER1:AUF | ZU     (erzwingt Tuerstatus, LED folgt automatisch)
TUER2:AUF | ZU
STATUS             (fragt aktuellen Zustand beider Tueren ab)
```

## Taster

Die Taster sind eigene 3D-gedruckte Bauteile mit eingesetzter LED.
