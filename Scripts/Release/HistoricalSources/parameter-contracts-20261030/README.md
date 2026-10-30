# Vorgänger der generierten Parameterverträge

`Predecessors.zip` enthält acht unveränderte Objektseiten aus
`7ef70dd77d2bcd0709908159807f9b97076c4f40` unter `Predecessors/`. Zwei
ursprüngliche XLSX-Zellbeschreibungen aus
`9363cb42eff328590276ad4d4f2289d4f3575262` stehen unter `Native/`; die
Lizenz bleibt unverändert. SHA256 des Archivs:
`2b2e9a703e4af3cc6ff97b77dc2f92e2f7a06b20cb56dec459060654353f37ab`.

[`parameter_documentation_transition.py`](../../parameter_documentation_transition.py)
ergänzt die bereits bestehende
[Dokumentationsprojektion](../documentation-followup-20261030/README.md).
Nur die eindeutig markierte Parametertabelle darf sich ändern. Ihr aktueller
Inhalt muss exakt aus SQL-Signatur und `api_examples.json` generiert sein;
sämtlicher übriger Text muss dem jeweiligen Vorgänger entsprechen. Fremde
Textergänzungen, abweichende Tabellen und unbekannte Pfade bleiben Fehler.

Alte Runtimeberichte, deren ursprüngliche Quellpins und ausführbare Quellen
werden nicht geändert. Die zwei Zellbeschreibungen werden ausschließlich für
ihre ursprünglichen Dokumentationspins aufgelöst. Eine geschlossene
Checkerprojektion entfernt nur diesen Dokument-Leseadapter vor der Prüfung
des alten Methodenpins; zusätzliche Checkeränderungen bleiben erkennbar.
Das ist keine neue native Qualifikation der aktuellen Referenztexte oder
des Leseadapters. Die aktuelle
[Objektreferenz](../../../../Documentation/Reference/README.md) wird durch die
normalen Dokumentationsprüfungen und die CI am aktuellen Head geprüft.
