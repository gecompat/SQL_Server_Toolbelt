# Regex-Tests

## Ownership des flüchtigen CI-Containers

`Tests/CI/run-regex-linux.sh` prüft im Runnerpfad Run-/Attempt-/SQL-/CL-Namen
und zufälligen Owner vor Setup. Der EXIT-Trap liest volle Container-ID und
Owner gemeinsam, entfernt ausschließlich diese ID und verlangt frische
Namensabwesenheit. Fremde oder unlesbare Identität, Dockerfehler, verbleibender
Container oder nicht entfernte private Dateien liefern
`REGEX_CI_CLEANUP_UNVERIFIED` und Exit1. Bestätigter Cleanup liefert
`REGEX_CI_CLEANUP_VERIFIED` und erhält einen vorherigen Fehlerstatus.
Runner-Cleanup sendet keine SQL-Abfrage über den ungeprüften Namen.

Der bestehende Lab-Shim hat keinen Container: sein No-op und die begrenzte
zusätzliche R2a-Trustbereinigung bleiben im getrennten Labzweig. Die
Runnerprüfung erzeugt dort weder Ownerlabel noch Inspection. Synthetische
Offlinefälle über `python Tests/CI/test_owned_container_cleanup.py --module regex`
prüfen die echte Cleanupfunktion, einschließlich Namensaustausch und
erhaltenem Lab-Exit0/Exit7, ohne Docker-/SQL-/Labzugriff. Exakte Head-/Main-CI
wird separat im PR nachgewiesen. Kein Runner-/Host-Hardinterruptnachweis.

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
Ausgabe und SQL-100k-Durchsatz bleiben `not executed`; Die aktuelle CI wird separat als PR-Mergegate nachgewiesen.

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
Die gleiche Suite ruft den Materialisierungsvertrag auf: vollständige Bytes,
vermeidbare Kopien bei No-match/fehlender Occurrence/Gesamtersatz, terminale
leere Treffer und unveränderte Validierung. Stringreferenzen dienen nur dem
internen Allokationsnachweis; sie sind keine öffentliche SQL-Garantie.
Die festen Größen- und Zeitbudgets werden zusätzlich direkt geprüft.
Diese Nachweise sind keine Last-/Durchsatzzusage. Runtime-Matrix, Upgrade und
Concurrency werden vom bestehenden Regexadapter ausgeführt.

Die begrenzte Timeout-Untersuchung und ihre Aussagegrenzen stehen im
[Release-Prüfbericht](../../../Releases/1.0.0/REGEX-TIMEOUT-QUALIFICATION.md).

## Aktuelle Validierungsevidenz

<!-- BEGIN GENERATED:MODULE_EVIDENCE -->
- Datum: `2026-10-24`
- Nachweis: `local: Tests/Release/Invoke-ApiQualificationLab.ps1 mit Tests/Release/Runtime/Regex.Scalar.Rights.sql`
- Scope: Alle sechs öffentlichen Regex-Skalarfunktionen auf Windows/Linux SQL2019 CL150, SQL2022 CL150/160 und SQL2025 CL150/160/170 jeweils lokal und direkt zentral: feste Werte unter Benutzer ohne Login, EXECUTE allein ohne REFERENCES, Abweisung ohne Rechte/mit REFERENCES allein/nach Entzug sowie drei gesperrte interne CLR-Kerne. Zwölf positive Fälle und zwei absichtlich fehlerhafte Wert-/Rechtevarianten mit unabhängigen Cleanup-/Pinaudits; drei temporäre CLR-Konfigurationsscopes wiederhergestellt und separat geprüft. Das historische Capture-Timeout-Gate ist inzwischen unter ausdrücklicher Restrisikoakzeptanz separat abgeschlossen; keine behauptete Ursachenklärung oder vollständige Regex-Freigabe. Lowpriv-CrossDB, weitere Ressourcen-/Parallel-/Recovery-/Clientgates und aktuelle Head-CI bleiben getrennt.
- Ergebnis: `success`
<!-- END GENERATED:MODULE_EVIDENCE -->
