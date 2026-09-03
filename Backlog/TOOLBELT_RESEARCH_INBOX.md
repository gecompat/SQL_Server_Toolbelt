# Toolbelt Research Inbox

Breit angelegte, noch ungefilterte Ideensammlung für `gecompat/SQL_Server_Toolbelt`.

Stand der Recherche: 2026-07-30

## Rolle und Status

- Diese Datei ist ein deduplizierter Research-Rohbestand, kein priorisierter Backlog.
- `RI-`-IDs sind stabile Research-Referenzen, aber keine formalen `TC-`-Kandidaten und keine Implementierungsfreigabe.
- Erst nach der gemeinsamen Filterung werden ausgewählte Einträge mit der vollständigen Kandidaten-Vorlage nach `TOOLBELT_CANDIDATES.md` übernommen.
- Mehrere Fundstellen derselben Grundidee wurden zu einem Eintrag verdichtet; alle relevanten Quellen bleiben über die Source-IDs erhalten.
- Aussagen zur konkreten Machbarkeit unter SQL Server 2019, 2022 und 2025 sind, sofern nicht bereits in einem formalen Kandidaten geklärt, ausdrücklich **offen**.
- Performance, Security, Lizenz, Plattformunterstützung und langfristige Wartbarkeit sind vor jeder Formalisierung einzeln zu prüfen.


## Formalisierte und freigegebene Einträge

Die Research-Zeilen bleiben als Herkunft unverändert erhalten. Folgende Ideen wurden
am 2026-07-30 nach gemeinsamer Vertragsbesprechung formalisiert und ausdrücklich
zur Implementierung freigegeben:

| Research-ID | Formaler Kandidat | Status |
|---|---|---|
| `RI-2026-011` | `TC-2026-029` – Sicheres Identifier- und Multipart-Name-Toolkit | `implemented`; Runtime `partially validated` |
| `RI-2026-075` | `TC-2026-030` – Semantic-Version Parser und Comparator | `implemented`; Runtime `partially validated` |
| `RI-2026-055` | `TC-2026-031` – Ganzzahlen in frei definierbaren Zahlensystemen | `implemented`; Runtime `partially validated` |
| `RI-2026-112` | `TC-2026-033` – ZIP Directory Listing | `implemented`; Runtime `partially validated` |
| `RI-2026-113` | `TC-2026-034` – ZIP-Archive kontrolliert extrahieren und erzeugen | `implemented`; Runtime `partially validated`; ZIP-Erzeugung und vollständige Dateisystemextraktion offen |
| `RI-2026-107` | `TC-2026-037` – Kontrolliertes Lesen und Schreiben von Text- und Binärdateien | `implemented`; beide vorhandenen Module Runtime `partially validated`; optionale portable Worker-Slices offen |
| `RI-2026-108` | `TC-2026-038` – Kontrolliertes Directory Listing | `implemented`; Windows-Provider Runtime `partially validated`; portabler Provider offen |
| `RI-2026-139` | `TC-2026-046` – Provider-Abstraktion für kontrollierte zweite SQL-Sessions | `implemented`; synchroner Second-Session-Slice Runtime `partially validated`; breitere Providerabstraktion `researched` |
| `RI-2026-163` | `TC-2026-019` – Execution Context und Correlation | `implemented`; Runtime `partially validated` |

## Bereits vorhandene Kandidaten – zusätzliche Fundstellen

Diese Treffer erzeugen bewusst keine Duplikate.

| Bestehender Kandidat | Ergänzende Perspektive | Quellen |
|---|---|---|
| `TC-2026-002` Kalendarische Differenz | PostgreSQL `age` und andere Date/Time-Verträge als Semantikvergleich | `SRC-PG-FUNCTIONS` |
| `TC-2026-005` Date/Time-Bucketing | `width_bucket`, BigQuery `RANGE_BUCKET` und dbt-Periodenbildung als Varianten mit festen oder frei definierten Grenzen | `SRC-PG-MATH`, `SRC-BQ-CONVERSION`, `SRC-DBT-UTILS` |
| `TC-2026-006` Zahlenreihen | dbt-utils `generate_series` und `date_spine` als Cross-database-Vertragsvergleich | `SRC-DBT-UTILS` |
| `TC-2026-009` JSON-Konstruktion und Pfadprüfung | PostgreSQL SQL/JSON und die aktuelle SQL-Server-JSON-Funktionsfamilie | `SRC-PG-JSON`, `SRC-SQLSERVER-JSON` |
| `TC-2026-010` Regex | DuckDB Pattern Matching sowie PostgreSQL- und DuckDB-Textfunktionen als Semantikvergleich | `SRC-DUCKDB-PATTERN`, `SRC-PG-FUNCTIONS`, `SRC-DUCKDB-TEXT` |
| `TC-2026-011` Fuzzy Matching | PostgreSQL `pg_trgm` und DuckDB Hamming-/Jaccard-/Jaro-Varianten | `SRC-PG-TRGM`, `SRC-DUCKDB-TEXT` |
| `TC-2026-012` Base64 | RFC 4648 definiert zusätzlich Base16, Base32, Base32hex und Base64url samt kanonischer Kodierung | `SRC-RFC4648` |
| `TC-2026-013` JSON-Aggregate | PostgreSQL- und Snowflake-Array-/JSON-Aggregate als zusätzlicher Vertragsvergleich | `SRC-PG-JSON`, `SRC-SNOWFLAKE-FUNCTIONS` |

## 1. Core, Metadaten, DDL und relationale Helfer

| ID | Verdichtete Idee | Nutzen und offene Abgrenzung | Quellen |
|---|---|---|---|
| `RI-2026-001` | Objekt-Clone-Framework | Tabellen samt Indizes, Constraints, Triggern, Defaults und optional Identity kontrolliert kopieren; Namensbildung und Dependency-Reihenfolge sind Kernfragen. | `SRC-PERSONAL`, `SRC-SNOWFLAKE-FUNCTIONS` |
| `RI-2026-002` | Schema-Diff und Migrationsplan | Zwei Tabellen- oder Schemazustände vergleichen und einen überprüfbaren, möglichst nicht destruktiven Änderungsplan erzeugen. | `SRC-DBT-UTILS`, `SRC-SNOWFLAKE-FUNCTIONS` |
| `RI-2026-003` | Kanonisches `GET_DDL` | Reproduzierbares DDL für Tabellen, Views, Constraints, Indizes und weitere Objekte erzeugen, ohne SMO zwingend vorauszusetzen. | `SRC-SNOWFLAKE-FUNCTIONS`, `SRC-PG-FUNCTIONS` |
| `RI-2026-004` | Dependency-Graph und topologische Reihenfolge | Objekt- oder Datenabhängigkeiten als DAG ermitteln, Zyklen markieren und Create/Drop/Load-Reihenfolgen ableiten. | `SRC-PG-FUNCTIONS`, `SRC-DATAFUSION` |
| `RI-2026-005` | `union_relations` nach Spaltennamen | Tabellen mit abweichender Spaltenreihenfolge oder Teilmengen sicher vereinigen und Datentypen kontrolliert harmonisieren. | `SRC-DBT-UTILS`, `SRC-DUCKDB-FUNCTIONS` |
| `RI-2026-006` | Dynamischer Pivot/Unpivot | Werte- und Spaltenlisten sicher ableiten, Identifier validieren und reproduzierbares Pivot-/Unpivot-SQL erzeugen. | `SRC-DBT-UTILS`, `SRC-PG-CONTRIB` |
| `RI-2026-007` | Deduplizierungs-Framework | Duplikatgruppen über konfigurierbare Partitionierung erkennen und anhand einer expliziten Ranking-Regel genau einen Gewinner bestimmen. | `SRC-DBT-UTILS` |
| `RI-2026-008` | Kanonischer Surrogate Key | Mehrere typisierte Werte einschließlich `NULL`, Leerstring, Collation und Datentypgrenzen kollisionsarm kanonisieren und hashen. | `SRC-DBT-UTILS`, `SRC-SQLSERVER-HASHBYTES`, `SRC-JCS` |
| `RI-2026-009` | Tabellen-Fingerprint | Reihenfolgeunabhängigen Fingerprint über Schema oder Datenmengen berechnen; exakte und probabilistische Varianten trennen. | `SRC-SNOWFLAKE-FUNCTIONS`, `SRC-HLL`, `SRC-JCS` |
| `RI-2026-010` | Zeilen-Diff mit fachlichem Schlüssel | Insert/Update/Delete-Kandidaten zwischen zwei Rowsets inklusive Spaltenunterschieden ausgeben, ohne Änderungen auszuführen. | `SRC-DBT-UTILS` |
| `RI-2026-011` | Sicheres Identifier- und Multipart-Name-Toolkit | Ein- bis vierteilige SQL-Namen parsen, normalisieren, quoten und gegen unerlaubte Bestandteile prüfen. | `SRC-ORACLE-DBMS-ASSERT`, `SRC-SQLSERVER-JSON` |
| `RI-2026-012` | Dry-run-DML-Generator | Aus einem Delta reproduzierbare parametrisierte DML-Vorschläge erzeugen; niemals ungeprüft ausführen. | `SRC-DATAFUSION`, `SRC-DBT-UTILS` |
| `RI-2026-013` | Constraint- und Index-Namensgenerator | Eindeutige, deterministische Namen aus Objektrolle und Bestand ableiten; maximale Identifierlänge beachten. | `SRC-PERSONAL` |
| `RI-2026-014` | Relationaler `star`-/Spaltenprojektions-Generator | Include-/Exclude-Listen, Präfixe, Aliase und stabile Spaltenreihenfolge aus Metadaten erzeugen. | `SRC-DBT-UTILS` |
| `RI-2026-015` | Generischer Key-Value-/Map-Adapter | Rowsets, JSON-Objekte und Key-Value-Paare verlustarm ineinander überführen; doppelte Keys explizit behandeln. | `SRC-DUCKDB-MAP`, `SRC-PG-JSON` |
| `RI-2026-016` | Hierarchie- und Pfadoperationen | Materialized Paths und `hierarchyid` kontrolliert verarbeiten, Vorfahren/Nachfahren bestimmen, Pfade normalisieren sowie Zyklen und maximale Traversal-Tiefe explizit behandeln. | `SRC-PG-CONTRIB`, `SRC-SQLSERVER-HIERARCHYID` |
| `RI-2026-017` | Range-/Interval-Algebra | Überlappung, Enthaltensein, Schnitt, Differenz, Vereinigung und Lücken für numerische und zeitliche Intervalle vereinheitlichen. | `SRC-PG-RANGES` |
| `RI-2026-018` | Dynamischer Crosstab mit Vertrag | PostgreSQL `tablefunc` als Inspiration für einen klar begrenzten, typisierten Crosstab-Provider prüfen. | `SRC-PG-CONTRIB` |
| `RI-2026-019` | Resultset-Vertrag introspektieren | Metadaten eines Statements oder einer Procedure in ein stabiles maschinenlesbares Schema überführen und gegen Erwartungen vergleichen. | `SRC-SQLSERVER-OPENROWSET`, `SRC-DUCKDB-FUNCTIONS` |
| `RI-2026-020` | Objekt-Herkunft und Deployment-Fingerprint | Toolbelt-eigene Objekte, Release-Zugehörigkeit und erwartete Definition zuverlässig identifizieren, ohne fremde Objekte zu beanspruchen. | `SRC-JCS`, `SRC-SQLSERVER-HASHBYTES` |
| `RI-2026-163` | Standardisierte Session-Context-Helfer | Benannte Schlüssel für Correlation, Actor und Tenant kontrolliert setzen, lesen und optional schreibschützen; Ownership, Connection Pooling, `NULL`, Typen und RLS-Nutzung vom allgemeinen Logging trennen. | `SRC-SQLSERVER-SESSION-CONTEXT`, `SRC-SQLSERVER-RLS` |
| `RI-2026-164` | Reservierung von Sequence-Ranges | `sys.sp_sequence_get_range` hinter einem typisierten Vertrag für Reservierung, Metadaten, Berechtigungen, Cycling und Erschöpfung kapseln; Protokollierung bleibt eine getrennte optionale Capability. | `SRC-SQLSERVER-SEQUENCE-RANGE` |
| `RI-2026-165` | Read-only Schema- und Objektintrospektion | Spalten, Types, Module und deklarierte Dependencies als stabile Rowsets für Generatoren und Dokumentation bereitstellen; Metadatasichtbarkeit, unaufgelöste Referenzen und Cross-database-Grenzen ausdrücklich ausweisen. | `SRC-SQLSERVER-CATALOG`, `SRC-SQLSERVER-DEPENDENCIES` |
| `RI-2026-166` | Sichere Dynamic-SQL-Primitiven | Objekt-/Spaltenexistenz, zulässige Sortierlisten und bereits gequotete Identifier als kleine validierende Primitive kapseln; keine allgemeine SQL-Erzeugung und keine freie Ausdruckssyntax. | `SRC-SQLSERVER-CATALOG`, `SRC-ORACLE-DBMS-ASSERT` |

## 2. Text, Unicode und Interoperabilität

| ID | Verdichtete Idee | Nutzen und offene Abgrenzung | Quellen |
|---|---|---|---|
| `RI-2026-021` | Unicode-Normalisierung NFC/NFD/NFKC/NFKD | Kanonisch oder kompatibel äquivalente Zeichenfolgen vor Vergleich, Hashing oder Austausch normalisieren. | `SRC-UAX15`, `SRC-ICU-NORMALIZATION` |
| `RI-2026-022` | Grapheme-aware Länge, Substring und Reverse | Benutzerwahrgenommene Zeichen statt UTF-16-Code-Units verarbeiten; Emoji- und Combining-Mark-Fälle einschließen. | `SRC-UAX29` |
| `RI-2026-023` | Unicode Word-/Sentence-Segmentierung | Text anhand definierter Unicode-Grenzen in Wörter und Sätze zerlegen. | `SRC-UAX29` |
| `RI-2026-024` | Unicode Case Folding | Locale-unabhängige case-insensitive Vergleichsschlüssel erzeugen; nicht mit einfachem `LOWER` verwechseln. | `SRC-ICU-CASE` |
| `RI-2026-025` | Transliteration zwischen Schriftsystemen | Beispielsweise griechische oder kyrillische Schrift regelbasiert in lateinische Darstellung überführen. | `SRC-ICU-TRANSFORMS` |
| `RI-2026-026` | Diakritika-/Akzent-Entfernung | Explizite, dokumentierte Transformationsfunktion statt impliziter Collation-Nebeneffekte. | `SRC-PG-CONTRIB`, `SRC-ICU-TRANSFORMS` |
| `RI-2026-027` | Slug- und Identifier-Normalisierung | Unicode-Normalisierung, Transliteration, Whitespace- und Zeichenregeln zu einem konfigurierbaren Slug-Vertrag kombinieren. | `SRC-UAX15`, `SRC-ICU-TRANSFORMS`, `SRC-RFC3986` |
| `RI-2026-028` | Natural Sort Key | Gemischte Text-/Zahlenfolgen so sortieren, dass numerische Segmente numerisch statt lexikalisch verglichen werden. | `SRC-DUCKDB-TEXT`, `SRC-ICU-CASE` |
| `RI-2026-029` | N-Gram-/Trigram-Toolkit | Tokens erzeugen, Ähnlichkeit berechnen und optional suchbare persistierte Hilfswerte definieren. | `SRC-PG-TRGM`, `SRC-DUCKDB-TEXT` |
| `RI-2026-030` | Phonetische Schlüssel-Familie | Soundex-Erweiterungen, Metaphone und Daitch-Mokotoff als klar getrennte sprachabhängige Provider prüfen. | `SRC-PG-CONTRIB` |
| `RI-2026-031` | URI Parser/Builder/Normalizer | Scheme, Authority, Host, Port, Path, Query und Fragment nach RFC 3986 zerlegen und wieder zusammensetzen. | `SRC-RFC3986` |
| `RI-2026-032` | URL Query-String Toolkit | Prozentkodierung, mehrfach vorkommende Parameter, leere Werte und stabile Reihenfolge verarbeiten. | `SRC-RFC3986` |
| `RI-2026-033` | Punycode/IDN-Konvertierung | Unicode-Domainlabels reversibel in ASCII-kompatible Form überführen; Spoofing-Risiken dokumentieren. | `SRC-RFC3492` |
| `RI-2026-034` | RFC- und HTML-Escape/Unescape-Familie | URL-, HTML-, XML-, JSON-, CSV- und Quoted-Printable-Escaping als getrennte, nicht austauschbare Verträge anbieten. | `SRC-RFC3986`, `SRC-RFC4180`, `SRC-PG-JSON` |
| `RI-2026-035` | Human-readable Größen parsen/formatieren | Byteangaben mit SI- und IEC-Präfixen eindeutig umrechnen; Rundung und Groß-/Kleinschreibung definieren. | `SRC-UCUM` |
| `RI-2026-036` | Word Wrap und Line Breaking | Harte und weiche Umbrüche unter Unicode-Regeln, maximaler Breite und Einrückung behandeln. | `SRC-UAX29`, `SRC-ICU-TRANSFORMS` |
| `RI-2026-037` | Volltext-Helfer außerhalb des Indexvertrags | Tokenisierung, Stopword-Listen, Stemming-Konfiguration und Highlighting als vorbereitende Utilities prüfen. | `SRC-DUCKDB-FTS`, `SRC-PG-FUNCTIONS` |
| `RI-2026-038` | Diff/Patch für Text | Zeilen- oder tokenbasierte Differenz mit strukturiertem Resultset, optional Patch-Anwendung. | `SRC-DATAFUSION` |
| `RI-2026-039` | Template Rendering mit strikt begrenzter Syntax | Platzhalter, Escaping und Missing-Value-Strategie ohne allgemeine Codeausführung definieren. | `SRC-DBT-UTILS` |
| `RI-2026-040` | Formatstring- und Platzhalter-Validator | Templates vor Ausführung auf unbekannte, doppelte oder unescaped Platzhalter prüfen. | `SRC-DBT-UTILS` |
| `RI-2026-167` | Resultset-Renderer für HTML und Markdown | Typisierte Rowsets mit stabiler Spaltenreihenfolge, `NULL`-, Längen- und Escaping-Regeln als HTML-Tabelle oder Markdown-Tabelle ausgeben; Mailversand, Persistenz und fachliche Reports bleiben außerhalb des Kernvertrags. | `SRC-SQLSERVER-FOR-XML` |

## 3. JSON, XML und semistrukturierte Daten

| ID | Verdichtete Idee | Nutzen und offene Abgrenzung | Quellen |
|---|---|---|---|
| `RI-2026-041` | JSON Pointer | Werte über einen standardisierten Pointer adressieren, Pointer validieren und Tokens korrekt escapen. | `SRC-RFC6901` |
| `RI-2026-042` | JSON Patch anwenden | RFC-6902-Operationen `add`, `remove`, `replace`, `move`, `copy`, `test` kontrolliert ausführen. | `SRC-RFC6902`, `SRC-RFC6901` |
| `RI-2026-043` | JSON Patch erzeugen | Aus zwei Dokumenten eine nachvollziehbare Patch-Sequenz erzeugen; Minimalität ist optional und gesondert zu bewerten. | `SRC-RFC6902` |
| `RI-2026-044` | JSON Merge Patch | Objektorientierte Teiländerungen nach RFC 7396 anwenden; besondere `null`-Semantik klar dokumentieren. | `SRC-RFC7396` |
| `RI-2026-045` | JSON Deep Merge mit Policies | Array-, `null`-, Duplicate-Key- und Typkonflikte über explizite Strategien steuern. | `SRC-PG-JSON`, `SRC-ORACLE-JSON-TRANSFORM` |
| `RI-2026-046` | JSON Flatten/Unflatten | Verschachtelte Dokumente in Pfad-/Wertzeilen überführen und bei eindeutiger Semantik rekonstruieren. | `SRC-SNOWFLAKE-FUNCTIONS`, `SRC-PG-JSON` |
| `RI-2026-047` | JSON Canonicalization | Hash- und Signatur-fähige deterministische JSON-Repräsentation nach JCS erzeugen. | `SRC-JCS`, `SRC-SQLSERVER-HASHBYTES` |
| `RI-2026-048` | JSON Schema Validation | JSON gegen Draft 2020-12 prüfen und strukturierte Fehlerpfade ausgeben; CLR/externer Provider wahrscheinlich. | `SRC-JSON-SCHEMA` |
| `RI-2026-049` | JSON Schema aus Rowset-Metadaten | Ein begrenztes Schema aus SQL-Datentypen, Nullability und bekannten Constraints ableiten. | `SRC-JSON-SCHEMA`, `SRC-SQLSERVER-JSON` |
| `RI-2026-050` | Schema-gesteuerte JSON-zu-Rowset-Projektion | Explizites Schema, Conversion-Fehler, Missing Keys und unbekannte Properties kontrolliert behandeln. | `SRC-PG-JSON`, `SRC-SQLSERVER-JSON` |
| `RI-2026-051` | JSON Key Rename/Move/Copy Batch | Mehrere Pfadoperationen atomar und in definierter Reihenfolge ausführen. | `SRC-ORACLE-JSON-TRANSFORM`, `SRC-RFC6902` |
| `RI-2026-052` | XML Canonicalization und Fingerprint | Semantisch äquivalente XML-Repräsentationen für Hashing/Signatur vorbereiten; Namespace- und Kommentarregeln beachten. | `SRC-W3C-XML-C14N`, `SRC-SQLSERVER-HASHBYTES` |
| `RI-2026-053` | XML Diff/Patch | Elemente, Attribute, Text und Namespaces strukturiert vergleichen; XPath-Adressierung und Reihenfolge explizit definieren. | `SRC-W3C-XML-C14N` |
| `RI-2026-054` | YAML/TOML-Konfigurationsadapter | Kleine Konfigurationsdokumente sicher lesen und nach JSON projizieren; Parser, Lizenz und untrusted-input-Risiken prüfen. | `SRC-DATAFUSION`, `SRC-DUCKDB-FUNCTIONS` |

## 4. Identifier, Encodings, Validierung und Kryptografie-nahe Utilities

| ID | Verdichtete Idee | Nutzen und offene Abgrenzung | Quellen |
|---|---|---|---|
| `RI-2026-055` | Ganzzahlen in frei definierbaren Zahlensystemen | Positive und negative Integer mit frei definierbarem Alphabet kodieren/dekodieren; Base 2 bis mindestens Base 36. | `SRC-PERSONAL`, `SRC-RFC4648` |
| `RI-2026-056` | Base32 und Base32hex | Binärdaten standardkonform einschließlich Padding und strikter Fehlerprüfung kodieren/dekodieren. | `SRC-RFC4648` |
| `RI-2026-057` | Base58 und Base58Check | Menschlich robuster Identifier ohne leicht verwechselbare Zeichen; Varianten dürfen nicht stillschweigend vermischt werden. | `SRC-BITCOIN-BASE58` |
| `RI-2026-058` | UUID v3/v5 | Deterministische namespace-basierte UUIDs mit klarer Byteorder und Normalisierung erzeugen. | `SRC-RFC9562` |
| `RI-2026-059` | UUID v6/v7/v8 | Zeitlich sortierbare und benutzerdefinierte UUID-Varianten prüfen; Monotonie, Entropie und `uniqueidentifier`-Sortierung getrennt testen. | `SRC-RFC9562` |
| `RI-2026-060` | ULID | Lexikographisch sortierbare 128-Bit-Identifier als Alternative vergleichen; Monotonie und Collation prüfen. | `SRC-ULID` |
| `RI-2026-061` | CRC32/CRC32C | Schnelle Integritätsprüfung für Streams und Dateiblöcke; Polynom und Variante sind Teil des Vertrags, beide Verfahren sind ausdrücklich nicht kryptografisch. | `SRC-ZIP-SPEC`, `SRC-RFC3720` |
| `RI-2026-062` | xxHash | Sehr schneller nicht kryptografischer Hash für Fingerprints und Partitionierung; Kollisionen und Portabilität dokumentieren. | `SRC-XXHASH` |
| `RI-2026-063` | BLAKE3 | Moderner kryptografischer Hash mit Streaming- und Parallelisierungsoptionen; CLR oder externer Provider. | `SRC-BLAKE3`, `SRC-SQLSERVER-HASHBYTES` |
| `RI-2026-064` | HMAC-Helfer | HMAC-SHA-256/512 mit expliziter Key-Verwaltung; Secrets niemals speichern oder debuggen. | `SRC-RFC4226`, `SRC-SQLSERVER-HASHBYTES` |
| `RI-2026-065` | JWT lesen und validieren | Header/Claims dekodieren und Signaturen mit Allowlist validieren; unsigniertes Dekodieren nie als Validierung darstellen. | `SRC-RFC7519`, `SRC-RFC4648` |
| `RI-2026-066` | HOTP/TOTP | Standardisierte OTP-Berechnung primär als Interoperabilitäts-/Testutility; Secret- und Timing-Risiken streng begrenzen. | `SRC-RFC4226`, `SRC-RFC6238` |
| `RI-2026-067` | Hexdump und Binärinspektion | Offset, Hexbytes, ASCII/Unicode-Ansicht und begrenzte Segmentierung für Diagnose von Binärformaten. | `SRC-RFC4648` |
| `RI-2026-068` | Endian- und Bit-Packing-Toolkit | Integer, GUID und Binärfelder kontrolliert in Big-/Little-Endian lesen und schreiben. | `SRC-RFC9562`, `SRC-ARROW` |
| `RI-2026-069` | Encoding-/BOM-Erkennung | BOM sicher erkennen; heuristische Charset-Erkennung ausdrücklich als Vermutung mit Confidence ausgeben. | `SRC-SQLSERVER-OPENROWSET`, `SRC-UNICODE` |
| `RI-2026-070` | Text-Encoding-Konvertierung | UTF-8, UTF-16 und ausgewählte Windows-Codepages mit klarer Fehlerstrategie konvertieren. | `SRC-UNICODE`, `SRC-SQLSERVER-OPENROWSET` |
| `RI-2026-071` | Generisches Check-Digit-Framework | Gewichtung, Modulus und Zeichensatz parametrierbar machen; nur geprüfte Profile als benannte Provider freigeben. | `SRC-ISO7064`, `SRC-GS1` |
| `RI-2026-072` | GS1/GTIN/GLN-Prüfziffern | Standardisierte GS1-Schlüssel berechnen und formell prüfen, ohne Existenz eines Artikels oder Unternehmens zu behaupten. | `SRC-GS1` |
| `RI-2026-073` | IBAN Struktur- und Prüfsummenprüfung | Formatregistry und MOD-97 prüfen; weder Kontoexistenz noch Kontoinhaber ableiten. | `SRC-SWIFT-IBAN`, `SRC-ISO7064` |
| `RI-2026-074` | Luhn, Verhoeff und Damm | Häufige Prüfzifferverfahren als getrennte Provider mit Testvektoren und klarer Nicht-Kryptografie-Kennzeichnung; vor Formalisierung ist je Algorithmus die Primärquelle festzulegen. | `SRC-ISO7064` |
| `RI-2026-075` | Semantic-Version Parser/Comparator | SemVer 2.0.0 einschließlich Pre-release und Build Metadata validieren, vergleichen und sortierbare Komponenten ausgeben. | `SRC-SEMVER` |
| `RI-2026-076` | Safe Cast mit Fehlerdetails | Statt Abbruch `success`, Zieltyp, normalisierter Wert und begrenzter Fehlergrund liefern; nicht bloß `TRY_CONVERT` umbenennen. | `SRC-BQ-CONVERSION` |
| `RI-2026-077` | IP/CIDR Parser und Range-Algebra | IPv4/IPv6 normalisieren, Prefix-Grenzen berechnen und Enthaltensein prüfen; Netzwerkzugriff bleibt außerhalb des Scopes. | `SRC-RFC4291`, `SRC-RFC4632` |
| `RI-2026-078` | E-Mail-/Mailbox-Syntaxprüfung | Syntax und Normalisierung bewusst von Zustellbarkeit trennen; Unicode-/IDN-Regeln berücksichtigen. | `SRC-RFC5321`, `SRC-RFC5322`, `SRC-RFC6531` |

## 5. Datum/Zeit, Mathematik, Statistik und probabilistische Datenstrukturen

| ID | Verdichtete Idee | Nutzen und offene Abgrenzung | Quellen |
|---|---|---|---|
| `RI-2026-079` | Date Spine und Kalenderdimension | Datums-/Zeitpunkte für Tag, Woche, Monat oder Quartal mit frei wählbarem Schritt erzeugen; optional Periodenanfang/-ende, Jahr, Monat, ISO-Woche und Quartal ausgeben. | `SRC-DBT-UTILS`, `SRC-PG-FUNCTIONS` |
| `RI-2026-080` | Business-Day-/Arbeitskalender-Engine | Wochenenden, benutzergepflegte Feiertage, Teilzeittage und Arbeitszeitfenster trennen; keine eingebaute „ewig aktuelle“ Feiertagswahrheit. | `SRC-RFC5545`, `SRC-CLDR-DATETIME` |
| `RI-2026-081` | Time-Zone-Konvertierung und Provider | Zeitzonen validieren und UTC-/Zonen-Konvertierungen mit `AT TIME ZONE` sowie `sys.time_zone_info` kapseln; DST-Lücken/-Überlappungen testen, IANA- und Windows-Namen kontrolliert abbilden und die Datenversion nachvollziehbar halten. | `SRC-SQLSERVER-TIMEZONE`, `SRC-IANA-TZ`, `SRC-RFC9557` |
| `RI-2026-082` | RFC-3339/IXDTF Parser und Formatter | Internet-Zeitstempel mit Offset und optionaler Time-Zone-Annotation strikt verarbeiten. | `SRC-RFC3339`, `SRC-RFC9557` |
| `RI-2026-083` | iCalendar RRULE expandieren | Wiederholungsregeln in konkrete Occurrences expandieren; Grenzen gegen unendliche oder riesige Folgen erzwingen. | `SRC-RFC5545` |
| `RI-2026-084` | Duration-/Period-Parser | Kalenderperioden und exakte Zeitdauern nicht vermischen; ISO-/iCalendar-nahe Formen getrennt behandeln. | `SRC-RFC5545`, `SRC-RFC3339` |
| `RI-2026-085` | Locale-aware Date/Time Formatting | CLDR-Muster statt eigener Übersetzungstabellen verwenden; Versionsabhängigkeit dokumentieren. | `SRC-CLDR-DATETIME` |
| `RI-2026-086` | `width_bucket` mit festen und freien Grenzen | Gleichbreite Buckets und explizite Grenzarrays als getrennte Varianten. | `SRC-PG-MATH`, `SRC-BQ-CONVERSION` |
| `RI-2026-087` | Median, Mode und gewichtete Quantile | Exakte und approximate Varianten sowie Tie-/NULL-Semantik klar trennen. | `SRC-SNOWFLAKE-FUNCTIONS`, `SRC-BQ-APPROX` |
| `RI-2026-088` | Lineare Regression und Trendparameter | Slope, Intercept, R² und Fehlermaße als mengenorientierte Aggregate prüfen. | `SRC-PG-MATH` |
| `RI-2026-089` | Vektor-Mathematik | Dot Product, Norm, Cosine-, L1- und L2-Distanz versionsübergreifend vergleichen; SQL Server 2025 Native Provider prüfen. | `SRC-DUCKDB-VSS`, `SRC-DUCKDB-FUNCTIONS` |
| `RI-2026-090` | HyperLogLog | Mergebarer probabilistischer Distinct Count mit dokumentierter Fehlerschranke. | `SRC-HLL`, `SRC-SNOWFLAKE-FUNCTIONS` |
| `RI-2026-091` | t-digest | Mergebare approximate Quantile mit guter Tail-Genauigkeit; Serialisierungsformat versionieren. | `SRC-TDIGEST`, `SRC-BQ-APPROX` |
| `RI-2026-092` | Bloom Filter | Speicherarme Membership-Prüfung mit False Positives; Parameter und Hashfamilie Teil des Vertrags. | `SRC-BLOOM` |
| `RI-2026-093` | MinHash/Jaccard Sketch | Große Mengen approximativ auf Ähnlichkeit vergleichen und Sketches kombinieren. | `SRC-SNOWFLAKE-FUNCTIONS` |
| `RI-2026-094` | Approximate Top-K / Heavy Hitters | Häufige Werte per Space-Saving-artigem Sketch mit Fehlergrenzen bestimmen. | `SRC-SPACESAVING`, `SRC-SNOWFLAKE-FUNCTIONS` |
| `RI-2026-095` | Count-Min Sketch | Frequenzschätzung für große Streams; Overestimation und Merge-Vertrag dokumentieren. | `SRC-COUNTMIN` |
| `RI-2026-096` | Reservoir Sampling | Unbekannt lange Ströme mit begrenztem Speicher zufällig sampeln; deterministischer Seed optional. | `SRC-RESERVOIR` |
| `RI-2026-097` | Deterministisches Hash-Sampling | Reproduzierbare Stichprobe anhand stabiler Schlüssel statt Session-Zufall. | `SRC-SQLSERVER-HASHBYTES`, `SRC-DBT-UTILS` |
| `RI-2026-098` | Entropie- und Verteilungsmaße | Shannon-Entropie, Gini, Konzentration und Skewness als Data-Quality-/Testutilities prüfen. | `SRC-PG-MATH`, `SRC-BQ-APPROX` |
| `RI-2026-168` | Temporal-Query-Helfer | Wiederverwendbare, identifier-sichere Oberflächen für Current, `AS OF`, Zeitintervalle und History-Lesezugriffe auf system-versionierte Tabellen prüfen; Retention bleibt eine getrennte administrative Capability. | `SRC-SQLSERVER-TEMPORAL-QUERY`, `SRC-SQLSERVER-TEMPORAL-RETENTION` |

## 6. Geodaten

| ID | Verdichtete Idee | Nutzen und offene Abgrenzung | Quellen |
|---|---|---|---|
| `RI-2026-099` | H3-Zellenindex | Punkt zu H3-Zelle, Nachbarn, Hierarchie und Boundary; native Library/CLR und Lizenz prüfen. | `SRC-H3` |
| `RI-2026-100` | Open Location Code / Plus Codes | Koordinaten offline kodieren/dekodieren, Codes kürzen und mit Referenzpunkt wiederherstellen. | `SRC-OLC` |
| `RI-2026-101` | Geohash | Koordinaten in hierarchischen Stringschlüssel überführen; Genauigkeit und Nachbarschaftsgrenzen klar benennen. | `SRC-OLC`, `SRC-H3` |
| `RI-2026-102` | GeoJSON-Konvertierung | SQL-Spatial-Werte zu GeoJSON-Fragmenten beziehungsweise Features konvertieren und zurücklesen. | `SRC-DUCKDB-SPATIAL`, `SRC-PG-JSON` |
| `RI-2026-103` | Geografisches Jittering | Koordinaten deterministisch oder zufällig innerhalb definierter Distanz verschieben; Re-Identifikationsrisiko dokumentieren. | `SRC-PERSONAL`, `SRC-PRESIDIO` |
| `RI-2026-104` | Grid-/Tile-Bucketing | Punkte in rechteckige, Quadkey- oder hexagonale Zellen einteilen und zwischen Auflösungen wechseln. | `SRC-H3`, `SRC-OLC` |
| `RI-2026-105` | Great-circle-Distanz und Bearing | Distanz, Anfangskurs und Zielpunkt mit eindeutigem Erdmodell berechnen; SQL-Spatial-Native Provider vergleichen. | `SRC-DUCKDB-SPATIAL` |
| `RI-2026-106` | Coordinate Reference Transformation | EPSG-basierte Transformation als externer Spatial-Provider prüfen; eingebettete Referenzdaten versionieren. | `SRC-DUCKDB-SPATIAL` |

## 7. Dateien, Archive, Office und externe Datenformate

| ID | Verdichtete Idee | Nutzen und offene Abgrenzung | Quellen |
|---|---|---|---|
| `RI-2026-107` | Text-/Binärdatei lesen und schreiben | Binary/Text, Encoding, BOM, Offset und maximale Größe kontrollieren; Serverrechte und Plattformgrenzen zentral. | `SRC-PERSONAL`, `SRC-SQLSERVER-OPENROWSET` |
| `RI-2026-108` | Directory Listing | Pfad, Typ, Größe und Zeitstempel auflisten; Root-Allowlist, Symlink/Reparse-Point- und Rechteprüfung erforderlich. | `SRC-PERSONAL`, `SRC-SQLSERVER-OPENROWSET` |
| `RI-2026-109` | RFC-4180-CSV Parser/Writer | Quotes, eingebettete Zeilenumbrüche, Header, Dialekte, Encoding und Streaming behandeln. | `SRC-RFC4180`, `SRC-SQLSERVER-OPENROWSET` |
| `RI-2026-110` | Delimited-/Fixed-width-Datei-Framework | CSV, TSV, frei definierte Delimiter und feste Spaltenbreiten mit gemeinsamem Fehlerresultset. | `SRC-SQLSERVER-OPENROWSET`, `SRC-RFC4180` |
| `RI-2026-111` | JSON Lines Reader/Writer | Ein JSON-Dokument pro Zeile streamen; defekte Zeilen mit Position isolieren. | `SRC-SQLSERVER-OPENROWSET`, `SRC-PG-JSON` |
| `RI-2026-112` | ZIP Directory Listing | Central Directory lesen, Metadaten und verdächtige Pfade melden, ohne Inhalte zu extrahieren. | `SRC-PERSONAL`, `SRC-ZIP-SPEC` |
| `RI-2026-113` | ZIP Extract/Create | Einzeldatei, Stream oder ganzes Archiv unter Schutz gegen Zip Slip, Bomben und Verschlüsselungsvarianten verarbeiten. | `SRC-PERSONAL`, `SRC-ZIP-SPEC` |
| `RI-2026-114` | Gzip Stream/File Adapter | Native `COMPRESS`/`DECOMPRESS` für Werte von vollständigem Gzip-Datei-/Streamvertrag abgrenzen. | `SRC-PERSONAL`, `SRC-SQLSERVER-COMPRESS` |
| `RI-2026-115` | Weitere Kompressionsprovider | Deflate, Brotli, Zstandard, bzip2 und 7z nur als klar getrennte optionale Provider mit Lizenz-/Plattformprüfung. | `SRC-PERSONAL`, `SRC-ZIP-SPEC` |
| `RI-2026-116` | XLSX Reader | ZIP + SpreadsheetML direkt oder über Open XML SDK lesen; Shared Strings, Styles, Formeln und Zelltypen korrekt behandeln. | `SRC-PERSONAL`, `SRC-XLSX`, `SRC-OPENXML-SDK`, `SRC-ZIP-SPEC` |
| `RI-2026-117` | XLSX Writer | Rowsets in valide Workbooks schreiben; Typen, Styles, Sheet-Namen, Limits und Streaming festlegen. | `SRC-XLSX`, `SRC-OPENXML-SDK` |
| `RI-2026-118` | Parquet Reader/Writer | Columnar Encoding, Schema Evolution, Statistics und Compression über externen Provider bereitstellen. | `SRC-PARQUET`, `SRC-ARROW`, `SRC-DATAFUSION` |
| `RI-2026-119` | Arrow IPC Adapter | Rowsets effizient mit Arrow-basierten Tools austauschen; Nullability, Decimal, Timestamp und Dictionary Encoding prüfen. | `SRC-ARROW`, `SRC-DATAFUSION` |
| `RI-2026-120` | Avro/ORC Adapter | Schema- und columnar Formate über austauschbaren externen Provider lesen/schreiben. | `SRC-DATAFUSION`, `SRC-DUCKDB-FUNCTIONS` |
| `RI-2026-121` | Datei-Manifest mit Checksums | Pfad, Größe, Hash, Encoding/Format und erwartete Reihenfolge als überprüfbares Manifest erzeugen. | `SRC-SQLSERVER-HASHBYTES`, `SRC-PARQUET` |
| `RI-2026-122` | Chunking großer BLOBs | Große Binärwerte deterministisch segmentieren, nummerieren, hashen und wieder zusammensetzen. | `SRC-ARROW`, `SRC-SQLSERVER-HASHBYTES` |
| `RI-2026-123` | MIME-/Magic-Format-Erkennung | Dateiendung, Magic Bytes und Inhaltstyp getrennt ausgeben; Erkennung nie als Sicherheitsfreigabe darstellen. | `SRC-ZIP-SPEC`, `SRC-PARQUET`, `SRC-XLSX` |
| `RI-2026-124` | Embedded DuckDB/DataFusion Bridge | SQL Server-Daten oder Dateien kontrolliert an eine lokale analytische Engine übergeben und Resultsets zurückführen. | `SRC-DUCKDB-FUNCTIONS`, `SRC-DATAFUSION` |

## 8. Testdaten, Anonymisierung und Developer Experience

| ID | Verdichtete Idee | Nutzen und offene Abgrenzung | Quellen |
|---|---|---|---|
| `RI-2026-125` | Deterministischer Hash-Lookup | Aus einem stabilen Hash eine Zeile aus einer synthetischen Lookup-Tabelle wählen und referenzielle Konsistenz erhalten. | `SRC-PERSONAL`, `SRC-SQLSERVER-HASHBYTES` |
| `RI-2026-126` | Format-preserving Pseudonymization | Zeichensatz, Länge und optional Prüfziffern erhalten; Pseudonymisierung nicht als Anonymisierung bezeichnen. | `SRC-PERSONAL`, `SRC-PRESIDIO` |
| `RI-2026-127` | Deterministischer Random-Range-Provider | Seed, Schlüssel und Range liefern reproduzierbare Werte für Tests und Masking. | `SRC-PERSONAL`, `SRC-FAKER` |
| `RI-2026-128` | Deterministic Date Shifting | Datum um einen pro Entität stabilen Offset verschieben und zeitliche Abstände optional erhalten. | `SRC-PERSONAL`, `SRC-PRESIDIO` |
| `RI-2026-129` | Shuffle innerhalb definierter Gruppen | Werte zwischen Zeilen permutieren, ohne Werteverteilung zu ändern; seltene Gruppen und Re-Identifikation beachten. | `SRC-PERSONAL`, `SRC-PRESIDIO` |
| `RI-2026-130` | Masking-DSL | Spalten je Datentyp einer benannten Strategie zuordnen; freie Codeausführung ausschließen. | `SRC-PERSONAL`, `SRC-PRESIDIO` |
| `RI-2026-131` | Synthetic Data Generator | Faker-artige Provider für Namen, Adressen, Zeitwerte, IDs und Texte; ausschließlich synthetische Fixtures. | `SRC-FAKER` |
| `RI-2026-132` | Referentially Consistent Synthetic Graph | Mehrere Tabellen mit gültigen PK/FK-Beziehungen, Verteilungen und Randfällen erzeugen. | `SRC-FAKER`, `SRC-DBT-UTILS` |
| `RI-2026-133` | Subset/Clone mit referenzieller Hülle | Aus synthetischen oder ausdrücklich freigegebenen Quellen eine zusammenhängende Teilmenge entlang von FK-Kanten ableiten. | `SRC-PERSONAL`, `SRC-PG-FUNCTIONS` |
| `RI-2026-134` | PII Detection Provider | Presidio-artige Erkennung als optionalen externen Prüfschritt integrieren; False Positives/Negatives explizit ausgeben. | `SRC-PRESIDIO` |
| `RI-2026-135` | Anonymization Verification | Nach Transformation auf Resttreffer, referenzielle Integrität, Formatregeln und erwartete Verteilungen prüfen. | `SRC-PRESIDIO`, `SRC-FAKER` |
| `RI-2026-136` | Property-based SQL Tests | Aus Typen, Constraints und Invarianten automatisch viele synthetische Randfälle erzeugen. | `SRC-FAKER`, `SRC-DBT-UTILS` |
| `RI-2026-137` | Golden-/Snapshot-Resultset-Vergleich | Resultsets kanonisieren und mit einer synthetischen erwarteten Fassung vergleichen; tolerante Felder deklarieren. | `SRC-JCS`, `SRC-DBT-UTILS` |
| `RI-2026-138` | Contract-Test-Generator | Parameter-, Help-, Resultset-, Fehler- und KeepData-Verträge eines Toolbelt-Objekts in Testfälle übersetzen. | `SRC-DBT-UTILS` |
| `RI-2026-139` | Provider-Abstraktion für zweite Sessions | `tSQLt.NewConnection`, Service Broker, SQL Agent oder externe Runner hinter einem Capability-Vertrag vergleichen. | `SRC-PERSONAL` |
| `RI-2026-140` | T-SQL AST Parse/Lint/Rewrite | ScriptDOM-artigen Provider für sichere Identifier-Analyse, DDL-Inspection und begrenzte Transformation einsetzen. Am 2026-09-03 als `TC-2026-047` formalisiert. | `SRC-SCRIPTDOM` |
| `RI-2026-141` | SQL Formatter | Syntaxbaum-basiertes, idempotentes Formatting mit erhaltenen Kommentaren und konfigurierbarem Stil. | `SRC-SCRIPTDOM` |
| `RI-2026-142` | Migration Idempotency Verifier | Deploy/Upgrade/Uninstall wiederholt in synthetischen Zuständen ausführen und Drift strukturiert melden. | `SRC-DBT-UTILS` |

## 9. Host-, Netzwerk- und Service-Provider

Diese Einträge sind besonders sicherheits- und plattformkritisch. Die Research-Aufnahme ist keine Empfehlung zur Aktivierung.

| ID | Verdichtete Idee | Nutzen und offene Abgrenzung | Quellen |
|---|---|---|---|
| `RI-2026-143` | HTTP Client mit Allowlist | REST-Calls mit Host-/Scheme-Allowlist, Timeout, Größenlimit, TLS-Prüfung und redigiertem Logging. | `SRC-PERSONAL`, `SRC-RFC3986` |
| `RI-2026-144` | REST Pagination Adapter | Link-, Cursor-, Offset- und Continuation-Token-Pagination als getrennte Strategien. | `SRC-PERSONAL`, `SRC-RFC3986` |
| `RI-2026-145` | Webhook Emitter | Signierte, idempotente Events mit Retry-Vertrag; Secrets bleiben außerhalb von Repository und Resultsets. | `SRC-RFC7519`, `SRC-RFC4226` |
| `RI-2026-146` | PowerShell Host Provider | Benannte, allowlisted Commands am Host ausführen und strukturierte Resultate zurückgeben; kein freier Scripttext. | `SRC-PERSONAL` |
| `RI-2026-147` | Python Host Provider | Registrierte Python-Work-Types mit typisierten Inputs/Outputs; Environment und Packages versionieren. | `SRC-PERSONAL`, `SRC-DATAFUSION` |
| `RI-2026-148` | AI Chat/Model Provider | Modellaufrufe mit Datenklassifikation, Redaction, Kosten-/Tokenlimit und strukturiertem Output; standardmäßig keine Originaldaten. | `SRC-PERSONAL`, `SRC-PRESIDIO` |
| `RI-2026-149` | Object-Storage Adapter | Azure Blob/S3-kompatible Quellen über benannte Credentials und Prefix-Allowlist lesen/schreiben. | `SRC-SQLSERVER-OPENROWSET`, `SRC-DUCKDB-FUNCTIONS` |
| `RI-2026-150` | Command Capability Registry | Nur registrierte Operationen mit typisierten Parametern ausführen; baut gedanklich auf `TC-2026-022` auf. | `SRC-PERSONAL`, `SRC-DATAFUSION` |

## 10. Bewusst weiter gedachte Kandidaten

| ID | Verdichtete Idee | Nutzen und offene Abgrenzung | Quellen |
|---|---|---|---|
| `RI-2026-151` | Merkle Tree über Rowsets oder Dateien | Teilmengen effizient auf Gleichheit prüfen und beweisbare Hash-Pfade erzeugen; kanonische Serialisierung zwingend. | `SRC-JCS`, `SRC-SQLSERVER-HASHBYTES` |
| `RI-2026-152` | Content-defined Chunking | BLOBs anhand ihres Inhalts statt fixer Offsets segmentieren, um Deduplizierung und Delta-Transfer zu erleichtern. | `SRC-FASTCDC` |
| `RI-2026-153` | SimHash/Locality-sensitive Hashing | Große Text- oder Featuremengen auf Near-Duplicates vorfiltern; False-Positive-Vertrag erforderlich. | `SRC-PG-TRGM`, `SRC-SNOWFLAKE-FUNCTIONS` |
| `RI-2026-154` | Graph-Algorithmen auf Adjazenzlisten | Topological Sort, Connected Components, Shortest Path und Cycle Detection als begrenzte TVF/USP-Familie prüfen. | `SRC-PG-FUNCTIONS`, `SRC-DATAFUSION` |
| `RI-2026-155` | Unit-of-Measure Engine | UCUM-Ausdrücke validieren, Dimensionen vergleichen und kompatible Einheiten umrechnen. | `SRC-UCUM` |
| `RI-2026-156` | Barcode-/QR-Payload-Toolkit | Payloads und Prüfziffern erzeugen/validieren; Bildrendering als separater Provider. | `SRC-GS1`, `SRC-ISO7064` |
| `RI-2026-157` | Compact Binary Serialization | Kleine typisierte Werte in ein versioniertes Binärformat packen und entpacken; Endianness und Schema-ID Teil des Vertrags. | `SRC-ARROW`, `SRC-PARQUET` |
| `RI-2026-158` | Data Sketch Registry | HLL, t-digest, Bloom, MinHash und Top-K über versionierte Header, Merge- und Estimate-Verträge verwalten. | `SRC-HLL`, `SRC-TDIGEST`, `SRC-BLOOM`, `SRC-SNOWFLAKE-FUNCTIONS` |
| `RI-2026-159` | Reversible Token-Vault-Abstraktion | Originalwerte ausschließlich außerhalb des Toolbelt-Kerns speichern; SQL erhält nur stabile Tokens und Providervertrag. | `SRC-PRESIDIO`, `SRC-RFC7519` |
| `RI-2026-160` | Event-Sourcing-Helfer | Kanonische Event-Hülle, Sequenz, Idempotency Key und Snapshot-Grenzen definieren, ohne eine vollständige Plattform zu bauen. | `SRC-JCS`, `SRC-RFC9562` |
| `RI-2026-161` | Datenvertrag als maschinenlesbares Manifest | Spalten, Typen, Nullability, Semantik, Klassifikation und Compatibility-Regeln versionieren und gegen Rowsets prüfen. | `SRC-JSON-SCHEMA`, `SRC-SEMVER`, `SRC-ARROW` |
| `RI-2026-162` | Reproduzierbarer Randomness-Service | Seedable Random Streams für Tests, Sampling und Masking mit expliziter Nicht-Kryptografie-Abgrenzung. | `SRC-FAKER`, `SRC-PG-MATH` |

## Source-Katalog

Alle Links sind öffentlich zugängliche technische Quellen. Externe Projekte sind Inspiration und Vergleichsmaßstab; ihre Nennung ist keine Dependency- oder Lizenzentscheidung.

| Source-ID | Öffentliche Quelle |
|---|---|
| `SRC-PERSONAL` | [Backlog/personal_Backlog_Bainstorm.md](./personal_Backlog_Bainstorm.md) |
| `SRC-DBT-UTILS` | [dbt-labs/dbt-utils – Utility macros](https://github.com/dbt-labs/dbt-utils) |
| `SRC-PG-CONTRIB` | [PostgreSQL – Additional Supplied Modules and Extensions](https://www.postgresql.org/docs/current/contrib.html) |
| `SRC-PG-FUNCTIONS` | [PostgreSQL – Functions and Operators](https://www.postgresql.org/docs/current/functions.html) |
| `SRC-PG-MATH` | [PostgreSQL – Mathematical Functions and Operators](https://www.postgresql.org/docs/current/functions-math.html) |
| `SRC-PG-JSON` | [PostgreSQL – JSON Functions and Operators](https://www.postgresql.org/docs/current/functions-json.html) |
| `SRC-PG-RANGES` | [PostgreSQL – Range Types](https://www.postgresql.org/docs/current/rangetypes.html) |
| `SRC-PG-TRGM` | [PostgreSQL – pg_trgm](https://www.postgresql.org/docs/current/pgtrgm.html) |
| `SRC-DUCKDB-FUNCTIONS` | [DuckDB – Function Overview](https://duckdb.org/docs/lts/sql/functions/overview.html) |
| `SRC-DUCKDB-TEXT` | [DuckDB – Text Functions](https://duckdb.org/docs/lts/sql/functions/text.html) |
| `SRC-DUCKDB-PATTERN` | [DuckDB – Pattern Matching](https://duckdb.org/docs/lts/sql/functions/pattern_matching.html) |
| `SRC-DUCKDB-MAP` | [DuckDB – Map Functions](https://duckdb.org/docs/lts/sql/functions/map.html) |
| `SRC-DUCKDB-SPATIAL` | [DuckDB – Spatial Functions](https://duckdb.org/docs/current/core_extensions/spatial/functions.html) |
| `SRC-DUCKDB-FTS` | [DuckDB – Full-Text Search Extension](https://duckdb.org/docs/current/core_extensions/full_text_search.html) |
| `SRC-DUCKDB-VSS` | [DuckDB – Vector Similarity Search Extension](https://duckdb.org/docs/current/core_extensions/vss.html) |
| `SRC-SNOWFLAKE-FUNCTIONS` | [Snowflake – All Functions](https://docs.snowflake.com/en/sql-reference/functions-all) |
| `SRC-BQ-APPROX` | [BigQuery – Approximate Aggregate Functions](https://docs.cloud.google.com/bigquery/docs/reference/standard-sql/approximate_aggregate_functions) |
| `SRC-BQ-CONVERSION` | [BigQuery – Conversion Functions](https://docs.cloud.google.com/bigquery/docs/reference/standard-sql/conversion_functions) |
| `SRC-ORACLE-JSON-TRANSFORM` | [Oracle – JSON_TRANSFORM](https://docs.oracle.com/en/database/oracle/oracle-database/21/adjsn/oracle-sql-function-json_transform.html) |
| `SRC-ORACLE-DBMS-ASSERT` | [Oracle – DBMS_ASSERT](https://docs.oracle.com/en/database/oracle/oracle-database/21/arpls/DBMS_ASSERT.html) |
| `SRC-RFC9562` | [RFC 9562 – UUIDs](https://www.rfc-editor.org/info/rfc9562/) |
| `SRC-RFC4648` | [RFC 4648 – Base-N Encodings](https://www.rfc-editor.org/info/rfc4648/) |
| `SRC-RFC3986` | [RFC 3986 – URI Generic Syntax](https://www.rfc-editor.org/info/rfc3986/) |
| `SRC-RFC4180` | [RFC 4180 – CSV](https://www.rfc-editor.org/info/rfc4180/) |
| `SRC-RFC3492` | [RFC 3492 – Punycode](https://datatracker.ietf.org/doc/html/rfc3492) |
| `SRC-RFC3720` | [RFC 3720 – iSCSI mit CRC32C-Spezifikation](https://www.rfc-editor.org/rfc/rfc3720.html) |
| `SRC-RFC4291` | [RFC 4291 – IPv6 Addressing Architecture](https://www.rfc-editor.org/rfc/rfc4291.html) |
| `SRC-RFC4632` | [RFC 4632 – Classless Inter-domain Routing](https://www.rfc-editor.org/rfc/rfc4632.html) |
| `SRC-RFC5321` | [RFC 5321 – SMTP](https://www.rfc-editor.org/rfc/rfc5321.html) |
| `SRC-RFC5322` | [RFC 5322 – Internet Message Format](https://www.rfc-editor.org/rfc/rfc5322.html) |
| `SRC-RFC6531` | [RFC 6531 – Internationalized Email](https://www.rfc-editor.org/info/rfc6531/) |
| `SRC-RFC6901` | [RFC 6901 – JSON Pointer](https://www.rfc-editor.org/info/rfc6901/) |
| `SRC-RFC6902` | [RFC 6902 – JSON Patch](https://www.rfc-editor.org/info/rfc6902/) |
| `SRC-RFC7396` | [RFC 7396 – JSON Merge Patch](https://datatracker.ietf.org/doc/html/rfc7396) |
| `SRC-JCS` | [RFC 8785 – JSON Canonicalization Scheme](https://www.rfc-editor.org/info/rfc8785/) |
| `SRC-RFC7519` | [RFC 7519 – JSON Web Token](https://datatracker.ietf.org/doc/html/rfc7519) |
| `SRC-RFC4226` | [RFC 4226 – HOTP](https://www.rfc-editor.org/info/rfc4226/) |
| `SRC-RFC6238` | [RFC 6238 – TOTP](https://www.rfc-editor.org/info/rfc6238/) |
| `SRC-RFC3339` | [RFC 3339 – Internet Timestamps](https://www.rfc-editor.org/info/rfc3339/) |
| `SRC-RFC9557` | [RFC 9557 – Internet Extended Date/Time Format](https://datatracker.ietf.org/doc/rfc9557/) |
| `SRC-RFC5545` | [RFC 5545 – iCalendar](https://datatracker.ietf.org/doc/html/rfc5545) |
| `SRC-UAX15` | [Unicode UAX #15 – Normalization Forms](https://unicode.org/reports/tr15/) |
| `SRC-UAX29` | [Unicode UAX #29 – Text Segmentation](https://www.unicode.org/reports/tr29/) |
| `SRC-UNICODE` | [The Unicode Standard](https://www.unicode.org/versions/latest/) |
| `SRC-ICU-CASE` | [ICU – Case Mappings](https://unicode-org.github.io/icu/userguide/transforms/casemappings.html) |
| `SRC-ICU-TRANSFORMS` | [ICU – General Transforms](https://unicode-org.github.io/icu/userguide/transforms/general/) |
| `SRC-ICU-NORMALIZATION` | [ICU – Normalization](https://unicode-org.github.io/icu/userguide/transforms/normalization/) |
| `SRC-CLDR-DATETIME` | [Unicode CLDR – Date & Time](https://cldr.unicode.org/translation/date-time) |
| `SRC-IANA-TZ` | [IANA Time Zone Database](https://www.iana.org/time-zones) |
| `SRC-H3` | [H3 – Geospatial Indexing System](https://h3geo.org/docs/) |
| `SRC-OLC` | [Google Open Location Code](https://github.com/google/open-location-code) |
| `SRC-PRESIDIO` | [Presidio – Data Protection and De-identification SDK](https://github.com/data-privacy-stack/presidio) |
| `SRC-FAKER` | [Faker – Synthetic Data](https://faker.readthedocs.io/) |
| `SRC-PARQUET` | [Apache Parquet – File Format](https://parquet.apache.org/docs/file-format/) |
| `SRC-ARROW` | [Apache Arrow – Columnar Format](https://arrow.apache.org/docs/format/Columnar.html) |
| `SRC-DATAFUSION` | [Apache DataFusion](https://github.com/apache/datafusion) |
| `SRC-SQLSERVER-SESSION-CONTEXT` | [SQL Server – sp_set_session_context](https://learn.microsoft.com/en-us/sql/relational-databases/system-stored-procedures/sp-set-session-context-transact-sql?view=sql-server-ver17) und [SESSION_CONTEXT](https://learn.microsoft.com/en-us/sql/t-sql/functions/session-context-transact-sql?view=sql-server-ver17) |
| `SRC-SQLSERVER-RLS` | [SQL Server – Row-Level Security](https://learn.microsoft.com/en-us/sql/relational-databases/security/row-level-security?view=sql-server-ver17) |
| `SRC-SQLSERVER-SEQUENCE-RANGE` | [SQL Server – sys.sp_sequence_get_range](https://learn.microsoft.com/en-us/sql/relational-databases/system-stored-procedures/sp-sequence-get-range-transact-sql?view=sql-server-ver17) |
| `SRC-SQLSERVER-CATALOG` | [SQL Server – Object Catalog Views](https://learn.microsoft.com/en-us/sql/relational-databases/system-catalog-views/object-catalog-views-transact-sql?view=sql-server-ver17) |
| `SRC-SQLSERVER-DEPENDENCIES` | [SQL Server – sys.sql_expression_dependencies](https://learn.microsoft.com/en-us/sql/relational-databases/system-catalog-views/sys-sql-expression-dependencies-transact-sql?view=sql-server-ver17) |
| `SRC-SQLSERVER-FOR-XML` | [SQL Server – FOR XML](https://learn.microsoft.com/en-us/sql/relational-databases/xml/for-xml-sql-server?view=sql-server-ver17) |
| `SRC-SQLSERVER-HIERARCHYID` | [SQL Server – hierarchyid data type method reference](https://learn.microsoft.com/en-us/sql/t-sql/data-types/hierarchyid-data-type-method-reference?view=sql-server-ver17) |
| `SRC-SQLSERVER-TIMEZONE` | [SQL Server – AT TIME ZONE](https://learn.microsoft.com/en-us/sql/t-sql/queries/at-time-zone-transact-sql?view=sql-server-ver17) und [sys.time_zone_info](https://learn.microsoft.com/en-us/sql/relational-databases/system-catalog-views/sys-time-zone-info-transact-sql?view=sql-server-ver17) |
| `SRC-SQLSERVER-TEMPORAL-QUERY` | [SQL Server – Query data in a system-versioned temporal table](https://learn.microsoft.com/en-us/sql/relational-databases/tables/querying-data-in-a-system-versioned-temporal-table?view=sql-server-ver17) |
| `SRC-SQLSERVER-TEMPORAL-RETENTION` | [SQL Server – Manage historical data in system-versioned temporal tables](https://learn.microsoft.com/en-us/sql/relational-databases/tables/manage-retention-of-historical-data-in-system-versioned-temporal-tables?view=sql-server-ver17) |
| `SRC-SQLSERVER-OPENROWSET` | [SQL Server – OPENROWSET BULK](https://learn.microsoft.com/en-us/sql/t-sql/functions/openrowset-bulk-transact-sql?view=sql-server-ver17) |
| `SRC-SQLSERVER-COMPRESS` | [SQL Server – COMPRESS](https://learn.microsoft.com/en-us/sql/t-sql/functions/compress-transact-sql?view=sql-server-ver17) und [DECOMPRESS](https://learn.microsoft.com/en-us/sql/t-sql/functions/decompress-transact-sql?view=sql-server-ver17) |
| `SRC-SQLSERVER-JSON` | [SQL Server – JSON Functions](https://learn.microsoft.com/en-us/sql/t-sql/functions/json-functions-transact-sql?view=sql-server-ver17) |
| `SRC-SQLSERVER-HASHBYTES` | [SQL Server – HASHBYTES](https://learn.microsoft.com/en-us/sql/t-sql/functions/hashbytes-transact-sql?view=sql-server-ver17) |
| `SRC-XLSX` | [Microsoft Open Specifications – MS-XLSX](https://learn.microsoft.com/en-us/openspecs/office_standards/ms-xlsx/2c5dee00-eff2-4b22-92b6-0738acd4475e) |
| `SRC-OPENXML-SDK` | [Microsoft – Open XML SDK](https://learn.microsoft.com/en-us/office/open-xml/open-xml-sdk) |
| `SRC-ZIP-SPEC` | [PKWARE – ZIP File Format Specification](https://pkware.cachefly.net/webdocs/casestudies/APPNOTE.TXT) |
| `SRC-HLL` | [Flajolet et al. – HyperLogLog](https://algo.inria.fr/flajolet/Publications/FlFuGaMe07.pdf) |
| `SRC-TDIGEST` | [Dunning/Ertl – t-digest](https://arxiv.org/abs/1902.04023) |
| `SRC-BLOOM` | [Mitzenmacher – Compressed Bloom Filters](https://www.eecs.harvard.edu/~michaelm/postscripts/ton2002.pdf) |
| `SRC-SPACESAVING` | [Metwally et al. – Space-Saving](https://www.cs.ucsb.edu/sites/default/files/documents/2005-23.pdf) |
| `SRC-COUNTMIN` | [Cormode/Muthukrishnan – Count-Min Sketch](https://dimacs.rutgers.edu/~graham/pubs/papers/cm-full.pdf) |
| `SRC-RESERVOIR` | [Vitter – Random Sampling with a Reservoir](https://www.cs.umd.edu/~samir/498/vitter.pdf) |
| `SRC-JSON-SCHEMA` | [JSON Schema Draft 2020-12](https://json-schema.org/draft/2020-12) |
| `SRC-SEMVER` | [Semantic Versioning 2.0.0](https://semver.org/) |
| `SRC-UCUM` | [Unified Code for Units of Measure](https://ucum.org/) |
| `SRC-ULID` | [ULID Canonical Specification](https://github.com/ulid/spec) |
| `SRC-XXHASH` | [xxHash](https://github.com/Cyan4973/xxHash) |
| `SRC-BLAKE3` | [BLAKE3 Specification](https://github.com/BLAKE3-team/BLAKE3-specs) |
| `SRC-ISO7064` | [ISO/IEC 7064 – Check Character Systems](https://www.iso.org/standard/31531.html) |
| `SRC-GS1` | [GS1 – Check Digit Calculation](https://www.gs1.org/services/how-calculate-check-digit-manually) |
| `SRC-SWIFT-IBAN` | [SWIFT – IBAN Registry](https://www.swift.com/standards/data-standards/iban-international-bank-account-number) |
| `SRC-BITCOIN-BASE58` | [Bitcoin Developer Reference – Base58Check Encoding](https://developer.bitcoin.org/reference/transactions.html#address-conversion) |
| `SRC-W3C-XML-C14N` | [W3C – Canonical XML 1.1](https://www.w3.org/TR/xml-c14n11/) |
| `SRC-SCRIPTDOM` | [Microsoft SqlScriptDOM](https://github.com/microsoft/SqlScriptDOM) |
| `SRC-FASTCDC` | [USENIX – FastCDC](https://www.usenix.org/conference/atc16/technical-sessions/presentation/xia) |
