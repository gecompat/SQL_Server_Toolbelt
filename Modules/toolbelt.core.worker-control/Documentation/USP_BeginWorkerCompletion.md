# USP_BeginWorkerCompletion

Verifiziert den Witness und hält den privaten Completion-Gate bis zum äußeren Commit/Rollback.

Interner attemptgebundener Providerpfad.

## Parameter

- `@SlotReservationId uniqueidentifier=NULL`
- `@ClaimToken uniqueidentifier=NULL`
- `@ExecutionId uniqueidentifier=NULL`
- `@Debug tinyint=0`
- `@Hilfe bit=0`

## Ergebnis

Der vollständige [Usage-Skill](../../../Metadata/UsageSkills/toolbelt_core/USP_BeginWorkerCompletion.md)
steht auch in der kanonischen DDL. `@Hilfe=1` liefert zusätzlich zur bisherigen
Standardhilfe eine vollständige Skillzeile mit `SkillFormatVersion`, `SchemaName`,
`ObjectName` und `SkillMarkdown nvarchar(max)`. Fachaufrufe gehören ausschließlich
in den kontrollierten Managedproviderpfad mit dessen tatsächlicher Connection-,
Transaktions- und Autoritätsbindung. Keine manuelle Recovery aus einzelnen
Helperaufrufen ableiten.

Kein fachliches Resultset.

Hilfe zuerst ohne fachliche Mutation; Debug erzeugt keine eigenen Messages. Kein fachlicher Resultset, keine OUTPUT-Parameter und keine ResultTable-/KeepData-Option. Bestehende Rechte, keine Grants. Fehler54210..54239 und unveränderte Engine-/Queuefehler. Sourcevorbereitung: not executed, unreleased.
