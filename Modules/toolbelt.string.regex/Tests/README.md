# Regex-Tests

## R2b (1.2.0)

Build und `powershell -File Modules/toolbelt.string.regex/Tests/Runtime/run-framework-relations.ps1 -AssemblyPath .runtime/regex-release/Toolbelt.String.Regex.dll` sind am 2026-10-01 erfolgreich. Die Suite verarbeitet tatsächlich 100000 Zeilen und 16 MiB Text, prüft Empty-Split ohne Zeichenverlust, terminale Treffer, NULL-/Fehlerpriorität und atomare Enumeratorrückgabe. Die unveränderte R2a-Frameworksuite ist ebenfalls erfolgreich. Keine SQL-SAFE-/Kapazitätszusage daraus.

SQL-Runtime, SQLClient-Metadaten und minimale SELECT-Rechte lokal/direkt zentral werden durch `Relations.Contract.sql`, `Relations.Metadata.ps1` und `Relations.Rights.sql` geprüft. `New-LegacyTestArtifacts.ps1` baut gepinnte echte 1.0-/1.1-Fixtures; der Regexadapter prüft neue Platzkollisionen, Vorgänger-Uninstall-Erhalt, echtes Upgrade und Dependency-Schutz. Der vollständige R2b-Adapter lief am 2026-10-01 auf SQL Server 2025 Windows/CU8 bei CL150/160/170 und SQL Server 2019 Linux/latest CL150 erfolgreich. Weitere R2b-Ziele bleiben offen; historische Nachweise bleiben erhalten.

Die gezielte SQL-100000-Zeilen-Stressprobe akzeptiert ausschließlich vollständige Ausgabe oder den vertraglichen SQL6522/TBX_REGEX_TIMEOUT ohne Teilzeilen. Sie ist keine 100k-SQL-Durchsatzevidenz; ein solcher Durchsatznachweis ist `not executed`. Kleine Rowlimit-/Grenzfalltests bleiben strikt. Ein separater SQLClient-SELECT prüft sowohl Rowlimitfehler als auch Runtime-Timeout ohne eine erste verwertbare Zeile. Lowpriv-CrossDB-Mappings bleiben ungetestet, direkt zentrale SELECT-Minimalrechte sind kein Ersatz dafür.

Der statische Validator prüft CLR-Projekt, Parsergrenzen, SAFE-/Trust-
Deployment, Manifest und Runtimeartefakte. Der Runtimeadapter deckt den
Dialekt, UTF-16-Positionen, NULL, Flags, Grenzen, stabile 6522-Präfixe,
Timeout, Erst-/Wiederholungsdeployment, Kollision, Central und Uninstall ab.

Die vollständige Pflichtmatrix lief am 2026-08-30 auf physischen SQL-Server-
2019-, 2022- und 2025-Zielen unter Windows base und Linux latest erfolgreich.
Die Adapter löschten ihre synthetischen Datenbanken und neu erzeugten
Trust-Einträge; die Lab-Umgebungen wurden nicht beendet.

Evidenz: `local: Tests/CI/run-lab-local.ps1`.

R2a wird zusätzlich mit `Transformations.Contract.sql` geprüft. Für ein
reproduzierbares echtes Upgrade zuerst `Scripts/New-LegacyTestArtifacts.ps1`
nach dem aktuellen Releasebuild ausführen. Der gepinnte öffentliche Gitstand
liefert das unveränderte Vorgängerbinary; vollständige Git-History ist nötig.
`powershell Tests/Runtime/run-framework-transformations.ps1 -AssemblyPath
<ReleaseBinary>` qualifiziert Restbudget und Enumeration unter .NET Framework.
Diese Nachweise sind keine Last-/Durchsatzzusage. Runtime-Matrix, Upgrade und
Concurrency werden vom bestehenden Regexadapter ausgeführt.

## Aktuelle Validierungsevidenz

<!-- BEGIN GENERATED:MODULE_EVIDENCE -->
- Datum: `2026-10-01`
- Nachweis: `local: Tests/CI/run-lab-local.ps1; Windows PowerShell: run-framework-relations.ps1`
- Scope: R2b auf SQL Server 2025 Windows/CU8 bei CL150/160/170 und SQL Server 2019 Linux/latest CL150: vollständiger Regexadapter, Empty-/UTF16-/NULL-/Fehlerpriorität, 16 MiB Outputhash, strikte kleine Rowlimits, SQLClient-Schema/Metadata und SELECT-Atomicity bei Rowlimitfehler/Runtime-Timeout lokal und central, SELECT-Minimalrechte lokal/direkt zentral, genuine 1.0/1.1 Upgrade, vier neue Namenskollisionen mit imitiertem Marker, historischer Uninstall-Erhalt, 1.2 Reinstall/Marker/Dependency-Uninstall/Cleanup. Framework tatsächlich 100000 Zeilen; gezielte SQL-100k-Probe nur vollständige Ausgabe oder atomarer Timeout, keine SQL-100k-Durchsatzevidenz. Weitere R2b-Ziele und Lowpriv-CrossDB noch nicht ausgeführt.
- Ergebnis: `success`
<!-- END GENERATED:MODULE_EVIDENCE -->
