# T-SQL Script Parser Contract-Testmatrix

> Die 2026-10-02-Nachweise unten gelten für den damaligen ScriptDom-Pin
> 18.0.56.2. Sie qualifizieren nicht den am 2026-10-07 ausgewählten
> ScriptDom 18.0.117.0-Pin.

## ScriptDom 18.0.117.0 – erneute Qualifikation

| Bereich | Pflichtnachweis | Status |
|---|---|---|
| Release-Artefakt | Exaktes NuGet-Binary, FileVersion `18.0.117.0`, SHA-512 `459E137268A4CA378023CD7E68A04655CEC2C19A8D01546E81B1A7ABF1FE2F9226A03CC3FA2323081C3C1B05626AF988C98527711D577919CF409367F853DAC7`; Parser-Provider-SHA-512 `E03C6099E2E919F3F930E2CCB5A753C47F16DABFC18B608F8BC33DEA5E93ED10D9A937CF599427FADED4EBBB11653E80D2C8BA23C49E5AAEEB0A80C60D51EDBF` | `success`, lokaler deterministischer Release-Build |
| Statischer Vertrag und integriertes Framework | Pin-Konsistenz, Migration vom exakt vorherigen modul-eigenen Binary, 245 begrenzte Kindprozesse und 60 Guard-Prüfungen | `success`, statischer Validator; 245 Framework-Kindprozesse bei 262144 Byte Stack; 60 Guard-Prüfungen, 2026-10-07 |
| Kandidaten-Gate | 82 isolierte Kindprozesse vor Source, explizit mit neuem Binary-Paar | `not executed`; der frühere private Runner ist im Repository und in den verfügbaren lokalen Arbeitsartefakten nicht vorhanden |
| SQL-Lifecycle | Saubere Erstinstallation sowie echtes 1.0.0→2.0.0-Upgrade mit altem ScriptDom-Pin, Upgrade auf neuen Pin, Repeat, Uninstall | `not executed`; gültiger Lab-Vertrag fehlt, CLR ist deaktiviert und der neue Trusthash ist nicht freigegeben |
| Table Clone Trigger-Consumer | `IncludeTriggers=1` mit genau den neuen Parser-/ScriptDom-Hashes | `not executed`; gleicher Lab-/Trust-Blocker |

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
