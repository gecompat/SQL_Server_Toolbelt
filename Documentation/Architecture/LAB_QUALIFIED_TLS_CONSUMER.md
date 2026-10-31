# Gebundener Lab-V2-Consumer

## Geltungsbereich

Der V2-Consumer bindet den SC-2026-045-Transportpfad an den ausdrücklich
gewählten Labkontext und dieselben geprüften Exportbytes. Die Transportprobe
verwendet echte SQL-Verbindungen und legt keine fachlichen SQL-Objekte an.

Der aktuelle Consumer verwendet Windows, PowerShell 7.5+ und den tatsächlichen
registrierten Benutzer-/Client-/Trustkontext der operativen Lab-V2-Lane.
Linux als SQL-Ziel ist davon getrennt; ein Linux-Clienthost oder die öffentliche
Hyper-V-Lane erhält hierdurch keinen Nachweis. Die gemeinsame native
Windows-Teilmatrix ist für Docker und Podman mit SQL 2019 CU32, 2022 CU27
und 2025 CU9 separat bestanden.

Der zusätzliche ausdrücklich isolierte Linuxclient befindet sich in
Entwicklung und ist noch nicht nativ freigegeben. Sein dedizierter
[read-only Preflight](../../Tests/CI/Invoke-LabLinuxPreflight.ps1) wird durch
die gekoppelte öffentliche Lab-Vordergrundsitzung aufgerufen. Er ersetzt
weder die Windows-Abnahmen noch die bestehenden Feature-/Deploymentadapter.
Der gemeinsame Reader verlangt unter Linux zusätzlich eine bereits privat
gebundene opaque Sitzung, LinuxClientRef und Contextdigest. Er erzeugt diese
nicht selbst und liest einen Windows-StateRoot nicht als Linuxpfad.

Die Sitzung liefert denselben V2-Bytesnapshot. Vor jedem tatsächlichen
System.Data.SqlClient-Open und sqlcmd-Start wird der öffentliche Labreader
frisch für den betreffenden Stack aufgerufen. Ein weiterlaufendes monotones
Fenster erhält nach Abzug des gesamten Austauschs mindestens 30 Sekunden;
Linux- und Controllerwanduhr werden nicht voneinander subtrahiert. Der
Preflight prüft erwarteten SQL-Build, Verschlüsselung, Binary- und geladenen
ODBC-18-Hash ohne SQL-Objekte, Pooling, Retry oder Trustoverride.

Der Linuxpfad verwendet den getrennten
[LabLinuxQualifiedContract.ps1](../../Tests/CI/LabLinuxQualifiedContract.ps1).
Der bisherige gemeinsame Windowshelper und run-lab-local.ps1 bleiben
byteidentisch; historische Runtime-, Rechte- und Sourcebindungen werden
nicht umgedeutet. Der direkte öffentliche Windowsreader weist einen
Linux-Namespaceexport ab. Der Linux-Consumer wird über die explizite
Lab-Vordergrundsitzung aufgerufen.

Der Operator wählt den vertrauenswürdigen Toolbeltcheckout ausdrücklich im
Labaufruf aus. Lab hält den festen transitiven Quellsatz und prüft Gastkopien.
Weder Export noch Schema-/Umgebungsangaben wählen Code aus. Credentials
gelangen nur über die eigene stdin-Verbindung in den Gastprozess. Diese
Fähigkeit macht den allgemeinen Dateiresolver oder Shelladapter nicht
pauschal Linuxfähig; deren bisherige Capabilitygrenzen bleiben bestehen.

## Discovery und Autorität

Die zusätzliche SSIS-Abnahme verwendet den
[`Invoke-CurrentAuthenticatedTlsLab.ps1`](../../Modules/toolbelt.tsql.ssis-debug/Tests/Runtime/Invoke-CurrentAuthenticatedTlsLab.ps1)
auf einem ausdrücklich ausgewählten Windows-/Hyper-V-SQL-2025-RTM-Run.
Sie konsumiert dieselbe Readergrenze und dieselben signierten Bytes vor jedem
Open. Ihr eigener, gebundener Entwicklungs-/Cleanup-Scope enthält synthetische
SQL-Objekte; die oben beschriebene allgemeine Transportprobe bleibt lesend.
[Ausführung, Wiederherstellung und Grenzen](../../Modules/toolbelt.tsql.ssis-debug/Tests/README.md#aktuelle-authentifizierte-tls-abnahme)
sind vom historischen Container- und Linuxclientnachweis getrennt.

Die bestehende Discovery bleibt erhalten: Prozess vor Benutzer für
`SQL_SERVER_LAB_TEST_ENV_FILE`, sonst
`SQL_SERVER_LAB_DATA_ROOT/Exports/TestUmgebung.json`; Schemaoverride vor
benachbartem Schema und ein gesetzter Promptpfad muss existieren.
Der Resolver liest höchstens 4 MiB einmal durch einen gehaltenen Lesehandle.
V1-Functional-Verträge behalten ihre BOM-Erkennung und benötigen kein Labmodul.
Unbekannte Vertragsversionen werden abgewiesen.

V2 verlangt zusätzlich den expliziten Caller-Kontext:

| Parameter | Herkunft |
|---|---|
| `LabModuleFile` | Vom Operator gewählter vertrauenswürdiger Labmodulpfad |
| `LabTlsStateRoot` | Privater StateRoot des ausdrücklich gewählten eigenen TLS-Labs |
| `LabTlsRunId` | Dessen exakte RunId |
| `LabTlsInstanceId` | Dessen exakte Instanz |

Der Export oder ein Schemaoverride darf keinen Codepfad oder Prüfkontext
bestimmen. Der Labreader prüft dieselben erfassten UTF-8-Bytes gegen das
kanonische V2-Schema, Signatur, Frist, Ziel, Zertifikat, Runtime, Registry,
Benutzer, Client und Trust. Toolbelt verwendet den daraus gelieferten Eintrag,
keine nachfolgende Dateilesung. V2 wird auch für `Functional` geprüft;
`AuthenticatedTls` verlangt V2 und False. Weder `GITHUB_ACTIONS` noch READY
ersetzen die Prüfung. V1 bleibt für unabhängige Functional-Tests erhalten.

### Eigenständige Runner mit AST-Import

Einige Modul-, Release-, CI- und Research-Runner übernehmen ausgewählte
Funktionsdefinitionen aus `Tests/CI/run-lab-local.ps1`, ohne dessen Top-Level-Code
auszuführen. Vor diesem AST-Import laden sie den gemeinsamen
[`LabQualifiedContract.ps1`](../../Tests/CI/LabQualifiedContract.ps1)-Helper
aus dem eigenen Repository. Dazu gehören auch die begrenzte Byte-Lesefunktion
und die V2-Prüfungen, die der Resolver transitiv benötigt. Es entsteht weder
ein zweiter Resolver noch ein aus dem Export abgeleiteter Codepfad.

Ein solcher Import erweitert die Capability des aufrufenden Runners nicht.
Ein Functional-Aufruf ohne expliziten V2-Kontext darf keinen V2-Export als
unqualifizierten Vertrag lesen. Windows-/Versions-, Signatur-, Frische- und
Zielbindungen bleiben unverändert; ein Linux-Clienthost bleibt für die
qualifizierte Lane gesperrt.

Der Table-Clone-Runner bindet seinen Resolver zusätzlich an den bereits
geschlossenen Inputkatalog. JSON-Bytes und Schema stammen aus diesen
Snapshots. Der begrenzte Snapshotzugriff liefert eine eigene Kopie der zuvor
erfassten Bytes und weist leere oder mehr als vier MiB große Eingaben ab.
UTF-8-, Schema- und V2-Prüfungen im gemeinsamen Resolver bleiben erhalten;
seine Datei-/ACL-Prüfung verlangt weiterhin einen echten FileStream.
Der private Seam wird vor Verwendung auf
die erwartete Resolverform geprüft und bricht bei Drift ab.

## Clientaufruf und Lebensdauer

Der Parent schreibt genau diesen Snapshot in eine neue private temporäre
Kontextdatei mit expliziten CurrentUser-/SYSTEM-ACLs und hält sie lesend ohne
Write-/Deletefreigabe. Kindprozesse prüfen deren erwarteten Bytehash. Sie lesen
den ursprünglichen Exportpfad nicht erneut. Die Kontextdatei enthält Secrets;
keine Ausgabe, Versionierung oder Übertragung.

Vor der SqlClient-Anmeldung, jeder sqlcmd-Verbindung im Adapter und jeder
SqlClient-Metadatenverbindung werden dieselben Bytes erneut im tatsächlichen
Clientkontext geprüft. Endpoint, Benutzer, Credential, Zielkey und ausgewählter
sqlcmd-Binaryhash müssen passen. Der Preflight prüft den exakten qualifizierten
SQL-Build und `encrypt_option=TRUE`. Qualifizierte SqlClient-Verbindungen
verwenden kein Pooling und keinen Connect-Retry; sqlcmd erhält `-N` ohne `-C`.

Die signierte Frist wird nicht verlängert. Vor einem neuen Login verlangt der
Consumer noch mindestens 30 Sekunden für den 15-Sekunden-Verbindungsaufbau.
Eine lange Ausführung kann deshalb fail-closed enden. Auch Cleanup darf nicht
mit abgelaufener Qualifikation oder Trust-Override fortgesetzt werden;
unklarer SQL-Cleanup bleibt Recoverybedarf. Nur eindeutig eigene temporäre
Kontextdateien werden nach beendetem Adapter entfernt. Prozessvariablen werden
wiederhergestellt; Toolbelt erstellt, repariert oder entfernt keine Labressourcen.

Der prüfende Snapshot reserviert weder Runtime noch Truststore. Die aktuelle
Prüfung gilt zum jeweiligen Beobachtungszeitpunkt; ein späterer Drift darf
nicht als erfolgreich qualifizierte Nutzung ausgegeben werden.

```powershell
& $toolbeltRunner -Versions 2025 -Platforms linux -LinuxPatches cu9 `
    -TestPurpose AuthenticatedTls -RunScripts run-authenticated-tls-lab.sh `
    -LabModuleFile $labModuleFile -LabTlsStateRoot $lab.StateRoot `
    -LabTlsRunId $lab.RunId -LabTlsInstanceId primary -StopOnFailure
```

`run-authenticated-tls-lab.sh` nutzt den tatsächlichen Toolbelt-Labadapter
für einen zusätzlichen Build-/Verschlüsselungsnachweis. Es erstellt keine
SQL-Objekte. Der erforderliche eigene Labexport wird durch Lab bereitgestellt.

## Verarbeitungsaufwand und Nachweise

Der bestehende Selektionsvalidator führt die neue synthetische Consumerfixture
zusätzlich zu seinen bisherigen Prüfungen aus. Der Modulstub darin ist kein
Kryptobeweis; echte RSA-/Schema-/Frischefälle gehören zum Labreader, echte
Verbindungen zur getrennten gemeinsamen Providerabnahme. Bestehende
Modulqualifikationen und große Runtime-Matrizen werden nicht pauschal wiederholt.

Die erneute native Bindungsprüfung vor qualifizierten Verbindungen verursacht
bewusst Aufwand und erhält die Driftgrenze. Sie läuft ausschließlich im
gewählten V2-/AuthenticatedTls-Pfad, ohne Hintergrundpolling oder neuen Dienst.
V1-Functional-Tests benötigen keine neue CA, keinen neuen Trust und keinen
Labimport. Ein gemeinsamer unabhängiger Reviewer prüft die gekoppelte
Sicherheitsfrage; keine Review-von-Review-Kette. Kosten und Tokens sind unbekannt.

Die [zusätzliche Definitionsprüfung](../../Tests/CI/test-cold-lab-consumer-contract.ps1)
läuft über dieselbe Consumerfixture in genau einem frischen PowerShell-Prozess.
Sie prüfte im Ausgangsstand 38 Helperimportstellen statisch und führt neun
tatsächliche begrenzte Importfamilien mit ihren jeweiligen Auswahllisten aus.
Ein über Main integrierter Geo-Consumer besitzt den gemeinsamen Import bereits;
die erneute Quellinventur zählt deshalb 39 Stellen bei unveränderten neun
Importfamilien. Dazu gehören Zwei-,
Vier-, Fünf-, Sechs- und Siebener-Auswahlen, der Release-Importer, sammelnde
Imports und die geschlossene Snapshot-Variante. Mutierende Treiber-Top-Levels
werden nicht ausgeführt. Synthetische V1-Verträge werden im jeweiligen
Definitionsscope gelesen. V1 im
AuthenticatedTls-Modus, unbekannte Versionen sowie V2 ohne Caller-Kontext
müssen scheitern. Die lokale Prüfung vom 2026-10-25 bestand mit 40 Fällen,
einschließlich unveränderter Snapshotbytes trotz Dateiaustausch, eigener
Bytekopie sowie leerer und übergroßer Inputs. Die bisherigen 15 synthetischen V2-Fälle bestanden separat
im selben Fixtureaufruf. Das sind keine SQL-, Kryptografie- oder Linux-TLS-Nachweise.
Der gesamte lokale Fixtureaufruf dauerte 5,4 Sekunden.

Die CI-Auswahl berücksichtigt dafür die PowerShell-Consumer unter Tests/CI,
Tests/Release, Tests/Research, den Modul-Testverzeichnissen und dem
XlsxMemory-Spike. Diese begrenzte Erweiterung erhält den Test auch dann,
wenn nur ein aufrufender Runner geändert wird. Sie startet keine zusätzlichen
SQL-/Provider-Matrizen und ergänzt keine Review- oder Modellaufrufkette.

Die historischen Execution-Context- und ResultTable-/Error-Envelope-Rechtebelege
bleiben an ihre ursprünglichen CSV-Runnerbytes gebunden. Der Releaseaudit prüft
diese Quellen aus dem hashgeprüften Recoverypaket. Für die aktuelle CSV-Quelle
ist ausschließlich der zusätzliche feste Readerimport an seiner festgelegten
Stelle zulässig; nach dessen Entfernung müssen sämtliche ursprünglichen Bytes
übereinstimmen. Der Reader selbst bleibt exakt an seine ursprünglichen Bytes
gebunden. Abweichender Import, weitere Quelländerungen oder Readerdrift werden
abgewiesen. Diese begrenzte Anwendbarkeitsprüfung ist keine erneute native
Rightsabnahme und ändert weder historische Ergebnisdateien noch Paketbytes.

Die später integrierte Geo-Qualifikation bindet ebenfalls die ursprünglichen
Geo- und Translate-Runner. Auch dort ist ausschließlich derselbe feste Import
an derselben Position zulässig; der jeweilige ursprüngliche SHA-256 muss nach Entfernung
der drei Zeilen exakt übereinstimmen. Die drei zulässigen Pfade und ihre
unterschiedlichen Originalhashes sind geschlossen festgelegt. Andere Pfade,
Importe, übrige Quelländerungen, vertauschte Pins oder Readerdrift bleiben
gesperrt; Geo-Beleg und kanonische SQL-Fixtures werden nicht verändert.

Die betroffene CI-Auswahl bindet sämtliche Consumer-Helfer an den bestehenden
Validator. Ein zusätzlicher begrenzter Windows-Job führt ausschließlich die
private Consumerfixture mit PowerShell 7.5 oder neuer aus: Ubuntu kann deren
Windows-ACL-Fälle nicht ausführen. Dieser notwendige Plattformnachweis ersetzt
keine SQL-/Providerabnahme und erzeugt keine Labs. AuthenticatedTls oder auch
nur ein Teil des Qualified-Kontexts sperrt vor jedem Runner-Kurzpfad; normale
Functional-Runner ohne Kontext behalten ihren bisherigen Weg.

## Begrenzter funktionaler V1-Preflight vom 2026-10-25

Die [Lab-Consumerinventur](https://github.com/gecompat/SQL_Server_Lab/blob/main/Documentation/Project_Planning/TLS_001_CONSUMER_INVENTORY.md#begrenzter-echter-v1-preflight-vom-2026-10-25)
führt den gekoppelten Nachweis und dessen Grenzen. Zehn begrenzte Importfamilien
lasen den echten öffentlichen V1-Export eines eigenen kompakten
Docker-/SQL-2025-CU9-Labs. Der CSV-Consumer bestand den kanonischen
`System.Data.SqlClient`-Functional-Preflight und einen getrennten ODBC-18-Fall;
beide lieferten Build `17.0.5005.3`. .NET erzwingt `Encrypt=True`, erhebt im
Functional-Zweig aber keinen zusätzlichen DMV-Sitzungswert. ODBC prüfte
zusätzlich `encrypt_option=TRUE`. Der Modus True/True prüft keine
Serveridentität.

Workerresultate, ganze Jobleere vor Remove, beide abgeschlossenen
Cleanupschritte und frische eigene Container-/Volume-/Exportabwesenheit
sind belegt und unabhängig ohne offene Findings geprüft. Der übergeordnete
Kontrolllauf bleibt wegen beobachteter paralleler fremder Git-/Runtimeänderungen
**FAIL**. Seine nicht abgeholten Parentzahlen und `Preserved=false` bleiben
unverändert; tatsächliche zehn Reader- und zwei Clientresultate werden getrennt
ausgewiesen. Eine globale Bestandsgleichheit wird nicht behauptet. Die zwei
vorherigen Kontroll-FAILs vor Labanlage bleiben erhalten. Originalexporte sind
bereinigt, ihre Bytehashes erhalten; eine Kopie der ursprünglichen Exportbytes
wird nicht behauptet.

Das ist ein funktionaler Windows-Consumerbeleg, keine Wiederholung oder
Erweiterung der folgenden V2-/Zertifikatsmatrix und kein Lauf sämtlicher
Modulruntimes. Aktuelle CI und Integrationsheads gehören zu den jeweiligen PRs.

## Gemeinsame native Windows-Abnahme vom 2026-10-22

Die [kanonische Lab-Evidence](https://github.com/gecompat/SQL_Server_Lab/blob/main/Documentation/Quality/TLS_V2_CONSUMER_CUTOVER_ACCEPTANCE_2026-10-22.md)
führt Quellen, ursprüngliche Fehler, getrennte Fälle und Grenzen.

| Provider | SQL-Profil | Tatsächlicher Build | Lab-/Consumerfälle | Cleanup |
|---|---|---|---|---|
| Docker | 2019 CU32 | `15.0.4430.1` | 5 / 3 PASS | PASS |
| Podman | 2019 CU32 | `15.0.4430.1` | 5 / 3 PASS | PASS |
| Docker | 2022 CU27 | `16.0.4295.3` | 5 / 3 PASS | PASS |
| Podman | 2022 CU27 | `16.0.4295.3` | 5 / 3 PASS | PASS |
| Docker | 2025 CU9 | `17.0.5005.3` | 5 / 3 PASS | PASS |
| Podman | 2025 CU9 | `17.0.5005.3` | 5 / 3 PASS | PASS |

Jede Provider-/SQL-Matrixzeile umfasste den öffentlichen Reader und die
positive Transportprüfung über tatsächlichen Toolbelt-Preflight und beide
echten Clientstacks mit geprüftem Build und verschlüsseltem Transport.
Eine gefälschte Signatur wurde vor SQL-Preflight
abgewiesen. Diese Ablehnung ist von Zertifikatsnegativfällen getrennt.
Die vorherigen Windows-Kryptoproben bleiben eigene historische Nachweise.

Zwei frühere Docker-/SQL-2019-Ausführungen bleiben FAIL: Boolean-Kompatibilität
des privaten Labprüfers und erneute Docker-PATH-Auflösung auf den absichtlichen
Toolbelt-Shim. Beide wurden reproduziert und korrigiert; die sechs PASS-Zeilen
stammen aus getrennten korrigierten Ausführungen. Alle acht eigenen Labs sind
entfernt, Container-/Volumeabwesenheit, feste Exporte und Bestandsvergleich
bestanden. Bestehende CA, Trust, Schlüssel und Hyper-V-Ressourcen blieben erhalten.

Die direkte Reader-API liefert private Bytes für den Consumer. Die generische
Lab-CLI-/Browserdarstellung schützt diese Bytes zusätzlich durch Maskierung;
das ist ein eigener synthetisch geprüfter Anzeigevertrag. Die CI-Gates und
exakten Integrationsheads gehören zu den jeweiligen Lab-/Toolbelt-PRs.
Linux-Clientprozesse, öffentliche Hyper-V-Lane und übrige TLS-001-Schritte
bleiben offen; SC-2026-045 ist durch diese Windows-Teilmatrix nicht pauschal
abgeschlossen. Rohdaten und Secrets bleiben lokal außerhalb Git.
