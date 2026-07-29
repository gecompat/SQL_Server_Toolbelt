#!/usr/bin/env python3
"""Inkrementelle Dokumentations- und Konsistenzprüfung.

Die Prüfung verwendet ausschließlich die Python-Standardbibliothek. Im
Normalbetrieb bestimmt sie den Scope aus dem Git-Diff und den in
`.ai/repo_map.yaml` registrierten Impact-Paketen. Ein vollständiger Audit wird
nur mit `--all` oder bei Änderungen an Governance und Validator ausgeführt.
"""

from __future__ import annotations

import argparse
import fnmatch
import hashlib
import re
import subprocess
import sys
from pathlib import Path


REPOSITORY_ROOT = Path(__file__).resolve().parents[2]
REPO_MAP = REPOSITORY_ROOT / ".ai" / "repo_map.yaml"
README = REPOSITORY_ROOT / "README.md"
MODULES_README = REPOSITORY_ROOT / "Modules" / "README.md"
BRAINSTORM = "Backlog/personal_Backlog_Bainstorm.md"
GENERATED_BADGE = "MODULE_STATUS_BADGE"
GENERATED_TABLE = "MODULE_STATUS_TABLE"

# Geschützte Inhalte dürfen nur nach ausdrücklicher Freigabe gemeinsam mit
# diesen Baselines geändert werden.
PROTECTED_SHA256 = {
    "LICENSE.md": "b513a23d5ca4484aa6f1ce78179da5a90edc3bf7929eb5cd5c726c8c08ca6ecd",
    "README.md::license-prefix": "f6c7bc408f055e9421514e0e80b3c0585845a36ff6cc2658108de3835066d0d8",
}

ALLOWED_IMPLEMENTATION_STATUS = {
    "proposed",
    "researched",
    "planned",
    "implemented",
    "deprecated",
    "unsupported",
}
ALLOWED_VALIDATION_STATUS = {
    "validated",
    "partially validated",
    "not executed",
    "not applicable",
    "failed",
}
ALLOWED_RELEASE_STATUS = {
    "unreleased",
    "preview",
    "released",
    "deprecated",
    "withdrawn",
}


class ValidationError(AssertionError):
    """Meldet eine belastbare Konsistenzabweichung."""


def read(path: Path) -> str:
    if not path.is_file():
        raise ValidationError(
            f"Pflichtartefakt fehlt: {path.relative_to(REPOSITORY_ROOT)}"
        )
    return path.read_text(encoding="utf-8")


def run_git(*arguments: str) -> str:
    result = subprocess.run(
        ("git", "-C", str(REPOSITORY_ROOT), *arguments),
        check=False,
        capture_output=True,
        text=True,
        encoding="utf-8",
    )
    if result.returncode != 0:
        raise ValidationError(
            f"Git-Aufruf fehlgeschlagen: git {' '.join(arguments)}\n"
            f"{result.stderr.strip()}"
        )
    return result.stdout


def sha256(value: str) -> str:
    return hashlib.sha256(value.encode("utf-8")).hexdigest()


def yaml_unquote(value: str) -> str:
    value = value.strip()
    if len(value) >= 2 and value[0] == value[-1] and value[0] in "\"'":
        return value[1:-1]
    return value


def top_scalar(text: str, key: str) -> str:
    match = re.search(
        rf"^{re.escape(key)}:\s*(.+?)\s*$",
        text,
        re.MULTILINE,
    )
    if match is None:
        raise ValidationError(f"Manifestfeld fehlt: {key}")
    return yaml_unquote(match.group(1))


def top_list(text: str, key: str) -> list[str]:
    lines = text.splitlines()
    marker = f"{key}:"
    for index, line in enumerate(lines):
        if line == marker:
            values: list[str] = []
            for candidate in lines[index + 1 :]:
                if candidate and not candidate.startswith(" "):
                    break
                match = re.match(r"^\s{2}-\s+(.+?)\s*$", candidate)
                if match:
                    values.append(yaml_unquote(match.group(1)))
            return values
    raise ValidationError(f"Manifestliste fehlt: {key}")


def section_values(text: str, section: str) -> dict[str, str | list[str]]:
    """Liest den bewusst einfachen Map/List-Teil eines Modulmanifests."""

    lines = text.splitlines()
    marker = f"{section}:"
    for index, line in enumerate(lines):
        if line != marker:
            continue
        values: dict[str, str | list[str]] = {}
        current_list: str | None = None
        for candidate in lines[index + 1 :]:
            if candidate and not candidate.startswith(" "):
                break
            scalar_match = re.match(r"^\s{2}([A-Za-z0-9_]+):\s*(.*?)\s*$", candidate)
            if scalar_match:
                key, raw_value = scalar_match.groups()
                if raw_value:
                    values[key] = yaml_unquote(raw_value)
                    current_list = None
                else:
                    values[key] = []
                    current_list = key
                continue
            list_match = re.match(r"^\s{4}-\s+(.+?)\s*$", candidate)
            if list_match and current_list:
                target = values[current_list]
                if isinstance(target, list):
                    target.append(yaml_unquote(list_match.group(1)))
        return values
    raise ValidationError(f"Manifestabschnitt fehlt: {section}")


def parse_repo_map() -> tuple[list[str], dict[str, dict[str, list[str]]], list[str]]:
    """Liest Registry und Change-Impact-Pakete aus dem eingeschränkten YAML-Format."""

    text = read(REPO_MAP)
    lines = text.splitlines()

    manifests: list[str] = []
    registry_index = lines.index("module_registry:")
    for candidate in lines[registry_index + 1 :]:
        if candidate and not candidate.startswith(" "):
            break
        match = re.match(r"^\s{4}-\s+(.+?)\s*$", candidate)
        if match:
            manifests.append(yaml_unquote(match.group(1)))
    if not manifests:
        raise ValidationError("Die Modulregistry enthält kein Manifest.")

    impact_index = lines.index("change_impact:")
    packages_index = next(
        index
        for index in range(impact_index + 1, len(lines))
        if lines[index] == "  packages:"
    )

    full_audit_paths: list[str] = []
    in_full_audit = False
    for candidate in lines[impact_index + 1 : packages_index]:
        if candidate == "  full_audit_paths:":
            in_full_audit = True
            continue
        if in_full_audit:
            match = re.match(r"^\s{4}-\s+(.+?)\s*$", candidate)
            if match:
                full_audit_paths.append(yaml_unquote(match.group(1)))

    packages: dict[str, dict[str, list[str]]] = {}
    current_package: str | None = None
    current_field: str | None = None
    for candidate in lines[packages_index + 1 :]:
        if candidate and not candidate.startswith(" "):
            break
        package_match = re.match(r"^\s{4}([A-Za-z0-9_-]+):\s*$", candidate)
        if package_match:
            current_package = package_match.group(1)
            packages[current_package] = {"paths": [], "checks": []}
            current_field = None
            continue
        field_match = re.match(r"^\s{6}(paths|checks):\s*$", candidate)
        if field_match and current_package:
            current_field = field_match.group(1)
            continue
        value_match = re.match(r"^\s{8}-\s+(.+?)\s*$", candidate)
        if value_match and current_package and current_field:
            packages[current_package][current_field].append(
                yaml_unquote(value_match.group(1))
            )

    if not full_audit_paths or not packages:
        raise ValidationError("Change-Impact-Registry ist unvollständig.")
    for name, package in packages.items():
        if not package["paths"] or not package["checks"]:
            raise ValidationError(f"Impact-Paket ist unvollständig: {name}")
    return manifests, packages, full_audit_paths


def changed_paths(base: str, head: str) -> list[str]:
    output = run_git("diff", "--name-only", "--diff-filter=ACMRD", base, head)
    return sorted({line.strip() for line in output.splitlines() if line.strip()})


def selected_checks(
    changed: list[str],
    packages: dict[str, dict[str, list[str]]],
    full_audit_paths: list[str],
    force_all: bool,
) -> tuple[set[str], list[str], bool]:
    full_audit = force_all or any(path in full_audit_paths for path in changed)
    selected: list[str] = []
    checks: set[str] = set()
    for name, package in packages.items():
        if full_audit or any(
            fnmatch.fnmatch(path, pattern)
            for path in changed
            for pattern in package["paths"]
        ):
            selected.append(name)
            checks.update(package["checks"])
    return checks, selected, full_audit


def load_modules(manifest_paths: list[str]) -> list[dict[str, object]]:
    modules: list[dict[str, object]] = []
    for manifest_path in manifest_paths:
        path = REPOSITORY_ROOT / manifest_path
        text = read(path)
        documentation = section_values(text, "documentation")
        contracts = section_values(text, "contracts")
        module_root = path.parent

        module = {
            "manifest_path": manifest_path,
            "root": module_root,
            "id": top_scalar(text, "module_id"),
            "name": top_scalar(text, "module_name"),
            "version": top_scalar(text, "version"),
            "implementation_status": top_scalar(text, "implementation_status"),
            "validation_status": top_scalar(text, "validation_status"),
            "release_status": top_scalar(text, "release_status"),
            "versions": top_list(text, "sql_server_versions"),
            "schemas": top_list(text, "schemas"),
            "documentation": documentation,
            "contracts": contracts,
            "evidence_workflows": re.findall(
                r'^\s{4}workflow:\s*"([^"]+)"\s*$',
                text,
                re.MULTILINE,
            ),
        }
        modules.append(module)
    return modules


def validate_manifests(modules: list[dict[str, object]]) -> None:
    seen_ids: set[str] = set()
    for module in modules:
        module_id = str(module["id"])
        if module_id in seen_ids:
            raise ValidationError(f"Doppelte Modul-ID: {module_id}")
        seen_ids.add(module_id)

        if module["implementation_status"] not in ALLOWED_IMPLEMENTATION_STATUS:
            raise ValidationError(
                f"{module_id}: ungültiger implementation_status "
                f"{module['implementation_status']}"
            )
        if module["validation_status"] not in ALLOWED_VALIDATION_STATUS:
            raise ValidationError(
                f"{module_id}: ungültiger validation_status "
                f"{module['validation_status']}"
            )
        if module["release_status"] not in ALLOWED_RELEASE_STATUS:
            raise ValidationError(
                f"{module_id}: ungültiger release_status "
                f"{module['release_status']}"
            )

        documentation = module["documentation"]
        assert isinstance(documentation, dict)
        required_documentation_keys = {
            "module",
            "public_objects",
            "architecture",
            "test_matrix",
            "evidence",
        }
        missing = required_documentation_keys - documentation.keys()
        if missing:
            raise ValidationError(
                f"{module_id}: Dokumentationskopplung fehlt: {sorted(missing)}"
            )
        contracts = module["contracts"]
        assert isinstance(contracts, dict)
        for contract in ("usp", "deployment", "validation"):
            if not contracts.get(contract):
                raise ValidationError(
                    f"{module_id}: Contract-Version fehlt: {contract}"
                )

        module_root = module["root"]
        assert isinstance(module_root, Path)
        for value in documentation.values():
            paths = value if isinstance(value, list) else [value]
            for relative in paths:
                target = (module_root / str(relative)).resolve()
                try:
                    target.relative_to(REPOSITORY_ROOT)
                except ValueError as error:
                    raise ValidationError(
                        f"{module_id}: Pfad verlässt das Repository: {relative}"
                    ) from error
                if not target.exists():
                    raise ValidationError(
                        f"{module_id}: gekoppeltes Artefakt fehlt: {relative}"
                    )

        evidence_workflows = module["evidence_workflows"]
        assert isinstance(evidence_workflows, list)
        if not evidence_workflows:
            raise ValidationError(f"{module_id}: Validierungsevidenz fehlt.")
        current_evidence = evidence_workflows[-1]
        for key in ("module", "test_matrix", "evidence"):
            values = documentation[key]
            paths = values if isinstance(values, list) else [values]
            for relative in paths:
                target = (module_root / str(relative)).resolve()
                if current_evidence not in read(target):
                    raise ValidationError(
                        f"{module_id}: aktuelle Evidenz fehlt in {relative}"
                    )


def validate_derived_backlog_status(modules: list[dict[str, object]]) -> None:
    backlog = read(REPOSITORY_ROOT / ".ai" / "BACKLOG.md")
    for module in modules:
        module_id = str(module["id"])
        if module_id not in backlog:
            continue
        expected = (
            ("Implementation Status", module["implementation_status"]),
            ("Validation Status", module["validation_status"]),
            ("Release Status", module["release_status"]),
        )
        for label, value in expected:
            pattern = (
                rf"\|\s*{re.escape(label)}\s*\|\s*`{re.escape(str(value))}`"
                rf"\s*[–-]\s*abgeleitet aus `module\.yaml`\s*\|"
            )
            if re.search(pattern, backlog) is None:
                raise ValidationError(
                    f"{module_id}: abgeleiteter Backlog-Status ist veraltet: {label}"
                )


def status_badge(modules: list[dict[str, object]]) -> str:
    implemented = sum(
        module["implementation_status"] == "implemented" for module in modules
    )
    partial = sum(
        module["validation_status"] == "partially validated" for module in modules
    )
    module_label = "Modul" if implemented == 1 else "Module"
    label = (
        f"{implemented}%20{module_label}%20implementiert%20%7C%20"
        f"{partial}%20teilweise%20validiert"
    )
    alt = (
        f"Status: {implemented} {module_label} implementiert – "
        f"{partial} teilweise validiert"
    )
    return (
        f"[![{alt}](https://img.shields.io/badge/Status-{label}-yellow)]"
        f"(./Modules/README.md)"
    )


def status_table(modules: list[dict[str, object]]) -> str:
    rows = [
        "| Modul-ID | Name | Version | Schema | Implementierung | Validierung | Release | SQL Server |",
        "|---|---|---:|---|---|---|---|---|",
    ]
    for module in sorted(modules, key=lambda item: str(item["id"])):
        rows.append(
            "| `{id}` | {name} | `{version}` | `{schema}` | `{implementation}` | "
            "`{validation}` | `{release}` | {versions} |".format(
                id=module["id"],
                name=module["name"],
                version=module["version"],
                schema=", ".join(str(value) for value in module["schemas"]),
                implementation=module["implementation_status"],
                validation=module["validation_status"],
                release=module["release_status"],
                versions=", ".join(str(value) for value in module["versions"]),
            )
        )
    return "\n".join(rows)


def replace_generated_block(text: str, name: str, generated: str) -> str:
    begin = f"<!-- BEGIN GENERATED:{name} -->"
    end = f"<!-- END GENERATED:{name} -->"
    pattern = re.compile(
        rf"{re.escape(begin)}\n.*?\n{re.escape(end)}",
        re.DOTALL,
    )
    replacement = f"{begin}\n{generated}\n{end}"
    if pattern.search(text) is None:
        raise ValidationError(f"Generated-Marker fehlt: {name}")
    return pattern.sub(replacement, text, count=1)


def validate_generated_status(
    modules: list[dict[str, object]], write_changes: bool
) -> None:
    targets = (
        (README, GENERATED_BADGE, status_badge(modules)),
        (MODULES_README, GENERATED_TABLE, status_table(modules)),
    )
    for path, name, generated in targets:
        current = read(path)
        expected = replace_generated_block(current, name, generated)
        if current == expected:
            continue
        if write_changes:
            path.write_text(expected, encoding="utf-8", newline="\n")
        else:
            raise ValidationError(
                f"Generierter Status ist veraltet: {path.relative_to(REPOSITORY_ROOT)}; "
                "mit --write aktualisieren."
            )


def markdown_files_for_scope(
    changed: list[str],
    modules: list[dict[str, object]],
    full_audit: bool,
) -> list[Path]:
    if full_audit:
        return sorted(
            path
            for path in REPOSITORY_ROOT.rglob("*.md")
            if ".git" not in path.parts
        )

    files = {
        REPOSITORY_ROOT / path
        for path in changed
        if path.lower().endswith(".md") and (REPOSITORY_ROOT / path).is_file()
    }
    for module in modules:
        documentation = module["documentation"]
        module_root = module["root"]
        assert isinstance(documentation, dict)
        assert isinstance(module_root, Path)
        for value in documentation.values():
            paths = value if isinstance(value, list) else [value]
            files.update(
                (module_root / str(relative)).resolve()
                for relative in paths
                if str(relative).lower().endswith(".md")
            )
    return sorted(files)


def validate_markdown_links(paths: list[Path]) -> None:
    link_pattern = re.compile(r"!?\[[^\]]*]\(([^)]+)\)")
    failures: list[str] = []
    for path in paths:
        text = read(path)
        for raw_target in link_pattern.findall(text):
            target = raw_target.strip().split(maxsplit=1)[0].strip("<>")
            if (
                not target
                or target.startswith(("#", "http://", "https://", "mailto:"))
            ):
                continue
            relative = target.split("#", 1)[0]
            if not relative:
                continue
            resolved = (path.parent / relative).resolve()
            if not resolved.exists():
                failures.append(
                    f"{path.relative_to(REPOSITORY_ROOT)} -> {relative}"
                )
    if failures:
        raise ValidationError(
            "Ungültige lokale Markdown-Links:\n- " + "\n- ".join(failures)
        )


def validate_brainstorm_history(base: str | None, head: str) -> None:
    path = REPOSITORY_ROOT / BRAINSTORM
    text = read(path)
    lines = text.splitlines()
    for index, line in enumerate(lines):
        if not line.startswith("~~"):
            continue
        following = "\n".join(lines[index + 1 : index + 5])
        if re.search(
            r"Änderungsvermerk\s+\d{4}-\d{2}-\d{2},\s*[^:]+:\s*\S+",
            following,
        ) is None:
            raise ValidationError(
                f"{BRAINSTORM}:{index + 1}: Durchstreichung ohne datierten "
                "Änderungsvermerk mit Autor und Begründung."
            )

    if base is None:
        return
    diff = run_git("diff", "--unified=0", base, head, "--", BRAINSTORM)
    removed = [
        line[1:]
        for line in diff.splitlines()
        if line.startswith("-") and not line.startswith("---") and line[1:].strip()
    ]
    added = [
        line[1:]
        for line in diff.splitlines()
        if line.startswith("+") and not line.startswith("+++") and line[1:].strip()
    ]
    for line in removed:
        if f"~~{line}~~" not in added:
            raise ValidationError(
                f"{BRAINSTORM}: vorhandene Zeile wurde gelöscht oder still geändert: "
                f"{line[:100]}"
            )
    if removed and not any(
        re.search(
            r"Änderungsvermerk\s+\d{4}-\d{2}-\d{2},\s*[^:]+:\s*\S+",
            line,
        )
        for line in added
    ):
        raise ValidationError(
            f"{BRAINSTORM}: Durchstreichung ohne neuen Änderungsvermerk."
        )


def validate_protected_content() -> None:
    license_hash = sha256(read(REPOSITORY_ROOT / "LICENSE.md"))
    if license_hash != PROTECTED_SHA256["LICENSE.md"]:
        raise ValidationError(
            "LICENSE.md weicht von der freigegebenen geschützten Baseline ab."
        )
    readme = read(README)
    marker = "# SQL Server Toolbelt"
    if marker not in readme:
        raise ValidationError("README-Lizenzblock kann nicht abgegrenzt werden.")
    prefix = readme.split(marker, 1)[0]
    if sha256(prefix) != PROTECTED_SHA256["README.md::license-prefix"]:
        raise ValidationError(
            "Der geschützte Lizenzblock am Anfang der README wurde verändert."
        )


def validate_status_truth() -> None:
    stale_patterns = {
        "README.md": r"Runtime nicht ausgeführt",
        "SECURITY.md": r"noch nicht zur Runtime validiert",
        "Documentation/Standards/USP_CONTRACT.md": (
            r"gemeinsame Runtime-Infrastruktur wird erst"
        ),
    }
    for relative, pattern in stale_patterns.items():
        if re.search(pattern, read(REPOSITORY_ROOT / relative), re.IGNORECASE):
            raise ValidationError(f"Veraltete Statusaussage in {relative}: {pattern}")


def validate_runtime_workflow_scope() -> None:
    workflow = read(
        REPOSITORY_ROOT / ".github" / "workflows" / "result-table-runtime.yml"
    )
    prohibited = (
        '"Documentation/Architecture/**"',
        '"Documentation/Standards/**"',
        '"Tests/RESULT_TABLE_CONTRACT_TEST_MATRIX.md"',
    )
    for marker in prohibited:
        if marker in workflow:
            raise ValidationError(
                f"Runtime-Vollmatrix wird durch reine Dokumentation ausgelöst: {marker}"
            )


def validate_base64_runtime_workflow_scope() -> None:
    workflow = read(
        REPOSITORY_ROOT / ".github" / "workflows" / "base64-runtime.yml"
    )
    prohibited = (
        '"Documentation/Architecture/**"',
        '"Documentation/Standards/**"',
        '"Modules/toolbelt.conversion.base64/Documentation/**"',
        '"Modules/toolbelt.conversion.base64/Tests/**/*.md"',
    )
    for marker in prohibited:
        if marker in workflow:
            raise ValidationError(
                "Base64-Runtime-Matrix wird durch reine Dokumentation "
                f"ausgelöst: {marker}"
            )


def validate_generate_series_runtime_workflow_scope() -> None:
    workflow = read(
        REPOSITORY_ROOT
        / ".github"
        / "workflows"
        / "generate-series-runtime.yml"
    )
    prohibited = (
        '"Documentation/Architecture/**"',
        '"Documentation/Standards/**"',
        '"Modules/toolbelt.core.generate-series/Documentation/**"',
        '"Modules/toolbelt.core.generate-series/Tests/**/*.md"',
    )
    for marker in prohibited:
        if marker in workflow:
            raise ValidationError(
                "Generate-Series-Runtime-Matrix wird durch reine "
                f"Dokumentation ausgelöst: {marker}"
            )


def run_result_table_static() -> None:
    script = (
        REPOSITORY_ROOT
        / "Modules"
        / "toolbelt.core.result-table"
        / "Tests"
        / "Static"
        / "validate_contract.py"
    )
    result = subprocess.run(
        (sys.executable, str(script)),
        cwd=REPOSITORY_ROOT,
        check=False,
        capture_output=True,
        text=True,
        encoding="utf-8",
    )
    if result.returncode != 0:
        raise ValidationError(
            "Modulspezifische statische Prüfung fehlgeschlagen:\n"
            f"{result.stdout}{result.stderr}"
        )


def run_base64_static() -> None:
    script = (
        REPOSITORY_ROOT
        / "Modules"
        / "toolbelt.conversion.base64"
        / "Tests"
        / "Static"
        / "validate_contract.py"
    )
    result = subprocess.run(
        (sys.executable, str(script)),
        cwd=REPOSITORY_ROOT,
        check=False,
        capture_output=True,
        text=True,
        encoding="utf-8",
    )
    if result.returncode != 0:
        raise ValidationError(
            "Statische Base64-Prüfung fehlgeschlagen:\n"
            f"{result.stdout}{result.stderr}"
        )


def run_generate_series_static() -> None:
    script = (
        REPOSITORY_ROOT
        / "Modules"
        / "toolbelt.core.generate-series"
        / "Tests"
        / "Static"
        / "validate_contract.py"
    )
    result = subprocess.run(
        (sys.executable, str(script)),
        cwd=REPOSITORY_ROOT,
        check=False,
        capture_output=True,
        text=True,
        encoding="utf-8",
    )
    if result.returncode != 0:
        raise ValidationError(
            "Statische Generate-Series-Prüfung fehlgeschlagen:\n"
            f"{result.stdout}{result.stderr}"
        )


def parse_arguments() -> argparse.Namespace:
    parser = argparse.ArgumentParser()
    parser.add_argument("--base", help="Git-Basisref für die Impact-Ermittlung")
    parser.add_argument("--head", default="HEAD", help="Git-Zielref")
    parser.add_argument(
        "--all",
        action="store_true",
        help="Vollständigen Baseline-/Release-Audit ausführen",
    )
    parser.add_argument(
        "--write",
        action="store_true",
        help="Generierte Statusabschnitte aktualisieren",
    )
    return parser.parse_args()


def main() -> int:
    arguments = parse_arguments()
    if not arguments.all and not arguments.base:
        raise ValidationError("Entweder --base oder --all ist erforderlich.")

    manifests, packages, full_audit_paths = parse_repo_map()
    zero_base = bool(arguments.base) and not arguments.base.strip("0")
    changed = (
        []
        if arguments.all or zero_base
        else changed_paths(arguments.base, arguments.head)
    )
    checks, selected, full_audit = selected_checks(
        changed,
        packages,
        full_audit_paths,
        arguments.all or zero_base,
    )
    modules = load_modules(manifests)

    # Kleine unveränderliche Basisschutzprüfungen laufen immer.
    validate_protected_content()
    validate_status_truth()
    validate_manifests(modules)
    validate_derived_backlog_status(modules)

    if "generated_status" in checks:
        validate_generated_status(modules, arguments.write)
    if "markdown_links" in checks:
        validate_markdown_links(
            markdown_files_for_scope(changed, modules, full_audit)
        )
    if "brainstorm_history" in checks:
        validate_brainstorm_history(arguments.base, arguments.head)
    if "runtime_workflow_scope" in checks:
        validate_runtime_workflow_scope()
    if "result_table_static" in checks:
        run_result_table_static()
    if "base64_runtime_workflow_scope" in checks:
        validate_base64_runtime_workflow_scope()
    if "base64_static" in checks:
        run_base64_static()
    if "generate_series_runtime_workflow_scope" in checks:
        validate_generate_series_runtime_workflow_scope()
    if "generate_series_static" in checks:
        run_generate_series_static()

    print("Dokumentations- und Konsistenzprüfung: erfolgreich")
    print(f"Modulmanifeste: {len(modules)}")
    print(
        "Prüfmodus: "
        + ("vollständiger Audit" if full_audit else "inkrementeller Change-Impact")
    )
    print("Impact-Pakete: " + (", ".join(selected) if selected else "keine"))
    print(f"Geänderte Pfade: {len(changed)}")
    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except ValidationError as error:
        print(f"Dokumentations- und Konsistenzprüfung: FEHLER: {error}", file=sys.stderr)
        raise SystemExit(1)
