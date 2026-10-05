# Safe Cast 1.0.0 – kanonischer Vertrag

Status: funktionsbezogen freigegeben am2026-10-05, Umsetzung aktiv.
RI-2026-076; die ausdrückliche Antwort „Diese sechs Funktionen freigegeben“
folgt der konkreten Vertragsbesprechung in [PR170](https://github.com/gecompat/SQL_Server_Toolbelt/pull/170).
Testcode oder native Engineproben qualifizieren diese APIs erst nach tatsächlicher Ausführung.

## Öffentliche API

`toolbelt.conversion.safe-cast` enthält genau sechs öffentliche, schemagebundene
Inline-T-SQL-TVFs im Schema `toolbelt_conversion`. Keine SVF, USP, CLR,
ResultTable-Abhängigkeit oder externe Eingabequelle.

| Objekt | Value-Typ | Zulässige Lexik |
|---|---|---|
| TVF_TryCastBigInt | bigint | Optionales ASCII +/−, mindestens eine ASCII-Ziffer |
| TVF_TryCastDecimal | decimal(38,18) | Wie bigint; optional ein Punkt mit mindestens einer Ziffer danach |
| TVF_TryCastDate | date | Exakt YYYY-MM-DD |
| TVF_TryCastDateTime2 | datetime2(7) | Exakt YYYY-MM-DDTHH:mm:ss; optional Punkt und1..7 Ziffern |
| TVF_TryCastBit | bit | Exakt0 oder1 |
| TVF_TryCastUniqueIdentifier | uniqueidentifier | Exakt36 ASCII-Hexzeichen/Bindestriche im8-4-4-4-12-Muster |

Das Vorzeichen ist U+002B oder U+002D, kein Unicode-Minus. GUID-Hexzeichen
dürfen Groß-/Kleinbuchstaben sein. Führende Ganzzahlnullen sind zulässig;
negative Null bleibt Null. Keine Leerzeichen, Trim, Exponenten, Tausendertrenner,
Localeformate, Braces, GUID-Suffixe, Datumszeitzonen oder Offsetentfernung.
Datum und Zeit verwenden ASCII-Ziffern und das große T. NUL, ungepaarte
Surrogate und sonstige Nicht-ASCII-Codeeinheiten erfüllen keine dieser Lexiken.

Parameterreihenfolge jeweils `@Text nvarchar(max)`, `@MaxInputBytes int=8192`.
Das Budget ist positiv und höchstens8192; kleinere Werte sind zulässig.
`DATALENGTH` zählt UTF16-Bytes einschließlich trailing spaces, unabhängig von
SC-, UTF8- und Datenbankcollation. Die Codeeinheitenprüfung verwendet explizites
BIN2 ohne SC. Die begrenzte Positionsmenge umfasst höchstens4096 Codeeinheiten.

Jeder Aufruf liefert genau eine Zeile mit genau drei Feldern:
`Value` im jeweiligen Zieltyp NULL, `Status varchar(16) NOT NULL`,
`ErrorCode varchar(32) NULL`. Textfelder verwenden Latin1_General_100_BIN2.
Kein Input-Echo und keine originale Enginefehlermeldung. Mengenverwendung über
CROSS APPLY oder OUTER APPLY; kein rekursionsabhängiger Callerhint.

## Ergebnis und Priorität

Die folgende Reihenfolge ist verbindlich, auch bei mehreren gleichzeitigen Fehlern.

| Priorität | Status | ErrorCode | Bedingung |
|---|---|---|---|
| 1 | SQL_NULL | NULL | Text ist SQL-NULL, auch bei ungültigem Budget |
| 2 | INVALID_ARGUMENT | PARAMETER | Budget NULL, nichtpositiv oder über8192 |
| 3 | LIMIT | INPUT_LIMIT | Eingabebytes überschreiten das gültige Budget |
| 4 | EMPTY | EMPTY | Eingabe hat0 Bytes |
| 5 | INVALID_FORMAT | FORMAT | Strikte Ziellexik verletzt |
| 6 | OUT_OF_RANGE | RANGE | Lexikalisch gültiger Wert außerhalb des Zielbereichs |
| 7 | LOSSY | SCALE | Innerhalb des Decimalbereichs, nichtnull Nachkommarest jenseits Skala18 |
| 8 | OK | NULL | Exakt repräsentierbarer Wert |

Nur OK trägt einen Wert; alle anderen Value-Felder sind NULL. Kalenderfehler,
Jahr0000 und unmögliche Zeitkomponenten sind RANGE nach erfolgreicher Lexik.
Bit2 ist FORMAT; es erfüllt die ausdrücklich auf0/1 beschränkte Lexik nicht.
Mehr als sieben Datetimefraction-Ziffern sind FORMAT, keine implizite Rundung.

## Exakte Zahlen

Bigint vergleicht den normalisierten Betrag gegen9223372036854775807 oder
bei negativem Vorzeichen9223372036854775808. Führende Nullstellen werden vor
der sicheren Konversion entfernt; lange Nullfolgen innerhalb des Budgets dürfen
keine künstliche native Längengrenze erzeugen.

Decimal hat maximal20 Ganzzahl- und18 Nachkommastellen. Nach Lexik wird der
exakte Betrag vor LOSSY geprüft: mehr als20 signifikante Ganzzahlstellen sind
RANGE. Bei20 Stellen überschreitet ausschließlich20 Ganzzahlneunen plus18
Nachkommaneunen plus ein späterer Nichtnullrest den maximalen Betrag.
Unter20 Stellen ist der Betrag innerhalb des Bereichs. Vorzeichen ändern die
symmetrische Decimalgrenze nicht. Überzählige Nachkommanullen dürfen exakt
entfallen; ein Nichtnullrest innerhalb des Bereichs ist SCALE. Die Konversion
erhält einen kurzen normalisierten Operanden, niemals einen gerundeten Wert
als Beweis für den mathematischen Bereich.

Beispiele: `99999999999999999999.9999999999999999990` ist OK;
derselbe Betrag mit letzter1 ist RANGE. `99999999999999999998.9999999999999999991`
ist SCALE. Die negativen Gegenstücke folgen derselben Klassifikation.

Alle Konversions-/Substring-/Längenausdrücke bleiben auch bei früher
Optimizer-Auswertung sicher. TRY_CONVERT verwendet ausschließlich zulässige
Text-zu-Ziel-Konversionen; CTE/APPLY/CASE werden nicht als Auswertungsbarriere
behauptet. Keine Performance-, Parallelitäts-, Heap- oder Produktionskapazitätszusage.

## Lifecycle und Abnahme

Local und central verwenden dieselben kanonischen Quellen und sechs IF-Slots.
Keine automatische Dependency-, Trust-, Konfigurations- oder Rechteänderung.
Read-only Preflight prüft vollständige Metadatensicht, Version/Modus, typische
Ownershipmarker, Objekttypen und fremde Consumer. Eigene atomare Transaktion
mit Application Lock; Callertransaktionen werden vor SET/DDL nicht-dooming
zurückgewiesen. Zentraler Uninstall benötigt ConfirmNoExternalConsumers=1.
Unbekannte Slots/Marker/Releases werden nicht adoptiert. Sourcehashes bleiben
diagnostisch; Wiederholung aktualisiert bekannte eigene Objekte.

Abnahme umfasst synthetische Grenz-/Fehlerwerte, Budgets, NULL-Priorität,
Native-vs-Lexik-Abweichung, lange Nullen, Calendar, Sprache/DATEFORMAT,
BIN2/CI/CS/SC/UTF8, APPLY und tatsächliche Clientmetadaten. Lifecycle prüft
Clean/Repeat, beide Modi, Consumer, Caller-/Lock-/Rollback-/Ownershipschutz
und ausschließlich eigene Bereinigung. Weitere physische Ziel- und
Minimalrechtekontexte bleiben sichtbar not executed, bis geprüft.

## Quellen und Alternativen

Native [TRY_CONVERT](https://learn.microsoft.com/en-us/sql/t-sql/functions/try-convert-transact-sql?view=sql-server-ver17)
ist die sichere Konversionsprimitive. Toolbelt ergänzt strengere Lexik und
stabile Diagnosen. Native [Decimalkonversion](https://learn.microsoft.com/en-us/sql/t-sql/data-types/decimal-and-numeric-transact-sql?view=sql-server-ver17)
kann die Skala durch Rundung reduzieren; der exakte Bereichs-/Restvergleich
ist eigene Vertragslogik. Native [GUID-Konversion](https://learn.microsoft.com/en-us/sql/t-sql/data-types/uniqueidentifier-transact-sql?view=sql-server-ver17)
ersetzt keinen vollständigen Längen-/Lexikbeweis. CLR/MSTVF bieten hier keinen
notwendigen Vorteil gegenüber einem begrenzten relationalen Ausdruck.
