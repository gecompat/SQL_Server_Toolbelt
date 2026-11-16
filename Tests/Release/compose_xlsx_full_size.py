"""Synthetische OPC-Archive in Originalgröße; keine manipulierten ZIP-Header."""
from __future__ import annotations

import hashlib
import io
import json
from pathlib import Path
import random
import sys
import zipfile

MIB = 1024 * 1024
S = "http://schemas.openxmlformats.org/spreadsheetml/2006/main"
R = "http://schemas.openxmlformats.org/officeDocument/2006/relationships"
P = "http://schemas.openxmlformats.org/package/2006/relationships"
SHEET = (f'<worksheet xmlns="{S}"><sheetData><row r="1">'
         '<c r="A1"><v>42</v></c></row></sheetData></worksheet>').encode()


def base() -> dict[str, bytes]:
    return {
        "[Content_Types].xml": ('<Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types">'
            '<Default Extension="bin" ContentType="application/octet-stream"/>'
            '<Override PartName="/xl/workbook.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.sheet.main+xml"/>'
            '<Override PartName="/xl/worksheets/sheet1.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.worksheet+xml"/></Types>').encode(),
        "_rels/.rels": (f'<Relationships xmlns="{P}"><Relationship Id="r1" Type="{R}/officeDocument" Target="xl/workbook.xml"/></Relationships>').encode(),
        "xl/workbook.xml": (f'<workbook xmlns="{S}" xmlns:r="{R}"><sheets><sheet name="Synthetic" sheetId="1" r:id="r1"/></sheets></workbook>').encode(),
        "xl/_rels/workbook.xml.rels": (f'<Relationships xmlns="{P}"><Relationship Id="r1" Type="{R}/worksheet" Target="worksheets/sheet1.xml"/></Relationships>').encode(),
        "xl/worksheets/sheet1.xml": SHEET,
    }


def padding(size: int) -> bytes:
    # XML-kommentarsicheres Alphabet; der Entropieblock bleibt im Deflatefenster.
    rng = random.Random(20261116)
    block = bytes(rng.choice(b"ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789")
                  for _ in range(16384))
    return (block * ((size + len(block) - 1) // len(block)))[:size]


def pack(parts: dict[str, bytes], stored: bool = False) -> bytes:
    out = io.BytesIO()
    with zipfile.ZipFile(out, "w", compression=zipfile.ZIP_STORED if stored else zipfile.ZIP_DEFLATED,
                         compresslevel=None if stored else 6, allowZip64=False) as archive:
        for name, data in parts.items():
            info = zipfile.ZipInfo(name, (2026, 1, 1, 0, 0, 0))
            info.compress_type = archive.compression
            archive.writestr(info, data)
    return out.getvalue()


def fixture(kind: str, overflow: bool) -> tuple[bytes, dict]:
    parts = base()
    delta = int(overflow)
    if kind == "archive":
        parts["padding.bin"] = b""
        overhead = len(pack(parts, stored=True))
        parts["padding.bin"] = padding(16 * MIB + delta - overhead)
    elif kind == "part":
        # ReadCells entpackt und parst diesen Part einschließlich CRC-Prüfung.
        prefix = SHEET[:-len(b"</worksheet>")] + b"<!--"
        suffix = b"--></worksheet>"
        parts["xl/worksheets/sheet1.xml"] = prefix + padding(16 * MIB + delta - len(prefix) - len(suffix)) + suffix
    elif kind == "total":
        # Vier unselektierte Payloads prüfen die deklarierte Archivsumme.
        # Die unabhängige Entpackprüfung unten validiert auch ihre echten Bytes.
        remaining = 64 * MIB + delta - sum(map(len, parts.values()))
        for index in range(4):
            size = min(16 * MIB, remaining)
            parts[f"padding{index}.bin"] = padding(size)
            remaining -= size
        assert remaining == 0
    elif kind == "parts":
        for index in range(256 + delta - len(parts)):
            parts[f"padding{index}.bin"] = b"x"
    else:
        raise ValueError(kind)
    binary = pack(parts, stored=kind == "archive")
    with zipfile.ZipFile(io.BytesIO(binary)) as archive:
        info = archive.infolist()
        assert len(info) == len(parts) and len({i.filename for i in info}) == len(info)
        for item in info:
            assert archive.read(item) == parts[item.filename]  # einschließlich CRC
            assert item.file_size <= 200 * max(1, item.compress_size)
        facts = dict(archive_bytes=len(binary), part_bytes=max(i.file_size for i in info),
                     total_bytes=sum(i.file_size for i in info), parts=len(info))
    ceilings = dict(archive_bytes=16*MIB, part_bytes=16*MIB, total_bytes=64*MIB, parts=256)
    metric = dict(archive="archive_bytes", part="part_bytes", total="total_bytes", parts="parts")[kind]
    assert facts[metric] == ceilings[metric] + delta
    assert all(facts[key] <= value for key, value in ceilings.items() if key != metric)
    return binary, facts


def compose(output: Path) -> dict:
    output.mkdir(parents=True, exist_ok=False)
    cases = []
    for kind in ("archive", "part", "total", "parts"):
        for overflow in (False, True):
            name = f"{kind}-{'plus-one' if overflow else 'exact'}"
            binary, facts = fixture(kind, overflow)
            (output / f"{name}.xlsx").write_bytes(binary)
            error = ("TBX_XLSX_ARCHIVE_LIMIT" if kind == "archive" else "TBX_XLSX_CONTAINER_INVALID") if overflow else "NONE"
            technical = ("ZIP_ARCHIVE_LIMIT" if kind == "archive" else
                         "ZIP_PART_LIMIT" if kind == "parts" else "ZIP_PART_OR_SUM_LIMIT") if overflow else "NONE"
            cases.append(dict(name=name, sha256=hashlib.sha256(binary).hexdigest(),
                              expected_error=error, technical_error=technical, **facts))
    result = dict(schema_version="toolbelt-xlsx-full-size-fixtures/v1", cases=cases)
    (output / "fixtures.json").write_text(json.dumps(result, indent=2) + "\n", encoding="utf-8")
    (output / "cases.tsv").write_text("".join(f"{c['name']}\t{c['sha256']}\t{c['expected_error']}\t{c['technical_error']}\n" for c in cases), encoding="ascii")
    return result


if __name__ == "__main__":
    compose(Path(sys.argv[1]))
    print("PASS XLSX FULL SIZE FIXTURES 8")
