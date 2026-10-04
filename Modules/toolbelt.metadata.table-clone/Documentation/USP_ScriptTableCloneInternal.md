# Interner kanonischer Scriptkern

`USP_ScriptTableCloneInternal` besitzt denselben Parameter-/Resultvertrag wie
[öffentliche Fassade](USP_ScriptTableClone.md). Kein zusätzlicher öffentlicher
Aufrufvertrag und keine zweite Fachimplementierung. Help delegiert an die reine
Help-Fassade. Öffentliche Fassade prüft Caller-Tempnamespace vor Core-Kompilierung;
Caller erhalten keine gesonderten EXECUTE-Grants auf den Kern.
Catalog Views lesen keine Nutzdaten; dynamisches SQL ausschließlich für
versionsabhängige Ledger-Metadaten, kontrollierten caller-lokalen Map-Snapshot und kanonisches ResultTable-Routing,
nicht für Ausführung des erzeugten Scripttexts.

W2 verwendet denselben W1-Renderer nach vollständiger Mapprüfung, keine duplizierte Tabellen-/Propertyimplementierung. Globale FK-Ausgabe erfolgt nach EPs; siehe [V3-Vertrag](../../../Documentation/Architecture/TABLE_CLONE_WAVE2_CONTRACT.md).
