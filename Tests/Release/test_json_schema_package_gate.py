"""Abweisungs- und Quellbindungsprüfungen für das JSON-Schema-Paketgate."""
from __future__ import annotations

import hashlib
import io
import json
from pathlib import Path
import sys
import tempfile
import unittest
from unittest import mock
import zipfile

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / "Scripts/Release"))
import json_schema_package as gate


class JsonSchemaPackageGateMixin:
    def _fixture(self, framework_root: Path, match_package: bool = False):
        report, _ = gate.validate_predecessor(ROOT)
        public_pins = gate.validate_source_pins(ROOT, report)
        package_binaries = {}
        if match_package:
            _, package_binaries = gate.inspect_package(ROOT, report["package"]["sha256"])
        frozen = [
            {"path": str(gate._repo_path(ROOT, path)), "sha256": digest}
            for path, digest in public_pins.items()
        ]
        for index in range(5):
            path = framework_root.parent / f"tool-input-{index}.bin"
            path.write_bytes(f"fixed synthetic tool input {index}".encode())
            frozen.append({"path": str(path), "sha256": hashlib.sha256(path.read_bytes()).hexdigest()})

        binaries = {}
        binary_pins = []
        for filename in sorted(gate.EXPECTED_BINARIES):
            payload = package_binaries.get(filename, ("fixed synthetic framework output " + filename).encode())
            (framework_root / filename).write_bytes(payload)
            binaries[filename] = payload
            binary_pins.append({"fileName": filename, "sha256": hashlib.sha256(payload).hexdigest()})
        receipt = {
            "status": "COMPLETE",
            "scope": gate.EXPECTED_FRAMEWORK_SCOPE,
            "postPins": True,
            "phases": [
                {"name": name, "exitCode": 0, "captureComplete": True, "emptyStderr": True,
                 "witness": gate.EXPECTED_WITNESSES[name]}
                for name in gate.EXPECTED_PHASES
            ],
            "binaryPins": binary_pins,
        }
        schema_il = {
            "status": "PASS", "scope": "own product and pinned shared Core calls only", "unknown": [],
        }
        return report, public_pins, receipt, frozen, schema_il, binaries

    def test_public_predecessor_and_framework_inputs_are_exactly_bound(self):
        report, historic = gate.validate_predecessor(ROOT)
        self.assertEqual(gate.sha256(historic), gate.PREDECESSOR_REPORT_SHA256)
        self.assertEqual(report["package"]["sha256"], "896989d546ae7396b4b698e3228ec4c55fd49857f4d2408e125904faf6471287")
        self.assertEqual(report["framework"]["schema_binary_package_bound"], False)
        pins = gate.validate_source_pins(ROOT, report)
        self.assertEqual(len(pins), 38)
        package, binaries = gate.inspect_package(ROOT, report["package"]["sha256"])
        self.assertEqual(package["archive_sha256"], report["package"]["sha256"])
        self.assertEqual(set(binaries), {gate.SCHEMA_DLL, gate.CORE_DLL, gate.CONSTRUCTOR_DLL})
        self.assertEqual(package["schema"]["sha256"], hashlib.sha256(binaries[gate.SCHEMA_DLL]).hexdigest())

    def test_schema_public_evidence_binds_the_package_and_reused_receipt(self):
        evidence = json.loads((ROOT / "Releases/1.0.0/JSON-SCHEMA-PACKAGE-QUALIFICATION.json").read_bytes())
        predecessor, _ = gate.validate_predecessor(ROOT)
        self.assertEqual(set(evidence), {
            "schema_version", "date", "status", "scope", "publication_authorized", "native_sql",
            "predecessor", "package", "binaries", "reused_source_framework", "new_package_schema_il",
            "oracles", "implementation_pins", "offline_checks", "release_regression_suite", "limits",
        })
        self.assertEqual(evidence["status"], "PASS")
        self.assertEqual(evidence["scope"], "JSON_SCHEMA_RELEASE_PACKAGE_DIRECT_IL")
        self.assertFalse(evidence["publication_authorized"])
        self.assertEqual(evidence["native_sql"], "NOT_EXECUTED")
        self.assertEqual(evidence["predecessor"], {
            "main_commit": gate.PREDECESSOR_COMMIT,
            "report_path": gate.PREDECESSOR_REPORT.as_posix(),
            "report_sha256": gate.PREDECESSOR_REPORT_SHA256,
            "source_package_sha256": predecessor["package"]["sha256"],
        })
        self.assertEqual(evidence["package"]["sha256"], predecessor["package"]["sha256"])
        package_record, _ = gate.inspect_package(ROOT, predecessor["package"]["sha256"])
        self.assertEqual(set(evidence["binaries"]), {gate.SCHEMA_DLL, gate.CORE_DLL, gate.CONSTRUCTOR_DLL})
        self.assertEqual(evidence["binaries"][gate.SCHEMA_DLL]["direct_package_il"], "PASS")
        self.assertEqual(evidence["binaries"][gate.SCHEMA_DLL]["sha256"], package_record["schema"]["sha256"])
        self.assertEqual(evidence["binaries"][gate.SCHEMA_DLL]["size"], package_record["schema"]["size"])
        self.assertTrue(evidence["binaries"][gate.SCHEMA_DLL]["source_framework_byte_match"])
        self.assertTrue(evidence["binaries"][gate.SCHEMA_DLL]["manifest_sha_size_verified"])
        self.assertTrue(evidence["binaries"][gate.CORE_DLL]["direct_package_il_dependency"])
        self.assertEqual(evidence["binaries"][gate.CORE_DLL]["sha256"],
                         predecessor["package_binaries"][gate.CORE_DLL]["sha256"])
        self.assertEqual(evidence["binaries"][gate.CORE_DLL]["size"], package_record["core"]["size"])
        self.assertTrue(evidence["binaries"][gate.CORE_DLL]["source_framework_byte_match"])
        self.assertTrue(evidence["binaries"][gate.CORE_DLL]["manifest_sha_size_verified"])
        self.assertEqual(evidence["binaries"][gate.CONSTRUCTOR_DLL]["sha256"],
                         predecessor["package_binaries"][gate.CONSTRUCTOR_DLL]["sha256"])
        self.assertEqual(set(evidence["reused_source_framework"]), {
            "receipt_status", "scope", "completed_phases", "post_pins", "private_input_files_rechecked",
            "public_input_pins_rechecked", "binary_outputs_rechecked", "source_schema_il",
            "source_schema_il_was_direct_package", "framework_input_pins",
        })
        self.assertFalse(evidence["reused_source_framework"]["source_schema_il_was_direct_package"])
        self.assertEqual(evidence["reused_source_framework"]["receipt_status"], "COMPLETE")
        self.assertEqual(evidence["reused_source_framework"]["framework_input_pins"],
                         predecessor["framework_input_pins"])
        self.assertEqual(evidence["reused_source_framework"]["completed_phases"], 27)
        self.assertTrue(evidence["reused_source_framework"]["post_pins"])
        self.assertEqual(evidence["reused_source_framework"]["private_input_files_rechecked"], 43)
        self.assertEqual(evidence["reused_source_framework"]["public_input_pins_rechecked"], 38)
        self.assertEqual(evidence["reused_source_framework"]["binary_outputs_rechecked"], 9)
        self.assertEqual(evidence["new_package_schema_il"]["unknown_bindings"], 0)
        self.assertTrue(evidence["new_package_schema_il"]["direct_package_binary"])
        self.assertEqual(evidence["new_package_schema_il"]["status"], "PASS")
        self.assertEqual(evidence["new_package_schema_il"]["host"], "Windows PowerShell 5.1")
        self.assertEqual(set(evidence["new_package_schema_il"]), {
            "status", "scope", "direct_package_binary", "guard_path", "host", "unknown_bindings",
            "schema_sha256", "core_dependency_sha256",
        })
        self.assertEqual(evidence["offline_checks"], {
            "schema_package_gate_tests": 9, "status": "PASS", "python_compile": "PASS",
            "powershell_ast": "PASS",
        })
        self.assertEqual(evidence["release_regression_suite"], {
            "command": "python -B Tests/Release/test_prepare_release.py",
            "tests": 148, "status": "PASS", "elapsed_seconds": 291.842,
        })
        self.assertEqual(gate.validate_source_pins(ROOT, predecessor), predecessor["framework_input_pins"])
        for item in evidence["oracles"].values():
            self.assertEqual(hashlib.sha256((ROOT / item["path"]).read_bytes()).hexdigest(), item["sha256"])
        for relative, digest in evidence["implementation_pins"].items():
            self.assertEqual(hashlib.sha256((ROOT / relative).read_bytes()).hexdigest(), digest)
        self.assertEqual(set(evidence["implementation_pins"]), {
            "Scripts/Release/json_schema_package.py",
            "Tests/Release/Invoke-JsonSchemaPackageQualification.ps1",
            "Modules/toolbelt.json.core/Tests/Framework/Test-JsonClosureIL.ps1",
            "Scripts/Release/json_constructor_package.py",
        })
        self.assertEqual(set(evidence["oracles"]), {"bridge", "numbers"})
        self.assertFalse(any(".runtime" in str(value) for value in evidence.values()))

    def test_framework_receipt_requires_complete_phases_and_fresh_sources(self):
        (ROOT / ".runtime").mkdir(exist_ok=True)
        with tempfile.TemporaryDirectory(dir=ROOT / ".runtime", prefix="json-schema-gate-") as temp:
            framework = Path(temp) / "framework"
            framework.mkdir()
            report, public_pins, receipt, frozen, schema_il, binaries = self._fixture(framework)
            actual = gate.validate_framework_receipt(ROOT, framework, public_pins, receipt, frozen, schema_il)
            self.assertEqual(len(actual), 9)
            self.assertEqual(actual[gate.SCHEMA_DLL]["sha256"], hashlib.sha256(binaries[gate.SCHEMA_DLL]).hexdigest())

            bad_phase = json.loads(json.dumps(receipt))
            bad_phase["phases"][7]["exitCode"] = 1
            with self.assertRaisesRegex(gate.SchemaPackageError, "FRAMEWORK_PHASES_INCOMPLETE"):
                gate.validate_framework_receipt(ROOT, framework, public_pins, bad_phase, frozen, schema_il)
            bad_witness = json.loads(json.dumps(receipt))
            bad_witness["phases"][12]["witness"] = "unexpected output"
            with self.assertRaisesRegex(gate.SchemaPackageError, "FRAMEWORK_PHASES_INCOMPLETE"):
                gate.validate_framework_receipt(ROOT, framework, public_pins, bad_witness, frozen, schema_il)
            with self.assertRaisesRegex(gate.SchemaPackageError, "FRAMEWORK_RECEIPT_INVALID"):
                gate.validate_framework_receipt(ROOT, framework, public_pins, None, frozen, schema_il)

            bad_input = json.loads(json.dumps(frozen))
            bad_input[0]["sha256"] = "0" * 64
            with self.assertRaisesRegex(gate.SchemaPackageError, "FRAMEWORK_FROZEN_INPUT_DRIFT"):
                gate.validate_framework_receipt(ROOT, framework, public_pins, receipt, bad_input, schema_il)

            (framework / gate.SCHEMA_DLL).write_bytes(b"unexpected synthetic output")
            with self.assertRaisesRegex(gate.SchemaPackageError, "FRAMEWORK_BINARY_OUTPUT_DRIFT"):
                gate.validate_framework_receipt(ROOT, framework, public_pins, receipt, frozen, schema_il)

    def test_schema_manifest_hash_is_checked_even_with_matching_outer_hash(self):
        package_path = ROOT / gate.PACKAGE_REL
        original = package_path.read_bytes()
        source = zipfile.ZipFile(io.BytesIO(original))
        mutated = io.BytesIO()
        with source, zipfile.ZipFile(mutated, "w", zipfile.ZIP_DEFLATED) as target:
            for info in source.infolist():
                payload = source.read(info.filename)
                if info.filename == gate.MANIFEST:
                    manifest = json.loads(payload)
                    manifest["files"]["Binaries/Toolbelt.JsonSchema.dll"]["sha256"] = "0" * 64
                    payload = json.dumps(manifest, sort_keys=True, separators=(",", ":")).encode()
                target.writestr(info, payload)
        data = mutated.getvalue()
        with self.assertRaisesRegex(gate.SchemaPackageError, "PACKAGE_SCHEMA_CONTENT_MISMATCH"):
            gate.validate_package_bytes(data, hashlib.sha256(data).hexdigest())

        source = zipfile.ZipFile(io.BytesIO(original))
        mutated_size = io.BytesIO()
        with source, zipfile.ZipFile(mutated_size, "w", zipfile.ZIP_DEFLATED) as target:
            for info in source.infolist():
                payload = source.read(info.filename)
                if info.filename == gate.MANIFEST:
                    manifest = json.loads(payload)
                    manifest["files"]["Binaries/Toolbelt.JsonSchema.dll"]["size"] += 1
                    payload = json.dumps(manifest, sort_keys=True, separators=(",", ":")).encode()
                target.writestr(info, payload)
        data = mutated_size.getvalue()
        with self.assertRaisesRegex(gate.SchemaPackageError, "PACKAGE_SCHEMA_CONTENT_MISMATCH"):
            gate.validate_package_bytes(data, hashlib.sha256(data).hexdigest())

    def test_package_archive_hash_and_fixed_oracle_pins_reject_drift(self):
        report, _ = gate.validate_predecessor(ROOT)
        package = (ROOT / gate.PACKAGE_REL).read_bytes()
        with self.assertRaisesRegex(gate.constructor_gate.PackageBindingError, "PACKAGE_ARCHIVE_HASH_MISMATCH"):
            gate.validate_package_bytes(package, "0" * 64)

        bad_report = json.loads(json.dumps(report))
        bad_report["framework_input_pins"]["Modules/toolbelt.json.schema/Tests/Framework/NumberOracles.tsv"] = "0" * 64
        with self.assertRaisesRegex(gate.SchemaPackageError, "FRAMEWORK_PUBLIC_INPUT_DRIFT"):
            gate.validate_source_pins(ROOT, bad_report)

    def test_schema_framework_output_must_equal_the_package_binary(self):
        (ROOT / ".runtime").mkdir(exist_ok=True)
        with tempfile.TemporaryDirectory(dir=ROOT / ".runtime", prefix="json-schema-output-") as temp:
            framework = Path(temp) / "framework"
            framework.mkdir()
            report, public_pins, receipt, frozen, schema_il, binaries = self._fixture(framework, match_package=True)
            framework_pins = gate.validate_framework_receipt(ROOT, framework, public_pins, receipt, frozen, schema_il)
            package_record, package_binaries = gate.inspect_package(ROOT, report["package"]["sha256"])
            gate.validate_source_package_match(framework, package_binaries, framework_pins)
            self.assertEqual(package_record["schema"]["sha256"], framework_pins[gate.SCHEMA_DLL]["sha256"])

            (framework / gate.SCHEMA_DLL).write_bytes(b"different output")
            with self.assertRaisesRegex(gate.SchemaPackageError, "PACKAGE_SOURCE_DLL_MISMATCH"):
                gate.validate_source_package_match(framework, package_binaries, framework_pins)

    def test_output_scope_rejects_external_path_before_creating_it(self):
        outside = ROOT / "json-schema-output-must-not-exist"
        with self.assertRaisesRegex(gate.SchemaPackageError, "PRIVATE_RUNTIME_SCOPE_INVALID"):
            gate.prepare(ROOT, ROOT / ".runtime/missing-framework-receipt", outside)
        self.assertFalse(outside.exists())

    def test_runtime_symlink_is_rejected_without_creating_output(self):
        private = Path(ROOT / ".runtime")
        output = private / "json-schema-symlink-output"
        with mock.patch.object(Path, "is_symlink", autospec=True, side_effect=lambda path: path == private):
            with self.assertRaisesRegex(gate.SchemaPackageError, "PRIVATE_RUNTIME_SCOPE_INVALID"):
                gate.prepare(ROOT, private / "missing-framework", output)
        self.assertFalse(output.exists())

    def test_postvalidation_rejects_receipt_and_framework_output_replacement(self):
        (ROOT / ".runtime").mkdir(exist_ok=True)
        with tempfile.TemporaryDirectory(dir=ROOT / ".runtime", prefix="json-schema-reuse-") as temp:
            temporary = Path(temp)
            framework = temporary / "framework"
            framework.mkdir()
            _, _, receipt, frozen, schema_il, _ = self._fixture(framework, match_package=True)
            (framework / "Receipt.private.json").write_text(json.dumps(receipt), encoding="utf-8")
            (framework / "FrozenInputs.private.json").write_text(json.dumps(frozen), encoding="utf-8")
            (framework / "Toolbelt.JsonSchema.IL.private.json").write_text(json.dumps(schema_il), encoding="utf-8")
            output = temporary / "qualification"
            prepared = gate.prepare(ROOT, framework, output)
            binding = json.loads((output / "Binding.private.json").read_bytes())
            self.assertEqual(len(binding["source_framework_output_sha256"]), 9)
            self.assertEqual(len(binding["source_receipt_sha256"]), 64)
            self.assertEqual(prepared["source_receipt_sha256"], binding["source_receipt_sha256"])

            changed = framework / "ProductHarness.exe"
            changed.write_bytes(b"replacement synthetic harness output")
            for pin in receipt["binaryPins"]:
                if pin["fileName"] == changed.name:
                    pin["sha256"] = hashlib.sha256(changed.read_bytes()).hexdigest()
            (framework / "Receipt.private.json").write_text(json.dumps(receipt), encoding="utf-8")
            with self.assertRaisesRegex(gate.SchemaPackageError, "PACKAGE_BINDING_CHANGED_DURING_IL"):
                gate.postvalidate(ROOT, framework, output)
