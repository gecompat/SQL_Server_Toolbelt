# Abnahme der 19 stabilen Kandidaten

Arbeitspaket vom 2026-10-31: die 19 stabilen Kandidaten gegen ihre aktuellen
Quellen und den freigegebenen Supportzielumfang prüfen, ausführbare offene
Pflichtfälle abarbeiten und verbleibende Blocker benennen. Dies ändert weder
den 45-Modul-Zielumfang noch Modulstatus oder Veröffentlichungsfreigaben.

## Ausgewählte Prüfung

Die aktuelle Integration wird auf Windows und Linux mit SQL Server 2019/CL150,
2022/CL150/160 und 2025/CL150/160/170 geprüft: zwölf ausdrücklich ausgewählte
schema-valide Labkontexte, jeweils local/central und zentraler Consumer.
Vorhandene administrative Rechte werden genutzt; keine Logins, Grants,
Serveroptionen, CLR-, Trust-, Zertifikats- oder Labressourcenänderungen.
Functional verwendet Verschlüsselung und den expliziten Lab-Trustwert.

Ausführung am 2026-10-31: **PASS im begrenzten Integrationsscope**. Der Testweg steht in der
[Release-Testanleitung](../../Tests/Release/README.md#aktuelle-19-stabile-kandidaten-abnehmen).
Er verwendet aktuelle, commitgebundene Exporte, die bestehenden fünf
Paketorakel und installierte Help-Orakel statt extrahierter Ersatzprozeduren.
Pro Fall werden drei eigene Datenbanken mit Besitz- und Identitätsprüfung
angelegt und entfernt; ein separater Prozess auditiert Cleanup und Inputpins.

Die [maschinenlesbare Abnahme](stable19-acceptance.json) bindet den tatsächlichen
Ausführungscommit `e156a3d5`, die aktuellen Produkt-/Testquellen und beide
verbindungslos erzeugten Exporte. Zwölf Fälle und zwölf unabhängige Audits
bestanden ohne fehlgeschlagenen Nativversuch. Alle 24 Deploymentpfade bestanden
Neuinstallation, Repeat mit unveränderten Objektdefinitionen, Präsenz aller
56 öffentlichen APIs und zweimaligen Uninstall ohne Objekt-/Markerreste.
Die sechs Prozeduren mit 39 Parametern bestanden 576 Help-Aufrufe mit
36.576 gezählten Assertions, einschließlich Callertransaktion und Temp-Daten.
Die fünf bisherigen Paketorakel liefen auch über eine separate zentrale
Consumer-Datenbank mit der vorhandenen administrativen Identität. Alle 36
eigenen Datenbanken sind unabhängig als entfernt auditiert. Das sind feste
synthetische Ergebnisprüfungen; keine vollständige neue APIqualifikation.

## Vorhandene Nachweise und offene Grenzen

Die [Freigabematrix](FREIGABEMATRIX.md) benennt die 19 Kandidaten. Ihre
kanonischen Manifeste bleiben `validated` und `unreleased`. Die
[V0c-Fach- und Lastabnahme](../../Tests/V0C_RELEASE_GATE_STATUS.md),
[Callerberichte](EVIDENCE-MAP.md) und die
[Help-Qualifikation](../../Tests/Release/ParameterHelp.md) behalten jeweils
ihren ursprünglichen Scope und Ausführungszeitpunkt. Die kanonischen engen
Übergangsprüfer für Parameterhilfe, Base64-, Series- und Date-Spine-DDL-Kommentare
erhalten die Bindung früherer Fach-/Callerläufe an deren Originalbytes. Sie
erlauben keine beliebigen Quellnormalisierungen. Die Release-Regressionssuite
prüft diese Übergänge und die vorhandenen Berichtsbindungen; aktuelle
Help-Ausführung und gemeinsame Integration sind die oben neu ausgeführten
Fälle. Die drei großen Lastfälle von ResultTable, Base64 und Generate Series
bleiben am 2026-10-19 qualifiziert; sie wurden ohne geänderten fachlichen Input
nicht erneut ausgeführt. Optionale Zeitmessungen bleiben gemäß DEC-2026-036 optional.

## Zuordnung je Modul

Diese Tabelle beschreibt den Abnahmesnapshot vom 2026-10-31, keine zweite
laufende Statusquelle. Die [Module](../../Modules/README.md) und ihre Manifeste
bleiben autoritativ. Alle folgenden Module bestanden die aktuelle Integration;
ihre früheren vollständigen Fachadapter stehen jeweils im Manifest. Die
zusätzlichen Rechteprofile sind lokal und direkt zentral belegt, ohne damit
echte niedrigprivilegierte CrossDB-Identitäten zu behaupten.

| Modul (jeweils `toolbelt.`) | Zugeordneter zusätzlicher Nachweis |
|---|---|
| `binary.bit-operations` | [Utility-Caller](UTILITY-CALLER-QUALIFICATION.md) |
| `conversion.base64` | [Konvertierungs-Caller](CONVERSION-CALLER-QUALIFICATION.md), V0c-Pflichtlast und [DDL-Übergang](base64-ddl-help-transition.json) |
| `conversion.integer-base` | Konvertierungs-Caller, V0c-Fachmatrix |
| `conversion.uri-component` | Konvertierungs-Caller, V0c-Fachmatrix |
| `core.console-message` | [Console-Caller](CONSOLE-CALLER-QUALIFICATION.md), V0c-ADO.NET-/ODBC-Frames |
| `core.error-envelope` | [ResultTable-/Envelope-Caller](TABLE-ENVELOPE-RIGHTS-INVESTIGATION.md) |
| `core.execution-context` | [Fünf isolierte API-Profile](EXECUTION-CONTEXT-RIGHTS-QUALIFICATION.md) |
| `core.generate-series` | [Series-/Datums-Caller](SERIES-DATE-CALLER-QUALIFICATION.md), V0c-Pflichtlast und [DDL-Übergang](generate-series-ddl-help-transition.json) |
| `core.result-table` | ResultTable-/Envelope-Caller, V0c-Pflichtlast |
| `datetime.bucket` | [Vollständiger Date-Math-CL-Abschluss](DATE-MATH-CL-COMPLETION.md) |
| `datetime.calendar-difference` | Vollständiger Date-Math-CL-Abschluss |
| `datetime.date-spine` | Series-/Datums-Caller und [DDL-Übergang](date-spine-ddl-help-transition.json) |
| `datetime.truncate` | Series-/Datums-Caller |
| `json.path-exists` | [JSON-Pfad-Caller](JSON-PATH-CALLER-QUALIFICATION.md), V0c-Fachmatrix |
| `metadata.capability-catalog` | [Catalog-Caller mit begrenzter Sicht](CATALOG-CALLER-QUALIFICATION.md) |
| `metadata.identifier` | Utility-Caller |
| `string.directional-trim` | Utility-Caller |
| `string.split-characters` | Utility-Caller, V0c-Fachmatrix |
| `validation.semantic-version` | Utility-Caller, V0c-Fachmatrix einschließlich verschärfter NULL-/Kardinalitätsorakel |

Die 56 öffentlichen APIs sind den vorhandenen Caller-Fixtures zugeordnet.
Dies ist eine Quellenzuordnung, keine neue Ausführung dieser Rechtefixtures.
Überholte pauschale Windows-/Performance-/Client-Restangaben in alten
Matrixpassagen sind mit den späteren gebundenen Berichten abgeglichen;
historische Tests und ihre Aussagegrenzen bleiben erhalten.

## Verbleibende Blocker und fehlende Freigaben

| Grenze | Stand / benötigter nächster Schritt | Verantwortung |
|---|---|---|
| Echte CrossDB-Calleridentität | `not executed`: direkte zentrale Benutzer-ohne-Login-Profile und administrative Consumer sind belegt. Für eine niedrigprivilegierte CrossDB-Zusage fehlen ausdrücklich zugeordnete vorhandene Principals und Login-/User-Mappings sowie deren positive/negative Prüfung. Kein Serverlogin oder fremdes Mapping wird aus diesem Auftrag eingerichtet. | Testumgebungsadministration und Modulverantwortlicher; Bereitstellung beziehungsweise gesonderte Freigabe des konkreten Aufbaus |
| Unterstützter Installationsprincipal | Der vorhandene administrative Installationsweg ist geprüft. Ein reduziertes DDL-/Metadaten-/Release-Marker-Rechteprofil ist nicht qualifiziert. Vor einer solchen Supportzusage konkretes vollständiges Profil festlegen und separat abnehmen; API-Objektgrants qualifizieren keinen Installer. | Modul-/Releaseverantwortlicher; Entscheidung über den zugesagten Installationsscope |
| SSMS-GUI und Windows-Anmeldung | `not executed`: ADO.NET-/ODBC-Fachnachweise bleiben gültig. Für eine ausdrückliche GUI-/Windows-Login-Zusage geeignete bestehende Client-/Identitätsfixture bereitstellen und manuell prüfen. | Client-/Testumgebungsverantwortlicher; externe Voraussetzung |
| Authentifiziertes TLS | `not executed` in dieser Welle; eigenständige Transportabnahme für Serveridentitätszusagen. Kein Blocker der unabhängigen Functional-Prüfungen. | Lab-/Transportverantwortlicher |
| Konkrete Modulveröffentlichung | Fachlicher Review der vollständig ausgewählten Pflichtnachweise, finale Quell-/Paket-/CI-Bindung, ausdrückliche Freigabe je veröffentlichtem Scope und tatsächliche Modul-Veröffentlichungsrecords fehlen. Der aktuelle Auftrag autorisiert Prüfungen und Dokumentation. | Releaseverantwortlicher und Benutzer |
| Projekt-v1.0.0 mit 45 Modulen | Die 26 Preview-Zielmodule und ihre offenen Pflichtgates bleiben außerhalb dieses Arbeitspakets. Eine auf die 19 stabilen Kandidaten begrenzte öffentliche Lieferung benötigt eine ausdrückliche Scopeentscheidung; sie wird hier nicht vorausgesetzt. | Benutzer; [bestehender Supportzielumfang](SUPPORT.md) und [übrige Releasegates](RELEASE-GATES.md) |

Im ausgeführten Scope wurde kein Produktfehler festgestellt. Eine pauschale
stabile Modulfreigabe wird daraus nicht abgeleitet. Keine offenen Identitäts-
oder Clientfälle werden als PASS oder ohne Capabilityentscheidung als
`not applicable` gewertet. Worker-/Datei-/SSIS-/Hard-Recoveryfälle der übrigen
Module werden nicht auf diese reine T-SQL-Kohorte übertragen.

Rahmen: ein Arbeitspaket/ein PR, ein Implementierer, zwölf native Fälle mit
je einem separaten Audit; 300 Sekunden Arbeit, 360 Sekunden einschließlich
Cleanup und 400 Sekunden äußerer Watchdog je Prozess, höchstens 4800 Sekunden
für die Matrix. Kein automatischer Retry oder Start einer nächsten Welle.
Rohlogs und Restorejournale bleiben privat; Kosten und Tokenverbrauch unbekannt.
