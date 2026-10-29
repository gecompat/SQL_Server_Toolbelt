"""Evidenz- und Paketbindungsregressionen für den Scriptparser."""
import io
import json
from pathlib import Path
import shutil
import sys
import tempfile
import unittest
import zipfile

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / "Scripts/Release"))
import script_parser_package as gate
import ssis_historical_source_bridge as ssis_history

REPORT = "Releases/1.0.0/SCRIPT-PARSER-PACKAGE-QUALIFICATION.json"
FIXTURE = "Tests/Release/ScriptParserPackageContractInputs.json"
EXPECTED_INPUTS = {
    "Releases/1.0.0/InstallPackages/SQL-Server-Toolbelt-1.0.0-CLR-Install.zip": "896989d546ae7396b4b698e3228ec4c55fd49857f4d2408e125904faf6471287",
    "Releases/1.0.0/InstallPackages/SQL-Server-Toolbelt-1.0.0-CLR-Install.zip.sha256": "350826f0cbac147d3c78cc457445f562ec0e7f27418ae48d7f365c838c5dd27c",
    "Releases/1.0.0/clr-qualification.json": "d484d87d8e5322b8ab55dbf8ee8901626df7ff4cb066f48b0bdd2dd90486936d",
    "Modules/toolbelt.string.edit-distance/Scripts/Invoke-OwnedProcess.ps1": "ff2cce9c0c33335892effac843d90bf2b131b597c68e9514850cc91c80cac993",
    "Scripts/Release/script_parser_package.py": "04d8b26af2f2911f7f7b327e24efcdb84b5869f7b1b6f303def34d67c8f2bf52",
    FIXTURE: "9d12f047c8b41badf0221135815fb2ae6e541bece775b2b0b6cec8f934429b21",
    "Tests/Release/Invoke-ScriptParserPackageQualification.ps1": "dbedd6484b19bb008e83482b0990bf269e93eecd602a841bde72bd1bf5f057da",
    "Modules/toolbelt.tsql.script-parser/Tests/Framework/ProviderTests.cs": "a71f44051612ecccfca70855d040dabb63473c6d581b59079e8910840402d221",
    "Modules/toolbelt.tsql.script-parser/Tests/Framework/TestInputs.cs": "b799543722356fc943d1013dde23a78bfd0f96fd8a8e19e159c0661fe640e730",
    "Modules/toolbelt.tsql.script-parser/Tests/Framework/GuardTests.cs": "ac0fa07e9cc714148d273a47c6fa0ddc436aeee8e42c057d0de69db9fcc8c776",
    "Modules/toolbelt.tsql.script-parser/Tests/Framework/Invoke-Contract.ps1": "83acc923eb17f76767e7da6d46028b252590849e1d2498ecd4fc583a3b3ea6df",
    "Modules/toolbelt.tsql.script-parser/Clr/PreparseGuard.cs": "83a84fbda92b416fae56db0c52030547fa9e482d9d671971c2e64d748e3c366e",
    "Modules/toolbelt.tsql.script-parser/Clr/PreparseGuardCore.cs": "33331e397100720c2413ac75d22ac25cd23cda4b7816bfa30338c2f14808829b",
    "Modules/toolbelt.tsql.script-parser/Clr/Properties/AssemblyInfo.cs": "3aa4b3107eaa7c75cecd06bc9e41e78b08bf6110958c909b2002bb320fdface4",
    "Modules/toolbelt.tsql.script-parser/Clr/Toolbelt.Tsql.ScriptParser.csproj": "a1a097e654154c57d108a859fdb28d10a913854dbf0caf5668fe6f85a5ff965e",
    "Modules/toolbelt.tsql.script-parser/module.yaml": "9aa29956f866987964c9972abe05b430ad2b02be84923d031de73c60909a8358",
}
EXPECTED_LIMITS = [
    "Der Provider wurde gegen das ausgewiesene feste Korpus und die ausgewählten Parser-Versionsgrenzen geprüft; dies ist keine vollständige Modul- oder Plattformmatrix.",
    "Der 60-Assert-Source-Guard wurde separat aus Quellcode gebaut und ist kein paketgebundener DLL-Nachweis.",
    "Der Nachweis ist keine vollständige transitive IL-, No-I/O-, SQL-, Lab-, Deployment- oder Gesamt-CLR-Qualifikation.",
    "Modulstatus, Manifest, Paketbytes und Veröffentlichungsfreigabe wurden nicht geändert.",
]


def expected_parser_corpus():
    return [
        "SELECT 1;",
        "SELECT N'𝄞é' AS [x];",
        "WITH c AS (SELECT 1 AS n) SELECT n FROM c WHERE EXISTS (SELECT 1);",
        "SELECT a.n FROM (SELECT 1 AS n) a JOIN (SELECT 2 AS n) b ON a.n=b.n CROSS APPLY (SELECT a.n) c;",
        "SELECT 1 UNION ALL SELECT 2 INTERSECT SELECT 3 EXCEPT SELECT 4;",
        "INSERT INTO dbo.t(n) VALUES(1); UPDATE dbo.t SET n=n+1; DELETE FROM dbo.t WHERE n>2;",
        "MERGE dbo.t AS t USING (SELECT 1 AS n) s ON t.n=s.n WHEN MATCHED THEN UPDATE SET n=s.n WHEN NOT MATCHED THEN INSERT(n) VALUES(s.n);",
        "CREATE TABLE dbo.t(n int NOT NULL CONSTRAINT pk PRIMARY KEY); CREATE INDEX ix ON dbo.t(n); ALTER TABLE dbo.t ADD x int; DROP TABLE dbo.t;",
        "CREATE PROCEDURE dbo.p AS BEGIN SELECT 1; END;",
        "CREATE FUNCTION dbo.f() RETURNS int AS BEGIN RETURN 1; END;",
        "CREATE TRIGGER dbo.tr ON dbo.t AFTER INSERT AS BEGIN SELECT 1; END;",
        "BEGIN TRY BEGIN TRANSACTION; SAVE TRANSACTION s; COMMIT; END TRY BEGIN CATCH ROLLBACK; THROW; END CATCH;",
        "CREATE ROLE demo; GRANT SELECT ON dbo.t TO demo; DENY INSERT ON dbo.t TO demo; REVOKE SELECT ON dbo.t FROM demo;",
        "/* quoted '' [ ] */ SELECT 1;\nGO\n-- unicode é\nSELECT 2;",
        "SELECT " + "1+" * 120 + "1 WHERE " + "1=1 AND " * 20 + "1=1;",
        "SELECT 1;",
    ]


def validate_parser_corpus_fixture(fixture):
    if set(fixture) != {"schema", "corpus"} or fixture["schema"] != "script-parser-corpus/v1" or \
            fixture["corpus"] != expected_parser_corpus():
        raise ValueError("SCRIPT_PARSER_CORPUS_DRIFT")


def validate_parser_report(report):
    required = {"schema_version", "date", "status", "scope", "publication_authorized",
                "native_sql", "package", "module", "qualification", "input_sha256",
                "setup_history", "limits"}
    if set(report) != required:
        raise ValueError("SCRIPT_PARSER_REPORT_FIELDS")
    if (report["schema_version"], report["date"], report["status"], report["native_sql"]) != \
            ("1.0", "2026-10-27", "PASS", "NOT_EXECUTED") or report["publication_authorized"] is not False:
        raise ValueError("SCRIPT_PARSER_REPORT_STATUS")
    if report["scope"] != "SCRIPT_PARSER_PACKAGE_BOUND_FIXED_CORPUS_AND_SEPARATE_SOURCE_GUARD":
        raise ValueError("SCRIPT_PARSER_REPORT_SCOPE")
    if report["package"] != {"path": gate.PACKAGE, "sha256": gate.PACKAGE_SHA256}:
        raise ValueError("SCRIPT_PARSER_REPORT_PACKAGE")
    binding, provider, scriptdom = gate.inspect(
        (ROOT / gate.PACKAGE).read_bytes(), (ROOT / gate.SIDECAR).read_bytes(),
        (ROOT / gate.QUALIFICATION).read_bytes())
    module = report["module"]
    if module != {
        "id": "toolbelt.tsql.script-parser", "version": "2.0.1", "assembly": "Toolbelt.Tsql.ScriptParser.dll",
        "assembly_size": 20992, "assembly_sha256": gate.PROVIDER_SHA256,
        "matches_package_entry": True,
        "dependency": {"assembly": "Microsoft.SqlServer.TransactSql.ScriptDom.dll",
                       "size": 6970680, "sha256": gate.SCRIPTDOM_SHA256,
                       "matches_package_entry": True},
    } or binding["package_sha256"] != report["package"]["sha256"] or \
            gate.sha(provider) != module["assembly_sha256"] or gate.sha(scriptdom) != module["dependency"]["sha256"]:
        raise ValueError("SCRIPT_PARSER_REPORT_MODULE")
    qualification = report["qualification"]
    if set(qualification) != {"provider_profile", "provider_children", "provider_cases", "provider_output",
                              "legacy_parser_versions", "fixed_corpus", "version_boundaries",
                              "separate_source_guard", "captured_stages", "hidden_process_chain",
                              "input_tool_and_output_pins", "negative_controls", "sql_or_lab"}:
        raise ValueError("SCRIPT_PARSER_REPORT_QUALIFICATION_FIELDS")
    if (qualification["provider_profile"], qualification["provider_children"],
            qualification["captured_stages"], qualification["hidden_process_chain"],
            qualification["input_tool_and_output_pins"], qualification["sql_or_lab"]) != \
            ("PASS", 63, 67, "PASS", "MATCH_BEFORE_AND_AFTER", "NOT_EXECUTED"):
        raise ValueError("SCRIPT_PARSER_REPORT_QUALIFICATION")
    if qualification["provider_output"] != {"line": "FRAMEWORK_PASS", "line_ending": "LF"}:
        raise ValueError("SCRIPT_PARSER_REPORT_PROVIDER_OUTPUT")
    if qualification["provider_cases"] != {
        "parameter_contract": 1, "legacy_parser_versions": 10, "fixed_corpus": 48, "version_boundaries": 4
    } or qualification["legacy_parser_versions"] != [80, 90, 100, 110, 120, 130, 140, 150, 160, 170]:
        raise ValueError("SCRIPT_PARSER_REPORT_CASES")
    if qualification["fixed_corpus"] != {
        "cases": 16, "parser_versions": [150, 160, 170], "fixture_sha256": EXPECTED_INPUTS[FIXTURE]
    }:
        raise ValueError("SCRIPT_PARSER_REPORT_CORPUS")
    if qualification["version_boundaries"] != [
        "WINDOW_AGGREGATE_150_REJECTED_160_ACCEPTED",
        "JSON_ARRAYAGG_160_REJECTED_170_ACCEPTED",
    ]:
        raise ValueError("SCRIPT_PARSER_REPORT_VERSION_BOUNDARIES")
    if qualification["separate_source_guard"] != {"status": "PASS", "assertions": 60, "package_bound": False}:
        raise ValueError("SCRIPT_PARSER_REPORT_SOURCE_GUARD")
    if qualification["negative_controls"] != [
        "PACKAGE_SHA256_REJECTED", "SIDECAR_REJECTED", "QUALIFICATION_SHA256_REJECTED",
        "ZIP_PATH_TRAVERSAL_REJECTED",
    ]:
        raise ValueError("SCRIPT_PARSER_REPORT_NEGATIVE_CONTROLS")
    if set(report["input_sha256"]) != set(EXPECTED_INPUTS) or report["input_sha256"] != EXPECTED_INPUTS:
        raise ValueError("SCRIPT_PARSER_REPORT_INPUTS")
    for relative, expected in EXPECTED_INPUTS.items():
        if relative in ssis_history.source_paths():
            ssis_history.validate_historical_source(ROOT, relative, expected)
            continue
        if gate.sha((ROOT / relative).read_bytes()) != expected:
            raise ValueError("SCRIPT_PARSER_REPORT_PIN_DRIFT")
    if report["setup_history"] != [
        {"status": "REJECTED_BEFORE_PROVIDER_START", "diagnostic": "SCRIPT_PARSER_RUNSET_SCHEMA",
         "provider_children": 0},
        {"status": "REJECTED_AFTER_PROVIDER_CASES", "diagnostic": "SCRIPT_PARSER_CORPUS_BINDING",
         "provider_children": 11},
        {"status": "PASS_SUPERSEDED_BY_CANONICAL_LF_REBINDING", "provider_children": 63,
         "source_guard_assertions": 60},
        {"status": "PASS", "provider_children": 63, "source_guard_assertions": 60,
         "fixture_line_endings": "GIT_CANONICAL_LF"},
    ]:
        raise ValueError("SCRIPT_PARSER_REPORT_HISTORY")
    if report["limits"] != EXPECTED_LIMITS:
        raise ValueError("SCRIPT_PARSER_REPORT_LIMITS")


class ScriptParserPackageGateMixin:
    def test_ssis_historical_source_bridge_is_exact_and_narrow(self):
        for path, binding in ssis_history.SOURCES.items():
            original = ssis_history.validate_historical_source(ROOT, path, binding['historical'])
            self.assertEqual(gate.sha(original), binding['historical'])
            with self.assertRaisesRegex(ValueError, 'SSIS_HISTORICAL_SOURCE_PIN'):
                ssis_history.validate_historical_source(ROOT, path, '0' * 64)
        with self.assertRaisesRegex(ValueError, 'SSIS_HISTORICAL_SOURCE_PATH'):
            ssis_history.validate_historical_source(ROOT, 'Modules/unrelated/module.yaml', '0' * 64)

        binding = ssis_history.SOURCES['Modules/toolbelt.tsql.ssis-debug/module.yaml']
        with tempfile.TemporaryDirectory() as temporary:
            sandbox = Path(temporary)
            archive = sandbox / ssis_history.ARCHIVE
            archive.parent.mkdir(parents=True)
            shutil.copyfile(ROOT / ssis_history.ARCHIVE, archive)
            current = sandbox / 'Modules/toolbelt.tsql.ssis-debug/module.yaml'
            current.parent.mkdir(parents=True)
            current.write_bytes(b'changed manifest')
            with self.assertRaisesRegex(ValueError, 'SSIS_HISTORICAL_SOURCE_CURRENT_BYTES'):
                ssis_history.validate_historical_source(
                    sandbox, 'Modules/toolbelt.tsql.ssis-debug/module.yaml', binding['historical'])
            current.write_bytes((ROOT / 'Modules/toolbelt.tsql.ssis-debug/module.yaml').read_bytes())
            archive_bytes = bytearray(archive.read_bytes())
            archive_bytes[0] ^= 1
            archive.write_bytes(archive_bytes)
            with self.assertRaisesRegex(ValueError, 'SSIS_HISTORICAL_ARCHIVE_PIN'):
                ssis_history.validate_historical_source(
                    sandbox, 'Modules/toolbelt.tsql.ssis-debug/module.yaml', binding['historical'])

    def test_script_parser_report_pins_package_sources_and_scope(self):
        self.assertEqual(sum(name.startswith("test_script_parser_") for name in dir(type(self))), 3)
        report = json.loads((ROOT / REPORT).read_bytes())
        validate_parser_report(report)

    def test_script_parser_report_and_corpus_drift_are_rejected(self):
        report = json.loads((ROOT / REPORT).read_bytes())
        validate_parser_report(report)
        altered = dict(report, unexpected=True)
        with self.assertRaisesRegex(ValueError, "SCRIPT_PARSER_REPORT_FIELDS"):
            validate_parser_report(altered)
        altered = json.loads(json.dumps(report))
        altered["qualification"]["provider_children"] = 64
        with self.assertRaisesRegex(ValueError, "SCRIPT_PARSER_REPORT_QUALIFICATION"):
            validate_parser_report(altered)
        altered = json.loads(json.dumps(report))
        altered["scope"] = "FULL_MODULE_QUALIFICATION"
        with self.assertRaisesRegex(ValueError, "SCRIPT_PARSER_REPORT_SCOPE"):
            validate_parser_report(altered)
        altered = dict(report, publication_authorized=0)
        with self.assertRaisesRegex(ValueError, "SCRIPT_PARSER_REPORT_STATUS"):
            validate_parser_report(altered)
        altered = dict(report, limits=[])
        with self.assertRaisesRegex(ValueError, "SCRIPT_PARSER_REPORT_LIMITS"):
            validate_parser_report(altered)
        altered = json.loads(json.dumps(report))
        altered["qualification"]["separate_source_guard"]["package_bound"] = True
        with self.assertRaisesRegex(ValueError, "SCRIPT_PARSER_REPORT_SOURCE_GUARD"):
            validate_parser_report(altered)
        altered = dict(report, setup_history=report["setup_history"][:-1])
        with self.assertRaisesRegex(ValueError, "SCRIPT_PARSER_REPORT_HISTORY"):
            validate_parser_report(altered)
        fixture = json.loads((ROOT / FIXTURE).read_bytes())
        validate_parser_corpus_fixture(fixture)
        fixture["corpus"][2] += " "
        with self.assertRaisesRegex(ValueError, "SCRIPT_PARSER_CORPUS_DRIFT"):
            validate_parser_corpus_fixture(fixture)

    def test_script_parser_package_binding_negative_controls(self):
        archive = (ROOT / gate.PACKAGE).read_bytes()
        sidecar = (ROOT / gate.SIDECAR).read_bytes()
        qualification = (ROOT / gate.QUALIFICATION).read_bytes()
        negatives = (
            (b"changed", sidecar, qualification, "SCRIPT_PARSER_PACKAGE_SHA256"),
            (archive, b"changed", qualification, "SCRIPT_PARSER_SIDECAR"),
            (archive, sidecar, b"changed", "SCRIPT_PARSER_QUALIFICATION_SHA256"),
        )
        for package_bytes, sidecar_bytes, qualification_bytes, expected in negatives:
            with self.subTest(expected=expected), self.assertRaisesRegex(gate.PackageError, expected):
                gate.inspect(package_bytes, sidecar_bytes, qualification_bytes)
        malicious = io.BytesIO()
        with zipfile.ZipFile(malicious, "w") as archive_file:
            archive_file.writestr("../outside.dll", b"x")
        with self.assertRaisesRegex(gate.PackageError, "SCRIPT_PARSER_ARCHIVE_PATH"):
            gate.read_archive(malicious.getvalue())
