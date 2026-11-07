# Interner kanonischer Scriptkern

Die [aktuelle genuine V1-Lifecycle-Profilmatrix](../../../Releases/1.0.0/TABLE-CLONE-GENUINE-V1-LIFECYCLE-QUALIFICATION.md)
belegt 240 eindeutige Profile auf 24 lokalen/direkt zentralen Windows-/Linux-
Kontexten: elf vollständige Fälle und ein Fall mit vier gebunden wiederverwendeten
Profilen plus bestandenem Restumfang. Beide ursprünglichen Koordinatoren bleiben
fehlgeschlagen. Alle 26 eigenen DBs entfernt, 14 frische Audits bestanden;
keine Rechte-/Produkt-SQL-/Server-/Labänderung. V1-Upgrade, aktuelles Uninstall,
Repeat und die drei gezielten Rollbackprofile sind damit belegt. Andere genuine
Zwischenversionen und übrige Modulpflichten bleiben getrennt.

Der [vollständige SQLCMD-Caller-Abbruch vom 2026-11-07](../../../Releases/1.0.0/TABLE-CLONE-SQLCMD-CALLER-QUALIFICATION.md)
besteht auf zwölf Windows-/Linux-Engine-/CL-Paaren lokal/direkt zentral:
24 Kontexte, 96 vollständige Deploy-/Uninstall-Profile mit XACT_ABORT OFF/ON.
Einschließlich erhaltenem Erstfehler bestätigen 13 frische Audits die Entfernung
aller 25 angelegten eigenen DBs. Die geänderte Kindprozess-Isolation behebt
nur den Testadapter; Produkt-SQL, Rechte und Serverzustand bleiben unverändert.
Die früher pauschal offenen vollständigen SQLCMD-Caller-Includes sind damit
geschlossen. Linux-Clienthost und genuine Upgrade-/Uninstall-/Recoveryfälle
bleiben separat; ältere datierte Teilnachweise behalten ihren ursprünglichen Scope.

Der [aktuelle Windows-Clientreader](../../../Releases/1.0.0/TABLE-CLONE-WINDOWS-CLIENT-METADATA-QUALIFICATION.md)
prüft die öffentliche Fassade auf 24 Windows-/Linux-SQL-Kontexten. Der interne
Core und seine Produktdefinition bleiben unverändert; die Korrektur betrifft
allein die veraltete Help-Parameterzahl der Clientfixture. Keine zusätzlichen
Grants auf den Kern oder Änderung seines Aufrufvertrags.

Der [aktuelle Trigger-Consumer-Nachweis](../../../Releases/1.0.0/TABLE-CLONE-TRIGGER-CURRENT-QUALIFICATION.md)
qualifiziert den aktuellen Parserpin im vorhandenen Option-1-Gate auf zwölf
Windows-Kontexten. Option 0 erreicht den korrigierten Pin nicht; seine gültigen
Nachweise werden mit geprüfter vollständiger Quellenäquivalenz wiederverwendet.
Der interne Core erhält dadurch keine neue Signatur oder Ausführungsgrenze.

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
