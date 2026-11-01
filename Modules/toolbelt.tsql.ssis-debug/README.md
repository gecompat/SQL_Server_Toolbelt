# SSIS Data Flow Debug SELECT

Der aktuelle Entwicklungsvertrag erzeugt aus DTSX-Bytes eine bearbeitbare
JSON-Vorlage und lesende Debug-Scripts für SQL-Server-Datenflüsse. Für ein
vollständig auflösbares Ziel bündelt `DebugScript` die benötigten
Vorbereitungs-, Plan-, Ergebnis- und Bereinigungsbatches.

Der [neutrale Modellaustausch mit Analyze](Exchange/README.md) verwendet
denselben typisierten Kern und einen externen .NET-Host. Analyze verarbeitet
das Modell ohne CLR- oder Toolbelt-Installation. Die bestehenden
Debug-SQL-Ausgaben und der neutrale Export verwenden denselben Modellkern.
Der externe Host besitzt einen getrennten, begrenzten
[nativen Windows-/Linux-Nachweis](Exchange/README.md#gemeinsame-prüfung).

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
ausgewiesen. Die ZIP-, Installer- und Snapshotnachweise werden nur bei
unveränderten Artefakt- und Quellbindungen weiterverwendet. Die aktuelle
Funktionsabnahme prüft den heutigen Defaultvertrag separat.
Aktuelle Head-/Main-CI und Integration werden am jeweiligen PR-/Merge-Head
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
Der getrennte [administrative SSIS-Trustschritt](Tests/InstallerTrust/README.md)
ist auf Windows SQL2019/2022/2025 geprüft; die vollständige Windows-Anmeldung
des Installationsbeispiels und dessen Servervorbereitung bleiben separat.

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
authentifizierte [TLS-Abnahme](Tests/Qualification/Current.AuthenticatedTls.Windows.20261031.json)
bestand zusätzlich auf einem eigenen Windows-/Hyper-V-SQL-2025-RTM-Run:
412 Assertions in local/central, CL170, signierter V2-Snapshot vor jeder
Anmeldung, Encrypt=True und TrustServerCertificate=False. Abschlussaudit und
Entfernung des eigenen Runs sind bestanden; bestehender Hosttrust blieb erhalten.
Die zusätzliche [Anmeldequalifikation](Tests/Qualification/Current.Access.Windows.CL.20261031.json)
bestand zwölf Kontexte mit 1.596 Assertions für echte Lowpriv-Cross-DB-SIDs
und Windows-Ausführung. Die sichtbare SSMS-Prüfung verwendete eine SQL-Anmeldung;
sie belegt keine Windows-Anmeldung in SSMS. Ursprüngliche Koordinatorfehler
und die getrennten erfolgreichen Abschlussaudits bleiben nachvollziehbar.

## Aktuelle Validierungsevidenz

<!-- BEGIN GENERATED:MODULE_EVIDENCE -->
- Datum: `2026-11-01`
- Nachweis: `local: Tests/InstallerTrust/Invoke-LabTrust.ps1 auf drei bestehenden Windows-Labzielen und unabhängige Audits`
- Scope: Öffentlicher administrativer SSIS-Trustschritt für den unveränderten aktuellen Binary auf SQL2019/CU32, SQL2022/CU26 und SQL2025/CU8: je 18 Assertions, 54 insgesamt, fehlender Eintrag und Wiederholung, NULL/Leerwert/Überlänge vor Mutation und bestehender eingeschränkter Guest-Kontext. Keine Netzwerk-Lowpriv-Anmeldung behauptet. Eigene Einträge entfernt, andere Trusteinträge und Konfiguration unverändert; drei finale unabhängige Audits PASS. Ein Vor-SQL-Adapterfehler, zwei bereinigte Fehlerfälle und drei frühere positive Fälle bleiben getrennt; alle acht tatsächlich ausgeführten Audits bestanden, insgesamt 17 Ziel-/Auditaufrufe. 26 Offlineprüfungen binden Quellen, Herkunft und Vor-SQL-Guards im bestehenden SSIS-Job. Ursprünglicher Snapshotinput für den später geänderten administrativen Guard wird ausschließlich aus seinem unveränderten hashgebundenen ZIP anerkannt, übrige Methoden/Binaries/Reports bleiben unverändert. Volle Windows-Anmeldung des Installers, PrepareServer, SSMS-Transport und harte Unterbrechung bleiben getrennt. Keine Veröffentlichung.
- Ergebnis: `success`
<!-- END GENERATED:MODULE_EVIDENCE -->

Der optionale externe [Begleittransport für native Objektkennungen](Exchange/README.md#native-objektkennungen-als-begleittransport)
verwendet denselben Paketkern. Er liefert GUIDs für eine separat zu belegende
Analyze-Korrelation und enthält weder einen Logdecoder noch ein Laufzeiturteil.
