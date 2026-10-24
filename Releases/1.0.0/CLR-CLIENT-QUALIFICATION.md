# Optionalen CLR-Installer über ODBC qualifizieren

Stand 2026-10-24. Der optionale PowerShell-Installer ist mit ausdrücklich
gewählter SQL-Anmeldung auf den zwölf unterstützten Ziel-/CL-Kombinationen
geprüft. Dies ergänzt die bisherige SqlClient-Paketprüfung. Die Anleitung für
Anwender:innen steht unter [CLR ohne eigenen Build installieren](CLR-INSTALL.md).
Veröffentlichung, Tag und GitHub-Release bleiben nicht freigegeben.

## Korrekturen

Bei mehreren installierten `sqlcmd`-Programmen übernahm der Helper bislang
eine Liste als Programmpfad. Er wählt jetzt genau das erste Tool im Suchpfad;
ein ausdrücklich gesetzter `-SqlcmdPath` bleibt möglich. Nach Fehlern gibt es
keinen Wechsel auf ein anderes Programm.

Der neue optionale Parameter `-Credential` verwendet ein bereits vorhandenes
SQL-Konto. Ohne ihn bleibt Windows-Anmeldung der Standard. Das Passwort geht
ausschließlich über das Environment des gestarteten Kindprozesses an
`sqlcmd`, ohne `-P`, Passwortdatei oder Änderung des Elternenvironments.
Verschlüsselung bleibt eingeschaltet; der Trustwert wird ausdrücklich gewählt.
Es gibt keinen automatischen Authentifizierungs- oder Transportfallback.

Der erste Windows-Versuch erreichte nach erfolgreicher Erstinstallation und
Repeat die unveränderte äußere Arbeitsgrenze. Das Paket enthielt eine fast
14 MB lange Einzelzeile für ScriptDom. Die korrigierte Paketierung unterteilt
ausschließlich bekannte Assemblyliterale mit der dokumentierten
[T-SQL-Zeilenfortsetzung](https://learn.microsoft.com/en-us/sql/t-sql/language-elements/sql-server-utilities-statements-backslash?view=sql-server-ver17).
Die längste aktuelle SQL-Zeile bleibt unter 8 KB. Bei dieser ersten
Clientkorrektur stimmten nach Entfernen der Zeilenfortsetzungen alle
SQL-Dateien bytegenau mit dem bisherigen Paket überein.

Die spätere [Rechte-Dokumentationskorrektur](REGEX-RIGHTS-QUALIFICATION.md)
ergänzt fünf exakt gebundene SQL-Headerkommentare und die zugehörigen
Metadaten. Diese neu erzeugten rohen Dateien bestanden erneut alle zwölf
ODBC-Paketfälle. Die erste Clientqualifikation bleibt unverändert über den
in der Projektion genannten öffentlichen Main-Vorstand zugänglich. Alle
dreizehn DLLs, ausführbaren Modulquellen, SQL-Verträge, Hash-/Consumerguards
und Regex-Sicherheitsbudgets bleiben identisch.

## Tatsächlich ausgeführter Umfang

Der vorhandene `Tests/Release/Invoke-ClrPackageLab.ps1` verwendet im explizit
ausgewählten Runsetpfad `client = OdbcSqlcmd` den vollständig entpackten
Pakethelper. Ohne diesen Eintrag bleibt der bisherige SqlClient-Testpfad
erhalten. Der Aufruf erfolgt über einen vorab festgelegten ODBC-Client,
`TestPurpose=Functional`, `Encrypt=True` und den ausdrücklichen booleschen
Trustwert des schema-validierten Labvertrags.

| Serverplattform | SQL-Version | Geprüfte Kompatibilitätsgrade | Paketprofile |
|---|---|---|---|
| Windows und Linux | 2019 | 150 | Windows beziehungsweise Portable, jeweils local und central |
| Windows und Linux | 2022 | 150, 160 | Windows beziehungsweise Portable, jeweils local und central |
| Windows und Linux | 2025 | 150, 160, 170 | Windows beziehungsweise Portable, jeweils local und central |

Jeder Fall führte beide Deploymentmodi mit Erstinstallation und exakter
Trustregistrierung, Repeat, zentralem Consumer, Uninstall und
UninstallAbsent aus. Die festen Orakel prüfen Assemblyhashes, Modulmarker,
einen Phonetikwert, zwei JSON-Help-Aufrufe und Rückstandsfreiheit nach Uninstall.
Die Grenzen blieben bei 300 Sekunden Arbeitszeit, 360 Sekunden Gesamtfrist
für die Bereinigung und 400 Sekunden äußerem Watchdog je Fall. Kein Budget
wurde zurückgesetzt oder erhöht.

Die [maschinenlesbare Projektion](clr-client-qualification.json) bindet
aktuelle Quellen, Paket-SQL, unveränderte Binaries und die zwölf erfolgreichen
Fälle. Der frühere Linux-Erfolg und der Windows-Deadline-Fall bleiben als
frühere Revision getrennt; sie zählen nicht zur korrigierten Matrix.
Ein separater lesender Audit prüfte die Bereinigung und Inputpins der
aktuellen und früheren Fälle. Die drei temporären CLR-Konfigurationsscopes
wurden wiederhergestellt und separat geprüft. Private Journale, Toolpfade,
Labidentitäten, Zugangsdaten und Rohlogs werden nicht veröffentlicht.

## Grenzen und weitere Releasegates

Dies qualifiziert den Paketinstaller mit expliziter SQL-Anmeldung. Die
Windows-Authentifizierung und der manuelle SSMS-GUI-Weg sind hier
`not executed`. Die lokalen Negativtests prüfen zusätzlich die unveränderten
Windows-Argumente, eindeutige Toolwahl, Passwortisolation bei Erfolg und
Fehlern sowie den fehlenden automatischen Retry; sie ersetzen keinen nativen
Windows-Anmeldenachweis.

Modulspezifische Minimalrechte-, Provider-, Datei-/Identitäts-, Ressourcen-
und Host-Recovery-Gates bleiben gemäß [Releasegatebericht](RELEASE-GATES.md)
offen. Dieser Lauf ist keine vollständige API-Abnahme und kein Nachweis einer
authentifizierten TLS-Verbindung. Stable-/Preview-Zielumfang und
Modulmanifeststatus ändern sich nicht.
