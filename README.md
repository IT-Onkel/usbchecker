# 🛡️ IT-Onkel USB-Checker

Der **IT-Onkel USB-Checker** ist eine kompakte, offlinefähige
USB-Prüfstation auf Basis von Raspberry Pi OS.

Er wurde entwickelt, um **USB-Sticks vor der Nutzung in
Unternehmen sicher zu prüfen**, ohne sie direkt an
Produktivsysteme anschließen zu müssen.

Die Lösung richtet sich an kleine und mittelständische
Unternehmen, Bildungseinrichtungen und Organisationen,
die einen einfachen, nachvollziehbaren und auditierbaren
Umgang mit externen Datenträgern benötigen.

## ✨ Features

- 🔒 **Isolierte USB-Prüfung**
  - USB-Sticks werden niemals an Produktivsysteme angeschlossen

- 🌐 **Kurzzeit-Online-Updates**
  - WLAN wird ausschließlich für Virensignatur-Updates aktiviert
  - Danach vollständiger Offline-Betrieb

- 🦠 **Malware-Erkennung**
  - ClamAV (Signaturbasierte Prüfung)
  - YARA-Regeln (Skripte, verdächtige Dateitypen)

- 🚦 **Klare Ergebnisanzeige**
  - Grün: Keine Malware gefunden
  - Warnung: Auffällige Dateitypen erkannt
  - Rot: Malware erkannt – Stick nicht verwenden

- 🧰 **Automatisierter Ablauf**
  - USB einstecken → Scan startet automatisch
  - Kein Benutzer-Login notwendig

- 📜 **Audit- & Richtlinienfähig**
  - Logs aller Prüfungen
  - Geeignet zur Einbindung in interne IT-Richtlinien

- 🧠 **Ressourcenschonend**
  - Optimiert für Raspberry Pi 3/4
  - Kein GUI, kein Overhead
 
  - ## ⚠️ Sicherheits-Hinweis

Der IT-Onkel USB-Checker reduziert das Risiko durch
USB-basierte Malware erheblich, ersetzt jedoch **keine**
umfassende Endpoint-Security.

Er erkennt:
- bekannte Malware
- verdächtige Skripte
- auffällige Dateitypen

Er kann **nicht** garantieren:
- die Erkennung von 0-Day-Exploits
- hardwarebasierte Angriffe (BadUSB)
- gezielte Advanced Persistent Threats (APT)

Der USB-Checker ist als **zusätzliche Schutzmaßnahme**
zu verstehen, nicht als alleinige Sicherheitslösung.

