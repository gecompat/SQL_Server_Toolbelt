# Vorschlag: JSON-Konstruktoren (`TC-2026-009`, Slice B)

## Aktueller freigegebener Slice B, 2026-10-01

Nach individueller Besprechung der zwei APIs hat der Benutzer deren Implementierung,
Prüfung und PR-Merge ausdrücklich freigegeben („ok, passt so“); dauerhaft erfasst
im ersten aktiven Abschnitt von `.ai/BACKLOG.md`. Nur `toolbelt_json.USP_JsonArray`
und `toolbelt_json.USP_JsonObject`, keine Aggregate/Patches/Typinferenz oder Release.
Die frühere Table-Type-Idee unten ist historisch und durch caller-lokale #Temp ersetzt.

Modul `toolbelt.json.constructors` 1.0.0, pure T-SQL. Ein interner kanonischer
Prüf-/Escapingkern mit zwei öffentlichen Fassaden, keine kopierte Fachlogik.
Die Parameter beider Fassaden lauten EntriesTable sysname=NULL,
MaxEntries int=10000, MaxTotalValueBytes bigint=2097152, MaxResultBytes bigint=2097152,
ResultTable sysname=NULL, KeepData bit=0, Debug tinyint=0, Hilfe bit=0.
Positive Ceilings 100000/16777216/16777216; keine Unlimited-Konvention.
Dies konkretisiert technische Parameternamen/Bytezählung innerhalb des freigegebenen Vertrags.

Inputspalten: Ordinal int positiv/eindeutig mit erlaubten Lücken, ValueKind und
Value nvarchar(max); Object zusätzlich Key nvarchar(max), nicht NULL/leer, maximal
1024 UTF-16-Codeeinheiten. Exakte erforderliche Typen; zusätzliche Spalten ignoriert.
Kind exakt string/number/boolean/null/json. NULL-Kind verlangt SQL-NULL, die übrigen
Kinds verlangen nicht-NULL. Number strikt JSON-Literalgrammatik ohne SQL-Precision-
oder Culturekonvertierung; Boolean exakt true/false; json vollständiges Objekt/Array.
Binär längensensitive Keys einschließlich Spaces, keine Normalisierung; Duplikate Fehler.

Ergebnis JsonValue nvarchar(max) NOT NULL, genau eine Zeile; leere Eingabe []/{}.
Wertebytes zählen DATALENGTH(Value), NULL=0. Ergebnisbytes umfassen Syntax, Keys,
Escapes und Werte. Vollständige Konstruktion vor Ausgabe/Zielmutation.
Helpfirst ignoriert alle anderen Parameter und mutiert nichts; Debug nur Messages.
Dependency ResultTable >=1.0.0 same_database mit vollständigem Versions-/Markerpreflight.

Ressourcen-Preflight liest zunächst Count/DATALENGTH/Keygrenzen/Kindlänge,
nicht private Kopien beliebig großer LOBs. TABLOCK/HOLDLOCK in eigener Transaktion
oder Caller-savepoint schützt diese Beobachtung bis zum Snapshot. Fremde Transaktionen
werden niemals committed; doomed Caller benötigt Callerrollback. Danach begrenzte
private Snapshot-/Fragment-/Ergebnistabellen und geordnete STRING_AGG-Assembly,
keine wiederholte Konkatenation des wachsenden Gesamt-LOBs. T-SQL-Cursor ist hier
auf einzelne bereits begrenzte Entries beschränkt; UTF-16-Prüfung blockweise set-basiert.
Alternativen: CLR wäre zusätzliche Security-/Deploymentfläche; FOR JSON ohne expliziten
Literalvertrag würde Typ-/Escapingsemantik verschieben; variadische Scalar-API ist nicht verfügbar.

Unicodeprüfung umfasst tatsächliche UTF-16 und dekodierte Strings/Keys in eingebettetem
JSON einschließlich \\uHHHH. Nach ISJSON folgt ein lexical Stringtoken-Scan ohne
rekursive LOB-Kopien, zusätzliche Tiefengrenze oder Umformatierung des Fragments.
Gültige Surrogatpaare erhalten, unpaired Folgen Fehler. Keine Schema- oder globale
Duplicate-Key-Prüfung innerhalb eines bereits gelieferten JSON-Fragments.

Technische Fehlerpriorität: Hilfe; reservierter Caller-Tempnamespace vor Core-Kompilierung;
Ressourcenparameter; Dependency; Inputname/Typ/
sameTarget; Count; Ordinals; Key-NULL/Leer/Länge; Kindlänge; rohe Werte-/minimale
Ergebnisbytes vor Copy; Snapshot-Keyduplicates/exakter Kind/NULL; weitere minimale
Ergebnisbytes; je Ordinal Unicode/Literal/decodiertes JSON-Unicode; fertige Ergebnisbytes;
Outputpreflight/Write. Kategorien53600–53610; Lifecycle53620–53629, nach Inventoryprüfung.
Fehlertexte enthalten keine Nutzdaten. Enginefehler unverändert; no partial outputs.
Der vorgeschaltete Namespaceguard verhindert auch unter CS-Datenbank/CI-tempdb,
dass fremde gleichnamige Tempobjekte den Core vor seiner eigenen Prüfung eclipsen.

Prüfplan: synthetische Byte-/Escaping-/Null-/Literal-/Surrogat-/Prioritäts-/Grenztests,
Help und tatsächliche clientseitige NOT-NULL-Resultmetadaten, alle KeepData-Fälle,
Blocker, own/caller/doomed Tx, local/central, Marker/Hash/Repeat, Kollisionen und
Uninstall-Dependencies. Risikobasiert zuerst 2019Linux/latest, dann2025Windows/CU8;
kein pauschaler vollständiger Matrix- oder Produktionskapazitätsnachweis.
Aktuelle Runtime-Evidenz steht ausschließlich in der gekoppelten Modul-Testmatrix.

## Historischer Vorschlagsstand vor Freigabe (superseded für Slice B)

Der Path-Exists-Slice von `TC-2026-009` bleibt unverändert und validiert.
Dieses Dokument bereitet die getrennten JSON-Konstruktoren vor. Es autorisiert
keine öffentlichen SQL-Objekte, keine Änderung des bestehenden Moduls und
keine JSON-Serialisierung.

## Problem

SQL Server 2019 besitzt keine variadische T-SQL-Aufrufoberfläche für eine
portable Entsprechung von `JSON_ARRAY` oder `JSON_OBJECT`. Eine Scalar-UDF
kann keine beliebige Anzahl heterogener Argumente entgegennehmen. Dynamischen
SQL-Text oder untypisierte JSON-Fragmente als Ausweichschnittstelle zu
akzeptieren, würde Escaping, Injektion und Nullsemantik unklar machen.

## Empfohlener V1-Schnitt

V1 sollte zwei getrennte In-memory-Procedure-Aufrufe mit expliziten,
typisierten Table Types verwenden:

1. **Array-Konstruktion:** positive Ordinalspalte, `ValueKind` und
   `nvarchar(max)`-Wert.
2. **Object-Konstruktion:** positive Ordinalspalte, nicht leerer Key,
   `ValueKind` und `nvarchar(max)`-Wert.

`ValueKind` unterscheidet mindestens String, Number, Boolean, JSON-`null` und
bereits validiertes JSON-Fragment. Die Values sind nicht durch SQL-
Datentypinferenz implizit: ein Textwert `"12"` und eine JSON-Zahl `12` haben
bewusst verschiedene Kind-Werte. Die späteren Type- und Procedure-Namen
bleiben vor der Funktionsbesprechung offen.

## Vertragsvorschlag

| Aspekt | Vorschlag |
|---|---|
| Reihenfolge | Einzigartige positive Ordinals; Array- und Objektmember erscheinen in dieser Reihenfolge. |
| SQL `NULL` | SQL-`NULL` in Wert oder Key ist Fehler, außer ein expliziter `ValueKind` definiert JSON-`null`. |
| Strings | Immer als JSON-String serialisieren und vollständig escapen. |
| Numbers / Boolean | Vor Einbau gegen eine festgelegte JSON-Literalgrammatik validieren; keine datenbankcollationabhängige Interpretation. |
| JSON-Fragment | Vor Einbau mit festgelegter JSON-Validierung prüfen; ungültige Fragmente sind Fehler. |
| Keys | Nicht leer, maximal festgelegte Länge und binär verglichen. Duplicate Keys sind V1-Fehler. |
| Ausgabe | `nvarchar(max)` mit kanonischer, nicht formatierter Serialisierung; keine Pretty-Print- oder Property-Reordering-Zusage. |

Caller liefern keine Propertynamen, JSON-Pfade, SQL-Ausdrücke oder Formatflags
als ausführbaren Text. Das Modul erzeugt nur den JSON-Wert und führt ihn nicht
aus. Große Werte benötigen explizite Eintrags- und Gesamtlängenlimits.

## Abgrenzung und Tests

Die V1-API ist eine Eingabeoberfläche für einzelne JSON-Werte, kein JSON-
Aggregate und kein allgemeines Transformationssystem. Gruppierte Erzeugung
bleibt `TC-2026-013`; JSON-Patch, Schema-Validierung und Abfrageausdrücke sind
eigene Kandidaten.

Tests verwenden nur synthetische Werte und prüfen Escaping, Control-
Characters, Unicode, SQL-`NULL`, JSON-`null`, alle ValueKinds, ungültige
Literale/Fragmente, Duplicate Keys, Ordinals, Grenzen, ResultTable-
Integration, Wiederholungsdeployment, Lifecycle und lokale SQL_Server_Lab-
Ziele für 2019, 2022 und 2025 unter Windows und Linux. Ein CU wird nur bei
patchgebundenem Verhalten ausgewählt.

## Entscheidungspunkt

Vor Implementierung wird der vorgeschlagene Table-Type-Schnitt bestätigt oder
geändert: getrennte Array-/Object-APIs, explizite ValueKinds, binäre Keys und
Duplicate-Key-Fehler. Danach werden Signaturen, genaue Literalgrammatik,
Limits, Fehlerbereich und Modulgrenze als konkrete Funktionen besprochen und
freigegeben.

## Quellen

- [Microsoft: STRING_ESCAPE](https://learn.microsoft.com/en-us/sql/t-sql/functions/string-escape-transact-sql?view=sql-server-ver17) – kanonisches JSON-Escaping einschließlich Controls.
- [Microsoft: ISJSON](https://learn.microsoft.com/en-us/sql/t-sql/functions/isjson-transact-sql?view=sql-server-ver17) – ohne neueren Typconstraint ausschließlich vollständiges Objekt/Array; kein Duplicate-Key-Nachweis.
- [Microsoft: STRING_AGG](https://learn.microsoft.com/en-us/sql/t-sql/functions/string-agg-transact-sql?view=sql-server-ver17) – geordnete Aggregation der begrenzten nvarchar(max)-Fragmente.
- [Microsoft: JSON_OBJECT](https://learn.microsoft.com/en-us/sql/t-sql/functions/json-object-transact-sql?view=sql-server-ver17)
- [Microsoft: JSON_ARRAY](https://learn.microsoft.com/en-us/sql/t-sql/functions/json-array-transact-sql?view=sql-server-ver17)
- [bestehender Candidate](../../Backlog/TOOLBELT_CANDIDATES.md#tc-2026-009-json-konstruktion-und-pfadprufung-fur-sql-server-2019)
