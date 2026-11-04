"""Exact delivery and scope controls for the Windows V1 procedure package."""
import json
from pathlib import Path
import sys
import unittest
from unittest import mock

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / "Scripts/Release"))
import validate_ssis_current_package as package
from ssis_historical_context import historical_root


class ProcedureDelivery(unittest.TestCase):
    def setUp(self):
        self.source_root = historical_root(ROOT, '410c994f657888faf5ccb1097b1d1a985a98ec96')

    def test_exact_executed_archive_and_current_inputs(self):
        package.validate_procedure_delivery(source_root=self.source_root)

    def test_other_archive_or_missing_audit_cannot_reuse_the_execution(self):
        read = package.read_regular_bounded
        path = ROOT / package.PROCEDURE_DELIVERY
        for field, key, value, reason in (
            ("package", "sha256", "0" * 64, "exact executed ZIP"),
            ("case", "cleanup_audit", "not executed", "package execution scope"),
            ("case", "deployment_mode", "central", "package execution scope"),
            ("case", "patch", "base", "package execution scope"),
        ):
            record = json.loads(path.read_bytes())
            record[field][key] = value

            def changed(candidate, maximum):
                return json.dumps(record).encode() if candidate == path else read(candidate, maximum)

            with self.subTest(field=field, key=key), mock.patch.object(package, "read_regular_bounded", changed):
                with self.assertRaisesRegex(ValueError, reason):
                    package.validate_procedure_delivery(source_root=self.source_root)

    def test_live_executable_source_drift_requires_new_qualification(self):
        read = package.read_regular_bounded
        source = self.source_root / package.MODULE / "Clr/ProcedureDefinition.cs"

        def changed(path, maximum):
            data = read(path, maximum)
            return data + b"\n// synthetic drift\n" if path == source else data

        with mock.patch.object(package, "read_regular_bounded", changed):
            with self.assertRaisesRegex(ValueError, "product source changed"):
                package.validate_procedure_delivery(source_root=self.source_root)


if __name__ == "__main__":
    unittest.main()
