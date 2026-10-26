# CSV: getrennte Callerrechte für Parser, Writer und ResultTable

Stand 2026-10-26: Der begrenzte Caller- und Ausgabewegscope der bereits
freigegebenen CSV-USPs 1.0.0 ist bestanden. SQL2019 CL150, SQL2022 CL150/160
und SQL2025 CL150/160/170 wurden auf Windows und Linux geprüft, jeweils lokal
und direkt in der zentralen Installationsdatenbank. Modulstatus bleibt
`partially validated`, `unreleased`; Veröffentlichung und Tags sind nicht freigegeben.

## Erforderliche vorhandene Objektrechte

| Aufruf | Direkte Ausgabe | Zusätzlich bei ResultTable |
|---|---|---|
| `toolbelt_file.USP_ParseCsv` | EXECUTE auf die USP und SELECT auf `toolbelt_file.TVF_InternalParseCsv` | EXECUTE auf `toolbelt_core.USP_PrepareResultTable` |
| `toolbelt_file.USP_WriteCsv` | EXECUTE auf die USP und jeweils auf `toolbelt_file.SVF_InternalMeasureCsvCell` und `toolbelt_file.SVF_InternalQuoteCsvCell` | EXECUTE auf `toolbelt_core.USP_PrepareResultTable` |

Dies sind die getesteten Kombinationen im unverändert installierten Ownershipstand.
Die dynamischen Arbeitsschritte verwenden Callerrechte. Fehlt das öffentliche
EXECUTE, wird exakt SQL229 erwartet. Bei erteiltem öffentlichem EXECUTE, aber
fehlender Sichtbarkeit eines benötigten internen Kerns beziehungsweise des
ResultTable-Helfers prüft die Fixture exakt SQL55309. Sie akzeptiert keine
beliebige Fehlermeldung als Rechtebeleg. Die andere öffentliche CSV-USP bleibt
in jedem Zustand selbst für `@Hilfe=1` mit SQL229 gesperrt.

## Entwickelte Prüfung und tatsächliche Ergebnisse

Neu sind der auf genau eine bestehende CSV-DLL begrenzte
[Labtreiber](../../Tests/Release/Invoke-CsvCallerLab.ps1), die eigenständige
[SQL-Fixture](../../Tests/Release/Runtime/Csv.CallerRights.sql) und vier
[Offline-Berichtsprüfungen](../../Tests/Release/test_csv_caller_profile.py).
Die bestehende Release-Regressionssuite importiert diese vier Prüfungen;
es entstehen keine neuen CI-Jobs oder Trigger. Der gemeinsame Trust-/
Konfigurationshelfer und alle bisher qualifizierten Treiber bleiben unverändert.

Pro Datenbank werden sieben Parser- und neun Writerrechtezustände geprüft:
ohne Grant, Teilkombinationen, vollständiges Profil und erneuter Entzug. Jede
Kombination läuft über beide Ausgabewege. Breite Rollen-, Datenbank- oder
Schemarechte sowie zusätzliche Objektrechte führen zum Abbruch. Insgesamt:
384 Rechtezustände, 48 vollständige Profile, 144 erfolgreiche Ausgabewege,
672 strikte SQL229- und 336 strikte SQL55309-Abweisungen.

Parsertext und Writerzellen werden unabhängig als feste synthetische Eingaben
gesetzt. Die sechs Parserzellen und die eine Writerzeile prüfen Header,
zweidimensionale Ordinals, Komma/Quote, SQL-NULL und wörtliches NullToken.
Der Writer muss außerdem exakt LF einschließlich finalem Abschluss, DataRows2
und ColumnCount2 liefern. Bytevergleiche unterscheiden NULL und Text und
erhalten Zeichen exakt; ein zweiter Provideraufruf erzeugt keine Sollwerte.
Insgesamt 504 feste Ergebniszeilenorakel über typisiertes INSERT EXEC und
caller-eigene ResultTable. Transaktionszustände werden getrennt vor/nach dem
Erfolgsaufruf erfasst, ohne Tabellenabfrage im selben Sessionzustandsausdruck.

Zwei frische Kontrollversuche werden an den beabsichtigten Prüfstellen
abgewiesen: falscher fester Sollwert und zusätzliches Schema-SELECT.
Alle 14 nativen Versuche sind terminal; zwölf Matrixfälle bestanden, beide
Kontrollen endeten erwartungsgemäß `FAILED_CLEANED`. Nach sämtlichen eigenen
Verbrauchern bestätigen 14 weitere getrennte rein lesende Auditprozesse die
Abwesenheit aller 26 eigenen Datenbanknamen, ursprüngliche Konfiguration sowie
entfernten eigenen beziehungsweise unverändert vorhandenen Trust.

## Wiederholbarkeit und Grenzen

Der private Runset unter `.runtime` benötigt `schema_version=csv-caller-contract/v1`,
zwölf explizite Ziel-/CL-Auswahlen, den schema-validierten Labvertrag, genau
Toolbelt_File_CsvMemory, ResultTable1.0.0, beide Deploymentexports sowie alle
Pflichtquellen und deren Pins. Vor einem neuen Lauf gelten die
[Labregeln](../../AGENTS.md) und ein geprüftes freies Testfenster. Bestehende
Journale werden nicht erneut ausgeführt oder überschrieben.

```powershell
python -B Tests/Release/test_csv_caller_profile.py
pwsh -NoProfile -NonInteractive -File Tests/Release/Invoke-CsvCallerLab.ps1 -RunsetPath $RunsetPath -CaseIndex $CaseIndex
pwsh -NoProfile -NonInteractive -File Tests/Release/Invoke-CsvCallerLab.ps1 -RunsetPath $RunsetPath -CaseIndex $CaseIndex -AuditOnly
```

Die Paket-DLL ist bytegleich zu zwei früheren isolierten reproduzierbaren Builds;
sämtliche aktuellen Compile-Inputs stimmen mit dem belegten Buildstand überein.
Es gab keinen neuen Build. Der [maschinenlesbare Bericht](csv-caller-profile.json)
bindet die ausgeführten Quellen und abstrakten Ergebnisse. Endpoints, reale
Konfigurationswerte, Trusthashes, Zugangsdaten und Runtimeausgaben bleiben privat.
Fachtests verwendeten verschlüsselte Functional-Verbindungen mit dem expliziten
Trustwert des validierten Vertrags; authentifiziertes TLS ist nicht ausgeführt.

Die bisherige Manifest-/Paketformulierung zu CSV-Callerrechten bleibt als
getrennter Metadaten-/Paketpflegepunkt offen. Produkt-SQL, C#, Manifeste und
Paketpayloads wurden in dieser Welle nicht geändert. Direkte Clientmetadaten,
vollständige Fehler-/KeepData-/Lifecycle-/Ressourcenmatrix, andere Ownershiplayouts,
Heap-/Parallelitätsgrenzen und echte CrossDB-Identitätsmappings bleiben getrennt.
Die bestehenden Modulnachweise bleiben an ihre jeweiligen Prüfstände gebunden.
