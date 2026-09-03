# ScriptDOM SQL CLR Provider Feasibility Spike (TC-2026-047 / DEC-2026-029)

## Ergebnis

- **Bibliothek:** `Microsoft.SqlServer.TransactSql.ScriptDom.dll` (v18.0.x / 180.x, Microsoft, MIT-Lizenz).
- **Zielframework:** .NET Framework 4.7.2 / 4.8.
- **Referenzen:** `mscorlib 4.0.0.0`, `System.Core 4.0.0.0`, `System 4.0.0.0`, `System.Xml 4.0.0.0`.
- **Statische Felder:** Die Assembly enthält 127 veränderliche statische Felder (nicht `initonly`), unter anderem Parser-Optionen, Helper-Singletons und Typ-Mappings.
- **Permission Set:** Aufgrund der veränderlichen statischen Felder schlägt `PERMISSION_SET = SAFE` im SQL-CLR-Verifier fehl. Die Assembly erfordert **`PERMISSION_SET = UNSAFE`**.
- **Plattformauswirkung:** Da SQL Server auf Linux weder `EXTERNAL_ACCESS` noch `UNSAFE` für User-Assemblies unterstützt, ist ein ScriptDOM-basierter In-Database-Provider **Windows-only** (analog zu `toolbelt.filesystem.windows`, `DEC-2026-024`).
- **Trust:** Die Registrierung erfolgt über SHA2-512-Hash in `sys.trusted_assemblies` (unter Beibehaltung von `clr strict security = 1`). `TRUSTWORTHY ON` ist nicht erforderlich.

## Providervergleich

| Kriterium | Option A: ScriptDOM (CLR UNSAFE) | Option B: Eigener Lexer/Tokenizer (CLR SAFE) | Option C: T-SQL Lexer |
|---|---|---|---|
| **Grammatik** | Vollständig für alle SQL-Server-Versionen (2019–2025), DDL, DML, CTE, Hints, JSON, XML | Nur Tokenstrom + Basisknoten (SELECT/FROM/JOIN/WHERE), keine vollständige AST-Grammatik | Stark begrenzt, langsame String-Schleifen |
| **Permission Set** | `UNSAFE` (127 mutable statics) | `SAFE` | Kein CLR nötig |
| **Plattformen** | Windows (Linux nicht unterstützt) | Windows und Linux | Windows und Linux |
| **Dependencies** | `Microsoft.SqlServer.TransactSql.ScriptDom.dll` (MIT) | Keine (nur `System`, `System.Data`) | Keine |
| **Leistung** | Sehr hoch (optimierter C#-Parser, < 1 ms für typische Statements) | Sehr hoch (< 0.5 ms) | Mittel bis langsam |
| **AST-Tiefe** | Vollständiger hierarchischer AST | Nur flache Token-/Identifer-Liste | Nur Bezeichnerzerlegung |

## Sicherheits- und Stabilitätsregeln für ScriptDOM CLR

1. **Stack-Overflow-Wächter:** Da ScriptDOM ein rekursiver Parser ist, prüft der CLR-Wrapper vor dem Parsen die Klammerungs- und Schachtelungstiefe (`@MaxNestingDepth`, Standard: 256), um CLR-StackOverflowExceptions (die den SQL-Prozess beenden würden) zu verhindern.
2. **Eingabelängenbegrenzung:** Standardmäßig maximal 2 MiB pro Aufruf (`@MaxInputBytes = 2097152`).
3. **Kein Datenzugriff:** `DataAccessKind.None`, `SystemDataAccessKind.None`.
4. **Keine veränderlichen Caches im Wrapper:** Der eigene Wrapper `Toolbelt_Tsql_ScriptParser` hält keinen statischen Zustand.

## Quellen und Binärmetadaten

- Microsoft SqlScriptDOM: https://github.com/microsoft/SqlScriptDOM
- NuGet: `Microsoft.SqlServer.TransactSql.ScriptDom`
- SHA2-512-Prüfsumme (v18.0.56.2): wird im Build-Manifest generiert.
