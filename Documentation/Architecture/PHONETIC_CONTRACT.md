# Phonetikvertrag 1.0.0

## Freigabe und Vor-Source-Gate

Die beiden Verfahren wurden am 2026-10-01 einzeln zur Implementierung
freigegeben. Am 2026-10-03 bestätigte der Benutzer zusätzlich die beiden
TVF-Formen, NULL-/Leer-/Fehlersemantik, das begrenzte Alphabet, vollständige
Double-Metaphone-Codes und die eigene portable SAFE-Assembly. Die technische
Referenz-, Lizenz-, Binding- und Grenzprüfung wurde vor Source unabhängig
abgeschlossen. Sie präzisiert die freigegebenen Verträge; sie erlaubt keine
weiteren öffentlichen Funktionen. Dieses Vor-Source-Gate ist geschlossen.
Build, Framework, eigene IL und begrenzter CLR-/SQL-/Lifecycle-Scope sind
unabhängig nachgewiesen. Java-Referenzdifferential, vollständige Qualifikation
und aktuelle Head-CI bleiben offen; siehe die
[Testevidenz](../../Modules/toolbelt.string.phonetic/Tests/README.md).

`toolbelt.string.phonetic` 1.0.0 besitzt ausschließlich zwei öffentliche
Inline-TVFs und zwei interne CLR-TVFs. Es erweitert keine Distanzassembly.
Die beiden kontextabhängigen Scanner werden einmal im eigenen speicherreinen
SAFE-Kern umgesetzt. Eine vollständige relationale T-SQL-Umsetzung wäre
ein weiterer Scanner mit nicht qualifizierten Kosten und eigener Wartung;
die geprüfte CLR-Variante ist deshalb ausdrücklich gewählt. Die IF-Fassaden
garantieren weder Algorithmus-Inlining noch Parallelität oder CPU-/Heapkosten.

## Öffentlicher Vertrag

| Funktion | Parameter ohne Default | Ergebnis in Reihenfolge |
|---|---|---|
| `toolbelt_string.TVF_ColognePhonetic` | `@Text nvarchar(max)` | `PhoneticCode varchar(max) NULL`, `ErrorCode int` |
| `toolbelt_string.TVF_DoubleMetaphone` | `@Text nvarchar(max)` | `PrimaryCode varchar(max) NULL`, `AlternateCode varchar(max) NULL`, `ErrorCode int` |

Jeder Aufruf ermittelt vollständig genau eine Zeile vor ihrer Ausgabe.
`ErrorCode` ist logisch immer nicht NULL; physisch nullable CLR-Metadaten
werden nicht durch erfundene Defaults verdeckt. SQL NULL liefert NULL-Codes
und Status0. Nicht-NULL-Eingaben mit leerem Code liefern leere Zeichenfolgen.
Beide Metaphone-Codes bleiben erhalten, auch wenn sie gleich sind; ein leerer
Alternativcode wird nicht zu NULL. Die ASCII-Codes verwenden
`Latin1_General_100_BIN2`. Terminales J kann im Alternativcode ein abschließendes
ASCII-Leerzeichen erzeugen. Dieses Byte bleibt erhalten: Tests prüfen Länge
und Bytes, nicht die gepaddete SQL-Textgleichheit.

Es gibt keine Sprachwahl, Vergleichs-USP, MaxCodeLen-, Normalisierungs- oder
Cultureoption. Der Funktionsname wählt das Verfahren.

## Alphabet und inhärente Verarbeitung

Kölner Phonetik erlaubt ASCII einschließlich Kontroll- und Satzzeichen sowie
Ä/Ö/Ü/ä/ö/ü/ß. Festes Uppercase, Umlautabbildung A/O/U und ß→SS sind Bestandteil
des Verfahrens. Großes ẞ ist nicht unterstützt. Nichtbuchstaben bleiben beim
Lookahead im Text und ändern im Scanner weder letzten Buchstaben noch letzten
Code; H setzt den ignorierten letzten Code. C-Anlaut bedeutet leerer
Ausgabepuffer, nicht Eingabeindex0.

Double Metaphone erlaubt ASCII und Ç/ç/Ñ/ñ. Nur Rand-Codeeinheiten
U+0000..U+0020 werden gemäß Java-trim entfernt; Innenzeichen bleiben erhalten.
Das Uppercase ist explizit für dieses Alphabet definiert. Es gibt keine
Unicode-Trim-, NFKD-, Akzententfernungs- oder Transliterationserweiterung.
Andere gültige Unicode-Scalars, auch Supplementary-Zeichen, sind unsupported.

## Grenzen und Fehlerpriorität

| Grenze pro Aufruf | Wert |
|---|---:|
| rohe UTF16-Codeeinheiten, vor Kopie | 4096 |
| transformierte UTF16-Codeeinheiten | 8192 |
| ASCII-Bytes je Code | 16384 |
| beide Double-Metaphone-Codes zusammen | 32768 |

Priorität: NULL → rohe Quote → vollständige UTF16-Validierung → Alphabet →
Transformation/Outputquote → Ergebnis. Ein späterer malformed Surrogate gewinnt
damit vor einem früheren unsupported Scalar. Ressourcenüberschreitung erzeugt
keine Teilcodes. Status1 bedeutet malformed UTF16, Status2 ausschließlich eine
deklarierte Quote, Status3 unsupported Alphabet. Bei Status1/2/3 sind sämtliche
Codefelder NULL. Technische Shape-, Scanner-, Binding-, Allokations- und
Overflowdefekte bleiben technische Fehler.

Alle Größenadditionen sind checked. Der vollständige Metaphone-Scanner besitzt
keinen Vierzeichenclamp und keinen erfolgreichen frühen Abbruch. Aus der
Scannerstruktur folgen bei zulässiger Eingabe konservativ höchstens8192 Bytes
je Code; die höheren Outputquoten bleiben unverändert und sind keine behaupteten
erreichbaren API-Grenzen. Kölner Transformation und Code können jeweils8192
erreichen. Diese strukturellen Schranken ersetzen keinen Runtime-Nachweis und
begründen keine Gesamtbatch-, Invocation-, Heap- oder Wallclockzusage.

## CLR-Bindings

`Toolbelt.String.Phonetic.dll`, AssemblyVersion1.0.0.0, wird als
`Toolbelt_String_Phonetic` mit `PERMISSION_SET=SAFE` installiert. Die Bridge
`Toolbelt.String.Phonetic.PhoneticBridge` bietet exakt:

- `EvaluateCologne(SqlChars)` / `FillCologneRow(object, out SqlString, out SqlInt32)`;
- `EvaluateDoubleMetaphone(SqlChars)` / `FillDoubleMetaphoneRow(object, out SqlString, out SqlString, out SqlInt32)`.

Beide Evaluate-Methoden liefern `IEnumerable`, kein yield, sondern ein festes
Array mit einer unveränderlichen invocationlokalen Zeile. FillRow akzeptiert
nur den privaten erwarteten Zeilentyp und prüft Status-/NULL-Konsistenz.
SqlFunction ist deterministic/precise, DataAccess/SystemDataAccess=None, mit
exaktem FillRowMethodName/TableDefinition. Die internen SQL-Slots heißen
`TVF_ColognePhoneticCore` und `TVF_DoubleMetaphoneCore` (FT); öffentliche Slots
sind IF mit expliziter ASCII-Konvertierung. Die internen FT-Codefelder und
beide TableDefinition-Attribute verwenden nvarchar(max): SQL Server erlaubt
in CLR-Tabellenrückgaben keine nicht-Unicode-Zeichenfelder. Die IF-Fassaden
konvertieren die bereits im Kern validierten ASCII-Codes unter
Latin1_General_100_BIN2 nach varchar(max) und behalten dieselbe Collation.
NULL, abschließende Leerzeichen und max-Länge bleiben erhalten; dies erweitert
weder das Alphabet noch den öffentlichen Ergebnisvertrag.
[Microsoft CLR-Tabellenfunktionen](https://learn.microsoft.com/en-us/sql/relational-databases/clr-integration-database-objects-user-defined-functions/clr-table-valued-functions?view=sql-server-ver17).
Keine I/O-/SQL-/Thread-/globale Mutable-State-API.

## Lifecycle, Rechte und Hashbindung

Local und central verwenden denselben Kern in derselben Installations-DB.
Deploy erwartet vollständige zuvor offline qualifizierte AssemblyBits sowie
den expliziten erwarteten installierten SHA2-512-Hash; 0x bedeutet ausschließlich
erwartete Abwesenheit. Repeat und Uninstall prüfen Hash, kohärente Modul-/
Release-/Modusmarker, exakt vier Slottypen und CLR-Bindings. Unbekannte,
inkohärente oder fremde Zustände werden nicht adoptiert. Sourcehashes sind
diagnostisch. Keine neue Known-Binary-Registry wird eingeführt.

Vor erster Mutation und unter eigener Application Lock werden vollständige
Metadatensicht, VIEW DEFINITION und SELECT auf sys.sql_expression_dependencies,
Assemblybytes/-bindungen und effektive Eigentümer geprüft. Schema, Assembly und
eigene Slots müssen kohärente Eigentümer besitzen. DDL/Marker sind atomar in
eigener Transaktion; aktive Callertransaktion wird vor SET/Mutation abgelehnt.
Uninstall schützt fremde SQL-/Assemblyconsumer; central verlangt ausdrücklich
Bestätigung externer Consumer. Keine Rechtevergabe, Ownerreparatur oder
EXECUTE-AS-Änderung. Runtime benötigt SELECT/Ownership-Chain, kein Hashparameter
und keine datenbankweite Runtime-Metadatensicht.

Trust ist ein getrennter administrativer exakter SHA2-512-Opt-in unter bereits
vorhandenen Sysadminrechten. Standarddeploy/Uninstall verändern weder Trust
noch clr enabled, strict security oder TRUSTWORTHY.

## Referenz und Lizenz

Der Port basiert auf Apache Commons Codec1.18.0, Commit
`5f76abb946164b943bc2cf367bc1d70b8f6e70d1`. Beide vollständigen Java-Scanner,
zugehörige Tests sowie LICENSE/NOTICE wurden vor Source separat bytegebunden
und gelesen. Apache-2.0-Header und modullokale LICENSE/NOTICE bleiben erhalten;
die C#-Portierung und semantischen Anpassungen werden ausdrücklich markiert.
Rootlizenz und geschützter README-Lizenzblock bleiben unverändert. Der separat
lizenzierte Aspell-Bulkbestand wird weder kopiert noch als Goldenbasis verwendet.
Explizite Apache-Testassertions außerhalb dieses Bestands und synthetische
Kontext-/Grenzfälle sind zulässig. Default4-Präfixassertions sind keine Fullcode-
Goldens. Es wird keine Java-Runtime installiert oder zur Laufzeit benötigt.

Primärquellen: [Release-Source](https://github.com/apache/commons-codec/tree/5f76abb946164b943bc2cf367bc1d70b8f6e70d1),
[Apache-2.0](https://www.apache.org/licenses/LICENSE-2.0).
