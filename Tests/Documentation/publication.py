"""Lokale Veröffentlichungskonsistenz und ausdrücklich gewählte GitHub-Abnahme.

Ein JSON-Datensatz belegt keine ausgeführte Qualifikation oder menschliche
Freigabe. Diese Inhalte bleiben Gegenstand des fachlichen Release-Reviews.
"""

from __future__ import annotations

import datetime as dt
import json
import re
import subprocess
from pathlib import Path
from urllib.parse import quote


REPOSITORY = "gecompat/SQL_Server_Toolbelt"
PUBLIC_ROOT = f"https://github.com/{REPOSITORY}"
PUBLISHED_STATUSES = {"preview", "released", "deprecated", "withdrawn"}


class PublicationError(ValueError):
    """Inkonsistenter oder nicht bestätigter Veröffentlichungsnachweis."""


def require(condition: bool, message: str) -> None:
    if not condition:
        raise PublicationError(message)


def unique_object(pairs: list[tuple[str, object]]) -> dict:
    result = {}
    for key, value in pairs:
        require(key not in result, "Doppelter JSON-Schlüssel")
        result[key] = value
    return result


def fields(value: object, expected: set[str]) -> dict:
    require(isinstance(value, dict) and set(value) == expected,
            "Veröffentlichungsfelder fehlen oder sind unbekannt")
    return value


def text(value: object) -> str:
    require(isinstance(value, str) and bool(value.strip())
            and not any(ord(c) < 32 for c in value), "Ungültiger Veröffentlichungstext")
    return value


def timestamp(value: object) -> dt.datetime:
    require(isinstance(value, str) and bool(re.fullmatch(
        r"\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}Z", value)), "UTC-Veröffentlichungszeit fehlt")
    try:
        return dt.datetime.strptime(value, "%Y-%m-%dT%H:%M:%SZ").replace(tzinfo=dt.timezone.utc)
    except ValueError as error:
        raise PublicationError("Ungültige Veröffentlichungszeit") from error


def reference(root: Path, value: object) -> None:
    """Referenzen sind überprüfbare Fundstellen, keine Freigabe-Attestierung."""
    value = text(value)
    if re.fullmatch(re.escape(PUBLIC_ROOT) + r"/(?:pull|issues)/[1-9]\d*(?:#(?:issuecomment-\d+|discussion_r\d+))?", value):
        return
    require(":" not in value and "\\" not in value and not value.startswith("/"),
            "Referenz muss repository-relativ oder eine öffentliche Projekt-PR-/Issue-URL sein")
    path, _, fragment = value.partition("#")
    target = (root / path).resolve()
    require(target.is_relative_to(root.resolve()) and target.is_file(), "Referenzdatei fehlt")
    if fragment:
        content = target.read_text(encoding="utf-8")
        # Unterstützt explizite IDs und die üblichen GitHub-Markdown-Headinganker.
        anchors = {re.sub(r"[^\w\- ]", "", h.lower()).replace(" ", "-")
                   for h in re.findall(r"^#+\s+(.+?)\s*$", content, re.MULTILINE)}
        require(fragment in anchors or f'id="{fragment}"' in content,
                "Referenzanker fehlt")


def git_manifest(root: Path, commit: str, manifest_path: str) -> str:
    try:
        kind = subprocess.run(
            ["git", "-C", str(root), "cat-file", "-t", commit],
            capture_output=True, text=True, encoding="utf-8", timeout=15, check=False,
        )
        require(kind.returncode == 0 and kind.stdout.strip() == "commit", "Quellreferenz ist kein lokal verfügbarer Commit")
        result = subprocess.run(
            ["git", "-C", str(root), "show", f"{commit}:{manifest_path}"],
            capture_output=True, text=True, encoding="utf-8", timeout=15, check=False,
        )
    except (OSError, subprocess.TimeoutExpired) as error:
        raise PublicationError("Quellcommit lokal nicht prüfbar; keine Bestätigung") from error
    require(result.returncode == 0, "Quellcommit/Manifest lokal nicht verfügbar; keine Bestätigung")
    return result.stdout


def provider_support(manifest: str, provider: str, platform: str) -> None:
    """Liest nur die etablierte Providerliste mit inline Plattformliste."""
    lines = manifest.splitlines()
    require("providers:" in lines, "Providerdeklaration fehlt")
    providers = []
    current = None
    for line in lines[lines.index("providers:") + 1:]:
        if line and not line.startswith(" "):
            break
        match = re.fullmatch(r"  - id:\s*(.+)", line)
        if match:
            current = {"id": match[1].strip("\"'")}
            providers.append(current)
        elif current is not None:
            match = re.fullmatch(r"    (platforms|status):\s*(.+)", line)
            if match:
                require(match[1] not in current, "Doppeltes Providerfeld")
                current[match[1]] = match[2].strip("\"'")
    selected = [item for item in providers if item["id"] == provider]
    require(len(selected) == 1, "Provider nicht eindeutig deklariert")
    selected = selected[0]
    declared = selected.get("platforms", "")
    require(declared.startswith("[") and declared.endswith("]")
            and platform in {item.strip().strip("\"'") for item in declared[1:-1].split(",")}
            and selected.get("status") in {"validated", "partially validated"},
            "Provider auf dieser Plattform nicht qualifiziert")


def verify_source_snapshot(root: Path, module: dict, commit: str) -> None:
    """Aktive Publikationsstatus dürfen keine veränderten Runtimeinputs verdecken."""
    prefix = Path(module["manifest_path"]).parent.as_posix()
    paths = [f"{prefix}/{directory}" for directory in ("Source", "Clr", "Deployment", "Scripts")]
    try:
        diff = subprocess.run(["git", "-C", str(root), "diff", "--quiet", commit, "--", *paths],
                              capture_output=True, timeout=15, check=False)
        untracked = subprocess.run(["git", "-C", str(root), "ls-files", "--others", "--exclude-standard", "--", *paths],
                                   capture_output=True, timeout=15, check=False)
    except (OSError, subprocess.TimeoutExpired) as error:
        raise PublicationError("Veröffentlichter Quellstand lokal nicht prüfbar") from error
    require(diff.returncode == 0 and untracked.returncode == 0 and not untracked.stdout,
            "Aktuelle Runtime-/Packaginginputs weichen vom veröffentlichten Quellcommit ab")


def validate_record(record: object, module: dict, root: Path, scalar, top_list, section) -> dict:
    """Prüft den geschlossenen v1-Vertrag ohne Netzwerk oder Runtimezugriff."""
    record = fields(record, {"schema_version", "module_id", "module_version", "source_commit",
                             "publication", "support_scope", "limitations", "pending_outside_scope", "artifacts"})
    require(record["schema_version"] == "1.0", "Unbekannte Publication-Schemaversion")
    require(record["module_id"] == module["id"] and record["module_version"] == module["version"],
            "Publication-Modul oder Version widerspricht dem Manifest")
    require(isinstance(record["source_commit"], str) and bool(re.fullmatch(r"[0-9a-f]{40}", record["source_commit"])),
            "Vollständiger Git-Commit erforderlich")
    source = git_manifest(root, record["source_commit"], module["manifest_path"])
    require(scalar(source, "module_id") == module["id"] and scalar(source, "version") == module["version"],
            "Quellcommit enthält eine andere Modulidentität oder Version")
    if module["release_status"] in {"preview", "released"}:
        verify_source_snapshot(root, module, record["source_commit"])
    require(module["implementation_status"] in {"implemented", "deprecated"}, "Veröffentlichung ohne Implementierung")
    require(module["validation_status"] in {"validated", "partially validated"}, "Veröffentlichung ohne erfolgreiche Qualifikation")
    publication = fields(record["publication"], {"url", "tag", "published_at", "approval_reference", "channel"})
    tag = text(publication["tag"])
    require(bool(re.fullmatch(r"[A-Za-z0-9][A-Za-z0-9._-]*", tag)) and ".." not in tag,
            "Ungültiger Veröffentlichungstag")
    require(publication["url"] == f"{PUBLIC_ROOT}/releases/tag/{quote(tag, safe='')}",
            "Veröffentlichungs-URL gehört nicht zum exakten Projekttag")
    published = timestamp(publication["published_at"])
    require(published <= dt.datetime.now(dt.timezone.utc), "Veröffentlichungszeit liegt in der Zukunft")
    require(isinstance(publication["channel"], str) and publication["channel"] in {"preview", "released"},
            "Ungültiger Veröffentlichungskanal")
    if module["release_status"] in {"preview", "released"}:
        require(publication["channel"] == module["release_status"], "Kanal widerspricht Release-Status")
    reference(root, publication["approval_reference"])
    for key in ("limitations", "pending_outside_scope"):
        require(isinstance(record[key], list), "Grenzen müssen explizite Listen sein")
        for item in record[key]:
            text(item)
    scope = record["support_scope"]
    require(isinstance(scope, list) and bool(scope), "Veröffentlichter Supportumfang fehlt")
    scopes = set()
    for row in scope:
        row = fields(row, {"sql_server_version", "platform", "provider", "deployment_mode", "qualification"})
        key = tuple(text(row[k]) for k in ("sql_server_version", "platform", "provider", "deployment_mode"))
        require(key not in scopes, "Doppelter Supportumfang")
        scopes.add(key)
        require(row["sql_server_version"] in module["versions"]
                and row["sql_server_version"] in top_list(source, "sql_server_versions"), "Nicht deklarierte SQL-Version")
        for manifest in (module["manifest_text"], source):
            platforms = section(manifest, "platforms")
            require(row["platform"] in {"Windows", "Linux"}
                    and platforms.get(row["platform"].lower()) in {"validated", "partially validated"},
                    "Nicht qualifizierte Plattform")
            provider_support(manifest, row["provider"], row["platform"])
            capabilities = section(manifest, "deployment_capabilities")
            require(row["deployment_mode"] in {"local", "central"}
                    and capabilities.get(row["deployment_mode"]) == "true", "Nicht deklarierter Deployment-Modus")
        evidence = row["qualification"]
        require(isinstance(evidence, list) and bool(evidence), "Qualifikation je Supportkombination fehlt")
        for item in evidence:
            item = fields(item, {"reference", "method", "executed_on", "result"})
            reference(root, item["reference"])
            text(item["method"])
            require(isinstance(item["executed_on"], str) and bool(re.fullmatch(r"\d{4}-\d{2}-\d{2}", item["executed_on"])),
                    "Qualifikationsdatum muss YYYY-MM-DD sein")
            try:
                executed = dt.date.fromisoformat(text(item["executed_on"]))
            except ValueError as error:
                raise PublicationError("Ungültiges Qualifikationsdatum") from error
            require(item["result"] == "success" and executed <= published.date(),
                    "Qualifikation fehlgeschlagen oder nach Veröffentlichung datiert")
    artifacts = record["artifacts"]
    require(isinstance(artifacts, list), "Artefaktliste fehlt")
    names = set()
    for artifact in artifacts:
        artifact = fields(artifact, {"name", "sha256"})
        name = text(artifact["name"])
        require(name not in names and bool(re.fullmatch(r"[A-Za-z0-9][A-Za-z0-9._-]*", name)), "Ungültiger/doppelter Artefaktname")
        names.add(name)
        require(isinstance(artifact["sha256"], str) and bool(re.fullmatch(r"[0-9a-f]{64}", artifact["sha256"])),
                "Ungültiger Artefakt-SHA256")
    require(section(source, "clr").get("used") != "true" or bool(artifacts), "CLR-Veröffentlichung ohne Binaryartefakte")
    return record


def github_get(endpoint: str) -> object:
    """Nur GET über den bestehenden CLI-Client; keine Antwort-/Credentiallogs."""
    try:
        result = subprocess.run(
            ["gh", "api", "--hostname", "github.com", "--method", "GET", endpoint],
            capture_output=True, text=True, encoding="utf-8", timeout=30, check=False,
        )
    except (OSError, subprocess.TimeoutExpired) as error:
        raise PublicationError("PUBLICATION_UNAVAILABLE: GitHub-Abfrage nicht ausführbar") from error
    if result.returncode:
        # Weder stderr noch komplette API-Antworten werden ausgegeben.
        if re.search(r"HTTP (404|410)\b", result.stderr):
            raise PublicationError("PUBLICATION_FAILED: Veröffentlichung/Referenz fehlt")
        raise PublicationError("PUBLICATION_UNAVAILABLE: GitHub liefert keinen prüfbaren Nachweis")
    try:
        return json.loads(result.stdout, object_pairs_hook=unique_object)
    except (ValueError, PublicationError) as error:
        raise PublicationError("PUBLICATION_UNAVAILABLE: ungültige GitHub-Antwort") from error


def verify_github(record: dict, get=None) -> None:
    if get is None:
        get = github_get
    publication = record["publication"]
    prefix = f"repos/{REPOSITORY}"
    release = get(f"{prefix}/releases/tags/{quote(publication['tag'], safe='')}")
    require(isinstance(release, dict), "PUBLICATION_FAILED: Releaseantwort ist kein Objekt")
    require(release.get("draft") is False and release.get("tag_name") == publication["tag"]
            and release.get("html_url") == publication["url"]
            and release.get("published_at") == publication["published_at"]
            and release.get("prerelease") is (publication["channel"] == "preview"),
            "PUBLICATION_FAILED: Veröffentlichung widerspricht dem Datensatz")
    ref = get(f"{prefix}/git/ref/tags/{quote(publication['tag'], safe='')}")
    require(isinstance(ref, dict) and ref.get("ref") == f"refs/tags/{publication['tag']}",
            "PUBLICATION_FAILED: exakte Tagreferenz fehlt")
    obj = ref.get("object")
    # Annotierte Tags auflösen; target_commitish kann ein veränderlicher Branch sein.
    for _ in range(5):
        require(isinstance(obj, dict) and isinstance(obj.get("sha"), str)
                and bool(re.fullmatch(r"[0-9a-f]{40}", obj["sha"])), "PUBLICATION_FAILED: ungültiges Git-Objekt")
        if obj.get("type") == "commit":
            break
        require(obj.get("type") == "tag", "PUBLICATION_FAILED: Tag zeigt nicht auf Commit")
        nested = get(f"{prefix}/git/tags/{obj['sha']}")
        require(isinstance(nested, dict), "PUBLICATION_FAILED: ungültiger annotierter Tag")
        obj = nested.get("object")
    require(isinstance(obj, dict) and obj.get("type") == "commit" and obj.get("sha") == record["source_commit"],
            "PUBLICATION_FAILED: Tag und Quellcommit widersprechen sich")
    assets = release.get("assets")
    require(isinstance(assets, list) and all(isinstance(a, dict) for a in assets), "PUBLICATION_FAILED: Artefaktliste fehlt")
    require(all(isinstance(a.get("name"), str) for a in assets), "PUBLICATION_FAILED: ungültige Assetnamen")
    require(len({a.get('name') for a in assets}) == len(assets), "PUBLICATION_FAILED: doppelte Assets")
    require({a.get("name") for a in assets} == {a["name"] for a in record["artifacts"]},
            "PUBLICATION_FAILED: ausgelieferte Artefaktmenge widerspricht dem Datensatz")
    for artifact in record["artifacts"]:
        asset = next(a for a in assets if a.get("name") == artifact["name"])
        require(asset.get("state") == "uploaded", "PUBLICATION_FAILED: Artefakt nicht fertig hochgeladen")
        require(isinstance(asset.get("digest"), str) and asset["digest"].startswith("sha256:"),
                "PUBLICATION_UNAVAILABLE: GitHub-Assetdigest fehlt; keine Hashbestätigung")
        require(asset["digest"] == "sha256:" + artifact["sha256"], "PUBLICATION_FAILED: Artefakthash widerspricht GitHub")


def validate_publications(modules: list[dict], root: Path, scalar, top_list, section,
                          *, online: bool = False) -> int:
    records = []
    for module in modules:
        manifest = module["manifest_text"]
        declarations = re.findall(r"^publication_record:\s*(.*?)\s*$", manifest, re.MULTILINE)
        required = module["release_status"] in PUBLISHED_STATUSES
        require(len(declarations) <= 1, "Doppelte publication_record-Deklaration")
        if not declarations:
            require(not required, f"{module['id']}: Veröffentlichungsnachweis fehlt")
            continue
        require(required, "unreleased erhält keinen behaupteten Veröffentlichungsnachweis")
        relative = scalar(manifest, "publication_record")
        require(":" not in relative and "\\" not in relative and not relative.startswith("/"), "Publication-Pfad muss modulrelativ sein")
        path = (module["root"] / relative).resolve()
        require(path.is_relative_to(module["root"].resolve()) and path.is_file() and path.suffix == ".json",
                "Publication-Datei fehlt oder verlässt das Modul")
        try:
            record = json.loads(path.read_text(encoding="utf-8"), object_pairs_hook=unique_object)
        except (OSError, ValueError) as error:
            raise PublicationError("Publication-JSON ist nicht lesbar oder nicht eindeutig") from error
        records.append(validate_record(record, module, root, scalar, top_list, section))
    # Erst alle lokalen Datensätze prüfen, dann gezielt externe Evidenz abfragen.
    if online:
        for record in records:
            verify_github(record)
    return len(records)
