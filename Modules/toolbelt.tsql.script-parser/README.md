# T-SQL Script Parser

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
- Datum: `2026-10-09`
- Nachweis: `local: Scripts/New-ClrReleaseArtifacts.ps1; Tests/Framework/Invoke-Contract.ps1 -QualificationProfile Reconstructed82; Tests/Static/validate_contract.py`
- Scope: Aktuelle rekonstruierte Offline-Regression: exakter ScriptDom-18.0.117.0-Pin, reproduzierter .NET-Framework-4.8-Releasebuild und 82 isolierte Kindprozesse bei 262144 Byte Stack. Historischer vor-Source-Runner bleibt nicht ausgeführt, ist aber durch Benutzerentscheidung geschlossen; dieser Lauf ersetzt ihn nicht. Keine SQL-Ausführung, Trust-, Konfigurations- oder Rechteänderung.
- Ergebnis: `success`
<!-- END GENERATED:MODULE_EVIDENCE -->
