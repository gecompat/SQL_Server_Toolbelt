# USP_FailWorkCore

Interner kanonischer Queuekern. Regulär den öffentlichen Einstieg
[`USP_FailWork`](USP_FailWork.md) verwenden; geschützte Managedparameter
sind keine frei nutzbare Admission-/Terminalautorität.

Der vollständige [Usage-Skill](../../../Metadata/UsageSkills/toolbelt_core/USP_FailWorkCore.md)
beschreibt jeden Parameter, Ausgabeform, Transaktions-/Savepointverhalten,
Rechte und Aussagegrenzen. Derselbe Text steht in der kanonischen DDL.

```sql
EXEC toolbelt_core.USP_FailWorkCore @Hilfe=1;
```

Die Hilfe liefert die bisherige Standardhilfe plus genau eine vollständige
vier-spaltige Skillzeile. Historische Fachbelege qualifizieren ausschließlich
ihre ursprünglichen Artefakte; die zusätzliche Hilfe ist separat abzunehmen.
