# Deterministic GeoJitter – begrenzter Vertrag vor Source

Stand: 2026-10-02. Die funktionsbezogene Benutzerfreigabe vom 2026-10-01 ist
in [.ai/BACKLOG.md](../../.ai/BACKLOG.md) dokumentiert. Dieser Vertrag
konkretisiert Typen, Grenzen, Fehler und Modell innerhalb dieses Scopes;
er behauptet keine zusätzliche Benutzerfreigabe. Die Vor-Source-Qualifikation
ist für den ausgewählten akzeptierten Punktbereich abgeschlossen. Source,
öffentliche API, Clientmetadaten, Lifecycle, Rechte und CI waren im damaligen
Vor-Source-Stand noch offen. Der unabhängige Vertragsfreeze wurde vor Source
als Commit `ebd7292` festgehalten.

## Integrierter Nachweis vom 2026-10-02

Der finale synthetische Geo-Adapter besteht auf SQL Server 2019 Linux/latest CL150 und 2025 Windows/CU8 CL150/160/170 jeweils lokal und zentral. Ausgeführt wurden ausdrücklich `GeoJitter.Contract.sql`, `GeoJitter.Safety.sql` und `InstalledMetadata.Contract.sql`, dazu SQL-/Clientmetadaten, echte 1.0.0-/1.1.0-Upgrades, Erstinstallation/Wiederholung, Caller-TX-/SET-Erhalt, Snapshot-Faults, Zukunftsslot-Erhalt, Uninstall und eigene Bereinigung. Der ursprüngliche Geo-Vertrag besteht unverändert in fünf unpartitionierten Batches mit 504 Orakeln. Die sieben bisherigen Source-Dateien bleiben bytegleich; dies ist kein erneuter finaler Runtime-Nachweis aller bisherigen APIs. Keine Konfigurations- oder Rechteänderungen. Neue Minimalrechte, weitere physische Ziele und ein exakt 129-Byte-UDT bleiben offen. Aktuelle CI wird als separater PR-Mergegate am exakten Head nachgewiesen. `partially validated`, `unreleased`.

Der gültige Mappingzweig enthält zwei bestehende RangeCore-Ausdrücke. Der komplementäre Konfigurationszweig bewahrt die ursprüngliche Fehlerpriorität. Relationale Aggregationen reduzieren wiederholte numerische Ausdrücke; daraus folgt keine Zusage einer physischen Ausführungsanzahl, Optimizer-Reihenfolge oder Pruning-Barriere. Die sichere Operandenkette und alle Formeln bleiben maßgeblich.

Historische Zwischenstände vom 2026-10-02: Die ursprüngliche Ausdrucksform und kleinere Zwischenkandidaten scheiterten mit SQL-Fehler 701; ein späterer Lauf endete mit Timeout -2. Diese Läufe bleiben fehlgeschlagen, eine allgemeine Compilerursache ist nicht nachgewiesen. Der historische Vector-Facts-Kandidat bestand auf Linux mit einer vorübergehenden Partitionierung: 72 Gruppen mit je sieben Radiuswerten, zusammen dieselben 504 Orakel, eingebettet in 78 Batches einschließlich Metadaten/Goldens/Defaults, Setup, globalem Coverage-Orakel und Wiederholung. Dieser Zwischenbeleg ersetzt den finalen Nachweis der ursprünglichen fünf Batches nicht.

## Zweck und öffentliche Form

Genau eine additive echte Inline-TVF im vorhandenen Modul
`toolbelt.pseudonymization.deterministic`, additive Version 1.2.0. Die
bisherigen sieben Source-Slots bleiben unverändert; Lifecycle unterstützt
die kohärenten Vorgänger 1.0.0 und 1.1.0:

```sql
toolbelt_pseudonymization.TVF_DeterministicGeoJitter
(@Value geography, @Key varbinary(max), @MappingVersion int,
 @Seed bigint = 0, @RadiusMeters int = 100)
```

Genau eine Zeile: Ordinal 1 `Value geography NULL`, Ordinal 2
`ErrorCode int NOT NULL`. `Key` bezeichnet den binären EntityKey.
Nur synthetische, gültige, nicht leere zweidimensionale Einzelpunkte mit
SRID 4326; Z und M müssen jeweils NULL sein. Keine weitere öffentliche
Spatial-API, kein Offset-/Richtungs-/Distanzresultat, keine stille Z/M-Verwerfung
oder zusätzliche Erhaltungs-API. Kein Land-/Gebiets-Clipping: Wasser und
Punkte außerhalb einer Verwaltungsgrenze sind zulässig. Wiederholte
Beobachtungen und gleiche Schlüssel bleiben verknüpfbar. Keine
Anonymisierungs-, Verschlüsselungs- oder kryptografische Schutzwirkung.

## Grenzen und Fehlerpriorität

Radius ganze Meter 1..10000, Default 100. NULL,0,negative oder größere Werte
sind ungültig; keine Radius 0-Identität. Key 1..8000 Bytes, MappingVersion
positive int, Seed beliebige nicht-null signed bigint. Geography maximal 128
serialisierte Bytes gemäß `DATALENGTH(CONVERT(varbinary(max), @Value))`.
Keine WKT-/LEN-Grenze, keine Kürzung und keine Reparatur mittels MakeValid.
128 Bytes begrenzt die akzeptierte UDT-Eingabe; dies schützt nicht vor Kosten
der bereits vom Caller konstruierten Geography oder ihrer Serialisierung.

Die erste zutreffende Zeile bestimmt das Ergebnis:

| Priorität | Bedingung | Ergebnis |
|---|---|---|
| 1 | Value oder Key NULL | NULL/0, vor allen anderen Prüfungen |
| 2 | MappingVersion NULL oder <=0 | NULL/1 |
| 3 | Seed NULL | NULL/2 |
| 4 | Radius NULL oder außerhalb 1..10000 | NULL/14 |
| 5 | Key leer oder >8000 Bytes | NULL/4 |
| 6 | Geography >128 Bytes, ungültig, leer, nicht Point, SRID ungleich 4326 oder Z/M nicht NULL | NULL/15 |
| 7 | Bestehender Range-Kern meldet Fehler | NULL/unveränderter Kernfehler |
| 8 | Numerische oder native Nachbedingung verletzt | NULL/16 |
| 9 | Sonst | gültiger Zielpunkt/0 |

Fehler 5 bleibt das bestehende ausgeschöpfte Range-Kandidatenbudget; interner
Fehler 6 ist kein regulärer fachlicher Eingabefall. Fehlerhafte Konstruktoren
oder Binärkonvertierungen des Callers außerhalb der TVF sind dort nicht
abfangbar und werden nicht als API-ErrorCode 15 ausgegeben.

## Gemeinsamer deterministischer Kern

Zweimal vorhandenes `TVF_DeterministicRangeCore`, Domain ASCII `TBXDGEO1`
(8 Bytes), Context 0 für Fläche und Context 1 für Richtung, Min 0 und
Max 9007199254740991. Keine neue Hash-/Range-Implementierung. Bestehendes
Frame-V1 bleibt unverändert:

```text
Domain8 || ContextBE8 || MappingVersionBE4 || SeedBE8 || MinBE8 || MaxBE8
|| KeyLengthBE4 || Key || AttemptBE4
```

Radius und Ursprungspunkt sind nicht Framebestandteile. Gleiche
Entitätsparameter ergeben dieselben normierten Stichproben, danach abhängig
von Punkt und Radius angewendet. `u=Value0/2^53`, `v=Value1/2^53`, beide in
[0,1). Span 2^53 teilt 2^64; im vorhandenen Range-Modell wird der erste
Hashkandidat angenommen. Keine Addition von 0,5 und kein Rundungsweg, der 1
zulässt. Seed ist kein Geheimnis.

## Flächenorientiertes Modell

Feste konservative Modellkonstante R=6416001 m:

```text
dmax = RadiusMeters / R
d = 2 * asin(sqrt(u) * sin(dmax / 2))
theta = 2 * pi * v
```

Dies entspricht einer flächenorientierten diskreten Stichprobe der
Kugelkappe mit gleichabständigen Richtungen. Keine Zusage exakter
Gleichverteilung auf einer WGS84-Distanzdisk oder universeller Zufallsqualität
der deterministischen Hashwerte. Der stabile Halbwinkel vermeidet die
Subtraktion nahezu gleicher Cosinuswerte für kleine Radien.

Aus geodätischer Breite phi und Länge lambda wird ohne Division durch
cos(phi) die lokale orthonormale Basis gebildet:

```text
n = (cos(phi)*cos(lambda), cos(phi)*sin(lambda), sin(phi))
N = (-sin(phi)*cos(lambda), -sin(phi)*sin(lambda), cos(phi))
E = (-sin(lambda), cos(lambda), 0)
p = cos(d)*n + sin(d)*(cos(theta)*N + sin(theta)*E)
latitude = ATN2(p.z, SQRT(p.x*p.x + p.y*p.y))
longitude = ATN2(p.y, p.x)
```

Gradkonvertierung; Ziellänge normalisiert auf [-180,180). Bei exakt +/-90 Grad
wird die Ursprungslänge für die Basis auf 0 kanonisiert. Verschiedene
Längendarstellungen desselben Pols führen dadurch zu derselben Verschiebung.
Keine Pol-/Datumsgrenzen-Reparatur. Der Zielpunkt entsteht über nativen
`geography::Point(latitude, longitude, 4326)` ohne Z/M.

WGS84 verwendet a=6378137 m und inverse Abplattung 298.257223563.
[NGA WGS84](https://earth-info.nga.mil/?action=wgs84&dir=wgs84)
Die daraus berechnete maximale geodätische Krümmungsmetrik a/sqrt(1-e²)
liegt unter 6400000 m. Als Modellableitung ist die WGS84-Länge entlang des
zugehörigen Kugelpfads durch Winkel*6400000 begrenzt. Mit dem dokumentierten
STDistance-Näherungsfaktor 1,0025 ergibt sich eine konservative Obergrenze
unter Winkel * 6416001. STDistance approximiert die Geodäsie mit dokumentierter
Abweichung bis 0,25 % auf üblichen Erdmodellen.
[Microsoft STDistance](https://learn.microsoft.com/en-us/sql/t-sql/spatial-geography/stdistance-geography-data-type?view=sql-server-ver17)
Die Ableitung erklärt die konservative Modellwahl; sie ist keine universelle
SQL-/Floatgarantie aus endlichen Tests. Der effektive WGS84-Rand liegt bewusst
geringfügig innerhalb des Maximalradius. Ein mittleres Kugelmodell wurde
verworfen, weil es die WGS84-Radiusgrenze überschreiten kann. Ein separater
ellipsoidischer Provider oder iterative Reparatur ist nicht Teil dieser Welle.

## Sichere native Operanden und Nachbedingungen

CTEs, CASE-Prädikate, WHERE und APPLY garantieren keine Auswertungsreihenfolge.
Jeder gefährdete Methodenaufruf erhält selbst einen qualifizierten sicheren
Operanden. Kanonische Datenabhängigkeit:

1. `Raw`: Originalwert und serialisierte Bytelänge ermitteln.
2. `Sized`: nur nicht-null Werte mit höchstens 128 Bytes behalten, sonst den
   gültigen zweidimensionalen Ersatzpunkt `geography::Point(0,0,4326)` einsetzen.
3. `STIsValid`: ausschließlich auf `Sized` prüfen.
4. `Valid`: nur bei STIsValid=1 den Sized-Operanden behalten, sonst Ersatzpunkt.
   STIsEmpty, STGeometryType und STSrid lesen ausschließlich diesen Operanden.
5. `Point`: nur gültiger, nicht leerer Point/SRID 4326 bleibt, sonst Ersatzpunkt.
   Lat, Long, Z und M lesen ausschließlich diesen Point-Operanden.
6. `2D`: nur Point ohne Z/M bleibt, sonst Ersatzpunkt. Vorwärtsrechnung und
   STDistance verwenden nur diese sichere zweidimensionale Geography.

Originale Budget-/Gültigkeits-/Typ-/SRID-/Z/M-Prädikate bleiben für die
öffentliche Fehlerentscheidung erhalten; Ersatzpunkte machen eine
ungültige Eingabe nicht gültig. Insbesondere dürfen STIsEmpty und
STGeometryType nicht gemeinsam mit STIsValid auf einem noch ungültigen
Sized-Operanden aufgerufen werden. Ebenso erhalten Hash-/Trigonometrie- und
Konstruktorpfade unabhängig von späteren Filtern gültige endliche Werte;
Konfigurationsfehler dürfen keinen unsicheren Radius oder Key weiterreichen.

Defensive Nachbedingungen: Ziel gültiger nicht leerer 2D-Point/SRID 4326,
Koordinaten endlich und im nativen Bereich, native STDistance nicht NULL,
nicht negativ, nicht nichtendlich und <=RadiusMeters. Verletzung => NULL/16.
Kein Clamp, Retry, MakeValid oder verdeckter Modellwechsel. Fehler 16 ist kein
normal akzeptierter Stichprobenfilter. Endlichkeit benötigt qualifizierte
native/providergeeignete Prüfungen oder einen Nachweis unter den endlichen
sicheren Operanden; keine erfundene ISFINITE-Funktion.

Float64 und Trigonometrie erzeugen Rundungsabweichungen. MappingVersion fixiert
Frame, Konstanten und Formeln; allein daraus folgt kein bitweiser
plattformübergreifender Vertrag für Koordinaten oder Geography-Serialisierung.
Numerische Regressionen vergleichen Zielkoordinaten mit höchstens 1e-9 Grad
absoluter Abweichung; Längendifferenzen werden dabei modulo 360 als kleinste
Winkeldifferenz bewertet. Bei exakt gleichen Polpunkten ist die Richtung
der Längendarstellung geometrisch nicht eindeutig; die kanonisierte
Vorwärtsbasis bleibt trotzdem ein eigenes Orakel. Dies ist eine
Regressionstoleranz, keine öffentliche Genauigkeits- oder Bitgleichheitszusage.
Die öffentliche STDistance-Nachbedingung wird nicht um eine Testtoleranz
erweitert. Keine Heap-, Hardwall- oder Produktionskapazitätsgarantie.

## Vor-Source-Evidenz und ehrliche Grenzen

Die folgenden Angaben sind synthetische, aggregierte Nachweise vom
2026-10-02; private Berichte, Endpoints, Pfade und originale Runtime-Ausgaben
werden nicht übernommen.

- Private Python-Modellreferenz: aktuelle 10685 Assertions, Exit 0. Feste
  Frames/Digests/53-Bit-Integer gegen bestehende unveränderte Range-V1-Referenz
  sowie zwei Struct-Encoder geprüft; Pole/Datumsgrenze, Flächen-CDF und
  unabhängige Winkel-/Meridianreferenz. Der frühere 10526-Snapshot druckte die
  Hashvektoren lediglich und ist kein damaliger Golden-Vector-Nachweis.
- Native Read-only-Modellprüfung auf schema-ausgewählten Linux 2019/latest
  und Windows 2025/CU8: je 1458 Fälle, davon 1080 aus dem tatsächlichen
  [0,1)²-Bereich und 378 zusätzliche Endpoints. Sieben Fehlerzähler jeweils 0,
  acht Methodenfixtures und erwartete Konstruktorabweisung bestanden.
  Endpoint 1 gehört nur zur Testinstrumentierung.
- Eine fehlerhafte Vorgänger-Operandenkette erzeugte Fehler 6522 beim Aufruf
  weiterer Methoden auf einer ungültigen Geography. Dieser Lauf ist FAILED,
  kein PASS. Die korrigierte Kette ergänzt `Valid` vor diesen Methoden.
- Korrigierte native Operandenkette: je ausgewähltem Ziel neun direkte
  Literalfixtures und 32 Variablenfixtures, jeweils in drei Formen
  (direkter SELECT, APPLY, äußerer CASE) bestanden. Enthalten sind
  konstruierbare ungültige Instanzen, tatsächliche 128-Byte-UDTs, größere
  UDTs, NULL/Empty/non-Point/SRID/Z/M und getrennte Caller-Konstruktorabweisung.
  Diese Methoden-/Operandenprüfung ist keine öffentliche TVF-Ausführung.
  Beobachtete Point-Formate lagen höchstens bei 38 Bytes; Z/M-Formate bleiben
  trotz dieses Budgets öffentlich unzulässig. Tatsächliche 128-Byte- und
  größere Non-Point-UDTs prüfen die sichere Budget-/Methodenkette getrennt.
- Exakt 129 serialisierte UDT-Bytes wurden nicht beobachtet; hierfür wird
  kein PASS behauptet. Getrennte Integerprädikatfälle 127/128/129 qualifizieren
  den numerischen Vergleich, nicht Existenz oder Verhalten eines 129-Byte-UDT.
  Native Modelle/Operatoren sind endlich qualifiziert, nicht universell bewiesen.

Die Vor-Source-Qualifikation ist für den akzeptierten Punktbereich geschlossen.
Der tatsächliche Source muss die geprüfte Operandenkette reproduzieren;
abweichende native Methoden oder Budgetbehandlung erfordern gezielte neue
Qualifikation. Die genaue 129-Byte-UDT-Evidenzlücke bleibt sichtbar und wird
nicht durch einen Ersatzfall oder erfundenen Zeugen geschlossen.

## Integrierter Qualifikationskatalog und verbleibender Mergegate

Der finale ausgewählte Nachweis oben schließt die ausgeführten API-/
Metadaten-/Lifecyclefälle. Der folgende Katalog bewahrt den geplanten Scope;
weitere physische Ziele und neue Minimalrechte sind nicht ausgeführt.
Aktuelle CI und PR-Merge bleiben separate Gates am exakten Head.

Öffentliche echte Inline-API mit Parametern/Defaults/Ordinals/Nullability;
alle kombinierten Fehlerprioritäten; tatsächliche native Invalid-/Budgetfälle
und sichere Konstanten/APPLY/äußererCASE-Pfade; feste Range-/Zielvektoren und
toleranzdefinierte Regressionen; Pole/Datumsgrenze/Radius 1/100/10000 sowie
native Distanznachbedingungen. Alle bestehenden APIs bleiben unverändert.
SQL 2019/2022/2025 Windows/Linux sind Zielmatrix, kein pauschaler Nachweis.

Lokale und administrative zentrale Verwendung, minimale vorhandene
Callerrechte ohne Grants, Own-/Callertransaktion; kohärenter versionierter
Lifecycle, echter Vorgängerupgrade, Kollisionen, Rollback, Wiederholung,
Uninstall und eigener Cleanup; unabhängiger Review, erforderliche grüne CI
auf aktuellem Head und PR-Merge. Nicht ausgeführte physische Matrix-/Rechtefälle
bleiben ausdrücklich offen. Keine neue Dependency, CLR-/Trust-/Configänderung
oder Releaseveröffentlichung aus diesem Vertragsstand ableiten.

Weitere Primärquellen:

- [Microsoft geography::Point](https://learn.microsoft.com/en-us/sql/t-sql/spatial-geography/point-geography-data-type?view=sql-server-ver17): native Lat/Long-Reihenfolge.
- [Microsoft STIsValid](https://learn.microsoft.com/en-us/sql/t-sql/spatial-geography/stisvalid-geography-data-type?view=sql-server-ver17): Gültigkeitsprüfung.
- [Microsoft Point](https://learn.microsoft.com/en-us/sql/relational-databases/spatial/point?view=sql-server-ver17): optionale Z/M-Werte, hier ausdrücklich ausgeschlossen.
