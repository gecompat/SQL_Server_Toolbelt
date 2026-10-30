# Vollständige Parameterhilfe prüfen

Die Prüfung gilt für den [aktuellen Installationssatz](../../Releases/1.0.0/PARAMETER-HELP.md).
Sie installiert echte Modulskripte mit ihren gebundenen DLLs in eigenen
Testdatenbanken und ruft die installierten Prozeduren auf. Extrahierte
Help-Blöcke oder Ersatzprozeduren gelten nicht als Laufzeitnachweis.

| Installation | Öffentliche Prozeduren / Parameter je Kontext |
|---|---:|
| Windows, lokal | 74 / 670 |
| Windows, zentral | 63 / 555 |
| Linux, lokal oder zentral | 62 / 517 |

SQL Server 2019/CL150, 2022/CL160 und 2025/CL170 werden jeweils lokal und
zentral geprüft. Die Windows-Matrix prüft zusätzlich den internen
SSIS-CLR-Einstieg mit 38 Parametern. Windows-Dateisystem und ZIP-Dateifassaden
sind ausschließlich lokal vorgesehen; SSIS ist Windows-spezifisch.
Die [gebundene Ergebnismatrix](../../Releases/1.0.0/parameter-help-qualification.json)
nennt den exakt ausgeführten Installationssatz, Testquellen und Grenzen.

Pro Prozedur werden ein minimaler Hilfeaufruf und ein Aufruf mit explizitem
NULL für die Fachparameter, ungültigem ResultTable-Namen, KeepData=1 und
Debug=255 ausgeführt. Geprüft werden genau ein Standard-Resultset, Identität,
alle Parameter in Signaturreihenfolge, Typen, Pflicht-/NULL-Metadaten,
technische Defaults und unveränderte vollständige Unicode-Beschreibungen.
Eine Callertransaktion und ihre synthetischen Temp-Daten müssen erhalten
bleiben; Diagnose-Messages und weitere Resultsets sind Fehler.

Der [Fallgenerator](../Documentation/new_parameter_help_cases.py) übernimmt
Erwartungswerte aus den tatsächlichen Signaturen und derselben redaktionellen
Quelle wie die Referenz. Der [Labtreiber](Invoke-ParameterHelpLab.ps1) benötigt
ein privates Runset mit ausdrücklich ausgewählten schema-validen Labzielen und
SHA-256-gebundenen Eingaben. Bestehende Lab-, SQL-, Trust-Consumer- und
Datenbank-Ownership-Guards werden wiederverwendet. Der Treiber setzt vorhandene
CLR-Bereitschaft voraus; erforderliche Testkonfigurationen bleiben separat
autorisiert, privat journalisiert und nach allen Verbrauchern wiederhergestellt.
Ein eigener `-AuditOnly`-Aufruf prüft danach Eingaben sowie Datenbank- und
Trust-Abwesenheit über eine frische Verbindung.

Offline laufen die [Vollständigkeits- und Projektionsprüfungen](../Documentation/test_parameter_help.py)
sowie die [Prüfung der ausführbaren Installationsinhalte](test_parameter_help_package.py)
im vorhandenen Dokumentationsworkflow. Historische Quell- und Methodenpins
bleiben erhalten; nur eng gebundene Help-/Lesadapteränderungen werden
rückprojiziert. Diese Rückprojektion qualifiziert keine neue Hilfe.

Nach den SQL-Läufen wurden ausschließlich die Links der Paket-Anleitung und
unverändert übernommene vorhandene Drittanbieter-Lizenzhinweise ergänzt.
Die vier Installationsskripte, Trustskripte und die Buildbindung sind bytegleich
zu den ausgeführten Dateien. Der Nachweis rekonstruiert alle vorherigen
Paketdateiinhalte exakt; ausführbare Änderungen wären ein Fehler.
Auch die [historischen Export-Fixture-Deklarationen](../../Deployment/Tests/export_parameter_help_definition_pins.py)
werden gegen ihre damaligen Definitionen gebunden, während die kanonische
Help-Projektion und unveränderter Fachcode separat geprüft werden. Das ist
keine erneute Abnahme populierter Upgrades.

Die Matrix belegt den Help-Vertrag und die aktuelle Neuinstallation. Vollständige
fachliche Modulabnahmen, zusätzliche niedrigere Kompatibilitätsstufen und
authentifizierte TLS-Verbindungen bleiben getrennte Nachweise.
