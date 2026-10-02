# DeterministicTranslate: freigegebener Vorwärtsvertrag

## Freigabe und Scope

Die einzelne Benutzerfreigabe vom 2026-10-01 in `.ai/BACKLOG.md` bestätigt
formaterhaltende Transformation synthetischer Kennungen einschließlich
Rückführbarkeit und verbleibender Länge-, Muster- und Häufigkeitsoffenlegung.
Dieser Vertrag konkretisiert die dort ausdrücklich vor Source freigegebenen
Typen, Budgets und Fehlerregeln. Additive Version `1.1.0` des vorhandenen
Moduls `toolbelt.pseudonymization.deterministic`; bestehende APIs unverändert.
Nur eine neue öffentliche Inline-TVF, kein Decode, neuer Provider, CLR,
persistierter Zustand, I/O oder Secretverwaltung. Die bestehende
ResultTable-Modulabhängigkeit bleibt wegen Lookup unverändert; Translate
verwendet ausschließlich den vorhandenen IntegerBytes-Kern und native T-SQL.

Keine Anonymisierung, Verschlüsselung oder kryptografische Schutzwirkung.
Eine bijektive kleine Substitution ist rückführbar. Format, Länge, Case,
Häufigkeiten und Gleichheitsmuster bleiben sichtbar; Fixpunkte und sogar
Identitätsabbildungen sind möglich. Geänderte MappingVersion oder Seed
garantieren keine Änderung eines einzelnen Werts.

## Öffentlicher Vertrag

```sql
toolbelt_pseudonymization.TVF_DeterministicTranslate
(
    @Value nvarchar(max),
    @MappingVersion int,
    @Seed bigint = 0,
    @AllowedSeparators nvarchar(max) = N'',
    @Profile nvarchar(max) = N'standard'
)
```

Genau eine Zeile mit `Value nvarchar(max) NULL` und `ErrorCode int NOT NULL`;
Ergebnistext `Latin1_General_100_BIN2`. Tatsächliche Clientmetadaten sind
separat zu prüfen. Fehler liefern ausschließlich NULL, niemals Teiloutput.

Feste Alphabete `a-z`, `A-Z`, `0-9`. Eine gemeinsame 26er-Permutation koppelt
die Casepaare; Ziffern erhalten eine eigene 10er-Permutation. Erlaubte
Separatoren bleiben unverändert. Kein Trim, keine Unicode-Normalisierung,
kein Caller-Alphabet und keine unbekannte-Zeichen-Passthrough-Option.

`@AllowedSeparators` enthält höchstens 33 eindeutige druckbare ASCII-Zeichen
32 bis 126, ausschließlich ohne Buchstaben und Ziffern. Der Default erlaubt
keinen Separator. Space zählt als Zeichen; alle 33 zulässigen Zeichen können
gemeinsam verwendet werden. Controls, NUL, DEL, Akzente, sonstiges Unicode
und Surrogates sind unbekannte Eingabezeichen.

Erste zutreffende Bedingung entscheidet:

| Bedingung | Value | ErrorCode |
|---|---|---|
| Value ist NULL, auch bei ungültiger Konfiguration | NULL | 0 |
| MappingVersion NULL oder nicht positiv | NULL | 1 |
| Seed NULL | NULL | 2 |
| Profile nicht bytegenau `standard` oder `large` | NULL | 10 |
| Separatoren NULL, überlang, doppelt oder unzulässig | NULL | 11 |
| Eingabe überschreitet Profilbudget | NULL | 12 |
| Mindestens ein unbekanntes Eingabezeichen | NULL | 13 |
| Erfolgreich, einschließlich leerer Eingabe | transformierter Wert | 0 |

Profile sind case- und längengenau, ohne abschließende Spaces:
`standard` höchstens 2.097.152 UTF-16-Bytes (1.048.576 Codeunits), `large`
höchstens 16.777.216 Bytes (8.388.608 Codeunits). Output hat exakt dieselbe
Bytezahl; keine Expansion und kein Abschneiden. Erlaubte trailing Spaces
bleiben vollständig erhalten. Profilgrenzen sind Ressourcenbegrenzungen,
keine Hardwall-, Heap-, Durchsatz- oder Parallelitätszusage.

## Mappingformat V1

MappingVersion ist ein positiver int-Kontext wie beim Range-Vertrag; Seed
ist jeder nicht-NULL bigint. Das Algorithmusformat V1 ist davon getrennt.
36 logische Mappingeingaben pro Kontext, jeweils exakt 22 Bytes:

| Feld | Breite | Format |
|---|---|---|
| Domain | 8 | ASCII `TBXDTRN1` |
| MappingVersion | 4 | signed int, Big Endian, Zweierkomplement |
| Seed | 8 | signed bigint, Big Endian, Zweierkomplement |
| AlphabetKind | 1 | 0 für Buchstaben, 1 für Ziffern |
| Originalordinal | 1 | 0..25 bzw. 0..9 |

Der vorhandene `TVF_DeterministicIntegerBytes` codiert Integer; keine Kopie
des Encoders. SHA2_256 über den gesamten Frame. Pro Alphabet nach vollständigem
32-Byte-Digest, lexikografisch unsigned, dann Originalordinal sortieren.
Die i-te kanonische Quelle wird auf das Originalzeichen am i-ten Rang
abgebildet. Großbuchstaben verwenden denselben Zielordinal wie Kleinbuchstaben.
Der Originalordinal-Tiebreak bewahrt Bijektion auch bei vollständigem
Digestgleichstand. Eingabe, Profile und Separatoren gehören nicht in Frames.
Keine Uniformitätszusage. Die 36 logischen Eingaben sind keine garantierte
physische HASHBYTES-Aufrufzahl oder Cache-Zusage des SQL-Optimizers.

## T-SQL-Sicherheit und Alternativen

Kanonische echte Inline-TVF: kleine feste Rangrelation, SHA2_256, ROW_NUMBER,
begrenzte STRING_AGG-Mappingstrings und natives TRANSLATE. Keine Relation
mit einer Zeile je Eingabecodeunit. Keine Scalar-Fassade oder Providerkopie.
Lookup bleibt die Alternative für synthetische Pools ohne Formaterhalt;
allgemeine Textmaskierung und Unicode-Alphabete gehören nicht zu diesem Slice.

Alle TRANSLATE-Operanden erhalten ausdrücklich `Latin1_General_100_BIN2`.
Native CI-Collation kann sonst Casepaare zusammenlegen. Unbekannte Zeichen
werden durch Translation des gesamten erlaubten ASCII-Vorrats nach `A`
und bytegenauen Vergleich mit einem gleich langen `nvarchar(max)`-A-Text
erkannt. Keine PATINDEX-/REPLACE-NUL-Annahme, keine SQL-Stringgleichheit,
die trailing Spaces ignoriert.

Profile bytegenau und mit DATALENGTH prüfen; Separatoranzahl ebenfalls über
DATALENGTH/2 statt LEN. WHERE und finale CASE-Projektion sind keine
Auswertungsbarriere. Jedes TRANSLATE muss auch bei NULL, ungültigen,
überlangen oder Surrogate-Separatoren sichere Operanden mit identischen
Mappingstringlängen erhalten. Vor REPLICATE/int-Konvertierung Eingabeanzahl
auf höchstens 8.388.608 begrenzen und `nvarchar(max)` erzwingen. Ungültige
Eingaben dürfen kein natives Exceptionverhalten vor dem Fehlercode erzeugen.

## Vor-Source-Qualifikation und offene Gates

Am 2026-10-02 bestehen vier privat isolierte, jeweils auf zehn Sekunden
begrenzte Python-Kinder insgesamt 5.540 Assertions; Root wiederholt dieselben
Artefakte unabhängig erfolgreich. Struct-basierter Frameoracle, signed
Grenzen, Bijektion/Inverse/Case, erzwungene Digestkollisionen, exhaustive
Kurztexte, Fehlerpriorität, Unicode/NUL/Surrogates, alle 33 Separatoren und
exakte 2-/16-MiB-Grenzen einschließlich Überschreitung. Keine SQL-API-Evidenz.

Separater Read-only-Labrunner besteht 48 native Assertions auf SQL Server
2019 Linux/latest und 2025 Windows/CU8: je BIN2, CS_AS, CI_AS_SC und
CI_AS_SC_UTF8; Case, NUL, Surrogates, erlaubte/verbotene trailing Spaces und
tatsächliches 16-MiB-TRANSLATE. Nur native Primitive, keine integrierte TVF,
keine Metadaten-, Optimizer-, Lifecycle- oder Rechtequalifikation.
Unabhängiger Vor-Source-Semantikreview bestätigt Freigabescope und Format.
Private Artefakte/Endpoints/Runtimeinventare verbleiben außerhalb Git.

Vor Merge weiterhin erforderlich: exakte Hash-/Mappingvektoren, integrierte
Fehlerpriorität und sichere Optimizeroperanden, Clientmetadaten, Collations,
Local/Central, Profilgrenzen und letzter unbekannter Codeunit, echte 1.0→1.1-
Migration, neue Namenskollisionen, Callertransaktion, Drift und Uninstall,
scopebezogene Labtests, unabhängiger finaler Review und erforderliche grüne CI.
Andere Targets, CrossDB-Minimalrechte und Produktionskapazität werden ohne
ausgeführten Nachweis ausdrücklich offen ausgewiesen.

Primärquellen:

- [Microsoft: TRANSLATE](https://learn.microsoft.com/en-us/sql/t-sql/functions/translate-transact-sql?view=sql-server-ver17)
- [Microsoft: HASHBYTES](https://learn.microsoft.com/en-us/sql/t-sql/functions/hashbytes-transact-sql?view=sql-server-ver17)
- [Microsoft: REPLICATE](https://learn.microsoft.com/en-us/sql/t-sql/functions/replicate-transact-sql?view=sql-server-ver17)
## Integrierte Qualifikation 2026-10-02

Die neue Inline-TVF und der gekoppelte 1.1-Lifecycle sind implementiert.
Die versionierte Referenzsuite besteht 1.746 zusätzliche Translateassertions;
unabhängige Source-, Lifecycle- und Datenschutzreviews sind erfolgreich.
Der vollständige synthetische Adapter `Tests/CI/run-deterministic-translate-lab.ps1`
besteht auf schema-validierten, ausgewählten SQL_Server_Lab-Zielen:
Linux 2019/latest CL150 local/central und Windows 2025/CU8 CL150/160/170
central. Geprüft sind bestehende APIregressionen, Translatevektoren,
21 Safetybatches, vier Caller-Collations, tatsächliche 2-/16-MiB-Grenzen,
SQL-/Clientmetadaten, echtes unverändertes 1.0-Upgrade, FirstInstall,
Wiederholung, Callertransaktionen, unveränderte Fehlersnapshots,
fremde Zukunftsslots, historischer Uninstall, CrossDB und eigener Cleanup.
Windows local: API-/Safetyfälle bestanden im früheren insgesamt fehlgeschlagenen
Lauf; anschließend bestand der separate korrigierte Metadaten-/Lifecycleadapter.
Dies ist kein Gesamt-PASS des früheren Fehllaufs. Keine Serverkonfiguration
oder Rechte wurden für diese Labprüfungen geändert.

Die vorstehende Vor-Source-Evidenz bleibt ein historisch getrennter Nachweis.
Erforderliche CI auf dem finalen PR-Head sowie neue direkte/CrossDB-Minimalrechte
sind noch offen; weitere physische Ziele und Produktionskapazität sind nicht
qualifiziert. Der Modulstatus bleibt `partially validated`, `unreleased`.
