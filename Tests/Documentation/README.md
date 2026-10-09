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

Das Impact-Paket `foundation_host_redirects` führt
`python3 -B Tests/Documentation/test_foundation_redirects.py` mit begrenzter
Laufzeit aus. Die Regression ersetzt HTTP-Transport durch synthetische
Antworten und prüft Vor-Dispatch-Originbindung, erlaubte Redirectketten,
Fehlercodes und installierte Provenienz. Sie aktiviert keine optionalen
Runtimes, Netzwerkverbindungen, Provisionierung oder SQL-Tests.

Das Impact-Paket `foundation_http_responses` führt
`python3 -B Tests/Documentation/test_foundation_http_response.py` ebenfalls
mit begrenzter Laufzeit aus. Es prüft die tatsächlichen HttpAdapter-Pfade
mit skalierten synthetischen Bytegrenzen und in-memory Antworten, einschließlich
kurzer Reads und unvollständiger Content-Length-Übertragung. Es ist keine
16MiB-Maximalworkload-, Heap-, Endpoint- oder Runtimequalifikation.

Das Impact-Paket `foundation_discovery` führt
`python3 -B Tests/Documentation/test_foundation_discovery.py` mit10s-Budget aus.
Es prüft den getrennten Versionsprobe und seine Discovery-Caller mit skalierten
Bodygrenzen und echtem urllib-Dispatch über synthetischen HTTP-Transport:
Redirects bleiben ungefolgt, nicht autorisierte Kandidaten unkontaktiert und
Transportfehler isolierte Vorschläge. Es startet keine CLI oder Runtime.
Die Originregression ergänzt credential-freies HTTP(S), syntaktische
Ablehnungen ohne Inputecho, sichere Defaultisolation und kontaktfreies
`probe=False`. Kleine synthetische Fixtures ersetzen keine realen Endpoint-,
DNS-/Proxy-/Hostvertrauens- oder SQL-Nachweise.

## Vollständiger Audit

Das Impact-Paket `foundation_processing` führt
`python3 -B Tests/Documentation/test_foundation_processing.py` mit10s-Budget aus.
Fünf Offline-Szenarien verwenden Kopien der aktuellen Projektregeln: die zweite
unveränderte Welle liest keine Regel erneut, eine geänderte Arbeitsregel invalidiert
die abhängige Kostenanalyse, eine neue Instruktion invalidiert alle Analysen,
fehlende Analyse wird nicht aus einem Fingerprint erfunden und unvollständige
Discovery erlaubt keine Wiederverwendung. Synthetische Discoverydaten attestieren
keine reale Clientkonfiguration oder einen tatsächlichen Session-CACHE_HIT.
Weder Netzwerk noch SQL wird verwendet.

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

## Veröffentlichungsnachweise

Der kanonische [JSON-Vertrag](../../Documentation/Architecture/MODULE_AND_DEPENDENCY_MODEL.md#öffentlicher-veröffentlichungsnachweis)
verbindet veröffentlichte Modulversionen mit Quellcommit, Supportscope,
Qualifikationsfundstellen, Freigabe, Release und Asset-Hashes.
`validate_documentation.py` prüft diese Struktur immer lokal und meldet externe
Bestätigung separat. Der ausdrücklich gewählte Zusatzmodus verwendet nur
GitHub-GET über den vorhandenen `gh`-Client:

```text
python -B Tests/Documentation/test_publication.py
python Tests/Documentation/validate_documentation.py --all --verify-publications
```

`publication_contract` ist in der Repo-Map an Manifest-/Publication-, Vertrags-,
Validator- und Rückmeldeformularänderungen gekoppelt. Die Regressionen verwenden
ein temporäres synthetisches Git-Repository und simulierte API-Antworten.
Sie erzeugen keine Release-Tags und greifen weder auf Netzwerk noch SQL zu.
Sie prüfen gültige Source-/Binary-/Preview-Zuordnungen sowie fehlende Nachweise,
Commit-/Versions-/Scopefehler, ungültige Referenzen, Drafts, Tagdrift, Assetdrift
und isolierte Transport-/Digest-Unverfügbarkeit. Das ist ein Validatornachweis,
keine tatsächliche Veröffentlichung oder SQL-Qualifikation.

Bei `unreleased` fehlen Veröffentlichungsdatensätze; auch der Zusatzmodus
meldet dann `not applicable` und stellt keine GitHub-Anfragen. Ohne Zusatzmodus
bleibt vorhandene externe Evidenz `not executed`. Ein fehlender lokaler
Quellcommit, etwa in einem flachen Checkout, ist keine Bestätigung: zuerst den
öffentlichen exakten Commit über den normalen autorisierten Git-Prozess
bereitstellen und erneut prüfen. Der Validator fetch't nicht selbst.

## Prüfevidenz 2026-10-07: Veröffentlichungsvertrag

- `python -B Tests/Documentation/test_publication.py`: 19 synthetische
  Regressionstests erfolgreich, einschließlich gleicher Modulversion mit
  veränderten/neuen Runtimeinputs, Provider-/Plattformbindung und Fehlerpfaden.
- `python -B Tests/Documentation/validate_documentation.py --all --verify-publications`:
  vollständiger lokaler Dokumentations-/Konsistenz-/Static-Audit erfolgreich;
  alle 44 unveröffentlichten Module benötigen keinen Veröffentlichungsdatensatz.
  Externe Abnahme `not applicable`; keine GitHub-Veröffentlichung bestätigt.
- Scope: Python-Standardbibliothek, temporäres synthetisches Git-Repository,
  vorhandene Governance-/Static-Verträge. Kein SQL-Server-, Plattform- oder
  Produkt-Runtime-Nachweis; API-Antworten ausschließlich synthetisch. Es wurden
  keine Veröffentlichungen, Release-Tags oder Modulstatusänderungen erzeugt.

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
