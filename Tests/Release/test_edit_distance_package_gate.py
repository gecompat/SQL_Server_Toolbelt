"""Synthetische Regressionen für die Edit-Distance-Paketbindung."""
from __future__ import annotations

import hashlib
import io
import json
from pathlib import Path
import sys
import tempfile
import unittest
import warnings
import zipfile
from unittest.mock import patch

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / "Scripts/Release"))
import edit_distance_package as gate


class EditDistancePackageGateMixin:
    @staticmethod
    def _validate_public_report(report):
        required = {"schema_version", "date", "status", "scope", "publication_authorized",
                    "native_sql", "package", "module", "fixed_contract", "module_source_sha256",
                    "implementation_sha256", "qualification", "setup_history", "limits"}
        if set(report) != required or report["status"] != "PASS" or report["publication_authorized"] is not False:
            raise ValueError("EDIT_DISTANCE_REPORT_SCOPE")
        if report["schema_version"] != "1.0" or report["date"] != "2026-10-27" or \
                report["scope"] != "EDIT_DISTANCE_1_1_0_PACKAGE_BOUND_FIXED_DISTANCE_AND_JARO_CONTRACT_AND_BOUNDED_IL_INSPECTION" or \
                report["native_sql"] != "NOT_EXECUTED":
            raise ValueError("EDIT_DISTANCE_REPORT_IDENTITY")
        if report["package"] != {"path": gate.PACKAGE, "sha256": gate.PACKAGE_SHA256}:
            raise ValueError("EDIT_DISTANCE_REPORT_PACKAGE")
        module = report["module"]
        if module != {"id": gate.MODULE_ID, "version": "1.1.0", "assembly": gate.DLL,
                      "assembly_sha256": "db74ba68d7cf2370a88f7b6bf5f190904145ab5da0614a57918957f307f3a29b",
                      "matches_extracted_package_bytes": True}:
            raise ValueError("EDIT_DISTANCE_REPORT_MODULE")
        if gate.sha((ROOT / gate.PACKAGE).read_bytes()) != gate.PACKAGE_SHA256:
            raise ValueError("EDIT_DISTANCE_REPORT_PACKAGE_BYTES")
        qualification = report["qualification"]
        if qualification != {"status": "PASS",
                             "framework_stages": ["python_reference", "package_binding", "golden_generation",
                                                  "framework_compile", "framework_contract"],
                             "bounded_il_inspection": "PASS", "hidden_process_chain": "PASS",
                             "final_package_byte_comparison": "PASS", "sql_or_lab": "NOT_EXECUTED"}:
            raise ValueError("EDIT_DISTANCE_REPORT_QUALIFICATION")
        if report["setup_history"] != [
                {"status": "REJECTED_BEFORE_CHILD_START", "cause": "Ausgabepfad außerhalb des festgelegten privaten Zielbereichs"},
                {"status": "FUNCTIONAL_STAGES_PASS_FINAL_AUDIT_FAILED", "cause": "Unvollständige Pfadliste im abschließenden Eingabepin-Audit"},
                {"status": "PASS", "framework_stages": 5}]:
            raise ValueError("EDIT_DISTANCE_REPORT_HISTORY")
        contract = report["fixed_contract"]
        if (contract["independent_reference_assertions"], contract["distance_golden_rows"],
            contract["jaro_golden_pairs"], contract["contract_assertions"]) != (21185, 27104, 60, 109333):
            raise ValueError("EDIT_DISTANCE_REPORT_ORACLE")
        sources = {**report["module_source_sha256"], **contract["oracle_sources"],
                   **report["implementation_sha256"]}
        if set(report["module_source_sha256"]) != set(gate.SOURCE_PATHS):
            raise ValueError("EDIT_DISTANCE_REPORT_SOURCE_SET")
        if set(contract["oracle_sources"]) != set(gate.FRAMEWORK_ORACLE_SHA256):
            raise ValueError("EDIT_DISTANCE_REPORT_ORACLE_SET")
        expected_implementation = {"Scripts/Release/edit_distance_package.py",
                                   "Tests/Release/Invoke-EditDistancePackageQualification.ps1",
                                   "Tests/Release/EditDistancePackageContract.cs",
                                   "Tests/Release/Test-EditDistancePackageIL.ps1",
                                   "Tests/Release/run_hidden_python.py",
                                   "Tests/Release/hidden_python_probe.py"}
        if set(report["implementation_sha256"]) != expected_implementation:
            raise ValueError("EDIT_DISTANCE_REPORT_IMPLEMENTATION_SET")
        for relative, expected in sources.items():
            if gate.sha((ROOT / relative).read_bytes()) != expected:
                raise ValueError("EDIT_DISTANCE_REPORT_SOURCE_PIN")

    @staticmethod
    def _inputs():
        return ((ROOT / gate.PACKAGE).read_bytes(), (ROOT / gate.SIDECAR).read_bytes(),
                (ROOT / gate.QUALIFICATION).read_bytes(), (ROOT / gate.SOURCE_REPORT).read_bytes(),
                {path: (ROOT / path).read_bytes() for path in gate.SOURCE_PATHS},
                {path: (ROOT / path).read_bytes() for path in gate.FRAMEWORK_ORACLE_SHA256})

    @staticmethod
    def _rewrite_edit_distance_archive(entries):
        stream = io.BytesIO()
        with zipfile.ZipFile(stream, "w", compression=zipfile.ZIP_DEFLATED) as archive:
            for name, data in entries:
                archive.writestr(name, data)
        return stream.getvalue()

    def test_edit_distance_package_binary_matches_original_release_pin(self):
        archive, sidecar, qualification, source_report, source_files, oracle_files = self._inputs()
        record, binary = gate.inspect_bytes(archive, sidecar, qualification, source_report, source_files, oracle_files)
        self.assertEqual(record["module_id"], gate.MODULE_ID)
        self.assertEqual(record["package_sha256"], gate.PACKAGE_SHA256)
        self.assertEqual(record["assembly_sha512"], gate.DLL_SHA512)
        self.assertEqual(record["assembly_sha512"], record["qualification_pin_sha512"])
        self.assertEqual(hashlib.sha256(binary).hexdigest(), record["assembly_sha256"])

    def test_edit_distance_sidecar_drift_is_rejected(self):
        archive, sidecar, qualification, source_report, source_files, oracle_files = self._inputs()
        with self.assertRaisesRegex(gate.PackageError, "EDIT_DISTANCE_SIDECAR"):
            gate.inspect_bytes(archive, sidecar + b"\n", qualification, source_report, source_files, oracle_files)

    def test_changed_package_dll_is_rejected_even_with_new_outer_digest(self):
        archive, _sidecar, qualification, source_report, source_files, oracle_files = self._inputs()
        entries = gate._read_archive(archive)
        entries[gate.DLL_ENTRY] += b"tamper"
        changed = self._rewrite_edit_distance_archive(entries.items())
        sidecar = f"{gate.sha(changed)}  {Path(gate.PACKAGE).name}\n".encode("ascii")
        with patch.object(gate, "PACKAGE_SHA256", gate.sha(changed)):
            with self.assertRaisesRegex(gate.PackageError, "EDIT_DISTANCE_PACKAGE_BINARY_BINDING"):
                gate.inspect_bytes(changed, sidecar, qualification, source_report, source_files, oracle_files)

    def test_duplicate_archive_member_is_rejected_before_manifest_binding(self):
        archive, _sidecar, qualification, source_report, source_files, oracle_files = self._inputs()
        entries = gate._read_archive(archive)
        stream = io.BytesIO()
        with warnings.catch_warnings():
            warnings.simplefilter("ignore", UserWarning)
            with zipfile.ZipFile(stream, "w", compression=zipfile.ZIP_STORED) as zf:
                zf.writestr(gate.MANIFEST, entries[gate.MANIFEST])
                zf.writestr(gate.MANIFEST, entries[gate.MANIFEST])
        duplicate = stream.getvalue()
        sidecar = f"{gate.sha(duplicate)}  {Path(gate.PACKAGE).name}\n".encode("ascii")
        with patch.object(gate, "PACKAGE_SHA256", gate.sha(duplicate)):
            with self.assertRaisesRegex(gate.PackageError, "EDIT_DISTANCE_PACKAGE_PATH"):
                gate.inspect_bytes(duplicate, sidecar, qualification, source_report, source_files, oracle_files)

    def test_archive_traversal_member_is_rejected_with_matching_outer_pin(self):
        archive, _sidecar, qualification, source_report, source_files, oracle_files = self._inputs()
        changed = self._rewrite_edit_distance_archive((("../escape.dll", b"x"),))
        sidecar = f"{gate.sha(changed)}  {Path(gate.PACKAGE).name}\n".encode("ascii")
        with patch.object(gate, "PACKAGE_SHA256", gate.sha(changed)):
            with self.assertRaisesRegex(gate.PackageError, "EDIT_DISTANCE_PACKAGE_PATH"):
                gate.inspect_bytes(changed, sidecar, qualification, source_report, source_files, oracle_files)

    def test_source_report_and_every_module_input_are_pinned(self):
        archive, sidecar, qualification, source_report, source_files, oracle_files = self._inputs()
        with self.assertRaisesRegex(gate.PackageError, "EDIT_DISTANCE_SOURCE_REPORT_PIN"):
            gate.inspect_bytes(archive, sidecar, qualification, source_report + b" ", source_files, oracle_files)
        changed = dict(source_files)
        changed[gate.SOURCE_PATHS[0]] += b"\n"
        with self.assertRaisesRegex(gate.PackageError, "EDIT_DISTANCE_SOURCE_PIN_DRIFT"):
            gate.inspect_bytes(archive, sidecar, qualification, source_report, changed, oracle_files)
        changed_oracles = dict(oracle_files)
        oracle_path = next(iter(gate.FRAMEWORK_ORACLE_SHA256))
        changed_oracles[oracle_path] += b"\n"
        with self.assertRaisesRegex(gate.PackageError, "EDIT_DISTANCE_ORACLE_PIN_DRIFT"):
            gate.inspect_bytes(archive, sidecar, qualification, source_report, source_files, changed_oracles)

    def test_output_path_must_be_a_fresh_direct_runtime_child(self):
        (ROOT / ".runtime").mkdir(exist_ok=True)
        with tempfile.TemporaryDirectory(dir=ROOT / ".runtime", prefix="edit-distance-scope-") as folder:
            rejected = Path(folder) / "nested"
            with self.assertRaisesRegex(gate.PackageError, "EDIT_DISTANCE_OUTPUT_SCOPE"):
                gate.prepare(ROOT, rejected)
            self.assertFalse(rejected.exists())

    def test_public_evidence_binds_fixed_contract_and_current_sources(self):
        report_path = ROOT / "Releases/1.0.0/EDIT-DISTANCE-PACKAGE-QUALIFICATION.json"
        report = json.loads(report_path.read_bytes())
        self._validate_public_report(report)
        self.assertEqual(report["status"], "PASS")
        self.assertEqual(report["package"]["sha256"], gate.PACKAGE_SHA256)
        self.assertRegex(report["module"]["assembly_sha256"], r"^[0-9a-f]{64}$")
        self.assertTrue(report["module"]["matches_extracted_package_bytes"])
        contract = report["fixed_contract"]
        self.assertEqual((contract["independent_reference_assertions"],
                          contract["distance_golden_rows"], contract["jaro_golden_pairs"],
                          contract["contract_assertions"]), (21185, 27104, 60, 109333))
        self.assertEqual(set(contract["oracle_sources"]), set(gate.FRAMEWORK_ORACLE_SHA256))
        self.assertEqual(set(report["module_source_sha256"]), set(gate.SOURCE_PATHS))
        for relative, expected in {**report["module_source_sha256"], **contract["oracle_sources"],
                                   **report["implementation_sha256"]}.items():
            self.assertEqual(gate.sha((ROOT / relative).read_bytes()), expected, relative)
        self.assertEqual(gate.sha((ROOT / gate.PACKAGE).read_bytes()), gate.PACKAGE_SHA256)
        self.assertFalse(report["publication_authorized"])
        self.assertEqual(report["native_sql"], "NOT_EXECUTED")

    def test_public_evidence_rejects_unknown_or_changed_scope_claims(self):
        report = json.loads((ROOT / "Releases/1.0.0/EDIT-DISTANCE-PACKAGE-QUALIFICATION.json").read_bytes())
        for altered in (dict(report, unexpected_claim=True),
                        dict(report, status="INCOMPLETE"),
                        dict(report, publication_authorized=True)):
            with self.subTest(claim=sorted(set(altered) - set(report)) or altered["status"]), \
                 self.assertRaises(ValueError):
                self._validate_public_report(altered)

    def test_public_evidence_rejects_package_and_oracle_pin_drift(self):
        report = json.loads((ROOT / "Releases/1.0.0/EDIT-DISTANCE-PACKAGE-QUALIFICATION.json").read_bytes())
        package_drift = dict(report, package={**report["package"], "sha256": "0" * 64})
        oracle_drift = dict(report, fixed_contract={**report["fixed_contract"], "distance_golden_rows": 27105})
        source_drift = dict(report, module_source_sha256={**report["module_source_sha256"],
                                                          gate.SOURCE_PATHS[0]: "0" * 64})
        for altered in (package_drift, oracle_drift, source_drift):
            with self.assertRaises(ValueError):
                self._validate_public_report(altered)

    def test_public_evidence_preserves_setup_history_and_scope_limits(self):
        report = json.loads((ROOT / "Releases/1.0.0/EDIT-DISTANCE-PACKAGE-QUALIFICATION.json").read_bytes())
        self._validate_public_report(report)
        altered = dict(report, setup_history=report["setup_history"][:-1])
        with self.assertRaisesRegex(ValueError, "EDIT_DISTANCE_REPORT_HISTORY"):
            self._validate_public_report(altered)
        self.assertTrue(any("begrenzte Inspektion" in item for item in report["limits"]))
