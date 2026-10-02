# Regex-Tests

## Capture/Replace (1.3.0)

`Tests/Framework/run-framework-captures.ps1 -AssemblyPath <ReleaseBinary>`
bestand am 2026-10-02 sieben isolierte Framework-Kinder mit konfiguriertem
256-KiB-Stack und zehn Sekunden Prozessdeadline: legacy75, budget102,
core72, faults193, history400223, output15, exhaustive2184 Assertions.
Die Suite verarbeitet tatsächliche 100000 Captures und 99099 verschachtelte
nullable Captures, qualifiziert konservative Historiengrenzen, Standard-/
Large-Outputcharge samt Gruppennamen und vergleicht die bisherigen sieben
APIs. Bestehende R2a-/R2b-Frameworksuiten bestanden gegen dasselbe Binary.
Kein SQL-SAFE-, Heap-, Backtracking- oder Durchsatznachweis daraus.

Der gezielte Lab-Treiber `Tests/CI/run-regex-captures-lab.ps1` prüft vor
Verbindung alle zwölf Release-Quellfingerprints, DLL-/Deploykopplung und den
integrierten Frameworkvertrag. Er verwendet ausschließlich schema-validierte
ausgewählte Ziele, keine Parameteraktivierung oder Rechtevergabe. Neue exakte
Trusthashes werden nur opt-in und mit privatem Restorejournal registriert;
Cleanup prüft unveränderte Ownership und alle möglichen Assemblyverbraucher.
SQL-Contract-/Client-/Lifecycle-Evidence ist separat zu dokumentieren.

Am 2026-10-02 bestand `Tests/CI/run-regex-captures-lab.ps1
-ApiQualificationOnly` jeweils lokal und zentral auf SQL Server2025 Windows/CU8
CL150/160/170 und SQL Server2019 Linux/latest CL150. Umfasst die unveränderten
R1b-/R2a-/R2b-Orakel, neue unabhängige Capture-/Replace-Orakel, nullable
SQLClient-Metadaten/Defaults, atomare Fehler und Standard-Namenschargegrenzen.
Der tatsächliche Datenbank-Assemblyhash entsprach dem vorher Framework-
qualifizierten Binary. Alle eigenen Datenbanken und neuen Trusteinträge
wurden überprüft entfernt; keine Parameteraktivierung oder Rechtevergabe.

Der vollständige Lifecycle-Gate war vor der zusätzlichen Freigabe **blockiert**: unsigned `clr_name`
liefert im geprüften Kontext keine tatsächliche Releaseversion. Das bestehende
historische CLR-Versionserwartung blieb fail-closed; die zusätzliche erwartete Hashbindung
ist seit der Benutzerantwort „Ja, exakte Hashbindung freigeben“ vom 2026-10-02
freigegeben. Die Adapter binden die offline geprüften installierten Binarybytes
explizit, prüfen Format-/Abwesenheits-/Mismatch-Fehler sowie den zweiten
Vergleich unter AppLock.
API-only ist kein Upgrade-,
Wiederdeployment-, Caller-TX-/Lock-/Rollback- oder Uninstall-Nachweis.
Weitere SQL-Versionen, neue Minimalrechte/CrossDB-Mappings und die tatsächliche
16-MiB-Capture-Outputgrenze in SQL sind noch nicht ausgeführt. Keine
100k-SQL-Capture-Durchsatzbehauptung.

Finaler Gesamtadapter vom 2026-10-02: Linux 2019/latest CL150 und Windows
2025/CU8 CL150/160/170 jeweils lokal und zentral erfolgreich. Der echte
1.2-Upgrade, Wiederdeployment, Caller-TX mit allen ON/OFF-Kombinationen,
Lock-Contention, post-DROP-Rollback, Ownership-/Future-Slot-/Dependency-
Erhalt, Uninstall und eigenes DB-/Trustcleanup bestanden ebenfalls.
Historische fehlgeschlagene Gesamtversuche betrafen eine nicht normalisierte
SQLCMD-Direktive des Vorgängers, `SET NOCOUNT ON` im Snapshot und die nach
Open credentialbereinigte Connection-String-Quelle des Lock-Halters. Die
finalen Adapter beseitigen diese Testfehler; die früheren Läufe sind kein PASS.
Neue Capture-Minimalrechte, weitere Ziele, tatsächliche große SQL-Capture-
Ausgabe und SQL-100k-Durchsatz bleiben `not executed`; CI ist noch ausstehend.

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
- Datum: `2026-10-02`
- Nachweis: `local: Tests/CI/run-regex-captures-lab.ps1; Windows PowerShell: Tests/Framework/run-framework-captures.ps1`
- Scope: Finaler Capture/Replace-Gesamtadapter lokal/zentral auf Linux 2019/latest CL150 und Windows 2025/CU8 CL150/160/170: sieben alte und zwei neue APIs, unabhängige Orakel, SQLClient acht nullable Spalten/Defaults/Atomicity, Standard-Namenscharge, echter 1.2-zu-1.3-Upgrade, Reinstall, explizite erwartete SHA2_512-Binaryhashbindung, Caller-TX/SET-Erhalt, AppLock, post-DROP-Rollback, Versions-/Marker-/Future-Slot-/Schema-Kollisionen, Dependencies, Uninstall und verifiziertes eigenes DB-/Trustcleanup. Framework tatsächlich 100000 Captures und Standard/Large. Frühere API-only- und fehlgeschlagene Adapterstände bleiben historische Evidenz. Neue Capture-Minimalrechte, weitere Ziele, ältere 1.0/1.1-Capture-Upgrades, tatsächliche große SQL-Capture-Ausgabe und SQL-100k-Durchsatz nicht ausgeführt; CI ausstehend, teilweise validiert/unreleased.
- Ergebnis: `success`
<!-- END GENERATED:MODULE_EVIDENCE -->
