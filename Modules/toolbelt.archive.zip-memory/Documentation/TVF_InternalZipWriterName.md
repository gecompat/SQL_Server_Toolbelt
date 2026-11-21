# toolbelt_archive.TVF_InternalZipWriterName

Interner CLR-Provider, kein zusätzlicher öffentlicher ZIP-Einstieg.

Der [vollständige Skill](../../../Metadata/UsageSkills/toolbelt_archive/TVF_InternalZipWriterName.md) beschreibt die rohe Signatur ohne Defaults, Statusfelder und Grenzen. Verwende den [öffentlichen Einstieg](./USP_CreateZipFromEntries.md). Die Modulberechtigung kann gezieltes SELECT auf diesen Provider erfordern; die interne Kennzeichnung erteilt selbst keine Rechte.

Writer-Erfolg ist ErrorNumber=0, Reader-Erfolg ErrorNumber IS NULL. Statuskonventionen nicht vermischen.

[SQL-Definition](../Source/ZipWriterClr.sql) · [Modul](../README.md)
