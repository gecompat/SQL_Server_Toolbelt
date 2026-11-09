# Split Advanced: echter gemappter SQL-Caller über Datenbankgrenzen

Stand 2026-11-09: **PASS_FOR_DECLARED_SQL_MAPPED_CALLER_SCOPE** auf
Windows SQL Server 2025/CU8, CL170, zentrale Installation mit getrennter
Consumerdatenbank. Der vollständige korrigierte Lauf und sein frischer
unabhängiger Abschlussaudit bestehen. Produkt-SQL und Modulstatus bleiben
unverändert. Die [vorhandene Caller-Matrix](SPLIT-ADVANCED-CL-COMPLETION.md)
bleibt für ihre zwölf Engine-/CL-Paare gültig; sie wird nicht wiederholt.

## Identität und Rechte

Die ausdrücklich freigegebene Ausnahme erzeugt ausschließlich einen eigenen
temporären SQL-Login mit vorab gebundener zufälliger SID und je einen exakt
gemappten Benutzer in zwei eigenen Testdatenbanken. Der gesamte explizite
Rechtescope besteht aus CONNECT in beiden DBs und SELECT ausschließlich auf
`toolbelt_string.TVF_SplitAdvanced` in der Installationsdatenbank. Keine
zusätzlichen Serverrollen, Sichtbarkeits-, Schema-, Helper- oder Datenrechte.
Das Loginpasswort wird nur im Prozessspeicher erzeugt und nie serialisiert.

Jeder Fall verwendet eine frische ungepoolte SQL-Clientverbindung. SID,
ORIGINAL_LOGIN, Benutzername und fehlende administrative Rechte werden im
Caller geprüft. Eine administrative Beobachterverbindung bestätigt dieselbe
SPID, den eigenen zufälligen Context-Tag, beide Sitzungs-SIDs und tatsächlich
SQL-Authentifizierung über TCP. EXECUTE AS ersetzt keinen Netzwerknachweis.

| Profil | Natives Ergebnis |
|---|---|
| Installation noch ohne Benutzerzuordnung | Datenbankzugriff mit SQL916 verweigert |
| Gemappter Benutzer, nur CONNECT | Split-Aufruf mit SQL229 verweigert |
| Einzelnes SELECT auf Split-TVF | drei exakte Originaltokens, Ordinals 1–3, gültige Zeilen ohne Fehler |
| Unquote-TVF ohne eigenes SELECT | SQL229 |
| ResultTable-Helper ohne EXECUTE | SQL229 |
| Split-SELECT widerrufen | erneuter Split-Aufruf mit SQL229 verweigert |

Die kanonischen ResultTable-/Split-Exporte bleiben unverändert. Coredefinitionen
und Sitzungsneutralität werden abschließend geprüft. Cleanup bindet Loginname,
SID, Principal-ID, Erstellungszeit, Defaultdatenbank und Sicherheitseinstellungen;
fremde Sessions, Rollen, Rechte oder Zuordnungen verhindern die Entfernung.
Eigene DBs werden nur nach Identitäts-/Ownermarkerprüfung entfernt. Der separate
Audit bindet das finale Originaljournal und bestätigt DB-/Login-/Mappingabsenz,
unveränderte Serverkonfiguration und Trust sowie die ursprünglichen Inputpins.

## Methode, Fehlerhistorie und Grenzen

Der [Treiber](../../Tests/Release/Invoke-SplitAdvancedMappedCallerLab.ps1)
und die [Fixture](../../Tests/Release/Runtime/SplitAdvanced.MappedCaller.Contract.ps1)
prüfen den schema-validierten Labvertrag und den exakt ausgewählten READY-Kontext.
`-ValidateOnly` prüft Admission ohne SQL oder Labimport. Siebzehn
[Offlinegegenproben](../../Tests/Release/test_split_mapped_caller_lab_contract.py)
prüfen insbesondere Autorität, Rechteumfang, Inputbindung, Netzwerkidentität,
falsche Serverrechte-Abfragen und neun Cleanup-Identitätsabweichungen.

| Methodencommit | Tatsächliches Ergebnis |
|---|---|
| `12253a59cc7f5cd80154fb04a581b4c4ac3ce4cf` | FAILED_CLEANED vor dem ersten Rechteprofil; frischer Audit PASS |
| `86fbb65e0a23091ad313e5a4e61cf1066e709028` | COMPLETE mit allen sechs Profilen; frischer Audit PASS |

Der erste Adapter verwendete bei HAS_PERMS_BY_NAME eine ungültige Serverklasse.
Die Korrektur verwendet für Serverrechte `NULL, NULL`, wie im
[Microsoft-Vertrag](https://learn.microsoft.com/en-us/sql/t-sql/functions/has-perms-by-name-transact-sql)
beschrieben. NULL wird weiterhin nicht als fehlendes Recht akzeptiert. Der
fehlgeschlagene Gesamtfall bleibt fehlgeschlagen. Die ausdrücklich vorab
genehmigte geänderte Adapterprobe startete erst nach bestätigtem Cleanup und
grünen Offlineprüfungen; kein bestandenes Rechteprofil wurde wiederholt.

Der gemeinsame Rahmen ist geschlossen: **vier Ziel-/Auditaufrufe**, vier
DB-Reservierungen, vier tatsächlich angelegte und entfernte DBs, zwei entfernte
eigene Logins und zwei frische Audits innerhalb derselben 45-Minuten-Grenze.
Private Originale, Fehler und Quellkapseln bleiben außerhalb Git erhalten.

Functional verwendet Verschlüsselung und den unveränderten expliziten
Lab-Trustwert. Windows-/Kerberos-/SSMS-Anmeldung, authentifiziertes TLS, andere
physische Engine-/CL-Paare für diesen Netzwerkpfad, weitere öffentliche APIs,
DDL-/Lifecycle-Minimalrechte und der vollständige Modulvertrag sind damit nicht
qualifiziert. Keine Lab-, Zertifikats-, Trust-, CLR- oder Serveroptionen geändert.
Keine Veröffentlichung oder Tags.
