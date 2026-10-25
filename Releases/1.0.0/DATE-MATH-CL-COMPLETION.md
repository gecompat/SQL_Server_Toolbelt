# Date-Math-Callerrechte: vollständige CL-Matrix

Stand 2026-10-25. Die sechs bisher fehlenden niedrigeren CL-Fälle bestehen
mit derselben festen Callerfixture. Zusammen mit den exakt gebundenen sechs
höchsten CL-Fällen sind vier öffentliche DateBucket-/CalendarDifference-TVFs
auf zwölf Ziel-/CL-Kombinationen lokal und direkt zentral qualifiziert.

| Plattform | Wiederverwendet | Neu ausgeführt |
|---|---|---|
| Linux | SQL2019/CL150, SQL2022/CL160, SQL2025/CL170 | SQL2022/CL150, SQL2025/CL150/160 |
| Windows | SQL2019/CL150, SQL2022/CL160, SQL2025/CL170 | SQL2022/CL150, SQL2025/CL150/160 |

Der [ursprüngliche Teilbericht](DATE-MATH-HIGHEST-CL-QUALIFICATION.md) und seine
JSON-Datei bleiben als historischer Ausführungsstand erhalten. Die
[additive Projektion](date-math-cl-completion.json) bindet ihn per SHA256 und
unterscheidet wiederverwendete und neue Fälle. Vor Wiederverwendung wurden
Fixture, Installationsbytes, Fallauswahl, Labbindung und sämtliche Quellpins
exakt verglichen. Unveränderte grüne Zielprüfungen wurden nicht wiederholt.

Die gemeinsamen festen Orakel und Einzelrechte bleiben unverändert: vier
SELECT-Profile, getrennte Abweisung des internen Bucket-Kerns und des
ResultTable-Helfers, fehlender Grant und REVOKE mit exakt SQL229. Insgesamt
bestehen 96 positive Einzelgrantprofile und 672 SQL229-Abweisungen. Die beiden
ursprünglichen verworfenen Gegenkontrollen bleiben gebunden. Nach allen
Verbrauchern wurden alle 14 terminalen Journale unabhängig erneut auditiert;
alle 26 eigenen Datenbanknamen waren abwesend.

Der [Testweg](../../Tests/Release/README.md#native-funktions-callerrechte-prüfen)
und die dort beschriebene feste Komposition ändern sich nicht. Die zusätzliche
Offlineprüfung `Tests/Release/test_additive_caller_qualification.py` prüft die
Vollständigkeit ohne doppelte Fälle, historische Bindung und aktuelle Quellpins.

Dieser Abschluss gilt für die Callerprofile. Vollständige API-, Client-,
Lifecycle- und Ressourcengates behalten ihren eigenen Scope. Echte Lowpriv-
CrossDB-Mappings und authentifiziertes TLS sind nicht qualifiziert. Functional
verwendet den schema-validen Labvertrag mit Verschlüsselung und dessen
explizitem Trustwert. Produkt-SQL, Status und Pakete bleiben unverändert;
Veröffentlichung und Tags sind nicht freigegeben. Weitere
[Releasegates](RELEASE-GATES.md) bleiben offen.
