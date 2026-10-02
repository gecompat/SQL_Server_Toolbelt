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

## Major 2.0.0: getrennte Pflichtnachweise

| Bereich | Prüfung | Status |
|---|---|---|
| Vorgeschalteter Kandidat | Exakte Dependency; 82 begrenzte Framework-Kindprozesse; Grenzen und Null-Dispatch bei Ablehnung; unabhängig wiederholt | `success`, 2026-10-02; ausschließlich Kandidaten-Gate |
| Integrierter Provider | Derselbe Wächtercode; vier APIs; Parametervalidierung und Fehlerpriorität; NULL-Text; Quoting-Flags und Legacy-Konstruktoren | `success`, 245 Framework-Kindprozesse, 2026-10-02 |
| AST | Gemeinsame iterative Traversierung, Parent-/Property-/Ordinalbezüge, Tiefengrenzen, deterministische Werte und Kulturunabhängigkeit | `success` im repräsentativen Framework-Korpus |
| Tokens/Errors | Lexikalisches Tokenize ohne Parse, Roundtrip/UTF-16-Offsets, lexikalische Fehler ohne Tokenausgabe, Diagnosepositionen und keine partiellen ASTs | `success` im Framework-Korpus und ausgewählten 2025-Labtests |
| Syntaxkorpus | DML, DDL, Prozeduren/Funktionen/DML-Trigger, CTE/JOIN/APPLY/Mengenoperationen, Transaktionen/TRY-CATCH, ausschließlich geparste Security-Statements; Versionskontraste 150/160/170 | `success`, repräsentativ statt vollständiger Syntaxabdeckung |
| Ausgabequoten | Tatsächliche Zeilen-/Verrechnungs-/Spaltenbreitengrenzen sowie separat injizierte interne Grenzen für atomare Ablehnung | `not executed`; abgesenkte Quoten ersetzen tatsächliche Limits nicht |
| Lifecycle | Saubere 2.0-Erstinstallation, echtes 1.0.0-Upgrade, Wiederholung, lokale/zentrale Nutzung, Marker-/Versions-/Dependency-Kollisionen, Caller-TX/SET-Erhalt, Uninstall und eigenes Cleanup | `success`, Windows 2025/CU8 CL150/160/170, 2026-10-02 |
| Lifecycle-Fehlerpfade | Fremdes unmarkiertes Schema/ScriptDom mit Sentinel bleiben unübernommen und unverändert; Lock-Contention blockiert beide Skripte; post-DROP-Fault rollt eigene Transaktion vollständig zurück | `success`, Windows 2025/CU8, lokaler und zentraler Modus |
| Lab Windows 2025 | Unmittelbar schema-validierte Auswahl mit erlaubter base/CU-Äquivalenz; keine Infrastrukturverwaltung oder Rechteausweitung | `success`, CU8 CL150/160/170, 2026-10-02 |
| Lab Windows 2019 | READY-/Login-Preflight bestanden; Modul-Live-Qualifikation separat | Modul-Live-Tests `not executed`, Aktivierung wegen fachfremder Pending-Konfiguration blockiert |
| Windows 2022 | Separate 2.0.0-Kombination | `not executed` |
| Minimale Rechte | Nur vorhandene Berechtigungen; keine Test-Grants | `not executed` |

Grenzen, stabile Fehlerpräfixe und Restrisiken sind im [Hardening-Vertrag](../../../Documentation/Architecture/TSQL_SCRIPT_PARSER_HARDENING_CONTRACT.md) beschrieben. Historische 1.0.0-Evidenz ist kein Nachweis dieser Matrix.

Semantische Namens- und Spaltenauflösung sowie automatisches Rewriting sind nicht Bestandteil dieses Moduls.

## Aktuelle Validierungsevidenz

<!-- BEGIN GENERATED:MODULE_EVIDENCE -->
- Datum: `2026-09-03`
- Nachweis: `statische Vertragsprüfung und Build-Validierung`
- Scope: Historisch nur 1.0.0: .NET Framework 4.8 Assembly, ScriptDom-Integration, 4 CLR-TVFs, Deployment- und Lifecycle-Skripte; kein 2.0.0-Nachweis.
- Ergebnis: `success`
<!-- END GENERATED:MODULE_EVIDENCE -->
