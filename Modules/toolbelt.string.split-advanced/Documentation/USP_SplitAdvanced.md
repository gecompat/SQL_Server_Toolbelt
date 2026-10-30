# USP_SplitAdvanced

Ausdrückliche Einzel-Freigabe 2026-10-01 nach
[Vertragsbesprechung](../../../Documentation/Architecture/ADVANCED_STRING_SPLIT_PROPOSAL.md):
„Unquoting, Split-USP und ZIP-Writer implementieren“.
Modul 1.1.0; genau eine Fassade des unveränderten TVF_SplitAdvanced-Kerns,
kein zweiter Parser und kein automatisches Unquoting.

~~~sql
EXEC toolbelt_string.USP_SplitAdvanced
    @Input=N'a;"b;c";d', @SeparatorsJson=N'[";"]';
EXEC toolbelt_string.USP_SplitAdvanced @Hilfe=1;
~~~

Parameter in Reihenfolge: Input nvarchar(max)=NULL,
SeparatorsJson nvarchar(max)=NULL, Quote nvarchar(max)=N'"',
Escape nvarchar(max)=N'\', KeepEmpty bit=1,
ResultTable sysname=NULL, KeepData bit=0, Debug tinyint=0, Hilfe bit=0.
KeepEmpty NULL entspricht 1; letzte drei Steuerparameter NULL entsprechen 0.
Alle fachlichen Regeln kommen aus [TVF_SplitAdvanced](TVF_SplitAdvanced.md).

Erfolg: Value nvarchar(max) NOT NULL, Ordinal bigint NOT NULL; Originaltokens.
SELECT ist nach Ordinal geordnet, ResultTable besitzt keine physische
Reihenfolgegarantie. Genau ein TVF-Snapshot; Geschäftsfehler THROW 51680 mit
symbolischem TVF-Code/Originalposition ohne Inputinhalt, vor Ausgabe oder
Zielmutation. Enginefehler behalten Originalnummer/Zustand.

NULL Input ist früher No-op: ResultTable=NULL leeres Erfolgsschema,
gesetzte ResultTable völlig unverändert, selbst mit KeepData=0 oder
ungültigem Namen. Nicht-NULL Input mit null Tokens hat reguläre Replace-
oder Append-Semantik.

Der vollständige [USP-Vertrag](../../../Documentation/Standards/USP_CONTRACT.md)
gilt: Help umgeht Fachfunktion, Pflichtvalidierung, Dependency-/Zielprüfung,
Mutation und Debug. Standardisiertes Help mit allen Parametern/Resultspalten
und Pflichtsections. Debug ausschließlich Messages, keine Input-/Tokeninhalte.

## ResultTable, Dependency und Transaktion

ResultTable muss existierende caller-lokale Temp sein; kein reservierter
#tbx_-Name, global/permanent/variable oder generisches INSERT EXEC.
Same-database toolbelt.core.result-table >=1.0.0 mit konsistenten Modul-/
Objektmarkern erforderlich (51681 bei Runtime-Dependencyfehler).
Keine automatische Installation oder Rechteausweitung.
TVFs benötigen diesen Helper nicht; Installer prüft Moduldependency vor Mutation.

Canonical USP_PrepareResultTable bereitet das exakte NOT-NULL/BIN2-Schema
vor: Replace/Append, leere Schemaanpassung und voller Dependency-Preflight.
Befüllt/unpassend mit KeepData=1 und blockierende Schemaabhängigkeiten sind
Fehler vor Mutation; Caller-Indizes/Constraints werden nicht entfernt.
Insertfehler werden mit eigener Transaktion oder committable Savepoint
zurückgerollt; keine fremde Transaktion committen oder pauschal rollbacken.
Bei XACT_STATE=-1 ist Savepointrollback unmöglich; Originalfehler bleibt,
Caller muss rollbacken. Kein implizites Ändern seines XACT_ABORT-Modus.
Private Temp-Objekte werden durch Procedure-Scope aufgeräumt.

EXECUTE auf USP und für ResultTable Helper-EXECUTE/Temp-Metadatensicht;
Central-Aufruf benötigt dieselbe Session und separate Callerrechte/Mapping.
Keine TRUSTWORTHY-/Login-/Infrastrukturänderung. Materialisierter Snapshot
und ResultTable-Kopie, keine LOB-Performancezusage.
Neue 1.1-Runtime-Verträge am 2026-10-01 auf SQL Server 2019 Linux/latest
und SQL Server 2025 Windows/CU8 erfolgreich. Weitere neue Version-/Plattform-
kombinationen, GitHub-1.1-Lauf und niedrigprivilegierter mapped Caller Cross-DB
nicht ausgeführt; Modul bleibt partially validated. Reproduzierbare Befehle
und genauer Scope stehen in [Tests/README](../Tests/README.md).

## Beispielaufruf

```sql
EXEC toolbelt_string.USP_SplitAdvanced @Input=N'a;b', @SeparatorsJson=N'[";"]', @Quote=N'', @Escape=N'';
```

```sql
EXEC toolbelt_string.USP_SplitAdvanced
    @Input=N'a;"b;c";d', @SeparatorsJson=N'[";"]';
EXEC toolbelt_string.USP_SplitAdvanced @Hilfe=1;
```

Die Beispiele verwenden synthetische Werte. Vorlagen mit registrierten
Handlern, Tabellen oder Dateien setzen deren beschriebene Vorbereitung voraus.

## Vollständiger Eingabevertrag

<!-- API_PARAMETERS:BEGIN -->
| Parameter | SQL-Typ | Default | Richtung | Erklärung / Werte |
|---|---|---|---|---|
| `@Input` | `nvarchar(max)` | `NULL` | Input | Text mit maximal 65536 UTF-16-Einheiten, NUL verboten; leer ist gültig. NULL ist ein früher No-op ohne Zeilen, selbst bei ungültiger Konfiguration. Tokens bleiben im Original einschließlich Quotes/Escapes; zum Entfernen TVF_UnquoteToken verwenden. |
| `@SeparatorsJson` | `nvarchar(max)` | `NULL` | Input | JSON-Array aus 1..16 verschiedenen nicht leeren Strings, z.B. ["::",","]; kein Objekt, keine JSON-null-/Zahlen-/Boolean-Elemente. Je Separator 1..64 UTF-16-Einheiten, Gesamt-JSON höchstens 16384 Einheiten. Binäre Gleichheit einschließlich Spaces; NUL und die aktivierten Quote-/Escape-Zeichen verboten. Längster passender Separator gewinnt. NULL ist außerhalb des frühen Input-NULL-Pfads ungültig. |
| `@Quote` | `nvarchar(max)` | `N'"'` | Input | Genau eine UTF-16-Einheit (Default Doppelquote) aktiviert Quotegruppen; leer deaktiviert sie. NULL, NUL und Surrogate ungültig. Muss sich vom aktiven Escape unterscheiden und darf in keinem Separator vorkommen; keine automatische mehrzeichige Quote-Syntax. |
| `@Escape` | `nvarchar(max)` | `N'\'` | Input | Genau eine UTF-16-Einheit (Default Backslash) schützt das nächste Zeichen vor Parserwirkung; leer deaktiviert Escaping. NULL, NUL und Surrogate ungültig. Darf weder aktives Quote noch Bestandteil eines Separators sein. Ein finales Escape ohne Folgezeichen ist ein Parserfehler; Ausgabe bleibt unentschlüsselt. |
| `@KeepEmpty` | `bit` | `1` | Input | Taxativ im gebundenen bit: 1 behält leere Tokens einschließlich leerem Input (Default); 0 entfernt sie. NULL wird wie 1 behandelt. |
| `@ResultTable` | `sysname` | `NULL` | Input | NULL (Default) liefert den fachlichen SELECT-Resultset. Sonst ein einzelner sysname mit 2..116 UTF-16-Einheiten einschließlich führendem # als Name einer bereits im Caller-Scope angelegten lokalen #Temp-Tabelle, z.B. N'#Result'; keine globale ##Temp, persistente oder mehrteilige Tabelle. Der ResultTable-Helper muss verfügbar sein; die Ausgabeform wird anhand des konkreten Objektresultsets vorbereitet. |
| `@KeepData` | `bit` | `0` | Input | Taxativ für bit: 0 ersetzt Ergebnisdaten (Default), 1 hängt bei kompatibler ResultTable an; NULL entspricht 0. Nur bei nicht-NULL ResultTable relevant; Schema- und Datenbehandlung folgen dem kanonischen ResultTable-Vertrag. |
| `@Debug` | `tinyint` | `0` | Input | tinyint 0..255: 0 (Default) oder NULL ohne Diagnose; 1..255 aktiviert die im Objekt beschriebenen abstrakten Diagnose-Messages, ohne zusätzlichen fachlichen Resultset. |
| `@Hilfe` | `bit` | `0` | Input | Taxativ für bit: 1 liefert nur die Standardhilfe vor der Fachvalidierung; 0 (Default) führt den Fachaufruf aus. NULL wird wie 0 behandelt. Syntaktisch erforderliche Argumente ohne technischen Default müssen auch beim Help-Aufruf angegeben werden. |
<!-- API_PARAMETERS:END -->


## Technischer Lösungsweg

[Grundlage, Verarbeitungsschritte und Designgründe](../../../Documentation/Reference/IMPLEMENTATION_GUIDE.md#tokenisierung).
