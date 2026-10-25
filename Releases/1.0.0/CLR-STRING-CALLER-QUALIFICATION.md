# CLR-Stringfunktionen: isolierte Callerrechte

Stand 2026-10-25. Fünf bestehende öffentliche TVFs bestehen auf zwölf
Windows-/Linux-Ziel-/CL-Kombinationen lokal und direkt zentral mit jeweils
genau einem SELECT-Grant. Belegt sind 120 positive Profile, 1440 erwartete
SQL229-Abweisungen und 480 feste Wert-/NULL-/Kardinalitätsorakel.

| API | Ausgewählte feste Orakel |
|---|---|
| TVF_ColognePhonetic | x/ax, Leertext und SQL-NULL; exakte Codebytes |
| TVF_DoubleMetaphone | the/AJ, Leertext und SQL-NULL; auch nachgestelltes Leerzeichen im Alternate-Code |
| TVF_LevenshteinDistance | kitten/sitting, Transposition, Threshold und NULL-Priorität |
| TVF_OsaDistance | dieselben Eingaben mit abweichendem Transpositionsgolden |
| TVF_JaroWinklerSimilarity | Identität, Groß-/Kleinschreibung, fester Bruchgolden und NULL-Priorität |

Ohne Grant, nach REVOKE und bei direkten Aufrufen der fünf internen CLR-Kerne
oder des ResultTable-Helfers ist exakt SQL229 erforderlich. Der jeweils andere
öffentliche Einstieg bleibt während eines Einzelgrantprofils ebenfalls gesperrt.
Breite Rollen-/Schema-/Datenbankrechte werden nicht gewährt.

## Tatsächlich entwickelter Code

Neu sind der begrenzte [CLR-Labtreiber](../../Tests/Release/Invoke-ClrCallerLab.ps1),
seine [Umgebungsfunktionen](../../Tests/Release/ClrCaller.Environment.ps1),
die [zehn isolierten Sicherheitsprüfungen](../../Tests/Release/Test-ClrCallerSafety.ps1)
und die feste ClrString.FunctionCases.sql. Der bisherige Funktions-Composer
und Rechteablauf bleiben unverändert. Produkt-SQL, C#-Produktquellen, Manifeste,
Modulstatus und Installationspakete wurden durch diese Welle nicht geändert.

Die zwei verwendeten Release-DLLs stimmen bytegenau mit zwei vorhandenen
isolierten Builds überein. Die ausgewählten aktuellen C#-Projektdateien und
Compile-Inputs sind identisch zum gebundenen historischen Buildstand.
Nur diese zwei exakt geprüften SAFE-Assemblies werden installiert. Binär- und
Trustfingerprints sowie tatsächliche Parameterstände bleiben privat.

## Matrix, Bindung und unveränderte Nachweise

Je Windows und Linux: SQL2019/CL150, SQL2022/CL150/160 und
SQL2025/CL150/160/170, jeweils lokal und direkt zentral.
Die [JSON-Projektion](clr-string-caller-qualification.json) bindet öffentliche
Quellteile, SQL-Exports, Matrix, Gegenkontrollen und Wiederverwendung.

Ein erster Admissionlauf stoppte vor Datenbank-, Trust- oder Konfigurations-
mutation: Der neue Guard unterschied eine dokumentierte Engine-Normalisierung
noch nicht von einer vorgemerkten Änderung. Die eng begrenzte Ausnahme stammt
aus der [Microsoft-Beschreibung von sys.configurations](https://learn.microsoft.com/en-us/sql/relational-databases/system-catalog-views/sys-configurations-transact-sql).
Es werden keine Speicheroptionen gesetzt; echte Pending-Änderungen bleiben
gesperrt. Der ursprüngliche Lauf und seine Audits bleiben erhalten.

Erfolgreiche APIfälle und Gegenkontrollen auf dem unveränderten Pfad
„CLR bereits aktiv“ wurden nicht erneut ausgeführt. Die originalen privaten
Umgebungsbytes wurden gegen ihren ursprünglichen Pin geprüft; die ausgeführten
Start-/Restore-Präfixe und übrigen verwendeten Helfer sind identisch. Eigene
aktuelle Auditprojektionen verändern keine Originalrunsets oder Journale und
dienen ausschließlich der frischen Zustands-/Bereinigungsprüfung.

Ein zusätzlicher Restore-Guard akzeptiert nur zum eigenen Journal passende
Übergänge. Sein geänderter serverweiter Pfad wurde auf den drei physischen
Zielen mit notwendiger eigener Aktivierung nativ bestätigt. Dieser Master-
Konfigurationspfad hängt nicht vom CL der Consumerdatenbank ab. Für die
weiteren CL-Fälle derselben physischen Ziele stimmen Selektor ohne CL und
ursprünglicher Konfigurationssnapshot überein; DLL-, SQL- und APIinputs sind
unverändert. Diese drei zusätzlichen Bestätigungen bleiben im Verbrauch
und ersetzen keine anderen API-/CL-Fälle.

## Sichere Bereinigung und Grenzen

Insgesamt wurden 18 native Zielversuche verbraucht, einschließlich Admission-
stopp und gezielter Safety-Bestätigungen. Nach allen Verbrauchern bestehen
frische unabhängige Audits für alle terminalen Journale: 32 eigene
Datenbanknamen sind abwesend, eigene Trusteinträge entfernt und vorbestehende
Trustfingerprints erhalten. Notwendige eigene CLR-Aktivierung ist
wiederhergestellt; vorbestehende Zustände bleiben erhalten.

Vor Aktivierung sind Sichtbarkeit und fehlende Benutzerassemblies auf dem
konkreten Ziel erforderlich. Fremde Konfigurationsdrift, neue Verbraucher,
unklare Ownership oder veränderte Trustfingerprints blockieren die Bereinigung.
Strict Security bleibt aktiv; kein Neustart, TRUSTWORTHY, Override,
Server-/Logingrant oder Lab-Infrastrukturverwaltung.

Diese Callerprofile ersetzen keine vollständige API-, Client-, Lifecycle-,
Maximalworkload-, Heap- oder Parallelitätsabnahme. Echte Lowpriv-CrossDB-
Identitätsmappings und authentifiziertes TLS bleiben separat. Functional
verwendet Verschlüsselung und den expliziten Trustwert des schema-validierten
Labvertrags ohne Transportfallback. Weitere [Releasegates](RELEASE-GATES.md)
und die öffentliche Veröffentlichung bleiben offen.

Eine spätere Konfigurationsabweichung wurde bei rein lesenden Abschlussaudits
beobachtet, nachdem eigene Wiederherstellung bereits unabhängig bestätigt war.
Sie wurde nicht überschrieben. Begrenztes read-only Warten bestätigte danach
wieder den ursprünglichen Zustand; sämtliche Abschlussaudits bestehen.
Ursprüngliche fehlgeschlagene Auditbeobachtungen bleiben privat erhalten;
für diese Beobachtungen wurden keine nativen Qualifikationen wiederholt.
