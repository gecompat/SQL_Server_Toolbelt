# toolbelt_core.USP_WriteConsoleMessage

**Typ:** Infrastruktur-Stored-Procedure ohne fachliches Resultset
**Status:** `implemented`; Runtime `partially validated`

## Zweck

Gibt lange Unicode-Texte vollständig als Messages aus. `@Immediate` wählt
zwischen gepuffertem `PRINT` und sofort gesendetem
`RAISERROR ... WITH NOWAIT`.

## Parameter

| Name | Typ | Default | Nullable | Beschreibung |
|---|---|---|---:|---|
| `@Message` | `nvarchar(max)` | `NULL` | ja | Payload; `NULL` und Leertext erzeugen keine Ausgabe. |
| `@Immediate` | `bit` | `0` | ja | `0` = `PRINT`; `1` = Severity-0-`RAISERROR` mit `NOWAIT`. Explizites `NULL` entspricht `0`. |
| `@Debug` | `tinyint` | `0` | ja | Standardparameter; V1 erzeugt keine zusätzlichen Debug-Messages. |
| `@Hilfe` | `bit` | `0` | ja | `1` gibt ausschließlich das Help-Resultset aus. |

## Ergebnis- und Fehlervertrag

Die normale Ausführung liefert kein Resultset und gibt bei Erfolg `RETURN 0`
zurück. Die Procedure erzeugt keine fachlichen Toolbelt-Fehler. Tatsächliche
Engine- oder Clientfehler werden nicht umklassifiziert.

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
150, 160 und 170. Physische Zielversions-, Windows- und weitere
Client-/Treiber-Läufe bleiben offen.
