# USP_JsonConstructInternal

Interner SQL-Snapshot-/Budget-/Routingadapter mit gemeinsamem SAFE-CLR-
Entrykern; keine zusätzliche öffentliche API. Seit 1.2 ersetzen Stage0,
das ursprüngliche echte ISJSON und Stage1 den früheren T-SQL-Entryparser.
Die globalen Prüfungen und ResultTable-/Callerregeln bleiben erhalten.
Der [Migrationsvertrag](../../../Documentation/Architecture/JSON_CLR_MIGRATION_CONTRACT.md)
bindet Bridge, Fehler-/Kostenorakel und bekannte Produktbytes; die vollständige
native 1.2-Regression ist noch offen. Begrenzte Teilnachweise stehen in
[Tests](../Tests/README.md).
`@ObjectMode bit=NULL` wählt intern Array=0/Object=1. Danach EntriesTable,
MaxEntries, MaxTotalValueBytes, MaxResultBytes, GroupMode bit=0, ResultTable, KeepData, Debug, Hilfe.
GroupMode 0 bewahrt eine JsonValue-Zeile und das bisherige Einspaltenschema;
GroupMode 1 trägt GroupOrdinal durch Snapshot/Fragmente und erzeugt je Gruppe
eine Zweispaltenzeile. Beide festen Referenztabellen verwenden verschiedene
Tempnamen. Unicode, Literalprüfung und Escaping existieren weiterhin nur einmal.
Globale Budgets sind keine Budgets je Gruppe. NULL GroupMode ist außerhalb Help
53600; der zusätzliche Parameter steht vor dem Standardtail.
Nur die öffentlichen Wrapper sind Anwendungsschnittstellen. Interne Help unterstützt
denselben standardisierten Vertrag und mutiert nichts.

Private Snapshot-/Fragment-/Ergebnistabellen; Eingabewerte niemals als SQL ausführen.
Zahlen werden als Literalgrammatik geprüft, ohne numerische SQL-Konvertierung.
Geordnete STRING_AGG-Fragmente vermeiden das wiederholte Anfügen an ein wachsendes
Gesamt-LOB; dies ist keine Streaming-, Echtzeit- oder Parallelitätszusage.
