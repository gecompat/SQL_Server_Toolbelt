"""Render the V2 installer using the existing guarded T-SQL renderer."""
from __future__ import annotations

import argparse
import json
from pathlib import Path

import new_ssis_standalone_tsql as legacy
from new_ssis_components_v2_package import MODULE, NAME, ROOT, require, sha
from validate_ssis_components_v2_package import validate


def main(args):
    archive = Path(MODULE + "InstallPackages/" + NAME + ".zip")
    qualification = Path(MODULE + "Tests/Qualification/ComponentsV2.InstallPackage.20261028.json")
    record_bytes = legacy.read_regular_bounded(ROOT / qualification, 1024 * 1024)
    require(sha(record_bytes) == args.qualification_sha256,
            "exact package qualification source")
    validate(ROOT / archive)
    legacy.PACKAGE = archive
    legacy.PACKAGE_SIDECAR = Path(str(archive) + ".sha256")
    legacy.PACKAGE_QUALIFICATION = qualification
    legacy.PACKAGE_QUALIFICATION_SHA256 = args.qualification_sha256
    legacy.ARCHIVE_ROOT = NAME + "/"
    legacy.OUTPUT = Path("Releases/1.0.0/SSIS-COMPONENTS-V2-INSTALL-TSQL.sql")
    legacy.PROVENANCE = Path("Releases/1.0.0/ssis-components-v2-standalone-installer.json")
    legacy.LICENSE_COPY = Path("Releases/1.0.0/SSIS-COMPONENTS-V2-INSTALL-TSQL-LICENSE.md")
    legacy.SCRIPTDOM_NOTICE = Path("Releases/1.0.0/ThirdParty/SSIS-Components-V2/ScriptDom-180.117.0")
    original_render = legacy.render

    def render(payloads, hashes):
        result = original_render(payloads, hashes)
        # Only comments change; all transaction, ownership and binary guards
        # and the bounded chunk/group SQL rendering remain in the old renderer.
        result = result.replace(
            "Toolbelt SSIS-Debug 1.0.0 – eigenständiger T-SQL-Installer.".encode("utf-8"),
            "Toolbelt SSIS-Debug Components V2 – eigenständiger T-SQL-Installer.".encode("utf-8"))
        result = result.replace(b"SSIS-INSTALL-TSQL-LICENSE.md",
                                b"SSIS-COMPONENTS-V2-INSTALL-TSQL-LICENSE.md")
        legacy.validate_installer_guards(result)
        return result

    legacy.render = render
    result = legacy.main()
    path = ROOT / legacy.PROVENANCE
    provenance = json.loads(path.read_text(encoding="utf-8"))
    provenance["component_profile"] = "ssis-debug-components-v2"
    provenance["limits"].append(
        "V2 analysis is explicitly selected by ProjectContext schemaVersion 2 or bindings-template-v2; V1 defaults remain available")
    path.write_text(json.dumps(provenance, indent=2, ensure_ascii=False) + "\n",
                    encoding="utf-8", newline="\n")
    return result


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--qualification-sha256", required=True,
                        type=lambda value: value.upper())
    options = parser.parse_args()
    require(len(options.qualification_sha256) == 64 and
            all(char in "0123456789ABCDEF" for char in options.qualification_sha256),
            "qualification hash format")
    raise SystemExit(main(options))
