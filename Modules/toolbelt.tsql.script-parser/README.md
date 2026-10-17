# T-SQL Script Parser

Patch 2.0.1 vom 2026-10-16 extrahiert den gemeinsamen lexikalischen Vorfilter
für das separat freigegebene [SSIS-Debug-Modul](../toolbelt.tsql.ssis-debug/README.md).
Die vier öffentlichen TVFs behalten ihre bisherigen Grenzen. Die aktuelle
Patchqualifikation umfasst 245 isolierte Framework-Kindprozesse, 60 Guardfälle
und statische Vertragsprüfungen. Zusätzlich sind der echte 2.0.0→2.0.1-Upgrade
und die gekoppelte Table-Clone-Triggerregression nativ geprüft; siehe
[SSIS-Prüfmatrix](../toolbelt.tsql.ssis-debug/Tests/README.md).
Weitere Parserqualifikation bleibt getrennt offen. Frühere Laufzeitnachweise
gelten für ihre damaligen Versionen und Binarypins.

`toolbelt.tsql.script-parser` stellt deterministische, rein lesende SQL-CLR Table-Valued Functions (TVFs) auf Basis von Microsoft ScriptDom (.NET Framework 4.8) bereit, um begrenzten T-SQL-Code syntaktisch in AST-Knoten, Knoteneigenschaften, einen verlustfreien Tokenstrom und strukturierte Fehlerlisten zu zerlegen.

## Kompatibilität der Major-Version 2.0.0

Der [Hardening-Vertrag](../../Documentation/Architecture/TSQL_SCRIPT_PARSER_HARDENING_CONTRACT.md) beschreibt die gemeinsamen Parameter-, Fehler-, Ressourcen- und Lifecycle-Grenzen. Die vier Funktionsnamen, Parameterreihenfolge und Ergebnisschemas bleiben erhalten. Bewusste Inkompatibilitäten gegenüber 1.0.0 sind endliche NULL-Limits, die Ablehnung unbekannter Parser-Versionen, konservative Ablehnung komplexer gültiger Skripte, keine partiellen AST-Ausgaben und ausschließlich lexikalisches Tokenize.

NULL-Text liefert stets null Zeilen. Sonst sind ausschließlich Parser-Versionen 80, 90, 100, 110, 120, 130, 140, 150, 160 und 170 zulässig; NULL wählt 160. Das Eingabelimit beträgt standardmäßig 2.097.152 UTF-16-Bytes und darf explizit nur 1..2.097.152 betragen. Die AST-Tiefe ist standardmäßig 100, explizit 1..256, mit Wurzel auf Tiefe 0. Der gemeinsame Rohtextwächter läuft vor ScriptDom: 512 Atome, 8.192 Rohtexteinheiten, aktive Klammer-/CASE-/BEGIN-Tiefe `min(32, angeforderte Tiefe)` und 16 verschachtelte Blockkommentare. Zähler gelten kumulativ über alle Batches; gültige größere Skripte können bewusst abgelehnt werden.

Ausgaben werden vollständig geprüft, bevor die erste Zeile geliefert wird. Nodes erlauben 32.768, Properties 131.072, Tokens 8.192 und Errors 256 Zeilen; zusätzlich gelten 16.777.216 verrechnete Bytes je Aufruf und die vorhandenen Spaltenbreiten. Diese Grenzen garantieren weder eine physische Heap-Obergrenze noch Laufzeit oder Stackverhalten für jede Eingabe. Parsing ersetzt keine semantische Referenzauflösung und keine sichere Rewriting-Freigabe.

Upgrade von 1.0.0 und Wiederholung von 2.0.0 erfordern konsistente Modul-/Objektmarker. Unbekannte installierte Versionen und fremde gleichnamige Objekte werden vor Änderungen zurückgewiesen. Install/Upgrade/Uninstall lehnen vorhandene Caller-Transaktionen vor SET-Änderungen ab; SQLCMD muss bei Fehlern abbrechen. Fremde Schemas und Assemblies werden nicht übernommen. Die genaue Dependency bleibt auf dem im Vertrag angegebenen Binary gepinnt; historische 1.0.0-Nachweise qualifizieren 2.0.0 nicht.

## Funktionen

- `toolbelt_tsql.TVF_ParseScriptNodes`: Hierarchischer AST-Knotenbaum in Pre-Order-Reihenfolge.
- `toolbelt_tsql.TVF_ParseScriptNodeProperties`: Skalare Knoteneigenschaften (z. B. Bezeichnernamen, Literalwerte, Enums).
- `toolbelt_tsql.TVF_TokenizeScript`: Lückenloser Tokenstrom inklusive Offsets, Zeilen und Spalten.
- `toolbelt_tsql.TVF_ParseScriptErrors`: Strukturierte Syntaxfehlerausgabe als Datenzeilen.

## Plattform- und Providerbesonderheiten

- **Plattform:** Windows (SQL Server 2019, 2022, 2025). SQL Server auf Linux unterstützt keine `UNSAFE`-Assemblies und ist nicht anwendbar.
- **Assembly:** `Toolbelt_Tsql_ScriptParser` / `Toolbelt.Tsql.ScriptParser.dll`.
- **Trust:** Die Freigabe erfolgt über den exakten SHA2-512-Hash via `sys.sp_add_trusted_assembly` unter Beibehaltung von `clr strict security = 1`.

## Aktuelle Validierungsevidenz

<!-- BEGIN GENERATED:MODULE_EVIDENCE -->
- Datum: `2026-10-17`
- Nachweis: `local: Modules/toolbelt.tsql.ssis-debug/Tests/Runtime/Invoke-LabContract.ps1 -Full -Version 2019/2022/2025 -Modes local,central -PredecessorRoot (je Version)`
- Scope: Eng begrenzter gekoppelter Nachweis auf Windows SQL2019/2022/2025 lokal/zentral: Originalrelease2.0.0 mit exakt passendem TableClone4.1.0-Consumer installiert, ursprüngliche Triggerfixture ausgeführt, echter Upgrade auf Parser2.0.1/TableClone4.1.1, aktuelle Triggerfixture und Repeat bestanden. Installierter SSIS-Consumer schützt Parser/ScriptDom vor Uninstall; eigene Datenbank-/Trust-/Konfigurationsbereinigung mit frischem Audit bestanden. Functional mit erforderlicher Verschlüsselung und explizitem TrustServerCertificate=True; authentifizierte TLS-Abnahme separat not executed. Keine neue Vollqualifikation der vier Parser-APIs, Minimalrechte, tatsächlichen Ausgabeceilings oder Head-CI.
- Ergebnis: `success`
<!-- END GENERATED:MODULE_EVIDENCE -->
