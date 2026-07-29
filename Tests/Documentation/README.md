# Dokumentations- und Konsistenzprüfung

`validate_documentation.py` hält Status, Modulmanifeste, gekoppelte
Dokumentation und Change-Impact-Regeln synchron.

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

`--write` aktualisiert ausschließlich die markierten generierten
Statusabschnitte. Narrative Dokumentation bleibt manuell gepflegt und wird
nicht überschrieben.
