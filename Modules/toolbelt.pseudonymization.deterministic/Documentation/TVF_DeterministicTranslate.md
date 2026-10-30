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

<!-- API_PARAMETERS:BEGIN -->
| Parameter | SQL-Typ | Default | Richtung | Erklärung / Werte |
|---|---|---|---|---|
| `@Value` | `nvarchar(max)` | `kein Default` | Input | ASCII-Kennung: Buchstaben a-z/A-Z und Ziffern 0-9 werden bijektiv substituiert, ausdrücklich erlaubte Separatoren bleiben unverändert. Leer ist gültig; NULL ergibt NULL/Code 0 vor jeder Konfigurationsprüfung. Kein Trim/Unicode-Transliterieren; Akzente, NUL, Controls, DEL und Surrogate ergeben Code 13. Bytebudget durch Profile, Output exakt gleiche Länge. |
| `@MappingVersion` | `int` | `kein Default` | Input | Positive Ganzzahl 1..2147483647 als explizite Mappingkontextversion. NULL/0/negativ ergibt ErrorCode 1, sofern kein früher NULL-Eingabepfad greift. Keine automatische aktuelle Version; Änderung verändert das Mapping, garantiert aber nicht jeden Einzelwert. |
| `@Seed` | `bigint` | `0` | Input | Jeder nicht-NULL-bigint (-9223372036854775808..9223372036854775807), Default 0. Deterministischer Variantenkontext, kein Zufall je Aufruf und kein Secret. NULL ergibt Code 2 nach dem frühen NULL-Eingabepfad. |
| `@AllowedSeparators` | `nvarchar(max)` | `N''` | Input | Explizite Menge von höchstens 33 verschiedenen druckbaren ASCII-Nichtalnum-Zeichen aus Codes 32..126, z.B. N'-/ '; jedes bleibt unverändert. Leer (Default) erlaubt keine Separatoren. Duplikate, Buchstaben/Ziffern, Controls/NUL/DEL/Unicode und NULL ergeben Code 11; trailing Spaces sind relevant. Keine mehrzeichige Separatorgrammatik. |
| `@Profile` | `nvarchar(max)` | `N'standard'` | Input | Taxativ, bytegenau ohne Trim: standard (Default) = höchstens 2097152 UTF-16-Inputbytes; large = höchstens 16777216. NULL/leer/andere Schreibweisen ergeben Code 10; Überschreitung Code 12. Profil ändert nur das Budget, nicht die Mappingpermutation. |
<!-- API_PARAMETERS:END -->

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

Am 2026-10-02 bestehen vollständige Adapter auf Linux 2019/latest CL150
local/central und Windows 2025/CU8 CL150/160/170 central. Windows local:
API-/Safetyfälle im früheren Gesamtfehllauf bestanden; separate korrigierte
Metadaten-/Lifecycleprüfung erfolgreich. Aktuelle CI, neue Minimalrechte,
weitere physische Targets und Kapazität bleiben offen. Teilweise validiert,
unveröffentlicht; der frühere Fehllauf wird nicht als Gesamt-PASS geführt.

## Technischer Lösungsweg

[Grundlage, Verarbeitungsschritte und Designgründe](../../../Documentation/Reference/IMPLEMENTATION_GUIDE.md#deterministische-zuordnung).
