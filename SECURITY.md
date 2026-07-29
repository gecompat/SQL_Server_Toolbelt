# Sicherheitsrichtlinie – SQL Server Toolbelt

## Unterstützter Stand

Der Repository-Grundaufbau ist initialisiert. Das erste fachliche Modul ist implementiert und auf GitHub-hosted Linux `partially validated`, aber noch nicht als stabile Version veröffentlicht. Windows und weitere Pflichtfälle sind noch nicht ausgeführt. Sicherheitsmeldungen zum Grundaufbau, zu Regeln, Templates und Modulen werden bewertet.

## Sicherheitslücken melden

**Keine öffentlichen Issues für Sicherheitslücken öffnen.**

Verwende den privaten GitHub-Kanal des Repositorys:

`Settings` → `Security` → `Report a vulnerability`

Eine Meldung soll enthalten:

- betroffene Komponente und Version;
- reproduzierbare synthetische Beschreibung;
- erwartete und beobachtete Auswirkungen;
- keine Produktions- oder Originaldaten, nicht öffentlichen Infrastrukturangaben, realen Runtime-/Runner-Hardwarewerten oder Secrets.

## Datenschutz

Sicherheitsmeldungen dürfen keine personenbezogenen oder sensiblen Daten, internen oder vertraulichen Kunden-/Firmendaten, Original-Tabelleninhalte, produktiven Logs, realen Execution Plans, konkreten Remote-Runner-Hardwarewerte oder Secrets enthalten. Verwende synthetische Beispiele. Fachlich relevante öffentliche Organisations-/Projektnamen und öffentliche Links sind zulässig; `gecompat` und `Gerhard Pisch` sind ausdrücklich freigegeben.

## Reaktionszeit

Meldungen werden so bald wie möglich bewertet. Es besteht keine garantierte Reaktionszeit.

## Geltende Regeln

- [Datenschutz und Vertraulichkeit](./Documentation/Standards/DATA_PRIVACY_AND_CONFIDENTIALITY.md)
- [CLR-Sicherheit und Portabilität](./Documentation/Architecture/CLR_SECURITY_AND_PORTABILITY.md)
- [Drittanbieter- und Quellenrichtlinie](./Documentation/Standards/THIRD_PARTY_AND_SOURCE_POLICY.md)
