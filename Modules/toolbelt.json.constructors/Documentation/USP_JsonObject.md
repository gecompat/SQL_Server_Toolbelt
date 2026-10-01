# USP_JsonObject

Freigegeben am 2026-10-01 gemäß kanonischem Backlog TC-2026-009 Slice B.

Signatur (Parameterreihenfolge): EntriesTable sysname=NULL, MaxEntries int=10000,
MaxTotalValueBytes bigint=2097152, MaxResultBytes bigint=2097152,
ResultTable sysname=NULL, KeepData bit=0, Debug tinyint=0, Hilfe bit=0.
Hilfe=1 ignoriert alle anderen Parameter vollständig. Standardparameter NULL
entsprechen 0; Ressourcenparameter NULL/0 sind ungültig.

Caller-lokale #Temp: Ordinal int, ValueKind nvarchar(max), Value nvarchar(max), zusätzlich Key nvarchar(max).
Erforderliche Spalten exakt, zusätzliche Spalten ignoriert; nullable Metadaten
sind erlaubt, Werte werden vollständig geprüft. Positive einzigartige Ordinals,
Lücken erlaubt; Ausgabe in Ordinalreihenfolge. Eingabeobjekt darf nicht Ausgabeobjekt sein.
Keine globale Temp/permanente Tabelle/Tabellenvariable; reserviertes #tbx_ nicht als Eingabe.
Keys nicht NULL/leer, maximal 1024 UTF-16-Codeeinheiten. BIN2 plus Bytelänge; keine Normalisierung, a und a[Space] sind verschieden. Binär identische Keys sind Fehler.

Exakte ValueKinds string/number/boolean/null/json. String vollständig JSON-escaped,
Number strikt -?(0|[1-9][0-9]*)(\\.[0-9]+)?([eE][+-]?[0-9]+)? ohne Präzisionsverlust,
Boolean exakt true/false. null verlangt Value IS NULL; andere Kinds verlangen
nicht-NULL. json ist ein vollständiges validiertes Objekt/Array, kein Scalar.
Tatsächliche und in JSON-Stringwerten/Keys decodierte UTF-16-Surrogatfolgen
müssen gültig gepaart sein, auch bei \\uHHHH. Fragmente bleiben sonst wörtlich erhalten.

Ergebnis genau eine Spalte/Zeile JsonValue nvarchar(max) NOT NULL, BIN2.
Leere Tabelle ergibt {}. Kein PrettyPrint, keine Inferenz oder Membernormalisierung;
eingebettetes validiertes JSON wird nicht umformatiert.

Positive MaxEntries bis100000; TotalValueBytes und ResultBytes jeweils bis16777216.
TotalValueBytes = SUM(DATALENGTH(Value)), NULL zählt0. ResultBytes zählt exakte
UTF-16-Ausgabe inklusive Keys/Escapes/Interpunktion. Konstruktion/Validierung vor
ResultTable-Mutation. Ressourcen sind keine RAM-/Durchsatz-/Wallclockgarantie.

Fehlerpriorität: Hilfe; reservierter Caller-Tempnamespace vor Core-Kompilierung;
Ressourcen; Dependency; Eingabename/Schematyp/sameTarget;
Count/Ordinals; Keynull/Leer/Länge; Kindlänge; rohe Gesamtwert-/minimale Ergebnisbytes
vor LOB-Copy; Snapshot-Keyduplicates; exakter ValueKind; NULLvertrag;
weitere minimale Ergebnisbytes; je Ordinal Unicode/Literal/decodiertes JSON-Unicode;
fertige Ergebnisbytes; Outputpreflight. Precopy-Count/DATALENGTH-Aggregate und Snapshot
liegen unter TABLOCK/HOLDLOCK in eigener Transaktion oder Caller-savepoint.
Fehler53600 Ressourcenparameter,53601 Input,53602 Ordinals,53603 Key,
53604 DuplicateKey,53605 Kind,53606 NULL,53607 Unicode,53608 Literal,
53609 Ressourcenüberschreitung,53610 Dependency. Enginefehler bleiben unverändert.

ResultTable: kanonischer Helper; Replace/Append nach USP_CONTRACT. Eigene
Transaktion oder Caller-savepoint; keine fremde Transaktion committen. Bei
uncommittable Callertransaktion ist deren Rollback Callerpflicht. Keine Teilausgabe.
Debug ausschließlich Messages ohne Payload. EXECUTE/Tempmetadatensicht und bei
ResultTable zusätzlich Helper-EXECUTE; keine Hochprivilegierung oder pauschale CrossDB-Rechtezusage.

Runtime: Am 2026-10-01 im ausgewählten Scope2019Linux/latest und2025Windows/CU8
erfolgreich, siehe Testmatrix. Weitere Ziel-/Rechtekontexte bleiben offen;
`partially validated`, keine Produktionskapazitätszusage.
