# R1a: Regex-Semantik- und Provider-Spike

Stand: 2026-08-30

> Nachgelagerter Status 2026-08-30: Nach Abschluss dieses Research-Scope
> wurden ein enger Toolbelt-Dialekt und drei R1b-Funktionen separat besprochen,
> ausdrücklich freigegeben und unter `Modules/toolbelt.string.regex`
> implementiert. R1a selbst enthält weiterhin kein Runtime-Objekt und seine
> Aussage gegen RE2-Parität bleibt unverändert.

## Ergebnis

R1a ist als Research-Slice abgeschlossen. Für SQL Server 2019 und 2022 ist
derzeit kein Provider nachgewiesen, der zugleich die native
SQL-Server-2025-RE2-Semantik, `SAFE`-SQL-CLR, Windows/Linux-Portabilität und
einen beherrschbaren Dependency-Lifecycle erfüllt. Deshalb entsteht aus
diesem Spike kein Modul, kein Deployment und keine öffentliche Runtime-API.

Ein späterer V1-Vertrag für `LIKE`, `INSTR` und `COUNT` benötigt zuerst eine
Benutzerentscheidung zwischen exakter RE2-Parität, einem ausdrücklich
kleineren Toolbelt-Regex-Dialekt oder einer reinen SQL-Server-2025-Fassade.

## Native SQL-Server-2025-Referenz

SQL Server 2025 verwendet RE2. Der dokumentierte Vertrag umfasst unter
anderem ASCII-definierte `\d`, `\s` und `\w`, Unicode-Kategorien,
case-sensitive Matching als Default, die Flags `c`, `i`, `m` und `s`, keine
Collation-Semantik sowie Grenzen von 2 MB für den Input und 8.000 Bytes für
das Pattern. RE2 garantiert lineare Laufzeit zur Inputlänge und unterstützt
weder Backreferences noch Lookaround.

Der physische Linux-Lauf auf SQL Server 2025 bestätigte am 2026-08-30:

- `REGEXP_INSTR` und `REGEXP_COUNT` unter Compatibility Levels 150, 160 und
  170;
- `REGEXP_LIKE` ausschließlich unter Compatibility Level 170;
- linke Alternativpriorität, greedy/lazy Matching, nicht überlappende Counts,
  Empty-Match-Fortschritt, `c`/`i`/`m`/`s`, ASCII-`\w`, Unicode-Kategorien,
  UTF-16-basierte Positionswerte und `NULL`;
- Fehler für Backreferences, Lookahead, Wiederholungsgrenzen über 1.000,
  unbekannte Flags und Startpositionen kleiner als 1.

Der Test verwendet nur eine synthetische Datenbank. Sie wurde nach dem Lauf
entfernt; die Lab-Umgebung wurde weder gestartet noch beendet. Windows blieb
wegen des bereits zuvor nicht erreichbaren SQL-Anmeldungs-Preflights
`not executed`.

## Providervergleich

| Option | Semantik | Security und Plattform | Ergebnis |
|---|---|---|---|
| Native SQL Server 2025 | Kanonische RE2-Referenz | Kein Zusatzartefakt; `LIKE` benötigt Compatibility 170 | Geeignet für einen möglichen 2025-Provider, schließt die 2019-/2022-Lücke aber nicht. |
| `.NET Framework 4.8` `System.Text.RegularExpressions` | Backtracking-Engine; akzeptiert unter anderem Backreferences, Lookahead und `{1001}`. Im Test wichen ASCII-`\w` und `$` vor finalem Newline ab. `ECMAScript` korrigiert `\w`, ist aber nicht mit `Singleline` kombinierbar und korrigiert `$` nicht. | `System.dll` ist eine unterstützte SQL-CLR-Bibliothek; `SAFE` und Linux sind grundsätzlich möglich. Ein Timeout begrenzt Laufzeit, stellt aber keine RE2-Parität oder lineare Laufzeit her. `RegexOptions.NonBacktracking` existiert erst ab .NET 7, während SQL CLR .NET Framework verlangt. | Nicht als RE2-kompatibler Provider geeignet. Nur nach Freigabe eines engeren Dialekts samt Parser/Transpiler, Timeout- und Fehlervertrag erneut bewerten. |
| `RE2.Managed` / `IronRe2` | Wrapper um native RE2-Artefakte | Native OS-Binaries; der aktuelle IronRe2-Pfad zielt nicht auf SQL-CLR-.NET-Framework. Native Aufrufe benötigen `UNSAFE`; SQL Server Linux unterstützt weder `EXTERNAL_ACCESS` noch `UNSAFE`. | Für den portablen In-Process-Vertrag ausgeschlossen; keine Dependency aufgenommen. |
| `Re2.Net` | RE2 über C++/CLI | Plattformabhängige x86/x64-DLLs und Visual-C++-Runtime, kein Linux-Pfad | Ausgeschlossen; keine Dependency aufgenommen. |
| Reines T-SQL | Nur kleine Pattern-Teilmengen realistisch | Portabel, aber keine allgemeine Regex-Engine | Kein Regex-Kompatibilitätsprovider. |

## Warum ein einfacher Pattern-Filter nicht genügt

Das bloße Verbieten von Backreferences und Lookaround macht die
.NET-Framework-Engine nicht zu RE2. Auch ausschließlich reguläre Konstrukte
können in einer Backtracking-Engine pathologische Laufzeiten erzeugen.
Zusätzlich unterscheiden sich Zeichenklassen, Anker und Optionskombinationen.
Ein belastbarer Toolbelt-Dialekt bräuchte daher einen vollständigen
Syntaxparser, explizite Transformationen, Größenlimits, einen festen Timeout,
stabile Fehlercodes und eine große Paritätsmatrix. Das ist ein eigener
Funktionsvertrag und nicht durch R1a freigegeben.

## Nächste fachliche Entscheidung

Vor einer Implementierung ist genau eine Richtung auszuwählen:

1. **Exakte RE2-Parität:** externer oder nativer Provider mit eigener
   Betriebs-, Trust-, Plattform- und Dependency-Freigabe.
2. **Toolbelt-Subset:** bewusst nicht als vollständige RE2-Parität bezeichnen;
   Syntax, Transformationen, Timeout, Limits und Fehlervertrag separat
   besprechen.
3. **SQL Server 2025 only:** dünne Fassade über native Funktionen; kein
   Backportnutzen für 2019/2022.

Bis dahin bleibt `TC-2026-010` `researched`; die Runtime-Implementierung ist
ausdrücklich nicht freigegeben.

## Reproduzierbare Evidenz

- `Tests/Research/Regex/SqlServer2025Compatibility.sql`
- `Tests/Research/Regex/SqlServer2025Semantics.sql`
- `Tests/Research/Regex/run-sqlserver-2025.sh`
- `Tests/Research/Regex/DotNet48Semantics.cs`
- `Tests/Research/Regex/run-dotnet48-semantics.ps1`

Die Testvektoren enthalten ausschließlich synthetische Strings und übernehmen
keine Runtime-, Host- oder Umgebungsdetails in das Repository.

## Primärquellen und Paketmetadaten

- [Microsoft: Regular expressions in SQL Server](https://learn.microsoft.com/en-us/sql/relational-databases/regular-expressions/overview?view=sql-server-ver17)
- [Microsoft: `REGEXP_LIKE`](https://learn.microsoft.com/en-us/sql/t-sql/functions/regexp-like-transact-sql?view=sql-server-ver17)
- [Microsoft: `REGEXP_INSTR`](https://learn.microsoft.com/en-us/sql/t-sql/functions/regexp-instr-transact-sql?view=sql-server-ver17)
- [Microsoft: `REGEXP_COUNT`](https://learn.microsoft.com/en-us/sql/t-sql/functions/regexp-count-transact-sql?view=sql-server-ver17)
- [Google RE2: README](https://github.com/google/re2/blob/main/README.md)
- [Google RE2: Syntax](https://github.com/google/re2/blob/main/doc/syntax.txt)
- [Google RE2: BSD-3-Clause-Lizenz](https://github.com/google/re2/blob/main/LICENSE)
- [Microsoft: SQL CLR on Linux and .NET Framework](https://learn.microsoft.com/en-us/sql/relational-databases/clr-integration/database-objects/getting-started-with-clr-integration?view=sql-server-ver17)
- [Microsoft: supported .NET Framework libraries in SQL CLR](https://learn.microsoft.com/en-us/sql/relational-databases/clr-integration/database-objects/supported-net-framework-libraries?view=sql-server-ver17)
- [Microsoft: CLR hosted environment and native-code boundary](https://learn.microsoft.com/en-us/sql/relational-databases/clr-integration/clr-integration-architecture-clr-hosted-environment?view=sql-server-ver17)
- [Microsoft: .NET Regex backtracking and timeout guidance](https://learn.microsoft.com/en-us/dotnet/standard/base-types/backtracking-in-regular-expressions)
- [NuGet: `RE2.Managed` 4.5.7](https://www.nuget.org/packages/RE2.Managed/4.5.7)
- [NuGet: `IronRe2` 2.1.0](https://www.nuget.org/packages/IronRe2/2.1.0)
- [Re2.Net source and platform notes](https://github.com/0xcb/Re2.Net)

Es wurde kein Drittanbieterartefakt heruntergeladen, eingebunden oder in das
Repository übernommen. Deshalb besteht für R1a kein Artefakthash- oder
Attributionspaket.
