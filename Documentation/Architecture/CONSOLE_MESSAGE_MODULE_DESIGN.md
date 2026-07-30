# Moduldesign: Console Message

## Status und Freigabe

`TC-2026-016` wurde am 2026-07-30 im V1-Scope von W2c ausdrücklich
freigegeben. Das Modul heißt `toolbelt.core.console-message`, Version `1.0.0`.

## Öffentlicher Vertrag

Einziges persistentes Objekt ist
`toolbelt_core.USP_WriteConsoleMessage(@Message nvarchar(max) = NULL,
@Immediate bit = 0, @Debug tinyint = 0, @Hilfe bit = 0)`.

- `@Immediate = 0`: `PRINT`, höchstens 4.000 UTF-16-Codeunits je Chunk;
- `@Immediate = 1`: `RAISERROR(N'%s', 0, 1, @Chunk) WITH NOWAIT`, höchstens
  2.000 UTF-16-Codeunits je Chunk;
- `NULL` und Leertext erzeugen keine Ausgabe;
- vorhandene Zeilenumbrüche und Prozentzeichen bleiben Payload;
- V1 erzeugt keine Präfixe, Zeitstempel, wählbare Severity oder Resultsets.

`@Debug` ist Teil des verbindlichen USP-Vertrags, erzeugt in V1 aber keine
zusätzliche Ausgabe. Dadurch bleibt die Nutzlast unverändert. `@Hilfe = 1`
liefert ausschließlich das standardisierte Help-Resultset.

## Unicode und Chunking

`PRINT` begrenzt `nvarchar` auf 4.000 Zeichen. `RAISERROR` besitzt ein
2.047-Zeichen-Limit und benötigt internen Platz für Formatparameter. Der
NOWAIT-Pfad verwendet deshalb konservativ 2.000 Zeichen und ein festes `%s`;
Prozentzeichen im Payload werden nicht als Formatstring interpretiert.

`LEN` und `SUBSTRING` werden mit `Latin1_General_100_BIN2` als UTF-16-
Codeunits ausgewertet. Endet ein Chunk mit einem High Surrogate und beginnt
der nächste mit dem zugehörigen Low Surrogate, wird die Grenze um eine
Codeunit vorgezogen. Nachgestellte Leerzeichen werden durch einen temporär
angehängten Nicht-Leerraum korrekt gezählt.

## Aussagegrenzen

Dokumentiert: Reihenfolge, vollständige Payload-Chunks und der
Unicode-sichere Enginepfad sind Modulvertrag.

Client- und Treiberverhalten: Pufferung, Präfixe, Zeilenformatierung und die
Darstellung von Message-Frame-Grenzen liegen außerhalb des Enginevertrags.
Insbesondere können Clients Chunkgrenzen als zusätzliche visuelle Zeilen
darstellen.

Message-Ausgabe ist linear und vergleichsweise teuer. Die Procedure ist für
Debug-, Fortschritts- und generierte SQL-Texte bestimmt, nicht für
zeilenweise Ausgabe in Hot Paths. Sie maskiert keine Secrets; Aufrufer bleiben
für zulässige Payloads verantwortlich.

## Deployment und Tests

Lokales und zentrales Deployment verwenden dieselbe Procedure. Die
Runtime-Matrix prüft Compatibility Levels 150/160/170, Help, Parameter,
NULL-/Leertext, beide Provider, Prozentzeichen, Supplementary Characters,
lange Payloads, Wiederholungsdeployment, Central-Aufruf und Uninstall.

Primärquellen:

- [Microsoft: PRINT](https://learn.microsoft.com/en-us/sql/t-sql/language-elements/print-transact-sql?view=sql-server-ver17)
- [Microsoft: RAISERROR](https://learn.microsoft.com/en-us/sql/t-sql/language-elements/raiserror-transact-sql?view=sql-server-ver17)
- [Microsoft: SUBSTRING und Supplementary Characters](https://learn.microsoft.com/en-us/sql/t-sql/functions/substring-transact-sql?view=sql-server-ver17)
