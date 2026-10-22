# SQL Server Toolbelt 1.0.0 – Releasekandidat

Dieses Gesamtpaket ist eine **unveröffentlichte Quellpaket-Vorbereitung** für
45 Module. Es enthält 19 stabile und 26 Preview-Kandidaten. Die Kennzeichnung
ist ein Vorschlag für den Release-Review, keine neue Produktions- oder
Plattformzusage. Bestehende Modulversionen und `unreleased` bleiben erhalten.

1. Lies [Lieferumfang, Voraussetzungen und offene Releasegates](README.md).
2. Prüfe [Modulversion, Kanalvorschlag und Nachweisgrenzen](FREIGABEMATRIX.md).
3. Lies [Deployment](../../Deployment/README.md), verwende zunächst `-PlanOnly`
   mit einer bewussten Modulauswahl und teste ausschließlich in einem eigenen
   Testsystem. Beispiele nicht gesammelt ausführen.
4. `Install-Stable-local.sql` und `Install-Stable-central.sql` bündeln nur die
   stabilen Kandidaten. Sie benötigen SQLCMD-Modus und eine frische exklusive
   Sitzung in der richtigen Datenbank. Der Bau hat diese Dateien nicht gegen
   einen SQL Server ausgeführt.
5. CLR-Provider benötigen passende Binaries und separaten exakten Trust.
   Das enthaltene [SSIS-ZIP](../../Modules/toolbelt.tsql.ssis-debug/InstallPackages/README.md)
   hat fertige qualifizierte DLLs; andere CLR-Module enthalten ihre Quellen
   und vorhandenen Buildskripte. Dieses Gesamtpaket verspricht keine allgemeine
   Installation aller CLR-Module ohne eigenen Build.

`PACKAGE-MANIFEST.json`, `SHA256SUMS.txt` und die externe ZIP-Prüfsumme prüfen
die Dateiintegrität. Sie ersetzen keine Herausgebersignatur oder fachliche
Abnahme. Es gibt keine automatische Server-, Rechte-, Trust- oder
Labkonfigurationsänderung. Die [Lizenz](../../LICENSE.md) gilt unverändert.

`PREPARATION.bundle` erhält den Quellcommit auch nach Branchcleanup. Der
Prüfmodus benötigt einen vollständigen Checkout mit der genannten Produktbasis
und rekonstruiert die Vorbereitung ausschließlich lokal und temporär.

Die [Releasegates](RELEASE-GATES.md) zeigen die ausgeführte Installation der
stabilen Paketexports und die Grenzen der CLR-Buildprüfung. Sie sind keine
Veröffentlichungsfreigabe für das Gesamtpaket oder die Preview-Module.
