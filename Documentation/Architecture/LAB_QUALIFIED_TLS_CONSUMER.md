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

## Discovery und Autorität

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

Die betroffene CI-Auswahl bindet sämtliche Consumer-Helfer an den bestehenden
Validator. Ein zusätzlicher begrenzter Windows-Job führt ausschließlich die
private Consumerfixture mit PowerShell 7.5 oder neuer aus: Ubuntu kann deren
Windows-ACL-Fälle nicht ausführen. Dieser notwendige Plattformnachweis ersetzt
keine SQL-/Providerabnahme und erzeugt keine Labs. AuthenticatedTls oder auch
nur ein Teil des Qualified-Kontexts sperrt vor jedem Runner-Kurzpfad; normale
Functional-Runner ohne Kontext behalten ihren bisherigen Weg.

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
