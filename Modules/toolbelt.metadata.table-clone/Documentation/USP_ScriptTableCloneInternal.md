# Interner kanonischer Scriptkern

`USP_ScriptTableCloneInternal` verwendet dieselben fachlichen Vorschauparameter
und vier Resultspalten wie die [öffentliche Fassade](USP_ScriptTableClone.md).
In4.1 besitzt nur der interne Core zusätzlich `InternalPurpose varchar(16)='PREVIEW'`
an Position10; der Standardtail steht intern an11..14. Öffentliche Planner13-
Signatur bleibt unverändert und erzwingt PREVIEW. Kein zusätzlicher öffentlicher
Aufrufvertrag und keine zweite Fachimplementierung. Eigene Help dokumentiert
alle14 internen Parameter und die vier Resultspalten. Die öffentliche Fassade prüft Caller-Tempnamespace vor Core-Kompilierung;
Caller erhalten keine gesonderten EXECUTE-Grants auf den Kern.
Catalog Views lesen keine Nutzdaten; dynamisches SQL ausschließlich für
versionsabhängige Ledger-Metadaten, kontrollierten caller-lokalen Map-Snapshot und kanonisches ResultTable-Routing,
nicht für Ausführung des erzeugten Scripttexts.

COPY_FK wird ausschließlich von der eigenen Copy-USP mit gesunder Transaktion,
Map-/ResultTable-Brücken, REJECT und IncludeTriggers/IncludeExtendedProperties0
verwendet. Es prüft bestehende gemappte Ziele und semantische Target-FK-Tupel,
rendert nur fehlende FOREIGN_KEY-/FOREIGN_KEY_STATE-Zeilen. PREVIEW und COPY_FK
verwenden dieselbe kanonische FK-Herleitung; der Core führt keine Scripts aus.
Die Copy-USP prüft DML-Form, Rechte und Sideeffects getrennt und führt den
geprüften FK-Plan im eigenen Scope aus.
[Datenkopievertrag](../../../Documentation/Architecture/TABLE_CLONE_DATA_COPY_CONTRACT.md).

In4.0 kommen ausschließlich im Windows-Trigger-Opt-in fest gebundene
Abfragen der vier vorhandenen Parser-TVFs hinzu. Diese Abfragen werden
bei Default0 weder kompiliert noch ausgeführt. AST-/Scopebindung und
tokenbasierte Umschreibung sind Teil desselben kanonischen Kerns;
kein experimenteller Resolver oder zusätzlicher Provider.
Siehe [Triggervertrag](../../../Documentation/Architecture/TABLE_CLONE_TRIGGER_CONTRACT.md).

W2 verwendet denselben W1-Renderer nach vollständiger Mapprüfung, keine duplizierte Tabellen-/Propertyimplementierung. Globale FK-Ausgabe erfolgt nach EPs; siehe [V3-Vertrag](../../../Documentation/Architecture/TABLE_CLONE_WAVE2_CONTRACT.md).
