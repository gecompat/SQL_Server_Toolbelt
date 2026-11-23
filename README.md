# ⚠️ READ BEFORE USE

## License notice

**NOTICE: SQL Server Toolbelt is NOT Open Source. Use is governed by the custom Attribution & Non-Commercial Redistribution License.**

1. **NO RESALE:** Selling or charging third parties for access to this software or its contents is strictly prohibited.
2. **ATTRIBUTION REQUIRED:** You must preserve the copyright notice for **gecompat - Gerhard Pisch**.
3. **NO LIABILITY:** Use this software at your own risk. The author is **NOT liable** for damages, data loss, or business interruptions.

The complete legal terms are available in [LICENSE.md](./LICENSE.md). In case of a discrepancy, the English master version in `LICENSE.md` prevails.

---

## Lizenzhinweis

**HINWEIS: SQL Server Toolbelt ist keine Open-Source-Software. Die Nutzung richtet sich nach der projektspezifischen Attribution & Non-Commercial Redistribution License.**

1. **NO RESALE:** Der Verkauf der Software sowie das Entgelt für den Zugang zu dieser Software oder ihren Inhalten sind untersagt.
2. **ATTRIBUTION REQUIRED:** Der Copyright-Hinweis für **gecompat – Gerhard Pisch** muss erhalten bleiben.
3. **NO LIABILITY:** Die Nutzung erfolgt auf eigenes Risiko; der Autor haftet nicht für Schäden, Datenverlust oder Betriebsunterbrechungen.

Maßgeblich ist der vollständige englische Wortlaut in [LICENSE.md](./LICENSE.md). Die Übersetzungen dienen der Verständlichkeit.

---

# SQL Server Toolbelt

SQL Server Toolbelt erweitert die SQL Server Database Engine ab Version 2019
um wiederverwendbare Funktionen, Stored Procedures und Views. Die Bibliothek
richtet sich an T-SQL-Entwickler und SQL-Server-Administratoren. 45 Module
sind implementiert.

## Installation und erster Test

[Toolbelt installieren](./INSTALL.md) führt von der Wahl des Pakets bis zum
ersten Aufruf. Installiere in der Anwendungsdatenbank oder zentral in einer
eigenen Datenbank. Der aktuelle Installer ergänzt fehlende Objekte. Für eine
Aktualisierung bereitest du eine separate Installation vor und stellst die
Aufrufer nach der Prüfung um.

Die Installationsanleitung erklärt die Voraussetzungen je Plattform, Rechte,
CLR und Trust sowie den Weg über PowerShell und über eine normale SQL-Datei
in SSMS. Veröffentlichte Vorabpakete haben ihren eigenen Installationsstand.

## Eine Funktion finden und verwenden

- [Nach Aufgabe auswählen](./Documentation/ChooseFunctions.md). Finde etwa
  den passenden JSON-Zugriff, eine Textvergleichsfunktion oder den richtigen
  Weg für Dateien, ZIP-Archive und DTSX-Pakete.
- [SQL-Objekte nachschlagen](./Documentation/Reference/README.md#einzelne-sql-objekte-nachschlagen).
  Suche nach dem Namen und lies Parameter, Ergebnisse, Grenzen und Beispiele.
- [Bedienerdokumentation](./Documentation/README.md). Anleitungen für
  Installation, zentrale Aufrufe, DTSX-Debugging, Queue und Worker.

## Unterstützte SQL-Server-Versionen

Die Zielversionen sind SQL Server 2019, 2022 und 2025. Welche Funktionen unter
Windows und Linux sowie lokal und zentral verfügbar sind, hängt vom
Installationsprofil und vom jeweiligen Objektvertrag ab. Die
[Profilauswahl](./INSTALL.md#lokal-oder-zentral-wählen) erklärt die Unterschiede.
Für Azure SQL Database und Azure SQL Managed Instance besteht keine allgemeine
Kompatibilitätszusage. Die öffentlichen Vorabpakete sind Entwicklungssnapshots.

Für Instanzanalyse, Diagnose, Performance und Sicherheitsauswertung gibt es das
separate Projekt [SQL Server Analyze](https://github.com/gecompat/SQL_Server_Analyze).

## Projektpflege

[Entwicklungsdokumentation und Nachweise](./Documentation/Development/README.md)
· [Modulübersicht](./Modules/README.md)
· [Validierungsmatrix](./Tests/MODULE_VALIDATION_MATRIX.md)
· [Mitwirken](./CONTRIBUTING.md)
· [KI-Einstieg](./AGENTS.md)

<!-- BEGIN GENERATED:MODULE_STATUS_BADGE -->
[![45 Module implementiert](https://img.shields.io/badge/Status-45%20Module%20implementiert-blue)](./Modules/README.md)
<!-- END GENERATED:MODULE_STATUS_BADGE -->

<a id="historische-modulnotizen"></a>
<a id="begrenzter-paarvergleich-100"></a>
<a id="xlsx-typinterpretation-110"></a>
<a id="csv-memory-100"></a>
<a id="json-pointer-100"></a>
<a id="safe-cast-100"></a>
[Historische Modulnotizen](./Documentation/History/MODULE_NOTES_2026-10-22.md)
