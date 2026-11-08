"""Closed Help-only transition; historical evidence never qualifies the new Help.

Archived sources are returned only after proving that live SQL differs solely
in its canonical generated Help branch. SSIS permits exactly its generated Help
constant and the API description projection. Every business byte remains bound.
"""
from pathlib import Path
import hashlib
import importlib.util
import io
import json
import re
import stat
import sys
import zipfile

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / "Scripts/Documentation"))
import generate_parameter_help as helpgen

ARCHIVE = "Scripts/Release/HistoricalSources/parameter-help-20261030/Predecessors.zip"
ARCHIVE_SHA256 = "5b082146c15a8990908151936de371620739eb29458218311e5878d4a0870a25"
VERIFIERS = "Scripts/Release/HistoricalSources/parameter-help-20261030/Verifiers.zip"
VERIFIERS_SHA256 = "071cf643f50de39341defd6f34e086d812808a92776bca83650e857b7f1b0f1e"
VERIFIER_PINS = "Scripts/Release/HistoricalSources/parameter-help-20261030/VerifierPins.json"
VERIFIER_PINS_SHA256 = "d0321bc15ba5f7a303f47bc81121bd4ed0c876985a68aaa23c845238b185241a"

# Additive, reviewed archive-reader catalog: updated historical-source readers
# restore their exact immutable verifier predecessors. No oracle/function or
# historical pin file changed; this is not current native qualification.
ADDITIONAL_REVIEWED_READ_ADAPTERS = {
    "Scripts/Release/help_contract_source.py":
        "6962c1f5e08ca01c55837433f001116ff7ba0e033f0e5d0019c3992ae3ef9039",
    "Tests/Release/test_zip_caller_profile.py":
        "a4789e0c8fa0d02e69323e1c3c2e16f164cedb066f590038c5d4f858b73fa83b",
    "Scripts/Release/xlsx_sst_budget.py":
        "5ce0b28d1402bc7d3dcfbeb7e05f6e9252cd7982e87200dc700b2b00abe40cbc",
    "Scripts/Release/ssis_historical_source_bridge.py":
        "d9583588f01c41fee0da15310305a5caacb20b38f538817b4a169be8de24832f",
    "Scripts/Release/json_schema_caller_transaction.py":
        "0244e4170aa772fe0f4ea731d0d4a7d3a389db523ac35b615a5985f3069b20b7",
    "Scripts/Release/json_schema_deploy_applock.py":
        "941c042775b5af5c81c7005a51639eba8b3eccc123dacc7e678708b5310c66c3",
    "Scripts/Release/json_schema_deploy_collision.py":
        "f091df943a2dbdb1a94881e471841e4677988e6611a6d15d74735d1ff8ca9528",
    "Scripts/Release/json_schema_uninstall_applock.py":
        "9e6c23511978ad684b913bc25930b01212039a6202d1345f7b54c95affda7ad9",
    "Scripts/Release/json_schema_uninstall_confirmation.py":
        "468ee9d1993191a4d19ca9a569d6979939359a1e4cfa9c8ddeae9b51f413825a",
    "Tests/Release/test_prepare_release.py":
        "0e88af05b653d853ae7fba8ffeb654c6fdec9a788a58f19ecb1a6d720e8fdaed",
    "Tests/Release/test_xlsx_boundary_evidence.py":
        "8fecb8df67f1eae7636b9a7c4d95f6088adc51760432693f273ce87281bcdd32",
    "Tests/Release/test_xlsx_cell_caller_qualification.py":
        "72237e9e04917214949c7417ed3a18d8d112402134750d0ae95863eab850c114",
    "Tests/Release/test_xlsx_raw_caller_evidence.py":
        "fc59528a3d1978c34d462a33c60a0967e22bed02e729aae840ba7a13575bcb2a",
    "Tests/Release/test_zip_entry_count_composer.py":
        "7c1a786af1ecead814a7f23591a547716df6903199c9f0699bd93b0ca59aa8bb",
}


def require(ok, message):
    if not ok:
        raise ValueError("Parameter Help transition: " + message)


def snapshot(root):
    root = Path(root)
    require((root / ARCHIVE).is_file(), "archive missing; Current Help source differs from fixed digest")
    data = (root / ARCHIVE).read_bytes()
    require(hashlib.sha256(data).hexdigest() == ARCHIVE_SHA256, "archive hash differs")
    with zipfile.ZipFile(io.BytesIO(data)) as archive:
        infos = archive.infolist()
        require(len(infos) == 69 and len({i.filename for i in infos}) == 69
                and all(not i.is_dir() and not i.flag_bits & 1
                        and stat.S_IFMT(i.external_attr >> 16) == stat.S_IFREG
                        and i.file_size <= 1024 * 1024 for i in infos)
                and sum(i.file_size for i in infos) < 8 * 1024 * 1024,
                "archive shape differs")
        payload = {i.filename: archive.read(i) for i in infos}
    require(payload.pop("LICENSE.md") == (root / "LICENSE.md").read_bytes(), "license differs")
    return payload


def normalize(data):
    return data.decode("utf-8-sig").replace("\r\n", "\n")


def ssis_files(root):
    script = Path(root) / "Modules/toolbelt.tsql.ssis-debug/Scripts/New-ContractSources.py"
    spec = importlib.util.spec_from_file_location("_ssis_parameter_help", script)
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module.generate(write=False)


PATHS = frozenset(snapshot(ROOT))


def verifier_pins():
    data = (ROOT / VERIFIER_PINS).read_bytes()
    require(hashlib.sha256(data).hexdigest() == VERIFIER_PINS_SHA256, "verifier pin set differs")
    return json.loads(data)


VERIFIER_PATHS = frozenset(verifier_pins())


def restore_verifier_source(root, path, current=None):
    """Undo only exact reviewed read-adapter bytes before older method checks."""
    pins = verifier_pins()
    require(path in pins, "unsupported verifier")
    if current is None: current = (Path(root) / path).read_bytes()
    digest = hashlib.sha256(current).hexdigest()
    if digest == pins[path]["before"]: return current
    require(digest == pins[path]["after"] or digest == ADDITIONAL_REVIEWED_READ_ADAPTERS.get(path),
            "qualification method differs from exact Help read adapter")
    archive_path = Path(root) / VERIFIERS
    require(archive_path.is_file(), "verifier archive missing")
    data = archive_path.read_bytes()
    require(hashlib.sha256(data).hexdigest() == VERIFIERS_SHA256, "verifier archive differs")
    with zipfile.ZipFile(io.BytesIO(data)) as archive:
        infos = archive.infolist()
        require(len(infos) == len(pins)+1 and {i.filename for i in infos} == set(pins)|{"LICENSE.md"}
                and all(not i.is_dir() and not i.flag_bits & 1 and stat.S_IFMT(i.external_attr >> 16) == stat.S_IFREG
                        and i.file_size <= 1024*1024 for i in infos)
                and sum(i.file_size for i in infos) < 8*1024*1024, "verifier archive shape differs")
        require(archive.read("LICENSE.md") == (Path(root)/"LICENSE.md").read_bytes(), "verifier license differs")
        original = archive.read(path)
    require(hashlib.sha256(original).hexdigest() == pins[path]["before"], "verifier predecessor differs")
    return original


def bound_source(root, path, expected_sha256):
    """Resolve an exact executed pin; never treat newer Help as old evidence."""
    current = (Path(root) / path).read_bytes()
    if hashlib.sha256(current).hexdigest() == expected_sha256.lower():
        return current
    if path in VERIFIER_PATHS:
        original = restore_verifier_source(root, path, current)
        if hashlib.sha256(original).hexdigest() == expected_sha256.lower(): return original
        import help_contract_source
        if path == help_contract_source.RAW_CALLER_TEST:
            return help_contract_source.restore_raw_caller_checker(root, original, expected_sha256)
        if path == help_contract_source.BOUNDARY_TEST:
            return help_contract_source.restore_boundary_checker(root, original, expected_sha256)
        require(False, "executed verifier pin differs")
    require(path in PATHS, "source outside supported Help delta")
    original = predecessor_source(root, path)
    if hashlib.sha256(original).hexdigest() == expected_sha256.lower():
        return original
    import help_contract_source
    require(path in help_contract_source.source_paths(root), "executed source pin differs")
    return help_contract_source.validate_historical_source(root, path, expected_sha256)


def predecessor_source(root, path, expected_sha256=None):
    root = Path(root)
    originals = snapshot(root)
    require(path in originals, "unsupported path")
    original = originals[path]
    if expected_sha256 is not None:
        require(hashlib.sha256(original).hexdigest() == expected_sha256.lower(), "predecessor pin differs")
    before, current = normalize(original), normalize((root / path).read_bytes())
    if path.endswith("Contracts/Api.json"):
        old, new = json.loads(before), json.loads(current)
        notes = helpgen.parameter_notes(root)["toolbelt_tsql.USP_ExplainSsisDataFlow"]["parameter_notes"]
        for p in old["parameters"]:
            p["description"] = notes[p["name"]]
        require(old == new, "API differs outside parameter descriptions")
    elif path.endswith("HelpContract.Generated.cs"):
        pattern = r'(internal const string Sql = @")(.*?)(";\n)'
        old, new = re.search(pattern, before, re.S), re.search(pattern, current, re.S)
        require(old is not None and new is not None, "CLR Help constant missing")
        require(current[:new.start(2)] + old[2] + current[new.end(2):] == before,
                "CLR differs outside Help constant")
        # Pure generator check also binds the new constant to current notes/API.
        require(ssis_files(root)["Clr/HelpContract.Generated.cs"] == current,
                "CLR Help differs from generator")
    else:
        module_name = Path(path).parts[1]
        items = [item for item in helpgen.catalog.objects(root)
                 if item["type"] == "USP" and item["module"] == module_name
                 and helpgen.catalog.signature(item)[0].relative_to(root).as_posix() == path]
        require(bool(items), "no public procedure for source")
        metadata = json.loads((root / helpgen.METADATA).read_text(encoding="utf-8"))
        notes = helpgen.parameter_notes(root)
        expected = before
        for item in items:
            a, b = helpgen.help_span(expected, item)
            if item["module"] == "toolbelt.tsql.ssis-debug":
                # Its facade generator retains the exact pre/post Help body.
                require(ssis_files(root)["Source/USP_ExplainSsisDataFlow.sql"] == current,
                        "SSIS facade differs from generator")
                c, d = helpgen.help_span(current, item)
                body = current[c:d]
            else:
                _, params = helpgen.catalog.signature(item)
                key = item["schema"] + "." + item["name"]
                body = helpgen.render(item, helpgen.help_rows(item, params, metadata[key], notes))
            expected = expected[:a] + body + expected[b:]
        require(expected == current, "source differs outside canonical Help branch")
    return original
