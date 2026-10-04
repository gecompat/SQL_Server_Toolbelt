# Dokumentations- und Konsistenzprüfung

`validate_documentation.py` hält Status, Modulmanifeste, gekoppelte
Dokumentation und Change-Impact-Regeln synchron.

Die Prüfung vergleicht zusätzlich:

- die aktuelle Modulzahl in README, Changelog, Roadmap, Projektkontext,
  Testübersicht und Backlog-Plan mit der Manifest-Registry;
- die Modulverzeichnisse in Root-README und Testmatrix mit allen registrierten
  `module.yaml`-Manifesten;
- die als implementiert geführten Kandidaten mit der
  Implementiert-Tabelle des kandidatenübergreifenden Plans;
- Statusverweise der Research-Inbox mit der kanonischen Kandidatenliste.

## Inkrementelle Prüfung

```bash
python3 Tests/Documentation/validate_documentation.py \
  --base origin/main \
  --head HEAD
```

Die Prüfung liest zuerst nur die geänderten Pfade. Anschließend werden
ausschließlich die in `.ai/repo_map.yaml` registrierten Impact-Pakete und
gekoppelten Modul-Artefakte geprüft.

## Vollständiger Audit

```bash
python3 Tests/Documentation/validate_documentation.py --all
```

Ein vollständiger Audit ist vorgesehen:

- zur erstmaligen Baseline;
- vor einem Release;
- nach Änderungen an Governance, Repo-Map oder Validator;
- auf ausdrücklichen Auftrag.

## Generierte Statusabschnitte

```bash
python3 Tests/Documentation/validate_documentation.py --all --write
```

`--write` aktualisiert die markierten generierten Statusabschnitte und den
öffentlichen API-Katalog. Narrative Dokumentation bleibt manuell gepflegt und wird
nicht überschrieben.

## Öffentlicher API-Katalog

`generate_api_catalog.py` erzeugt Markdown, HTML und SQL-Beispiele aus
Manifesten, Source-Signaturen und einer synthetischen Beispielregistry.
Ohne `--write` prüft es ausschließlich die Synchronität. Quellen, Pflege und
Grenzen stehen in [Documentation/Reference/README.md](../../Documentation/Reference/README.md).

```bash
python3 Tests/Documentation/generate_api_catalog.py --write
python3 Tests/Documentation/generate_api_catalog.py
python3 Tests/Documentation/test_api_catalog.py
```

Das Impact-Paket `public_api_catalog` koppelt Manifest-, Source-, Modul-Doku-,
Registry- und Generatoränderungen an die bestehende Dokumentations-CI.
Die Regressionstests prüfen vollständige öffentliche Inventarisierung,
SQL-Signaturen und Drift-Erkennung mit temporären synthetischen Repositorys;
SQL Server und zusätzliche Python-Pakete werden nicht benötigt.
