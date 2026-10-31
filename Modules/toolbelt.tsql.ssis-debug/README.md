# SSIS Data Flow Debug SELECT

Der aktuelle Entwicklungsvertrag erzeugt aus DTSX-Bytes eine bearbeitbare
JSON-Vorlage und lesende Debug-Scripts für SQL-Server-Datenflüsse. Für ein
vollständig auflösbares Ziel bündelt `DebugScript` die benötigten
Vorbereitungs-, Plan-, Ergebnis- und Bereinigungsbatches.

Der [neutrale Modellaustausch mit Analyze](Exchange/README.md) verwendet
denselben typisierten Kern und einen externen .NET-Host. Analyze verarbeitet
das Modell ohne CLR- oder Toolbelt-Installation. Die bestehenden
Debug-SQL-Ausgaben und der neutrale Export verwenden denselben Modellkern.

Der aktuelle Standard verwendet `bindings-template` und `explain` ohne
Profil-Opt-in. Die bearbeitbare Vorlage verwendet `schemaVersion: 2` und
`profile: "ssis-debug-components-v2"`; ein `bindings-template-v2`-Alias oder
ein öffentlicher V1-API-Pfad wird nicht angeboten. Die verbindliche
[API-Semantik](../../Documentation/Architecture/SSIS_CURRENT_API_CONTRACT.md)
ergänzt den weiterhin geltenden [Komponentenvertrag](../../Documentation/Architecture/SSIS_COMPONENTS_V2_CONTRACT.md).
Ressourcenlimits werden über 24 benannte `bigint`-Parameter gesetzt; `0` ist
unbegrenzt und JSON-Ressourcenoptionen sind ungültig.

Die [historische Komponenten-V2-Installation](Documentation/ComponentsV2Installation.md)
beschreibt die bereits qualifizierten, unveränderten Vorgängerartefakte. Sie ist
kein Nachweis des aktuellen SQL-Parametervertrags oder einer aktuellen Lieferung.
Die [Anleitung für den aktuellen Entwicklungsstand](Documentation/CurrentInstallation.md)
beschreibt den neuen T-SQL-Installer, das aktuelle ZIP sowie Vorlage, Parameter
und `DebugScript`-Verwendung.
Die [API-Beschreibung](Documentation/USP_ExplainSsisDataFlow.md) zeigt den
SSMS-Aufruf. [Testumfang und offene Gates](Tests/README.md) sind getrennt
ausgewiesen. Die historischen ZIP- und Installerbytes haben begrenzte,
nativ gebundene Windows-Nachweise; sie qualifizieren den aktuellen Vertrag
nicht. Aktuelle Head-/Main-CI und Integration werden am jeweiligen PR-/Merge-Head
separat nachgewiesen. Der aktuelle freigegebene Debugvertrag ist auf Windows
funktionsqualifiziert (`validated`); das Modul bleibt `unreleased`.

Das [vollständige SSMS-Beispiel](Examples/README.md) mit
[`SsmsDebugWalkthrough.sql`](Examples/SsmsDebugWalkthrough.sql) und synthetischer
DTSX-Fixture zeigt Import, JSON-Vorlage, Werteänderung, Stufenauswahl und direkte
DECLARE-Änderungen einschließlich erwarteter Ergebnisse und Cleanup.

Die [Installationsanleitung](Examples/Installation/README.md) enthält die
SQL-Server-Vorbereitung, einen PowerShell-Installer mit Offline-Artefaktprüfung
und die anschließende Installationskontrolle für Parser, ResultTable und
SSIS-Debug einschließlich des getrennten Assembly-Trust-Opt-ins.

Das [vollständige ZIP-Installationspaket](InstallPackages/README.md) enthält
den qualifizierten SSIS-Build mit Pipeline-Identitäten und qualifizierten Lookup-Ausgangsrollen einschließlich
passender DLLs, SQL-/PowerShell-Skripte und SSMS-Beispiel zum Testen ohne eigenen
Build. Der externe Exporthost gehört nicht zu diesem SQL-Installationspaket.
Build- und Paketnachweise stehen getrennt in der Prüfmatrix.

Die Analyse führt keine Quellabfrage und kein SSIS-Paket aus. Für die
Dependencyprüfung werden ausschließlich Metadaten derselben SQL-Instanz
gelesen. Connections werden explizit auf Datenbanken abgebildet; Credentials
und Connection Strings gehören in keines der JSON-Dokumente.

Quell-, Referenz- und zulässige Kataloglesezugriffe erhalten `WITH (NOLOCK)`.
Damit können unbestätigte, fehlende oder doppelt gelesene Zeilen auftreten;
Schemasperren bleiben möglich. Vollständige SSIS-Laufzeitgleichheit wird nicht
behauptet. Lookup-Mehrfachtreffer werden über den vollständigen effektiven
Schlüssel reduziert und in sitzungslokalen Temp-Tabellen für weitere
Prüfstufen festgehalten. Eine eigene `CleanupSql`-Zeile räumt sie auf.

Optionale Quellinstallation für die Entwicklung: Parser 2.0.1 und Result Table 1.0.0
separat installieren, Release
mit `Scripts/New-ClrReleaseArtifacts.ps1` reproduzierbar bauen, den exakten
Assemblyhash administrativ freigeben und `Artifacts/Deploy.WithAssembly.sql`
im SQLCMD-Modus mit `DeploymentMode=local` oder `central` ausführen. Der
UNSAFE-/Strict-Security-Vertrag wird nicht aufgeweicht. Shared Dependencies
und Trusteinträge werden beim Uninstall nicht entfernt.

Die aktuelle Funktionsabnahme bindet den heutigen Source-Build an das vorhandene
[Parameter-Help-Paket](../../Releases/1.0.0/PARAMETER-HELP.md). Sie umfasst zwölf
Windows-/Engine-/CL-/Moduskontexte mit 12.396 Assertions und getrennten Audits.
Die [Prüfmatrix](Tests/README.md) erklärt Komponenten-, API-, Callerrechte-,
Lifecycle- und Ressourcenabdeckung, weiterverwendete Belege und die getrennten
Supportgrenzen. Frühere Pipeline-/Scope-Builds und echte Upgradepfade behalten
ihre eigenen datierten Nachweise. Das Modul bleibt unveröffentlicht.
Die Abnahme verwendet `TestPurpose=Functional` mit dem ausdrücklich
gesetzten Trustwert des schema-validierten Labvertrags. Für diese Funktion
ist Serverzertifikatsprüfung keine fachliche Voraussetzung. Die getrennte
authentifizierte TLS-Abnahme bleibt `not executed`.

## Aktuelle Validierungsevidenz

<!-- BEGIN GENERATED:MODULE_EVIDENCE -->
- Datum: `2026-10-31`
- Nachweis: `local: aktuelle SSIS-Funktionsqualifikation, zwölf Windows-/CL-/Moduskontexte und unabhängige Audits`
- Scope: Aktueller Binary und Deployment exakt an das bestehende Parameter-Help-Paket gebunden. Zwölf native Kontexte: SQL2019/CL150, SQL2022/CL150/160 und SQL2025/CL150/160/170 jeweils local/central, mit BIN2, CS_AS beziehungsweise CI_AS_SC_UTF8. 12396 Assertions für aktuellen Default, komponierte Komponenten-/Ausdrucks-/Plan-, Katalog-/Safety-, API-/ResultTable-, Callerrechte- und Lifecycleverträge; zwölf getrennte Abschlussaudits. Native 64-Gruppen-Pläne mit mehr als16 Einheiten auf SQL2025/CL170 in beiden Modi unter128MiB Defaultoutput. Aktuelle Full26-Frameworkprüfung und22 Wiederverwendungsgegenproben bestanden;22 unveränderte fachliche Quellen und APIgleichheit ohne Beschreibungstexte binden alte ZIP-/Standalone-/Snapshotbelege. Elf frühere Harness-/Fixturefehler, ein positiver Teilumfang und ein historischer positiver Gesamtlauf bleiben getrennte Historie; alle25 nativen Abschlussaudits bestanden. Qualifiziert ist der freigegebene Debugvertrag; Lowpriv-CrossDB-Identitäten, GUI/Windows-Anmeldung, administrativer Installer-Trust, authentifiziertes TLS, harte Recovery, Linux-Exporthost und Produktionskapazität bleiben getrennt. Veröffentlichung nicht autorisiert.
- Ergebnis: `success`
<!-- END GENERATED:MODULE_EVIDENCE -->

Der optionale externe [Begleittransport für native Objektkennungen](Exchange/README.md#native-objektkennungen-als-begleittransport)
verwendet denselben Paketkern. Er liefert GUIDs für eine separat zu belegende
Analyze-Korrelation und enthält weder einen Logdecoder noch ein Laufzeiturteil.
