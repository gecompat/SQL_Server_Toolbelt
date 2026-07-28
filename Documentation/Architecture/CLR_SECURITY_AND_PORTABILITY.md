# CLR-Sicherheit und Portabilität

## Einsatz von SQL CLR

SQL CLR wird nur eingesetzt, wenn es technisch besser ist als T-SQL. Die Begründung muss Folgendes umfassen:
- Performance-Vergleich (messbar, nicht spekulativ)
- Security-Auswirkungen
- Deployment-Aufwand
- Plattformabhängigkeiten (Windows/Linux)
- Wartungsaufwand

## Permission-Sets

| Permission Set | Bevorzugt | Bedingung |
|---|---|---|
| `SAFE` | Ja | Standard; keine externen Ressourcen, kein unmanaged Code |
| `EXTERNAL_ACCESS` | Zulässig | Wenn externen Zugriff technisch erforderlich; dokumentieren |
| `UNSAFE` | Zulässig | Wenn unmanaged Code technisch erforderlich; dokumentieren |

## clr strict security

`clr strict security` wird **nicht regulär deaktiviert**. Es ist eine Sicherheitsfunktion ab SQL Server 2017.

## Trust-Modell

Default-Trust für offizielle Releases erfolgt durch kontrollierte Registrierung:
1. **SHA2-512-Hash** des exakten Assembly-Binaries in `sys.trusted_assemblies` (bevorzugt)
2. **Strong Name / asymmetrischer Schlüssel** als Alternative

## Verbotene Signing-Artefakte

Niemals ins Repository:
- Private Signing Keys (`*.pfx`, `*.p12`, `*.pvk`, `*.snk`)
- Zertifikate mit privatem Schlüssel

Öffentliche Schlüssel (nur öffentliche Zertifikate, kein Private Key) dürfen im Repository sein, wenn sie für Verifikationszwecke benötigt werden.

## TRUSTWORTHY

`TRUSTWORTHY ON` ist **kein regulärer oder automatischer Weg**. Es darf nur als Last-Resort-Ausnahme verwendet werden, wenn:
- SHA2-512-Hash und Strong Name technisch nicht möglich sind (Begründung erforderlich)
- Die Ausnahme separat dokumentiert und vom Benutzer ausdrücklich freigegeben ist

Jede `TRUSTWORTHY`-Ausnahme erhält eine Entscheidung in `DECISIONS.md`.

## Portabilität

- Beim Einsatz einer Windows-only-Funktion ist eine portable Alternative zu prüfen.
- Zwei CLR-Provider nur bei relevantem Performance-, Overhead-, Capability- oder Security-Unterschied; gleicher öffentlicher Vertrag.
- Parallelitätsfähigkeit anstreben, nicht garantieren.
- Streaming und geringer Speicherverbrauch bevorzugen.

## Plattformen und CLR

SQL CLR-Komponenten müssen auf Windows und Linux getestet werden, sofern technisch möglich. Plattformgrenzen sind pro Modul zu dokumentieren.
