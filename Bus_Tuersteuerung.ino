/*
 * Bus Simulator - Tür Taster + LED Steuerung
 * ESP8266, Kommunikation über USB-Serial (115200 Baud)
 *
 * Pinbelegung:
 *   Taster 1 (Vordere Tür) : D5 (GPIO14)  -> anderes Bein an GND
 *   LED 1                  : D1 (GPIO5)   -> über 220Ohm Widerstand
 *   Taster 2 (Hintere Tür) : D6 (GPIO12)  -> anderes Bein an GND
 *   LED 2                  : D2 (GPIO4)   -> über 220Ohm Widerstand
 *
 * Serial-Protokoll (ESP -> PC), bei jedem Tastendruck:
 *   TUER1:AUF
 *   TUER1:ZU
 *   TUER2:AUF
 *   TUER2:ZU
 *
 * Serial-Befehle (PC -> ESP), Zeilenweise, mit Newline abschliessen:
 *   LED1:AN        -> LED 1 dauerhaft an
 *   LED1:AUS       -> LED 1 aus
 *   LED1:BLINK     -> LED 1 blinkt
 *   LED2:AN / AUS / BLINK   -> selbes für LED 2
 *   TUER1:AUF / ZU -> Tuerstatus von der Software erzwingen (LED folgt automatisch)
 *   TUER2:AUF / ZU -> selbes für Tuer 2
 *   STATUS         -> aktuellen Zustand aller Tueren zurückmelden
 */

#define PIN_TASTER1 D5
#define PIN_LED1    D1
#define PIN_TASTER2 D6
#define PIN_LED2    D2

const unsigned long DEBOUNCE_MS = 50;
const unsigned long BLINK_INTERVAL_MS = 400;

enum LedMode { LED_AUS, LED_AN, LED_BLINK };

struct Tuer {
  const char* name;
  uint8_t pinTaster;
  uint8_t pinLed;
  bool offen;              // Tuerstatus: true = auf, false = zu
  LedMode ledMode;
  bool letzterTasterZustand;
  unsigned long letzteAenderung;
  unsigned long letzterBlink;
  bool blinkAn;
};

Tuer tuer1 = { "TUER1", PIN_TASTER1, PIN_LED1, false, LED_AUS, HIGH, 0, 0, false };
Tuer tuer2 = { "TUER2", PIN_TASTER2, PIN_LED2, false, LED_AUS, HIGH, 0, 0, false };

void setup() {
  Serial.begin(115200);
  delay(200);

  pinMode(tuer1.pinTaster, INPUT_PULLUP);
  pinMode(tuer2.pinTaster, INPUT_PULLUP);
  pinMode(tuer1.pinLed, OUTPUT);
  pinMode(tuer2.pinLed, OUTPUT);

  digitalWrite(tuer1.pinLed, LOW);
  digitalWrite(tuer2.pinLed, LOW);

  Serial.println("READY");
}

void loop() {
  tasterPruefen(tuer1);
  tasterPruefen(tuer2);

  ledAktualisieren(tuer1);
  ledAktualisieren(tuer2);

  serialBefehlePruefen();
}

void tasterPruefen(Tuer &t) {
  bool zustand = digitalRead(t.pinTaster);
  unsigned long jetzt = millis();

  // Flanke erkannt: von HIGH (nicht gedrueckt) auf LOW (gedrueckt)
  if (zustand == LOW && t.letzterTasterZustand == HIGH && (jetzt - t.letzteAenderung) > DEBOUNCE_MS) {
    t.letzteAenderung = jetzt;
    t.offen = !t.offen;
    t.ledMode = t.offen ? LED_AN : LED_AUS;

    Serial.print(t.name);
    Serial.println(t.offen ? ":AUF" : ":ZU");
  }

  if (zustand != t.letzterTasterZustand) {
    t.letzteAenderung = jetzt;
  }
  t.letzterTasterZustand = zustand;
}

void ledAktualisieren(Tuer &t) {
  switch (t.ledMode) {
    case LED_AUS:
      digitalWrite(t.pinLed, LOW);
      break;
    case LED_AN:
      digitalWrite(t.pinLed, HIGH);
      break;
    case LED_BLINK:
      if (millis() - t.letzterBlink >= BLINK_INTERVAL_MS) {
        t.letzterBlink = millis();
        t.blinkAn = !t.blinkAn;
        digitalWrite(t.pinLed, t.blinkAn ? HIGH : LOW);
      }
      break;
  }
}

void serialBefehlePruefen() {
  if (!Serial.available()) return;

  String zeile = Serial.readStringUntil('\n');
  zeile.trim();
  zeile.toUpperCase();

  if (zeile == "STATUS") {
    statusSenden();
    return;
  }

  int trenner = zeile.indexOf(':');
  if (trenner == -1) return;

  String ziel = zeile.substring(0, trenner);
  String wert = zeile.substring(trenner + 1);

  Tuer* t = nullptr;
  if (ziel == "LED1" || ziel == "TUER1") t = &tuer1;
  if (ziel == "LED2" || ziel == "TUER2") t = &tuer2;
  if (t == nullptr) return;

  if (ziel.startsWith("LED")) {
    if (wert == "AN") t->ledMode = LED_AN;
    else if (wert == "AUS") t->ledMode = LED_AUS;
    else if (wert == "BLINK") t->ledMode = LED_BLINK;
  } else if (ziel.startsWith("TUER")) {
    if (wert == "AUF") { t->offen = true; t->ledMode = LED_AN; }
    else if (wert == "ZU") { t->offen = false; t->ledMode = LED_AUS; }
  }
}

void statusSenden() {
  Serial.print("STATUS:TUER1=");
  Serial.print(tuer1.offen ? "AUF" : "ZU");
  Serial.print(",TUER2=");
  Serial.println(tuer2.offen ? "AUF" : "ZU");
}
