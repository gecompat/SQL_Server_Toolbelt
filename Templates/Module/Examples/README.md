# Beispiele – {{ModuleName}}

Alle Beispiele verwenden ausschließlich synthetische Daten.

## Verwendungsbeispiel

```sql
-- Synthetisches Beispiel (nicht ausführbar ohne vollständige Installation)
-- {{Beschreibung des Beispiels}}

EXEC toolbelt_{{category}}.USP_{{ObjectName}}
    @{{Parameter1}} = {{BeispielWert}},
    @Hilfe          = 0;
```

## Hilfe-Aufruf

```sql
-- Help-Resultset abrufen (nicht ausführbar ohne vollständige Installation)
EXEC toolbelt_{{category}}.USP_{{ObjectName}}
    @Hilfe = 1;
```

## Hinweis

Beispiele sind Vorlagen; vor Ausführung vollständige Installation erforderlich.
