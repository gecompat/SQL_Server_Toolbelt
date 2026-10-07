# Tests für toolbelt.file.content

## Übersicht

| Test | Zweck | Ort |
|---|---|---|
| Statische Vertragsprüfung | Artefakte, Vertragsmarker und Signatur | `Tests/Static/validate_contract.py` |
| Lifecycle-Contract | Objekte existieren im Ziel-Compatibility-Level | `Tests/Runtime/Lifecycle.Contract.sql` |
| Befüllter Repeat | Zwei echte versionsgleiche Deploys; exakte Zeilen, Identity und Katalog | [RepeatCurrent.Contract.sql](Runtime/RepeatCurrent.Contract.sql) mit gemeinsamem [Snapshot](Runtime/RepeatCurrent.Capture.sql) und [Orakel](Runtime/RepeatCurrent.Assert.sql) |
| File-Content-Contract | Hilfe-Contract, Pfadvalidierung, Allowlist, Traversal | `Tests/Runtime/FileContent.Contract.sql` |
| Root-Grenzvertrag | Literale Verzeichnisgrenzen, Unicode, Leerzeichen und beide Fassaden | [RootBoundary.Contract.sql](Runtime/RootBoundary.Contract.sql), vom File-Content-Contract eingebunden |

## Ausführung

Lokales Deployment:

```bash
cd Modules/toolbelt.file.content/Deployment
sqlcmd -S localhost -d ToolbeltFileContentTest -i Deploy.sql \
  -v DeploymentMode=local
```

Statische Prüfung:

```bash
python3 Modules/toolbelt.file.content/Tests/Static/validate_contract.py
```

Runtime-Test für ein Compatibility Level:

```bash
cd Modules/toolbelt.file.content/Tests/Runtime
sqlcmd -S localhost -d ToolbeltFileContentTest -i FileContent.Contract.sql \
  -v CompatibilityLevel=170 FixtureRoot=/synthetic/file-content-fixtures
```

## Hinweise

- Der befüllte Repeat läuft ausschließlich auf einer eigenen leeren,
  installierten Test-Allowlist. Aus `Modules/toolbelt.file.content/Deployment`
  mit `sqlcmd -i ../Tests/Runtime/RepeatCurrent.Contract.sql -v DeploymentMode=local`
  beziehungsweise `central` aufrufen. Die Session hält ihre Snapshots über
  beide echten Deploys. Kein Datei-I/O, CLR, Konfigurationsänderung oder Grant.
- Vier synthetische Zeilen enthalten aktive/inaktive Roots, NULL/leere und
  Unicode-/Trailing-Space-Texte sowie feste Auditzeiten. Eine zusätzlich
  gelöschte höchste Identity und der nächste reguläre Insert prüfen den
  Zähler unabhängig von `MAX(RootPathId)`. Die Daten werden bytegenau verglichen.
- Der Katalogsnapshot vergleicht Objekt-/Schemaidentität, Spalten, Identity,
  Indizes samt Schlüsselspalten, Constraints, Trigger, vorhandene
  Berechtigungsmetadaten und Extended Properties. Die Tabellenbeschreibung
  wird absichtlich veraltet; ausschließlich diese `MS_Description` muss der
  Deploy kanonisch erneuern. Eigene zusätzliche Tabellen-/Spaltenannotation
  muss erhalten bleiben. Es werden keine nichtleeren Benutzergrants erzeugt;
  deren Erhalt und echte Minimalrechte bleiben offen.
- Der bestehende Linuxadapter führt den Repeat vor der I/O-Konfiguration in
  lokalem und zentralem Modus auf dem jeweiligen nativen Default-CL aus:
  2019/150, 2022/160, 2025/170. Die anschließende bestehende Datei-Suite
  qualifiziert davon getrennt ihre bisherige CL-Matrix. Fehler enden über
  SQLCMD; die eigene disposable CI-Umgebung wird im vorhandenen EXIT-Trap
  entfernt. Ein Hard-Interrupt-Cleanup wird daraus nicht abgeleitet.

- Nur eine vorbereitete eigene Testdatenbank verwenden. Die Grenzmatrix
  verwendet eine vorhandene Allowlist-Zeile ohne Identity-Insert und
  restauriert Allowlist-Zeilen per Rollback.
- Der File-Content-Contract enthält kleine Datei-Fixtures und erfordert eine
  vorbereitete Allowlist sowie serverseitige Dateien unter `FixtureRoot`.
  Der eingebundene Root-Grenzvertrag prüft das gemeinsame Prädikat und beide
  Fassaden mit synthetischen Pfaden; Denial-Fälle dürfen keinen Providerfehler
  als erfolgreiche Ablehnung ausgeben. Allowlist-Änderungen werden zurückgerollt.
- SQLCMD-Includes werden relativ zum angegebenen Arbeitsverzeichnis aufgelöst.
  Die beiden Beispiele beginnen jeweils am Repository-Root.
- `OPENROWSET(BULK...)` erfordert `ad hoc distributed queries` oder
  `ADMINISTER BULK OPERATIONS`.

Evidenz: https://github.com/gecompat/SQL_Server_Toolbelt/actions/runs/30692267356

Die binären Runtime-Fixtures werden durch `Tests/CI/run-file-content-linux.sh` deterministisch und bytegenau unter `.runtime/file-content-fixtures` erzeugt. Sie werden nicht in Git gespeichert.

## Aktuelle Validierungsevidenz

<!-- BEGIN GENERATED:MODULE_EVIDENCE -->
- Datum: `2026-09-01`
- Nachweis: `https://github.com/gecompat/SQL_Server_Toolbelt/actions/workflows/file-content-runtime.yml`
- Scope: GitHub-hosted Linux-Matrix SQL Server 2019, 2022 und 2025; erstmals auf allen drei Zielversionen erfolgreich, nachdem der Testadapter die Compatibility Levels aus der Zielversion ableitet
- Ergebnis: `success`
<!-- END GENERATED:MODULE_EVIDENCE -->
