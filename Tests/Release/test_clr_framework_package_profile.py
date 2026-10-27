"""Regressionen für den begrenzten CSV-/Phonetic-Paketnachweis."""

from pathlib import Path
import copy
import hashlib
import json
import runpy
import shutil
import sys
import tempfile
import zipfile
from unittest.mock import patch


ROOT = Path(__file__).resolve().parents[2]
REPORT = "Releases/1.0.0/CLR-FRAMEWORK-PACKAGE-QUALIFICATION.json"
PACKAGE = "Releases/1.0.0/InstallPackages/SQL-Server-Toolbelt-1.0.0-CLR-Install.zip"
PACKAGE_SHA256 = "896989d546ae7396b4b698e3228ec4c55fd49857f4d2408e125904faf6471287"
SIDECAR_SHA256 = "350826f0cbac147d3c78cc457445f562ec0e7f27418ae48d7f365c838c5dd27c"
QUALIFICATION_SHA256 = "48e89b12dccf6fd936547729c6344c03b6e059007cbe3aa20d9d7a979890082d"
PACKAGE_PREFIX = "SQL-Server-Toolbelt-1.0.0-CLR-Install/"
EXPECTED_PINS = {
    PACKAGE: PACKAGE_SHA256,
    PACKAGE + ".sha256": SIDECAR_SHA256,
    "Releases/1.0.0/qualification.json": QUALIFICATION_SHA256,
    "Tests/Release/bind_clr_framework_candidate.py": "aa630a6a1c8faa4ebe56844a9d2a0952efde11b5d246b40b00c792258dcffcdb",
    "Modules/toolbelt.string.phonetic/Tests/Framework/run-framework-phonetic.ps1": "3e11140b2f6fe2df39f88b8baaab058ad4becd207cbc5c3a0dfdd71f46204801",
    "Modules/toolbelt.string.phonetic/Tests/Framework/PhoneticHarness.cs": "b36acbd84a72a3acdefecc570049e16eaa585bf067a2da6fb53f403377b9fd85",
    "Modules/toolbelt.string.phonetic/Scripts/Invoke-OwnedProcess.ps1": "ff2cce9c0c33335892effac843d90bf2b131b597c68e9514850cc91c80cac993",
    "Modules/toolbelt.file.csv-memory/Tests/Framework/run-framework-csv.ps1": "6f213ec43895235cb51e3544d9256cd3b1dbd0099df5ac654c24090541dfe1f7",
    "Modules/toolbelt.file.csv-memory/Tests/Framework/CsvHarness.cs": "026b3391eaa3f3a517536fd5a04b77ab406550d2f434bf7bcf19ffbf11fe8165",
    "Modules/toolbelt.string.edit-distance/Scripts/Invoke-OwnedProcess.ps1": "ff2cce9c0c33335892effac843d90bf2b131b597c68e9514850cc91c80cac993",
}
EXPECTED_CULTURES = ["en-US", "de-DE", "tr-TR"]
EXPECTED_LIMITS = [
    "Nur die unveränderten bestehenden Framework-Harnesses wurden mit den gelieferten CSV- und Phonetic-DLL-Bytes ausgeführt.",
    "Phonetic prüft feste In-Process-Bridgefälle, Zeilenbindung und Assemblyidentität; dies ist keine SQL-TVF- oder vollständige Modulqualifikation.",
    "CSV umfasst die bestehenden Parser-/Writer-/Grenzverträge und eine begrenzte direkte IL-Inspektion; keine vollständige transitive No-I/O- oder Sicherheitsqualifikation.",
    "Keine SQL-, Lab-, Deployment-, Plattformmatrix- oder vollständige CLR-Suite wurde ausgeführt; Modulstatus und Paketbytes blieben unverändert.",
]


def validate_candidate_framework_profile_report(report, root=ROOT):
    required = {"schema_version", "date", "status", "scope", "publication_authorized", "native_sql",
                "package", "historical_qualification", "source_pins", "profiles", "limits"}
    if set(report) != required:
        raise ValueError("CLR_FRAMEWORK_REPORT_FIELDS")
    if (report["schema_version"], report["date"], report["status"], report["scope"], report["native_sql"]) != (
            "1.0", "2026-10-27", "PASS", "CSV_AND_PHONETIC_DELIVERED_CLR_DLLS_ON_EXISTING_FRAMEWORK_HARNESSES",
            "NOT_EXECUTED") or report["publication_authorized"] is not False:
        raise ValueError("CLR_FRAMEWORK_REPORT_STATUS")
    if report["package"] != {"path": PACKAGE, "sha256": PACKAGE_SHA256, "sidecar_sha256": SIDECAR_SHA256}:
        raise ValueError("CLR_FRAMEWORK_REPORT_PACKAGE")
    if report["historical_qualification"] != {
            "path": "Releases/1.0.0/qualification.json", "sha256": QUALIFICATION_SHA256,
            "role": "Bindet den früheren Bericht der ausgewählten Frameworkkandidaten; dieser Bericht ergänzt den Abgleich mit den gelieferten Paket-DLLs."}:
        raise ValueError("CLR_FRAMEWORK_REPORT_HISTORY")
    pins = report["source_pins"]
    if not isinstance(pins, list) or len(pins) != 10:
        raise ValueError("CLR_FRAMEWORK_REPORT_PIN_COUNT")
    if any(set(pin) != {"path", "sha256"} for pin in pins):
        raise ValueError("CLR_FRAMEWORK_REPORT_PIN_FIELDS")
    pin_map = {pin["path"]: pin["sha256"] for pin in pins}
    if len(pin_map) != len(pins) or pin_map != EXPECTED_PINS:
        raise ValueError("CLR_FRAMEWORK_REPORT_PIN_SET")
    for path, expected in EXPECTED_PINS.items():
        actual = hashlib.sha256((root / path).read_bytes()).hexdigest()
        if actual != expected:
            raise ValueError("CLR_FRAMEWORK_CURRENT_SOURCE_PIN")

    profiles = report["profiles"]
    if set(profiles) != {"phonetic", "csv", "shared"}:
        raise ValueError("CLR_FRAMEWORK_REPORT_PROFILES")
    phonetic = profiles["phonetic"]
    phonetic_required = {"module_id", "module_version", "assembly", "assembly_size", "assembly_sha256",
                         "matches_delivered_package_entry", "scope", "cultures", "fixed_contract",
                         "sql_executed", "full_module_qualified"}
    if set(phonetic) != phonetic_required or phonetic != {
            "module_id": "toolbelt.string.phonetic", "module_version": "1.0.0",
            "assembly": "Toolbelt.String.Phonetic.dll", "assembly_size": 19456,
            "assembly_sha256": "8309e0b8defeea9e0586fd0e264c784f2fd1662bc8624b08229a4e43af839f88",
            "matches_delivered_package_entry": True,
            "scope": "EXISTING_PHONETIC_BRIDGE_FIXED_CONTRACTS_ONLY",
            "cultures": [{"name": culture, "status": "PASS", "assertions": 223} for culture in EXPECTED_CULTURES],
            "fixed_contract": {"bridge_cases_per_culture": 34, "cologne_cases": 18,
                               "double_metaphone_cases": 16, "wrong_row_binding_controls_per_culture": 2,
                               "assembly_identity_assertions_per_culture": 1},
            "sql_executed": False, "full_module_qualified": False}:
        raise ValueError("CLR_FRAMEWORK_PHONETIC_PROFILE")

    csv = profiles["csv"]
    csv_required = {"module_id", "module_version", "assembly", "assembly_size", "assembly_sha256",
                    "matches_delivered_package_entry", "scope", "cultures", "fixed_contract",
                    "sql_core_dependency_exercised", "sql_executed", "full_module_qualified"}
    if set(csv) != csv_required or csv != {
            "module_id": "toolbelt.file.csv-memory", "module_version": "1.0.0",
            "assembly": "Toolbelt.File.CsvMemory.dll", "assembly_size": 12800,
            "assembly_sha256": "8e925d5627235b154c81cb4d85fa01550aa96e89d90fe045e4a627dda7a40201",
            "matches_delivered_package_entry": True,
            "scope": "EXISTING_CSV_CLR_FRAMEWORK_CONTRACTS_ONLY",
            "cultures": [{"name": EXPECTED_CULTURES[0], "status": "PASS", "assertions": 1728},
                         {"name": EXPECTED_CULTURES[1], "status": "PASS", "assertions": 1704},
                         {"name": EXPECTED_CULTURES[2], "status": "PASS", "assertions": 1704}],
            "fixed_contract": {"quote_parse_combinations_per_corpus_culture": 208,
                               "corpus_cultures": EXPECTED_CULTURES,
                               "direct_il_inspection": "BOUNDED_DIRECT_PRODUCT_IL_ONLY",
                               "transitive_no_io_or_security_claim": False},
            "sql_core_dependency_exercised": False, "sql_executed": False, "full_module_qualified": False}:
        raise ValueError("CLR_FRAMEWORK_CSV_PROFILE")
    shared = profiles["shared"]
    shared_required = {"framework_phases_per_profile", "package_binding", "tool_and_framework_reference_fingerprints_published",
                       "sql_executed", "full_clr_suite_qualified", "module_status_changed", "package_changed",
                       "publication_authorized"}
    if set(shared) != shared_required or shared != {
            "framework_phases_per_profile": 3, "package_binding": True,
            "tool_and_framework_reference_fingerprints_published": False,
            "sql_executed": False, "full_clr_suite_qualified": False, "module_status_changed": False,
            "package_changed": False, "publication_authorized": False}:
        raise ValueError("CLR_FRAMEWORK_SHARED_PROFILE")
    if report["limits"] != EXPECTED_LIMITS:
        raise ValueError("CLR_FRAMEWORK_REPORT_LIMITS")

    package_bytes = (root / PACKAGE).read_bytes()
    if hashlib.sha256(package_bytes).hexdigest() != PACKAGE_SHA256:
        raise ValueError("CLR_FRAMEWORK_PACKAGE_CURRENT_PIN")
    sidecar = (root / (PACKAGE + ".sha256")).read_text(encoding="ascii")
    if sidecar != f"{PACKAGE_SHA256}  {Path(PACKAGE).name}\n":
        raise ValueError("CLR_FRAMEWORK_SIDECAR_CURRENT_PIN")
    with zipfile.ZipFile(root / PACKAGE) as archive:
        manifest_name = PACKAGE_PREFIX + "CLR-PACKAGE.json"
        if sum(item.filename == manifest_name for item in archive.infolist()) != 1:
            raise ValueError("CLR_FRAMEWORK_MANIFEST_ENTRY_COUNT")
        manifest = json.loads(archive.read(manifest_name))
        if manifest.get("publication_authorized") is not False:
            raise ValueError("CLR_FRAMEWORK_PACKAGE_PUBLICATION")
        for key, filename in (("phonetic", "Toolbelt.String.Phonetic.dll"),
                              ("csv", "Toolbelt.File.CsvMemory.dll")):
            entry = PACKAGE_PREFIX + "Binaries/" + filename
            if sum(item.filename == entry for item in archive.infolist()) != 1:
                raise ValueError("CLR_FRAMEWORK_PACKAGE_ENTRY_COUNT")
            data = archive.read(entry)
            profile = profiles[key]
            artifact = [item for item in manifest["artifacts"] if item["module_id"] == profile["module_id"]]
            file_record = manifest["files"].get("Binaries/" + filename)
            if (len(artifact) != 1 or artifact[0].get("origin") != "reproducible_double_build"
                    or artifact[0].get("file") != filename or file_record is None
                    or hashlib.sha256(data).hexdigest() != profile["assembly_sha256"]
                    or len(data) != profile["assembly_size"] or artifact[0]["sha256"] != profile["assembly_sha256"]
                    or file_record.get("size") != len(data) or file_record.get("sha256") != profile["assembly_sha256"]):
                raise ValueError("CLR_FRAMEWORK_PACKAGE_ENTRY_BINDING")


class ClrFrameworkCandidateProfileMixin:
    def _candidate_framework_report(self):
        return json.loads((ROOT / REPORT).read_bytes())

    def test_candidate_framework_public_evidence_is_exactly_package_bound(self):
        validate_candidate_framework_profile_report(self._candidate_framework_report())

    def test_candidate_framework_report_scope_and_pin_drift_are_rejected(self):
        report = self._candidate_framework_report()
        mutations = []
        wrong_scope = copy.deepcopy(report)
        wrong_scope["profiles"]["csv"]["scope"] = "FULL_MODULE_QUALIFICATION"
        mutations.append(wrong_scope)
        full_top_scope = copy.deepcopy(report)
        full_top_scope["scope"] = "FULL_RELEASE_QUALIFICATION"
        mutations.append(full_top_scope)
        empty_limits = copy.deepcopy(report)
        empty_limits["limits"] = []
        mutations.append(empty_limits)
        false_publication = copy.deepcopy(report)
        false_publication["publication_authorized"] = 0
        mutations.append(false_publication)
        broad_il = copy.deepcopy(report)
        broad_il["profiles"]["csv"]["fixed_contract"]["direct_il_inspection"] = "COMPLETE_TRANSITIVE_NO_IO"
        mutations.append(broad_il)
        unknown_pin = copy.deepcopy(report)
        unknown_pin["source_pins"][0]["path"] = "Tests/Release/Runtime/unknown.sql"
        mutations.append(unknown_pin)
        duplicate_pin = copy.deepcopy(report)
        duplicate_pin["source_pins"][1] = copy.deepcopy(duplicate_pin["source_pins"][0])
        mutations.append(duplicate_pin)
        changed_binding = copy.deepcopy(report)
        changed_binding["profiles"]["phonetic"]["matches_delivered_package_entry"] = False
        mutations.append(changed_binding)
        broad_claims = copy.deepcopy(report)
        broad_claims["profiles"]["csv"]["sql_executed"] = True
        broad_claims["profiles"]["csv"]["full_module_qualified"] = True
        broad_claims["profiles"]["csv"]["sql_core_dependency_exercised"] = True
        broad_claims["profiles"]["shared"]["full_clr_suite_qualified"] = True
        broad_claims["profiles"]["shared"]["module_status_changed"] = True
        broad_claims["profiles"]["shared"]["package_changed"] = True
        mutations.append(broad_claims)
        for candidate in mutations:
            with self.subTest(candidate=candidate), self.assertRaises(ValueError):
                validate_candidate_framework_profile_report(candidate)

    def test_candidate_framework_binder_rejects_invalid_inputs(self):
        runtime_parent = ROOT / '.runtime'
        runtime_parent.mkdir(exist_ok=True)
        with tempfile.TemporaryDirectory(prefix='candidate-framework-', dir=runtime_parent) as temporary:
            temporary_root = Path(temporary).resolve(strict=True)
            self.assertTrue(temporary_root.is_relative_to(runtime_parent.resolve(strict=True)))
            inputs = (PACKAGE, PACKAGE + '.sha256', 'Releases/1.0.0/qualification.json',
                      'Modules/toolbelt.string.phonetic/Tests/Framework/run-framework-phonetic.ps1',
                      'Modules/toolbelt.string.phonetic/Tests/Framework/PhoneticHarness.cs',
                      'Modules/toolbelt.string.phonetic/Scripts/Invoke-OwnedProcess.ps1',
                      'Tests/Release/bind_clr_framework_candidate.py')
            cases = (
                ('wrong_package', PACKAGE, b'bad package', 'PACKAGE_SHA256_MISMATCH'),
                ('wrong_sidecar', PACKAGE + '.sha256', b'bad sidecar\n', 'PACKAGE_SIDECAR_MISMATCH'),
                ('wrong_qualification', 'Releases/1.0.0/qualification.json', b'{}\n',
                 'HISTORICAL_QUALIFICATION_SHA256_MISMATCH'),
            )
            for name, changed_path, changed_bytes, expected_error in cases:
                with self.subTest(case=name):
                    case_root = temporary_root / name
                    fake_root = case_root / 'repo'
                    runtime = case_root / '.runtime'
                    output = runtime / 'output'
                    fake_root.mkdir(parents=True)
                    runtime.mkdir()
                    for relative in inputs:
                        target = fake_root / relative
                        target.parent.mkdir(parents=True, exist_ok=True)
                        source = ROOT / relative
                        shutil.copyfile(source, target)
                    (fake_root / changed_path).write_bytes(changed_bytes)
                    argv = ['bind_clr_framework_candidate.py', '--root', str(fake_root),
                            '--runtime-root', str(runtime), '--profile', 'phonetic', '--output', str(output)]
                    with patch.object(sys, 'argv', argv), self.assertRaisesRegex(ValueError, expected_error):
                        runpy.run_path(str(fake_root / 'Tests/Release/bind_clr_framework_candidate.py'),
                                       run_name='__main__')
                    self.assertFalse(output.exists())

            for name, runtime_inside, output_exists, expected_error in (
                    ('occupied_output', False, True, 'PRIVATE_OUTPUT_MUST_BE_FRESH_RUNTIME_CHILD'),
                    ('runtime_inside_repo', True, False, 'PRIVATE_OUTPUT_MUST_BE_FRESH_RUNTIME_CHILD')):
                with self.subTest(case=name):
                    case_root = temporary_root / name
                    fake_root = case_root / 'repo'
                    outside_runtime = case_root / '.runtime'
                    fake_root.mkdir(parents=True)
                    outside_runtime.mkdir()
                    for relative in inputs:
                        target = fake_root / relative
                        target.parent.mkdir(parents=True, exist_ok=True)
                        shutil.copyfile(ROOT / relative, target)
                    runtime = fake_root / '.runtime' if runtime_inside else outside_runtime
                    if runtime_inside:
                        runtime.mkdir()
                    output = runtime / 'output'
                    if output_exists:
                        output.mkdir()
                        (output / 'sentinel').write_bytes(b'preserve')
                    argv = ['bind_clr_framework_candidate.py', '--root', str(fake_root),
                            '--runtime-root', str(runtime), '--profile', 'phonetic', '--output', str(output)]
                    with patch.object(sys, 'argv', argv), self.assertRaisesRegex(ValueError, expected_error):
                        runpy.run_path(str(fake_root / 'Tests/Release/bind_clr_framework_candidate.py'),
                                       run_name='__main__')
                    if output_exists:
                        self.assertEqual((output / 'sentinel').read_bytes(), b'preserve')
                    else:
                        self.assertFalse(output.exists())
