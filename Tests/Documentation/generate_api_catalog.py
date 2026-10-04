#!/usr/bin/env python3
"""Offline-Katalog: öffentliche Manifestobjekte, echte SQL-Signaturen und Beispiele.

Die kleine explizite Beispielregistry ergänzt die modullokalen Verträge. Sie
enthält ausschließlich redaktionelle, synthetische Inhalte. SQLCMD, SQL Server,
Secrets, Hostdaten und externe Pakete werden weder benötigt noch gelesen.
"""
from __future__ import annotations

import argparse
import hashlib
import html
import json
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
DEST = ROOT / "Documentation/Reference"
REGISTRY = DEST / "api_examples.json"
PUBLIC_TYPES = {"USP", "TVF", "SVF", "VW", "VIEW", "CLR_TVF", "CLR_SVF", "CLR_AGGREGATE"}


def sql_parts(text: str, split: bool = False, header: bool = False) -> list[str]:
    """Entfernt Kommentare und trennt nur Kommas außerhalb von Strings/Klammern.

    SQL-Strings und bracketed Identifier werden als Einheit gelesen; dadurch
    verändern Defaultwerte mit Kommas oder Kommentarzeichen die Signatur nicht.
    """
    parts, current, depth, index = [], [], 0, 0
    outer_signature = False
    while index < len(text):
        if text.startswith("--", index):
            end = text.find("\n", index)
            index = len(text) if end < 0 else end
            current.append(" ")
            continue
        if text.startswith("/*", index):
            level = 1
            index += 2
            while index < len(text) and level:
                if text.startswith("/*", index):
                    level += 1
                    index += 2
                elif text.startswith("*/", index):
                    level -= 1
                    index += 2
                else:
                    index += 1
            if level:
                raise ValueError("Unvollständiger SQL-Kommentar")
            current.append(" ")
            continue
        char = text[index]
        if (header and depth == 0
                and (index == 0 or not re.match(r"\w", text[index-1]))
                and re.match(r"AS\b", text[index:], re.I)):
            break
        if char in "'[":
            closing = "'" if char == "'" else "]"
            start = index
            index += 1
            while index < len(text):
                if text[index] == closing:
                    if index + 1 < len(text) and text[index + 1] == closing:
                        index += 2
                        continue
                    index += 1
                    break
                index += 1
            else:
                raise ValueError("Unvollständiger SQL-String/Identifier")
            current.append(text[start:index])
            continue
        if char == "(":
            if header and not "".join(current).strip():
                outer_signature = True
            depth += 1
        elif char == ")":
            depth -= 1
            if header and outer_signature and depth == 0:
                current.append(char)
                break
        if split and char == "," and depth == 0:
            parts.append("".join(current).strip())
            current = []
        else:
            current.append(char)
        index += 1
    parts.append("".join(current).strip())
    return parts


def objects(root: Path) -> list[dict]:
    """Liest die beiden im Projekt verwendeten YAML-Objektlistenformen.

    Unbekannte öffentliche Objekttypen sind ein Fehler, kein stiller Verlust.
    Tabellen/Assemblies sind keine Aufrufoberfläche und werden separat ignoriert.
    """
    result = []
    for path in sorted((root / "Modules").glob("*/module.yaml")):
        text = path.read_text(encoding="utf-8-sig")
        block = re.search(r"^objects:\s*\n(.*?)(?=^\S|\Z)", text, re.M | re.S)
        if not block:
            raise ValueError(f"Objektliste fehlt: {path.relative_to(root)}")
        version = re.search(r'^version:\s*"([^\"]+)"', text, re.M).group(1)
        for row in re.split(r"^\s+-\s+", block.group(1), flags=re.M)[1:]:
            fields = {k: v.strip().strip("\"'") for k, v in re.findall(
                r"(type|schema|name|visibility):\s*([^,}\n]+)", row)}
            if fields.get("visibility") != "public":
                continue
            kind = fields.get("type")
            if kind in {"TABLE", "ASSEMBLY"}:
                continue
            if kind not in PUBLIC_TYPES:
                raise ValueError(f"Nicht unterstützter öffentlicher Typ: {fields}")
            result.append(dict(fields, module=path.parent.name, version=version, root=path.parent))
    keys = [i["schema"] + "." + i["name"] for i in result]
    if len(keys) != len(set(keys)):
        raise ValueError("Doppelte öffentliche API im Manifest")
    return result


def signature(item: dict) -> tuple[Path, list[dict]]:
    """Bindet jedes Objekt an genau eine CREATE-Deklaration seiner Source.

    SQL-Typen, Reihenfolge, Defaults und OUTPUT werden nie aus Beispielen oder
    einem installierten Katalog geraten. Views besitzen keine Parameterliste.
    """
    prefix = (r"CREATE(?:\s+OR\s+ALTER)?\s+(?:PROCEDURE|FUNCTION|AGGREGATE|VIEW)\s+"
              + r"\[?" + re.escape(item["schema"]) + r"\]?\.\[?"
              + re.escape(item["name"]) + r"\]?(?!\w)")
    matches = []
    for source in sorted((item["root"] / "Source").glob("*.sql")):
        # CREATE in synthetischen Dynamic-SQL-Aggregatdeklarationen ist zulässig.
        text = source.read_text(encoding="utf-8-sig")
        for found in re.finditer(prefix, text, re.I):
            matches.append((source, text[found.end():]))
    if len(matches) != 1:
        raise ValueError(f"Genau eine Source-Deklaration erforderlich: {item['name']} ({len(matches)})")
    source, tail = matches[0]
    if item["type"] in {"VW", "VIEW"}:
        return source, []
    tail = sql_parts(tail, header=True)[0].lstrip()
    if tail.startswith("("):
        if not tail.endswith(")"):
            raise ValueError(f"Unvollständige Signatur: {item['name']}")
        header_text = tail[1:-1]
    else:
        header_text = tail.strip()
    params = []
    for declaration in sql_parts(header_text, split=True):
        if not declaration:
            continue
        match = re.fullmatch(r"(@\w+)\s+([\w.\[\]]+(?:\s*\([^)]*\))?)\s*"
                             r"(?:=\s*(.*?))?\s*(OUTPUT|OUT|READONLY)?", declaration, re.I | re.S)
        if not match:
            raise ValueError(f"Nicht unterstützte Signatur: {item['name']}: {declaration}")
        name, kind, default, modifier = match.groups()
        params.append(dict(name=name, type=re.sub(r"\s+", "", kind),
                           default=default.strip() if default is not None else "kein Default",
                           output=(modifier or "").upper() in {"OUTPUT", "OUT"}))
    return source, params


def documentation(item: dict) -> list[Path]:
    directory = item["root"] / "Documentation"
    exact = directory / (item["name"] + ".md")
    if exact.is_file():
        return [exact]
    candidates = [p for p in sorted(directory.glob("*.md"))
                  if item["name"] in p.read_text(encoding="utf-8-sig")]
    return candidates or [item["root"] / "README.md"]


def render(root: Path = ROOT) -> dict[str, str]:
    registry = json.loads((root / REGISTRY.relative_to(ROOT)).read_text(encoding="utf-8"))
    entries = objects(root)
    keys = {i["schema"] + "." + i["name"] for i in entries}
    if keys != registry.keys():
        raise ValueError(f"Beispielregistry unvollständig/veraltet: fehlen={sorted(keys-registry.keys())}, "
                         f"veraltet={sorted(registry.keys()-keys)}")
    md = ["# SQL Server Toolbelt Beispielkatalog", "",
          "<!-- Generiert mit Tests/Documentation/generate_api_catalog.py --write; nicht direkt bearbeiten. -->", "",
          f"{len(entries)} öffentliche Schnittstellen aus {len({i['module'] for i in entries})} Modulen. "
          "Dieser Katalog ergänzt die verbindlichen Objektverträge mit kurzen Erklärungen, "
          "Source-Signaturen und synthetischen Beispielaufrufen.", "",
          "Jedes Beispiel separat verwenden. Funktionen verlangen positionsbezogene Argumente; "
          "`DEFAULT` verwendet einen deklarierten Default, `NULL` kann davon abweichen. "
          "Prozeduren verwenden benannte Parameter. Vorlagen mit Handlern, Claims, Dateien oder "
          "Plan-Hashes erfordern die beschriebenen Voraussetzungen. Eine Syntaxvorlage ist kein Runtime-Nachweis.", "",
          "Pflege und Generierung: [README](README.md).", ""]
    sql = ["-- Generiert aus Repositoryquellen; Beispiele einzeln auswählen, nicht gesammelt ausführen.",
           "-- Kein Installationsziel wird fest vorgegeben. In der gewünschten Toolbelt-Datenbank verwenden.", ""]
    cards = []
    for item in entries:
        key = item["schema"] + "." + item["name"]
        entry = registry[key]
        if set(entry) != {"summary", "examples", "requirements", "parameter_notes"} or not entry["summary"] or not entry["examples"]:
            raise ValueError(f"Ungültiger redaktioneller Eintrag: {key}")
        if (not isinstance(entry["summary"], str)
                or not isinstance(entry["examples"], list)
                or not isinstance(entry["requirements"], list)
                or not isinstance(entry["parameter_notes"], dict)
                or any(not isinstance(s, str) or not s.strip() for s in
                       entry["examples"] + entry["requirements"] + list(entry["parameter_notes"].values()))):
            raise ValueError(f"Ungültige redaktionelle Inhalte: {key}")
        source, params = signature(item)
        if set(entry["parameter_notes"]) != {p["name"] for p in params}:
            raise ValueError(f"Parametererklärungen fehlen oder sind veraltet: {key}")
        docs = documentation(item)
        sources = [source] + docs
        fingerprint = hashlib.sha256("\n".join(
            p.relative_to(root).as_posix() + "\n" + p.read_text(encoding="utf-8-sig")
            for p in sources).encode("utf-8")).hexdigest()
        links = [f"[{p.name}](../../{p.relative_to(root).as_posix()})" for p in sources]
        md += [f"## {key}", "", f"Modul `{item['module']}` · Version `{item['version']}` · `{item['type']}`", "",
               entry["summary"], "", "Vertrag und Quelle: " + ", ".join(links) + ".", ""]
        md += [f"<!-- Source/Vertrag SHA256: {fingerprint} -->", ""]
        for requirement in entry["requirements"]:
            md += ["Voraussetzung: " + requirement, ""]
        if params:
            md += ["| Parameter | SQL-Typ | Default | Richtung | Erklärung / Werte |", "|---|---|---|---|---|"]
            for param in params:
                md.append("| " + " | ".join("`" + str(param[k]).replace("|", "&#124;") + "`"
                          for k in ("name", "type", "default")) + " | "
                          + ("OUTPUT" if param["output"] else "Input") + " | "
                          + entry["parameter_notes"][param["name"]].replace("|", "&#124;").replace("\n", " ") + " |")
            md += ["", "Erlaubte Werte, fachliche Pflicht und Grenzen stehen im verlinkten Objektvertrag.", ""]
        else:
            md += ["Keine Eingabeparameter.", ""]
        sql += ["-- " + key, "-- " + entry["summary"]]
        sql += ["-- Voraussetzung: " + r for r in entry["requirements"]]
        for example in entry["examples"]:
            if not isinstance(example, str) or key not in example:
                raise ValueError(f"Beispiel ohne eigenen Aufruf: {key}")
            md += ["```sql", example, "```", ""]
            sql += ["/* Separat auswählen und ausführen:", example, "*/", ""]
        if item["type"] == "USP":
            mandatory = [p["name"] + "=NULL" for p in params if p["default"] == "kein Default"]
            md += ["Hilfe:", "", "```sql", "EXEC " + key + " " + ", ".join(mandatory + ["@Hilfe=1"]) + ";", "```", ""]
        # Beide Ansichten verwenden dieselben Einträge, ohne externe Assets.
        body = [f'<p>Modul <code>{html.escape(item["module"])}</code> · '
                f'Version {html.escape(item["version"])} · {item["type"]}</p>',
                f'<p>{html.escape(entry["summary"])}</p>', '<p>Vertrag und Quelle: ' +
                ', '.join(f'<a href="../../{p.relative_to(root).as_posix()}">{html.escape(p.name)}</a>'
                          for p in sources) + '</p>']
        body += [f'<p class="requirement">Voraussetzung: {html.escape(r)}</p>' for r in entry["requirements"]]
        if params:
            body.append('<div class="table"><table><thead><tr><th>Parameter</th><th>SQL-Typ</th>'
                        '<th>Default</th><th>Richtung</th><th>Erklärung / Werte</th></tr></thead><tbody>')
            for param in params:
                body.append('<tr>' + ''.join(f'<td><code>{html.escape(str(param[k]))}</code></td>'
                                            for k in ("name", "type", "default")) +
                            '<td>' + ('OUTPUT' if param['output'] else 'Input') + '</td><td>' +
                            html.escape(entry['parameter_notes'][param['name']]) + '</td></tr>')
            body.append('</tbody></table></div><p>Erlaubte Werte und Grenzen: siehe Objektvertrag.</p>')
        else:
            body.append('<p>Keine Eingabeparameter.</p>')
        snippets = list(entry["examples"])
        if item["type"] == "USP":
            snippets.append("EXEC " + key + " " + ", ".join(mandatory + ["@Hilfe=1"]) + ";")
        body += ['<div class="example"><button type="button">SQL kopieren</button><pre><code>' +
                 html.escape(example) + '</code></pre></div>' for example in snippets]
        cards.append(f'<article data-search="{html.escape((key+" "+entry["summary"]+" "+item["module"]).lower(), quote=True)}">'
                     f'<h2>{html.escape(key)}</h2>' + ''.join(body) + '</article>')
    page = ('<!doctype html><html lang="de"><meta charset="utf-8"><meta name="viewport" content="width=device-width">'
            '<title>SQL Server Toolbelt Beispielkatalog</title><style>body{font:16px/1.6 Segoe UI,sans-serif;max-width:1200px;'
            'margin:30px auto;padding:20px;background:#f3f6f8;color:#18384e}input{padding:12px;width:95%;font:inherit;'
            'position:sticky;top:10px}article{background:white;padding:24px;margin:24px 0;border-radius:10px}'
            'h2{overflow-wrap:anywhere}pre{white-space:pre-wrap;overflow-wrap:anywhere;font:14px/1.6 Consolas,monospace}'
            'table{border-collapse:collapse;width:100%}td,th{padding:8px;text-align:left;border-bottom:1px solid #d6e0e8}'
            '.table{overflow:auto}.example{background:#eef3f7;padding:15px;margin:15px 0;border-radius:8px}'
            'button{cursor:pointer;padding:6px 12px}.requirement{border-left:3px solid #ba861b;padding-left:12px}'
            '[hidden]{display:none}</style><h1>SQL Server Toolbelt Beispielkatalog</h1>'
            f'<p>{len(entries)} öffentliche Schnittstellen. Beispiele einzeln in der gewünschten Toolbelt-Datenbank verwenden. '
            'Voraussetzungen beachten; Syntaxvorlagen sind kein Runtime-Nachweis.</p>'
            '<p><a href="README.md">Pflege</a> · <a href="API_CATALOG.md">Markdown</a> · '
            '<a href="API_EXAMPLES.sql">SQL-Beispielsammlung</a></p>'
            '<input type="search" aria-label="Suchen" placeholder="Funktion, Modul oder Beschreibung suchen">'
            + "\n".join(cards) + '<script>document.querySelector("input").addEventListener("input",e=>{'
            'const q=e.target.value.toLowerCase().trim();document.querySelectorAll("article").forEach(a=>'
            'a.hidden=!a.dataset.search.includes(q));});'
            'document.querySelectorAll("button").forEach(b=>b.addEventListener("click",async()=>{'
            'try{await navigator.clipboard.writeText(b.parentElement.querySelector("code").textContent);'
            'b.textContent="Kopiert";}catch{b.textContent="Bitte SQL markieren und kopieren";}}));</script></html>\n')
    return {"API_CATALOG.md": "\n".join(md).rstrip() + "\n",
            "API_EXAMPLES.sql": "\n".join(sql).rstrip() + "\n", "API_CATALOG.html": page}


def check(root: Path = ROOT, write: bool = False) -> None:
    for name, expected in render(root).items():
        target = root / DEST.relative_to(ROOT) / name
        if write:
            target.write_text(expected, encoding="utf-8", newline="\n")
        elif not target.is_file() or target.read_text(encoding="utf-8") != expected:
            raise ValueError(f"Katalog veraltet: {target.relative_to(root)}; generate_api_catalog.py --write ausführen")


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--write", action="store_true", help="Abgeleitete Katalogdateien aktualisieren")
    args = parser.parse_args()
    try:
        check(write=args.write)
    except (ValueError, KeyError, AttributeError) as error:
        parser.exit(1, f"API-Katalog: FEHLER: {error}\n")
    print("API-Katalog: PASS")
