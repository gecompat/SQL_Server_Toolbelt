# Aktueller SSIS-Build: ZIP- und SSMS-Abnahme

Die Abnahme vom 2026-11-16 gilt ausschließlich für das
[SecurityCorrected-Installationspaket](../../Modules/toolbelt.tsql.ssis-debug/InstallPackages/README.md#aktuelles-paket-mit-ansi-sicherheitskorrektur)
und den darin enthaltenen sicherheitskorrigierten Provider. Der
[kanonische Record](../../Modules/toolbelt.tsql.ssis-debug/Tests/Qualification/Current.ZipSsms.20261116.json)
bindet Artefakte, tatsächlich ausgeführte Fälle und Quellen. Private Originaljournale
bleiben erhalten; dieser Bericht übernimmt keine realen Runtimeausgaben.

## Vollständige funktionale ZIP-Matrix

| Windows SQL Server | Patch | Compatibility Levels | Modi |
|---|---|---|---|
| 2019 | CU32 | 150 | lokal, zentral |
| 2022 | CU26 | 150, 160 | lokal, zentral |
| 2025 | CU8 | 150, 160, 170 | lokal, zentral |

Alle zwölf entpackten ZIP-Gesamtfälle sind PASS_CLEANED: 96 Paket-, 12.444
Fach-/API-/Rechte-/Lifecycle- und 2.664 Prozedurassertions, insgesamt 15.204.
Jeder Fall besitzt einen frischen separaten Abschlussaudit, gebunden an das
unveränderte finale Journal. Die bereits konkret genehmigte Ausnahme für
synthetische API-/Prozedur-Minimalrechte bleibt der gesamte Rechtescope.
24 eigene Datenbanken und zwölf Logins sind entfernt; Konfiguration, Trust
und andere Verbraucher sind erhalten.

## Sichtbarer Windows-/SSMS-Gesamtfall

Windows SQL2025/CU8, CL150 lokal: 17 Prüfungen und ein vollständiger
PASS_CLEANED-Koordinator mit frischem Windows-Audit. Die eigene sichtbare
SSMS-Instanz führte vier Abfragen aus: Ziel-/Windows-/Verschlüsselungsvorcheck,
aktuelle API, kontrollierte SQLCMD-Fehlerprobe und vollständiges Script samt
Receipt. Erst- und Wiederholungsinstallation nutzten den öffentlichen Installer.

Die echte Grid-Zellenkopie mit 184.441 UTF-16-Zeichen wurde vor der Ausführung
hashgeprüft. Der absichtliche Fehler 51001 beendete SQLCMD vor dem späteren
Sentinel; Receiptphase 1 blieb unverändert. Das vollständig gebundene
Script samt Receipt lieferte zwei erwartete Fachzeilen und den Unicode-Witness;
Phase 2 und der fehlerfreie Messages-Abschluss sind tatsächlich belegt.
Nur die eigene Instanz und Datenbank wurden entfernt. Anmeldung und
Gridoptionen übernahm der Benutzer; sämtliche vier Ausführungen der Agent.

## Wiederverwendung und Grenzen

Der unveränderte Provider übernimmt seine tatsächlich gültigen 29 Frameworkfälle,
ANSI-Lineage-Prüfungen, strikte TLS-Abnahme und unabhängige Sicherheitsabnahme.
Diese grünen Nachweise wurden nicht wiederholt. Historische C7-Archive und
Records bleiben bytegleich; sie werden nicht zum neuen Build umgedeutet.
Der neue Buildrecord liegt im ZIP als kanonische LF-Projektion des gebundenen
Erzeugungscommits vor; die fünf nativ gebundenen aktuellen Eingabedateien
behalten ihre originalen CRLF-Bytes auf jedem Checkout.

Die Fachmatrix und Windows-/SSMS-Anmeldung verwenden Functional mit
Verschlüsselung und dem genehmigten Trust-Override. Der separate strikte
TLS-Nachweis verwendet SQL-Anmeldung; daraus folgt keine kombinierte
Windows-/TLS-Identitätsqualifikation. Kein neuer Linux-Hostlauf, vollständiger
OS-/VM-Verlust des Koordinators, vollständige SSIS-Runtime-Parität oder
unbegrenzte Produktionskapazität wird behauptet. Gesamtmodul teilweise
validiert und unveröffentlicht; keine Veröffentlichung oder Tags autorisiert.

## Reproduzierbare Integritätsprüfung

```text
python Scripts/Release/validate_ssis_current_package.py Modules/toolbelt.tsql.ssis-debug/InstallPackages/SSIS-Debug-SecurityCorrected-Install-Windows.zip --profile ssis-debug-security-corrected
python Scripts/Release/validate_ssis_security_corrected_zip_ssms.py
```

Diese Befehle prüfen vorhandene Quellen und Records ohne SQL-/GUI-Wiederholung.
Die nativen Adapter, neue Gegenproben und originalen Aufrufparameter sind im
Record beziehungsweise in privaten Ausführungsnachweisen gebunden.
