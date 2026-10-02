# USP_JsonConstructInternal

Interner kanonischer pure-T-SQL-Kern; keine zusätzliche öffentliche API.
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
