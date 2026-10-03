# TVF_JaroWinklerSimilarity

```sql
SELECT * FROM toolbelt_string.TVF_JaroWinklerSimilarity(N'ABC',N'ACB',DEFAULT);
```

Die öffentliche inline TVF übernimmt `@LeftText nvarchar(max)`,
`@RightText nvarchar(max)` und `@Profile nvarchar(max)=N'standard'`.
Sie liefert genau eine Zeile mit `Similarity float(53)` und `ErrorCode int`.
Similarity ist bei einem Fachfehler oder NULL-Text NULL; ErrorCode ist logisch
nicht NULL. Physische SQL-/Clientmetadaten dürfen nullable sein.

Unicode Scalars werden ordinal verglichen, ohne Normalisierung oder Trim.
NULL-Text gewinnt vor Profilprüfung. Danach gelten Profilfehler 1, Rawlimit 3,
ungültiges UTF-16 4, Scalarlimit 5 und geplante Fensterarbeit 6. Erfolgsstatus 0
enthält einen vollständigen Score von 0 bis 1; Code 2 wird nicht verwendet.

Standard erlaubt je Text 2048 UTF-16-Einheiten und 1024 Scalars sowie 1048576
Fensterplätze. Large erlaubt 65536 Einheiten und 32768 Scalars sowie 16777216
Fensterplätze. Die Prognose wird vor Matching und Identitätsabkürzungen geprüft.
Die kürzere Seite steht zuerst, bei gleicher Länge die scalarlexikalisch kleinere.
Greedy Matching verwendet den ersten unbenutzten Partner im inklusiven Fenster.
Transpositionen sind reell `h/2`. Ein Präfixbonus von `0.1` für höchstens vier
Scalars gilt nur bei rational exakt geprüftem `J > 0.7`.

Der interne FT-Transport nutzt denselben SAFE-Provider 1.1 wie Levenshtein/OSA
und den einzigen physischen UnicodeScalar-Helfer. Aufrufrecht ist SELECT auf der
öffentlichen TVF; Deployment und administrativer Hash-Trust sind getrennt.
Es gibt keine IO-/Culture-/Datenzugriffe oder neue externe Referenz.
Die Floatberechnung ist ausdrücklich `IsPrecise=false`.

Zielmatrix: SQL Server 2019/2022/2025 auf Windows und Linux. Die neue 1.1
bestand separate Builds, Frameworkregression und IL-Metadatengates sowie
private native Gesamtadapter auf Linux 2019/latest CL150 und Windows 2025/CU8
CL150/160/170 lokal/zentral und SC-UTF8 einschließlich genuine 1.0-Upgrades,
Clienttransport und unabhängigem Cleanup. Weitere Ziele und tatsächliche
Minimalrechte bleiben offen; teilweise validiert und unveröffentlicht.
Die [Testdokumentation](../Tests/README.md) trennt historische 1.0-Evidenz
und den begrenzten doomed-Prozedurkontext der neuen Callerqualifikation.
Es gibt keine Heap-, Hardwall-, Parallelitäts-, SARGability- oder bitweise
plattformübergreifende Gleichheitszusage. Siehe den
[kanonischen Vertrag](../../../Documentation/Architecture/JARO_WINKLER_CONTRACT.md).
