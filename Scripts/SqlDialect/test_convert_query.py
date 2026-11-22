import unittest

from convert_query import convert


class TranslateIntegerSelect(unittest.TestCase):
    def setUp(self):
        self.binding = {
            "source": ["dbo", "Event"],
            "target": ["main", "demo", "Event"],
            "columns": {"id": {"type": "BIGINT", "nullable": True}},
        }
        self.parameters = {"key": {"type": "BIGINT", "nullable": False}}

    def test_typed_filter_roundtrip(self):
        first = convert(
            "SELECT e.id AS copy, -1 AS literal FROM dbo.Event AS e WHERE e.id >= @key OR e.id IS NULL",
            "tsql",
            {"relation": self.binding, "parameters": self.parameters},
        )
        self.assertEqual(first["status"], "converted")
        self.assertIn("`main`.`demo`.`Event` AS `e`", first["sql"])
        self.assertIn("CAST(:key AS BIGINT)", first["sql"])
        self.assertEqual(first["result_schema"], [
            {"name": "copy", "type": "BIGINT", "nullable": True},
            {"name": "literal", "type": "INT", "nullable": False},
        ])
        reverse = {
            **self.binding, "source": self.binding["target"], "target": self.binding["source"],
        }
        second = convert(first["sql"], "databricks", {"relation": reverse, "parameters": self.parameters})
        self.assertEqual(second["status"], "converted")
        self.assertIn("[dbo].[Event] AS [e]", second["sql"])
        self.assertIn("CAST(@key AS BIGINT)", second["sql"])
        self.assertEqual(second["result_schema"], first["result_schema"])
        self.assertEqual(second["parameters"], first["parameters"])
        self.assertEqual(second["native_validation"], "not executed")

    def test_missing_context_is_not_conversion(self):
        result = convert("SELECT e.id AS x FROM dbo.Event AS e", "tsql", {})
        self.assertEqual(result["status"], "requires_context")
        self.assertIsNone(result["sql"])

    def test_rejected_statements_do_not_emit_sql(self):
        for sql in (
            "SELECT 1 AS value; SELECT 2 AS value",
            "SELECT 1 AS value INTO dbo.X",
            "UPDATE dbo.X SET X = 1",
            "SELECT TOP 2 1 AS value",
            "SELECT 1 AS value /* diagnostic input */",
            "SELECT 1 AS value ORDER BY 1",
            "SELECT 'private-looking-input' AS value",
            "SELECT 2147483648 AS value",
            "SELECT 1 AS value, 2 AS VALUE",
            "SELECT CAST(CAST(1 AS BIGINT) AS INT) AS value",
            "SELECT CAST(1 AS BIGINT) AS value WHERE CAST(1 AS BIGINT) = 1",
        ):
            with self.subTest(sql=sql):
                result = convert(sql, "tsql", {})
                self.assertNotEqual(result["status"], "converted")
                self.assertIsNone(result["sql"])

    def test_depth_and_bytes(self):
        self.assertEqual(convert("SELECT " + "(" * 17 + "1" + ")" * 17, "tsql", {})["status"],
                         "limit_exceeded")
        self.assertEqual(convert(" " * 16_385, "tsql", {})["status"], "limit_exceeded")

    def test_provider_fallback_omits_input(self):
        result = convert("EXECUTE dbo.ContosoProcedure", "tsql", {})
        self.assertIsNone(result["sql"])
        self.assertNotIn("ContosoProcedure", str(result))

    def test_cte_join_roundtrip_preserves_null_extension(self):
        declarations = [
            {**self.binding, "columns": {"id": {"type": "BIGINT", "nullable": False}}},
            {"source": ["dbo", "Detail"], "target": ["main", "demo", "Detail"],
             "columns": {"id": {"type": "BIGINT", "nullable": False}}},
        ]
        sql = ("WITH a AS (SELECT e.id AS id FROM dbo.Event AS e), "
               "b AS (SELECT x.id AS id FROM a AS x) "
               "SELECT x.id AS left_id, d.id AS right_id FROM b AS x "
               "LEFT OUTER JOIN dbo.Detail AS d ON d.id = x.id WHERE x.id >= @key")
        first = convert(sql, "tsql", {"relations": declarations, "parameters": self.parameters})
        self.assertEqual(first["status"], "converted")
        self.assertEqual([item["nullable"] for item in first["result_schema"]], [False, True])
        reversed_mappings = [
            {**item, "source": item["target"], "target": item["source"]} for item in declarations
        ]
        second = convert(first["sql"], "databricks", {"relations": reversed_mappings, "parameters": self.parameters})
        self.assertEqual(second["status"], "converted")
        self.assertIn("LEFT JOIN [dbo].[Detail] AS [d] ON", second["sql"])
        self.assertEqual(first["result_schema"], second["result_schema"])

    def test_cte_scopes_fail_closed(self):
        for sql in (
            "WITH a AS (SELECT t.id AS id FROM a AS t) SELECT 1 AS id",
            "WITH a AS (SELECT t.id AS id FROM b AS t), b AS (SELECT 1 AS id) SELECT 2 AS id",
            "WITH a AS (SELECT 1 AS id), A AS (SELECT 2 AS id) SELECT 3 AS id",
            "WITH a AS (SELECT 1 AS id) SELECT t.id AS id FROM a AS t, a AS b",
            "WITH a AS (SELECT 1 AS id) SELECT b.id AS id FROM a AS t JOIN a AS T ON t.id = T.id",
        ):
            with self.subTest(sql=sql):
                self.assertIsNone(convert(sql, "tsql", {})["sql"])

    def test_explicit_cross_and_right_join_nullability(self):
        for join, expected in (
            ("CROSS JOIN one AS y", [False, False]),
            ("RIGHT JOIN one AS y ON x.id = y.id", [True, False]),
            ("FULL JOIN one AS y ON x.id = y.id", [True, True]),
        ):
            with self.subTest(join=join):
                sql = f"WITH one AS (SELECT 1 AS id) SELECT x.id AS a, y.id AS b FROM one AS x {join}"
                result = convert(sql, "tsql", {})
                self.assertEqual(result["status"], "converted")
                self.assertEqual([item["nullable"] for item in result["result_schema"]], expected)

    def test_correlated_apply_is_capability_gated_and_roundtrips(self):
        sql = ("WITH one AS (SELECT 1 AS id) SELECT x.id AS a, y.id AS b FROM one AS x "
               "OUTER APPLY (SELECT z.id AS id FROM one AS z WHERE z.id = x.id) AS y")
        unavailable = convert(sql, "tsql", {})
        self.assertEqual((unavailable["status"], unavailable["sql"]), ("requires_context", None))
        context = {"lateral_select": True}
        first = convert(sql, "tsql", context)
        self.assertEqual(first["status"], "converted")
        self.assertIn("LEFT JOIN LATERAL", first["sql"])
        self.assertIn("ON TRUE", first["sql"])
        self.assertEqual(first["required_capabilities"], ["lateral_select"])
        self.assertEqual([item["nullable"] for item in first["result_schema"]], [False, True])
        second = convert(first["sql"], "databricks", context)
        self.assertEqual(second["status"], "converted")
        self.assertIn("OUTER APPLY", second["sql"])
        self.assertEqual(second["result_schema"], first["result_schema"])
        self.assertIsNone(convert(sql.replace("z.id = x.id", "z.id > x.id"), "tsql", context)["sql"])

    def test_union_all_derived_relation_and_schema(self):
        sql = ("WITH one AS (SELECT 1 AS id) SELECT d.id AS merged FROM "
               "(SELECT x.id AS id FROM one AS x UNION ALL SELECT @p AS alias) AS d")
        context = {"parameters": {"p": {"type": "INT", "nullable": True}}}
        first = convert(sql, "tsql", context)
        self.assertEqual(first["status"], "converted")
        self.assertEqual(first["result_schema"], [{"name": "merged", "type": "INT", "nullable": True}])
        self.assertIn("UNION ALL", first["sql"])
        reverse = convert(first["sql"], "databricks", context)
        self.assertEqual(reverse["status"], "converted")
        self.assertEqual(first["result_schema"], reverse["result_schema"])
        self.assertIsNone(convert(sql.replace("UNION ALL", "UNION"), "tsql", context)["sql"])
        wider = {"parameters": {"p": {"type": "BIGINT", "nullable": True}}}
        self.assertIsNone(convert(sql, "tsql", wider)["sql"])


if __name__ == "__main__":
    unittest.main()
