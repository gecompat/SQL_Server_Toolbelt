"""rc.3-Installationsbundle aus exakten Gitbytes; keine SQL-/Netzwerkausführung."""
from __future__ import annotations

import argparse
import hashlib
import io
import json
from pathlib import Path
import posixpath
import re
import zipfile

import prepare_release as source

TAG = "v1.0.0-rc.3"
INNER = "Releases/1.0.0/Builds/2026-11-18-78fb8571/SQL-Server-Toolbelt-1.0.0-Current-Install.zip"
INNER_SHA = "78a8a737395ee42d34d264191756d8c5d06bae5b82b368c04c35afd9f67183fb"
ENTRY = "Deployment/Install-Toolbelt.ps1"
EVIDENCE = "Deployment/Tests/Qualification/OneCallInstaller.20261119.json"
GUIDE = "Releases/1.0.0/RC3-INSTALL.md"
DOCS = {"START-HERE.md": GUIDE, "INSTALL.md": "INSTALL.md",
        "Deployment/ONE-CALL-INSTALL.md": "Deployment/ONE-CALL-INSTALL.md"}
MANIFEST = "BUNDLE.json"
SUMS = "SHA256SUMS"
MAX_BYTES = 64 * 1024 * 1024


def require(condition, message):
    if not condition:
        raise ValueError("ONE_CALL_BUNDLE: " + message)


def sha(data):
    return hashlib.sha256(data).hexdigest()


def encoded(value):
    return (json.dumps(value, ensure_ascii=False, sort_keys=True, indent=2) + "\n").encode()


def git_file(commit, path):
    source.safe_path(path)
    return source.git("show", commit + ":" + path)


def read_zip(data):
    with zipfile.ZipFile(io.BytesIO(data)) as archive:
        require(len(archive.infolist()) <= 64 and sum(x.file_size for x in archive.infolist()) <= MAX_BYTES,
                "Archivbudget überschritten")
        result = {}
        seen = set()
        for item in archive.infolist():
            source.safe_path(item.filename)
            require(not item.is_dir() and item.filename.casefold() not in seen, "Doppelter oder ungültiger Archiveintrag")
            seen.add(item.filename.casefold())
            result[item.filename] = archive.read(item)
        return result


def relocate_doc(data, original_path, delivered_path, delivered, commit, docs=None):
    """Lokale Lesewege erhalten, nicht mitgelieferte Vertiefung commitfest verlinken."""
    aliases = {original: destination for destination, original in (docs or DOCS).items()}

    def replace(match):
        target = match[1].decode("utf-8")
        if target.startswith(("#", "/")) or ":" in target:
            return match[0]
        path, separator, anchor = target.partition("#")
        origin = posixpath.normpath(posixpath.join(posixpath.dirname(original_path), path))
        destination = aliases.get(origin, origin)
        if destination in delivered:
            link = posixpath.relpath(destination, posixpath.dirname(delivered_path) or ".")
        else:
            link = "https://github.com/gecompat/SQL_Server_Toolbelt/blob/" + commit + "/" + origin
        return (link + separator + anchor).encode()

    return re.sub(rb"(?<=\]\()([^\s)]+)(?=\))", replace, data)


def payload(commit):
    resolved = source.git("rev-parse", commit + "^{commit}").decode().strip()
    require(bool(re.fullmatch(r"[0-9a-f]{40}", resolved)), "Vollständiger Quellcommit erforderlich")
    # export-ignore hält fertige ZIPs aus Quell-Exports heraus. Für die Lieferung
    # wird die bekannte Basis gezielt aus ihrem unveränderten Gitobjekt gelesen.
    inner = git_file(resolved, INNER)
    require(sha(inner) == INNER_SHA, "Ursprüngliche rc.2-Basis abweichend")
    original = read_zip(inner)
    evidence_bytes = git_file(resolved, EVIDENCE)
    evidence = json.loads(evidence_bytes)
    require(evidence["result"] == "PASS_FOR_DECLARED_SCOPE" and evidence["totals"]["profiles"] == 12
            and evidence["totals"]["fresh_success_audits"] == 6
            and evidence["package"] == {"path": INNER, "sha256": INNER_SHA}
            and evidence["scope"]["new_tls_or_gui_qualification"] is False
            and evidence["scope"]["new_business_module_qualification"] is False, "Nativer Clientnachweis fehlt")
    for path, digest in evidence["method_source_sha256"].items():
        require(sha(git_file(resolved, path).replace(b"\r\n", b"\n")) == digest, "Native Methodenbindung abweichend: " + path)
    entry = git_file(resolved, ENTRY)
    require(sha(entry.replace(b"\r\n", b"\n")) == evidence["method_source_sha256"][ENTRY], "Einstieg nicht nativ gebunden")
    require(b"../" + INNER.encode() in entry, "Lokale Paketauflösung wurde geändert")
    result = {ENTRY: entry, INNER: inner, EVIDENCE: evidence_bytes, "LICENSE.md": original["LICENSE.md"]}
    result.update({name: data for name, data in original.items() if name.startswith("ThirdParty/")})
    delivered = set(result) | DOCS.keys()
    projection = {}
    for destination, path in DOCS.items():
        raw = git_file(resolved, path)
        result[destination] = relocate_doc(raw, path, destination, delivered, resolved)
        projection[destination] = {"source_path": path, "source_sha256": sha(raw)}
    result[MANIFEST] = encoded({
        "kind": "one_call_install_bundle", "project_prerelease": TAG, "source_commit": resolved,
        "entrypoint": ENTRY, "base_release": "v1.0.0-rc.2", "base_package": {"path": INNER, "sha256": INNER_SHA},
        "native_evidence": {"path": EVIDENCE, "sha256": sha(evidence_bytes), "reused_profiles": 12, "fresh_audits_in_original_wave": 6},
        "reuse": "entrypoint and inner ZIP unchanged; same relative runtime layout; documentation links projected",
        "new_sql_tls_execution": False, "module_release_status_changed": False,
        "documentation_projection": projection,
        "files": {name: {"bytes": len(data), "sha256": sha(data)} for name, data in sorted(result.items())},
    })
    result[SUMS] = "".join(sha(data) + "  " + name + "\n" for name, data in sorted(result.items())).encode()
    require(sum(map(len, result.values())) <= MAX_BYTES, "Lieferbudget überschritten")
    return result


def write_zip(files):
    stream = io.BytesIO()
    with zipfile.ZipFile(stream, "w", compression=zipfile.ZIP_DEFLATED, compresslevel=9) as archive:
        for name, data in sorted(files.items()):
            source.safe_path(name)
            info = zipfile.ZipInfo(name, (2026, 11, 19, 0, 0, 0))
            info.compress_type = zipfile.ZIP_DEFLATED
            info.external_attr = 0o100644 << 16
            archive.writestr(info, data)
    return stream.getvalue()


def verify_payload(files):
    require(MANIFEST in files and SUMS in files, "Manifest/Prüfsummen fehlen")
    manifest = json.loads(files[MANIFEST])
    require(manifest.get("kind") == "one_call_install_bundle" and manifest.get("project_prerelease") == TAG,
            "Falscher Liefervertrag")
    commit = manifest.get("source_commit", "")
    require(bool(re.fullmatch(r"[0-9a-f]{40}", commit)), "Ungültiger Quellcommit")
    # Die Gitquelle bestimmt alle erlaubten Bytes, auch nach konsistentem
    # Neuhashen eines manipulierten Manifests oder ausgetauschten Einstiegs.
    require(files == payload(commit), "Lieferung weicht vom gebundenen Gitstand ab")
    return manifest


def build(commit, output):
    output = Path(output)
    checksum = Path(str(output) + ".sha256")
    require(output.parent.is_dir() and not output.exists() and not checksum.exists(), "Neues Ausgabeziel erforderlich")
    data = write_zip(payload(commit))
    verify_payload(read_zip(data))
    with output.open("xb") as stream:
        stream.write(data)
    with checksum.open("x", encoding="ascii", newline="\n") as stream:
        stream.write(sha(data) + "  " + output.name + "\n")


def verify(path):
    path = Path(path)
    data = path.read_bytes()
    require(Path(str(path) + ".sha256").read_text().split() == [sha(data), path.name], "Äußere Prüfsumme abweichend")
    return verify_payload(read_zip(data))


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    mode = parser.add_mutually_exclusive_group(required=True)
    mode.add_argument("--build", action="store_true")
    mode.add_argument("--verify", type=Path)
    parser.add_argument("--source-commit")
    parser.add_argument("--output", type=Path)
    args = parser.parse_args()
    if args.verify:
        verify(args.verify)
    else:
        require(args.source_commit and args.output, "Quellcommit und Ausgabe erforderlich")
        build(args.source_commit, args.output)
    print("ONE_CALL_BUNDLE_INTEGRITY_PASS; unchanged entry/basis and bound evidence; no SQL or publication")
