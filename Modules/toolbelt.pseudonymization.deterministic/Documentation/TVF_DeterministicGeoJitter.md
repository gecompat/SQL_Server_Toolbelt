# toolbelt_pseudonymization.TVF_DeterministicGeoJitter

Echte Inline-TVF ab additiver Modulversion 1.2.0 für synthetische Punkte.
Einzelfreigabe vom 2026-10-01, genauer
[Vor-Source-Vertrag](../../../Documentation/Architecture/DETERMINISTIC_GEO_JITTER_CONTRACT.md).
Source implementiert; finale ausgewählte SQL-/Client-/Lifecycleadapter
bestanden. Neue Minimalrechte und weitere Ziele bleiben offen; aktuelle CI
wird als separater PR-Mergegate am exakten Head nachgewiesen.
Primitivevidenz bleibt vom integrierten Nachweis getrennt.

```sql
toolbelt_pseudonymization.TVF_DeterministicGeoJitter
    (@Value geography, @Key varbinary(max), @MappingVersion int,
     @Seed bigint = 0, @RadiusMeters int = 100)
```

Genau eine Zeile: `Value geography NULL`, `ErrorCode int NOT NULL`.
Eingabe gültiger nicht leerer 2D-Point/SRID 4326, Z/M NULL und höchstens
128 serialisierte Bytes. Key 1..8000 Bytes, MappingVersion positiv,
Seed nicht NULL, Radius ganze Meter 1..10000. Radius 0 ist ungültig.
Keine WKT-Konvertierung, Kürzung, Reparatur oder zusätzliche öffentliche API.

Priorität: NULL-Value/Key zuerst NULL/0; Version 1; Seed 2; Radius 14;
Key 4; Geography 15; bestehender Range-Kernfehler unverändert; numerische
oder native Ziel-/Entfernungsnachbedingung 16. Bei jedem Fehler ist Value NULL.
Fehlerhafte Caller-Konstruktoren außerhalb der TVF sind dort nicht abfangbar.

Zwei Ausdrücke des vorhandenen Range-Kerns im gültigen Mappingzweig mit Domain `TBXDGEO1`, Context 0/1
und 53-Bit-Uniformwerten bestimmen Fläche und Richtung. Radius/Ursprung sind
nicht Teil des Hashframes. Die konservative Kugelkappe verwendet R=6416001 m
und die flächenorientierte Halbwinkelformel des Vertrags. Polfeste 3D-Basis,
kanonisierte Ursprungslänge am exakten Pol und Zielnormalisierung [-180,180).
Keine bevorzugte Richtung im Stichprobenmodell; keine Zusage exakter
Gleichverteilung auf einer WGS84-Distanzdisk.

Native Nachbedingung `STDistance <= RadiusMeters` strikt ohne Epsilon,
zusätzlich gültiger 2D-Point/SRID 4326 und nicht-null, nichtnegative endliche
Entfernung. Fehler 16 erzeugt keinen erfolgreich geklemmten oder reparierten
Zielpunkt. Float64-/Trigonometrieabweichungen bleiben möglich; keine bitweise
Gleichheitszusage über Plattformen. Koordinatenregression 1e-9 Grad,
Längendifferenz modulo 360; dies erweitert den öffentlichen Radius nicht.

```sql
SELECT shifted.Value, shifted.ErrorCode
FROM (VALUES (CONVERT(varbinary(max), 0x010203), geography::Point(45, 179.99, 4326)))
    AS synthetic(EntityKey, Origin)
CROSS APPLY toolbelt_pseudonymization.TVF_DeterministicGeoJitter
    (synthetic.Origin, synthetic.EntityKey, 1, DEFAULT, DEFAULT) AS shifted;
```

SELECT auf der öffentlichen TVF, keine Rechteausweitung. Lokale und
administrative zentrale Verwendung vorgesehen; tatsächliche Minimalrechte-
und Plattformnachweise bleiben getrennte Gates. Kein I/O, persistiertes
Mapping, neuer CLR-Provider oder neue Dependency. Kein Land-/Gebiets-Clipping,
keine Anonymisierung oder Kryptografie; Entitäten und wiederholte
Beobachtungen können verknüpfbar bleiben. Keine Heap-/Hardwallgarantie.

Native sichere Operandenkette Raw → Sized → STIsValid → Valid → Point → 2D
ersetzt ungeeignete Operanden vor gefährdeten Methoden, behält aber die
ursprünglichen Fehlerflags. CASE/WHERE/APPLY ist keine Reihenfolgegarantie.
128 Bytes begrenzt den akzeptierten UDT, nicht dessen Caller-Konstruktion.
Die exakte 129-Byte-UDT-Probe ist weiterhin unbeobachtet; Integergrenzen
127/128/129 sind kein Ersatz für diesen UDT-Nachweis.

Primärquellen: [Microsoft STDistance](https://learn.microsoft.com/en-us/sql/t-sql/spatial-geography/stdistance-geography-data-type?view=sql-server-ver17),
[Microsoft geography::Point](https://learn.microsoft.com/en-us/sql/t-sql/spatial-geography/point-geography-data-type?view=sql-server-ver17).


## Finaler ausgewählter Nachweis

Der finale synthetische Geo-Adapter besteht auf SQL Server 2019 Linux/latest CL150 und 2025 Windows/CU8 CL150/160/170 jeweils lokal und zentral. Ausgeführt wurden ausdrücklich `GeoJitter.Contract.sql`, `GeoJitter.Safety.sql` und `InstalledMetadata.Contract.sql`, dazu SQL-/Clientmetadaten, echte 1.0.0-/1.1.0-Upgrades, Erstinstallation/Wiederholung, Caller-TX-/SET-Erhalt, Snapshot-Faults, Zukunftsslot-Erhalt, Uninstall und eigene Bereinigung. Der ursprüngliche Geo-Vertrag besteht unverändert in fünf unpartitionierten Batches mit 504 Orakeln. Die sieben bisherigen Source-Dateien bleiben bytegleich; dies ist kein erneuter finaler Runtime-Nachweis aller bisherigen APIs. Keine Konfigurations- oder Rechteänderungen. Neue Minimalrechte, weitere physische Ziele und ein exakt 129-Byte-UDT bleiben offen. Aktuelle CI wird als separater PR-Mergegate am exakten Head nachgewiesen. `partially validated`, `unreleased`.

Der gültige Mappingzweig enthält zwei bestehende RangeCore-Ausdrücke. Der komplementäre Konfigurationszweig bewahrt die ursprüngliche Fehlerpriorität. Relationale Aggregationen reduzieren wiederholte numerische Ausdrücke; daraus folgt keine Zusage einer physischen Ausführungsanzahl, Optimizer-Reihenfolge oder Pruning-Barriere. Die sichere Operandenkette und alle Formeln bleiben maßgeblich.
