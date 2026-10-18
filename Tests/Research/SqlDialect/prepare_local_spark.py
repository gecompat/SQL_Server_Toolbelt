"""Bereitet ausschließlich eine hashgebundene lokale Research-Laufzeit vor.

Keine Installation, Dienste, Cloudkonten oder Labänderungen. Apache Spark,
Py4J und eine portable Java-Laufzeit bleiben unter dem ignorierten .runtime/.
Python ab 3.12 ist wegen der sicheren tar-Extraktion erforderlich.
"""

from __future__ import annotations

import hashlib
import json
from pathlib import Path
import tarfile
from urllib.request import Request, urlopen
import zipfile


ROOT = Path(__file__).resolve().parents[3]
RUNTIME = ROOT / ".runtime/spark-sql-spike-4.0.2"
SPARK_VERSION = "4.0.2"
ASSETS = (
    ("pyspark-4.0.2.tar.gz", "https://files.pythonhosted.org/packages/96/89/408b42c803db71f4a4d8a3f1ab0745a40dfe41aeacdfc453545665a171f4/pyspark-4.0.2.tar.gz",
     "938b4a1883383374d331ebfcb5d92debfa1891cf3d7a6d730520a1a2d23f1a90"),
    ("py4j-0.10.9.9-py2.py3-none-any.whl", "https://files.pythonhosted.org/packages/bd/db/ea0203e495be491c85af87b66e37acfd3bf756fd985f87e46fc5e3bf022c/py4j-0.10.9.9-py2.py3-none-any.whl",
     "c7c26e4158defb37b0bb124933163641a2ff6e3a3913f7811b0ddbe07ed61533"),
    ("temurin-21.0.12.1-jre.zip", "https://github.com/adoptium/temurin21-binaries/releases/download/jdk-21.0.12.1%2B1/OpenJDK21U-jre_x64_windows_hotspot_21.0.12.1_1.zip",
     "d35f31e712f0fcf6ac5a093edc90204fbff22f720ba3950bd09d331d5e621636"),
)


def digest(path: Path) -> str:
    with path.open("rb") as stream:
        return hashlib.file_digest(stream, "sha256").hexdigest()


def prepare() -> dict:
    RUNTIME.mkdir(parents=True, exist_ok=True)
    receipt = []
    for name, url, expected in ASSETS:
        path = RUNTIME / name
        if not path.exists() or digest(path) != expected:
            request = Request(url, headers={"User-Agent": "sql-dialect-research-spike"})
            with urlopen(request, timeout=60) as response, path.open("wb") as target:
                while block := response.read(1024 * 1024):
                    target.write(block)
        if digest(path) != expected:
            raise RuntimeError("ARTIFACT_HASH_MISMATCH")
        receipt.append(dict(filename=name, url=url, sha256=expected))
    # Archivfilter und vollständige Pfadprüfung verhindern fremde Schreibziele.
    with tarfile.open(RUNTIME / ASSETS[0][0]) as archive:
        archive.extractall(RUNTIME / "distribution", filter="data")
    java_root = RUNTIME / "java"
    with zipfile.ZipFile(RUNTIME / ASSETS[2][0]) as archive:
        for member in archive.infolist():
            if not (java_root / member.filename).resolve().is_relative_to(java_root.resolve()):
                raise RuntimeError("UNSAFE_ARCHIVE_PATH")
        archive.extractall(java_root)
    spark = RUNTIME / "distribution/pyspark-4.0.2"
    java = RUNTIME / "java/jdk-21.0.12.1+1-jre"
    if not (java / "bin/java.exe").is_file() or not (spark / "deps/bin/spark-submit.cmd").is_file():
        raise RuntimeError("RUNTIME_LAYOUT_UNEXPECTED")
    layout = dict(spark_home=str(spark / "deps"), pyspark_source=str(spark), java_home=str(java),
                  py4j=str(RUNTIME / ASSETS[1][0]))
    (RUNTIME / "dependency-receipt.json").write_text(json.dumps(receipt, indent=2) + "\n", encoding="utf-8")
    (RUNTIME / "runtime-layout.json").write_text(json.dumps(layout, indent=2) + "\n", encoding="utf-8")
    return layout


if __name__ == "__main__":
    prepare()
    print("Prepared Apache Spark 4.0.2 / Py4J 0.10.9.9 / Temurin JRE 21.0.12.1+1 under .runtime/")
