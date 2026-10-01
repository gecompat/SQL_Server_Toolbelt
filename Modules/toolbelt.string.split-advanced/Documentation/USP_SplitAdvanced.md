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
