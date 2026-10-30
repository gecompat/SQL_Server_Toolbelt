# toolbelt_core.USP_WriteConsoleMessage

**Typ:** Infrastruktur-Stored-Procedure ohne fachliches Resultset
**Status:** `implemented`; Runtime `validated`

## Zweck

Gibt lange Unicode-Texte vollständig als Messages aus. `@Immediate` wählt
zwischen gepuffertem `PRINT` und sofort gesendetem
`RAISERROR ... WITH NOWAIT`.

## Parameter

<!-- API_PARAMETERS:BEGIN -->
| Parameter | SQL-Typ | Default | Richtung | Erklärung / Werte |
|---|---|---|---|---|
| `@Message` | `nvarchar(max)` | `NULL` | Input | Auszugebender Unicode-Text als nvarchar(max), maximal 1048576 UTF-16-Bytes und höchstens 512 berechnete Frames. CR/LF und Prozentzeichen sind Inhalt, kein Formatstring. Default/NULL und leerer Text erzeugen keine Ausgabe; Überschreitung wird vor erster Ausgabe abgewiesen. |
| `@Immediate` | `bit` | `0` | Input | Taxativ für bit: 0 puffert über PRINT mit bis 4000 Codeeinheiten je Frame (Default); 1 nutzt RAISERROR Severity 0 WITH NOWAIT mit bis 2000 Codeeinheiten je Frame. NULL entspricht 0; konkrete Clientpufferung bleibt vom Client abhängig. |
| `@Debug` | `tinyint` | `0` | Input | tinyint 0..255 oder NULL, Default 0; in dieser Procedure haben alle diese Werte bewusst keine Wirkung und erzeugen keine zusätzliche Diagnose. |
| `@Hilfe` | `bit` | `0` | Input | Taxativ für bit: 1 liefert ausschließlich Hilfe und ignoriert alle anderen Argumente; 0 führt die Messageausgabe aus (Default). NULL wird wie 0 behandelt. |
<!-- API_PARAMETERS:END -->

## Ergebnis- und Fehlervertrag

Die normale Ausführung liefert kein Resultset und gibt bei Erfolg `RETURN 0`
zurück. Fehler `52801` weist mehr als 1 MiB UTF-16 zurück; `52802` mehr als
512 Frames. Beide Grenzen werden vor erster Ausgabe geprüft, ohne Teiltext
oder Kürzung. Tatsächliche Engine- oder Clientfehler werden nicht umklassifiziert.

`@Hilfe = 1` liefert das Help-Resultset gemäß
[`USP_CONTRACT.md`](../../../Documentation/Standards/USP_CONTRACT.md). Der
deklarative `RESULT_COLUMN`-Eintrag beschreibt ausdrücklich, dass kein
fachliches Resultset existiert.

## Chunking

| Provider | Chunkgröße | Verhalten |
|---|---:|---|
| `PRINT` | 4.000 UTF-16-Codeunits | SQL Server beziehungsweise Client darf puffern. |
| `RAISERROR ... NOWAIT` | 2.000 UTF-16-Codeunits | Severity 0; sofortige Übergabe an den Client angefordert. |

`Latin1_General_100_BIN2` ermöglicht eine codeunit-genaue Grenzprüfung.
Erkannte High-/Low-Surrogatpaare werden nicht getrennt. Der NOWAIT-Pfad
verwendet ein festes `%s`, daher bleiben Prozentzeichen Nutzdaten.

## Rechte und Seiteneffekte

Erforderlich ist `EXECUTE` auf der Procedure. Es gibt keine
Rechteausweitung, Datenmutation oder explizite Transaktion. Message-Ausgabe
kann langsam sein und gehört nicht in einen zeilenweisen Hot Path.

## Beispiele

```sql
EXEC toolbelt_core.USP_WriteConsoleMessage
      @Message = N'Gepufferte Ausgabe'
    , @Immediate = 0;

EXEC toolbelt_core.USP_WriteConsoleMessage
      @Message = N'Fortschritt: 100 %'
    , @Immediate = 1;

EXEC toolbelt_core.USP_WriteConsoleMessage @Hilfe = 1;
```

## Einschränkungen

Reihenfolge und Payload-Chunks sind Enginevertrag. Pufferung, Präfixe,
Zeilenformatierung und Darstellung der Message-Frame-Grenzen hängen von
Client beziehungsweise Treiber ab.

Die [W2c-Runtime
30573135975](https://github.com/gecompat/SQL_Server_Toolbelt/actions/runs/30573135975)
belegt den Enginevertrag auf SQL Server 2025 Linux mit Compatibility Levels
150, 160 und 170. Die Nachqualifikation vom 2026-10-19 ergänzt die
vollständige physische Windows-/Linux-Matrix auf SQL Server 2019/2022/2025
sowie zusätzliche ADO.NET-/ODBC-Prüfungen. Details und Aussagegrenzen:
[Clientprüfung](../Tests/README.md#clientprüfung-2026-10-19).
