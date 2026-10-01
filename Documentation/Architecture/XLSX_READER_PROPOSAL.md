# Vorschlag: XLSX-Reader (`TC-2026-045`)

## Status

`TC-2026-045` bleibt Research. Dieses Dokument bereitet die spätere
Funktionsbesprechung vor. Es autorisiert weder einen Dateizugriff noch einen
Provider, ein SQL-Objekt oder die Verarbeitung eines realen Workbooks.

## Nutzerentscheidung und verpflichtender Folgescope vom 2026-10-01

Der Benutzer hat den begrenzten Binary-/Raw-/Text-/Cache-Scope als erste
Richtung bestätigt. Anzeigeformat, Styles, Culture und Datumsbehandlung
müssen als spätere Erweiterung dauerhaft im Backlog geführt werden. Das ist
eine Scope-Entscheidung, keine Freigabe des noch offenen Providers, konkreter
Reader-Signaturen oder einer Implementierung.

V1-Text bedeutet aufgelösten Shared-/Inline-String-Inhalt, keine formatierte
Excel-Anzeige. Numerischer Rohtext, Formeltext und vorhandener gespeicherter
Cachewert bleiben getrennt. Die spätere Erweiterung muss Styles und
Number-Formats, explizite Culture, 1900-/1904-Modus einschließlich des
historischen 1900-Schaltjahrsonderfalls sowie typisierte Datums-/Zeit- und
Dauerwerte besprechen. Sie ist verpflichtender Folgescope unter
`TC-2026-045`, aber nicht stillschweigend Bestandteil von V1.

## Empfohlene erste Grenze

V1 soll ein **datenbankseitig übergebenes XLSX-Binary** lesen und ein
normalisiertes, typisiertes Zellresultat zurückgeben. Ein Pfadparameter,
Freigabezugriff, Upload, Excel-Automation, VBA-/Makroausführung, externe
Beziehungen und ein Writer gehören nicht zum Scope.

Das Resultset enthält für jede vorhandene Zelle mindestens Sheet-Ordinal,
Sheet-Name, Zeilen- und Spaltenordinal, gespeicherten Zelltyp, Rohwert und
aufgelösten Stringtext sowie getrennten Formeltext und Cachewert. Damit bleibt die Ergebnisform unabhängig von einer
arbeitsmappenspezifischen Spaltenstruktur. Die Anwendung einer fachlichen
Tabelle, automatische Header-Erkennung und Datentypinferenz erfolgen erst
in späteren, getrennten Importverträgen.

## Unterstützte und ausgeschlossene Inhalte

| V1 unterstützt | V1 schließt aus |
|---|---|
| `.xlsx`-Open-XML-Container, sichtbare und ausgeblendete Worksheets, Shared Strings, Inline Strings, Boolean, numerische und Error-Zellwerte | `.xls`, `.xlsb`, `.xlsm`, Makros, ActiveX, externe Datenverbindungen und alle Ausführung von Workbook-Inhalten |
| gespeicherter Formeltext und gegebenenfalls gespeicherter Cachewert, klar getrennt | Formelberechnung, Recalculation, automatische Interpretation fehlender Cachewerte |
| 1900-/1904-Datumsmodus als Workbook-Metadatum | automatische Datums-/Zeitumrechnung ohne Stil- und Culturevertrag |
| explizite Ressourcen- und Containerlimits | Streamingzusagen, unbeschränkte Dateien oder unbeschränkte Shared-String-Tabellen |

Ein ausgeblendetes Sheet ist Metadatum, keine Sicherheitsgrenze. Makro- oder
Beziehungsinhalte werden nicht ausgeführt, aufgelöst oder als vertrauenswürdig
behandelt. Das Input-Binary bleibt untrusted und wird weder in Tests noch in
Diagnoseausgaben mit seinem Inhalt protokolliert.

## Providerentscheidung

Ein direktes T-SQL-Parsing von ZIP und Open XML wäre für Shared Strings,
Worksheet-Relationships, Formeln und Containerlimits zu fehleranfällig. Der
bevorzugte spätere Weg ist ein plattformfähiger, bewusst begrenzter Open-XML-
Provider hinter einem eigenen Deployment- und Berechtigungsvertrag. Der
vorhandene ZIP-Memory-Slice kann als interne Vorarbeit dienen, ersetzt jedoch
keine vollständige Open-XML-Semantik.

Der Provider darf keine Datei-, Netzwerk-, Prozess- oder Office-Automation
benötigen. Seine genaue Form (SQL CLR mit zulässigen Abhängigkeiten oder ein
kontrollierter externer Worker) wird erst nach Prüfung von Runtime,
Lizenz, Trust, Secret-Grenzen und Windows-/Linux-Deployment entschieden.

## Grenzen und Testmatrix

Ein begrenzter Provider-Spike soll zuerst die konkrete SDK-Version,
Dependency-/Lizenzkette, Memory-only-Verarbeitung und erforderliche
Assemblyrechte prüfen. Die offiziellen SDK-Hinweise nennen mögliche
Isolated-Storage-Probleme unter .NET Framework; `SAFE` und Verarbeitung ohne
Diskspill sind deshalb nachzuweisen, nicht vorauszusetzen. Keine
Hochprivilegierung oder externer Fallback entsteht automatisch aus dem Spike.
Öffentliche SQL-Objekte und Labtests gehören nicht zu dieser vorbereitenden
Dokumentationswelle.

Ungemessene V1-Prüfgrenzen zur Besprechung: 16 MiB komprimiert, 64 MiB
insgesamt dekomprimiert, 16 MiB je Part, 256 ZIP-Parts, 32 Worksheets,
100.000 vorhandene Zellen, 50.000 Shared Strings mit insgesamt 8 MiB
dekodiertem Text und XML-Tiefe 64. Eine Container-Ratio von 200 ist nur ein
Vorschlag; sie kann gültige, stark repetitive Workbooks ausschließen.
Die Zahlen sind keine Runtime-, Streaming- oder Performancezusage.

Vor der Implementierung werden maximale komprimierte und dekomprimierte
Containergröße, maximale Worksheets, Zellen, Zeilen, Spalten und
Shared-Strings festgelegt. Die Verarbeitung muss Limits vor vollständiger
Materialisierung durchsetzen und ZIP-/XML-Bomben als stabile Fehler
zurückweisen.

Tests verwenden ausschließlich selbst erzeugte Minimalworkbooks. Sie decken
Shared/Inline Strings, Unicode, leere und fehlende Zellen, Boolean, Zahlen,
Fehlerwerte, Formeltext mit/ohne Cache, 1900/1904-Metadaten, versteckte
Sheets, unzulässige Beziehungen, beschädigte ZIP-/XML-Strukturen und jedes
Ressourcenlimit ab. Nach Providerwahl folgen Deployment, Wiederholung,
Kollision, Lifecycle und die lokalen SQL_Server_Lab-Ziele für 2019, 2022 und
2025 unter Windows und Linux. Ein CU wird nur bei patchgebundenem Verhalten
gezielt gewählt.

## Entscheidungspunkt

Vor einer Implementierungsfreigabe wird der V1-Schnitt bestätigt oder
geändert: Binary-only-Eingabe und ein normalisiertes Zellresultat ohne
Formelausführung, Dateizugriff oder Typinferenz. Danach können Signatur,
Resultset-Schema, Limits, Errorvertrag und Provider als konkrete Funktion
besprochen und freigegeben werden.

## Quellen

- [Offizielles Open-XML-SDK: bekannte Probleme](https://github.com/dotnet/Open-XML-SDK#known-issues) – am 2026-10-01 geprüft; kein SQL-CLR-/SAFE-Nachweis.
- [Microsoft: Open XML SDK](https://learn.microsoft.com/en-us/office/open-xml/open-xml-sdk)
- [Microsoft: MS-XLSX](https://learn.microsoft.com/en-us/openspecs/office_standards/ms-xlsx/2c5dee00-eff2-4b22-92b6-0738acd4475e)
- [bestehender Candidate](../../Backlog/TOOLBELT_CANDIDATES.md#tc-2026-045-xlsx-dateien-direkt-lesen)
