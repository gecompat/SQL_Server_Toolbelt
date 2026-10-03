# Test-Evidence

Die Manuelle Windows-CLR-Preflight-Validierung vom 2026-08-04 war auf SQL Server 2025 unter Windows erfolgreich. Sie umfasste .NET-Framework-4.8-CLR-Build, SHA2-512-Trust, lokales Deployment, alle Help-Verträge und die kontrollierte SQL-Authentication-Ablehnung im `Caller`-Modus ohne I/O-Spuren. Der Lauf `Ergänzender Windows-CLR-Preflight-Lauf` vom 2026-08-05 bestätigte kontrolliertes ServiceAccount-Verzeichnis- und Textschreiben mit konfiguriertem `WorkPath`.

Windows-Authentication-, NTFS-ACL- und weitere I/O-Tests bleiben `not executed`. Reale Pfade, Benutzer, NTFS-ACLs, Runtime-Ausgaben und Inhalte bleiben außerhalb des Repositorys.

Ein begrenzter nativer Windows-/SQL-Server-2025-Test vom 2026-10-03 bestätigte Installation und Wiederholung, scheiterte aber am Help-Metadatenvertrag: `IsRequired` war `int` statt `bit`. Der SQL-Fix typisiert die fünf Parameterzeilen ausdrücklich als `bit`, damit auch `IsNullable` seinen vertraglichen Typ behält. Der korrigierte Stand bestand anschließend die Prüfung der zwölf CLR-Spaltentypen, sieben Help-Zeilen und zulässigen NULL-Werte für `USP_WriteBinaryFile @Hilfe=1`. Dies ist ein begrenzter Help-Nachweis, kein vollständiger Modulnachweis.

Der nachfolgende Caller-Dateischreibaufruf scheiterte mit `51540/1`; seine konkrete Providerursache wird getrennt untersucht. Alle eigenen Testressourcen wurden bereinigt; jeweils eine separate frische Prüfung bestätigte dies. Caller-/NTFS-/I/O-Nachweise bleiben offen. Die fehlgeschlagenen Gesamtläufe werden nicht als Erfolg gewertet.

Der .NET-Framework-4.8-Build und der statische Vertrag waren im Wartungslauf https://github.com/gecompat/SQL_Server_Toolbelt/actions/runs/30692267356 erfolgreich. Dies ist kein Windows-SQL-Server-/NTFS-Runtime-Nachweis.

## Aktuelle Validierungsevidenz

<!-- BEGIN GENERATED:MODULE_EVIDENCE -->
- Datum: `2026-10-03`
- Nachweis: `Portierter NoOverwrite-Frameworktest und private Prozesskontrollen`
- Scope: Aktueller sourcegebundener Fixed-only-Harness: neun Fälle/254 Assertions, Staging-/Zielerhalt und eigene Bereinigung erfolgreich; vier private tatsächliche Prozesskontrollen für Nonzero, Timeout, Capturegrenze und Postpin-Drift erfolgreich. Aktueller Projektbuild/Releaseartefakt mit Assemblyversion1.0.0.0 ebenfalls erfolgreich. Offline-Scope ohne SQL, Caller-/NTFS-Nachweis; CI am exakten PR-Head separat.
- Ergebnis: `success`
<!-- END GENERATED:MODULE_EVIDENCE -->

## NoOverwrite: begrenzter Offline-Nachweis 2026-10-03

Der korrigierte aktuelle Provider besteht den .NET-Framework-4.8-Projektbuild und die kanonische Releaseartefakt-Erzeugung. Die historische private Helperqualifikation besteht neun synthetische Fälle mit 254 Assertions: vorhandenes und während des Schreibens erzeugtes Ziel bei NoOverwrite, leere Ausgabe, Overwrite=true und eigene Staging-Bereinigung bei Writefehler. Dies belegt weder SQL-Caller-Impersonation noch NTFS-ACLs oder Power-Loss-Verhalten.

Der neue [Fixed-only-Test](./Framework/README.md) kompiliert ausschließlich den aktuellen Provider und Harness aus gebundenen Sourcebytes. Seine aktuelle Ausführung bestand am 2026-10-03 neun Fälle/254 Assertions; der vollständige Witness, tatsächlicher Exit0, eigene Bereinigung und abschließende Pins wurden geprüft. Vier tatsächliche private Prozesskontrollen bestanden Nonzero, Timeout, Capturegrenze und Postpin-Drift einschließlich beendeter/disposierter eigener Children und fester Fehlercodes. Die elf synthetischen Witness-Kontrollen bleiben ein getrenntes Parser-Prädikat, keine Prozessausführung. Aktuelle CI wird separat am exakten PR-Head nachgewiesen. Neue Binary-/Caller-/NTFS-Runtimequalifikation bleibt offen. Historische Evidenz oben bleibt erhalten.
