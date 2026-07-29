# Auswahlvorbereitung für das zweite Toolbelt-Modul

## Dokumentstatus

| Feld | Wert |
|---|---|
| Zweck | Entscheidungsvorlage für die Besprechung des zweiten fachlichen Moduls |
| Status | `implemented; partially validated` |
| Prüfdatum | 2026-07-29 |
| Bevorzugter Kandidat | `TC-2026-012` – Base64-/Base64URL-Konvertierung |
| Alternative | `TC-2026-004` – `DATETRUNC`-Kompatibilität |
| Implementierungsfreigabe | Am 2026-07-29 ausdrücklich erteilt |
| Implementierungsblocker | Keine; das scopebezogene Qualitäts-Gate ist in `DEC-2026-021` dokumentiert |

Dieses Dokument hält die vorausgegangene Research- und Auswahlbegründung fest.
Der verbindliche öffentliche Vertrag steht nun in
`../Architecture/BASE64_MODULE_DESIGN.md`; die Pflichtprüfungen stehen in der
modulspezifischen Contract-Testmatrix.

## Ergebnis

`TC-2026-012` wurde als zweites Modul ausgewählt, besprochen und freigegeben.
Die Implementierung erfolgt in `toolbelt.conversion.base64`.

Der zuvor naheliegende Kandidat `TC-2026-004` wird zurückgestellt. Die
vertiefte Vertragsprüfung zeigt, dass ein einzelner T-SQL-Backport die native
`DATETRUNC`-Semantik nicht vollständig nachbilden kann, ohne vorab eine
sichtbare Abweichung beim Rückgabetyp oder eine Familie typspezifischer
Funktionen zu entscheiden.

## Vergleich

| Kriterium | `TC-2026-004` – DATETRUNC | `TC-2026-012` – Base64 |
|---|---|---|
| Versionslücke | SQL Server 2019 | SQL Server 2019 und 2022 |
| Native Referenz | SQL Server 2022+ | SQL Server 2025+ |
| Öffentliche Datengrenze | mehrere Date-/Time-Typen mit dynamischem Rückgabetyp und Scale | `varbinary` zu `varchar` und zurück |
| Zentrale Vertragsunsicherheit | feste UDF-Rückgabe versus native Typ-/Scale-Erhaltung | Standard/Base64URL, Padding, Whitespace und Fehlerparität |
| Sessionabhängigkeit | `week` hängt von `@@DATEFIRST` ab | keine entsprechende Sessionabhängigkeit bekannt |
| Providervergleich | T-SQL-Varianten und native Funktion | T-SQL/XML, optional `SAFE` CLR und native Funktion |
| Referenzvektoren | versions- und typabhängige Engine-Matrix | RFC 4648 plus SQL-Server-2025-Semantik |
| Eignung als zweiter vertikaler Slice | erst nach Grundsatzentscheidung zum Typsystem | gut, sofern LOB- und Fehlergrenzen vorab festgelegt werden |
| Empfehlung | zurückstellen | bevorzugt besprechen |

## Warum DATETRUNC vorerst zurückgestellt wird

Microsoft dokumentiert für `DATETRUNC` einen dynamischen Rückgabetyp: Typ und
gegebenenfalls Fractional Scale entsprechen dem Eingabewert. Eine skalare
benutzerdefinierte Funktion besitzt dagegen einen statisch definierten
Rückgabetyp. Daraus folgen drei mögliche, aber fachlich unterschiedliche
Produkte:

1. eine einzelne Funktion mit einem festen, dokumentierten Rückgabetyp wie
   `datetime2(7)`, die bewusst keine vollständige native Parität verspricht;
2. mehrere typspezifische Funktionen, die den Objektumfang deutlich erhöhen;
3. ein prozeduraler oder ausdrucksgenerierender Vertrag, der die einfache
   Verwendung der nativen Funktion nicht nachbildet.

Zusätzlich ist `datepart` in der nativen Syntax kein gewöhnlicher
Stringparameter. Ein Backport müsste unterstützte Werte selbst auflösen.
`week` hängt von `@@DATEFIRST` ab, `iso_week` dagegen nicht. T-SQL-UDFs
unterstützen außerdem weder dynamisches SQL noch `TRY...CATCH` oder
`RAISERROR`. Fehler- und Aliasverhalten können deshalb nicht beiläufig aus
der nativen Funktion übernommen werden.

Vor einer späteren Aktivierung von `TC-2026-004` müssen Rückgabetyp,
Objektfamilie, Datepart-Aliasse, ungültige Werte und `DATEFIRST`-Semantik
explizit besprochen werden.

## Vorgeschlagener Besprechungsrahmen für Base64

Die folgenden Punkte bildeten den Besprechungsrahmen. Die getroffenen
Entscheidungen sind im Moduldesign verbindlich dokumentiert.

### Öffentliche Oberfläche

Bevorzugte Ausgangsoption:

- zwei getrennte skalare Funktionen für Encode und Decode;
- Projektschema `toolbelt_conversion`;
- ausschließlich `varbinary` als Encode-Eingabe und `varchar` als
  Decode-Eingabe;
- `NULL` ergibt `NULL`;
- keine stillschweigende Zeichenkodierung von `nvarchar` oder `varchar`.

Die endgültigen Objektnamen, Parameter und Rückgabetypen wurden im
Moduldesign festgelegt.

### Standard und URL-safe

Zu entscheiden:

- Standard-Base64 und Base64URL in derselben Encode-Funktion über einen
  expliziten Modus oder in getrennten Funktionen;
- Standardausgabe mit RFC-4648-Padding;
- Base64URL-Ausgabe ohne Padding entsprechend der nativen
  SQL-Server-2025-Funktion;
- Decode-Akzeptanz für Standard- und URL-safe-Alphabet;
- optionale beziehungsweise erforderliche Padding-Akzeptanz;
- Behandlung von Leerzeichen, Tab, CR und LF.

Empfehlung: Die SQL-Server-2025-Semantik als Referenz verwenden, Abweichungen
auf älteren Providern nicht still akzeptieren, sondern als explizite
Contract-Entscheidung dokumentieren.

### Fehlervertrag

Zu entscheiden:

- ob ungültige Zeichen, fehlerhaftes Format und ungültiges Padding getrennte
  Modulfehler erhalten;
- ob der Backport die nativen Fehlerklassen semantisch abbildet, ohne fremde
  Engine-Fehlernummern zu imitieren;
- ob Whitespace vor der Validierung normalisiert wird;
- welche maximale Eingabegröße synchron verarbeitet wird.

Decode-Ausgaben sind untrusted binary data. Debug- und Hilfetexte dürfen
Eingaben oder dekodierte Inhalte nicht ungefragt ausgeben.

### Provider und Größenklassen

Vorgeschlagene Reihenfolge:

1. native Funktionen auf SQL Server 2025 als Referenzprovider;
2. T-SQL/XML-Provider auf SQL Server 2019 und 2022 für Korrektheit und kleine
   bis mittlere Werte;
3. `SAFE`-CLR-Provider nur nach messbarem, reproduzierbarem Vorteil und eigener
   Plattform-/Deployment-Entscheidung.

Für `varbinary(max)` und `varchar(max)` ist vor der Implementierung eine
reproduzierbare Größen- und Speichermatrix erforderlich. Ein formal erlaubter
LOB-Typ darf nicht automatisch als unbegrenzt praxistauglicher synchroner
Vertrag interpretiert werden.

## Vorläufige Contract-Testdimensionen

| Dimension | Mindestfälle |
|---|---|
| Standardvektoren | RFC-4648-Vektoren, leerer Wert und `NULL` |
| Alphabet | Standard und URL-safe |
| Padding | vollständig, ausgelassen, zu viel und Daten nach Padding |
| Whitespace | Space, Tab, CR und LF |
| Fehler | ungültiges Zeichen, ungültige Länge, ungültiges Padding |
| Größen | feste kleine Werte, Grenzwerte der Nicht-MAX-Typen und definierte LOB-Klassen |
| Roundtrip | Encode → Decode und Decode → kanonisches Encode |
| Providerparität | 2019/2022-Backport gegen SQL Server 2025 |
| Plattform | Windows und Linux, falls der gewählte Provider eine Plattformabhängigkeit erzeugt |
| Datenschutz | ausschließlich synthetische Binärwerte; keine Secrets oder Originaldaten |

## Gates und nächste Schritte

| Gate | Status | Erforderliche Aktion |
|---|---|---|
| Kandidatenvergleich | erfüllt | Dieses Dokument und die Kandidateneinträge aktuell halten |
| Auswahlbesprechung | erfüllt | `TC-2026-012` ausgewählt |
| Öffentlicher Funktionsvertrag | erfüllt | `BASE64_MODULE_DESIGN.md` |
| Funktionsbezogene Implementierungsfreigabe | erfüllt | ausdrücklich am 2026-07-29 |
| Scopebezogenes Qualitäts-Gate | erfüllt | `DEC-2026-021`; keine ResultTable-Abhängigkeit |
| Implementierung | erfüllt | Modulartefakte vorhanden |
| Runtime-Validierung | teilweise erfüllt | SQL Server 2025 Linux mit Compatibility Levels 150/160/170 erfolgreich; physische 2019-/2022- und Windows-Läufe offen |

Die offenen ResultTable-Pflichtfälle bleiben unabhängig bestehen. Sie werden
nicht als Evidenz für das Base64-Modul verwendet und blockieren dessen
unabhängige Contract-Prüfung nicht.

## Primärquellen

- [DATETRUNC (Transact-SQL)](https://learn.microsoft.com/en-us/sql/t-sql/functions/datetrunc-transact-sql?view=sql-server-ver17)
- [Create User-Defined Functions (Database Engine)](https://learn.microsoft.com/en-us/sql/relational-databases/user-defined-functions/create-user-defined-functions-database-engine?view=sql-server-ver17)
- [Scalar UDF inlining](https://learn.microsoft.com/en-us/sql/relational-databases/user-defined-functions/scalar-udf-inlining?view=sql-server-ver17)
- [BASE64_ENCODE (Transact-SQL)](https://learn.microsoft.com/en-us/sql/t-sql/functions/base64-encode-transact-sql?view=sql-server-ver17)
- [BASE64_DECODE (Transact-SQL)](https://learn.microsoft.com/en-us/sql/t-sql/functions/base64-decode-transact-sql?view=sql-server-ver17)
- [RFC 4648: Base-N Encodings](https://www.rfc-editor.org/rfc/rfc4648)
