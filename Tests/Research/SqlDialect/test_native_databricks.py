"""Lokale Negativkontrollen des Databricks-Harness, keine Enginequalifikation."""

import os
import unittest
from unittest.mock import patch

from run_native_databricks import Client, NoRedirect, ProbeError, compare_response, rows_key


def case_and_response():
    # Handgeschrieben: gleiche Zeile zweimal sowie ein wirkliches JSON-NULL.
    case = dict(columns=[dict(name="id", type="INT")], expected_rows=[["1"], ["1"], [None]], ordered=False)
    response = dict(status=dict(state="SUCCEEDED"), manifest=dict(
        format="JSON_ARRAY", total_chunk_count=1, total_row_count=3, truncated=False,
        schema=dict(columns=[dict(name="id", position=0, type_text="INT", type_name="INT")])),
        result=dict(data_array=[[None], ["1"], ["1"]]))
    return case, response


class NativeDatabricksControls(unittest.TestCase):
    def test_bag_and_metadata(self):
        case, response = case_and_response()
        actual = compare_response(case, response)
        self.assertEqual(actual["metadata_nullability"], "not exposed by this API")

    def test_lost_duplicate(self):
        case, response = case_and_response()
        response["result"]["data_array"] = [[None], ["1"]]
        response["manifest"]["total_row_count"] = 2
        with self.assertRaisesRegex(ProbeError, "RESULT_BAG_OR_ORDER"):
            compare_response(case, response)

    def test_null_is_not_zero(self):
        case, response = case_and_response()
        response["result"]["data_array"][0] = ["0"]
        with self.assertRaisesRegex(ProbeError, "RESULT_BAG_OR_ORDER"):
            compare_response(case, response)

    def test_wrong_width(self):
        case, response = case_and_response()
        response["manifest"]["schema"]["columns"][0]["type_text"] = "BIGINT"
        with self.assertRaisesRegex(ProbeError, "COLUMN_TYPE_OR_NAME"):
            compare_response(case, response)

    def test_truncation_chunks_and_failed_state(self):
        for label in ("truncated", "chunks", "failed", "row_count", "external"):
            with self.subTest(label=label):
                case, response = case_and_response()
                if label == "truncated":
                    response["manifest"]["truncated"] = True
                elif label == "chunks":
                    response["result"]["next_chunk_index"] = 1
                elif label == "failed":
                    response["status"]["state"] = "FAILED"
                elif label == "row_count":
                    response["manifest"]["total_row_count"] = 4
                else:
                    response["result"]["external_links"] = [dict(external_link="https://example.com")]
                with self.assertRaises(ProbeError):
                    compare_response(case, response)

    def test_order(self):
        case, response = case_and_response()
        case["ordered"] = True
        with self.assertRaisesRegex(ProbeError, "RESULT_BAG_OR_ORDER"):
            compare_response(case, response)

    def test_empty_count_and_ranking_differ(self):
        for dtype in ("INT", "BIGINT"):
            case = dict(columns=[dict(name="v", type=dtype)], expected_rows=[["0"]], ordered=False)
            response = dict(status=dict(state="SUCCEEDED"), manifest=dict(format="JSON_ARRAY", total_row_count=0,
                schema=dict(columns=[dict(name="v", position=0, type_text=dtype)])), result={})
            with self.assertRaisesRegex(ProbeError, "RESULT_BAG_OR_ORDER"):
                compare_response(case, response)
            case["expected_rows"] = []
            compare_response(case, response)

    def test_decimal_dimension(self):
        case, response = case_and_response()
        case["columns"][0]["type"] = "DECIMAL(12,2)"
        response["manifest"]["schema"]["columns"][0]["type_text"] = "DECIMAL(12,3)"
        with self.assertRaisesRegex(ProbeError, "COLUMN_TYPE_OR_NAME"):
            compare_response(case, response)

    def test_ntz_representation_without_precision_loss(self):
        columns = [dict(type="TIMESTAMP_NTZ")]
        left = rows_key([["2026-01-02T03:04:05.1234560"]], columns, False)
        right = rows_key([["2026-01-02 03:04:05.123456"]], columns, False)
        self.assertEqual(left, right)
        for value in ("2026-01-02T03:04:05.1234567", "2026-01-02T03:04:05+01:00"):
            with self.assertRaisesRegex(ProbeError, "INVALID_NTZ_RESULT"):
                rows_key([[value]], columns, False)

    def test_json_numbers_are_not_typed_client_integers(self):
        case, response = case_and_response()
        response["result"]["data_array"][1] = [1]
        with self.assertRaisesRegex(ProbeError, "NON_STRING_API_VALUE"):
            compare_response(case, response)

    def test_missing_configuration(self):
        with patch.dict(os.environ, {}, clear=True):
            with self.assertRaisesRegex(ProbeError, "DATABRICKS_CONFIG_MISSING"):
                Client()

    def test_invalid_host_and_redirect(self):
        config = dict(DATABRICKS_TOKEN="synthetic-test-value", DATABRICKS_SQL_WAREHOUSE_ID="synthetic")
        for host in ("http://localhost", "https://localhost/private", "https://user@localhost"):
            with patch.dict(os.environ, dict(config, DATABRICKS_HOST=host), clear=True):
                with self.assertRaisesRegex(ProbeError, "DATABRICKS_HOST_INVALID"):
                    Client()
        with self.assertRaisesRegex(ProbeError, "HTTP_REDIRECT_REJECTED"):
            NoRedirect().redirect_request(None, None, 302, "", {}, "https://example.com")


if __name__ == "__main__":
    unittest.main()
