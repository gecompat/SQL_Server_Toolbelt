# Tests für toolbelt.file.content

## Übersicht

| Test | Zweck | Ort |
|---|---|---|
| Statische Vertragsprüfung | Artefakte, Vertragsmarker und Signatur | `Tests/Static/validate_contract.py` |
| Lifecycle-Contract | Objekte existieren im Ziel-Compatibility-Level | `Tests/Runtime/Lifecycle.Contract.sql` |
| File-Content-Contract | Hilfe-Contract, Pfadvalidierung, Allowlist, Traversal | `Tests/Runtime/FileContent.Contract.sql` |

## Ausführung

Lokales Deployment:

```bash
sqlcmd -S localhost -d master -i Modules/toolbelt.file.content/Deployment/Deploy.sql \
  -v DeploymentMode=local
```

Statische Prüfung:

```bash
python3 Modules/toolbelt.file.content/Tests/Static/validate_contract.py
```

Runtime-Test für ein Compatibility Level:

```bash
sqlcmd -S localhost -d master -i Modules/toolbelt.file.content/Tests/Runtime/FileContent.Contract.sql \
  -v CompatibilityLevel=170
```

## Hinweise

- Runtime-Tests, die echte Dateien lesen, erfordern eine vorbereitete
  Allowlist und Dateien im Container-Dateisystem. Sie sind bewusst nicht im
  Contract-Test enthalten, um plattformunabhängige CI-Ausführung zu ermöglichen.
- `OPENROWSET(BULK...)` erfordert `ad hoc distributed queries` oder
  `ADMINISTER BULK OPERATIONS`.

Evidenz: https://github.com/gecompat/SQL_Server_Toolbelt/actions/runs/30692267356

Die binären Runtime-Fixtures werden durch `Tests/CI/run-file-content-linux.sh` deterministisch und bytegenau unter `.runtime/file-content-fixtures` erzeugt. Sie werden nicht in Git gespeichert.
