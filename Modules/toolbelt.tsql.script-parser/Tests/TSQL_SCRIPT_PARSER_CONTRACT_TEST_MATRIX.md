# T-SQL Script Parser Contract-Testmatrix

| Bereich | Pflichtnachweis |
|---|---|
| CLR | .NET Framework 4.8, ScriptDom-Integration, UNSAFE-Registrierung mit SHA2-512 |
| AST-Knoten | Hierarchische Pre-Order-Knotenliste mit Parent-Bezug und Typen (`TVF_ParseScriptNodes`) |
| Knoteneigenschaften | Skalare Eigenschaften, Bezeichner, Literale, Enums (`TVF_ParseScriptNodeProperties`) |
| Tokenstrom | Lückenloser, verlustfreier Tokenstrom mit Offsets und Zeilen (`TVF_TokenizeScript`) |
| Syntaxfehler | Erkennung fehlerhafter Syntax ohne Engine-Abbruch als strukturierte Zeilen (`TVF_ParseScriptErrors`) |
| Grenzen | Eingabelimit (`@MaxInputBytes`), Schachtelungstiefen-Wächter (`@MaxNestingDepth`) |
| Lifecycle | SHA2-512-Trust, Erst- und Wiederholungsdeployment, Dependency-Schutz, Central-Modus, Uninstall |
| Plattform | Windows (SQL Server 2019, 2022, 2025) |

Semantische Namens- und Spaltenauflösung sowie automatisches Rewriting sind nicht Bestandteil dieses Moduls.

## Aktuelle Validierungsevidenz

<!-- BEGIN GENERATED:MODULE_EVIDENCE -->
- Datum: `2026-09-03`
- Nachweis: `statische Vertragsprüfung und Build-Validierung`
- Scope: .NET Framework 4.8 Assembly, ScriptDom-Integration, 4 CLR-TVFs, Deployment- und Lifecycle-Skripte
- Ergebnis: `success`
<!-- END GENERATED:MODULE_EVIDENCE -->
