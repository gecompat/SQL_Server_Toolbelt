# T-SQL Script Parser Contract-Testmatrix

> Die 2026-10-02-Nachweise unten gelten für den damaligen ScriptDom-Pin
> 18.0.56.2. Sie qualifizieren nicht den am 2026-10-07 ausgewählten
> ScriptDom 18.0.117.0-Pin.

## ScriptDom 18.0.117.0 – erneute Qualifikation

| Bereich | Pflichtnachweis | Status |
|---|---|---|
| Release-Artefakt | Exaktes NuGet-Binary, FileVersion `18.0.117.0`, SHA-512 `459E137268A4CA378023CD7E68A04655CEC2C19A8D01546E81B1A7ABF1FE2F9226A03CC3FA2323081C3C1B05626AF988C98527711D577919CF409367F853DAC7`; Parser-Provider-SHA-512 `2113ABD6828CE5A1454EF0259F7558F8744A0399E46345E4E54C9E012641BC983F5A0A08C6E2F7BF258A14EAEE5082FA6DE9E4DC25C813BDB5246D5D34701773` | `success`, lokaler deterministischer Release-Build |
| Statischer Vertrag und integriertes Framework | Pin-Konsistenz, Migration vom exakt vorherigen modul-eigenen Binary, 245 begrenzte Kindprozesse und 60 Guard-Prüfungen | `success`, statischer Validator; 245 Framework-Kindprozesse bei 262144 Byte Stack; 60 Guard-Prüfungen, 2026-10-07 |
| Historisches Kandidaten-Gate | 82 isolierte Kindprozesse vor Source, explizit mit neuem Binary-Paar | `not executed`, am 2026-10-09 durch ausdrückliche Benutzerentscheidung geschlossen und durch die rekonstruierte Offline-Qualifikation ersetzt. Es ist kein offenes Arbeitsgate und wird nicht erneut eingeplant. |
| Rekonstruierte Offline-Qualifikation | 82 isolierte Kindprozesse mit aktuellem Guard, Provider und exakt gepinntem neuen Binary-Paar | `success`, 2026-10-09; `Invoke-Contract.ps1 -QualificationProfile Reconstructed82`. Getrennte aktuelle Regression, kein Ersatz für historische Vor-Source-Evidenz. |
| SQL-Lifecycle | Saubere Erstinstallation sowie echtes 1.0.0→2.0.0-Upgrade mit altem ScriptDom-Pin, Upgrade auf neuen Pin, Repeat, Uninstall | `success`, 2026-10-11 auf ausgewähltem Windows-SQL-Server-2025-Labziel, lokal/zentral bei CL150/160/170; exakter eigener Trust und eigene Datenbanken bereinigt |
| Table Clone Trigger-Consumer | `IncludeTriggers=1` mit genau den neuen Parser-/ScriptDom-Hashes | `not executed`; der Parser-Live-Nachweis wird nicht auf den getrennten Trigger-Consumer übertragen |

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
- Datum: `2026-10-17`
- Nachweis: `local: Modules/toolbelt.tsql.ssis-debug/Tests/Runtime/Invoke-LabContract.ps1 -Full -Version 2019/2022/2025 -Modes local,central -PredecessorRoot (je Version)`
- Scope: Eng begrenzter gekoppelter Nachweis auf Windows SQL2019/2022/2025 lokal/zentral: Originalrelease2.0.0 mit exakt passendem TableClone4.1.0-Consumer installiert, ursprüngliche Triggerfixture ausgeführt, echter Upgrade auf Parser2.0.1/TableClone4.1.1, aktuelle Triggerfixture und Repeat bestanden. Installierter SSIS-Consumer schützt Parser/ScriptDom vor Uninstall; eigene Datenbank-/Trust-/Konfigurationsbereinigung mit frischem Audit bestanden. Functional mit erforderlicher Verschlüsselung und explizitem TrustServerCertificate=True; authentifizierte TLS-Abnahme separat not executed. Keine neue Vollqualifikation der vier Parser-APIs, Minimalrechte, tatsächlichen Ausgabeceilings oder Head-CI.
- Ergebnis: `success`
<!-- END GENERATED:MODULE_EVIDENCE -->
