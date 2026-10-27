"""Negative Paketbindungskontrollen für den JSON-Constructor-Frameworkgate."""
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
import xml.etree.ElementTree as ET

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / "Scripts/Release"))
import json_constructor_package as gate


class JsonConstructorPackageGateMixin:
    def _package_bytes(self) -> bytes:
        return (ROOT / gate.PACKAGE_REL).read_bytes()

    def _rewrite(self, change) -> bytes:
        source = zipfile.ZipFile(io.BytesIO(self._package_bytes()))
        output = io.BytesIO()
        with source, zipfile.ZipFile(output, "w", zipfile.ZIP_DEFLATED) as target:
            for info in source.infolist():
                payload = source.read(info.filename)
                if info.filename == gate.MANIFEST:
                    manifest = json.loads(payload)
                    change(manifest, target)
                    payload = json.dumps(manifest, sort_keys=True, separators=(",", ":")).encode()
                target.writestr(info, payload)
            change.finish(target) if hasattr(change, "finish") else None
        return output.getvalue()

    def test_current_package_binds_exact_constructor_and_core_dlls(self):
        record, binaries = gate.inspect_package(ROOT)
        self.assertEqual(set(binaries), {"Toolbelt.JsonConstructors.dll", "Toolbelt.JsonCore.dll"})
        self.assertEqual(record["files"]["Toolbelt.JsonConstructors.dll"]["sha256"],
                         hashlib.sha256(binaries["Toolbelt.JsonConstructors.dll"]).hexdigest())
        self.assertEqual(record["files"]["Toolbelt.JsonCore.dll"]["sha256"],
                         hashlib.sha256(binaries["Toolbelt.JsonCore.dll"]).hexdigest())

    def test_public_evidence_binds_current_sources_package_and_scope(self):
        report = json.loads((ROOT / "Releases/1.0.0/JSON-CONSTRUCTORS-PACKAGE-QUALIFICATION.json").read_bytes())
        self.assertEqual(report["status"], "PASS")
        self.assertEqual(report["scope"], "JSON_CONSTRUCTORS_RELEASE_PACKAGE_FRAMEWORK_AND_CORE_CLOSURE_IL")
        self.assertEqual(report["native_sql"], "NOT_EXECUTED")
        self.assertFalse(report["publication_authorized"])
        self.assertFalse(report["framework"]["schema_binary_package_bound"])
        self.assertEqual(report["framework"]["completed_phases"], 27)
        self.assertTrue(report["framework"]["post_pins"])
        self.assertEqual(set(report["package_binaries"]),
                         {"Toolbelt.JsonConstructors.dll", "Toolbelt.JsonCore.dll"})
        self.assertEqual(report["package_binaries"]["Toolbelt.JsonConstructors.dll"]["direct_il"], "PASS")
        self.assertFalse(report["package_binaries"]["Toolbelt.JsonCore.dll"]["direct_package_il"])
        self.assertEqual(report["package_binaries"]["Toolbelt.JsonCore.dll"]["source_closure_il"],
                         "BESTANDEN; Paketbytes sind exakt bytegleich")
        self.assertEqual(report["oracles"]["sha256"],
                         "6dec6c30b8a362d1ee55408c69e84f92a7a902e5977be9eee801dbea9aa16fbf")
        self.assertEqual(report["oracles"]["cultures"], ["de-DE", "en-US", "tr-TR"])
        self.assertEqual((report["oracles"]["rows_per_run"], report["oracles"]["assertions_per_run"],
                          report["oracles"]["large_rows"], report["oracles"]["large_assertions"]),
                         (37, 960, 3, 67))
        fixed = {
            "Modules/toolbelt.json.constructors/Clr/Toolbelt.JsonConstructors.csproj",
            "Modules/toolbelt.json.core/Clr/Toolbelt.JsonCore.csproj",
            "Modules/toolbelt.json.schema/Clr/Toolbelt.JsonSchema.csproj",
            "Modules/toolbelt.json.core/Tests/Framework/Test-JsonClosureIL.ps1",
            "Modules/toolbelt.json.core/Tests/Framework/Test-RejectedClosure.ps1",
            "Modules/toolbelt.json.core/Tests/Framework/RejectedClosureFixture.cs",
            "Modules/toolbelt.json.constructors/Scripts/Invoke-OwnedProcess.ps1",
            "Modules/toolbelt.json.schema/Tests/Framework/Invoke-SourceQualification.ps1",
            "Modules/toolbelt.json.constructors/Tests/Framework/BridgeGoldens.tsv",
            "Modules/toolbelt.json.schema/Tests/Framework/NumberOracles.tsv",
            "Modules/toolbelt.json.schema/Tests/Framework/generate-number-oracles.py",
            "Modules/toolbelt.json.constructors/Tests/Framework/ProductHarness.cs",
            "Modules/toolbelt.json.core/Tests/Framework/TokenHarness.cs",
            "Modules/toolbelt.json.core/Tests/Framework/WorkBudgetHarness.cs",
            "Modules/toolbelt.json.schema/Tests/Framework/NumberHarness.cs",
            "Modules/toolbelt.json.schema/Tests/Framework/SchemaHarness.cs",
            "Modules/toolbelt.json.schema/Tests/Framework/BridgeHarness.cs",
        }
        expected_inputs = set(fixed)
        for project in (p for p in fixed if p.endswith(".csproj")):
            xml = ET.parse(ROOT / project).getroot()
            for node in xml.iter():
                if node.tag.endswith("Compile"):
                    expected_inputs.add((ROOT / Path(project).parent / node.attrib["Include"]).resolve().relative_to(ROOT).as_posix())
        self.assertEqual(set(report["framework_input_pins"]), expected_inputs)
        self.assertTrue(all(path.startswith("Modules/") for path in report["framework_input_pins"]))
        for relative, digest in report["framework_input_pins"].items():
            self.assertEqual(hashlib.sha256((ROOT / relative).read_bytes()).hexdigest(), digest)
        self.assertEqual(report["setup_history"][0]["status"], "FAILED_BEFORE_FRAMEWORK_PHASES")
        self.assertEqual(report["setup_history"][0]["framework_phases"], 0)
        self.assertEqual(report["setup_history"][1], {"status": "PASS", "framework_phases": 27})
        self.assertEqual(set(report["implementation_pins"]), {
            "Tests/Release/Invoke-JsonConstructorsPackageQualification.ps1",
            "Scripts/Release/json_constructor_package.py",
            "Modules/toolbelt.json.constructors/Tests/Framework/Invoke-Framework.ps1",
            "Modules/toolbelt.json.schema/Tests/Framework/Invoke-SourceQualification.ps1",
            "Modules/toolbelt.json.core/Tests/Framework/Test-JsonClosureIL.ps1",
        })
        self.assertEqual(report["release_regression_suite"], {
            "command": "python -B Tests/Release/test_prepare_release.py",
            "tests": 139,
            "status": "PASS",
            "elapsed_seconds": 298.935,
        })
        self.assertEqual(report["post_run_evidence_binding_test"], {
            "test": "CallerMetadataTests.test_public_evidence_binds_current_sources_package_and_scope",
            "status": "PASS",
            "tests": 1,
            "elapsed_seconds": 0.266,
        })
        record, binaries = gate.inspect_package(ROOT)
        self.assertEqual(report["package"]["sha256"], record["archive_sha256"])
        for filename, payload in binaries.items():
            self.assertEqual(report["package_binaries"][filename]["sha256"],
                             hashlib.sha256(payload).hexdigest())
            self.assertTrue(report["package_binaries"][filename]["framework_source_binary_byte_match"])
        for relative, digest in report["implementation_pins"].items():
            self.assertEqual(hashlib.sha256((ROOT / relative).read_bytes()).hexdigest(), digest)

    def test_outer_package_hash_mismatch_is_rejected(self):
        data = self._package_bytes()
        with self.assertRaisesRegex(gate.PackageBindingError, "PACKAGE_ARCHIVE_HASH_MISMATCH"):
            gate._validate_archive(data, "0" * 64)

    def test_dll_manifest_drift_is_rejected_even_with_matching_outer_hash(self):
        def corrupt(manifest, _target):
            manifest["files"]["Binaries/Toolbelt.JsonConstructors.dll"]["sha256"] = "0" * 64

        data = self._rewrite(corrupt)
        with self.assertRaisesRegex(gate.PackageBindingError, "PACKAGE_DLL_CONTENT_MISMATCH"):
            gate._validate_archive(data, hashlib.sha256(data).hexdigest())

    def test_unlisted_package_entry_and_duplicate_entry_are_rejected(self):
        def add_entry(manifest, target):
            target.writestr(gate.PREFIX + "Binaries/Unlisted.dll", b"synthetic")

        data = self._rewrite(add_entry)
        with self.assertRaisesRegex(gate.PackageBindingError, "PACKAGE_FILE_SET_MISMATCH"):
            gate._validate_archive(data, hashlib.sha256(data).hexdigest())

        source = zipfile.ZipFile(io.BytesIO(self._package_bytes()))
        duplicate = io.BytesIO()
        with source, warnings.catch_warnings(), zipfile.ZipFile(duplicate, "w", zipfile.ZIP_DEFLATED) as target:
            warnings.simplefilter("ignore", UserWarning)
            for info in source.infolist():
                target.writestr(info.filename, source.read(info.filename))
            first = source.infolist()[0].filename
            target.writestr(first, source.read(first))
        data = duplicate.getvalue()
        with self.assertRaisesRegex(gate.PackageBindingError, "PACKAGE_DUPLICATE_ENTRY"):
            gate._validate_archive(data, hashlib.sha256(data).hexdigest())

    def test_zip_traversal_is_rejected(self):
        source = zipfile.ZipFile(io.BytesIO(self._package_bytes()))
        traversal = io.BytesIO()
        with source, zipfile.ZipFile(traversal, "w", zipfile.ZIP_DEFLATED) as target:
            for info in source.infolist():
                target.writestr(info, source.read(info.filename))
            target.writestr(gate.PREFIX + "../../outside.bin", b"synthetic")
        data = traversal.getvalue()
        with self.assertRaisesRegex(gate.PackageBindingError, "PACKAGE_UNSAFE_ENTRY"):
            gate._validate_archive(data, hashlib.sha256(data).hexdigest())

    def test_extraction_requires_fresh_private_runtime_scope(self):
        with self.assertRaisesRegex(gate.PackageBindingError, "PACKAGE_OUTPUT_SCOPE_INVALID"):
            gate.extract_package(ROOT, ROOT / "outside-package-output")
        (ROOT / ".runtime").mkdir(exist_ok=True)
        with tempfile.TemporaryDirectory(dir=ROOT / ".runtime", prefix="json-package-gate-") as temp:
            parent = Path(temp)
            target = parent / "extracted"
            record = gate.extract_package(ROOT, target)
            self.assertEqual(set(p.name for p in target.iterdir()),
                             {"Toolbelt.JsonConstructors.dll", "Toolbelt.JsonCore.dll"})
            self.assertEqual(record["archive_sha256"], gate.inspect_package(ROOT)[0]["archive_sha256"])
            with self.assertRaisesRegex(gate.PackageBindingError, "PACKAGE_OUTPUT_EXISTS"):
                gate.extract_package(ROOT, target)
