# Table Clone 4.1.1: direkte bekannte Vorgänger

Am 2026-11-07 bestand die aktuelle direkte Lifecycle-Matrix für fünf echte
öffentliche Vorgänger: **zwölf vollständige Läufe, 24 lokale/direkt zentrale
Kontexte, 360 eindeutige Profile und zwölf frische unabhängige Abschlussaudits**.
Ergebnis: **PASS_FOR_DECLARED_KNOWN_PREDECESSOR_DIRECT_LIFECYCLE_MATRIX**.
Alle 24 eigenen Datenbanken wurden entfernt. Keine nativen Fehler, Korrekturen
oder Wiederholung bestandener Profile. Keine Modulgesamtfreigabe.

## Originale und aktuelle Quellen

Der [Methodenstand a455ef84](https://github.com/gecompat/SQL_Server_Toolbelt/commit/a455ef84b2de7cb5ef2bf97426e44cbbfbc0a256)
bindet den [begrenzten Treiber](../../Tests/Release/Invoke-TableCloneKnownPredecessorsLab.ps1)
und die Quellen-/Zulassungsgegenproben. Originalbytes, Dateimengen,
SHA256, Provenienz, bekannte Signaturen und vollständig expandierte Texte
werden vor SQL geprüft. Der unabhängige Nachprüfer vergleicht die 29 Dateien
zusätzlich mit den tatsächlichen öffentlichen Git-Blobs; kein zurückversionierter
aktueller Installer und keine nachträgliche Umdeutung historischer Nachweise.

| Echter Vorgänger | Öffentlicher Originalcommit | Originaldateien |
|---|---|---:|
| 2.0.0 | [8c04f0ee](https://github.com/gecompat/SQL_Server_Toolbelt/commit/8c04f0ee80921012bd53ca363fb1aa809a0708a1) | 5 |
| 3.0.0 | [2e1daeb6](https://github.com/gecompat/SQL_Server_Toolbelt/commit/2e1daeb60375b145360a15f173985ba921338976) | 5 |
| 3.1.0 | [7c4b32fe](https://github.com/gecompat/SQL_Server_Toolbelt/commit/7c4b32fe23d8527cf2966e5dff2f6a5a0bc1de6c) | 6 |
| 4.0.0 | [7a240210](https://github.com/gecompat/SQL_Server_Toolbelt/commit/7a240210850b859cf1cf2c016ff0fbeb4da99059) | 6 |
| 4.1.0 | [86f4b53e](https://github.com/gecompat/SQL_Server_Toolbelt/commit/86f4b53e9de0ecac22818892dcf0cb802b050bb6) | 7 |

Zehn Originalinstallationstexte und vier aktuelle Deploy-/Uninstall-Texte
werden aus ihren kanonischen Include-Bäumen erneut exakt abgeleitet.
Alle gelesenen Source-Knoten, privaten Exporte, Hilfsskripte, Regeln,
Labvertrag und Laufzeitinputs sind gehasht. Die anfänglichen Exporte
installieren ausschließlich die unveränderte ResultTable-1.0.0-Abhängigkeit.
Aktuell erwartet werden die vier Procedure-Signaturen mit 13/14/14/9 Parametern.

## Drei fehlende Profile je Vorgänger und Kontext

1. Der aktuelle Uninstaller entfernt den installierten echten Vorgänger.
2. Ein gezielt später Fehler des aktuellen Upgrades rollt vollständig zurück.
3. Das tatsächliche direkte Upgrade ersetzt den Vorgänger durch 4.1.1.

Originalinstallation, Wiederherstellung des Ausgangsstands und aktuelle
Deinstallation zwischen zwei Vorgängern sind ausschließlich Aufbau/Bereinigung.
Die Originalinstallation läuft jeweils in einer eigenen anschließend geschlossenen
Sitzung; die Überprüfung verwendet eine getrennte Sitzung. Bereits bestandene
V1-, aktuelle Repeat-, API-, Datenkopie-, Trigger-, SQLCMD- und Rechtefixtures
wurden nicht erneut qualifiziert.

Die Rollbackprobe fügt ausschließlich am eindeutigen Anker vor COMMIT
SQL 54932/State 1 ein. Verlangt sind identische Moduldefinitionen,
Schemaidentitäten/-owner und Modul-/Objekt-/Schemaproperties vor/nach dem Fehler,
erhaltene ursprüngliche Version/Signaturen und ein neutraler Transaktionszustand.
Die ResultTable-Abhängigkeit bleibt unverändert. Jedes bestandene Profil wird
sofort mit Version, Modus sowie kanonischem und ausgeführtem Texthash erfasst.
Der unabhängige Nachprüfer rekonstruiert alle 120 Fehlertexte und prüft
die exakt geordnete Menge aller 360 eindeutigen Profil-Tupel.

## Native Zielmatrix

| Ausgewähltes SQL-Ziel | Compatibility Levels | Modi | Kontexte |
|---|---|---|---:|
| Windows 2019/CU32 | 150 | lokal/direkt zentral | 2 |
| Windows 2022/CU26 | 150, 160 | lokal/direkt zentral | 4 |
| Windows 2025/CU8 | 150, 160, 170 | lokal/direkt zentral | 6 |
| Linux 2019/latest | 150 | lokal/direkt zentral | 2 |
| Linux 2022/latest | 150, 160 | lokal/direkt zentral | 4 |
| Linux 2025/latest | 150, 160, 170 | lokal/direkt zentral | 6 |

Windows ist der Clienthost mit System.Data.SqlClient und vorhandener
administrativer SQL-Lab-Anmeldung. Linux bezeichnet das SQL-Ziel.
Functional mit erforderlicher Verschlüsselung und unverändertem explizitem
Trustwert; kein Linux-Client-, Windows-SSPI-/GUI- oder authentifizierter TLS-Test.

Der gemeinsame vor SQL bestimmte Rahmen von höchstens 28 Ziel-/Auditaufrufen,
28 eigenen Datenbankreservierungen und 60 Minuten wurde mit **24 Aufrufen
und 24 Reservierungen** abgeschlossen; übrige Plätze geschlossen.
Zwei eigene Datenbanken je Lauf werden für die fünf Vorgänger seriell verwendet.
Jeder frische unabhängige Audit bindet das finale Originaljournal, tatsächliches
SQL-Ziel, entfernte eigene Datenbanken und unveränderte gesamte
Serverkonfiguration/Trust. Keine neuen Rechte, Benutzer, CLR-, Server-,
Zertifikats-, Truststore- oder Lab-Infrastrukturänderungen.
Private Originaljournale, Quellenkapseln und Diagnoseausgaben bleiben privat.

## Prüfung und verbleibender Scope

Die 13 Quellen-/Scopegegenproben bestehen: fehlende/falsch geordnete Versionen,
selbst neu gehashte Original-/Provenienz-/Renderfälschung, fehlende transitive
Pins, Kontext-/Modusabweichung, Fristüberschreitung, unechte boolesche Freigabe
und Erweiterung des reinen Abhängigkeitsexports werden abgewiesen.
Tatsächlicher Lab-ValidateOnly-Preflight und unabhängiger Nachprüfer bestehen.

Vollständiger Dokumentationsaudit und tatsächliche Head-/Main-CI sind separate
Integrationsgates; ihre tatsächlichen Ergebnisse stehen im zugeordneten PR.
Die heutigen direkten bekannten Zwischenversions-Upgrades und deren gezielte
späte Recovery sind damit geschlossen. Historische datierte Teilnachweise
bleiben unverändert ihren Originalartefakten zugeordnet. Nicht abgedeckt:
andere Clients/Identitäten, zusätzliche Rechte, andere Fehlerstellen,
externe Consumer-/Namespace-/Sicherheitsnegativfälle und übrige
Modulgesamtpflichten. Der teilweise validierte/unveröffentlichte Modulstatus bleibt;
keine Veröffentlichung oder Tags.
