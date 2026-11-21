# toolbelt_archive.TVF_InternalListZipEntriesClr

Interner CLR-Provider, kein zusätzlicher öffentlicher ZIP-Einstieg.

Der [vollständige Skill](../../../Metadata/UsageSkills/toolbelt_archive/TVF_InternalListZipEntriesClr.md) beschreibt die rohe Signatur ohne Defaults, Statusfelder und Grenzen. Verwende den [öffentlichen Einstieg](./USP_ListZipEntriesFromBinary.md). Die Modulberechtigung kann gezieltes SELECT auf diesen Provider erfordern; die interne Kennzeichnung erteilt selbst keine Rechte.

Writer-Erfolg ist ErrorNumber=0, Reader-Erfolg ErrorNumber IS NULL. Statuskonventionen nicht vermischen.

[SQL-Definition](../Source/TVF_InternalListZipEntriesClr.sql) · [Modul](../README.md)
