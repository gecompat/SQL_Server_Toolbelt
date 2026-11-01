"""Current executable installer contents, source coupling and checksum guards."""
from pathlib import Path
import copy
import hashlib
import json
import re
import sys
import unittest
import zipfile

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / "Scripts/Documentation"))
sys.path.insert(0, str(ROOT / "Scripts/Release"))
import generate_parameter_help as generator
import new_parameter_help_package as package
import validate_ssis_administrative_trust as administrative_trust

QUALIFICATION = "Releases/1.0.0/parameter-help-qualification.json"
NATIVE_INPUTS = {
    "Tests/Release/Invoke-ParameterHelpLab.ps1", "Tests/Release/Runtime/Invoke-ParameterHelpCases.ps1",
    "Tests/Release/Invoke-ApiQualificationLab.ps1", "Tests/Release/Invoke-StablePackageLab.ps1",
    "Tests/CI/run-csv-memory-lab.ps1", "Tests/CI/run-lab-local.ps1", "Tests/CI/LabQualifiedContract.ps1",
    "Tests/Documentation/new_parameter_help_cases.py", "Scripts/Documentation/generate_parameter_help.py",
    "Documentation/Reference/api_examples.json", "Documentation/Reference/usp_help.json",
}


def validate(root=ROOT):
    path = root / package.OUTPUT
    checksum = path.with_suffix(".zip.sha256").read_text(encoding="ascii").split()
    if checksum != [package.sha(path.read_bytes()), path.name]: raise ValueError("Help ZIP checksum differs")
    expected = {"Install-"+p+"-"+m+".sql" for p in ("Windows","Portable") for m in ("local","central")}
    expected |= {"LICENSE.md","START-HERE.md","SSIS-BUILD.json","Trust-Windows.sql","Trust-Portable.sql","PACKAGE.json","SHA256SUMS"}
    expected |= set(package.NOTICE_SOURCES)
    with zipfile.ZipFile(path) as archive:
        infos = archive.infolist()
        if len(infos) != len(expected) or {i.filename for i in infos} != expected or any(i.file_size > 64*1024*1024 or i.flag_bits & 1 for i in infos): raise ValueError("Help ZIP shape differs")
        payload = {i.filename: archive.read(i) for i in infos}
    sums = dict(line.split("  ",1)[::-1] for line in payload["SHA256SUMS"].decode("ascii").splitlines())
    if sums != {p: package.sha(b) for p,b in payload.items() if p != "SHA256SUMS"}: raise ValueError("Help payload checksums differ")
    metadata = json.loads(payload["PACKAGE.json"])
    if metadata["schema_version"] != "toolbelt-parameter-help-package/v1" or metadata["publication_authorized"] is not False: raise ValueError("Help package identity differs")
    if metadata["files"] != {p: package.sha(b) for p,b in payload.items() if p not in ("PACKAGE.json","SHA256SUMS")}: raise ValueError("Help payload manifest differs")
    for field in ("source_sha256", "editorial_sha256", "predecessor_packages"):
        for relative, digest in metadata[field].items():
            data = (root / relative).read_bytes()
            if field == "source_sha256": data=data.replace(b"\r\n",b"\n")
            if package.sha(data) != digest: raise ValueError("Help current input differs: " + relative)
    if payload["LICENSE.md"] != (root/"LICENSE.md").read_bytes() or payload["START-HERE.md"] != package.package_readme(root): raise ValueError("Help guidance differs")
    if any(payload[name]!=data for name,data in package.notices(root).items()): raise ValueError("Help third-party attribution differs")
    build = json.loads(payload["SSIS-BUILD.json"])
    if build["reproducedBuild"] is not True or build["sha512"].lower() != metadata["binary_sha512"]["Toolbelt.Tsql.SsisDebug.dll"]: raise ValueError("Help SSIS build differs")
    for field in ("sourceFiles", "deploymentFiles"):
        for entry in build[field]:
            relative, digest = entry.rsplit(":", 1)
            path = (root / "Modules/toolbelt.tsql.ssis-debug" / relative).resolve(strict=True)
            if not path.is_relative_to(root.resolve(strict=True)): raise ValueError("Help SSIS build input escapes root")
            data = path.read_bytes()
            if (field == "deploymentFiles" and relative == "Deployment/Add-TrustedAssembly.sql"
                    and package.sha(data).upper() != digest):
                # Das unveränderte Help-Paket bindet seinen ursprünglichen
                # administrativen Input. Der aktuelle Guard wird separat nativ
                # geprüft; keine allgemeine Ausnahme für Deploymentquellen.
                data = administrative_trust.snapshot_predecessor_source(root, administrative_trust.SCRIPT, data)
            if package.sha(data).upper() != digest: raise ValueError("Help SSIS build input differs: " + relative)
    return metadata, payload


def validate_qualification(record, payload, root=ROOT):
    if (record["schema_version"] != "toolbelt-parameter-help-qualification/v1" or record["result"] != "PASS"
            or record["publication_authorized"] is not False or record["test_purpose"] != "Functional"
            or record["authenticated_tls"] != "not executed"
            or record["scope"] != "Installed Help and fresh-install executable contents only; no full business requalification"):
        raise ValueError("Help qualification scope differs")
    if record["current_package"] != {"path":package.OUTPUT,"sha256":package.sha((root/package.OUTPUT).read_bytes())}:
        raise ValueError("Help qualification package differs")
    native = record["native_execution"]
    if set(native["input_sha256"]) != NATIVE_INPUTS: raise ValueError("Help native input set differs")
    for relative, digest in native["input_sha256"].items():
        if package.sha((root/relative).read_bytes()) != digest: raise ValueError("Help native input differs: " + relative)
    sys.path.insert(0,str(root/"Tests/Documentation"))
    from new_parameter_help_cases import cases
    fixture=(json.dumps(cases(),ensure_ascii=False,indent=2)+"\n").encode()
    if native["fixture_line_endings"] == "CRLF": fixture=fixture.replace(b"\n",b"\r\n")
    elif native["fixture_line_endings"] != "LF": raise ValueError("Help native fixture EOL contract differs")
    if package.sha(fixture) != native["fixture_sha256"]: raise ValueError("Help native fixture differs")
    delta=record["non_executable_followup"]
    if (delta["kind"] != "guidance_links_and_existing_third_party_attribution" or delta["executable_bytes_changed"] is not False
            or delta["changed_entries"] != sorted({"START-HERE.md","PACKAGE.json","SHA256SUMS"}|set(package.NOTICE_SOURCES))
            or delta["exact_reverse_projection"] != "Scripts/Release/new_parameter_help_package.py::pre_followup_payload"):
        raise ValueError("Help documentation delta differs")
    previous=package.pre_followup_payload(payload,root)
    if native["payload_sha256"] != {p:package.sha(b) for p,b in previous.items()}:
        raise ValueError("Help executed payload differs")
    changed={p for p in payload if p not in previous or payload[p] != previous[p]}
    if changed != set(delta["changed_entries"]): raise ValueError("Help executable delta is not documentation-only")
    expected={(platform,version,level,mode) for platform in ("windows","linux")
              for version,level in (("2019",150),("2022",160),("2025",170)) for mode in ("local","central")}
    cases=record["cases"]
    if len(cases)!=12 or {(c["platform"],c["sql_server"],c["compatibility_level"],c["deployment_mode"]) for c in cases} != expected:
        raise ValueError("Help native context matrix differs")
    for c in cases:
        count,params=(62,517) if c["platform"]=="linux" else ((74,670) if c["deployment_mode"]=="local" else (63,555))
        internal=1 if c["platform"]=="windows" else 0
        patch={"2019":"CU32","2022":"CU26","2025":"CU8"}[c["sql_server"]] if internal else "latest"
        if (c["result"]!="PASS" or c["cleanup_audit"]!="PASS" or c["requested_patch"]!=patch
                or c["procedures"]!=count or c["parameters"]!=params
                or c["internalProcedures"]!=internal or c["internalParameters"]!=38*internal
                or c["calls"]!=2*(count+internal)
                or c["assertions"]!=2*(params+38*internal)*7+c["calls"]*18):
            raise ValueError("Help native counts or cleanup differ")
    if (record["total_help_calls"]!=sum(c["calls"] for c in cases)
            or record["total_counted_assertions"]!=sum(c["assertions"] for c in cases)):
        raise ValueError("Help native totals differ")


class ParameterHelpPackage(unittest.TestCase):
    def test_current_package_is_bound_to_actual_sources_and_inputs(self):
        metadata, _ = validate()
        self.assertEqual(len(metadata["binary_sha512"]), 13)
        self.assertEqual(len(metadata["profiles"]), 4)

    def test_installer_contains_every_complete_current_help_branch(self):
        metadata, payload = validate()
        for profile in metadata["profiles"]:
            sql = payload["Install-"+profile["name"]+".sql"].decode("utf-8-sig")
            marked = re.findall(r"^-- BEGIN MODULE (\S+)$",sql,re.M)
            self.assertEqual(set(marked),set(profile["modules"]))
            self.assertEqual(len(marked),len(set(marked)))
            for item in generator.catalog.objects(ROOT):
                if item["type"] != "USP" or item["module"] not in profile["modules"]: continue
                path,_=generator.catalog.signature(item)
                source=path.read_text(encoding="utf-8-sig")
                a,b=generator.help_span(source,item)
                body=source[a:b]
                self.assertTrue(body in sql or body.replace("'","''") in sql, profile["name"]+"/"+item["name"])
            if profile["platform"] == "Portable": self.assertNotIn("toolbelt.tsql.script-parser",marked)
            if profile["mode"] == "central": self.assertFalse(package.LOCAL_ONLY & set(marked))

    def test_actual_twelve_context_native_record_and_exact_documentation_followup(self):
        _,payload=validate()
        validate_qualification(json.loads((ROOT/QUALIFICATION).read_bytes()),payload)

    def test_wrong_context_skipped_parameter_changed_executable_or_broader_claim_is_rejected(self):
        _,payload=validate()
        original=json.loads((ROOT/QUALIFICATION).read_bytes())
        mutations=(
            lambda r:r["cases"][0].update(compatibility_level=140),
            lambda r:r["cases"][0].update(parameters=r["cases"][0]["parameters"]-1),
            lambda r:r.update(authenticated_tls="PASS"),
            lambda r:r["native_execution"]["payload_sha256"].update({"Install-Windows-local.sql":"0"*64}),
            lambda r:r["non_executable_followup"]["changed_entries"].append("Install-Windows-local.sql"),
            lambda r:r["native_execution"]["input_sha256"].update({"Unknown/input.sql":"0"*64}),
        )
        for i,mutate in enumerate(mutations):
            changed=copy.deepcopy(original);mutate(changed)
            with self.subTest(mutation=i),self.assertRaises(ValueError): validate_qualification(changed,payload)


if __name__ == "__main__": unittest.main()
