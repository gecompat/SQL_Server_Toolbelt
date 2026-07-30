# `TVF_ParseSemanticVersion`

Signatur: `TVF_ParseSemanticVersion(@Version varchar(8000))`.

Die Funktion liefert genau eine Zeile mit `IsValid`, `ValidationCode`,
`Major`, `Minor`, `Patch`, `PreRelease`, `BuildMetadata` und
`CanonicalVersion`. Gültig ist ausschließlich SemVer 2.0.0. Numerische Core-
und Pre-release-Identifier dürfen keine führenden Nullen besitzen.

Aktuelle Evidenz:
https://github.com/gecompat/SQL_Server_Toolbelt/actions/runs/30517137373
