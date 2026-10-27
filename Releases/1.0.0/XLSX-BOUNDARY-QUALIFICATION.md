# XLSX: feste Blattgrenze und nicht abgeschlossene Shared-String-Grenze

Dieser Bericht trennt zwei bestehende XLSX-Verträge. Die maschinenlesbare
[Evidenz](xlsx-boundary-qualification.json) bindet die verwendeten
Installationspaket-DLLs und die repository-relativen Eingaben der beiden
Läufe. Für die gepinnte XLSX-Matrixdatei bleiben die ausgeführten CRLF-Bytes
und ihr SHA-256 erhalten; zusätzlich ist nur die verlustfreie LF-Projektion
für Cold-Checkouts gebunden. Sie ändert weder Produktcode noch Modul- oder
Veröffentlichungsstatus.

## Blattanzahl: PASS für 32/33

`toolbelt_file.USP_ListXlsxWorksheets` wurde mit dem unveränderten
Standardlimit geprüft. Zwölf Ziel-/Kompatibilitätsfälle decken Windows und
Linux mit SQL Server 2019/CL150, 2022/CL150 und CL160 sowie 2025/CL150,
CL160 und CL170 ab. Jeder Fall enthält lokale und direkte zentrale Ausgabe.

- 24 positive Routen lieferten jeweils 32 feste Blattzeilen (768 insgesamt).
- Synthetische Workbooks enthalten `Sheet01` bis `Sheet32`; das Overflow-
  Workbook fügt `Sheet33` hinzu. Es gibt kein Shared-Strings-Teil.
- 24 direkte Reader-Aufrufe wurden mit SQL-Fehler 51520 und dem exakten
  Fehlertext `TBX_XLSX_SHEET_LIMIT` abgewiesen, bevor eine Zeile gelesen
  wurde.
- Zwölf unmittelbare und sechs ausgewählte Abschlussaudits bestanden. Die
  24 eigenen Datenbanken wurden entfernt.

Die Zeilen werden über `SheetOrdinal` geprüft; der Report nimmt keine
SQL-Auslieferungsreihenfolge an. Das Ergebnis gilt nur für diesen
Listing-Grenzfall.

## Shared Strings: BLOCKED_BUDGET

Der separate Test von `toolbelt_file.USP_ReadXlsxWorksheetCells` erreichte
keine erfolgreiche positive Ausgabe mit 50.000 Shared Strings. Zwei lokale
Aufrufe – Linux SQL Server 2019/CL150 und Windows SQL Server 2025/CL170 –
endeten vor den drei erwarteten Zellzeilen mit SQL-Fehler 51520 und
`TBX_XLSX_BUDGET_EXCEEDED`. Beide Fälle wurden bereinigt und auditiert.

Damit ist die 50.000-Grenze nicht qualifiziert. Das Workbook mit 50.001
Strings und zentrale Routen wurden nicht ausgeführt; hierzu gibt es keinen
Ergebnis- oder Fehlernachweis. Das unveränderte Provider-Ausführungsbudget
beträgt 5.000 ms. Ein erneuter Versuch setzt eine separat freigegebene
Änderung der Ausführungsbedingungen voraus; es wird weder das Budget noch das
Orakel für diesen Bericht angepasst.

## Gesamtumfang und Grenzen

Insgesamt gab es 34 SQL-Prozessinvokationen: 30 für die Blattmatrix und vier
für die beiden fehlgeschlagenen Shared-String-Läufe samt unmittelbaren
Audits. Die Journale weisen 26 eigene Datenbankeinträge sowie 28
Trust-Entfernungsereignisse aus; Ereignisse sind keine Aussage über
unterschiedliche Trust-Hashes.

Der Bericht belegt weder eine vollständige XLSX-Modulabnahme noch andere
Inputgrenzen, ResultTable-Ausgabe, Callerrechte oder authentifiziertes TLS.
Der Modulstatus bleibt `partially validated`, der Release-Status
`unreleased`, und Veröffentlichung ist nicht autorisiert.
