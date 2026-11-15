# SSIS Copy Column V1: zusammengesetzte Deltaabnahme

Stand 2026-11-14 UTC. Die konkrete Benutzerfreigabe vom 2026-11-13 umfasst
ausschließlich eine zusätzliche relationale Copy-Column-Stage für `explain`.
Der [Vertrag](../../Documentation/Architecture/SSIS_CURRENT_API_CONTRACT.md#additiver-einzelfunktionsvertrag-copy-column-v1--2026-11-13)
und die [Benutzeranleitung](../../Modules/toolbelt.tsql.ssis-debug/Documentation/CopyColumnV1.md)
beschreiben Eingaben, Ergebnisse, Abweisungen und Grenzen.

Der [maschinenlesbare Record](../../Modules/toolbelt.tsql.ssis-debug/Tests/Qualification/CopyColumn.V1.20261114.json)
ist **PASS_FOR_COMPOSED_DELTA**: insgesamt 56 native Profile, 1.112 Assertions
und 14 frische unabhängige Abschlussaudits. Dies ist keine vollständige neue
SSIS-Modul-, ZIP-, SSMS-, TLS- oder Linux-Hostabnahme.

## Ursprüngliche Explain-Matrix

Zwölf vollständige Läufe mit je 92 Assertions prüften lokal/direkt zentral:

| Windows SQL | Patch | Compatibility Levels | Kontexte |
|---|---|---|---:|
| 2019 | CU32 | 150 | 2 |
| 2022 | CU26 | 150,160 | 4 |
| 2025 | CU8 | 150,160,170 | 6 |

Je Kontext bestanden Paketformat 6/8 mit Integer- und Unicode-/NULL-Quelle:
48 Profile und 1.104 Assertions. Ausgeführt wurde das vollständige zurückgegebene
DebugScript über seine unveränderte, hashgeprüfte Batchliste. Feste Orakel prüfen
Zeilen, SQL-Typen, Quell-/Kopiewerte, NULL, Unicode, leeren Text und erhaltene
Quelldaten. Eine neu erzeugte Vorlage mit fehlender Quell-Lineage muss den
abhängigen Zielpfad abweisen. Eigene Testdatenbanken wurden entfernt; zwölf
frische unabhängig ausgeführte Audits bestätigten DB-, Trust- und Konfigurationscleanup.

Diese erfolgreichen Läufe gehören zum ersten geprüften Copy-Column-DLL.
Sie werden nicht nachträglich zu frischen Läufen eines anderen DLL umbenannt.

## Gefundene Scopeerweiterung und gezielte Korrektur

Der nachfolgende Vertragsreview fand, dass der gemeinsame Stagebuilder die
neue Komponente auch für `procedure-definition` zugelassen hätte. Der finale
Build weist diesen nicht freigegebenen Weg mit `procedure_profile` ab.
Die neue negative Operation bestand nativ auf Windows SQL2025/CU8 CL170 lokal
und direkt zentral: acht Profile, acht Assertions und zwei frische Audits.
Es wird keine Prozedurdefinition ausgegeben oder installiert.

Die Explain-Matrix wird nur für ihren unveränderten Zweig wiederverwendet.
Der [Validator](../../Scripts/Release/validate_ssis_copy_column.py) entfernt
genau den neuen frühen Prozedurguard aus der aktuellen Translatorquelle und
vergleicht dann die Originalhashes aller 24 Produktdateien einschließlich
gemeinsamer Core-/Parserquelle. Jede andere Produktänderung blockiert diese
Anerkennung. Die alten und finalen DLL-Identitäten stehen getrennt im Record.

## Offline- und Modellprüfung

Der finale Build ist reproduzierbar; die vollständige bestehende Frameworksuite
bestand mit 29 begrenzten Prozessen. Der neue Copy-Column-Teil prüft beide
ClassIDs/Paketformate, Quellerhalt und Reihenfolge, Mehrfachkopien einer Quelle,
SQL-Sonderzeichen in Metadatennamen und fehlerhafte Lineage-, Typ-, Codepage-,
Versions- und Portformen. Die Prozedurabweisung ist eine eigene Gegenprobe.

Die gemeinsame CLR-/externe Hostprüfung besteht mit 232 Checks auf Windows.
Dabei wurde eine echte Schemaabweichung korrigiert: qualifizierte synchrone
Ports geben das bereits deklarierte `REGULAR` aus. Die frühere Ausgabe
`NORMAL` entsprach nicht dem bestehenden Austauschschema. Die gemeinsame
Modellquelle ist nach der abschließenden Prozedurguard-Korrektur bytegleich;
kein frischer nativer Linux-Exporthostlauf wird behauptet.

Die Nativezulassung prüft den eingefrorenen Runset, eine Full-Frameworkreceipt,
Produkt-/Fixturepins, exakte Zielauswahl und Deadline vor der Labnutzung.
Offlinegegenproben führen weder Labdiscovery noch SQL aus. Die frühere
vollständige SSIS-Abnahme wird separat am unveränderten historischen Snapshot
validiert; ihre originalen Berichte und ZIPs bleiben unverändert.

## Gemeinsamer Rahmen und Grenzen

Der gemeinsame Rahmen betrug höchstens 28 Lauf-/Auditaufrufe, 28 DB-Reservierungen
und 60 Minuten. Tatsächlich: 28 Aufrufe, 14 angelegte und entfernte eigene DBs,
14 frische Audits, kein nativer Fehllauf. Die ursprüngliche Explainphase bleibt
mit 24 Aufrufen geschlossen; die bereits eingeplante Korrekturreserve prüfte
nur den neu betroffenen Prozedurguard. Ausgangszeit und Zähler wurden nicht
zurückgesetzt. Private Vorbereitungsfehler vor jedem SQL-Zugriff und die
ursprünglichen Framework-/Modellbefunde bleiben in den privaten Originalen.

Keine neuen Principals oder Grants, keine Lab-/Zertifikats-/Truststoreänderung.
Nur eigene notwendige CLR-Konfiguration und bekannte gebundene Releasehashes
wurden nach bestehender Freigabe verwendet und wiederhergestellt.
Functional-Verschlüsselung belegt keine authentifizierte TLS-Verbindung.
Native SSIS-Runtime-Parität, OS-/VM-Verlust und unbegrenzte Kapazität sind
nicht qualifiziert. Nicht veröffentlicht oder getaggt.
