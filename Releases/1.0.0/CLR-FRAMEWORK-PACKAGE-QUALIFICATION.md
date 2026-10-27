# Gebundene CSV- und Phonetic-Frameworkprofile

Am 27.10.2026 wurden die beiden vorhandenen .NET-Framework-Harnesses erneut
ausgeführt, diesmal mit den exakt aus dem CLR-Installationspaket gelesenen
CSV- und Phonetic-DLL-Bytes. Das [maschinenlesbare Protokoll](CLR-FRAMEWORK-PACKAGE-QUALIFICATION.json)
bindet den Paket- und Qualificationstand sowie zehn relevante, repo-relative
Eingaben. Compiler- und Frameworkreferenz-Fingerprints bleiben privat.

## Ergebnisse

| Profil | Paket-DLL | Feste beziehungsweise gemessene Prüfung |
|---|---|---|
| Phonetic | `Toolbelt.String.Phonetic.dll`, SHA-256 `8309e0b8…af839f88` | Drei bestehende Kulturphasen mit je 223 Assertions. Pro Phase: 34 feste Bridgefälle (18 Cologne und 16 Double Metaphone), zwei falsche Zeilenbindungen und eine Assemblyidentitätsprüfung. |
| CSV | `Toolbelt.File.CsvMemory.dll`, SHA-256 `8e925d56…a40201` | Drei bestehende Kulturphasen. Gemessene Assertions: 1728, 1704 und 1704. Alle drei Kulturphasen rufen das feste Korpus mit jeweils 208 Quote-/Parse-Kombinationen auf; en-US prüft zusätzlich Grenzfälle. |

Die ursprünglichen Frameworkharnesses, Quellen und Owned-Process-Helfer blieben
unverändert. Die vorherige Releaseevidenz hatte erfolgreiche Läufe gegen
Buildkandidaten verzeichnet; sie band diese Kandidaten nicht dauerhaft an die
gelieferten Paketbytes. Dieses Protokoll ergänzt genau diese Paketbindung.

## Grenzen

Phonetic prüft die bestehenden In-Process-Bridgeverträge, keine SQL-TVF-Aufrufe.
CSV prüft die bestehende CLR-Parser-/Writer-Suite und eine begrenzte direkte
IL-Inspektion. Daraus folgt kein vollständiger transitiver No-I/O- oder
Sicherheitsnachweis. Die SQL-seitige ResultTable-Abhängigkeit von CSV wurde
nicht ausgeführt; das Harness benötigte keine Core- oder ResultTable-DLL.

Es gab keine SQL-/Lab-Ausführung, keine Produktbuilds und keine Änderungen an
Modulstatus oder Paket. Die Ergebnisse sind keine vollständige Modul-,
Plattform-, Deployment- oder CLR-Suitequalifikation. Veröffentlichung und
Tagging sind nicht autorisiert.
