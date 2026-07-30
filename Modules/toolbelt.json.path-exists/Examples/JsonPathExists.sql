DECLARE @Document nvarchar(max) =
    N'{
        "info": {
            "addresses": [
                {"town": "Wien"},
                {"town": null}
            ]
        }
    }';

SELECT
      town.PathExists AS AnyTown
    , missing.PathExists AS MissingProperty
FROM toolbelt_json.TVF_JsonPathExists
     (@Document, N'$.info.addresses[*].town') AS town
CROSS JOIN toolbelt_json.TVF_JsonPathExists
     (@Document, N'$.info.postcode') AS missing;
GO
