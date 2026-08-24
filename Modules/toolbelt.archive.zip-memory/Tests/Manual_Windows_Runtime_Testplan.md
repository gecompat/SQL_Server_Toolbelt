# Manueller Windows-Runtime-Testplan

Status: ausstehend. Dieser Testplan ergänzt die erfolgreiche Linux-Matrix um den erforderlichen Windows-SQL-Server-Runtime-Nachweis. Ein erfolgreicher .NET-Framework-Build allein ist keine Runtime-Evidenz.

Bestehende Linux-Evidenz für Version `1.2.0`: [SQL-Server-2019-/2022-/2025-Matrix](https://github.com/gecompat/SQL_Server_Toolbelt/actions/runs/32701896453). Diese Evidenz ersetzt keinen Windows-SQL-Server-Runtime-Lauf.

## Sicherheitsrahmen

- Ausschließlich eine dedizierte synthetische Testdatenbank verwenden.
- Nur die im Repository erzeugten synthetischen ZIP-Testvektoren ausführen.
- Keine realen Archive, Dateipfade, Benutzer-, Host-, Kunden- oder Unternehmensdaten verwenden oder in das Repository übernehmen.
- `TRUSTWORTHY ON`, deaktiviertes `clr strict security`, `UNSAFE`, `EXTERNAL_ACCESS` und `xp_cmdshell` sind für dieses Modul unzulässig.
- Der serverweite Trust-Eintrag wird nur für den exakten SHA2-512-Hash des gebauten Testbinaries gesetzt und getrennt administrativ verwaltet.

## Vorbedingungen

1. Windows SQL Server 2019, 2022 oder 2025 mit aktiviertem SQL CLR bereitstellen. Instanzoptionen werden nicht durch das Modul geändert.
2. Das Modul `toolbelt.core.result-table` in derselben Testdatenbank installieren.
3. Mit `Scripts/New-ClrReleaseArtifacts.ps1` aus dem konkreten Commit DLL, Trust-Manifest und binäres Deployment-SQL erzeugen.
4. Den exakten Hash administrativ über `Deployment/Add-TrustedAssembly.sql` freigeben.
5. `Deployment/Deploy.sql` in der dedizierten Testdatenbank ausführen.

## Testreihen

| ID | Test | Erwartung |
|---|---|---|
| DEP-01 | Build, Trust-Opt-in und lokales Deployment | `SAFE`-Assembly und interne CLR-TVF werden erfolgreich angelegt; keine unzulässige Instanzänderung. |
| ZIP-01 | `ZipMemory.Contract.sql` | Stored und Deflate, Data Descriptor, CRC32, Größen-/Ratio-/Featurefehler sowie Duplicate-/Encrypted-Semantik erfolgreich. |
| META-01 | `Metadata.Contract.sql` | Geordnetes Listing, Metadatenstatus, UTF-8/CP437, Duplicate-, Directory-, Pfad-, Zeit-, Limit- und Strukturverträge erfolgreich. |
| ENC-01 | `Encoding.Contract.sql` | UTF-8- und CP437-Entry-Namen werden gemäß ZIP-Flag und Vertrag ausgewertet. |
| RESULT-01 | Direkte Ausgabe und `@ResultTable`/`@KeepData` | Ergebnisvertrag und ResultTable-Integration erfolgreich. |
| LIFE-01 | `Lifecycle.Contract.sql` sowie wiederholtes Deployment | Wiederholung ist kontrolliert; Version, Marker und Objektbestand bleiben konsistent. |
| CENTRAL-01 | Zentrales Deployment und `Central.Contract.sql` | Aufruf aus einer getrennten Consumer-Testdatenbank funktioniert gemäß dokumentiertem Scope. |
| UNINSTALL-01 | `Deployment/Uninstall.sql` | Datenbankobjekte werden vollständig entfernt; der serverweite Trust-Eintrag wird bewusst nicht automatisch gelöscht. |
| LIMIT-01 | Größere, ausschließlich synthetische Stored- und Deflate-Payloads innerhalb und knapp oberhalb der freigegebenen Limits | Innerhalb der Limits korrekt; oberhalb kontrollierte Ablehnung ohne Teilresultat oder unkontrollierten Ressourcenverbrauch. |

## Versionsumfang

- Mindestens ein vollständiger Windows-Runtime-Lauf auf der vorgesehenen primären Zielversion.
- Vor Produktfreigabe gezielte Wiederholung auf SQL Server 2019, 2022 und 2025, sofern alle drei physischen Versionen unterstützt werden sollen.
- Compatibility Levels prüfen Parser-/Planungsgrenzen, ersetzen aber weder die physische Engine- noch die Windows-Runtime-Evidenz.

## Abstrahierte Rückmeldung

Nur folgende Felder übermitteln:

| Test-ID | SQL Server-Version | Compatibility Level | Ergebnis | Fehlernummer/Kategorie | Abstrahierte Bemerkung |
|---|---|---:|---|---|---|
| z. B. ZIP-01 | 2022 | 160 | pass | – | Stored, Deflate und CRC32 erfolgreich |

Keine realen Datenbanknamen, Hashwerte, Pfade, Konten, Hostnamen, Archive, Dateiinhalte, Screenshots oder vollständigen Rohlogs übermitteln. Bei einem Fehler genügen Test-ID, SQL-Fehlernummer, gekürzte Kategorie und die Information, ob Assembly-, Trust-, Datenbank- oder Uninstall-Zustand unerwartet verändert wurde.
