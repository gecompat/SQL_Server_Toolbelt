# Copy Column V1 im Debug-Datenfluss

Copy Column ergänzt eine bestehende Zeile um eine oder mehrere Kopien vorhandener
Eingabespalten. Die Quellspalten bleiben erhalten. Der Generator projiziert einen
Alias; er konvertiert weder Werte noch Typen und schreibt keine Quelldaten.

Verwende die bestehende Operation `explain` aus dem
[öffentlichen Aufrufablauf](USP_ExplainSsisDataFlow.md). Es gibt keinen neuen
Parameter, keine neue SQL-Prozedur und keinen Opt-in. `procedure-definition`
weist einen Pfad mit Copy Column mit `procedure_profile` ab; die separate
Prozedurerzeugung wurde durch diesen Slice nicht erweitert.

Der aktuelle Quellsatz und die separat qualifizierte DLL stehen im
[unveröffentlichten Installationspaket](../InstallPackages/README.md#aktueller-entwicklungsstand-mit-copy-column-v1).
Dessen Offline-Integrität ist von einer tatsächlichen neuen ZIP-Ausführung
getrennt.

## Voraussetzungen und Ergebnis

Der unterstützte Paketkatalog umfasst die beiden nativen Copy-Column-ClassIDs
des [Einzelfunktionsvertrags](../../../Documentation/Architecture/SSIS_CURRENT_API_CONTRACT.md#additiver-einzelfunktionsvertrag-copy-column-v1--2026-11-13),
Komponentenversion 1, einen synchronen Eingang und einen normalen Ausgang.
Die üblichen Quelltabellen-/Katalogbindungen müssen eindeutig auflösbar sein.

Die synthetische [Integer-Fixture](../Tests/Fixtures/copy-column-8-int.dtsx)
erhält KeyA und Amount und erzeugt KeyACopy und AmountCopy. Ihr Ziel projiziert:

| OriginalKeyA | KeyACopy | OriginalAmount | AmountCopy |
|---:|---:|---:|---:|
| 7 | 7 | NULL | NULL |

Das ist ein erklärtes Beispiel, keine reale Umgebungszeile. Die
[Unicode-Fixture](../Tests/Fixtures/copy-column-8-text.dtsx) verwendet eine
`nvarchar(10)`-Quelle. SQL-NULL, leerer Text, Unicode und der Collationkontext
bleiben beim Kopieren erhalten. Für Paketformat 6 existieren dieselben
[Integer-](../Tests/Fixtures/copy-column-6-int.dtsx) und
[Textfälle](../Tests/Fixtures/copy-column-6-text.dtsx).

`StageIndex` zeigt die unveränderten Quellspalten und danach die Kopien in
Deklarationsreihenfolge. `ColumnLineage` beschreibt die Zielprojektion;
`DebugScript` bündelt die bereits üblichen Plan-/Ergebnis-/Cleanupbatches.
Die Fixture ist ein vollständiges Paket für den bekannten synthetischen
Quelltabellennamen; sie ist kein SSIS-Paketexecutor und legt die Quelle nicht an.

## Abweisungen und Prüfung

Fehlende, nichtkanonische oder doppelte Lineage-Bindungen, kollidierende Namen
und IDs, Typ-/Codepageabweichungen sowie unbekannte Versionen oder Ports
blockieren den abhängigen Pfad. Die Diagnose ist im Ergebnis sichtbar; eine
unvollständige Zielprojektion wird nicht als ausführbar ausgegeben.

Die [Prüfmatrix](../Tests/README.md#copy-column-v1-deltaabnahme)
trennt die ursprünglichen Explain-Läufe vom abschließenden Prozedurguard.
Paketintegrität, tatsächliche ZIP-Ausführung, SSMS, TLS und Linux-Exporthost
sind eigene Nachweise. Ältere Gesamtabnahmen bleiben an ihre ursprünglichen
Builds gebunden; der aktuelle Gesamtmodulstatus steht in `module.yaml`.
