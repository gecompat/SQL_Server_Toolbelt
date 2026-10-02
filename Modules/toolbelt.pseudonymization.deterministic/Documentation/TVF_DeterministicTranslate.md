# toolbelt_pseudonymization.TVF_DeterministicTranslate

**Typ:** Inline Table-valued Function  
**Status:** `implemented`; Validierung entsprechend Testmatrix, `unreleased`.

## Zweck und Verwendung

Formaterhaltende Vorwärtstransformation synthetischer ASCII-Kennungen.
Öffentliche echte Inline-TVF ab Modulversion 1.1.0; keine Scalar-Fassade.
Der [kanonische Vertrag](../../../Documentation/Architecture/DETERMINISTIC_TRANSLATE_CONTRACT.md)
definiert das exakte Mappingformat und alle Grenzen.

```sql
SELECT source.SyntheticId, mapped.Value, mapped.ErrorCode
FROM (VALUES(N'Ab09-xy'),(N'Cd12-zw')) source(SyntheticId)
CROSS APPLY toolbelt_pseudonymization.TVF_DeterministicTranslate
    (source.SyntheticId, 1, 42, N'-', DEFAULT) mapped;
```

## Parameter

| Parameter | Typ | Default / Vertrag |
|---|---|---|
| Value | nvarchar(max) | erforderlich; NULL zuerst |
| MappingVersion | int | erforderlich; positiver Mappingkontext |
| Seed | bigint | 0; jeder nicht-NULL bigint |
| AllowedSeparators | nvarchar(max) | leer; höchstens 33 eindeutige druckbare ASCII-Nichtalnum-Zeichen |
| Profile | nvarchar(max) | standard; bytegenau standard oder large |

## Resultset und Fehler

| Ordinal | Spalte | Typ | Nullable | Bedeutung |
|---:|---|---|---|---|
| 1 | Value | nvarchar(max) | ja | Transformierter Text oder NULL |
| 2 | ErrorCode | int | nein | 0 für Erfolg/NULL-Eingabe; sonst erste Fehlerbedingung |

Genau eine Zeile: `Value nvarchar(max) NULL` mit
`Latin1_General_100_BIN2`, `ErrorCode int NOT NULL`. Successcode 0;
Fehler liefern NULL ohne Teiloutput. Priorität: NULL-Value → 0,
ungültige MappingVersion → 1, NULL-Seed → 2, ungültiges Profile → 10,
ungültige Separatoren → 11, Inputübergröße → 12, unbekanntes Zeichen → 13.
Leere Eingabe liefert leeren Wert mit 0. Profile-/Separator-NULL ist ein
Konfigurationsfehler, außer die Eingabe selbst ist NULL.

## Mapping, Grenzen und Collation

Feste ASCII-Alphabete a-z/A-Z/0-9; dieselbe Buchstabenpermutation koppelt
Casepaare, Ziffern verwenden eine eigene Permutation. Explizit erlaubte
Separatoren einschließlich trailing Spaces bleiben unverändert. Controls,
NUL, DEL, Akzente, sonstiges Unicode und Surrogates scheitern. Keine
Normalisierung, kein Trim und kein Abschneiden. Standard erlaubt höchstens
2.097.152 UTF-16-Bytes, large 16.777.216 Bytes; Output exakt gleiche Länge.

Das versionierte 22-Byte-Framing nutzt den vorhandenen IntegerBytes-Kern,
SHA2_256 und Digest-/Ordinal-Ranking für eine bijektive Substitution.
MappingVersion und Seed beeinflussen die Abbildung, Profile und Separatoren
nicht. Fixpunkte/Identitätsabbildungen sind möglich; Kontextänderungen
garantieren keine Änderung jedes einzelnen Zeichens. Kein Decode-API.

## Rechte, Dependencies und Plattformen

Länge, Case, Format, Häufigkeiten und Gleichheitsmuster bleiben sichtbar.
Rückführbarkeit ist ausdrücklich akzeptiert. Keine Anonymisierung,
Verschlüsselung, kryptografische Schutzwirkung oder Secretverwaltung.
Keine I/O-/Zustandsänderung, CLR oder neue Dependency. Das bestehende Modul
benötigt weiterhin ResultTable wegen Lookup; Translate ruft es nicht auf.

Local und Central verwenden denselben Source. Caller benötigen bestehende
SELECT-Rechte; der Installer erteilt keine Rechte. Dreiteilige Verwendung
benötigt Berechtigungen in der Zieldatenbank. Keine pauschale CrossDB-
Minimalrechte-, Heap-, Hardwall-, Durchsatz- oder Parallelitätsgarantie.
## Performance und Teststatus

Mappingrelationen bleiben klein; der Optimizer kann Ausdrücke wiederholt
auswerten. Status, tatsächlich ausgeführte SQL-API-/Lifecycle-/Metadaten-
Qualifikation und verbleibende Fälle stehen in der
[Testmatrix](../Tests/CONTRACT_TEST_MATRIX.md).
