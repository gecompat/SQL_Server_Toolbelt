# CSV-Callerrechte im Manifest und in den Lieferpaketen

Diese Pflege übernimmt ausschließlich die bereits in
[PR #450](https://github.com/gecompat/SQL_Server_Toolbelt/pull/450)
[nativ belegten CSV-Objektrechte](CSV-CALLER-PROFILE.md) in das Modulmanifest
und dessen Paketquellen. Die Installation vergibt keine Rechte automatisch.
Alle Module bleiben `unreleased`; Veröffentlichung, Tags und GitHub-Release
sind weiterhin nicht freigegeben.

## Vorhandene Rechte auswählen

| Aufruf | Direkte Ausgabe | Zusätzlich bei ResultTable |
|---|---|---|
| `toolbelt_file.USP_ParseCsv` | EXECUTE auf diese USP und SELECT auf `toolbelt_file.TVF_InternalParseCsv` | EXECUTE auf `toolbelt_core.USP_PrepareResultTable` |
| `toolbelt_file.USP_WriteCsv` | EXECUTE auf diese USP und beide internen Skalare `SVF_InternalMeasureCsvCell`/`SVF_InternalQuoteCsvCell` im selben Schema | EXECUTE auf `toolbelt_core.USP_PrepareResultTable` |

Die bestehenden Lifecycle-/Release-Marker-/Trustvoraussetzungen stehen weiterhin
unverändert im [Manifest](../../Modules/toolbelt.file.csv-memory/module.yaml).
Diese dokumentierenden Aufrufprofile gelten für den geprüften Ownershipstand;
andere Owner, alternative Sichtbarkeitsrechte und Help-Profile werden nicht
zusätzlich qualifiziert. Interne CLR-Objekte werden dadurch keine öffentlichen APIs.

## Paketbindung ohne neue Runtimebehauptung

Der ursprüngliche [CSV-Ausführungsbericht](csv-caller-profile.json) bleibt
bytegenau erhalten, einschließlich seines damaligen Manifestpins und offenen
Metadatenpunkts. [csv-metadata-update.json](csv-metadata-update.json) bindet
diesen historischen Pin getrennt an das exakt korrigierte Manifest. Die sechs
früheren [Caller-Metadatenkorrekturen](CALLER-METADATA-UPDATE.md) und die
frühere SSIS-Lieferqualifikation bleiben eigene unveränderte Nachweise.

Der [begrenzte Prüfer](../../Scripts/Release/csv_metadata.py) erlaubt genau das
CSV-Rechtefeld und vier konkrete Lesepfadkorrekturen. Andere bereits öffentliche
Markdownpflege wird nur gegen den gebundenen Integrationsstand übernommen.
SQL, C#, Dependencies, Status, Deployment, Worker und sämtliche SSIS-Quellen
dürfen in diesem Produktdelta nicht geändert werden. Die neue Produktbindung
setzt die bisherigen Nachweisketten fort; sie datiert keinen alten Test um.

Im CLR-Paket werden genau fünf CSV-Source-Einträge aktualisiert: Manifest,
Modul-README, beide API-Seiten und Testanleitung. Ein additiver
`METADATA-UPDATE.json` und die Dateiliste im `CLR-PACKAGE.json` erklären den
neuen Metadatenstand. Alle 13 DLLs, 20 SQL-Dateien, Profile, native
`QUALIFICATION.json`, Installer, Lizenz und Drittanbietertexte bleiben bytegleich.
Es gibt keinen neuen lokalen Build oder nativen SQL-Lauf. Die neue
`metadata_update_evidence` ist ausdrücklich von der historischen
Runtimequalifikation getrennt.

Der Quellpaket-Kandidat erhält eine neue, mit synthetischen Commitmetadaten
gesicherte Produkt-/Recoverybindung. Die Stable-SQL-Payloads und das gesamte
Stable-Unterpaket bleiben unverändert. Die bisherigen nativen Paketprüfungen
werden ausschließlich für exakt erhaltene ausführbare Bytes weiterverwendet.
Die aktuellen Head-/Main-Prüfungen sind im zugehörigen PR separat nachzuweisen.

## Prüfung und verbleibende Grenzen

```powershell
python -B Tests/Release/test_csv_metadata.py
python -B Scripts/Release/prepare_clr_package.py --verify Releases/1.0.0/InstallPackages/SQL-Server-Toolbelt-1.0.0-CLR-Install.zip
python -B Scripts/Release/prepare_release.py --verify Releases/1.0.0/Artifacts/SQL-Server-Toolbelt-1.0.0-candidate-source.zip
```

Die sechs neuen Offlineprüfungen ergänzen die bestehende Release-Suite.
Negativkontrollen weisen unbekannte Manifestfelder, Runtime-/SSIS-/Payload-
Änderungen, falsche Quellenpins und fehlende Metadatenprovenienz ab. Die
Recoverykontrolle prüft den gebundenen Baum auch bei fehlendem lokalem
Produktcommit und weist Baumdrift zurück. Neue CI-Jobs oder Trigger entstehen
nicht; die bestehende CSV-Build-/Framework-CI wird durch die Manifeständerung
regulär ausgelöst. Ihr Erfolg ersetzt keine native SQL-Abnahme.

Geschlossen wird nur die CSV-Manifest-/Paketlücke. Die vollständigen Modul-,
Client-, Lifecycle-, Ressourcen-, Identity-/CrossDB- und Releasepflichten in
[RELEASE-GATES.md](RELEASE-GATES.md) bleiben getrennt. Die Pflichtqualifikation
aller zugesagten Kombinationen ist weiterhin Voraussetzung einer späteren
Veröffentlichung. Dieser endliche Rahmen umfasst eine PR, vier Stunden ab
Originalstart und keine neuen nativen SQL-Zielversuche.
