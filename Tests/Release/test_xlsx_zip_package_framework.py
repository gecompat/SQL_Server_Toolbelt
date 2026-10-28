"""Prüft die gebundene XLSX-/ZIP-Framework-Evidenz und Guards ohne CLR-Lauf."""
from __future__ import annotations

import copy
import hashlib
import json
import os
from pathlib import Path
import shutil
import subprocess
import tempfile
import unittest
import zipfile
import sys

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / 'Scripts/Release'))
import xlsx_sst_budget
import help_contract_source
REPORT = "Releases/1.0.0/XLSX-ZIP-PACKAGE-FRAMEWORK-QUALIFICATION.json"
PACKAGE = "Releases/1.0.0/InstallPackages/SQL-Server-Toolbelt-1.0.0-CLR-Install.zip"
PACKAGE_SHA256 = "896989d546ae7396b4b698e3228ec4c55fd49857f4d2408e125904faf6471287"
SIDECAR_SHA256 = "350826f0cbac147d3c78cc457445f562ec0e7f27418ae48d7f365c838c5dd27c"
PACKAGE_PREFIX = "SQL-Server-Toolbelt-1.0.0-CLR-Install/"
SOURCE_MAP_SHA256 = "9f129bd638674bbc316e1f0c83d23dd8b7e6972007d0df6d7b59f89933f90f55"
EXPECTED_LIMITS = [
    "XLSX umfasst nur die 19 Phasen des bestehenden Candidate-Frameworkrunners gegen die DLLs aus dem Installationspaket; die Paketvorbereitung erzeugte private Sidecars und änderte keine ursprünglichen Releaseartefakte.",
    "Die XLSX-Sandbox prüft eingeschränkte Framework-Ausführung und Deny-Canaries, keine Betriebssystem-Systemaufrufe. Die eigene IL-Prüfung ist auf den Provider begrenzt und behauptet keine transitive No-I/O-Eigenschaft des Frameworks.",
    "ZIP umfasst sieben vorhandene EntrySecurity-Fälle und den unveränderten WriterFramework-Body; ein separater Main prüfte Paketpfad, Assemblyversion und DLL-SHA256 vor und nach dem Lauf.",
    "Es gab keine SQL-/Lab-/Deployment-Ausführung, keine Assemblyinstallation oder Truständerung und keinen Produktbuild. Dies ist keine vollständige Modul-, Plattform-, Rechte-, Ressourcen- oder Sicherheitsqualifikation.",
    "Modulstatus, Paketpayload und Veröffentlichungsfreigabe blieben unverändert; Veröffentlichung ist nicht autorisiert.",
]


def _xlsx_zip_digest(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()


def _xlsx_zip_source_map_digest(pins: list[dict[str, str]]) -> str:
    value = "".join(f"{item['path']}\0{item['sha256']}\n" for item in pins)
    return _xlsx_zip_digest(value.encode("utf-8"))


def validate_xlsx_zip_package_report(report: dict, root: Path = ROOT) -> None:
    required = {
        "schema_version", "date", "status", "scope", "publication_authorized", "native_sql",
        "product_build_executed", "product_sql_changed", "module_status_changed", "package_payload_changed",
        "deployment_executed", "assembly_installed_or_trusted", "package", "modules", "input_pins", "limits",
    }
    if not isinstance(report, dict) or set(report) != required:
        raise ValueError("XLSX_ZIP_REPORT_FIELDS")
    if (report["schema_version"], report["date"], report["status"], report["scope"], report["native_sql"]) != (
            "1.0", "2026-10-27", "PASS", "EXISTING_XLSX_CANDIDATE_AND_ZIP_WRITER_PACKAGE_FRAMEWORK_CONTRACTS_ONLY",
            "NOT_EXECUTED"):
        raise ValueError("XLSX_ZIP_REPORT_STATUS")
    for field in ("publication_authorized", "product_build_executed", "product_sql_changed", "module_status_changed",
                  "package_payload_changed", "deployment_executed", "assembly_installed_or_trusted"):
        if report[field] is not False:
            raise ValueError("XLSX_ZIP_REPORT_SCOPE_FLAGS")
    if report["package"] != {
            "path": PACKAGE, "sha256": PACKAGE_SHA256, "sidecar_sha256": SIDECAR_SHA256}:
        raise ValueError("XLSX_ZIP_REPORT_PACKAGE")

    modules = report["modules"]
    if set(modules) != {"xlsx", "zip_writer"}:
        raise ValueError("XLSX_ZIP_REPORT_MODULES")
    if modules["xlsx"] != {
            "module_id": "toolbelt.file.xlsx-memory", "module_version": "1.2.0",
            "assembly": "Toolbelt.File.XlsxMemory.dll", "assembly_size": 37376,
            "assembly_sha256": "15bff87fad9695dca6f2127f49a8f509a34825b2d855545dc4b875a1a5af71ec",
            "matches_delivered_package_entry": True,
            "scope": "EXISTING_XLSX_CANDIDATE_FRAMEWORK_CONTRACTS_ONLY",
            "framework": {
                "status": "PASS", "phases": 19, "metadata_clr_slots": 4, "metadata_sql_source_count": 9,
                "sql_sources_executed": False, "type_assertions_per_culture": 6437,
                "display_cases_per_culture": 5619, "cultures": ["en-US", "de-DE", "tr-TR"],
                "transport_assertions": 55, "raw_fixed_oracle": "PASS RAW EXISTING_ORACLE",
                "sandbox_phases": 3,
                "sandbox_scope": "restricted Framework execution and deny canaries; not OS syscall observation",
                "own_il_scope": "bounded own-provider IL/reference inspection",
                "transitive_framework_no_io_claim": False,
            },
            "sql_executed": False, "full_module_qualified": False,
    }:
        raise ValueError("XLSX_ZIP_REPORT_XLSX_PROFILE")
    expected_markers = [
        "ZIP_ENTRY_SECURITY_PASS cases=7",
        "ZIP Writer Framework: independent ZipArchive roundtrips, empty Deflate, deterministic Stored, boundaries, names, malformed transport and parallel calls PASS.",
        "ZIP_WRITER_PACKAGE_FRAMEWORK_PASS",
    ]
    if modules["zip_writer"] != {
            "module_id": "toolbelt.archive.zip-memory", "module_version": "1.4.0",
            "assembly": "Toolbelt.Archive.ZipMemory.dll", "assembly_size": 40960,
            "assembly_sha256": "bae312b3a125ffa157da72a5ae1b5bf29b6abbe604509638df2cc5e7136b575d",
            "matches_delivered_package_entry": True,
            "scope": "EXISTING_ZIP_WRITER_AND_ENTRY_SECURITY_FIXED_CONTRACTS_ONLY",
            "framework": {
                "status": "PASS", "phases": 2, "entry_security_cases": 7,
                "writer_body_reused_unmodified": True, "added_writer_oracles": 0,
                "main_assembly_identity_binding_before_after": True, "expected_assembly_version": "1.4.0.0",
                "markers": expected_markers,
            },
            "sql_executed": False, "full_module_qualified": False,
    }:
        raise ValueError("XLSX_ZIP_REPORT_ZIP_PROFILE")
    if report["limits"] != EXPECTED_LIMITS:
        raise ValueError("XLSX_ZIP_REPORT_LIMITS")

    pin_record = report["input_pins"]
    if set(pin_record) != {"repo_relative_count", "source_map_sha256", "pins"}:
        raise ValueError("XLSX_ZIP_REPORT_PIN_FIELDS")
    pins = pin_record["pins"]
    if not isinstance(pins, list) or pin_record["repo_relative_count"] != 48 or len(pins) != 48:
        raise ValueError("XLSX_ZIP_REPORT_PIN_COUNT")
    if any(set(item) != {"path", "sha256"} for item in pins):
        raise ValueError("XLSX_ZIP_REPORT_PIN_ITEM_FIELDS")
    paths = [item["path"] for item in pins]
    if paths != sorted(paths) or len(set(paths)) != len(paths):
        raise ValueError("XLSX_ZIP_REPORT_PIN_ORDER_OR_DUPLICATE")
    if pin_record["source_map_sha256"] != SOURCE_MAP_SHA256 or _xlsx_zip_source_map_digest(pins) != SOURCE_MAP_SHA256:
        raise ValueError("XLSX_ZIP_REPORT_PIN_MAP")
    for item in pins:
        path = item["path"]
        if not isinstance(path, str) or path.startswith(("/", "\\")) or ".." in Path(path).parts:
            raise ValueError("XLSX_ZIP_REPORT_PIN_PATH")
        if path in xlsx_sst_budget.HISTORICAL:
            source = xlsx_sst_budget.validate_historical_source(root, path, item['sha256'])
        elif path in help_contract_source.source_paths(root):
            source = help_contract_source.validate_historical_source(root, path, item['sha256'])
        else:
            source = (root / path).read_bytes()
        if _xlsx_zip_digest(source) != item["sha256"]:
            raise ValueError("XLSX_ZIP_CURRENT_SOURCE_PIN")

    report_text = json.dumps(report, ensure_ascii=False)
    if "sha512" in report_text.casefold() or ".runtime" in report_text.casefold():
        raise ValueError("XLSX_ZIP_REPORT_PRIVATE_DATA")
    package_path = root / PACKAGE
    package_bytes = package_path.read_bytes()
    if _xlsx_zip_digest(package_bytes) != PACKAGE_SHA256:
        raise ValueError("XLSX_ZIP_CURRENT_PACKAGE_PIN")
    if (root / (PACKAGE + ".sha256")).read_text(encoding="ascii") != f"{PACKAGE_SHA256}  {Path(PACKAGE).name}\n":
        raise ValueError("XLSX_ZIP_CURRENT_SIDECAR_PIN")
    with zipfile.ZipFile(package_path) as archive:
        manifest_name = PACKAGE_PREFIX + "CLR-PACKAGE.json"
        if sum(item.filename == manifest_name for item in archive.infolist()) != 1:
            raise ValueError("XLSX_ZIP_MANIFEST_ENTRY_COUNT")
        manifest = json.loads(archive.read(manifest_name))
        if manifest.get("publication_authorized") is not False:
            raise ValueError("XLSX_ZIP_PACKAGE_PUBLICATION")
        for key, binary in modules.items():
            name = PACKAGE_PREFIX + "Binaries/" + binary["assembly"]
            if sum(item.filename == name for item in archive.infolist()) != 1:
                raise ValueError("XLSX_ZIP_BINARY_ENTRY_COUNT")
            data = archive.read(name)
            records = [item for item in manifest["artifacts"] if item.get("module_id") == binary["module_id"]]
            file_record = manifest["files"].get("Binaries/" + binary["assembly"])
            if (len(records) != 1 or records[0].get("origin") != "reproducible_double_build"
                    or records[0].get("file") != binary["assembly"] or file_record is None
                    or _xlsx_zip_digest(data) != binary["assembly_sha256"] or len(data) != binary["assembly_size"]
                    or records[0].get("sha256") != binary["assembly_sha256"]
                    or file_record.get("size") != len(data) or file_record.get("sha256") != binary["assembly_sha256"]):
                raise ValueError("XLSX_ZIP_BINARY_BINDING")


class XlsxZipPackageFrameworkMixin:
    def _xlsx_zip_load_report(self):
        return json.loads((ROOT / REPORT).read_bytes())

    def test_xlsx_zip_package_report_is_exactly_bound(self):
        validate_xlsx_zip_package_report(self._xlsx_zip_load_report())

    def test_xlsx_zip_package_report_drift_is_rejected(self):
        report = self._xlsx_zip_load_report()
        mutations = []
        for field, value in (
                ("scope", "FULL_RELEASE_QUALIFICATION"),
                ("publication_authorized", 0),
                ("package_payload_changed", True),
                ("deployment_executed", True)):
            changed = copy.deepcopy(report)
            changed[field] = value
            mutations.append(changed)
        changed = copy.deepcopy(report)
        changed["limits"] = []
        mutations.append(changed)
        changed = copy.deepcopy(report)
        changed["modules"]["zip_writer"]["scope"] = "FULL_MODULE_QUALIFICATION"
        mutations.append(changed)
        changed = copy.deepcopy(report)
        changed["modules"]["xlsx"]["framework"]["transitive_framework_no_io_claim"] = True
        mutations.append(changed)
        changed = copy.deepcopy(report)
        changed["input_pins"]["pins"].pop()
        mutations.append(changed)
        changed = copy.deepcopy(report)
        changed["input_pins"]["pins"][0]["sha256"] = "0" * 64
        mutations.append(changed)
        for altered in mutations:
            with self.subTest(mutation=altered.get("scope", altered.get("input_pins", {}))):
                with self.assertRaises(ValueError):
                    validate_xlsx_zip_package_report(altered)

    @unittest.skipUnless(shutil.which("pwsh"), "PowerShell 7 ist für die lokalen Guard-Proben nicht verfügbar.")
    def test_xlsx_zip_package_native_preparers_reject_invalid_scopes(self):
        runtime = ROOT / ".runtime"
        if runtime.is_symlink() or not runtime.is_dir():
            raise RuntimeError("Testlaufzeit muss ein physisches .runtime-Verzeichnis sein.")
        runtime_resolved = runtime.resolve(strict=True)
        cases = ("wrong-package", "wrong-sidecar", "occupied-preparer-output", "runtime-inside-repository", "occupied-writer-output")
        for case in cases:
            with self.subTest(case=case):
                with tempfile.TemporaryDirectory(prefix="xlsx-zip-guard-", dir=runtime) as temporary:
                    temp_root = Path(temporary).resolve(strict=True)
                    self.assertTrue(temp_root.is_relative_to(runtime_resolved))
                    fake_root = temp_root / "fake-repository"
                    release = fake_root / "Tests" / "Release"
                    release.mkdir(parents=True)
                    (fake_root / "Releases" / "1.0.0" / "InstallPackages").mkdir(parents=True)
                    preparer = ROOT / "Tests/Release/Prepare-XlsxPackageFrameworkArtifacts.ps1"
                    writer = ROOT / "Tests/Release/Invoke-ZipWriterPackageFramework.ps1"
                    shutil.copyfile(preparer, release / preparer.name)
                    shutil.copyfile(writer, release / writer.name)
                    package_source = ROOT / PACKAGE
                    package_bytes = package_source.read_bytes()
                    package_target = fake_root / PACKAGE
                    package_target.parent.mkdir(parents=True, exist_ok=True)
                    if case == "wrong-package":
                        package_bytes = bytes([package_bytes[0] ^ 1]) + package_bytes[1:]
                    package_target.write_bytes(package_bytes)
                    sidecar = (ROOT / (PACKAGE + ".sha256")).read_bytes()
                    if case == "wrong-sidecar":
                        sidecar = b"0" * 64 + sidecar[64:]
                    Path(str(package_target) + ".sha256").write_bytes(sidecar)

                    external_runtime = temp_root / "external" / ".runtime"
                    external_runtime.mkdir(parents=True)
                    output = external_runtime / "output"
                    expected_guard = {
                        "wrong-package": "PACKAGE_SHA256_MISMATCH",
                        "wrong-sidecar": "PACKAGE_SIDECAR_MISMATCH",
                        "occupied-preparer-output": "PRIVATE_FRESH_OUTPUT_REQUIRED",
                        "runtime-inside-repository": "PRIVATE_FRESH_OUTPUT_REQUIRED",
                    }.get(case, "PRIVATE_FRESH_OUTPUT_REQUIRED")
                    if case in ("occupied-preparer-output", "occupied-writer-output"):
                        output.mkdir()
                        sentinel = output / "preserve.txt"
                        sentinel.write_bytes(b"keep")
                    if case == "runtime-inside-repository":
                        external_runtime = fake_root / ".runtime"
                        external_runtime.mkdir()
                        output = external_runtime / "output"
                        expected_guard = "PRIVATE_FRESH_OUTPUT_REQUIRED"
                    preparer_path = release / preparer.name
                    writer_path = release / writer.name
                    if case == "occupied-writer-output":
                        command = [shutil.which("pwsh"), "-NoLogo", "-NoProfile", "-File", str(writer_path),
                                   "-RuntimeRoot", str(external_runtime), "-OutputDirectory", str(output),
                                   "-CompilerPath", "unused-csc.exe", "-GitPath", "unused-git.exe"]
                        expected_guard = "PRIVATE_FRESH_OUTPUT_REQUIRED"
                    else:
                        command = [shutil.which("pwsh"), "-NoLogo", "-NoProfile", "-File", str(preparer_path),
                                   "-RuntimeRoot", str(external_runtime), "-OutputDirectory", str(output)]
                    startupinfo = None
                    creationflags = 0
                    if os.name == "nt":
                        startupinfo = subprocess.STARTUPINFO()
                        startupinfo.dwFlags |= subprocess.STARTF_USESHOWWINDOW
                        startupinfo.wShowWindow = 0
                        creationflags = subprocess.CREATE_NO_WINDOW
                    completed = subprocess.run(command, cwd=fake_root, capture_output=True, timeout=30,
                                               check=False, creationflags=creationflags, startupinfo=startupinfo)
                    diagnostic = (completed.stdout + completed.stderr).decode("utf-8", errors="replace")
                    self.assertNotEqual(completed.returncode, 0)
                    self.assertIn(expected_guard, diagnostic)
                    if case in ("wrong-package", "wrong-sidecar", "runtime-inside-repository"):
                        self.assertFalse(output.exists())
                    if case in ("occupied-preparer-output", "occupied-writer-output"):
                        self.assertEqual((output / "preserve.txt").read_bytes(), b"keep")
                    self.assertTrue(temp_root.is_relative_to(runtime_resolved))
                self.assertFalse(temp_root.exists())


if __name__ == "__main__":
    unittest.main()
