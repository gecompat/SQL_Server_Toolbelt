# Strikte Safe Casts

`toolbelt.conversion.safe-cast` 1.0.0 bietet genau sechs reine Inline-TVFs im
Schema `toolbelt_conversion`: BigInt, Decimal38/18, Date, DateTime2(7), Bit
und UniqueIdentifier. Der [kanonische Vertrag](../../Documentation/Architecture/SAFE_CAST_CONTRACT.md)
legt ASCII-/ISO-Lexik, Wertebereich, Verlustfreiheit und Fehlerpriorität fest.
Keine Localeinterpretation, stille Rundung, GUID-Trunkierung oder Eingabeveränderung.

Jede Funktion erhält `@Text nvarchar(max)` und `@MaxInputBytes int=8192`;
das Budget darf nur abgesenkt werden. Genau eine Zeile enthält `Value` im
Zieltyp, `Status varchar(16) NOT NULL` und `ErrorCode varchar(32) NULL`.
Nur OK trägt einen Wert. SQL_NULL hat Vorrang vor ungültigen Budgets.
Ausgabe enthält weder Eingabetext noch originale Enginefehler.

Für Mengen bevorzugt CROSS APPLY oder OUTER APPLY:

```sql
SELECT input.TextValue, converted.Value, converted.Status, converted.ErrorCode
FROM (VALUES(N'42'),(N'9223372036854775808'),(N' 42')) input(TextValue)
CROSS APPLY toolbelt_conversion.TVF_TryCastBigInt(input.TextValue, DEFAULT) converted;
```

SQL Server 2019/2022/2025 und Windows/Linux sind Zielplattformen; tatsächliche
Nachweise stehen getrennt in [Tests/README.md](Tests/README.md).
Kein CLR, Servertrust oder abhängiges Modul. Local/central installieren
dieselben sechs schemagebundenen IF-Objekte. SQLCMD-Deployment verwendet
`DeploymentMode=local|central`; zentraler Uninstall verlangt
`ConfirmNoExternalConsumers=1`. Installer erteilen keine Rechte.

Öffentliche Objektseiten:

- [TVF_TryCastBigInt](Documentation/TVF_TryCastBigInt.md)
- [TVF_TryCastDecimal](Documentation/TVF_TryCastDecimal.md)
- [TVF_TryCastDate](Documentation/TVF_TryCastDate.md)
- [TVF_TryCastDateTime2](Documentation/TVF_TryCastDateTime2.md)
- [TVF_TryCastBit](Documentation/TVF_TryCastBit.md)
- [TVF_TryCastUniqueIdentifier](Documentation/TVF_TryCastUniqueIdentifier.md)

[Beispiele](Examples/SafeCast.sql) und [Testmatrix](Tests/SAFE_CAST_TEST_MATRIX.md)
verwenden ausschließlich synthetische Daten. Das 8192-Byte-Limit begrenzt
Eingabetext; keine allgemeine Heap-, Durchsatz- oder Parallelitätszusage.

## Aktuelle Validierungsevidenz

<!-- BEGIN GENERATED:MODULE_EVIDENCE -->
- Datum: `2026-10-06`
- Nachweis: `local: Tests/CI/run-safe-cast-lab.ps1`
- Scope: Auf demselben bereits ausgewählten schema-validierten Windows2025/exaktCU8-Ziel bestanden zusätzlich CL150 und CL160 mit jeweils vollständigem local/central/Consumer-Adapter: je 13104 feste API-Oracles, 54 direkte Clientreader und 38 Lifecyclefälle. Je Exit0, vollständige Kanäle und leeres Stderr. Frische unabhängige Audits bestätigten COMPLETE38, drei eigene DBs abwesend, je zwei Marker-/Fremdslotfixtures exakt restauriert mit zwei Abweisungen sowie unveränderte Input- und sechs Sourcepins. Keine Konfigurations-/Rechte-/Truständerungen. Weitere physische Ziele, Minimalrechte, Heap und vollständige Runtime-Head-CI bleiben offen.
- Ergebnis: `success`
<!-- END GENERATED:MODULE_EVIDENCE -->
