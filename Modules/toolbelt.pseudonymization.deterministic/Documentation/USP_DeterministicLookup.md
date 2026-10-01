# toolbelt_pseudonymization.USP_DeterministicLookup

Öffentliche Stored Procedure, USP-Vertrag 1.0. Individuelle Freigabe vom
2026-10-01: Reservewelle in `.ai/BACKLOG.md`. Implementiert und im ausgewählten
Linux2019-Local-/Central-Scope einschließlich Clientmetadaten und direkten
Minimalrechten geprüft. Weitere Ziele/Restscope: [Testnachweise](../Tests/README.md).

## Signatur

```sql
USP_DeterministicLookup
    @InputTable sysname = NULL,
    @LookupTable sysname = NULL,
    @MappingVersion int = NULL,
    @Seed bigint = 0,
    @LookupVersion bigint = NULL,
    @MaxInputRows int = 10000,
    @MaxLookupRows int = 10000,
    @MaxLookupTextBytes bigint = 2097152,
    @MaxResultBytes bigint = 16777216,
    @ResultTable sysname = NULL,
    @KeepData bit = 0,
    @Debug tinyint = 0,
    @Hilfe bit = 0
```

Technische NULL-Defaults ermöglichen den reinen Hilfeaufruf. Fachlich sind
beide lokale #Temp-Namen, positive MappingVersion/LookupVersion und
nicht-NULL Seed erforderlich. Limits sind positiv, niemals unlimited:
beide Rowlimits höchstens 100000; beide Textbytebudgets höchstens 16777216.
Textbytes zählen `DATALENGTH` der Unicodewerte, nicht Zeichen oder Metadaten.

## Tabellen und Ergebnis

Caller erzeugt und besitzt beide Tabellen derselben Session. Name beginnt
mit einem #, nicht ## oder dem reservierten #tbx_-Präfix (case-unabhängig),
höchstens 116 UTF-16-Einheiten. Identifier werden mit QUOTENAME aufgelöst;
keine vierteiligen Namen, regulären Tabellen oder Tabellenvariablen.
Zwei- oder dreiteilige Procedure-Aufrufe benötigen keine Synonyme.

| Tabelle | Erforderliche Spalten | Datensemantik |
|---|---|---|
| Input | Ordinal bigint, Key varbinary(max) | Ordinal nicht-NULL, positiv/eindeutig; Key NULL oder 1..8000 Byte |
| Pool | Ordinal bigint, Value nvarchar(max) | Ordinal nicht-NULL, positiv/eindeutig; unveränderter Unicodewert, auch leer/NULL zulässig |

Spaltennamen sind byteexakt, Systemtypen ohne Alias oder computed column.
Zusätzliche Spalten werden ignoriert. Nullability darf nullable sein, da
die Ordinalwerte geprüft werden. Ordinal-Lücken sind ausdrücklich zulässig.
Die ResultTable darf nicht auf eine Eingabetabelle auflösen. Gleiche
Tabellen für Input und Pool sind zulässig, wenn beide Spaltenshapes passen.
Leerer Pool ist immer ein Fehler, auch bei leerem Input.

| Ordinal | Ergebnis | Typ | Nullable |
|---:|---|---|---|
| 1 | InputOrdinal | bigint | nein |
| 2 | LookupOrdinal | bigint | ja |
| 3 | Value | nvarchar(max), Latin1_General_100_BIN2 | ja |

Genau eine Zeile pro Inputordinal, SELECT aufsteigend danach sortiert.
NULL-Key erzeugt NULL-LookupOrdinal und NULL-Value; sonst wird der originale
Poolordinal und dessen unveränderter Value ausgegeben. Gleiche Keys können
denselben Eintrag erhalten, verschiedene Keys ebenfalls; keine 1:1-Zusage.
Keine Originalkeys, Hashes, Seeds oder zusätzlichen Statusspalten.

## Mapping und Atomarität

Der Pool erhält eine lückenlose technische Position nach aufsteigendem
Ordinal. Der gemeinsame Range-Kern wählt 1..PoolCount. Byteformat und
Interpretation sind dieselbe unveränderliche V1-Implementierung wie Range,
mit Domain ASCII `TBXDLKP1` und positivem bigint-LookupVersion-Kontext statt
Range-Domain/0. Der Originalkey wird nicht gekürzt oder vorgehasht.
Inputordinal beeinflusst das Mapping nicht. Poolwerte werden nicht gehasht.
Unveränderter Pool und gleiche Parameter liefern gleiche Zuordnung.
Pooländerungen benötigen eine neue LookupVersion; der Caller verantwortet
dies, keine Historie oder Driftprüfung wird persistiert.

Die öffentliche Fassade prüft Help und alle vier reservierten privaten
Tempnamen, bevor sie die interne Core-Prozedur aufruft. Erst deren separate
Compilergrenze enthält die private Temp-DDL und die einmalige Mappinglogik.
Damit kann eine inkompatible Caller-Temp nicht vor Help oder dem fachlichen
Guard einen Bindungsfehler 207 erzeugen. Direkter Core-Aufruf ist unsupported.

Zuerst werden begrenzte Mengen/Ordinals/Keylängen/Pooltextbytes read-only
geprüft, dann Keys, Pool und Mapping privat materialisiert. Tabellen-S-Locks mit
HOLDLOCK verhindern Drift im synchronen Aufruf. Die Keykopie verwendet
varbinary(8000) erst nach Längenprüfung und wird unmittelbar nach Mapping
entfernt. Der Core-Aufruf erfolgt statisch innerhalb der gleichbesitzigen
Ownershipchain: keine zusätzliche SELECT-Freigabe interner Funktionen,
Signatur, EXECUTE AS oder Trust-Ausweitung. Der frühere dynamische Direktaufruf
war unter minimalen EXECUTE-Rechten nicht zulässig und wurde verworfen.
Das Ergebnistextbudget wird aus den ausgewählten Poolwerten geprüft,
bevor Ergebniswerte kopiert werden. Pool und Ergebniskopie haben je
höchstens 16 MiB Text. Die separate Keykopie kann bei Default10000 Zeilen
bis zu80000000 und beim expliziten Ceiling100000 bis zu800000000 Nutzbytes
enthalten, zusätzlich Row-/Mapping-/Plan-/TempDB-Strukturen und Callerinput.
Das ist keine Peak-RAM- oder Laufzeitgarantie; lange Keys, 100000 Zeilen,
bis zu 128 Kandidaten und Optimizer-Spools bleiben empirisch zu qualifizieren.

Alle Geschäftsfehler und Ergebnisgrenzen werden vor ResultTable-Mutation
erkannt. SELECT und ResultTable verwenden denselben fertigen Snapshot.
Eigene Transaktion wird vor SELECT committed; Caller-Transaktion bleibt
offen. Savepoint-Rollback nur wenn tatsächlich gesetzt und committable;
Enginefehler bleiben unverändert. Ein doomed Caller braucht Callerrollback.
Locks in einer Callertransaktion haben deren reguläre Lebensdauer.
MARS-/Paralleländerungen derselben Temps sind nicht unterstützt.

ResultTable verwendet ausschließlich den registrierten same-database
Helper `toolbelt_core.USP_PrepareResultTable >=1.0.0`, ohne INSERT EXEC,
EXECUTE AS, TRUSTWORTHY, neue Rechte oder fremde Helper-Implementierung.
Alle KeepData-Konstellationen entsprechen Replace/Append im Standard;
auch leerer Input liefert ein reguläres leeres Ergebnis und darf bei
KeepData 0 vorhandene Resultdaten ersetzen. Kein NULL-Inputtable-No-op.
Der ResultTable-Pfad liefert kein fachliches SELECT.

## Help, Debug und Fehlerpriorität

Hilfe 1 kommt zuerst: genau das zwölfspaltige Standardresultset, alle
13 Parameter/3 Resultspalten, keine Messages oder Fachprüfungen.
NULL-KeepData/Debug/Hilfe entsprechen 0. Debug-Messages enthalten nur
Phasen-/Metadateninformation, nie Keys, Values, Seeds oder Hashes.
Stufe1 meldet Snapshotbereitschaft, Stufe2 zusätzlich Zeilen-/Pooltextcounts,
Stufe3 zusätzlich ermittelte Objekt-IDs;255 umfasst diese Diagnose. Kein
stabiler öffentlicher Detailtrace und keine zusätzlichen SELECT-Resultsets.

| Priorität | Fehler | Bedeutung |
|---:|---:|---|
| 1 | 54000 | Mapping-/LookupVersion oder Seed ungültig |
| 2 | 54001 | Ressourcenparameter ungültig |
| 3 | 54002 | Name/Sichtbarkeit/Schema oder Resultalias ungültig |
| 4 | 54009 | reservierter privater Temp-Name sichtbar |
| 5 | 54001 | Inputrowlimit überschritten |
| 6 | 54003 | Inputordinal ungültig/doppelt |
| 7 | 54004 | Nicht-NULL Inputkey ungültig |
| 8 | 54001 | Poolrowlimit überschritten |
| 9 | 54003 | Poolordinal ungültig/doppelt |
| 10 | 54005 | Pool leer |
| 11 | 54006 | Pooltextbudget überschritten |
| 12 | 54007 | Range-Kern liefert fachlichen Fehler |
| 13 | 54006 | Ergebnistextbudget überschritten |
| 14 | 54008 | ResultTable-Dependency fehlt/malformed/Markerdrift |
| 15 | Helper-/Enginefehler | Zielprüfung/Mutation; Originalfehler |

Nie fachliche Teilzeilen bei einem Geschäftsfehler. Vollmaterialisierung
garantiert keine atomare Netzwerkauslieferung nach erfolgreicher Prüfung.
Erfolg RETURN 0, keine Status-SELECTs. Keine Anonymisierungs-,
Kryptografie- oder Re-Identifikationsschutz-Zusage.

State ist 1, außer Inputrowlimit 54001/2, Poolrowlimit 54001/3,
Poolordinal 54003/2 und Ergebnistextbudget 54006/2. Helper-/Enginefehler
behalten ihre ursprüngliche Nummer und ihren State.

## Synthetisches Beispiel

```sql
CREATE TABLE #Input(Ordinal bigint, [Key] varbinary(max));
CREATE TABLE #Pool(Ordinal bigint, [Value] nvarchar(max));
INSERT #Input VALUES (10,0x010203),(30,NULL);
INSERT #Pool VALUES (20,N'synthetic alpha'),(80,N'synthetic beta');
EXEC toolbelt_pseudonymization.USP_DeterministicLookup
    @InputTable=N'#Input', @LookupTable=N'#Pool',
    @MappingVersion=1, @LookupVersion=1;
```

Rechte: EXECUTE auf USP, für ResultTable zusätzlich Helper-EXECUTE und
Temp-Metadatensicht. Minimalrechte lokal/direkt zentral sind synthetisch unter
WITHOUT LOGIN-Usern auf SQL2019 Linux geprüft. CrossDB ist bislang nur eine
administrative Baseline, kein CrossDB-Minimalrechtenachweis.
