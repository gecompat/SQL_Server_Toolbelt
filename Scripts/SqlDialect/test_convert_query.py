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


if __name__ == "__main__":
    unittest.main()
