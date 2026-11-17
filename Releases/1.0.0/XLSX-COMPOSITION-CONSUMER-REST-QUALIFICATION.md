# XLSX: Kompositionen und providerfreie zentrale Consumer

Ausführung am 2026-11-17 (UTC): `PASS_FOR_DECLARED_SCOPE`. Das unveränderte
aktuelle fokussierte Paket besteht die vorhandenen Raw→Type- und
Raw→Type→Display-Kompositionen installiert sowie aus einer eigenen
Consumerdatenbank ohne lokale Providerobjekte. Der [JSON-Bericht](XLSX-COMPOSITION-CONSUMER-REST-QUALIFICATION.json)
bindet die tatsächliche Methode und sämtliche ausgeführten öffentlichen Inputs.

| Plattform / Patchselektor | SQL 2019 | SQL 2022 | SQL 2025 | Kontexte |
|---|---|---|---|---|
| Linux / latest | CL150 | CL150, CL160 | CL150, CL160, CL170 | lokal, direkt zentral, separater zentraler Consumer |
| Windows / CU32, CU26, CU8 | CL150 | CL150, CL160 | CL150, CL160, CL170 | lokal, direkt zentral, separater zentraler Consumer |

## Tatsächlich geprüfter Ablauf

Je Ziel-/CL-Paar werden die öffentlichen Erst-/Repeatinstallationen in zwei
eigenen Providerdatenbanken geprüft. Die unveränderte Display.Lifecycle-Fixture
bestätigt neun bekannte Slots samt Markern und internem Display-Binding. In
beiden Modi laufen anschließend die originalen Invoke-TypesComposition- und
Invoke-DisplayComposition-Helfer: 48 installierte Kompositionsläufe.

Für den zentralen Modus kommt genau eine dritte eigene Datenbank mit
Latin1_General_100_CS_AS hinzu. Vor und nach den Aufrufen werden der tatsächliche
DB-Kontext, Compatibility Level und die Collation geprüft; eigene
Benutzerobjekte, Assemblies, Toolbelt-Schemas und Modulmarker müssen fehlen.
Das sind 24 Providerfrei-Zeugen für zwölf separate Consumerkontexte.

Aus dieser Datenbank laufen beide unveränderten Metadatenhelfer und beide
Kompositionen mit ausdrücklich gesetzter Providerdatenbank: weitere 24
Kompositionsläufe und 24 Metadatenhelfer. Die zusätzliche originale
Katalognullabilityprüfung liest ihren Katalog aus der Providerdatenbank und
vergleicht ihn mit dem echten Reader aus dem Consumer: zwölf Prüfungen. Es
werden keine neuen Logins oder gemappten Identitäten eingerichtet; alle
Verbindungen verwenden die vorhandene administrative Labidentität. Das ist
keine Lowpriv-, andere Owner-, neue Netzwerk- oder Linux-Clienthostabnahme.

Die Kompositionen verwenden ausschließlich das bestehende synthetische
Neun-Zellen-Workbook und die festen ursprünglichen SQL-/Workbookhashes. Die
Originalhelfer lesen geprüfte Bytesnapshots, parametrisieren das Workbook und
prüfen unter anderem exakte Raw-Echos, Formel-/Cachetrennung und die bestehenden
Typ-/Anzeigeorakel. Private Caller-ResultTables liegen in tempdb; persistente
Consumerobjekte dürfen nicht zurückbleiben. Die aktuelle gemeinsame monotone
Restfrist wird an die unveränderten Readerhelfer weitergegeben; Ressourcen
werden auch bei Fehlern geschlossen.

Nach dem Schließen der Consumerverbindung wird zentraler Uninstall mit
ConfirmNoExternalConsumers=0 zwölfmal ausdrücklich mit 51536 abgewiesen.
Der vollständige Providersnapshot und alle Paketdefinitionen bleiben gleich.
Danach bestehen bestätigter öffentlicher Uninstall und UninstallAbsent sowie
die eigene Ressourcenbereinigung. Der historische Top-level-Lab-/Legacy-Lauf
wird nicht gestartet; neue Fachlogik wird nicht implementiert.

## Abschluss und Grenzen

Zwölf COMPLETE-Fälle und zwölf getrennte frische AUDIT_PASS binden jeweils das
exakte finale Journal. Alle 36 eigenen Datenbanken wurden entfernt, eigene
Konfigurations-/Trustzustände wiederhergestellt und fremde Zustände erhalten.
Der gemeinsame vorab festgelegte Rahmen umfasst höchstens 28 Lauf-/Auditaufrufe,
42 DB-Reservierungen und 60 Minuten ab erstem nativem Start, darin höchstens
zwei geänderte Adapterfälle nach Befund und bestätigtem Cleanup. Verbraucht:
24 Aufrufe und 36 Reservierungen; keine nativen Fehler oder Adapterkorrekturen.
Die Welle ist geschlossen. Freie Plätze eröffnen keine Wiederholung.

Die bisherige Create/Identity/Ownermarker/CL-Sequenz des Paketadapters liegt nun
in einem gemeinsamen Testhelfer. Local/central bleiben auf zwei eigene DBs
begrenzt; nur dieser Scope erlaubt die dritte CS-Consumerdatenbank. Der
SQL-freie Test prüft Besitzer-/Suffix-/Collation-/Zählerablehnungen vor SQL,
korrekte Journalzustände und Dispose bei Markerfehlern, alte lokale/zentrale
Erstellung, tatsächliches Consumer-Routing, leere Providerkataloge, getrennte
Katalogorakel, Confirm0, Fehler ohne PASS-Aufwertung, Auditgegenproben und die
realen AST-Scope-/Budgetselektionen. Testdoubles sind keine SQL-Pässe.

Aktuelle qualifizierte DLLs, Paket und bestehende Entwicklungs-/Trustfreigabe
werden wiederverwendet. Produktcode, öffentliche Parameter, Rechte, Identitäten,
Labressourcen, Zertifikate und Truststores bleiben unverändert. Andere
Consumer-/Namespace-/Owner-/Minimalrechte-, Host-/Transport-, Heap-/Kapazitäts-
und OS-/VM-Ausfallprofile sowie der gesamte Modulumfang bleiben separat.
Keine Veröffentlichung oder Tags; XLSX bleibt teilweise validiert.

Reproduzierbare Integritätsprüfung ohne SQL:

```text
python Scripts/Release/validate_xlsx_composition_consumer_rest.py
python -B Tests/Release/test_xlsx_composition_consumer_rest.py
```
