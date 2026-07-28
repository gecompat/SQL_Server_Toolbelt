# Beispiele – {{ModuleName}}

Alle Beispiele verwenden ausschließlich synthetische Daten und entsprechen der tatsächlichen Implementierung.

## Stored Procedure

```sql
EXEC toolbelt_{{category}}.USP_{{ObjectName}}
    @{{Parameter}} = {{SyntheticValue}};

EXEC toolbelt_{{category}}.USP_{{ObjectName}}
    @Hilfe = 1;
```

## Table-valued Function

```sql
SELECT *
FROM toolbelt_{{category}}.TVF_{{ObjectName}}({{SyntheticArguments}});
```

## Scalar-valued Function

```sql
SELECT toolbelt_{{category}}.SVF_{{ObjectName}}({{SyntheticArguments}}) AS ResultValue;
```

## View

```sql
SELECT *
FROM toolbelt_{{category}}.VW_{{ObjectName}};
```

Entferne nicht zutreffende Abschnitte. Beispiele sind erst nach vollständiger Installation ausführbar.
