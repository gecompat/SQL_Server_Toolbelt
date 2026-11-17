"""Alte SSIS-Nachweise an Originalbytes prüfen; keine aktuelle Providerqualifikation."""
from pathlib import Path
import hashlib
import zipfile
ARCHIVE="Releases/1.0.0/Artifacts/SSIS-Parser-Binding-Predecessor.zip"
ARCHIVE_SHA='55b89513656c819b3c3ffa1a75d77b79156ed79869301ca5cf5663189ce3a7e3'
OLD_HASHES={'Modules/toolbelt.tsql.ssis-debug/Contracts/DependencyPins.json': 'b9436a76728e6c5e137a8250155f2ff197ff806dd1fcb746f8e1831a33f96429', 'Modules/toolbelt.tsql.ssis-debug/Deployment/DependencyPreflight.sql': '11883e7a9bb2f719458821b64a3703e86a998c24d03394cca37835b3a076a31a', 'Modules/toolbelt.tsql.ssis-debug/Clr/DependencyPins.Generated.cs': 'b4f66a94d541c09793fc89e9e867430d24d6e1458019656fa4ec73780b6233a9'}
OLD_PARSER='7F34D0472DBE5913C8D019A72B2684D89CB4CA79590B599DD5B06154D6A40C5494334D8F46218E10E9D1BC5DB983A8750BA77A685D68865D9BCDF30C3D853506'
NEW_PARSER='F2213559FA9085BDAC9B6A4C1954D7BE18EAAE9BFBF950E2A29CC0121D8B36D6838D4366327D3A6B0C9ED655179ACBE898E2887D917AA0D0C2B7C243C891C16A'

def historical_dependency_source(root, relative):
    root=Path(root)
    data=(root/relative).read_bytes()
    if relative not in OLD_HASHES or hashlib.sha256(data).hexdigest()==OLD_HASHES[relative]:
        return data
    archive=root/ARCHIVE
    if hashlib.sha256(archive.read_bytes()).hexdigest()!=ARCHIVE_SHA:
        raise ValueError("SSIS binding predecessor archive drift")
    with zipfile.ZipFile(archive) as zipped:
        if set(zipped.namelist())!=set(OLD_HASHES):
            raise ValueError("SSIS binding predecessor closure drift")
        original=zipped.read(relative)
    if (hashlib.sha256(original).hexdigest()!=OLD_HASHES[relative]
            or original.count(OLD_PARSER.encode())!=1
            or data!=original.replace(OLD_PARSER.encode(),NEW_PARSER.encode())):
        raise ValueError("Unapproved SSIS dependency source delta")
    return original
