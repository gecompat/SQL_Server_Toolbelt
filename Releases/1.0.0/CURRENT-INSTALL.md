# Gemeinsamer aktueller Installer für v1.0.0

Der Installationssatz enthält eigenständige SQLCMD-Skripte für eine leere,
ausdrücklich ausgewählte Datenbank: Windows und Portable, jeweils lokal/zentral.
Portable schließt die vier Windows-only-Module aus; zentrale Installation schließt
Windows Filesystem und ZIP Files aus. Alle übrigen vorgesehenen Module und
Abhängigkeiten sind enthalten. Keine Veröffentlichung oder pauschale Vollqualifikation.

## Voraussetzungen und Installation

SQL Server 2019/2022/2025, vorhandene Installationsrechte und wirksames CLR.
`clr strict security` bleibt aktiv, `TRUSTWORTHY` bleibt aus. Das Paket legt keine
Logins, Windows-Roots oder Dateirechte an. Ausschließlich eigene ausgewählte
Testziele verwenden; bestehende Installationen nicht mit diesem Fresh-Install-Satz ersetzen.

1. ZIP mit der separaten SHA256-Datei prüfen, anschließend die entpackten
   Nutzdaten gegen SHA256SUMS vergleichen.
2. Genau ein Install-Windows-local.sql, Install-Windows-central.sql,
   Install-Portable-local.sql oder Install-Portable-central.sql wählen.
3. Benötigte exakte Assemblyhashes bewusst administrativ mit dem passenden
   Trust-Windows.sql oder Trust-Portable.sql in master autorisieren. Trust ist
   eine getrennte Aktion, kein Bestandteil des Installationsskripts.
4. In einer leeren Datenbank und frischen Sitzung das gewählte vollständige
   Script mit SQLCMD-Fehlerabbruch ausführen, etwa mit sqlcmd -b -f 65001.
5. EXEC toolbelt_core.USP_BeginExecution @Hilfe=1 liefert die API-Hilfe.
   Fehlerabbruch und Voraussetzungen beibehalten; bei Fehlern keine bestehenden
   fremden Datenbanken, Trusteinträge oder Konfigurationen verändern.

## Herkunft und Abnahme

Der gemeinsame Exporter verarbeitet aktuelle Modulquellen. Die bestehenden
geprüften DLLs werden unverändert wiederverwendet: unveränderte CLR-Komponenten
aus dem gebundenen Wartungspaket, aktuelle JSON-Constructors aus ihrer bekannten
Closure, aktueller Parser aus seinem quellgebundenen nativen Stand und SSIS
aus dem sicherheitskorrigierten, separat qualifizierten Paket.
BINARY-PROVENANCE.json bindet Compilerquellen und ersetzte Binaries;
PACKAGE.json bindet Deploymentquellen, Profile und alle Nutzdaten.
Historische Installer und Nachweise bleiben unverändert. Die neue gemeinsame
Installationsabnahme ist getrennt vom erneuten Prüfen bestehender Fachfunktionen,
SSMS und TLS. Ihre Ergebnisse werden im zugehörigen aktuellen Abnahmebericht geführt.
